package posix

import "core:c"

when ODIN_OS == .Darwin {
	foreign import lib "system:System.framework"
} else {
	foreign import lib "system:c"
}

// monetary.h - monetary types

foreign lib {

	/*
	Places characters into the array pointed to by s as controlled by the string format.
	No more than maxsize bytes are placed into the array.

	Returns: -1 (setting errno) on failure, the number of bytes added to s otherwise

	Example:
		posix.setlocale(.ALL, "en_US.UTF-8")
		value := 123456.789
		buffer: [100]byte
		size := posix.strfmon(raw_data(buffer[:]), len(buffer), "%n", value)
		if int(size) == -1 {
			fmt.panicf("strfmon failure: %s", posix.strerror(posix.errno()))
		}
		fmt.println(string(buffer[:size]))

	Output:
		$123,456.79

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/strfmon.html ]]
	*/
	strfmon :: proc(
		s:              [^]byte,
		maxsize:        c.size_t,
		format:         cstring,
		#c_vararg args: ..any,
	) -> c.size_t ---
}
