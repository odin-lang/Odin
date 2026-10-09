// Tests issue #7708 https://github.com/odin-lang/Odin/issues/7708
// A record argument whose constant parameters differ from the parameter's must be rejected
package test_issues

M :: struct($R, $C: int, $T: typeid) { data: [C][R]T }

m11 :: proc(m: M(1, 1, $T)) -> int { return 11 }
c11 :: proc(m: $X/M(1, 1, $T)) -> int { return 11 }

main :: proc() {
	m: M(3, 3, f64)
	_ = m11(m)
	_ = c11(m)
}
