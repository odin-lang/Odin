// This package implements Yann Collet's LZ4 Block and Frame compression and decompression.
// It is a cleanroom implementation straight from the spec without referencing Yann's code.
package compress_lz4

import "base:intrinsics"
import "base:runtime"
import "core:compress"
import "core:hash/xxhash"
import "core:io"

/*
	Copyright 2026 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's license.

	List of contributors:
		Jeroen van Rijn: Initial implementation.

	Formats: Yann Collet's LZ4 block and frame format specifications:
		https://github.com/lz4/lz4/blob/dev/doc/lz4_Block_format.md
		https://github.com/lz4/lz4/blob/dev/doc/lz4_Frame_format.md
*/

// One exception to the cleanroom principle is present only for the highest
// compression modes:
//
// The optimal parser's tie-break towards fewer sequences and the joining of
// adjacent matches that share an offset are based on ideas from lz4ultra:
// https://github.com/emmanuel-marty/lz4ultra/blob/master/src/shrink_block.c
// Its Odin-compatible Zlib license is found at the bottom of this file.

compress_block :: proc{compress_block_to_slice, compress_block_to_dynamic}
compress_frame :: proc{compress_frame_to_slice, compress_frame_to_dynamic}

compress_block_bound :: proc(length: int) -> int {
	if length < 0 || length > LZ4_INPUT_MAX {
		return -1
	}
	return length + length / 255 + 16
}

compress_frame_bound :: proc(length: int, frame_options := Frame_Options{flags = DEFAULT_FRAME_FLAGS}) -> int {
	if length < 0 || length > LZ4_INPUT_MAX {
		return -1
	}
	block_max := LZ4_BLOCK_MAX_BYTES[frame_options.block_max_size]
	blocks    := (length + block_max - 1) / block_max
	return FRAME_HEADER_MAX + FRAME_FOOTER_MAX + 4 + blocks * 8 + length + block_max / 255 + 16
}

compress_block_to_slice :: proc(s: ^LZ4, output, input: []u8, level := Level.Default, options: compress.Options = {}, dictionary: []u8 = nil) -> (written: int, err: Error) {
	lz4_check_options(options) or_return
	bound := compress_block_bound(len(input))
	lz4_check_arguments(s, bound) or_return
	limit := lz4_output_size(len(output), options)
	lz4_reset(s, level)

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	data    := input
	history := 0
	if len(dictionary) > 0 {
		data, history = lz4_prefix_dictionary(dictionary, input) or_return
		lz4_index(s, data, 0, history, level)
	}

	if options.progress == nil && limit >= bound {
		return lz4_compress_range(s, output, data, history, len(data), 0, level, false, nil), nil
	}
	check := lz4_progress_init(options, history, i64(len(input)), -1)
	check.limit = limit
	written = lz4_compress_range(s, output, data, history, len(data), 0, level, true, &check)
	if check.err != nil {
		return 0, check.err
	}
	compress.report_progress(options, i64(len(input)), i64(written), i64(len(input)), -1) or_return
	return written, nil
}

compress_block_to_dynamic :: proc(output: ^[dynamic]u8, input: []u8, level := Level.Default, options: compress.Options = {}, dictionary: []u8 = nil, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator
	return lz4_to_dynamic(output, input, compress_block_bound(len(input)), level, {}, options, dictionary, false)
}

compress_frame_to_slice :: proc(s: ^LZ4, output, input: []u8, level := Level.Default, frame_options := Frame_Options{flags = DEFAULT_FRAME_FLAGS}, options: compress.Options = {}, dictionary: []u8 = nil) -> (written: int, err: Error) #no_bounds_check {
	lz4_check_options(options) or_return
	lz4_check_arguments(s, compress_frame_bound(len(input), frame_options)) or_return
	limit := lz4_output_size(len(output), options)
	lz4_reset(s, level)

	block_max := LZ4_BLOCK_MAX_BYTES[frame_options.block_max_size]
	header: [FRAME_HEADER_MAX]u8
	op := lz4_write_frame_header(header[:], frame_options, u64(len(input)))
	if op > limit {
		return 0, General_Error.Output_Too_Short
	}
	copy(output, header[:op])

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	data    := input
	history := 0
	if len(dictionary) > 0 && .Independent_Blocks not_in frame_options.flags {
		data, history = lz4_prefix_dictionary(dictionary, input) or_return
		lz4_index(s, data, 0, history, level)
	}

	check := lz4_progress_init(options, 0, i64(len(input)), -1)
	for offset := 0; offset < len(input); offset += block_max {
		block_end := min(offset + block_max, len(input))
		op += lz4_encode_block(s, output[op:limit], data, history + offset, history + block_end, level, frame_options.flags, dictionary) or_return
		if block_end >= check.mark && block_end < len(input) && lz4_progress_report(&check, block_end, i64(block_end), i64(op)) {
			return 0, check.err
		}
	}

	if 4 + (4 if .Content_Checksum in frame_options.flags else 0) > limit - op {
		return 0, General_Error.Output_Too_Short
	}
	dst := raw_data(output)
	lz4_store_u32(dst[op:], 0)
	op += 4
	if .Content_Checksum in frame_options.flags {
		lz4_store_u32(dst[op:], xxhash.XXH32(input))
		op += 4
	}
	compress.report_progress(options, i64(len(input)), i64(op), i64(len(input)), -1) or_return
	return op, nil
}

compress_frame_to_dynamic :: proc(output: ^[dynamic]u8, input: []u8, level := Level.Default, frame_options := Frame_Options{flags = DEFAULT_FRAME_FLAGS}, options: compress.Options = {}, dictionary: []u8 = nil, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator
	return lz4_to_dynamic(output, input, compress_frame_bound(len(input), frame_options), level, frame_options, options, dictionary, true)
}

