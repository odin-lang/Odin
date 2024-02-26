package miniaudio

import "core:c/libc"

when ODIN_OS == .Windows {
	foreign import lib "lib/miniaudio.lib"
} else {
	foreign import lib "lib/miniaudio.a"
}

MAX_LOG_CALLBACKS :: 4


/*
The callback for handling log messages.


Parameters
----------
pUserData (in)
    The user data pointer that was passed into ma_log_register_callback().

logLevel (in)
    The log level. This can be one of the following:

    +----------------------+
    | Log Level            |
    +----------------------+
    | MA_LOG_LEVEL_DEBUG   |
    | MA_LOG_LEVEL_INFO    |
    | MA_LOG_LEVEL_WARNING |
    | MA_LOG_LEVEL_ERROR   |
    +----------------------+

pMessage (in)
    The log message.
*/
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
	log_postv               :: proc(pLog: ^log, level: u32, pFormat: cstring, args: libc.va_list) -> result ---
	log_postf               :: proc(pLog: ^log, level: u32, pFormat: cstring, #c_vararg args: ..any) -> result ---
}
