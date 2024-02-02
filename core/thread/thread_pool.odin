package thread

/*
	thread.Pool
	Copyright 2022 eisbehr
	Made available under Odin's BSD-3 license.
*/

import "base:intrinsics"
import "core:sync"
import "core:mem"

Task_Proc :: #type proc(task: Task)

Task :: struct {
	procedure:  Task_Proc,
	data:       rawptr,
	user_index: int,
	allocator:  mem.Allocator,
}

// Do not access the pool's members directly while the pool threads are running,
// since they use different kinds of locking and mutual exclusion devices.
// Careless access can and will lead to nasty bugs. Once initialized, the
// pool's memory address is not allowed to change until it is destroyed.
Pool :: struct {
	allocator:     mem.Allocator,
	mutex:         sync.Mutex,
	sem_available: sync.Sema,

	// the following values are atomic
	num_waiting:       int,
	num_in_processing: int,
	num_outstanding:   int, // num_waiting + num_in_processing
	num_done:          int,
	// end of atomics

	is_running: bool,

	threads: []^Thread,


	tasks:      [dynamic]Task,
	tasks_done: [dynamic]Task,
}

// Once initialized, the pool's memory address is not allowed to change until
// it is destroyed. 
//
// The thread pool requires an allocator which it either owns, or which is thread safe.
pool_init :: proc(pool: ^Pool, allocator: mem.Allocator, thread_count: int) {
	context.allocator = allocator
	pool.allocator = allocator
	pool.tasks      = make([dynamic]Task)
	pool.tasks_done = make([dynamic]Task)
	pool.threads    = make([]^Thread, max(thread_count, 1))

	pool.is_running = true

	for _, i in pool.threads {
		t := create(proc(t: ^Thread) {
			pool := (^Pool)(t.data)

			for intrinsics.atomic_load(&pool.is_running) {
				sync.wait(&pool.sem_available)

				if task, ok := pool_pop_waiting(pool); ok {
					pool_do_work(pool, task)
				}
			}

			sync.post(&pool.sem_available, 1)
		})
		t.user_index = i
		t.data = pool
		pool.threads[i] = t
	}
}

pool_destroy :: proc(pool: ^Pool) {
	delete(pool.tasks)
	delete(pool.tasks_done)

	for &t in pool.threads {
		destroy(t)
	}

	delete(pool.threads, pool.allocator)
}

pool_start :: proc(pool: ^Pool) {
	for t in pool.threads {
		start(t)
	}
}

// Finish tasks that have already started processing, then shut down all pool
// threads. Might leave over waiting tasks, any memory allocated for the
// user data of those tasks will not be freed.
pool_join :: proc(pool: ^Pool) {
	intrinsics.atomic_store(&pool.is_running, false)
	sync.post(&pool.sem_available, len(pool.threads))

	yield()

started_count: int
	for started_count < len(pool.threads) {
		started_count = 0
		for t in pool.threads {
			if .Started in t.flags {
				started_count += 1
				if .Joined not_in t.flags {
					join(t)
				}
			}
		}
	}
}

// Add a task to the thread pool.
//
// Tasks can be added from any thread, not just the thread that created
// the thread pool. You can even add tasks from inside other tasks.
//
// Each task also needs an allocator which it either owns, or which is thread
// safe. 
pool_add_task :: proc(pool: ^Pool, allocator: mem.Allocator, procedure: Task_Proc, data: rawptr, user_index: int = 0) {
	sync.guard(&pool.mutex)

	append(&pool.tasks, Task{
		procedure  = procedure,
		data       = data,
		user_index = user_index,
		allocator  = allocator,
	})
	intrinsics.atomic_add(&pool.num_waiting, 1)
	intrinsics.atomic_add(&pool.num_outstanding, 1)
	sync.post(&pool.sem_available, 1)
}

// Number of tasks waiting to be processed. Only informational, mostly for
// debugging. Don't rely on this value being consistent with other num_*
// values.
pool_num_waiting :: #force_inline proc(pool: ^Pool) -> int {
	return intrinsics.atomic_load(&pool.num_waiting)
}

// Number of tasks currently being processed. Only informational, mostly for
// debugging. Don't rely on this value being consistent with other num_*
// values.
pool_num_in_processing :: #force_inline proc(pool: ^Pool) -> int {
	return intrinsics.atomic_load(&pool.num_in_processing)
}

// Outstanding tasks are all tasks that are not done, that is, tasks that are
// waiting, as well as tasks that are currently being processed. Only
// informational, mostly for debugging. Don't rely on this value being
// consistent with other num_* values.
pool_num_outstanding :: #force_inline proc(pool: ^Pool) -> int {
	return intrinsics.atomic_load(&pool.num_outstanding)
}

// Number of tasks which are done processing. Only informational, mostly for
// debugging. Don't rely on this value being consistent with other num_*
// values.
pool_num_done :: #force_inline proc(pool: ^Pool) -> int {
	return intrinsics.atomic_load(&pool.num_done)
}

// If tasks are only being added from one thread, and this procedure is being
// called from that same thread, it will reliably tell if the thread pool is
// empty or not. Empty in this case means there are no tasks waiting, being
// processed, or _done_.
pool_is_empty :: #force_inline proc(pool: ^Pool) -> bool {
	return pool_num_outstanding(pool) == 0 && pool_num_done(pool) == 0
}

// Mostly for internal use.
pool_pop_waiting :: proc(pool: ^Pool) -> (task: Task, got_task: bool) {
	sync.guard(&pool.mutex)

	if len(pool.tasks) != 0 {
		intrinsics.atomic_sub(&pool.num_waiting, 1)
		intrinsics.atomic_add(&pool.num_in_processing, 1)
		task = pop_front(&pool.tasks)
		got_task = true
	}

	return
}

// Use this to take out finished tasks.
pool_pop_done :: proc(pool: ^Pool) -> (task: Task, got_task: bool) {
	sync.guard(&pool.mutex)

	if len(pool.tasks_done) != 0 {
		task = pop_front(&pool.tasks_done)
		got_task = true
		intrinsics.atomic_sub(&pool.num_done, 1)
	}

	return
}

// Mostly for internal use.
pool_do_work :: proc(pool: ^Pool, task: Task) {
	{
		context.allocator = task.allocator
		task.procedure(task)
	}

	sync.guard(&pool.mutex)

	append(&pool.tasks_done, task)
	intrinsics.atomic_add(&pool.num_done, 1)
	intrinsics.atomic_sub(&pool.num_outstanding, 1)
	intrinsics.atomic_sub(&pool.num_in_processing, 1)
}

// Process the rest of the tasks, also use this thread for processing, then join
// all the pool threads.
pool_finish :: proc(pool: ^Pool) {
	for task in pool_pop_waiting(pool) {
		pool_do_work(pool, task)
	}
	pool_join(pool)
}
