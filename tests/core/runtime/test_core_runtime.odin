#+feature dynamic-literals
#+feature using-stmt
package test_core_runtime

import "base:intrinsics"
import "core:mem"
import "base:runtime"
import "core:slice"
import "core:testing"

// Tests that having space for the allocation, but not for the allocation and alignment
// is handled correctly.
@(test)
test_temp_allocator_alignment_boundary :: proc(t: ^testing.T) {
	arena: runtime.Arena
	context.allocator = runtime.arena_allocator(&arena)
	defer runtime.arena_destroy(&arena)

	_, _ = mem.alloc(int(runtime.DEFAULT_ARENA_GROWING_MINIMUM_BLOCK_SIZE)-120)
	_, err := mem.alloc(112, 32)
	testing.expect(t, err == nil)
}

// Tests that big allocations with big alignments are handled correctly.
@(test)
test_temp_allocator_big_alloc_and_alignment :: proc(t: ^testing.T) {
	arena: runtime.Arena
	context.allocator = runtime.arena_allocator(&arena)
	defer runtime.arena_destroy(&arena)

	mappy: map[[8]int]int
	err := reserve(&mappy, 50000)
	testing.expect(t, err == nil)
}

@(test)
test_align_bumping_block_limit :: proc(t: ^testing.T) {
	a: runtime.Arena
	a.minimum_block_size = 8*mem.Megabyte
	defer runtime.arena_destroy(&a)

	data, err := runtime.arena_alloc(&a, 4193371, 1)
	testing.expect_value(t, err, nil)
	testing.expect(t, len(data) == 4193371)

	data, err = runtime.arena_alloc(&a, 896, 64)
	testing.expect_value(t, err, nil)
	testing.expect(t, len(data) == 896)
}

@(test)
test_temp_allocator_returns_correct_size :: proc(t: ^testing.T) {
	arena: runtime.Arena
	context.allocator = runtime.arena_allocator(&arena)
	defer runtime.arena_destroy(&arena)

	bytes, err := mem.alloc_bytes(10, 16)
	testing.expect(t, err == nil)
	testing.expect(t, len(bytes) == 10)
}

@(test)
test_init_cap_map_dynarray :: proc(t: ^testing.T) {
	m1 := make(map[int]string)
	defer delete(m1)
	testing.expect(t, cap(m1) == 0)
	testing.expect(t, m1.allocator.procedure == context.allocator.procedure)

	ally := context.temp_allocator
	m2 := make(map[int]string, ally)
	defer delete(m2)
	testing.expect(t, cap(m2) == 0)
	testing.expect(t, m2.allocator.procedure == ally.procedure)

	d1 := make([dynamic]string)
	defer delete(d1)
	testing.expect(t, cap(d1) == 0)
	testing.expect(t, d1.allocator.procedure == context.allocator.procedure)

	d2 := make([dynamic]string, ally)
	defer delete(d2)
	testing.expect(t, cap(d2) == 0)
	testing.expect(t, d2.allocator.procedure == ally.procedure)
}

@(test)
test_map_get :: proc(t: ^testing.T) {
	check :: proc(t: ^testing.T, m: map[$K]$V, loc := #caller_location) {
		for k, v in m {
			got_key, got_val, ok := runtime.map_get(m, k)
			testing.expect_value(t, got_key, k, loc = loc)
			testing.expect_value(t, got_val, v, loc = loc)
			testing.expect(t, ok, loc = loc)
		}
	}

	// small keys & values
	{
		m := map[int]int{
			1 = 10,
			2 = 20,
			3 = 30,
		}
		defer delete(m)
		check(t, m)
	}

	// small keys; 2 values per cell
	{
		m := map[int][3]int{
			1 = [3]int{10, 100, 1000},
			2 = [3]int{20, 200, 2000},
			3 = [3]int{30, 300, 3000},
		}
		defer delete(m)
		check(t, m)
	}

	// 2 keys per cell; small values
	{
		m := map[[3]int]int{
			[3]int{10, 100, 1000} = 1,
			[3]int{20, 200, 2000} = 2,
			[3]int{30, 300, 3000} = 3,
		}
		defer delete(m)
		check(t, m)
	}


	// small keys; 3 values per cell
	{
		val :: struct #packed {
			a, b: int,
			c:    i32,
		}
		m := map[int]val{
			1 = val{10, 100, 1000},
			2 = val{20, 200, 2000},
			3 = val{30, 300, 3000},
		}
		defer delete(m)
		check(t, m)
	}

	// 3 keys per cell; small values
	{
		key :: struct #packed {
			a, b: int,
			c:    i32,
		}
		m := map[key]int{
			key{10, 100, 1000} = 1,
			key{20, 200, 2000} = 2,
			key{30, 300, 3000} = 3,
		}
		defer delete(m)
		check(t, m)
	}

	// small keys; value bigger than a chacheline
	{
		m := map[int][9]int{
			1 = [9]int{10, 100, 1000, 10000, 100000, 1000000, 10000000, 100000000, 1000000000},
			2 = [9]int{20, 200, 2000, 20000, 200000, 2000000, 20000000, 200000000, 2000000000},
			3 = [9]int{30, 300, 3000, 30000, 300000, 3000000, 30000000, 300000000, 3000000000},
		}
		defer delete(m)
		check(t, m)
	}
	// keys bigger than a chacheline; small values
	{
		m := map[[9]int]int{
			[9]int{10, 100, 1000, 10000, 100000, 1000000, 10000000, 100000000, 1000000000} = 1,
			[9]int{20, 200, 2000, 20000, 200000, 2000000, 20000000, 200000000, 2000000000} = 2,
			[9]int{30, 300, 3000, 30000, 300000, 3000000, 30000000, 300000000, 3000000000} = 3,
		}
		defer delete(m)
		check(t, m)
	}
}

