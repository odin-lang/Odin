// This is purely for documentation
package intrinsics


x86_mmx :: x86_mmx; // Specialized SIMD Vector type

simd_vector :: proc($N: int, $T: typeid) -> type/#simd[N]T

atomic_fence        :: proc() ---
atomic_fence_acq    :: proc() ---
atomic_fence_rel    :: proc() ---
atomic_fence_acqrel :: proc() ---

atomic_store           :: proc(dst: ^$T, val: $T) ---
atomic_store_rel       :: proc(dst: ^$T, val: $T) ---
atomic_store_relaxed   :: proc(dst: ^$T, val: $T) ---
atomic_store_unordered :: proc(dst: ^$T, val: $T) ---

atomic_load           :: proc(dst: ^$T) -> T ---
atomic_load_acq       :: proc(dst: ^$T) -> T ---
atomic_load_relaxed   :: proc(dst: ^$T) -> T ---
atomic_load_unordered :: proc(dst: ^$T) -> T ---

atomic_add          :: proc(dst; ^$T, val: $T) -> T ---
atomic_add_acq      :: proc(dst; ^$T, val: $T) -> T ---
atomic_add_rel      :: proc(dst; ^$T, val: $T) -> T ---
atomic_add_acqrel   :: proc(dst; ^$T, val: $T) -> T ---
atomic_add_relaxed  :: proc(dst; ^$T, val: $T) -> T ---
atomic_sub          :: proc(dst; ^$T, val: $T) -> T ---
atomic_sub_acq      :: proc(dst; ^$T, val: $T) -> T ---
atomic_sub_rel      :: proc(dst; ^$T, val: $T) -> T ---
atomic_sub_acqrel   :: proc(dst; ^$T, val: $T) -> T ---
atomic_sub_relaxed  :: proc(dst; ^$T, val: $T) -> T ---
atomic_and          :: proc(dst; ^$T, val: $T) -> T ---
atomic_and_acq      :: proc(dst; ^$T, val: $T) -> T ---
atomic_and_rel      :: proc(dst; ^$T, val: $T) -> T ---
atomic_and_acqrel   :: proc(dst; ^$T, val: $T) -> T ---
atomic_and_relaxed  :: proc(dst; ^$T, val: $T) -> T ---
atomic_nand         :: proc(dst; ^$T, val: $T) -> T ---
atomic_nand_acq     :: proc(dst; ^$T, val: $T) -> T ---
atomic_nand_rel     :: proc(dst; ^$T, val: $T) -> T ---
atomic_nand_acqrel  :: proc(dst; ^$T, val: $T) -> T ---
atomic_nand_relaxed :: proc(dst; ^$T, val: $T) -> T ---
atomic_or           :: proc(dst; ^$T, val: $T) -> T ---
atomic_or_acq       :: proc(dst; ^$T, val: $T) -> T ---
atomic_or_rel       :: proc(dst; ^$T, val: $T) -> T ---
atomic_or_acqrel    :: proc(dst; ^$T, val: $T) -> T ---
atomic_or_relaxed   :: proc(dst; ^$T, val: $T) -> T ---
atomic_xor          :: proc(dst; ^$T, val: $T) -> T ---
atomic_xor_acq      :: proc(dst; ^$T, val: $T) -> T ---
atomic_xor_rel      :: proc(dst; ^$T, val: $T) -> T ---
atomic_xor_acqrel   :: proc(dst; ^$T, val: $T) -> T ---
atomic_xor_relaxed  :: proc(dst; ^$T, val: $T) -> T ---

atomic_xchg         :: proc(dst; ^$T, val: $T) -> T ---
atomic_xchg_acq     :: proc(dst; ^$T, val: $T) -> T ---
atomic_xchg_rel     :: proc(dst; ^$T, val: $T) -> T ---
atomic_xchg_acqrel  :: proc(dst; ^$T, val: $T) -> T ---
atomic_xchg_relaxed :: proc(dst; ^$T, val: $T) -> T ---

