package test_core_libc

import "core:c"
import "core:testing"

@test
test_libc_fastint_width :: proc(t: ^testing.T) {
	when ODIN_OS == .FreeBSD || ODIN_OS == .OpenBSD || ODIN_OS == .NetBSD {
		testing.expect_value(t, size_of(c.int_fast8_t), 4)
		testing.expect_value(t, size_of(c.uint_fast8_t), 4)
		testing.expect_value(t, size_of(c.int_fast16_t), 4)
		testing.expect_value(t, size_of(c.uint_fast16_t), 4)
		testing.expect_value(t, size_of(c.int_fast32_t), 4)
		testing.expect_value(t, size_of(c.uint_fast32_t), 4)
	} else when ODIN_OS == .Darwin {
		testing.expect_value(t, size_of(c.int_fast8_t), 1)
		testing.expect_value(t, size_of(c.uint_fast8_t), 1)
		testing.expect_value(t, size_of(c.int_fast16_t), 2)
		testing.expect_value(t, size_of(c.uint_fast16_t), 2)
		testing.expect_value(t, size_of(c.int_fast32_t), 4)
		testing.expect_value(t, size_of(c.uint_fast32_t), 4)
	} else when ODIN_OS == .Linux {
		testing.expect_value(t, size_of(c.int_fast8_t), 1)
		testing.expect_value(t, size_of(c.uint_fast8_t), 1)
		when size_of(rawptr) == 8 { // glibc only - broken for musl
			testing.expect_value(t, size_of(c.int_fast16_t), 8)
			testing.expect_value(t, size_of(c.uint_fast16_t), 8)
			testing.expect_value(t, size_of(c.int_fast32_t), 8)
			testing.expect_value(t, size_of(c.uint_fast32_t), 8)
		} else {
			testing.expect_value(t, size_of(c.int_fast16_t), 4)
			testing.expect_value(t, size_of(c.uint_fast16_t), 4)
			testing.expect_value(t, size_of(c.int_fast32_t), 4)
			testing.expect_value(t, size_of(c.uint_fast32_t), 4)
		}
	} else when ODIN_OS == .Windows {
		testing.expect_value(t, size_of(c.int_fast8_t), 1)
		testing.expect_value(t, size_of(c.uint_fast8_t), 1)
		testing.expect_value(t, size_of(c.int_fast16_t), 4)
		testing.expect_value(t, size_of(c.uint_fast16_t), 4)
		testing.expect_value(t, size_of(c.int_fast32_t), 4)
		testing.expect_value(t, size_of(c.uint_fast32_t), 4)
	} else {
		testing.expect_value(t, size_of(c.int_fast8_t), 1)
		testing.expect_value(t, size_of(c.uint_fast8_t), 1)
		testing.expect_value(t, size_of(c.int_fast16_t), 4)
		testing.expect_value(t, size_of(c.uint_fast16_t), 4)
		testing.expect_value(t, size_of(c.int_fast32_t), 4)
		testing.expect_value(t, size_of(c.uint_fast32_t), 4)
	}
	testing.expect_value(t, size_of(c.int_fast64_t), 8)
	testing.expect_value(t, size_of(c.uint_fast64_t), 8)
}
