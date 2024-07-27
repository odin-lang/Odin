package posix

import "base:intrinsics"

import "core:c"

result :: enum c.int {
 	// Use `errno` and `strerror` for more information.
	FAIL = -1,
	// Operation succeeded.
	OK = 0,
}

FD :: distinct c.int

@(private)
log2 :: intrinsics.constant_log2

when ODIN_OS == .Darwin && ODIN_ARCH == .amd64 {
	@(private)
	INODE_SUFFIX :: "$INODE64"
} else {
	@(private)
	INODE_SUFFIX :: ""
}

