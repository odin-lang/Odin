package libc

// 7.17 Atomics

import "core:intrinsics"

ATOMIC_BOOL_LOCK_FREE     :: true
ATOMIC_CHAR_LOCK_FREE     :: true
ATOMIC_CHAR16_T_LOCK_FREE :: true
ATOMIC_CHAR32_T_LOCK_FREE :: true
ATOMIC_WCHAR_T_LOCK_FREE  :: true
ATOMIC_SHORT_LOCK_FREE    :: true
ATOMIC_INT_LOCK_FREE      :: true
ATOMIC_LONG_LOCK_FREE     :: true
ATOMIC_LLONG_LOCK_FREE    :: true
ATOMIC_POINTER_LOCK_FREE  :: true

// 7.17.3 Order and consistency
memory_order :: enum int {
	relaxed,
	consume,
	acquire,
	release,
	acq_rel,
	seq_cst,
}

memory_order_relaxed :: memory_order.relaxed
memory_order_consume :: memory_order.consume
memory_order_acquire :: memory_order.acquire
memory_order_release :: memory_order.release
memory_order_acq_rel :: memory_order.acq_rel
memory_order_seq_cst :: memory_order.seq_cst

// 7.17.2 Initialization
ATOMIC_VAR_INIT :: #force_inline proc(value: $T) -> T {
	return value
}

atomic_init :: #force_inline proc(obj: ^$T, value: T) {
	intrinsics.atomic_store(obj, value)
}

kill_dependency :: #force_inline proc(value: $T) -> T {
	return value
}

// 7.17.4 Fences
atomic_thread_fence :: #force_inline proc(order: memory_order) {
	assert(order != .relaxed)
	assert(order != .consume)
	#partial switch order {
	case .acquire: intrinsics.atomic_thread_fence(.acquire)
	case .release: intrinsics.atomic_thread_fence(.release)
	case .acq_rel: intrinsics.atomic_thread_fence(.acq_rel)
	case .seq_cst: intrinsics.atomic_thread_fence(.seq_cst)
	}
}

atomic_signal_fence :: #force_inline proc(order: memory_order) {
	assert(order != .relaxed)
	assert(order != .consume)
	#partial switch order {
	case .acquire: intrinsics.atomic_signal_fence(.acquire)
	case .release: intrinsics.atomic_signal_fence(.release)
	case .acq_rel: intrinsics.atomic_signal_fence(.acq_rel)
	case .seq_cst: intrinsics.atomic_signal_fence(.seq_cst)
	}
}

// 7.17.5 Lock-free property
atomic_is_lock_free :: #force_inline proc(obj: ^$T) -> bool {
	return size_of(T) <= 8 && (intrinsics.type_is_integer(T) || intrinsics.type_is_pointer(T))
}

// 7.17.6 Atomic integer types
atomic_bool           :: distinct bool
atomic_char           :: distinct char
atomic_schar          :: distinct char
atomic_uchar          :: distinct uchar
atomic_short          :: distinct short
atomic_ushort         :: distinct ushort
atomic_int            :: distinct int
atomic_uint           :: distinct uint
atomic_long           :: distinct long
atomic_ulong          :: distinct ulong
atomic_llong          :: distinct longlong
atomic_ullong         :: distinct ulonglong
atomic_char16_t       :: distinct char16_t
atomic_char32_t       :: distinct char32_t
atomic_wchar_t        :: distinct wchar_t
atomic_int_least8_t   :: distinct int_least8_t
atomic_uint_least8_t  :: distinct uint_least8_t
atomic_int_least16_t  :: distinct int_least16_t
atomic_uint_least16_t :: distinct uint_least16_t
atomic_int_least32_t  :: distinct int_least32_t
atomic_uint_least32_t :: distinct uint_least32_t
atomic_int_least64_t  :: distinct int_least64_t
atomic_uint_least64_t :: distinct uint_least64_t
atomic_int_fast8_t    :: distinct int_fast8_t
atomic_uint_fast8_t   :: distinct uint_fast8_t
atomic_int_fast16_t   :: distinct int_fast16_t
atomic_uint_fast16_t  :: distinct uint_fast16_t
atomic_int_fast32_t   :: distinct int_fast32_t
atomic_uint_fast32_t  :: distinct uint_fast32_t
atomic_int_fast64_t   :: distinct int_fast64_t
atomic_uint_fast64_t  :: distinct uint_fast64_t
atomic_intptr_t       :: distinct intptr_t
atomic_uintptr_t      :: distinct uintptr_t
atomic_size_t         :: distinct size_t
atomic_ptrdiff_t      :: distinct ptrdiff_t
atomic_intmax_t       :: distinct intmax_t
atomic_uintmax_t      :: distinct uintmax_t

