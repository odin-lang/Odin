package sync

import "base:intrinsics"

cpu_relax :: intrinsics.cpu_relax

/*
Atomic_Memory_Order :: enum {
	Relaxed = 0, // Unordered
	Consume = 1, // Monotonic
	Acquire = 2,
	Release = 3,
	Acq_Rel = 4,
	Seq_Cst = 5,
}
*/
Atomic_Memory_Order :: intrinsics.Atomic_Memory_Order


atomic_thread_fence                     :: intrinsics.atomic_thread_fence
atomic_signal_fence                     :: intrinsics.atomic_signal_fence
atomic_store                            :: intrinsics.atomic_store
atomic_store_explicit                   :: intrinsics.atomic_store_explicit
atomic_load                             :: intrinsics.atomic_load
atomic_load_explicit                    :: intrinsics.atomic_load_explicit
atomic_add                              :: intrinsics.atomic_add
atomic_add_explicit                     :: intrinsics.atomic_add_explicit
atomic_sub                              :: intrinsics.atomic_sub
atomic_sub_explicit                     :: intrinsics.atomic_sub_explicit
atomic_and                              :: intrinsics.atomic_and
atomic_and_explicit                     :: intrinsics.atomic_and_explicit
atomic_nand                             :: intrinsics.atomic_nand
atomic_nand_explicit                    :: intrinsics.atomic_nand_explicit
atomic_or                               :: intrinsics.atomic_or
atomic_or_explicit                      :: intrinsics.atomic_or_explicit
atomic_xor                              :: intrinsics.atomic_xor
atomic_xor_explicit                     :: intrinsics.atomic_xor_explicit
atomic_exchange                         :: intrinsics.atomic_exchange
atomic_exchange_explicit                :: intrinsics.atomic_exchange_explicit

// Returns value and optional ok boolean
atomic_compare_exchange_strong          :: intrinsics.atomic_compare_exchange_strong
atomic_compare_exchange_strong_explicit :: intrinsics.atomic_compare_exchange_strong_explicit
atomic_compare_exchange_weak            :: intrinsics.atomic_compare_exchange_weak
atomic_compare_exchange_weak_explicit   :: intrinsics.atomic_compare_exchange_weak_explicit