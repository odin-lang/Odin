// In order to test the heap allocator in a deterministic manner, we must run
// this program without the help of the test runner, because the runner itself
// makes use of heap allocation.
package tests_heap_allocator

import "base:intrinsics"
import "base:runtime"
import "core:flags"
import "core:fmt"
import "core:log"
import "core:math/rand"
import "core:os"
import "core:sync"
import "core:thread"
import "core:time"
import "core:mem"

import libc_allocator "libc"

ODIN_DEBUG_HEAP :: runtime.ODIN_DEBUG_HEAP

INTEGER_BITS :: 8 * size_of(int)
SECTOR_BITS  :: 8 * size_of(uint)

// The tests are specific to feoramalloc, but the benchmarks are general-purpose.

//
// Utility
//

expect :: proc "contextless" (condition: bool, message := #caller_expression(condition), loc := #caller_location) {
	if !condition {
		@(cold)
		internal :: proc "contextless" (message: string, loc: runtime.Source_Code_Location) {
			runtime.print_string("\n* Expectation failed: ")
			runtime.print_string(message)
			runtime.print_string(" @ ")
			runtime.print_caller_location(loc)
			runtime.print_string("\n\n")
			when ODIN_DEBUG {
				intrinsics.debug_trap()
			} else {
				intrinsics.trap()
			}
		}
		internal(message, loc)
	}
}

verify_zeroed_slice :: proc(bytes: []byte, loc := #caller_location) {
	for b in bytes {
		expect(b == 0, loc = loc)
	}
}

verify_zeroed_ptr :: proc(ptr: [^]byte, size: int, loc := #caller_location) {
	for i := 0; i < size; i += 1 {
		expect(ptr[i] == 0, loc = loc)
	}
}

verify_zeroed :: proc {
	verify_zeroed_slice,
	verify_zeroed_ptr,
}

verify_integrity_slice :: proc(bytes: []byte, seed: u64, loc := #caller_location) {
	buf: [1]byte
	rand.reset(seed)
	for i := 0; i < len(bytes); i += len(buf) {
		expect(rand.read(buf[:]) == len(buf), loc = loc)
		length := min(len(buf), len(bytes) - i)
		for j := 0; j < length; j += 1 {
			expect(bytes[i+j] == buf[j], loc = loc)
		}
	}
}

verify_integrity_ptr :: proc(ptr: [^]byte, size: int, seed: u64, loc := #caller_location) {
	verify_integrity_slice(transmute([]byte)runtime.Raw_Slice{
		data = ptr,
		len = size,
	}, seed, loc)
}

verify_integrity :: proc {
	verify_integrity_slice,
	verify_integrity_ptr,
}


randomize_bytes_slice :: proc(bytes: []byte, seed: u64, loc := #caller_location) {
	rand.reset(seed)
	buf: [1]byte
	for i := 0; i < len(bytes); i += len(buf) {
		expect(rand.read(buf[:]) == len(buf), loc = loc)
		length := min(len(buf), len(bytes) - i)
		for j := 0; j < length; j += 1 {
			bytes[i+j] = buf[j]
		}
	}
}

randomize_bytes_ptr :: proc(ptr: [^]byte, size: int, seed: u64, loc := #caller_location) {
	randomize_bytes_slice(transmute([]byte)runtime.Raw_Slice{
		data = ptr,
		len = size,
	}, seed, loc)
}

randomize_bytes :: proc {
	randomize_bytes_slice,
	randomize_bytes_ptr,
}

dump_slabs :: proc() {
	intrinsics.atomic_thread_fence(.Seq_Cst)
	superpage := runtime.local_heap
	for {
		if superpage == nil {
			return
		}
		log.infof("+++ Superpage at %p", superpage)
		log.infof(" -  Free slabs: %i", superpage.free_slabs)
		log.infof(" -  Next free slab index: %i", superpage.next_free_slab_index)
		for i := 0; i < runtime.HEAP_SLAB_COUNT; /**/ {
			slab := runtime.heap_superpage_index_slab(superpage, i)
			if slab.bin_size == 0 {
				// log.infof("Slab %i unused.", slab.index)
				expect(i == slab.index)
			} else {
				log.infof("%#v", slab)
				if slab.free_bins == 0 {
					expect(intrinsics.atomic_load(&slab.is_full))
				}
			}
			if slab.bin_size > runtime.HEAP_MAX_BIN_SIZE {
				// Skip contiguous slabs.
				i += runtime.heap_slabs_needed_for_size(slab.bin_size)
			} else {
				i += 1
			}
		}
		log.info("")
		superpage = superpage.next
	}
}

validate_cache :: proc() {
	cache := runtime.local_heap_cache
	slab_map_terminated: [runtime.HEAP_BIN_RANKS]bool
	superpages_with_free_slabs_terminated: bool
	for {
		// Validate the slab map.
		for rank in 0..<runtime.HEAP_BIN_RANKS {
			start := rank * runtime.HEAP_CACHE_SLAB_MAP_STRIDE
			for i := start; i < start+runtime.HEAP_CACHE_SLAB_MAP_STRIDE; i += 1 {
				slab := cache.slab_map[i]
				if slab_map_terminated[rank] {
					expect(slab == nil)
				} else if slab == nil {
					slab_map_terminated[rank] = true
				} else {
					expect(rank == runtime.heap_bin_size_to_rank(slab.bin_size))
				}
			}
		}

		// Validate the list of superpages with free slabs.
		for i := 0; i < len(cache.superpages_with_free_slabs); i += 1 {
			superpage := cache.superpages_with_free_slabs[i]
			if superpages_with_free_slabs_terminated {
				expect(superpage == nil)
			} else if superpage == nil {
				superpages_with_free_slabs_terminated = true
			} else {
				expect(superpage.free_slabs > 0)
			}
		}

		next_cache := intrinsics.atomic_load_explicit(&cache.next_cache_block, .Acquire)
		if next_cache == nil {
			break
		}
		cache = next_cache
	}
}

//
// Allocation API Testing
//

Size_Strategy :: enum {
	Adding,
	Multiplying,
	Randomizing,
}

Free_Strategy :: enum {
	Never,
	At_The_End,  // free at end of allocs
	Interleaved, // free X after Y allocs
}

Free_Direction :: enum {
	Forward,  // like a queue
	Backward, // like a stack
	Randomly,
}

