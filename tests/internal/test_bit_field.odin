package test_internal

import "base:intrinsics"
import "core:testing"

// A `bit_field`'s layout is defined on the backing *value*, not on its bytes: the first field
// occupies the low bits and each next one continues upward, so for
// `bit_field u32 { a: bool|1, b: bool|1, f: u32|30 }` and a backing `x`, `a` is `x & 1`, `b` is
// `(x >> 1) & 1` and `f` is `x >> 2`. Writing the tests against the backing integer rather than a
// byte array is what keeps them endian-neutral
@(test)
bit_field_layout_starts_at_the_low_bit :: proc(t: ^testing.T) {
	BF :: bit_field u32 { a: bool | 1, b: bool | 1, f: u32 | 30 }

	backings := []u32{0, 1, 2, 3, 0b1101, 0xFFFF_FFFF, 0x8000_0000, 0xDEAD_BEEF}
	for x in backings {
		v := transmute(BF)x
		testing.expect_value(t, v.a, x & 1 == 1)
		testing.expect_value(t, v.b, (x >> 1) & 1 == 1)
		testing.expect_value(t, v.f, x >> 2)
		testing.expect_value(t, transmute(u32)v, x)
	}

	// and the same layout when built field by field rather than transmuted into
	w: BF
	w.a = true
	w.b = false
	w.f = 0x3FFF_FFFF
	testing.expect_value(t, transmute(u32)w, 0xFFFF_FFFD)
}

// the declared widths, and offsets that are their running sum
@(test)
bit_field_declared_sizes_and_offsets :: proc(t: ^testing.T) {
	BF :: bit_field u32 { a: u8 | 3, b: u16 | 9, c: bool | 1, d: u8 | 7 }   // 12 bits spare

	testing.expect_value(t, intrinsics.type_field_bit_size(BF, "a"), 3)
	testing.expect_value(t, intrinsics.type_field_bit_size(BF, "b"), 9)
	testing.expect_value(t, intrinsics.type_field_bit_size(BF, "c"), 1)
	testing.expect_value(t, intrinsics.type_field_bit_size(BF, "d"), 7)

	testing.expect_value(t, intrinsics.type_field_bit_offset(BF, "a"), 0)
	testing.expect_value(t, intrinsics.type_field_bit_offset(BF, "b"), 3)
	testing.expect_value(t, intrinsics.type_field_bit_offset(BF, "c"), 12)
	testing.expect_value(t, intrinsics.type_field_bit_offset(BF, "d"), 13)

	testing.expect_value(t, size_of(BF), size_of(u32))

	// a field that straddles a byte boundary is still contiguous in the value
	v: BF
	v.b = 0b1_1111_1111
	testing.expect_value(t, transmute(u32)v, 0b1_1111_1111 << 3)
	testing.expect_value(t, v.b, 0b1_1111_1111)
}

// a write touches its own bits and no others, including the spare high bits of the backing
@(test)
bit_field_writes_leave_neighbours_alone :: proc(t: ^testing.T) {
	P :: bit_field u16 { a: u8 | 3, b: u8 | 2 }   // 11 bits spare

	p := transmute(P)u16(0xFFFF)
	p.a = 0
	testing.expect_value(t, transmute(u16)p, 0xFFF8)
	testing.expect_value(t, p.b, 3)

	q: P
	q.b = 3
	testing.expect_value(t, transmute(u16)q, 0b11000)
	testing.expect_value(t, q.a, 0)

	q.a = 5
	testing.expect_value(t, q.b, 3)
	testing.expect_value(t, q.a, 5)
}

// a signed field is sign extended from its own width, not from its type's
@(test)
bit_field_signed_fields_sign_extend :: proc(t: ^testing.T) {
	S :: bit_field u8 { s: i8 | 3, r: u8 | 5 }

	expected := [8]i8{0, 1, 2, 3, -4, -3, -2, -1}
	for v in u8(0) ..< 8 {
		x := transmute(S)v
		testing.expect_value(t, x.s, expected[v])
	}

	W :: bit_field u32 { s: i32 | 12, r: u32 | 20 }
	w: W
	w.s = -1
	testing.expect_value(t, w.s, -1)
	testing.expect_value(t, transmute(u32)w, 0xFFF)
	w.s = -2048
	testing.expect_value(t, w.s, -2048)
	w.s = 2047
	testing.expect_value(t, w.s, 2047)
}

