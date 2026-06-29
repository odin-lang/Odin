#+no-instrumentation
package sanitizer

@(private="file")
MSAN_ENABLED :: .Memory in ODIN_SANITIZER_FLAGS

@(private="file")
@(default_calling_convention="system")
foreign {
	__msan_unpoison :: proc(addr: rawptr, size: uint) ---
}

/*
Marks a slice as fully initialized.

Code instrumented with `-sanitize:memory` will be permitted to access any
address within the slice as if it had already been initialized.

When msan is not enabled this procedure does nothing.
*/
memory_unpoison_slice :: proc "contextless" (region: $T/[]$E) {
	when MSAN_ENABLED {
		__msan_unpoison(raw_data(region),  size_of(E) * len(region))
	}
}

/*
Marks a pointer as fully initialized.

Code instrumented with `-sanitize:memory` will be permitted to access memory
within the region the pointer points to as if it had already been initialized.

When msan is not enabled this procedure does nothing.
*/
memory_unpoison_ptr :: proc "contextless" (ptr: ^$T) {
	when MSAN_ENABLED {
		__msan_unpoison(ptr, size_of(T))
	}
}

/*
Marks the region covering `[ptr, ptr+len)` as fully initialized.

Code instrumented with `-sanitize:memory` will be permitted to access memory
within this range as if it had already been initialized.

When msan is not enabled this procedure does nothing.
*/
memory_unpoison_rawptr :: proc "contextless" (ptr: rawptr, len: int) {
	when MSAN_ENABLED {
		__msan_unpoison(ptr, uint(len))
	}
}

/*
Marks the region covering `[ptr, ptr+len)` as fully initialized.

Code instrumented with `-sanitize:memory` will be permitted to access memory
within this range as if it had already been initialized.

When msan is not enabled this procedure does nothing.
*/
memory_unpoison_rawptr_uint :: proc "contextless" (ptr: rawptr, len: uint) {
	when MSAN_ENABLED {
		__msan_unpoison(ptr, len)
	}
}

memory_unpoison :: proc {
	memory_unpoison_slice,
	memory_unpoison_ptr,
	memory_unpoison_rawptr,
	memory_unpoison_rawptr_uint,
}
