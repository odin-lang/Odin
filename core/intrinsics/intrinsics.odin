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
atomic_fence        :: proc() ---
atomic_fence_acq    :: proc() ---
atomic_fence_rel    :: proc() ---
atomic_fence_acqrel :: proc() ---

atomic_store           :: proc(dst: ^$T, val: T) ---
atomic_store_rel       :: proc(dst: ^$T, val: T) ---
atomic_store_relaxed   :: proc(dst: ^$T, val: T) ---
atomic_store_unordered :: proc(dst: ^$T, val: T) ---

atomic_load           :: proc(dst: ^$T) -> T ---
atomic_load_acq       :: proc(dst: ^$T) -> T ---
atomic_load_relaxed   :: proc(dst: ^$T) -> T ---
atomic_load_unordered :: proc(dst: ^$T) -> T ---

atomic_add          :: proc(dst; ^$T, val: T) -> T ---
atomic_add_acq      :: proc(dst; ^$T, val: T) -> T ---
atomic_add_rel      :: proc(dst; ^$T, val: T) -> T ---
atomic_add_acqrel   :: proc(dst; ^$T, val: T) -> T ---
atomic_add_relaxed  :: proc(dst; ^$T, val: T) -> T ---
atomic_sub          :: proc(dst; ^$T, val: T) -> T ---
atomic_sub_acq      :: proc(dst; ^$T, val: T) -> T ---
atomic_sub_rel      :: proc(dst; ^$T, val: T) -> T ---
atomic_sub_acqrel   :: proc(dst; ^$T, val: T) -> T ---
atomic_sub_relaxed  :: proc(dst; ^$T, val: T) -> T ---
atomic_and          :: proc(dst; ^$T, val: T) -> T ---
atomic_and_acq      :: proc(dst; ^$T, val: T) -> T ---
atomic_and_rel      :: proc(dst; ^$T, val: T) -> T ---
atomic_and_acqrel   :: proc(dst; ^$T, val: T) -> T ---
atomic_and_relaxed  :: proc(dst; ^$T, val: T) -> T ---
atomic_nand         :: proc(dst; ^$T, val: T) -> T ---
atomic_nand_acq     :: proc(dst; ^$T, val: T) -> T ---
atomic_nand_rel     :: proc(dst; ^$T, val: T) -> T ---
atomic_nand_acqrel  :: proc(dst; ^$T, val: T) -> T ---
atomic_nand_relaxed :: proc(dst; ^$T, val: T) -> T ---
atomic_or           :: proc(dst; ^$T, val: T) -> T ---
atomic_or_acq       :: proc(dst; ^$T, val: T) -> T ---
atomic_or_rel       :: proc(dst; ^$T, val: T) -> T ---
atomic_or_acqrel    :: proc(dst; ^$T, val: T) -> T ---
atomic_or_relaxed   :: proc(dst; ^$T, val: T) -> T ---
atomic_xor          :: proc(dst; ^$T, val: T) -> T ---
atomic_xor_acq      :: proc(dst; ^$T, val: T) -> T ---
atomic_xor_rel      :: proc(dst; ^$T, val: T) -> T ---
atomic_xor_acqrel   :: proc(dst; ^$T, val: T) -> T ---
atomic_xor_relaxed  :: proc(dst; ^$T, val: T) -> T ---

atomic_xchg         :: proc(dst; ^$T, val: T) -> T ---
atomic_xchg_acq     :: proc(dst; ^$T, val: T) -> T ---
atomic_xchg_rel     :: proc(dst; ^$T, val: T) -> T ---
atomic_xchg_acqrel  :: proc(dst; ^$T, val: T) -> T ---
atomic_xchg_relaxed :: proc(dst; ^$T, val: T) -> T ---

