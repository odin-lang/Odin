package test_core_mem

import "core:mem"
import "core:mem/tlsf"
import "core:mem/virtual"
import "core:testing"

@(require_results)
count_byte :: proc(data: []byte, value: byte) -> (n: int) {
	for b in data {
		if b == value {
			n += 1
		}
	}
	return
}

/*
Grow, grow without zeroing, then shrink one allocation, checking that the old
bytes survive each step and that the zeroing resize clears the new tail.

Fill the backing memory with non-zero bytes first where possible, so that a
tail which is not zeroed shows up.
*/
expect_resize_keeps_bytes :: proc(t: ^testing.T, allocator: mem.Allocator, loc := #caller_location) {
	data, err := mem.alloc_bytes(100, 16, allocator)
	if !testing.expect_value(t, err, nil, loc) {
		return
	}
	data = data[:100] // TLSF hands back the whole block
	mem.set(raw_data(data), 0xAA, len(data))

	data, err = mem.resize_bytes(data, 150, 16, allocator)
	if !testing.expect_value(t, err, nil, loc) {
		return
	}
	testing.expect_value(t, count_byte(data[:100], 0xAA), 100, loc)
	testing.expect_value(t, count_byte(data[100:], 0),     50,  loc)

	data, err = mem.resize_bytes_non_zeroed(data, 200, 16, allocator)
	if !testing.expect_value(t, err, nil, loc) {
		return
	}
	testing.expect_value(t, count_byte(data[:100],    0xAA), 100, loc)
	testing.expect_value(t, count_byte(data[100:150], 0),    50,  loc)

	data, err = mem.resize_bytes(data, 50, 16, allocator)
	if !testing.expect_value(t, err, nil, loc) {
		return
	}
	testing.expect_value(t, count_byte(data, 0xAA), 50, loc)
	_ = mem.free_bytes(data, allocator)
}

// Allocate 48 bytes off a 64-byte boundary, holding their own indices.
@(require_results)
alloc_off_64 :: proc(t: ^testing.T, allocator: mem.Allocator, loc := #caller_location) -> (data: []byte, ok: bool) {
	for i in 0..<8 {
		data, _ = mem.alloc_bytes(48, 16, allocator)
		if data != nil && !mem.is_aligned(raw_data(data), 64) {
			data = data[:48]
			for &b, j in data {
				b = byte(j)
			}
			return data, true
		}
		// Shift the next allocation along, by a different amount each time.
		_, _ = mem.alloc_bytes(16*(i+1), 16, allocator)
	}
	testing.expect(t, false, "found no allocation off a 64-byte boundary", loc=loc)
	return nil, false
}

// Resizing to a stricter alignment than the allocation has must move it, keeping its bytes.
expect_resize_realigns :: proc(t: ^testing.T, allocator: mem.Allocator, loc := #caller_location) {
	for size in ([]int{48, 32, 96}) {
		data := alloc_off_64(t, allocator, loc) or_break

		resized, err := mem.resize_bytes(data, size, 64, allocator)
		if !testing.expect_value(t, err, nil, loc) {
			continue
		}
		testing.expectf(t, mem.is_aligned(raw_data(resized), 64), "resizing to %d bytes left them at %p", size, raw_data(resized), loc=loc)

		kept := 0
		for b, i in resized[:min(size, 48)] {
			if b == byte(i) {
				kept += 1
			}
		}
		testing.expectf(t, kept == min(size, 48), "resizing to %d bytes kept %d of the old bytes", size, kept, loc=loc)
		_ = mem.free_bytes(resized, allocator)
	}
}

@(test)
test_stack_resize :: proc(t: ^testing.T) {
	buf: [4096]byte
	mem.set(&buf, 0xCC, len(buf))

	s: mem.Stack
	mem.stack_init(&s, buf[:])
	expect_resize_keeps_bytes(t, mem.stack_allocator(&s))
	expect_resize_realigns(t, mem.stack_allocator(&s))
}