test_alloc_write_free :: proc(
	object_count: int,

	starting_size: int,
	final_size: int,

	size_strategy: Size_Strategy,
	size_operand: int,

	allocs_per_free_operation: int,
	free_operations_at_once: int,
	free_strategy: Free_Strategy,
	free_direction: Free_Direction,
) {
	Allocation :: struct {
		data: []byte,
		seed: u64,
	}
	pointers := make([]Allocation, object_count, context.temp_allocator)

	allocator := context.allocator
	size := starting_size
	start_index := 0
	end_index := 0

	allocs := 0

	log.infof("AWF: %i objects. Size: [%i..=%i] %v by %i each allocation. %i freed every %i, %v and %v.", object_count, starting_size, final_size, size_strategy, size_operand, free_operations_at_once, allocs_per_free_operation, free_strategy, free_direction)

	for o in 1..=u64(object_count) {
		seed := u64(intrinsics.read_cycle_counter()) * o
		alignment := min(size, runtime.HEAP_MAX_ALIGNMENT)

		bytes, alloc_err := allocator.procedure(allocator.data, .Alloc, size, alignment, nil, 0)
		expect(alloc_err == nil)
		pointers[end_index] = Allocation{
			data = bytes,
			seed = seed,
		}
		end_index += 1
		allocs += 1

		verify_zeroed(bytes)
		randomize_bytes(bytes, seed)

		if size < final_size {
			switch size_strategy {
			case .Adding:      size += size_operand
			case .Multiplying: size *= size_operand
			case .Randomizing: size = starting_size + rand.int_max(final_size - starting_size)
			}
			if final_size > starting_size {
				size = min(size, final_size)
			} else {
				size = max(size, final_size)
			}
		}

		if allocs % allocs_per_free_operation != 0 {
			continue
		}

		switch free_strategy {
		case .Never, .At_The_End:
			break
		case .Interleaved:
			for _ in 0..<free_operations_at_once {
				ptr: Allocation
				switch free_direction {
				case .Forward:
					ptr = pointers[start_index]
					start_index += 1
				case .Backward:
					ptr = pointers[end_index - 1]
					end_index -= 1
				case .Randomly:
					index := start_index + rand.int_max(end_index - start_index)
					ptr = pointers[index]
					pointers[index] = pointers[end_index - 1] // unordered_remove
					end_index -= 1
				}
				verify_integrity(ptr.data, ptr.seed)
				_, free_err := allocator.procedure(allocator.data, .Free, 0, 0, raw_data(ptr.data), 0)
				expect(free_err == nil)
			}
		}


		if o % max(1, u64(object_count / 20)) == 0 {
			validate_cache()
		}
	}

	if end_index - start_index != 0 || free_strategy == .At_The_End {
		for i in start_index..<end_index {
			ptr := pointers[i]
			verify_integrity(ptr.data, ptr.seed)
			_, free_err := allocator.procedure(allocator.data, .Free, 0, 0, raw_data(ptr.data), 0)
			expect(free_err == nil)
		}
	}
}


test_continuous_allocation_of_size_n :: proc(count: int, max_size: int) {
	buf := make([][^]byte, count, context.temp_allocator)

	log.infof("Testing continuous allocation of all sizes from 0 to %i, for %i objects each.", max_size, count)
	allocator := context.allocator
	base_seed := u64(intrinsics.read_cycle_counter())
	for size in 0..<max_size {
		alignment := min(size, runtime.HEAP_MAX_ALIGNMENT)
		seed := base_seed * (1+u64(size))

		for i in 0..<count {
			bytes, alloc_err := allocator.procedure(allocator.data, .Alloc, size, alignment, nil, 0)
			expect(alloc_err == nil)
			buf[i] = raw_data(bytes)
			// Verify the fresh memory is zeroed.
			verify_zeroed(bytes)
		}
		for ptr in buf {
			// Verify the memory is all zeroes at the end of allocation.
			verify_zeroed(ptr, size)
		}
		for ptr in buf {
			// Verify that the memory continues to be zero as other memory is being randomized.
			verify_zeroed(ptr, size)
			randomize_bytes(ptr, size, seed)
		}
		for ptr in buf {
			// Verify that all of the memory is intact, as other memory is being freed.
			verify_integrity(ptr, size, seed)
			_, free_err := allocator.procedure(allocator.data, .Free, 0, 0, ptr, 0)
			expect(free_err == nil)
		}
	}
}

test_individual_allocation_and_free :: proc(count: int) {
	log.infof("Testing allocation of all sizes from 0 to %i.", count)
	allocator := context.allocator
	different_pointers := 0
	for size in 0..<count {
		if size > 0 && size % (runtime.HEAP_MAX_BIN_SIZE/8) == 0 {
			log.infof("... %i ...", size)
		}
		alignment := min(size, runtime.HEAP_MAX_ALIGNMENT)

		// Allocate and free twice to make sure that the memory is truly zeroed.
		//
		// This works on the assumption that the allocator will return the same
		// pointer if we allocate, free, then allocate again with the same
		// characteristics.
		//
		// libc malloc does not guarantee this behavior, but feoramalloc does
		// in non-parallel scenarios.
		old_ptr: rawptr
		for i in 0..<2 {
			bytes, alloc_err := allocator.procedure(allocator.data, .Alloc, size, alignment, nil, 0)
			if i == 0 {
				old_ptr = raw_data(bytes)
			} else {
				if old_ptr != raw_data(bytes) {
					different_pointers += 1
				}
			}
			expect(alloc_err == nil)
			verify_zeroed(bytes)
			randomize_bytes(bytes, u64(intrinsics.read_cycle_counter()))
			_, free_err := allocator.procedure(allocator.data, .Free, 0, 0, raw_data(bytes), 0)
			expect(free_err == nil)
		}
	}
	if different_pointers > 0 {
		log.warnf("There were %i cases in which the allocator didn't return the same pointer after allocating, freeing, then allocating again with the same size.", different_pointers)
	}
	log.info("Done.")
}

test_single_alloc_and_resize :: proc(start, target: int) {
	log.infof("Testing allocation of %i bytes, resizing to %i, then resizing back.", start, target)
	allocator := context.allocator
	base_seed := u64(intrinsics.read_cycle_counter())

	alignment := min(start, runtime.HEAP_MAX_ALIGNMENT)
	seed := base_seed * (1+u64(start))

	bytes, alloc_err := allocator.procedure(allocator.data, .Alloc, start, alignment, nil, 0)
	expect(alloc_err == nil)
	expect(len(bytes) == start)
	verify_zeroed(bytes)
	randomize_bytes(bytes, seed)

	resized_bytes_1, resize_1_err := allocator.procedure(allocator.data, .Resize, target, alignment, raw_data(bytes), start)
	expect(resize_1_err == nil)
	expect(len(resized_bytes_1) == target)
	verify_integrity(resized_bytes_1[:min(start, target)], seed)
	if target > start {
		verify_zeroed(resized_bytes_1[start:])
	}

	resized_bytes_2, resize_2_err := allocator.procedure(allocator.data, .Resize, start, alignment, raw_data(resized_bytes_1), target)
	expect(resize_2_err == nil)
	expect(len(resized_bytes_2) == start)
	verify_integrity(resized_bytes_2[:min(start, target)], seed)
	if start > target {
		verify_zeroed(resized_bytes_2[target:])
	}

	_, free_err := allocator.procedure(allocator.data, .Free, 0, 0, raw_data(resized_bytes_2), 0)
	expect(free_err == nil)
}