atomic_cxchg                    :: proc(dst: ^$T, old, new: T) -> (T, bool) #optional_ok ---
atomic_cxchg_acq                :: proc(dst: ^$T, old, new: T) -> (T, bool) #optional_ok ---
atomic_cxchg_rel                :: proc(dst: ^$T, old, new: T) -> (T, bool) #optional_ok ---
atomic_cxchg_acqrel             :: proc(dst: ^$T, old, new: T) -> (T, bool) #optional_ok ---
atomic_cxchg_relaxed            :: proc(dst: ^$T, old, new: T) -> (T, bool) #optional_ok ---
atomic_cxchg_failrelaxed        :: proc(dst: ^$T, old, new: T) -> (T, bool) #optional_ok ---
atomic_cxchg_failacq            :: proc(dst: ^$T, old, new: T) -> (T, bool) #optional_ok ---
atomic_cxchg_acq_failrelaxed    :: proc(dst: ^$T, old, new: T) -> (T, bool) #optional_ok ---
atomic_cxchg_acqrel_failrelaxed :: proc(dst: ^$T, old, new: T) -> (T, bool) #optional_ok ---

atomic_cxchgweak                    :: proc(dst: ^$T, old, new: T) -> (T, bool) #optional_ok ---
atomic_cxchgweak_acq                :: proc(dst: ^$T, old, new: T) -> (T, bool) #optional_ok ---
atomic_cxchgweak_rel                :: proc(dst: ^$T, old, new: T) -> (T, bool) #optional_ok ---
atomic_cxchgweak_acqrel             :: proc(dst: ^$T, old, new: T) -> (T, bool) #optional_ok ---
atomic_cxchgweak_relaxed            :: proc(dst: ^$T, old, new: T) -> (T, bool) #optional_ok ---
atomic_cxchgweak_failrelaxed        :: proc(dst: ^$T, old, new: T) -> (T, bool) #optional_ok ---
atomic_cxchgweak_failacq            :: proc(dst: ^$T, old, new: T) -> (T, bool) #optional_ok ---
atomic_cxchgweak_acq_failrelaxed    :: proc(dst: ^$T, old, new: T) -> (T, bool) #optional_ok ---
atomic_cxchgweak_acqrel_failrelaxed :: proc(dst: ^$T, old, new: T) -> (T, bool) #optional_ok ---

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

type_is_endian_platform :: proc($T: typeid) -> bool ---
type_is_endian_little   :: proc($T: typeid) -> bool ---
type_is_endian_big      :: proc($T: typeid) -> bool ---
type_is_unsigned        :: proc($T: typeid) -> bool ---
type_is_numeric         :: proc($T: typeid) -> bool ---
type_is_ordered         :: proc($T: typeid) -> bool ---
type_is_ordered_numeric :: proc($T: typeid) -> bool ---
type_is_indexable       :: proc($T: typeid) -> bool ---
type_is_sliceable       :: proc($T: typeid) -> bool ---
type_is_comparable      :: proc($T: typeid) -> bool ---
type_is_simple_compare  :: proc($T: typeid) -> bool --- // easily compared using memcmp (== and !=)
type_is_dereferenceable :: proc($T: typeid) -> bool ---
type_is_valid_map_key   :: proc($T: typeid) -> bool ---

type_is_named            :: proc($T: typeid) -> bool ---
type_is_pointer          :: proc($T: typeid) -> bool ---
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

type_has_nil :: proc($T: typeid) -> bool ---

type_is_specialization_of :: proc($T, $S: typeid) -> bool ---
type_is_variant_of :: proc($U, $V: typeid) -> bool where type_is_union(U) ---

type_has_field :: proc($T: typeid, $name: string) -> bool ---

type_proc_parameter_count :: proc($T: typeid) -> int where type_is_proc(T) ---
type_proc_return_count    :: proc($T: typeid) -> int where type_is_proc(T) ---

type_proc_parameter_type  :: proc($T: typeid, index: int) -> typeid where type_is_proc(T) ---
type_proc_return_type     :: proc($T: typeid, index: int) -> typeid where type_is_proc(T) ---

type_polymorphic_record_parameter_count :: proc($T: typeid) -> typeid ---
type_polymorphic_record_parameter_value :: proc($T: typeid, index: int) -> $V ---


type_field_index_of :: proc($T: typeid, $name: string) -> uintptr ---

type_equal_proc  :: proc($T: typeid) -> (equal:  proc "contextless" (rawptr, rawptr) -> bool)                 where type_is_comparable(T) ---
type_hasher_proc :: proc($T: typeid) -> (hasher: proc "contextless" (data: rawptr, seed: uintptr) -> uintptr) where type_is_comparable(T) ---


// Internal compiler use only

__entry_point :: proc() ---