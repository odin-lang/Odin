package sys_windows

foreign import shell32 "system:Shell32.lib"

@(default_calling_convention = "std")
foreign shell32 {
	CommandLineToArgvW :: proc(cmd_list: wstring, num_args: ^c_int) -> ^wstring ---
}