atomic_cxchg                    :: proc(dst: ^$T, old, new: T) -> (T, /*option*/bool) ---
atomic_cxchg_acq                :: proc(dst: ^$T, old, new: T) -> (T, /*option*/bool) ---
atomic_cxchg_rel                :: proc(dst: ^$T, old, new: T) -> (T, /*option*/bool) ---
atomic_cxchg_acqrel             :: proc(dst: ^$T, old, new: T) -> (T, /*option*/bool) ---
atomic_cxchg_relaxed            :: proc(dst: ^$T, old, new: T) -> (T, /*option*/bool) ---
atomic_cxchg_failrelaxed        :: proc(dst: ^$T, old, new: T) -> (T, /*option*/bool) ---
atomic_cxchg_failacq            :: proc(dst: ^$T, old, new: T) -> (T, /*option*/bool) ---
atomic_cxchg_acq_failrelaxed    :: proc(dst: ^$T, old, new: T) -> (T, /*option*/bool) ---
atomic_cxchg_acqrel_failrelaxed :: proc(dst: ^$T, old, new: T) -> (T, /*option*/bool) ---

atomic_cxchgweak                    :: proc(dst: ^$T, old, new: T) -> (T, /*option*/bool) ---
atomic_cxchgweak_acq                :: proc(dst: ^$T, old, new: T) -> (T, /*option*/bool) ---
atomic_cxchgweak_rel                :: proc(dst: ^$T, old, new: T) -> (T, /*option*/bool) ---
atomic_cxchgweak_acqrel             :: proc(dst: ^$T, old, new: T) -> (T, /*option*/bool) ---
atomic_cxchgweak_relaxed            :: proc(dst: ^$T, old, new: T) -> (T, /*option*/bool) ---
atomic_cxchgweak_failrelaxed        :: proc(dst: ^$T, old, new: T) -> (T, /*option*/bool) ---
atomic_cxchgweak_failacq            :: proc(dst: ^$T, old, new: T) -> (T, /*option*/bool) ---
atomic_cxchgweak_acq_failrelaxed    :: proc(dst: ^$T, old, new: T) -> (T, /*option*/bool) ---
atomic_cxchgweak_acqrel_failrelaxed :: proc(dst: ^$T, old, new: T) -> (T, /*option*/bool) ---


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

type_is_endian_little   :: proc($T: typeid) -> bool ---
type_is_endian_big      :: proc($T: typeid) -> bool ---
type_is_unsigned        :: proc($T: typeid) -> bool ---
type_is_numeric         :: proc($T: typeid) -> bool ---
type_is_ordered         :: proc($T: typeid) -> bool ---
type_is_ordered_numeric :: proc($T: typeid) -> bool ---
type_is_indexable       :: proc($T: typeid) -> bool ---
type_is_sliceable       :: proc($T: typeid) -> bool ---
type_is_simple_compare  :: proc($T: typeid) -> bool --- // easily compared using memcmp
type_is_dereferenceable :: proc($T: typeid) -> bool ---
type_is_valid_map_key   :: proc($T: typeid) -> bool ---

type_is_named           :: proc($T: typeid) -> bool ---
type_is_pointer         :: proc($T: typeid) -> bool ---
type_is_opaque          :: proc($T: typeid) -> bool ---
type_is_array           :: proc($T: typeid) -> bool ---
type_is_slice           :: proc($T: typeid) -> bool ---
type_is_dynamic_array   :: proc($T: typeid) -> bool ---
type_is_map             :: proc($T: typeid) -> bool ---
type_is_struct          :: proc($T: typeid) -> bool ---
type_is_union           :: proc($T: typeid) -> bool ---
type_is_enum            :: proc($T: typeid) -> bool ---
type_is_proc            :: proc($T: typeid) -> bool ---
type_is_bit_field       :: proc($T: typeid) -> bool ---
type_is_bit_field_value :: proc($T: typeid) -> bool ---
type_is_bit_set         :: proc($T: typeid) -> bool ---
type_is_simd_vector     :: proc($T: typeid) -> bool ---

type_has_nil            :: proc($T: typeid) -> bool ---

type_proc_parameter_count :: proc($T: typeid) -> int where type_is_proc(T) ---
type_proc_return_count    :: proc($T: typeid) -> int where type_is_proc(T) ---