@(test)
test_stack_resize_out_of_memory :: proc(t: ^testing.T) {
	// The rest of `buf` takes any write past the end of the stack.
	buf: [8192]byte
	s: mem.Stack
	mem.stack_init(&s, buf[:1024])
	allocator := mem.stack_allocator(&s)

	data, _ := mem.alloc_bytes(512, 16, allocator)
	offset := s.curr_offset

	grown, err := mem.resize_bytes(data, 4096, 16, allocator)
	testing.expect_value(t, err, mem.Allocator_Error.Out_Of_Memory)
	testing.expect(t, grown == nil)
	testing.expect_value(t, s.curr_offset, offset)
}

@(test)
test_stack_resize_last_allocation :: proc(t: ^testing.T) {
	buf: [1024]byte
	s: mem.Stack
	mem.stack_init(&s, buf[:])
	allocator := mem.stack_allocator(&s)

	_, _ = mem.alloc_bytes(100, 16, allocator)
	last, _ := mem.alloc_bytes(100, 16, allocator)
	offset := s.curr_offset

	grown, err := mem.resize_bytes(last, 150, 16, allocator)
	testing.expect_value(t, err, nil)
	testing.expect(t, raw_data(grown) == raw_data(last), "the last allocation did not grow in place")
	testing.expect_value(t, s.curr_offset, offset+50)
	testing.expect_value(t, s.peak_used,   offset+50)

	shrunk, shrunk_err := mem.resize_bytes(grown, 20, 16, allocator)
	testing.expect_value(t, shrunk_err, nil)
	testing.expect(t, raw_data(shrunk) == raw_data(last), "the last allocation did not shrink in place")
	testing.expect_value(t, s.curr_offset, offset-80)
}

@(test)
test_stack_resize_earlier_allocation :: proc(t: ^testing.T) {
	buf: [1024]byte
	s: mem.Stack
	mem.stack_init(&s, buf[:])
	allocator := mem.stack_allocator(&s)

	first, _ := mem.alloc_bytes(100, 16, allocator)
	last,  _ := mem.alloc_bytes(100, 16, allocator)
	mem.set(raw_data(first), 0xAA, len(first))
	mem.set(raw_data(last),  0xBB, len(last))

	grown, err := mem.resize_bytes(first, 150, 16, allocator)
	testing.expect_value(t, err, nil)
	testing.expect(t, raw_data(grown) != raw_data(first), "an earlier allocation grew in place over a later one")
	testing.expect_value(t, count_byte(grown[:100], 0xAA), 100)
	testing.expect_value(t, count_byte(grown[100:], 0),    50)
	testing.expect_value(t, count_byte(last,        0xBB), 100)
}

@(test)
test_small_stack_resize :: proc(t: ^testing.T) {
	buf: [4096]byte
	mem.set(&buf, 0xCC, len(buf))

	s: mem.Small_Stack
	mem.small_stack_init(&s, buf[:])
	expect_resize_keeps_bytes(t, mem.small_stack_allocator(&s))
	expect_resize_realigns(t, mem.small_stack_allocator(&s))
}

@(test)
test_scratch_resize :: proc(t: ^testing.T) {
	s: mem.Scratch
	mem.scratch_init(&s, 4096)
	defer mem.scratch_destroy(&s)
	mem.set(raw_data(s.data), 0xCC, len(s.data))

	expect_resize_keeps_bytes(t, mem.scratch_allocator(&s))
	expect_resize_realigns(t, mem.scratch_allocator(&s))
}

