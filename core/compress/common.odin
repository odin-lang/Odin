package compress

import "core:io"
import "core:image"

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
}

GZIP_Error :: enum {
	Invalid_GZIP_Signature,
	Reserved_Flag_Set,
	Invalid_Extra_Data,
	Original_Name_Too_Long,
	Comment_Too_Long,
	Payload_Length_Invalid,
	Payload_CRC_Invalid,
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

// General context for ZLIB, LZW, etc.
Context :: struct {
	code_buffer: u32,
	num_bits: i8,
	/*
		num_bits will be set to -100 if the buffer is malformed
	*/
	eof: b8,

	input: io.Stream,
	output: io.Stream,
	bytes_written: i64,
	// Used to update hash as we write instead of all at once
	rolling_hash: u32,

	// Sliding window buffer. Size must be a power of two.
	window_size: i64,
	last: ^[dynamic]byte,
}

// Stream helpers
/*
	TODO: These need to be optimized.

	Streams should really only check if a certain method is available once, perhaps even during setup.

	Bit and byte readers may be merged so that reading bytes will grab them from the bit buffer first.
	This simplifies end-of-stream handling where bits may be left in the bit buffer.
*/

read_data :: #force_inline proc(c: ^Context, $T: typeid) -> (res: T, err: io.Error) {
	b := make([]u8, size_of(T), context.temp_allocator);
	r, e1 := io.to_reader(c.input);
	_, e2 := io.read(r, b);
	if !e1 || e2 != .None {
		return T{}, e2;
	}

	res = (^T)(raw_data(b))^;
	return res, .None;
}

read_u8 :: #force_inline proc(z: ^Context) -> (res: u8, err: io.Error) {
	return read_data(z, u8);
}

peek_data :: #force_inline proc(c: ^Context, $T: typeid) -> (res: T, err: io.Error) {
	// Get current position to read from.
	curr, e1 := c.input->impl_seek(0, .Current);
	if e1 != .None {
		return T{}, e1;
	}
	r, e2 := io.to_reader_at(c.input);
	if !e2 {
		return T{}, .Empty;
	}
	b := make([]u8, size_of(T), context.temp_allocator);
	_, e3 := io.read_at(r, b, curr);
	if e3 != .None {
		return T{}, .Empty;
	}

	res = (^T)(raw_data(b))^;
	return res, .None;
}

// Sliding window read back
peek_back_byte :: proc(c: ^Context, offset: i64) -> (res: u8, err: io.Error) {
	// Look back into the sliding window.
	return c.last[offset % c.window_size], .None;
}

// Generalized bit reader LSB
refill_lsb :: proc(z: ^Context, width := i8(24)) {
	for {
		if z.num_bits > width {
			break;
		}
		if z.code_buffer == 0 && z.num_bits == -1 {
			z.num_bits = 0;
		}
		if z.code_buffer >= 1 << uint(z.num_bits) {
			// Code buffer is malformed.
			z.num_bits = -100;
        	return;
		}
		c, err := read_u8(z);
		if err != .None {
			// This is fine at the end of the file.
			z.num_bits = -42;
			z.eof = true;
			return;
		}
		z.code_buffer |= (u32(c) << u8(z.num_bits));
		z.num_bits += 8;
	}
}

consume_bits_lsb :: #force_inline proc(z: ^Context, width: u8) {
	z.code_buffer >>= width;
	z.num_bits -= i8(width);
}

peek_bits_lsb :: #force_inline proc(z: ^Context, width: u8) -> u32 {
	if z.num_bits < i8(width) {
		refill_lsb(z);
	}
	// assert(z.num_bits >= i8(width));
	return z.code_buffer & ~(~u32(0) << width);
}

peek_bits_no_refill_lsb :: #force_inline proc(z: ^Context, width: u8) -> u32 {
	assert(z.num_bits >= i8(width));
	return z.code_buffer & ~(~u32(0) << width);
}

read_bits_lsb :: #force_inline proc(z: ^Context, width: u8) -> u32 {
	k := peek_bits_lsb(z, width);
	consume_bits_lsb(z, width);
	return k;
}

read_bits_no_refill_lsb :: #force_inline proc(z: ^Context, width: u8) -> u32 {
	k := peek_bits_no_refill_lsb(z, width);
	consume_bits_lsb(z, width);
	return k;
}

discard_to_next_byte_lsb :: proc(z: ^Context) {
	discard := u8(z.num_bits & 7);
	consume_bits_lsb(z, discard);
}
