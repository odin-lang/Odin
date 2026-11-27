// Reversible filters that make executables and some other data compress better
//
// Branch converters (BCJ) for x86, PowerPC, IA-64, ARM, ARM Thumb, SPARC, ARM64 and RISC-V, Delta, and Swap2/Swap4,
// as used by xz (and so zip method 95) and 7z, plus 7z's four-stream BCJ2.
// Each filter runs in place over a buffer (BCJ2 one-shot between whole buffers), or streams through
// `Reader` and `Writer` (`Bcj2_Reader` and `Bcj2_Writer` for BCJ2). Mapping xz filter IDs and 7z
// method IDs onto them is up to those containers.
// It is a port of Igor Pavlov's public domain LZMA SDK, and the output is byte-identical to the SDK's.
package compress_filters

import "base:intrinsics"
import "base:runtime"
import "core:compress"
import "core:io"

/*
	Copyright 2026 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's license.

	List of contributors:
		Jeroen van Rijn: Initial implementation.

	Ported from the LZMA SDK 26.05 (2026-10-21), written by Igor Pavlov and placed in the public domain:
		https://www.7-zip.org/sdk.html

		C/Bra.c:                 PowerPC, ARM, ARM Thumb, SPARC, ARM64 and RISC-V converters
		C/Bra86.c:               x86 converter, in the prev-mask form of the LZMA SDK 9.20
		C/BraIA64.c:             IA-64 converter
		C/Delta.c:               Delta
		C/SwapBytes.c:           Swap2 and Swap4
		C/Bcj2.c, C/Bcj2Enc.c:   BCJ2 decoder and encoder

	Many thanks to Igor Pavlov for these filters, and for placing the SDK in the public domain.
*/

Error         :: compress.Error
General_Error :: compress.General_Error
BCJ2_Error    :: compress.BCJ2_Error

Branch_Arch :: enum u8 {
	X86,
	PowerPC,
	IA64,
	ARM,
	ARM_Thumb,
	SPARC,
	ARM64,
	RISCV,
}

Branch_State :: struct {
	arch:     Branch_Arch,
	pc:       u32,
	x86_mask: u32,
}

DELTA_DISTANCE_MIN :: 1
DELTA_DISTANCE_MAX :: 256

Delta_State :: struct {
	distance: int,
	history:  [DELTA_DISTANCE_MAX]u8,
}

BRANCH_ALIGNMENT := [Branch_Arch]int{
	.X86       = 1,
	.PowerPC   = 4,
	.IA64      = 16,
	.ARM       = 4,
	.ARM_Thumb = 2,
	.SPARC     = 4,
	.ARM64     = 4,
	.RISCV     = 2,
}

BCJ2_RELAT_LIMIT_DEFAULT :: u32(0x0F) << 24
BCJ2_RELAT_LIMIT_MAX     :: u32(1) << 31

Bcj2_Streams :: struct {
	main: [dynamic]u8,
	call: [dynamic]u8,
	jump: [dynamic]u8,
	rc:   [dynamic]u8,
}

FILTER_CHUNK_SIZE     :: 64 * 1024
FILTER_BUFFER_MIN     :: 16
BCJ2_SIDE_BUFFER_SIZE :: 4 * 1024
BCJ2_BUFFER_MIN       :: 64

Direction :: enum u8 {
	Decode,
	Encode,
}

Branch_Filter :: struct {
	arch:         Branch_Arch,
	start_offset: u32,
}

Delta_Filter :: struct {
	distance: int,
}

Swap_Filter :: enum u8 {
	Swap2,
	Swap4,
}

Filter :: union {
	Branch_Filter,
	Delta_Filter,
	Swap_Filter,
}

Reader :: struct {
	source:      io.Reader,
	converter:   Converter,
	buffer:      []u8,
	start:       int,
	ready:       int,
	end:         int,
	eof:         bool,
	owns_buffer: bool,
	allocator:   runtime.Allocator,
	err:         Error,
}

Writer :: struct {
	w:           io.Writer,
	converter:   Converter,
	buffer:      []u8,
	pending:     int,
	finished:    bool,
	owns_buffer: bool,
	allocator:   runtime.Allocator,
	err:         Error,
}

Bcj2_Stream :: enum u8 {
	Main,
	Call,
	Jump,
	RC,
}

Bcj2_Reader :: struct {
	inputs:       [Bcj2_Stream]Bcj2_Input,
	storage:      []u8,
	owns_storage: bool,
	allocator:    runtime.Allocator,
	probs:        [2 + 256]u16,
	range_:       u32,
	code:         u32,
	ip:           u32,
	prev:         u32,
	marker:       u32,
	pending:      [4]u8,
	pending_pos:  int,
	step:         Bcj2_Step,
	err:          Error,
}

