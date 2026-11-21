package test_riscv64

import "base:intrinsics"
import "core:testing"
import "core:thread"

ATOMIC_THREADS    :: 4
ATOMIC_ITERATIONS :: 4000

Atomic_State :: struct #align(64) {
	start:  bool,
	bytes:  [2 * ATOMIC_THREADS]u8,
	halves: [ATOMIC_THREADS]u16,
	words:  [ATOMIC_THREADS]u32,
	add8:   u8,
	add16:  u16,
	add32:  u32,
	add64:  u64,
	sub8:   i8,
	sub16:  i16,
	cas8:   u8,
	cas16:  u16,
	cas64:  u64,
	xor8:   u8,
	or16:   u16,
	and16:  u16,
}

@(test)
atomics_sub_word_contention :: proc(t: ^testing.T) {
	state: Atomic_State
	state.and16 = 0xffff

	worker :: proc(k: int, s: ^Atomic_State) {
		for !intrinsics.atomic_load_explicit(&s.start, .Acquire) {
			intrinsics.cpu_relax()
		}
		for n in 0..<ATOMIC_ITERATIONS {
			intrinsics.atomic_add(&s.bytes[k], 1)
			intrinsics.atomic_add_explicit(&s.bytes[k + ATOMIC_THREADS], 3, .Relaxed)
			intrinsics.atomic_add_explicit(&s.halves[k], 1, .Acq_Rel)
			intrinsics.atomic_sub_explicit(&s.words[k], 1, .Release)
			intrinsics.atomic_add(&s.add8, 1)
			intrinsics.atomic_add_explicit(&s.add16, 1, .Relaxed)
			intrinsics.atomic_add_explicit(&s.add32, 1, .Acquire)
			intrinsics.atomic_add(&s.add64, 1)
			intrinsics.atomic_sub(&s.sub8, 1)
			intrinsics.atomic_sub_explicit(&s.sub16, 1, .Relaxed)
			intrinsics.atomic_xor(&s.xor8, u8(1) << uint(k))
			if n == k {
				intrinsics.atomic_or(&s.or16, u16(1) << uint(4 * k + 1))
				intrinsics.atomic_and_explicit(&s.and16, ~(u16(1) << uint(4 * k + 2)), .Seq_Cst)
			}

			for {
				old := intrinsics.atomic_load_explicit(&s.cas8, .Relaxed)
				if _, ok := intrinsics.atomic_compare_exchange_weak_explicit(&s.cas8, old, old + 1, .Acq_Rel, .Relaxed); ok {
					break
				}
			}
			for {
				old := intrinsics.atomic_load(&s.cas16)
				if _, ok := intrinsics.atomic_compare_exchange_strong(&s.cas16, old, old + 1); ok {
					break
				}
			}
			for {
				old := intrinsics.atomic_load(&s.cas64)
				if _, ok := intrinsics.atomic_compare_exchange_weak(&s.cas64, old, old + 1); ok {
					break
				}
			}
		}
	}

	threads: [ATOMIC_THREADS]^thread.Thread
	for k in 0..<ATOMIC_THREADS {
		threads[k] = thread.create_and_start_with_poly_data2(k, &state, worker)
	}
	intrinsics.atomic_store_explicit(&state.start, true, .Release)
	thread.join_multiple(..threads[:])
	for th in threads {
		thread.destroy(th)
	}

	TOTAL :: ATOMIC_THREADS * ATOMIC_ITERATIONS
	for k in 0..<ATOMIC_THREADS {
		testing.expectf(t, state.bytes[k] == u8(ATOMIC_ITERATIONS % 256), "bytes[%v] = %v", k, state.bytes[k])
		testing.expectf(t, state.bytes[k + ATOMIC_THREADS] == u8(3 * ATOMIC_ITERATIONS % 256), "bytes[%v] = %v", k + ATOMIC_THREADS, state.bytes[k + ATOMIC_THREADS])
		testing.expectf(t, state.halves[k] == u16(ATOMIC_ITERATIONS), "halves[%v] = %v", k, state.halves[k])
		testing.expectf(t, state.words[k] == ~u32(0) - ATOMIC_ITERATIONS + 1, "words[%v] = %v", k, state.words[k])
	}
	testing.expect_value(t, state.add8, u8(TOTAL % 256))
	testing.expect_value(t, state.add16, u16(TOTAL))
	testing.expect_value(t, state.add32, u32(TOTAL))
	testing.expect_value(t, state.add64, u64(TOTAL))
	testing.expect_value(t, state.sub8, i8(-(TOTAL % 256)))
	testing.expect_value(t, state.sub16, i16(-TOTAL))
	testing.expect_value(t, state.cas8, u8(TOTAL % 256))
	testing.expect_value(t, state.cas16, u16(TOTAL))
	testing.expect_value(t, state.cas64, u64(TOTAL))
	testing.expect_value(t, state.xor8, u8(0))
	testing.expect_value(t, state.or16, u16(0x2222))
	testing.expect_value(t, state.and16, u16(0xbbbb))
}

@(test)
atomics_fetch_results :: proc(t: ^testing.T) {
	check :: proc(t: ^testing.T, $T: typeid) {
		values := [?]T{0, 1, 0x5a, max(T), min(T), max(T) / 3}
		v := new(T)
		defer free(v)
		for x in values {
			for y in values {
				v^ = x
				testing.expect_value(t, intrinsics.atomic_add(v, y), x)
				testing.expect_value(t, v^, x + y)
				v^ = x
				testing.expect_value(t, intrinsics.atomic_sub(v, y), x)
				testing.expect_value(t, v^, x - y)
				v^ = x
				testing.expect_value(t, intrinsics.atomic_and(v, y), x)
				testing.expect_value(t, v^, x & y)
				v^ = x
				testing.expect_value(t, intrinsics.atomic_nand(v, y), x)
				testing.expect_value(t, v^, ~(x & y))
				v^ = x
				testing.expect_value(t, intrinsics.atomic_or(v, y), x)
				testing.expect_value(t, v^, x | y)
				v^ = x
				testing.expect_value(t, intrinsics.atomic_xor(v, y), x)
				testing.expect_value(t, v^, x ~ y)
				v^ = x
				testing.expect_value(t, intrinsics.atomic_exchange(v, y), x)
				testing.expect_value(t, v^, y)
				v^ = x
				old, ok := intrinsics.atomic_compare_exchange_strong(v, y, x ~ y)
				testing.expect_value(t, old, x)
				testing.expect_value(t, ok, x == y)
				testing.expect_value(t, v^, x ~ y if x == y else x)
			}
		}
	}
	check(t, u8)
	check(t, i8)
	check(t, u16)
	check(t, i16)
	check(t, u32)
	check(t, i32)
	check(t, u64)
	check(t, i64)
}
