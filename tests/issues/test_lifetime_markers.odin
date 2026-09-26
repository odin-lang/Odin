package test_issues

import "core:testing"

// tests the -lifetime-markers compiler flag


peek :: #force_no_inline proc(buf: ^[8]int, i: int) -> int {
	return buf[i]
}

@(test)
test_defer_reads_local :: proc(t: ^testing.T) {
	v := 0
	{
		buf: [8]int
		defer v = peek(&buf, 3)
		buf[3] = 42
	}
	testing.expect_value(t, v, 42)
}

@(test)
test_return_from_nested :: proc(t: ^testing.T) {

	early_return :: proc(out: ^int, early_out: bool) {
		buf: [8]int
		defer out^ = peek(&buf, 5)
		{
			buf[5] = 42
			if early_out {
				return
			}
		}
		buf[5] = 43
	}

	r := 0
	early_return(&r, true)
	testing.expect_value(t, r, 42)
	early_return(&r, false)
	testing.expect_value(t, r, 43)
}

@(test)
test_break_out_of_nested :: proc(t: ^testing.T) {
	total := 0
	outer: for i in 0 ..< 4 {
		for j in 0 ..< 4 {
			buf: [8]int
			defer total += peek(&buf, 0)
			buf[0] = i*10 + j
			if j == 2 {
				break outer
			}
		}
	}
	// i == 0, j == 0, 1, 2
	testing.expect_value(t, total, 3)
}

@(test)
test_continue_defer :: proc(t: ^testing.T) {
	total := 0
	for i in 0 ..< 4 {
		buf: [8]int
		defer total += peek(&buf, 4)
		buf[4] = i
		if i % 2 == 0 {
			continue
		}
		buf[4] = 100 + i
	}
	// 0 + 101 + 2 + 103
	testing.expect_value(t, total, 206)
}

@(test)
test_switch_cases :: proc(t: ^testing.T) {

	switch_cases :: proc(x: int) -> int {
		r := 0
		switch x {
		case 1:
			a: [8]int
			defer r += peek(&a, 0)
			a[0] = 5
			fallthrough
		case 2:
			b: [8]int
			defer r += peek(&b, 1)
			b[1] = 7
		}
		return r
	}

	testing.expect_value(t, switch_cases(1), 12)
	testing.expect_value(t, switch_cases(2), 7)
	testing.expect_value(t, switch_cases(3), 0)
}


@(test)
test_type_switch_cases :: proc(t: ^testing.T) {

	Value :: union {
		int,
		[8]int,
	}

	type_switch_cases :: proc(v: Value) -> int {
		r := 0
		switch x in v {
		case [8]int:
			copied := x
			defer r = peek(&copied, 2)
			copied[2] += 1
		case int:
			r = x
		}
		return r
	}

	v: Value = [8]int{2 = 9}
	testing.expect_value(t, type_switch_cases(v), 10)
	v = 3
	testing.expect_value(t, type_switch_cases(v), 3)
}

@(test)
test_or_return_runs_defer :: proc(t: ^testing.T) {

	or_return_helper :: proc(out: ^int, ok: bool) -> bool {

		f :: #force_no_inline proc(b: bool) -> bool {
			return b
		}

		buf: [8]int
		defer out^ = peek(&buf, 2)
		buf[2] = 31
		f(ok) or_return
		buf[2] = 32
		return true
	}

	r := 0
	testing.expect_value(t, or_return_helper(&r, false), false)
	testing.expect_value(t, r, 31)
	testing.expect_value(t, or_return_helper(&r, true), true)
	testing.expect_value(t, r, 32)
}

@(test)
test_sret_forwarding :: proc(t: ^testing.T) {

	Big :: struct {
		data: [32]int,
	}

	make_big :: #force_no_inline proc(src: ^[32]int) -> (b: Big) {
		b.data = src^
		return
	}

	init_big :: proc() -> Big {
		tmp: [32]int
		for i in 0 ..< 32 {
			tmp[i] = i * 3
		}
		tmp[7] = 1234
		return make_big(&tmp)
	}

	b := init_big()
	testing.expect_value(t, b.data[7], 1234)
	testing.expect_value(t, b.data[31], 93)
}
