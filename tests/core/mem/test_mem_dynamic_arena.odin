package test_core_mem

import "base:runtime"
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
	testing.expectf(t, uintptr(element) % uintptr(alignment) == 0, "Expected allocation to be aligned to %d byte boundary, got %v", alignment, element)

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

expect_reused_block_alignment :: proc(
	t:            ^testing.T,
	backing:      []byte,
	block_size:   int,
	should_reuse: bool,
) {
	block_arena: mem.Arena
	mem.arena_init(&block_arena, backing)

	arena: mem.Dynamic_Arena
	mem.dynamic_arena_init(
		&arena,
		block_allocator = mem.arena_allocator(&block_arena),
		block_size = block_size,
		out_band_size = block_size + 1,
	)
	defer mem.dynamic_arena_destroy(&arena)

	allocator := mem.dynamic_arena_allocator(&arena)
	first, first_err := mem.alloc(1, 16, allocator)
	testing.expect_value(t, first_err, mem.Allocator_Error.None)
	testing.expect(t, uintptr(first) % 64 == 16)

	mem.dynamic_arena_reset(&arena)

	aligned, aligned_err := mem.alloc(1, 64, allocator)
	testing.expect_value(t, aligned_err, mem.Allocator_Error.None)
	testing.expect(t, uintptr(aligned) % 64 == 0)
	testing.expect_value(t, arena.current_block == first, should_reuse)
}

@(test)
test_dynamic_arena_realigns_reused_block :: proc(t: ^testing.T) {
	Backing :: struct #align(64) {
		_:    [16]byte,
		data: [128]byte,
	}

	backing: Backing
	expect_reused_block_alignment(t, backing.data[:], 128, true)
}

@(test)
test_dynamic_arena_skips_incompatible_reused_block :: proc(t: ^testing.T) {
	Backing :: struct #align(64) {
		_:    [16]byte,
		data: [176]byte,
	}

	backing: Backing
	expect_reused_block_alignment(t, backing.data[:], 64, false)
}

@(test)
test_dynamic_arena_alloc_out_of_band :: proc(t: ^testing.T) {
	expect_arena_allocation_out_of_band(t, num_bytes = 128, block_size = 512, out_band_size = 128)
	expect_arena_allocation_out_of_band(t, num_bytes = 129, block_size = 512, out_band_size = 128)
	expect_arena_allocation_out_of_band(t, num_bytes = 513, block_size = 512, out_band_size = 128)
}

@(test)
test_dynamic_arena_alloc_past_block :: proc(t: ^testing.T) {
	// The block size is below the out-band size and not a multiple of the alignments:
	// whatever doesn't fit a block once aligned goes out-band instead of failing.
	for alignment in ([?]int{1, 8, 16, 32, 64}) {
		arena: mem.Dynamic_Arena
		mem.dynamic_arena_init(&arena, block_size = 1022, out_band_size = 6554)
		defer mem.dynamic_arena_destroy(&arena)
		allocator := mem.dynamic_arena_allocator(&arena)

		for size in 1..=2048 {
			data, err := mem.alloc_bytes(size, alignment, allocator)
			testing.expectf(t, err == .None && len(data) == size, "size %v, alignment %v: got %v bytes, %v", size, alignment, len(data), err)
			testing.expectf(t, uintptr(raw_data(data)) % uintptr(alignment) == 0, "size %v: expected alignment %v, got %p", size, alignment, raw_data(data))
		}
	}
}

@(test)
test_dynamic_arena_grow_past_block :: proc(t: ^testing.T) {
	// A dynamic array outgrowing a block keeps every element.
	arena: mem.Dynamic_Arena
	mem.dynamic_arena_init(&arena, block_size = 256)
	defer mem.dynamic_arena_destroy(&arena)

	items := make([dynamic][4]u64, mem.dynamic_arena_allocator(&arena))
	for i in 0..<100 {
		_, err := append(&items, [4]u64{u64(i), 1, 2, 3})
		testing.expectf(t, err == .None, "append %v: %v", i, err)
	}
	testing.expect_value(t, len(items), 100)
	for item, i in items {
		testing.expectf(t, item == {u64(i), 1, 2, 3}, "item %v: got %v", i, item)
	}
}

