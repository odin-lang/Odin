// Companion to test_issue_7598.odin, covering the other half of issue #7598.
// https://github.com/odin-lang/Odin/issues/7598
//
// When the scope map is rehashed from inside `check_scope_decls`' iteration, the iteration
// either runs off the end of the reallocated table (the crash in test_issue_7598.odin) or it
// stops at the slot the stale end sentinel named and silently drops every entity whose new slot
// lies behind it. A dropped entity is never checked, so an invalid declaration simply produces
// no diagnostic at all.
//
// Every invalid declaration here must be reported: 2 declarations x 2 procedure scopes = 4
// errors. `boundary_errors_13` holds 13 entities, one above the 12/16 load boundary, so its map
// has already grown by the time the loop starts and it reports its own 2 errors even without the
// fix; `boundary_errors_12` holds exactly 12 entities and its map grows *inside* the loop, so
// without the fix it swallows one of its 2.
package test_issues

boundary_errors_13 :: proc() -> int {
	n :: 11
	a0 :: proc() -> int { return 1 }
	b1 :: a0
	c2 :: a0
	d3 :: proc() -> int { return 4 }
	e4 :: undeclared_name_5
	f5 :: proc() -> int { return 6 }
	g6 :: proc() -> int { return 7 }
	h7 :: undeclared_name_8
	i8 :: proc() -> int { return 9 }
	j9 :: proc() -> int { return 10 }
	k10 :: proc() -> int { return 11 }
	l11 :: proc() -> int { return 12 }

	return n + a0() + b1() + c2() + d3() + f5() + g6() + i8() + j9() + k10() + l11()
}

boundary_errors_12 :: proc() -> int {
	n :: 11
	a0 :: proc() -> int { return 1 }
	b1 :: a0
	c2 :: a0
	d3 :: proc() -> int { return 4 }
	e4 :: undeclared_name_5
	f5 :: proc() -> int { return 6 }
	g6 :: proc() -> int { return 7 }
	h7 :: undeclared_name_8
	i8 :: proc() -> int { return 9 }
	j9 :: proc() -> int { return 10 }
	k10 :: proc() -> int { return 11 }

	return n + a0() + b1() + c2() + d3() + f5() + g6() + i8() + j9() + k10()
}

main :: proc() {
	_ = boundary_errors_13()
	_ = boundary_errors_12()
}