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
	when ODIN_CODEPAGE_MAGIC {
		SetConsoleOutputCP(old_console_codepage)
	}
	RaiseException(EXCEPTION_ARRAY_BOUNDS_EXCEEDED, 0, 0, nil)
}

windows_trap_type_assertion :: proc "contextless" () -> ! {
	windows_trap_array_bounds()
}

when ODIN_NO_CRT {
	@(export, link_name="_tls_index", private="file")
	_tls_index: u32 = 0

	@(export, link_name="_fltused", private="file")
	_fltused: u32 = 0x9875

	@(export, link_name="__chkstk", private="file")
	__chkstk :: proc "naked" () {
		internal :: asm() {
			// Allocate 16 bytes to store values of r10 and r11
			sub   %rsp, 0x10
			mov   [%rsp], %r10
			mov   [%rsp + 0x8], %r11
			// Set r10 to point to the stack as of the moment of the function call
			lea   %r10, [%rsp+0x18]
			// Subtract r10 til the bottom of the stack allocation, if we overflow
			// reset r10 to 0, we'll crash with segfault anyway
			xor   %r11, %r11
			sub   %r10, %rax
			cmovb %r10, %r11
			// Load r11 with the bottom of the stack (lowest allocated address)
			mov   %r11, [%gs:0x10]
			// If the bottom of the allocation is above the bottom of the stack,
			// we don't need to probe
			cmp   %r10, %r11
			jnb   .end
			// Align the bottom of the allocation down to page size
			and   %r10w, 0xf000
		.loop:
			// Move the pointer to the next guard page, and touch it by loading 0
			// into that page
			lea   %r11, [%r11 - 0x1000]
			mov   [%r11]:u8, 0x0
			// Did we reach the bottom of the allocation?
			cmp   %r10, %r11
			jnz   .loop
		.end:
			// Restore previous r10 and r11 and return
			mov   %r10, [%rsp]
			mov   %r11, [%rsp + 0x8]
			add   %rsp, 0x10
			ret
		}

		internal()
	}
	// @(require)
	// foreign import crt_lib "procs_windows_amd64.asm"
}
