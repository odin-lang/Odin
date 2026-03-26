package test_issues

import "core:testing"
import "core:mem"

// Test for a problem encountered with the scratch allocator.
// Say you have a scratch allocator with an arena size of N.
// If you make an allocation whose size is <= N but greater than
// the amount of free space left in the arena, the allocator
// will return a slice of memory from the start of the arena,
// overlapping previous allocations.  (the expected
// behavior is it satisfies the request with the backup allocator)

@test
test_scratch_smash :: proc(t: ^testing.T) {
    // setup
    frAlloc: mem.Scratch
    err := mem.scratch_init(&frAlloc, 1 * mem.Kilobyte)
    testing.expect(t, err == nil)

    talloc := mem.scratch_allocator(&frAlloc)
    defer mem.scratch_destroy(&frAlloc)

    // First allocation fits in arena.
    a1 := make([]byte, 512, talloc)

    // Second allocation does not fit in the free space, but is
    // <= the arena size.
    a2 := make([]byte, 1024, talloc)

    // Should be true, but bug in scratch allocator returns space
    // overlapping a1 when allocating a2.
    testing.expect(t, &a1[0] != &a2[0])
}

