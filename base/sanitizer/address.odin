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

Address_Located_Address :: struct {
	category: string,
	name: string,
	region: []byte,
}

Address_Shadow_Mapping :: struct {
	scale: uint,
	offset: uint,
}

/*
Marks a slice as unaddressable

Code instrumented with `-sanitize:address` is forbidden from accessing any address
within the slice. This procedure is not thread-safe because no two threads can
poison or unpoison memory in the same memory region region simultaneously.

When asan is not enabled this procedure does nothing.
*/
@(no_sanitize_address)
address_poison_slice :: proc "contextless" (region: $T/[]$E) {
	when ASAN_ENABLED {
		__asan_poison_memory_region(raw_data(region), size_of(E) * len(region))
	}
}

/*
Marks a slice as addressable

Code instrumented with `-sanitize:address` is allowed to access any address
within the slice again. This procedure is not thread-safe because no two threads
can poison or unpoison memory in the same memory region region simultaneously.

When asan is not enabled this procedure does nothing.
*/
@(no_sanitize_address)
address_unpoison_slice :: proc "contextless" (region: $T/[]$E) {
	when ASAN_ENABLED {
		__asan_unpoison_memory_region(raw_data(region), size_of(E) * len(region))
	}
}

/*
Marks a pointer as unaddressable

Code instrumented with `-sanitize:address` is forbidden from accessing any address
within the region the pointer points to. This procedure is not thread-safe because no
two threads can poison or unpoison memory in the same memory region region simultaneously.

When asan is not enabled this procedure does nothing.
*/
@(no_sanitize_address)
address_poison_ptr :: proc "contextless" (ptr: ^$T) {
	when ASAN_ENABLED {
		__asan_poison_memory_region(ptr, size_of(T))
	}
}

/*
Marks a pointer as addressable

Code instrumented with `-sanitize:address` is allowed to access any address
within the region the pointer points to again. This procedure is not thread-safe
because no two threads can poison or unpoison memory in the same memory region
region simultaneously.

When asan is not enabled this procedure does nothing.
*/
@(no_sanitize_address)
address_unpoison_ptr :: proc "contextless" (ptr: ^$T) {
	when ASAN_ENABLED {
		__asan_unpoison_memory_region(ptr, size_of(T))
	}
}

/*
Marks the region covering `[ptr, ptr+len)` as unaddressable

Code instrumented with `-sanitize:address` is forbidden from accessing any address
within the region. This procedure is not thread-safe because no two threads can
poison or unpoison memory in the same memory region region simultaneously.

When asan is not enabled this procedure does nothing.
*/
@(no_sanitize_address)
address_poison_rawptr :: proc "contextless" (ptr: rawptr, len: int) {
	when ASAN_ENABLED {
		assert_contextless(len >= 0)
		__asan_poison_memory_region(ptr, uint(len))
	}
}

/*
Marks the region covering `[ptr, ptr+len)` as unaddressable

Code instrumented with `-sanitize:address` is forbidden from accessing any address
within the region. This procedure is not thread-safe because no two threads can
poison or unpoison memory in the same memory region region simultaneously.

When asan is not enabled this procedure does nothing.
*/
@(no_sanitize_address)
address_poison_rawptr_uint :: proc "contextless" (ptr: rawptr, len: uint) {
	when ASAN_ENABLED {
		__asan_poison_memory_region(ptr, len)
	}
}

/*
Marks the region covering `[ptr, ptr+len)` as addressable

Code instrumented with `-sanitize:address` is allowed to access any address
within the region again. This procedure is not thread-safe because no two
threads can poison or unpoison memory in the same memory region region simultaneously.

When asan is not enabled this procedure does nothing.
*/
@(no_sanitize_address)
address_unpoison_rawptr :: proc "contextless" (ptr: rawptr, len: int) {
	when ASAN_ENABLED {
		assert_contextless(len >= 0)
		__asan_unpoison_memory_region(ptr, uint(len))
	}
}

/*
Marks the region covering `[ptr, ptr+len)` as addressable

Code instrumented with `-sanitize:address` is allowed to access any address
within the region again. This procedure is not thread-safe because no two
threads can poison or unpoison memory in the same memory region region simultaneously.

When asan is not enabled this procedure does nothing.
*/
@(no_sanitize_address)
address_unpoison_rawptr_uint :: proc "contextless" (ptr: rawptr, len: uint) {
	when ASAN_ENABLED {
		__asan_unpoison_memory_region(ptr, len)
	}
}

address_poison :: proc {
	address_poison_slice,
	address_poison_ptr,
	address_poison_rawptr,
	address_poison_rawptr_uint,
}

address_unpoison :: proc {
	address_unpoison_slice,
	address_unpoison_ptr,
	address_unpoison_rawptr,
	address_unpoison_rawptr_uint,
}

