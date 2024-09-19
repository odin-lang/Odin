#+private
package testing

/*
	(c) Copyright 2024 Feoramund <rune@swevencraft.org>.
	Made available under Odin's BSD-3 license.

	List of contributors:
		Ginger Bill: Initial implementation.
		Feoramund:   Total rewrite.
*/

import "base:intrinsics"
import "base:runtime"
import "core:bytes"
import "core:encoding/ansi"
@require import "core:encoding/base64"
@require import "core:encoding/json"
import "core:fmt"
import "core:io"
@require import "core:log"
import "core:math/rand"
import "core:mem"
import "core:os"
import "core:slice"
@require import "core:strings"
import "core:sync/chan"
import "core:thread"
import "core:time"

// Specify how many threads to use when running tests.
TEST_THREADS          : int    : #config(ODIN_TEST_THREADS, 0)
// Track the memory used by each test.
TRACKING_MEMORY       : bool   : #config(ODIN_TEST_TRACK_MEMORY, true)
// Always report how much memory is used, even when there are no leaks or bad frees.
ALWAYS_REPORT_MEMORY  : bool   : #config(ODIN_TEST_ALWAYS_REPORT_MEMORY, false)
// Treat memory leaks and bad frees as errors.
FAIL_ON_BAD_MEMORY    : bool   : #config(ODIN_TEST_FAIL_ON_BAD_MEMORY, false)
// Specify how much memory each thread allocator starts with.
PER_THREAD_MEMORY     : int    : #config(ODIN_TEST_THREAD_MEMORY, mem.ROLLBACK_STACK_DEFAULT_BLOCK_SIZE)
// Select a specific set of tests to run by name.
// Each test is separated by a comma and may optionally include the package name.
// This may be useful when running tests on multiple packages with `-all-packages`.
// The format is: `package.test_name,test_name_only,...`
TEST_NAMES            : string : #config(ODIN_TEST_NAMES, "")
// Show the fancy animated progress report.
FANCY_OUTPUT          : bool   : #config(ODIN_TEST_FANCY, true)
// Copy failed tests to the clipboard when done.
USE_CLIPBOARD         : bool   : #config(ODIN_TEST_CLIPBOARD, false)
// How many test results to show at a time per package.
PROGRESS_WIDTH        : int    : #config(ODIN_TEST_PROGRESS_WIDTH, 24)
// This is the random seed that will be sent to each test.
// If it is unspecified, it will be set to the system cycle counter at startup.
SHARED_RANDOM_SEED    : u64    : #config(ODIN_TEST_RANDOM_SEED, 0)
// Set the lowest log level for this test run.
LOG_LEVEL_DEFAULT     : string : "debug" when ODIN_DEBUG else "info"
LOG_LEVEL             : string : #config(ODIN_TEST_LOG_LEVEL, LOG_LEVEL_DEFAULT)
// Show only the most necessary logging information.
USING_SHORT_LOGS      : bool   : #config(ODIN_TEST_SHORT_LOGS, false)
// Output a report of the tests to the given path.
JSON_REPORT           : string : #config(ODIN_TEST_JSON_REPORT, "")

get_log_level :: #force_inline proc() -> runtime.Logger_Level {
	when LOG_LEVEL == "debug"   { return .Debug   } else
	when LOG_LEVEL == "info"    { return .Info    } else
	when LOG_LEVEL == "warning" { return .Warning } else
	when LOG_LEVEL == "error"   { return .Error   } else
	when LOG_LEVEL == "fatal"   { return .Fatal   } else {
		#panic("Unknown `ODIN_TEST_LOG_LEVEL`: \"" + LOG_LEVEL + "\", possible levels are: \"debug\", \"info\", \"warning\", \"error\", or \"fatal\".")
	}
}

JSON :: struct {
	total:    int,
	success:  int,
	duration: time.Duration,
	packages: map[string][dynamic]JSON_Test,
}

JSON_Test :: struct {
	success: bool,
	name:    string,
}

end_t :: proc(t: ^T) {
	for i := len(t.cleanups)-1; i >= 0; i -= 1 {
		#no_bounds_check c := t.cleanups[i]
		context = c.ctx
		c.procedure(c.user_data)
	}

	delete(t.cleanups)
	t.cleanups = {}
}

when TRACKING_MEMORY && FAIL_ON_BAD_MEMORY {
	Task_Data :: struct {
		it: Internal_Test,
		t: T,
		allocator_index: int,
		tracking_allocator: ^mem.Tracking_Allocator,
	}
} else {
	Task_Data :: struct {
		it: Internal_Test,
		t: T,
		allocator_index: int,
	}
}

