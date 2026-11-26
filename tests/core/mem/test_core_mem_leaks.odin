package test_core_mem

import "base:runtime"
import "core:mem"
import "core:mem/virtual"
import "core:testing"

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

@(private="file")
failing_allocator :: proc(fa: ^Failing_Allocator) -> runtime.Allocator {
	return {procedure = failing_allocator_proc, data = fa}
}

@(private="file")
HUGE_SIZES :: [?]int{max(int), max(int) - 1, max(int) - 8, max(int) - 40, max(int) - 4096, max(int)/2 + 1}

@(private="file")
GUARDED_SIZES :: [?]int{max(int), max(int) - 1, max(int) - 2}

@(private="file")
WRAPPING_COUNT :: (1 << uint(8*size_of(int) - 3)) + 1

@(test)
test_leak_rollback_stack_huge_request :: proc(t: ^testing.T) {
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	defer mem.tracking_allocator_destroy(&track)

	rb: mem.Rollback_Stack
	testing.expect_value(t, mem.rollback_stack_init_dynamic(&rb, 4096, mem.tracking_allocator(&track)), nil)
	alloc := mem.rollback_stack_allocator(&rb)

	small, small_err := mem.alloc_bytes(64, 8, alloc)
	testing.expect_value(t, small_err, nil)
	testing.expect_value(t, len(small), 64)

	for size in GUARDED_SIZES {
		for alignment in ([?]int{1, 8, 64}) {
			data, err := mem.alloc_bytes(size, alignment, alloc)
			testing.expectf(t, err == .Out_Of_Memory, "size %v, alignment %v: %v", size, alignment, err)
			testing.expectf(t, data == nil, "size %v, alignment %v: got %v bytes", size, alignment, len(data))
		}
		grown, grown_err := mem.resize_bytes(small, size, 8, alloc)
		testing.expectf(t, grown_err == .Out_Of_Memory, "resize to %v: %v", size, grown_err)
		testing.expectf(t, grown == nil, "resize to %v: got %v bytes", size, len(grown))
	}

	more, more_err := mem.alloc_bytes(8192, 8, alloc)
	testing.expect_value(t, more_err, nil)
	testing.expect_value(t, len(more), 8192)
	testing.expect_value(t, mem.free_bytes(more, alloc), nil)
	testing.expect_value(t, mem.free_bytes(small, alloc), nil)

	mem.rollback_stack_destroy(&rb)
	testing.expect_value(t, len(track.allocation_map), 0)
	testing.expect_value(t, len(track.bad_free_array), 0)
}

@(test)
test_leak_arena_huge_request :: proc(t: ^testing.T) {
	buf: [256]byte
	arena: mem.Arena
	mem.arena_init(&arena, buf[:])

	first, first_err := mem.arena_alloc_bytes(&arena, 16)
	testing.expect_value(t, first_err, nil)
	offset := arena.offset

	for size in HUGE_SIZES {
		data, err := mem.arena_alloc_bytes(&arena, size)
		testing.expectf(t, err == .Out_Of_Memory, "size %v: %v", size, err)
		testing.expectf(t, data == nil, "size %v: got %v bytes", size, len(data))
		testing.expectf(t, arena.offset == offset, "size %v: offset %v", size, arena.offset)

		grown, grown_err := mem.arena_resize_bytes(&arena, first, size)
		testing.expectf(t, grown_err == .Out_Of_Memory, "resize to %v: %v", size, grown_err)
		testing.expectf(t, grown == nil, "resize to %v: got %v bytes", size, len(grown))
		testing.expectf(t, arena.offset == offset, "resize to %v: offset %v", size, arena.offset)
	}
}

