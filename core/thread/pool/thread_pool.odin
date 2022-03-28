// A thread pool runs a number of threads and distributes tasks among them.
//
// The thread pool needs to be initialized before use, and destroyed afterwards.
// You can start adding tasks after initialization, but you will have to call
// start() to begin processing. Tasks which are done processing can be taken
// out with a call to pop_done().
//
// The thread pool requires an allocator which it either owns, or which is thread safe.
package thread_pool

import "core:intrinsics"
import sync "core:sync/sync2"
import "core:mem"
import "core:thread"

Task_Proc :: #type proc(task: ^Task)

Task :: struct {
	allocator: mem.Allocator,
	procedure: Task_Proc,
	data: rawptr,
	user_index: int,
}

// Do not access the pool's members directly while the pool threads are running,
// since they use different kinds of locking and mutual exclusion devices.
// Careless access can and will lead to nasty bugs. Once initialized, the
// pool's memory address is not allowed to change until it is destroyed.
Pool :: struct {
	allocator: mem.Allocator,
	mutex: sync.Mutex,
	sem_available: sync.Sema,

	// the following values are atomic
	num_waiting : int,
	num_in_processing: int,
	num_outstanding: int, // num_waiting + num_in_processing
	num_done: int,
	// end of atomics

	is_running: bool,

	threads: []^thread.Thread,

	tasks: [dynamic]Task,
	tasks_done: [dynamic]Task,
}

nil_allocator :: mem.Allocator{
		procedure = mem.nil_allocator_proc,
		data = nil,
}

// Once initialized, the pool's memory address is not allowed to change until
// it is destroyed. If thread_count < 1, thread count 1 will be used.
//
// The thread pool requires an allocator which it either owns, or which is thread safe.
init :: proc(pool: ^Pool, thread_count: int, allocator: mem.Allocator) {
	worker_thread_internal :: proc(t: ^thread.Thread) {
		pool := (^Pool)(t.data)

		for intrinsics.atomic_load(&pool.is_running) {
			sync.wait(&pool.sem_available)

			if task, ok := pop_waiting(pool); ok {
				do_work(pool, &task)
			}
		}

		sync.post(&pool.sem_available, 1)
	}
	actual_thread_count := thread_count
	if actual_thread_count<1 do actual_thread_count = 1

	context.allocator = allocator
	pool.allocator = allocator
	pool.tasks = make([dynamic]Task)
	pool.tasks_done = make([dynamic]Task)
	pool.threads = make([]^thread.Thread, actual_thread_count)

	pool.is_running = true

	for _, i in pool.threads {
		t := thread.create(worker_thread_internal)
		t.user_index = i
		t.data = pool
		pool.threads[i] = t
	}
}

destroy :: proc(pool: ^Pool) {
	delete(pool.tasks)
	delete(pool.tasks_done)

	for t in &pool.threads {
		thread.destroy(t)
	}

	delete(pool.threads, pool.allocator)
}

start :: proc(pool: ^Pool) {
	for t in pool.threads {
		thread.start(t)
	}
}

// Finish tasks that have already started processing, then shut down all pool
// threads. Might leave over waiting tasks, any memory allocated for the
// user data of those tasks will not be freed.
join :: proc(pool: ^Pool) {
	intrinsics.atomic_store(&pool.is_running, false)

	sync.post(&pool.sem_available, len(pool.threads))

	thread.yield()

	for t in pool.threads {
		thread.join(t)
	}
}

// Add a task to the thread pool.
//
// Tasks can be added from any thread, not just the thread that created
// the thread pool. You can even add tasks from inside other tasks.
//
// Each task also needs an allocator which it either owns, or which is thread
// safe. By default, allocations in the task are disabled by use of the
// nil_allocator.
add :: proc(pool: ^Pool, procedure: Task_Proc, data: rawptr, user_index: int = 0, allocator: mem.Allocator = nil_allocator) {
	sync.lock(&pool.mutex)
	defer sync.unlock(&pool.mutex)

	task:= Task{
		allocator = allocator,
		procedure = procedure,
		data = data,
		user_index = user_index,
	}

	append(&pool.tasks, task)
	intrinsics.atomic_add(&pool.num_waiting, 1)
	intrinsics.atomic_add(&pool.num_outstanding, 1)
	sync.post(&pool.sem_available, 1)
}

// Number of tasks waiting to be processed. Only informational, mostly for
// debugging. Don't rely on this value being consistent with other num_*
// values.
num_waiting :: #force_inline proc(pool: ^Pool) -> int {
	return intrinsics.atomic_load(&pool.num_waiting)
}

// Number of tasks currently being processed. Only informational, mostly for
// debugging. Don't rely on this value being consistent with other num_*
// values.
num_in_processing :: #force_inline proc(pool: ^Pool) -> int {
	return intrinsics.atomic_load(&pool.num_in_processing)
}

// Outstanding tasks are all tasks that are not done, that is, tasks that are
// waiting, as well as tasks that are currently being processed. Only
// informational, mostly for debugging. Don't rely on this value being
// consistent with other num_* values.
num_outstanding :: #force_inline proc(pool: ^Pool) -> int {
	return intrinsics.atomic_load(&pool.num_outstanding)
}

// Number of tasks which are done processing. Only informational, mostly for
// debugging. Don't rely on this value being consistent with other num_*
// values.
num_done :: #force_inline proc(pool: ^Pool) -> int {
	return intrinsics.atomic_load(&pool.num_done)
}

// If tasks are only being added from one thread, and this procedure is being
// called from that same thread, it will reliably tell if the thread pool is
// empty or not. Empty in this case means there are no tasks waiting, being
// processed, or _done_.
is_empty :: #force_inline proc(pool: ^Pool) -> bool {
	return num_outstanding(pool)==0&&num_done(pool)==0
}

// Mostly for internal use.
pop_waiting :: proc(pool: ^Pool) -> (task: Task, got_task: bool = false) {
	sync.lock(&pool.mutex)
	defer sync.unlock(&pool.mutex)

	if len(pool.tasks) != 0 {
		intrinsics.atomic_sub(&pool.num_waiting, 1)
		intrinsics.atomic_add(&pool.num_in_processing, 1)
		task = pop_front(&pool.tasks)
		got_task = true
	}

	return
}

// Use this to take out finished tasks.
pop_done :: proc(pool: ^Pool) -> (task: Task, got_task: bool = false) {
	sync.lock(&pool.mutex)
	defer sync.unlock(&pool.mutex)

	if len(pool.tasks_done) != 0 {
		task = pop_front(&pool.tasks_done)
		got_task = true
		intrinsics.atomic_sub(&pool.num_done, 1)
	}

	return
}

// Mostly for internal use.
do_work :: proc(pool: ^Pool, task: ^Task) {
	{
		context.allocator = task.allocator
		task.procedure(task)
	}

	sync.lock(&pool.mutex)
	defer sync.unlock(&pool.mutex)

	append(&pool.tasks_done, task^)
	intrinsics.atomic_add(&pool.num_done, 1)
	intrinsics.atomic_sub(&pool.num_outstanding, 1)
	intrinsics.atomic_sub(&pool.num_in_processing, 1)
}

// Process the rest of the tasks, also use this thread for processing, then join
// all the pool threads.
finish :: proc(pool: ^Pool) {
	for task in pop_waiting(pool) {
		t:= task
		do_work(pool, &t)
	}
	join(pool)
}
