package orca

import "core:c"

THREAD_NAME_MAX_SIZE :: 64  // including null terminator


thread :: struct {}

thread_start_proc :: proc "c" (userPointer: rawptr) -> i32

@(default_calling_convention="c", link_prefix="oc_")
foreign {
	thread_create           :: proc(start: thread_start_proc, userPointer: rawptr) -> ^thread ---
	thread_create_with_name :: proc(start: thread_start_proc, userPointer: rawptr, name: string) -> ^thread ---
	thread_get_name         :: proc(thread: ^thread) -> string ---
	thread_unique_id        :: proc(thread: ^thread) -> u64 ---
	thread_self_id          :: proc() -> u64 ---
	thread_signal           :: proc(thread: ^thread, sig: c.int) -> c.int ---
	thread_join             :: proc(thread: ^thread, exitCode: ^i64) -> c.int ---
	thread_detach           :: proc(thread: ^thread) -> c.int ---
}

//---------------------------------------------------------------
// Platform Mutex API
//---------------------------------------------------------------

mutex :: struct {}

@(default_calling_convention="c", link_prefix="oc_")
foreign {
	mutex_create :: proc() -> ^mutex ---
	mutex_destroy :: proc(mutex: ^mutex) -> c.int ---
	mutex_lock    :: proc(mutex: ^mutex) -> c.int ---
	mutex_unlock  :: proc(mutex: ^mutex) -> c.int ---
}

//---------------------------------------------------------------
// Lightweight ticket mutex API
//---------------------------------------------------------------

ticket :: struct {
	nextTicket: u64, // volatile and atomic
	serving:    u64, // volatile and atomic
}

@(default_calling_convention="c", link_prefix="oc_")
foreign {
	ticket_init   :: proc(mutex: ^ticket) ---
	ticket_lock   :: proc(mutex: ^ticket) ---
	ticket_unlock :: proc(mutex: ^ticket) ---
}

//---------------------------------------------------------------
// Platform condition variable API
//---------------------------------------------------------------

condition :: struct {}

@(default_calling_convention="c", link_prefix="oc_")
foreign {
	condition_create    :: proc() -> ^condition ---
	condition_destroy   :: proc(cond: ^condition) -> c.int ---
	condition_wait      :: proc(cond: ^condition, mutex: ^mutex) -> c.int ---
	condition_timedwait :: proc(cond: ^condition, mutex: ^mutex, seconds: f64) -> c.int ---
	condition_signal    :: proc(cond: ^condition) -> c.int ---
	condition_broadcast :: proc(cond: ^condition) -> c.int ---
}
//---------------------------------------------------------------
// Putting threads to sleep
//---------------------------------------------------------------
@(default_calling_convention="c", link_prefix="oc_")
foreign {
	sleep_nano :: proc(nanoseconds: u64) --- // sleep for a given number of nanoseconds
}