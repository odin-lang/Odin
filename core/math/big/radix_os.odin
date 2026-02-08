#+build !freestanding
#+build !js
package math_big

/*
	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's license.

	An arbitrary precision mathematics implementation in Odin.
	For the theoretical underpinnings, see Knuth's The Art of Computer Programming, Volume 2, section 4.3.
	The code started out as an idiomatic source port of libTomMath, which is in the public domain, with thanks.

	This file contains radix conversions, `string_to_int` (atoi) and `int_to_string` (itoa).

	TODO:
		- Use Barrett reduction for non-powers-of-two.
		- Also look at extracting and splatting several digits at once.
*/

import "core:mem"
import os "core:os/os2"

/*
	We might add functions to read and write byte-encoded Ints from/to files, using `int_to_bytes_*` functions.

	LibTomMath allows exporting/importing to/from a file in ASCII, but it doesn't support a much more compact representation in binary, even though it has several pack functions int_to_bytes_* (which I expanded upon and wrote Python interoperable versions of as well), and (un)pack, which is GMP compatible.
	Someone could implement their own read/write binary int procedures, of course.

	Could be worthwhile to add a canonical binary file representation with an optional small header that says it's an Odin big.Int, big.Rat or Big.Float, byte count for each component that follows, flag for big/little endian and a flag that says a checksum exists at the end of the file.
	For big.Rat and big.Float the header couldn't be optional, because we'd have no way to distinguish where the components end.
*/

/*
	Read an Int from an ASCII file.
*/
internal_int_read_from_ascii_file :: proc(a: ^Int, filename: string, radix := i8(10), allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	/*
		We can either read the entire file at once, or read a bunch at a time and keep multiplying by the radix.
		For now, we'll read the entire file. Eventually we'll replace this with a copy that duplicates the logic
		of `atoi` so we don't need to read the entire file.
	*/
	res, res_err := os.read_entire_file(filename, allocator)
	defer delete(res, allocator)

	if res_err != nil {
		return .Cannot_Read_File
	}

	as := string(res)
	return atoi(a, as, radix)
}

/*
	Write an Int to an ASCII file.
*/
internal_int_write_to_ascii_file :: proc(a: ^Int, filename: string, radix := i8(10), allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	/*
		For now we'll convert the Int using itoa and writing the result in one go.
		If we want to preserve memory we could duplicate the itoa logic and write backwards.
	*/

	as := itoa(a, radix) or_return
	defer delete(as)

	l := len(as)
	assert(l > 0)

	data := transmute([]u8)mem.Raw_Slice{
		data = raw_data(as),
		len  = l,
	}

	write_err := os.write_entire_file(filename, data, truncate=true)
	return nil if write_err == nil else .Cannot_Write_File
}