/*
This test helped find an issue with the orphanage.
*/
test_parallel_pointer_passing :: proc(thread_count: int) {
	Data :: struct {
		thread: ^thread.Thread,
		ptr: ^^int,
		sema: sync.Sema,
		friend: ^sync.Sema,
		wg: ^sync.Wait_Group,
	}

	task :: proc(t: ^thread.Thread) {
		data := cast(^Data)t.data
		sync.wait(&data.sema)
		expect(data.ptr != nil)
		expect(data.ptr^ != nil)
		expect(data.ptr^^ != 0)
		free(data.ptr^)
		data.ptr^ = new(int)
		expect(data.ptr^^ == 0)
		data.ptr^^ = int(intrinsics.read_cycle_counter())
		if data.friend != nil {
			sync.post(data.friend)
		}
		sync.wait_group_done(data.wg)
	}

	data := new(int)
	data^ = int(intrinsics.read_cycle_counter())
	tasks := make([]Data, thread_count, context.temp_allocator)

	wg: sync.Wait_Group
	sync.wait_group_add(&wg, thread_count)
	
	for i in 0..<thread_count-1 {
		tasks[i].friend = &tasks[i+1].sema
	}

	for i in 0..<thread_count {
		tasks[i].ptr = &data
		tasks[i].wg = &wg
		tasks[i].thread = thread.create(task)
		tasks[i].thread.data = &tasks[i]
		tasks[i].thread.init_context = context
		thread.start(tasks[i].thread)
	}

	sync.post(&tasks[0].sema)
	sync.wait_group_wait(&wg)

	for i in 0..<thread_count {
		thread.join(tasks[i].thread)
		thread.destroy(tasks[i].thread)
	}

	// Free the final pointer.
	free(tasks[len(tasks)-1].ptr^)

	log.info("Parallel pointer write test succeeded.")
}

/*
This test makes sure that a Superpage is reused when abandoned by a thread and
picked up by a different one.
*/
test_superpage_abandonment_and_reuse :: proc() {
	Alloc_Data :: struct {
		thread: ^thread.Thread,
		slice: []int,
		signature: rawptr,
		done: sync.Sema,
	}

	alloc_task :: proc(t: ^thread.Thread) {
		// In this first thread, we allocate a small chunk of memory in a new
		// superpage and mark where it came from.
		data := cast(^Alloc_Data)t.data
		data.slice = make([]int, 4096)
		data.signature = runtime.find_superpage_from_pointer(raw_data(data.slice))
		for &v, i in data.slice {
			v = i
		}
		sync.post(&data.done)
		// Shortly after this point, the thread cleanly exits
	}

	reuse_task :: proc(t: ^thread.Thread) {
		// In the second thread here, we'll assert the memory is as we expect
		// and check the signature of the slice's raw data.
		data := cast(^Alloc_Data)t.data
		for v, i in data.slice {
			expect(v == i)
		}
		// Delete the data and allocate a new integer. If everything works as
		// expected, this thread will have remotely freed the old chunk of
		// memory, then adopted the superpage with the new operation.
		//
		// Upon adoption, the remote free should be acknowledged.
		delete(data.slice)
		x := new(int)
		free(x)
		// This is where we check to make sure the new pointer comes from the
		// same place as the old data.
		expect(runtime.find_superpage_from_pointer(x) == data.signature)
		sync.post(&data.done)
	}

	data: Alloc_Data
	allocer := thread.create(alloc_task)
	allocer.init_context = context
	allocer.data = &data

	thread.start(allocer)

	sync.wait(&data.done)

	// It will take an infinitesimal amount of time for the superpage to be
	// pushed to the orphanage, so let's wait a (rather long) moment.
	time.sleep(1 * time.Millisecond)

	reuser := thread.create(reuse_task)
	reuser.init_context = context
	reuser.data = &data

	thread.start(reuser)

	sync.wait(&data.done)

	thread.join(allocer)
	thread.join(reuser)
	thread.destroy(allocer)
	thread.destroy(reuser)
	log.info("Superpage abandonment and reuse test succeeded.")
}

/*
This test ensures a pointer can be resized by any thread, which should cause
the thread to take ownership if a size change is needed.
*/
test_parallel_pointer_resizing :: proc(thread_count: int) {
	Data :: struct {
		thread: ^thread.Thread,
		step: byte,
		ptr: ^[^]byte,
		len: ^int,
		sema: sync.Sema,
		friend: ^sync.Sema,
		wg: ^sync.Wait_Group,
	}

	task :: proc(t: ^thread.Thread) {
		data := cast(^Data)t.data
		expect(data.ptr != nil)
		expect(data.len != nil)
		sync.wait(&data.sema)

		for i := 0; i < data.len^; i += 1 {
			expect(data.ptr^[i] == data.step)
		}
		allocator := context.allocator

		old_len := data.len^
		new_len := old_len*2

		resized_ptr, resize_err := allocator.procedure(allocator.data, .Resize, new_len, 1, data.ptr^, old_len)
		expect(resize_err == nil)

		// If we're dealing with sub-slab sizes, the pointer should stay the
		// same if the bin rank did not change.
		if new_len <= runtime.HEAP_SLAB_SIZE {
			old_rank := runtime.heap_bin_size_to_rank(runtime.heap_round_to_bin_size(old_len))
			new_rank := runtime.heap_bin_size_to_rank(runtime.heap_round_to_bin_size(new_len))

			if old_rank == new_rank {
				expect(raw_data(resized_ptr) == data.ptr^)
			} else {
				expect(raw_data(resized_ptr) != data.ptr^)
			}
		}

		data.ptr^ = raw_data(resized_ptr)
		data.len^ = new_len
		for i := 0; i < new_len; i += 1 {
			resized_ptr[i] = data.step + 1
		}

		if data.friend != nil {
			sync.post(data.friend)
		}
		sync.wait_group_done(data.wg)
	}

	len: int = 2
	data: [^]byte = raw_data(make([]byte, len))
	tasks := make([]Data, thread_count, context.temp_allocator)
	for i := 0; i < len; i += 1 {
		data[i] = 1
	}

	wg: sync.Wait_Group
	sync.wait_group_add(&wg, thread_count)
	
	for i in 0..<thread_count-1 {
		tasks[i].friend = &tasks[i+1].sema
	}

	for i in 0..<thread_count {
		tasks[i].ptr = &data
		tasks[i].len = &len
		tasks[i].wg = &wg
		tasks[i].thread = thread.create(task)
		tasks[i].thread.data = &tasks[i]
		tasks[i].thread.init_context = context
		tasks[i].step = 1 + byte(i)
		thread.start(tasks[i].thread)
	}

	sync.post(&tasks[0].sema)
	sync.wait_group_wait(&wg)

	for i in 0..<thread_count {
		thread.join(tasks[i].thread)
		thread.destroy(tasks[i].thread)
	}
	log.info("Parallel pointer resize test succeeded.")
}

