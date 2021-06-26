package compress

/*
	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-2 license.

	List of contributors:
		Jeroen van Rijn: Initial implementation, optimization.
*/

import "core:io"
import "core:image"
import "core:bytes"

/*
	These settings bound how much compression algorithms will allocate for their output buffer.
	If streaming their output, these are unnecessary and will be ignored.

*/

/*
	When a decompression routine doesn't stream its output, but writes to a buffer,
	we pre-allocate an output buffer to speed up decompression. The default is 1 MiB.
*/
COMPRESS_OUTPUT_ALLOCATE_MIN :: int(#config(COMPRESS_OUTPUT_ALLOCATE_MIN, 1 << 20));

/*
	This bounds the maximum a buffer will resize to as needed, or the maximum we'll
	pre-allocate if you inform the decompression routine you know the payload size.

	For reference, the largest payload size of a GZIP file is 4 GiB.

*/
when size_of(uintptr) == 8 {
	/*
		For 64-bit platforms, we set the default max buffer size to 4 GiB,
		which is GZIP and PKZIP's max payload size.
	*/	
	COMPRESS_OUTPUT_ALLOCATE_MAX :: int(#config(COMPRESS_OUTPUT_ALLOCATE_MAX, 1 << 32));
} else {
	/*
		For 32-bit platforms, we set the default max buffer size to 512 MiB.
	*/
	COMPRESS_OUTPUT_ALLOCATE_MAX :: int(#config(COMPRESS_OUTPUT_ALLOCATE_MAX, 1 << 29));
}


Error :: union {
	General_Error,
	Deflate_Error,
	ZLIB_Error,
	GZIP_Error,
	ZIP_Error,
	/*
		This is here because png.load will return a this type of error union,
		as it may involve an I/O error, a Deflate error, etc.
	*/
	image.Error,
}

General_Error :: enum {
	File_Not_Found,
	Cannot_Open_File,
	File_Too_Short,
	Stream_Too_Short,
	Output_Too_Short,
	Unknown_Compression_Method,
	Checksum_Failed,
	Incompatible_Options,
	Unimplemented,


	/*
		Memory errors
	*/
	Allocation_Failed,
	Resize_Failed,
}

GZIP_Error :: enum {
	Invalid_GZIP_Signature,
	Reserved_Flag_Set,
	Invalid_Extra_Data,
	Original_Name_Too_Long,
	Comment_Too_Long,
	Payload_Length_Invalid,
	Payload_CRC_Invalid,

	/*
		GZIP's payload can be a maximum of max(u32le), or 4 GiB.
		If you tell it you expect it to contain more, that's obviously an error.
	*/
	Payload_Size_Exceeds_Max_Payload,
	/*
		For buffered instead of streamed output, the payload size can't exceed
		the max set by the `COMPRESS_OUTPUT_ALLOCATE_MAX` switch in compress/common.odin.

		You can tweak this setting using `-define:COMPRESS_OUTPUT_ALLOCATE_MAX=size_in_bytes`
	*/
	Output_Exceeds_COMPRESS_OUTPUT_ALLOCATE_MAX,

}

ZIP_Error :: enum {
	Invalid_ZIP_File_Signature,
	Unexpected_Signature,
	Insert_Next_Disk,
	Expected_End_of_Central_Directory_Record,
}

ZLIB_Error :: enum {
	Unsupported_Window_Size,
	FDICT_Unsupported,
	Unsupported_Compression_Level,
	Code_Buffer_Malformed,
}

Deflate_Error :: enum {
	Huffman_Bad_Sizes,
	Huffman_Bad_Code_Lengths,
	Inflate_Error,
	Bad_Distance,
	Bad_Huffman_Code,
	Len_Nlen_Mismatch,
	BType_3,
}


// General I/O context for ZLIB, LZW, etc.
Context :: struct {
	input_data:        []u8,
	input:             io.Stream,
	output:            ^bytes.Buffer,
	bytes_written:     i64,

	/*
		If we know the data size, we can optimize the reads and writes.
	*/    
	size_packed:   i64,
	size_unpacked: i64,

	code_buffer: u64,
	num_bits:    u64,

	/*
		Flags:
			`input_fully_in_memory` tells us whether we're EOF when `input_data` is empty.
			`input_refills_from_stream` tells us we can then possibly refill from the stream.
	*/
	input_fully_in_memory: b8,
	input_refills_from_stream: b8,
}


// Stream helpers
/*
	TODO: These need to be optimized.

	Streams should really only check if a certain method is available once, perhaps even during setup.

	Bit and byte readers may be merged so that reading bytes will grab them from the bit buffer first.
	This simplifies end-of-stream handling where bits may be left in the bit buffer.
*/

@(optimization_mode="speed")
read_slice :: #force_inline proc(z: ^Context, size: int) -> (res: []u8, err: io.Error) {
	#no_bounds_check {
		if len(z.input_data) >= size {
			res = z.input_data[:size];
			z.input_data = z.input_data[size:];
			return res, .None;
		}
	}

	if z.input_fully_in_memory {
		if len(z.input_data) == 0 {
			return []u8{}, .EOF;
		} else {
			return []u8{}, .Short_Buffer;
		}
	}

	/*
		TODO: Try to refill z.input_data from stream, using packed_data as a guide.
	*/
	b := make([]u8, size, context.temp_allocator);
	_, e := z.input->impl_read(b[:]);
	if e == .None {
		return b, .None;
	}

	return []u8{}, e;
}

@(optimization_mode="speed")
read_data :: #force_inline proc(z: ^Context, $T: typeid) -> (res: T, err: io.Error) {
	b, e := read_slice(z, size_of(T));
	if e == .None {
		return (^T)(&b[0])^, .None;
	}

	return T{}, e;
}

