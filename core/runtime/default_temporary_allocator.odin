package runtime

DEFAULT_TEMP_ALLOCATOR_BACKING_SIZE: int : #config(DEFAULT_TEMP_ALLOCATOR_BACKING_SIZE, 4 * Megabyte)


when ODIN_OS == .Freestanding || ODIN_OS == .JS || ODIN_DEFAULT_TO_NIL_ALLOCATOR {
	Default_Temp_Allocator :: struct {}
	
	default_temp_allocator_init :: proc(s: ^Default_Temp_Allocator, size: int, backing_allocator := context.allocator) {}
	
	default_temp_allocator_destroy :: proc(s: ^Default_Temp_Allocator) {}
	
	default_temp_allocator_proc :: nil_allocator_proc
} else {
	Default_Temp_Allocator :: struct {
		arena: Arena,
	}
	
	default_temp_allocator_init :: proc(s: ^Default_Temp_Allocator, size: int, backing_allocator := context.allocator) {
		_ = arena_init(&s.arena, uint(size), backing_allocator)
	}

	default_temp_allocator_destroy :: proc(s: ^Default_Temp_Allocator) {
		if s != nil {
			arena_destroy(&s.arena)
			s^ = {}
		}
	}

	default_temp_allocator_proc :: proc(allocator_data: rawptr, mode: Allocator_Mode,
	                                    size, alignment: int,
	                                    old_memory: rawptr, old_size: int, loc := #caller_location) -> (data: []byte, err: Allocator_Error) {

		s := (^Default_Temp_Allocator)(allocator_data)
		return arena_allocator_proc(&s.arena, mode, size, alignment, old_memory, old_size, loc)
	}
}

default_temp_allocator :: proc(allocator: ^Default_Temp_Allocator) -> Allocator {
	return Allocator{
		procedure = default_temp_allocator_proc,
		data      = allocator,
	}
}
