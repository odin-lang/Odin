// +build windows
package win32

foreign import "system:shell32.lib"

@(default_calling_convention = "std")
foreign shell32 {
	CommandLineToArgvW :: proc(cmd_list: LPCWSTR, num_args: ^i32) -> ^LPCWSTR ---;
}

command_line_to_argv_w :: CommandLineToArgvW;
