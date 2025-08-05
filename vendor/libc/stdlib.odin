package odin_libc

import "base:intrinsics"
import "base:runtime"

import "core:c"
import "core:os"
import "core:slice"
import "core:sort"
import "core:strconv"
import "core:strings"

@(require, linkage="strong", link_name="malloc")
malloc :: proc "c" (size: uint) -> rawptr {
	context = g_ctx
	ptr, err := runtime.mem_alloc_non_zeroed(int(size))
	assert(err == nil, "allocation failure")
	return raw_data(ptr)
}

@(require, linkage="strong", link_name="aligned_alloc")
aligned_alloc :: proc "c" (alignment: uint, size: uint) -> rawptr {
	context = g_ctx
	ptr, err := runtime.mem_alloc_non_zeroed(int(size), int(alignment))
	assert(err == nil, "allocation failure")
	return raw_data(ptr)
}

@(require, linkage="strong", link_name="free")
free :: proc "c" (ptr: rawptr) {
	context = g_ctx
	runtime.mem_free(ptr)
}

@(require, linkage="strong", link_name="realloc")
realloc :: proc "c" (ptr: rawptr, new_size: uint) -> rawptr {
	context = g_ctx
	// -1 for the old_size, assumed to be wrapped with the mem.Compat_Allocator to get the right size.
	// Note that realloc does not actually care about alignment and is allowed to just align it to something
	// else than the original allocation.
	ptr, err := runtime.non_zero_mem_resize(ptr, -1, int(new_size))
	assert(err == nil, "realloc failure")
	return raw_data(ptr)
}

@(require, linkage="strong", link_name="qsort")
qsort :: proc "c" (base: rawptr, num: uint, size: uint, cmp: proc "c" (a, b: rawptr) -> i32) {
	context = g_ctx

	Inputs :: struct {
		base: rawptr,
		num:  uint,
		size: uint,
		cmp:  proc "c" (a, b: rawptr) -> i32,
	}

	sort.sort({
		collection = &Inputs{base, num, size, cmp},
		len = proc(it: sort.Interface) -> int {
			inputs := (^Inputs)(it.collection)
			return int(inputs.num)
		},
		less = proc(it: sort.Interface, i, j: int) -> bool {
			inputs := (^Inputs)(it.collection)
			a := rawptr(uintptr(inputs.base) + (uintptr(i) * uintptr(inputs.size)))
			b := rawptr(uintptr(inputs.base) + (uintptr(j) * uintptr(inputs.size)))
			return inputs.cmp(a, b) < 0
		},
		swap = proc(it: sort.Interface, i, j: int) {
			inputs := (^Inputs)(it.collection)

			a := rawptr(uintptr(inputs.base) + (uintptr(i) * uintptr(inputs.size)))
			b := rawptr(uintptr(inputs.base) + (uintptr(j) * uintptr(inputs.size)))

			slice.ptr_swap_non_overlapping(a, b, int(inputs.size))
		},
	})
}

@(require, linkage="strong", link_name="atoi")
atoi :: proc "c" (str: cstring) -> i32 {
	return i32(atoll(str))
}

@(require, linkage="strong", link_name="atol")
atol :: proc "c" (str: cstring) -> c.long {
	return c.long(atoll(str))
}

@(require, linkage="strong", link_name="atoll")
atoll :: proc "c" (str: cstring) -> c.longlong {
	context = g_ctx

	sstr := string(str)
	sstr  = strings.trim_left_space(sstr)
	i, _ := strconv.parse_i64_of_base(sstr, 10)
	return c.longlong(i)
}

@(require, linkage="strong", link_name="atof")
atof :: proc "c" (str: cstring) -> f64 {
	context = g_ctx

	sstr := string(str)
	sstr  = strings.trim_left_space(sstr)
	f, _ := strconv.parse_f64(sstr)
	return f
}

@(require, linkage="strong", link_name="strtol")
strtol :: proc "c" (str: cstring, str_end: ^cstring, base: i32) -> c.long {
	context = g_ctx
	sstr := string(str)
	sstr  = strings.trim_left_space(sstr)

	n: int
	i, _ := strconv.parse_i64_of_base(sstr, int(base), &n)
	str_end ^= cstring(raw_data(sstr)[n:])
	if str_end != nil {
		str_end ^= cstring(raw_data(sstr)[n:])
	}
	return c.long(clamp(i, i64(min(c.long)), i64(max(c.long))))
}

@(require, linkage="strong", link_name="strtod")
strtod :: proc "c" (str: cstring, str_end: ^cstring) -> c.double {
	context = g_ctx

	sstr := string(str)
	sstr  = strings.trim_left_space(sstr)

	n: int
	val, _ := strconv.parse_f64(sstr, &n)
	if str_end != nil {
		str_end ^= cstring(raw_data(sstr)[n:])
	}

	return c.double(val)
}

@(require, linkage="strong", link_name="abort")
abort :: proc "c" () -> ! {
	intrinsics.trap()
}

ATEXIT_MAX :: 32

@(private)
atexit_functions: [ATEXIT_MAX]proc "c" ()
@(private)
atexit_functions_count: int

@(require, linkage="strong", link_name="atexit")
atexit :: proc "c" (function: proc "c" ()) -> i32 {
	entry := intrinsics.atomic_add(&atexit_functions_count, 1)
	if entry >= ATEXIT_MAX {
		return -1
	}

	atexit_functions[entry] = function
	return 0
}


@(require, linkage="strong", link_name="exit")
exit :: proc "c" (exit_code: c.int) -> ! {
	finish_atexit()
	os.exit(int(exit_code))
}

@(private, fini)
finish_atexit :: proc "c" () {
	n := intrinsics.atomic_exchange(&atexit_functions_count, 0)
	for function in atexit_functions[:n] {
		function()
	}
}

ldiv_t :: struct {
	quot: c.long,
	rem:  c.long,
}

@(require, linkage="strong", link_name="ldiv")
ldiv :: proc "c" (number: c.long, denom: c.long) -> ldiv_t {
	return {
		quot = number  / denom,
		rem  = number %% denom,
	}
}
