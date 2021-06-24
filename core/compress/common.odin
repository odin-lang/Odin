package compress

/*
	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-2 license.

	List of contributors:
		Jeroen van Rijn: Initial implementation, optimization.
*/

import "core:io"
import "core:image"

// when #config(TRACY_ENABLE, false) { import tracy "shared:odin-tracy" }

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


// General I/O context for ZLIB, LZW, etc.
Context :: struct #packed {
	input:             io.Stream,
	input_data:        []u8,

	output:            io.Stream,
	output_buf:        [dynamic]u8,
	bytes_written:     i64,

	/*
		If we know the data size, we can optimize the reads and writes.
	*/    
	size_packed:   i64,
	size_unpacked: i64,

	/*
		Used to update hash as we write instead of all at once.
	*/
	rolling_hash:  u32,
	/*
		Reserved
	*/
	reserved:      [2]u32,
	/*
		Flags:
			`input_fully_in_memory` tells us whether we're EOF when `input_data` is empty.
			`input_refills_from_stream` tells us we can then possibly refill from the stream.
	*/
	input_fully_in_memory: b8,
	input_refills_from_stream: b8,
	reserved_flags: [2]b8,
}
#assert(size_of(Context) == 128);

/*
	Compression algorithm context
*/
Code_Buffer :: struct #packed {
	code_buffer: u64,
	num_bits:    u64,
	/*
		Sliding window buffer. Size must be a power of two.
	*/
	window_mask: i64,
	last:        [dynamic]u8,
}
#assert(size_of(Code_Buffer) == 64);

// Stream helpers
/*
	TODO: These need to be optimized.

	Streams should really only check if a certain method is available once, perhaps even during setup.

	Bit and byte readers may be merged so that reading bytes will grab them from the bit buffer first.
	This simplifies end-of-stream handling where bits may be left in the bit buffer.
*/

@(optimization_mode="speed")
read_slice :: #force_inline proc(z: ^Context, size: int) -> (res: []u8, err: io.Error) {
	when #config(TRACY_ENABLE, false) { tracy.ZoneN("Read Slice"); }

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
	when #config(TRACY_ENABLE, false) { tracy.ZoneN("Read Data"); }

	b, e := read_slice(z, size_of(T));
	if e == .None {
		return (^T)(&b[0])^, .None;
	}

	return T{}, e;
}

@(optimization_mode="speed")
read_u8 :: #force_inline proc(z: ^Context) -> (res: u8, err: io.Error) {
	when #config(TRACY_ENABLE, false) { tracy.ZoneN("Read u8"); }

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
	when #config(TRACY_ENABLE, false) { tracy.ZoneN("Peek Data"); }

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
peek_back_byte :: #force_inline proc(cb: ^Code_Buffer, offset: i64) -> (res: u8, err: io.Error) {
	// Look back into the sliding window.
	return cb.last[offset & cb.window_mask], .None;
}

// Generalized bit reader LSB
@(optimization_mode="speed")
refill_lsb :: proc(z: ^Context, cb: ^Code_Buffer, width := i8(24)) {
	when #config(TRACY_ENABLE, false) { tracy.ZoneN("Refill LSB"); }

	refill := u64(width);

	for {
		if cb.num_bits > refill {
			break;
		}
		if cb.code_buffer == 0 && cb.num_bits > 63 {
			cb.num_bits = 0;
		}
		if cb.code_buffer >= 1 << uint(cb.num_bits) {
			// Code buffer is malformed.
			cb.num_bits = max(u64);
			return;
		}
		b, err := read_u8(z);
		if err != .None {
			// This is fine at the end of the file.
			return;
		}
		cb.code_buffer |= (u64(b) << u8(cb.num_bits));
		cb.num_bits += 8;
	}
}

@(optimization_mode="speed")
consume_bits_lsb :: #force_inline proc(cb: ^Code_Buffer, width: u8) {
	cb.code_buffer >>= width;
	cb.num_bits -= u64(width);
}

@(optimization_mode="speed")
peek_bits_lsb :: #force_inline proc(z: ^Context, cb: ^Code_Buffer, width: u8) -> u32 {
	if cb.num_bits < u64(width) {
		refill_lsb(z, cb);
	}
	// assert(z.num_bits >= i8(width));
	return u32(cb.code_buffer & ~(~u64(0) << width));
}

@(optimization_mode="speed")
peek_bits_no_refill_lsb :: #force_inline proc(z: ^Context, cb: ^Code_Buffer, width: u8) -> u32 {
	assert(cb.num_bits >= u64(width));
	return u32(cb.code_buffer & ~(~u64(0) << width));
}

@(optimization_mode="speed")
read_bits_lsb :: #force_inline proc(z: ^Context, cb: ^Code_Buffer, width: u8) -> u32 {
	k := peek_bits_lsb(z, cb, width);
	consume_bits_lsb(cb, width);
	return k;
}

@(optimization_mode="speed")
read_bits_no_refill_lsb :: #force_inline proc(z: ^Context, cb: ^Code_Buffer, width: u8) -> u32 {
	k := peek_bits_no_refill_lsb(z, cb, width);
	consume_bits_lsb(cb, width);
	return k;
}

@(optimization_mode="speed")
discard_to_next_byte_lsb :: proc(cb: ^Code_Buffer) {
	discard := u8(cb.num_bits & 7);
	consume_bits_lsb(cb, discard);
}
