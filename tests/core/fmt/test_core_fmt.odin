package test_core_fmt

import "core:fmt"
import "core:os"
import "core:testing"
import "core:mem"

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
	test_fmt_memory(&t)

	fmt.printf("%v/%v tests successful.\n", TEST_count - TEST_fail, TEST_count)
	if TEST_fail > 0 {
		os.exit(1)
	}
}

test_fmt_memory :: proc(t: ^testing.T) {
	check :: proc(t: ^testing.T, exp: string, format: string, args: ..any, loc := #caller_location) {
		got := fmt.tprintf(format, ..args)
		expect(t, got == exp, fmt.tprintf("(%q, %v): %q != %q", format, args, got, exp), loc)
	}

	check(t, "5b",       "%m",    5)
	check(t, "5B",       "%M",    5)
	check(t, "-5B",      "%M",    -5)
	check(t, "3.00kb",   "%m",    mem.Kilobyte * 3)
	check(t, "3kb",      "%.0m",  mem.Kilobyte * 3)
	check(t, "3KB",      "%.0M",  mem.Kilobyte * 3)
	check(t, "3.000 mb", "%#.3m", mem.Megabyte * 3)
	check(t, "3.50 gb",  "%#m",   u32(mem.Gigabyte * 3.5))
	check(t, "001tb",    "%5.0m", mem.Terabyte)
	check(t, "-01tb",    "%5.0m", -mem.Terabyte)
	check(t, "2.50 pb",  "%#5.m", uint(mem.Petabyte * 2.5))
	check(t, "1.00 EB",  "%#M",   mem.Exabyte)
	check(t, "255 B",    "%#M",   u8(255))
	check(t, "0b",       "%m",    u8(0))
}
