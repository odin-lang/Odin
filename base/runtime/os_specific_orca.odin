//+build orca
//+private
package runtime

import "base:intrinsics"

// Constants allowing to specify the level of logging verbosity.
log_level :: enum u32 {
	// Only errors are logged.
	ERROR = 0,
	// Only warnings and errors are logged.
	WARNING = 1,
	// All messages are logged.
	INFO = 2,
	COUNT = 3,
}

@(default_calling_convention="c", link_prefix="oc_")
foreign {
	abort_ext   :: proc(file: cstring, function: cstring, line: i32, fmt: cstring, #c_vararg args: ..any) -> ! ---
	assert_fail :: proc(file: cstring, function: cstring, line: i32, src: cstring, fmt: cstring, #c_vararg args: ..any) -> ! ---
	log_ext     :: proc(level: log_level, function: cstring, file: cstring, line: i32, fmt: cstring, #c_vararg args: ..any) ---
}

// NOTE: This is all pretty gross, don't look.

// WASM is single threaded so this should be fine.
orca_stderr_buffer:     [4096]byte
orca_stderr_buffer_idx: int

_stderr_write :: proc "contextless" (data: []byte) -> (int, _OS_Errno) {
	for b in data {
		orca_stderr_buffer[orca_stderr_buffer_idx] = b
		orca_stderr_buffer_idx += 1

		if b == '\n' || orca_stderr_buffer_idx == len(orca_stderr_buffer)-1 {
			log_ext(.ERROR, "", "", 0, cstring(raw_data(orca_stderr_buffer[:orca_stderr_buffer_idx])))
			orca_stderr_buffer_idx = 0
		}
	}

	return len(data), 0
}
