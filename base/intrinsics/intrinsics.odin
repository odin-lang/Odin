// This is purely for documentation
#+build ignore
package intrinsics

import "base:runtime"

// Package-Related
is_package_imported :: proc(package_name: string) -> bool ---

// Matrix Related Procedures
transpose        :: proc(m: $T/matrix[$R, $C]$E)    -> matrix[C, R]E ---
outer_product    :: proc(a: $A/[$X]$E, b: $B/[$Y]E) -> matrix[X, Y]E ---
hadamard_product :: proc(a, b: $T/matrix[$R, $C]$E) -> T ---
matrix_flatten   :: proc(m: $T/matrix[$R, $C]$E)    -> [R*C]E ---

// Types
soa_struct :: proc($N: int, $T: typeid) -> type/#soa[N]T

// Volatile
volatile_load  :: proc(dst: ^$T) -> T ---
volatile_store :: proc(dst: ^$T, val: T) ---

non_temporal_load  :: proc(dst: ^$T) -> T ---
non_temporal_store :: proc(dst: ^$T, val: T)  ---

// Trapping
debug_trap :: proc() ---
trap       :: proc() -> ! ---

// Instructions

alloca             :: proc(size, align: int) -> [^]u8 ---
cpu_relax          :: proc() ---
read_cycle_counter :: proc() -> i64 ---

count_ones           :: proc(x: $T) -> T where type_is_integer(T) || type_is_simd_vector(T) ---
count_zeros          :: proc(x: $T) -> T where type_is_integer(T) || type_is_simd_vector(T) ---
count_trailing_zeros :: proc(x: $T) -> T where type_is_integer(T) || type_is_simd_vector(T) ---
count_leading_zeros  :: proc(x: $T) -> T where type_is_integer(T) || type_is_simd_vector(T) ---
reverse_bits         :: proc(x: $T) -> T where type_is_integer(T) || type_is_simd_vector(T) ---
byte_swap            :: proc(x: $T) -> T where type_is_integer(T) || type_is_float(T) ---

overflow_add :: proc(lhs, rhs: $T) -> (T, bool) where type_is_integer(T) #optional_ok ---
overflow_sub :: proc(lhs, rhs: $T) -> (T, bool) where type_is_integer(T) #optional_ok ---
overflow_mul :: proc(lhs, rhs: $T) -> (T, bool) where type_is_integer(T) #optional_ok ---

saturating_add :: proc(lhs, rhs: $T) -> T where type_is_integer(T) ---
saturating_sub :: proc(lhs, rhs: $T) -> T where type_is_integer(T) ---

sqrt :: proc(x: $T) -> T where type_is_float(T) || (type_is_simd_vector(T) && type_is_float(type_elem_type(T))) ---

fused_mul_add :: proc(a, b, c: $T) -> T where type_is_float(T) || (type_is_simd_vector(T) && type_is_float(type_elem_type(T))) ---

mem_copy                 :: proc(dst, src: rawptr, len: int) ---
mem_copy_non_overlapping :: proc(dst, src: rawptr, len: int) ---
mem_zero                 :: proc(ptr: rawptr, len: int) ---
mem_zero_volatile        :: proc(ptr: rawptr, len: int) ---

// prefer [^]T operations if possible
ptr_offset :: proc(ptr: ^$T, offset: int) -> ^T ---
ptr_sub    :: proc(a, b: ^$T) -> int ---

unaligned_load           :: proc(src: ^$T) -> T ---
unaligned_store          :: proc(dst: ^$T, val: T) -> T ---