test_orphaned_superpage_with_remote_frees :: proc() {
	Data :: struct {
		thread: ^thread.Thread,
		ptr: ^int,
		ptr_ready: sync.Sema,
		task_done: sync.Sema,
	}

	task :: proc(t: ^thread.Thread) {
		data := cast(^Data)t.data
		data.ptr = new(int)
		sync.post(&data.ptr_ready)
		sync.wait(&data.task_done)
	}

	data: Data
	data.thread = thread.create(task)
	data.thread.data = &data
	data.thread.init_context = context
	thread.start(data.thread)

	sync.wait(&data.ptr_ready)
	assert(data.ptr != nil)
	free(data.ptr)
	sync.post(&data.task_done)

	thread.join(data.thread)
	thread.destroy(data.thread)
	log.info("Oprhaned superpage with remote free test succeeded.")
}

test_orphanage_overflow :: proc(thread_count: int) {
	Data :: struct {
		thread: ^thread.Thread,
		barrier: ^sync.Barrier,
		wg: ^sync.Wait_Group,
	}

	task :: proc(t: ^thread.Thread) {
		data := cast(^Data)t.data

		x := new(int)
		intrinsics.mem_zero_volatile(x, size_of(int))
		sync.barrier_wait(data.barrier)

		free(x)

		sync.wait_group_done(data.wg)
	}

	tasks := make([]Data, thread_count, context.temp_allocator)

	barrier: sync.Barrier
	sync.barrier_init(&barrier, thread_count)

	wg: sync.Wait_Group
	sync.wait_group_add(&wg, thread_count)
	
	for i in 0..<thread_count {
		tasks[i].barrier = &barrier
		tasks[i].wg = &wg
		tasks[i].thread = thread.create(task)
		tasks[i].thread.data = &tasks[i]
		tasks[i].thread.init_context = context
		thread.start(tasks[i].thread)
	}

	sync.wait_group_wait(&wg)

	for i in 0..<thread_count {
		thread.join(tasks[i].thread)
		thread.destroy(tasks[i].thread)
	}

	time.sleep(1 * time.Millisecond)

	count := intrinsics.atomic_load_explicit(&runtime.heap_orphanage_count, .Acquire)
	log.debug(count, runtime.HEAP_MAX_EMPTY_ORPHANED_SUPERPAGES)
	expect(count == runtime.HEAP_MAX_EMPTY_ORPHANED_SUPERPAGES)

	log.info("Orphanage overflow test succeeded.")
}

test_single_alloc_and_resize_incremental :: proc(start, target: int) {
	log.infof("Testing allocation of %i bytes, resizing by increments of one until %i is reached.", start, target)
	allocator := context.allocator

	alignment := min(start, runtime.HEAP_MAX_ALIGNMENT)
	seed := u64(intrinsics.read_cycle_counter()) * (1+u64(start))

	bytes, alloc_err := allocator.procedure(allocator.data, .Alloc, start, alignment, nil, 0)
	expect(alloc_err == nil)
	verify_zeroed(bytes)
	randomize_bytes(bytes, seed)

	o := raw_data(bytes)
	for new_size := start + 1; new_size < target; new_size += 1 {
		resized, resize_err := allocator.procedure(allocator.data, .Resize, new_size, alignment, o, new_size - 1)
		expect(resize_err == nil)

		verify_integrity(resized[:new_size-1], seed)
		verify_zeroed(resized[new_size:])
		randomize_bytes(resized, seed)

		o = raw_data(resized)
	}

	_, free_err := allocator.procedure(allocator.data, .Free, 0, 0, o, 0)
	expect(free_err == nil)
}

test_serial_bin_sanity :: proc() {
	log.info("Testing bitmap sanity.")
	o := new(int)
	slab := runtime.find_slab_from_pointer(o)
	log.infof("The slab being tested: %#v", slab)
	expect(slab.dirty_bins == 1)
	expect(slab.free_bins != 0)
	// expect(slab.is_dirty)
	expect(slab.max_bins > 0)
	expect(slab.bin_size > 0)
	expect(intrinsics.atomic_load_explicit(&slab.remote_free_bins_scheduled, .Acquire) == 0)

	list := make([]^int, slab.max_bins)
	list[0] = o

	for i in 0..<slab.max_bins-1 {
		list[i + 1] = new(int)
		expect(slab.dirty_bins == i + 2)
	}

	expect(slab.free_bins == 0)
	expect(slab.dirty_bins == slab.max_bins)

	for sector in 0..<slab.sectors {
		expect(slab.local_free[sector] == 0)
		expect(intrinsics.atomic_load_explicit(&slab.remote_free[sector], .Acquire) == 0)
	}
	expect(intrinsics.atomic_load_explicit(&slab.is_full, .Acquire))

	for ptr in list {
		bin_number := int(uintptr(ptr) - slab.data) / slab.bin_size
		sector := bin_number / INTEGER_BITS
		index := uint(bin_number) % INTEGER_BITS
		expect(slab.local_free[sector] & (1 << index) == 0)
		free(ptr)
		expect(slab.local_free[sector] & (1 << index) != 0)
	}

	for sector in 0..<slab.sectors {
		expect(slab.local_free[sector] != 0)
		expect(intrinsics.atomic_load_explicit(&slab.remote_free[sector], .Acquire) == 0)
	}
	log.info("Done.")
}

//
// Benchmarking
//

Struct_16 :: struct { data: [16]byte }
Struct_32 :: struct { data: [32]byte }
Struct_64 :: struct { data: [64]byte }
Struct_512 :: struct { data: [512]byte }


bench_alloc_n_then_free_n :: proc(n: int, $T: typeid, location := #caller_location) {
	pointers := make([]^T, n)
	defer delete(pointers)

	start := time.now()
	for &pointer in pointers {
		pointer = new(T)
	}
	done := time.since(start)
	log.infof("ALLOC: % 7ix % 12s in % 14s", n, fmt.tprintf("%s", type_info_of(T)), fmt.tprintf("%s", done), location = location)

	start = time.now()
	for pointer in pointers {
		free(pointer)
	}
	done = time.since(start)
	log.infof("FREE:  % 7ix % 12s in % 14s", n, fmt.tprintf("%s", type_info_of(T)), fmt.tprintf("%s", done), location = location)
}

