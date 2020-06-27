package sync


// A barrier enabling multiple threads to synchronize the beginning of some computation
/*
 * Example:
 *
 * 	package example
 *
 * 	import "core:fmt"
 * 	import "core:sync"
 * 	import "core:thread"
 *
 * 	barrier := &sync.Barrier{};
 *
 * 	main :: proc() {
 * 		fmt.println("Start");
 *
 * 		THREAD_COUNT :: 4;
 * 		threads: [THREAD_COUNT]^thread.Thread;
 *
 * 		sync.barrier_init(barrier, THREAD_COUNT);
 * 		defer sync.barrier_destroy(barrier);
 *
 *
 * 		for _, i in threads {
 * 			threads[i] = thread.create_and_start(proc(t: ^thread.Thread) {
 * 				// Same messages will be printed together but without any interleaving
 * 				fmt.println("Getting ready!");
 * 				sync.barrier_wait(barrier);
 * 				fmt.println("Off their marks they go!");
 * 			});
 * 		}
 *
 * 		for t in threads {
 * 			thread.destroy(t); // join and free thread
 * 		}
 * 		fmt.println("Finished");
 * 	}
 *
 */
Barrier :: struct {
	mutex: Blocking_Mutex,
	cond:  Condition,
	index:         int,
	generation_id: int,
	thread_count:  int,
}

barrier_init :: proc(b: ^Barrier, thread_count: int) {
	blocking_mutex_init(&b.mutex);
	condition_init(&b.cond, &b.mutex);
	b.index = 0;
	b.generation_id = 0;
	b.thread_count = thread_count;
}

barrier_destroy :: proc(b: ^Barrier) {
	blocking_mutex_destroy(&b.mutex);
	condition_destroy(&b.cond);
}

// Block the current thread until all threads have rendezvoused
// Barrier can be reused after all threads rendezvoused once, and can be used continuously
barrier_wait :: proc(b: ^Barrier) -> (is_leader: bool) {
	blocking_mutex_lock(&b.mutex);
	defer blocking_mutex_unlock(&b.mutex);
	local_gen := b.generation_id;
	b.index += 1;
	if b.index < b.thread_count {
		for local_gen == b.generation_id && b.index < b.thread_count {
			condition_wait_for(&b.cond);
		}
		return false;
	}

	b.index = 0;
	b.generation_id += 1;
	condition_broadcast(&b.cond);
	return true;
}
