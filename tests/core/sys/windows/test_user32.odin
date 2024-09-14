#+build windows
package test_core_sys_windows

import "core:testing"
import win32 "core:sys/windows"

@(test)
verify_rawinput_code :: proc(t: ^testing.T) {
	testing.expect_value(t, win32.GET_RAWINPUT_CODE_WPARAM(0), win32.RAWINPUT_CODE.RIM_INPUT)
	testing.expect_value(t, win32.GET_RAWINPUT_CODE_WPARAM(1), win32.RAWINPUT_CODE.RIM_INPUTSINK)
	testing.expect_value(t, win32.GET_RAWINPUT_CODE_WPARAM(0x100), win32.RAWINPUT_CODE.RIM_INPUT)
	testing.expect_value(t, win32.GET_RAWINPUT_CODE_WPARAM(0x101), win32.RAWINPUT_CODE.RIM_INPUTSINK)
}
