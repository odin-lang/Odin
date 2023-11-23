//+private
package container_queue_mpsc

import test "core:testing"

import "core:sync"
import "core:thread"
import "core:time"
import "core:intrinsics"
import "core:fmt"

@test
example :: proc(T: ^test.T) {
	Data :: struct {
		q: ^Queue(int),
		producers: ^[dynamic]^thread.Thread
	}

	did_acquire :: proc(m: ^b64) -> (acquired: bool) {
		res, ok := intrinsics.atomic_compare_exchange_strong(m, false, true)
		return ok && res == false
	}

	consumer_proc :: proc(t: ^thread.Thread) {
		data := cast(^Data)t.data
		for len(data.producers) > 0 do for val in dequeue(data.q) {
			fmt.printf("Consumed value %d\n", val)
		}
		for val in dequeue(data.q) {
			fmt.printf("Consumed value %d\n", val)
		}
	}

	producer_proc :: proc(t: ^thread.Thread) {
		data := cast(^Data)t.data
		for i in 0..=10 {
			val := i * (t.user_index + 1)
			enqueue(data.q, val)
			fmt.printf("Produced value %d\n", val)
		}
	}

	

	N_PRODUCERS :: 4

	q: Queue(int)
	init(&q, context.allocator)
	producers: [dynamic]^thread.Thread
	consumer: ^thread.Thread
	data: Data
	data.q = &q
	data.producers = &producers

	consumer = thread.create(consumer_proc)
	test.expect(T, consumer != nil, "Cannot create consumer.")
	consumer.init_context = context
	consumer.user_index = 0
	consumer.procedure = consumer_proc
	thread.start(consumer)

	for i in 0..=N_PRODUCERS {
		t := thread.create(producer_proc)
		test.expect(T, t != nil, "Cannot create producer.")
		t.user_index = i
		t.init_context = context
		t.procedure = producer_proc
		append(&producers, t)
		thread.start(t)
	}

	for len(producers) > 0 do for i := 0; i < len(producers); {
		if t := producers[i]; thread.is_done(t) {
			fmt.printf("Producer thread %d is done\n", t.user_index)
			thread.destroy(t)
			ordered_remove(&producers, i)
		} else {
			i += 1
		}
	}

	for !thread.is_done(consumer) {
		continue
	}
	fmt.printf("Thread consumer is done\n")
	thread.destroy(consumer)
	test.expect(T, q.count == 0, "Did not consume all the produced values\n")
}