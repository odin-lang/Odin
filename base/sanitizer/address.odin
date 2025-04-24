#+no-instrumentation
package sanitizer

Address_Death_Callback :: #type proc "c" (pc: rawptr, bp: rawptr, sp: rawptr, addr: rawptr, is_write: i32, access_size: uint)

@(private="file")
ASAN_ENABLED :: .Address in ODIN_SANITIZER_FLAGS

@(private="file")
@(default_calling_convention="system")
foreign {
	__asan_poison_memory_region      :: proc(address: rawptr, size: uint) ---
	__asan_unpoison_memory_region    :: proc(address: rawptr, size: uint) ---
	__sanitizer_set_death_callback   :: proc(callback: Address_Death_Callback) ---
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

Address_Access_Type :: enum {
	none,
	read,
	write,
}

Address_Located_Address_String :: struct {
	category: string,
	name: string,
}

Address_Shadow_Mapping :: struct {
	scale: uint,
	offset: uint,
}

address_poison_slice :: proc "contextless" (region: $T/[]$E) {
	when ASAN_ENABLED {
		__asan_poison_memory_region(raw_data(region), size_of(E) * len(region))
	}
}

address_unpoison_slice :: proc "contextless" (region: $T/[]$E) {
	when ASAN_ENABLED {
		__asan_unpoison_memory_region(raw_data(region), size_of(E) * len(region))
	}
}

address_poison_ptr :: proc "contextless" (ptr: ^$T) {
	when ASAN_ENABLED {
		__asan_poison_memory_region(ptr, size_of(T))
	}
}

address_unpoison_ptr :: proc "contextless" (ptr: ^$T) {
	when ASAN_ENABLED {
		__asan_unpoison_memory_region(ptr, size_of(T))
	}
}

address_poison_rawptr :: proc "contextless" (ptr: rawptr, len: int) {
	when ASAN_ENABLED {
		assert_contextless(len >= 0)
		__asan_poison_memory_region(ptr, uint(len))
	}
}

address_unpoison_rawptr :: proc "contextless" (ptr: rawptr, len: int) {
	when ASAN_ENABLED {
		assert_contextless(len >= 0)
		__asan_unpoison_memory_region(ptr, uint(len))
	}
}

address_poison :: proc {
	address_poison_slice,
	address_poison_ptr,
	address_poison_rawptr,
}

address_unpoison :: proc {
	address_unpoison_slice,
	address_unpoison_ptr,
	address_unpoison_rawptr,
}

address_set_death_callback :: proc "contextless" (callback: Address_Death_Callback) {
	when ASAN_ENABLED {
		__sanitizer_set_death_callback(callback)
	}
}

address_region_is_poisoned_slice :: proc "contextless" (region: []$T/$E) -> rawptr {
	when ASAN_ENABLED {
		return __asan_region_is_poisoned(raw_data(region), size_of(E) * len(region))
	} else {
		return nil
	}
}

address_region_is_poisoned_ptr :: proc "contextless" (ptr: ^$T) -> rawptr {
	when ASAN_ENABLED {
		return __asan_region_is_poisoned(ptr, size_of(T))
	} else {
		return nil
	}
}

address_region_is_poisoned_rawptr :: proc "contextless" (region: rawptr, len: int) -> rawptr {
	when ASAN_ENABLED {
		assert_contextless(len >= 0)
		return __asan_region_is_poisoned(region, uint(len))
	} else {
		return nil
	}
}

address_region_is_poisoned :: proc {
	address_region_is_poisoned_slice,
	address_region_is_poisoned_ptr,
	address_region_is_poisoned_rawptr,
}

address_address_is_poisoned :: proc "contextless" (address: rawptr) -> bool {
	when ASAN_ENABLED {
		return __asan_address_is_poisoned(address) != 0
	} else {
		return false
	}
}

address_describe_address :: proc "contextless" (address: rawptr) {
	when ASAN_ENABLED {
		__asan_describe_address(address)
	}
}

address_report_present :: proc "contextless" () -> bool {
	when ASAN_ENABLED {
		return __asan_report_present() != 0
	} else {
		return false
	}
}

address_get_report_pc :: proc "contextless" () -> rawptr {
	when ASAN_ENABLED {
		return __asan_get_report_pc()
	} else {
		return nil
	}
}

address_get_report_bp :: proc "contextless" () -> rawptr {
	when ASAN_ENABLED {
		return __asan_get_report_bp()
	} else {
		return nil
	}
}

address_get_report_sp :: proc "contextless" () -> rawptr {
	when ASAN_ENABLED {
		return __asan_get_report_sp()
	} else {
		return nil
	}
}

address_get_report_address :: proc "contextless" () -> rawptr {
	when ASAN_ENABLED {
		return __asan_get_report_address()
	} else {
		return nil
	}
}

address_get_report_access_type :: proc "contextless" () -> Address_Access_Type {
	when ASAN_ENABLED {
		return __asan_get_report_access_type() == 0 ? .read : .write
	} else {
		return .none
	}
}

address_get_report_access_size :: proc "contextless" () -> uint {
	when ASAN_ENABLED {
		return __asan_get_report_access_size()
	} else {
		return 0
	}
}

address_get_report_description :: proc "contextless" () -> string {
	when ASAN_ENABLED {
		return string(__asan_get_report_description())
	} else {
		return "unknown"
	}
}

address_locate_address :: proc "contextless" (addr: rawptr, data: []byte) -> (Address_Located_Address_String, []byte) {
	when ASAN_ENABLED {
		out_addr: rawptr
		out_size: uint
		str := __asan_locate_address(addr, raw_data(data), len(data), &out_addr, &out_size)
		return { string(str), string(cstring(raw_data(data))) }, (cast([^]byte)out_addr)[:out_size]
	} else {
		return { "", "" }, {}
	}
}

address_get_alloc_stack_trace :: proc "contextless" (addr: rawptr, data: []rawptr) -> ([]rawptr, int) {
	when ASAN_ENABLED {
		out_thread: i32
		__asan_get_alloc_stack(addr, raw_data(data), len(data), &out_thread)
		return data, int(out_thread)
	} else {
		return {}, 0
	}
}

address_get_free_stack_trace :: proc "contextless" (addr: rawptr, data: []rawptr) -> ([]rawptr, int) {
	when ASAN_ENABLED {
		out_thread: i32
		__asan_get_free_stack(addr, raw_data(data), len(data), &out_thread)
		return data, int(out_thread)
	} else {
		return {}, 0
	}
}

address_get_shadow_mapping :: proc "contextless" () -> Address_Shadow_Mapping {
	when ASAN_ENABLED {
		result: Address_Shadow_Mapping
		__asan_get_shadow_mapping(&result.scale, &result.offset)
		return result
	} else {
		return {}
	}
}

address_print_accumulated_stats :: proc "contextless" () {
	when ASAN_ENABLED {
		__asan_print_accumulated_stats()
	}
}

address_get_current_fake_stack :: proc "contextless" () -> rawptr {
	when ASAN_ENABLED {
		return __asan_get_current_fake_stack()
	} else {
		return nil
	}
}

address_is_in_fake_stack :: proc "contextless" (fake_stack: rawptr, addr: rawptr) -> ([]byte, bool) {
	when ASAN_ENABLED {
		begin: rawptr
		end: rawptr
		if __asan_addr_is_in_fake_stack(fake_stack, addr, &begin, &end) == nil {
			return {}, false
		}
		return ((cast([^]byte)begin)[:uintptr(end)-uintptr(begin)]), true
	} else {
		return {}, false
	}
}

address_handle_no_return :: proc "contextless" () {
	when ASAN_ENABLED {
		__asan_handle_no_return()
	}
}

address_update_allocation_context :: proc "contextless" (addr: rawptr) -> bool {
	when ASAN_ENABLED {
		return __asan_update_allocation_context(addr) != 0
	} else {
		return false
	}
}

