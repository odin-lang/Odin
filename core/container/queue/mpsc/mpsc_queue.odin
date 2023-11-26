package container_queue_mpsc

import "core:sync"
import "core:intrinsics"
import "core:runtime"

Node :: struct($T: typeid) {
	next: ^Node(T),
	value: T,
}

Queue :: struct($T: typeid) {
	sentinel: Node(T),
	head: ^Node(T),
	tail: ^Node(T),
	count: int,
	allocator: runtime.Allocator, // needs to be thread safe
}

init :: proc(q: ^Queue($T), allocator := context.allocator) {
	q.allocator = allocator
	intrinsics.atomic_store_explicit(&q.sentinel.next, nil, .Relaxed)
	intrinsics.atomic_store_explicit(&q.head, &q.sentinel, .Relaxed)
	intrinsics.atomic_store_explicit(&q.tail, &q.sentinel, .Relaxed)
	intrinsics.atomic_store_explicit(&q.count, 0, .Relaxed)
}

destroy :: proc(q: ^Queue($T)) {
	for _ in dequeue() { 
		continue
	}
}

enqueue :: proc(q: ^Queue($T), val: T) -> int {
	context.allocator = q.allocator
	node := new(Node(T))
	node.value = val
	return enqueue_node(q, node)
}

@private
enqueue_node :: proc(q: ^Queue($T), node: ^Node(T)) -> int {
	intrinsics.atomic_store_explicit(&node.next, nil, .Release)
    head_ptr := cast(^uintptr) &q.head
	prev := intrinsics.atomic_exchange_explicit(head_ptr, uintptr(node), .Acq_Rel)
    prev_node := cast(^Node(T)) prev
    prev_next_ptr := cast(^uintptr)&prev_node.next
	intrinsics.atomic_store_explicit(prev_next_ptr, uintptr(node), .Release)
	count := 1 + intrinsics.atomic_add_explicit(&q.count, 1, .Release)
	return count
}

dequeue :: proc(q: ^Queue($T)) -> (value: T, has_item: bool) {
	tail := intrinsics.atomic_load_explicit(&q.tail, .Acquire)
	next := intrinsics.atomic_load_explicit(&tail.next, .Acquire)
	if next != nil {
		context.allocator = q.allocator
		intrinsics.atomic_store_explicit(&q.tail, next, .Release)
		value = next.value
		intrinsics.atomic_sub_explicit(&q.count, 1, .Release)
		if tail != &q.sentinel {
			//free(tail)
		}
		return value, true
	}

	assert(intrinsics.atomic_load_explicit(&q.count, .Acquire) == 0)
	return {}, false
}
