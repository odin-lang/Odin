// Tests issue #7598: the compiler crashed with a null pointer dereference when a procedure
// scope held exactly 12 (and, at the next load factor, exactly 24) entities.
// https://github.com/odin-lang/Odin/issues/7598
//
// `check_scope_decls` iterates the scope's entity map while `check_entity_decl` can insert an
// entity into that very scope: a procedure alias such as `f :: e` goes through
// `override_entity_in_scope`, which inserts into the scope being iterated. The scope map is
// grown at 75% load (12 of 16 slots, then 24 of 32), so the insert rehashes and reallocates the
// table *inside* the loop. The range-for's end sentinel had captured the old capacity, so the
// iteration kept walking the new table past the slot that sentinel named, off the end of the
// table, dereferencing whatever followed it as an `Entity *`.
//
// Both sides of the count are exact, which is what made one declaration more or less compile:
// one entity fewer and the alias insert does not reach the load factor, one entity more and the
// map has already grown while collecting declarations, before the loop starts.
package test_issues

import "core:testing"


// The reported program: 12 entities in one procedure scope, three of them procedure aliases.
// The scope map sits at 75% load (12/16), so the alias insert inside the entity loop rehashes it.
issue_repro :: proc() -> int {
	n :: 11
	a :: proc() -> int { return 1 }
	b :: proc() -> int { return 2 }
	C :: bit_set[1..=9]
	d :: proc() -> int { return 4 }
	e :: proc() -> int { return 5 }
	f :: e
	g :: e
	h :: e
	i :: proc() -> int { return 9 }
	j :: proc() -> int { return 10 }
	k :: proc() -> int { return 11 }

	std :: size_of(C)
	return n + a() + b() + std + d() + e() + f() + g() + h() + i() + j() + k()
}

// 11 entities: one below the 12/16 load boundary, the map never grows inside the loop.
boundary_11 :: proc() -> int {
	n :: 11
	b11_1 :: proc() -> int { return 1 }
	b11_2 :: b11_1
	b11_3 :: b11_1
	b11_4 :: proc() -> int { return 4 }
	b11_5 :: proc() -> int { return 5 }
	b11_6 :: proc() -> int { return 6 }
	b11_7 :: proc() -> int { return 7 }
	b11_8 :: proc() -> int { return 8 }
	b11_9 :: proc() -> int { return 9 }
	b11_10 :: proc() -> int { return 10 }

	return n + b11_1() + b11_2() + b11_3() + b11_4() + b11_5() + b11_6() + b11_7() + b11_8() + b11_9() + b11_10()
}

// 12 entities again, with names that rehash into different slots: a second layout at the boundary.
boundary_12_alt :: proc() -> int {
	n :: 11
	c12_1 :: proc() -> int { return 1 }
	c12_2 :: proc() -> int { return 2 }
	c12_3 :: proc() -> int { return 3 }
	c12_4 :: c12_1
	c12_5 :: c12_1
	c12_6 :: proc() -> int { return 6 }
	c12_7 :: proc() -> int { return 7 }
	c12_8 :: proc() -> int { return 8 }
	c12_9 :: proc() -> int { return 9 }
	c12_10 :: proc() -> int { return 10 }
	c12_11 :: proc() -> int { return 11 }

	return n + c12_1() + c12_2() + c12_3() + c12_4() + c12_5() + c12_6() + c12_7() + c12_8() + c12_9() + c12_10() + c12_11()
}

// 12 entities, third layout, with the aliases visited later in the iteration.
boundary_12_alt2 :: proc() -> int {
	n :: 11
	d12_1 :: proc() -> int { return 1 }
	d12_2 :: proc() -> int { return 2 }
	d12_3 :: proc() -> int { return 3 }
	d12_4 :: proc() -> int { return 4 }
	d12_5 :: proc() -> int { return 5 }
	d12_6 :: d12_1
	d12_7 :: d12_1
	d12_8 :: d12_1
	d12_9 :: proc() -> int { return 9 }
	d12_10 :: proc() -> int { return 10 }
	d12_11 :: proc() -> int { return 11 }

	return n + d12_1() + d12_2() + d12_3() + d12_4() + d12_5() + d12_6() + d12_7() + d12_8() + d12_9() + d12_10() + d12_11()
}

// 13 entities: the map has already grown while collecting, so it does not grow inside the loop.
boundary_13 :: proc() -> int {
	n :: 11
	e13_1 :: proc() -> int { return 1 }
	e13_2 :: e13_1
	e13_3 :: e13_1
	e13_4 :: proc() -> int { return 4 }
	e13_5 :: proc() -> int { return 5 }
	e13_6 :: proc() -> int { return 6 }
	e13_7 :: proc() -> int { return 7 }
	e13_8 :: proc() -> int { return 8 }
	e13_9 :: proc() -> int { return 9 }
	e13_10 :: proc() -> int { return 10 }
	e13_11 :: proc() -> int { return 11 }
	e13_12 :: proc() -> int { return 12 }

	return n + e13_1() + e13_2() + e13_3() + e13_4() + e13_5() + e13_6() + e13_7() + e13_8() + e13_9() + e13_10() + e13_11() + e13_12()
}

