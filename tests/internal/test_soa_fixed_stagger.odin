package test_internal

import "base:runtime"
import "core:testing"

@(private="file")
V :: struct {a, b, c, d, e, f: f32}

@(private="file")
N :: 1024

@(private="file")
table := #soa[N]V{3 = {1, 2, 3, 4, 5, 6}, N-1 = {6, 5, 4, 3, 2, 1}}

// The offsets of the columns of an #soa type which holds its elements inline
@(private="file")
columns :: proc(T: typeid) -> []uintptr {
	info := runtime.type_info_base(type_info_of(T)).variant.(^runtime.Type_Info_Struct)
	count := int(info.field_count)
	if info.soa_kind == .Fixed_Capacity_Dynamic {
		count -= 1 // len
	}
	return info.offsets[:count]
}

@(private="file")
expect_staggered :: proc(t: ^testing.T, offsets: []uintptr, loc := #caller_location) {
	for i in 1..<len(offsets) {
		testing.expect(t, offsets[i] > offsets[i-1], "the columns keep the order of the fields", loc=loc)
		for j in 0..<i {
			apart := (offsets[i] - offsets[j]) % 4096
			testing.expectf(t, apart >= 128 && apart <= 4096-128, "columns %d and %d start %d bytes apart, modulo 4 KiB", j, i, apart, loc=loc)
		}
	}
}

// Columns a multiple of 4 KiB long would start at the same offset modulo 4 KiB
@(test)
test_soa_fixed_columns_staggered :: proc(t: ^testing.T) {
	expect_staggered(t, columns(#soa[N]V))
	expect_staggered(t, columns(#soa[N/2]V))
	expect_staggered(t, columns(#soa[N][4]f32))
	expect_staggered(t, columns(#soa[dynamic; N]V))

	testing.expect_value(t, offset_of(#soa[N]V, b), 4096 + 128)
	testing.expect_value(t, size_of(#soa[N]V), 6*4096 + 5*128)

	// The length comes after the last column
	info := runtime.type_info_base(type_info_of(#soa[dynamic; N]V)).variant.(^runtime.Type_Info_Struct)
	testing.expect_value(t, info.offsets[6], info.offsets[5] + N*size_of(f32))

	// Columns less than 4 KiB apart are left as they are
	testing.expect_value(t, offset_of(#soa[100]V, f), 5*100*size_of(f32))
	testing.expect_value(t, size_of(#soa[100]V), 100*size_of(V))
}

// Elements are read and written through the padding between the columns
@(test)
test_soa_fixed_stagger_values :: proc(t: ^testing.T) {
	elem :: proc(i: int) -> V {
		x := f32(i)
		return {x, x+1, x+2, x+3, x+4, x+5}
	}

	ps := new(#soa[N]V)
	defer free(ps)
	for i in 0..<N {
		ps[i] = elem(i)
	}
	s := ps[:]
	for i in 0..<N {
		p := &ps[i]
		if !testing.expect_value(t, ps[i], elem(i)) ||
		   !testing.expect_value(t, s[i], elem(i)) ||
		   !testing.expect_value(t, ps.f[i], f32(i) + 5) ||
		   !testing.expect_value(t, p.c, f32(i) + 2) {
			return
		}
	}

	testing.expect_value(t, table[0], V{})
	testing.expect_value(t, table[3], V{1, 2, 3, 4, 5, 6})
	testing.expect_value(t, table[N-1], V{6, 5, 4, 3, 2, 1})

	x := f32(7)
	local := new_clone(#soa[N]V{5 = {x, x, x, x, x, x}})
	defer free(local)
	testing.expect_value(t, local[5], V{7, 7, 7, 7, 7, 7})
	testing.expect_value(t, local[6], V{})

	d := new(#soa[dynamic; N]V)
	defer free(d)
	for i in 0..<N {
		append(d, elem(i))
	}
	testing.expect_value(t, len(d^), N)
	ordered_remove(d, 0)
	testing.expect(t, inject_at(d, 1, V{}))
	testing.expect_value(t, d[0], elem(1))
	testing.expect_value(t, d[1], V{})
	testing.expect_value(t, d[2], elem(2))
	testing.expect_value(t, d[N-1], elem(N-1))
}
