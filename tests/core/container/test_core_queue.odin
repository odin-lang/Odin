package test_core_container

import "base:runtime"
import "core:container/queue"
import "core:testing"

@test
test_queue :: proc(t: ^testing.T) {
	buf := [?]int{99, 99, 99, 99, 99}
	q: queue.Queue(int)

	testing.expect(t, queue.init_from_slice(&q, buf[:]))
	testing.expect_value(t, queue.reserve(&q, len(buf)), nil)

	queue.push_back(&q, 1)
	queue.push_back_elems(&q, 2, 3)
	queue.push_front(&q, 0)

	// {
	// data = [1, 2, 3, 99, 0],
	// len = 4,
	// offset = 4,
	// }

	testing.expect_value(t, queue.back(&q), 3)
	testing.expect_value(t, queue.back_ptr(&q), &buf[2])
	testing.expect_value(t, queue.front(&q), 0)
	testing.expect_value(t, queue.front_ptr(&q), &buf[4])

	queue.get(&q, 3)

	for i in 0..<4 {
		testing.expect_value(t, queue.get(&q, i), i)
		queue.set(&q, i, i)
	}
	testing.expect_value(t, queue.get_ptr(&q, 3), &buf[2])

	queue.consume_back(&q, 1)
	queue.consume_front(&q, 1)
	testing.expect_value(t, queue.pop_back(&q), 2)
	v, ok := queue.pop_back_safe(&q)
	testing.expect_value(t, v, 1)
	testing.expect_value(t, ok, true)


	// Test `init_with_contents`.
	buf2 := [?]int{99, 3, 5}

	queue.init_with_contents(&q, buf2[:])
	push_ok, push_err := queue.push_back(&q, 1)
	testing.expect(t, !push_ok)
	testing.expect_value(t, push_err, runtime.Allocator_Error.Out_Of_Memory)
	push_ok, push_err = queue.push_front(&q, 2)
	testing.expect(t, !push_ok)
	testing.expect_value(t, push_err, runtime.Allocator_Error.Out_Of_Memory)

	pop_front_v, pop_front_ok := queue.pop_front_safe(&q)
	testing.expect(t, pop_front_ok)
	testing.expect_value(t, pop_front_v, 99)

	// Re-initialization.
	queue.init(&q, 0)
	defer queue.destroy(&q)

	queue.push_back_elems(&q, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18)
	testing.expect_value(t, queue.len(q), 18)
	queue.push_back_elems(&q, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18)
	testing.expect_value(t, queue.len(q), 36)

	for i in 1..=18 {
		testing.expect_value(t, queue.pop_front(&q), i)
	}
	for i in 1..=18 {
		testing.expect_value(t, queue.pop_front(&q), i)
	}
}

@test
test_queue_grow_edge_case :: proc(t: ^testing.T) {
	// Create a situation in which we trigger `q.offset + q.len > n` inside
	// `_grow` to evaluate the `copy` behavior.
	qq: queue.Queue(int)
	queue.init(&qq, 0)
	defer queue.destroy(&qq)

	queue.push_back_elems(&qq, 1, 2, 3, 4, 5, 6, 7)
	testing.expect_value(t, queue.pop_front(&qq), 1)
	testing.expect_value(t, queue.pop_front(&qq), 2)
	testing.expect_value(t, queue.pop_front(&qq), 3)
	queue.push_back(&qq, 8)
	queue.push_back(&qq, 9)

	testing.expect_value(t, qq.len, 6)
	testing.expect_value(t, qq.offset, 3)
	testing.expect_value(t, len(qq.data), 8) // value contingent on smallest dynamic array capacity on first allocation

	queue.reserve(&qq, 16)

	testing.expect_value(t, queue.len(qq), 6)
	for i in 4..=9 {
		testing.expect_value(t, queue.pop_front(&qq), i)
	}
	testing.expect_value(t, queue.len(qq), 0)

	// If we made it to this point without failure, the queue should have
	// copied the data into the right place after resizing the backing array.
}

@test
test_queue_grow_edge_case_2 :: proc(t: ^testing.T) {
	// Create a situation in which we trigger `insert_from + insert_to > sz` inside `push_back_elems`
	// to evaluate the modified `insert_to` behavior.
	qq: queue.Queue(int)
	queue.init(&qq, 8)
	defer queue.destroy(&qq)

	queue.push_back_elems(&qq, -1, -2, -3, -4, -5, -6, -7)
	queue.consume_front(&qq, 3)
	queue.push_back_elems(&qq, -8, -9, -10)

	queue.push_back_elems(&qq, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10)

	testing.expect_value(t, queue.len(qq), 17)
	for i in 4..=10 {
		testing.expect_value(t, queue.pop_front(&qq), -i)
	}
	for i in 1..=10 {
		testing.expect_value(t, queue.pop_front(&qq), i)
	}
	testing.expect_value(t, queue.len(qq), 0)
}

@test
test_queue_shrink :: proc(t: ^testing.T) {
	qq: queue.Queue(int)
	queue.init(&qq, 8)
	defer queue.destroy(&qq)

	queue.push_back_elems(&qq, -1, -2, -3, -4, -5, -6, -7)
	queue.consume_front(&qq, 3)
	queue.push_back_elems(&qq, -8, -9, -10)

	queue.push_back_elems(&qq, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10)

	queue.shrink(&qq)
	queue.consume_front(&qq, 7)
	queue.shrink(&qq)

	for i in 1..=10 {
		testing.expect_value(t, queue.pop_front(&qq), i)
	}

	buf: [1]int
	qq_backed: queue.Queue(int)
	queue.init_from_slice(&qq_backed, buf[:])
	queue.shrink(&qq_backed)
}
