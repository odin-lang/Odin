#+build !freestanding, wasm32, wasm64p32
package mem

import "base:runtime"
import "core:sync"

/*
Allocation entry for the tracking allocator.

This structure stores the data related to an allocation.
*/
Tracking_Allocator_Entry :: struct {
	// Pointer to an allocated region.
	memory: rawptr,
	// Size of the allocated memory region.
	size: int,
	// Requested alignment.
	alignment: int,
	// Mode of the operation.
	mode: Allocator_Mode,
	// Error.
	err: Allocator_Error,
	// Location of the allocation.
	location:  runtime.Source_Code_Location,
}

/*
Bad free entry for a tracking allocator.
*/
Tracking_Allocator_Bad_Free_Entry :: struct {
	// Pointer, on which free operation was called.
	memory: rawptr,
	// The source location of where the operation was called.
	location: runtime.Source_Code_Location,
}

/*
Callback type for when tracking allocator runs into a bad free.
*/
Tracking_Allocator_Bad_Free_Callback :: proc(t: ^Tracking_Allocator, memory: rawptr, location: runtime.Source_Code_Location)

/*
Tracking allocator data.
*/
Tracking_Allocator :: struct {
	backing: Allocator,
	allocation_map: map[rawptr]Tracking_Allocator_Entry,
	bad_free_callback: Tracking_Allocator_Bad_Free_Callback,
	bad_free_array: [dynamic]Tracking_Allocator_Bad_Free_Entry,
	mutex: sync.Mutex,
	clear_on_free_all: bool,
	total_memory_allocated: i64,
	total_allocation_count: i64,
	total_memory_freed: i64,
	total_free_count: i64,
	peak_memory_allocated: i64,
	current_memory_allocated: i64,
}

/*
Initialize the tracking allocator.

This procedure initializes the tracking allocator `t` with a backing allocator
specified with `backing_allocator`. The `internals_allocator` will used to
allocate the tracked data.
*/
tracking_allocator_init :: proc(t: ^Tracking_Allocator, backing_allocator: Allocator, internals_allocator := context.allocator) {
	t.backing = backing_allocator
	t.allocation_map.allocator = internals_allocator
	t.bad_free_callback = tracking_allocator_bad_free_callback_panic
	t.bad_free_array.allocator = internals_allocator
	if .Free_All in query_features(t.backing) {
		t.clear_on_free_all = true
	}
}

/*
Destroy the tracking allocator.
*/
tracking_allocator_destroy :: proc(t: ^Tracking_Allocator) {
	delete(t.allocation_map)
	delete(t.bad_free_array)
}

/*
Clear the tracking allocator.

This procedure clears the tracked data from a tracking allocator.

**Note**: This procedure clears only the current allocation data while keeping
the totals intact.
*/
tracking_allocator_clear :: proc(t: ^Tracking_Allocator) {
	sync.mutex_lock(&t.mutex)
	clear(&t.allocation_map)
	clear(&t.bad_free_array)
	t.current_memory_allocated = 0
	sync.mutex_unlock(&t.mutex)
}

/*
Reset the tracking allocator.

Reset all of a Tracking Allocator's allocation data back to zero.
*/
tracking_allocator_reset :: proc(t: ^Tracking_Allocator) {
	sync.mutex_lock(&t.mutex)
	clear(&t.allocation_map)
	clear(&t.bad_free_array)
	t.total_memory_allocated = 0
	t.total_allocation_count = 0
	t.total_memory_freed = 0
	t.total_free_count = 0
	t.peak_memory_allocated = 0
	t.current_memory_allocated = 0
	sync.mutex_unlock(&t.mutex)
}

/*
Default behavior for a bad free: Crash with error message that says where the
bad free happened.

Override Tracking_Allocator.bad_free_callback to have something else happen. For
example, you can use tracking_allocator_bad_free_callback_add_to_array to return
the tracking allocator to the old behavior, where the bad_free_array was used.
*/
tracking_allocator_bad_free_callback_panic :: proc(t: ^Tracking_Allocator, memory: rawptr, location: runtime.Source_Code_Location) {
	runtime.print_caller_location(location)
	runtime.print_string(" Tracking allocator error: Bad free of pointer ")
	runtime.print_uintptr(uintptr(memory))
	runtime.print_string("\n")
	runtime.trap()
}

/*
Alternative behavior for a bad free: Store in `bad_free_array`. If you use this,
then you must make sure to check Tracking_Allocator.bad_free_array at some point.
*/
tracking_allocator_bad_free_callback_add_to_array :: proc(t: ^Tracking_Allocator, memory: rawptr, location: runtime.Source_Code_Location) {
	append(&t.bad_free_array, Tracking_Allocator_Bad_Free_Entry {
		memory = memory,
		location = location,
	})
}

