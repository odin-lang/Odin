package test_internal

import "core:testing"

// A union constant must be byte-identical to the same value built at run time,
// whatever the variant.  These unions are not `is_type_union_constantable`, so
// lb_const_value used to skip its union branch for them and lower the value as
// a scalar of the union's LLVM type.

V :: union { bool, f64, ^int }
SP :: struct { p: ^int, n: int }
VI :: union { SP, int }
VE :: enum { A, B }
VES :: union { VE, ^int }
VA :: union { bool, [4]^int }
VAOK :: struct { a: int, b: int }
VC :: union { VAOK, int }

@(private="file")
expect_same_bytes :: proc(t: ^testing.T, constant, variable: $T, what: string) {
	testing.expectf(t,
		transmute([size_of(T)]u8)constant == transmute([size_of(T)]u8)variable,
		"%s: constant %v vs variable %v", what,
		transmute([size_of(T)]u8)constant, transmute([size_of(T)]u8)variable)
}

// typed constant in a procedure body (the report's program)
@(test)
union_typed_constant_local :: proc(t: ^testing.T) {
	{
		c: V : true
		v: V = true
		expect_same_bytes(t, c, v, "bool")
	}
	{
		c: V : f64(1.5)
		v: V = f64(1.5)
		expect_same_bytes(t, c, v, "f64")
	}
	{
		c: V : f64(2)
		v: V = f64(2)
		expect_same_bytes(t, c, v, "f64 from integer literal")
	}
}

// file-scope typed constants and global variables with constant initializers
@(private="file") FC_BOOL: V = true
@(private="file") FC_F64: V = f64(2.718)
@(private="file") FC_INT: VI = 7

@(test)
union_typed_constant_file_scope :: proc(t: ^testing.T) {
	c0: V = true
	c1: V = f64(2.718)
	c2: VI = 7
	expect_same_bytes(t, FC_BOOL, c0, "file-scope bool constant")
	expect_same_bytes(t, FC_F64, c1, "file-scope f64 constant")
	expect_same_bytes(t, FC_INT, c2, "file-scope int constant")
}

@(test)
union_global_initializer :: proc(t: ^testing.T) {
	c0: V = true
	c1: V = f64(1.25)
	expect_same_bytes(t, GB, c0, "global bool")
	expect_same_bytes(t, GF, c1, "global f64")
}

@(private="file") GB: V = true
@(private="file") GF: V = f64(1.25)

// every variant kind, including the ones the constant whitelist rejects
@(test)
union_variant_kinds :: proc(t: ^testing.T) {
	{
		c: VE : .B
		v: VE = .B
		expect_same_bytes(t, c, v, "enum-variant union")
	}
	{
		c: VI : SP{n=7}
		v: VI = SP{n=7}
		expect_same_bytes(t, c, v, "struct-with-pointer variant")
	}
	{
		c: VI : 42
		v: VI = 42
		expect_same_bytes(t, c, v, "other variant of the same union")
	}
	{
		c: VA : true
		v: VA = true
		expect_same_bytes(t, c, v, "large-payload variant")
	}
	{
		c: VES : VE.A
		v: VES = VE.A
		expect_same_bytes(t, c, v, "enum payload with pointer variant present")
	}
}

// a union with only constantable variants keeps working
@(test)
union_constantable_control :: proc(t: ^testing.T) {
	c: VC : VAOK{1, 2}
	v: VC = VAOK{1, 2}
	expect_same_bytes(t, c, v, "constantable union")
}

// default parameter values are materialized through the same constant path
union_default :: proc(x: V = true) -> V { return x }

@(test)
union_default_parameter :: proc(t: ^testing.T) {
	v: V = true
	expect_same_bytes(t, union_default(), v, "default parameter")
}

// @(static) / @(thread_local) / @(rodata): the initializer used to be lowered
// with the expression's type instead of the declared type, so the global was
// sized to the payload while every access used the union layout.
VS :: union { int, bool }
VSS :: union { string, int }

@(test)
union_static_and_rodata :: proc(t: ^testing.T) {
	@(static) s_int: VS = 1
	@(static) s_str: VSS = "xy"
	@(static) s_bool: V = true
	@(static) s_f64: V = f64(1.5)
	@(thread_local) th: V = true
	@(static) @(rodata) ro: V = true

	i: VS = 1
	s: VSS = "xy"
	b: V = true
	f: V = f64(1.5)
	expect_same_bytes(t, s_int, i, "@(static) int")
	expect_same_bytes(t, s_str, s, "@(static) string")
	expect_same_bytes(t, s_bool, b, "@(static) bool")
	expect_same_bytes(t, s_f64, f, "@(static) f64")
	expect_same_bytes(t, th, b, "@(thread_local)")
	expect_same_bytes(t, ro, b, "@(rodata) static")
	expect_same_bytes(t, RO_GLOBAL, b, "@(rodata) global")

	// the tag must be in the right place, not past the end of the global
	if v, ok := s_int.(int); ok {
		testing.expect_value(t, v, 1)
	} else {
		testing.expectf(t, false, "@(static) int variant not resolved")
	}
	if v, ok := s_str.(string); ok {
		testing.expect_value(t, v, "xy")
	} else {
		testing.expectf(t, false, "@(static) string variant not resolved")
	}
	if v, ok := s_bool.(bool); ok {
		testing.expect(t, v, "@(static) bool variant not resolved")
	} else {
		testing.expectf(t, false, "@(static) bool variant not resolved")
	}
	if v, ok := s_f64.(f64); ok {
		testing.expect_value(t, v, 1.5)
	} else {
		testing.expectf(t, false, "@(static) f64 variant not resolved")
	}
	if v, ok := th.(bool); ok {
		testing.expect(t, v, "@(thread_local) bool variant not resolved")
	} else {
		testing.expectf(t, false, "@(thread_local) bool variant not resolved")
	}
	if v, ok := ro.(bool); ok {
		testing.expect(t, v, "@(rodata) bool variant not resolved")
	} else {
		testing.expectf(t, false, "@(rodata) bool variant not resolved")
	}
}

@(rodata)
RO_GLOBAL: V = true

// statics of non-union types must be unaffected
@(test)
static_non_union_unaffected :: proc(t: ^testing.T) {
	@(static) i: int = 42
	@(static) f: f64 = 2.5
	@(static) s: string = "hey"
	@(static) a: [3]int = {1, 2, 3}
	@(static) e: VE = .B
	testing.expect_value(t, i, 42)
	testing.expect_value(t, f, 2.5)
	testing.expect_value(t, s, "hey")
	testing.expect_value(t, a, [3]int{1, 2, 3})
	testing.expect_value(t, e, VE.B)
}