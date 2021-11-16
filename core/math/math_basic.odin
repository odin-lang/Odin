//+build !js
package math

@(default_calling_convention="none")
foreign _ {
	@(link_name="llvm.sqrt.f16")
	sqrt_f16 :: proc(x: f16) -> f16 ---
	@(link_name="llvm.sqrt.f32")
	sqrt_f32 :: proc(x: f32) -> f32 ---
	@(link_name="llvm.sqrt.f64")
	sqrt_f64 :: proc(x: f64) -> f64 ---

	@(link_name="llvm.sin.f16")
	sin_f16 :: proc(θ: f16) -> f16 ---
	@(link_name="llvm.sin.f32")
	sin_f32 :: proc(θ: f32) -> f32 ---
	@(link_name="llvm.sin.f64")
	sin_f64 :: proc(θ: f64) -> f64 ---

	@(link_name="llvm.cos.f16")
	cos_f16 :: proc(θ: f16) -> f16 ---
	@(link_name="llvm.cos.f32")
	cos_f32 :: proc(θ: f32) -> f32 ---
	@(link_name="llvm.cos.f64")
	cos_f64 :: proc(θ: f64) -> f64 ---

	@(link_name="llvm.pow.f16")
	pow_f16 :: proc(x, power: f16) -> f16 ---
	@(link_name="llvm.pow.f32")
	pow_f32 :: proc(x, power: f32) -> f32 ---
	@(link_name="llvm.pow.f64")
	pow_f64 :: proc(x, power: f64) -> f64 ---

	@(link_name="llvm.fmuladd.f16")
	fmuladd_f16 :: proc(a, b, c: f16) -> f16 ---
	@(link_name="llvm.fmuladd.f32")
	fmuladd_f32 :: proc(a, b, c: f32) -> f32 ---
	@(link_name="llvm.fmuladd.f64")
	fmuladd_f64 :: proc(a, b, c: f64) -> f64 ---

	@(link_name="llvm.log.f16")
	ln_f16 :: proc(x: f16) -> f16 ---
	@(link_name="llvm.log.f32")
	ln_f32 :: proc(x: f32) -> f32 ---
	@(link_name="llvm.log.f64")
	ln_f64 :: proc(x: f64) -> f64 ---

	@(link_name="llvm.exp.f16")
	exp_f16 :: proc(x: f16) -> f16 ---
	@(link_name="llvm.exp.f32")
	exp_f32 :: proc(x: f32) -> f32 ---
	@(link_name="llvm.exp.f64")
	exp_f64 :: proc(x: f64) -> f64 ---
}