/*
Tracking allocator.

The tracking allocator is an allocator wrapper that tracks memory allocations.
This allocator stores all the allocations in a map. Whenever a pointer that's
not inside of the map is freed, the `bad_free_array` entry is added.

Here follows an example of how to use the `Tracking_Allocator` to track
subsequent allocations in your program and report leaks. By default, the
tracking allocator will crash on bad frees. You can override that behavior by
overriding `track.bad_free_callback`.

Example:

	package foo

	import "core:mem"
	import "core:fmt"

	main :: proc() {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		defer mem.tracking_allocator_destroy(&track)
		context.allocator = mem.tracking_allocator(&track)

		do_stuff()

		for _, leak in track.allocation_map {
			fmt.printf("%v leaked %m\n", leak.location, leak.size)
		}
	}
*/
@(require_results)
tracking_allocator :: proc(data: ^Tracking_Allocator) -> Allocator {
	return Allocator{
		data = data,
		procedure = tracking_allocator_proc,
	}
}

tracking_allocator_proc :: proc(
	allocator_data: rawptr,
	mode: Allocator_Mode,
	size, alignment: int,
	old_memory: rawptr,
	old_size: int,
	loc := #caller_location,
) -> (result: []byte, err: Allocator_Error) {
	track_alloc :: proc(data: ^Tracking_Allocator, entry: ^Tracking_Allocator_Entry) {
		data.total_memory_allocated += i64(entry.size)
		data.total_allocation_count += 1
		data.current_memory_allocated += i64(entry.size)
		if data.current_memory_allocated > data.peak_memory_allocated {
			data.peak_memory_allocated = data.current_memory_allocated
		}
	}

	track_free :: proc(data: ^Tracking_Allocator, entry: ^Tracking_Allocator_Entry) {
		data.total_memory_freed += i64(entry.size)
		data.total_free_count += 1
		data.current_memory_allocated -= i64(entry.size)
	}

	data := (^Tracking_Allocator)(allocator_data)

	sync.mutex_guard(&data.mutex)

	if mode == .Query_Info {
		info := (^Allocator_Query_Info)(old_memory)
		if info != nil && info.pointer != nil {
			if entry, ok := data.allocation_map[info.pointer]; ok {
				info.size = entry.size
				info.alignment = entry.alignment
			}
			info.pointer = nil
		}

		return
	}

	if mode == .Free && old_memory != nil && old_memory not_in data.allocation_map {
		if data.bad_free_callback != nil {
			data.bad_free_callback(data, old_memory, loc)
		}
	} else {
		result = data.backing.procedure(data.backing.data, mode, size, alignment, old_memory, old_size, loc) or_return
	}
	result_ptr := raw_data(result)

	if data.allocation_map.allocator.procedure == nil {
		data.allocation_map.allocator = context.allocator
	}

	switch mode {
	case .Alloc, .Alloc_Non_Zeroed:
		data.allocation_map[result_ptr] = Tracking_Allocator_Entry{
			memory = result_ptr,
			size = size,
			mode = mode,
			alignment = alignment,
			err = err,
			location = loc,
		}
		track_alloc(data, &data.allocation_map[result_ptr])
	case .Free:
		if old_memory != nil && old_memory in data.allocation_map {
			track_free(data, &data.allocation_map[old_memory])
		}
		delete_key(&data.allocation_map, old_memory)
	case .Free_All:
		if data.clear_on_free_all {
			clear_map(&data.allocation_map)
			data.current_memory_allocated = 0
		}
	case .Resize, .Resize_Non_Zeroed:
		if old_memory != nil && old_memory in data.allocation_map {
			track_free(data, &data.allocation_map[old_memory])
		}
		if old_memory != result_ptr {
			delete_key(&data.allocation_map, old_memory)
		}
		data.allocation_map[result_ptr] = Tracking_Allocator_Entry{
			memory = result_ptr,
			size = size,
			mode = mode,
			alignment = alignment,
			err = err,
			location = loc,
		}
		track_alloc(data, &data.allocation_map[result_ptr])

	case .Query_Features:
		set := (^Allocator_Mode_Set)(old_memory)
		if set != nil {
			set^ = {.Alloc, .Alloc_Non_Zeroed, .Free, .Free_All, .Resize, .Query_Features, .Query_Info}
		}
		return nil, nil

	case .Query_Info:
		unreachable()
	}

	return
}

