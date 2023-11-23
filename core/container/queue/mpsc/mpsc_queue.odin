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
}

destroy :: proc(q: ^Queue($T)) {
	for _ in dequeue() { 
		continue
	}
}

enqueue :: proc(q: ^Queue($T), val: T) -> int {
	context.allocator = q.allocator
	node := new(Node(T))
	return enqueue_node(q, node)
}

@private
enqueue_node :: proc(q: ^Queue($T), node: ^Node(T)) -> int {
	prev := intrinsics.atomic_exchange_explicit(&q.head, node, .Acq_Rel)
	intrinsics.atomic_store_explicit(&prev.next, node, .Release)
	count := 1 + intrinsics.atomic_add_explicit(&q.count, 1, .Relaxed)
	return count
}

dequeue :: proc(q: ^Queue($T)) -> (value: T, has_item: bool) {
	tail := intrinsics.atomic_load_explicit(&q.tail, .Relaxed)
	next := intrinsics.atomic_load_explicit(&tail.next, .Relaxed)
	if next != nil {
		context.allocator = q.allocator
		intrinsics.atomic_store_explicit(&tail, next, .Relaxed)
		value = next.value
		intrinsics.atomic_sub_explicit(&q.count, 1, .Relaxed)
		free(tail)
		return value, true
	}

	assert(intrinsics.atomic_load_explicit(&q.count, .Acquire) == 0)
	return {}, false
}



