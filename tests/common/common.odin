// Boilerplate for tests
package common

import "core:testing"
import "core:fmt"
import "core:os"
import "core:strings"


expect  :: testing.expect
log     :: testing.log

// Returns absolute path to `sub_path` where `sub_path` is within the "tests/" sub-directory of the Odin project root
// and we're being run from the Odin project root or from a sub-directory of "tests/"
// e.g. get_data_path("assets/blah") will return "/Odin_root/tests/assets/blah" if run within "/Odin_root",
// "/Odin_root/tests" or "/Odin_root/tests/subdir" etc
get_data_path :: proc(t: ^testing.T, sub_path: string) -> (data_path: string) {

	cwd := os.get_current_directory()
	defer delete(cwd)

	when ODIN_OS == .Windows {
		norm, was_allocation := strings.replace_all(cwd, "\\", "/")
		if !was_allocation {
			norm = strings.clone(norm)
		}
		defer delete(norm)
	} else {
		norm := cwd
	}

	last_index := strings.last_index(norm, "/tests/")
	if last_index == -1 {
		len := len(norm)
		if len >= 6 && norm[len-6:] == "/tests" {
			data_path = fmt.tprintf("%s/%s", norm, sub_path)
		} else {
			data_path = fmt.tprintf("%s/tests/%s", norm, sub_path)
		}
	} else {
		data_path = fmt.tprintf("%s/tests/%s", norm[:last_index], sub_path)
	}

	return data_path
}
