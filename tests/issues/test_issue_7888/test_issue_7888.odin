package expect_assert_race

import "core:testing"

check :: proc(x: int) { assert(x < 10, "x too big") }

@(test) misuse_1 :: proc(t: ^testing.T) { testing.expect_assert(t, "x too big"); check(50) }
@(test) misuse_2 :: proc(t: ^testing.T) { testing.expect_assert(t, "x too big"); check(50) } //comment out this line to make it work
