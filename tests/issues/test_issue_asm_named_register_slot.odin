#+build amd64
// A slot that only a named hardware register can fill (segment/control/debug/x87/MMX)
// carries no width and no register class, so it used to absorb any operand at all and
// hand the backend an instruction that does not encode.
package test_issues

// Rejected: none of these widths pair up, and only `mov`'s segment-register forms ever
// admitted them.
bad_64_32 :: asm(a: i64) -> (r: i32) { mov r, a; }
bad_8_16  :: asm(a: u8)  -> (r: u16) { mov r, a; }
bad_16_8  :: asm(a: u16) -> (r: u8)  { mov r, a; }
bad_64_8  :: asm(a: u64) -> (r: u8)  { mov r, a; }

// Accepted: equal widths, regardless of signedness or pointer spelling.
ok_32   :: asm(a: i32)    -> (r: u32)    { mov r, a; }
ok_64   :: asm(a: u64)    -> (r: i64)    { mov r, a; }
ok_ptr  :: asm(a: rawptr) -> (r: ^i32)   { mov r, a; }

// Accepted: the named registers those forms are actually for.
ok_seg  :: asm(a: u64) -> (r: u64) { mov %ds,  a; mov r, a; }
ok_ctrl :: asm(a: u64) -> (r: u64) { mov %cr0, a; mov r, a; }
ok_dbg  :: asm(a: u64) -> (r: u64) { mov %dr0, a; mov r, a; }

use :: proc() {
	a8:  u8
	a16: u16
	a32: i32
	a64: i64
	au64: u64
	ap:  rawptr
	_ = bad_64_32(a64)
	_ = bad_8_16(a8)
	_ = bad_16_8(a16)
	_ = bad_64_8(au64)
	_ = ok_32(a32)
	_ = ok_64(au64)
	_ = ok_ptr(ap)
	_ = ok_seg(au64)
	_ = ok_ctrl(au64)
	_ = ok_dbg(au64)
}
