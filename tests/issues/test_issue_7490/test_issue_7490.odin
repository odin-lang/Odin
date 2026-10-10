package test_issue_7490

import "base:intrinsics"
import "core:mem"
import "core:slice"
import "core:testing"

expect_elements :: proc(t: ^testing.T, got, expected: []$T) {
	testing.expect_value(t, len(got), len(expected))
	testing.expectf(t, slice.equal(got, expected), "Expected %v, got %v", expected, got)
}

@test
concatenate_zero_arrays :: proc(t: ^testing.T) {
	ARR :: [2]u8{}
	arr :: intrinsics.concatenate(ARR, [1]u8{1}, [2]u8{}, [3]u8{5, 4, 3})
	actual := arr
	expected := [8]u8{0, 0, 1, 0, 0, 5, 4, 3}
	expect_elements(t, actual[:], expected[:])
	when len(arr) == 8 {
		#assert(arr[0] == 0 && arr[2] == 1 && arr[7] == 3)
	}

	zeros := intrinsics.concatenate([2]int{}, [3]int{})
	expect_elements(t, zeros[:], []int{0, 0, 0, 0, 0})
	tail := intrinsics.concatenate([1]int{9}, [2]int{})
	expect_elements(t, tail[:], []int{9, 0, 0})
	empty := intrinsics.concatenate([0]int{}, [0]int{})
	testing.expect_value(t, len(empty), 0)

	s := intrinsics.concatenate([]u8{}, []u8{1}, []u8{}, []u8{5, 4, 3})
	expect_elements(t, s, []u8{1, 5, 4, 3})
	empty_slice := intrinsics.concatenate([]u8{}, []u8{})
	testing.expect_value(t, len(empty_slice), 0)
}

@test
concatenate_typed_zeros :: proc(t: ^testing.T) {
	Word :: distinct u16
	words := intrinsics.concatenate([2]Word{}, [1]Word{7})
	expect_elements(t, words[:], []Word{0, 0, 7})
	floats := intrinsics.concatenate([1]f64{}, [1]f64{1.5})
	expect_elements(t, floats[:], []f64{0, 1.5})
	complexes := intrinsics.concatenate([1]complex128{}, [1]complex128{1 + 2i})
	expect_elements(t, complexes[:], []complex128{0, 1 + 2i})
	quaternions := intrinsics.concatenate([1]quaternion256{}, [1]quaternion256{1 + 2i})
	expect_elements(t, quaternions[:], []quaternion256{0, 1 + 2i})
	bools := intrinsics.concatenate([2]bool{}, [1]bool{true})
	expect_elements(t, bools[:], []bool{false, false, true})
	strings := intrinsics.concatenate([2]string{}, [1]string{"x"}, [1]string{})
	expect_elements(t, strings[:], []string{"", "", "x", ""})

	Pair :: [2]int
	Record :: struct {
		number: int,
		enabled: bool,
		text: string,
		pair: Pair,
	}
	r :: Record{7, true, "x", {3, 4}}
	records := intrinsics.concatenate([2]Record{}, [1]Record{r}, [1]Record{})
	expect_elements(t, records[:], []Record{{}, {}, r, {}})
	rows := intrinsics.concatenate([2]Pair{}, [1]Pair{{3, 4}}, [1]Pair{})
	expect_elements(t, rows[:], []Pair{{0, 0}, {0, 0}, {3, 4}, {0, 0}})
}

@test
concatenate_nested_arrays :: proc(t: ^testing.T) {
	nested := intrinsics.concatenate(
		intrinsics.concatenate([2]u8{}, [1]u8{1}),
		intrinsics.concatenate([2]u8{}, [3]u8{5, 4, 3}))
	expect_elements(t, nested[:], []u8{0, 0, 1, 0, 0, 5, 4, 3})
	nested_slice := intrinsics.concatenate(intrinsics.concatenate([]u8{}, []u8{1}), []u8{})
	expect_elements(t, nested_slice, []u8{1})
}

@test
concatenate_nil_elements :: proc(t: ^testing.T) {
	values := intrinsics.concatenate([2][dynamic]int{}, [0][dynamic]int{})
	testing.expect_value(t, len(values), 2)
	for value in values {
		raw := transmute(mem.Raw_Dynamic_Array)value
		testing.expect(t, raw.data == nil)
		testing.expect_value(t, raw.len, 0)
		testing.expect_value(t, raw.cap, 0)
		testing.expect(t, raw.allocator.procedure == nil && raw.allocator.data == nil)
	}

	Nested :: [2][dynamic]int
	nested := intrinsics.concatenate([2]Nested{}, [0]Nested{})
	testing.expect_value(t, len(nested), 2)
	for row in nested {
		for value in row {
			raw := transmute(mem.Raw_Dynamic_Array)value
			testing.expect(t, raw.data == nil && raw.allocator.procedure == nil && raw.allocator.data == nil)
			testing.expect_value(t, raw.len, 0)
			testing.expect_value(t, raw.cap, 0)
		}
	}

	Record :: struct {
		marker: int,
		data: [dynamic]int,
	}
	r :: Record{marker = 7}
	records := intrinsics.concatenate([2]Record{}, [1]Record{r}, [1]Record{})
	testing.expect_value(t, len(records), 4)
	for record, i in records {
		testing.expect_value(t, record.marker, i == 2 ? 7 : 0)
		raw := transmute(mem.Raw_Dynamic_Array)record.data
		testing.expect(t, raw.data == nil && raw.allocator.procedure == nil && raw.allocator.data == nil)
		testing.expect_value(t, raw.len, 0)
		testing.expect_value(t, raw.cap, 0)
	}
}
