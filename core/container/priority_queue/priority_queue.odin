package container_priority_queue

import "core:builtin"

Priority_Queue :: struct($T: typeid) {
	queue: [dynamic]T,
	
	less:  proc(a, b: T) -> bool,
	swap:  proc(q: []T, i, j: int),
}

DEFAULT_CAPACITY :: 16

default_swap_proc :: proc($T: typeid) -> proc(q: []T, i, j: int) {
	return proc(q: []T, i, j: int) {
		q[i], q[j] = q[j], q[i]
	}
}

init :: proc(pq: ^$Q/Priority_Queue($T), less: proc(a, b: T) -> bool, swap: proc(q: []T, i, j: int), capacity := DEFAULT_CAPACITY, allocator := context.allocator) {
	if pq.queue.allocator.procedure == nil {
		pq.queue.allocator = allocator
	}
	reserve(pq, capacity)
	pq.less = less
	pq.swap = swap
}

init_from_dynamic_array :: proc(pq: ^$Q/Priority_Queue($T), queue: [dynamic]T, less: proc(a, b: T) -> bool, swap: proc(q: []T, i, j: int)) {
	pq.queue = queue
	pq.less = less
	pq.swap = swap
	n := builtin.len(pq.queue)
	for i := n/2 - 1; i >= 0; i -= 1 {
		_shift_down(pq, i, n)
	}
}

destroy :: proc(pq: ^$Q/Priority_Queue($T)) {
	clear(pq)
	delete(pq.queue)
}

reserve :: proc(pq: ^$Q/Priority_Queue($T), capacity: int) {
	builtin.reserve(&pq.queue, capacity)
}
clear :: proc(pq: ^$Q/Priority_Queue($T)) {
	builtin.clear(&pq.queue)
}
len :: proc(pq: $Q/Priority_Queue($T)) -> int {
	return builtin.len(pq.queue)
}
cap :: proc(pq: $Q/Priority_Queue($T)) -> int {
	return builtin.cap(pq.queue)
}

_shift_down :: proc(pq: ^$Q/Priority_Queue($T), i0, n: int) -> bool {
	// O(n log n)
	if 0 > i0 || i0 > n {
		return false
	}
	
	i := i0
	queue := pq.queue[:]
	
	for {
		j1 := 2*i + 1
		if j1 < 0 || j1 >= n {
			break
		}
		j := j1
		if j2 := j1+1; j2 < n && pq.less(queue[j2], queue[j1]) {
			j = j2
		}
		if !pq.less(queue[j], queue[i]) {
			break
		}
		
		pq.swap(queue, i, j)
		i = j
	}
	return i > i0
}

_shift_up :: proc(pq: ^$Q/Priority_Queue($T), j: int) {
	j := j
	queue := pq.queue[:]
	n := builtin.len(queue)
	for 0 <= j {
		i := (j-1)/2
		if i == j || !pq.less(queue[j], queue[i]) {
			break
		}
		pq.swap(queue, i, j)
		j = i
	}
}

// NOTE(bill): When an element at index 'i' has changed its value, this will fix the
// the heap ordering. This is using a basic "heapsort" with shift up and a shift down parts.
fix :: proc(pq: ^$Q/Priority_Queue($T), i: int) {
	if !_shift_down(pq, i, builtin.len(pq.queue)) {
		_shift_up(pq, i)
	}
}

push :: proc(pq: ^$Q/Priority_Queue($T), value: T) {
	append(&pq.queue, value)
	_shift_up(pq, builtin.len(pq.queue)-1)
}

pop :: proc(pq: ^$Q/Priority_Queue($T), loc := #caller_location) -> (value: T) {
	assert(condition=builtin.len(pq.queue)>0, loc=loc)
	
	n := builtin.len(pq.queue)-1
	pq.swap(pq.queue[:], 0, n)
	_shift_down(pq, 0, n)
	return builtin.pop(&pq.queue)
}

pop_safe :: proc(pq: ^$Q/Priority_Queue($T), loc := #caller_location) -> (value: T, ok: bool) {
	if builtin.len(pq.queue) > 0 {
		n := builtin.len(pq.queue)-1
		pq.swap(pq.queue[:], 0, n)
		_shift_down(pq, 0, n)
		return builtin.pop_safe(&pq.queue)
	}
	return
}

remove :: proc(pq: ^$Q/Priority_Queue($T), i: int) -> (value: T, ok: bool) {
	n := builtin.len(pq.queue)
	if 0 <= i && i < n {
		if n != i {
			pq.swap(pq.queue[:], i, n)
			_shift_down(pq, i, n)
			_shift_up(pq, i)
		}
		value, ok = builtin.pop_safe(&pq.queue)
	}
	return
}

