package test_core_mem

import "core:mem"
import "core:mem/tlsf"
import "core:mem/virtual"
import "core:testing"
import "core:slice"

@test
test_tlsf_bitscan :: proc(t: ^testing.T) {
	Vector :: struct {
		op:  enum{ffs, fls, fls_uint},
		v:   union{u32, uint},
		exp: i32,
	}
	Tests := []Vector{
		{.ffs,      u32 (0x0000_0000_0000_0000), -1},
		{.ffs,      u32 (0x0000_0000_0000_0000), -1},
		{.fls,      u32 (0x0000_0000_0000_0000), -1},
		{.ffs,      u32 (0x0000_0000_0000_0001),  0},
		{.fls,      u32 (0x0000_0000_0000_0001),  0},
		{.ffs,      u32 (0x0000_0000_8000_0000), 31},
		{.ffs,      u32 (0x0000_0000_8000_8000), 15},
		{.fls,      u32 (0x0000_0000_8000_0008), 31},
		{.fls,      u32 (0x0000_0000_7FFF_FFFF), 30},
		{.fls_uint, uint(0x0000_0000_8000_0000), 31},
		{.fls_uint, uint(0x0000_0001_0000_0000), 32},
		{.fls_uint, uint(0xffff_ffff_ffff_ffff), 63},
	}

	for test in Tests {
		switch test.op {
		case .ffs:
			res := tlsf.ffs(test.v.?)
			testing.expectf(t, res == test.exp, "Expected tlsf.ffs(0x%08x) == %v, got %v", test.v, test.exp, res)
		case .fls:
			res := tlsf.fls(test.v.?)
			testing.expectf(t, res == test.exp, "Expected tlsf.fls(0x%08x) == %v, got %v", test.v, test.exp, res)
		case .fls_uint:
			res := tlsf.fls_uint(test.v.?)
			testing.expectf(t, res == test.exp, "Expected tlsf.fls_uint(0x%16x) == %v, got %v", test.v, test.exp, res)
		}
	}
}

@(test)
test_align_bumping_block_limit :: proc(t: ^testing.T) {
	a: virtual.Arena
	defer virtual.arena_destroy(&a)

	data, err := virtual.arena_alloc(&a, 4193371, 1)
	testing.expect_value(t, err, nil)
	testing.expect(t, len(data) == 4193371)

	data, err = virtual.arena_alloc(&a, 896, 64)
	testing.expect_value(t, err, nil)
	testing.expect(t, len(data) == 896)
}

@(test)
tlsf_test_overlap_and_zero :: proc(t: ^testing.T) {
	default_allocator := context.allocator
	alloc: tlsf.Allocator
	defer tlsf.destroy(&alloc)

	NUM_ALLOCATIONS :: 1_000
	BACKING_SIZE    :: NUM_ALLOCATIONS * (1_000 + size_of(uintptr))

	if err := tlsf.init_from_allocator(&alloc, default_allocator, BACKING_SIZE); err != .None {
		testing.fail_now(t, "TLSF init error")
	}
	context.allocator = tlsf.allocator(&alloc)

	allocations := make([dynamic][]byte, 0, NUM_ALLOCATIONS, default_allocator)
	defer delete(allocations)

	err: mem.Allocator_Error
	s:   []byte

	for size := 1; err == .None && size <= NUM_ALLOCATIONS; size += 1 {
		s, err = make([]byte, size)
		append(&allocations, s)
	}

	slice.sort_by(allocations[:], proc(a, b: []byte) -> bool {
		return uintptr(raw_data(a)) < uintptr(raw_data((b)))
	})

	for i in 0..<len(allocations) - 1 {
		fail_if_allocations_overlap(t, allocations[i], allocations[i + 1])
		fail_if_not_zeroed(t, allocations[i])
	}
}

@(test)
tlsf_test_grow_pools :: proc(t: ^testing.T) {
	default_allocator := context.allocator
	alloc: tlsf.Allocator
	defer tlsf.destroy(&alloc)

	NUM_ALLOCATIONS    :: 10
	ALLOC_SIZE         :: mem.Megabyte
	BACKING_SIZE_INIT  := tlsf.estimate_pool_size(1, ALLOC_SIZE, 64)
	BACKING_SIZE_GROW  := tlsf.estimate_pool_size(1, ALLOC_SIZE, 64)

	allocations := make([dynamic][]byte, 0, NUM_ALLOCATIONS, default_allocator)
	defer delete(allocations)

	if err := tlsf.init_from_allocator(&alloc, default_allocator, BACKING_SIZE_INIT, BACKING_SIZE_GROW); err != .None {
		testing.fail_now(t, "TLSF init error")
	}
	context.allocator = tlsf.allocator(&alloc)

	for len(allocations) < NUM_ALLOCATIONS {
		s := make([]byte, ALLOC_SIZE) or_break
		testing.expect_value(t, len(s), ALLOC_SIZE)
		append(&allocations, s)
	}

	testing.expect_value(t, len(allocations), NUM_ALLOCATIONS)

	slice.sort_by(allocations[:], proc(a, b: []byte) -> bool {
		return uintptr(raw_data(a)) < uintptr(raw_data((b)))
	})

	for i in 0..<len(allocations) - 1 {
		fail_if_allocations_overlap(t, allocations[i], allocations[i + 1])
		fail_if_not_zeroed(t, allocations[i])
	}
}

@(test)
tlsf_test_free_all :: proc(t: ^testing.T) {
	default_allocator := context.allocator
	alloc: tlsf.Allocator
	defer tlsf.destroy(&alloc)

	NUM_ALLOCATIONS :: 10
	ALLOCATION_SIZE :: mem.Megabyte
	BACKING_SIZE    :: NUM_ALLOCATIONS * (ALLOCATION_SIZE + size_of(uintptr))

	if init_err := tlsf.init_from_allocator(&alloc, default_allocator, BACKING_SIZE); init_err != .None {
		testing.fail_now(t, "TLSF init error")
	}
	context.allocator = tlsf.allocator(&alloc)

	allocations: [2][dynamic][]byte
	allocations[0] = make([dynamic][]byte, 0, NUM_ALLOCATIONS, default_allocator) // After `init`
	allocations[1] = make([dynamic][]byte, 0, NUM_ALLOCATIONS, default_allocator) // After `free_all`
	defer {
		delete(allocations[0])
		delete(allocations[1])
	}

	for {
		s := make([]byte, ALLOCATION_SIZE) or_break
		append(&allocations[0], s)
	}
	testing.expect(t, len(allocations[0]) >= 10)

	free_all(tlsf.allocator(&alloc))

	for {
		s := make([]byte, ALLOCATION_SIZE) or_break
		append(&allocations[1], s)
	}
	testing.expect(t, len(allocations[1]) >= 10)

	for i in 0..<len(allocations[0]) {
		s0, s1 := allocations[0][i], allocations[1][i]
		assert(raw_data(s0) ==  raw_data((s1)))
		assert(len(s0)      ==  len((s1)))
	}
}

fail_if_not_zeroed :: proc(t: ^testing.T, a: []byte) {
	for b in a {
		if b != 0 {
			testing.fail_now(t, "Allocation wasn't zeroed")
		}
	}
}

fail_if_allocations_overlap :: proc(t: ^testing.T, a, b: []byte) {
	a, b := a, b

	a_start := uintptr(raw_data(a))
	a_end   := a_start + uintptr(len(a))
	b_start := uintptr(raw_data(b))
	b_end   := b_start + uintptr(len(b))

	if a_end >= b_end && b_end >= a_start {
		testing.fail_now(t, "Allocations overlapped")
	}
}
