#+feature using-stmt
package test_internal

import "base:intrinsics"
import "core:fmt"
import "core:reflect"
import "core:testing"

@(private="file")
Split_Vec :: struct {
	x, y, z: f32,
}

@(private="file")
Split_Particle :: struct {
	#soa_split pos: Split_Vec,
	vel:            Split_Vec,
	#soa_split col: [4]u8,
	id:             i64,
}

@(private="file")
Split_Nested :: struct {
	#soa_split p: Split_Particle,
	w:            f64,
}

// More columns than the #soa append stores elements one at a time for
@(private="file")
Split_Wide :: struct {
	#soa_split a: [4]u32,
	#soa_split b: [4]u32,
	#soa_split c: [4]u32,
	#soa_split d: [4]u32,
	#soa_split e: struct { x, y: u16 },
}

@(private="file")
split_particle :: proc(i: int) -> Split_Particle {
	f := f32(i)
	return {pos = {f, f + 1, f + 2}, vel = {-f, -f - 1, -f - 2}, col = {u8(i), u8(i + 1), u8(i + 2), u8(i + 3)}, id = i64(i)*10}
}

@(private="file")
split_wide :: proc(i: int) -> (w: Split_Wide) {
	k := u32(i)*100
	w.a = {k, k + 1, k + 2, k + 3}
	w.b = w.a + 10
	w.c = w.a + 20
	w.d = w.a + 30
	w.e = {u16(i), u16(i + 1)}
	return
}

@(private="file")
expect_split_particles :: proc(t: ^testing.T, s: #soa[]Split_Particle, loc := #caller_location) {
	for i in 0..<len(s) {
		testing.expect_value(t, s[i], split_particle(i), loc)
	}
}

