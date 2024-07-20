/*
	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-3 license.

	List of contributors:
		Jeroen van Rijn: Initial implementation, optimization.
*/


// package compress is a collection of utilities to aid with other compression packages
package compress

import "core:io"
import "core:bytes"
import "base:runtime"

/*
	These settings bound how much compression algorithms will allocate for their output buffer.
	If streaming their output, these are unnecessary and will be ignored.

*/


// When a decompression routine doesn't stream its output, but writes to a buffer,
// we pre-allocate an output buffer to speed up decompression. The default is 1 MiB.
COMPRESS_OUTPUT_ALLOCATE_MIN :: int(#config(COMPRESS_OUTPUT_ALLOCATE_MIN, 1 << 20))

/*
	This bounds the maximum a buffer will resize to as needed, or the maximum we'll
	pre-allocate if you inform the decompression routine you know the payload size.

	For reference, the largest payload size of a GZIP file is 4 GiB.

*/
when size_of(uintptr) == 8 {

	// For 64-bit platforms, we set the default max buffer size to 4 GiB,
	// which is GZIP and PKZIP's max payload size.
	COMPRESS_OUTPUT_ALLOCATE_MAX :: int(#config(COMPRESS_OUTPUT_ALLOCATE_MAX, 1 << 32))
} else {
	
	// For 32-bit platforms, we set the default max buffer size to 512 MiB.
	COMPRESS_OUTPUT_ALLOCATE_MAX :: int(#config(COMPRESS_OUTPUT_ALLOCATE_MAX, 1 << 29))
}


Error :: union #shared_nil {
	General_Error,
	Deflate_Error,
	ZLIB_Error,
	GZIP_Error,
	ZIP_Error,

	runtime.Allocator_Error,
}

General_Error :: enum {
	None = 0,
	File_Not_Found,
	Cannot_Open_File,
	File_Too_Short,
	Stream_Too_Short,
	Output_Too_Short,
	Unknown_Compression_Method,
	Checksum_Failed,
	Incompatible_Options,
	Unimplemented,

	// Memory errors

	Allocation_Failed,
	Resize_Failed,
}

GZIP_Error :: enum {
	None = 0,
	Invalid_GZIP_Signature,
	Reserved_Flag_Set,
	Invalid_Extra_Data,
	Original_Name_Too_Long,
	Comment_Too_Long,
	Payload_Length_Invalid,
	Payload_CRC_Invalid,

	// GZIP's payload can be a maximum of max(u32le), or 4 GiB.
	// If you tell it you expect it to contain more, that's obviously an error.

	Payload_Size_Exceeds_Max_Payload,

	// For buffered instead of streamed output, the payload size can't exceed
	// the max set by the `COMPRESS_OUTPUT_ALLOCATE_MAX` switch in compress/common.odin.
	//
	// You can tweak this setting using `-define:COMPRESS_OUTPUT_ALLOCATE_MAX=size_in_bytes`

	Output_Exceeds_COMPRESS_OUTPUT_ALLOCATE_MAX,

}

ZIP_Error :: enum {
	None = 0,
	Invalid_ZIP_File_Signature,
	Unexpected_Signature,
	Insert_Next_Disk,
	Expected_End_of_Central_Directory_Record,
}

ZLIB_Error :: enum {
	None = 0,
	Unsupported_Window_Size,
	FDICT_Unsupported,
	Unsupported_Compression_Level,
	Code_Buffer_Malformed,
}

Deflate_Error :: enum {
	None = 0,
	Huffman_Bad_Sizes,
	Huffman_Bad_Code_Lengths,
	Inflate_Error,
	Bad_Distance,
	Bad_Huffman_Code,
	Len_Nlen_Mismatch,
	BType_3,
}

// General I/O context for ZLIB, LZW, etc.
Context_Memory_Input :: struct #packed {
	input_data:        []u8,
	output:            ^bytes.Buffer,
	bytes_written:     i64,

	code_buffer:       u64,
	num_bits:          u64,

	// If we know the data size, we can optimize the reads and writes.

	size_packed:       i64,
	size_unpacked:     i64,
}
when size_of(rawptr) == 8 {
	#assert(size_of(Context_Memory_Input) == 64)
} else {
	// e.g. `-target:windows_i386`
	#assert(size_of(Context_Memory_Input) == 52)
}

Context_Stream_Input :: struct #packed {
	input_data:        []u8,
	input:             io.Stream,
	output:            ^bytes.Buffer,
	bytes_written:     i64,

	code_buffer:       u64,
	num_bits:          u64,

	// If we know the data size, we can optimize the reads and writes.

	size_packed:       i64,
	size_unpacked:     i64,

	// Flags:
	// `input_fully_in_memory`
	//   true  = This tells us we read input from `input_data` exclusively. [] = EOF.
	//   false = Try to refill `input_data` from the `input` stream.

	input_fully_in_memory: b8,

	padding: [1]u8,
}

