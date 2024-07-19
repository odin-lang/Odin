package test_internal

import "core:testing"

@test
test_128_align :: proc(t: ^testing.T) {
	Danger_Struct :: struct {
		x: u128,
		y: u64,
	}

	list := [?]Danger_Struct{{0, 0}, {1, 0}, {2, 0}, {3, 0}}

	testing.expectf(t, list[0].x == 0, "[0].x (%v) != 0", list[0].x)
	testing.expectf(t, list[0].y == 0, "[0].y (%v) != 0", list[0].y)

	testing.expectf(t, list[1].x == 1, "[1].x (%v) != 1", list[1].x)
	testing.expectf(t, list[1].y == 0, "[1].y (%v) != 0", list[1].y)

	testing.expectf(t, list[2].x == 2, "[2].x (%v) != 2", list[2].x)
	testing.expectf(t, list[2].y == 0, "[2].y (%v) != 0", list[2].y)

	testing.expectf(t, list[3].x == 3, "[3].x (%v) != 3", list[3].x)
	testing.expectf(t, list[3].y == 0, "[3].y (%v) != 0", list[3].y)
}