@(test)
test_soa_array_resize :: proc(t: ^testing.T) {

	V :: struct {x: int, y: u8}

	array := make(#soa[dynamic]V, 0, 2)
	defer delete(array)

	append(&array, V{1, 2}, V{3, 4})

	testing.expect_value(t, len(array), 2)
	testing.expect_value(t, array[0], V{1, 2})
	testing.expect_value(t, array[1], V{3, 4})

	resize(&array, 1)

	testing.expect_value(t, len(array), 1)
	testing.expect_value(t, array[0], V{1, 2})

	resize(&array, 2)

	testing.expect_value(t, len(array), 2)
	testing.expect_value(t, array[0], V{1, 2})
	testing.expect_value(t, array[1], V{0, 0})

	resize(&array, 0)
	resize(&array, 3)

	testing.expect_value(t, len(array), 3)
	testing.expect_value(t, array[0], V{0, 0})
	testing.expect_value(t, array[1], V{0, 0})
	testing.expect_value(t, array[2], V{0, 0})
}

@(test)
test_soa_make_len :: proc(t: ^testing.T) {

	array, err := make(#soa[dynamic][2]int, 2)
	defer delete(array)
	array[0] = [2]int{1, 2}
	array[1] = [2]int{3, 4}

	testing.expect_value(t, err, nil)
	testing.expect_value(t, len(array), 2)
	testing.expect_value(t, cap(array), 2)

	testing.expect_value(t, array[0], [2]int{1, 2})
	testing.expect_value(t, array[1], [2]int{3, 4})
}

// storing an all-zero constant into a slice/dynamic #soa element
@(test)
test_soa_zero_elem_store :: proc(t: ^testing.T) {

	V :: struct {a: u8, b: u16, c: u32, d: u64, e: u128}
	one := V{1, 2, 3, 4, 5}

	array := make(#soa[dynamic]V, 0, 8)
	defer delete(array)
	for _ in 0 ..< 8 {
		append(&array, one)
	}

	array[2] = {}
	array[5] = V{0, 0, 0, 0, 0}

	s: #soa[]V = array[:]
	s[7] = V{}

	for i in 0 ..< 8 {
		expected := one if i != 2 && i != 5 && i != 7 else V{}
		testing.expect_value(t, array[i], expected)
	}
}


V_Padded :: struct {a: i32, b: f64, c: f32}
soa_padded_global := #soa[3]V_Padded{
	{a = 1, b = 1.0, c = 1.0},
	{a = 2, b = 2.0, c = 1.0},
	{a = 3, b = 3.0, c = 1.0},
}

// fixed #soa compound literals with a padded element struct
@(test)
test_soa_fixed_compound_literal :: proc(t: ^testing.T) {
	for i in 0 ..< 3 {
		testing.expect_value(t, soa_padded_global[i], V_Padded{i32(i + 1), f64(i + 1), 1.0})
	}

	local := #soa[3]V_Padded{
		{a = 1, b = 1.0, c = 1.0},
		{a = 2, b = 2.0, c = 1.0},
		{a = 3, b = 3.0, c = 1.0},
	}
	for i in 0 ..< 3 {
		testing.expect_value(t, local[i], V_Padded{i32(i + 1), f64(i + 1), 1.0})
	}

	sparse := #soa[4]V_Padded{
		0 ..= 1 = {a = 7, b = 7.0, c = 7.0},
		3 = {a = 9, b = 9.0, c = 9.0},
	}
	testing.expect_value(t, sparse[0], V_Padded{7, 7.0, 7.0})
	testing.expect_value(t, sparse[1], V_Padded{7, 7.0, 7.0})
	testing.expect_value(t, sparse[2], V_Padded{})
	testing.expect_value(t, sparse[3], V_Padded{9, 9.0, 9.0})
}

