package test_thread_pool

import "core:testing"

import "core:fmt"
import "core:runtime"
import "core:time"
import "core:intrinsics"
import "core:math/rand"
import "core:thread/pool"

NUM_ITERATIONS :: 1
RANDOMIZE_RUNS :: false

TEST_count := 0
TEST_fail  := 0

when ODIN_TEST {
	expect  :: testing.expect
	log     :: testing.log
} else {
	expect  :: proc(t: ^testing.T, condition: bool, message: string, loc := #caller_location) {
		TEST_count += 1
		if !condition {
			TEST_fail += 1
			fmt.printf("[%v] %v\n", loc, message)
			return
		}
	}
	log     :: proc(t: ^testing.T, v: any, loc := #caller_location) {
		fmt.printf("[%v] ", loc)
		fmt.printf("log: %v\n", v)
	}
}

task_proc_simple :: proc(task: ^pool.Task) {
	r := rand.create(u64(task.user_index))
	ms:= time.Duration(50+rand.int31_max(450, &r))
	time.sleep(ms*time.Millisecond)
}

task_proc_spawning :: proc(task: ^pool.Task) {
	tp := cast(^pool.Pool)task.data
	if(task.user_index<=5) {
		pool.add(tp, task_proc_spawning, task.data, task.user_index+1)
		pool.add(tp, task_proc_spawning, task.data, task.user_index+1)
	}
	r := rand.create(u64(task.user_index))
	ms:= time.Duration(50+rand.int31_max(450, &r))
	time.sleep(ms*time.Millisecond)
}

@test
tests :: proc(t: ^testing.T) {
	fmt.println("Beginning thread pool")
	tp: pool.Pool
	NUM_TASKS :: 25
	num_tasks:= NUM_TASKS
	seed: u64
	when RANDOMIZE_RUNS {
		seed = u64(intrinsics.read_cycle_counter())
	} else {
		seed = 5
	}
	r := rand.create(seed)
	num_threads:= int(rand.int31_max(15, &r))
	fmt.printf("Running pool with %i threads\n", num_threads)

	// explicitly use default allocator, which should be thread safe
	pool.init(&tp, num_threads, runtime.default_allocator())

	for i in 1..num_tasks {
		pool.add(&tp, task_proc_simple, nil, int(rand.int31(&r)))
	}
	fmt.println("Waiting tasks: ", pool.num_waiting(&tp))
	pool.start(&tp)

	num_tasks_done:int
	num_random_tasks:int
	MAX_RANDOM_ADD :: 10
	for !pool.is_empty(&tp) {
		if pool.num_done(&tp)>0 {
			for t in pool.pop_done(&tp) {
				num_tasks_done += 1

				if rand.int31_max(10) == 0 {
					fmt.println("randomly adding another task")
					num_tasks += 1
					num_random_tasks += 1
					pool.add(&tp, task_proc_simple, nil, int(rand.int31(&r)))
				}
			}
		}
		time.sleep(100*time.Millisecond)
	}
	fmt.printf("Tasks done %i/%i (%i+%i)\n", num_tasks_done, num_tasks, NUM_TASKS, num_random_tasks)
	expect(t, num_tasks_done==num_tasks, "expecting all tasks to be finished")

	fmt.println("Testing tasks that spawn more tasks")
	NUM_SPAWNING_TASKS :: 1+2+4+8+16+32
	num_tasks += NUM_SPAWNING_TASKS
	pool.add(&tp, task_proc_spawning, &tp, 1)
	for !pool.is_empty(&tp) {
		if pool.num_done(&tp)>0 {
			for t in pool.pop_done(&tp) {
				fmt.printf("Done task number %i\n", t.user_index)
				num_tasks_done += 1
				}
		}
		time.sleep(100*time.Millisecond)
	}
	fmt.printf("Tasks done %i/%i (%i+%i+%i)\n", num_tasks_done, num_tasks, NUM_TASKS, num_random_tasks, NUM_SPAWNING_TASKS)
	expect(t, num_tasks_done==num_tasks, "expecting all tasks to be finished")

	fmt.println("Add another batch of tasks")
	for i in 1..NUM_TASKS {
		num_tasks += 1
		pool.add(&tp, task_proc_simple, nil, int(rand.int31(&r)))
	}

	fmt.println("waiting for all tasks to process, and doing work on this thread too")
	pool.finish(&tp)
	if pool.num_outstanding(&tp)>0 {
		fmt.println("Error, still outstanding tasks left after pool_finish(&tp)")
		return
	}

	for _ in pool.pop_done(&tp) {
		num_tasks_done += 1
	}
	fmt.printf("Tasks done %i/%i (%i+%i+%i+%i)\n", num_tasks_done, num_tasks, NUM_TASKS, num_random_tasks, NUM_SPAWNING_TASKS, NUM_TASKS)
	expect(t, num_tasks_done==num_tasks, "expecting all tasks to be finished")
	pool.destroy(&tp)
	fmt.println("Thread pool done")
}

main :: proc() {
	t := testing.T{}

	fmt.printf("Running a batch of %i iterations\n", NUM_ITERATIONS)
	for i in 1..NUM_ITERATIONS {
		fmt.printf("BATCH ITERATION %i/%i\n", i, NUM_ITERATIONS)
		tests(&t)
	}
	fmt.printf("All %i iterations successful\n", NUM_ITERATIONS)
}