frame_writer_init :: proc(fw: ^Frame_Writer, w: io.Writer, level := Level.Default, frame_options := Frame_Options{flags = DEFAULT_FRAME_FLAGS}, input_size: i64 = -1, options: compress.Options = {}, dictionary: []u8 = nil, allocator := context.allocator) -> (err: Error) {
	fw^ = {}
	fw.level         = level
	fw.frame_options = frame_options
	fw.dictionary    = dictionary
	fw.allocator     = allocator
	fw.options       = options
	fw.block_max     = LZ4_BLOCK_MAX_BYTES[frame_options.block_max_size]
	defer fw.err = err

	if options.max_output_size < 0 || options.max_memory < 0 || options.chunk_size < 0 || options.progress_interval < 0 || input_size < -1 {
		return General_Error.Incompatible_Options
	}

	minimum   := 2 * LZ4_WINDOW_SIZE + fw.block_max + 4
	out_size  := FRAME_HEADER_MAX + compress_block_bound(fw.block_max) + 8 + FRAME_FOOTER_MAX
	available := compress.memory_limit(options) - size_of(LZ4) - out_size
	if options.buffer != nil {
		if len(options.buffer) < minimum {
			return General_Error.Incompatible_Options
		}
		fw.window = options.buffer
	} else if available < minimum {
		return General_Error.Memory_Limit_Exceeded
	}

	state := runtime.mem_alloc_non_zeroed(size_of(LZ4), align_of(LZ4), allocator) or_return
	fw.state = (^LZ4)(raw_data(state))
	fw.out = non_zero_make([]u8, out_size, allocator) or_return
	if fw.window == nil {
		size := min(minimum + (options.chunk_size if options.chunk_size > 0 else WRITER_CHUNK_SIZE), available)
		fw.window      = non_zero_make([]u8, size, allocator) or_return
		fw.owns_window = true
	}
	lz4_writer_start(fw, w, input_size)
	return nil
}

frame_writer_reset :: proc(fw: ^Frame_Writer, w: io.Writer, input_size: i64 = -1) -> (err: Error) {
	defer fw.err = err
	if fw.state == nil || fw.out == nil || fw.window == nil || input_size < -1 {
		return General_Error.Incompatible_Options
	}
	lz4_writer_start(fw, w, input_size)
	return nil
}

frame_writer_write :: proc(fw: ^Frame_Writer, p: []u8) -> (n: int, err: Error) {
	if fw.err != nil {
		return 0, fw.err
	}
	if fw.finished {
		return 0, io.Error.Closed
	}
	defer fw.err = err
	if fw.input_size >= 0 && i64(len(p)) > fw.input_size - fw.total {
		return 0, General_Error.Size_Mismatch
	}
	for n < len(p) {
		if fw.filled == len(fw.window) {
			lz4_writer_slide(fw)
		}
		k := copy(fw.window[fw.filled:], p[n:])
		if .Content_Checksum in fw.flags {
			xxhash.XXH32_update(&fw.digest, p[n:n + k])
		}
		fw.filled += k
		fw.total  += i64(k)
		n         += k
		for fw.filled - fw.start >= fw.block_max + 4 {
			lz4_writer_block(fw, fw.block_max) or_return
			compress.report_progress(fw.options, fw.total, fw.flushed, fw.input_size, -1) or_return
		}
	}
	return
}

frame_writer_finish :: proc(fw: ^Frame_Writer) -> (err: Error) {
	if fw.err != nil {
		return fw.err
	}
	if fw.finished {
		return nil
	}
	defer fw.err = err
	if fw.input_size >= 0 && fw.total != fw.input_size {
		return General_Error.Size_Mismatch
	}
	for fw.start < fw.filled {
		lz4_writer_block(fw, min(fw.block_max, fw.filled - fw.start)) or_return
	}
	dst := raw_data(fw.out)
	lz4_store_u32(dst[fw.out_len:], 0)
	fw.out_len += 4
	if .Content_Checksum in fw.flags {
		lz4_store_u32(dst[fw.out_len:], u32(xxhash.XXH32_digest(&fw.digest)))
		fw.out_len += 4
	}
	lz4_writer_flush(fw) or_return
	fw.finished = true
	return compress.report_progress(fw.options, fw.total, fw.flushed, fw.input_size, -1)
}

frame_writer_to_stream :: proc(fw: ^Frame_Writer) -> (s: io.Stream) {
	s.data      = fw
	s.procedure = lz4_writer_stream_proc
	return
}

frame_writer_destroy :: proc(fw: ^Frame_Writer) {
	if fw.owns_window {
		delete(fw.window, fw.allocator)
	}
	delete(fw.out, fw.allocator)
	free(fw.state, fw.allocator)
	fw.state       = nil
	fw.window      = nil
	fw.out         = nil
	fw.owns_window = false
}

@(private)
lz4_check_arguments :: proc(s: ^LZ4, bound: int) -> Error {
	if s == nil {
		return General_Error.Incompatible_Options
	}
	if bound < 0 {
		return LZ4_Error.Input_Too_Large
	}
	return nil
}

@(private)
lz4_check_options :: proc "contextless" (options: compress.Options) -> Error {
	if options.max_output_size < 0 || options.max_memory < 0 || options.progress_interval < 0 {
		return General_Error.Incompatible_Options
	}
	return nil
}

@(private)
lz4_output_size :: proc "contextless" (size: int, options: compress.Options) -> int {
	return min(size, options.max_output_size) if options.max_output_size > 0 else size
}

