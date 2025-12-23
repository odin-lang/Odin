// A dynamically resizable double-ended queue/ring-buffer.
package container_queue

import "base:builtin"
import "base:runtime"
_ :: runtime

/*
`Queue` is a dynamically resizable double-ended queue/ring-buffer.

Being double-ended means that either end may be pushed onto or popped from
across the same block of memory, in any order, thus providing both stack and
queue-like behaviors in the same data structure.
*/
Queue :: struct($T: typeid) {
	data:   [dynamic]T,
	len:    uint,
	offset: uint,
}

DEFAULT_CAPACITY :: 16

/*
Initialize a `Queue` with a starting `capacity` and an `allocator`.
*/
init :: proc(q: ^$Q/Queue($T), capacity := DEFAULT_CAPACITY, allocator := context.allocator, loc := #caller_location) -> runtime.Allocator_Error {
	clear(q)
	q.data = transmute([dynamic]T)runtime.Raw_Dynamic_Array{
		data = nil,
		len = 0,
		cap = 0,
		allocator = allocator,
	}
	return reserve(q, capacity, loc)
}

/*
Initialize a `Queue` from a fixed `backing` slice into which modifications are
made directly.

The contents of the `backing` will be overwritten as items are pushed onto the
`Queue`. Any previous contents will not be available through the API but are
not explicitly zeroed either.

Note that procedures which need space to work (`push_back`, ...) will fail if
the backing slice runs out of space.
*/
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

/*
Initialize a `Queue` from a fixed `backing` slice into which modifications are
made directly.

The contents of the queue will start out with all of the elements in `backing`,
effectively creating a full queue from the slice. As such, no procedures will
be able to add more elements to the queue until some are taken off.
*/
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

/*
Delete memory that has been dynamically allocated from a `Queue` that was setup with `init`.

Note that this procedure should not be used on queues setup with
`init_from_slice` or `init_with_contents`, as neither of those procedures keep
track of the allocator state of the underlying `backing` slice.
*/
destroy :: proc(q: ^$Q/Queue($T)) {
	delete(q.data)
}

/*
Return the length of the queue.
*/
len :: proc(q: $Q/Queue($T)) -> int {
	return int(q.len)
}

/*
Return the capacity of the queue.
*/
cap :: proc(q: $Q/Queue($T)) -> int {
	return builtin.len(q.data)
}

/*
Return the remaining space in the queue.

This will be `cap() - len()`.
*/
space :: proc(q: $Q/Queue($T)) -> int {
	return builtin.len(q.data) - int(q.len)
}

/*
Reserve enough space in the queue for at least the specified capacity.

This may return an error if allocation failed.
*/
reserve :: proc(q: ^$Q/Queue($T), capacity: int, loc := #caller_location) -> runtime.Allocator_Error {
	if capacity > space(q^) {
		return _grow(q, uint(capacity), loc)
	}
	return nil
}

/*
Shrink a queue's dynamically allocated array.

This has no effect if the queue was initialized with a backing slice.
*/
shrink :: proc(q: ^$Q/Queue($T), temp_allocator := context.temp_allocator, loc := #caller_location) {
	if q.data.allocator.procedure == runtime.nil_allocator_proc {
		return
	}

	if q.len > 0 && q.offset > 0 {
		// Make the array contiguous again.
		buffer := make([]T, q.len, temp_allocator)
		defer delete(buffer, temp_allocator)

		right := uint(builtin.len(q.data)) - q.offset
		copy(buffer[:],      q.data[q.offset:])
		copy(buffer[right:], q.data[:q.offset])

		copy(q.data[:], buffer[:])

		q.offset = 0
	}

	builtin.shrink(&q.data, q.len, loc)
}

/*
Get the element at index `i`.

This will raise a bounds checking error if `i` is an invalid index.
*/
get :: proc(q: ^$Q/Queue($T), #any_int i: int, loc := #caller_location) -> T {
	runtime.bounds_check_error_loc(loc, i, int(q.len))

	idx := (uint(i)+q.offset)%builtin.len(q.data)
	return q.data[idx]
}

/*
Get a pointer to the element at index `i`.

This will raise a bounds checking error if `i` is an invalid index.
*/
get_ptr :: proc(q: ^$Q/Queue($T), #any_int i: int, loc := #caller_location) -> ^T {
	runtime.bounds_check_error_loc(loc, i, int(q.len))

	idx := (uint(i)+q.offset)%builtin.len(q.data)
	return &q.data[idx]
}

