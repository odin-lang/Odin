package tests_core_os_os2

import os "core:os/os2"
import    "core:log"
import    "core:path/filepath"
import    "core:testing"
import    "core:strings"

@(test)
test_executable :: proc(t: ^testing.T) {
	path, err := os.get_executable_path(context.allocator)
	defer delete(path)

	log.infof("executable path: %q", path)

	// NOTE: some sanity checks that should always be the case, at least in the CI.

	testing.expect_value(t, err, nil)
	testing.expect(t, len(path) > 0)
	testing.expect(t, filepath.is_abs(path))
	testing.expectf(t, strings.contains(path, filepath.base(os.args[0])), "expected the executable path to contain the base of os.args[0] which is %q", filepath.base(os.args[0]))
}
