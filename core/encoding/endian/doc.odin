/*
    Package endian implements a simple translation between bytes and numbers with
    specific endian encodings.

Example:
	buf: [100]u8
	put_u16(buf[:], .Little, 16) or_return

	// You may ask yourself, why isn't `byte_order` platform Endianness by default, so we can write:
	put_u16(buf[:], 16) or_return

	// The answer is that very few file formats are written in native/platform endianness. Most of them specify the endianness of
	// each of their fields, or use a header field which specifies it for the entire file.

	// e.g. a file which specifies it at the top for all fields could do this:
	file_order := .Little if buf[0] == 0 else .Big
	field := get_u16(buf[1:], file_order) or_return

	// If on the other hand a field is *always* Big-Endian, you're wise to explicitly state it for the benefit of the reader,
	// be that your future self or someone else.

	field := get_u16(buf[:], .Big) or_return
*/
package encoding_endian
