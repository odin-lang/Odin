// Boilerplate for tests
package common

import "core:testing"
import "core:fmt"
import "core:os"
import "core:strings"

TEST_count := 0
TEST_fail  := 0

when ODIN_TEST {
	expect  :: testing.expect
	log     :: testing.log
} else {
	expect  :: proc(t: ^testing.T, condition: bool, message: string, loc := #caller_location) {
		TEST_count += 1
		if !condition {
			TEST_fail += 1
			fmt.printf("[%v] FAIL %v\n", loc, message)
			return
		}
	}
	log     :: proc(t: ^testing.T, v: any, loc := #caller_location) {
		fmt.printf("[%v] ", loc)
		fmt.printf("log: %v\n", v)
	}
}

report :: proc(t: ^testing.T) {
	if TEST_fail > 0 {
		if TEST_fail > 1 {
			fmt.printf("%v/%v tests successful, %v tests failed.\n", TEST_count - TEST_fail, TEST_count, TEST_fail)
		} else {
			fmt.printf("%v/%v tests successful, 1 test failed.\n", TEST_count - TEST_fail, TEST_count)
		}
		os.exit(1)
	} else {
		fmt.printf("%v/%v tests successful.\n", TEST_count, TEST_count)
	}
}

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
