//+build wasm32, wasm64p32
package stb_truetype

import "base:builtin"
import "base:intrinsics"
import "base:runtime"

import "core:c"
import "core:math"
import "core:slice"
import "core:sort"

@(require, linkage="strong", link_name="stbtt_malloc")
malloc :: proc "c" (size: uint) -> rawptr {
	context = runtime.default_context()
	ptr, _ := runtime.mem_alloc_non_zeroed(int(size))
	return raw_data(ptr)
}

@(require, linkage="strong", link_name="stbtt_free")
free :: proc "c" (ptr: rawptr) {
	context = runtime.default_context()
	builtin.free(ptr)
}

@(require, linkage="strong", link_name="stbtt_qsort")
qsort :: proc "c" (base: rawptr, num: uint, size: uint, cmp: proc "c" (a, b: rawptr) -> i32) {
	context = runtime.default_context()

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

@(require, linkage="strong", link_name="stbtt_floor")
floor :: proc "c" (x: f64) -> f64 { return math.floor(x) }
@(require, linkage="strong", link_name="stbtt_ceil")
ceil :: proc "c" (x: f64) -> f64 { return math.ceil(x) }
@(require, linkage="strong", link_name="stbtt_sqrt")
sqrt :: proc "c" (x: f64) -> f64 { return math.sqrt(x) }
@(require, linkage="strong", link_name="stbtt_pow")
pow :: proc "c" (x, y: f64) -> f64 { return math.pow(x, y) }
@(require, linkage="strong", link_name="stbtt_fmod")
fmod :: proc "c" (x, y: f64) -> f64 { return math.mod(x, y) }
@(require, linkage="strong", link_name="stbtt_cos")
cos :: proc "c" (x: f64) -> f64 { return math.cos(x) }
@(require, linkage="strong", link_name="stbtt_acos")
acos :: proc "c" (x: f64) -> f64 { return math.acos(x) }
@(require, linkage="strong", link_name="stbtt_fabs")
fabs :: proc "c" (x: f64) -> f64 { return math.abs(x) }

@(require, linkage="strong", link_name="stbtt_strlen")
strlen :: proc "c" (str: cstring) -> c.ulong { return c.ulong(len(str)) }

// NOTE: defined in runtime.
// void *memcpy(void *dst, const void *src, size_t count);
// void *memset(void *dst, int x, size_t count);