/*
Set the element at index `i` to `val`.

This will raise a bounds checking error if `i` is an invalid index.
*/
set :: proc(q: ^$Q/Queue($T), #any_int i: int, val: T, loc := #caller_location) {
	runtime.bounds_check_error_loc(loc, i, int(q.len))

	idx := (uint(i)+q.offset)%builtin.len(q.data)
	q.data[idx] = val
}

/*
Get the element at the front of the queue.

This will raise a bounds checking error if the queue is empty.
*/
front :: proc(q: ^$Q/Queue($T), loc := #caller_location) -> T {
	when !ODIN_NO_BOUNDS_CHECK {
		ensure(q.len > 0, "Queue is empty.", loc)
	}
	return q.data[q.offset]
}

/*
Get a pointer to the element at the front of the queue.

This will raise a bounds checking error if the queue is empty.
*/
front_ptr :: proc(q: ^$Q/Queue($T), loc := #caller_location) -> ^T {
	when !ODIN_NO_BOUNDS_CHECK {
		ensure(q.len > 0, "Queue is empty.", loc)
	}
	return &q.data[q.offset]
}

/*
Get the element at the back of the queue.

This will raise a bounds checking error if the queue is empty.
*/
back :: proc(q: ^$Q/Queue($T), loc := #caller_location) -> T {
	when !ODIN_NO_BOUNDS_CHECK {
		ensure(q.len > 0, "Queue is empty.", loc)
	}
	idx := (q.offset+uint(q.len - 1))%builtin.len(q.data)
	return q.data[idx]
}

/*
Get a pointer to the element at the back of the queue.

This will raise a bounds checking error if the queue is empty.
*/
back_ptr :: proc(q: ^$Q/Queue($T), loc := #caller_location) -> ^T {
	when !ODIN_NO_BOUNDS_CHECK {
		ensure(q.len > 0, "Queue is empty.", loc)
	}
	idx := (q.offset+uint(q.len - 1))%builtin.len(q.data)
	return &q.data[idx]
}


@(deprecated="Use `front_ptr` instead")
peek_front :: proc(q: ^$Q/Queue($T), loc := #caller_location) -> ^T {
	return front_ptr(q, loc)
}

@(deprecated="Use `back_ptr` instead")
peek_back :: proc(q: ^$Q/Queue($T), loc := #caller_location) -> ^T {
	return back_ptr(q, loc)
}

/*
Push an element to the back of the queue.

If there is no more space left and allocation fails to get more, this will
return false with an `Allocator_Error`.

Example:

	import "base:runtime"
	import "core:container/queue"

	// This demonstrates typical queue behavior (First-In First-Out).
	main :: proc() {
		q: queue.Queue(int)
		queue.init(&q)
		queue.push_back(&q, 1)
		queue.push_back(&q, 2)
		queue.push_back(&q, 3)
		// q.data is now [1, 2, 3, ...]
		assert(queue.pop_front(&q) == 1)
		assert(queue.pop_front(&q) == 2)
		assert(queue.pop_front(&q) == 3)
	}
*/
push_back :: proc(q: ^$Q/Queue($T), elem: T, loc := #caller_location) -> (ok: bool, err: runtime.Allocator_Error) {
	if space(q^) == 0 {
		_grow(q, loc = loc) or_return
	}
	idx := (q.offset+uint(q.len))%builtin.len(q.data)
	q.data[idx] = elem
	q.len += 1
	return true, nil
}

/*
Push an element to the front of the queue.

If there is no more space left and allocation fails to get more, this will
return false with an `Allocator_Error`.

Example:

	import "base:runtime"
	import "core:container/queue"

	// This demonstrates stack behavior (First-In Last-Out).
	main :: proc() {
		q: queue.Queue(int)
		queue.init(&q)
		queue.push_back(&q, 1)
		queue.push_back(&q, 2)
		queue.push_back(&q, 3)
		// q.data is now [1, 2, 3, ...]
		assert(queue.pop_back(&q) == 3)
		assert(queue.pop_back(&q) == 2)
		assert(queue.pop_back(&q) == 1)
	}
*/
push_front :: proc(q: ^$Q/Queue($T), elem: T, loc := #caller_location) -> (ok: bool, err: runtime.Allocator_Error)  {
	if space(q^) == 0 {
		_grow(q, loc = loc) or_return
	}
	q.offset = uint(q.offset - 1 + builtin.len(q.data)) % builtin.len(q.data)
	q.len += 1
	q.data[q.offset] = elem
	return true, nil
}