@(private)
lz4_progress_init :: proc "contextless" (options: compress.Options, origin: int, total_in, total_out: i64) -> (p: LZ4_Check) {
	p.options   = options
	p.interval  = compress.progress_interval(options)
	p.mark      = max(int)
	p.limit     = max(int)
	p.total_in  = total_in
	p.total_out = total_out
	if options.progress != nil {
		p.mark = origin + p.interval if p.interval < max(int) - origin else max(int)
	}
	return
}

@(private)
lz4_progress_report :: proc(p: ^LZ4_Check, position: int, bytes_in, bytes_out: i64) -> (canceled: bool) {
	p.err  = compress.report_progress(p.options, bytes_in, bytes_out, p.total_in, p.total_out)
	p.mark = position + p.interval if p.interval < max(int) - position else max(int)
	return p.err != nil
}

@(private)
lz4_sequence_overflows :: #force_inline proc "contextless" (check: ^LZ4_Check, op, literals, length: int) -> bool {
	if op + literals + (literals + 240) / 255 + (length - LZ4_MIN_MATCH + 240) / 255 + 9 <= check.limit {
		return false
	}
	check.err = General_Error.Output_Too_Short
	return true
}

@(private)
lz4_last_overflows :: #force_inline proc "contextless" (check: ^LZ4_Check, op, literals: int) -> bool {
	if op + 1 + literals + (literals + 240) / 255 <= check.limit {
		return false
	}
	check.err = General_Error.Output_Too_Short
	return true
}

@(private)
lz4_to_dynamic :: proc(output: ^[dynamic]u8, input: []u8, bound: int, level: Level, frame_options: Frame_Options, options: compress.Options, dictionary: []u8, $FRAME: bool) -> (err: Error) {
	if output == nil {
		return General_Error.Incompatible_Options
	}
	lz4_check_options(options) or_return
	if bound < 0 {
		return LZ4_Error.Input_Too_Large
	}
	if size_of(LZ4) > compress.memory_limit(options) {
		return General_Error.Memory_Limit_Exceeded
	}
	state := runtime.mem_alloc_non_zeroed(size_of(LZ4), align_of(LZ4)) or_return
	s := (^LZ4)(raw_data(state))
	defer free(s)

	non_zero_resize(output, min(bound, compress.output_limit(options))) or_return
	written: int
	when FRAME {
		written, err = compress_frame_to_slice(s, output[:], input, level, frame_options, options, dictionary)
	} else {
		written, err = compress_block_to_slice(s, output[:], input, level, options, dictionary)
	}
	non_zero_resize(output, written)
	return
}

@(private)
lz4_prefix_dictionary :: proc(dictionary, input: []u8) -> (data: []u8, history: int, err: Error) {
	tail := dictionary[max(0, len(dictionary) - LZ4_MAX_OFFSET):]
	if len(tail) + len(input) > LZ4_INPUT_MAX {
		return nil, 0, LZ4_Error.Input_Too_Large
	}
	data = make([]u8, len(tail) + len(input), context.temp_allocator) or_return
	copy(data, tail)
	copy(data[len(tail):], input)
	return data, len(tail), nil
}

@(private)
lz4_reset :: proc(s: ^LZ4, level: Level) {
	if LZ4_LEVELS[clamp(level, Level.Fastest, Level.Best)].strategy == .Fast {
		intrinsics.mem_zero(&s.fast, size_of(s.fast))
	} else {
		intrinsics.mem_zero(&s.head, size_of(s.head))
	}
}

@(private)
lz4_index :: proc(s: ^LZ4, data: []u8, from, to: int, level: Level) #no_bounds_check {
	src  := raw_data(data)
	last := min(to, len(data) - 4)
	#partial switch LZ4_LEVELS[clamp(level, Level.Fastest, Level.Best)].strategy {
	case .Fast:
		for p in from..<min(to, len(data) - 8) {
			s.fast[lz4_hash_fast(lz4_load_u64(src[p:]))] = u32(p)
		}
	case .Double:
		for p in from..<min(to, len(data) - 8) {
			lz4_double_insert(s, src, p)
		}
	case:
		next := from
		lz4_insert(s, src, &next, last)
	}
}

@(private)
lz4_compress_range :: proc(s: ^LZ4, output, data: []u8, start, end, low: int, level: Level, $CHECKED: bool, check: ^LZ4_Check) -> int {
	parameters := LZ4_LEVELS[clamp(level, Level.Fastest, Level.Best)]
	switch parameters.strategy {
	case .Fast:
		return lz4_compress_fast(s, output, data, start, end, low, CHECKED, check)
	case .Double:
		return lz4_compress_double(s, output, data, start, end, low, CHECKED, check)
	case .Greedy:
		return lz4_compress_chain(s, output, data, start, end, low, parameters.chain_depth, parameters.nice_length, false, CHECKED, check)
	case .Lazy:
		return lz4_compress_chain(s, output, data, start, end, low, parameters.chain_depth, parameters.nice_length, true, CHECKED, check)
	case .Optimal:
		return lz4_compress_optimal(s, output, data, start, end, low, parameters.chain_depth, parameters.nice_length, CHECKED, check)
	}
	unreachable()
}

@(private)
lz4_hash_fast :: #force_inline proc "contextless" (sequence: u64) -> u32 {
	return u32(((sequence << 24) * 889523592379) >> (64 - LZ4_FAST_HASH_LOG))
}

@(private)
lz4_hash :: #force_inline proc "contextless" (sequence: u32) -> u32 {
	return (sequence * 2654435761) >> (32 - LZ4_HASH_LOG)
}

