// Boilerplate for tests
package common

import "core:testing"
import "core:fmt"
import "core:os"

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
			fmt.printf("[%v] FAIL %s\n", loc, message)
            return
        }
        fmt.printf("[%v] PASS\n", loc)
    }
    log     :: proc(t: ^testing.T, v: any, loc := #caller_location) {
        fmt.printf("[%v]", loc)
        fmt.printf(" log: %v\n", v)
    }
}

report :: proc(t: ^testing.T) {
	if TEST_fail > 0 {
		if TEST_fail > 1 {
			fmt.printf("%v/%v tests successful, %v tests failed.\n", TEST_count - TEST_fail, TEST_count, TEST_fail)
		} else {
			fmt.printf("%v/%v tests successful, %v test failed.\n", TEST_count - TEST_fail, TEST_count, TEST_fail)
		}
		os.exit(1)
	} else {
		fmt.printf("%v/%v tests successful.\n", TEST_count, TEST_count)
	}
}
