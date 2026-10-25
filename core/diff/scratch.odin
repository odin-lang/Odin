#+private
package diff

// Every array carved from scratch starts on this alignment.
SCRATCH_ALIGN :: 8

// A bump allocator over the caller's scratch buffer.
Scratch :: struct {
	buf: []byte,
	pos: int,
}

// Returns the bytes `scratch_take` uses for `count` values of `T`, rounded so the next array stays aligned.
@(require_results)
scratch_bytes :: #force_inline proc "contextless" ($T: typeid, count: int) -> int {
	#assert(align_of(T) <= SCRATCH_ALIGN)
	return (count*size_of(T) + SCRATCH_ALIGN-1) &~ (SCRATCH_ALIGN-1)
}

// Carves `count` values of `T` from the scratch buffer. The values are not zeroed.
@(require_results)
scratch_take :: proc(s: ^Scratch, $T: typeid, count: int, loc := #caller_location) -> []T {
	base  := uintptr(raw_data(s.buf))
	start := int((base + uintptr(s.pos) + (SCRATCH_ALIGN-1)) &~ (SCRATCH_ALIGN-1) - base)
	end   := start + scratch_bytes(T, count)

	assert(end <= len(s.buf), "scratch buffer too small", loc)

	s.pos = end

	return ([^]T)(rawptr(base + uintptr(start)))[:count]
}