@(private)
lz4_count :: #force_inline proc "contextless" (src: [^]u8, current, candidate, limit: int) -> int {
	p := current
	q := candidate
	for p + 8 <= limit {
		x := lz4_load_u64(src[p:]) ~ lz4_load_u64(src[q:])
		if x != 0 {
			return p - current + int(intrinsics.count_trailing_zeros(x) >> 3)
		}
		p += 8
		q += 8
	}
	for p < limit && src[p] == src[q] {
		p += 1
		q += 1
	}
	return p - current
}

@(private)
lz4_emit_sequence :: #force_inline proc "contextless" (dst: [^]u8, op: int, src: [^]u8, anchor, literals, offset, length: int) -> int {
	op := op
	token := op
	op += 1
	match := length - LZ4_MIN_MATCH
	dst[token] = u8(min(literals, 15) << 4 | min(match, 15))
	if literals >= 15 {
		n := literals - 15
		for n >= 255 {
			dst[op] = 255
			op += 1
			n  -= 255
		}
		dst[op] = u8(n)
		op += 1
	}
	if literals < 32 {
		for i := 0; i < literals; i += 8 {
			lz4_copy_8(dst[op + i:], src[anchor + i:])
		}
	} else {
		intrinsics.mem_copy_non_overlapping(dst[op:], src[anchor:], literals)
	}
	op += literals
	lz4_store_u16(dst[op:], u16(offset))
	op += 2
	if match >= 15 {
		n := match - 15
		for n >= 255 {
			dst[op] = 255
			op += 1
			n  -= 255
		}
		dst[op] = u8(n)
		op += 1
	}
	return op
}

@(private)
lz4_emit_last :: #force_inline proc "contextless" (dst: [^]u8, op: int, src: [^]u8, anchor, end: int) -> int {
	op := op
	literals := end - anchor
	dst[op] = u8(min(literals, 15) << 4)
	op += 1
	if literals >= 15 {
		n := literals - 15
		for n >= 255 {
			dst[op] = 255
			op += 1
			n  -= 255
		}
		dst[op] = u8(n)
		op += 1
	}
	intrinsics.mem_copy_non_overlapping(dst[op:], src[anchor:], literals)
	return op + literals
}

@(private)
lz4_compress_fast :: proc(s: ^LZ4, output, data: []u8, start, end, low: int, $CHECKED: bool, check: ^LZ4_Check) -> int #no_bounds_check {
	LZ4_SKIP_TRIGGER :: 6

	dst := raw_data(output)
	src := raw_data(data)
	op  := 0
	anchor := start

	if end - start <= LZ4_MATCH_START_LIMIT {
		when CHECKED {
			if lz4_last_overflows(check, op, end - anchor) {
				return op
			}
		}
		return lz4_emit_last(dst, op, src, anchor, end)
	}
	match_limit  := end - LZ4_MATCH_START_LIMIT
	length_limit := end - LZ4_LAST_LITERALS
	table := &s.fast
	ip := start

	outer: for ip <= match_limit {
		when CHECKED {
			if ip >= check.mark && lz4_progress_report(check, ip, i64(ip - start), i64(op)) {
				return op
			}
		}
		candidate: int
		search := 1 << LZ4_SKIP_TRIGGER
		for {
			sequence := lz4_load_u64(src[ip:])
			h := lz4_hash_fast(sequence)
			candidate = int(table[h])
			table[h]  = u32(ip)
			if uint(ip - candidate - 1) < LZ4_MAX_OFFSET && candidate >= low && lz4_load_u32(src[candidate:]) == u32(sequence) {
				break
			}
			ip     += search >> LZ4_SKIP_TRIGGER
			search += 1
			if ip > match_limit {
				break outer
			}
			when CHECKED {
				if ip >= check.mark && lz4_progress_report(check, ip, i64(ip - start), i64(op)) {
					return op
				}
			}
		}

		for ip > anchor && candidate > low && src[ip - 1] == src[candidate - 1] {
			ip        -= 1
			candidate -= 1
		}

		length := LZ4_MIN_MATCH + lz4_count(src, ip + LZ4_MIN_MATCH, candidate + LZ4_MIN_MATCH, length_limit)
		when CHECKED {
			if lz4_sequence_overflows(check, op, ip - anchor, length) {
				return op
			}
		}
		op = lz4_emit_sequence(dst, op, src, anchor, ip - anchor, ip - candidate, length)
		ip    += length
		anchor = ip
		if ip > match_limit {
			break
		}
		table[lz4_hash_fast(lz4_load_u64(src[ip - 2:]))] = u32(ip - 2)
	}
	when CHECKED {
		if lz4_last_overflows(check, op, end - anchor) {
			return op
		}
	}
	return lz4_emit_last(dst, op, src, anchor, end)
}

@(private)
LZ4_DOUBLE_HASH_LOG :: 15

@(private)
lz4_double_insert :: #force_inline proc "contextless" (s: ^LZ4, src: [^]u8, p: int) {
	sequence := lz4_load_u64(src[p:])
	s.head[(sequence * 0x9E3779B185EBCA87) >> (64 - LZ4_DOUBLE_HASH_LOG)] = u32(p)
	s.head[(1 << LZ4_DOUBLE_HASH_LOG) + int((u32(sequence) * 2654435761) >> (32 - LZ4_DOUBLE_HASH_LOG))] = u32(p)
}

