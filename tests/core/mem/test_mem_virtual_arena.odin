package test_core_mem

import "core:mem"
import "core:mem/virtual"
import "core:sync"
import "core:testing"
import "core:thread"

ARENA_THREADS       :: 8
ARENA_THREAD_ALLOCS :: 2048
ARENA_RACERS        :: 4

Arena_Thread_Alloc :: struct {
	data:    []byte,
	pattern: byte,
}

Arena_Worker :: struct {
	allocator: mem.Allocator,
	barrier:   ^sync.Barrier,
	rng:       u64,
	id:        int,
	allocs:    []Arena_Thread_Alloc,
	problem:   string,
}

@(require_results)
arena_worker_below :: proc(w: ^Arena_Worker, n: int) -> int {
	w.rng ~= w.rng << 13
	w.rng ~= w.rng >> 7
	w.rng ~= w.rng << 17
	return int(w.rng % u64(n))
}

arena_worker_proc :: proc(w: ^Arena_Worker) {
	sync.barrier_wait(w.barrier)
	for &a, i in w.allocs {
		size := 1 + arena_worker_below(w, 512)
		if arena_worker_below(w, 64) == 0 {
			size = 16*mem.Kilobyte + arena_worker_below(w, 48*mem.Kilobyte)
		}
		align := 1 << uint(arena_worker_below(w, 7))
		zero  := arena_worker_below(w, 2) == 0

		data: []byte
		err:  mem.Allocator_Error
		if zero {
			data, err = mem.alloc_bytes(size, align, w.allocator)
		} else {
			data, err = mem.alloc_bytes_non_zeroed(size, align, w.allocator)
		}
		switch {
		case err != nil:
			w.problem = "an allocation failed"
		case len(data) != size:
			w.problem = "an allocation has the wrong length"
		case uintptr(raw_data(data)) & uintptr(align-1) != 0:
			w.problem = "an allocation is misaligned"
		case zero && count_byte(data, 0) != size:
			w.problem = "a zeroed allocation is not zero"
		}
		if w.problem != "" {
			return
		}

		a.pattern = byte((w.id*len(w.allocs) + i)%255 + 1)
		mem.set(raw_data(data), a.pattern, size)
		a.data = data

		// Grows in place only if no other thread allocated in between.
		if arena_worker_below(w, 8) == 0 {
			grown, grow_err := mem.resize_bytes(data, size + 1 + arena_worker_below(w, 256), align, w.allocator)
			switch {
			case grow_err != nil:
				w.problem = "a resize failed"
			case count_byte(grown[:size], a.pattern) != size:
				w.problem = "a resize lost the old contents"
			case count_byte(grown[size:], 0) != len(grown)-size:
				w.problem = "a resize did not zero the new part"
			}
			if w.problem != "" {
				return
			}
			mem.set(raw_data(grown), a.pattern, len(grown))
			a.data = grown
		}
	}
}

@(test)
test_virtual_arena_threads :: proc(t: ^testing.T) {
	for kind in ([?]virtual.Arena_Kind{.Growing, .Static}) {
		arena: virtual.Arena
		switch kind {
		case .Growing:
			testing.expect_value(t, virtual.arena_init_growing(&arena, 256*mem.Kilobyte), nil)
		case .Static:
			testing.expect_value(t, virtual.arena_init_static(&arena, reserved=256*mem.Megabyte, commit_size=64*mem.Kilobyte), nil)
		case .Buffer:
		}
		defer virtual.arena_destroy(&arena)

		workers: [ARENA_THREADS]Arena_Worker
		for &w, i in workers {
			w.allocator = virtual.arena_allocator(&arena)
			w.id        = i
			w.allocs    = make([]Arena_Thread_Alloc, ARENA_THREAD_ALLOCS)
		}
		defer for w in workers {
			delete(w.allocs)
		}

		for round in 0..<3 {
			barrier: sync.Barrier
			sync.barrier_init(&barrier, ARENA_THREADS)

			threads: [ARENA_THREADS]^thread.Thread
			for &w, i in workers {
				w.barrier  = &barrier
				w.rng      = t.seed + u64(round*ARENA_THREADS + i) | 1
				threads[i] = thread.create_and_start_with_poly_data(&w, arena_worker_proc)
			}
			thread.join_multiple(..threads[:])
			for th in threads {
				thread.destroy(th)
			}

			for w in workers {
				if !testing.expectf(t, w.problem == "", "%v arena, round %d: %s", kind, round, w.problem) {
					return
				}
				for a in w.allocs {
					if !testing.expectf(t, count_byte(a.data, a.pattern) == len(a.data), "%v arena, round %d: allocations overlap", kind, round) {
						return
					}
				}
			}
			virtual.arena_free_all(&arena)
		}
	}
}

