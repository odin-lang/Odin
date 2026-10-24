#+vet explicit-allocators
package debug_trace

import "base:runtime"

import "core:mem"
import "core:sync"

/*
The backtrace tracking allocator is a similar allocator as the `core:mem` tracking allocator but keeps
backtraces for each allocation.

Print results at the end using `tracking_allocator_print_results`.

Example:
	package main

	import "core:debug/trace"

	main :: proc() {
		track: trace.Tracking_Allocator
		trace.tracking_allocator_init(&track, context.allocator)
		defer trace.tracking_allocator_destroy(&track)

		context.allocator = trace.tracking_allocator(&track)
		defer trace.tracking_allocator_print_results(&track)

		_main()
	}

	_main :: proc() {
		for _ in 0..<5 {
			_ = new(int)
			free(rawptr(uintptr(100)))
		}
	}
*/
Tracking_Allocator :: struct {
	backing:                  mem.Allocator,
	allocation_map:           map[rawptr]Tracking_Allocator_Entry,
	bad_free_callback:        Tracking_Allocator_Bad_Free_Callback,
	bad_free_array:           [dynamic]Tracking_Allocator_Bad_Free_Entry,
	mutex:                    sync.Mutex,
	clear_on_free_all:        bool,
	total_memory_allocated:   i64,
	total_allocation_count:   i64,
	total_memory_freed:       i64,
	total_free_count:         i64,
	peak_memory_allocated:    i64,
	current_memory_allocated: i64,
}

Tracking_Allocator_Entry :: struct {
	memory:    rawptr,
	size:      int,
	alignment: int,
	mode:      mem.Allocator_Mode,
	err:       mem.Allocator_Error,
	location:  runtime.Source_Code_Location,
	backtrace: Capture_Const,
}

Tracking_Allocator_Bad_Free_Entry :: struct {
	memory:    rawptr,
	location:  runtime.Source_Code_Location,
	backtrace: Capture_Const,
}

/*
Callback type for when tracking allocator runs into a bad free.
*/
Tracking_Allocator_Bad_Free_Callback :: #type proc(
	t: ^Tracking_Allocator,
	memory: rawptr,
	backtrace: Capture_Const,
	location: runtime.Source_Code_Location,
)

@(no_sanitize_address)
tracking_allocator_init :: proc(
	t: ^Tracking_Allocator,
	backing_allocator: mem.Allocator,
	internals_allocator := context.allocator,
) {
	t.backing = backing_allocator
	t.allocation_map.allocator = internals_allocator
	t.bad_free_callback = tracking_allocator_bad_free_callback_panic 
	t.bad_free_array.allocator = internals_allocator

	if .Free_All in mem.query_features(t.backing) {
		t.clear_on_free_all = true
	}
}

@(no_sanitize_address)
tracking_allocator_destroy :: proc(t: ^Tracking_Allocator) {
	delete(t.allocation_map)
	delete(t.bad_free_array)
	t.allocation_map = {}
	t.bad_free_array = {}
}

@(no_sanitize_address)
tracking_allocator_clear :: proc(t: ^Tracking_Allocator) {
	sync.guard(&t.mutex)

	clear(&t.allocation_map)
	clear(&t.bad_free_array)
	t.current_memory_allocated = 0
}

@(no_sanitize_address)
tracking_allocator_reset :: proc(t: ^Tracking_Allocator) {
	sync.guard(&t.mutex)
	clear(&t.allocation_map)
	clear(&t.bad_free_array)
	t.total_memory_allocated = 0
	t.total_allocation_count = 0
	t.total_memory_freed = 0
	t.total_free_count = 0
	t.peak_memory_allocated = 0
	t.current_memory_allocated = 0
}

@(no_sanitize_address)
tracking_allocator_bad_free_callback_panic :: proc(
	t: ^Tracking_Allocator,
	memory: rawptr,
	backtrace: Capture_Const,
	location: runtime.Source_Code_Location,
) {
	buf: [256]byte
	offset := 0
	_ = runtime.write_string(&offset, buf[:], "Tracking allocator error: Bad free of pointer ")
	_ = runtime.write_u64(&offset, buf[:], u64(uintptr(memory)))
	panic(string(buf[:offset]), loc = location)
}

@(no_sanitize_address)
tracking_allocator_bad_free_callback_add_to_array :: proc(
	t: ^Tracking_Allocator,
	memory: rawptr,
	backtrace: Capture_Const,
	location: runtime.Source_Code_Location,
) {
	append(&t.bad_free_array, Tracking_Allocator_Bad_Free_Entry {
		memory = memory,
		location = location,
		backtrace = backtrace,
	})
}

@(require_results, no_sanitize_address)
tracking_allocator :: proc(data: ^Tracking_Allocator) -> mem.Allocator {
	return mem.Allocator{data = data, procedure = tracking_allocator_proc}
}