bench_alloc_n_then_free_n_backwards :: proc(n: int, $T: typeid, location := #caller_location) {
	pointers := make([]^T, n)
	defer delete(pointers)

	start := time.now()
	for &pointer in pointers {
		pointer = new(T)
	}
	done := time.since(start)
	log.infof("ALLOC: % 7ix % 12s in % 14s", n, fmt.tprintf("%s", type_info_of(T)), fmt.tprintf("%s", done), location = location)

	start = time.now()
	#reverse for pointer in pointers {
		free(pointer)
	}
	done = time.since(start)
	log.infof("FREE:  % 7ix % 12s in % 14s", n, fmt.tprintf("%s", type_info_of(T)), fmt.tprintf("%s", done), location = location)
}

bench_alloc_n_then_free_n_randomly :: proc(n: int, $T: typeid, location := #caller_location) {
	pointers := make([]^T, n)
	defer delete(pointers)

	start := time.now()
	for &pointer in pointers {
		pointer = new(T)
	}
	done := time.since(start)
	log.infof("ALLOC: % 7ix % 12s in % 14s", n, fmt.tprintf("%s", type_info_of(T)), fmt.tprintf("%s", done), location = location)

	rand.shuffle(pointers)
	start = time.now()
	for pointer in pointers {
		free(pointer)
	}
	done = time.since(start)
	log.infof("FREE:  % 7ix % 12s in % 14s", n, fmt.tprintf("%s", type_info_of(T)), fmt.tprintf("%s", done), location = location)
}

bench_alloc_1_then_free_1_repeatedly :: proc(times: int, $T: typeid, location := #caller_location) {
	start := time.now()
	for _ in 0..<times {
		free(new(T))
	}
	done := time.since(start)
	log.infof("ALLOC+FREE:  1x % 12s %i times in %v", fmt.tprintf("%s", type_info_of(T)), times, done, location = location)
}

/*
This is a benchmark, but it's also a good way to test thread sanity in parallel
operating situations.
*/
bench_1_producer_n_consumer_for_m_alloc :: proc(thread_count: int, allocs_per_thread: int, $T: typeid, location := #caller_location) {
	Consumer_Data :: struct {
		start_time: ^time.Time,
		thread: ^thread.Thread,
		barrier: ^sync.Barrier,
		wg: ^sync.Wait_Group,

		runs: int,

		all_pointers: []rawptr,
		all_pointers_len: ^int,
		all_pointers_ticket: ^int,
	}

	spmc_task :: proc(t: ^thread.Thread) {
		data := cast(^Consumer_Data)t.data
		sync.barrier_wait(data.barrier)

		for _ in 0..<data.runs {
			ticket := intrinsics.atomic_add_explicit(data.all_pointers_ticket, 1, .Relaxed)

			for ticket >= intrinsics.atomic_load_explicit(data.all_pointers_len, .Acquire) {
				// Spinlock.
				intrinsics.cpu_relax()
			}
			intrinsics.atomic_thread_fence(.Seq_Cst)

			ptr := data.all_pointers[ticket]

			expect(ptr != nil)
			i_ptr := cast(^i64)ptr
			expect(i_ptr^ == 0)
			val := intrinsics.read_cycle_counter()
			i_ptr^ = val
			expect(i_ptr^ == val)
			free(ptr)
		}

		sync.wait_group_done(data.wg)
	}

	start_time: time.Time

	barrier: sync.Barrier
	sync.barrier_init(&barrier, thread_count)

	wg: sync.Wait_Group
	sync.wait_group_add(&wg, thread_count)

	// non-atomic
	all_pointers        := make([]rawptr, thread_count*allocs_per_thread)
	defer delete(all_pointers)
	// atomic
	all_pointers_len    := 0
	all_pointers_ticket := 0

	consumers := make([]Consumer_Data, thread_count)
	defer delete(consumers)

	for i in 0..<thread_count {
		consumers[i] = {
			all_pointers = all_pointers,
			all_pointers_len = &all_pointers_len,
			all_pointers_ticket = &all_pointers_ticket,
			barrier = &barrier,
			wg = &wg,
			runs = allocs_per_thread,
			start_time = &start_time,
			thread = thread.create(spmc_task),
		}
		consumers[i].thread.data = &consumers[i]
		consumers[i].thread.init_context = context
		thread.start(consumers[i].thread)
	}

	start_time = time.now()

	for i in 0..<thread_count*allocs_per_thread {
		new_ptr := cast(rawptr)new(T)
		expect(new_ptr != nil)

		all_pointers[i] = new_ptr

		intrinsics.atomic_add_explicit(&all_pointers_len, 1, .Release)
	}

	sync.wait_group_wait(&wg)
	done := time.since(start_time)

	for i in 0..<thread_count {
		thread.join(consumers[i].thread)
		thread.destroy(consumers[i].thread)
	}

	// Feoramund's malloc does not gather remote frees until a malloc call.
	// Do this to trigger collection of eligible remote frees remaining.
	x := new(int)
	x ^= 32
	x ^= x^ * 2
	free(x)

	log.infof("ALLOC+FREE(% 3i threads): % 7i %s/thr in %v", thread_count, allocs_per_thread, fmt.tprintf("%s", type_info_of(T)),  done, location = location)
}

//
// Main
//