/*
	TODO: The stream versions should really only check if a certain method is available once, perhaps even during setup.

	Bit and byte readers may be merged so that reading bytes will grab them from the bit buffer first.
	This simplifies end-of-stream handling where bits may be left in the bit buffer.
*/

input_size_from_memory :: proc(z: ^Context_Memory_Input) -> (res: i64, err: Error) {
	return i64(len(z.input_data)), nil
}

input_size_from_stream :: proc(z: ^Context_Stream_Input) -> (res: i64, err: Error) {
	res, _ = io.size(z.input)
	return
}

input_size :: proc{input_size_from_memory, input_size_from_stream}

@(optimization_mode="favor_size")
read_slice_from_memory :: #force_inline proc(z: ^Context_Memory_Input, size: int) -> (res: []u8, err: io.Error) {
	#no_bounds_check {
		if len(z.input_data) >= size {
			res = z.input_data[:size]
			z.input_data = z.input_data[size:]
			return res, .None
		}
	}

	if len(z.input_data) == 0 {
		return []u8{}, .EOF
	} else {
		return []u8{}, .Short_Buffer
	}
}

@(optimization_mode="favor_size")
read_slice_from_stream :: #force_inline proc(z: ^Context_Stream_Input, size: int) -> (res: []u8, err: io.Error) {
	// TODO: REMOVE ALL USE OF context.temp_allocator here
	// there is literally no need for it
	b := make([]u8, size, context.temp_allocator)
	_ = io.read(z.input, b[:]) or_return
	return b, nil
}

read_slice :: proc{read_slice_from_memory, read_slice_from_stream}

@(optimization_mode="favor_size")
read_data :: #force_inline proc(z: ^$C, $T: typeid) -> (res: T, err: io.Error) {
	b := read_slice(z, size_of(T)) or_return
	return (^T)(&b[0])^, nil
}

@(optimization_mode="favor_size")
read_u8_from_memory :: #force_inline proc(z: ^Context_Memory_Input) -> (res: u8, err: io.Error) {
	#no_bounds_check {
		if len(z.input_data) >= 1 {
			res = z.input_data[0]
			z.input_data = z.input_data[1:]
			return res, .None
		}
	}
	return 0, .EOF
}

@(optimization_mode="favor_size")
read_u8_from_stream :: #force_inline proc(z: ^Context_Stream_Input) -> (res: u8, err: io.Error) {
	b := read_slice_from_stream(z, 1) or_return
	return b[0], nil
}

read_u8 :: proc{read_u8_from_memory, read_u8_from_stream}

// You would typically only use this at the end of Inflate, to drain bits from the code buffer
// preferentially.
@(optimization_mode="favor_size")
read_u8_prefer_code_buffer_lsb :: #force_inline proc(z: ^$C) -> (res: u8, err: io.Error) {
	if z.num_bits >= 8 {
		res = u8(read_bits_no_refill_lsb(z, 8))
	} else {
		size, _ := input_size(z)
		if size > 0 {
			res, err = read_u8(z)
		} else {
			err = .EOF
		}
	}
	return
}

@(optimization_mode="favor_size")
peek_data_from_memory :: #force_inline proc(z: ^Context_Memory_Input, $T: typeid) -> (res: T, err: io.Error) {
	size :: size_of(T)

	#no_bounds_check {
		if len(z.input_data) >= size {
			buf := z.input_data[:size]
			return (^T)(&buf[0])^, .None
		}
	}

	if len(z.input_data) == 0 {
		return T{}, .EOF
	} else {
		return T{}, .Short_Buffer
	}
}

