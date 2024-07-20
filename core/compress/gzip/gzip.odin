package compress_gzip

/*
	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-3 license.

	List of contributors:
		Jeroen van Rijn: Initial implementation.

	This package implements support for the GZIP file format v4.3,
	as specified in RFC 1952.

	It is implemented in such a way that it lends itself naturally
	to be the input to a complementary TAR implementation.
*/

import "core:compress/zlib"
import "core:compress"
import "core:os"
import "core:io"
import "core:bytes"
import "core:hash"

Magic :: enum u16le {
	GZIP = 0x8b << 8 | 0x1f,
}

Header :: struct #packed {
	magic: Magic,
	compression_method: Compression,
	flags: Header_Flags,
	modification_time: u32le,
	xfl: Compression_Flags,
	os: OS,
}
#assert(size_of(Header) == 10)

Header_Flag :: enum u8 {
	// Order is important
	text       = 0,
	header_crc = 1,
	extra      = 2,
	name       = 3,
	comment    = 4,
	reserved_1 = 5,
	reserved_2 = 6,
	reserved_3 = 7,
}
Header_Flags :: distinct bit_set[Header_Flag; u8]

OS :: enum u8 {
	FAT          = 0,
	Amiga        = 1,
	VMS          = 2,
	Unix         = 3,
	VM_CMS       = 4,
	Atari_TOS    = 5,
	HPFS         = 6,
	Macintosh    = 7,
	Z_System     = 8,
	CP_M         = 9,
	TOPS_20      = 10,
	NTFS         = 11,
	QDOS         = 12,
	Acorn_RISCOS = 13,
	_Unknown     = 14,
	Unknown      = 255,
}
OS_Name :: #sparse[OS]string{
	._Unknown     = "",
	.FAT          = "FAT",
	.Amiga        = "Amiga",
	.VMS          = "VMS/OpenVMS",
	.Unix         = "Unix",
	.VM_CMS       = "VM/CMS",
	.Atari_TOS    = "Atari TOS",
	.HPFS         = "HPFS",
	.Macintosh    = "Macintosh",
	.Z_System     = "Z-System",
	.CP_M         = "CP/M",
	.TOPS_20      = "TOPS-20",
	.NTFS         = "NTFS",
	.QDOS         = "QDOS",
	.Acorn_RISCOS = "Acorn RISCOS",
	.Unknown      = "Unknown",
}

Compression :: enum u8 {
	DEFLATE = 8,
}

Compression_Flags :: enum u8 {
	Maximum_Compression = 2,
	Fastest_Compression = 4,
}

Error     :: compress.Error
E_General :: compress.General_Error
E_GZIP    :: compress.GZIP_Error
E_ZLIB    :: compress.ZLIB_Error
E_Deflate :: compress.Deflate_Error

GZIP_MAX_PAYLOAD_SIZE :: i64(max(u32le))

load :: proc{load_from_bytes, load_from_file, load_from_context}

load_from_file :: proc(filename: string, buf: ^bytes.Buffer, expected_output_size := -1, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	data, ok := os.read_entire_file(filename)
	defer delete(data)

	err = E_General.File_Not_Found
	if ok {
		err = load_from_bytes(data, buf, len(data), expected_output_size)
	}
	return
}

load_from_bytes :: proc(data: []byte, buf: ^bytes.Buffer, known_gzip_size := -1, expected_output_size := -1, allocator := context.allocator) -> (err: Error) {
	buf := buf

	z := &compress.Context_Memory_Input{
		input_data = data,
		output = buf,
	}
	return load_from_context(z, buf, known_gzip_size, expected_output_size, allocator)
}

