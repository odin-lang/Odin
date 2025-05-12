#+private
package runtime

import "base:intrinsics"

foreign import netbsd_asm "virtual_memory_netbsd_arm64.asm"

@(private="file")
c_long :: i32 when size_of(rawptr) == 4 else i64

foreign netbsd_asm {
	__netbsd_sys_mmap :: proc "c" (addr: rawptr, len: uint, prot: i32, flags: i32, fd: i32, PAD: c_long, pos: i64) -> (rawptr, bool) ---
}
