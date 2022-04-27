// This is purely for documentation
//+ignore
package intrinsics

// Package-Related
is_package_imported :: proc(package_name: string) -> bool ---

// Types
simd_vector :: proc($N: int, $T: typeid) -> type/#simd[N]T
soa_struct :: proc($N: int, $T: typeid) -> type/#soa[N]T

// Volatile
volatile_load  :: proc(dst: ^$T) -> T ---
volatile_store :: proc(dst: ^$T, val: T) -> T ---

// Trapping
debug_trap :: proc() ---
trap       :: proc() -> ! ---

// Instructions

alloca             :: proc(size, align: int) -> [^]u8 ---
cpu_relax          :: proc() ---
read_cycle_counter :: proc() -> i64 ---

count_ones           :: proc(x: $T) -> T where type_is_integer(T) ---
count_zeros          :: proc(x: $T) -> T where type_is_integer(T) ---
count_trailing_zeros :: proc(x: $T) -> T where type_is_integer(T) ---
count_leading_zeros  :: proc(x: $T) -> T where type_is_integer(T) ---
reverse_bits         :: proc(x: $T) -> T where type_is_integer(T) ---
byte_swap            :: proc(x: $T) -> T where type_is_integer(T) || type_is_float(T) ---

overflow_add :: proc(lhs, rhs: $T) -> (T, bool) #optional_ok ---
overflow_sub :: proc(lhs, rhs: $T) -> (T, bool) #optional_ok ---
overflow_mul :: proc(lhs, rhs: $T) -> (T, bool) #optional_ok ---

sqrt :: proc(x: $T) -> T where type_is_float(T) ---

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
expect :: proc(val, expected_val: T) -> T ---

// Linux and Darwin Only
syscall :: proc(id: uintptr, args: ..uintptr) -> uintptr ---


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
atomic_add               :: proc(dst; ^$T, val: T) -> T ---
atomic_add_explicit      :: proc(dst; ^$T, val: T, order: Atomic_Memory_Order) -> T ---
atomic_sub               :: proc(dst; ^$T, val: T) -> T ---
atomic_sub_explicit      :: proc(dst; ^$T, val: T, order: Atomic_Memory_Order) -> T ---
atomic_and               :: proc(dst; ^$T, val: T) -> T ---
atomic_and_explicit      :: proc(dst; ^$T, val: T, order: Atomic_Memory_Order) -> T ---
atomic_nand              :: proc(dst; ^$T, val: T) -> T ---
atomic_nand_explicit     :: proc(dst; ^$T, val: T, order: Atomic_Memory_Order) -> T ---
atomic_or                :: proc(dst; ^$T, val: T) -> T ---
atomic_or_explicit       :: proc(dst; ^$T, val: T, order: Atomic_Memory_Order) -> T ---
atomic_xor               :: proc(dst; ^$T, val: T) -> T ---
atomic_xor_explicit      :: proc(dst; ^$T, val: T, order: Atomic_Memory_Order) -> T ---
atomic_exchange          :: proc(dst; ^$T, val: T) -> T ---
atomic_exchange_explicit :: proc(dst; ^$T, val: T, order: Atomic_Memory_Order) -> T ---

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

type_is_specialization_of :: proc($T, $S: typeid) -> bool ---
type_is_variant_of :: proc($U, $V: typeid) -> bool where type_is_union(U) ---

type_has_field :: proc($T: typeid, $name: string) -> bool ---
type_field_type :: proc($T: typeid, $name: string) -> typeid ---

type_proc_parameter_count :: proc($T: typeid) -> int where type_is_proc(T) ---
type_proc_return_count    :: proc($T: typeid) -> int where type_is_proc(T) ---

type_proc_parameter_type  :: proc($T: typeid, index: int) -> typeid where type_is_proc(T) ---
type_proc_return_type     :: proc($T: typeid, index: int) -> typeid where type_is_proc(T) ---

type_struct_field_count :: proc($T: typeid) -> int where type_is_struct(T) ---

type_polymorphic_record_parameter_count :: proc($T: typeid) -> typeid ---
type_polymorphic_record_parameter_value :: proc($T: typeid, index: int) -> $V ---

type_is_specialized_polymorphic_record   :: proc($T: typeid) -> bool ---
type_is_unspecialized_polymorphic_record :: proc($T: typeid) -> bool ---

type_is_subtype_of :: proc($T, $U: typeid) -> bool ---

type_field_index_of :: proc($T: typeid, $name: string) -> uintptr ---

type_equal_proc  :: proc($T: typeid) -> (equal:  proc "contextless" (rawptr, rawptr) -> bool)                 where type_is_comparable(T) ---
type_hasher_proc :: proc($T: typeid) -> (hasher: proc "contextless" (data: rawptr, seed: uintptr) -> uintptr) where type_is_comparable(T) ---

constant_utf16_cstring :: proc($literal: string) -> [^]u16 ---

// WASM targets only
wasm_memory_grow :: proc(index, delta: uintptr) -> int ---
wasm_memory_size :: proc(index: uintptr)        -> int ---


// Darwin targets only
objc_object   :: struct{}
objc_selector :: struct{}
objc_class    :: struct{}
objc_id    :: ^objc_object
objc_SEL   :: ^objc_selector
objc_Class :: ^objc_class

objc_find_selector     :: proc($name: string) -> objc_SEL   ---
objc_register_selector :: proc($name: string) -> objc_SEL   ---
objc_find_class        :: proc($name: string) -> objc_Class ---
objc_register_class    :: proc($name: string) -> objc_Class ---

// Internal compiler use only

__entry_point :: proc() ---