package sync2

import "core:intrinsics"

cpu_relax :: intrinsics.cpu_relax

atomic_fence         :: intrinsics.atomic_fence
atomic_fence_acquire :: intrinsics.atomic_fence_acq
atomic_fence_release :: intrinsics.atomic_fence_rel
atomic_fence_acqrel  :: intrinsics.atomic_fence_acqrel

atomic_store           :: intrinsics.atomic_store
atomic_store_release   :: intrinsics.atomic_store_rel
atomic_store_relaxed   :: intrinsics.atomic_store_relaxed
atomic_store_unordered :: intrinsics.atomic_store_unordered

atomic_load           :: intrinsics.atomic_load
atomic_load_acquire   :: intrinsics.atomic_load_acq
atomic_load_relaxed   :: intrinsics.atomic_load_relaxed
atomic_load_unordered :: intrinsics.atomic_load_unordered

atomic_add          :: intrinsics.atomic_add
atomic_add_acquire  :: intrinsics.atomic_add_acq
atomic_add_release  :: intrinsics.atomic_add_rel
atomic_add_acqrel   :: intrinsics.atomic_add_acqrel
atomic_add_relaxed  :: intrinsics.atomic_add_relaxed
atomic_sub          :: intrinsics.atomic_sub
atomic_sub_acquire  :: intrinsics.atomic_sub_acq
atomic_sub_release  :: intrinsics.atomic_sub_rel
atomic_sub_acqrel   :: intrinsics.atomic_sub_acqrel
atomic_sub_relaxed  :: intrinsics.atomic_sub_relaxed
atomic_and          :: intrinsics.atomic_and
atomic_and_acquire  :: intrinsics.atomic_and_acq
atomic_and_release  :: intrinsics.atomic_and_rel
atomic_and_acqrel   :: intrinsics.atomic_and_acqrel
atomic_and_relaxed  :: intrinsics.atomic_and_relaxed
atomic_nand         :: intrinsics.atomic_nand
atomic_nand_acquire :: intrinsics.atomic_nand_acq
atomic_nand_release :: intrinsics.atomic_nand_rel
atomic_nand_acqrel  :: intrinsics.atomic_nand_acqrel
atomic_nand_relaxed :: intrinsics.atomic_nand_relaxed
atomic_or           :: intrinsics.atomic_or
atomic_or_acquire   :: intrinsics.atomic_or_acq
atomic_or_release   :: intrinsics.atomic_or_rel
atomic_or_acqrel    :: intrinsics.atomic_or_acqrel
atomic_or_relaxed   :: intrinsics.atomic_or_relaxed
atomic_xor          :: intrinsics.atomic_xor
atomic_xor_acquire  :: intrinsics.atomic_xor_acq
atomic_xor_release  :: intrinsics.atomic_xor_rel
atomic_xor_acqrel   :: intrinsics.atomic_xor_acqrel
atomic_xor_relaxed  :: intrinsics.atomic_xor_relaxed

atomic_exchange         :: intrinsics.atomic_xchg
atomic_exchange_acquire :: intrinsics.atomic_xchg_acq
atomic_exchange_release :: intrinsics.atomic_xchg_rel
atomic_exchange_acqrel  :: intrinsics.atomic_xchg_acqrel
atomic_exchange_relaxed :: intrinsics.atomic_xchg_relaxed

// Returns value and optional ok boolean
atomic_compare_exchange_strong                     :: intrinsics.atomic_cxchg
atomic_compare_exchange_strong_acquire             :: intrinsics.atomic_cxchg_acq
atomic_compare_exchange_strong_release             :: intrinsics.atomic_cxchg_rel
atomic_compare_exchange_strong_acqrel              :: intrinsics.atomic_cxchg_acqrel
atomic_compare_exchange_strong_relaxed             :: intrinsics.atomic_cxchg_relaxed
atomic_compare_exchange_strong_failrelaxed         :: intrinsics.atomic_cxchg_failrelaxed
atomic_compare_exchange_strong_failacquire         :: intrinsics.atomic_cxchg_failacq
atomic_compare_exchange_strong_acquire_failrelaxed :: intrinsics.atomic_cxchg_acq_failrelaxed
atomic_compare_exchange_strong_acqrel_failrelaxed  :: intrinsics.atomic_cxchg_acqrel_failrelaxed

// Returns value and optional ok boolean
atomic_compare_exchange_weak                     :: intrinsics.atomic_cxchgweak
atomic_compare_exchange_weak_acquire             :: intrinsics.atomic_cxchgweak_acq
atomic_compare_exchange_weak_release             :: intrinsics.atomic_cxchgweak_rel
atomic_compare_exchange_weak_acqrel              :: intrinsics.atomic_cxchgweak_acqrel
atomic_compare_exchange_weak_relaxed             :: intrinsics.atomic_cxchgweak_relaxed
atomic_compare_exchange_weak_failrelaxed         :: intrinsics.atomic_cxchgweak_failrelaxed
atomic_compare_exchange_weak_failacquire         :: intrinsics.atomic_cxchgweak_failacq
atomic_compare_exchange_weak_acquire_failrelaxed :: intrinsics.atomic_cxchgweak_acq_failrelaxed
atomic_compare_exchange_weak_acqrel_failrelaxed  :: intrinsics.atomic_cxchgweak_acqrel_failrelaxed
