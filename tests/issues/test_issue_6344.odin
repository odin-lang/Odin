// Tests issue #6344 https://github.com/odin-lang/Odin/issues/6344
package test_issues

import "core:testing"

@(test)
test_soa_dynamic_field_write :: proc(t: ^testing.T) {
	V :: struct {
		x: f32,
		y: f32,
	}

	array := make(#soa[dynamic]V, 4, 8)
	defer delete(array)

	for i in 0 ..< 4 {
		array[i] = V{f32(i), f32(i) * 2}
	}

	// Simple write through field-first indexing (was: compiler panic)
	for i in 0 ..< 4 {
		array.x[i] = f32(i) * 10
	}
	testing.expect_value(t, array[0].x, 0)
	testing.expect_value(t, array[1].x, 10)
	testing.expect_value(t, array[2].x, 20)
	testing.expect_value(t, array[3].x, 30)

	// Compound write through field-first indexing (was: compiler panic)
	for i in 0 ..< 4 {
		array.x[i] += array.y[i]
	}
	testing.expect_value(t, array[0].x, 0)
	testing.expect_value(t, array[1].x, 12)
	testing.expect_value(t, array[2].x, 24)
	testing.expect_value(t, array[3].x, 36)
}

@(test)
test_soa_slice_field_write :: proc(t: ^testing.T) {
	V :: struct {
		x: f32,
		y: f32,
	}

	array := make(#soa[dynamic]V, 4, 8)
	defer delete(array)

	for i in 0 ..< 4 {
		array[i] = V{f32(i), f32(i) * 2}
	}

	slice := array[:]

	// Write through slice field-first indexing (was: compiler panic)
	for i in 0 ..< 4 {
		slice.x[i] = f32(i) * 10
	}
	testing.expect_value(t, array[0].x, 0)
	testing.expect_value(t, array[1].x, 10)
	testing.expect_value(t, array[2].x, 20)
	testing.expect_value(t, array[3].x, 30)

	// Compound write through slice field-first indexing
	for i in 0 ..< 4 {
		slice.x[i] += slice.y[i]
	}
	testing.expect_value(t, array[0].x, 0)
	testing.expect_value(t, array[1].x, 12)
	testing.expect_value(t, array[2].x, 24)
	testing.expect_value(t, array[3].x, 36)
}
