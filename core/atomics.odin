// TODO(bill): Use assembly instead here to implement atomics
// Inline vs external file?

import win32 "sys/windows.odin" when ODIN_OS == "windows";
_ := compile_assert(ODIN_ARCH == "amd64"); // TODO(bill): x86 version


proc yield_thread() { win32.mm_pause(); }
proc mfence      () { win32.read_write_barrier(); }
proc sfence      () { win32.write_barrier(); }
proc lfence      () { win32.read_barrier(); }


proc load(a: ^i32) -> i32 {
	return a^;
}
proc store(a: ^i32, value: i32) {
	a^ = value;
}
proc compare_exchange(a: ^i32, expected, desired: i32) -> i32 {
	return win32.interlocked_compare_exchange(a, desired, expected);
}
proc exchanged(a: ^i32, desired: i32) -> i32 {
	return win32.interlocked_exchange(a, desired);
}
proc fetch_add(a: ^i32, operand: i32) -> i32 {
	return win32.interlocked_exchange_add(a, operand);

}
proc fetch_and(a: ^i32, operand: i32) -> i32 {
	return win32.interlocked_and(a, operand);
}
proc fetch_or(a: ^i32, operand: i32) -> i32 {
	return win32.interlocked_or(a, operand);
}
proc spin_lock(a: ^i32, time_out: int) -> bool { // NOTE(bill) time_out = -1 as default
	old_value := compare_exchange(a, 1, 0);
	counter := 0;
	for old_value != 0 && (time_out < 0 || counter < time_out) {
		counter++;
		yield_thread();
		old_value = compare_exchange(a, 1, 0);
		mfence();
	}
	return old_value == 0;
}
proc spin_unlock(a: ^i32) {
	store(a, 0);
	mfence();
}
proc try_acquire_lock(a: ^i32) -> bool {
	yield_thread();
	old_value := compare_exchange(a, 1, 0);
	mfence();
	return old_value == 0;
}


proc load(a: ^i64) -> i64 {
	return a^;
}
proc store(a: ^i64, value: i64) {
	a^ = value;
}
proc compare_exchange(a: ^i64, expected, desired: i64) -> i64 {
	return win32.interlocked_compare_exchange64(a, desired, expected);
}
proc exchanged(a: ^i64, desired: i64) -> i64 {
	return win32.interlocked_exchange64(a, desired);
}
proc fetch_add(a: ^i64, operand: i64) -> i64 {
	return win32.interlocked_exchange_add64(a, operand);
}
proc fetch_and(a: ^i64, operand: i64) -> i64 {
	return win32.interlocked_and64(a, operand);
}
proc fetch_or(a: ^i64, operand: i64) -> i64 {
	return win32.interlocked_or64(a, operand);
}
proc spin_lock(a: ^i64, time_out: int) -> bool { // NOTE(bill) time_out = -1 as default
	old_value := compare_exchange(a, 1, 0);
	counter := 0;
	for old_value != 0 && (time_out < 0 || counter < time_out) {
		counter++;
		yield_thread();
		old_value = compare_exchange(a, 1, 0);
		mfence();
	}
	return old_value == 0;
}
proc spin_unlock(a: ^i64) {
	store(a, 0);
	mfence();
}
proc try_acquire_lock(a: ^i64) -> bool {
	yield_thread();
	old_value := compare_exchange(a, 1, 0);
	mfence();
	return old_value == 0;
}
