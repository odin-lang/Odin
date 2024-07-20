package test_core_mem

import "core:mem/tlsf"
import "core:testing"

@test
test_tlsf_bitscan :: proc(t: ^testing.T) {
	Vector :: struct {
		op:  enum{ffs, fls, fls_uint},
		v:   union{u32, uint},
		exp: i32,
	}
	Tests := []Vector{
		{.ffs,      u32 (0x0000_0000_0000_0000), -1},
		{.ffs,      u32 (0x0000_0000_0000_0000), -1},
		{.fls,      u32 (0x0000_0000_0000_0000), -1},
		{.ffs,      u32 (0x0000_0000_0000_0001),  0},
		{.fls,      u32 (0x0000_0000_0000_0001),  0},
		{.ffs,      u32 (0x0000_0000_8000_0000), 31},
		{.ffs,      u32 (0x0000_0000_8000_8000), 15},
		{.fls,      u32 (0x0000_0000_8000_0008), 31},
		{.fls,      u32 (0x0000_0000_7FFF_FFFF), 30},
		{.fls_uint, uint(0x0000_0000_8000_0000), 31},
		{.fls_uint, uint(0x0000_0001_0000_0000), 32},
		{.fls_uint, uint(0xffff_ffff_ffff_ffff), 63},
	}

	for test in Tests {
		switch test.op {
		case .ffs:
			res := tlsf.ffs(test.v.?)
			testing.expectf(t, res == test.exp, "Expected tlsf.ffs(0x%08x) == %v, got %v", test.v, test.exp, res)
		case .fls:
			res := tlsf.fls(test.v.?)
			testing.expectf(t, res == test.exp, "Expected tlsf.fls(0x%08x) == %v, got %v", test.v, test.exp, res)
		case .fls_uint:
			res := tlsf.fls_uint(test.v.?)
			testing.expectf(t, res == test.exp, "Expected tlsf.fls_uint(0x%16x) == %v, got %v", test.v, test.exp, res)
		}
	}
}