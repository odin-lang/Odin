package sync

Ordering :: enum {
	Relaxed, // Monotonic
	Release,
	Acquire,
	Acquire_Release,
	Sequentially_Consistent,
}

strongest_failure_ordering :: inline proc "contextless" (order: Ordering) -> Ordering {
	using Ordering;
	#complete switch order {
	case Relaxed: return Relaxed;
	case Release: return Relaxed;
	case Acquire: return Acquire;
	case Acquire_Release: return Acquire;
	case Sequentially_Consistent: return Sequentially_Consistent;
	}
	return Relaxed;
}

fence :: proc "contextless" (order: Ordering) {
	using Ordering;
	#complete switch order {
	case Relaxed: panic("there is no such thing as a relaxed fence");
	case Release: __atomic_fence_rel();
	case Acquire: __atomic_fence_acq();
	case Acquire_Release:  __atomic_fence_acqrel();
	case Sequentially_Consistent: __atomic_fence();
	case: panic("unknown order");
	}
}


atomic_store :: proc "contextless" (dst: ^$T, val: T, order: Ordering) {
	using Ordering;
	#complete switch order {
	case Relaxed: __atomic_store_relaxed(dst, val);
	case Release: __atomic_store_rel(dst, val);
	case Sequentially_Consistent: __atomic_store(dst, val);
	case Acquire: panic("there is not such thing as an acquire store");
	case Acquire_Release: panic("there is not such thing as an acquire/release store");
	case: panic("unknown order");
	}
}

atomic_load :: proc "contextless" (dst: ^$T, order: Ordering) -> T {
	using Ordering;
	#complete switch order {
	case Relaxed: return __atomic_load_relaxed(dst);
	case Acquire: return __atomic_load_acq(dst);
	case Sequentially_Consistent: return __atomic_load(dst);
	case Release: panic("there is no such thing as a release load");
	case Acquire_Release: panic("there is no such thing as an acquire/release load");
	}
	panic("unknown order");
	return T{};
}

atomic_swap :: proc "contextless" (dst: ^$T, val: T, order: Ordering) -> T {
	using Ordering;
	#complete switch order {
	case Relaxed:                 return __atomic_xchg_relaxed(dst, val);
	case Release:                 return __atomic_xchg_rel(dst, val);
	case Acquire:                 return __atomic_xchg_acq(dst, val);
	case Acquire_Release:         return __atomic_xchg_acqrel(dst, val);
	case Sequentially_Consistent: return __atomic_xchg(dst, val);
	}
	panic("unknown order");
	return T{};
}

atomic_compare_exchange :: proc "contextless" (dst: ^$T, old, new: T, success, failure: Ordering) -> (val: T, ok: bool) {
	using Ordering;
	switch failure {
	case Relaxed:
		switch success {
		case Release:                 return __atomic_cxchg_rel_failrelaxed(dst, old, new);
		case Relaxed:                 return __atomic_cxchg_relaxed(dst, old, new);
		case Acquire:                 return __atomic_cxchg_acq_failrelaxed(dst, old, new);
		case Acquire_Release:         return __atomic_cxchg_acqrel_failrelaxed(dst, old, new);
		case Sequentially_Consistent: return __atomic_cxchg_failrelaxed(dst, old, new);
		case: panic("an unknown ordering combination");
		}
	case Acquire:
		switch success {
		case Acquire:                 return __atomic_cxchg_acq(dst, old, new);
		case Acquire_Release:         return __atomic_cxchg_acqrel_failacq(dst, old, new);
		case Sequentially_Consistent: return __atomic_acqrel_failacq(dst, old, new);
		case: panic("an unknown ordering combination");
		}
	case Sequentially_Consistent:
		switch success {
		case Sequentially_Consistent: return __atomic_cxchg(dst, old, new);
		case: panic("an unknown ordering combination");
		}
	case Acquire_Release:
		panic("there is not such thing as an acquire/release failure ordering");
	case Release:
		panic("there is not such thing as an release failure ordering");
	}

	return T{}, false;
}


atomic_add :: proc "contextless" (dst: ^$T, val: T, order: Ordering) -> T {
	using Ordering;
	#complete switch order {
	case Relaxed:                 return __atomic_add_relaxed(dst, val);
	case Release:                 return __atomic_add_rel(dst, val);
	case Acquire:                 return __atomic_add_acq(dst, val);
	case Acquire_Release:         return __atomic_add_acqrel(dst, val);
	case Sequentially_Consistent: return __atomic_add(dst, val);
	}
	panic("unknown order");
	return T{};
}

atomic_sub :: proc "contextless" (dst: ^$T, val: T, order: Ordering) -> T {
	using Ordering;
	#complete switch order {
	case Relaxed:                 return __atomic_sub_relaxed(dst, val);
	case Release:                 return __atomic_sub_rel(dst, val);
	case Acquire:                 return __atomic_sub_acq(dst, val);
	case Acquire_Release:         return __atomic_sub_acqrel(dst, val);
	case Sequentially_Consistent: return __atomic_sub(dst, val);
	}
	panic("unknown order");
	return T{};
}

atomic_and :: proc "contextless" (dst: ^$T, val: T, order: Ordering) -> T {
	using Ordering;
	#complete switch order {
	case Relaxed:                 return __atomic_and_relaxed(dst, val);
	case Release:                 return __atomic_and_rel(dst, val);
	case Acquire:                 return __atomic_and_acq(dst, val);
	case Acquire_Release:         return __atomic_and_acqrel(dst, val);
	case Sequentially_Consistent: return __atomic_and(dst, val);
	}
	panic("unknown order");
	return T{};
}

atomic_nand :: proc "contextless" (dst: ^$T, val: T, order: Ordering) -> T {
	using Ordering;
	#complete switch order {
	case Relaxed:                 return __atomic_nand_relaxed(dst, val);
	case Release:                 return __atomic_nand_rel(dst, val);
	case Acquire:                 return __atomic_nand_acq(dst, val);
	case Acquire_Release:         return __atomic_nand_acqrel(dst, val);
	case Sequentially_Consistent: return __atomic_nand(dst, val);
	}
	panic("unknown order");
	return T{};
}

atomic_or :: proc "contextless" (dst: ^$T, val: T, order: Ordering) -> T {
	using Ordering;
	#complete switch order {
	case Relaxed:                 return __atomic_or_relaxed(dst, val);
	case Release:                 return __atomic_or_rel(dst, val);
	case Acquire:                 return __atomic_or_acq(dst, val);
	case Acquire_Release:         return __atomic_or_acqrel(dst, val);
	case Sequentially_Consistent: return __atomic_or(dst, val);
	}
	panic("unknown order");
	return T{};
}

atomic_xor :: proc "contextless" (dst: ^$T, val: T, order: Ordering) -> T {
	using Ordering;
	#complete switch order {
	case Relaxed:                 return __atomic_xor_relaxed(dst, val);
	case Release:                 return __atomic_xor_rel(dst, val);
	case Acquire:                 return __atomic_xor_acq(dst, val);
	case Acquire_Release:         return __atomic_xor_acqrel(dst, val);
	case Sequentially_Consistent: return __atomic_xor(dst, val);
	}
	panic("unknown order");
	return T{};
}

