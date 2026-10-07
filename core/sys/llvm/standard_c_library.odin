// Standard C Library Intrinsics

package sys_llvm

@(default_calling_convention="none")
foreign _ {
	when size_of(int) == 4 {
		@(link_name="llvm.memcpy.p0.p0.i32")
		memcpy :: proc(dst, src: rawptr, len: int, #const is_volatile: bool = false) ---

		@(link_name="llvm.memcpy.inline.p0.p0.i32")
		memcpy_inline :: proc(dst, src: rawptr, len: int, #const is_volatile: bool = false) ---

		@(link_name="llvm.memmove.p0.p0.i32")
		memmove :: proc(dst, src: rawptr, len: int, #const is_volatile: bool = false) ---

		@(link_name="llvm.memset.p0.i32")
		memset :: proc(dst: rawptr, val: byte, len: int, #const is_volatile: bool = false) ---

		@(link_name="llvm.memset.inline.p0.i32")
		memset_inline :: proc(dst: rawptr, val: byte, len: int, #const is_volatile: bool = false) ---
	} else {
		@(link_name="llvm.memcpy.p0.p0.i64")
		memcpy :: proc(dst, src: rawptr, len: int, #const is_volatile: bool = false) ---

		@(link_name="llvm.memcpy.inline.p0.p0.i64")
		memcpy_inline :: proc(dst, src: rawptr, len: int, #const is_volatile: bool = false) ---

		@(link_name="llvm.memmove.p0.p0.i64")
		memmove :: proc(dst, src: rawptr, len: int, #const is_volatile: bool = false) ---

		@(link_name="llvm.memset.p0.i64")
		memset :: proc(dst: rawptr, val: byte, len: int, #const is_volatile: bool = false) ---

		@(link_name="llvm.memset.inline.p0.i64")
		memset_inline :: proc(dst: rawptr, val: byte, len: int, #const is_volatile: bool = false) ---
	}
}


@(default_calling_convention="none")
foreign _ {
	@(link_name="llvm.sqrt.f32")
	sqrt_f32 :: proc(f32) -> f32 ---
	@(link_name="llvm.sqrt.f64")
	sqrt_f64 :: proc(f64) -> f64 ---

	@(link_name="llvm.powi.f32.i32")
	powi_f32 :: proc(val: f32, power: i32) -> f32 ---
	@(link_name="llvm.powi.f64.i32")
	powi_f64 :: proc(val: f64, power: i32) -> f64 ---

	@(link_name="llvm.sin.f32")
	sin_f32 :: proc(f32) -> f32 ---
	@(link_name="llvm.sin.f64")
	sin_f64 :: proc(f64) -> f64 ---

	@(link_name="llvm.cos.f32")
	cos_f32 :: proc(f32) -> f32 ---
	@(link_name="llvm.cos.f64")
	cos_f64 :: proc(f64) -> f64 ---

	// LLVM 19+
	@(link_name="llvm.tan.f32")
	tan_f32 :: proc(f32) -> f32 ---
	@(link_name="llvm.tan.f64")
	tan_f64 :: proc(f64) -> f64 ---

	// LLVM 19+
	@(link_name="llvm.asin.f32")
	asin_f32 :: proc(f32) -> f32 ---
	@(link_name="llvm.asin.f64")
	asin_f64 :: proc(f64) -> f64 ---

	// LLVM 19+
	@(link_name="llvm.acos.f32")
	acos_f32 :: proc(f32) -> f32 ---
	@(link_name="llvm.acos.f64")
	acos_f64 :: proc(f64) -> f64 ---

	// LLVM 19+
	@(link_name="llvm.atan.f32")
	atan_f32 :: proc(f32) -> f32 ---
	@(link_name="llvm.atan.f64")
	atan_f64 :: proc(f64) -> f64 ---

	// LLVM 20+
	@(link_name="llvm.atan2.f32")
	atan2_f32 :: proc(y, x: f32) -> f32 ---
	@(link_name="llvm.atan2.f64")
	atan2_f64 :: proc(y, x: f64) -> f64 ---

	// LLVM 19+
	@(link_name="llvm.sinh.f32")
	sinh_f32 :: proc(f32) -> f32 ---
	@(link_name="llvm.sinh.f64")
	sinh_f64 :: proc(f64) -> f64 ---

	// LLVM 19+
	@(link_name="llvm.cosh.f32")
	cosh_f32 :: proc(f32) -> f32 ---
	@(link_name="llvm.cosh.f64")
	cosh_f64 :: proc(f64) -> f64 ---

	// LLVM 19+
	@(link_name="llvm.tanh.f32")
	tanh_f32 :: proc(f32) -> f32 ---
	@(link_name="llvm.tanh.f64")
	tanh_f64 :: proc(f64) -> f64 ---

	// LLVM 20+
	@(link_name="llvm.sincos.f32")
	sincos_f32 :: proc(f32) -> (sin, cos: f32) ---
	@(link_name="llvm.sincos.f64")
	sincos_f64 :: proc(f64) -> (sin, cos: f64) ---

	@(link_name="llvm.pow.f32")
	pow_f32 :: proc(val, power: f32) -> f32 ---
	@(link_name="llvm.pow.f64")
	pow_f64 :: proc(val, power: f64) -> f64 ---

	@(link_name="llvm.exp.f32")
	exp_f32 :: proc(f32) -> f32 ---
	@(link_name="llvm.exp.f64")
	exp_f64 :: proc(f64) -> f64 ---

	@(link_name="llvm.exp2.f32")
	exp2_f32 :: proc(f32) -> f32 ---
	@(link_name="llvm.exp2.f64")
	exp2_f64 :: proc(f64) -> f64 ---

	// LLVM 18+, calls `exp10` from the C library, which Windows does not have
	@(link_name="llvm.exp10.f32")
	exp10_f32 :: proc(f32) -> f32 ---
	@(link_name="llvm.exp10.f64")
	exp10_f64 :: proc(f64) -> f64 ---

	@(link_name="llvm.ldexp.f32.i32")
	ldexp_f32 :: proc(val: f32, exp: i32) -> f32 ---
	@(link_name="llvm.ldexp.f64.i32")
	ldexp_f64 :: proc(val: f64, exp: i32) -> f64 ---

	@(link_name="llvm.frexp.f32.i32")
	frexp_f32 :: proc(val: f32) -> (fraction: f32, exp: i32) ---
	@(link_name="llvm.frexp.f64.i32")
	frexp_f64 :: proc(val: f64) -> (fraction: f64, exp: i32) ---

	@(link_name="llvm.log.f32")
	log_f32 :: proc(f32) -> f32 ---
	@(link_name="llvm.log.f64")
	log_f64 :: proc(f64) -> f64 ---

	@(link_name="llvm.log10.f32")
	log10_f32 :: proc(f32) -> f32 ---
	@(link_name="llvm.log10.f64")
	log10_f64 :: proc(f64) -> f64 ---

	@(link_name="llvm.log2.f32")
	log2_f32 :: proc(f32) -> f32 ---
	@(link_name="llvm.log2.f64")
	log2_f64 :: proc(f64) -> f64 ---

	@(link_name="llvm.fma.f32")
	fma_f32 :: proc(a, b, c: f32) -> f32 ---
	@(link_name="llvm.fma.f64")
	fma_f64 :: proc(a, b, c: f64) -> f64 ---

	@(link_name="llvm.fabs.f32")
	fabs_f32 :: proc(f32) -> f32 ---
	@(link_name="llvm.fabs.f64")
	fabs_f64 :: proc(f64) -> f64 ---

	@(link_name="llvm.minnum.f32")
	min_num_f32 :: proc(val0, val1: f32) -> f32 ---
	@(link_name="llvm.minnum.f64")
	min_num_f64 :: proc(val0, val1: f64) -> f64 ---

	@(link_name="llvm.maxnum.f32")
	max_num_f32 :: proc(val0, val1: f32) -> f32 ---
	@(link_name="llvm.maxnum.f64")
	max_num_f64 :: proc(val0, val1: f64) -> f64 ---

	@(link_name="llvm.minimum.f32")
	minimum_f32 :: proc(val0, val1: f32) -> f32 ---
	@(link_name="llvm.minimum.f64")
	minimum_f64 :: proc(val0, val1: f64) -> f64 ---

	@(link_name="llvm.maximum.f32")
	maximum_f32 :: proc(val0, val1: f32) -> f32 ---
	@(link_name="llvm.maximum.f64")
	maximum_f64 :: proc(val0, val1: f64) -> f64 ---

	// LLVM 20+, whose x86 code at -o:none and -o:minimal can return a NaN operand when the other is a constant
	@(link_name="llvm.minimumnum.f32")
	minimum_num_f32 :: proc(val0, val1: f32) -> f32 ---
	@(link_name="llvm.minimumnum.f64")
	minimum_num_f64 :: proc(val0, val1: f64) -> f64 ---

	// LLVM 20+, whose x86 code at -o:none and -o:minimal can return a NaN operand when the other is a constant
	@(link_name="llvm.maximumnum.f32")
	maximum_num_f32 :: proc(val0, val1: f32) -> f32 ---
	@(link_name="llvm.maximumnum.f64")
	maximum_num_f64 :: proc(val0, val1: f64) -> f64 ---

	@(link_name="llvm.copysign.f32")
	copy_sign_f32 :: proc(mag, sgn: f32) -> f32 ---
	@(link_name="llvm.copysign.f64")
	copy_sign_f64 :: proc(mag, sgn: f64) -> f64 ---

	@(link_name="llvm.floor.f32")
	floor_f32 :: proc(f32) -> f32 ---
	@(link_name="llvm.floor.f64")
	floor_f64 :: proc(f64) -> f64 ---

	@(link_name="llvm.ceil.f32")
	ceil_f32 :: proc(f32) -> f32 ---
	@(link_name="llvm.ceil.f64")
	ceil_f64 :: proc(f64) -> f64 ---

	@(link_name="llvm.trunc.f32")
	trunc_f32 :: proc(f32) -> f32 ---
	@(link_name="llvm.trunc.f64")
	trunc_f64 :: proc(f64) -> f64 ---

	@(link_name="llvm.rint.f32")
	rint_f32 :: proc(f32) -> f32 ---
	@(link_name="llvm.rint.f64")
	rint_f64 :: proc(f64) -> f64 ---

	@(link_name="llvm.nearbyint.f32")
	nearby_int_f32 :: proc(f32) -> f32 ---
	@(link_name="llvm.nearbyint.f64")
	nearby_int_f64 :: proc(f64) -> f64 ---

	@(link_name="llvm.round.f32")
	round_f32 :: proc(f32) -> f32 ---
	@(link_name="llvm.round.f64")
	round_f64 :: proc(f64) -> f64 ---

	@(link_name="llvm.roundeven.f32")
	round_even_f32 :: proc(f32) -> f32 ---
	@(link_name="llvm.roundeven.f64")
	round_even_f64 :: proc(f64) -> f64 ---


	@(link_name="llvm.lround.i32.f32")
	lround_f32_i32 :: proc(f32) -> i32 ---
	@(link_name="llvm.lround.i32.f64")
	lround_f64_i32 :: proc(f64) -> i32 ---

	@(link_name="llvm.lround.i64.f32")
	lround_f32_i64 :: proc(f32) -> i64 ---
	@(link_name="llvm.lround.i64.f64")
	lround_f64_i64 :: proc(f64) -> i64 ---

	@(link_name="llvm.llround.i64.f32")
	llround_f32_i64 :: proc(f32) -> i64 ---
	@(link_name="llvm.llround.i64.f64")
	llround_f64_i64 :: proc(f64) -> i64 ---


	@(link_name="llvm.lrint.i32.f32")
	lrint_f32_i32 :: proc(f32) -> i32 ---
	@(link_name="llvm.lrint.i32.f64")
	lrint_f64_i32 :: proc(f64) -> i32 ---

	@(link_name="llvm.lrint.i64.f32")
	lrint_f32_i64 :: proc(f32) -> i64 ---
	@(link_name="llvm.lrint.i64.f64")
	lrint_f64_i64 :: proc(f64) -> i64 ---

	@(link_name="llvm.llrint.i64.f32")
	llrint_f32_i64 :: proc(f32) -> i64 ---
	@(link_name="llvm.llrint.i64.f64")
	llrint_f64_i64 :: proc(f64) -> i64 ---
}
