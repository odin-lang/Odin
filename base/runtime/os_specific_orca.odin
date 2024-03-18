//+build orca
//+private
package runtime

@(private="file")
oc_log_level :: enum i32 {
	ERROR,
	WARNING,
	INFO,
}

@(private="file", default_calling_convention="c")
foreign {
	oc_bridge_log :: proc(
		level:       oc_log_level,
		functionLen: i32,
		function:    cstring,
		fileLen:     i32,
		file:        cstring,
		line:        i32,
		msgLen:      i32,
		msg:         [^]byte,
	) ---
}

_stderr_write :: proc "contextless" (data: []byte) -> (int, _OS_Errno) {
	oc_bridge_log(.ERROR,
	              0, "",
	              0, "",
	              0,
	              i32(len(data)), raw_data(data),
	)
	return len(data), 0
}
