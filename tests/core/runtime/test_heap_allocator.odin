package test_core_runtime

import "base:runtime"
import "core:testing"

when .Address in ODIN_SANITIZER_FLAGS {
	// Under -sanitize:address the allocator aborts the process on an
	// over-large request ("allocation-size-too-big") instead of returning a
	// null pointer, so the out-of-memory path below would never be reached.
	// Ask AddressSanitizer to return null on such requests, which is the
	// behaviour the non-instrumented allocator already has, so the test can
	// exercise a genuine allocation failure.
	@(export, link_name = "__asan_default_options")
	_asan_default_options :: proc "c" () -> cstring {
		return "allocator_may_return_null=1"
	}
}

@(test)
test_resize_out_of_memory_keeps_array_intact :: proc(t: ^testing.T) {
	// #7262: a failed resize must leave the original array intact. The default
	// heap allocator used to free the original block when the underlying
	// realloc failed (which leaves the original intact), so the later delete()
	// double-freed it, aborting with "free(): invalid pointer".
	//
	// Use the raw heap allocator directly; the test runner otherwise wraps the
	// context in a tracking allocator that does not hit this path.
	context.allocator = runtime.heap_allocator()

	arr := make([dynamic]int, 4)
	defer delete(arr)
	arr[0] = 0x1234

	err := resize(&arr, 1 << 58) // far more memory than can be allocated

	testing.expect_value(t, err, runtime.Allocator_Error.Out_Of_Memory)
	testing.expect_value(t, len(arr), 4)
	testing.expect_value(t, arr[0], 0x1234)
}