// 7.17.7 Operations on atomic types
atomic_store :: #force_inline proc(object: ^$T, desired: T) {
	intrinsics.atomic_store(object, desired)
}

atomic_store_explicit :: #force_inline proc(object: ^$T, desired: T, order: memory_order) {
	assert(order != .consume)
	assert(order != .acquire)
	assert(order != .acq_rel)

	#partial switch order {
	case .relaxed: intrinsics.atomic_store_explicit(object, desired, .relaxed)
	case .release: intrinsics.atomic_store_explicit(object, desired, .release)
	case .seq_cst: intrinsics.atomic_store_explicit(object, desired, .seq_cst)
	}
}

atomic_load :: #force_inline proc(object: ^$T) -> T {
	return intrinsics.atomic_load(object)
}

atomic_load_explicit :: #force_inline proc(object: ^$T, order: memory_order) {
	assert(order != .release)
	assert(order != .acq_rel)

	#partial switch order {
	case .relaxed: return intrinsics.atomic_load_explicit(object, .relaxed)
	case .consume: return intrinsics.atomic_load_explicit(object, .consume)
	case .acquire: return intrinsics.atomic_load_explicit(object, .acquire)
	case .seq_cst: return intrinsics.atomic_load_explicit(object, .seq_cst)
	}
}

atomic_exchange :: #force_inline proc(object: ^$T, desired: T) -> T {
	return intrinsics.atomic_exchange(object, desired)
}

atomic_exchange_explicit :: #force_inline proc(object: ^$T, desired: T, order: memory_order) -> T {
	switch order {
	case .relaxed: return intrinsics.atomic_exchange_explicit(object, desired, .relaxed)
	case .consume: return intrinsics.atomic_exchange_explicit(object, desired, .consume)
	case .acquire: return intrinsics.atomic_exchange_explicit(object, desired, .acquire)
	case .release: return intrinsics.atomic_exchange_explicit(object, desired, .release)
	case .acq_rel: return intrinsics.atomic_exchange_explicit(object, desired, .acq_rel)
	case .seq_cst: return intrinsics.atomic_exchange_explicit(object, desired, .seq_cst)
	}
	return false
}

// C does not allow failure memory order to be order_release or acq_rel.
// Similarly, it does not allow the failure order to be stronger than success
// order. Since consume and acquire are both monotonic, we can count them as
// one, for a total of three memory orders that are relevant in compare exchange.
// 	relaxed, acquire (consume), seq_cst.
// The requirement that the failure order cannot be stronger than success limits
// the valid combinations for the failure order to this table:
// 	[success = seq_cst, failure = seq_cst] => _
// 	[success = acquire, failure = seq_cst] => acq
// 	[success = release, failure = seq_cst] => rel
// 	[success = acq_rel, failure = seq_cst] => acqrel
// 	[success = relaxed, failure = relaxed] => relaxed
// 	[success = seq_cst, failure = relaxed] => failrelaxed
// 	[success = seq_cst, failure = acquire] => failacq
// 	[success = acquire, failure = relaxed] => acq_failrelaxed
// 	[success = acq_rel, failure = relaxed] => acqrel_failrelaxed
atomic_compare_exchange_strong :: #force_inline proc(object, expected: ^$T, desired: T) -> bool {
	value, ok := intrinsics.atomic_compare_exchange_strong(object, expected^, desired)
	if !ok { expected^ = value } 
	return ok
}