@(test)
test_scratch_resize_leaked_allocation :: proc(t: ^testing.T) {
	s: mem.Scratch
	mem.scratch_init(&s, 64)
	defer mem.scratch_destroy(&s)
	allocator := mem.scratch_allocator(&s)

	// Both are too big for the buffer, so they come from the backup allocator.
	first, _ := mem.alloc_bytes(128, 16, allocator)
	last,  _ := mem.alloc_bytes(128, 16, allocator)

	grown, err := mem.resize_bytes(last, 256, 16, allocator)
	testing.expect_value(t, err, nil)
	if testing.expect_value(t, len(s.leaked_allocations), 2) {
		testing.expect(t, raw_data(s.leaked_allocations[0]) == raw_data(first), "resizing freed the wrong allocation")
		testing.expect(t, raw_data(s.leaked_allocations[1]) == raw_data(grown))
	}
}

@(test)
test_scratch_resize_nil :: proc(t: ^testing.T) {
	s: mem.Scratch
	mem.scratch_init(&s, 1024)
	defer mem.scratch_destroy(&s)

	data, err := mem.scratch_resize_bytes(&s, nil, 64)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, len(data), 64)

	start := uintptr(raw_data(s.data))
	ptr   := uintptr(raw_data(data))
	testing.expect(t, start <= ptr && ptr+64 <= start+uintptr(len(s.data)), "resizing nil did not allocate from the buffer")
}

@(test)
test_arena_resize :: proc(t: ^testing.T) {
	buf: [4096]byte
	mem.set(&buf, 0xCC, len(buf))

	arena: mem.Arena
	mem.arena_init(&arena, buf[:])
	expect_resize_keeps_bytes(t, mem.arena_allocator(&arena))
	expect_resize_realigns(t, mem.arena_allocator(&arena))
}

@(test)
test_dynamic_arena_resize :: proc(t: ^testing.T) {
	arena: mem.Dynamic_Arena
	mem.dynamic_arena_init(&arena)
	defer mem.dynamic_arena_destroy(&arena)

	expect_resize_keeps_bytes(t, mem.dynamic_arena_allocator(&arena))
	expect_resize_realigns(t, mem.dynamic_arena_allocator(&arena))
}

@(test)
test_rollback_resize :: proc(t: ^testing.T) {
	buf: [4096]byte
	mem.set(&buf, 0xCC, len(buf))

	rb: mem.Rollback_Stack
	mem.rollback_stack_init(&rb, buf[:])
	expect_resize_keeps_bytes(t, mem.rollback_stack_allocator(&rb))
	expect_resize_realigns(t, mem.rollback_stack_allocator(&rb))
}

@(test)
test_rollback_resize_nil :: proc(t: ^testing.T) {
	buf: [1024]byte
	rb: mem.Rollback_Stack
	mem.rollback_stack_init(&rb, buf[:])

	data, err := mem.rb_resize_bytes(&rb, nil, 64)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, len(data), 64)
	testing.expect(t, raw_data(data) != nil)
}

@(test)
test_rollback_resize_to_end :: proc(t: ^testing.T) {
	buf: [1024]byte
	rb: mem.Rollback_Stack
	mem.rollback_stack_init(&rb, buf[:])
	allocator := mem.rollback_stack_allocator(&rb)

	// Growing the last allocation to exactly the end of the buffer fits.
	data, _ := mem.alloc_bytes(64, 8, allocator)
	room := len(rb.head.buffer) - int(rb.head.offset) + len(data)

	grown, err := mem.resize_bytes(data, room, 8, allocator)
	testing.expect_value(t, err, nil)
	testing.expect(t, raw_data(grown) == raw_data(data), "the last allocation did not grow in place")
	testing.expect_value(t, int(rb.head.offset), len(rb.head.buffer))
}

@(test)
test_buddy_resize :: proc(t: ^testing.T) {
	buf, _ := mem.make_aligned([]byte, 8192, 64)
	defer delete(buf)
	mem.set(raw_data(buf), 0xCC, len(buf))

	b: mem.Buddy_Allocator
	mem.buddy_allocator_init(&b, buf, 16)
	expect_resize_keeps_bytes(t, mem.buddy_allocator(&b))
}