// A '#soa_split' field takes one column for each of its own fields (or lanes), in its place
@(test)
test_soa_split_columns :: proc(t: ^testing.T) {
	testing.expect_value(t, intrinsics.type_soa_field_sizes(#soa[]Split_Particle)^, [9]int{4, 4, 4, 12, 1, 1, 1, 1, 8})
	testing.expect_value(t, len(intrinsics.type_soa_field_sizes(#soa[dynamic]Split_Nested)^), 10)
	testing.expect_value(t, len(intrinsics.type_soa_field_sizes(#soa[]Split_Wide)^), 18)
	testing.expect_value(t, size_of(#soa[4]Split_Particle), 4*(3*4 + 12 + 4 + 8))
	testing.expect_value(t, reflect.soa_field_count(#soa[dynamic]Split_Particle), 9)

	s: #soa[2]Split_Particle
	s[1] = split_particle(1)
	testing.expect_value(t, reflect.soa_field_value(s, 1, 1).(f32), 2)
	testing.expect_value(t, reflect.soa_field_value(s, 1, 3).(Split_Vec), Split_Vec{-1, -2, -3})
	testing.expect_value(t, reflect.soa_field_value(s, 1, 6).(u8), 3)
	testing.expect_value(t, reflect.soa_field_value(s, 1, 8).(i64), 10)

	// The flag is part of the type
	testing.expect(t, typeid_of(struct { #soa_split v: Split_Vec }) == typeid_of(struct { #soa_split v: Split_Vec }))
	testing.expect(t, typeid_of(struct { #soa_split v: Split_Vec }) != typeid_of(struct { v: Split_Vec }))
}

@(private="file")
split_sum_x :: proc(v: #soa[]Split_Vec) -> (sum: f32) {
	for e in v {
		sum += e.x
	}
	return
}

// Every #soa kind stores and loads its elements through the columns, and has an '#soa[]' view of the columns of a '#soa_split' field
@(test)
test_soa_split_kinds :: proc(t: ^testing.T) {
	fixed: #soa[5]Split_Particle
	for i in 0..<len(fixed) {
		fixed[i] = split_particle(i)
	}
	expect_split_particles(t, fixed[:])
	testing.expect_value(t, typeid_of(type_of(fixed.pos)), typeid_of(#soa[]Split_Vec))
	testing.expect_value(t, typeid_of(type_of(fixed.col)), typeid_of(#soa[][4]u8))
	testing.expect_value(t, len(fixed.pos), 5)
	testing.expect_value(t, fixed.pos[2], Split_Vec{2, 3, 4})
	testing.expect_value(t, fixed.col[2], [4]u8{2, 3, 4, 5})
	testing.expect_value(t, split_sum_x(fixed.pos), 10)
	testing.expect_value(t, split_sum_x(fixed.pos[1:3]), 3)
	fixed.pos[1].z = 99
	fixed.pos.x[3] = 42
	fixed.col.w[0] = 7
	testing.expect_value(t, fixed[1].pos, Split_Vec{1, 2, 99})
	testing.expect_value(t, fixed[3].pos.x, 42)
	testing.expect_value(t, fixed[0].col, [4]u8{0, 1, 2, 7})

	slice := make_soa(#soa[]Split_Particle, 5)
	defer delete(slice)
	for i in 0..<len(slice) {
		slice[i] = split_particle(i)
	}
	expect_split_particles(t, slice)
	testing.expect_value(t, slice[1:4].pos.x[0], 1)

	dynamic_array: #soa[dynamic]Split_Particle
	defer delete(dynamic_array)
	for i in 0..<40 {
		append(&dynamic_array, split_particle(i))
	}
	expect_split_particles(t, dynamic_array[:])
	for &v, i in dynamic_array.pos {
		v.y = f32(i*100)
	}
	pd := &dynamic_array
	testing.expect_value(t, len(pd.pos), 40)
	testing.expect_value(t, pd.pos[4], Split_Vec{4, 400, 6})
	testing.expect_value(t, dynamic_array[3].vel, split_particle(3).vel)

	appended: #soa[dynamic]Split_Particle
	defer delete(appended)
	append(&appended, split_particle(0), split_particle(1), split_particle(2))
	expect_split_particles(t, appended[:])

	capacity: #soa[dynamic; 8]Split_Particle
	for i in 0..<6 {
		append(&capacity, split_particle(i))
	}
	expect_split_particles(t, capacity[:])
	testing.expect_value(t, len(capacity.pos), 6)
	testing.expect_value(t, capacity.pos.z[1], 3)
	testing.expect_value(t, capacity.col[0], [4]u8{0, 1, 2, 3})

	wide: #soa[dynamic]Split_Wide
	defer delete(wide)
	append(&wide, split_wide(0), split_wide(1), split_wide(2), split_wide(3))
	append(&wide, split_wide(4))
	testing.expect_value(t, len(wide), 5)
	for i in 0..<len(wide) {
		testing.expect_value(t, wide[i], split_wide(i))
	}
}

@(private="file")
split_set :: proc(using p: #soa^#soa[]Split_Particle) {
	pos.y = 50
	pos = {pos.x, pos.y, 51}
	col.w = 7
}

// The fields of a '#soa_split' field select its columns: as a value, a field, a lane, or a swizzle
@(test)
test_soa_split_fields :: proc(t: ^testing.T) {
	s: #soa[4]Split_Particle
	s[1] = split_particle(1)
	testing.expect_value(t, s[1].pos, Split_Vec{1, 2, 3})
	testing.expect_value(t, s[1].pos.y, 2)
	testing.expect_value(t, s[1].col, [4]u8{1, 2, 3, 4})
	testing.expect_value(t, s[1].col.z, 3)
	testing.expect_value(t, s[1].col.wx, [2]u8{4, 1})
	j := 3
	testing.expect_value(t, s[1].col[j], 4)
	testing.expect_value(t, s[1].id, 10)

	s[2].pos = {10, 20, 30}
	s[2].pos.z += 3
	s[2].col.yx = {1, 2}
	s[2].col[j] = 99
	s[2].col += 1
	testing.expect_value(t, s[2], Split_Particle{pos = {10, 20, 33}, col = {3, 2, 1, 100}})

	p := &s[2].pos.y
	p^ = 7
	testing.expect_value(t, s[2].pos.y, 7)

	for x, k in s[1].col {
		testing.expect_value(t, x, u8(k + 1))
	}
	for &x in s[3].col {
		x = 5
	}
	testing.expect_value(t, s[3].col, [4]u8{5, 5, 5, 5})

	for &e, i in s {
		e.pos.x = f32(i)
	}
	for e, i in s {
		testing.expect_value(t, e.pos.x, f32(i))
	}

	sp := &s[0]
	sp.pos = {1, 1, 1}
	sp.pos.x = 4
	testing.expect_value(t, s[0].pos, Split_Vec{4, 1, 1})

	slice := s[:]
	split_set(&slice[3])
	testing.expect_value(t, s[3].pos, Split_Vec{3, 50, 51})
	testing.expect_value(t, s[3].col, [4]u8{5, 5, 5, 7})

	slice[0].pos = slice[1].pos
	testing.expect_value(t, s[0].pos, Split_Vec{1, 2, 3})

	n: #soa[2]Split_Nested
	n[1] = {p = split_particle(5), w = 1.5}
	n[1].p.pos.z = 30
	n[1].p.col.w = 9
	want := split_particle(5)
	want.pos.z = 30
	want.col.w = 9
	testing.expect_value(t, n[1], Split_Nested{p = want, w = 1.5})
	testing.expect_value(t, n[0], Split_Nested{})

	n.p.pos[0].x = 7
	testing.expect_value(t, typeid_of(type_of(n.p)), typeid_of(#soa[]Split_Particle))
	testing.expect_value(t, n.p[1], want)
	testing.expect_value(t, n.p.pos[1], want.pos)
	testing.expect_value(t, n.p.vel[1], want.vel)
	testing.expect_value(t, n[0].p.pos, Split_Vec{7, 0, 0})

	// A lane of an array element holds the whole value, '#soa_split' fields included
	lanes: #soa[2][2]Split_Particle
	lanes[1][0] = split_particle(3)
	lanes[1][0].pos.y = 9
	q := &lanes[1][0].pos
	q.z = 8
	want = split_particle(3)
	want.pos.y = 9
	want.pos.z = 8
	testing.expect_value(t, lanes[1], [2]Split_Particle{want, {}})
}

@(private="file")
Split_Body :: struct {
	#soa_split pos: [3]f32,
	#soa_split vel: [3]f32,
	life:           f32,
}

// Arithmetic on a '#soa_split' array, and on the elements of an #soa array of arrays, one lane per column
@(test)
test_soa_split_arithmetic :: proc(t: ^testing.T) {
	bs: #soa[dynamic]Split_Body
	defer delete(bs)
	for i in 0..<37 {
		append(&bs, Split_Body{pos = {f32(i), 1, 2}, vel = {1, 2, 3}, life = f32(i % 2)})
	}
	for &b in bs {
		b.pos += b.vel * 0.5
	}
	for &b in bs {
		if b.life > 0 {
			b.pos = b.pos*2 - b.vel
		}
	}
	for b, i in bs {
		want := [3]f32{f32(i) + 0.5, 2, 3.5}
		if i % 2 == 1 {
			want = want*2 - [3]f32{1, 2, 3}
		}
		testing.expect_value(t, b.pos, want)
	}

	vs: #soa[dynamic][4]i32
	defer delete(vs)
	for i in 0..<21 {
		append(&vs, [4]i32{i32(i), 1, 2, 3})
	}
	k := 5
	vs[k] += 10
	for &v in vs {
		v = v*3 + 1
	}
	testing.expect_value(t, vs[20], [4]i32{61, 4, 7, 10})
	testing.expect_value(t, vs[k], [4]i32{46, 34, 37, 40})
}

// 'soa_unzip' gives one result for each field of the element, and the '#soa[]' view of a '#soa_split' field
@(test)
test_soa_split_unzip :: proc(t: ^testing.T) {
	s: #soa[3]Split_Particle
	for i in 0..<len(s) {
		s[i] = split_particle(i)
	}
	pos, vel, col, id := soa_unzip(s[:])
	testing.expect_value(t, typeid_of(type_of(pos)), typeid_of(#soa[]Split_Vec))
	testing.expect_value(t, typeid_of(type_of(col)), typeid_of(#soa[][4]u8))
	testing.expect_value(t, len(pos), 3)
	testing.expect_value(t, pos[2], Split_Vec{2, 3, 4})
	testing.expect_value(t, vel[1], split_particle(1).vel)
	testing.expect_value(t, col.w[2], 5)
	testing.expect_value(t, id[2], 20)

	xs, ys, zs := soa_unzip(s.pos)
	testing.expect_value(t, xs[1], 1)
	testing.expect_value(t, ys[1], 2)
	testing.expect_value(t, zs[1], 3)

	Only :: struct {
		#soa_split v: Split_Vec,
	}
	o: #soa[2]Only
	o[1] = {{1, 2, 3}}
	only := soa_unzip(o[:])
	testing.expect_value(t, typeid_of(type_of(only)), typeid_of(#soa[]Split_Vec))
	testing.expect_value(t, only[1], Split_Vec{1, 2, 3})
}

@(private="file")
Split_Six :: struct {
	#soa_split pos: Split_Vec,
	#soa_split vel: Split_Vec,
}

@(private="file")
Split_Three :: struct {
	#soa_split p: [2]f64,
	w:            i64,
}

// Columns of one size that fill the element are copied in transposed blocks, which '#soa_split' fields can make
@(test)
test_soa_split_copy :: proc(t: ^testing.T) {
	testing.expect_value(t, intrinsics.type_soa_field_sizes(#soa[]Split_Six)^, [6]int{4, 4, 4, 4, 4, 4})
	testing.expect_value(t, intrinsics.type_soa_field_sizes(#soa[]Split_Three)^, [3]int{8, 8, 8})

	six:   [37]Split_Six
	three: [37]Split_Three
	for i in 0..<len(six) {
		f := f32(i)
		six[i]   = {{f, f + 1, f + 2}, {-f, -f - 1, -f - 2}}
		three[i] = {{f64(i), f64(i)*2}, i64(i)*3}
	}

	soa_six:   #soa[37]Split_Six
	soa_three: #soa[37]Split_Three
	testing.expect_value(t, copy(soa_six[:], six[:]), 37)
	testing.expect_value(t, copy(soa_three[:], three[:]), 37)
	testing.expect_value(t, ([37]Split_Six)(soa_six), six)
	testing.expect_value(t, ([37]Split_Three)(soa_three), three)

	back_six:   [37]Split_Six
	back_three: [37]Split_Three
	copy(back_six[:], soa_six[:])
	copy(back_three[:], soa_three[:])
	testing.expect_value(t, back_six, six)
	testing.expect_value(t, back_three, three)
}

@(private="file")
SPLIT_CONSTANT :: #soa[2]Split_Particle{{{1, 2, 3}, {4, 5, 6}, {7, 8, 9, 10}, 11}, {id = 12}}

@(private="file", rodata)
g_split := #soa[2]Split_Particle{{pos = {1, 2, 3}, id = 4}, {col = {5, 6, 7, 8}}}

// Constants, and conversions to and from arrays, place each field in its column
@(test)
test_soa_split_constants_and_conversions :: proc(t: ^testing.T) {
	testing.expect_value(t, SPLIT_CONSTANT.id, [2]i64{11, 12})
	testing.expect_value(t, SPLIT_CONSTANT.vel, [2]Split_Vec{{4, 5, 6}, {}})
	testing.expect_value(t, SPLIT_CONSTANT[0].pos, Split_Vec{1, 2, 3})
	testing.expect_value(t, SPLIT_CONSTANT[1].id, 12)
	testing.expect_value(t, g_split[0], Split_Particle{pos = {1, 2, 3}, id = 4})
	testing.expect_value(t, g_split[1], Split_Particle{col = {5, 6, 7, 8}})

	a: [3]Split_Particle
	for &v, i in a {
		v = split_particle(i)
	}
	s := (#soa[3]Split_Particle)(a)
	expect_split_particles(t, s[:])
	testing.expect_value(t, ([3]Split_Particle)(s), a)
}

// Formatting an element in place gives the text of the element as a value
@(test)
test_soa_split_fmt :: proc(t: ^testing.T) {
	s: #soa[2]Split_Particle
	s[0] = split_particle(1)
	testing.expect_value(t, fmt.tprint(s), fmt.tprint([2]Split_Particle{split_particle(1), {}}))
	testing.expect_value(t, fmt.tprintf("%#v", s), fmt.tprintf("%#v", [2]Split_Particle{split_particle(1), {}}))

	n: #soa[1]Split_Nested
	n[0] = {p = split_particle(2), w = 3}
	testing.expect_value(t, fmt.tprint(n), fmt.tprint([1]Split_Nested{{p = split_particle(2), w = 3}}))
}