fixed_point_mul     :: proc(lhs, rhs: $T, #const scale: uint) -> T where type_is_integer(T) ---
fixed_point_div     :: proc(lhs, rhs: $T, #const scale: uint) -> T where type_is_integer(T) ---
fixed_point_mul_sat :: proc(lhs, rhs: $T, #const scale: uint) -> T where type_is_integer(T) ---
fixed_point_div_sat :: proc(lhs, rhs: $T, #const scale: uint) -> T where type_is_integer(T) ---

prefetch_read_instruction  :: proc(address: rawptr, #const locality: i32 /* 0..=3 */) ---
prefetch_read_data         :: proc(address: rawptr, #const locality: i32 /* 0..=3 */) ---
prefetch_write_instruction :: proc(address: rawptr, #const locality: i32 /* 0..=3 */) ---
prefetch_write_data        :: proc(address: rawptr, #const locality: i32 /* 0..=3 */) ---

// Compiler Hints
expect :: proc(val, expected_val: $T) -> T ---

// Linux and Darwin Only
syscall :: proc(id: uintptr, args: ..uintptr) -> uintptr ---
// FreeBSD, NetBSD, et cetera
syscall_bsd :: proc(id: uintptr, args: ..uintptr) -> (uintptr, bool) ---


// Atomics
Atomic_Memory_Order :: enum {
	Relaxed = 0, // Unordered
	Consume = 1, // Monotonic
	Acquire = 2,
	Release = 3,
	Acq_Rel = 4,
	Seq_Cst = 5,
}

atomic_type_is_lock_free :: proc($T: typeid) -> bool ---

atomic_thread_fence :: proc(order: Atomic_Memory_Order) ---
atomic_signal_fence :: proc(order: Atomic_Memory_Order) ---

atomic_store          :: proc(dst: ^$T, val: T) ---
atomic_store_explicit :: proc(dst: ^$T, val: T, order: Atomic_Memory_Order) ---

atomic_load           :: proc(dst: ^$T) -> T ---
atomic_load_explicit  :: proc(dst: ^$T, order: Atomic_Memory_Order) -> T ---

// fetch then operator
atomic_add               :: proc(dst: ^$T, val: T) -> T ---
atomic_add_explicit      :: proc(dst: ^$T, val: T, order: Atomic_Memory_Order) -> T ---
atomic_sub               :: proc(dst: ^$T, val: T) -> T ---
atomic_sub_explicit      :: proc(dst: ^$T, val: T, order: Atomic_Memory_Order) -> T ---
atomic_and               :: proc(dst: ^$T, val: T) -> T ---
atomic_and_explicit      :: proc(dst: ^$T, val: T, order: Atomic_Memory_Order) -> T ---
atomic_nand              :: proc(dst: ^$T, val: T) -> T ---
atomic_nand_explicit     :: proc(dst: ^$T, val: T, order: Atomic_Memory_Order) -> T ---
atomic_or                :: proc(dst: ^$T, val: T) -> T ---
atomic_or_explicit       :: proc(dst: ^$T, val: T, order: Atomic_Memory_Order) -> T ---
atomic_xor               :: proc(dst: ^$T, val: T) -> T ---
atomic_xor_explicit      :: proc(dst: ^$T, val: T, order: Atomic_Memory_Order) -> T ---
atomic_exchange          :: proc(dst: ^$T, val: T) -> T ---
atomic_exchange_explicit :: proc(dst: ^$T, val: T, order: Atomic_Memory_Order) -> T ---

atomic_compare_exchange_strong          :: proc(dst: ^$T, old, new: T) -> (T, bool) #optional_ok ---
atomic_compare_exchange_strong_explicit :: proc(dst: ^$T, old, new: T, success, failure: Atomic_Memory_Order) -> (T, bool) #optional_ok ---
atomic_compare_exchange_weak            :: proc(dst: ^$T, old, new: T) -> (T, bool) #optional_ok ---
atomic_compare_exchange_weak_explicit   :: proc(dst: ^$T, old, new: T, success, failure: Atomic_Memory_Order) -> (T, bool) #optional_ok ---


// Constant type tests

type_base_type :: proc($T: typeid) -> type ---
type_core_type :: proc($T: typeid) -> type ---
type_elem_type :: proc($T: typeid) -> type ---

type_is_boolean    :: proc($T: typeid) -> bool ---
type_is_integer    :: proc($T: typeid) -> bool ---
type_is_rune       :: proc($T: typeid) -> bool ---
type_is_float      :: proc($T: typeid) -> bool ---
type_is_complex    :: proc($T: typeid) -> bool ---
type_is_quaternion :: proc($T: typeid) -> bool ---
type_is_string     :: proc($T: typeid) -> bool ---
type_is_typeid     :: proc($T: typeid) -> bool ---
type_is_any        :: proc($T: typeid) -> bool ---

type_is_endian_platform       :: proc($T: typeid) -> bool ---
type_is_endian_little         :: proc($T: typeid) -> bool ---
type_is_endian_big            :: proc($T: typeid) -> bool ---
type_is_unsigned              :: proc($T: typeid) -> bool ---
type_is_numeric               :: proc($T: typeid) -> bool ---
type_is_ordered               :: proc($T: typeid) -> bool ---
type_is_ordered_numeric       :: proc($T: typeid) -> bool ---
type_is_indexable             :: proc($T: typeid) -> bool ---
type_is_sliceable             :: proc($T: typeid) -> bool ---
type_is_comparable            :: proc($T: typeid) -> bool ---
type_is_simple_compare        :: proc($T: typeid) -> bool --- // easily compared using memcmp (== and !=)
type_is_dereferenceable       :: proc($T: typeid) -> bool ---
type_is_valid_map_key         :: proc($T: typeid) -> bool ---
type_is_valid_matrix_elements :: proc($T: typeid) -> bool ---

type_is_named            :: proc($T: typeid) -> bool ---
type_is_pointer          :: proc($T: typeid) -> bool ---
type_is_multi_pointer    :: proc($T: typeid) -> bool ---
type_is_array            :: proc($T: typeid) -> bool ---
type_is_enumerated_array :: proc($T: typeid) -> bool ---
type_is_slice            :: proc($T: typeid) -> bool ---
type_is_dynamic_array    :: proc($T: typeid) -> bool ---
type_is_map              :: proc($T: typeid) -> bool ---
type_is_struct           :: proc($T: typeid) -> bool ---
type_is_union            :: proc($T: typeid) -> bool ---
type_is_enum             :: proc($T: typeid) -> bool ---
type_is_proc             :: proc($T: typeid) -> bool ---
type_is_bit_set          :: proc($T: typeid) -> bool ---
type_is_simd_vector      :: proc($T: typeid) -> bool ---
type_is_matrix           :: proc($T: typeid) -> bool ---

type_has_nil :: proc($T: typeid) -> bool ---

type_is_matrix_row_major    :: proc($T: typeid) -> bool where type_is_matrix(T) ---
type_is_matrix_column_major :: proc($T: typeid) -> bool where type_is_matrix(T) ---

type_is_specialization_of :: proc($T, $S: typeid) -> bool ---

type_is_variant_of        :: proc($U, $V: typeid)          -> bool    where type_is_union(U) ---
type_union_tag_type       :: proc($T: typeid)              -> typeid  where type_is_union(T) ---
type_union_tag_offset     :: proc($T: typeid)              -> uintptr where type_is_union(T) ---
type_union_base_tag_value :: proc($T: typeid)              -> int     where type_is_union(U) ---
type_union_variant_count  :: proc($T: typeid)              -> int     where type_is_union(T) ---
type_variant_type_of      :: proc($T: typeid, $index: int) -> typeid  where type_is_union(T) ---
type_variant_index_of     :: proc($U, $V: typeid)          -> int     where type_is_union(U) ---

type_bit_set_elem_type       :: proc($T: typeid) -> typeid where type_is_bit_set(T) ---
type_bit_set_underlying_type :: proc($T: typeid) -> typeid where type_is_bit_set(T) ---

type_has_field  :: proc($T: typeid, $name: string) -> bool ---
type_field_type :: proc($T: typeid, $name: string) -> typeid ---

type_proc_parameter_count :: proc($T: typeid) -> int where type_is_proc(T) ---
type_proc_return_count    :: proc($T: typeid) -> int where type_is_proc(T) ---

type_proc_parameter_type  :: proc($T: typeid, index: int) -> typeid where type_is_proc(T) ---
type_proc_return_type     :: proc($T: typeid, index: int) -> typeid where type_is_proc(T) ---

type_struct_field_count          :: proc($T: typeid) -> int  where type_is_struct(T) ---
type_struct_has_implicit_padding :: proc($T: typeid) -> bool where type_is_struct(T) ---

type_polymorphic_record_parameter_count :: proc($T: typeid) -> typeid ---
type_polymorphic_record_parameter_value :: proc($T: typeid, index: int) -> $V ---

type_is_specialized_polymorphic_record   :: proc($T: typeid) -> bool ---
type_is_unspecialized_polymorphic_record :: proc($T: typeid) -> bool ---

type_is_subtype_of :: proc($T, $U: typeid) -> bool ---

type_field_index_of :: proc($T: typeid, $name: string) -> uintptr ---

type_equal_proc  :: proc($T: typeid) -> (equal:  proc "contextless" (rawptr, rawptr) -> bool)                 where type_is_comparable(T) ---
type_hasher_proc :: proc($T: typeid) -> (hasher: proc "contextless" (data: rawptr, seed: uintptr) -> uintptr) where type_is_comparable(T) ---

type_map_info      :: proc($T: typeid/map[$K]$V) -> ^runtime.Map_Info ---
type_map_cell_info :: proc($T: typeid)           -> ^runtime.Map_Cell_Info ---

type_convert_variants_to_pointers :: proc($T: typeid) -> typeid where type_is_union(T) ---
type_merge :: proc($U, $V: typeid) -> typeid where type_is_union(U), type_is_union(V) ---

type_has_shared_fields :: proc($U, $V: typeid) -> bool where type_is_struct(U), type_is_struct(V) ---

constant_utf16_cstring :: proc($literal: string) -> [^]u16 ---

constant_log2 :: proc($v: $T) -> T where type_is_integer(T) ---

// SIMD related
simd_add  :: proc(a, b: #simd[N]T) -> #simd[N]T ---
simd_sub  :: proc(a, b: #simd[N]T) -> #simd[N]T ---
simd_mul  :: proc(a, b: #simd[N]T) -> #simd[N]T ---
simd_div  :: proc(a, b: #simd[N]T) -> #simd[N]T where type_is_float(T) ---

simd_saturating_add  :: proc(a, b: #simd[N]T) -> #simd[N]T where type_is_integer(T) ---
simd_saturating_sub  :: proc(a, b: #simd[N]T) -> #simd[N]T where type_is_integer(T) ---

// Keeps Odin's Behaviour
// (x << y) if y <= mask else 0
simd_shl :: proc(a: #simd[N]T, b: #simd[N]Unsigned_Integer) -> #simd[N]T ---
simd_shr :: proc(a: #simd[N]T, b: #simd[N]Unsigned_Integer) -> #simd[N]T ---

// Similar to C's Behaviour
// x << (y & mask)
simd_shl_masked :: proc(a: #simd[N]T, b: #simd[N]Unsigned_Integer) -> #simd[N]T ---
simd_shr_masked :: proc(a: #simd[N]T, b: #simd[N]Unsigned_Integer) -> #simd[N]T ---

simd_bit_and     :: proc(a, b: #simd[N]T) -> #simd[N]T ---
simd_bit_or      :: proc(a, b: #simd[N]T) -> #simd[N]T ---
simd_bit_xor     :: proc(a, b: #simd[N]T) -> #simd[N]T ---
simd_bit_and_not :: proc(a, b: #simd[N]T) -> #simd[N]T ---

simd_neg  :: proc(a: #simd[N]T) -> #simd[N]T ---

simd_abs :: proc(a: #simd[N]T) -> #simd[N]T ---

simd_min   :: proc(a, b: #simd[N]T) -> #simd[N]T ---
simd_max   :: proc(a, b: #simd[N]T) -> #simd[N]T ---
simd_clamp :: proc(v, min, max: #simd[N]T) -> #simd[N]T ---

// Return an unsigned integer of the same size as the input type
// NOT A BOOLEAN
// element-wise:
//     false => 0x00...00
//     true  => 0xff...ff
simd_lanes_eq :: proc(a, b: #simd[N]T) -> #simd[N]Integer ---
simd_lanes_ne :: proc(a, b: #simd[N]T) -> #simd[N]Integer ---
simd_lanes_lt :: proc(a, b: #simd[N]T) -> #simd[N]Integer ---
simd_lanes_le :: proc(a, b: #simd[N]T) -> #simd[N]Integer ---
simd_lanes_gt :: proc(a, b: #simd[N]T) -> #simd[N]Integer ---
simd_lanes_ge :: proc(a, b: #simd[N]T) -> #simd[N]Integer ---

simd_extract :: proc(a: #simd[N]T, idx: uint) -> T ---
simd_replace :: proc(a: #simd[N]T, idx: uint, elem: T) -> #simd[N]T ---

simd_reduce_add_ordered :: proc(a: #simd[N]T) -> T where type_is_integer(T) || type_is_float(T)---
simd_reduce_mul_ordered :: proc(a: #simd[N]T) -> T where type_is_integer(T) || type_is_float(T)---
simd_reduce_min         :: proc(a: #simd[N]T) -> T where type_is_integer(T) || type_is_float(T)---
simd_reduce_max         :: proc(a: #simd[N]T) -> T where type_is_integer(T) || type_is_float(T)---
simd_reduce_and         :: proc(a: #simd[N]T) -> T where type_is_integer(T) || type_is_float(T)---
simd_reduce_or          :: proc(a: #simd[N]T) -> T where type_is_integer(T) || type_is_float(T)---
simd_reduce_xor         :: proc(a: #simd[N]T) -> T where type_is_integer(T) || type_is_float(T)---

simd_reduce_any         :: proc(a: #simd[N]T) -> T where type_is_boolean(T) ---
simd_reduce_all         :: proc(a: #simd[N]T) -> T where type_is_boolean(T) ---

simd_extract_lsbs       :: proc(a: #simd[N]T) -> bit_set[0..<N] where type_is_integer(T) || type_is_boolean(T) ---
simd_extract_msbs       :: proc(a: #simd[N]T) -> bit_set[0..<N] where type_is_integer(T) || type_is_boolean(T) ---


simd_gather       :: proc(ptr: #simd[N]rawptr, val: #simd[N]T, mask: #simd[N]U) -> #simd[N]T where type_is_integer(U) || type_is_boolean(U) ---
simd_scatter      :: proc(ptr: #simd[N]rawptr, val: #simd[N]T, mask: #simd[N]U)              where type_is_integer(U) || type_is_boolean(U) ---

simd_masked_load  :: proc(ptr: rawptr, val: #simd[N]T, mask: #simd[N]U) -> #simd[N]T where type_is_integer(U) || type_is_boolean(U) ---
simd_masked_store :: proc(ptr: rawptr, val: #simd[N]T, mask: #simd[N]U)              where type_is_integer(U) || type_is_boolean(U) ---

simd_masked_expand_load    :: proc(ptr: rawptr, val: #simd[N]T, mask: #simd[N]U) -> #simd[N]T where type_is_integer(U) || type_is_boolean(U) ---
simd_masked_compress_store :: proc(ptr: rawptr, val: #simd[N]T, mask: #simd[N]U)              where type_is_integer(U) || type_is_boolean(U) ---



simd_shuffle :: proc(a, b: #simd[N]T, indices: ..int) -> #simd[len(indices)]T ---
simd_select  :: proc(cond: #simd[N]boolean_or_integer, true, false: #simd[N]T) -> #simd[N]T ---

// Lane-wise operations
simd_ceil    :: proc(a: #simd[N]any_float) -> #simd[N]any_float ---
simd_floor   :: proc(a: #simd[N]any_float) -> #simd[N]any_float ---
simd_trunc   :: proc(a: #simd[N]any_float) -> #simd[N]any_float ---
// rounding to the nearest integral value; if two values are equally near, rounds to the even one
simd_nearest :: proc(a: #simd[N]any_float) -> #simd[N]any_float ---

simd_to_bits :: proc(v: #simd[N]T) -> #simd[N]Integer where size_of(T) == size_of(Integer), type_is_unsigned(Integer) ---

// equivalent to a swizzle with descending indices, e.g. reserve(a, 3, 2, 1, 0)
simd_lanes_reverse :: proc(a: #simd[N]T) -> #simd[N]T ---

simd_lanes_rotate_left  :: proc(a: #simd[N]T, $offset: int) -> #simd[N]T ---
simd_lanes_rotate_right :: proc(a: #simd[N]T, $offset: int) -> #simd[N]T ---

// Checks if the current target supports the given target features.
//
// Takes a constant comma-seperated string (eg: "sha512,sse4.1"), or a procedure type which has either
// `@(require_target_feature)` or `@(enable_target_feature)` as its input and returns a boolean indicating
// if all listed features are supported.
has_target_feature :: proc($test: $T) -> bool where type_is_string(T) || type_is_proc(T) ---


// Returns the value of the procedure where `x` must be a call expression
procedure_of :: proc(x: $T) -> T where type_is_proc(T) ---

// WASM targets only
wasm_memory_grow :: proc(index, delta: uintptr) -> int ---
wasm_memory_size :: proc(index: uintptr)        -> int ---

// `timeout_ns` is maximum number of nanoseconds the calling thread will be blocked for
// A negative value will be blocked forever
// Return value:
// 0 - indicates that the thread blocked and then was woken up
// 1 - the loaded value from `ptr` did not match `expected`, the thread did not block
// 2 - the thread blocked, but the timeout
@(require_target_feature="atomics")
wasm_memory_atomic_wait32   :: proc(ptr: ^u32, expected: u32, timeout_ns: i64) -> u32 ---
@(require_target_feature="atomics")
wasm_memory_atomic_notify32 :: proc(ptr: ^u32, waiters: u32) -> (waiters_woken_up: u32) ---

// x86 Targets (i386, amd64)
x86_cpuid  :: proc(ax, cx: u32) -> (eax, ebx, ecx, edx: u32) ---
x86_xgetbv :: proc(cx: u32) -> (eax, edx: u32) ---


// Darwin targets only
objc_object   :: struct{}
objc_selector :: struct{}
objc_class    :: struct{}
objc_ivar     :: struct{}

objc_id    :: ^objc_object
objc_SEL   :: ^objc_selector
objc_Class :: ^objc_class
objc_Ivar  :: ^objc_ivar

objc_find_selector     :: proc($name: string) -> objc_SEL   ---
objc_register_selector :: proc($name: string) -> objc_SEL   ---
objc_find_class        :: proc($name: string) -> objc_Class ---
objc_register_class    :: proc($name: string) -> objc_Class ---
ivar_get			   :: proc(self: ^$T, $U: typeid) -> ^U ---

valgrind_client_request :: proc(default: uintptr, request: uintptr, a0, a1, a2, a3, a4: uintptr) -> uintptr ---

// Internal compiler use only

__entry_point :: proc() ---
