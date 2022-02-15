package miniaudio

import c "core:c/libc"

when ODIN_OS == .Windows { foreign import lib "lib/miniaudio.lib" }
when ODIN_OS == .Linux   { foreign import lib "lib/miniaudio.a" }

MAX_LOG_CALLBACKS :: 4

log_callback_proc :: proc "c" (pUserData: rawptr, level: u32, pMessage: cstring)

log_callback :: struct {
	onLog:     log_callback_proc,
	pUserData: rawptr,
}

log :: struct {
	callbacks:           [MAX_LOG_CALLBACKS]log_callback,
	callbackCount:       u32,
	allocationCallbacks: allocation_callbacks,    /* Need to store these persistently because log_postv() might need to allocate a buffer on the heap. */
	lock:                (struct {} when NO_THREADING else mutex),
}

@(default_calling_convention="c", link_prefix="ma_")
foreign lib {
	log_callback_init :: proc(onLog: log_callback_proc, pUserData: rawptr) -> log_callback ---
	
	log_init                :: proc(pAllocationCallbacks: ^allocation_callbacks, pLog: ^log) -> result ---
	log_uninit              :: proc(pLog: ^log) ---
	log_register_callback   :: proc(pLog: ^log, callback: log_callback) -> result ---
	log_unregister_callback :: proc(pLog: ^log, callback: log_callback) -> result ---
	log_post                :: proc(pLog: ^log, level: u32, pMessage: cstring) -> result ---
	log_postv               :: proc(pLog: ^log, level: u32, pFormat: cstring, args: c.va_list) -> result ---
	log_postf               :: proc(pLog: ^log, level: u32, pFormat: cstring, #c_vararg args: ..any) -> result ---
}