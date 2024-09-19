#+private
#+no-instrumentation
package runtime

foreign import kernel32 "system:Kernel32.lib"

@(private)
foreign kernel32 {
	RaiseException :: proc "system" (dwExceptionCode, dwExceptionFlags, nNumberOfArguments: u32, lpArguments: ^uint) -> ! ---
}

windows_trap_array_bounds :: proc "contextless" () -> ! {
	EXCEPTION_ARRAY_BOUNDS_EXCEEDED :: 0xC000008C


	RaiseException(EXCEPTION_ARRAY_BOUNDS_EXCEEDED, 0, 0, nil)
}

windows_trap_type_assertion :: proc "contextless" () -> ! {
	windows_trap_array_bounds()
}

when ODIN_NO_CRT {
	@(require)
	foreign import crt_lib "procs_windows_amd64.asm"
}
