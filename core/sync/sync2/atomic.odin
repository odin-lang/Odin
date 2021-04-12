package sync2

import "intrinsics"

// TODO(bill): Is this even a good design? The intrinsics seem to be more than good enough and just as clean

cpu_relax :: intrinsics.cpu_relax;

atomic_fence        :: intrinsics.atomic_fence;
atomic_fence_acq    :: intrinsics.atomic_fence_acq;
atomic_fence_rel    :: intrinsics.atomic_fence_rel;
atomic_fence_acqrel :: intrinsics.atomic_fence_acqrel;

atomic_store           :: intrinsics.atomic_store;
atomic_store_rel       :: intrinsics.atomic_store_rel;
atomic_store_relaxed   :: intrinsics.atomic_store_relaxed;
atomic_store_unordered :: intrinsics.atomic_store_unordered;

atomic_load           :: intrinsics.atomic_load;
atomic_load_acq       :: intrinsics.atomic_load_acq;
atomic_load_relaxed   :: intrinsics.atomic_load_relaxed;
atomic_load_unordered :: intrinsics.atomic_load_unordered;

atomic_add          :: intrinsics.atomic_add;
atomic_add_acq      :: intrinsics.atomic_add_acq;
atomic_add_rel      :: intrinsics.atomic_add_rel;
atomic_add_acqrel   :: intrinsics.atomic_add_acqrel;
atomic_add_relaxed  :: intrinsics.atomic_add_relaxed;
atomic_sub          :: intrinsics.atomic_sub;
atomic_sub_acq      :: intrinsics.atomic_sub_acq;
atomic_sub_rel      :: intrinsics.atomic_sub_rel;
atomic_sub_acqrel   :: intrinsics.atomic_sub_acqrel;
atomic_sub_relaxed  :: intrinsics.atomic_sub_relaxed;
atomic_and          :: intrinsics.atomic_and;
atomic_and_acq      :: intrinsics.atomic_and_acq;
atomic_and_rel      :: intrinsics.atomic_and_rel;
atomic_and_acqrel   :: intrinsics.atomic_and_acqrel;
atomic_and_relaxed  :: intrinsics.atomic_and_relaxed;
atomic_nand         :: intrinsics.atomic_nand;
atomic_nand_acq     :: intrinsics.atomic_nand_acq;
atomic_nand_rel     :: intrinsics.atomic_nand_rel;
atomic_nand_acqrel  :: intrinsics.atomic_nand_acqrel;
atomic_nand_relaxed :: intrinsics.atomic_nand_relaxed;
atomic_or           :: intrinsics.atomic_or;
atomic_or_acq       :: intrinsics.atomic_or_acq;
atomic_or_rel       :: intrinsics.atomic_or_rel;
atomic_or_acqrel    :: intrinsics.atomic_or_acqrel;
atomic_or_relaxed   :: intrinsics.atomic_or_relaxed;
atomic_xor          :: intrinsics.atomic_xor;
atomic_xor_acq      :: intrinsics.atomic_xor_acq;
atomic_xor_rel      :: intrinsics.atomic_xor_rel;
atomic_xor_acqrel   :: intrinsics.atomic_xor_acqrel;
atomic_xor_relaxed  :: intrinsics.atomic_xor_relaxed;

atomic_xchg         :: intrinsics.atomic_xchg;
atomic_xchg_acq     :: intrinsics.atomic_xchg_acq;
atomic_xchg_rel     :: intrinsics.atomic_xchg_rel;
atomic_xchg_acqrel  :: intrinsics.atomic_xchg_acqrel;
atomic_xchg_relaxed :: intrinsics.atomic_xchg_relaxed;

atomic_cxchg                    :: intrinsics.atomic_cxchg;
atomic_cxchg_acq                :: intrinsics.atomic_cxchg_acq;
atomic_cxchg_rel                :: intrinsics.atomic_cxchg_rel;
atomic_cxchg_acqrel             :: intrinsics.atomic_cxchg_acqrel;
atomic_cxchg_relaxed            :: intrinsics.atomic_cxchg_relaxed;
atomic_cxchg_failrelaxed        :: intrinsics.atomic_cxchg_failrelaxed;
atomic_cxchg_failacq            :: intrinsics.atomic_cxchg_failacq;
atomic_cxchg_acq_failrelaxed    :: intrinsics.atomic_cxchg_acq_failrelaxed;
atomic_cxchg_acqrel_failrelaxed :: intrinsics.atomic_cxchg_acqrel_failrelaxed;

atomic_cxchgweak                    :: intrinsics.atomic_cxchgweak;
atomic_cxchgweak_acq                :: intrinsics.atomic_cxchgweak_acq;
atomic_cxchgweak_rel                :: intrinsics.atomic_cxchgweak_rel;
atomic_cxchgweak_acqrel             :: intrinsics.atomic_cxchgweak_acqrel;
atomic_cxchgweak_relaxed            :: intrinsics.atomic_cxchgweak_relaxed;
atomic_cxchgweak_failrelaxed        :: intrinsics.atomic_cxchgweak_failrelaxed;
atomic_cxchgweak_failacq            :: intrinsics.atomic_cxchgweak_failacq;
atomic_cxchgweak_acq_failrelaxed    :: intrinsics.atomic_cxchgweak_acq_failrelaxed;
atomic_cxchgweak_acqrel_failrelaxed :: intrinsics.atomic_cxchgweak_acqrel_failrelaxed;
