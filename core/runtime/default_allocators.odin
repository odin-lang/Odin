package runtime

when ODIN_DEFAULT_TO_NIL_ALLOCATOR || ODIN_OS == "freestanding" {
	// mem.nil_allocator reimplementation

	default_allocator_proc :: proc(allocator_data: rawptr, mode: mem.Allocator_Mode,
	                               size, alignment: int,
	                               old_memory: rawptr, old_size: int, loc := #caller_location) -> ([]byte, Allocator_Error) {
		return nil, .None;
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

@(private)
byte_slice :: #force_inline proc "contextless" (data: rawptr, len: int) -> (res: []byte) {
	r := (^Raw_Slice)(&res);
	r.data, r.len = data, len;
	return;
}


DEFAULT_TEMP_ALLOCATOR_BACKING_SIZE: int : #config(DEFAULT_TEMP_ALLOCATOR_BACKING_SIZE, 1<<22);


Default_Temp_Allocator :: struct {
	data:               []byte,
	curr_offset:        int,
	prev_allocation:    rawptr,
	backup_allocator:   Allocator,
	leaked_allocations: [dynamic][]byte,
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
		free(raw_data(ptr), s.backup_allocator);
	}
	delete(s.leaked_allocations);
	delete(s.data, s.backup_allocator);
	s^ = {};
}

default_temp_allocator_proc :: proc(allocator_data: rawptr, mode: Allocator_Mode,
                                    size, alignment: int,
                                    old_memory: rawptr, old_size: int, loc := #caller_location) -> ([]byte, Allocator_Error) {

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
			return byte_slice(rawptr(ptr), size), .None;

		case size <= len(s.data):
			start := uintptr(raw_data(s.data));
			ptr := align_forward_uintptr(start, uintptr(alignment));
			mem_zero(rawptr(ptr), size);

			s.prev_allocation = rawptr(ptr);
			offset := int(ptr - start);
			s.curr_offset = offset + size;
			return byte_slice(rawptr(ptr), size), .None;
		}
		a := s.backup_allocator;
		if a.procedure == nil {
			a = context.allocator;
			s.backup_allocator = a;
		}

		data, err := mem_alloc_bytes(size, alignment, a, loc);
		if err != nil {
			return data, err;
		}
		if s.leaked_allocations == nil {
			s.leaked_allocations = make([dynamic][]byte, a);
		}
		append(&s.leaked_allocations, data);

		// TODO(bill): Should leaks be notified about?
		if logger := context.logger; logger.lowest_level <= .Warning {
			if logger.procedure != nil {
				logger.procedure(logger.data, .Warning, "default temp allocator resorted to backup_allocator" , logger.options, loc);
			}
		}

		return data, .None;

	case .Free:
		if old_memory == nil {
			return nil, .None;
		}

		start := uintptr(raw_data(s.data));
		end := start + uintptr(len(s.data));
		old_ptr := uintptr(old_memory);

		if s.prev_allocation == old_memory {
			s.curr_offset = int(uintptr(s.prev_allocation) - start);
			s.prev_allocation = nil;
			return nil, .None;
		}

		if start <= old_ptr && old_ptr < end {
			// NOTE(bill): Cannot free this pointer but it is valid
			return nil, .None;
		}

		if len(s.leaked_allocations) != 0 {
			for data, i in s.leaked_allocations {
				ptr := raw_data(data);
				if ptr == old_memory {
					free(ptr, s.backup_allocator);
					ordered_remove(&s.leaked_allocations, i);
					return nil, .None;
				}
			}
		}
		return nil, .Invalid_Pointer;
		// panic("invalid pointer passed to default_temp_allocator");

	case .Free_All:
		s.curr_offset = 0;
		s.prev_allocation = nil;
		for data in s.leaked_allocations {
			free(raw_data(data), s.backup_allocator);
		}
		clear(&s.leaked_allocations);

	case .Resize:
		begin := uintptr(raw_data(s.data));
		end := begin + uintptr(len(s.data));
		old_ptr := uintptr(old_memory);
		if old_memory == s.prev_allocation && old_ptr & uintptr(alignment)-1 == 0 {
			if old_ptr+uintptr(size) < end {
				s.curr_offset = int(old_ptr-begin)+size;
				return byte_slice(old_memory, size), .None;
			}
		}
		ptr, err := default_temp_allocator_proc(allocator_data, .Alloc, size, alignment, old_memory, old_size, loc);
		if err == .None {
			copy(ptr, byte_slice(old_memory, old_size));
			_, err = default_temp_allocator_proc(allocator_data, .Free, 0, alignment, old_memory, old_size, loc);
		}
		return ptr, err;

	case .Query_Features:
		set := (^Allocator_Mode_Set)(old_memory);
		if set != nil {
			set^ = {.Alloc, .Free, .Free_All, .Resize, .Query_Features};
		}
		return nil, nil;

	case .Query_Info:
		return nil, .None;
	}

	return nil, .None;
}

default_temp_allocator :: proc(allocator: ^Default_Temp_Allocator) -> Allocator {
	return Allocator{
		procedure = default_temp_allocator_proc,
		data = allocator,
	};
}
