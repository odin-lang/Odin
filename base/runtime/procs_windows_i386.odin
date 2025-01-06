#+private
#+no-instrumentation
package runtime

@require foreign import "system:int64.lib"

foreign import kernel32 "system:Kernel32.lib"

windows_trap_array_bounds :: proc "contextless" () -> ! {
	DWORD :: u32
	ULONG_PTR :: uint

	EXCEPTION_ARRAY_BOUNDS_EXCEEDED :: 0xC000008C

	foreign kernel32 {
		RaiseException :: proc "system" (dwExceptionCode, dwExceptionFlags, nNumberOfArguments: DWORD, lpArguments: ^ULONG_PTR) -> ! ---
	}

	RaiseException(EXCEPTION_ARRAY_BOUNDS_EXCEEDED, 0, 0, nil)
}

windows_trap_type_assertion :: proc "contextless" () -> ! {
	windows_trap_array_bounds()
}

@(private, export, link_name="_fltused") _fltused: i32 = 0x9875

@(private, export, link_name="_tls_index") _tls_index: u32
@(private, export, link_name="_tls_array") _tls_array: u32