// swizzling an element of an #soa container with an array element type
@(test)
test_soa_array_elem_swizzle :: proc(t: ^testing.T) {

	ref := [4]u16{1, 2, 3, 4} // reference

	fixed: #soa[3][4]u16
	fixed.x[0], fixed.y[0], fixed.z[0], fixed.w[0] = 90, 91, 92, 93
	fixed.x[1], fixed.y[1], fixed.z[1], fixed.w[1] = 1, 2, 3, 4

	testing.expect_value(t, fixed[1].x, ref.x)
	testing.expect_value(t, fixed[1].xy, ref.xy)
	testing.expect_value(t, fixed[1].xyz, ref.xyz)
	testing.expect_value(t, fixed[1].xyzw, ref.xyzw)
	testing.expect_value(t, fixed[1].yx, ref.yx)   // permuted
	testing.expect_value(t, fixed[1].xx, ref.xx)   // repeated
	testing.expect_value(t, fixed[1].wzyx, ref.wzyx)

	// swizzle may repeat components and count can go > the array len
	testing.expect_value(t, swizzle(fixed[1], 0, 1), swizzle(ref, 0, 1))
	testing.expect_value(t, swizzle(fixed[1], 3, 0, 1), swizzle(ref, 3, 0, 1))
	testing.expect_value(t, swizzle(fixed[1], 0, 1, 0, 1, 0), swizzle(ref, 0, 1, 0, 1, 0))
	testing.expect_value(t, swizzle(fixed[1], 3, 3, 3, 3, 3, 3), swizzle(ref, 3, 3, 3, 3, 3, 3))

	// runtime element index
	i := 1
	testing.expect_value(t, fixed[i].xy, ref.xy)

	// scatter writes
	fixed[1].xy = [2]u16{10, 11}
	testing.expect_value(t, fixed.x[1], 10)
	testing.expect_value(t, fixed.y[1], 11)
	testing.expect_value(t, fixed.z[1], 3)
	// scatter writes permuted
	fixed[1].yx = [2]u16{20, 21}
	testing.expect_value(t, fixed.y[1], 20)
	testing.expect_value(t, fixed.x[1], 21)
	testing.expect_value(t, fixed.x[0], 90)
	testing.expect_value(t, fixed.w[0], 93)

	// dynamic and slice kinds
	dyn := make(#soa[dynamic][4]u16, 2)
	defer delete(dyn)
	dyn[0] = [4]u16{1, 2, 3, 4}
	dyn[1] = [4]u16{5, 6, 7, 8}

	testing.expect_value(t, dyn[0].xy, ref.xy)
	testing.expect_value(t, dyn[0].zx, ref.zx)
	dyn[1].xy = [2]u16{40, 41}
	testing.expect_value(t, dyn.x[1], 40)
	testing.expect_value(t, dyn.y[1], 41)
	testing.expect_value(t, dyn.x[0], 1)

	s := dyn[:]
	testing.expect_value(t, s[0].zw, ref.zw)
	s[0].zw = [2]u16{50, 51}
	testing.expect_value(t, dyn.z[0], 50)
	testing.expect_value(t, dyn.w[0], 51)

	// through #soa pointer
	p := &dyn[0]
	testing.expect_value(t, p^.x, u16(1))
	testing.expect_value(t, p^.xy, [2]u16{1, 2})
	
	// auto-deref through the #soa pointer
	testing.expect_value(t, p.x, u16(1))
	testing.expect_value(t, p.xy, [2]u16{1, 2})
	testing.expect_value(t, p.yx, [2]u16{2, 1})
	p.zw = [2]u16{60, 61}
	testing.expect_value(t, dyn.z[0], 60)
	testing.expect_value(t, dyn.w[0], 61)
	p.xy += [2]u16{1, 1}
	testing.expect_value(t, dyn.x[0], 2)
	testing.expect_value(t, dyn.y[0], 3)

	// read-modify-write
	fixed[1].xy += [2]u16{9, 10}
	testing.expect_value(t, fixed.x[1], 30)
	testing.expect_value(t, fixed.y[1], 30)
	fixed[1].xx += [2]u16{5, 100}
	testing.expect_value(t, fixed.x[1], 35)

	// range over an element swizzle
	sum: u16
	for c in fixed[1].wz {
		sum += c
	}
	testing.expect_value(t, sum, u16(7))

	// shuffle
	fixed[1].xy = [2]u16{9, 10}
	fixed[1].xy = fixed[1].yx
	testing.expect_value(t, fixed[1].xy, [2]u16{10, 9})
}

// chained indexing of #soa container when element type is an array -> soa[i][j]
@(test)
test_soa_array_elem_chained_indexing :: proc(t: ^testing.T) {

	fixed: #soa[3][4]u16
	for i in 0 ..< 3 {
		fixed.x[i] = u16(i*10 + 0)
		fixed.y[i] = u16(i*10 + 1)
		fixed.z[i] = u16(i*10 + 2)
		fixed.w[i] = u16(i*10 + 3)
	}

	// const inner index
	testing.expect_value(t, fixed[1][0], 10)
	testing.expect_value(t, fixed[2][3], 23)

	// var inner index
	for i in 0 ..< 3 {
		tmp := fixed[i]
		for j in 0 ..< 4 {
			testing.expect_value(t, fixed[i][j], tmp[j])
			testing.expect_value(t, fixed[i][j], u16(i*10 + j))
		}
	}

	// index and the .x/y/z/w name must agree
	for i in 0 ..< 3 {
		testing.expect_value(t, fixed[i][0], fixed[i].x)
		testing.expect_value(t, fixed[i][3], fixed[i].w)
	}

	// dynamic + slice
	dyn := make(#soa[dynamic][4]u16, 2)
	defer delete(dyn)
	dyn[0] = [4]u16{10, 11, 12, 13}
	dyn[1] = [4]u16{20, 21, 22, 23}

	testing.expect_value(t, dyn[0][3], 13)
	testing.expect_value(t, dyn[1][0], 20)

	slice := dyn[:]
	testing.expect_value(t, slice[0][3], 13)
	testing.expect_value(t, slice[1][2], 22)

	for i in 0 ..< 2 {
		dyn_tmp := dyn[i]
		slice_tmp := slice[i]
		for j in 0 ..< 4 {
			testing.expect_value(t, dyn[i][j], dyn_tmp[j])
			testing.expect_value(t, slice[i][j], dyn_tmp[j])
			testing.expect_value(t, dyn[i][j], slice_tmp[j])
			testing.expect_value(t, slice[i][j], slice_tmp[j])
		}
	}

	// soa[i][j] must equal v[j] where v is the for-in looping variable
	// test fixed, dynamic and sliec
	for v, i in fixed {
		testing.expect_value(t, v[3], u16(i*10 + 3))
		for j in 0 ..< 4 {
			testing.expect_value(t, v[j], fixed[i][j])
		}
	}
	for &v, i in fixed {
		testing.expect_value(t, v[1], u16(i*10 + 1))
		j := 2
		testing.expect_value(t, v[j], u16(i*10 + j))
	}
	for v, i in dyn {
		for j in 0 ..< 4 {
			testing.expect_value(t, v[j], u16((i + 1)*10 + j))
		}
	}
	for &v, i in dyn {
		testing.expect_value(t, v[1], u16((i + 1)*10 + 1))
		j := 3
		testing.expect_value(t, v[j], u16((i + 1)*10 + j))
	}	
	for v, i in slice {
		testing.expect_value(t, v[2], slice[i][2])
	}
	for &v, i in slice {
		testing.expect_value(t, v[2], slice[i][2])
		j := 0
		testing.expect_value(t, v[j], u16((i + 1)*10 + j))
	}		

	// write access must work through the looping var
	fixed_scatter: #soa[2][4]u16
	for &v, i in fixed_scatter {
		v[0] = u16(i)
		for j in 1 ..< 4 {
			v[j] = u16(i*10 + j)
		}
		v[3] += 5
	}
	for i in 0 ..< 2 {
		testing.expect_value(t, fixed_scatter.x[i], u16(i))
		testing.expect_value(t, fixed_scatter.y[i], u16(i*10 + 1))
		testing.expect_value(t, fixed_scatter.z[i], u16(i*10 + 2))
		testing.expect_value(t, fixed_scatter.w[i], u16(i*10 + 3 + 5))
	}
	// for fixed soa you can get fancy and select a whole .x/y/z/w lane
	testing.expect_value(t, fixed_scatter.x, [2]u16{0, 1})
	testing.expect_value(t, fixed_scatter.y, [2]u16{1, 11})
	testing.expect_value(t, fixed_scatter.z, [2]u16{2, 12})
	testing.expect_value(t, fixed_scatter.w, [2]u16{3 + 5, 13 + 5})

	dyn_scatter := make(#soa[dynamic][4]u16, 2)
	defer delete(dyn_scatter)
	for &v, i in dyn_scatter {
		v[0] = u16(i + 1)
		for j in 1 ..< 4 {
			v[j] = u16((i + 1)*10 + j)
		}
		v[3] += 5
	}
	for i in 0 ..< 2 {
		testing.expect_value(t, dyn_scatter.x[i], u16(i + 1))
		testing.expect_value(t, dyn_scatter.y[i], u16((i + 1)*10 + 1))
		testing.expect_value(t, dyn_scatter.z[i], u16((i + 1)*10 + 2))
		testing.expect_value(t, dyn_scatter.w[i], u16((i + 1)*10 + 3 + 5))
	}

	slice_scatter := dyn_scatter[:]
	for &v in slice_scatter {
		v[1] += 100
	}
	testing.expect_value(t, dyn_scatter.y[0], 111)
	testing.expect_value(t, dyn_scatter.y[1], 121)
	testing.expect_value(t, dyn_scatter.x[0], 1)

	// soa[i][j] writes
	fixed_write: #soa[3][4]u16
	fixed_write[1][0] = 5
	k := 2
	fixed_write[1][k] = 6
	fixed_write[1][1] += 7
	fixed_write[1][0], fixed_write[1][3] = fixed_write[1][3], fixed_write[1][0]
	testing.expect_value(t, fixed_write.x, [3]u16{0, 0, 0})
	testing.expect_value(t, fixed_write.y, [3]u16{0, 7, 0})
	testing.expect_value(t, fixed_write.z, [3]u16{0, 6, 0})
	testing.expect_value(t, fixed_write.w, [3]u16{0, 5, 0})

	dyn_write := make(#soa[dynamic][4]u16, 2)
	defer delete(dyn_write)
	dyn_write[0][3] = 41
	dyn_write[1][k] = 42
	slice_write := dyn_write[:]
	slice_write[0][1] = 43
	slice_write[0][k] = 44
	testing.expect_value(t, dyn_write.w[0], 41)
	testing.expect_value(t, dyn_write.z[1], 42)
	testing.expect_value(t, dyn_write.y[0], 43)
	testing.expect_value(t, dyn_write.z[0], 44)
	testing.expect_value(t, dyn_write.x[0], 0)

	// a single component has a real address
	testing.expect_value(t, &fixed_write[1][2], &fixed_write.z[1])
	pw := &fixed_write[1][2]
	pw^ = 60
	testing.expect_value(t, fixed_write.z[1], 60)
	for j in 0 ..< 4 {
		p := &fixed_write[1][j]
		p^ = u16(70 + j)
	}
	testing.expect_value(t, fixed_write.x, [3]u16{0, 70, 0})
	testing.expect_value(t, fixed_write.y, [3]u16{0, 71, 0})
	testing.expect_value(t, fixed_write.z, [3]u16{0, 72, 0})
	testing.expect_value(t, fixed_write.w, [3]u16{0, 73, 0})

	for j in 0 ..< 4 {
		p := &dyn_write[0][j]
		p^ = u16(80 + j)
	}
	testing.expect_value(t, dyn_write.x[0], 80)
	testing.expect_value(t, dyn_write.w[0], 83)
	for j in 0 ..< 4 {
		p := &slice_write[1][j]
		p^ = u16(90 + j)
	}
	testing.expect_value(t, dyn_write.x[1], 90)
	testing.expect_value(t, dyn_write.w[1], 93)

	// through a pointer to the element
	ep := &fixed_write[1]
	k = 2
	testing.expect_value(t, ep[k], 72)
	testing.expect_value(t, ep[1], ep^[1])
	ep[0] = 100
	testing.expect_value(t, fixed_write.x[1], 100)
	ep[k] = 102
	testing.expect_value(t, fixed_write.z[1], 102)
	pe := &ep[3]
	pe^ = 103
	testing.expect_value(t, fixed_write.w[1], 103)

	eps := &slice_write[0]
	eps[1] = 143
	testing.expect_value(t, dyn_write.y[0], 143)
	epd := &dyn_write[1]
	testing.expect_value(t, epd[k], 92)
	epd[0] = 190
	testing.expect_value(t, dyn_write.x[1], 190)

	// multi dim array element type, only the outer index is scattered
	nested: #soa[2][3][2]u16
	nested[1].x = {1, 3}
	nested[1].z = {7, 11}
	testing.expect_value(t, nested[1][0][1], 3)
	testing.expect_value(t, nested[1][2][0], 7)	

	nested[1][0][1] = 8
	nested[1][2][0] = 9
	testing.expect_value(t, nested[1][0], [2]u16{1, 8})
	testing.expect_value(t, nested[1][2], [2]u16{9, 11})

	for j in 0 ..< 3 {
		nested[1][j][0] = u16(50 + j)
	}
	for j in 0 ..< 3 {
		testing.expect_value(t, nested[1][j][0], u16(50 + j))
	}
	testing.expect_value(t, nested.x[1][0], 50)
	testing.expect_value(t, nested.y[1][0], 51)
	testing.expect_value(t, nested.z[1][0], 52)
	testing.expect_value(t, nested[0][0], [2]u16{0, 0})

	pn := &nested[1]
	testing.expect_value(t, pn[0][0], 50)
	pn[0][1] = 60
	testing.expect_value(t, nested.x[1][1], 60)
}

// ranging over an element of array-element typed #soa,
// for v in soa[i], or for &v in soa[i]
@(test)
test_soa_array_elem_range :: proc(t: ^testing.T) {
	fixed: #soa[3][4]u16
	fixed[0] = [4]u16{90, 91, 92, 93}
	fixed[1] = [4]u16{10, 11, 12, 13}

	for v, j in fixed[1] {
		testing.expect_value(t, v, fixed[1][j])
	}

	#reverse for v, j in fixed[0] {
		testing.expect_value(t, v, fixed[0][j])
	}

	got: [4]u16
	i := 0
	for v in fixed[1] {
		got[i] = v
		i += 1
	}
	testing.expect_value(t, got, [4]u16{10, 11, 12, 13})

	// double loop
	sum : u16 = 0
	for e in fixed {
		for v in e {
			sum += v
		}
	}
	testing.expect_value(t, sum, 90 + 91 + 92 + 93 + 10 + 11 + 12 + 13)

	// through pointer to the container
	got = {}
	i = 0
	p := &fixed
	k := 1
	for v in p[k] {
		got[i] = v
		i += 1
	}
	testing.expect_value(t, got, [4]u16{10, 11, 12, 13})

	// slice
	slice := fixed[:]
	got = {}
	i = 0
	for v in slice[1] {
		got[i] = v
		i += 1
	}
	testing.expect_value(t, got, [4]u16{10, 11, 12, 13})

	// dynamic
	dyn: #soa[dynamic][4]u16
	defer delete(dyn)
	append_soa(&dyn, [4]u16{20, 21, 22, 23})
	append_soa(&dyn, [4]u16{30, 31, 32, 33})
	got = {}
	i = 0
	for v in dyn[1] {
		got[i] = v
		i += 1
	}
	testing.expect_value(t, got, [4]u16{30, 31, 32, 33})

	// multi dim array type
	nested: #soa[2][3][2]u16
	nested[1] = [3][2]u16{{1, 2}, {3, 4}, {5, 6}}
	flat: [6]u16
	n := 0
	for row in nested[1] {
		for v in row {
			flat[n] = v
			n += 1
		}
	}
	testing.expect_value(t, flat, [6]u16{1, 2, 3, 4, 5, 6})

	// a write during the loop is visible to later iterations
	// (same as normal arrays)
	live: #soa[2][4]u16
	live[0] = [4]u16{1, 2, 3, 4}
	seen: [4]u16
	for v, j in live[0] {
		if j == 0 {
			live.z[0] = 99
		}
		seen[j] = v
	}
	testing.expect_value(t, seen, [4]u16{1, 2, 99, 4})

	//////////////////////////
	// for &v in soa[i]
	//////////////////////////

	// fixed: #soa[3][4]u16
	fixed[1] = [4]u16{1, 2, 3, 4}
	for &v in fixed[1] {
		v *= 10
	}
	testing.expect_value(t, fixed[1], [4]u16{10, 20, 30, 40})
	testing.expect_value(t, fixed.x[1], 10)
	testing.expect_value(t, fixed.w[1], 40)

	fixed[1] = [4]u16{1, 2, 3, 4}
	for &v, j in fixed[1] {
		v += u16(j)
	}
	testing.expect_value(t, fixed[1], [4]u16{1, 3, 5, 7})

	fixed[1] = [4]u16{1, 2, 3, 4}
	#reverse for &v in fixed[1] {
		v *= 2
	}
	testing.expect_value(t, fixed[1], [4]u16{2, 4, 6, 8})

	// through pointer to the container
	fixed[1] = [4]u16{1, 2, 3, 4}
	k = 1
	p = &fixed
	for &v in p[k] {
		v += 100
	}
	testing.expect_value(t, fixed[1], [4]u16{101, 102, 103, 104})

	// slice
	fixed[1] = [4]u16{1, 2, 3, 4}
	slice = fixed[:]
	for &v in slice[1] {
		v *= 3
	}
	testing.expect_value(t, fixed[1], [4]u16{3, 6, 9, 12})

	// dynamic
	dyn[0] = [4]u16{1, 2, 3, 4}
	for &v in dyn[0] {
		v += 5
	}
	testing.expect_value(t, dyn[0], [4]u16{6, 7, 8, 9})

	// multi dim array type
	nested[0] = [2]u16{1, 2}
	nested[1] = [2]u16{5, 6}
	for &e in nested {
		for &v in e {
			v += 1
		}
	}
	testing.expect_value(t, nested[0], [2]u16{2, 3})
	testing.expect_value(t, nested[1], [2]u16{6, 7})

	//////////////////////////
	// through a pointer to the element
	// for v in ep^, or for v in ep
	//////////////////////////

	fixed[1] = [4]u16{1, 2, 3, 4}
	ep := &fixed[1]

	got = {}
	i = 0
	for v in ep^ {
		got[i] = v
		i += 1
	}
	testing.expect_value(t, got, [4]u16{1, 2, 3, 4})

	for &v, j in ep^ {
		v += u16(10 * (j + 1))
	}
	testing.expect_value(t, fixed[1], [4]u16{11, 22, 33, 44})

	// auto-deref
	fixed[1] = [4]u16{1, 2, 3, 4}
	got = {}
	i = 0
	for v in ep {
		got[i] = v
		i += 1
	}
	testing.expect_value(t, got, [4]u16{1, 2, 3, 4})

	for &v in ep {
		v *= 2
	}
	testing.expect_value(t, fixed[1], [4]u16{2, 4, 6, 8})

	// a [0]T element has no components; the loop must not run
	// (and the compiler must not crash :)
	c0: #soa[2][0]u16
	n = 0
	for v in c0[0] {
		_ = v
		n += 1
	}
	testing.expect_value(t, n, 0)
}

// "using" on an #soa for-in looping variable
@(test)
test_soa_for_in_using :: proc(t: ^testing.T) {
	S :: struct {
		a: int,
		b: int,
		c: int,
	}
	s: #soa[2]S = {{a = 1, b = 2, c = 3}, {a = 4, b = 5, c = 6}}

	sum := 0
	for v in s {
		using v
		sum += a + c
	}
	testing.expect_value(t, sum, 14)

	for &v in s {
		using v
		b += 10
	}
	testing.expect_value(t, s.b[0], 12)
	testing.expect_value(t, s.b[1], 15)
}

// &v in for-in over soa container
@(test)
test_soa_for_in_addr :: proc(t: ^testing.T) {
	S :: struct {
		a: int,
		b: int,
	}
	s: #soa[2]S = {{a = 1, b = 2}, {a = 3, b = 4}}

	for &v, i in s {
		p := &v
		testing.expect_value(t, p.a, s.a[i])
		p.b += 10 * (i + 1)
	}
	testing.expect_value(t, s.b[0], 12)
	testing.expect_value(t, s.b[1], 24)

	// &v is the same type as &s[i]
	q := &s[0]
	for &v in s {
		q = &v
	}

	// still valid
	testing.expect_value(t, q.a, 3)
	q.a = 30
	testing.expect_value(t, s.a[1], 30)

	// array element type
	arr: #soa[2][4]u16
	arr[1] = [4]u16{1, 2, 3, 4}
	for &v, i in arr {
		pv := &v
		if i == 1 {
			testing.expect_value(t, pv.x, u16(1))
			pv.y = 20
		}
	}
	testing.expect_value(t, arr.y[1], 20)
}

@(test)
test_soa_array_allocator_resize :: proc(t: ^testing.T) {

	arena: runtime.Arena
	context.allocator = runtime.arena_allocator(&arena)
	defer runtime.arena_destroy(&arena)

	// |1 3 _ 2 4 _|
	// |1 3 _ _ 2 4 _ _|

	array, err := make(#soa[dynamic][2]int, 2, 3)
	defer delete(array)
	array[0] = [2]int{1, 2}
	array[1] = [2]int{3, 4}

	testing.expect_value(t, err, nil)
	testing.expect_value(t, len(array), 2)
	testing.expect_value(t, cap(array), 3)

	err = resize(&array, 4)

	testing.expect_value(t, err, nil)
	testing.expect_value(t, len(array), 4)
	testing.expect_value(t, cap(array), 4)

	testing.expect_value(t, array[0], [2]int{1, 2})
	testing.expect_value(t, array[1], [2]int{3, 4})
	testing.expect_value(t, array[2], [2]int{0, 0})
	testing.expect_value(t, array[3], [2]int{0, 0})
}


@(test)
test_soa_array_allocator_resize_overlapping :: proc(t: ^testing.T) {

	arena: runtime.Arena
	context.allocator = runtime.arena_allocator(&arena)
	defer runtime.arena_destroy(&arena)

	// |1 4 2 5 3 6|
	// |1 4 _ _ 2 5 _ _ 3 6 _ _|

	array, err := make(#soa[dynamic][3]int, 2, 2)
	defer delete(array)
	array[0] = [3]int{1, 2, 3}
	array[1] = [3]int{4, 5, 6}

	testing.expect_value(t, err, nil)
	testing.expect_value(t, len(array), 2)
	testing.expect_value(t, cap(array), 2)

	err = resize(&array, 4)

	testing.expect_value(t, err, nil)
	testing.expect_value(t, len(array), 4)
	testing.expect_value(t, cap(array), 4)

	testing.expect_value(t, array[0], [3]int{1, 2, 3})
	testing.expect_value(t, array[1], [3]int{4, 5, 6})
	testing.expect_value(t, array[2], [3]int{0, 0, 0})
	testing.expect_value(t, array[3], [3]int{0, 0, 0})
}

@(test)
test_soa_array_inject_at_elem :: proc(t: ^testing.T) {

	V :: struct {a: u8, b: f32}

	array := make(#soa[dynamic]V, 0, 2)
	defer delete(array)

	append(&array, V{1, 1.5}, V{2, 2.5}, V{3, 3.5})

	expect_inject(t, &array, 0, {0, 0.5}, {{0, 0.5}, {1, 1.5}, {2, 2.5}, {3, 3.5}})
	expect_inject(t, &array, 2, {5, 5.5}, {{0, 0.5}, {1, 1.5}, {5, 5.5}, {2, 2.5}, {3, 3.5}})
	expect_inject(t, &array, 5, {9, 9.5}, {{0, 0.5}, {1, 1.5}, {5, 5.5}, {2, 2.5}, {3, 3.5}, {9, 9.5}})

	expect_inject :: proc(t: ^testing.T, arr: ^#soa[dynamic]V, index: int, arg: V, expected_slice: []V) {
		ok, err := inject_at_soa(arr, index, arg)
		testing.expectf(t, ok == true, "Injection of %v at index %d failed", arg, index)
		testing.expectf(t, err == nil, "Injection allocation of %v at index %d failed: %v", arg, index, err)
		equals := len(arr) == len(expected_slice)
		for e, i in expected_slice {
			if arr[i] != e {
				equals = false
				break
			}
		}
		testing.expectf(t, equals, "After injection of %v at index %d, expected array to be\n&%v, got\n%v", arg, index, expected_slice, arr)
	}
}

@(test)
test_soa_array_inject_at_elems :: proc(t: ^testing.T) {

	V :: struct {a: u8, b: f32}

	array := make(#soa[dynamic]V, 0, 2)
	defer delete(array)

	append(&array, V{1, 1.5}, V{2, 2.5}, V{3, 3.5})

	expect_inject(t, &array, 0, {{0, 0.5}}, {{0, 0.5}, {1, 1.5}, {2, 2.5}, {3, 3.5}})
	expect_inject(t, &array, 2, {{5, 5.5}, {6, 6.5}}, {{0, 0.5}, {1, 1.5}, {5, 5.5}, {6, 6.5}, {2, 2.5}, {3, 3.5}})
	expect_inject(t, &array, 6, {{9, 9.5}, {10, 10.5}}, {{0, 0.5}, {1, 1.5}, {5, 5.5}, {6, 6.5}, {2, 2.5}, {3, 3.5}, {9, 9.5}, {10, 10.5}})
	expect_inject(t, &array, 6, {}, {{0, 0.5}, {1, 1.5}, {5, 5.5}, {6, 6.5}, {2, 2.5}, {3, 3.5}, {9, 9.5}, {10, 10.5}})

	expect_inject :: proc(t: ^testing.T, arr: ^#soa[dynamic]V, index: int, args: []V, expected_slice: []V) {
		ok, err := inject_at_soa(arr, index, ..args)
		testing.expectf(t, ok == true, "Injection of %v at index %d failed", args, index)
		testing.expectf(t, err == nil, "Injection allocation of %v at index %d failed: %v", args, index, err)
		equals := len(arr) == len(expected_slice)
		for e, i in expected_slice {
			if arr[i] != e {
				equals = false
				break
			}
		}
		testing.expectf(t, equals, "After injection of %v at index %d, expected array to be\n&%v, got\n%v", args, index, expected_slice, arr)
	}
}

@(test)
test_memory_equal :: proc(t: ^testing.T) {
	data: [256]u8
	cmp: [256]u8

	slice.fill(data[:], 0xAA)
	slice.fill(cmp[:], 0xAA)

	for offset in 0..<len(data) {
		subdata := data[offset:]
		subcmp := cmp[offset:]
		for idx in 0..<len(subdata) {
			if !testing.expect_value(t, runtime.memory_equal(&subdata[0], &subcmp[0], len(subdata)), true) {
				return
			}

			subcmp[idx] = 0x55
			if !testing.expect_value(t, runtime.memory_equal(&subdata[0], &subcmp[0], len(subdata)), false) {
				return
			}
			subcmp[idx] = 0xAA
		}
	}
}

@(test)
test_memory_compare :: proc(t: ^testing.T) {
	data: [256]u8
	cmp: [256]u8

	for offset in 0..<len(data) {
		subdata := data[offset:]
		subcmp := cmp[offset:]
		for idx in 0..<len(subdata) {
			if !testing.expect_value(t, runtime.memory_compare(&subdata[0], &subcmp[0], len(subdata)), 0) {
				return
			}

			subdata[idx] = 0x7F
			subcmp[idx] = 0xFF
			if !testing.expect_value(t, runtime.memory_compare(&subdata[0], &subcmp[0], len(subdata)), -1) {
				return
			}

			subdata[idx] = 0xFF
			subcmp[idx] = 0x7F
			if !testing.expect_value(t, runtime.memory_compare(&subdata[0], &subcmp[0], len(subdata)), 1) {
				return
			}

			subdata[idx] = 0
			subcmp[idx] = 0
		}
	}
}

@(test)
test_memory_compare_zero :: proc(t: ^testing.T) {
	data: [256]u8

	for offset in 0..<len(data) {
		subdata := data[offset:]
		for idx in 0..<len(subdata) {
			if !testing.expect_value(t, runtime.memory_compare_zero(&subdata[0], len(subdata)), 0) {
				return
			}
			subdata[idx] = 0xFF
			if !testing.expect_value(t, runtime.memory_compare_zero(&subdata[0], len(subdata)), 1) {
				return
			}
			subdata[idx] = 0
		}
	}
}

// Runs identical append/inject/remove sequences for a #soa[dynamic] array
// and an AoS [dynamic] reference, comparing all elements after each
// stage. Covers appends, injections (interior, at the end, and past the
// end where the gap must read as zero elements), unordered and ordered
// removes.
@(test)
test_soa_array_append_inject_remove :: proc(t: ^testing.T) {
	check :: proc(t: ^testing.T, $E: typeid, mk: proc(i: int) -> E) {
		expect_same :: proc(t: ^testing.T, soa: #soa[dynamic]$T, model: [dynamic]T) {
			testing.expect_value(t, len(soa), len(model))
			for i in 0..<min(len(soa), len(model)) {
				testing.expect_value(t, soa[i], model[i])
			}
		}

		soa: #soa[dynamic]E
		defer delete(soa)
		ref: [dynamic]E
		defer delete(ref)

		// single appends
		for i in 0..<10 {
			n, err := append(&soa, mk(i))
			testing.expect_value(t, n, 1)
			testing.expect_value(t, err, nil)
			append(&ref, mk(i))
		}
		expect_same(t, soa, ref)

		// batch appends
		buf: [32]E
		for i in 0..<32 { buf[i] = mk(123 + i) }
		BATCH_LEN :: 5
		n, err := append(&soa, ..buf[:BATCH_LEN])
		testing.expect_value(t, n, BATCH_LEN)
		testing.expect_value(t, err, nil)
		append(&ref, ..buf[:BATCH_LEN])
		expect_same(t, soa, ref)

		n, err = append(&soa, ..buf[:])
		testing.expect_value(t, n, 32)
		testing.expect_value(t, err, nil)
		append(&ref, ..buf[:])
		expect_same(t, soa, ref)

		// single injections
		ok: bool
		ok, err = inject_at_soa(&soa, 0, mk(300))
		testing.expect(t, ok)
		testing.expect_value(t, err, nil)
		inject_at(&ref, 0, mk(300))
		expect_same(t, soa, ref)

		ok, err = inject_at_soa(&soa, len(soa)/2, mk(301))
		testing.expect(t, ok)
		testing.expect_value(t, err, nil)
		inject_at(&ref, len(ref)/2, mk(301))
		expect_same(t, soa, ref)

		// inject at the end
		ok, err = inject_at_soa(&soa, len(soa), mk(302))
		testing.expect(t, ok)
		testing.expect_value(t, err, nil)
		inject_at(&ref, len(ref), mk(302))
		expect_same(t, soa, ref)

		// batch injections
		ok, err = inject_at_soa(&soa, 3, ..buf[:BATCH_LEN])
		testing.expect(t, ok)
		testing.expect_value(t, err, nil)
		inject_at(&ref, 3, ..buf[:BATCH_LEN])
		expect_same(t, soa, ref)

		ok, err = inject_at_soa(&soa, len(soa), ..buf[:])
		testing.expect(t, ok)
		testing.expect_value(t, err, nil)
		inject_at(&ref, len(ref), ..buf[:])
		expect_same(t, soa, ref)

		// injecting nothing is a no-op
		ok, err = inject_at_soa(&soa, 4, ..buf[:0])
		testing.expect(t, ok)
		testing.expect_value(t, err, nil)
		inject_at(&ref, 4, ..buf[:0])
		expect_same(t, soa, ref)

		// single injection past the end: the gap [len, index) reads as zero
		// elements. Poison the spare capacity first (fresh heap pages are
		// already zero, which would hide a missing gap zero), then shrink back.
		for i in 0..<8 {
			n, err = append(&soa, mk(900 + i))
			testing.expect_value(t, n, 1)
			testing.expect_value(t, err, nil)
		}
		testing.expect_value(t, resize_soa(&soa, len(soa) - 8), nil)
		ok, err = inject_at_soa(&soa, len(soa) + 3, mk(500))
		testing.expect(t, ok)
		testing.expect_value(t, err, nil)
		inject_at(&ref, len(ref) + 3, mk(500))
		expect_same(t, soa, ref)

		// batch injection past the end (its gap slots reuse the poison above)
		ok, err = inject_at_soa(&soa, len(soa) + 2, ..buf[:BATCH_LEN])
		testing.expect(t, ok)
		testing.expect_value(t, err, nil)
		inject_at(&ref, len(ref) + 2, ..buf[:BATCH_LEN])
		expect_same(t, soa, ref)

		// unordered removes
		unordered_remove_soa(&soa, 20)
		unordered_remove(&ref, 20)
		unordered_remove_soa(&soa, 0)
		unordered_remove(&ref, 0)
		unordered_remove_soa(&soa, len(soa)-1)
		unordered_remove(&ref, len(ref)-1)
		expect_same(t, soa, ref)

		// ordered removes
		ordered_remove_soa(&soa, 17)
		ordered_remove(&ref, 17)
		ordered_remove_soa(&soa, 0)
		ordered_remove(&ref, 0)
		ordered_remove_soa(&soa, len(soa)-1)
		ordered_remove(&ref, len(ref)-1)
		expect_same(t, soa, ref)

		// interleaved removes, appends and injections
		for i in 0..<8 {
			unordered_remove_soa(&soa, i)
			unordered_remove(&ref, i)
			n, err = append(&soa, mk(200 + i))
			testing.expect_value(t, n, 1)
			testing.expect_value(t, err, nil)
			append(&ref, mk(200 + i))
			ok, err = inject_at_soa(&soa, i, mk(400 + i))
			testing.expect(t, ok)
			testing.expect_value(t, err, nil)
			inject_at(&ref, i, mk(400 + i))
		}
		expect_same(t, soa, ref)

		// remove till empty, then reuse
		for len(soa) > 0 {
			unordered_remove_soa(&soa, 0)
			unordered_remove(&ref, 0)
		}
		testing.expect_value(t, len(soa), 0)

		// inject into an empty array
		ok, err = inject_at_soa(&soa, 0, mk(998))
		testing.expect(t, ok)
		testing.expect_value(t, err, nil)
		inject_at(&ref, 0, mk(998))
		expect_same(t, soa, ref)

		// non-zero append
		n, err = non_zero_append(&soa, mk(42))
		testing.expect_value(t, n, 1)
		testing.expect_value(t, err, nil)
		non_zero_append(&ref, mk(42))
		expect_same(t, soa, ref)
	}

	// mixed field widths + padding
	Padded :: struct { a: u8, b: u64, c: u16 }
	check(t, Padded, proc(i: int) -> Padded { return {u8(i*3), u64(i)*257 + 7, u16(i*5 + 1)} })
	// array element type
	check(t, [4]u16, proc(i: int) -> [4]u16 { return {u16(i), u16(i + 1), u16(i*3), u16(i*7)} })
	// eight fields at varying widths, no two neighbouring fields share a stride
	Eight :: struct { a: u8, b: u16, c: u32, d: u64, e: i8, f: i16, g: f32, h: f64 }
	check(t, Eight, proc(i: int) -> Eight {
		return {
			u8(i), u16(i*3 + 1), u32(i)*5 + 2, u64(i)*7 + 3,
			i8(i >> 1), i16(i*11 + 4), f32(i)*1.5, f64(i)*2.25,
		}
	})
	// #packed struct with > 16 fields, field offsets diverging from default
	// layout (u8/u64 alternate, align_of == 1), and the field count takes
	// the type-erased batch appends compile time branch.
	Packed17 :: struct #packed {
		f0: u8, f1: u64, f2: u8, f3: u64, f4: u8, f5: u64, f6: u8, f7: u64,
		f8: u8, f9: u64, f10: u8, f11: u64, f12: u8, f13: u64, f14: u8, f15: u64,
		f16: u8,
	}
	check(t, Packed17, proc(i: int) -> Packed17 {
		return {
			u8(i), u64(i)*3 + 1, u8(i >> 1), u64(i)*5 + 2, u8(i >> 2), u64(i)*7 + 3, u8(i >> 3), u64(i)*11 + 4,
			u8(i >> 4), u64(i)*13 + 5, u8(i >> 5), u64(i)*17 + 6, u8(i >> 6), u64(i)*19 + 7, u8(i >> 7), u64(i)*23 + 8,
			u8(i*3),
		}
	})
}
