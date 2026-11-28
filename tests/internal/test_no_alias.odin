package test_internal

import "core:testing"

@(private="file")
N :: 17 // not a multiple of a vector loop's step

@(private="file")
add_into :: proc(#no_alias out: []f32, a: []f32) {
	for &v, i in out {
		v += a[i]
	}
}

@(private="file")
add_from :: proc(out: []f32, #no_alias a: []f32) {
	for &v, i in out {
		v += a[i]
	}
}

@(private="file")
add_contextless :: proc "contextless" (#no_alias out: []f32, a: []f32) {
	for &v, i in out {
		v += a[i]
	}
}

@(private="file")
add_c :: proc "c" (#no_alias out: []f32, a: []f32) {
	for &v, i in out {
		v += a[i]
	}
}

@(private="file")
add_sum :: proc(#no_alias out: []f32, a: []f32) -> (total: f32, n: int) {
	for &v, i in out {
		v += a[i]
		total += v
	}
	return total, len(out)
}

@(private="file")
add_big :: proc(#no_alias out: []f64, a: []f64) -> (r: [8]f64) {
	defer r[7] = 7
	for &v, i in out {
		v += a[i]
	}
	r[0] = out[0]
	return
}

@(private="file")
check_added :: proc(t: ^testing.T, out: []f32, loc := #caller_location) {
	for v, i in out {
		testing.expect_value(t, v, f32(i + 10*i), loc)
	}
}

@(private="file")
reset :: proc(out, a: []f32) {
	for i in 0..<len(out) {
		out[i] = f32(i)
		a[i]   = f32(10*i)
	}
}

@test
test_no_alias_slices :: proc(t: ^testing.T) {
	out_array, a_array: [N]f32
	out, a := out_array[:], a_array[:]

	reset(out, a); add_into(out, a);        check_added(t, out)
	reset(out, a); add_from(out, a);        check_added(t, out)
	reset(out, a); add_contextless(out, a); check_added(t, out)
	reset(out, a); add_c(out, a);           check_added(t, out)

	// NOTE(bill): `#no_alias` is not part of the type
	f: proc(out: []f32, a: []f32) = add_into
	reset(out, a); f(out, a); check_added(t, out)

	reset(out, a)
	total, n := add_sum(out, a)
	check_added(t, out)
	testing.expect_value(t, n, N)
	testing.expect_value(t, total, f32(11*N*(N-1)/2))

	out64, a64: [N]f64
	for i in 0..<N {
		out64[i] = 1
		a64[i]   = f64(i)
	}
	r := add_big(out64[:], a64[:])
	testing.expect_value(t, r[0], 1)
	testing.expect_value(t, r[7], 0) // deferred after the result is taken
	testing.expect_value(t, out64[N-1], f64(N))
}

@(private="file")
add_bytes :: proc(out: []u8, #no_alias s: string) {
	for &b, i in out {
		b += s[i]
	}
}

@(private="file")
add_dynamic :: proc(#no_alias d: [dynamic]f32, a: []f32) {
	for &v, i in d {
		v += a[i]
	}
}

@test
test_no_alias_strings_and_dynamic_arrays :: proc(t: ^testing.T) {
	s := "abcdefghijklmnopq"
	out: [N]u8
	for &b in out {
		b = 1
	}
	add_bytes(out[:], s)
	for b, i in out {
		testing.expect_value(t, b, s[i] + 1)
	}

	d: [dynamic]f32
	defer delete(d)
	a: [N]f32
	for i in 0..<N {
		append(&d, f32(i))
		a[i] = f32(10*i)
	}
	add_dynamic(d, a[:])
	check_added(t, d[:])
}

@(private="file")
Particle :: struct {
	x, vx, life: f32,
}

@(private="file")
step :: proc(#no_alias ps: #soa[]Particle) {
	for &p in ps {
		p.x    += p.vx
		p.life -= 1
	}
}

@(private="file")
step_dynamic :: proc(#no_alias ps: #soa[dynamic]Particle) {
	for i in 0..<len(ps) {
		ps[i].x += ps[i].vx
	}
}

@test
test_no_alias_soa :: proc(t: ^testing.T) {
	array: #soa[N]Particle
	for i in 0..<N {
		array[i] = {x = f32(i), vx = 0.5, life = 3}
	}
	step(array[:])
	for i in 0..<N {
		testing.expect_value(t, array[i].x, f32(i) + 0.5)
		testing.expect_value(t, array[i].life, 2)
	}

	ps: #soa[dynamic]Particle
	defer delete_soa(ps)
	for i in 0..<N {
		append_soa(&ps, Particle{x = f32(i), vx = 2})
	}
	step_dynamic(ps)
	for i in 0..<N {
		testing.expect_value(t, ps[i].x, f32(i) + 2)
	}
}

@(private="file")
scale :: proc(#no_alias out: []$T, k: T) {
	for &v in out {
		v *= k
	}
}

// NOTE(bill): read-only parameters may share memory
@(private="file")
dot :: proc(#no_alias a, b: []f32) -> (sum: f32) {
	for x, i in a {
		sum += x*b[i]
	}
	return
}

@(private="file")
sum_all :: proc(#no_alias xs: ..f32) -> (sum: f32) {
	for x in xs {
		sum += x
	}
	return
}

@(private="file")
fill_halves :: proc(#no_alias out: []int, value: int) {
	if len(out) <= 1 {
		for &v in out {
			v = value
		}
		return
	}
	half := len(out)/2
	fill_halves(out[:half], value)
	fill_halves(out[half:], value + 1)
}

@(private="file")
with_nested :: proc(#no_alias out: []int) {
	double :: proc(x: int) -> int {
		return 2*x
	}
	for &v, i in out {
		v = double(i)
	}
}

@(private="file")
fail :: proc(#no_alias message: string) -> ! {
	panic(message)
}

@test
test_no_alias_other_forms :: proc(t: ^testing.T) {
	xs := [4]f32{1, 2, 3, 4}
	scale(xs[:], 2)
	testing.expect_value(t, xs, [4]f32{2, 4, 6, 8})

	testing.expect_value(t, dot(xs[:], xs[:]), 120)
	testing.expect_value(t, sum_all(1, 2, 3), 6)
	testing.expect_value(t, sum_all(..xs[:]), 20)

	halves: [4]int
	fill_halves(halves[:], 1)
	testing.expect_value(t, halves, [4]int{1, 2, 2, 3})

	doubled: [4]int
	with_nested(doubled[:])
	testing.expect_value(t, doubled, [4]int{0, 2, 4, 6})

	// NOTE(bill): built, not called
	failing := fail
	testing.expect(t, failing != nil)
}