// 23 entities: the second grow point (24/32) is not reached.
boundary_23 :: proc() -> int {
	n :: 11
	f23_1 :: proc() -> int { return 1 }
	f23_2 :: f23_1
	f23_3 :: f23_1
	f23_4 :: proc() -> int { return 4 }
	f23_5 :: proc() -> int { return 5 }
	f23_6 :: proc() -> int { return 6 }
	f23_7 :: proc() -> int { return 7 }
	f23_8 :: proc() -> int { return 8 }
	f23_9 :: proc() -> int { return 9 }
	f23_10 :: proc() -> int { return 10 }
	f23_11 :: proc() -> int { return 11 }
	f23_12 :: proc() -> int { return 12 }
	f23_13 :: proc() -> int { return 13 }
	f23_14 :: proc() -> int { return 14 }
	f23_15 :: proc() -> int { return 15 }
	f23_16 :: proc() -> int { return 16 }
	f23_17 :: proc() -> int { return 17 }
	f23_18 :: proc() -> int { return 18 }
	f23_19 :: proc() -> int { return 19 }
	f23_20 :: proc() -> int { return 20 }
	f23_21 :: proc() -> int { return 21 }
	f23_22 :: proc() -> int { return 22 }

	return n + f23_1() + f23_2() + f23_3() + f23_4() + f23_5() + f23_6() + f23_7() + f23_8() + f23_9() + f23_10() + f23_11() + f23_12() + f23_13() + f23_14() + f23_15() + f23_16() + f23_17() + f23_18() + f23_19() + f23_20() + f23_21() + f23_22()
}

// 24 entities: the scope map is at 75% load again (24/32) and grows 32 -> 64 inside the loop.
boundary_24 :: proc() -> int {
	n :: 11
	g24_1 :: proc() -> int { return 1 }
	g24_2 :: g24_1
	g24_3 :: g24_1
	g24_4 :: proc() -> int { return 4 }
	g24_5 :: proc() -> int { return 5 }
	g24_6 :: proc() -> int { return 6 }
	g24_7 :: proc() -> int { return 7 }
	g24_8 :: proc() -> int { return 8 }
	g24_9 :: proc() -> int { return 9 }
	g24_10 :: proc() -> int { return 10 }
	g24_11 :: proc() -> int { return 11 }
	g24_12 :: proc() -> int { return 12 }
	g24_13 :: proc() -> int { return 13 }
	g24_14 :: proc() -> int { return 14 }
	g24_15 :: proc() -> int { return 15 }
	g24_16 :: proc() -> int { return 16 }
	g24_17 :: proc() -> int { return 17 }
	g24_18 :: proc() -> int { return 18 }
	g24_19 :: proc() -> int { return 19 }
	g24_20 :: proc() -> int { return 20 }
	g24_21 :: proc() -> int { return 21 }
	g24_22 :: proc() -> int { return 22 }
	g24_23 :: proc() -> int { return 23 }

	return n + g24_1() + g24_2() + g24_3() + g24_4() + g24_5() + g24_6() + g24_7() + g24_8() + g24_9() + g24_10() + g24_11() + g24_12() + g24_13() + g24_14() + g24_15() + g24_16() + g24_17() + g24_18() + g24_19() + g24_20() + g24_21() + g24_22() + g24_23()
}

// 24 entities, second layout at the second grow point.
boundary_24_alt :: proc() -> int {
	n :: 11
	h24_1 :: proc() -> int { return 1 }
	h24_2 :: proc() -> int { return 2 }
	h24_3 :: proc() -> int { return 3 }
	h24_4 :: proc() -> int { return 4 }
	h24_5 :: proc() -> int { return 5 }
	h24_6 :: proc() -> int { return 6 }
	h24_7 :: h24_1
	h24_8 :: h24_1
	h24_9 :: proc() -> int { return 9 }
	h24_10 :: proc() -> int { return 10 }
	h24_11 :: proc() -> int { return 11 }
	h24_12 :: proc() -> int { return 12 }
	h24_13 :: proc() -> int { return 13 }
	h24_14 :: proc() -> int { return 14 }
	h24_15 :: proc() -> int { return 15 }
	h24_16 :: proc() -> int { return 16 }
	h24_17 :: proc() -> int { return 17 }
	h24_18 :: proc() -> int { return 18 }
	h24_19 :: proc() -> int { return 19 }
	h24_20 :: proc() -> int { return 20 }
	h24_21 :: proc() -> int { return 21 }
	h24_22 :: proc() -> int { return 22 }
	h24_23 :: proc() -> int { return 23 }

	return n + h24_1() + h24_2() + h24_3() + h24_4() + h24_5() + h24_6() + h24_7() + h24_8() + h24_9() + h24_10() + h24_11() + h24_12() + h24_13() + h24_14() + h24_15() + h24_16() + h24_17() + h24_18() + h24_19() + h24_20() + h24_21() + h24_22() + h24_23()
}

