// Tests that Odin run returns exit code of built executable on Unix
// Needs exit status to be inverted to return 0 on success, e.g.
// $(./odin run tests/core/os/test_core_os_exit.odin && exit 1 || exit 0)
package test_core_os_exit

import "core:os"

main :: proc() {
	os.exit(1)
}
