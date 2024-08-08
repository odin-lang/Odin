//+build windows
package test_core_sys_windows

import "core:testing"
import win32 "core:sys/windows"

@(test)
make_hresult :: proc(t: ^testing.T) {
	expect_value(t, win32.MAKE_HRESULT(win32.SEVERITY.SUCCESS, win32.FACILITY.NULL, win32.ERROR_SUCCESS), win32.S_OK)
	expect_value(t, win32.MAKE_HRESULT(win32.SEVERITY.ERROR, win32.FACILITY.NULL, 0x4001), win32.E_NOTIMPL)
	expect_value(t, win32.MAKE_HRESULT(win32.SEVERITY.ERROR, win32.FACILITY.NULL, 0x4002), win32.E_NOINTERFACE)
	expect_value(t, win32.MAKE_HRESULT(win32.SEVERITY.ERROR, win32.FACILITY.NULL, 0x4003), win32.E_POINTER)
	expect_value(t, win32.MAKE_HRESULT(win32.SEVERITY.ERROR, win32.FACILITY.NULL, 0x4004), win32.E_ABORT)
	expect_value(t, win32.MAKE_HRESULT(win32.SEVERITY.ERROR, win32.FACILITY.NULL, 0x4005), win32.E_FAIL)
	expect_value(t, win32.MAKE_HRESULT(win32.SEVERITY.ERROR, win32.FACILITY.NULL, 0xFFFF), win32.E_UNEXPECTED)

	expect_value(t, win32.MAKE_HRESULT(win32.SEVERITY.ERROR, win32.FACILITY.WIN32, win32.ERROR_ACCESS_DENIED), win32.E_ACCESSDENIED)
	expect_value(t, win32.MAKE_HRESULT(win32.SEVERITY.ERROR, win32.FACILITY.WIN32, win32.ERROR_INVALID_HANDLE), win32.E_HANDLE)
	expect_value(t, win32.MAKE_HRESULT(win32.SEVERITY.ERROR, win32.FACILITY.WIN32, win32.ERROR_OUTOFMEMORY), win32.E_OUTOFMEMORY)
	expect_value(t, win32.MAKE_HRESULT(win32.SEVERITY.ERROR, win32.FACILITY.WIN32, win32.ERROR_INVALID_PARAMETER), win32.E_INVALIDARG)

	expect_value(t, win32.MAKE_HRESULT(win32.SEVERITY.ERROR, win32.FACILITY.WIN32, win32.System_Error.ACCESS_DENIED), win32.E_ACCESSDENIED)
	expect_value(t, win32.MAKE_HRESULT(win32.SEVERITY.ERROR, win32.FACILITY.WIN32, win32.System_Error.INVALID_HANDLE), win32.E_HANDLE)
	expect_value(t, win32.MAKE_HRESULT(win32.SEVERITY.ERROR, win32.FACILITY.WIN32, win32.System_Error.OUTOFMEMORY), win32.E_OUTOFMEMORY)
	expect_value(t, win32.MAKE_HRESULT(win32.SEVERITY.ERROR, win32.FACILITY.WIN32, win32.System_Error.INVALID_PARAMETER), win32.E_INVALIDARG)
}

@(test)
decode_hresult :: proc(t: ^testing.T) {
	s, f, c := win32.DECODE_HRESULT(win32.E_INVALIDARG)
	expect_value(t, s, win32.SEVERITY.ERROR)
	expect_value(t, f, win32.FACILITY.WIN32)
	expect_value(t, c, win32.System_Error.INVALID_PARAMETER)
}