@(private)
lz4_compress_double :: proc(s: ^LZ4, output, data: []u8, start, end, low: int, $CHECKED: bool, check: ^LZ4_Check) -> int #no_bounds_check {
	LZ4_SKIP_TRIGGER :: 6

	dst := raw_data(output)
	src := raw_data(data)
	op  := 0
	anchor := start

	if end - start <= LZ4_MATCH_START_LIMIT {
		when CHECKED {
			if lz4_last_overflows(check, op, end - anchor) {
				return op
			}
		}
		return lz4_emit_last(dst, op, src, anchor, end)
	}
	match_limit  := end - LZ4_MATCH_START_LIMIT
	length_limit := end - LZ4_LAST_LITERALS
	long_table  := s.head[:1 << LZ4_DOUBLE_HASH_LOG]
	short_table := s.head[1 << LZ4_DOUBLE_HASH_LOG:]
	ip := start
	search := 1 << LZ4_SKIP_TRIGGER

	for ip <= match_limit {
		when CHECKED {
			if ip >= check.mark && lz4_progress_report(check, ip, i64(ip - start), i64(op)) {
				return op
			}
		}
		sequence := lz4_load_u64(src[ip:])
		h8 := (sequence * 0x9E3779B185EBCA87) >> (64 - LZ4_DOUBLE_HASH_LOG)
		h4 := (u32(sequence) * 2654435761) >> (32 - LZ4_DOUBLE_HASH_LOG)
		long_candidate  := int(long_table[h8])
		short_candidate := int(short_table[h4])
		long_table[h8]  = u32(ip)
		short_table[h4] = u32(ip)

		length    := 0
		candidate := 0
		if uint(ip - long_candidate - 1) < LZ4_MAX_OFFSET && long_candidate >= low && lz4_load_u32(src[long_candidate:]) == u32(sequence) {
			length    = LZ4_MIN_MATCH + lz4_count(src, ip + LZ4_MIN_MATCH, long_candidate + LZ4_MIN_MATCH, length_limit)
			candidate = long_candidate
		}
		if length < 8 && short_candidate != long_candidate && uint(ip - short_candidate - 1) < LZ4_MAX_OFFSET && short_candidate >= low && lz4_load_u32(src[short_candidate:]) == u32(sequence) {
			short_length := LZ4_MIN_MATCH + lz4_count(src, ip + LZ4_MIN_MATCH, short_candidate + LZ4_MIN_MATCH, length_limit)
			if short_length > length {
				length    = short_length
				candidate = short_candidate
			}
		}
		if length == 0 {
			ip     += search >> LZ4_SKIP_TRIGGER
			search += 1
			continue
		}
		search = 1 << LZ4_SKIP_TRIGGER

		for ip > anchor && candidate > low && src[ip - 1] == src[candidate - 1] {
			ip        -= 1
			candidate -= 1
			length    += 1
		}

		match_start := ip
		when CHECKED {
			if lz4_sequence_overflows(check, op, ip - anchor, length) {
				return op
			}
		}
		op = lz4_emit_sequence(dst, op, src, anchor, ip - anchor, ip - candidate, length)
		ip    += length
		anchor = ip
		if ip > match_limit {
			break
		}
		lz4_double_insert(s, src, match_start + 1)
		lz4_double_insert(s, src, ip - 2)
		lz4_double_insert(s, src, ip - 1)
	}
	when CHECKED {
		if lz4_last_overflows(check, op, end - anchor) {
			return op
		}
	}
	return lz4_emit_last(dst, op, src, anchor, end)
}

@(private)
lz4_insert :: #force_inline proc "contextless" (s: ^LZ4, src: [^]u8, next: ^int, target: int) {
	for p := next^; p < target; p += 1 {
		h := lz4_hash(lz4_load_u32(src[p:]))
		delta := p - int(s.head[h])
		s.chain[p & (LZ4_WINDOW_SIZE - 1)] = u16(delta) if delta > 0 && delta <= LZ4_MAX_OFFSET else 0
		s.head[h] = u32(p)
	}
	next^ = max(next^, target)
}

@(private)
lz4_find :: #force_inline proc "contextless" (s: ^LZ4, src: [^]u8, ip, low, length_limit: int, depth, nice: i32) -> (best_length, best_offset: int) {
	sequence  := lz4_load_u32(src[ip:])
	candidate := int(s.head[lz4_hash(sequence)])
	next_head := int(s.head[lz4_hash(lz4_load_u32(src[ip + 1:]))])
	intrinsics.prefetch_read_data(&s.chain[next_head & (LZ4_WINDOW_SIZE - 1)], 3)
	intrinsics.prefetch_read_data(&src[next_head], 3)
	if candidate >= ip {
		return 0, 0
	}
	best_length = LZ4_MIN_MATCH - 1
	max_length := length_limit - ip
	floor      := max(low, ip - LZ4_MAX_OFFSET)
	target     := src[ip + best_length]
	depth := depth
	for depth > 0 && candidate >= floor {
		if src[candidate + best_length] == target && lz4_load_u32(src[candidate:]) == sequence {
			length := LZ4_MIN_MATCH + lz4_count(src, ip + LZ4_MIN_MATCH, candidate + LZ4_MIN_MATCH, length_limit)
			if length > best_length {
				best_length = length
				best_offset = ip - candidate
				if length >= int(nice) || length >= max_length {
					break
				}
				target = src[ip + best_length]
			}
		}
		delta := int(s.chain[candidate & (LZ4_WINDOW_SIZE - 1)])
		if delta == 0 {
			break
		}
		candidate -= delta
		depth     -= 1
	}
	if best_length < LZ4_MIN_MATCH {
		return 0, 0
	}
	return
}

