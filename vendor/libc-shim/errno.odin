package odin_libc

import "core:c"

EBADF  :: 9
EILSEQ :: 84

@(private)
_errno: c.int

@(require, linkage="strong", link_name="__errno_location")
__errno_location :: proc "c" () -> ^c.int {
	return &_errno
}