atomic_compare_exchange_strong_explicit :: #force_inline proc(object, expected: ^$T, desired: T, success, failure: memory_order) -> bool {
	assert(failure != .release)
	assert(failure != .acq_rel)

	value: T; ok: bool
	#partial switch failure {
	case .seq_cst:
		assert(success != .relaxed)
		#partial switch success {
		case .seq_cst:
			value, ok = intrinsics.atomic_compare_exchange_strong_explicit(object, expected^, desired, .seq_cst, .seq_cst)
		case .acquire:
			value, ok = intrinsics.atomic_compare_exchange_strong_explicit(object, expected^, desired, .acquire, .seq_cst)
		case .consume:
			value, ok = intrinsics.atomic_compare_exchange_strong_explicit(object, expected^, desired, .consume, .seq_cst)
		case .release:
			value, ok = intrinsics.atomic_compare_exchange_strong_explicit(object, expected^, desired, .release, .seq_cst)
		case .acq_rel:
			value, ok = intrinsics.atomic_compare_exchange_strong_explicit(object, expected^, desired, .acq_rel, .seq_cst)
		}
	case .relaxed:
		assert(success != .release)
		#partial switch success {
		case .relaxed:
			value, ok = intrinsics.atomic_compare_exchange_strong_explicit(object, expected^, desired, .relaxed, .relaxed)
		case .seq_cst:
			value, ok = intrinsics.atomic_compare_exchange_strong_explicit(object, expected^, desired, .seq_cst, .relaxed)
		case .acquire:
			value, ok = intrinsics.atomic_compare_exchange_strong_explicit(object, expected^, desired, .acquire, .relaxed)
		case .consume:
			value, ok = intrinsics.atomic_compare_exchange_strong_explicit(object, expected^, desired, .consume, .relaxed)
		case .acq_rel:
			value, ok = intrinsics.atomic_compare_exchange_strong_explicit(object, expected^, desired, .acq_rel, .relaxed)
		}
	case .consume:
		assert(success == .seq_cst)
		value, ok = intrinsics.atomic_compare_exchange_strong_explicit(object, expected^, desired, .seq_cst, .consume)
	case .acquire:
		assert(success == .seq_cst)
		value, ok = intrinsics.atomic_compare_exchange_strong_explicit(object, expected^, desired, .seq_cst, .acquire)

	}
	if !ok { expected^ = value }
	return ok
}

atomic_compare_exchange_weak :: #force_inline proc(object, expected: ^$T, desired: T) -> bool {
	value, ok := intrinsics.atomic_compare_exchange_weak(object, expected^, desired)
	if !ok { expected^ = value }
	return ok
}

atomic_compare_exchange_weak_explicit :: #force_inline proc(object, expected: ^$T, desited: T, success, failure: memory_order) -> bool {
	assert(failure != .release)
	assert(failure != .acq_rel)

	value: T; ok: bool
	#partial switch failure {
	case .seq_cst:
		assert(success != .relaxed)
		#partial switch success {
		case .seq_cst:
			value, ok = intrinsics.atomic_compare_exchange_weak_explicit(object, expected^, desired, .seq_cst, .seq_cst)
		case .acquire:
			value, ok = intrinsics.atomic_compare_exchange_weak_explicit(object, expected^, desired, .acquire, .seq_cst)
		case .consume:
			value, ok = intrinsics.atomic_compare_exchange_weak_explicit(object, expected^, desired, .consume, .seq_cst)
		case .release:
			value, ok = intrinsics.atomic_compare_exchange_weak_explicit(object, expected^, desired, .release, .seq_cst)
		case .acq_rel:
			value, ok = intrinsics.atomic_compare_exchange_weak_explicit(object, expected^, desired, .acq_rel, .seq_cst)
		}
	case .relaxed:
		assert(success != .release)
		#partial switch success {
		case .relaxed:
			value, ok = intrinsics.atomic_compare_exchange_weak_explicit(object, expected^, desired, .relaxed, .relaxed)
		case .seq_cst:
			value, ok = intrinsics.atomic_compare_exchange_weak_explicit(object, expected^, desired, .seq_cst, .relaxed)
		case .acquire:
			value, ok = intrinsics.atomic_compare_exchange_weak_explicit(object, expected^, desired, .acquire, .relaxed)
		case .consume:
			value, ok = intrinsics.atomic_compare_exchange_weak_explicit(object, expected^, desired, .consume, .relaxed)
		case .acq_rel:
			value, ok = intrinsics.atomic_compare_exchange_weak_explicit(object, expected^, desired, .acq_rel, .relaxed)
		}
	case .consume:
		assert(success == .seq_cst)
		value, ok = intrinsics.atomic_compare_exchange_weak_explicit(object, expected^, desired, .seq_cst, .consume)
	case .acquire:
		assert(success == .seq_cst)
		value, ok = intrinsics.atomic_compare_exchange_weak_explicit(object, expected^, desired, .seq_cst, .acquire)

	}
	if !ok { expected^ = value }
	return ok
}

// 7.17.7.5 The atomic_fetch and modify generic functions
atomic_fetch_add :: #force_inline proc(object: ^$T, operand: T) -> T {
	return intrinsics.atomic_add(object, operand)
}

atomic_fetch_add_explicit :: #force_inline proc(object: ^$T, operand: T, order: memory_order) -> T {
	switch order {
	case .relaxed: return intrinsics.atomic_add_explicit(object, operand, .relaxed)
	case .consume: return intrinsics.atomic_add_explicit(object, operand, .consume)
	case .acquire: return intrinsics.atomic_add_explicit(object, operand, .acquire)
	case .release: return intrinsics.atomic_add_explicit(object, operand, .release)
	case .acq_rel: return intrinsics.atomic_add_explicit(object, operand, .acq_rel)
	case: fallthrough
	case .seq_cst: return intrinsics.atomic_add_explicit(object, operand, .seq_cst)
	}
}

