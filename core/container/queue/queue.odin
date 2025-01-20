package container_queue

import "base:builtin"
import "base:runtime"
_ :: runtime

// Dynamically resizable double-ended queue/ring-buffer
Queue :: struct($T: typeid) {
	data:   [dynamic]T,
	len:    uint,
	offset: uint,
}

DEFAULT_CAPACITY :: 16

// Procedure to initialize a queue
init :: proc(q: ^$Q/Queue($T), capacity := DEFAULT_CAPACITY, allocator := context.allocator) -> runtime.Allocator_Error {
	if q.data.allocator.procedure == nil {
		q.data.allocator = allocator
	}
	clear(q)
	return reserve(q, capacity)
}

// Procedure to initialize a queue from a fixed backing slice.
// The contents of the `backing` will be overwritten as items are pushed onto the `Queue`.
// Any previous contents are not available.
init_from_slice :: proc(q: ^$Q/Queue($T), backing: []T) -> bool {
	clear(q)
	q.data = transmute([dynamic]T)runtime.Raw_Dynamic_Array{
		data = raw_data(backing),
		len = builtin.len(backing),
		cap = builtin.len(backing),
		allocator = {procedure=runtime.nil_allocator_proc, data=nil},
	}
	return true
}

// Procedure to initialize a queue from a fixed backing slice.
// Existing contents are preserved and available on the queue.
init_with_contents :: proc(q: ^$Q/Queue($T), backing: []T) -> bool {
	clear(q)
	q.data = transmute([dynamic]T)runtime.Raw_Dynamic_Array{
		data = raw_data(backing),
		len = builtin.len(backing),
		cap = builtin.len(backing),
		allocator = {procedure=runtime.nil_allocator_proc, data=nil},
	}
	q.len = builtin.len(backing)
	return true
}

// Procedure to destroy a queue
destroy :: proc(q: ^$Q/Queue($T)) {
	delete(q.data)
}

// The length of the queue
len :: proc(q: $Q/Queue($T)) -> int {
	return int(q.len)
}

// The current capacity of the queue
cap :: proc(q: $Q/Queue($T)) -> int {
	return builtin.len(q.data)
}

// Remaining space in the queue (cap-len)
space :: proc(q: $Q/Queue($T)) -> int {
	return builtin.len(q.data) - int(q.len)
}

// Reserve enough space for at least the specified capacity
reserve :: proc(q: ^$Q/Queue($T), capacity: int) -> runtime.Allocator_Error {
	if capacity > space(q^) {
		return _grow(q, uint(capacity)) 
	}
	return nil
}


get :: proc(q: ^$Q/Queue($T), #any_int i: int, loc := #caller_location) -> T {
	runtime.bounds_check_error_loc(loc, i, builtin.len(q.data))

	idx := (uint(i)+q.offset)%builtin.len(q.data)
	return q.data[idx]
}

front :: proc(q: ^$Q/Queue($T)) -> T {
	return q.data[q.offset]
}
front_ptr :: proc(q: ^$Q/Queue($T)) -> ^T {
	return &q.data[q.offset]
}

back :: proc(q: ^$Q/Queue($T)) -> T {
	idx := (q.offset+uint(q.len - 1))%builtin.len(q.data)
	return q.data[idx]
}
back_ptr :: proc(q: ^$Q/Queue($T)) -> ^T {
	idx := (q.offset+uint(q.len - 1))%builtin.len(q.data)
	return &q.data[idx]
}

set :: proc(q: ^$Q/Queue($T), #any_int i: int, val: T, loc := #caller_location) {
	runtime.bounds_check_error_loc(loc, i, builtin.len(q.data))
	
	idx := (uint(i)+q.offset)%builtin.len(q.data)
	q.data[idx] = val
}
get_ptr :: proc(q: ^$Q/Queue($T), #any_int i: int, loc := #caller_location) -> ^T {
	runtime.bounds_check_error_loc(loc, i, builtin.len(q.data))
	
	idx := (uint(i)+q.offset)%builtin.len(q.data)
	return &q.data[idx]
}

peek_front :: proc(q: ^$Q/Queue($T), loc := #caller_location) -> ^T {
	runtime.bounds_check_error_loc(loc, 0, builtin.len(q.data))
	idx := q.offset%builtin.len(q.data)
	return &q.data[idx]
}