@(test)
test_leak_scratch_huge_request :: proc(t: ^testing.T) {
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	defer mem.tracking_allocator_destroy(&track)

	s: mem.Scratch
	testing.expect_value(t, mem.scratch_init(&s, 1024, mem.tracking_allocator(&track)), nil)
	first, first_err := mem.scratch_alloc_bytes(&s, 16)
	testing.expect_value(t, first_err, nil)
	offset := s.curr_offset

	for size in GUARDED_SIZES {
		for alignment in ([?]int{1, 16, 64}) {
			data, err := mem.scratch_alloc_bytes(&s, size, alignment)
			testing.expectf(t, err == .Out_Of_Memory, "size %v, alignment %v: %v", size, alignment, err)
			testing.expectf(t, data == nil, "size %v, alignment %v: got %v bytes", size, alignment, len(data))
			testing.expectf(t, s.curr_offset == offset, "size %v, alignment %v: offset %v", size, alignment, s.curr_offset)
		}
		grown, grown_err := mem.scratch_resize_bytes(&s, first, size)
		testing.expectf(t, grown_err == .Out_Of_Memory, "resize to %v: %v", size, grown_err)
		testing.expectf(t, grown == nil, "resize to %v: got %v bytes", size, len(grown))
		testing.expectf(t, s.curr_offset == offset, "resize to %v: offset %v", size, s.curr_offset)
	}

	mem.scratch_destroy(&s)
	testing.expect_value(t, len(track.allocation_map), 0)
	testing.expect_value(t, len(track.bad_free_array), 0)
}

@(test)
test_leak_scratch_lazy_init_oom :: proc(t: ^testing.T) {
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	defer mem.tracking_allocator_destroy(&track)
	fa := Failing_Allocator{backing = mem.tracking_allocator(&track), fail_at = 0}

	s: mem.Scratch
	{
		context.allocator = failing_allocator(&fa)
		data, err := mem.scratch_alloc_bytes(&s, 32)
		testing.expect_value(t, err, mem.Allocator_Error.Out_Of_Memory)
		testing.expect(t, data == nil)
		testing.expect(t, s.data == nil)

		resized, resize_err := mem.scratch_resize_bytes(&s, nil, 32)
		testing.expect_value(t, resize_err, nil)
		testing.expect_value(t, len(resized), 32)
		testing.expect_value(t, mem.scratch_free(&s, raw_data(resized)), nil)
	}
	mem.scratch_destroy(&s)
	testing.expect_value(t, len(track.allocation_map), 0)
	testing.expect_value(t, len(track.bad_free_array), 0)
}

@(test)
test_leak_scratch_backup_append_oom :: proc(t: ^testing.T) {
	for k in 0..<8 {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		fa := Failing_Allocator{backing = mem.tracking_allocator(&track), fail_at = -1}

		s: mem.Scratch
		testing.expect_value(t, mem.scratch_init(&s, 64, failing_allocator(&fa)), nil)
		fa.fail_at = fa.count + k
		data, err := mem.scratch_alloc_bytes(&s, 256)
		if err == nil {
			testing.expectf(t, len(data) == 256, "fail at %v: %v bytes", k, len(data))
			testing.expectf(t, mem.scratch_free(&s, raw_data(data)) == nil, "fail at %v: free failed", k)
		} else {
			testing.expectf(t, err == .Out_Of_Memory, "fail at %v: %v", k, err)
			testing.expectf(t, data == nil, "fail at %v: data returned with an error", k)
		}
		injected := fa.count > fa.fail_at
		mem.scratch_destroy(&s)
		leaked := len(track.allocation_map)
		bad_frees := len(track.bad_free_array)
		mem.tracking_allocator_destroy(&track)
		testing.expectf(t, leaked == 0, "fail at %v: %v block(s) leaked", k, leaked)
		testing.expectf(t, bad_frees == 0, "fail at %v: %v bad free(s)", k, bad_frees)
		if !injected {
			testing.expectf(t, err == nil, "fail at %v: no failure injected: %v", k, err)
			break
		}
	}
}

@(test)
test_leak_stack_huge_request :: proc(t: ^testing.T) {
	buf: [512]byte
	s: mem.Stack
	mem.stack_init(&s, buf[:])

	first, first_err := mem.stack_alloc_bytes(&s, 32)
	testing.expect_value(t, first_err, nil)
	offset := s.curr_offset

	for size in HUGE_SIZES {
		data, err := mem.stack_alloc_bytes(&s, size)
		testing.expectf(t, err == .Out_Of_Memory, "size %v: %v", size, err)
		testing.expectf(t, data == nil, "size %v: got %v bytes", size, len(data))
		testing.expectf(t, s.curr_offset == offset, "size %v: offset %v", size, s.curr_offset)

		grown, grown_err := mem.stack_resize_bytes(&s, first, size)
		testing.expectf(t, grown_err == .Out_Of_Memory, "resize to %v: %v", size, grown_err)
		testing.expectf(t, grown == nil, "resize to %v: got %v bytes", size, len(grown))
		testing.expectf(t, s.curr_offset == offset, "resize to %v: offset %v", size, s.curr_offset)
	}
}

