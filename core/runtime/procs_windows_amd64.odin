//+private
package runtime

foreign import kernel32 "system:Kernel32.lib"

@(private)
foreign kernel32 {
	RaiseException :: proc "stdcall" (dwExceptionCode, dwExceptionFlags, nNumberOfArguments: u32, lpArguments: ^uint) -> ! ---
}

windows_trap_array_bounds :: proc "contextless" () -> ! {
	EXCEPTION_ARRAY_BOUNDS_EXCEEDED :: 0xC000008C


	RaiseException(EXCEPTION_ARRAY_BOUNDS_EXCEEDED, 0, 0, nil)
}

windows_trap_type_assertion :: proc "contextless" () -> ! {
	windows_trap_array_bounds()
}

when ODIN_NO_CRT {
	@private
	@(link_name="_tls_index")
	_tls_index: u32

	@private
	@(link_name="_fltused")
	_fltused: i32 = 0x9875
}