@(no_sanitize_address)
tracking_allocator_proc :: proc(
	allocator_data: rawptr,
	mode: mem.Allocator_Mode,
	size, alignment: int,
	old_memory: rawptr,
	old_size: int,
	loc := #caller_location,
) -> (
	result: []byte,
	err: mem.Allocator_Error,
) {
	@(no_sanitize_address)
	track_alloc :: proc(data: ^Tracking_Allocator, entry: ^Tracking_Allocator_Entry) {
		data.total_memory_allocated += i64(entry.size)
		data.total_allocation_count += 1
		data.current_memory_allocated += i64(entry.size)
		if data.current_memory_allocated > data.peak_memory_allocated {
			data.peak_memory_allocated = data.current_memory_allocated
		}
	}

	@(no_sanitize_address)
	track_free :: proc(data: ^Tracking_Allocator, entry: ^Tracking_Allocator_Entry) {
		data.total_memory_freed += i64(entry.size)
		data.total_free_count += 1
		data.current_memory_allocated -= i64(entry.size)
	}

	data := (^Tracking_Allocator)(allocator_data)

	sync.mutex_guard(&data.mutex)

	if mode == .Query_Info {
		info := (^mem.Allocator_Query_Info)(old_memory)
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
			data.bad_free_callback(data, old_memory, capture(skip=1), loc)
		}
	} else {
		result = data.backing.procedure(
			data.backing.data,
			mode,
			size,
			alignment,
			old_memory,
			old_size,
			loc,
		) or_return
	}
	result_ptr := raw_data(result)

	if data.allocation_map.allocator.procedure == nil {
		data.allocation_map.allocator = context.allocator
	}

	switch mode {
	case .Alloc, .Alloc_Non_Zeroed:
		data.allocation_map[result_ptr] = Tracking_Allocator_Entry {
			memory    = result_ptr,
			size      = size,
			mode      = mode,
			alignment = alignment,
			err       = err,
			location  = loc,
			backtrace = capture(skip=1),
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
		data.allocation_map[result_ptr] = Tracking_Allocator_Entry {
			memory    = result_ptr,
			size      = size,
			mode      = mode,
			alignment = alignment,
			err       = err,
			location  = loc,
			backtrace = capture(skip=1),
		}
		track_alloc(data, &data.allocation_map[result_ptr])

	case .Query_Features:
		set := (^mem.Allocator_Mode_Set)(old_memory)
		if set != nil {
			set^ = {
				.Alloc,
				.Alloc_Non_Zeroed,
				.Free,
				.Free_All,
				.Resize,
				.Query_Features,
				.Query_Info,
			}
		}
		return nil, nil

	case .Query_Info:
		unreachable()
	}

	return
}

tracking_allocator_print_results :: proc(t: ^Tracking_Allocator, temp_allocator := context.temp_allocator) {
	i: int
	ALLOCATOR_MAX_BACKTRACES :: 16

	for _, leak in t.allocation_map {
		runtime.print_caller_location(leak.location)
		runtime.print_string(" leaked ")
		_print_memory(leak.size)
		runtime.print_byte('\n')

		defer i += 1
		if i > ALLOCATOR_MAX_BACKTRACES {
			continue
		}

		runtime.print_string("[back trace]\n")

		trace, err := resolve(leak.backtrace, temp_allocator, temp_allocator)
		if err != nil {
			runtime.print_string("\tbacktrace error: ")
			runtime.print_string(resolve_err_string(err))
			runtime.print_string("\n")
			continue
		}
		defer locations_destroy(trace, temp_allocator)

		print(trace)
		runtime.print_string("\n")
	}

	for bad_free, _ in t.bad_free_array {
		runtime.print_caller_location(bad_free.location)
		runtime.print_string(" allocation ")
		runtime.print_u64(u64(uintptr(bad_free.memory)))
		runtime.print_string(" was freed badly\n")

		defer i += 1
		if i > ALLOCATOR_MAX_BACKTRACES {
			continue
		}

		runtime.print_string("[back trace]\n")

		trace, err := resolve(bad_free.backtrace, temp_allocator, temp_allocator)
		if err != nil {
			runtime.print_string("\tbacktrace error: ")
			runtime.print_string(resolve_err_string(err))
			runtime.print_string("\n")
			continue
		}
		defer locations_destroy(trace, temp_allocator)

		print(trace)
	}
}

@(rodata)
_MEMORY_UNITS := [?]string{"b", "kib", "mib", "gib", "tib", "pib", "eib"}

_print_memory :: proc(size: int) {
	assert(size >= 0)

	u := u64(size)
	unit_idx := 0
	div: u64 = 1
	for u / div >= mem.Kilobyte && unit_idx < len(_MEMORY_UNITS) - 1 {
		div *= mem.Kilobyte
		unit_idx += 1
	}

	whole := u / div
	rem   := u % div
	frac  := (rem * 10 + div / 2) / div
	if frac == 10 {
		frac = 0
		whole += 1
		if whole == mem.Kilobyte && unit_idx < len(_MEMORY_UNITS) - 1 {
			whole = 1
			unit_idx += 1
		}
	}

	runtime.print_u64(whole)
	if frac != 0 {
		runtime.print_byte('.')
		runtime.print_byte(byte('0' + frac))
	}
	runtime.print_string(_MEMORY_UNITS[unit_idx])
}
