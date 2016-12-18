// TODO(bill): Use assembly instead here to implement atomics
// Inline vs external file?

#import win32 "sys/windows.odin" when ODIN_OS == "windows";
_ := compile_assert(ODIN_ARCH == "amd64"); // TODO(bill): x86 version


proc yield_thread() { win32._mm_pause(); }
proc mfence      () { win32.ReadWriteBarrier(); }
proc sfence      () { win32.WriteBarrier(); }
proc lfence      () { win32.ReadBarrier(); }


proc load32(a ^i32) -> i32 {
	return a^;
}
proc store32(a ^i32, value i32) {
	a^ = value;
}
proc compare_exchange32(a ^i32, expected, desired i32) -> i32 {
	return win32.InterlockedCompareExchange(a, desired, expected);
}
proc exchanged32(a ^i32, desired i32) -> i32 {
	return win32.InterlockedExchange(a, desired);
}
proc fetch_add32(a ^i32, operand i32) -> i32 {
	return win32.InterlockedExchangeAdd(a, operand);

}
proc fetch_and32(a ^i32, operand i32) -> i32 {
	return win32.InterlockedAnd(a, operand);

}
proc fetch_or32(a ^i32, operand i32) -> i32 {
	return win32.InterlockedOr(a, operand);
}
proc spin_lock32(a ^i32, time_out int) -> bool { // NOTE(bill) time_out = -1 as default
	old_value := compare_exchange32(a, 1, 0);
	counter := 0;
	for old_value != 0 && (time_out < 0 || counter < time_out) {
		counter++;
		yield_thread();
		old_value = compare_exchange32(a, 1, 0);
		mfence();
	}
	return old_value == 0;
}
proc spin_unlock32(a ^i32) {
	store32(a, 0);
	mfence();
}
proc try_acquire_lock32(a ^i32) -> bool {
	yield_thread();
	old_value := compare_exchange32(a, 1, 0);
	mfence();
	return old_value == 0;
}


proc load64(a ^i64) -> i64 {
	return a^;
}
proc store64(a ^i64, value i64) {
	a^ = value;
}
proc compare_exchange64(a ^i64, expected, desired i64) -> i64 {
	return win32.InterlockedCompareExchange64(a, desired, expected);
}
proc exchanged64(a ^i64, desired i64) -> i64 {
	return win32.InterlockedExchange64(a, desired);
}
proc fetch_add64(a ^i64, operand i64) -> i64 {
	return win32.InterlockedExchangeAdd64(a, operand);
}
proc fetch_and64(a ^i64, operand i64) -> i64 {
	return win32.InterlockedAnd64(a, operand);
}
proc fetch_or64(a ^i64, operand i64) -> i64 {
	return win32.InterlockedOr64(a, operand);
}
proc spin_lock64(a ^i64, time_out int) -> bool { // NOTE(bill) time_out = -1 as default
	old_value := compare_exchange64(a, 1, 0);
	counter := 0;
	for old_value != 0 && (time_out < 0 || counter < time_out) {
		counter++;
		yield_thread();
		old_value = compare_exchange64(a, 1, 0);
		mfence();
	}
	return old_value == 0;
}
proc spin_unlock64(a ^i64) {
	store64(a, 0);
	mfence();
}
proc try_acquire_lock64(a ^i64) -> bool {
	yield_thread();
	old_value := compare_exchange64(a, 1, 0);
	mfence();
	return old_value == 0;
}