@(private)
lz4_compress_chain :: proc(s: ^LZ4, output, data: []u8, start, end, low: int, depth, nice: i32, lazy: bool, $CHECKED: bool, check: ^LZ4_Check) -> int #no_bounds_check {
	dst := raw_data(output)
	src := raw_data(data)
	op  := 0
	anchor := start
	next   := start
	insert_limit := len(data) - 4

	if end - start <= LZ4_MATCH_START_LIMIT {
		lz4_insert(s, src, &next, min(end, insert_limit))
		when CHECKED {
			if lz4_last_overflows(check, op, end - anchor) {
				return op
			}
		}
		return lz4_emit_last(dst, op, src, anchor, end)
	}
	match_limit  := end - LZ4_MATCH_START_LIMIT
	length_limit := end - LZ4_LAST_LITERALS
	ip := start

	for ip <= match_limit {
		when CHECKED {
			if ip >= check.mark && lz4_progress_report(check, ip, i64(ip - start), i64(op)) {
				return op
			}
		}
		lz4_insert(s, src, &next, ip)
		length, offset := lz4_find(s, src, ip, low, length_limit, depth, nice)
		if length == 0 {
			ip += 1
			continue
		}
		if lazy {
			for ip + 1 <= match_limit && length < int(nice) {
				lz4_insert(s, src, &next, ip + 1)
				next_length, next_offset := lz4_find(s, src, ip + 1, low, length_limit, depth, nice)
				if next_length <= length {
					break
				}
				ip += 1
				length, offset = next_length, next_offset
			}
		}
		when CHECKED {
			if lz4_sequence_overflows(check, op, ip - anchor, length) {
				return op
			}
		}
		op = lz4_emit_sequence(dst, op, src, anchor, ip - anchor, offset, length)
		ip    += length
		anchor = ip
	}
	lz4_insert(s, src, &next, min(end, insert_limit))
	when CHECKED {
		if lz4_last_overflows(check, op, end - anchor) {
			return op
		}
	}
	return lz4_emit_last(dst, op, src, anchor, end)
}

@(private)
LZ4_OPTIMAL_WINDOW :: 4096

@(private)
LZ4_OPTIMAL_SKIP :: 64

@(private)
LZ4_Optimal_Node :: struct {
	cost:     i32,
	tokens:   i32,
	literals: i32,
	previous: i32,
	length:   i32,
	offset:   i32,
}

@(private)
lz4_length_extra :: #force_inline proc "contextless" (n: int) -> int {
	return 0 if n < 15 else 1 + (n - 15) / 255
}

@(private)
lz4_compress_optimal :: proc(s: ^LZ4, output, data: []u8, start, end, low: int, depth, nice: i32, $CHECKED: bool, check: ^LZ4_Check) -> int #no_bounds_check {
	dst := raw_data(output)
	src := raw_data(data)
	op  := 0
	anchor := start
	next   := start
	insert_limit := len(data) - 4

	if end - start <= LZ4_MATCH_START_LIMIT {
		lz4_insert(s, src, &next, min(end, insert_limit))
		when CHECKED {
			if lz4_last_overflows(check, op, end - anchor) {
				return op
			}
		}
		return lz4_emit_last(dst, op, src, anchor, end)
	}
	match_limit  := end - LZ4_MATCH_START_LIMIT
	length_limit := end - LZ4_LAST_LITERALS

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	node_count := LZ4_OPTIMAL_WINDOW + 1
	nodes, alloc_err := make([]LZ4_Optimal_Node, node_count, context.temp_allocator)
	if alloc_err != nil {
		return lz4_compress_chain(s, output, data, start, end, low, depth, nice, true, CHECKED, check)
	}

	Match :: struct {
		length: int,
		offset: int,
	}
	matches: [64]Match

	pending_start, pending_offset, pending_length := 0, 0, 0
	p := start
	for p <= match_limit {
		when CHECKED {
			if check.err != nil || p >= check.mark && lz4_progress_report(check, p, i64(p - start), i64(op)) {
				return op
			}
		}
		window := min(LZ4_OPTIMAL_WINDOW, match_limit + 1 - p)
		for k in 0..=window {
			nodes[k].cost = max(i32)
		}
		nodes[0] = {cost = 0, tokens = 0, literals = i32(p - max(anchor, pending_start + pending_length)), previous = -1}

		finish := window
		forced_length, forced_offset := 0, 0
		skip_until := 0

		for k in 0..<window {
			node := nodes[k]
			if node.cost == max(i32) {
				continue
			}
			i := p + k

			literals := int(node.literals) + 1
			literal_cost := node.cost + 1 + i32(lz4_length_extra(literals) - lz4_length_extra(literals - 1))
			if literal_cost < nodes[k + 1].cost || (literal_cost == nodes[k + 1].cost && node.tokens < nodes[k + 1].tokens) {
				nodes[k + 1] = {cost = literal_cost, tokens = node.tokens, literals = i32(literals), previous = i32(k), length = 0}
			}

			if nodes[k + 1].cost <= node.cost && k + LZ4_MIN_MATCH <= window && nodes[k + LZ4_MIN_MATCH].cost <= node.cost + 3 {
				continue
			}
			if k < skip_until {
				continue
			}
			lz4_insert(s, src, &next, i)
			count := lz4_gather(s, src, i, low, length_limit, depth, nice, matches[:])
			if count == 0 {
				continue
			}
			longest := matches[count - 1]
			if longest.length >= int(nice) {
				finish        = k
				forced_length = longest.length
				forced_offset = longest.offset
				break
			}
			if longest.length >= LZ4_OPTIMAL_SKIP {
				skip_until = k + longest.length - LZ4_OPTIMAL_SKIP / 2
			}
			base := node.cost + 1 + 2
			length := LZ4_MIN_MATCH
			limit  := window - k
			for m in matches[:count] {
				top := min(m.length, limit)
				for ; length <= top; length += 1 {
					cost := base + i32(lz4_length_extra(length - LZ4_MIN_MATCH))
					target := k + length
					if cost < nodes[target].cost || (cost == nodes[target].cost && node.tokens + 1 < nodes[target].tokens) {
						nodes[target] = {cost = cost, tokens = node.tokens + 1, literals = 0, previous = i32(k), length = i32(length), offset = i32(m.offset)}
					}
				}
			}
		}

		path_end := finish
		for path_end > 0 && nodes[path_end].cost == max(i32) {
			path_end -= 1
		}

		steps := 0
		for k := path_end; k > 0; k = int(nodes[k].previous) {
			steps += 1
		}
		chain := make([]i32, steps, context.temp_allocator)
		{
			i := steps
			for k := path_end; k > 0; k = int(nodes[k].previous) {
				i -= 1
				chain[i] = i32(k)
			}
		}
		for k in chain {
			node := nodes[k]
			if node.length == 0 {
				continue
			}
			match_start := p + int(node.previous)
			op = lz4_emit_pending(dst, op, src, &anchor, &pending_start, &pending_offset, &pending_length, match_start, int(node.offset), int(node.length), CHECKED, check)
		}
		p += path_end

		if forced_length > 0 {
			op = lz4_emit_pending(dst, op, src, &anchor, &pending_start, &pending_offset, &pending_length, p, forced_offset, forced_length, CHECKED, check)
			p += forced_length
		}
		if path_end == 0 && forced_length == 0 {
			p += 1
		}
	}
	if pending_length > 0 {
		when CHECKED {
			if lz4_sequence_overflows(check, op, pending_start - anchor, pending_length) {
				return op
			}
		}
		op = lz4_emit_sequence(dst, op, src, anchor, pending_start - anchor, pending_offset, pending_length)
		anchor = pending_start + pending_length
	}
	lz4_insert(s, src, &next, min(end, insert_limit))
	when CHECKED {
		if lz4_last_overflows(check, op, end - anchor) {
			return op
		}
	}
	return lz4_emit_last(dst, op, src, anchor, end)
}

