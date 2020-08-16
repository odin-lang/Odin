package sync

import "intrinsics"

Ordering :: enum {
	Relaxed, // Monotonic
	Release,
	Acquire,
	Acquire_Release,
	Sequentially_Consistent,
}

strongest_failure_ordering_table := [Ordering]Ordering{
	.Relaxed                 = .Relaxed,
	.Release                 = .Relaxed,
	.Acquire                 = .Acquire,
	.Acquire_Release         = .Acquire,
	.Sequentially_Consistent = .Sequentially_Consistent,
};

strongest_failure_ordering :: inline proc(order: Ordering) -> Ordering {
	return strongest_failure_ordering_table[order];
}

fence :: inline proc($order: Ordering) {
	     when order == .Relaxed                 { #panic("there is no such thing as a relaxed fence"); }
	else when order == .Release                 { intrinsics.atomic_fence_rel();                       }
	else when order == .Acquire                 { intrinsics.atomic_fence_acq();                       }
	else when order == .Acquire_Release         { intrinsics.atomic_fence_acqrel();                    }
	else when order == .Sequentially_Consistent { intrinsics.atomic_fence();                           }
	else { #panic("unknown order"); }
}


atomic_store :: inline proc(dst: ^$T, val: T, $order: Ordering) {
	     when order == .Relaxed                 { intrinsics.atomic_store_relaxed(dst, val); }
	else when order == .Release                 { intrinsics.atomic_store_rel(dst, val); }
	else when order == .Sequentially_Consistent { intrinsics.atomic_store(dst, val); }
	else when order == .Acquire                 { #panic("there is not such thing as an acquire store"); }
	else when order == .Acquire_Release         { #panic("there is not such thing as an acquire/release store"); }
	else { #panic("unknown order"); }
}

atomic_load :: inline proc(dst: ^$T, $order: Ordering) -> T {
	     when order == .Relaxed                 { return intrinsics.atomic_load_relaxed(dst); }
	else when order == .Acquire                 { return intrinsics.atomic_load_acq(dst); }
	else when order == .Sequentially_Consistent { return intrinsics.atomic_load(dst); }
	else when order == .Release                 { #panic("there is no such thing as a release load"); }
	else when order == .Acquire_Release         { #panic("there is no such thing as an acquire/release load"); }
	else { #panic("unknown order"); }
}

atomic_swap :: inline proc(dst: ^$T, val: T, $order: Ordering) -> T {
	     when order == .Relaxed                 { return intrinsics.atomic_xchg_relaxed(dst, val); }
	else when order == .Release                 { return intrinsics.atomic_xchg_rel(dst, val);     }
	else when order == .Acquire                 { return intrinsics.atomic_xchg_acq(dst, val);     }
	else when order == .Acquire_Release         { return intrinsics.atomic_xchg_acqrel(dst, val);  }
	else when order == .Sequentially_Consistent { return intrinsics.atomic_xchg(dst, val);         }
	else { #panic("unknown order"); }
}

atomic_compare_exchange :: inline proc(dst: ^$T, old, new: T, $success, $failure: Ordering) -> (val: T, ok: bool) {
	when failure == .Relaxed {
		     when success == .Relaxed                 { return intrinsics.atomic_cxchg_relaxed(dst, old, new); }
		else when success == .Acquire                 { return intrinsics.atomic_cxchg_acq_failrelaxed(dst, old, new); }
		else when success == .Acquire_Release         { return intrinsics.atomic_cxchg_acqrel_failrelaxed(dst, old, new); }
		else when success == .Sequentially_Consistent { return intrinsics.atomic_cxchg_failrelaxed(dst, old, new); }
		else when success == .Release                 { return intrinsics.atomic_cxchg_rel(dst, old, new); }
		else { #panic("an unknown ordering combination"); }
	} else when failure == .Acquire {
		     when success == .Release { return intrinsics.atomic_cxchg_acqrel(dst, old, new); }
		else when success == .Acquire { return intrinsics.atomic_cxchg_acq(dst, old, new); }
		else { #panic("an unknown ordering combination"); }
	} else when failure == .Sequentially_Consistent {
		when success == .Sequentially_Consistent { return intrinsics.atomic_cxchg(dst, old, new); }
		else { #panic("an unknown ordering combination"); }
	} else when failure == .Acquire_Release {
		#panic("there is not such thing as an acquire/release failure ordering");
	} else when failure == .Release {
		when success == .Acquire { return instrinsics.atomic_cxchg_failacq(dst, old, new); }
		else { #panic("an unknown ordering combination"); }
	} else {
		return T{}, false;
	}

}

atomic_compare_exchange_weak :: inline proc(dst: ^$T, old, new: T, $success, $failure: Ordering) -> (val: T, ok: bool) {
	when failure == .Relaxed {
		     when success == .Relaxed                 { return intrinsics.atomic_cxchgweak_relaxed(dst, old, new); }
		else when success == .Acquire                 { return intrinsics.atomic_cxchgweak_acq_failrelaxed(dst, old, new); }
		else when success == .Acquire_Release         { return intrinsics.atomic_cxchgweak_acqrel_failrelaxed(dst, old, new); }
		else when success == .Sequentially_Consistent { return intrinsics.atomic_cxchgweak_failrelaxed(dst, old, new); }
		else when success == .Release                 { return intrinsics.atomic_cxchgweak_rel(dst, old, new); }
		else { #panic("an unknown ordering combination"); }
	} else when failure == .Acquire {
		     when success == .Release { return intrinsics.atomic_cxchgweak_acqrel(dst, old, new); }
		else when success == .Acquire { return intrinsics.atomic_cxchgweak_acq(dst, old, new); }
		else { #panic("an unknown ordering combination"); }
	} else when failure == .Sequentially_Consistent {
		when success == .Sequentially_Consistent { return intrinsics.atomic_cxchgweak(dst, old, new); }
		else { #panic("an unknown ordering combination"); }
	} else when failure == .Acquire_Release {
		#panic("there is not such thing as an acquire/release failure ordering");
	} else when failure == .Release {
		when success == .Acquire { return intrinsics.atomic_cxchgweak_failacq(dst, old, new); }
		else { #panic("an unknown ordering combination"); }
	} else {
		return T{}, false;
	}

}


atomic_add :: inline proc(dst: ^$T, val: T, $order: Ordering) -> T {
	     when order == .Relaxed                 { return intrinsics.atomic_add_relaxed(dst, val); }
	else when order == .Release                 { return intrinsics.atomic_add_rel(dst, val); }
	else when order == .Acquire                 { return intrinsics.atomic_add_acq(dst, val); }
	else when order == .Acquire_Release         { return intrinsics.atomic_add_acqrel(dst, val); }
	else when order == .Sequentially_Consistent { return intrinsics.atomic_add(dst, val); }
	else { #panic("unknown order"); }
}

atomic_sub :: inline proc(dst: ^$T, val: T, $order: Ordering) -> T {
	     when order == .Relaxed                 { return intrinsics.atomic_sub_relaxed(dst, val); }
	else when order == .Release                 { return intrinsics.atomic_sub_rel(dst, val); }
	else when order == .Acquire                 { return intrinsics.atomic_sub_acq(dst, val); }
	else when order == .Acquire_Release         { return intrinsics.atomic_sub_acqrel(dst, val); }
	else when order == .Sequentially_Consistent { return intrinsics.atomic_sub(dst, val); }
	else { #panic("unknown order"); }
}

atomic_and :: inline proc(dst: ^$T, val: T, $order: Ordering) -> T {
	     when order == .Relaxed                 { return intrinsics.atomic_and_relaxed(dst, val); }
	else when order == .Release                 { return intrinsics.atomic_and_rel(dst, val); }
	else when order == .Acquire                 { return intrinsics.atomic_and_acq(dst, val); }
	else when order == .Acquire_Release         { return intrinsics.atomic_and_acqrel(dst, val); }
	else when order == .Sequentially_Consistent { return intrinsics.atomic_and(dst, val); }
	else { #panic("unknown order"); }
}

atomic_nand :: inline proc(dst: ^$T, val: T, $order: Ordering) -> T {
	     when order == .Relaxed                 { return intrinsics.atomic_nand_relaxed(dst, val); }
	else when order == .Release                 { return intrinsics.atomic_nand_rel(dst, val); }
	else when order == .Acquire                 { return intrinsics.atomic_nand_acq(dst, val); }
	else when order == .Acquire_Release         { return intrinsics.atomic_nand_acqrel(dst, val); }
	else when order == .Sequentially_Consistent { return intrinsics.atomic_nand(dst, val); }
	else { #panic("unknown order"); }
}

atomic_or :: inline proc(dst: ^$T, val: T, $order: Ordering) -> T {
	     when order == .Relaxed                 { return intrinsics.atomic_or_relaxed(dst, val); }
	else when order == .Release                 { return intrinsics.atomic_or_rel(dst, val); }
	else when order == .Acquire                 { return intrinsics.atomic_or_acq(dst, val); }
	else when order == .Acquire_Release         { return intrinsics.atomic_or_acqrel(dst, val); }
	else when order == .Sequentially_Consistent { return intrinsics.atomic_or(dst, val); }
	else { #panic("unknown order"); }
}

atomic_xor :: inline proc(dst: ^$T, val: T, $order: Ordering) -> T {
	     when order == .Relaxed                 { return intrinsics.atomic_xor_relaxed(dst, val); }
	else when order == .Release                 { return intrinsics.atomic_xor_rel(dst, val); }
	else when order == .Acquire                 { return intrinsics.atomic_xor_acq(dst, val); }
	else when order == .Acquire_Release         { return intrinsics.atomic_xor_acqrel(dst, val); }
	else when order == .Sequentially_Consistent { return intrinsics.atomic_xor(dst, val); }
	else { #panic("unknown order"); }
}

