package test_core_dynlib

import "core:dynlib"
import "core:log"
import win32 "core:sys/windows"
import "core:testing"

Gdi_Table :: struct {
	__handle:     dynlib.Library,
	GradientFill: rawptr,
}

Gdi_No_Handle :: struct {
	not_in_msimg32: rawptr,
}

@(test)
test_dynlib_reload_keeps_one_reference :: proc(t: ^testing.T) {
	name: cstring16 = "msimg32.dll"
	if win32.GetModuleHandleW(name) != nil {
		log.info("msimg32.dll is already loaded; skipping")
		return
	}

	tbl: Gdi_Table
	count, ok := dynlib.initialize_symbols(&tbl, "msimg32.dll")
	testing.expect_value(t, count, 1)
	testing.expect(t, ok)

	count, ok = dynlib.initialize_symbols(&tbl, MISSING_LIB)
	testing.expect_value(t, count, -1)
	testing.expect(t, !ok)
	testing.expect(t, win32.GetModuleHandleW(name) != nil)

	count, ok = dynlib.initialize_symbols(&tbl, "msimg32.dll")
	testing.expect_value(t, count, 1)
	testing.expect(t, ok)
	testing.expect(t, tbl.GradientFill != nil)

	testing.expect(t, dynlib.unload_library(tbl.__handle))
	testing.expect(t, win32.GetModuleHandleW(name) == nil)

	unused: Gdi_No_Handle
	count, ok = dynlib.initialize_symbols(&unused, "msimg32.dll")
	testing.expect_value(t, count, 0)
	testing.expect(t, !ok)
	testing.expect(t, win32.GetModuleHandleW(name) == nil)
}
