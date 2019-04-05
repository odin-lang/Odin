// +build windows
package win32

import "core:strings";

call_external_process :: proc(program, command_line: string) -> bool {

	si := Startup_Info{};
	pi := Process_Information{};
	si.cb = size_of(si);

	p := utf8_to_wstring(program);
	c := utf8_to_wstring(command_line);

	ret := create_process_w(
		p,
		c,
		nil,
		nil,
		Bool(false),
		u32(0x10), // Create New Console
		nil,
		nil,
		&si,
		&pi
	);
    return cast(bool)ret;
}

open_website :: proc(url: string) -> bool {
	p :: "C:\\Windows\\System32\\cmd.exe";
	arg := []string{"/C", "start", url};
	args := strings.join(arg, " ", context.temp_allocator);
	return call_external_process(p, args);
}