@(optimization_mode="favor_size")
peek_data_at_offset_from_memory :: #force_inline proc(z: ^Context_Memory_Input, $T: typeid, #any_int offset: int) -> (res: T, err: io.Error) {
	size :: size_of(T)

	#no_bounds_check {
		if len(z.input_data) >= size + offset {
			buf := z.input_data[offset:][:size]
			return (^T)(&buf[0])^, .None
		}
	}

	if len(z.input_data) == 0 {
		return T{}, .EOF
	} else {
		return T{}, .Short_Buffer
	}
}

@(optimization_mode="favor_size")
peek_data_from_stream :: #force_inline proc(z: ^Context_Stream_Input, $T: typeid) -> (res: T, err: io.Error) {
	size :: size_of(T)

	// Get current position to read from.
	curr := z.input->impl_seek(0, .Current) or_return
	r, e1 := io.to_reader_at(z.input)
	if !e1 {
		return T{}, .Empty
	}
	when size <= 128 {
		b: [size]u8
	} else {
		b := make([]u8, size, context.temp_allocator)
	}
	_, e2 := io.read_at(r, b[:], curr)
	if e2 != .None {
		return T{}, .Empty
	}

	res = (^T)(&b[0])^
	return res, .None
}

@(optimization_mode="favor_size")
peek_data_at_offset_from_stream :: #force_inline proc(z: ^Context_Stream_Input, $T: typeid, #any_int offset: int) -> (res: T, err: io.Error) {
	size :: size_of(T)

	// Get current position to return to.
	cur_pos := z.input->impl_seek(0, .Current) or_return
	// Seek to offset.
	pos := z.input->impl_seek(offset, .Start) or_return

	r, e3 := io.to_reader_at(z.input)
	if !e3 {
		return T{}, .Empty
	}
	when size <= 128 {
		b: [size]u8
	} else {
		b := make([]u8, size, context.temp_allocator)
	}
	_, e4 := io.read_at(r, b[:], pos)
	if e4 != .None {
		return T{}, .Empty
	}

	// Return read head to original position.
	z.input->impl_seek(cur_pos, .Start)

	res = (^T)(&b[0])^
	return res, .None
}

peek_data :: proc{peek_data_from_memory, peek_data_from_stream, peek_data_at_offset_from_memory, peek_data_at_offset_from_stream}



// Sliding window read back
@(optimization_mode="favor_size")
peek_back_byte :: #force_inline proc(z: ^$C, offset: i64) -> (res: u8, err: io.Error) {
	// Look back into the sliding window.
	return z.output.buf[z.bytes_written - offset], .None
}

// Generalized bit reader LSB
@(optimization_mode="favor_size")
refill_lsb_from_memory :: #force_inline proc(z: ^Context_Memory_Input, width := i8(48)) {
	refill := u64(width)
	b      := u64(0)

	if z.num_bits > refill {
		return
	}

	for {
		if len(z.input_data) != 0 {
			b = u64(z.input_data[0])
			z.input_data = z.input_data[1:]
		} else {
			b = 0
		}

		z.code_buffer |= b << u8(z.num_bits)
		z.num_bits += 8
		if z.num_bits > refill {
			break
		}
	}
}

// Generalized bit reader LSB
@(optimization_mode="favor_size")
refill_lsb_from_stream :: proc(z: ^Context_Stream_Input, width := i8(24)) {
	refill := u64(width)

	for {
		if z.num_bits > refill {
			break
		}
		if z.code_buffer == 0 && z.num_bits > 63 {
			z.num_bits = 0
		}
		if z.code_buffer >= 1 << uint(z.num_bits) {
			// Code buffer is malformed.
			z.num_bits = max(u64)
			return
		}
		b, err := read_u8(z)
		if err != .None {
			// This is fine at the end of the file.
			return
		}
		z.code_buffer |= (u64(b) << u8(z.num_bits))
		z.num_bits += 8
	}
}