@(private)
lz4_emit_pending :: #force_inline proc "contextless" (dst: [^]u8, op: int, src: [^]u8, anchor, pending_start, pending_offset, pending_length: ^int, start, offset, length: int, $CHECKED: bool, check: ^LZ4_Check) -> int {
	op := op
	if pending_length^ > 0 && start == pending_start^ + pending_length^ && lz4_count(src, start, start - pending_offset^, start + length) == length {
		pending_length^ += length
		return op
	}
	if pending_length^ > 0 {
		when CHECKED {
			if lz4_sequence_overflows(check, op, pending_start^ - anchor^, pending_length^) {
				return op
			}
		}
		op = lz4_emit_sequence(dst, op, src, anchor^, pending_start^ - anchor^, pending_offset^, pending_length^)
		anchor^ = pending_start^ + pending_length^
	}
	pending_start^  = start
	pending_offset^ = offset
	pending_length^ = length
	return op
}

@(private)
lz4_gather :: #force_inline proc "contextless" (s: ^LZ4, src: [^]u8, ip, low, length_limit: int, depth, nice: i32, matches: []$T) -> (count: int) #no_bounds_check {
	sequence  := lz4_load_u32(src[ip:])
	candidate := int(s.head[lz4_hash(sequence)])
	next_head := int(s.head[lz4_hash(lz4_load_u32(src[ip + 1:]))])
	intrinsics.prefetch_read_data(&s.chain[next_head & (LZ4_WINDOW_SIZE - 1)], 3)
	intrinsics.prefetch_read_data(&src[next_head], 3)
	if candidate >= ip {
		return 0
	}
	best_length := LZ4_MIN_MATCH - 1
	max_length  := length_limit - ip
	floor       := max(low, ip - LZ4_MAX_OFFSET)
	target      := src[ip + best_length]
	depth := depth
	for depth > 0 && candidate >= floor {
		if src[candidate + best_length] == target && lz4_load_u32(src[candidate:]) == sequence {
			length := LZ4_MIN_MATCH + lz4_count(src, ip + LZ4_MIN_MATCH, candidate + LZ4_MIN_MATCH, length_limit)
			if length > best_length {
				best_length = length
				if count == len(matches) {
					count -= 1
				}
				matches[count] = {length, ip - candidate}
				count += 1
				if length >= int(nice) || length >= max_length {
					break
				}
				target = src[ip + best_length]
			}
		}
		delta := int(s.chain[candidate & (LZ4_WINDOW_SIZE - 1)])
		if delta == 0 {
			break
		}
		candidate -= delta
		depth     -= 1
	}
	return
}

@(private)
lz4_write_frame_header :: proc(output: []u8, options: Frame_Options, content_size: u64) -> int #no_bounds_check {
	_, has_dictionary_id := options.dictionary_id.?
	dst := raw_data(output)
	lz4_store_u32(dst, FRAME_MAGIC)
	flg := transmute(LZ4_Descriptor_Flags)options.flags + {.Version_Low}
	if has_dictionary_id {
		flg += {.Dictionary_ID}
	}
	dst[4] = transmute(u8)flg
	dst[5] = LZ4_BLOCK_MAX_CODE[options.block_max_size] << 4
	op := 6
	if .Content_Size in options.flags {
		lz4_store_u64(dst[op:], content_size)
		op += 8
	}
	if has_dictionary_id {
		lz4_store_u32(dst[op:], options.dictionary_id.?)
		op += 4
	}
	dst[op] = u8(xxhash.XXH32(output[4:op]) >> 8)
	return op + 1
}

