#+vet explicit-allocators
package debug_trace

import "base:runtime"

import "core:fmt"
import "core:mem"
import "core:sync"

// TODO: should this just be added to `core:mem.Tracking_Allocator`?

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
	backing:              mem.Allocator,
	internals_allocator:  mem.Allocator,
	allocation_map:       map[rawptr]Tracking_Allocator_Entry,
	bad_free_array:       [dynamic]Tracking_Allocator_Bad_Free_Entry,
	mutex:                sync.Mutex,
	clear_on_free_all:    bool,
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

tracking_allocator_init :: proc(
	t: ^Tracking_Allocator,
	backing_allocator: mem.Allocator,
	internals_allocator := context.allocator,
) {
	t.backing = backing_allocator
	t.internals_allocator = internals_allocator
	t.allocation_map.allocator = internals_allocator
	t.bad_free_array.allocator = internals_allocator

	if .Free_All in mem.query_features(t.backing) {
		t.clear_on_free_all = true
	}
}

tracking_allocator_destroy :: proc(t: ^Tracking_Allocator) {
	delete(t.allocation_map)
	delete(t.bad_free_array)
}

tracking_allocator_clear :: proc(t: ^Tracking_Allocator) {
	sync.guard(&t.mutex)

	clear(&t.allocation_map)
	clear(&t.bad_free_array)
}

@(require_results)
tracking_allocator :: proc(data: ^Tracking_Allocator) -> mem.Allocator {
	return mem.Allocator{data = data, procedure = tracking_allocator_proc}
}

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
		append(
			&data.bad_free_array,
			Tracking_Allocator_Bad_Free_Entry{
				memory = old_memory,
				location = loc,
				backtrace = capture(skip=1),
			},
		)
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
	case .Free:
		delete_key(&data.allocation_map, old_memory)
	case .Free_All:
		if data.clear_on_free_all {
			clear_map(&data.allocation_map)
		}
	case .Resize, .Resize_Non_Zeroed:
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
		fmt.eprintfln("%v leaked %m", leak.location, leak.size)

		defer i += 1
		if i > ALLOCATOR_MAX_BACKTRACES {
			continue
		}

		fmt.eprintln("[back trace]")

		trace, err := resolve(leak.backtrace, temp_allocator, temp_allocator)
		if err != nil {
			fmt.eprintfln("\tbacktrace error: %v", err)
			continue
		}
		defer locations_destroy(trace, temp_allocator)

		print(trace)
		fmt.eprintln()
	}

	for bad_free, _ in t.bad_free_array {
		fmt.eprintfln(
			"%v allocation %p was freed badly",
			bad_free.location,
			bad_free.memory,
		)

		defer i += 1
		if i > ALLOCATOR_MAX_BACKTRACES {
			continue
		}

		fmt.eprintln("[back trace]")

		trace, err := resolve(bad_free.backtrace, temp_allocator, temp_allocator)
		if err != nil {
			fmt.eprintfln("\tbacktrace error: %v", err)
			continue
		}
		defer locations_destroy(trace, temp_allocator)

		print(trace)
	}
}