main :: proc() {
	// Need to avoid dynamic allocation as much as possible.
	//
	// There are dynamic heap allocations that happen in global variables
	// throughout the Odin core, but there's not much we can do about that
	// here.
	dummy_space: [8192]u8
	dummy_allocator: mem.Arena
	mem.arena_init(&dummy_allocator, dummy_space[:])
	context.allocator = mem.arena_allocator(&dummy_allocator)

	Allocator :: enum {
		libc,
		feoramalloc,
	}

	Options :: struct {
		allocator:           Allocator `args:"required" usage:"Which allocator to test/bench."`,
		vmem_tests:          bool `usage:"Run virtual memory tests."`,
		serial_tests:        bool `usage:"Run single-threaded tests."`,
		serial_benchmarks:   bool `usage:"Run single-threaded benchmarks."`,
		parallel_tests:      bool `usage:"Run multi-threaded tests."`,
		parallel_benchmarks: bool `usage:"Run multi-threaded benchmarks."`,
		long:                bool `usage:"Where applicable, run tests with large constants. This will take some time to complete."`,
		compact:             bool `usage:"Compact the heap at the end."`,
		info:                bool `usage:"Show heap info at the end."`,
		trap:                bool `usage:"Trigger a debug trap at the end."`,
		coverage:            bool `usage:"Check code coverage."`,
	}

	opt: Options
	flags.parse_or_exit(&opt, os.args)

	logger_data := log.File_Console_Logger_Data{
		file_handle = os.INVALID_HANDLE,
		ident = "",
	}
	context.logger = log.Logger{log.file_console_logger_proc, &logger_data, .Debug, {
		.Level, .Terminal_Color, .Line, .Procedure,
	}}

	if !runtime.ODIN_VIRTUAL_MEMORY_SUPPORTED {
		log.info("Virtual memory is not supported on this platform.")
		os.exit(1)
	}

	allocator: runtime.Allocator
	switch opt.allocator {
	case .libc:
		log.info("Using libc malloc.")
		allocator = libc_allocator.libc_allocator()
	case .feoramalloc:
		log.info("Using Feoramund's malloc.")
		allocator = runtime.heap_allocator()
	case:
		log.info("No allocator set; exiting.")
		os.exit(1)
	}

	{
		rand.reset(0x1337CAFE)
		context.allocator = allocator

		if opt.vmem_tests {
			log.info("Testing virtual memory allocation ...")
			time.sleep(1 * time.Second)
			for size in 12..<uint(22) {
				size := 1 << size
				for shift in 0..<uint(22) {
					alignment := 1 << shift
					v := runtime.allocate_virtual_memory_aligned(size, alignment)
					log.debugf("%i bytes of %i align: %v", size, alignment, v)
					expect(uintptr(v) % uintptr(alignment) == 0)
					va := cast([^]u8)v
					for i in 0..<size {
						expect(va[i] == 0)
					}
					for i in 0..<size {
						va[i] = 0xAA
					}
					for i in 0..<size {
						expect(va[i] == 0xAA)
					}
					v = runtime.resize_virtual_memory(v, size, size+1, alignment)
					va = cast([^]u8)v
					for i in 0..<size {
						expect(va[i] == 0xAA)
					}
					expect(va[size] == 0)
					runtime.free_virtual_memory(v, size+1)
				}
			}
			{
				log.debugf("Testing superpage allocation and alignment ...")
				v := runtime.allocate_virtual_memory_superpage()
				expect(uintptr(v) % runtime.SUPERPAGE_SIZE == 0)
				va := cast([^]u8)v
				for i in 0..<runtime.SUPERPAGE_SIZE {
					expect(va[i] == 0)
				}
				for i in 0..<runtime.SUPERPAGE_SIZE {
					va[i] = 0xAA
				}
				for i in 0..<runtime.SUPERPAGE_SIZE {
					expect(va[i] == 0xAA)
				}
				runtime.free_virtual_memory(v, runtime.SUPERPAGE_SIZE)
			}
			log.info("Done.")
			time.sleep(3 * time.Second)
		}

		if opt.parallel_tests {
			log.info("--- Multi-threaded tests ---")
			// This test must run first in order to guarantee that the
			// orphanage hasn't been touched yet.
			test_superpage_abandonment_and_reuse()

			test_orphanage_overflow(runtime.HEAP_MAX_EMPTY_ORPHANED_SUPERPAGES * 3)

			test_parallel_pointer_passing(4)
			if opt.long {
				test_parallel_pointer_resizing(22)
			} else {
				test_parallel_pointer_resizing(17)
			}

			test_orphaned_superpage_with_remote_frees()

			// Reset the heap, removing any of the dirty slabs before the next tests.
			runtime.compact_heap()
		}

		if opt.serial_tests {
			log.info("--- Single-threaded tests ---")

			// Test the Resize_Wide_Slab_Expanded_In_Place code path.
			{
				N :: runtime.HEAP_SLAB_SIZE
				o1, err1 := allocator.procedure(allocator.data, .Alloc, N, 1, nil, 0)
				expect(err1 == nil)
				o2, err2 := allocator.procedure(allocator.data, .Resize, N*2, 1, raw_data(o1), N)
				expect(err2 == nil)
				_, err3 := allocator.procedure(allocator.data, .Free, 0, 0, raw_data(o2), 0)
				expect(err3 == nil)
				when ODIN_DEBUG_HEAP {
					expect(intrinsics.atomic_load(&runtime.heap_global_code_coverage[.Resize_Wide_Slab_Expanded_In_Place]) == 1)
				}
			}

			// Test the Resize_Wide_Slab_Shrunk_In_Place code path.
			{
				N :: runtime.HEAP_SLAB_SIZE * 2
				o1, err1 := allocator.procedure(allocator.data, .Alloc, N, 1, nil, 0)
				expect(err1 == nil)
				o2, err2 := allocator.procedure(allocator.data, .Resize, N/2, 1, raw_data(o1), N)
				expect(err2 == nil)
				_, err3 := allocator.procedure(allocator.data, .Free, 0, 0, raw_data(o2), 0)
				expect(err3 == nil)
				when ODIN_DEBUG_HEAP {
					expect(intrinsics.atomic_load(&runtime.heap_global_code_coverage[.Resize_Wide_Slab_Shrunk_In_Place]) == 1)
				}
			}

			// Test the Superpage_Added_To_Open_Cache_By_Resizing_Wide_Slab code path.
			{
				N :: runtime.HEAP_SLAB_SIZE - runtime.HEAP_SLAB_ALLOCATION_BOOK_KEEPING
				M :: runtime.HEAP_SLAB_SIZE * 3 - runtime.HEAP_SLAB_ALLOCATION_BOOK_KEEPING

				// Take a large slab-wide allocation that we can resize down later.
				o1, err1 := allocator.procedure(allocator.data, .Alloc, M, 1, nil, 0)
				expect(err1 == nil)

				// Fill the rest of the superpage.
				list := make([dynamic]rawptr, context.temp_allocator)
				for _ in 0..<runtime.HEAP_SLAB_COUNT - 3 {
					o, err2 := allocator.procedure(allocator.data, .Alloc, N, 1, nil, 0)
					expect(err2 == nil)
					append(&list, raw_data(o))
				}

				o2, err3 := allocator.procedure(allocator.data, .Resize, N, 1, raw_data(o1), M)
				expect(err3 == nil)

				free(raw_data(o2))
				for ptr in list {
					free(ptr)
				}
				when ODIN_DEBUG_HEAP {
					expect(intrinsics.atomic_load(&runtime.heap_global_code_coverage[.Superpage_Added_To_Open_Cache_By_Resizing_Wide_Slab]) == 1)
				}
			}

			// Test the Resize_Wide_Slab_Failed_To_Find_Contiguous_Expansion code path.
			{
				N :: runtime.HEAP_SLAB_SIZE - runtime.HEAP_SLAB_ALLOCATION_BOOK_KEEPING
				M :: runtime.HEAP_SLAB_SIZE * 3 - runtime.HEAP_SLAB_ALLOCATION_BOOK_KEEPING

				// Fill the superpage.
				list := make([dynamic]rawptr, context.temp_allocator)
				for _ in 0..<runtime.HEAP_SLAB_COUNT {
					o, err := allocator.procedure(allocator.data, .Alloc, N, 1, nil, 0)
					expect(err == nil)
					append(&list, raw_data(o))
				}

				// Create a situation where we have enough free slabs but not
				// enough contiguous free slabs.
				free(list[0])
				free(list[2])
				free(list[3])

				o1, err1 := allocator.procedure(allocator.data, .Alloc, N, 1, nil, 0)
				expect(err1 == nil)
				o2, err2 := allocator.procedure(allocator.data, .Resize, M, 1, raw_data(o1), N)
				expect(err2 == nil)
				_, err3 := allocator.procedure(allocator.data, .Free, 0, 0, raw_data(o2), 0)
				expect(err3 == nil)

				free(list[1])
				for i in 4..<runtime.HEAP_SLAB_COUNT {
					free(list[i])
				}
				when ODIN_DEBUG_HEAP {
					// TODO(Feoramund): This test will fail if feoramalloc is
					// the default allocator due to allocations that Odin core
					// makes throughout a couple global variables such as
					// `os.args`, which will upset the expectation of a clean
					// slate, but I've tested it to work correctly when libc was
					// the default allocator.

					// expect(intrinsics.atomic_load(&runtime.heap_global_code_coverage[.Resize_Wide_Slab_Failed_To_Find_Contiguous_Expansion]) == 1)
				}
			}

			// Inter-bin tests.
			test_single_alloc_and_resize(0, 8)
			test_single_alloc_and_resize(8, 0)

			test_single_alloc_and_resize(4, 8)
			test_single_alloc_and_resize(8, 4)

			// Cross-bin tests.
			test_single_alloc_and_resize(64, 8)
			test_single_alloc_and_resize(8, 64)

			test_single_alloc_and_resize(runtime.HEAP_MAX_BIN_SIZE, runtime.HEAP_MAX_BIN_SIZE / 2)
			test_single_alloc_and_resize(runtime.HEAP_MAX_BIN_SIZE / 2, runtime.HEAP_MAX_BIN_SIZE * 2)

			// Inter-slab tests.
			test_single_alloc_and_resize(runtime.HEAP_SLAB_SIZE - 1, runtime.HEAP_SLAB_SIZE)

			// Cross-category tests.
			// Bin <-> Slab
			test_single_alloc_and_resize(runtime.HEAP_MAX_BIN_SIZE, runtime.HEAP_SLAB_SIZE)
			test_single_alloc_and_resize(runtime.HEAP_SLAB_SIZE, runtime.HEAP_MAX_BIN_SIZE)

			// Bin <-> Huge
			test_single_alloc_and_resize(runtime.HEAP_MAX_BIN_SIZE, runtime.HEAP_HUGE_ALLOCATION_THRESHOLD)
			test_single_alloc_and_resize(runtime.HEAP_HUGE_ALLOCATION_THRESHOLD, runtime.HEAP_MAX_BIN_SIZE)

			// Slab <-> Huge
			test_single_alloc_and_resize(runtime.HEAP_MAX_BIN_SIZE + 1, runtime.HEAP_HUGE_ALLOCATION_THRESHOLD)
			test_single_alloc_and_resize(runtime.HEAP_HUGE_ALLOCATION_THRESHOLD, runtime.HEAP_MAX_BIN_SIZE + 1)

			// Inter-huge tests.
			test_single_alloc_and_resize(runtime.HEAP_HUGE_ALLOCATION_THRESHOLD + 2, runtime.HEAP_HUGE_ALLOCATION_THRESHOLD + 1)
			test_single_alloc_and_resize(runtime.HEAP_HUGE_ALLOCATION_THRESHOLD + 1, runtime.SUPERPAGE_SIZE)

			// Larger-than-superpage tests.
			test_single_alloc_and_resize(runtime.SUPERPAGE_SIZE, runtime.SUPERPAGE_SIZE * 3)
			test_single_alloc_and_resize(runtime.SUPERPAGE_SIZE * 3, runtime.SUPERPAGE_SIZE)

			// Brute-force tests.
			test_individual_allocation_and_free(runtime.HEAP_MAX_BIN_SIZE if opt.long else 1024)
			test_continuous_allocation_of_size_n(16, runtime.HEAP_MAX_BIN_SIZE if opt.long else 1024)

			test_alloc_write_free(
				object_count = 400,
				starting_size = 16, final_size = 16,
				size_strategy = .Adding, size_operand = 0,
				allocs_per_free_operation = 16,
				free_operations_at_once = 4,
				free_strategy = .Interleaved,
				free_direction = .Randomly,
			)

			test_alloc_write_free(
				object_count = 100,
				starting_size = 2, final_size = 4096,
				size_strategy = .Multiplying, size_operand = 2,
				allocs_per_free_operation = 16,
				free_operations_at_once = 4,
				free_strategy = .Interleaved,
				free_direction = .Randomly,
			)

			test_alloc_write_free(
				object_count = 100,
				starting_size = 2, final_size = 32768,
				size_strategy = .Adding, size_operand = 2,
				allocs_per_free_operation = 16,
				free_operations_at_once = 4,
				free_strategy = .Interleaved,
				free_direction = .Randomly,
			)

			test_alloc_write_free(
				object_count = 100,
				starting_size = 2, final_size = 8096,
				size_strategy = .Adding, size_operand = 2,
				allocs_per_free_operation = 16,
				free_operations_at_once = 15,
				free_strategy = .Interleaved,
				free_direction = .Backward,
			)

			test_alloc_write_free(
				object_count = 10,
				starting_size = 8096, final_size = 2,
				size_strategy = .Adding, size_operand = -2,
				allocs_per_free_operation = 16,
				free_operations_at_once = 15,
				free_strategy = .At_The_End,
				free_direction = .Forward,
			)

			test_alloc_write_free(
				object_count = 10,
				starting_size = 65535, final_size = 65535,
				size_strategy = .Adding, size_operand = 0,
				allocs_per_free_operation = 1,
				free_operations_at_once = 1,
				free_strategy = .At_The_End,
				free_direction = .Forward,
			)

			test_alloc_write_free(
				object_count = 300000,
				starting_size = 8, final_size = 8,
				size_strategy = .Adding, size_operand = 0,
				allocs_per_free_operation = 1,
				free_operations_at_once = 1,
				free_strategy = .At_The_End,
				free_direction = .Forward,
			)

			test_alloc_write_free(
				object_count = runtime.HEAP_SLAB_COUNT*2,
				starting_size = runtime.HEAP_SLAB_SIZE/2, final_size = runtime.HEAP_SLAB_SIZE*4,
				size_strategy = .Multiplying, size_operand = 2,
				allocs_per_free_operation = 1,
				free_operations_at_once = 1,
				free_strategy = .At_The_End,
				free_direction = .Forward,
			)

			test_alloc_write_free(
				object_count = 2,
				starting_size = runtime.SUPERPAGE_SIZE/2, final_size = runtime.SUPERPAGE_SIZE*4,
				size_strategy = .Multiplying, size_operand = 2,
				allocs_per_free_operation = 1,
				free_operations_at_once = 1,
				free_strategy = .At_The_End,
				free_direction = .Forward,
			)

			// This is a lengthy test and won't tell us much more than any other test will.
			if opt.long {
				test_single_alloc_and_resize_incremental(0, runtime.HEAP_SLAB_SIZE)
			}

			runtime.compact_heap()

			test_serial_bin_sanity()

			runtime.compact_heap()
		}

		if opt.serial_benchmarks {
			log.info("--- Single-threaded benchmarks ---")

			log.info("* Freeing forwards ...")
			bench_alloc_n_then_free_n(1_000_000, int)
			bench_alloc_n_then_free_n(1_000_000, Struct_16)
			bench_alloc_n_then_free_n(1_000_000, Struct_32)
			bench_alloc_n_then_free_n(1_000_000, Struct_64)
			bench_alloc_n_then_free_n(1_000_000, Struct_512)
			bench_alloc_n_then_free_n(10_000, [8192]u8)
			bench_alloc_n_then_free_n(1000, [runtime.HEAP_SLAB_SIZE/4]u8)
			bench_alloc_n_then_free_n(1000, [runtime.HEAP_SLAB_SIZE*4]u8)
			bench_alloc_n_then_free_n(10, [runtime.SUPERPAGE_SIZE]u8)

			log.info("* Freeing backwards ...")
			bench_alloc_n_then_free_n_backwards(1_000_000, int)
			bench_alloc_n_then_free_n_backwards(1_000_000, Struct_16)
			bench_alloc_n_then_free_n_backwards(1_000_000, Struct_32)
			bench_alloc_n_then_free_n_backwards(1_000_000, Struct_64)
			bench_alloc_n_then_free_n_backwards(1_000_000, Struct_512)
			bench_alloc_n_then_free_n_backwards(10_000, [8192]u8)
			bench_alloc_n_then_free_n_backwards(1000, [runtime.HEAP_SLAB_SIZE/4]u8)
			bench_alloc_n_then_free_n_backwards(1000, [runtime.HEAP_SLAB_SIZE*4]u8)
			bench_alloc_n_then_free_n_backwards(10, [runtime.SUPERPAGE_SIZE]u8)

			log.info("* Freeing randomly ...")
			bench_alloc_n_then_free_n_randomly(1_000_000, int)
			bench_alloc_n_then_free_n_randomly(1_000_000, Struct_16)
			bench_alloc_n_then_free_n_randomly(1_000_000, Struct_32)
			bench_alloc_n_then_free_n_randomly(1_000_000, Struct_64)
			bench_alloc_n_then_free_n_randomly(1_000_000, Struct_512)
			bench_alloc_n_then_free_n_randomly(10_000, [8192]u8)
			bench_alloc_n_then_free_n_randomly(10_000, [runtime.HEAP_SLAB_SIZE/4]u8)
			bench_alloc_n_then_free_n_randomly(10_000, [runtime.HEAP_SLAB_SIZE-runtime.HEAP_SLAB_ALLOCATION_BOOK_KEEPING]u8)
			bench_alloc_n_then_free_n_randomly(10_000, [runtime.HEAP_SLAB_SIZE]u8)
			bench_alloc_n_then_free_n_randomly(10_000, [runtime.HEAP_SLAB_SIZE*2]u8)
			bench_alloc_n_then_free_n_randomly(10, [runtime.SUPERPAGE_SIZE]u8)

			log.info("* Allocating and freeing repeatedly ...")
			bench_alloc_1_then_free_1_repeatedly(100_000, int)
			bench_alloc_1_then_free_1_repeatedly(100_000, Struct_16)
			bench_alloc_1_then_free_1_repeatedly(100_000, Struct_32)
			bench_alloc_1_then_free_1_repeatedly(100_000, Struct_64)
			bench_alloc_1_then_free_1_repeatedly(100_000, Struct_512)
			bench_alloc_1_then_free_1_repeatedly(10_000, [8192]u8)
		}

		if opt.parallel_benchmarks {
			log.info("--- Multi-threaded benchmarks ---")

			bench_1_producer_n_consumer_for_m_alloc(1, 10_000, Struct_16)
			bench_1_producer_n_consumer_for_m_alloc(2, 10_000, Struct_16)
			bench_1_producer_n_consumer_for_m_alloc(4, 10_000, Struct_16)

			bench_1_producer_n_consumer_for_m_alloc(1, 10_000, Struct_32)
			bench_1_producer_n_consumer_for_m_alloc(2, 10_000, Struct_32)
			bench_1_producer_n_consumer_for_m_alloc(4, 10_000, Struct_32)

			bench_1_producer_n_consumer_for_m_alloc(1, 10_000, Struct_64)
			bench_1_producer_n_consumer_for_m_alloc(2, 10_000, Struct_64)
			bench_1_producer_n_consumer_for_m_alloc(4, 10_000, Struct_64)

			bench_1_producer_n_consumer_for_m_alloc(1, 10_000, Struct_512)
			bench_1_producer_n_consumer_for_m_alloc(2, 10_000, Struct_512)
			bench_1_producer_n_consumer_for_m_alloc(4, 10_000, Struct_512)

			bench_1_producer_n_consumer_for_m_alloc(1, 1_000, [8192]u8)
			bench_1_producer_n_consumer_for_m_alloc(2, 1_000, [8192]u8)
			bench_1_producer_n_consumer_for_m_alloc(4, 1_000, [8192]u8)

			bench_1_producer_n_consumer_for_m_alloc(4, 10, [runtime.HEAP_SLAB_SIZE]u8)

			when .Thread not_in ODIN_SANITIZER_FLAGS {
				// NOTE: TSan doesn't work well with excessive thread counts,
				// in my experience.
				bench_1_producer_n_consumer_for_m_alloc(32, 1_000, Struct_32)
				bench_1_producer_n_consumer_for_m_alloc(64, 1_000, Struct_32)
				bench_1_producer_n_consumer_for_m_alloc(128, 1_000, Struct_32)
			}
		}

	}

	log.info("Tests complete.")

	if opt.compact {
		runtime.compact_heap()
		log.info("The main thread's heap has been compacted.")
	}

	if opt.coverage {
		when runtime.ODIN_DEBUG_HEAP {
			log.info("--- Code coverage report ---")
			for key in runtime.Heap_Code_Coverage_Type {
				value := intrinsics.atomic_load_explicit(&runtime.heap_global_code_coverage[key], .Acquire)
				log.infof("%s%v: %v", ">>> " if value == 0 else "", key, value)
			}

			log.infof("Full code coverage: %v", runtime._check_heap_code_coverage())
		} else {
			log.error("ODIN_DEBUG_HEAP is not enabled, thus coverage cannot be calculated.")
		}
	}

	if opt.info {
		heap_info := runtime.get_local_heap_info()
		log.infof("%#v", heap_info)
	}

	// if .Dump_Slabs in params {
	// 	dump_slabs()
	// }

	if opt.trap {
		intrinsics.debug_trap()
	}
}
