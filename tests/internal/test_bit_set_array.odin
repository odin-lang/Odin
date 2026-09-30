package test_internal

import "core:fmt"
import "core:testing"

// Regression tests for `bit_set` types backed by an array of integers, e.g. `bit_set[E; [4]u64]`.
// The interesting cases are the set relations (`<`, `<=`, `>`, `>=`) with their subset/superset
// semantics, which must agree between the compile-time constant folding and the generated code, and
// must match an ordinary integer-backed bit_set. An array backing also lets a bit_set exceed the
// 128-bit limit of the integer backings.

@(private="file")
Bsa_E :: enum u8 { A, B, C, D, E, F, G, H }

@(private="file")
Bsa_Arr :: bit_set[Bsa_E; [4]u64] // array backed (256 bits)

@(private="file")
Bsa_Int :: bit_set[Bsa_E; u16]    // integer backed, for cross-checking

@(private="file")
bsa_arr_from :: proc(m: u8) -> (s: Bsa_Arr) {
	for i in 0..<8 {
		if (m >> uint(i)) & 1 == 1 {
			s += {Bsa_E(i)}
		}
	}
	return
}

@(private="file")
bsa_int_from :: proc(m: u8) -> (s: Bsa_Int) {
	for i in 0..<8 {
		if (m >> uint(i)) & 1 == 1 {
			s += {Bsa_E(i)}
		}
	}
	return
}

@(test)
bit_set_array_membership :: proc(t: ^testing.T) {
	s := Bsa_Arr{.A, .C, .E}
	testing.expect(t, .A in     s, ".A should be in s")
	testing.expect(t, .E in     s, ".E should be in s")
	testing.expect(t, .B not_in s, ".B should not be in s")
	testing.expect(t, .H not_in s, ".H should not be in s")

	// runtime (non-constant) key
	k := Bsa_E.E
	testing.expect(t, k in s, "runtime key .E should be in s")
	k = .F
	testing.expect(t, k not_in s, "runtime key .F should not be in s")

	// constant folding of `in`
	C :: Bsa_Arr{.A, .C}
	#assert(.A in C)
	#assert(.B not_in C)
}

@(test)
bit_set_array_algebra :: proc(t: ^testing.T) {
	a := Bsa_Arr{.A, .C, .E}
	b := Bsa_Arr{.C, .E, .G}

	testing.expect_value(t, a | b, Bsa_Arr{.A, .C, .E, .G})
	testing.expect_value(t, a & b, Bsa_Arr{.C, .E})
	testing.expect_value(t, a &~ b, Bsa_Arr{.A})
	testing.expect_value(t, a + b, a | b)  // `+` aliases `|`
	testing.expect_value(t, a - b, a &~ b) // `-` aliases `&~`

	// complement
	full := ~Bsa_Arr{}
	testing.expect_value(t, card(full), 8)
	testing.expect_value(t, ~a, full &~ a)

	// assignment operators
	s := Bsa_Arr{.A}
	s += {.C}
	s |= {.E}
	testing.expect_value(t, s, Bsa_Arr{.A, .C, .E})
	s -= {.A}
	s &~= {.C}
	testing.expect_value(t, s, Bsa_Arr{.E})
	s = Bsa_Arr{.A, .B, .C}
	s &= {.B, .C, .D}
	testing.expect_value(t, s, Bsa_Arr{.B, .C})
}

@(test)
bit_set_array_subset :: proc(t: ^testing.T) {
	sup := Bsa_Arr{.A, .B, .C, .D}
	sub := Bsa_Arr{.B, .C}
	dis := Bsa_Arr{.E, .F}

	testing.expect(t, sub <= sup, "sub is a subset")
	testing.expect(t, sub <  sup, "sub is a strict subset")
	testing.expect(t, sup >= sub, "sup is a superset")
	testing.expect(t, sup >  sub, "sup is a strict superset")

	testing.expect(t, sup <= sup,   "reflexive <=")
	testing.expect(t, sup >= sup,   "reflexive >=")
	testing.expect(t, !(sup < sup), "not a strict subset of itself")
	testing.expect(t, !(sup > sup), "not a strict superset of itself")

	testing.expect(t, !(dis <= sup), "disjoint set is not a subset")
	testing.expect(t, !(sup <= dis), "superset is not a subset of a disjoint set")

	// the same relations must fold at compile time
	CSUP :: Bsa_Arr{.A, .B, .C, .D}
	CSUB :: Bsa_Arr{.B, .C}
	#assert(CSUB <= CSUP)
	#assert(CSUB < CSUP)
	#assert(CSUP >= CSUB)
	#assert(CSUP > CSUB)
	#assert(CSUP <= CSUP)
	#assert(!(CSUP < CSUP))
	#assert(CSUP == CSUP)
	#assert(CSUB != CSUP)
}

