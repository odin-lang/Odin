package runtime

import "core:os"

default_allocator_proc :: os.heap_allocator_proc;

default_allocator :: proc() -> Allocator {
	return os.heap_allocator();
}


Default_Temp_Allocator :: struct {
	data:     []byte,
	curr_offset: int,
	prev_offset: int,
	backup_allocator: Allocator,
	leaked_allocations: [dynamic]rawptr,
}

default_temp_allocator_init :: proc(allocator: ^Default_Temp_Allocator, data: []byte, backup_allocator := context.allocator) {
	allocator.data = data;
	allocator.curr_offset = 0;
	allocator.prev_offset = 0;
	allocator.backup_allocator = backup_allocator;
	allocator.leaked_allocations.allocator = backup_allocator;
}

default_temp_allocator_destroy :: proc(using allocator: ^Default_Temp_Allocator) {
	if allocator == nil {
		return;
	}
	for ptr in leaked_allocations {
		free(ptr, backup_allocator);
	}
	delete(leaked_allocations);
	delete(data, backup_allocator);
	allocator^ = {};
}

default_temp_allocator_proc :: proc(allocator_data: rawptr, mode: Allocator_Mode,
                                    size, alignment: int,
                                    old_memory: rawptr, old_size: int, flags: u64 = 0, loc := #caller_location) -> rawptr {

	allocator := (^Default_Temp_Allocator)(allocator_data);

	if allocator.data == nil {
		DEFAULT_SCRATCH_BACKING_SIZE :: 1<<22;
		a := context.allocator;
		if !(context.allocator.procedure != default_temp_allocator_proc &&
		     context.allocator.data != allocator_data) {
			a = default_allocator();
		}
		default_temp_allocator_init(allocator, make([]byte, 1<<22, a), a);
	}

	switch mode {
	case .Alloc:
		switch {
		case allocator.curr_offset+size <= len(allocator.data):
			offset := align_forward_uintptr(uintptr(allocator.curr_offset), uintptr(alignment));
			ptr := &allocator.data[offset];
			mem_zero(ptr, size);
			allocator.prev_offset = int(offset);
			allocator.curr_offset = int(offset) + size;
			return ptr;
		case size <= len(allocator.data):
			offset := align_forward_uintptr(uintptr(0), uintptr(alignment));
			ptr := &allocator.data[offset];
			mem_zero(ptr, size);
			allocator.prev_offset = int(offset);
			allocator.curr_offset = int(offset) + size;
			return ptr;
		}
		// TODO(bill): Should leaks be notified about? Should probably use a logging system that is built into the context system
		a := allocator.backup_allocator;
		if a.procedure == nil {
			a = context.allocator;
			allocator.backup_allocator = a;
		}

		ptr := mem_alloc(size, alignment, a, loc);
		if allocator.leaked_allocations == nil {
			allocator.leaked_allocations = make([dynamic]rawptr, a);
		}
		append(&allocator.leaked_allocations, ptr);

		return ptr;

	case .Free:
		if len(allocator.data) == 0 {
			return nil;
		}
		last_ptr := rawptr(&allocator.data[allocator.prev_offset]);
		if old_memory == last_ptr {
			full_size := allocator.curr_offset - allocator.prev_offset;
			allocator.curr_offset = allocator.prev_offset;
			mem_zero(last_ptr, full_size);
			return nil;
		} else {
			#no_bounds_check start, end := &allocator.data[0], &allocator.data[allocator.curr_offset];
			if start <= old_memory && old_memory < end {
				// NOTE(bill): Cannot free this pointer
				return nil;
			}

			if len(allocator.leaked_allocations) != 0 {
				for ptr, i in allocator.leaked_allocations {
					if ptr == old_memory {
						free(ptr, allocator.backup_allocator);
						ordered_remove(&allocator.leaked_allocations, i);
						return nil;
					}
				}
			}
		}
		// NOTE(bill): It's a temporary memory, don't worry about freeing

	case .Free_All:
		allocator.curr_offset = 0;
		allocator.prev_offset = 0;
		for ptr in allocator.leaked_allocations {
			free(ptr, allocator.backup_allocator);
		}
		clear(&allocator.leaked_allocations);

	case .Resize:
		last_ptr := rawptr(&allocator.data[allocator.prev_offset]);
		if old_memory == last_ptr && len(allocator.data)-allocator.prev_offset >= size {
			allocator.curr_offset = allocator.prev_offset+size;
			return old_memory;
		}
		return default_temp_allocator_proc(allocator_data, Allocator_Mode.Alloc, size, alignment, old_memory, old_size, flags, loc);
	}

	return nil;
}

default_temp_allocator :: proc(allocator: ^Default_Temp_Allocator) -> Allocator {
	return Allocator{
		procedure = default_temp_allocator_proc,
		data = allocator,
	};
}
