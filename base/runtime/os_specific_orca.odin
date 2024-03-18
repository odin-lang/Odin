//+build orca
//+private
package runtime

@(private="file")
log_level :: enum i32 {
	ERROR,
	WARNING,
	INFO,
}

@(private="file", default_calling_convention="c")
foreign {
	oc_log_ext :: proc(
		level: log_level,
		function: cstring,
		file: cstring,
		line: i32,
		fmt: cstring,
		#c_vararg args: ..any,
	) ---
}

_stderr_write :: proc "contextless" (data: []byte) -> (int, _OS_Errno) {
	oc_log_ext(.ERROR, "", "", 0, "%.*s", i32(len(data)), raw_data(data))
	return len(data), 0
}
