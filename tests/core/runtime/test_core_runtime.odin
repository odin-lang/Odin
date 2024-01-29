package test_core_runtime

import "core:fmt"
import "base:intrinsics"
import "core:mem"
import "core:os"
import "core:reflect"
import "base:runtime"
import "core:testing"

TEST_count := 0
TEST_fail  := 0

when ODIN_TEST {
	expect_value :: testing.expect_value
} else {
	expect_value :: proc(t: ^testing.T, value, expected: $T, loc := #caller_location) -> bool where intrinsics.type_is_comparable(T) {
		TEST_count += 1
		ok := value == expected || reflect.is_nil(value) && reflect.is_nil(expected)
		if !ok {
			TEST_fail += 1
			fmt.printf("[%v] expected %v, got %v\n", loc, expected, value)
		}
		return ok
	}
}

main :: proc() {
	t := testing.T{}

	test_temp_allocator_big_alloc_and_alignment(&t)
	test_temp_allocator_alignment_boundary(&t)
	test_temp_allocator_returns_correct_size(&t)

	fmt.printf("%v/%v tests successful.\n", TEST_count - TEST_fail, TEST_count)
	if TEST_fail > 0 {
		os.exit(1)
	}
}

// Tests that having space for the allocation, but not for the allocation and alignment
// is handled correctly.
@(test)
test_temp_allocator_alignment_boundary :: proc(t: ^testing.T) {
	arena: runtime.Arena
	context.allocator = runtime.arena_allocator(&arena)

	_, _ = mem.alloc(int(runtime.DEFAULT_ARENA_GROWING_MINIMUM_BLOCK_SIZE)-120)
	_, err := mem.alloc(112, 32)
	expect_value(t, err, nil)
}

// Tests that big allocations with big alignments are handled correctly.
@(test)
test_temp_allocator_big_alloc_and_alignment :: proc(t: ^testing.T) {
	arena: runtime.Arena
	context.allocator = runtime.arena_allocator(&arena)

	mappy: map[[8]int]int
	err := reserve(&mappy, 50000)
	expect_value(t, err, nil)
}

@(test)
test_temp_allocator_returns_correct_size :: proc(t: ^testing.T) {
	arena: runtime.Arena
	context.allocator = runtime.arena_allocator(&arena)

	bytes, err := mem.alloc_bytes(10, 16)
	expect_value(t, err, nil)
	expect_value(t, len(bytes), 10)
}
