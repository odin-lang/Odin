package test_core_dynlib

import "core:dynlib"
import "core:strings"
import "core:testing"

when ODIN_OS == .Windows {
	LIB :: "kernel32.dll"
	Table :: struct {
		__handle: dynlib.Library,
		missing:  rawptr,
		pid:      proc "system" () -> u32 `dynlib:"GetCurrentProcessId"`,
	}
} else {
	when ODIN_OS == .Darwin {
		LIB :: "/usr/lib/libSystem.B.dylib"
	} else when ODIN_OS == .Linux {
		LIB :: "libc.so.6"
	} else when ODIN_OS == .FreeBSD {
		LIB :: "libc.so.7"
	} else when ODIN_OS == .NetBSD {
		LIB :: "libc.so.12"
	} else when ODIN_OS == .OpenBSD {
		LIB :: "libc.so"
	}
	Table :: struct {
		__handle: dynlib.Library,
		missing:  rawptr,
		pid:      proc "c" () -> i32 `dynlib:"getpid"`,
	}
}

MISSING_LIB :: "odin_dynlib_test_missing." + dynlib.LIBRARY_FILE_EXTENSION

@(test)
test_dynlib_long_missing_name_then_short :: proc(t: ^testing.T) {
	tbl: Table
	prefix := strings.repeat("x", 2040, context.temp_allocator)
	count, ok := dynlib.initialize_symbols(&tbl, LIB, prefix)
	testing.expect_value(t, count, 1)
	testing.expect(t, ok)
	testing.expect(t, tbl.missing == nil)
	testing.expect(t, tbl.pid != nil)
	if tbl.__handle != nil {
		testing.expect(t, dynlib.unload_library(tbl.__handle))
	}
}

@(test)
test_dynlib_failed_reload_keeps_table :: proc(t: ^testing.T) {
	tbl: Table
	count, ok := dynlib.initialize_symbols(&tbl, LIB)
	testing.expect_value(t, count, 1)
	testing.expect(t, ok)
	if !ok {
		return
	}
	old := tbl
	count, ok = dynlib.initialize_symbols(&tbl, MISSING_LIB)
	testing.expect_value(t, count, -1)
	testing.expect(t, !ok)
	testing.expect(t, tbl == old)
	testing.expect(t, tbl.pid() != 0)
	count, ok = dynlib.initialize_symbols(&tbl, LIB)
	testing.expect_value(t, count, 1)
	testing.expect(t, ok)
	testing.expect(t, tbl.__handle == old.__handle)
	testing.expect(t, tbl.pid != nil)
	testing.expect(t, dynlib.unload_library(tbl.__handle))
}
