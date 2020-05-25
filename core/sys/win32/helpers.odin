// +build windows
package win32

import "core:strings";

call_external_process :: proc(program, command_line: string) -> bool {
    si := STARTUPINFO{ cb=size_of(STARTUPINFO) };
    pi := PROCESS_INFORMATION{};

    return cast(bool)CreateProcessW(
        utf8_to_wstring(program),
        utf8_to_wstring(command_line),
        nil,
        nil,
        BOOL(false),
        u32(0x10),
        nil,
        nil,
        &si,
        &pi
    );
}

open_website :: proc(url: string) -> bool {
	p :: "C:\\Windows\\System32\\cmd.exe";
	arg := []string{"/C", "start", url};
	args := strings.join(arg, " ", context.temp_allocator);
	return call_external_process(p, args);
}