/*
Registers a callback to be run when asan detects a memory error right before terminating
the process.

This can be used for logging and/or debugging purposes.

When asan is not enabled this procedure does nothing.
*/
@(no_sanitize_address)
address_set_death_callback :: proc "contextless" (callback: Address_Death_Callback) {
	when ASAN_ENABLED {
		__sanitizer_set_death_callback(callback)
	}
}

/*
Checks if the memory region covered by the slice is poisoned.

If it is poisoned this procedure returns the address which would result
in an asan error.

When asan is not enabled this procedure returns `nil`.
*/
@(no_sanitize_address)
address_region_is_poisoned_slice :: proc "contextless" (region: $T/[]$E) -> rawptr {
	when ASAN_ENABLED {
		return __asan_region_is_poisoned(raw_data(region), size_of(E) * len(region))
	} else {
		return nil
	}
}

/*
Checks if the memory region pointed to by the pointer is poisoned.

If it is poisoned this procedure returns the address which would result
in an asan error.

When asan is not enabled this procedure returns `nil`.
*/
@(no_sanitize_address)
address_region_is_poisoned_ptr :: proc "contextless" (ptr: ^$T) -> rawptr {
	when ASAN_ENABLED {
		return __asan_region_is_poisoned(ptr, size_of(T))
	} else {
		return nil
	}
}

/*
Checks if the memory region covered by `[ptr, ptr+len)` is poisoned.

If it is poisoned this procedure returns the address which would result
in an asan error.

When asan is not enabled this procedure returns `nil`.
*/
@(no_sanitize_address)
address_region_is_poisoned_rawptr :: proc "contextless" (region: rawptr, len: int) -> rawptr {
	when ASAN_ENABLED {
		assert_contextless(len >= 0)
		return __asan_region_is_poisoned(region, uint(len))
	} else {
		return nil
	}
}

/*
Checks if the memory region covered by `[ptr, ptr+len)` is poisoned.

If it is poisoned this procedure returns the address which would result
in an asan error.

When asan is not enabled this procedure returns `nil`.
*/
@(no_sanitize_address)
address_region_is_poisoned_rawptr_uint :: proc "contextless" (region: rawptr, len: uint) -> rawptr {
	when ASAN_ENABLED {
		return __asan_region_is_poisoned(region, len)
	} else {
		return nil
	}
}


address_region_is_poisoned :: proc {
	address_region_is_poisoned_slice,
	address_region_is_poisoned_ptr,
	address_region_is_poisoned_rawptr,
	address_region_is_poisoned_rawptr_uint,
}

/*
Checks if the address is poisoned.

If it is poisoned this procedure returns `true`, otherwise it returns
`false`.

When asan is not enabled this procedure returns `false`.
*/
@(no_sanitize_address)
address_is_poisoned :: proc "contextless" (address: rawptr) -> bool {
	when ASAN_ENABLED {
		return __asan_address_is_poisoned(address) != 0
	} else {
		return false
	}
}

/*
Describes the sanitizer state for an address.

This procedure prints the description out to `stdout`.

When asan is not enabled this procedure does nothing.
*/
@(no_sanitize_address)
address_describe_address :: proc "contextless" (address: rawptr) {
	when ASAN_ENABLED {
		__asan_describe_address(address)
	}
}

/*
Returns `true` if an asan error has occured, otherwise it returns
`false`.

When asan is not enabled this procedure returns `false`.
*/
@(no_sanitize_address)
address_report_present :: proc "contextless" () -> bool {
	when ASAN_ENABLED {
		return __asan_report_present() != 0
	} else {
		return false
	}
}

/*
Returns the program counter register value of an asan error.

If no asan error has occurd `nil` is returned.

When asan is not enabled this procedure returns `nil`.
*/
@(no_sanitize_address)
address_get_report_pc :: proc "contextless" () -> rawptr {
	when ASAN_ENABLED {
		return __asan_get_report_pc()
	} else {
		return nil
	}
}

/*
Returns the base pointer register value of an asan error.

If no asan error has occurd `nil` is returned.

When asan is not enabled this procedure returns `nil`.
*/
@(no_sanitize_address)
address_get_report_bp :: proc "contextless" () -> rawptr {
	when ASAN_ENABLED {
		return __asan_get_report_bp()
	} else {
		return nil
	}
}

/*
Returns the stack pointer register value of an asan error.

If no asan error has occurd `nil` is returned.

When asan is not enabled this procedure returns `nil`.
*/
@(no_sanitize_address)
address_get_report_sp :: proc "contextless" () -> rawptr {
	when ASAN_ENABLED {
		return __asan_get_report_sp()
	} else {
		return nil
	}
}

/*
Returns the report buffer address of an asan error.

If no asan error has occurd `nil` is returned.

When asan is not enabled this procedure returns `nil`.
*/
@(no_sanitize_address)
address_get_report_address :: proc "contextless" () -> rawptr {
	when ASAN_ENABLED {
		return __asan_get_report_address()
	} else {
		return nil
	}
}