atomic_fetch_sub :: #force_inline proc(object: ^$T, operand: T) -> T {
	return intrinsics.atomic_sub(object, operand)
}

atomic_fetch_sub_explicit :: #force_inline proc(object: ^$T, operand: T, order: memory_order) -> T {
	switch order {
	case .relaxed: return intrinsics.atomic_sub_explicit(object, operand, .relaxed)
	case .consume: return intrinsics.atomic_sub_explicit(object, operand, .consume)
	case .acquire: return intrinsics.atomic_sub_explicit(object, operand, .acquire)
	case .release: return intrinsics.atomic_sub_explicit(object, operand, .release)
	case .acq_rel: return intrinsics.atomic_sub_explicit(object, operand, .acq_rel)
	case: fallthrough
	case .seq_cst: return intrinsics.atomic_sub_explicit(object, operand, .seq_cst)
	}
}

atomic_fetch_or :: #force_inline proc(object: ^$T, operand: T) -> T {
	return intrinsics.atomic_or(object, operand)
}

atomic_fetch_or_explicit :: #force_inline proc(object: ^$T, operand: T, order: memory_order) -> T {
	switch order {
	case .relaxed: return intrinsics.atomic_or_explicit(object, operand, .relaxed)
	case .consume: return intrinsics.atomic_or_explicit(object, operand, .consume)
	case .acquire: return intrinsics.atomic_or_explicit(object, operand, .acquire)
	case .release: return intrinsics.atomic_or_explicit(object, operand, .release)
	case .acq_rel: return intrinsics.atomic_or_explicit(object, operand, .acq_rel)
	case: fallthrough
	case .seq_cst: return intrinsics.atomic_or_explicit(object, operand, .seq_cst)
	}
}

atomic_fetch_xor :: #force_inline proc(object: ^$T, operand: T) -> T {
	return intrinsics.atomic_xor(object, operand)
}

atomic_fetch_xor_explicit :: #force_inline proc(object: ^$T, operand: T, order: memory_order) -> T {
	switch order {
	case .relaxed: return intrinsics.atomic_xor_explicit(object, operand, .relaxed)
	case .consume: return intrinsics.atomic_xor_explicit(object, operand, .consume)
	case .acquire: return intrinsics.atomic_xor_explicit(object, operand, .acquire)
	case .release: return intrinsics.atomic_xor_explicit(object, operand, .release)
	case .acq_rel: return intrinsics.atomic_xor_explicit(object, operand, .acq_rel)
	case: fallthrough
	case .seq_cst: return intrinsics.atomic_xor_explicit(object, operand, .seq_cst)
	}
}

atomic_fetch_and :: #force_inline proc(object: ^$T, operand: T) -> T {
	return intrinsics.atomic_and(object, operand)
}
atomic_fetch_and_explicit :: #force_inline proc(object: ^$T, operand: T, order: memory_order) -> T {
	switch order {
	case .relaxed: return intrinsics.atomic_and_explicit(object, operand, .relaxed)
	case .consume: return intrinsics.atomic_and_explicit(object, operand, .consume)
	case .acquire: return intrinsics.atomic_and_explicit(object, operand, .acquire)
	case .release: return intrinsics.atomic_and_explicit(object, operand, .release)
	case .acq_rel: return intrinsics.atomic_and_explicit(object, operand, .acq_rel)
	case: fallthrough
	case .seq_cst: return intrinsics.atomic_and_explicit(object, operand, .seq_cst)
	}
}

// 7.17.8 Atomic flag type and operations
atomic_flag :: distinct atomic_bool

atomic_flag_test_and_set :: #force_inline proc(flag: ^atomic_flag) -> bool {
	return bool(atomic_exchange(flag, atomic_flag(true)))
}

atomic_flag_test_and_set_explicit :: #force_inline proc(flag: ^atomic_flag, order: memory_order) -> bool {
	return bool(atomic_exchange_explicit(flag, atomic_flag(true), order))
}

atomic_flag_clear :: #force_inline proc(flag: ^atomic_flag) {
	atomic_store(flag, atomic_flag(false))
}

atomic_flag_clear_explicit :: #force_inline proc(flag: ^atomic_flag, order: memory_order) {
	atomic_store_explicit(flag, atomic_flag(false), order)
}