@(test)
bit_set_array_card :: proc(t: ^testing.T) {
	testing.expect_value(t, card(Bsa_Arr{}), 0)
	testing.expect_value(t, card(Bsa_Arr{.A}), 1)
	testing.expect_value(t, card(Bsa_Arr{.A, .C, .E, .G}), 4)
	testing.expect_value(t, card(~Bsa_Arr{}), 8)
}

@(test)
bit_set_array_over_128_bits :: proc(t: ^testing.T) {
	Big :: enum { V0 = 0, V64 = 64, V127 = 127, V128 = 128, V200 = 200 }
	BS :: bit_set[Big; [4]u64] // 256 bits, cannot be an integer backing

	testing.expect_value(t, size_of(BS), 32)

	s := BS{.V0, .V128, .V200}
	testing.expect(t, .V0   in     s, ".V0 in s")
	testing.expect(t, .V128 in     s, ".V128 in s (past 128 bits)")
	testing.expect(t, .V200 in     s, ".V200 in s (past 128 bits)")
	testing.expect(t, .V64  not_in s, ".V64 not in s")
	testing.expect(t, .V127 not_in s, ".V127 not in s")
	testing.expect_value(t, card(s), 3)

	// bits beyond 128 must participate in the set relations
	testing.expect(t, BS{.V200} <= s,   "high bit subset")
	testing.expect(t, !(BS{.V64} <= s), "absent high bit is not a subset")
	testing.expect_value(t, s & BS{.V128}, BS{.V128})
}

@(test)
bit_set_array_matches_integer_backing :: proc(t: ^testing.T) {
	// Exhaustively compare an array-backed and an integer-backed bit_set over the same 8-bit masks
	// for every relation and set operation.
	mismatches := 0
	for a in u16(0)..<256 {
		for b in u16(0)..<256 {
			aa, ab := bsa_arr_from(u8(a)), bsa_arr_from(u8(b))
			ia, ib := bsa_int_from(u8(a)), bsa_int_from(u8(b))

			if (aa <  ab) != (ia <  ib) { mismatches += 1 }
			if (aa <= ab) != (ia <= ib) { mismatches += 1 }
			if (aa >  ab) != (ia >  ib) { mismatches += 1 }
			if (aa >= ab) != (ia >= ib) { mismatches += 1 }
			if (aa == ab) != (ia == ib) { mismatches += 1 }
			if (aa != ab) != (ia != ib) { mismatches += 1 }

			if card(aa)       != card(ia)       { mismatches += 1 }
			if card(aa | ab)  != card(ia | ib)  { mismatches += 1 }
			if card(aa & ab)  != card(ia & ib)  { mismatches += 1 }
			if card(aa &~ ab) != card(ia &~ ib) { mismatches += 1 }
			if card(~aa)      != card(~ia)      { mismatches += 1 }
		}
	}
	testing.expect_value(t, mismatches, 0)
}

@(test)
bit_set_array_formatting :: proc(t: ^testing.T) {
	a := Bsa_Arr{.A, .C, .H}
	i := Bsa_Int{.A, .C, .H}

	// The `%w` verb lists the members without the surrounding bit_set type name, so an array-backed
	// set and an integer-backed set with the same members format identically.
	sa := fmt.tprintf("%w", a)
	si := fmt.tprintf("%w", i)
	testing.expect_value(t, sa, si)
	testing.expect_value(t, sa, "{Bsa_E.A, Bsa_E.C, Bsa_E.H}")
}
