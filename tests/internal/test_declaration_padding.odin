package test_internal

import "base:intrinsics"
import "core:testing"

// A declared variable's padding is zero, whatever was on the stack before and however its value is built.

@(private="file")
Padded :: struct {
	a: bool,
	b: int,
	c: [16]int,
}

@(private="file")
Small_Padded :: struct {
	a: bool,
	b: int,
}

@(private="file")
PADDED :: Padded{a = true, b = 3, c = {1 = 9}}

@(private="file")
scribble :: #force_no_inline proc() {
	buf: [8192]byte = ---
	for i in 0..<len(buf) {
		intrinsics.volatile_store(&buf[i], 0xAA)
	}
}

@(private="file")
make_padded :: #force_no_inline proc(n: int) -> Padded {
	return Padded{a = true, b = n}
}

@(private="file")
make_padded_named :: #force_no_inline proc(n: int) -> (p: Padded) {
	p.a = true
	p.b = n
	return
}

@(private="file")
make_padded_contextless :: #force_no_inline proc "contextless" (n: int) -> Padded {
	return Padded{a = true, b = n}
}

@(private="file")
make_padded_c :: #force_no_inline proc "c" (n: int) -> Padded {
	return Padded{a = true, b = n}
}

@(private="file")
make_padded_pair :: #force_no_inline proc(n: int) -> (Padded, Padded) {
	return Padded{a = true, b = n}, Padded{b = n}
}

@(private="file")
expect_zero_padding :: proc(t: ^testing.T, p: rawptr, name: string, loc := #caller_location) {
	bytes := ([^]byte)(p)
	for i in 1..<align_of(int) {
		testing.expectf(t, bytes[i] == 0, "%s: padding byte %d is %x", name, i, bytes[i], loc=loc)
	}
}

@(private="file")
check_declarations :: #force_no_inline proc(t: ^testing.T, n: int) {
	literal := Padded{b = n}
	expect_zero_padding(t, &literal, "literal")

	mixed := Padded{a = true, b = n, c = {0 = 7}}
	expect_zero_padding(t, &mixed, "mixed literal")

	copied := literal
	expect_zero_padding(t, &copied, "copy")

	empty := Padded{}
	expect_zero_padding(t, &empty, "empty literal")

	constant := PADDED
	expect_zero_padding(t, &constant, "constant")

	small := Small_Padded{b = n}
	expect_zero_padding(t, &small, "small literal")

	uninit: Padded = ---
	uninit.a = true
	expect_zero_padding(t, &uninit, "---")

	// The callee writes its result straight into the variable.
	called := make_padded(n)
	expect_zero_padding(t, &called, "call")

	named := make_padded_named(n)
	expect_zero_padding(t, &named, "named result")

	contextless := make_padded_contextless(n)
	expect_zero_padding(t, &contextless, "contextless call")

	c_call := make_padded_c(n)
	expect_zero_padding(t, &c_call, "c call")

	via_value := make_padded
	indirect := via_value(n)
	expect_zero_padding(t, &indirect, "procedure value")

	first, second := make_padded_pair(n)
	expect_zero_padding(t, &first, "first of two results")
	expect_zero_padding(t, &second, "second of two results")

	literal = Padded{a = true, b = n + 1}
	expect_zero_padding(t, &literal, "assignment")
}

@test
test_declaration_padding_is_zero :: proc(t: ^testing.T) {
	scribble()
	check_declarations(t, 5)
}