@(test)
test_compat_resize :: proc(t: ^testing.T) {
	buf: [4096]byte
	mem.set(&buf, 0xCC, len(buf))

	arena: mem.Arena
	mem.arena_init(&arena, buf[:])
	c: mem.Compat_Allocator
	mem.compat_allocator_init(&c, mem.arena_allocator(&arena))
	expect_resize_keeps_bytes(t, mem.compat_allocator(&c))
	expect_resize_realigns(t, mem.compat_allocator(&c))
}

@(test)
test_compat_resize_nil :: proc(t: ^testing.T) {
	c: mem.Compat_Allocator
	mem.compat_allocator_init(&c)
	allocator := mem.compat_allocator(&c)

	// `mem.resize` deals with nil itself, so call the procedure directly.
	data, err := allocator.procedure(allocator.data, .Resize, 64, 16, nil, 0)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, len(data), 64)
	testing.expect_value(t, count_byte(data, 0), 64)
	mem.free_bytes(data, allocator)
}

@(test)
test_tlsf_resize :: proc(t: ^testing.T) {
	alloc: tlsf.Allocator
	defer tlsf.destroy(&alloc)
	if err := tlsf.init_from_allocator(&alloc, context.allocator, 1 << 16); err != .None {
		testing.fail_now(t, "TLSF init error")
	}

	expect_resize_keeps_bytes(t, tlsf.allocator(&alloc))
	expect_resize_realigns(t, tlsf.allocator(&alloc))
}

@(require_results)
init_virtual_arena :: proc(arena: ^virtual.Arena, kind: virtual.Arena_Kind, buffer: []byte) -> mem.Allocator_Error {
	switch kind {
	case .Growing: return virtual.arena_init_growing(arena)
	case .Static:  return virtual.arena_init_static(arena)
	case .Buffer:  return virtual.arena_init_buffer(arena, buffer)
	}
	return nil
}

@(test)
test_virtual_arena_resize :: proc(t: ^testing.T) {
	for kind in virtual.Arena_Kind {
		buf: [8192]byte
		arena: virtual.Arena
		testing.expect_value(t, init_virtual_arena(&arena, kind, buf[:]), nil)
		defer virtual.arena_destroy(&arena)

		expect_resize_keeps_bytes(t, virtual.arena_allocator(&arena))
		expect_resize_realigns(t, virtual.arena_allocator(&arena))
	}
}

@(test)
test_scratch_resize_to_end :: proc(t: ^testing.T) {
	s: mem.Scratch
	mem.scratch_init(&s, 1024)
	defer mem.scratch_destroy(&s)
	allocator := mem.scratch_allocator(&s)

	data, _ := mem.alloc_bytes(64, 16, allocator)
	room := len(s.data) - int(uintptr(raw_data(data)) - uintptr(raw_data(s.data)))

	grown, err := mem.resize_bytes(data, room, 16, allocator)
	testing.expect_value(t, err, nil)
	testing.expect(t, raw_data(grown) == raw_data(data), "the last allocation did not grow in place")
}

