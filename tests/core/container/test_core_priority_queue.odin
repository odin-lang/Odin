package test_core_container

import "base:runtime"
import pq "core:container/priority_queue"
import "core:math/rand"
import "core:testing"

@test
test_priority_queue :: proc(t: ^testing.T) {
	q: pq.Priority_Queue(int)
	pq.init(&q, proc(a, b: int) -> bool {
		return a < b
	}, pq.default_swap_proc(int))
	defer pq.destroy(&q)

	assert(pq.cap(q) == pq.DEFAULT_CAPACITY)

	pq.push(&q, 42)
	assert(pq.len(q)  == 1)
	assert(pq.peek(q) == 42)

	v := pq.pop(&q)
	assert(v == 42)
	assert(pq.len(q) == 0)

	ok: bool
	v, ok = pq.peek_safe(q)
	assert(v == 0 && ok == false)

	v, ok = pq.pop_safe(&q)
	assert(v == 0 && ok == false)

	N :: 15
	for _ in 0..<N {
		v = int(rand.int63())
		pq.push(&q, v)
	}

	assert(pq.len(q) == N)

	last := 0
	for pq.len(q) > 0 {
		v = pq.pop(&q)
		assert(v >= last)
		last = v
	}

	vals := []int{6, 15, 3, 9, 12}
	for _v in vals {
		pq.push(&q, _v)
	}
	// Break ordering and fix it
	q.queue[3] = 42
	pq.fix(&q, 3)

	last = 0
	for pq.len(q) > 0 {
		v = pq.pop(&q)
		assert(v >= last)
		last = v
	}

	assert(pq.len(q) == 0)

	for _v in vals {
		pq.push(&q, _v)
	}

	// Break ordering again, but this time delete that index
	q.queue[3] = 42
	v, ok = pq.remove(&q, 3)
	assert(v == 42 && ok == true)

	last = 0
	for pq.len(q) > 0 {
		v = pq.pop(&q)
		assert(v >= last && v != 42)
		last = v
	}
}

@(test)
test_pq_init_from_dynamic_array :: proc(t: ^testing.T) {
	N :: 50_000

	arr := make_dynamic_array_len_cap([dynamic]u64, N, N, context.allocator)
	assert(runtime.random_generator_read_ptr(context.random_generator, raw_data(arr), N * size_of(u64)))

	q: pq.Priority_Queue(u64)
	pq.init_from_dynamic_array(
		pq    = &q,
		queue = arr,
		less  = proc(a, b: u64) -> bool { return a < b },
		swap  = pq.default_swap_proc(u64),
	)
	defer pq.destroy(&q)

	assert(pq.len(q) == N)

	last: u64
	for pq.len(q) > 0 {
		v := pq.pop(&q)
		assert(v >= last)
		last = v
	}

	assert(pq.len(q) == 0)
	assert(pq.cap(q) == N)

	pq.reserve(&q, N + 12)
	assert(pq.cap(q) == N + 12)

}