/*
Pop an element from the back of the queue.

This will raise a bounds checking error if the queue is empty.

Example:

	import "base:runtime"
	import "core:container/queue"

	// This demonstrates stack behavior (First-In Last-Out) at the far end of the data array.
	main :: proc() {
		q: queue.Queue(int)
		queue.init(&q)
		queue.push_front(&q, 1)
		queue.push_front(&q, 2)
		queue.push_front(&q, 3)
		// q.data is now [..., 3, 2, 1]
		log.infof("%#v", q)
		assert(queue.pop_front(&q) == 3)
		assert(queue.pop_front(&q) == 2)
		assert(queue.pop_front(&q) == 1)
	}
*/
pop_back :: proc(q: ^$Q/Queue($T), loc := #caller_location) -> (elem: T) {
	when !ODIN_NO_BOUNDS_CHECK {
		ensure(q.len > 0, "Queue is empty.", loc)
	}
	q.len -= 1
	idx := (q.offset+uint(q.len))%builtin.len(q.data)
	elem = q.data[idx]
	return
}

/*
Pop an element from the back of the queue if one exists and return true.
Otherwise, return a nil element and false.
*/
pop_back_safe :: proc(q: ^$Q/Queue($T)) -> (elem: T, ok: bool) {
	if q.len > 0 {
		q.len -= 1
		idx := (q.offset+uint(q.len))%builtin.len(q.data)
		elem = q.data[idx]
		ok = true
	}
	return
}

/*
Pop an element from the front of the queue

This will raise a bounds checking error if the queue is empty.
*/
pop_front :: proc(q: ^$Q/Queue($T), loc := #caller_location) -> (elem: T) {
	when !ODIN_NO_BOUNDS_CHECK {
		ensure(q.len > 0, "Queue is empty.", loc)
	}
	elem = q.data[q.offset]
	q.offset = (q.offset+1)%builtin.len(q.data)
	q.len -= 1
	return
}

/*
Pop an element from the front of the queue if one exists and return true.
Otherwise, return a nil element and false.
*/
pop_front_safe :: proc(q: ^$Q/Queue($T)) -> (elem: T, ok: bool) {
	if q.len > 0 {
		elem = q.data[q.offset]
		q.offset = (q.offset+1)%builtin.len(q.data)
		q.len -= 1
		ok = true
	}
	return
}

/*
Push many elements at once to the back of the queue.

If there is not enough space left and allocation fails to get more, this will
return false with an `Allocator_Error`.
*/
push_back_elems :: proc(q: ^$Q/Queue($T), elems: ..T, loc := #caller_location) -> (ok: bool, err: runtime.Allocator_Error)  {
	n := uint(builtin.len(elems))
	if space(q^) < int(n) {
		_grow(q, q.len + n, loc) or_return
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

/*
Consume `n` elements from the back of the queue.

This will raise a bounds checking error if the queue does not have enough elements.
*/
consume_front :: proc(q: ^$Q/Queue($T), n: int, loc := #caller_location) {
	when !ODIN_NO_BOUNDS_CHECK {
		ensure(q.len >= uint(n), "Queue does not have enough elements to consume.", loc)
	}
	if n > 0 {
		nu := uint(n)
		q.offset = (q.offset + nu) % builtin.len(q.data)
		q.len -= nu
	}
}

/*
Consume `n` elements from the back of the queue.

This will raise a bounds checking error if the queue does not have enough elements.
*/
consume_back :: proc(q: ^$Q/Queue($T), n: int, loc := #caller_location) {
	when !ODIN_NO_BOUNDS_CHECK {
		ensure(q.len >= uint(n), "Queue does not have enough elements to consume.", loc)
	}
	if n > 0 {
		q.len -= uint(n)
	}
}



append_elem  :: push_back
append_elems :: push_back_elems
push   :: proc{push_back, push_back_elems}
append :: proc{push_back, push_back_elems}
enqueue :: push_back
dequeue :: pop_front


/*
Reset the queue's length and offset to zero, letting it write new elements over
old memory, in effect clearing the accessible contents.
*/
clear :: proc(q: ^$Q/Queue($T)) {
	q.len = 0
	q.offset = 0
}


// Internal growing procedure
_grow :: proc(q: ^$Q/Queue($T), min_capacity: uint = 0, loc := #caller_location) -> runtime.Allocator_Error {
	new_capacity := max(min_capacity, uint(8), uint(builtin.len(q.data))*2)
	n := uint(builtin.len(q.data))
	builtin.resize(&q.data, int(new_capacity), loc) or_return
	if q.offset + q.len > n {
		diff := n - q.offset
		copy(q.data[new_capacity-diff:], q.data[q.offset:][:diff])
		q.offset += new_capacity - n
	}
	return nil
}
