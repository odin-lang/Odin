// The warnings for stack memory say where the pointer is held, what it points into, and where that address was taken
package test_issues

Arena :: struct {
	buf:  [64]u8,
	used: int,
}

Allocator :: struct {
	procedure: rawptr,
	data:      rawptr,
}

arena_allocator :: proc(arena: ^Arena) -> Allocator {
	return {nil, arena}
}

Temp_Arena :: struct {
	arena:     Arena,
	allocator: Allocator,
}

// A value pointing into itself gets a note, as no conversion makes returning it safe
temp_arena_init :: proc() -> (temp: Temp_Arena, ok: bool) {
	temp.allocator = arena_allocator(&temp.arena)
	return temp, true // warning
}

Self :: struct {
	buf: [16]u8,
	s:   []u8,
}

self_init :: proc() -> Self {
	x: Self
	x.s = x.buf[:]
	return x // warning
}

Holder :: struct {
	p: ^int,
}

hold :: proc(p: ^int) -> Holder {
	return {p}
}

through_call :: proc() -> Holder {
	x := 1
	h := hold(&x)
	return h // warning
}

global_ptr: ^int

store_global :: proc() {
	x: Temp_Arena
	p := &x.arena.used
	global_ptr = p // warning
}