@(test)
test_leak_small_stack_huge_request :: proc(t: ^testing.T) {
	buf: [512]byte
	s: mem.Small_Stack
	mem.small_stack_init(&s, buf[:])

	first, first_err := mem.small_stack_alloc_bytes(&s, 32)
	testing.expect_value(t, first_err, nil)
	offset := s.offset

	for size in HUGE_SIZES {
		data, err := mem.small_stack_alloc_bytes(&s, size)
		testing.expectf(t, err == .Out_Of_Memory, "size %v: %v", size, err)
		testing.expectf(t, data == nil, "size %v: got %v bytes", size, len(data))
		testing.expectf(t, s.offset == offset, "size %v: offset %v", size, s.offset)

		grown, grown_err := mem.small_stack_resize_bytes(&s, first, size)
		testing.expectf(t, grown_err == .Out_Of_Memory, "resize to %v: %v", size, grown_err)
		testing.expectf(t, grown == nil, "resize to %v: got %v bytes", size, len(grown))
		testing.expectf(t, s.offset == offset, "resize to %v: offset %v", size, s.offset)
	}
}

@(test)
test_leak_dynamic_arena_huge_request :: proc(t: ^testing.T) {
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	defer mem.tracking_allocator_destroy(&track)

	arena: mem.Dynamic_Arena
	mem.dynamic_arena_init(&arena, mem.tracking_allocator(&track), mem.tracking_allocator(&track), block_size = 1024, out_band_size = max(int))

	first, first_err := mem.dynamic_arena_alloc_bytes(&arena, 32)
	testing.expect_value(t, first_err, nil)
	bytes_left := arena.bytes_left

	for size in GUARDED_SIZES {
		data, err := mem.dynamic_arena_alloc_bytes(&arena, size)
		testing.expectf(t, err == .Out_Of_Memory, "size %v: %v", size, err)
		testing.expectf(t, data == nil, "size %v: got %v bytes", size, len(data))
		testing.expectf(t, arena.bytes_left == bytes_left, "size %v: %v bytes left", size, arena.bytes_left)

		grown, grown_err := mem.dynamic_arena_resize_bytes(&arena, first, size)
		testing.expectf(t, grown_err == .Out_Of_Memory, "resize to %v: %v", size, grown_err)
		testing.expectf(t, grown == nil, "resize to %v: got %v bytes", size, len(grown))
		testing.expectf(t, arena.bytes_left == bytes_left, "resize to %v: %v bytes left", size, arena.bytes_left)
	}

	mem.dynamic_arena_destroy(&arena)
	testing.expect_value(t, len(track.allocation_map), 0)
	testing.expect_value(t, len(track.bad_free_array), 0)
}

@(test)
test_leak_buddy_huge_request :: proc(t: ^testing.T) {
	backing, backing_err := mem.make_aligned([]byte, 4096, 64)
	testing.expect_value(t, backing_err, nil)
	defer delete(backing)

	b: mem.Buddy_Allocator
	mem.buddy_allocator_init(&b, backing, 16)

	first, first_err := mem.buddy_allocator_alloc_bytes(&b, 32)
	testing.expect_value(t, first_err, nil)
	testing.expect_value(t, len(first), 32)

	for size in ([?]uint{max(uint), max(uint) - 15, uint(max(int)), 4097, 1 << 20}) {
		data, err := mem.buddy_allocator_alloc_bytes(&b, size)
		testing.expectf(t, err == .Out_Of_Memory, "size %v: %v", size, err)
		testing.expectf(t, data == nil, "size %v: got %v bytes", size, len(data))
	}
	for size in HUGE_SIZES {
		data, err := mem.alloc_bytes(size, 16, mem.buddy_allocator(&b))
		testing.expectf(t, err == .Out_Of_Memory, "allocator size %v: %v", size, err)
		testing.expectf(t, data == nil, "allocator size %v: got %v bytes", size, len(data))
	}

	second, second_err := mem.buddy_allocator_alloc_bytes(&b, 1024)
	testing.expect_value(t, second_err, nil)
	testing.expect_value(t, len(second), 1024)
	testing.expect_value(t, mem.buddy_allocator_free(&b, raw_data(second)), nil)
	testing.expect_value(t, mem.buddy_allocator_free(&b, raw_data(first)), nil)
}