// and to the full width of its type, even one wider than the backing, without taking any bits of its
// neighbours: `lo` and `hi` are set around `s`, so a read that keeps them gets the wrong value
@(test)
bit_field_signed_field_wider_than_backing :: proc(t: ^testing.T) {
	S :: bit_field u16 { lo: u8 | 5, s: i32 | 3, hi: u8 | 8 }

	expected := [8]i32{0, 1, 2, 3, -4, -3, -2, -1}
	for v in u16(0) ..< 8 {
		x := transmute(S)(0xAA00 | v << 5 | 0b10101) // hi = 0xAA, s = v, lo = 0b10101
		testing.expect_value(t, x.s, expected[v])
	}
}

// an array backing is laid out the same way, with fields running across its elements
@(test)
bit_field_array_backing :: proc(t: ^testing.T) {
	A :: bit_field [3]u8 { lo: u8 | 4, mid: u16 | 12, hi: i8 | 8 }

	a := transmute(A)[3]u8{0x5A, 0xBC, 0xF0}
	testing.expect_value(t, a.lo, 0xA)
	testing.expect_value(t, a.mid, 0xBC5)
	testing.expect_value(t, a.hi, -16)

	a.mid = 0x123
	testing.expect_value(t, transmute([3]u8)a, [3]u8{0x3A, 0x12, 0xF0})
}

// a field may lie across several elements of an array backing, whose size need not be a multiple of 8 bytes
@(test)
bit_field_array_backing_across_elements :: proc(t: ^testing.T) {
	A :: bit_field [11]u8 { lo: u64 | 60, mid: u32 | 24, hi: i8 | 4 }

	a := transmute(A)[11]u8{0x10, 0x32, 0x54, 0x76, 0x98, 0xBA, 0xDC, 0xFE, 0x21, 0x43, 0xA5}
	testing.expect_value(t, a.lo, 0x0EDCBA9876543210)
	testing.expect_value(t, a.mid, 0x54321F)
	testing.expect_value(t, a.hi, -6)

	a.mid = 0x123456
	testing.expect_value(t, transmute([11]u8)a, [11]u8{0x10, 0x32, 0x54, 0x76, 0x98, 0xBA, 0xDC, 0x6E, 0x45, 0x23, 0xA1})
}

// the elements of an array backing may be wider than its fields
@(test)
bit_field_array_backing_wide_elements :: proc(t: ^testing.T) {
	A :: bit_field [2]u128 { lo: u64 | 64, pad: u64 | 60, mid: u16 | 12, hi: u64 | 64 }

	a: A
	a.mid = 0xABC
	a.hi  = 0x0123456789ABCDEF
	testing.expect_value(t, transmute([2]u128)a, [2]u128{0xC << 124, 0x0123456789ABCDEF << 8 | 0xAB})
	testing.expect_value(t, a.mid, 0xABC)
	testing.expect_value(t, a.hi, 0x0123456789ABCDEF)
}

// A 1-bit boolean field is well formed at every backing value: the mask leaves only bit 0, so the
// read is 0 or 1 whichever way it is tested. Wider boolean fields are legal -- any non-zero value
// is true -- and are not covered here
@(test)
bit_field_boolean_field_is_well_formed :: proc(t: ^testing.T) {
	One :: bit_field u8 { flag: bool | 1, rest: u8 | 7 }

	for i in 0 ..< 256 {
		backing := u8(i)
		bytes := [1]u8{backing}
		o := (^One)(&bytes[0])^
		f := o.flag
		testing.expectf(t, f == true || f == false, "backing %v gave a bool that is neither", backing)
		testing.expect_value(t, f, backing & 1 == 1)
		testing.expect_value(t, o.rest, backing >> 1)

		// and it survives being copied out of the bit_field
		g := f
		testing.expect_value(t, g, f)
		testing.expect_value(t, u8(f), backing & 1)
	}
}

