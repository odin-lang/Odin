// What unoptimized x86 code is lowered to before LLVM's fast instruction selector sees it
package test_issue_fast_isel_lowering

import "core:testing"

Pair :: struct {
	name:  string,
	value: int,
}

Wide :: struct {
	a, b, c: i32,
	d:       [3]f32,
	e:       Pair,
	f:       bool,
}

@(require_results)
pick :: proc(cond: bool, x, y: Pair) -> Pair {
	return x if cond else y
}

@(require_results)
copy_through :: proc(dst, src: ^Wide) -> Wide {
	dst^ = src^
	return dst^
}

@(require_results)
classify :: proc(x: int) -> (res: string) {
	switch x {
	case 1:  res = "one"
	case 2:  res = "two"
	case 7:  res = "seven"
	case:    res = "other"
	}
	return
}

@(require_results)
shared_target :: proc(x: u8) -> int {
	r := 0
	switch x {
	case 3, 9: r = 10
	case 4:    r = 20
	}
	return r + int(x)
}

@(require_results)
both :: proc(a, b: bool) -> bool {
	return a && b
}

@(require_results)
either :: proc(a, b: bool) -> bool {
	return a || b
}

@(require_results)
count_true :: proc(xs: ..bool) -> (n: int) {
	for x in xs {
		n += int(x)
	}
	return
}

global_pair: Pair

@(test)
test_fast_isel_lowering :: proc(t: ^testing.T) {
	p := pick(true, {"a", 1}, {"bb", 2})
	q := pick(false, {"a", 1}, {"bb", 2})
	testing.expect_value(t, p, Pair{"a", 1})
	testing.expect_value(t, q, Pair{"bb", 2})

	s := "yes" if p.value == 1 else "no"
	testing.expect_value(t, s, "yes")

	global_pair = q
	testing.expect_value(t, global_pair.name, "bb")

	src := Wide{1, 2, 3, {4, 5, 6}, {"wide", 7}, true}
	dst: Wide
	w := copy_through(&dst, &src)
	testing.expect_value(t, w, src)
	testing.expect_value(t, dst, src)

	ws := []Wide{src, {}, src}
	ws[1] = ws[0]
	testing.expect_value(t, ws[1], src)

	merged: Pair
	if w.f {
		merged = p
	} else {
		merged = q
	}
	testing.expect_value(t, merged, p)

	names := [4]string{"one", "two", "seven", "other"}
	for x, i in ([]int{1, 2, 7, 5}) {
		testing.expect_value(t, classify(x), names[i])
	}
	testing.expect_value(t, shared_target(3), 13)
	testing.expect_value(t, shared_target(9), 19)
	testing.expect_value(t, shared_target(4), 24)
	testing.expect_value(t, shared_target(5), 5)

	a, b := w.a == 1, w.b == 3
	testing.expect_value(t, both(a, b), false)
	testing.expect_value(t, either(a, b), true)
	testing.expect_value(t, count_true(a, b, a && !b, a || b), 3)

	buf := [8]u8{1, 2, 3, 4, 5, 6, 7, 8}
	copy(buf[1:], buf[:4])
	testing.expect_value(t, buf, [8]u8{1, 1, 2, 3, 4, 6, 7, 8})
	small: [3]u8 = {9, 9, 9}
	small = {}
	testing.expect_value(t, small, [3]u8{})
}