/*
Returns the address access type of an asan error.

If no asan error has occurd `.none` is returned.

When asan is not enabled this procedure returns `.none`.
*/
@(no_sanitize_address)
address_get_report_access_type :: proc "contextless" () -> Address_Access_Type {
	when ASAN_ENABLED {
		if ! address_report_present() {
			return .none
		}
		return __asan_get_report_access_type() == 0 ? .read : .write
	} else {
		return .none
	}
}

/*
Returns the access size of an asan error.

If no asan error has occurd `0` is returned.

When asan is not enabled this procedure returns `0`.
*/
@(no_sanitize_address)
address_get_report_access_size :: proc "contextless" () -> uint {
	when ASAN_ENABLED {
		return __asan_get_report_access_size()
	} else {
		return 0
	}
}

/*
Returns the bug description of an asan error.

If no asan error has occurd an empty string is returned.

When asan is not enabled this procedure returns an empty string.
*/
@(no_sanitize_address)
address_get_report_description :: proc "contextless" () -> string {
	when ASAN_ENABLED {
		return string(__asan_get_report_description())
	} else {
		return ""
	}
}

/*
Returns asan information about the address provided, writing the category into `data`.

The information provided include:
* The category of the address, i.e. stack, global, heap, etc.
* The name of the variable this address belongs to
* The memory region of the address

When asan is not enabled this procedure returns zero initialised values.
*/
@(no_sanitize_address)
address_locate_address :: proc "contextless" (addr: rawptr, data: []byte) -> Address_Located_Address {
	when ASAN_ENABLED {
		out_addr: rawptr
		out_size: uint
		str := __asan_locate_address(addr, raw_data(data), len(data), &out_addr, &out_size)
		return { string(str), string(cstring(raw_data(data))), (cast([^]byte)out_addr)[:out_size] }, 
	} else {
		return { "", "", {} }
	}
}

/*
Returns the allocation stack trace and thread id for a heap address.

The stack trace is filled into the `data` slice.

When asan is not enabled this procedure returns a zero initialised value.
*/
@(no_sanitize_address)
address_get_alloc_stack_trace :: proc "contextless" (addr: rawptr, data: []rawptr) -> ([]rawptr, int) {
	when ASAN_ENABLED {
		out_thread: i32
		__asan_get_alloc_stack(addr, raw_data(data), len(data), &out_thread)
		return data, int(out_thread)
	} else {
		return {}, 0
	}
}

/*
Returns the free stack trace and thread id for a heap address.

The stack trace is filled into the `data` slice.

When asan is not enabled this procedure returns zero initialised values.
*/
@(no_sanitize_address)
address_get_free_stack_trace :: proc "contextless" (addr: rawptr, data: []rawptr) -> ([]rawptr, int) {
	when ASAN_ENABLED {
		out_thread: i32
		__asan_get_free_stack(addr, raw_data(data), len(data), &out_thread)
		return data, int(out_thread)
	} else {
		return {}, 0
	}
}

/*
Returns the current asan shadow memory mapping.

When asan is not enabled this procedure returns a zero initialised value.
*/
@(no_sanitize_address)
address_get_shadow_mapping :: proc "contextless" () -> Address_Shadow_Mapping {
	when ASAN_ENABLED {
		result: Address_Shadow_Mapping
		__asan_get_shadow_mapping(&result.scale, &result.offset)
		return result
	} else {
		return {}
	}
}

/*
Prints asan statistics to `stderr`

When asan is not enabled this procedure does nothing.
*/
@(no_sanitize_address)
address_print_accumulated_stats :: proc "contextless" () {
	when ASAN_ENABLED {
		__asan_print_accumulated_stats()
	}
}

/*
Returns the address of the current fake stack used by asan.

This pointer can be then used for `address_is_in_fake_stack`.

When asan is not enabled this procedure returns `nil`.
*/
@(no_sanitize_address)
address_get_current_fake_stack :: proc "contextless" () -> rawptr {
	when ASAN_ENABLED {
		return __asan_get_current_fake_stack()
	} else {
		return nil
	}
}

/*
Returns if an address belongs to a given fake stack and if so the region of the fake frame.

When asan is not enabled this procedure returns zero initialised values.
*/
@(no_sanitize_address)
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

/*
Performs shadow memory cleanup for the current thread before a procedure with no return is called
i.e. a procedure such as `panic` and `os.exit`.

When asan is not enabled this procedure does nothing.
*/
@(no_sanitize_address)
address_handle_no_return :: proc "contextless" () {
	when ASAN_ENABLED {
		__asan_handle_no_return()
	}
}

/*
Updates the allocation stack trace for the given address.

Returns `true` if successful, otherwise it returns `false`.

When asan is not enabled this procedure returns `false`.
*/
@(no_sanitize_address)
address_update_allocation_context :: proc "contextless" (addr: rawptr) -> bool {
	when ASAN_ENABLED {
		return __asan_update_allocation_context(addr) != 0
	} else {
		return false
	}
}

