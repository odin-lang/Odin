// Tests issue #7708 https://github.com/odin-lang/Odin/issues/7708
// A record's concrete constant parameters must match, e.g. `M(1, 1, $T)` does not take a `M(3, 3, f64)`
package test_issues

import "core:testing"

M :: struct($R, $C: int, $T: typeid) { data: [C][R]T }

m11 :: proc(m: M(1, 1, $T)) -> int { return 11 }
m33 :: proc(m: M(3, 3, $T)) -> int { return 33 }
m_group :: proc{m11, m33}

m_forward :: proc(m: M($R, $C, $T)) -> int { return m_group(m) }

c11 :: proc(m: $X/M(1, 1, $T)) -> int { return 11 }
c33 :: proc(m: $X/M(3, 3, $T)) -> int { return 33 }
c_group :: proc{c11, c33}

p11 :: proc(m: ^M(1, 1, $T)) -> int { return 11 }
p33 :: proc(m: ^M(3, 3, $T)) -> int { return 33 }
p_group :: proc{p11, p33}

Kind :: enum { A, B }
E :: struct($K: Kind, $T: typeid) { x: T }
ea :: proc(e: E(.A, $T)) -> int { return 1 }
eb :: proc(e: E(.B, $T)) -> int { return 2 }
e_group :: proc{ea, eb}

S :: struct($N: string, $T: typeid) { x: T }
sa :: proc(s: S("a", $T)) -> int { return 1 }
sb :: proc(s: S("b", $T)) -> int { return 2 }
s_group :: proc{sa, sb}

U :: union($N: int, $T: typeid) { [N]T }
u1 :: proc(u: U(1, $T)) -> int { return 1 }
u2 :: proc(u: U(2, $T)) -> int { return 2 }
u_group :: proc{u1, u2}

@(test)
test_issue_7708 :: proc(t: ^testing.T) {
	a: M(1, 1, i32)
	b: M(3, 3, f64)
	testing.expect_value(t, m_group(a), 11)
	testing.expect_value(t, m_group(b), 33)
	testing.expect_value(t, m_forward(a), 11)
	testing.expect_value(t, m_forward(b), 33)
	testing.expect_value(t, c_group(a), 11)
	testing.expect_value(t, c_group(b), 33)
	testing.expect_value(t, p_group(&a), 11)
	testing.expect_value(t, p_group(&b), 33)

	ea_: E(.A, int)
	eb_: E(.B, int)
	testing.expect_value(t, e_group(ea_), 1)
	testing.expect_value(t, e_group(eb_), 2)

	sa_: S("a", int)
	sb_: S("b", int)
	testing.expect_value(t, s_group(sa_), 1)
	testing.expect_value(t, s_group(sb_), 2)

	u1_: U(1, int)
	u2_: U(2, int)
	testing.expect_value(t, u_group(u1_), 1)
	testing.expect_value(t, u_group(u2_), 2)
}
