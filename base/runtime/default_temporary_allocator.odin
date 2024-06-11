package runtime

DEFAULT_TEMP_ALLOCATOR_BACKING_SIZE: int : #config(DEFAULT_TEMP_ALLOCATOR_BACKING_SIZE, 4 * Megabyte)
NO_DEFAULT_TEMP_ALLOCATOR: bool : ODIN_OS == .Freestanding || ODIN_DEFAULT_TO_NIL_ALLOCATOR

when NO_DEFAULT_TEMP_ALLOCATOR {
	Default_Temp_Allocator :: struct {}
	
	default_temp_allocator_init :: proc(s: ^Default_Temp_Allocator, size: int, backing_allocator := context.allocator) {}
	
	default_temp_allocator_destroy :: proc(s: ^Default_Temp_Allocator) {}
	
	default_temp_allocator_proc :: nil_allocator_proc

	@(require_results)
	default_temp_allocator_temp_begin :: proc(loc := #caller_location) -> (temp: Arena_Temp) {
		return
	}

	default_temp_allocator_temp_end :: proc(temp: Arena_Temp, loc := #caller_location) {
	}
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

	@(require_results)
	default_temp_allocator_temp_begin :: proc(loc := #caller_location) -> (temp: Arena_Temp) {
		if context.temp_allocator.data == &global_default_temp_allocator_data {
			temp = arena_temp_begin(&global_default_temp_allocator_data.arena, loc)
		}
		return
	}

	default_temp_allocator_temp_end :: proc(temp: Arena_Temp, loc := #caller_location) {
		arena_temp_end(temp, loc)
	}

	@(fini, private)
	_destroy_temp_allocator_fini :: proc() {
		default_temp_allocator_destroy(&global_default_temp_allocator_data)
	}
}

@(deferred_out=default_temp_allocator_temp_end)
DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD :: #force_inline proc(ignore := false, loc := #caller_location) -> (Arena_Temp, Source_Code_Location) {
	if ignore {
		return {}, loc
	} else {
		return default_temp_allocator_temp_begin(loc), loc
	}
}


default_temp_allocator :: proc(allocator: ^Default_Temp_Allocator) -> Allocator {
	return Allocator{
		procedure = default_temp_allocator_proc,
		data      = allocator,
	}
}
