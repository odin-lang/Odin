package test_issue_const_array_broadcast

import "core:testing"

// A value assigned to an array is broadcast to every element of every level, but the constant
// lowering only recognised a literal whose type was the immediate element type. `[4][8]Item` has
// two levels to cross and `[8]U` has a union variant to reach, so both were taken for array
// literals and tripped an assertion in the compiler.

@(private="file")
Item :: struct {
	stage: int,
	size:  int,
}

@(private="file")
U :: union {
	Item,
}

@(private="file")
Desc :: struct {
	items: [4][8]Item,
}

@(private="file")
nested_global: [4][8]Item = Item{stage = 1, size = 64}

@(private="file")
union_global: [8]U = U(Item{stage = 2, size = 65})

@(test)
const_array_broadcast_nested :: proc(t: ^testing.T) {
	expected :: Item{stage = 1, size = 64}

	for row in nested_global {
		for item in row {
			testing.expect_value(t, item, expected)
		}
	}

	nested_local: [4][8]Item = Item{stage = 1, size = 64}
	testing.expect_value(t, nested_local, nested_global)

	d := Desc{items = Item{stage = 1, size = 64}}
	testing.expect_value(t, d.items, nested_global)

	// positional fields reach the same path
	positional: [4][8]Item = Item{1, 64}
	testing.expect_value(t, positional, nested_global)

	deep: [2][3][4]int = 7
	testing.expect_value(t, deep[1][2][3], 7)
}

@(test)
const_array_broadcast_union :: proc(t: ^testing.T) {
	expected :: Item{stage = 2, size = 65}

	for u in union_global {
		item, ok := u.(Item)
		testing.expect(t, ok, "every element should hold the Item variant")
		testing.expect_value(t, item, expected)
	}

	union_local: [8]U = U(Item{stage = 2, size = 65})
	testing.expect_value(t, union_local, union_global)
}

// A named untyped constant against a union hint, broadcast into an array variant, lost its
// constant value and the backend then tried to load the constant entity as a variable.

@(private="file")
Target :: union {
	[]Item,
	[2]u32,
}

@(private="file")
TARGET_SIZE :: 8192

@(private="file")
take_target :: proc(target: Target, count: u32) -> Target {
	return target
}

@(test)
const_array_broadcast_into_union_variant :: proc(t: ^testing.T) {
	expected := [2]u32{TARGET_SIZE, TARGET_SIZE}

	assigned: Target = TARGET_SIZE
	testing.expect_value(t, assigned.([2]u32), expected)

	named := take_target(target = TARGET_SIZE, count = 3)
	testing.expect_value(t, named.([2]u32), expected)

	positional := take_target(TARGET_SIZE*2, 3)
	testing.expect_value(t, positional.([2]u32), [2]u32{2*TARGET_SIZE, 2*TARGET_SIZE})

	elems := [2]Target{TARGET_SIZE, {}}
	testing.expect_value(t, elems[0].([2]u32), expected)
	testing.expect(t, elems[1] == nil, "the second element should be nil")
}

@(test)
const_array_literals_unchanged :: proc(t: ^testing.T) {
	// a literal for the array's own type is not a broadcast
	indexed: [4]Item = {0..<2 = Item{stage = 3, size = 66}, 3 = Item{stage = 4, size = 67}}
	testing.expect_value(t, indexed[0], Item{stage = 3, size = 66})
	testing.expect_value(t, indexed[1], Item{stage = 3, size = 66})
	testing.expect_value(t, indexed[2], Item{})
	testing.expect_value(t, indexed[3], Item{stage = 4, size = 67})

	positional: [3]Item = {Item{stage = 5, size = 68}, {}, {}}
	testing.expect_value(t, positional[0], Item{stage = 5, size = 68})
	testing.expect_value(t, positional[2], Item{})
}
