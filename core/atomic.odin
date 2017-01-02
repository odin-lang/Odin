// TODO(bill): Use assembly instead here to implement atomics
// Inline vs external file?

#import win32 "sys/windows.odin" when ODIN_OS == "windows";
_ := compile_assert(ODIN_ARCH == "amd64"); // TODO(bill): x86 version


yield_thread :: proc() { win32._mm_pause(); }
mfence       :: proc() { win32.ReadWriteBarrier(); }
sfence       :: proc() { win32.WriteBarrier(); }
lfence       :: proc() { win32.ReadBarrier(); }


load32 :: proc(a: ^i32) -> i32 {
	return a^;
}
store32 :: proc(a: ^i32, value: i32) {
	a^ = value;
}
compare_exchange32 :: proc(a: ^i32, expected, desired: i32) -> i32 {
	return win32.InterlockedCompareExchange(a, desired, expected);
}
exchanged32 :: proc(a: ^i32, desired: i32) -> i32 {
	return win32.InterlockedExchange(a, desired);
}
fetch_add32 :: proc(a: ^i32, operand: i32) -> i32 {
	return win32.InterlockedExchangeAdd(a, operand);

}
fetch_and32 :: proc(a: ^i32, operand: i32) -> i32 {
	return win32.InterlockedAnd(a, operand);

}
fetch_or32 :: proc(a: ^i32, operand: i32) -> i32 {
	return win32.InterlockedOr(a, operand);
}
spin_lock32 :: proc(a: ^i32, time_out: int) -> bool { // NOTE(bill) time_out = -1 as default
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
spin_unlock32 :: proc(a: ^i32) {
	store32(a, 0);
	mfence();
}
try_acquire_lock32 :: proc(a: ^i32) -> bool {
	yield_thread();
	old_value := compare_exchange32(a, 1, 0);
	mfence();
	return old_value == 0;
}


load64 :: proc(a: ^i64) -> i64 {
	return a^;
}
store64 :: proc(a: ^i64, value: i64) {
	a^ = value;
}
compare_exchange64 :: proc(a: ^i64, expected, desired: i64) -> i64 {
	return win32.InterlockedCompareExchange64(a, desired, expected);
}
exchanged64 :: proc(a: ^i64, desired: i64) -> i64 {
	return win32.InterlockedExchange64(a, desired);
}
fetch_add64 :: proc(a: ^i64, operand: i64) -> i64 {
	return win32.InterlockedExchangeAdd64(a, operand);
}
fetch_and64 :: proc(a: ^i64, operand: i64) -> i64 {
	return win32.InterlockedAnd64(a, operand);
}
fetch_or64 :: proc(a: ^i64, operand: i64) -> i64 {
	return win32.InterlockedOr64(a, operand);
}
spin_lock64 :: proc(a: ^i64, time_out: int) -> bool { // NOTE(bill) time_out = -1 as default
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
spin_unlock64 :: proc(a: ^i64) {
	store64(a, 0);
	mfence();
}
try_acquire_lock64 :: proc(a: ^i64) -> bool {
	yield_thread();
	old_value := compare_exchange64(a, 1, 0);
	mfence();
	return old_value == 0;
}
