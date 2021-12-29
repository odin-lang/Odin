package container_priority_queue

import "core:builtin"

Priority_Queue :: struct($T: typeid) {
	data:     [dynamic]T,
	len:      int,
	priority: proc(item: T) -> int,
}

DEFAULT_CAPACITY :: 16

init_none :: proc(q: ^$Q/Priority_Queue($T), f: proc(item: T) -> int, allocator := context.allocator) {
	init_len(q, f, 0, allocator)
}
init_len :: proc(q: ^$Q/Priority_Queue($T), f: proc(item: T) -> int, len: int, allocator := context.allocator) {
	init_len_cap(q, f, 0, DEFAULT_CAPACITY, allocator)
}
init_len_cap :: proc(q: ^$Q/Priority_Queue($T), f: proc(item: T) -> int, len: int, cap: int, allocator := context.allocator) {
	if q.data.allocator.procedure == nil {
		q.data.allocator = allocator
	}
	builtin.resize(&q.data, cap)
	q.len = len
	q.priority = f
}

init :: proc{init_none, init_len, init_len_cap}


delete :: proc(q: $Q/Priority_Queue($T)) {
	builtin.delete(q.data)
}

clear :: proc(q: ^$Q/Priority_Queue($T)) {
	q.len = 0
}

len :: proc(q: $Q/Priority_Queue($T)) -> int {
	return q.len
}

cap :: proc(q: $Q/Priority_Queue($T)) -> int {
	return builtin.cap(q.data)
}

space :: proc(q: $Q/Priority_Queue($T)) -> int {
	return builtin.len(q.data) - q.len
}

reserve :: proc(q: ^$Q/Priority_Queue($T), capacity: int) {
	if capacity > q.len {
		builtin.resize(&q.data, capacity)
	}
}

resize :: proc(q: ^$Q/Priority_Queue($T), length: int) {
	if length > q.len {
		builtin.resize(&q.data, length)
	}
	q.len = length
}

_grow :: proc(q: ^$Q/Priority_Queue($T), min_capacity: int = 8) {
	new_capacity := max(builtin.len(q.data)*2, min_capacity, 1)
	builtin.resize(&q.data, new_capacity)
}


push :: proc(q: ^$Q/Priority_Queue($T), item: T) {
	if builtin.len(q.data) - q.len == 0 {
		_grow(q)
	}

	s := q.data[:]
	s[q.len] = item

	i := q.len
	for i > 0 {
		p := (i - 1) / 2
		if q.priority(s[p]) <= q.priority(item) { 
			break 
		}
		s[i] = s[p]
		i = p
	}

	q.len += 1
	if q.len > 0 { 
		s[i] = item 
	} 
}

pop :: proc(q: ^$Q/Priority_Queue($T), loc := #caller_location) -> T {
	val, ok := pop_safe(q)
	assert(condition=ok, loc=loc)
	return val
}


pop_safe :: proc(q: ^$Q/Priority_Queue($T)) -> (T, bool) {
	if q.len > 0 {
		s := q.data[:]
		min := s[0]
		root := s[q.len-1]
		q.len -= 1

		i := 0
		for i * 2 + 1 < q.len {
			a := i * 2 + 1
			b := i * 2 + 2
			c := b < q.len && q.priority(s[b]) < q.priority(s[a]) ? b : a

			if q.priority(s[c]) >= q.priority(root) {
				break
			}
			s[i] = s[c]
			i = c
		}

		if q.len > 0 {
			s[i] = root
		}
		return min, true
	}
	return T{}, false
}

peek :: proc(q: ^$Q/Priority_Queue($T), loc := #caller_location) -> T {
	assert(condition=q.len > 0, loc=loc)

	return q.data[0]
}

peek_safe :: proc(q: ^$Q/Priority_Queue($T)) -> (T, bool) {
	if q.len > 0 {
		return q.data[0], true
	}
	return T{}, false
}