@(private)
lz4_encode_block :: proc(s: ^LZ4, output, data: []u8, start, end: int, level: Level, flags: Frame_Flags, dictionary: []u8) -> (written: int, err: Error) #no_bounds_check {
	dst  := raw_data(output)
	size := end - start
	room := len(output) - 4 - (4 if .Block_Checksum in flags else 0)
	if room < 1 {
		return 0, General_Error.Output_Too_Short
	}

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	block := data
	from, to, low := start, end, max(0, start - LZ4_MAX_OFFSET)
	switch {
	case len(dictionary) > 0 && .Independent_Blocks in flags:
		block_history: int
		block, block_history = lz4_prefix_dictionary(dictionary, data[start:end]) or_return
		lz4_reset(s, level)
		lz4_index(s, block, 0, block_history, level)
		from, to, low = block_history, len(block), 0
	case .Independent_Blocks in flags:
		low = start
	}

	compressed: int
	if room >= compress_block_bound(size) {
		compressed = lz4_compress_range(s, output[4:], block, from, to, low, level, false, nil)
	} else {
		check := LZ4_Check{mark = max(int), limit = min(room, size - 1)}
		compressed = lz4_compress_range(s, output[4:], block, from, to, low, level, true, &check)
		if check.err != nil {
			compressed = size
		}
	}

	if compressed >= size {
		if size > room {
			return 0, General_Error.Output_Too_Short
		}
		intrinsics.mem_copy_non_overlapping(dst[4:], raw_data(data[start:]), size)
		lz4_store_u32(dst, u32(size) | 0x8000_0000)
		compressed = size
	} else {
		lz4_store_u32(dst, u32(compressed))
	}
	if .Block_Checksum in flags {
		lz4_store_u32(dst[4 + compressed:], xxhash.XXH32(output[4:4 + compressed]))
		compressed += 4
	}
	return 4 + compressed, nil
}

@(private)
lz4_writer_start :: proc(fw: ^Frame_Writer, w: io.Writer, input_size: i64) {
	fw.w            = w
	fw.input_size   = input_size
	fw.filled       = 0
	fw.start        = 0
	fw.history      = 0
	fw.total        = 0
	fw.flushed      = 0
	fw.needs_index  = false
	fw.finished     = false
	header_options := fw.frame_options
	if input_size < 0 {
		header_options.flags -= {.Content_Size}
	}
	fw.flags = header_options.flags
	lz4_reset(fw.state, fw.level)
	fw.out_len = lz4_write_frame_header(fw.out, header_options, u64(max(input_size, 0)))
	if len(fw.dictionary) > 0 && .Independent_Blocks not_in fw.flags {
		tail := fw.dictionary[max(0, len(fw.dictionary) - LZ4_MAX_OFFSET):]
		copy(fw.window, tail)
		fw.filled      = len(tail)
		fw.start       = len(tail)
		fw.history     = len(tail)
		fw.needs_index = true
	}
	if .Content_Checksum in fw.flags {
		xxhash.XXH32_reset_state(&fw.digest)
	}
}

@(private)
lz4_writer_block :: proc(fw: ^Frame_Writer, size: int) -> (err: Error) {
	data := fw.window[:fw.filled]
	if fw.needs_index {
		lz4_index(fw.state, data, 0, fw.history, fw.level)
		fw.needs_index = false
	}
	fw.out_len += lz4_encode_block(fw.state, fw.out[fw.out_len:], data, fw.start, fw.start + size, fw.level, fw.flags, fw.dictionary) or_return
	fw.start   += size
	return lz4_writer_flush(fw)
}

@(private)
lz4_writer_flush :: proc(fw: ^Frame_Writer) -> (err: Error) {
	if fw.out_len > 0 {
		_, write_err := io.write_full(fw.w, fw.out[:fw.out_len])
		if write_err != nil {
			return write_err
		}
		fw.flushed += i64(fw.out_len)
		fw.out_len  = 0
	}
	return nil
}

@(private)
lz4_writer_slide :: proc(fw: ^Frame_Writer) {
	shift := (fw.start - LZ4_WINDOW_SIZE) &~ (LZ4_WINDOW_SIZE - 1)
	copy(fw.window, fw.window[shift:fw.filled])
	fw.filled -= shift
	fw.start  -= shift
	table := fw.state.fast[:] if LZ4_LEVELS[clamp(fw.level, Level.Fastest, Level.Best)].strategy == .Fast else fw.state.head[:]
	for &position in table {
		position = position - u32(shift) if int(position) >= shift else 0
	}
}

@(private)
lz4_writer_stream_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	fw := (^Frame_Writer)(stream_data)
	#partial switch mode {
	case .Write:
		written, write_err := frame_writer_write(fw, p)
		n = i64(written)
		if write_err != nil {
			io_err, is_io := write_err.(io.Error)
			err = io_err if is_io else .Unknown
		}
		return
	case .Close:
		if finish_err := frame_writer_finish(fw); finish_err != nil {
			io_err, is_io := finish_err.(io.Error)
			err = io_err if is_io else .Unknown
		}
		return
	case .Destroy:
		frame_writer_destroy(fw)
		return 0, nil
	case .Query:
		return io.query_utility({.Write, .Close, .Destroy, .Query})
	}
	return 0, .Unsupported
}

/*
The optimal parser's tie-break towards fewer sequences and the joining of
adjacent matches that share an offset are based on ideas from lz4ultra:
https://github.com/emmanuel-marty/lz4ultra/blob/master/src/shrink_block.c

    The zlib License

    Copyright (C) 2019 Emmanuel Marty

This software is provided 'as-is', without any express or implied
warranty.  In no event will the authors be held liable for any damages
arising from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it
freely, subject to the following restrictions:

1. The origin of this software must not be misrepresented; you must not
   claim that you wrote the original software. If you use this software
   in a product, an acknowledgment in the product documentation would be
   appreciated but is not required.
2. Altered source versions must be plainly marked as such, and must not be
   misrepresented as being the original software.
3. This notice may not be removed or altered from any source distribution.
*/