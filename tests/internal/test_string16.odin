package test_internal

import "core:testing"

// The compiler folds constant `string16` operations at check time and emits the same
// operations at runtime. Every case below computes a value both ways and compares them,
// because the interesting failures are the ones where the two disagree silently.

// Related previous issue #6101

@(private="file")
opaque :: proc(v: $T) -> T { return v }

@(private="file")
Ascii   : string16 : "hello"          // 5 bytes utf-8, 5 units utf-16
@(private="file")
Latin   : string16 : "héllo"          // 6 bytes utf-8, 5 units utf-16
@(private="file")
Cjk     : string16 : "日本語"          // 9 bytes utf-8, 3 units utf-16
@(private="file")
NonBmp  : string16 : "\U0001F63A"     // 4 bytes utf-8, 2 units utf-16 (surrogate pair)
@(private="file")
Mixed   : string16 : "a日\U0001F63A"   // 8 bytes utf-8, 4 units utf-16
@(private="file")
Empty   : string16 : ""

@test
string16_constant_length :: proc(t: ^testing.T) {
	// lengths are in utf-16 code units, not utf-8 bytes
	testing.expect_value(t, len(Ascii),  5)
	testing.expect_value(t, len(Latin),  5)
	testing.expect_value(t, len(Cjk),    3)
	testing.expect_value(t, len(NonBmp), 2)
	testing.expect_value(t, len(Mixed),  4)
	testing.expect_value(t, len(Empty),  0)

	// the constant length must match the length of the same value at runtime
	testing.expect_value(t, len(Ascii),  len(opaque(Ascii)))
	testing.expect_value(t, len(Latin),  len(opaque(Latin)))
	testing.expect_value(t, len(Cjk),    len(opaque(Cjk)))
	testing.expect_value(t, len(NonBmp), len(opaque(NonBmp)))
	testing.expect_value(t, len(Mixed),  len(opaque(Mixed)))
	testing.expect_value(t, len(Empty),  len(opaque(Empty)))
}

@test
string16_constant_index :: proc(t: ^testing.T) {
	testing.expect_value(t, Latin[0], 'h')
	testing.expect_value(t, Latin[1], 0x00E9) // é stays one unit
	testing.expect_value(t, Cjk[0],   0x65E5)
	testing.expect_value(t, Cjk[2],   0x8A9E)
	testing.expect_value(t, NonBmp[0], 0xD83D) // high surrogate
	testing.expect_value(t, NonBmp[1], 0xDE3A) // low surrogate

	// each constant-folded unit must match the same unit read at runtime
	m := opaque(Mixed)
	testing.expect_value(t, Mixed[0], m[0])
	testing.expect_value(t, Mixed[1], m[1])
	testing.expect_value(t, Mixed[2], m[2])
	testing.expect_value(t, Mixed[3], m[3])
}

@test
string16_constant_slice :: proc(t: ^testing.T) {
	A :: Latin[0:2]
	B :: Cjk[1:3]
	C :: NonBmp[0:2]
	D :: Mixed[1:2]
	E :: Ascii[2:2]

	testing.expect_value(t, len(A), 2)
	testing.expect_value(t, len(B), 2)
	testing.expect_value(t, len(C), 2)
	testing.expect_value(t, len(D), 1)
	testing.expect_value(t, len(E), 0)

	testing.expect_value(t, A[0], 'h')
	testing.expect_value(t, A[1], 0x00E9)
	testing.expect_value(t, B[0], 0x672C)
	testing.expect_value(t, C[1], 0xDE3A)
	testing.expect_value(t, D[0], 0x65E5)

	// open-ended and full slices
	F :: Cjk[:]
	G :: Cjk[1:]
	H :: Cjk[:2]
	testing.expect_value(t, len(F), 3)
	testing.expect_value(t, len(G), 2)
	testing.expect_value(t, len(H), 2)

	// folded slice must equal the same slice taken at runtime
	l := opaque(Latin)
	rt := l[0:2]
	testing.expect_value(t, len(A), len(rt))
	testing.expect_value(t, A[0], rt[0])
	testing.expect_value(t, A[1], rt[1])
}

@test
string16_from_cast_and_assignment :: proc(t: ^testing.T) {
	// the three ways a constant acquires a string16 type must agree
	Typed  : string16 : "日本語"
	Casted :: string16("日本語")
	testing.expect_value(t, len(Typed), len(Casted))
	testing.expect_value(t, Typed[0], Casted[0])
	testing.expect_value(t, Typed[2], Casted[2])

	assigned: string16 = "日本語"
	testing.expect_value(t, len(assigned), len(Typed))
	testing.expect_value(t, assigned[0], Typed[0])
}

@test
string16_underlying_units :: proc(t: ^testing.T) {
	// transmute exposes the utf-16 code units directly
	u := transmute([]u16)opaque(NonBmp)
	testing.expect_value(t, len(u), 2)
	testing.expect_value(t, u[0], 0xD83D)
	testing.expect_value(t, u[1], 0xDE3A)

	c := transmute([]u16)opaque(Cjk)
	testing.expect_value(t, len(c), 3)
	testing.expect_value(t, c[0], 0x65E5)

	// a utf-8 string of the same text keeps its byte length
	testing.expect_value(t, len("日本語"), 9)
}

@test
string16_comparison :: proc(t: ^testing.T) {
	X : string16 : "日本語"
	testing.expect(t, X == Cjk)
	testing.expect(t, X != Ascii)
	testing.expect(t, opaque(X) == Cjk)
	testing.expect(t, Empty == "")
}
