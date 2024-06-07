package test_internal

import "core:fmt"
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
		testing.expectf(t, checksum == 0, "Expected g_b to be zero-initialized, got %v", g_b)
	}
	{
		checksum := 0
		for v, i in l_b {
			checksum += (i+1) * int(v)
		}
		testing.expectf(t, checksum == 0, "Expected l_b to be zero-initialized, got %v", l_b)
	}

	testing.expectf(t, size_of(Buggy_Struct) == 40, "Expected size_of(Buggy_Struct) == 40, got %v", size_of(Buggy_Struct))
	testing.expectf(t, size_of(g_buggy)      == 40, "Expected size_of(g_buggy) == 40, got %v", size_of(g_buggy))
	testing.expectf(t, size_of(l_buggy)      == 40, "Expected size_of(l_buggy) == 40, got %v", size_of(l_buggy))

	g_s := fmt.tprintf("%s", g_buggy)
	l_s := fmt.tprintf("%s", l_buggy)
	testing.expectf(t, g_s == EXPECTED_REPR, "Expected fmt.tprintf(\"%%s\", g_s)) to return \"%v\", got \"%v\"", EXPECTED_REPR, g_s)
	testing.expectf(t, l_s == EXPECTED_REPR, "Expected fmt.tprintf(\"%%s\", l_s)) to return \"%v\", got \"%v\"", EXPECTED_REPR, l_s)
}
