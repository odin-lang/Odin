#+no-instrumentation
package runtime

Asan_Death_Callback :: #type proc "c" (pc: rawptr, bp: rawptr, sp: rawptr, addr: rawptr, is_write: i32, access_size: uint)

@(private="file")
ASAN_ENABLED :: .Address in ODIN_SANITIZER_FLAGS

@(private="file")
@(default_calling_convention="system")
foreign {
	__asan_poison_memory_region      :: proc(address: rawptr, size: uint) ---
	__asan_unpoison_memory_region    :: proc(address: rawptr, size: uint) ---
	__sanitizer_set_death_callback   :: proc(callback: Asan_Death_Callback) ---
	__asan_region_is_poisoned        :: proc(begin: rawptr, size: uint) -> rawptr ---
	__asan_address_is_poisoned       :: proc(addr: rawptr) -> i32 ---
	__asan_describe_address          :: proc(addr: rawptr) ---
	__asan_report_present            :: proc() -> i32 ---
	__asan_get_report_pc             :: proc() -> rawptr ---
	__asan_get_report_bp             :: proc() -> rawptr ---
	__asan_get_report_sp             :: proc() -> rawptr ---
	__asan_get_report_address        :: proc() -> rawptr ---
	__asan_get_report_access_type    :: proc() -> i32 ---
	__asan_get_report_access_size    :: proc() -> uint ---
	__asan_get_report_description    :: proc() -> cstring ---
	__asan_locate_address            :: proc(addr: rawptr, name: rawptr, name_size: uint, region_address: ^rawptr, region_size: ^uint) -> cstring ---
	__asan_get_alloc_stack           :: proc(addr: rawptr, trace: rawptr, size: uint, thread_id: ^i32) -> uint ---
	__asan_get_free_stack            :: proc(addr: rawptr, trace: rawptr, size: uint, thread_id: ^i32) -> uint ---
	__asan_get_shadow_mapping        :: proc(shadow_scale: ^uint, shadow_offset: ^uint) ---
	__asan_print_accumulated_stats   :: proc() ---
	__asan_get_current_fake_stack    :: proc() -> rawptr ---
	__asan_addr_is_in_fake_stack     :: proc(fake_stack: rawptr, addr: rawptr, beg: ^rawptr, end: ^rawptr) -> rawptr ---
	__asan_handle_no_return          :: proc() ---
	__asan_update_allocation_context :: proc(addr: rawptr) -> i32 ---
}

Asan_Access_Type :: enum {
	none,
	read,
	write,
}

Asan_Located_Address_String :: struct {
	category: string,
	name: string,
}

Asan_Shadow_Mapping :: struct {
	scale, offset: uint
}

asan_poison_slice :: proc(region: $T/[]$E) {
	when ASAN_ENABLED {
		__asan_poison_memory_region(raw_data(region), size_of(E) * len(region))
	}
}

asan_unpoison_slice :: proc(region: $T/[]$E) {
	when ASAN_ENABLED {
		__asan_unpoison_memory_region(raw_data(region), size_of(E) * len(region))
	}
}

asan_poison_ptr :: proc(ptr: ^$T) {
	when ASAN_ENABLED {
		__asan_poison_memory_region(ptr, size_of(T))
	}
}

asan_unpoison_ptr :: proc(ptr: ^$T) {
	when ASAN_ENABLED {
		__asan_unpoison_memory_region(ptr, size_of(T))
	}
}

asan_poison_rawptr :: proc(ptr: rawptr, len: int) {
	when ASAN_ENABLED {
		assert(len >= 0)
		__asan_poison_memory_region(ptr, uint(len))
	}
}

asan_unpoison_rawptr :: proc(ptr: rawptr, len: int) {
	when ASAN_ENABLED {
		assert(len >= 0)
		__asan_unpoison_memory_region(ptr, uint(len))
	}
}

asan_poison :: proc {
	asan_poison_slice,
	asan_poison_ptr,
	asan_poison_rawptr,
}

asan_unpoison :: proc {
	asan_unpoison_slice,
	asan_unpoison_ptr,
	asan_unpoison_rawptr,
}

asan_set_death_callback :: proc(callback: Asan_Death_Callback) {
	when ASAN_ENABLED {
		__sanitizer_set_death_callback(callback)
	}
}

asan_region_is_poisoned_slice :: proc(region: []$T/$E) -> rawptr {
	when ASAN_ENABLED {
		return __asan_region_is_poisoned(raw_data(region), size_of(E) * len(region))
	} else {
		return nil
	}
}

asan_region_is_poisoned_ptr :: proc(ptr: ^$T) -> rawptr {
	when ASAN_ENABLED {
		return __asan_region_is_poisoned(ptr, size_of(T))
	} else {
		return nil
	}
}

asan_region_is_poisoned_rawptr :: proc(region: rawptr, len: int) -> rawptr {
	when ASAN_ENABLED {
		assert(len >= 0)
		return __asan_region_is_poisoned(region, uint(len))
	} else {
		return nil
	}
}

