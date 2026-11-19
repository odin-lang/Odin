// Decoders for PKZIP's legacy compression methods: Shrink (1), Reduce (2-5) and Implode (6).
package compress_pkzip_legacy

import "base:intrinsics"
import "base:runtime"
import "core:compress"

/*
	Copyright 2026 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's license.

	List of contributors:
		Jeroen van Rijn: Initial implementation.

	Format: PKWARE's APPNOTE.TXT, sections 5.1-5.3 (UnShrinking, Expanding, Imploding):
		https://pkware.cachefly.net/webdocs/casestudies/APPNOTE.TXT

	Fuzzed against hwzip, Hans Wennborg's public domain zip implementation:
		https://www.hanshq.net/zip.html
*/

Error              :: compress.Error
General_Error      :: compress.General_Error
PKZIP_Legacy_Error :: compress.PKZIP_Legacy_Error

Implode_Option :: enum u8 {
	Large_Window = 1,
	Literal_Tree = 2,
}
Implode_Options :: bit_set[Implode_Option; u8]

SHRINK_MIN_CODE_SIZE      :: 9
SHRINK_MAX_CODE_SIZE      :: 13
SHRINK_TABLE_SIZE         :: 1 << SHRINK_MAX_CODE_SIZE
SHRINK_CONTROL_CODE       :: 256
SHRINK_FIRST_FREE_CODE    :: 257
SHRINK_INCREASE_CODE_SIZE :: 1
SHRINK_PARTIAL_CLEAR      :: 2
SHRINK_LEAF_END           :: 0xffff
#assert(compress.SHRINK_EXPANSION_MAX == SHRINK_TABLE_SIZE)

REDUCE_DLE                :: 144
REDUCE_MAX_FOLLOWERS      :: 32
REDUCE_MIN_MATCH          :: 3

IMPLODE_PRIMARY_BITS      :: 9
IMPLODE_MAX_CODE_LENGTH   :: 16
IMPLODE_LITERAL_SYMBOLS   :: 256
IMPLODE_LENGTH_SYMBOLS    :: 64
IMPLODE_DISTANCE_SYMBOLS  :: 64
IMPLODE_EXTRA_LENGTH      :: 63

READER_WINDOW_SIZE        :: 64 * 1024
READER_HISTORY            :: 8192
READER_STEP_MAX           :: SHRINK_TABLE_SIZE + 1
#assert(READER_HISTORY >= (1 << IMPLODE_DISTANCE_BITS_MAX) * IMPLODE_DISTANCE_SYMBOLS)
#assert(READER_WINDOW_SIZE - READER_STEP_MAX >= READER_HISTORY)

IMPLODE_DISTANCE_BITS_MAX :: 7

Reader :: struct {
	z:             ^compress.Context,
	src:           ^compress.Context,
	source:        compress.Context,
	streamed:      bool,
	owns_window:   bool,
	base:          i64,
	pulled:        i64,
	options:       compress.Options,
	allocator:     runtime.Allocator,
	method:        Reader_Method,
	window:        []u8,
	start:         int,
	ready:         int,
	produced:      i64,
	size:          i64,
	total_in:      i64,
	done:          bool,
	started:       bool,
	err:           Error,

	shrink:        ^Unshrink,
	code_size:     uint,
	next_free:     int,
	previous:      int,
	first_byte:    u8,

	expand:        ^Expand,
	state:         Expand_State,
	length_bits:   uint,
	length_max:    int,
	distance_mask: int,
	last:          int,
	v:             int,
	length:        int,

	trees:         ^[3]Implode_Tree,
	literal_tree:  bool,
	distance_bits: uint,
	min_match:     int,
}

@(private)
Reader_Method :: enum u8 {
	Shrink,
	Reduce,
	Implode,
}

@(private)
Unshrink :: struct {
	parent:    [SHRINK_TABLE_SIZE]u16,
	value:     [SHRINK_TABLE_SIZE]u8,
	used:      [SHRINK_TABLE_SIZE]bool,
	children:  [SHRINK_TABLE_SIZE]u16,
	leaf_next: [SHRINK_TABLE_SIZE]u16,
	free:      [SHRINK_TABLE_SIZE / 64]u64,
	leaf_head: u16,
	stack:     [SHRINK_TABLE_SIZE + 1]u8,
}

@(private)
Bits :: struct {
	buffer: u64,
	count:  u64,
}

@(private)
Out :: struct {
	data:     [^]u8,
	at:       int,
	capacity: int,
}

@(private)
Unshrink_Cache :: struct {
	position: [SHRINK_TABLE_SIZE]int,
	length:   [SHRINK_TABLE_SIZE]u16,
}

