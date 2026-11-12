// An implementation of the GZIP wrapper over the Deflate algorith.
// Deprecated, folded into `core:compress/deflate`.
package compress_gzip

/*
	Copyright 2021-2026 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's license.

	List of contributors:
		Jeroen van Rijn: Initial implementation.

	This package implements support for the GZIP file format v4.3,
	as specified in RFC 1952.

	It is implemented in such a way that it lends itself naturally
	to be the input to a complementary TAR implementation.
*/

import "core:compress"
import "core:compress/deflate"
import "core:os"
import "core:bytes"

Magic             :: deflate.Gzip_Magic
Header            :: deflate.Gzip_Header
Header_Flag       :: deflate.Gzip_Header_Flag
Header_Flags      :: deflate.Gzip_Header_Flags
OS                :: deflate.Gzip_OS
OS_Name           :: deflate.GZIP_OS_NAME
Compression       :: deflate.Gzip_Compression
Compression_Flags :: deflate.Gzip_Compression_Flags

Error     :: compress.Error
E_General :: compress.General_Error
E_GZIP    :: compress.GZIP_Error
E_ZLIB    :: compress.ZLIB_Error
E_Deflate :: compress.Deflate_Error

GZIP_MAX_PAYLOAD_SIZE :: deflate.GZIP_MAX_PAYLOAD_SIZE

load :: proc{load_from_bytes, load_from_file, load_from_context}

@(deprecated="Use `os.read_entire_file` and `deflate.inflate_gzip` from `core:compress/deflate`")
load_from_file :: proc(filename: string, output: ^bytes.Buffer, expected_output_size := -1, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	file_data, file_err := os.read_entire_file(filename, allocator)
	defer delete(file_data)

	if file_err != nil {
		return E_General.File_Not_Found
	}
	return deflate.inflate_gzip_from_bytes(&output.buf, file_data, expected_output_size, allocator=allocator)
}

@(deprecated="Use `deflate.inflate_gzip` from `core:compress/deflate`")
load_from_bytes :: proc(data: []byte, output: ^bytes.Buffer, known_gzip_size := -1, expected_output_size := -1, allocator := context.allocator) -> (err: Error) {
	return deflate.inflate_gzip_from_bytes(&output.buf, data, expected_output_size, allocator=allocator)
}

@(deprecated="Use `deflate.inflate_gzip` from `core:compress/deflate`")
load_from_context :: proc(z: ^compress.Context, known_gzip_size := -1, allocator := context.allocator) -> (err: Error) {
	return deflate.inflate_gzip_from_context(z, int(z.size_unpacked), allocator=allocator)
}
