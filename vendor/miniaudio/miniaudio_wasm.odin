#+build wasm32, wasm64p32
package miniaudio

import "core:c"

@(require) import _ "vendor:libc-shim"

// Built with MA_NO_THREADING on wasm: these types only appear in declarations that
// are compiled out of the C library (device I/O, threads), so they are placeholders.
thread          :: distinct rawptr
mutex           :: distinct rawptr
event           :: struct { _: rawptr }
semaphore       :: struct { _: rawptr }
thread_priority :: distinct c.int