@(optimization_mode="speed")
read_u8 :: #force_inline proc(z: ^Context) -> (res: u8, err: io.Error) {
	#no_bounds_check {
		if len(z.input_data) >= 1 {
			res = z.input_data[0];
			z.input_data = z.input_data[1:];
			return res, .None;
		}
	}

	b, e := read_slice(z, 1);
	if e == .None {
		return b[0], .None;
	}

	return 0, e;
}

@(optimization_mode="speed")
peek_data :: #force_inline proc(z: ^Context, $T: typeid) -> (res: T, err: io.Error) {
	size :: size_of(T);

	#no_bounds_check {
		if len(z.input_data) >= size {
			buf := z.input_data[:size];
			return (^T)(&buf[0])^, .None;
		}
	}

	if z.input_fully_in_memory {
		if len(z.input_data) < size {
			return T{}, .EOF;
		} else {
			return T{}, .Short_Buffer;
		}
	}

	// Get current position to read from.
	curr, e1 := z.input->impl_seek(0, .Current);
	if e1 != .None {
		return T{}, e1;
	}
	r, e2 := io.to_reader_at(z.input);
	if !e2 {
		return T{}, .Empty;
	}
	when size <= 128 {
		b: [size]u8;
	} else {
		b := make([]u8, size, context.temp_allocator);
	}
	_, e3 := io.read_at(r, b[:], curr);
	if e3 != .None {
		return T{}, .Empty;
	}

	res = (^T)(&b[0])^;
	return res, .None;
}

// Sliding window read back
@(optimization_mode="speed")
peek_back_byte :: #force_inline proc(z: ^Context, offset: i64) -> (res: u8, err: io.Error) {
	// Look back into the sliding window.
	return z.output.buf[z.bytes_written - offset], .None;
}

// Generalized bit reader LSB
@(optimization_mode="speed")
refill_lsb :: proc(z: ^Context, width := i8(24)) {
	refill := u64(width);

	for {
		if z.num_bits > refill {
			break;
		}
		if z.code_buffer == 0 && z.num_bits > 63 {
			z.num_bits = 0;
		}
		if z.code_buffer >= 1 << uint(z.num_bits) {
			// Code buffer is malformed.
			z.num_bits = max(u64);
			return;
		}
		b, err := read_u8(z);
		if err != .None {
			// This is fine at the end of the file.
			return;
		}
		z.code_buffer |= (u64(b) << u8(z.num_bits));
		z.num_bits += 8;
	}
}

@(optimization_mode="speed")
consume_bits_lsb :: #force_inline proc(z: ^Context, width: u8) {
	z.code_buffer >>= width;
	z.num_bits -= u64(width);
}

@(optimization_mode="speed")
peek_bits_lsb :: #force_inline proc(z: ^Context, width: u8) -> u32 {
	if z.num_bits < u64(width) {
		refill_lsb(z);
	}
	// assert(z.num_bits >= i8(width));
	return u32(z.code_buffer & ~(~u64(0) << width));
}

@(optimization_mode="speed")
peek_bits_no_refill_lsb :: #force_inline proc(z: ^Context, width: u8) -> u32 {
	assert(z.num_bits >= u64(width));
	return u32(z.code_buffer & ~(~u64(0) << width));
}

@(optimization_mode="speed")
read_bits_lsb :: #force_inline proc(z: ^Context, width: u8) -> u32 {
	k := peek_bits_lsb(z, width);
	consume_bits_lsb(z, width);
	return k;
}

@(optimization_mode="speed")
read_bits_no_refill_lsb :: #force_inline proc(z: ^Context, width: u8) -> u32 {
	k := peek_bits_no_refill_lsb(z, width);
	consume_bits_lsb(z, width);
	return k;
}

@(optimization_mode="speed")
discard_to_next_byte_lsb :: proc(z: ^Context) {
	discard := u8(z.num_bits & 7);
	consume_bits_lsb(z, discard);
}
