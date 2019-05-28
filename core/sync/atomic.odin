package sync

import "intrinsics"

Ordering :: enum {
	Relaxed, // Monotonic
	Release,
	Acquire,
	Acquire_Release,
	Sequentially_Consistent,
}

strongest_failure_ordering :: inline proc "contextless" (order: Ordering) -> Ordering {
	#complete switch order {
	case .Relaxed:                 return .Relaxed;
	case .Release:                 return .Relaxed;
	case .Acquire:                 return .Acquire;
	case .Acquire_Release:         return .Acquire;
	case .Sequentially_Consistent: return .Sequentially_Consistent;
	}
	return .Relaxed;
}

fence :: inline proc "contextless" ($order: Ordering) {
	#complete switch order {
	case .Relaxed:                 panic("there is no such thing as a relaxed fence");
	case .Release:                 intrinsics.atomic_fence_rel();
	case .Acquire:                 intrinsics.atomic_fence_acq();
	case .Acquire_Release:         intrinsics.atomic_fence_acqrel();
	case .Sequentially_Consistent: intrinsics.atomic_fence();
	case: panic("unknown order");
	}
}


atomic_store :: inline proc "contextless" (dst: ^$T, val: T, $order: Ordering) {
	#complete switch order {
	case .Relaxed:                 intrinsics.atomic_store_relaxed(dst, val);
	case .Release:                 intrinsics.atomic_store_rel(dst, val);
	case .Sequentially_Consistent: intrinsics.atomic_store(dst, val);
	case .Acquire:         panic("there is not such thing as an acquire store");
	case .Acquire_Release: panic("there is not such thing as an acquire/release store");
	case: panic("unknown order");
	}
}

atomic_load :: inline proc "contextless" (dst: ^$T, $order: Ordering) -> T {
	#complete switch order {
	case .Relaxed:                 return intrinsics.atomic_load_relaxed(dst);
	case .Acquire:                 return intrinsics.atomic_load_acq(dst);
	case .Sequentially_Consistent: return intrinsics.atomic_load(dst);
	case .Release:         panic("there is no such thing as a release load");
	case .Acquire_Release: panic("there is no such thing as an acquire/release load");
	}
	panic("unknown order");
	return T{};
}

atomic_swap :: inline proc "contextless" (dst: ^$T, val: T, $order: Ordering) -> T {
	#complete switch order {
	case .Relaxed:                 return intrinsics.atomic_xchg_relaxed(dst, val);
	case .Release:                 return intrinsics.atomic_xchg_rel(dst, val);
	case .Acquire:                 return intrinsics.atomic_xchg_acq(dst, val);
	case .Acquire_Release:         return intrinsics.atomic_xchg_acqrel(dst, val);
	case .Sequentially_Consistent: return intrinsics.atomic_xchg(dst, val);
	}
	panic("unknown order");
	return T{};
}

atomic_compare_exchange :: inline proc "contextless" (dst: ^$T, old, new: T, $success, $failure: Ordering) -> (val: T, ok: bool) {
	switch failure {
	case .Relaxed:
		switch success {
		case .Relaxed:                 return intrinsics.atomic_cxchg_relaxed(dst, old, new);
		case .Acquire:                 return intrinsics.atomic_cxchg_acq_failrelaxed(dst, old, new);
		case .Acquire_Release:         return intrinsics.atomic_cxchg_acqrel_failrelaxed(dst, old, new);
		case .Sequentially_Consistent: return intrinsics.atomic_cxchg_failrelaxed(dst, old, new);
		case .Release:                 return intrinsics.atomic_cxchg_rel(dst, old, new);
		case: panic("an unknown ordering combination");
		}
	case .Acquire:
		switch success {
		case .Release:                 return intrinsics.atomic_cxchg_acqrel(dst, old, new);
		case .Acquire:                 return intrinsics.atomic_cxchg_acq(dst, old, new);
		case: panic("an unknown ordering combination");
		}
	case .Sequentially_Consistent:
		switch success {
		case .Sequentially_Consistent: return intrinsics.atomic_cxchg(dst, old, new);
		case: panic("an unknown ordering combination");
		}
	case .Acquire_Release:
		panic("there is not such thing as an acquire/release failure ordering");
	case .Release:
		switch success {
		case .Acquire:                 return instrinsics.atomic_cxchg_failacq(dst, old, new);
		case: panic("an unknown ordering combination");
		}
	}
	return T{}, false;

}

