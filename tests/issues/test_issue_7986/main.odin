// Tests issue #7986 https://github.com/odin-lang/Odin/issues/7986 (shared libraries using the main program's globals)
package test_issue_7986

import common "common"
import dynlib "core:dynlib"
import testing "core:testing"

@(test)
test_issue_7986 :: proc(t: ^testing.T) {
	lib, ok := dynlib.load_library("./test_issue_7986_lib." + dynlib.LIBRARY_FILE_EXTENSION)
	if !testing.expect(t, ok, "could not load test_issue_7986_lib") {
		return
	}
	defer dynlib.unload_library(lib)

	addr, found := dynlib.symbol_address(lib, "lib_counter")
	if !testing.expect(t, found, "could not find lib_counter") {
		return
	}
	lib_counter := cast(proc "c" () -> int)addr

	// Each image runs its own `@(init)` once, on its own copy of the global
	testing.expect_value(t, lib_counter(), 1)
	testing.expect_value(t, common.get(), 1)
}
