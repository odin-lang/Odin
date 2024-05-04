// Intended to contain code that would trigger asan easily if the abi was set up badly.
package test_asan

import "core:fmt"
import "core:testing"
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
			fmt.printf("[%v] %v\n", loc, message)
			return
		}
	}
	log     :: proc(t: ^testing.T, v: any, loc := #caller_location) {
		fmt.printf("[%v] ", loc)
		fmt.printf("log: %v\n", v)
	}
}

main :: proc() {
	t := testing.T{}

	test_12_bytes(&t)
	test_12_bytes_two(&t)

	fmt.printf("%v/%v tests successful.\n", TEST_count - TEST_fail, TEST_count)
	if TEST_fail > 0 {
		os.exit(1)
	}
}

@(test)
test_12_bytes :: proc(t: ^testing.T) {
	internal :: proc() -> (a, b: f32, ok: bool) {
		return max(f32), 0, true
	}

	a, b, ok := internal()
	expect(t, a == max(f32), fmt.tprintf("a (%v) != max(f32)", a))
	expect(t, b == 0,        fmt.tprintf("b (%v) != 0", b))
	expect(t, ok,            fmt.tprintf("ok (%v) != true", ok))
}

@(test)
test_12_bytes_two :: proc(t: ^testing.T) {
	internal :: proc() -> (a: f32, b: int) {
		return 100., max(int)
	}

	a, b := internal()
	expect(t, a == 100.,     fmt.tprintf("a (%v) != 100.", a))
	expect(t, b == max(int), fmt.tprintf("b (%v) != max(int)", b))
}
