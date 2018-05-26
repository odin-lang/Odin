package atomics

// TODO(bill): Use assembly instead here to implement atomics
// Inline vs external file?

import "core:sys/win32"


yield_thread :: proc() { win32.mm_pause(); }
mfence       :: proc() { win32.read_write_barrier(); }
sfence       :: proc() { win32.write_barrier(); }
lfence       :: proc() { win32.read_barrier(); }


load_i32 :: proc(a: ^i32) -> i32 {
	return a^;
}
store_i32 :: proc(a: ^i32, value: i32) {
	a^ = value;
}
compare_exchange_i32 :: proc(a: ^i32, expected, desired: i32) -> i32 {
	return win32.interlocked_compare_exchange(a, desired, expected);
}
exchanged_i32 :: proc(a: ^i32, desired: i32) -> i32 {
	return win32.interlocked_exchange(a, desired);
}
fetch_add_i32 :: proc(a: ^i32, operand: i32) -> i32 {
	return win32.interlocked_exchange_add(a, operand);

}
fetch_and_i32 :: proc(a: ^i32, operand: i32) -> i32 {
	return win32.interlocked_and(a, operand);
}
fetch_or_i32 :: proc(a: ^i32, operand: i32) -> i32 {
	return win32.interlocked_or(a, operand);
}
spin_lock_i32 :: proc(a: ^i32, time_out: int) -> bool { // NOTE(bill) time_out = -1 as default
	old_value := compare_exchange_i32(a, 1, 0);
	counter := 0;
	for old_value != 0 && (time_out < 0 || counter < time_out) {
		counter += 1;
		yield_thread();
		old_value = compare_exchange_i32(a, 1, 0);
		mfence();
	}
	return old_value == 0;
}
spin_unlock_i32 :: proc(a: ^i32) {
	store_i32(a, 0);
	mfence();
}
try_acquire_lock_i32 :: proc(a: ^i32) -> bool {
	yield_thread();
	old_value := compare_exchange_i32(a, 1, 0);
	mfence();
	return old_value == 0;
}


load_i64 :: proc(a: ^i64) -> i64 {
	return a^;
}
store_i64 :: proc(a: ^i64, value: i64) {
	a^ = value;
}
compare_exchange_i64 :: proc(a: ^i64, expected, desired: i64) -> i64 {
	return win32.interlocked_compare_exchange64(a, desired, expected);
}
exchanged_i64 :: proc(a: ^i64, desired: i64) -> i64 {
	return win32.interlocked_exchange64(a, desired);
}
fetch_add_i64 :: proc(a: ^i64, operand: i64) -> i64 {
	return win32.interlocked_exchange_add64(a, operand);
}
fetch_and_i64 :: proc(a: ^i64, operand: i64) -> i64 {
	return win32.interlocked_and64(a, operand);
}
fetch_or_i64 :: proc(a: ^i64, operand: i64) -> i64 {
	return win32.interlocked_or64(a, operand);
}
spin_lock_i64 :: proc(a: ^i64, time_out: int) -> bool { // NOTE(bill) time_out = -1 as default
	old_value := compare_exchange_i64(a, 1, 0);
	counter := 0;
	for old_value != 0 && (time_out < 0 || counter < time_out) {
		counter += 1;
		yield_thread();
		old_value = compare_exchange_i64(a, 1, 0);
		mfence();
	}
	return old_value == 0;
}
spin_unlock_i64 :: proc(a: ^i64) {
	store_i64(a, 0);
	mfence();
}
try_acquire_lock_i64 :: proc(a: ^i64) -> bool {
	yield_thread();
	old_value := compare_exchange_i64(a, 1, 0);
	mfence();
	return old_value == 0;
}