peek_back :: proc(q: ^$Q/Queue($T), loc := #caller_location) -> ^T {
	runtime.bounds_check_error_loc(loc, int(q.len - 1), builtin.len(q.data))
	idx := (uint(q.len - 1)+q.offset)%builtin.len(q.data)
	return &q.data[idx]
}

// Push an element to the back of the queue
push_back :: proc(q: ^$Q/Queue($T), elem: T) -> (ok: bool, err: runtime.Allocator_Error) {
	if space(q^) == 0 {
		_grow(q) or_return
	}
	idx := (q.offset+uint(q.len))%builtin.len(q.data)
	q.data[idx] = elem
	q.len += 1
	return true, nil
}

// Push an element to the front of the queue
push_front :: proc(q: ^$Q/Queue($T), elem: T) -> (ok: bool, err: runtime.Allocator_Error)  {
	if space(q^) == 0 {
		_grow(q) or_return
	}	
	q.offset = uint(q.offset - 1 + builtin.len(q.data)) % builtin.len(q.data)
	q.len += 1
	q.data[q.offset] = elem
	return true, nil
}


// Pop an element from the back of the queue
pop_back :: proc(q: ^$Q/Queue($T), loc := #caller_location) -> (elem: T) {
	assert(condition=q.len > 0, loc=loc)
	q.len -= 1
	idx := (q.offset+uint(q.len))%builtin.len(q.data)
	elem = q.data[idx]
	return
}
// Safely pop an element from the back of the queue
pop_back_safe :: proc(q: ^$Q/Queue($T)) -> (elem: T, ok: bool) {
	if q.len > 0 {
		q.len -= 1
		idx := (q.offset+uint(q.len))%builtin.len(q.data)
		elem = q.data[idx]
		ok = true
	}
	return
}

// Pop an element from the front of the queue
pop_front :: proc(q: ^$Q/Queue($T), loc := #caller_location) -> (elem: T) {
	assert(condition=q.len > 0, loc=loc)
	elem = q.data[q.offset]
	q.offset = (q.offset+1)%builtin.len(q.data)
	q.len -= 1
	return
}
// Safely pop an element from the front of the queue
pop_front_safe :: proc(q: ^$Q/Queue($T)) -> (elem: T, ok: bool) {
	if q.len > 0 {
		elem = q.data[q.offset]
		q.offset = (q.offset+1)%builtin.len(q.data)
		q.len -= 1
		ok = true
	}
	return
}

// Push multiple elements to the back of the queue
push_back_elems :: proc(q: ^$Q/Queue($T), elems: ..T) -> (ok: bool, err: runtime.Allocator_Error)  {
	n := uint(builtin.len(elems))
	if space(q^) < int(n) {
		_grow(q, q.len + n) or_return
	}
	
	sz := uint(builtin.len(q.data))
	insert_from := (q.offset + q.len) % sz
	insert_to := n
	if insert_from + insert_to > sz {
		insert_to = sz - insert_from
	}
	copy(q.data[insert_from:], elems[:insert_to])
	copy(q.data[:insert_from], elems[insert_to:])
	q.len += n
	return true, nil
}

// Consume `n` elements from the front of the queue
consume_front :: proc(q: ^$Q/Queue($T), n: int, loc := #caller_location) {
	assert(condition=int(q.len) >= n, loc=loc)
	if n > 0 {
		nu := uint(n)
		q.offset = (q.offset + nu) % builtin.len(q.data)
		q.len -= nu	
	}
}

// Consume `n` elements from the back of the queue
consume_back :: proc(q: ^$Q/Queue($T), n: int, loc := #caller_location) {
	assert(condition=int(q.len) >= n, loc=loc)
	if n > 0 {
		q.len -= uint(n)
	}
}



append_elem  :: push_back
append_elems :: push_back_elems
push   :: proc{push_back, push_back_elems}
append :: proc{push_back, push_back_elems}


// Clear the contents of the queue
clear :: proc(q: ^$Q/Queue($T)) {
	q.len = 0
	q.offset = 0
}


// Internal growing procedure
_grow :: proc(q: ^$Q/Queue($T), min_capacity: uint = 0) -> runtime.Allocator_Error {
	new_capacity := max(min_capacity, uint(8), uint(builtin.len(q.data))*2)
	n := uint(builtin.len(q.data))
	builtin.resize(&q.data, int(new_capacity)) or_return
	if q.offset + q.len > n {
		diff := n - q.offset
		copy(q.data[new_capacity-diff:], q.data[q.offset:][:diff])
		q.offset += new_capacity - n
	}
	return nil
}