asan_region_is_poisoned :: proc {
	asan_region_is_poisoned_slice,
	asan_region_is_poisoned_ptr,
	asan_region_is_poisoned_rawptr,
}

asan_address_is_poisoned :: proc(address: rawptr) -> bool {
	when ASAN_ENABLED {
		return __asan_address_is_poisoned(address) != 0
	} else {
		return false
	}
}

asan_describe_address :: proc(address: rawptr) {
	when ASAN_ENABLED {
		__asan_describe_address(address)
	}
}

asan_report_present :: proc() -> bool {
	when ASAN_ENABLED {
		return __asan_report_present() != 0
	} else {
		return false
	}
}

asan_get_report_pc :: proc() -> rawptr {
	when ASAN_ENABLED {
		return __asan_get_report_pc()
	} else {
		return nil
	}
}

asan_get_report_bp :: proc() -> rawptr {
	when ASAN_ENABLED {
		return __asan_get_report_bp()
	} else {
		return nil
	}
}

asan_get_report_sp :: proc() -> rawptr {
	when ASAN_ENABLED {
		return __asan_get_report_sp()
	} else {
		return nil
	}
}

asan_get_report_address :: proc() -> rawptr {
	when ASAN_ENABLED {
		return __asan_get_report_address()
	} else {
		return nil
	}
}

asan_get_report_access_type :: proc() -> Asan_Access_Type {
	when ASAN_ENABLED {
		return __asan_get_report_access_type() == 0 ? .read : .write
	} else {
		return .none
	}
}

asan_get_report_access_size :: proc() -> uint {
	when ASAN_ENABLED {
		return __asan_get_report_access_size()
	} else {
		return 0
	}
}

asan_get_report_description :: proc() -> string {
	when ASAN_ENABLED {
		return string(__asan_get_report_description())
	} else {
		return "unknown"
	}
}

asan_locate_address :: proc(addr: rawptr, allocator: Allocator, string_alloc_size := 64) -> (Asan_Located_Address_String, []byte, Allocator_Error) {
	when ASAN_ENABLED {
		data, err := make([]byte, string_alloc_size, allocator)
		if err != nil {
			return { "", "" }, {}, err
		}
		out_addr: rawptr
		out_size: uint
		str := __asan_locate_address(addr, raw_data(data), len(data), &out_addr, &out_size)
		return { string(str), string(cstring(raw_data(data))) }, (cast([^]byte)out_addr)[:out_size], nil
	} else {
		return { "", "" }, {}, nil
	}
}

asan_get_alloc_stack_trace :: proc(addr: rawptr, allocator: Allocator, stack_alloc_size := 32) -> ([]rawptr, int, Allocator_Error) {
	when ASAN_ENABLED {
		data, err := make([]rawptr, stack_alloc_size, allocator)
		if err != nil {
			return {}, 0, err
		}
		out_thread: i32
		__asan_get_alloc_stack(addr, raw_data(data), len(data), &out_thread)
		return data, int(out_thread), nil
	} else {
		return {}, 0, nil
	}
}

asan_get_free_stack_trace :: proc(addr: rawptr, allocator: Allocator, stack_alloc_size := 32) -> ([]rawptr, int, Allocator_Error) {
	when ASAN_ENABLED {
		data, err := make([]rawptr, stack_alloc_size, allocator)
		if err != nil {
			return {}, 0, err
		}
		out_thread: i32
		__asan_get_free_stack(addr, raw_data(data), len(data), &out_thread)
		return data, int(out_thread), nil
	} else {
		return {}, 0, nil
	}
}

asan_get_shadow_mapping :: proc() -> Asan_Shadow_Mapping {
	when ASAN_ENABLED {
		result: Asan_Shadow_Mapping
		__asan_get_shadow_mapping(&result.scale, &result.offset)
		return result
	} else {
		return {}
	}
}

asan_print_accumulated_stats :: proc() {
	when ASAN_ENABLED {
		__asan_print_accumulated_stats()
	}
}

asan_get_current_fake_stack :: proc() -> rawptr {
	when ASAN_ENABLED {
		return __asan_get_current_fake_stack()
	} else {
		return nil
	}
}

asan_is_in_fake_stack :: proc(fake_stack: rawptr, addr: rawptr) -> ([]byte, bool) {
	when ASAN_ENABLED {
		begin: rawptr
		end: rawptr
		addr := __asan_addr_is_in_fake_stack(fake_stack, addr, &begin, &end)
		if addr == nil {
			return {}, false
		}
		return ((cast([^]byte)begin)[:uintptr(end)-uintptr(begin)]), true
	} else {
		return {}, false
	}
}

asan_handle_no_return :: proc() {
	when ASAN_ENABLED {
		__asan_handle_no_return()
	}
}

asan_update_allocation_context :: proc(addr: rawptr) -> bool {
	when ASAN_ENABLED {
		return __asan_update_allocation_context(addr) != 0
	} else {
		return false
	}
}

