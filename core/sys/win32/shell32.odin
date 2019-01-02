// +build windows
package win32

foreign import "system:shell32.lib"

@(default_calling_convention = "std")
foreign shell32 {
	@(link_name="CommandLineToArgvW") command_line_to_argv_w :: proc(cmd_list: Wstring, num_args: ^i32) -> ^Wstring ---;
}
