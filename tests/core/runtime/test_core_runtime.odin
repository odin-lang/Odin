package test_core_runtime

import "base:intrinsics"
import "core:mem"
import "base:runtime"
import "core:testing"

// Tests that having space for the allocation, but not for the allocation and alignment
// is handled correctly.
@(test)
test_temp_allocator_alignment_boundary :: proc(t: ^testing.T) {
	arena: runtime.Arena
	context.allocator = runtime.arena_allocator(&arena)
	defer runtime.arena_destroy(&arena)

	_, _ = mem.alloc(int(runtime.DEFAULT_ARENA_GROWING_MINIMUM_BLOCK_SIZE)-120)
	_, err := mem.alloc(112, 32)
	testing.expect(t, err == nil)
}

// Tests that big allocations with big alignments are handled correctly.
@(test)
test_temp_allocator_big_alloc_and_alignment :: proc(t: ^testing.T) {
	arena: runtime.Arena
	context.allocator = runtime.arena_allocator(&arena)
	defer runtime.arena_destroy(&arena)

	mappy: map[[8]int]int
	err := reserve(&mappy, 50000)
	testing.expect(t, err == nil)
}

@(test)
test_temp_allocator_returns_correct_size :: proc(t: ^testing.T) {
	arena: runtime.Arena
	context.allocator = runtime.arena_allocator(&arena)
	defer runtime.arena_destroy(&arena)

	bytes, err := mem.alloc_bytes(10, 16)
	testing.expect(t, err == nil)
	testing.expect(t, len(bytes) == 10)
}

@(test)
test_init_cap_map_dynarray :: proc(t: ^testing.T) {
        m1 := make(map[int]string)
        defer delete(m1)
        testing.expect(t, cap(m1) == 0)
        testing.expect(t, m1.allocator.procedure == context.allocator.procedure)

        ally := context.temp_allocator
        m2 := make(map[int]string, ally)
        defer delete(m2)
        testing.expect(t, cap(m2) == 0)
        testing.expect(t, m2.allocator.procedure == ally.procedure)

        d1 := make([dynamic]string)
        defer delete(d1)
        testing.expect(t, cap(d1) == 0)
        testing.expect(t, d1.allocator.procedure == context.allocator.procedure)

        d2 := make([dynamic]string, ally)
        defer delete(d2)
        testing.expect(t, cap(d2) == 0)
        testing.expect(t, d2.allocator.procedure == ally.procedure)
}