@(test)
test_arena_resize_in_place :: proc(t: ^testing.T) {
	buf: [1024]byte
	mem.set(&buf, 0xCC, len(buf))
	arena: mem.Arena
	mem.arena_init(&arena, buf[:])
	allocator := mem.arena_allocator(&arena)

	first, _ := mem.alloc_bytes(64, 16, allocator)
	last,  _ := mem.alloc_bytes(64, 16, allocator)
	mem.set(raw_data(last), 0xAA, len(last))
	offset := arena.offset

	grown, err := mem.resize_bytes(last, 128, 16, allocator)
	testing.expect_value(t, err, nil)
	testing.expect(t, raw_data(grown) == raw_data(last), "the last allocation did not grow in place")
	testing.expect_value(t, arena.offset,    offset+64)
	testing.expect_value(t, arena.peak_used, offset+64)
	testing.expect_value(t, count_byte(grown[:64], 0xAA), 64)
	testing.expect_value(t, count_byte(grown[64:], 0),    64)

	shrunk, shrunk_err := mem.resize_bytes(grown, 32, 16, allocator)
	testing.expect_value(t, shrunk_err, nil)
	testing.expect(t, raw_data(shrunk) == raw_data(last), "the last allocation did not shrink in place")
	testing.expect_value(t, arena.offset, offset-32)

	// An earlier allocation shrinks in place but keeps its tail, and moves to grow.
	offset = arena.offset
	first_shrunk, _ := mem.resize_bytes(first, 16, 16, allocator)
	testing.expect(t, raw_data(first_shrunk) == raw_data(first), "an earlier allocation did not shrink in place")
	testing.expect_value(t, arena.offset, offset)
	first_grown, _ := mem.resize_bytes(first_shrunk, 128, 16, allocator)
	testing.expect(t, raw_data(first_grown) != raw_data(first), "an earlier allocation grew in place over a later one")
	testing.expect_value(t, count_byte(shrunk, 0xAA), 32)

	// While a temporary memory region is active, a shrunk last allocation keeps its tail.
	offset = arena.offset
	tmp := mem.begin_arena_temp_memory(&arena)
	_, _ = mem.resize_bytes(first_grown, 64, 16, allocator)
	testing.expect_value(t, arena.offset, offset)
	mem.end_arena_temp_memory(tmp)
	testing.expect_value(t, arena.offset, offset)
}

@(test)
test_small_stack_resize_in_place :: proc(t: ^testing.T) {
	buf: [1024]byte
	s: mem.Small_Stack
	mem.small_stack_init(&s, buf[:])
	allocator := mem.small_stack_allocator(&s)

	first, _ := mem.alloc_bytes(64, 16, allocator)
	last,  _ := mem.alloc_bytes(64, 16, allocator)
	mem.set(raw_data(last), 0xAA, len(last))
	offset := s.offset

	grown, err := mem.resize_bytes(last, 128, 16, allocator)
	testing.expect_value(t, err, nil)
	testing.expect(t, raw_data(grown) == raw_data(last), "the last allocation did not grow in place")
	testing.expect_value(t, s.offset,    offset+64)
	testing.expect_value(t, s.peak_used, offset+64)

	shrunk, shrunk_err := mem.resize_bytes(grown, 32, 16, allocator)
	testing.expect_value(t, shrunk_err, nil)
	testing.expect(t, raw_data(shrunk) == raw_data(last), "the last allocation did not shrink in place")
	testing.expect_value(t, s.offset, offset-32)

	// An earlier allocation shrinks in place, and moves to grow.
	offset = s.offset
	first_shrunk, _ := mem.resize_bytes(first, 16, 16, allocator)
	testing.expect(t, raw_data(first_shrunk) == raw_data(first), "an earlier allocation did not shrink in place")
	testing.expect_value(t, s.offset, offset)
	first_grown, _ := mem.resize_bytes(first_shrunk, 128, 16, allocator)
	testing.expect(t, raw_data(first_grown) != raw_data(first), "an earlier allocation grew in place over a later one")
	testing.expect_value(t, count_byte(shrunk, 0xAA), 32)
}

