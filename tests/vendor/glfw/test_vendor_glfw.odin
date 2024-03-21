package test_vendor_glfw

import "core:testing"
import "core:fmt"
import "vendor:glfw"
import "core:os"

GLFW_MAJOR :: 3
GLFW_MINOR :: 4
GLFW_PATCH :: 0

TEST_count := 0
TEST_fail  := 0

when ODIN_TEST {
	expect  :: testing.expect
	log     :: testing.log
} else {
	expect :: proc(t: ^testing.T, condition: bool, message: string, loc := #caller_location) {
		fmt.printf("[%v] ", loc)
		TEST_count += 1
		if !condition {
			TEST_fail += 1
			fmt.println(message)
			return
		}
		fmt.println(" PASS")
	}
	log :: proc(t: ^testing.T, v: any, loc := #caller_location) {
		fmt.printf("[%v] ", loc)
		fmt.printf("log: %v\n", v)
	}
}

main :: proc() {
	t := testing.T{}
	test_glfw(&t)

	fmt.printf("%v/%v tests successful.\n", TEST_count - TEST_fail, TEST_count)
	if TEST_fail > 0 {
		os.exit(1)
	}
}

@(test)
test_glfw :: proc(t: ^testing.T) {
	major, minor, patch := glfw.GetVersion()
	expect(t, major == GLFW_MAJOR && minor == GLFW_MINOR, fmt.tprintf("Expected GLFW.GetVersion: %v.%v.%v, got %v.%v.%v instead", GLFW_MAJOR, GLFW_MINOR, GLFW_PATCH, major, minor, patch))
}
