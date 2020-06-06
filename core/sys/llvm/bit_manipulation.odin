// Bit Manipulation Intrinsics
package sys_llvm

/*
@(default_calling_convention="none")
foreign _ {
	@(link_name="llvm.bitreverse.i8")
	bit_reverse_u8 :: proc(u8) -> u8 ---
	@(link_name="llvm.bitreverse.i16")
	bit_reverse_u16 :: proc(u16) -> u16 ---
	@(link_name="llvm.bitreverse.i32")
	bit_reverse_u32 :: proc(u32) -> u32 ---
	@(link_name="llvm.bitreverse.i64")
	bit_reverse_u64 :: proc(u64) -> u64 ---
	@(link_name="llvm.bitreverse.i128")
	bit_reverse_u128 :: proc(u128) -> u128 ---

	@(link_name="llvm.bswap.i16")
	bswap_u16 :: proc(u16) -> u16 ---
	@(link_name="llvm.bswap.i32")
	bswap_u32 :: proc(u32) -> u32 ---
	@(link_name="llvm.bswap.i64")
	bswap_u64 :: proc(u64) -> u64 ---
	@(link_name="llvm.bswap.i128")
	bswap_u128 :: proc(u128) -> u128 ---

	@(link_name="llvm.ctpop.i8")
	ctpop_u8 :: proc(u8) -> u8 ---
	@(link_name="llvm.ctpop.i16")
	ctpop_u16 :: proc(u16) -> u16 ---
	@(link_name="llvm.ctpop.i32")
	ctpop_u32 :: proc(u32) -> u32 ---
	@(link_name="llvm.ctpop.i64")
	ctpop_u64 :: proc(u64) -> u64 ---
	@(link_name="llvm.ctpop.i128")
	ctpop_u128 :: proc(u128) -> u128 ---

	@(link_name="llvm.ctlz.i8")
	ctlz_u8 :: proc(u8) -> u8 ---
	@(link_name="llvm.ctlz.i16")
	ctlz_u16 :: proc(u16) -> u16 ---
	@(link_name="llvm.ctlz.i32")
	ctlz_u32 :: proc(u32) -> u32 ---
	@(link_name="llvm.ctlz.i64")
	ctlz_u64 :: proc(u64) -> u64 ---
	@(link_name="llvm.ctlz.i128")
	ctlz_u128 :: proc(u128) -> u128 ---

	@(link_name="llvm.cttz.i8")
	cttz_u8 :: proc(u8) -> u8 ---
	@(link_name="llvm.cttz.i16")
	cttz_u16 :: proc(u16) -> u16 ---
	@(link_name="llvm.cttz.i32")
	cttz_u32 :: proc(u32) -> u32 ---
	@(link_name="llvm.cttz.i64")
	cttz_u64 :: proc(u64) -> u64 ---
	@(link_name="llvm.cttz.i128")
	cttz_u128 :: proc(u128) -> u128 ---


	@(link_name="llvm.fshl.i8")
	fshl_u8 :: proc(a, b, c: u8) -> u8 ---
	@(link_name="llvm.fshl.i16")
	fshl_u16 :: proc(a, b, c: u16) -> u16 ---
	@(link_name="llvm.fshl.i32")
	fshl_u32 :: proc(a, b, c: u32) -> u32 ---
	@(link_name="llvm.fshl.i64")
	fshl_u64 :: proc(a, b, c: u64) -> u64 ---
	@(link_name="llvm.fshl.i128")
	fshl_u128 :: proc(a, b, c: u128) -> u128 ---

	@(link_name="llvm.fshr.i8")
	fshr_u8 :: proc(a, b, c: u8) -> u8 ---
	@(link_name="llvm.fshr.i16")
	fshr_u16 :: proc(a, b, c: u16) -> u16 ---
	@(link_name="llvm.fshr.i32")
	fshr_u32 :: proc(a, b, c: u32) -> u32 ---
	@(link_name="llvm.fshr.i64")
	fshr_u64 :: proc(a, b, c: u64) -> u64 ---
	@(link_name="llvm.fshr.i128")
	fshr_u128 :: proc(a, b, c: u128) -> u128 ---
}
*/
