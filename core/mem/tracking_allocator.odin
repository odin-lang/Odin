//+build !freestanding
package mem

import "base:runtime"
import "core:sync"

Tracking_Allocator_Entry :: struct {
	memory:    rawptr,
	size:      int,
	alignment: int,
	mode:      Allocator_Mode,
	err:       Allocator_Error,
	location:  runtime.Source_Code_Location,
}
Tracking_Allocator_Bad_Free_Entry :: struct {
	memory:   rawptr,
	location: runtime.Source_Code_Location,
}
Tracking_Allocator :: struct {
	backing:           Allocator,
	allocation_map:    map[rawptr]Tracking_Allocator_Entry,
	bad_free_array:    [dynamic]Tracking_Allocator_Bad_Free_Entry,
	mutex:             sync.Mutex,
	clear_on_free_all: bool,

	total_memory_allocated:   i64,
	total_allocation_count:   i64,
	total_memory_freed:       i64,
	total_free_count:         i64,
	peak_memory_allocated:    i64,
	current_memory_allocated: i64,
}

tracking_allocator_init :: proc(t: ^Tracking_Allocator, backing_allocator: Allocator, internals_allocator := context.allocator) {
	t.backing = backing_allocator
	t.allocation_map.allocator = internals_allocator
	t.bad_free_array.allocator = internals_allocator

	if .Free_All in query_features(t.backing) {
		t.clear_on_free_all = true
	}
}

tracking_allocator_destroy :: proc(t: ^Tracking_Allocator) {
	delete(t.allocation_map)
	delete(t.bad_free_array)
}


tracking_allocator_clear :: proc(t: ^Tracking_Allocator) {
	sync.mutex_lock(&t.mutex)
	clear(&t.allocation_map)
	clear(&t.bad_free_array)
	t.current_memory_allocated = 0
	sync.mutex_unlock(&t.mutex)
}


@(require_results)
tracking_allocator :: proc(data: ^Tracking_Allocator) -> Allocator {
	return Allocator{
		data = data,
		procedure = tracking_allocator_proc,
	}
}

tracking_allocator_proc :: proc(allocator_data: rawptr, mode: Allocator_Mode,
                                size, alignment: int,
                                old_memory: rawptr, old_size: int, loc := #caller_location) -> (result: []byte, err: Allocator_Error) {
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
		append(&data.bad_free_array, Tracking_Allocator_Bad_Free_Entry{
			memory = old_memory,
			location = loc,
		})
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

