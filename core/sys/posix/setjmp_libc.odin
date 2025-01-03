#+build windows, linux, darwin, netbsd, openbsd, freebsd
package posix

import "core:c/libc"

// setjmp.h - stack environment declarations

jmp_buf :: libc.jmp_buf

longjmp :: libc.longjmp
setjmp  :: libc.setjmp
