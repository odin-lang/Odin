/*
A priority queue data structure.

Important: It needs to be initialized with `less` and `swap` procedures, see `init` and `init_from_dynamic_array`.

Example:
	import "base:runtime"
	import pq "core:container/priority_queue"

	main :: proc() {
		Printer_Job :: struct {
			user_id: u64,
			weight:  enum u8 {Highest, High, Normal, Low, Idle},
		}

		q: pq.Priority_Queue(Printer_Job)
		pq.init(
			pq   = &q,
			less = proc(a, b: Printer_Job) -> bool {
				// Jobs will be sorted in order of increasing weight
				return a.weight < b.weight
			},
			swap = pq.default_swap_proc(Printer_Job),
		)
		defer pq.destroy(&q)

		// Add jobs with random weights
		for _ in 0..<100 {
			job: Printer_Job = ---
			assert(runtime.random_generator_read_ptr(context.random_generator, &job, size_of(job)))
			pq.push(&q, job)
		}

		// Drain jobs in order of importance
		last: Printer_Job
		for pq.len(q) > 0 {
			v := pq.pop(&q)
			assert(v.weight >= last.weight)
			last = v
		}

		// Queue empty?
		assert(pq.len(q) == 0)

		// Add one more job
		pq.push(&q, Printer_Job{user_id = 42, weight = .Idle})

		// Cancel all jobs
		pq.clear(&q)
		assert(pq.len(q) == 0)
	}
*/
package container_priority_queue