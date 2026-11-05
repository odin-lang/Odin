package compress

/*
	Copyright 2026 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's license.

	List of contributors:
		Jeroen van Rijn: Initial implementation, optimization.
*/

import "base:intrinsics"
import "base:runtime"
import "core:io"

CONTEXT_WINDOW_SIZE :: 64 * 1024
CONTEXT_HISTORY     :: 16

/*
	A generic I/O context for ZLIB, LZW, etc.

	When `input.procedure` equals this package's `_memory_reader_proc`,
	it signals that `input.data` is a `^[]byte` containing the whole input,
	which we can access directly as a fast path.

	Streams are now read in blocks into `window`, backed by `backing` to
	forestall unnecessary slowdowns by reading a stream byte-by-byte.
*/
Context :: struct #align(64) {
	input:             io.Stream,     // 32-bit: 8, 64-bit: 16
	output:            ^[dynamic]byte, // 32-bit: 4, 64-bit: 8
	bytes_written:     i64,           // 32-bit: 8, 64-bit: 8
	code_buffer:       u64,           // 32-bit: 8, 64-bit: 8
	num_bits:          u64,           // 32-bit: 8, 64-bit: 8

	// Some algorithms, like legacy PKZIP methods Implode & Reduce,
	// need to know the unpacked size to not write a spurious tail,
	size_unpacked:     i64,           // 32-bit: 8, 64-bit: 8

	buffer:            []byte,
	window:            []byte,
	backing:           []byte,
	backing_allocator: runtime.Allocator,
	owns_backing:      b8,
	_reserved:         [7]u8,
}

when size_of(rawptr) == 8 {
	#assert(size_of(Context) == 16 + 8 + 8 + 8 + 8 + 8 + 3 * 16 + 16 + 8)
	// 128 bytes
} else {
	#assert(size_of(Context) == (8 + 4 + 8 + 8 + 8 + 8 + 3 * 8 + 8 + 8 + 63) &~ 63)
	// 84 bytes, padded to 128 by `#align(64)`
}


// A fake `io.Stream` for when the full input is in memory as a ^[]byte` in its `data` pointer.
Memory_Reader :: io.Stream

// A fake `io.Stream` implementation.
// When `s.procedure` equals this procedure, it means that `s.data` is a `^[]byte` containing the whole input.
// Not meant to be used as a real `io.Stream` and always returns `.Unsupported`.
_memory_reader_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	return 0, .Unsupported
}

// Initialize I/O `Context` from byte slice
init_context_from_slice :: proc(data: ^[]byte, output: ^[dynamic]byte = nil, size_unpacked := i64(-1)) -> (ctx: Context) {
	ctx.input = Memory_Reader{
		procedure = _memory_reader_proc,
		data      = data,
	}
	ctx.buffer        = data^
	ctx.window        = data^
	ctx.output        = output
	ctx.size_unpacked = size_unpacked
	return
}

// Initialize I/O `Context` from `io.Stream`
init_context_from_stream :: proc(stream: io.Stream, output: ^[dynamic]byte = nil, size_unpacked := i64(-1), buffer: []byte = nil, allocator := context.allocator) -> (ctx: Context) {
	ctx.input         = stream
	ctx.size_unpacked = size_unpacked
	ctx.output        = output
	ctx.backing_allocator = allocator
	if buffer != nil {
		ctx.backing = buffer
	} else {
		ctx.backing, _    = make([]byte, CONTEXT_WINDOW_SIZE, allocator)
		ctx.owns_backing  = true
	}
	ctx.buffer = ctx.backing[:0]
	ctx.window = ctx.buffer
	return
}

init_context :: proc{init_context_from_slice, init_context_from_stream}

destroy_context :: proc(z: ^Context) {
	if z.owns_backing {
		delete(z.backing, z.backing_allocator)
	}
	z.backing      = nil
	z.buffer       = nil
	z.window       = nil
	z.owns_backing = false
}

// Tests whether the `Context` was initialized with the full input in memory
is_memory_context :: #force_inline proc(z: ^Context) -> (memory_context: bool) {
	return z.input.procedure == _memory_reader_proc
}

@(optimization_mode="favor_size")
refill_window :: proc(z: ^Context, need: int) -> (err: io.Error) #no_bounds_check {
	if len(z.window) >= need {
		return nil
	}
	if is_memory_context(z) || need > len(z.backing) - CONTEXT_HISTORY {
		return .EOF if len(z.window) == 0 else .Short_Buffer
	}

	offset := len(z.buffer) - len(z.window)
	keep   := min(offset, CONTEXT_HISTORY)
	filled := copy(z.backing, z.buffer[offset - keep:])

	stalled := 0
	for filled - keep < need {
		n, read_err := io.read(z.input, z.backing[filled:])
		filled += n
		if read_err != nil && read_err != .EOF {
			err = read_err
			break
		}
		if n == 0 {
			if read_err == .EOF {
				err = .EOF if filled == keep else .Short_Buffer
				break
			}
			stalled += 1
			if stalled > 100 {
				err = .No_Progress
				break
			}
		}
	}

	z.buffer = z.backing[:filled]
	z.window = z.buffer[keep:]
	return
}

rewind :: proc(z: ^Context, n: int) -> (ok: bool) {
	offset := len(z.buffer) - len(z.window)
	if n < 0 || n > offset {
		return false
	}
	z.window = z.buffer[offset - n:]
	return true
}

// Returns the size of the `Context`'s input or `io.Error`s.
@(optimization_mode="favor_size")
size :: proc(z: ^Context) -> (res: i64, err: io.Error) {
	if is_memory_context(z) {
		return i64(len(z.window)), nil
	}
	total    := io.size(z.input)                   or_return
	position := io.seek(z.input, 0, .Current)     or_return
	return total - position + i64(len(z.window)), nil
}