@(private)
Expand :: struct {
	followers:  [256][REDUCE_MAX_FOLLOWERS]u8,
	counts:     [256]u8,
	index_bits: [256]u8,
}

@(private)
Expand_State :: enum {
	Literal,
	DLE,
	Length,
	Distance,
}

@(private)
Implode_Tree :: struct {
	table:   [1 << IMPLODE_PRIMARY_BITS]u16,
	first:   [IMPLODE_MAX_CODE_LENGTH + 1]int,
	count:   [IMPLODE_MAX_CODE_LENGTH + 1]int,
	offset:  [IMPLODE_MAX_CODE_LENGTH + 1]int,
	symbols: [IMPLODE_LITERAL_SYMBOLS]u8,
}

@(private)
Output_Progress :: struct {
	options:   compress.Options,
	base:      i64,
	pulled:    i64,
	total_in:  i64,
	total_out: i64,
	interval:  int,
	mark:      int,
}

@(private)
check_options :: proc "contextless" (options: compress.Options) -> (err: Error) {
	if options.max_output_size < 0 || options.max_memory < 0 || options.chunk_size < 0 || options.progress_interval < 0 {
		return General_Error.Incompatible_Options
	}
	return nil
}

@(private)
progress_begin :: proc(p: ^Output_Progress, z: ^compress.Context, expected: int, options: compress.Options) {
	p^ = {options = options, total_in = -1, total_out = i64(expected), mark = max(int)}
	if options.progress == nil {
		return
	}
	p.total_in = i64(compress.input_size(z))
	p.interval = compress.progress_interval(options)
	p.mark     = p.interval
	p.base     = i64(len(z.window)) + i64(z.num_bits / 8)
}

@(private)
progress_report :: proc(p: ^Output_Progress, z: ^compress.Context, written: int, bits: u64) -> (err: Error) {
	p.mark = written + p.interval if p.interval < max(int) - written else max(int)
	consumed := p.base + p.pulled - i64(len(z.window)) - i64(bits / 8)
	return compress.report_progress(p.options, consumed, i64(written), p.total_in, p.total_out)
}

@(private)
refill_bits :: proc(z: ^compress.Context, pulled: ^i64) -> (err: Error) #no_bounds_check {
	for z.num_bits <= 56 {
		if len(z.window) == 0 {
			refill_err := compress.refill_window(z, 1)
			pulled^ += i64(len(z.window))
			if refill_err == .EOF {
				return nil
			}
			if refill_err != nil {
				return refill_err
			}
		}
		z.code_buffer |= u64(z.window[0]) << z.num_bits
		z.window       = z.window[1:]
		z.num_bits    += 8
	}
	return nil
}

@(private)
read_bits :: #force_inline proc(z: ^compress.Context, pulled: ^i64, count: uint) -> (value: int, available: bool, err: Error) #no_bounds_check {
	if z.num_bits < u64(count) {
		refill_bits(z, pulled) or_return
		if z.num_bits < u64(count) {
			return 0, false, nil
		}
	}
	value = int(z.code_buffer & (u64(1) << count - 1))
	z.code_buffer >>= count
	z.num_bits     -= u64(count)
	return value, true, nil
}

@(private)
read_bits_required :: #force_inline proc(z: ^compress.Context, pulled: ^i64, count: uint) -> (value: int, err: Error) {
	available: bool
	value, available = read_bits(z, pulled, count) or_return
	if !available {
		return 0, General_Error.Stream_Too_Short
	}
	return
}

@(private)
bits_refill :: #force_inline proc(z: ^compress.Context, pulled: ^i64, b: ^Bits) -> (err: Error) #no_bounds_check {
	if len(z.window) >= 8 && b.count <= 56 {
		bytes := (64 - b.count) >> 3
		total := b.count + bytes << 3
		value := u64(intrinsics.unaligned_load((^u64le)(raw_data(z.window)))) << b.count
		if total < 64 {
			value &= u64(1) << total - 1
		}
		b.buffer |= value
		b.count   = total
		z.window  = z.window[bytes:]
		return nil
	}
	z.code_buffer = b.buffer
	z.num_bits    = b.count
	err = refill_bits(z, pulled)
	b.buffer = z.code_buffer
	b.count  = z.num_bits
	return
}

@(private)
bits_read :: #force_inline proc(z: ^compress.Context, pulled: ^i64, b: ^Bits, count: uint) -> (value: int, available: bool, err: Error) #no_bounds_check {
	if b.count < u64(count) {
		bits_refill(z, pulled, b) or_return
		if b.count < u64(count) {
			return 0, false, nil
		}
	}
	value = int(b.buffer & (u64(1) << count - 1))
	b.buffer >>= count
	b.count   -= u64(count)
	return value, true, nil
}
