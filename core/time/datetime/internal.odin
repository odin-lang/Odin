#+private
package datetime

// Internal helper functions for calendrical conversions

import "base:intrinsics"

sign :: proc "contextless" (v: i64) -> (res: i64) {
	if v == 0 {
		return 0
	} else if v > 0 {
		return 1
	}
	return -1
}

// Caller has to ensure y != 0
divmod :: proc "contextless" (x, y: $T, loc := #caller_location) -> (a: T, r: T)
	where intrinsics.type_is_integer(T) {
	a = x / y
	r = x % y
	if (r > 0 && y < 0) || (r < 0 && y > 0) {
		a -= 1
		r += y
	}
	return a, r
}

// Divides and floors
floor_div :: proc "contextless" (x, y: $T) -> (res: T)
	where intrinsics.type_is_integer(T) {
	res = x / y
	r  := x % y
	if (r > 0 && y < 0) || (r < 0 && y > 0) {
		res -= 1
	}
	return res
}

// Half open: x mod [1..b]
interval_mod :: proc "contextless" (x, a, b: i64) -> (res: i64) {
	if a == b {
		return x
	}
	return a + ((x - a) %% (b - a))
}

// x mod [1..b]
adjusted_remainder :: proc "contextless" (x, b: i64) -> (res: i64) {
	m := x %% b
	return b if m == 0 else m
}

gcd :: proc "contextless" (x, y: i64) -> (res: i64) {
	if y == 0 {
		return x
	}

	m := x %% y
	return gcd(y, m)
}

lcm :: proc "contextless" (x, y: i64) -> (res: i64) {
	return x * y / gcd(x, y)
}

sum :: proc "contextless" (i: i64, f: proc "contextless" (n: i64) -> i64, cond: proc "contextless" (n: i64) -> bool) -> (res: i64) {
	for idx := i; cond(idx); idx += 1 {
		res += f(idx)
	}
	return
}

product :: proc "contextless" (i: i64, f: proc "contextless" (n: i64) -> i64, cond: proc "contextless" (n: i64) -> bool) -> (res: i64) {
	res = 1
	for idx := i; cond(idx); idx += 1 {
		res *= f(idx)
	}
	return
}

smallest :: proc "contextless" (k: i64, cond: proc "contextless" (n: i64) -> bool) -> (d: i64) {
	k := k
	for !cond(k) {
		k += 1
	}
	return k
}

biggest :: proc "contextless" (k: i64, cond: proc "contextless" (n: i64) -> bool) -> (d: i64) {
	k := k
	for !cond(k) {
		k -= 1
	}
	return k
}