@(optimization_mode="favor_size")
read_ptr :: proc(z: ^Context, ptr: ^$T) -> (err: io.Error) #no_bounds_check {
	return read_slice(z, ([^]byte)(ptr)[:size_of(T)])
}

@(optimization_mode="favor_size")
read_data :: proc(z: ^Context, $T: typeid) -> (res: T, err: io.Error) #no_bounds_check {
	if len(z.window) < size_of(T) {
		refill_window(z, size_of(T)) or_return
	}
	res = intrinsics.unaligned_load(cast(^T)raw_data(z.window))
	z.window = z.window[size_of(T):]
	return res, nil
}

@(optimization_mode="favor_size")
read_slice :: proc(z: ^Context, buf: []byte) -> (err: io.Error) #no_bounds_check {
	if len(z.window) >= len(buf) {
		copy(buf, z.window)
		z.window = z.window[len(buf):]
		return nil
	}
	if is_memory_context(z) {
		return .Short_Buffer
	}

	n    := copy(buf, z.window)
	z.window = z.window[n:]
	rest := buf[n:]

	if len(rest) <= len(z.backing) - CONTEXT_HISTORY {
		if err = refill_window(z, len(rest)); err != nil {
			return .Short_Buffer if err == .EOF else err
		}
		copy(rest, z.window)
		z.window = z.window[len(rest):]
		return nil
	}

	if _, err = io.read_full(z.input, rest); err != nil {
		return .Short_Buffer if err == .EOF || err == .Unexpected_EOF else err
	}
	kept    := copy(z.backing, rest[max(len(rest) - CONTEXT_HISTORY, 0):])
	z.buffer = z.backing[:kept]
	z.window = z.buffer[kept:]
	return nil
}

@(optimization_mode="favor_size")
read_u8 :: proc(z: ^Context) -> (res: byte, err: io.Error) #no_bounds_check {
	if len(z.window) < 1 {
		refill_window(z, 1) or_return
	}
	res      = z.window[0]
	z.window = z.window[1:]
	return
}

@(optimization_mode="favor_size")
skip :: proc(z: ^Context, offset: i64) -> (err: io.Error) #no_bounds_check {
	if offset < 0 {
		return .Short_Buffer
	}
	if i64(len(z.window)) >= offset {
		z.window = z.window[offset:]
		return
	}
	if is_memory_context(z) {
		return .Short_Buffer
	}

	remaining := offset - i64(len(z.window))
	z.window   = z.window[len(z.window):]

	if _, seek_err := io.seek(z.input, remaining, .Current); seek_err == nil {
		z.buffer = z.backing[:0]
		z.window = z.buffer
		return nil
	}

	for remaining > 0 {
		refill_window(z, int(min(remaining, i64(len(z.backing) - CONTEXT_HISTORY)))) or_return
		n := min(i64(len(z.window)), remaining)
		z.window   = z.window[n:]
		remaining -= n
	}
	return nil
}

@(optimization_mode="favor_size")
peek_data_at_cursor :: proc(z: ^Context, $T: typeid) -> (res: T, err: io.Error) #no_bounds_check {
	if len(z.window) < size_of(T) {
		refill_window(z, size_of(T)) or_return
	}
	res = intrinsics.unaligned_load(cast(^T)raw_data(z.window))
	return res, nil
}

@(optimization_mode="favor_size")
peek_data_at_offset :: proc(z: ^Context, $T: typeid, #any_int offset: i64) -> (res: T, err: io.Error) #no_bounds_check {
	if offset < 0 {
		return {}, .Short_Buffer
	}
	if i64(len(z.window)) < size_of(T) + offset {
		if !is_memory_context(z) && size_of(T) + offset > i64(len(z.backing) - CONTEXT_HISTORY) {
			peek_input_at(z, ([^]byte)(&res)[:size_of(T)], offset) or_return
			return res, nil
		}
		refill_window(z, int(offset) + size_of(T)) or_return
	}
	res = intrinsics.unaligned_load(cast(^T)raw_data(z.window[offset:]))
	return res, nil
}

@(optimization_mode="favor_size")
peek_input_at :: proc(z: ^Context, buf: []byte, offset: i64) -> (err: io.Error) {
	position := io.seek(z.input, 0, .Current) or_return
	io.seek(z.input, position - i64(len(z.window)) + offset, .Start) or_return
	_, err = io.read_full(z.input, buf)
	_, seek_err := io.seek(z.input, position, .Start)
	return err if err != nil else seek_err
}

@(optimization_mode="favor_size")
read_remaining :: proc(z: ^Context, allocator := context.allocator) -> (data: [dynamic]byte, err: io.Error) {
	data.allocator = allocator
	if _, append_err := append(&data, ..z.window); append_err != nil {
		return data, .Buffer_Full
	}
	z.window = z.window[len(z.window):]
	if is_memory_context(z) {
		return data, nil
	}

	stalled := 0
	for {
		start := len(data)
		if start + CONTEXT_WINDOW_SIZE > COMPRESS_OUTPUT_ALLOCATE_MAX || non_zero_resize(&data, start + CONTEXT_WINDOW_SIZE) != nil {
			return data, .Buffer_Full
		}
		n, read_err := io.read(z.input, data[start:])
		non_zero_resize(&data, start + n)
		if read_err == .EOF {
			return data, nil
		}
		if read_err != nil {
			return data, read_err
		}
		if n == 0 {
			stalled += 1
			if stalled > 100 {
				return data, .No_Progress
			}
		}
	}
}

peek_data :: proc{peek_data_at_cursor, peek_data_at_offset}
