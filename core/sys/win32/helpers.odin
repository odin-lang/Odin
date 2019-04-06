// +build windows
package win32

import "core:strings";

call_external_process :: proc(program, command_line: string) -> bool {
    si := Startup_Info{ cb=size_of(Startup_Info) };
    pi := Process_Information{};

    return cast(bool)create_process_w(
        utf8_to_wstring(program),
        utf8_to_wstring(command_line),
        nil, 
        nil, 
        Bool(false), 
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