load_from_context :: proc(z: ^$C, buf: ^bytes.Buffer, known_gzip_size := -1, expected_output_size := -1, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator
	buf := buf
	expected_output_size := expected_output_size

	input_data_consumed := 0

	z.output = buf

	if i64(expected_output_size) > i64(GZIP_MAX_PAYLOAD_SIZE) {
		return E_GZIP.Payload_Size_Exceeds_Max_Payload
	}

	if expected_output_size > compress.COMPRESS_OUTPUT_ALLOCATE_MAX {
		return E_GZIP.Output_Exceeds_COMPRESS_OUTPUT_ALLOCATE_MAX
	}

	b: []u8

	header, e := compress.read_data(z, Header)
	if e != .None {
		return E_General.File_Too_Short
	}
	input_data_consumed += size_of(Header)

	if header.magic != .GZIP {
		return E_GZIP.Invalid_GZIP_Signature
	}
	if header.compression_method != .DEFLATE {
		return E_General.Unknown_Compression_Method
	}

	if header.os >= ._Unknown {
		header.os = .Unknown
	}

	if .reserved_1 in header.flags || .reserved_2 in header.flags || .reserved_3 in header.flags {
		return E_GZIP.Reserved_Flag_Set
	}

	// printf("signature: %v\n", header.magic);
	// printf("compression: %v\n", header.compression_method);
	// printf("flags: %v\n", header.flags);
	// printf("modification time: %v\n", time.unix(i64(header.modification_time), 0));
	// printf("xfl: %v (%v)\n", header.xfl, int(header.xfl));
	// printf("os: %v\n", OS_Name[header.os]);

	if .extra in header.flags {
		xlen, e_extra := compress.read_data(z, u16le)
		input_data_consumed += 2

		if e_extra != .None {
			return E_General.Stream_Too_Short
		}
		// printf("Extra data present (%v bytes)\n", xlen);
		if xlen < 4 {
			// Minimum length is 2 for ID + 2 for a field length, if set to zero.
			return E_GZIP.Invalid_Extra_Data
		}

		field_id:     [2]u8
		field_length: u16le
		field_error: io.Error

		for xlen >= 4 {
			// println("Parsing Extra field(s).");
			field_id, field_error = compress.read_data(z, [2]u8)
			if field_error != .None {
				// printf("Parsing Extra returned: %v\n", field_error);
				return E_General.Stream_Too_Short
			}
			xlen -= 2
			input_data_consumed += 2

			field_length, field_error = compress.read_data(z, u16le)
			if field_error != .None {
				// printf("Parsing Extra returned: %v\n", field_error);
				return E_General.Stream_Too_Short
			}
			xlen -= 2
			input_data_consumed += 2

			if xlen <= 0 {
				// We're not going to try and recover by scanning for a ZLIB header.
				// Who knows what else is wrong with this file.
				return E_GZIP.Invalid_Extra_Data
			}

			// printf("    Field \"%v\" of length %v found: ", string(field_id[:]), field_length);
			if field_length > 0 {
				b, field_error = compress.read_slice(z, int(field_length))
				if field_error != .None {
					// printf("Parsing Extra returned: %v\n", field_error);
					return E_General.Stream_Too_Short
				}
				xlen -= field_length
				input_data_consumed += int(field_length)

				// printf("%v\n", string(field_data));
			}

			if xlen != 0 {
				return E_GZIP.Invalid_Extra_Data
			}
		}
	}

	if .name in header.flags {
		// Should be enough.
		name: [1024]u8
		i := 0
		name_error: io.Error

		for i < len(name) {
			b, name_error = compress.read_slice(z, 1)
			if name_error != .None {
				return E_General.Stream_Too_Short
			}
			input_data_consumed += 1
			if b[0] == 0 {
				break
			}
			name[i] = b[0]
			i += 1
			if i >= len(name) {
				return E_GZIP.Original_Name_Too_Long
			}
		}
		// printf("Original filename: %v\n", string(name[:i]));
	}

	if .comment in header.flags {
		// Should be enough.
		comment: [1024]u8
		i := 0
		comment_error: io.Error

		for i < len(comment) {
			b, comment_error = compress.read_slice(z, 1)
			if comment_error != .None {
				return E_General.Stream_Too_Short
			}
			input_data_consumed += 1
			if b[0] == 0 {
				break
			}
			comment[i] = b[0]
			i += 1
			if i >= len(comment) {
				return E_GZIP.Comment_Too_Long
			}
		}
		// printf("Comment: %v\n", string(comment[:i]));
	}

	if .header_crc in header.flags {
		crc_error: io.Error
		_, crc_error = compress.read_slice(z, 2)
		input_data_consumed += 2
		if crc_error != .None {
			return E_General.Stream_Too_Short
		}
		/*
			We don't actually check the CRC16 (lower 2 bytes of CRC32 of header data until the CRC field).
			If we find a gzip file in the wild that sets this field, we can add proper support for it.
		*/
	}

	/*
		We should have arrived at the ZLIB payload.
	*/
	payload_u32le: u32le

	// fmt.printf("known_gzip_size: %v | expected_output_size: %v\n", known_gzip_size, expected_output_size);

	if expected_output_size > -1 {
		/*
			We already checked that it's not larger than the output buffer max,
			or GZIP length field's max.

			We'll just pass it on to `zlib.inflate_raw`;
		*/
	} else {
		/*
			If we know the size of the GZIP file *and* it is fully in memory,
			then we can peek at the unpacked size at the end.

			We'll still want to ensure there's capacity left in the output buffer when we write, of course.

		*/
		if known_gzip_size > -1 {
			offset := i64(known_gzip_size - input_data_consumed - 4)
			size, _ := compress.input_size(z)
			if size >= offset + 4 {
				length_bytes         := z.input_data[offset:][:4]
				payload_u32le         = (^u32le)(&length_bytes[0])^
				expected_output_size = int(payload_u32le)
			}
		} else {
			/*
				TODO(Jeroen): When reading a GZIP from a stream, check if impl_seek is present.
				If so, we can seek to the end, grab the size from the footer, and seek back to payload start.
			*/
		}
	}

	// fmt.printf("GZIP: Expected Payload Size: %v\n", expected_output_size);

	zlib.inflate_raw(z, expected_output_size=expected_output_size) or_return

	/*
		Read CRC32 using the ctx bit reader because zlib may leave bytes in there.
	*/
	compress.discard_to_next_byte_lsb(z)

	footer_error: io.Error

	payload_crc_b: [4]u8
	for _, i in payload_crc_b {
		payload_crc_b[i], footer_error = compress.read_u8_prefer_code_buffer_lsb(z)
	}
	payload_crc := transmute(u32le)payload_crc_b

	payload := bytes.buffer_to_bytes(buf)
	crc32   := u32le(hash.crc32(payload))
	if crc32 != payload_crc {
		return E_GZIP.Payload_CRC_Invalid
	}

	payload_len_b: [4]u8
	for _, i in payload_len_b {
		payload_len_b[i], footer_error = compress.read_u8_prefer_code_buffer_lsb(z)
	}
	payload_len := transmute(u32le)payload_len_b

	if len(payload) != int(payload_len) {
		return E_GZIP.Payload_Length_Invalid
	}
	return nil
}