Task_Timeout :: struct {
	test_index: int,
	at_time: time.Time,
	location: runtime.Source_Code_Location,
}

run_test_task :: proc(task: thread.Task) {
	data := cast(^Task_Data)(task.data)

	setup_task_signal_handler(task.user_index)

	chan.send(data.t.channel, Event_New_Test {
		test_index = task.user_index,
	})

	chan.send(data.t.channel, Event_State_Change {
		new_state = .Running,
	})
	
	context.assertion_failure_proc = test_assertion_failure_proc

	context.logger = {
		procedure = test_logger_proc,
		data = &data.t,
		lowest_level = get_log_level(),
		options = Default_Test_Logger_Opts,
	}

	random_generator_state: runtime.Default_Random_State
	context.random_generator = {
		procedure = runtime.default_random_generator_proc,
		data = &random_generator_state,
	}
	rand.reset(data.t.seed)

	free_all(context.temp_allocator)

	data.it.p(&data.t)

	end_t(&data.t)

	when TRACKING_MEMORY && FAIL_ON_BAD_MEMORY {
		// NOTE(Feoramund): The simplest way to handle treating memory failures
		// as errors is to allow the test task runner to access the tracking
		// allocator itself.
		//
		// This way, it's still able to send up a log message, which will be
		// used in the end summary, and it can set the test state to `Failed`
		// under the usual conditions.
		//
		// No outside intervention needed.
		memory_leaks := len(data.tracking_allocator.allocation_map)
		bad_frees    := len(data.tracking_allocator.bad_free_array)

		memory_is_in_bad_state := memory_leaks + bad_frees > 0

		data.t.error_count += memory_leaks + bad_frees

		if memory_is_in_bad_state {
			log.errorf("Memory failure in `%s.%s` with %i leak%s and %i bad free%s.",
				data.it.pkg, data.it.name,
				memory_leaks, "" if memory_leaks == 1 else "s",
				bad_frees, "" if bad_frees == 1 else "s")
		}
	}

	new_state : Test_State = .Failed if failed(&data.t) else .Successful

	chan.send(data.t.channel, Event_State_Change {
		new_state = new_state,
	})
}

