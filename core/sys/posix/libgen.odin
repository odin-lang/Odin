#+build linux, darwin, netbsd, openbsd, freebsd
package posix

when ODIN_OS == .Darwin {
	foreign import lib "system:System.framework"
} else {
	foreign import lib "system:c"
}

// libgen.h - definitions for pattern matching functions

foreign lib {
	/*
	Takes the pathname pointed to by path and return a pointer to the final component of the
	pathname, deleting any trailing '/' characters.

	NOTE: may modify input, so don't give it string literals.

	Returns: a string that might be a modification of the input string or a static string overwritten by subsequent calls

	Example:
		tests := []string{
			"usr", "usr/", "", "/", "//", "///", "/usr/", "/usr/lib",
			"//usr//lib//", "/home//dwc//test",
		}

		tbl: table.Table
		table.init(&tbl)
		table.header(&tbl, "input", "dirname", "basename")

		for test in tests {
			din := strings.clone_to_cstring(test); defer delete(din)
			dir := strings.clone_from_cstring(posix.dirname(din))

			bin  := strings.clone_to_cstring(test); defer delete(bin)
			base := strings.clone_from_cstring(posix.basename(bin))
			table.row(&tbl, test, dir, base)
		}

		table.write_plain_table(os.stream_from_handle(os.stdout), &tbl)

	Output:
		+----------------+----------+--------+
		|input           |dirname   |basename|
		+----------------+----------+--------+
		|usr             |.         |usr     |
		|usr/            |.         |usr     |
		|                |.         |.       |
		|/               |/         |/       |
		|//              |/         |/       |
		|///             |/         |/       |
		|/usr/           |/         |usr     |
		|/usr/lib        |/usr      |lib     |
		|//usr//lib//    |//usr     |lib     |
		|/home//dwc//test|/home//dwc|test    |
		+----------------+----------+--------+

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/basename.html ]]
	*/
	@(link_name=LBASENAME)
	basename :: proc(path: cstring) -> cstring ---

	/*
	Takes a string that contains a pathname, and returns a string that is a pathname of the parent
	directory of that file.

	NOTE: may modify input, so don't give it string literals.

	Returns: a string that might be a modification of the input string or a static string overwritten by subsequent calls

	See example for basename().

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/dirname.html ]]
	*/
	dirname :: proc(path: cstring) -> cstring ---
}

when ODIN_OS == .Linux {
	@(private) LBASENAME :: "__xpg_basename"
} else {
	@(private) LBASENAME :: "basename"
}
