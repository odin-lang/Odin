package test_internal

import "core:testing"

// Each level used to measure its member twice. Build time doubled with every level.

Deep_00 :: struct #align(32) {
	x: f64,
}

Deep_01 :: struct {
	a: Deep_00,
}

Deep_02 :: struct {
	a: Deep_01,
}

Deep_03 :: struct {
	a: Deep_02,
}

Deep_04 :: struct {
	a: Deep_03,
}

Deep_05 :: struct {
	a: Deep_04,
}

Deep_06 :: struct {
	a: Deep_05,
}

Deep_07 :: struct {
	a: Deep_06,
}

Deep_08 :: struct {
	a: Deep_07,
}

Deep_09 :: struct {
	a: Deep_08,
}

Deep_10 :: struct {
	a: Deep_09,
}

Deep_11 :: struct {
	a: Deep_10,
}

Deep_12 :: struct {
	a: Deep_11,
}

Deep_13 :: struct {
	a: Deep_12,
}

Deep_14 :: struct {
	a: Deep_13,
}

Deep_15 :: struct {
	a: Deep_14,
}

Deep_16 :: struct {
	a: Deep_15,
}

Deep_17 :: struct {
	a: Deep_16,
}

Deep_18 :: struct {
	a: Deep_17,
}

Deep_19 :: struct {
	a: Deep_18,
}

Deep_20 :: struct {
	a: Deep_19,
}

Deep_21 :: struct {
	a: Deep_20,
}

Deep_22 :: struct {
	a: Deep_21,
}

Deep_23 :: struct {
	a: Deep_22,
}

Deep_24 :: struct {
	a: Deep_23,
}

Deep_25 :: struct {
	a: Deep_24,
}

Deep_26 :: struct {
	a: Deep_25,
}

Deep_27 :: struct {
	a: Deep_26,
}

Deep_28 :: struct {
	a: Deep_27,
}

Deep_29 :: struct {
	a: Deep_28,
}

Deep_30 :: struct {
	a: Deep_29,
}

Deep_31 :: struct {
	a: Deep_30,
}

@(private="file")
deep_identity :: proc "c" (d: Deep_31) -> Deep_31 {
	return d
}

@(test)
test_deep_nested_struct :: proc(t: ^testing.T) {
	d: Deep_31
	(^f64)(&d)^ = 1.5

	e := #force_no_inline deep_identity(d)
	testing.expect(t, e == d)
	testing.expect_value(t, size_of(Deep_31), 32)
	testing.expect_value(t, align_of(Deep_31), 32)
}

DEEP_WHEN :: 32

when DEEP_WHEN == 0 {
} else when DEEP_WHEN == 1 {
} else when DEEP_WHEN == 2 {
} else when DEEP_WHEN == 3 {
} else when DEEP_WHEN == 4 {
} else when DEEP_WHEN == 5 {
} else when DEEP_WHEN == 6 {
} else when DEEP_WHEN == 7 {
} else when DEEP_WHEN == 8 {
} else when DEEP_WHEN == 9 {
} else when DEEP_WHEN == 10 {
} else when DEEP_WHEN == 11 {
} else when DEEP_WHEN == 12 {
} else when DEEP_WHEN == 13 {
} else when DEEP_WHEN == 14 {
} else when DEEP_WHEN == 15 {
} else when DEEP_WHEN == 16 {
} else when DEEP_WHEN == 17 {
} else when DEEP_WHEN == 18 {
} else when DEEP_WHEN == 19 {
} else when DEEP_WHEN == 20 {
} else when DEEP_WHEN == 21 {
} else when DEEP_WHEN == 22 {
} else when DEEP_WHEN == 23 {
} else when DEEP_WHEN == 24 {
} else when DEEP_WHEN == 25 {
} else when DEEP_WHEN == 26 {
} else when DEEP_WHEN == 27 {
} else when DEEP_WHEN == 28 {
} else when DEEP_WHEN == 29 {
} else when DEEP_WHEN == 30 {
} else when DEEP_WHEN == 31 {
} else {
	DEEP_WHEN_REACHED :: true
}

@(test)
test_deep_when_chain :: proc(t: ^testing.T) {
	testing.expect(t, DEEP_WHEN_REACHED)
}