@(test)
test_virtual_arena_single_thread_flag :: proc(t: ^testing.T) {
	buffer := make([]byte, 16*mem.Megabyte)
	defer delete(buffer)

	for kind in virtual.Arena_Kind {
		arena: virtual.Arena
		testing.expect_value(t, init_virtual_arena(&arena, kind, buffer), nil)
		arena.flags = {.Single_Thread}
		defer virtual.arena_destroy(&arena)

		barrier: sync.Barrier
		sync.barrier_init(&barrier, 1)

		w := Arena_Worker{
			allocator = virtual.arena_allocator(&arena),
			barrier   = &barrier,
			rng       = t.seed | 1,
			allocs    = make([]Arena_Thread_Alloc, ARENA_THREAD_ALLOCS),
		}
		defer delete(w.allocs)

		for round in 0..<3 {
			arena_worker_proc(&w)
			if !testing.expectf(t, w.problem == "", "%v arena, round %d: %s", kind, round, w.problem) {
				return
			}
			for a in w.allocs {
				if !testing.expectf(t, count_byte(a.data, a.pattern) == len(a.data), "%v arena, round %d: allocations overlap", kind, round) {
					return
				}
			}
			virtual.arena_free_all(&arena)
		}
	}
}

Arena_Racer :: struct {
	allocator: mem.Allocator,
	stop:      ^bool,
	failures:  int,
}

arena_racer_proc :: proc(r: ^Arena_Racer) {
	for i := 0; !sync.atomic_load(r.stop); i += 1 {
		data: []byte
		err:  mem.Allocator_Error
		if i%2 == 0 {
			data, err = mem.alloc_bytes(64, 16, r.allocator)
		} else {
			data, err = mem.alloc_bytes_non_zeroed(64, 16, r.allocator)
		}
		if err != nil || len(data) != 64 {
			r.failures += 1
		}
	}
}

@(test)
test_virtual_arena_free_all_racing_allocations :: proc(t: ^testing.T) {
	arena: virtual.Arena
	testing.expect_value(t, virtual.arena_init_growing(&arena, 256*mem.Kilobyte), nil)
	defer virtual.arena_destroy(&arena)
	allocator := virtual.arena_allocator(&arena)

	// The racers never write to their memory: `free_all` may release it under them.
	stop:    bool
	racers:  [ARENA_RACERS]Arena_Racer
	threads: [ARENA_RACERS]^thread.Thread
	for &r, i in racers {
		r.allocator = allocator
		r.stop      = &stop
		threads[i]  = thread.create_and_start_with_poly_data(&r, arena_racer_proc)
	}
	for _ in 0..<100 {
		virtual.arena_free_all(&arena)
	}
	sync.atomic_store(&stop, true)
	thread.join_multiple(..threads[:])
	for r, i in racers {
		thread.destroy(threads[i])
		testing.expect_value(t, r.failures, 0)
	}

	virtual.arena_free_all(&arena)
	allocs: [1000][]byte
	for &data, i in allocs {
		err: mem.Allocator_Error
		data, err = mem.alloc_bytes(1 + i%300, 16, allocator)
		testing.expect_value(t, err, nil)
		testing.expect_value(t, count_byte(data, 0), len(data))
		mem.set(raw_data(data), byte(i%255 + 1), len(data))
	}
	for data, i in allocs {
		testing.expect_value(t, count_byte(data, byte(i%255 + 1)), len(data))
	}
}