@(test)
test_dynamic_arena_minimum_alignment_out_of_band :: proc(t: ^testing.T) {
	// Out-band allocations keep the minimum alignment too, as in-block ones do.
	arena: mem.Dynamic_Arena
	mem.dynamic_arena_init(&arena, block_size = 256, out_band_size = 512, minimum_alignment = 64)
	defer mem.dynamic_arena_destroy(&arena)
	allocator := mem.dynamic_arena_allocator(&arena)

	for size in ([?]int{100, 300, 600}) {
		data, err := mem.alloc_bytes(size, 1, allocator)
		testing.expectf(t, err == .None && len(data) == size, "size %v: got %v bytes, %v", size, len(data), err)
		testing.expectf(t, uintptr(raw_data(data)) % 64 == 0, "size %v: expected alignment 64, got %p", size, raw_data(data))
	}
}

@(private="file")
Failing_Allocator :: struct {
	backing: runtime.Allocator,
	count:   int,
	fail_at: int,
}

@(private="file")
failing_allocator_proc :: proc(
	data: rawptr, mode: runtime.Allocator_Mode,
	size, alignment: int, old_memory: rawptr, old_size: int,
	loc := #caller_location,
) -> ([]byte, runtime.Allocator_Error) {
	fa := (^Failing_Allocator)(data)
	#partial switch mode {
	case .Alloc, .Alloc_Non_Zeroed, .Resize, .Resize_Non_Zeroed:
		if fa.count == fa.fail_at {
			fa.count += 1
			return nil, .Out_Of_Memory
		}
		fa.count += 1
	}
	return fa.backing.procedure(fa.backing.data, mode, size, alignment, old_memory, old_size, loc)
}

// Allocates in blocks and out-band, past the 8 entries each of the arena's arrays starts with, resets, and
// allocates again from the reused blocks. Returns how many allocations failed.
@(private="file")
dynamic_arena_failure_run :: proc(t: ^testing.T, backing: runtime.Allocator) -> (failures: int) {
	arena: mem.Dynamic_Arena
	mem.dynamic_arena_init(&arena, backing, backing, block_size = 256, out_band_size = 1024)
	defer mem.dynamic_arena_destroy(&arena)
	allocator := mem.dynamic_arena_allocator(&arena)

	for _ in 0..<2 {
		for i in 0..<40 {
			size := 2000 if i % 4 == 0 else 100
			data, err := mem.alloc_bytes(size, 16, allocator)
			if err != nil {
				testing.expectf(t, data == nil, "%v bytes: got %v bytes with %v", size, len(data), err)
				failures += 1
				continue
			}
			testing.expectf(t, raw_data(data) != nil && len(data) == size, "%v bytes: got %p, %v bytes", size, raw_data(data), len(data))
			if raw_data(data) != nil {
				mem.set(raw_data(data), 0xAB, len(data))
			}
		}
		mem.dynamic_arena_reset(&arena)
	}
	return
}

@(test)
test_dynamic_arena_allocation_failure :: proc(t: ^testing.T) {
	// Any allocation the arena makes, for a block, an out-band allocation or its own arrays, can fail.
	// The request that needed it then fails, later ones still get real memory, and nothing leaks.
	total: int
	{
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		defer mem.tracking_allocator_destroy(&track)
		fa := Failing_Allocator{backing = mem.tracking_allocator(&track), fail_at = -1}
		testing.expect_value(t, dynamic_arena_failure_run(t, {failing_allocator_proc, &fa}), 0)
		total = fa.count
		testing.expect_value(t, len(track.allocation_map), 0)
	}

	for k in 0..<total {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		defer mem.tracking_allocator_destroy(&track)
		fa := Failing_Allocator{backing = mem.tracking_allocator(&track), fail_at = k}
		failures := dynamic_arena_failure_run(t, {failing_allocator_proc, &fa})
		testing.expectf(t, failures <= 1, "k=%d of %d: %d allocations failed", k, total, failures)
		testing.expectf(t, len(track.allocation_map) == 0, "k=%d of %d: %d leaked", k, total, len(track.allocation_map))
	}
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
