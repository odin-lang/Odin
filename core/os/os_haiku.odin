package os

foreign import libc "system:c"

import "core:strings"
import "core:c"
import "base:runtime"

Handle    :: distinct i32
Pid       :: distinct i32
File_Time :: distinct i64
Errno     :: distinct i32

B_GENERAL_ERROR_BASE :: min(i32)
B_POSIX_ERROR_BASE   :: B_GENERAL_ERROR_BASE + 0x7000

INVALID_HANDLE :: ~Handle(0)

ERROR_NONE:	Errno: 0

