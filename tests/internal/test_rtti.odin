package test_internal_rtti

import "core:fmt"
import "core:mem"
import "core:os"
import "core:testing"


Buggy_Struct :: struct {
	a: int,
	b: bool,
	c: [3]^string,
}
#assert(size_of(Buggy_Struct) == 40)

g_buggy: Buggy_Struct = {}

EXPECTED_REPR := "%!s(Buggy_Struct=Buggy_Struct{a = 0, b = false, c = [0x0, 0x0, 0x0]})"

@test
rtti_test :: proc(t: ^testing.T) {
	l_buggy: Buggy_Struct = {}

	g_b := ([^]u8)(&g_buggy)[:size_of(Buggy_Struct)]
	l_b := ([^]u8)(&l_buggy)[:size_of(Buggy_Struct)]
	{
		checksum := 0
		for v, i in g_b {
			checksum += (i+1) * int(v)
		}
		expect(t, checksum == 0, fmt.tprintf("Expected g_b to be zero-initialized, got %v", g_b))
	}
	{
		checksum := 0
		for v, i in l_b {
			checksum += (i+1) * int(v)
		}
		expect(t, checksum == 0, fmt.tprintf("Expected l_b to be zero-initialized, got %v", l_b))
	}

	expect(t, size_of(Buggy_Struct) == 40, fmt.tprintf("Expected size_of(Buggy_Struct) == 40, got %v", size_of(Buggy_Struct)))
	expect(t, size_of(g_buggy)      == 40, fmt.tprintf("Expected size_of(g_buggy) == 40, got %v", size_of(g_buggy)))
	expect(t, size_of(l_buggy)      == 40, fmt.tprintf("Expected size_of(l_buggy) == 40, got %v", size_of(l_buggy)))

	g_s := fmt.tprintf("%s", g_buggy)
	l_s := fmt.tprintf("%s", l_buggy)
	expect(t, g_s == EXPECTED_REPR, fmt.tprintf("Expected fmt.tprintf(\"%%s\", g_s)) to return \"%v\", got \"%v\"", EXPECTED_REPR, g_s))
	expect(t, l_s == EXPECTED_REPR, fmt.tprintf("Expected fmt.tprintf(\"%%s\", l_s)) to return \"%v\", got \"%v\"", EXPECTED_REPR, l_s))
}

// -------- -------- -------- -------- -------- -------- -------- -------- -------- --------

main :: proc() {
	t := testing.T{}

	rtti_test(&t)

	fmt.printf("%v/%v tests successful.\n", TEST_count - TEST_fail, TEST_count)
	if TEST_fail > 0 {
		os.exit(1)
	}
}

mem_track_test :: proc(t: ^testing.T, test: proc(t: ^testing.T)) {
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	context.allocator = mem.tracking_allocator(&track)

	test(t)

	expect(t, len(track.allocation_map) == 0, "Expected no leaks.")
	expect(t, len(track.bad_free_array) == 0, "Expected no leaks.")

	for _, leak in track.allocation_map {
		fmt.printf("%v leaked %v bytes\n", leak.location, leak.size)
	}
	for bad_free in track.bad_free_array {
		fmt.printf("%v allocation %p was freed badly\n", bad_free.location, bad_free.memory)
	}
}

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