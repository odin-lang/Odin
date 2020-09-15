package runtime

import "core:os"

current_thread_id :: proc "contextless" () -> int {
	return os.current_thread_id();
}

default_assertion_failure_proc :: proc(prefix, message: string, loc: Source_Code_Location) {
	fd := os.stderr;
	print_caller_location(fd, loc);
	os.write_string(fd, " ");
	os.write_string(fd, prefix);
	if len(message) > 0 {
		os.write_string(fd, ": ");
		os.write_string(fd, message);
	}
	os.write_byte(fd, '\n');
	debug_trap();
}