atomic_compare_exchange_weak :: inline proc "contextless" (dst: ^$T, old, new: T, $success, $failure: Ordering) -> (val: T, ok: bool) {
	switch failure {
	case .Relaxed:
		switch success {
		case .Relaxed:                 return intrinsics.atomic_cxchgweak_relaxed(dst, old, new);
		case .Acquire:                 return intrinsics.atomic_cxchgweak_acq_failrelaxed(dst, old, new);
		case .Acquire_Release:         return intrinsics.atomic_cxchgweak_acqrel_failrelaxed(dst, old, new);
		case .Sequentially_Consistent: return intrinsics.atomic_cxchgweak_failrelaxed(dst, old, new);
		case .Release:                 return intrinsics.atomic_cxchgweak_rel(dst, old, new);
		case: panic("an unknown ordering combination");
		}
	case .Acquire:
		switch success {
		case .Release:                 return intrinsics.atomic_cxchgweak_acqrel(dst, old, new);
		case .Acquire:                 return intrinsics.atomic_cxchgweak_acq(dst, old, new);
		case: panic("an unknown ordering combination");
		}
	case .Sequentially_Consistent:
		switch success {
		case .Sequentially_Consistent: return intrinsics.atomic_cxchgweak(dst, old, new);
		case: panic("an unknown ordering combination");
		}
	case .Acquire_Release:
		panic("there is not such thing as an acquire/release failure ordering");
	case .Release:
		switch success {
		case .Acquire:                 return intrinsics.atomic_cxchgweak_failacq(dst, old, new);
		case: panic("an unknown ordering combination");
		}
	}
	return T{}, false;

}


atomic_add :: inline proc "contextless" (dst: ^$T, val: T, $order: Ordering) -> T {
	#complete switch order {
	case .Relaxed:                 return intrinsics.atomic_add_relaxed(dst, val);
	case .Release:                 return intrinsics.atomic_add_rel(dst, val);
	case .Acquire:                 return intrinsics.atomic_add_acq(dst, val);
	case .Acquire_Release:         return intrinsics.atomic_add_acqrel(dst, val);
	case .Sequentially_Consistent: return intrinsics.atomic_add(dst, val);
	}
	panic("unknown order");
	return T{};
}

atomic_sub :: inline proc "contextless" (dst: ^$T, val: T, $order: Ordering) -> T {
	#complete switch order {
	case .Relaxed:                 return intrinsics.atomic_sub_relaxed(dst, val);
	case .Release:                 return intrinsics.atomic_sub_rel(dst, val);
	case .Acquire:                 return intrinsics.atomic_sub_acq(dst, val);
	case .Acquire_Release:         return intrinsics.atomic_sub_acqrel(dst, val);
	case .Sequentially_Consistent: return intrinsics.atomic_sub(dst, val);
	}
	panic("unknown order");
	return T{};
}

atomic_and :: inline proc "contextless" (dst: ^$T, val: T, $order: Ordering) -> T {
	#complete switch order {
	case .Relaxed:                 return intrinsics.atomic_and_relaxed(dst, val);
	case .Release:                 return intrinsics.atomic_and_rel(dst, val);
	case .Acquire:                 return intrinsics.atomic_and_acq(dst, val);
	case .Acquire_Release:         return intrinsics.atomic_and_acqrel(dst, val);
	case .Sequentially_Consistent: return intrinsics.atomic_and(dst, val);
	}
	panic("unknown order");
	return T{};
}

atomic_nand :: inline proc "contextless" (dst: ^$T, val: T, $order: Ordering) -> T {
	#complete switch order {
	case .Relaxed:                 return intrinsics.atomic_nand_relaxed(dst, val);
	case .Release:                 return intrinsics.atomic_nand_rel(dst, val);
	case .Acquire:                 return intrinsics.atomic_nand_acq(dst, val);
	case .Acquire_Release:         return intrinsics.atomic_nand_acqrel(dst, val);
	case .Sequentially_Consistent: return intrinsics.atomic_nand(dst, val);
	}
	panic("unknown order");
	return T{};
}

atomic_or :: inline proc "contextless" (dst: ^$T, val: T, $order: Ordering) -> T {
	#complete switch order {
	case .Relaxed:                 return intrinsics.atomic_or_relaxed(dst, val);
	case .Release:                 return intrinsics.atomic_or_rel(dst, val);
	case .Acquire:                 return intrinsics.atomic_or_acq(dst, val);
	case .Acquire_Release:         return intrinsics.atomic_or_acqrel(dst, val);
	case .Sequentially_Consistent: return intrinsics.atomic_or(dst, val);
	}
	panic("unknown order");
	return T{};
}

atomic_xor :: inline proc "contextless" (dst: ^$T, val: T, $order: Ordering) -> T {
	#complete switch order {
	case .Relaxed:                 return intrinsics.atomic_xor_relaxed(dst, val);
	case .Release:                 return intrinsics.atomic_xor_rel(dst, val);
	case .Acquire:                 return intrinsics.atomic_xor_acq(dst, val);
	case .Acquire_Release:         return intrinsics.atomic_xor_acqrel(dst, val);
	case .Sequentially_Consistent: return intrinsics.atomic_xor(dst, val);
	}
	panic("unknown order");
	return T{};
}