// a constant is range-checked against the field's width whether or not it carries its type
@(test)
bit_field_typed_constants_in_range :: proc(t: ^testing.T) {
	E :: enum u8 { A, B, C, D }
	W :: bit_field u8 { n: u8 | 2, s: i8 | 2, e: E | 1, r: u8 | 3 }

	w: W
	w.n = u8(3)
	w.s = i8(-2)
	w.e = .B
	w.r = 7
	testing.expect_value(t, w.n, 3)
	testing.expect_value(t, w.s, -2)
	testing.expect_value(t, w.e, E.B)
	testing.expect_value(t, w.r, 7)

	C :: u8(3)
	v := W{ n = C, s = i8(1), e = .A, r = u8(5) }
	testing.expect_value(t, v.n, 3)
	testing.expect_value(t, v.s, 1)
	testing.expect_value(t, v.e, E.A)
	testing.expect_value(t, v.r, 5)

	// an enum field holds every value its width can represent
	V :: bit_field u8 { e: E | 2, r: u8 | 6 }
	for want in ([]E{.A, .B, .C, .D}) {
		x: V
		x.e = want
		testing.expect_value(t, x.e, want)
	}

	// a variable is not a constant, so it truncates rather than being refused
	m: u8 = 200
	w.n = m
	testing.expect_value(t, w.n, 0)
}

// a field as wide as its backing keeps every value
@(test)
bit_field_full_width_fields :: proc(t: ^testing.T) {
	Full :: bit_field u64 { v: u64 | 64 }
	Half :: bit_field u64 { lo: u32 | 32, hi: u32 | 32 }

	f := transmute(Full)u64(0xDEAD_BEEF_CAFE_F00D)
	testing.expect_value(t, f.v, 0xDEAD_BEEF_CAFE_F00D)

	h := transmute(Half)u64(0xDEAD_BEEF_CAFE_F00D)
	testing.expect_value(t, h.lo, 0xCAFE_F00D)
	testing.expect_value(t, h.hi, 0xDEAD_BEEF)

	h.hi = 0
	testing.expect_value(t, transmute(u64)h, 0xCAFE_F00D)
}

// field access on a constant bit_field used to always return the zero value
@(test)
bit_field_constant_field_access :: proc(t: ^testing.T) {
	BF :: bit_field u32 { a: u8 | 3, b: u16 | 9, c: bool | 1, d: u8 | 7 }

	FULL :: BF{ a = 3, b = 100, c = true, d = 5 }
	testing.expect_value(t, FULL.a, u8(3))
	testing.expect_value(t, FULL.b, u16(100))
	testing.expect_value(t, FULL.c, true)
	testing.expect_value(t, FULL.d, u8(5))

	// unset fields still read as zero
	EMPTY :: BF{}
	testing.expect_value(t, EMPTY.a, u8(0))
	testing.expect_value(t, EMPTY.b, u16(0))
	testing.expect_value(t, EMPTY.c, false)
	testing.expect_value(t, EMPTY.d, u8(0))

	v := FULL
	testing.expect_value(t, v.a, FULL.a)
	testing.expect_value(t, v.b, FULL.b)
	testing.expect_value(t, v.c, FULL.c)
	testing.expect_value(t, v.d, FULL.d)
}

// a compound literal of an array backed bit_field used to generate invalid LLVM IR for a field set from
// a variable and would lose the high bits of a field narrower than the array's elements
@(test)
bit_field_array_backed_compound_literal :: proc(t: ^testing.T) {
	BF :: bit_field [2]u16 { a: u8 | 5, b: u8 | 5 }

	v := u8(31)
	x := BF{ b = v, a = 1 }
	testing.expect_value(t, x.a, 1)
	testing.expect_value(t, x.b, 31)

	y := BF{ b = 31, a = 1 }
	testing.expect_value(t, y.a, 1)
	testing.expect_value(t, y.b, 31)
}