// 25 entities: the map grew while collecting, so it does not grow inside the loop.
boundary_25 :: proc() -> int {
	n :: 11
	i25_1 :: proc() -> int { return 1 }
	i25_2 :: i25_1
	i25_3 :: i25_1
	i25_4 :: proc() -> int { return 4 }
	i25_5 :: proc() -> int { return 5 }
	i25_6 :: proc() -> int { return 6 }
	i25_7 :: proc() -> int { return 7 }
	i25_8 :: proc() -> int { return 8 }
	i25_9 :: proc() -> int { return 9 }
	i25_10 :: proc() -> int { return 10 }
	i25_11 :: proc() -> int { return 11 }
	i25_12 :: proc() -> int { return 12 }
	i25_13 :: proc() -> int { return 13 }
	i25_14 :: proc() -> int { return 14 }
	i25_15 :: proc() -> int { return 15 }
	i25_16 :: proc() -> int { return 16 }
	i25_17 :: proc() -> int { return 17 }
	i25_18 :: proc() -> int { return 18 }
	i25_19 :: proc() -> int { return 19 }
	i25_20 :: proc() -> int { return 20 }
	i25_21 :: proc() -> int { return 21 }
	i25_22 :: proc() -> int { return 22 }
	i25_23 :: proc() -> int { return 23 }
	i25_24 :: proc() -> int { return 24 }

	return n + i25_1() + i25_2() + i25_3() + i25_4() + i25_5() + i25_6() + i25_7() + i25_8() + i25_9() + i25_10() + i25_11() + i25_12() + i25_13() + i25_14() + i25_15() + i25_16() + i25_17() + i25_18() + i25_19() + i25_20() + i25_21() + i25_22() + i25_23() + i25_24()
}

// The same boundary in a nested block scope: the declaration-checking flag reaches nested blocks
// as well, so the block's own scope is collected and iterated exactly like a procedure body's.
boundary_12_block :: proc() -> int {
	total := 0
	{
		n :: 11
		blk_1 :: proc() -> int { return 1 }
		blk_2 :: blk_1
		blk_3 :: blk_1
		blk_4 :: proc() -> int { return 4 }
		blk_5 :: proc() -> int { return 5 }
		blk_6 :: proc() -> int { return 6 }
		blk_7 :: proc() -> int { return 7 }
		blk_8 :: proc() -> int { return 8 }
		blk_9 :: proc() -> int { return 9 }
		blk_10 :: proc() -> int { return 10 }
		blk_11 :: proc() -> int { return 11 }

		total = n + blk_1() + blk_2() + blk_3() + blk_4() + blk_5() + blk_6() + blk_7() + blk_8() + blk_9() + blk_10() + blk_11()
	}
	return total
}

// Every case is called and its result checked: an entity whose declaration the entity loop
// dropped has to fail here, and a compiler that cannot check the scope has to fail before it
// gets this far.
@(test)
test_issue_7598_issue_repro :: proc(t: ^testing.T) {
	testing.expect_value(t, issue_repro(), 70)
}

@(test)
test_issue_7598_boundary_11 :: proc(t: ^testing.T) {
	testing.expect_value(t, boundary_11(), 63)
}

@(test)
test_issue_7598_boundary_12_alt :: proc(t: ^testing.T) {
	testing.expect_value(t, boundary_12_alt(), 70)
}

@(test)
test_issue_7598_boundary_12_alt2 :: proc(t: ^testing.T) {
	testing.expect_value(t, boundary_12_alt2(), 59)
}

@(test)
test_issue_7598_boundary_12_block :: proc(t: ^testing.T) {
	testing.expect_value(t, boundary_12_block(), 74)
}

@(test)
test_issue_7598_boundary_13 :: proc(t: ^testing.T) {
	testing.expect_value(t, boundary_13(), 86)
}

@(test)
test_issue_7598_boundary_23 :: proc(t: ^testing.T) {
	testing.expect_value(t, boundary_23(), 261)
}

@(test)
test_issue_7598_boundary_24 :: proc(t: ^testing.T) {
	testing.expect_value(t, boundary_24(), 284)
}

@(test)
test_issue_7598_boundary_24_alt :: proc(t: ^testing.T) {
	testing.expect_value(t, boundary_24_alt(), 274)
}

@(test)
test_issue_7598_boundary_25 :: proc(t: ^testing.T) {
	testing.expect_value(t, boundary_25(), 308)
}