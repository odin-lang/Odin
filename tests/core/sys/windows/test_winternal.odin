#+build windows
#+build i386, amd64 // for now only supported on x86

package test_core_sys_windows

import "core:testing"
import win32 "core:sys/windows"


@(test)
test_get_teb :: proc(t: ^testing.T) {
	context_ := win32.CONTEXT { ContextFlags = win32.WOW64_CONTEXT_CONTROL }
	win32.GetThreadContext(win32.GetCurrentThread(), &context_)

	tib := win32.NtCurrentTeb().Tib
	stack_left := cast(uintptr) context_.Rsp - (cast(uintptr) tib.StackLimit)

	testing.expect(t, stack_left != 0, "stack left != 0")
}