Bcj2_Writer :: struct {
	outputs:      [Bcj2_Stream]io.Writer,
	written:      [Bcj2_Stream]i64,
	buffers:      [Bcj2_Stream][]u8,
	filled:       [Bcj2_Stream]int,
	input:        []u8,
	pending:      int,
	storage:      []u8,
	owns_storage: bool,
	allocator:    runtime.Allocator,
	probs:        [2 + 256]u16,
	low:          u64,
	range_:       u32,
	cache:        u8,
	cache_size:   u64,
	ip:           u64,
	prev:         u32,
	size_limit:   u64,
	relat_limit:  u32,
	scanning:     bool,
	finished:     bool,
	err:          Error,
}

@(private)
Converter_Kind :: enum u8 {
	None,
	Branch,
	Delta,
	Swap2,
	Swap4,
}

@(private)
Converter :: struct {
	kind:      Converter_Kind,
	direction: Direction,
	branch:    Branch_State,
	delta:     Delta_State,
}

@(private)
Bcj2_Input :: struct {
	reader: io.Reader,
	buffer: []u8,
	pos:    int,
	end:    int,
	eof:    bool,
}

@(private)
Bcj2_Step :: enum u8 {
	Header,
	Normalize,
	Scan,
	Address,
	Output,
	Verify,
	Done,
}

@(private) BCJ2_TOP        :: u32(1) << 24
@(private) READ_STALLS_MAX :: 100
@(private) BCJ2_PROB_BITS  :: 11
@(private) BCJ2_PROB_INIT  :: u16(1 << BCJ2_PROB_BITS >> 1)
@(private) BCJ2_MOVE_BITS  :: 5

@(private)
X86_MASK_TO_ALLOWED := [8]bool{true, true, true, false, true, false, false, false}

@(private)
X86_MASK_TO_BIT_NUMBER := [8]u32{0, 1, 2, 2, 3, 3, 3, 3}

@(private)
get_le16 :: #force_inline proc "contextless" (data: []u8, i: int) -> u32 #no_bounds_check {
	return u32(intrinsics.unaligned_load((^u16le)(&data[i])))
}

@(private)
get_le32 :: #force_inline proc "contextless" (data: []u8, i: int) -> u32 #no_bounds_check {
	return u32(intrinsics.unaligned_load((^u32le)(&data[i])))
}

@(private)
get_be32 :: #force_inline proc "contextless" (data: []u8, i: int) -> u32 #no_bounds_check {
	return u32(intrinsics.unaligned_load((^u32be)(&data[i])))
}

@(private)
put_le16 :: #force_inline proc "contextless" (data: []u8, i: int, v: u32) #no_bounds_check {
	intrinsics.unaligned_store((^u16le)(&data[i]), u16le(v))
}

@(private)
put_le32 :: #force_inline proc "contextless" (data: []u8, i: int, v: u32) #no_bounds_check {
	intrinsics.unaligned_store((^u32le)(&data[i]), u32le(v))
}

@(private)
put_be32 :: #force_inline proc "contextless" (data: []u8, i: int, v: u32) #no_bounds_check {
	intrinsics.unaligned_store((^u32be)(&data[i]), u32be(v))
}

@(private)
_chunk_size :: proc "contextless" (options: compress.Options) -> (size: int) {
	return options.chunk_size if options.chunk_size > 0 else FILTER_CHUNK_SIZE
}

@(private)
_stream_buffer :: proc(options: compress.Options, minimum, size: int, allocator: runtime.Allocator) -> (buffer: []u8, owned: bool, err: Error) {
	if options.max_output_size < 0 || options.max_memory < 0 || options.chunk_size < 0 || options.progress_interval < 0 {
		return nil, false, General_Error.Incompatible_Options
	}
	if options.buffer != nil {
		if len(options.buffer) < minimum {
			return nil, false, General_Error.Incompatible_Options
		}
		return options.buffer, false, nil
	}
	if size > compress.memory_limit(options) {
		return nil, false, General_Error.Memory_Limit_Exceeded
	}
	buffer = make([]u8, size, allocator) or_return
	return buffer, true, nil
}

@(private)
_io_error :: proc "contextless" (err: Error) -> (result: io.Error) {
	if err == nil {
		return nil
	}
	if io_err, is_io := err.(io.Error); is_io {
		return io_err
	}
	return .Unknown
}
