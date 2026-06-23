package test_core_mem

import "core:testing"
import "core:mem"


expect_arena_allocation :: proc(t: ^testing.T, expected_used_bytes, num_bytes, alignment: int) {
	arena: mem.Dynamic_Arena
	mem.dynamic_arena_init(&arena, minimum_alignment = alignment)
	arena_allocator := mem.dynamic_arena_allocator(&arena)

	element, err := mem.alloc(num_bytes, alignment, arena_allocator)
	testing.expect(t, err == .None)
	testing.expect(t, element != nil)

	expected_bytes_left := arena.block_size - expected_used_bytes
	testing.expectf(t, arena.bytes_left == expected_bytes_left,
		`
		Allocated data with size %v bytes, expected %v bytes left, got %v bytes left, off by %v bytes.
		Pool:
		block_size           = %v
		out_band_size        = %v
		minimum_alignment    = %v
		unused_blocks        = %v
		used_blocks          = %v
		out_band_allocations = %v
		current_block        = %v
		current_pos          = %v
		bytes_left           = %v
		`,
		num_bytes, expected_bytes_left, arena.bytes_left, expected_bytes_left - arena.bytes_left,
		arena.block_size,
		arena.out_band_size,
		arena.minimum_alignment,
		arena.unused_blocks,
		arena.used_blocks,
		arena.out_band_allocations,
		arena.current_block,
		arena.current_pos,
		arena.bytes_left,
	)
	testing.expectf(t, uintptr(element) % uint(alignment) == 0, "Expected allocation to be aligned to %d byte boundary, got %v", alignment, element)

	mem.dynamic_arena_destroy(&arena)
	testing.expect(t, arena.used_blocks == nil)
}

expect_arena_allocation_out_of_band :: proc(t: ^testing.T, num_bytes, block_size, out_band_size: int) {
	testing.expect(t, num_bytes >= out_band_size, "Sanity check failed, your test call is flawed! Make sure that num_bytes >= out_band_size!")

	arena: mem.Dynamic_Arena
	mem.dynamic_arena_init(&arena, block_size = block_size, out_band_size = out_band_size)
	arena_allocator := mem.dynamic_arena_allocator(&arena)

	element, err := mem.alloc(num_bytes, allocator = arena_allocator)
	testing.expect(t, err == .None)
	testing.expect(t, element != nil)
	testing.expectf(t, arena.out_band_allocations != nil,
		"Allocated data with size %v bytes, which is >= out_of_band_size and it should be in arena.out_band_allocations, but isn't!",
	)

	mem.dynamic_arena_destroy(&arena)
	testing.expect(t, arena.out_band_allocations == nil)
}

@(test)
test_dynamic_arena_alloc_aligned :: proc(t: ^testing.T) {
	expect_arena_allocation(t, expected_used_bytes = 16, num_bytes = 16, alignment=8)
}

@(test)
test_dynamic_arena_alloc_unaligned :: proc(t: ^testing.T) {
	expect_arena_allocation(t, expected_used_bytes = 8,  num_bytes = 1, alignment = 8)
	expect_arena_allocation(t, expected_used_bytes = 16, num_bytes = 9, alignment = 8)
}

@(test)
test_dynamic_arena_alloc_out_of_band :: proc(t: ^testing.T) {
	expect_arena_allocation_out_of_band(t, num_bytes = 128, block_size = 512, out_band_size = 128)
	expect_arena_allocation_out_of_band(t, num_bytes = 129, block_size = 512, out_band_size = 128)
	expect_arena_allocation_out_of_band(t, num_bytes = 513, block_size = 512, out_band_size = 128)
}

@(test)
test_intentional_leaks :: proc(t: ^testing.T) {
	testing.expect_leaks(t, intentionally_leaky_test, leak_verifier)
}

// Not tagged with @(test) because it's run through `test_intentional_leaks`
intentionally_leaky_test :: proc(t: ^testing.T) {
	a: [dynamic]int
	// Intentional leak
	append(&a, 42)

	// Intentional bad free
	b := uintptr(&a[0]) + 42
	free(rawptr(b))
}

leak_verifier :: proc(t: ^testing.T, ta: ^mem.Tracking_Allocator) {
	testing.expect_value(t, len(ta.allocation_map), 1)
	testing.expect_value(t, len(ta.bad_free_array), 1)
}
