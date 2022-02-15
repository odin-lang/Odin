package runtime

DEFAULT_TEMP_ALLOCATOR_BACKING_SIZE: int : #config(DEFAULT_TEMP_ALLOCATOR_BACKING_SIZE, 1<<22)


when ODIN_OS == .Freestanding || ODIN_OS == .JS || ODIN_DEFAULT_TO_NIL_ALLOCATOR {
	Default_Temp_Allocator :: struct {}
	
	default_temp_allocator_init :: proc(s: ^Default_Temp_Allocator, size: int, backup_allocator := context.allocator) {}
	
	default_temp_allocator_destroy :: proc(s: ^Default_Temp_Allocator) {}
	
	default_temp_allocator_proc :: nil_allocator_proc
} else {
	Default_Temp_Allocator :: struct {
		data:               []byte,
		curr_offset:        int,
		prev_allocation:    rawptr,
		backup_allocator:   Allocator,
		leaked_allocations: [dynamic][]byte,
	}
	
	default_temp_allocator_init :: proc(s: ^Default_Temp_Allocator, size: int, backup_allocator := context.allocator) {
		s.data = make_aligned([]byte, size, 2*align_of(rawptr), backup_allocator)
		s.curr_offset = 0
		s.prev_allocation = nil
		s.backup_allocator = backup_allocator
		s.leaked_allocations.allocator = backup_allocator
	}

	default_temp_allocator_destroy :: proc(s: ^Default_Temp_Allocator) {
		if s == nil {
			return
		}
		for ptr in s.leaked_allocations {
			free(raw_data(ptr), s.backup_allocator)
		}
		delete(s.leaked_allocations)
		delete(s.data, s.backup_allocator)
		s^ = {}
	}

	@(private)
	default_temp_allocator_alloc :: proc(s: ^Default_Temp_Allocator, size, alignment: int, loc := #caller_location) -> ([]byte, Allocator_Error) {
		size := size
		size = align_forward_int(size, alignment)

		switch {
		case s.curr_offset+size <= len(s.data):
			start := uintptr(raw_data(s.data))
			ptr := start + uintptr(s.curr_offset)
			ptr = align_forward_uintptr(ptr, uintptr(alignment))
			mem_zero(rawptr(ptr), size)

			s.prev_allocation = rawptr(ptr)
			offset := int(ptr - start)
			s.curr_offset = offset + size
			return byte_slice(rawptr(ptr), size), .None

		case size <= len(s.data):
			start := uintptr(raw_data(s.data))
			ptr := align_forward_uintptr(start, uintptr(alignment))
			mem_zero(rawptr(ptr), size)

			s.prev_allocation = rawptr(ptr)
			offset := int(ptr - start)
			s.curr_offset = offset + size
			return byte_slice(rawptr(ptr), size), .None
		}
		a := s.backup_allocator
		if a.procedure == nil {
			a = context.allocator
			s.backup_allocator = a
		}

		data, err := mem_alloc_bytes(size, alignment, a, loc)
		if err != nil {
			return data, err
		}
		if s.leaked_allocations == nil {
			s.leaked_allocations = make([dynamic][]byte, a)
		}
		append(&s.leaked_allocations, data)

		// TODO(bill): Should leaks be notified about?
		if logger := context.logger; logger.lowest_level <= .Warning {
			if logger.procedure != nil {
				logger.procedure(logger.data, .Warning, "default temp allocator resorted to backup_allocator" , logger.options, loc)
			}
		}

		return data, .None
	}

	@(private)
	default_temp_allocator_free :: proc(s: ^Default_Temp_Allocator, old_memory: rawptr, loc := #caller_location) -> Allocator_Error {
		if old_memory == nil {
			return .None
		}

		start := uintptr(raw_data(s.data))
		end := start + uintptr(len(s.data))
		old_ptr := uintptr(old_memory)

		if s.prev_allocation == old_memory {
			s.curr_offset = int(uintptr(s.prev_allocation) - start)
			s.prev_allocation = nil
			return .None
		}

		if start <= old_ptr && old_ptr < end {
			// NOTE(bill): Cannot free this pointer but it is valid
			return .None
		}

		if len(s.leaked_allocations) != 0 {
			for data, i in s.leaked_allocations {
				ptr := raw_data(data)
				if ptr == old_memory {
					free(ptr, s.backup_allocator)
					ordered_remove(&s.leaked_allocations, i)
					return .None
				}
			}
		}
		return .Invalid_Pointer
		// panic("invalid pointer passed to default_temp_allocator");
	}

	@(private)
	default_temp_allocator_free_all :: proc(s: ^Default_Temp_Allocator, loc := #caller_location) {
		s.curr_offset = 0
		s.prev_allocation = nil
		for data in s.leaked_allocations {
			free(raw_data(data), s.backup_allocator)
		}
		clear(&s.leaked_allocations)
	}

	@(private)
	default_temp_allocator_resize :: proc(s: ^Default_Temp_Allocator, old_memory: rawptr, old_size, size, alignment: int, loc := #caller_location) -> ([]byte, Allocator_Error) {
		begin := uintptr(raw_data(s.data))
		end := begin + uintptr(len(s.data))
		old_ptr := uintptr(old_memory)
		if old_memory == s.prev_allocation && old_ptr & uintptr(alignment)-1 == 0 {
			if old_ptr+uintptr(size) < end {
				s.curr_offset = int(old_ptr-begin)+size
				return byte_slice(old_memory, size), .None
			}
		}
		data, err := default_temp_allocator_alloc(s, size, alignment, loc)
		if err == .None {
			copy(data, byte_slice(old_memory, old_size))
			err = default_temp_allocator_free(s, old_memory, loc)
		}
		return data, err
	}

	default_temp_allocator_proc :: proc(allocator_data: rawptr, mode: Allocator_Mode,
	                                    size, alignment: int,
	                                    old_memory: rawptr, old_size: int, loc := #caller_location) -> (data: []byte, err: Allocator_Error) {

		s := (^Default_Temp_Allocator)(allocator_data)

		if s.data == nil {
			default_temp_allocator_init(s, DEFAULT_TEMP_ALLOCATOR_BACKING_SIZE, default_allocator())
		}

		switch mode {
		case .Alloc:
			data, err = default_temp_allocator_alloc(s, size, alignment, loc)
		case .Free:
			err = default_temp_allocator_free(s, old_memory, loc)

		case .Free_All:
			default_temp_allocator_free_all(s, loc)

		case .Resize:
			data, err = default_temp_allocator_resize(s, old_memory, old_size, size, alignment, loc)

		case .Query_Features:
			set := (^Allocator_Mode_Set)(old_memory)
			if set != nil {
				set^ = {.Alloc, .Free, .Free_All, .Resize, .Query_Features}
			}

		case .Query_Info:
			// Nothing to give
		}

		return
	}
}

default_temp_allocator :: proc(allocator: ^Default_Temp_Allocator) -> Allocator {
	return Allocator{
		procedure = default_temp_allocator_proc,
		data = allocator,
	}
}