@(test)
test_dynamic_arena_resize_in_place :: proc(t: ^testing.T) {
	arena: mem.Dynamic_Arena
	mem.dynamic_arena_init(&arena)
	defer mem.dynamic_arena_destroy(&arena)
	allocator := mem.dynamic_arena_allocator(&arena)

	last, _ := mem.alloc_bytes(64, 16, allocator)
	mem.set(raw_data(last), 0xAA, len(last))
	bytes_left := arena.bytes_left

	grown, err := mem.resize_bytes(last, 128, 16, allocator)
	testing.expect_value(t, err, nil)
	testing.expect(t, raw_data(grown) == raw_data(last), "the last allocation did not grow in place")
	testing.expect_value(t, arena.bytes_left, bytes_left-64)
	testing.expect_value(t, count_byte(grown[:64], 0xAA), 64)
	testing.expect_value(t, count_byte(grown[64:], 0),    64)

	shrunk, shrunk_err := mem.resize_bytes(grown, 32, 16, allocator)
	testing.expect_value(t, shrunk_err, nil)
	testing.expect(t, raw_data(shrunk) == raw_data(last), "the last allocation did not shrink in place")
	testing.expect_value(t, arena.bytes_left, bytes_left+32)

	// An allocation followed by another is not the last one, even when a
	// stricter alignment would round its size up to reach past the later one.
	first: []byte
	for {
		first, _ = mem.alloc_bytes(16, 16, allocator)
		if mem.is_aligned(raw_data(first), 64) {
			break
		}
	}
	later, _ := mem.alloc_bytes(48, 16, allocator)
	mem.set(raw_data(later), 0xBB, len(later))

	first_grown, _ := mem.resize_bytes(first, 64, 64, allocator)
	testing.expect(t, raw_data(first_grown) != raw_data(first), "an earlier allocation grew in place over a later one")
	testing.expect_value(t, count_byte(later, 0xBB), 48)
}

@(test)
test_virtual_arena_resize_in_place :: proc(t: ^testing.T) {
	for kind in virtual.Arena_Kind {
		buf: [16384]byte
		arena: virtual.Arena
		testing.expect_value(t, init_virtual_arena(&arena, kind, buf[:]), nil)
		defer virtual.arena_destroy(&arena)
		allocator := virtual.arena_allocator(&arena)

		data, _ := mem.alloc_bytes(4096, 16, allocator)
		mem.set(raw_data(data), 0xAA, len(data))
		used  := arena.curr_block.used
		total := arena.total_used

		// Shrinking the last allocation gives its tail back, zeroed.
		shrunk, err := mem.resize_bytes(data, 1000, 16, allocator)
		testing.expect_value(t, err, nil)
		testing.expect(t, raw_data(shrunk) == raw_data(data), "the last allocation did not shrink in place")
		testing.expect_value(t, count_byte(shrunk, 0xAA), 1000)
		testing.expect_value(t, arena.curr_block.used, used-3096)
		testing.expect_value(t, arena.total_used,      total-3096)

		next, _ := mem.alloc_bytes(3000, 1, allocator)
		testing.expect(t, raw_data(next) == raw_data(shrunk[1000:]), "the tail was not given back")
		testing.expect_value(t, count_byte(next, 0), 3000)

		// An earlier allocation shrinks in place, keeping its tail.
		used = arena.curr_block.used
		_, _ = mem.resize_bytes(shrunk, 500, 16, allocator)
		testing.expect_value(t, arena.curr_block.used, used)
	}
}

@(test)
test_virtual_arena_shrink_in_temp :: proc(t: ^testing.T) {
	for kind in virtual.Arena_Kind {
		buf: [16384]byte
		arena: virtual.Arena
		testing.expect_value(t, init_virtual_arena(&arena, kind, buf[:]), nil)
		defer virtual.arena_destroy(&arena)
		allocator := virtual.arena_allocator(&arena)

		data, _ := mem.alloc_bytes(4096, 16, allocator)
		used := arena.curr_block.used

		// The temporary region saved the end of the allocation, so it keeps its tail.
		temp := virtual.arena_temp_begin(&arena)
		shrunk, err := mem.resize_bytes(data, 1000, 16, allocator)
		testing.expect_value(t, err, nil)
		testing.expect(t, raw_data(shrunk) == raw_data(data), "the last allocation did not shrink in place")
		testing.expect_value(t, arena.curr_block.used, used)
		virtual.arena_temp_end(temp)
		testing.expect_value(t, arena.curr_block.used, used)
	}
}