refill_lsb :: proc{refill_lsb_from_memory, refill_lsb_from_stream}


@(optimization_mode="favor_size")
consume_bits_lsb_from_memory :: #force_inline proc(z: ^Context_Memory_Input, width: u8) {
	z.code_buffer >>= width
	z.num_bits -= u64(width)
}

@(optimization_mode="favor_size")
consume_bits_lsb_from_stream :: #force_inline proc(z: ^Context_Stream_Input, width: u8) {
	z.code_buffer >>= width
	z.num_bits -= u64(width)
}

consume_bits_lsb :: proc{consume_bits_lsb_from_memory, consume_bits_lsb_from_stream}

@(optimization_mode="favor_size")
peek_bits_lsb_from_memory :: #force_inline proc(z: ^Context_Memory_Input, width: u8) -> u32 {
	if z.num_bits < u64(width) {
		refill_lsb(z)
	}
	return u32(z.code_buffer &~ (~u64(0) << width))
}

@(optimization_mode="favor_size")
peek_bits_lsb_from_stream :: #force_inline proc(z: ^Context_Stream_Input, width: u8) -> u32 {
	if z.num_bits < u64(width) {
		refill_lsb(z)
	}
	return u32(z.code_buffer &~ (~u64(0) << width))
}

peek_bits_lsb :: proc{peek_bits_lsb_from_memory, peek_bits_lsb_from_stream}

@(optimization_mode="favor_size")
peek_bits_no_refill_lsb_from_memory :: #force_inline proc(z: ^Context_Memory_Input, width: u8) -> u32 {
	assert(z.num_bits >= u64(width))
	return u32(z.code_buffer &~ (~u64(0) << width))
}

@(optimization_mode="favor_size")
peek_bits_no_refill_lsb_from_stream :: #force_inline proc(z: ^Context_Stream_Input, width: u8) -> u32 {
	assert(z.num_bits >= u64(width))
	return u32(z.code_buffer &~ (~u64(0) << width))
}

peek_bits_no_refill_lsb :: proc{peek_bits_no_refill_lsb_from_memory, peek_bits_no_refill_lsb_from_stream}

@(optimization_mode="favor_size")
read_bits_lsb_from_memory :: #force_inline proc(z: ^Context_Memory_Input, width: u8) -> u32 {
	k := #force_inline peek_bits_lsb(z, width)
	#force_inline consume_bits_lsb(z, width)
	return k
}

@(optimization_mode="favor_size")
read_bits_lsb_from_stream :: #force_inline proc(z: ^Context_Stream_Input, width: u8) -> u32 {
	k := peek_bits_lsb(z, width)
	consume_bits_lsb(z, width)
	return k
}

read_bits_lsb :: proc{read_bits_lsb_from_memory, read_bits_lsb_from_stream}

@(optimization_mode="favor_size")
read_bits_no_refill_lsb_from_memory :: #force_inline proc(z: ^Context_Memory_Input, width: u8) -> u32 {
	k := #force_inline peek_bits_no_refill_lsb(z, width)
	#force_inline consume_bits_lsb(z, width)
	return k
}

@(optimization_mode="favor_size")
read_bits_no_refill_lsb_from_stream :: #force_inline proc(z: ^Context_Stream_Input, width: u8) -> u32 {
	k := peek_bits_no_refill_lsb(z, width)
	consume_bits_lsb(z, width)
	return k
}

read_bits_no_refill_lsb :: proc{read_bits_no_refill_lsb_from_memory, read_bits_no_refill_lsb_from_stream}


@(optimization_mode="favor_size")
discard_to_next_byte_lsb_from_memory :: proc(z: ^Context_Memory_Input) {
	discard := u8(z.num_bits & 7)
	#force_inline consume_bits_lsb(z, discard)
}


@(optimization_mode="favor_size")
discard_to_next_byte_lsb_from_stream :: proc(z: ^Context_Stream_Input) {
	discard := u8(z.num_bits & 7)
	consume_bits_lsb(z, discard)
}

discard_to_next_byte_lsb :: proc{discard_to_next_byte_lsb_from_memory, discard_to_next_byte_lsb_from_stream}
