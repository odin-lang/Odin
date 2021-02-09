package runtime

when ODIN_DEFAULT_TO_NIL_ALLOCATOR || ODIN_OS == "freestanding" {
	// mem.nil_allocator reimplementation

	default_allocator_proc :: proc(allocator_data: rawptr, mode: mem.Allocator_Mode,
	                               size, alignment: int,
	                               old_memory: rawptr, old_size: int, flags: u64 = 0, loc := #caller_location) -> rawptr {
		return nil;
	}

	default_allocator :: proc() -> Allocator {
		return Allocator{
			procedure = default_allocator_proc,
			data = nil,
		};
	}
} else when ODIN_OS != "windows" {
	// TODO(bill): reimplement these procedures in the os_specific stuff
	import "core:os"

	default_allocator_proc :: os.heap_allocator_proc;

	default_allocator :: proc() -> Allocator {
		return os.heap_allocator();
	}
}


DEFAULT_TEMP_ALLOCATOR_BACKING_SIZE: int : #config(DEFAULT_TEMP_ALLOCATOR_BACKING_SIZE, 1<<22);


Default_Temp_Allocator :: struct {
	data:               []byte,
	curr_offset:        int,
	prev_allocation:    rawptr,
	backup_allocator:   Allocator,
	leaked_allocations: [dynamic]rawptr,
}

default_temp_allocator_init :: proc(s: ^Default_Temp_Allocator, size: int, backup_allocator := context.allocator) {
	s.data = make_aligned([]byte, size, 2*align_of(rawptr), backup_allocator);
	s.curr_offset = 0;
	s.prev_allocation = nil;
	s.backup_allocator = backup_allocator;
	s.leaked_allocations.allocator = backup_allocator;
}

default_temp_allocator_destroy :: proc(s: ^Default_Temp_Allocator) {
	if s == nil {
		return;
	}
	for ptr in s.leaked_allocations {
		free(ptr, s.backup_allocator);
	}
	delete(s.leaked_allocations);
	delete(s.data, s.backup_allocator);
	s^ = {};
}

default_temp_allocator_proc :: proc(allocator_data: rawptr, mode: Allocator_Mode,
                                    size, alignment: int,
                                    old_memory: rawptr, old_size: int, flags: u64 = 0, loc := #caller_location) -> rawptr {

	s := (^Default_Temp_Allocator)(allocator_data);

	if s.data == nil {
		default_temp_allocator_init(s, DEFAULT_TEMP_ALLOCATOR_BACKING_SIZE, default_allocator());
	}

	size := size;

	switch mode {
	case .Alloc:
		size = align_forward_int(size, alignment);

		switch {
		case s.curr_offset+size <= len(s.data):
			start := uintptr(raw_data(s.data));
			ptr := start + uintptr(s.curr_offset);
			ptr = align_forward_uintptr(ptr, uintptr(alignment));
			mem_zero(rawptr(ptr), size);

			s.prev_allocation = rawptr(ptr);
			offset := int(ptr - start);
			s.curr_offset = offset + size;
			return rawptr(ptr);

		case size <= len(s.data):
			start := uintptr(raw_data(s.data));
			ptr := align_forward_uintptr(start, uintptr(alignment));
			mem_zero(rawptr(ptr), size);

			s.prev_allocation = rawptr(ptr);
			offset := int(ptr - start);
			s.curr_offset = offset + size;
			return rawptr(ptr);
		}
		a := s.backup_allocator;
		if a.procedure == nil {
			a = context.allocator;
			s.backup_allocator = a;
		}

		ptr := mem_alloc(size, alignment, a, loc);
		if s.leaked_allocations == nil {
			s.leaked_allocations = make([dynamic]rawptr, a);
		}
		append(&s.leaked_allocations, ptr);

		// TODO(bill): Should leaks be notified about?
		if logger := context.logger; logger.lowest_level <= .Warning {
			if logger.procedure != nil {
				logger.procedure(logger.data, .Warning, "default temp allocator resorted to backup_allocator" , logger.options, loc);
			}
		}

		return ptr;

	case .Free:
		if old_memory == nil {
			return nil;
		}

		start := uintptr(raw_data(s.data));
		end := start + uintptr(len(s.data));
		old_ptr := uintptr(old_memory);

		if s.prev_allocation == old_memory {
			s.curr_offset = int(uintptr(s.prev_allocation) - uintptr(start));
			s.prev_allocation = nil;
			return nil;
		}

		if start <= old_ptr && old_ptr < end {
			// NOTE(bill): Cannot free this pointer but it is valid
			return nil;
		}

		if len(s.leaked_allocations) != 0 {
			for ptr, i in s.leaked_allocations {
				if ptr == old_memory {
					free(ptr, s.backup_allocator);
					ordered_remove(&s.leaked_allocations, i);
					return nil;
				}
			}
		}
		panic("invalid pointer passed to default_temp_allocator");

	case .Free_All:
		s.curr_offset = 0;
		s.prev_allocation = nil;
		for ptr in s.leaked_allocations {
			free(ptr, s.backup_allocator);
		}
		clear(&s.leaked_allocations);

	case .Resize:
		begin := uintptr(raw_data(s.data));
		end := begin + uintptr(len(s.data));
		old_ptr := uintptr(old_memory);
		if old_memory == s.prev_allocation && old_ptr & uintptr(alignment)-1 == 0 {
			if old_ptr+uintptr(size) < end {
				s.curr_offset = int(old_ptr-begin)+size;
				return old_memory;
			}
		}
		ptr := default_temp_allocator_proc(allocator_data, .Alloc, size, alignment, old_memory, old_size, flags, loc);
		mem_copy(ptr, old_memory, old_size);
		default_temp_allocator_proc(allocator_data, .Free, 0, alignment, old_memory, old_size, flags, loc);
		return ptr;

	case .Query_Features:
		set := (^Allocator_Mode_Set)(old_memory);
		if set != nil {
			set^ = {.Alloc, .Free, .Free_All, .Resize, .Query_Features};
		}
		return set;

	case .Query_Info:
		return nil;
	}

	return nil;
}

default_temp_allocator :: proc(allocator: ^Default_Temp_Allocator) -> Allocator {
	return Allocator{
		procedure = default_temp_allocator_proc,
		data = allocator,
	};
}
