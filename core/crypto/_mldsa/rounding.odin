#+private
package _mldsa

power2round :: proc "contextless" (a: i32) -> (i32, i32) {
	a1 := (a + (1 << (D-1)) - 1) >> D
	a0 := a - (a1 << D)
	return a0, a1
}

decompose :: proc "contextless" (a: i32, gamma2: i32) -> (i32, i32) {
	a1 := (a + 127) >> 7
	switch gamma2 {
	case (Q - 1)/32:
		a1 = (a1 * 1025 + (1 << 21)) >> 22
		a1 &= 15
	case (Q - 1)/88:
		a1 = (a1 * 11275 + (1 << 23)) >> 24
		a1 ~= ((43 - a1) >> 31) & a1
	}

	a0 := a - a1 * 2 * gamma2
	a0 -= (((Q - 1)/2 - a0) >> 31) & Q
	return a0, a1
}

make_hint :: proc "contextless" (a0, a1: i32, gamma2: i32) -> uint {
	if (a0 > gamma2 || a0 < -gamma2 || (a0 == -gamma2 && a1 != 0)) {
		return 1
	}
	return 0
}

use_hint :: proc "contextless" (a: i32, hint: uint, gamma2: i32) -> i32 {
	a0, a1 := decompose(a, gamma2)
	if hint == 0 {
		return a1
	}

	switch gamma2 {
	case (Q - 1)/32:
		if (a0 > 0) {
			return (a1 + 1) & 15
		} else {
			return (a1 -1) & 15
		}
	case (Q - 1)/88:
		if (a0 > 0) {
			return (a1 == 43) ? 0 : a1 + 1
		} else {
			return (a1 == 0) ? 43 : a1 - 1
		}
	}

	unreachable()
}

