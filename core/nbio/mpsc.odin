#+private
package nbio

import "base:runtime"

import "core:sync"

Multi_Producer_Single_Consumer :: struct {
	count:  int,
	head:   int,
	tail:   int,
	buffer: []rawptr,
	mask:   int,
}

mpsc_init :: proc(mpscq: ^Multi_Producer_Single_Consumer, cap: int, allocator: runtime.Allocator) -> runtime.Allocator_Error {
	assert(runtime.is_power_of_two_int(cap), "cap must be a power of 2")
	mpscq.buffer = make([]rawptr, cap, allocator) or_return
	mpscq.mask   = cap-1
	sync.atomic_thread_fence(.Release)
	return nil
}

mpsc_destroy :: proc(mpscq: ^Multi_Producer_Single_Consumer, allocator: runtime.Allocator) {
	delete(mpscq.buffer, allocator)
}

mpsc_enqueue :: proc(mpscq: ^Multi_Producer_Single_Consumer, obj: rawptr) -> bool {
	count := sync.atomic_add_explicit(&mpscq.count, 1, .Acquire)
	if count >= len(mpscq.buffer) {
		sync.atomic_sub_explicit(&mpscq.count, 1, .Release)
		return false
	}

	head := sync.atomic_add_explicit(&mpscq.head, 1, .Acquire)
	assert(mpscq.buffer[head & mpscq.mask] == nil)
	rv := sync.atomic_exchange_explicit(&mpscq.buffer[head & mpscq.mask], obj, .Release)
	assert(rv == nil)
	return true
}

mpsc_dequeue :: proc(mpscq: ^Multi_Producer_Single_Consumer) -> rawptr {
	ret := sync.atomic_exchange_explicit(&mpscq.buffer[mpscq.tail], nil, .Acquire)
	if ret == nil {
		return nil
	}

	mpscq.tail += 1
	if mpscq.tail >= len(mpscq.buffer) {
		mpscq.tail = 0
	}
	r := sync.atomic_sub_explicit(&mpscq.count, 1, .Release)
	assert(r > 0)
	return ret
}

mpsc_count :: proc(mpscq: ^Multi_Producer_Single_Consumer) -> int {
	return sync.atomic_load_explicit(&mpscq.count, .Relaxed)
}

mpsc_cap :: proc(mpscq: ^Multi_Producer_Single_Consumer) -> int {
	return len(mpscq.buffer)
}