// The ABI classifiers ran over the lowered type, where Odin has already turned
// padding into an explicit `[N x i8]` member and a `#raw_union` into an opaque
// integer. SysV contributes no class for padding and merges a union's members, 
// and AAPCS64 counts a union as a Composite Type. So a struct with an `f32` 
// alone in an eightbyte went to an integer register where C uses SSE, and a 
// union of floats never reached a floating-point register at all.
//
// Being an ABI guarantee, must be cross-checked against a c compiler
package test_issues

import "core:testing"

Pad_Int_Float    :: struct { a: i64, b: f32 }  // f32 alone in eightbyte 1
Pad_Float_Double :: struct { a: f32, b: f64 }  // f32 alone in eightbyte 0
No_Pad           :: struct { a: f32, b: f32 }  // fills its eightbyte exactly
Nested           :: struct { a: struct{ x: f32 }, b: f64 }
Union_Float      :: struct #raw_union { x: f32, y: f32 }
Union_In_Struct  :: struct { u: Union_Float, b: f64 }

foreign import lib "build/test_issue_sysv_abi_c.o"

@(default_calling_convention="c")
foreign lib {
	c_pad_int_float    :: proc(s: Pad_Int_Float,    next: f64) -> f64 ---
	c_pad_float_double :: proc(s: Pad_Float_Double, next: f64) -> f64 ---
	c_no_pad           :: proc(s: No_Pad,           next: f64) -> f64 ---
	c_nested           :: proc(s: Nested,           next: f64) -> f64 ---
	c_union_float      :: proc(s: Union_Float,      next: f64) -> f64 ---
	c_union_in_struct  :: proc(s: Union_In_Struct,  next: f64) -> f64 ---

	c_make_pad_int_float :: proc() -> Pad_Int_Float ---
	c_make_union_float   :: proc() -> Union_Float ---
}

// The control. It has no padding and no union, so it was correct before the fix
// and must stay correct. Without it, "padding is misclassified" and "f32 pairs
// are broken" would look the same.
@(test)
test_no_padding_control :: proc(t: ^testing.T) {
	testing.expect_value(t, c_no_pad(No_Pad{1, 3.5}, 7), f64(7))
}

@(test)
test_padded_struct_arguments :: proc(t: ^testing.T) {
	testing.expect_value(t, c_pad_int_float(Pad_Int_Float{1, 3.5}, 7), f64(7))
	testing.expect_value(t, c_pad_float_double(Pad_Float_Double{3.5, 2}, 7), f64(7))
	testing.expect_value(t, c_nested(Nested{{3.5}, 2}, 7), f64(7))
}

@(test)
test_raw_union_arguments :: proc(t: ^testing.T) {
	testing.expect_value(t, c_union_float(Union_Float{x = 3.5}, 7), f64(7))
	testing.expect_value(t, c_union_in_struct(Union_In_Struct{Union_Float{x = 3.5}, 2}, 7), f64(7))
}

@(test)
test_returns :: proc(t: ^testing.T) {
	s := c_make_pad_int_float()
	testing.expect_value(t, s.a, i64(11))
	testing.expect_value(t, s.b, f32(2.5))

	u := c_make_union_float()
	testing.expect_value(t, u.x, f32(2.5))
}
