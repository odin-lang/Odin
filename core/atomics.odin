// TODO(bill): Use assembly instead here to implement atomics
// Inline vs external file?

#import win32 "sys/windows.odin" when ODIN_OS == "windows";
var _ = compile_assert(ODIN_ARCH == "amd64"); // TODO(bill): x86 version


const yield_thread = proc() { win32.mm_pause(); }
const mfence       = proc() { win32.read_write_barrier(); }
const sfence       = proc() { win32.write_barrier(); }
const lfence       = proc() { win32.read_barrier(); }


const load = proc(a: ^i32) -> i32 {
	return a^;
}
const store = proc(a: ^i32, value: i32) {
	a^ = value;
}
const compare_exchange = proc(a: ^i32, expected, desired: i32) -> i32 {
	return win32.interlocked_compare_exchange(a, desired, expected);
}
const exchanged = proc(a: ^i32, desired: i32) -> i32 {
	return win32.interlocked_exchange(a, desired);
}
const fetch_add = proc(a: ^i32, operand: i32) -> i32 {
	return win32.interlocked_exchange_add(a, operand);

}
const fetch_and = proc(a: ^i32, operand: i32) -> i32 {
	return win32.interlocked_and(a, operand);
}
const fetch_or = proc(a: ^i32, operand: i32) -> i32 {
	return win32.interlocked_or(a, operand);
}
const spin_lock = proc(a: ^i32, time_out: int) -> bool { // NOTE(bill) time_out = -1 as default
	var old_value = compare_exchange(a, 1, 0);
	var counter = 0;
	for old_value != 0 && (time_out < 0 || counter < time_out) {
		counter++;
		yield_thread();
		old_value = compare_exchange(a, 1, 0);
		mfence();
	}
	return old_value == 0;
}
const spin_unlock = proc(a: ^i32) {
	store(a, 0);
	mfence();
}
const try_acquire_lock = proc(a: ^i32) -> bool {
	yield_thread();
	var old_value = compare_exchange(a, 1, 0);
	mfence();
	return old_value == 0;
}


const load = proc(a: ^i64) -> i64 {
	return a^;
}
const store = proc(a: ^i64, value: i64) {
	a^ = value;
}
const compare_exchange = proc(a: ^i64, expected, desired: i64) -> i64 {
	return win32.interlocked_compare_exchange64(a, desired, expected);
}
const exchanged = proc(a: ^i64, desired: i64) -> i64 {
	return win32.interlocked_exchange64(a, desired);
}
const fetch_add = proc(a: ^i64, operand: i64) -> i64 {
	return win32.interlocked_exchange_add64(a, operand);
}
const fetch_and = proc(a: ^i64, operand: i64) -> i64 {
	return win32.interlocked_and64(a, operand);
}
const fetch_or = proc(a: ^i64, operand: i64) -> i64 {
	return win32.interlocked_or64(a, operand);
}
const spin_lock = proc(a: ^i64, time_out: int) -> bool { // NOTE(bill) time_out = -1 as default
	var old_value = compare_exchange(a, 1, 0);
	var counter = 0;
	for old_value != 0 && (time_out < 0 || counter < time_out) {
		counter++;
		yield_thread();
		old_value = compare_exchange(a, 1, 0);
		mfence();
	}
	return old_value == 0;
}
const spin_unlock = proc(a: ^i64) {
	store(a, 0);
	mfence();
}
const try_acquire_lock = proc(a: ^i64) -> bool {
	yield_thread();
	var old_value = compare_exchange(a, 1, 0);
	mfence();
	return old_value == 0;
}