runner :: proc(internal_tests: []Internal_Test) -> bool {
	BATCH_BUFFER_SIZE     :: 32 * mem.Kilobyte
	POOL_BLOCK_SIZE       :: 16 * mem.Kilobyte
	CLIPBOARD_BUFFER_SIZE :: 16 * mem.Kilobyte

	BUFFERED_EVENTS_PER_CHANNEL :: 16
	RESERVED_LOG_MESSAGES       :: 64
	RESERVED_TEST_FAILURES      :: 64

	ERROR_STRING_TIMEOUT : string : "Test timed out."
	ERROR_STRING_UNKNOWN : string : "Test failed for unknown reasons."
	OSC_WINDOW_TITLE     : string : ansi.OSC + ansi.WINDOW_TITLE + ";Odin test runner (%i/%i)" + ansi.ST

	safe_delete_string :: proc(s: string, allocator := context.allocator) {
		// Guard against bad frees on static strings.
		switch raw_data(s) {
		case raw_data(ERROR_STRING_TIMEOUT), raw_data(ERROR_STRING_UNKNOWN):
			return
		case:
			delete(s, allocator)
		}
	}

	when ODIN_OS == .Windows {
		console_ansi_init()
	}

	stdout := io.to_writer(os.stream_from_handle(os.stdout))
	stderr := io.to_writer(os.stream_from_handle(os.stderr))

	// -- Prepare test data.

	alloc_error: mem.Allocator_Error

	when TEST_NAMES != "" {
		select_internal_tests: [dynamic]Internal_Test
		defer delete(select_internal_tests)

		{
			index_list := TEST_NAMES
			for selector in strings.split_iterator(&index_list, ",") {
				// Temp allocator is fine since we just need to identify which test it's referring to.
				split_selector := strings.split(selector, ".", context.temp_allocator)

				found := false
				switch len(split_selector) {
				case 1:
					// Only the test name?
					#no_bounds_check name := split_selector[0]
					find_test_by_name: for it in internal_tests {
						if it.name == name {
							found = true
							_, alloc_error = append(&select_internal_tests, it)
							fmt.assertf(alloc_error == nil, "Error appending to select internal tests: %v", alloc_error)
							break find_test_by_name
						}
					}
				case 2:
					#no_bounds_check pkg  := split_selector[0]
					#no_bounds_check name := split_selector[1]
					find_test_by_pkg_and_name: for it in internal_tests {
						if it.pkg == pkg && it.name == name {
							found = true
							_, alloc_error = append(&select_internal_tests, it)
							fmt.assertf(alloc_error == nil, "Error appending to select internal tests: %v", alloc_error)
							break find_test_by_pkg_and_name
						}
					}
				}
				if !found {
					fmt.wprintfln(stderr, "No test found for the name: %q", selector)
				}
			}
		}

		// `-vet` needs parameters to be shadowed by themselves first as an
		// explicit declaration, to allow the next line to work.
		internal_tests := internal_tests
		// Intentional shadow with user-specified tests.
		internal_tests = select_internal_tests[:]
	}

	total_failure_count := 0
	total_success_count := 0
	total_done_count    := 0
	total_test_count    := len(internal_tests)

	when !FANCY_OUTPUT {
		// This is strictly for updating the window title when the progress
		// report is disabled. We're otherwise able to depend on the call to
		// `needs_to_redraw`.
		last_done_count := -1
	}

	if total_test_count == 0 {
		// Exit early.
		fmt.wprintln(stdout, "No tests to run.")
		return true
	}

	for it in internal_tests {
		// NOTE(Feoramund): The old test runner skipped over tests with nil
		// procedures, but I couldn't find any case where they occurred.
		// This assert stands to prevent any oversight on my part.
		fmt.assertf(it.p != nil, "Test %s.%s has <nil> procedure.", it.pkg, it.name)
	}

	slice.sort_by(internal_tests, proc(a, b: Internal_Test) -> bool {
		if a.pkg == b.pkg {
			return a.name < b.name
		} else {
			return a.pkg < b.pkg
		}
	})

	// -- Set thread count.

	when TEST_THREADS == 0 {
		thread_count := os.processor_core_count()
	} else {
		thread_count := max(1, TEST_THREADS)
	}

	thread_count = min(thread_count, total_test_count)

	// -- Allocate.

	pool_stack: mem.Rollback_Stack
	alloc_error = mem.rollback_stack_init(&pool_stack, POOL_BLOCK_SIZE)
	fmt.assertf(alloc_error == nil, "Error allocating memory for thread pool: %v", alloc_error)
	defer mem.rollback_stack_destroy(&pool_stack)

	pool: thread.Pool
	thread.pool_init(&pool, mem.rollback_stack_allocator(&pool_stack), thread_count)
	defer thread.pool_destroy(&pool)

	task_channels: []Task_Channel = ---
	task_channels, alloc_error = make([]Task_Channel, thread_count)
	fmt.assertf(alloc_error == nil, "Error allocating memory for update channels: %v", alloc_error)
	defer delete(task_channels)

	for &task_channel, index in task_channels {
		task_channel.channel, alloc_error = chan.create_buffered(Update_Channel, BUFFERED_EVENTS_PER_CHANNEL, context.allocator)
		fmt.assertf(alloc_error == nil, "Error allocating memory for update channel #%i: %v", index, alloc_error)
	}
	defer for &task_channel in task_channels {
		chan.destroy(&task_channel.channel)
	}

	// This buffer is used to batch writes to STDOUT or STDERR, to help reduce
	// screen flickering.
	batch_buffer: bytes.Buffer
	bytes.buffer_init_allocator(&batch_buffer, 0, BATCH_BUFFER_SIZE)
	batch_writer := io.to_writer(bytes.buffer_to_stream(&batch_buffer))
	defer bytes.buffer_destroy(&batch_buffer)

	report: Report = ---
	report, alloc_error = make_report(internal_tests)
	fmt.assertf(alloc_error == nil, "Error allocating memory for test report: %v", alloc_error)
	defer destroy_report(&report)

	when FANCY_OUTPUT {
		// We cannot make use of the ANSI save/restore cursor codes, because they
		// work by absolute screen coordinates. This will cause unnecessary
		// scrollback if we print at the bottom of someone's terminal.
		ansi_redraw_string := fmt.aprintf(
			// ANSI for "go up N lines then erase the screen from the cursor forward."
			ansi.CSI + "%i" + ansi.CPL + ansi.CSI + ansi.ED +
			// We'll combine this with the window title format string, since it
			// can be printed at the same time.
			"%s",
			// 1 extra line for the status bar.
			1 + len(report.packages), OSC_WINDOW_TITLE)
		assert(len(ansi_redraw_string) > 0, "Error allocating ANSI redraw string.")
		defer delete(ansi_redraw_string)

		thread_count_status_string: string = ---
		{
			PADDING :: PROGRESS_COLUMN_SPACING + PROGRESS_WIDTH

			unpadded := fmt.tprintf("%i thread%s", thread_count, "" if thread_count == 1 else "s")
			thread_count_status_string = fmt.aprintf("%- *[1]s", unpadded, report.pkg_column_len + PADDING)
			assert(len(thread_count_status_string) > 0, "Error allocating thread count status string.")
		}
		defer delete(thread_count_status_string)
	}

	task_data_slots: []Task_Data = ---
	task_data_slots, alloc_error = make([]Task_Data, thread_count)
	fmt.assertf(alloc_error == nil, "Error allocating memory for task data slots: %v", alloc_error)
	defer delete(task_data_slots)

	// Tests rotate through these allocators as they finish.
	task_allocators: []mem.Rollback_Stack = ---
	task_allocators, alloc_error = make([]mem.Rollback_Stack, thread_count)
	fmt.assertf(alloc_error == nil, "Error allocating memory for task allocators: %v", alloc_error)
	defer delete(task_allocators)

	when TRACKING_MEMORY {
		task_memory_trackers: []mem.Tracking_Allocator = ---
		task_memory_trackers, alloc_error = make([]mem.Tracking_Allocator, thread_count)
		fmt.assertf(alloc_error == nil, "Error allocating memory for memory trackers: %v", alloc_error)
		defer delete(task_memory_trackers)
	}

	#no_bounds_check for i in 0 ..< thread_count {
		alloc_error = mem.rollback_stack_init(&task_allocators[i], PER_THREAD_MEMORY)
		fmt.assertf(alloc_error == nil, "Error allocating memory for task allocator #%i: %v", i, alloc_error)
		when TRACKING_MEMORY {
			mem.tracking_allocator_init(&task_memory_trackers[i], mem.rollback_stack_allocator(&task_allocators[i]))
		}
	}

	defer #no_bounds_check for i in 0 ..< thread_count {
		when TRACKING_MEMORY {
			mem.tracking_allocator_destroy(&task_memory_trackers[i])
		}
		mem.rollback_stack_destroy(&task_allocators[i])
	}

	task_timeouts: [dynamic]Task_Timeout = ---
	task_timeouts, alloc_error = make([dynamic]Task_Timeout, 0, thread_count)
	fmt.assertf(alloc_error == nil, "Error allocating memory for task timeouts: %v", alloc_error)
	defer delete(task_timeouts)

	failed_test_reason_map: map[int]string = ---
	failed_test_reason_map, alloc_error = make(map[int]string, RESERVED_TEST_FAILURES)
	fmt.assertf(alloc_error == nil, "Error allocating memory for failed test reasons: %v", alloc_error)
	defer delete(failed_test_reason_map)

	log_messages: [dynamic]Log_Message = ---
	log_messages, alloc_error = make([dynamic]Log_Message, 0, RESERVED_LOG_MESSAGES)
	fmt.assertf(alloc_error == nil, "Error allocating memory for log message queue: %v", alloc_error)
	defer delete(log_messages)

	sorted_failed_test_reasons: [dynamic]int = ---
	sorted_failed_test_reasons, alloc_error = make([dynamic]int, 0, RESERVED_TEST_FAILURES)
	fmt.assertf(alloc_error == nil, "Error allocating memory for sorted failed test reasons: %v", alloc_error)
	defer delete(sorted_failed_test_reasons)

	when USE_CLIPBOARD {
		clipboard_buffer: bytes.Buffer
		bytes.buffer_init_allocator(&clipboard_buffer, 0, CLIPBOARD_BUFFER_SIZE)
		defer bytes.buffer_destroy(&clipboard_buffer)
	}

	when SHARED_RANDOM_SEED == 0 {
		shared_random_seed := cast(u64)intrinsics.read_cycle_counter()
	} else {
		shared_random_seed := SHARED_RANDOM_SEED
	}

	// -- Setup initial tasks.

	// NOTE(Feoramund): This is the allocator that will be used by threads to
	// persist log messages past their lifetimes. It has its own variable name
	// in the event it needs to be changed from `context.allocator` without
	// digging through the source to divine everywhere it is used for that.
	shared_log_allocator := context.allocator

	context.logger = {
		procedure = runner_logger_proc,
		data = &log_messages,
		lowest_level = get_log_level(),
		options = Default_Test_Logger_Opts - {.Short_File_Path, .Line, .Procedure},
	}

	run_index: int

	setup_tasks: for &data, task_index in task_data_slots {
		setup_next_test: for run_index < total_test_count {
			#no_bounds_check it := internal_tests[run_index]
			defer run_index += 1

			data.it = it
			data.t.seed = shared_random_seed
			#no_bounds_check data.t.channel = chan.as_send(task_channels[task_index].channel)
			data.t._log_allocator = shared_log_allocator
			data.allocator_index = task_index

			#no_bounds_check when TRACKING_MEMORY {
				task_allocator := mem.tracking_allocator(&task_memory_trackers[task_index])
				when FAIL_ON_BAD_MEMORY {
					data.tracking_allocator = &task_memory_trackers[task_index]
				}
			} else {
				task_allocator := mem.rollback_stack_allocator(&task_allocators[task_index])
			}

			thread.pool_add_task(&pool, task_allocator, run_test_task, &data, run_index)

			continue setup_tasks
		}
	}

	// -- Run tests.

	setup_signal_handler()

	fmt.wprint(stdout, ansi.CSI + ansi.DECTCEM_HIDE)

	when FANCY_OUTPUT {
		signals_were_raised := false

		redraw_report(stdout, report)
		draw_status_bar(stdout, thread_count_status_string, total_done_count, total_test_count)
	}

	when TEST_THREADS == 0 {
		log.infof("Starting test runner with %i thread%s. Set with -define:ODIN_TEST_THREADS=n.",
			thread_count,
			"" if thread_count == 1 else "s")
	} else {
		log.infof("Starting test runner with %i thread%s.",
			thread_count,
			"" if thread_count == 1 else "s")
	}

	when SHARED_RANDOM_SEED == 0 {
		log.infof("The random seed sent to every test is: %v. Set with -define:ODIN_TEST_RANDOM_SEED=n.", shared_random_seed)
	} else {
		log.infof("The random seed sent to every test is: %v.", shared_random_seed)
	}

	when TRACKING_MEMORY {
		when ALWAYS_REPORT_MEMORY {
			log.info("Memory tracking is enabled. Tests will log their memory usage when complete.")
		} else {
			log.info("Memory tracking is enabled. Tests will log their memory usage if there's an issue.")
		}
		log.info("< Final Mem/ Total Mem> <  Peak Mem> (#Free/Alloc) :: [package.test_name]")
	} else {
		when ALWAYS_REPORT_MEMORY {
			log.warn("ODIN_TEST_ALWAYS_REPORT_MEMORY is true, but ODIN_TEST_TRACK_MEMORY is false.")
		}
		when FAIL_ON_BAD_MEMORY {
			log.warn("ODIN_TEST_FAIL_ON_BAD_MEMORY is true, but ODIN_TEST_TRACK_MEMORY is false.")
		}
	}

	start_time := time.now()

	thread.pool_start(&pool)
	main_loop: for !thread.pool_is_empty(&pool) {
		{
			events_pending := thread.pool_num_done(&pool) > 0

			if !events_pending {
				poll_tasks: for &task_channel in task_channels {
					if chan.len(task_channel.channel) > 0 {
						events_pending = true
						break poll_tasks
					}
				}
			}

			if !events_pending {
				// Keep the main thread from pegging a core at 100% usage.
				time.sleep(1 * time.Microsecond)
			}
		}

		cycle_pool: for task in thread.pool_pop_done(&pool) {
			data := cast(^Task_Data)(task.data)

			when TRACKING_MEMORY {
				#no_bounds_check tracker := &task_memory_trackers[data.allocator_index]

				memory_is_in_bad_state := len(tracker.allocation_map) + len(tracker.bad_free_array) > 0

				when ALWAYS_REPORT_MEMORY {
					should_report := true
				} else {
					should_report := memory_is_in_bad_state
				}

				if should_report {
					write_memory_report(batch_writer, tracker, data.it.pkg, data.it.name)

					when FAIL_ON_BAD_MEMORY {
						log.log(.Error if memory_is_in_bad_state else .Info, bytes.buffer_to_string(&batch_buffer))
					} else {
						log.log(.Warning if memory_is_in_bad_state else .Info, bytes.buffer_to_string(&batch_buffer))
					}
					bytes.buffer_reset(&batch_buffer)
				}

				mem.tracking_allocator_reset(tracker)
			}

			free_all(task.allocator)

			if run_index < total_test_count {
				#no_bounds_check it := internal_tests[run_index]
				defer run_index += 1

				data.it = it
				data.t.seed = shared_random_seed
				data.t.error_count = 0
				data.t._fail_now_called = false

				thread.pool_add_task(&pool, task.allocator, run_test_task, data, run_index)
			}
		}

		handle_events: for &task_channel in task_channels {
			for ev in chan.try_recv(task_channel.channel) {
				switch event in ev {
				case Event_New_Test:
					task_channel.test_index = event.test_index

				case Event_State_Change:
					#no_bounds_check report.all_test_states[task_channel.test_index] = event.new_state

					#no_bounds_check it := internal_tests[task_channel.test_index]
					#no_bounds_check pkg := report.packages_by_name[it.pkg]

					#partial switch event.new_state {
					case .Failed:
						if task_channel.test_index not_in failed_test_reason_map {
							failed_test_reason_map[task_channel.test_index] = ERROR_STRING_UNKNOWN
						}
						total_failure_count += 1
						total_done_count += 1
					case .Successful:
						total_success_count += 1
						total_done_count += 1
					}

					when ODIN_DEBUG {
						log.debugf("Test #%i %s.%s changed state to %v.", task_channel.test_index, it.pkg, it.name, event.new_state)
					}

					pkg.last_change_state = event.new_state
					pkg.last_change_name = it.name
					pkg.frame_ready = false

				case Event_Set_Fail_Timeout:
					_, alloc_error = append(&task_timeouts, Task_Timeout {
						test_index = task_channel.test_index,
						at_time = event.at_time,
						location = event.location,
					})
					fmt.assertf(alloc_error == nil, "Error appending to task timeouts: %v", alloc_error)

				case Event_Log_Message:
					_, alloc_error = append(&log_messages, Log_Message {
						level = event.level,
						text = event.formatted_text,
						time = event.time,
						allocator = shared_log_allocator,
					})
					fmt.assertf(alloc_error == nil, "Error appending to log messages: %v", alloc_error)

					if event.level >= .Error {
						// Save the message for the final summary.
						if old_error, ok := failed_test_reason_map[task_channel.test_index]; ok {
							safe_delete_string(old_error, shared_log_allocator)
						}
						failed_test_reason_map[task_channel.test_index] = event.text
					} else {
						delete(event.text, shared_log_allocator)
					}
				}
			}
		}

		check_timeouts: for i := len(task_timeouts) - 1; i >= 0; i -= 1 {
			#no_bounds_check timeout := &task_timeouts[i]

			if time.since(timeout.at_time) < 0 {
				continue check_timeouts
			}

			defer unordered_remove(&task_timeouts, i)

			#no_bounds_check if report.all_test_states[timeout.test_index] > .Running {
				continue check_timeouts
			}

			if !thread.pool_stop_task(&pool, timeout.test_index) {
				// The task may have stopped a split second after we started
				// checking, but we haven't handled the new state yet.
				continue check_timeouts
			}

			#no_bounds_check report.all_test_states[timeout.test_index] = .Failed
			#no_bounds_check it := internal_tests[timeout.test_index]
			#no_bounds_check pkg := report.packages_by_name[it.pkg]
			pkg.frame_ready = false

			if old_error, ok := failed_test_reason_map[timeout.test_index]; ok {
				safe_delete_string(old_error, shared_log_allocator)
			}
			failed_test_reason_map[timeout.test_index] = ERROR_STRING_TIMEOUT
			total_failure_count += 1
			total_done_count += 1

			now := time.now()
			_, alloc_error = append(&log_messages, Log_Message {
				level = .Error,
				text = format_log_text(.Error, ERROR_STRING_TIMEOUT, Default_Test_Logger_Opts, timeout.location, now),
				time = now,
				allocator = context.allocator,
			})
			fmt.assertf(alloc_error == nil, "Error appending to log messages: %v", alloc_error)

			find_task_data_for_timeout: for &data in task_data_slots {
				if data.it.pkg == it.pkg && data.it.name == it.name {
					end_t(&data.t)
					break find_task_data_for_timeout
				}
			}
		}

		if should_stop_runner() {
			fmt.wprintln(stderr, "\nCaught interrupt signal. Stopping all tests.")
			thread.pool_shutdown(&pool)
			break main_loop
		}

		when FANCY_OUTPUT {
			// Because the bounds checking procs send directly to STDERR with
			// no way to redirect or handle them, we need to at least try to
			// let the user see those messages when using the animated progress
			// report. This flag may be set by the block of code below if a
			// signal is raised.
			//
			// It'll be purely by luck if the output is interleaved properly,
			// given the nature of non-thread-safe printing.
			//
			// At worst, if Odin did not print any error for this signal, we'll
			// just re-display the progress report. The fatal log error message
			// should be enough to clue the user in that something dire has
			// occurred.
			bypass_progress_overwrite := false
		}

		if test_index, reason, ok := should_stop_test(); ok {
			#no_bounds_check report.all_test_states[test_index] = .Failed
			#no_bounds_check it := internal_tests[test_index]
			#no_bounds_check pkg := report.packages_by_name[it.pkg]
			pkg.frame_ready = false

			found := thread.pool_stop_task(&pool, test_index)
			fmt.assertf(found, "A signal (%v) was raised to stop test #%i %s.%s, but it was unable to be found.",
				reason, test_index, it.pkg, it.name)

			// The order this is handled in is a little particular.
			task_data: ^Task_Data
			find_task_data_for_stop_signal: for &data in task_data_slots {
				if data.it.pkg == it.pkg && data.it.name == it.name {
					task_data = &data
					break find_task_data_for_stop_signal
				}
			}

			fmt.assertf(task_data != nil, "A signal (%v) was raised to stop test #%i %s.%s, but its task data is missing.",
				reason, test_index, it.pkg, it.name)

			if !task_data.t._fail_now_called {
				if test_index not_in failed_test_reason_map {
					// We only write a new error message here if there wasn't one
					// already, because the message we can provide based only on
					// the signal won't be very useful, whereas asserts and panics
					// will provide a user-written error message.
					failed_test_reason_map[test_index] = fmt.aprintf("Signal caught: %v", reason, allocator = shared_log_allocator)
					log.fatalf("Caught signal to stop test #%i %s.%s for: %v.", test_index, it.pkg, it.name, reason)
				}

				when FANCY_OUTPUT {
					bypass_progress_overwrite = true
					signals_were_raised = true
				}
			}

			end_t(&task_data.t)

			total_failure_count += 1
			total_done_count += 1
		}

		// -- Redraw.

		when FANCY_OUTPUT {
			if len(log_messages) == 0 && !needs_to_redraw(report) {
				continue main_loop
			}

			if !bypass_progress_overwrite {
				fmt.wprintf(stdout, ansi_redraw_string, total_done_count, total_test_count)
			}
		} else {
			if total_done_count != last_done_count {
				fmt.wprintf(stdout, OSC_WINDOW_TITLE, total_done_count, total_test_count)
				last_done_count = total_done_count
			}

			if len(log_messages) == 0 {
				continue main_loop
			}
		}

		// Because each thread has its own messenger channel, log messages
		// arrive in chunks that are in-order, but when they're merged with the
		// logs from other threads, they become out-of-order.
		slice.stable_sort_by(log_messages[:], proc(a, b: Log_Message) -> bool {
			return time.diff(a.time, b.time) > 0
		})

		for message in log_messages {
			fmt.wprintln(batch_writer, message.text)
			delete(message.text, message.allocator)
		}

		fmt.wprint(stderr, bytes.buffer_to_string(&batch_buffer))
		clear(&log_messages)
		bytes.buffer_reset(&batch_buffer)

		when FANCY_OUTPUT {
			redraw_report(batch_writer, report)
			draw_status_bar(batch_writer, thread_count_status_string, total_done_count, total_test_count)
			fmt.wprint(stdout, bytes.buffer_to_string(&batch_buffer))
			bytes.buffer_reset(&batch_buffer)
		}
	}

	// -- All tests are complete, or the runner has been interrupted.

	// NOTE(Feoramund): If you've arrived here after receiving signal 11 or
	// SIGSEGV on the main runner thread, while using a UNIX-like platform,
	// there is the possibility that you may have encountered a rare edge case
	// involving the joining of threads.
	//
	// At the time of writing, the thread library is undergoing a rewrite that
	// should solve this problem; it is not an issue with the test runner itself.
	thread.pool_join(&pool)

	finished_in := time.since(start_time)

	when !FANCY_OUTPUT {
		// One line to space out the results, since we don't have the status
		// bar in plain mode.
		fmt.wprintln(batch_writer)
	}

	fmt.wprintf(batch_writer,
		"Finished %i test%s in %v.",
		total_done_count,
		"" if total_done_count == 1 else "s",
		finished_in)
	
	if total_done_count != total_test_count {
		not_run_count := total_test_count - total_done_count
		fmt.wprintf(batch_writer,
			" " + SGR_READY + "%i" + SGR_RESET + " %s left undone.",
			not_run_count,
			"test was" if not_run_count == 1 else "tests were")
	}

	if total_success_count == total_test_count {
		fmt.wprintfln(batch_writer,
			" %s " + SGR_SUCCESS + "successful." + SGR_RESET,
			"The test was" if total_test_count == 1 else "All tests were")
	} else if total_failure_count > 0 {
		if total_failure_count == total_test_count {
			fmt.wprintfln(batch_writer,
				" %s " + SGR_FAILED + "failed." + SGR_RESET,
				"The test" if total_test_count == 1 else "All tests")
		} else {
			fmt.wprintfln(batch_writer,
				" " + SGR_FAILED + "%i" + SGR_RESET + " test%s failed.",
				total_failure_count,
				"" if total_failure_count == 1 else "s")
		}

		for test_index in failed_test_reason_map {
			_, alloc_error = append(&sorted_failed_test_reasons, test_index)
			fmt.assertf(alloc_error == nil, "Error appending to sorted failed test reasons: %v", alloc_error)
		}

		slice.sort(sorted_failed_test_reasons[:])

		for test_index in sorted_failed_test_reasons {
			#no_bounds_check last_error := failed_test_reason_map[test_index]
			#no_bounds_check it := internal_tests[test_index]
			pkg_and_name := fmt.tprintf("%s.%s", it.pkg, it.name)
			fmt.wprintfln(batch_writer, " - %- *[1]s\t%s",
				pkg_and_name,
				report.pkg_column_len + report.test_column_len,
				last_error)
			safe_delete_string(last_error, shared_log_allocator)
		}

		if total_success_count > 0 {
			when USE_CLIPBOARD {
				clipboard_writer := io.to_writer(bytes.buffer_to_stream(&clipboard_buffer))
				fmt.wprint(clipboard_writer, "-define:ODIN_TEST_NAMES=")
				for test_index in sorted_failed_test_reasons {
					#no_bounds_check it := internal_tests[test_index]
					fmt.wprintf(clipboard_writer, "%s.%s,", it.pkg, it.name)
				}

				encoded_names := base64.encode(bytes.buffer_to_bytes(&clipboard_buffer), allocator = context.temp_allocator)

				fmt.wprintf(batch_writer,
					ansi.OSC + ansi.CLIPBOARD + ";c;%s" + ansi.ST + 
					"\nThe name%s of the failed test%s been copied to your clipboard.",
					encoded_names,
					"" if total_failure_count == 1 else "s",
					" has" if total_failure_count == 1 else "s have")
			} else {
				fmt.wprintf(batch_writer, "\nTo run only the failed test%s, use:\n\t-define:ODIN_TEST_NAMES=",
					"" if total_failure_count == 1 else "s")
				for test_index in sorted_failed_test_reasons {
					#no_bounds_check it := internal_tests[test_index]
					fmt.wprintf(batch_writer, "%s.%s,", it.pkg, it.name)
				}
				fmt.wprint(batch_writer, "\n\nIf your terminal supports OSC 52, you may use -define:ODIN_TEST_CLIPBOARD to have this copied directly to your clipboard.")
			}

			fmt.wprintln(batch_writer)
		}
	}

	fmt.wprint(stdout, ansi.CSI + ansi.DECTCEM_SHOW)

	when FANCY_OUTPUT {
		if signals_were_raised {
			fmt.wprintln(batch_writer, `
Signals were raised during this test run. Log messages are likely to have collided with each other.
To partly mitigate this, redirect STDERR to a file or use the -define:ODIN_TEST_FANCY=false option.`)
		}
	}

	fmt.wprintln(stderr, bytes.buffer_to_string(&batch_buffer))

	when JSON_REPORT != "" {
		json_report: JSON

		mode: int
		when ODIN_OS != .Windows {
			mode = os.S_IRUSR|os.S_IWUSR|os.S_IRGRP|os.S_IROTH
		}
		json_fd, err := os.open(JSON_REPORT, os.O_WRONLY|os.O_CREATE|os.O_TRUNC, mode)
		fmt.assertf(err == nil, "unable to open file %q for writing of JSON report, error: %v", JSON_REPORT, err)
		defer os.close(json_fd)

		for test, i in report.all_tests {
			#no_bounds_check state := report.all_test_states[i]

			if test.pkg not_in json_report.packages {
				json_report.packages[test.pkg] = {}
			}

			tests := &json_report.packages[test.pkg]
			append(tests, JSON_Test{name = test.name, success = state == .Successful})
		}

		json_report.total    = len(internal_tests)
		json_report.success  = total_success_count
		json_report.duration = finished_in

		err := json.marshal_to_writer(os.stream_from_handle(json_fd), json_report, &{ pretty = true })
		fmt.assertf(err == nil, "Error writing JSON report: %v", err)
	}

	return total_success_count == total_test_count
}