@(test)
test_leak_compat_huge_request :: proc(t: ^testing.T) {
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	defer mem.tracking_allocator_destroy(&track)

	c: mem.Compat_Allocator
	mem.compat_allocator_init(&c, mem.tracking_allocator(&track))
	alloc := mem.compat_allocator(&c)

	first, first_err := mem.alloc_bytes(32, 16, alloc)
	testing.expect_value(t, first_err, nil)

	for size in GUARDED_SIZES {
		data, err := mem.alloc_bytes(size, 16, alloc)
		testing.expectf(t, err == .Out_Of_Memory, "size %v: %v", size, err)
		testing.expectf(t, data == nil, "size %v: got %v bytes", size, len(data))

		grown, grown_err := mem.resize_bytes(first, size, 16, alloc)
		testing.expectf(t, grown_err == .Out_Of_Memory, "resize to %v: %v", size, grown_err)
		testing.expectf(t, grown == nil, "resize to %v: got %v bytes", size, len(grown))
	}

	testing.expect_value(t, mem.free_bytes(first, alloc), nil)
	testing.expect_value(t, len(track.allocation_map), 0)
	testing.expect_value(t, len(track.bad_free_array), 0)
}

@(test)
test_leak_make_over_aligned_size_overflow :: proc(t: ^testing.T) {
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	defer mem.tracking_allocator_destroy(&track)

	slice, original, err := mem.make_over_aligned([]u64, WRAPPING_COUNT, 64, mem.tracking_allocator(&track))
	testing.expect_value(t, err, mem.Allocator_Error.Out_Of_Memory)
	testing.expect_value(t, len(slice), 0)
	testing.expect(t, original == nil)

	slice, original, err = mem.make_over_aligned([]u64, 10, 64, mem.tracking_allocator(&track))
	testing.expect_value(t, err, nil)
	testing.expect_value(t, len(slice), 10)
	testing.expect(t, uintptr(raw_data(slice)) % 64 == 0)
	delete(original, mem.tracking_allocator(&track))

	testing.expect_value(t, track.total_allocation_count, 1)
	testing.expect_value(t, len(track.allocation_map), 0)
}

@(test)
test_leak_virtual_huge_request :: proc(t: ^testing.T) {
	arena: virtual.Arena
	testing.expect_value(t, virtual.arena_init_growing(&arena), nil)
	defer virtual.arena_destroy(&arena)

	s, s_err := virtual.make(&arena, []u64, WRAPPING_COUNT)
	testing.expect_value(t, s_err, virtual.Allocator_Error.Out_Of_Memory)
	testing.expect_value(t, len(s), 0)

	mp, mp_err := virtual.make(&arena, [^]u64, WRAPPING_COUNT)
	testing.expect_value(t, mp_err, virtual.Allocator_Error.Out_Of_Memory)
	testing.expect(t, mp == nil)

	ok, ok_err := virtual.make(&arena, []u64, 16)
	testing.expect_value(t, ok_err, nil)
	testing.expect_value(t, len(ok), 16)

	block, block_err := virtual.memory_block_alloc(0, max(uint))
	testing.expect_value(t, block_err, virtual.Allocator_Error.Out_Of_Memory)
	testing.expect(t, block == nil)

	block, block_err = virtual.memory_block_alloc(0, 1 << 16, uint(1) << (8*size_of(uint) - 1))
	testing.expect_value(t, block_err, virtual.Allocator_Error.Out_Of_Memory)
	testing.expect(t, block == nil)

	static_arena: virtual.Arena
	testing.expect_value(t, virtual.arena_init_static(&static_arena, max(uint)), virtual.Allocator_Error.Out_Of_Memory)
}
