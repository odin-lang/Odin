// The BSD 1-Clause License (BSD-1-Clause)
//
// Copyright (c) 2015-2020 the fiat-crypto authors (see the AUTHORS file)
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//     1. Redistributions of source code must retain the above copyright
//        notice, this list of conditions and the following disclaimer.
//
// THIS SOFTWARE IS PROVIDED BY the fiat-crypto authors "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
// THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
// PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL Berkeley Software Design,
// Inc. BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
// EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
// PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
// PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
// LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
// NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

package field_curve25519

// The file provides arithmetic on the field Z/(2^255-19) using
// unsaturated 64-bit integer arithmetic.  It is derived primarily
// from the machine generated Golang output from the fiat-crypto project.
//
// While the base implementation is provably correct, this implementation
// makes no such claims as the port and optimizations were done by hand.
//
// TODO:
//  * When fiat-crypto supports it, using a saturated 64-bit limbs
//    instead of 51-bit limbs will be faster, though the gains are
//    minimal unless adcx/adox/mulx are used.

import fiat "core:crypto/_fiat"
import "core:math/bits"

Loose_Field_Element :: distinct [5]u64
Tight_Field_Element :: distinct [5]u64

@(rodata)
FE_ZERO := Tight_Field_Element{0, 0, 0, 0, 0}
@(rodata)
FE_ONE := Tight_Field_Element{1, 0, 0, 0, 0}

@(rodata)
FE_SQRT_M1 := Tight_Field_Element {
	1718705420411056,
	234908883556509,
	2233514472574048,
	2117202627021982,
	765476049583133,
}

_addcarryx_u51 :: #force_inline proc "contextless" (
	arg1: fiat.u1,
	arg2, arg3: u64,
) -> (
	out1: u64,
	out2: fiat.u1,
) {
	x1 := ((u64(arg1) + arg2) + arg3)
	x2 := (x1 & 0x7ffffffffffff)
	x3 := fiat.u1((x1 >> 51))
	out1 = x2
	out2 = x3
	return
}

_subborrowx_u51 :: #force_inline proc "contextless" (
	arg1: fiat.u1,
	arg2, arg3: u64,
) -> (
	out1: u64,
	out2: fiat.u1,
) {
	x1 := ((i64(arg2) - i64(arg1)) - i64(arg3))
	x2 := fiat.i1((x1 >> 51))
	x3 := (u64(x1) & 0x7ffffffffffff)
	out1 = x3
	out2 = (0x0 - fiat.u1(x2))
	return
}

fe_carry_mul :: proc "contextless" (out1: ^Tight_Field_Element, arg1, arg2: ^Loose_Field_Element) {
	x2, x1 := bits.mul_u64(arg1[4], (arg2[4] * 0x13))
	x4, x3 := bits.mul_u64(arg1[4], (arg2[3] * 0x13))
	x6, x5 := bits.mul_u64(arg1[4], (arg2[2] * 0x13))
	x8, x7 := bits.mul_u64(arg1[4], (arg2[1] * 0x13))
	x10, x9 := bits.mul_u64(arg1[3], (arg2[4] * 0x13))
	x12, x11 := bits.mul_u64(arg1[3], (arg2[3] * 0x13))
	x14, x13 := bits.mul_u64(arg1[3], (arg2[2] * 0x13))
	x16, x15 := bits.mul_u64(arg1[2], (arg2[4] * 0x13))
	x18, x17 := bits.mul_u64(arg1[2], (arg2[3] * 0x13))
	x20, x19 := bits.mul_u64(arg1[1], (arg2[4] * 0x13))
	x22, x21 := bits.mul_u64(arg1[4], arg2[0])
	x24, x23 := bits.mul_u64(arg1[3], arg2[1])
	x26, x25 := bits.mul_u64(arg1[3], arg2[0])
	x28, x27 := bits.mul_u64(arg1[2], arg2[2])
	x30, x29 := bits.mul_u64(arg1[2], arg2[1])
	x32, x31 := bits.mul_u64(arg1[2], arg2[0])
	x34, x33 := bits.mul_u64(arg1[1], arg2[3])
	x36, x35 := bits.mul_u64(arg1[1], arg2[2])
	x38, x37 := bits.mul_u64(arg1[1], arg2[1])
	x40, x39 := bits.mul_u64(arg1[1], arg2[0])
	x42, x41 := bits.mul_u64(arg1[0], arg2[4])
	x44, x43 := bits.mul_u64(arg1[0], arg2[3])
	x46, x45 := bits.mul_u64(arg1[0], arg2[2])
	x48, x47 := bits.mul_u64(arg1[0], arg2[1])
	x50, x49 := bits.mul_u64(arg1[0], arg2[0])
	x51, x52 := bits.add_u64(x13, x7, u64(0x0))
	x53, _ := bits.add_u64(x14, x8, u64(fiat.u1(x52)))
	x55, x56 := bits.add_u64(x17, x51, u64(0x0))
	x57, _ := bits.add_u64(x18, x53, u64(fiat.u1(x56)))
	x59, x60 := bits.add_u64(x19, x55, u64(0x0))
	x61, _ := bits.add_u64(x20, x57, u64(fiat.u1(x60)))
	x63, x64 := bits.add_u64(x49, x59, u64(0x0))
	x65, _ := bits.add_u64(x50, x61, u64(fiat.u1(x64)))
	x67 := ((x63 >> 51) | ((x65 << 13) & 0xffffffffffffffff))
	x68 := (x63 & 0x7ffffffffffff)
	x69, x70 := bits.add_u64(x23, x21, u64(0x0))
	x71, _ := bits.add_u64(x24, x22, u64(fiat.u1(x70)))
	x73, x74 := bits.add_u64(x27, x69, u64(0x0))
	x75, _ := bits.add_u64(x28, x71, u64(fiat.u1(x74)))
	x77, x78 := bits.add_u64(x33, x73, u64(0x0))
	x79, _ := bits.add_u64(x34, x75, u64(fiat.u1(x78)))
	x81, x82 := bits.add_u64(x41, x77, u64(0x0))
	x83, _ := bits.add_u64(x42, x79, u64(fiat.u1(x82)))
	x85, x86 := bits.add_u64(x25, x1, u64(0x0))
	x87, _ := bits.add_u64(x26, x2, u64(fiat.u1(x86)))
	x89, x90 := bits.add_u64(x29, x85, u64(0x0))
	x91, _ := bits.add_u64(x30, x87, u64(fiat.u1(x90)))
	x93, x94 := bits.add_u64(x35, x89, u64(0x0))
	x95, _ := bits.add_u64(x36, x91, u64(fiat.u1(x94)))
	x97, x98 := bits.add_u64(x43, x93, u64(0x0))
	x99, _ := bits.add_u64(x44, x95, u64(fiat.u1(x98)))
	x101, x102 := bits.add_u64(x9, x3, u64(0x0))
	x103, _ := bits.add_u64(x10, x4, u64(fiat.u1(x102)))
	x105, x106 := bits.add_u64(x31, x101, u64(0x0))
	x107, _ := bits.add_u64(x32, x103, u64(fiat.u1(x106)))
	x109, x110 := bits.add_u64(x37, x105, u64(0x0))
	x111, _ := bits.add_u64(x38, x107, u64(fiat.u1(x110)))
	x113, x114 := bits.add_u64(x45, x109, u64(0x0))
	x115, _ := bits.add_u64(x46, x111, u64(fiat.u1(x114)))
	x117, x118 := bits.add_u64(x11, x5, u64(0x0))
	x119, _ := bits.add_u64(x12, x6, u64(fiat.u1(x118)))
	x121, x122 := bits.add_u64(x15, x117, u64(0x0))
	x123, _ := bits.add_u64(x16, x119, u64(fiat.u1(x122)))
	x125, x126 := bits.add_u64(x39, x121, u64(0x0))
	x127, _ := bits.add_u64(x40, x123, u64(fiat.u1(x126)))
	x129, x130 := bits.add_u64(x47, x125, u64(0x0))
	x131, _ := bits.add_u64(x48, x127, u64(fiat.u1(x130)))
	x133, x134 := bits.add_u64(x67, x129, u64(0x0))
	x135 := (u64(fiat.u1(x134)) + x131)
	x136 := ((x133 >> 51) | ((x135 << 13) & 0xffffffffffffffff))
	x137 := (x133 & 0x7ffffffffffff)
	x138, x139 := bits.add_u64(x136, x113, u64(0x0))
	x140 := (u64(fiat.u1(x139)) + x115)
	x141 := ((x138 >> 51) | ((x140 << 13) & 0xffffffffffffffff))
	x142 := (x138 & 0x7ffffffffffff)
	x143, x144 := bits.add_u64(x141, x97, u64(0x0))
	x145 := (u64(fiat.u1(x144)) + x99)
	x146 := ((x143 >> 51) | ((x145 << 13) & 0xffffffffffffffff))
	x147 := (x143 & 0x7ffffffffffff)
	x148, x149 := bits.add_u64(x146, x81, u64(0x0))
	x150 := (u64(fiat.u1(x149)) + x83)
	x151 := ((x148 >> 51) | ((x150 << 13) & 0xffffffffffffffff))
	x152 := (x148 & 0x7ffffffffffff)
	x153 := (x151 * 0x13)
	x154 := (x68 + x153)
	x155 := (x154 >> 51)
	x156 := (x154 & 0x7ffffffffffff)
	x157 := (x155 + x137)
	x158 := fiat.u1((x157 >> 51))
	x159 := (x157 & 0x7ffffffffffff)
	x160 := (u64(x158) + x142)
	out1[0] = x156
	out1[1] = x159
	out1[2] = x160
	out1[3] = x147
	out1[4] = x152
}

fe_carry_square :: proc "contextless" (out1: ^Tight_Field_Element, arg1: ^Loose_Field_Element) {
	x1 := (arg1[4] * 0x13)
	x2 := (x1 * 0x2)
	x3 := (arg1[4] * 0x2)
	x4 := (arg1[3] * 0x13)
	x5 := (x4 * 0x2)
	x6 := (arg1[3] * 0x2)
	x7 := (arg1[2] * 0x2)
	x8 := (arg1[1] * 0x2)
	x10, x9 := bits.mul_u64(arg1[4], x1)
	x12, x11 := bits.mul_u64(arg1[3], x2)
	x14, x13 := bits.mul_u64(arg1[3], x4)
	x16, x15 := bits.mul_u64(arg1[2], x2)
	x18, x17 := bits.mul_u64(arg1[2], x5)
	x20, x19 := bits.mul_u64(arg1[2], arg1[2])
	x22, x21 := bits.mul_u64(arg1[1], x2)
	x24, x23 := bits.mul_u64(arg1[1], x6)
	x26, x25 := bits.mul_u64(arg1[1], x7)
	x28, x27 := bits.mul_u64(arg1[1], arg1[1])
	x30, x29 := bits.mul_u64(arg1[0], x3)
	x32, x31 := bits.mul_u64(arg1[0], x6)
	x34, x33 := bits.mul_u64(arg1[0], x7)
	x36, x35 := bits.mul_u64(arg1[0], x8)
	x38, x37 := bits.mul_u64(arg1[0], arg1[0])
	x39, x40 := bits.add_u64(x21, x17, u64(0x0))
	x41, _ := bits.add_u64(x22, x18, u64(fiat.u1(x40)))
	x43, x44 := bits.add_u64(x37, x39, u64(0x0))
	x45, _ := bits.add_u64(x38, x41, u64(fiat.u1(x44)))
	x47 := ((x43 >> 51) | ((x45 << 13) & 0xffffffffffffffff))
	x48 := (x43 & 0x7ffffffffffff)
	x49, x50 := bits.add_u64(x23, x19, u64(0x0))
	x51, _ := bits.add_u64(x24, x20, u64(fiat.u1(x50)))
	x53, x54 := bits.add_u64(x29, x49, u64(0x0))
	x55, _ := bits.add_u64(x30, x51, u64(fiat.u1(x54)))
	x57, x58 := bits.add_u64(x25, x9, u64(0x0))
	x59, _ := bits.add_u64(x26, x10, u64(fiat.u1(x58)))
	x61, x62 := bits.add_u64(x31, x57, u64(0x0))
	x63, _ := bits.add_u64(x32, x59, u64(fiat.u1(x62)))
	x65, x66 := bits.add_u64(x27, x11, u64(0x0))
	x67, _ := bits.add_u64(x28, x12, u64(fiat.u1(x66)))
	x69, x70 := bits.add_u64(x33, x65, u64(0x0))
	x71, _ := bits.add_u64(x34, x67, u64(fiat.u1(x70)))
	x73, x74 := bits.add_u64(x15, x13, u64(0x0))
	x75, _ := bits.add_u64(x16, x14, u64(fiat.u1(x74)))
	x77, x78 := bits.add_u64(x35, x73, u64(0x0))
	x79, _ := bits.add_u64(x36, x75, u64(fiat.u1(x78)))
	x81, x82 := bits.add_u64(x47, x77, u64(0x0))
	x83 := (u64(fiat.u1(x82)) + x79)
	x84 := ((x81 >> 51) | ((x83 << 13) & 0xffffffffffffffff))
	x85 := (x81 & 0x7ffffffffffff)
	x86, x87 := bits.add_u64(x84, x69, u64(0x0))
	x88 := (u64(fiat.u1(x87)) + x71)
	x89 := ((x86 >> 51) | ((x88 << 13) & 0xffffffffffffffff))
	x90 := (x86 & 0x7ffffffffffff)
	x91, x92 := bits.add_u64(x89, x61, u64(0x0))
	x93 := (u64(fiat.u1(x92)) + x63)
	x94 := ((x91 >> 51) | ((x93 << 13) & 0xffffffffffffffff))
	x95 := (x91 & 0x7ffffffffffff)
	x96, x97 := bits.add_u64(x94, x53, u64(0x0))
	x98 := (u64(fiat.u1(x97)) + x55)
	x99 := ((x96 >> 51) | ((x98 << 13) & 0xffffffffffffffff))
	x100 := (x96 & 0x7ffffffffffff)
	x101 := (x99 * 0x13)
	x102 := (x48 + x101)
	x103 := (x102 >> 51)
	x104 := (x102 & 0x7ffffffffffff)
	x105 := (x103 + x85)
	x106 := fiat.u1((x105 >> 51))
	x107 := (x105 & 0x7ffffffffffff)
	x108 := (u64(x106) + x90)
	out1[0] = x104
	out1[1] = x107
	out1[2] = x108
	out1[3] = x95
	out1[4] = x100
}

fe_carry :: proc "contextless" (out1: ^Tight_Field_Element, arg1: ^Loose_Field_Element) {
	x1 := arg1[0]
	x2 := ((x1 >> 51) + arg1[1])
	x3 := ((x2 >> 51) + arg1[2])
	x4 := ((x3 >> 51) + arg1[3])
	x5 := ((x4 >> 51) + arg1[4])
	x6 := ((x1 & 0x7ffffffffffff) + ((x5 >> 51) * 0x13))
	x7 := (u64(fiat.u1((x6 >> 51))) + (x2 & 0x7ffffffffffff))
	x8 := (x6 & 0x7ffffffffffff)
	x9 := (x7 & 0x7ffffffffffff)
	x10 := (u64(fiat.u1((x7 >> 51))) + (x3 & 0x7ffffffffffff))
	x11 := (x4 & 0x7ffffffffffff)
	x12 := (x5 & 0x7ffffffffffff)
	out1[0] = x8
	out1[1] = x9
	out1[2] = x10
	out1[3] = x11
	out1[4] = x12
}

fe_add :: proc "contextless" (out1: ^Loose_Field_Element, arg1, arg2: ^Tight_Field_Element) {
	x1 := (arg1[0] + arg2[0])
	x2 := (arg1[1] + arg2[1])
	x3 := (arg1[2] + arg2[2])
	x4 := (arg1[3] + arg2[3])
	x5 := (arg1[4] + arg2[4])
	out1[0] = x1
	out1[1] = x2
	out1[2] = x3
	out1[3] = x4
	out1[4] = x5
}

fe_sub :: proc "contextless" (out1: ^Loose_Field_Element, arg1, arg2: ^Tight_Field_Element) {
	x1 := ((0xfffffffffffda + arg1[0]) - arg2[0])
	x2 := ((0xffffffffffffe + arg1[1]) - arg2[1])
	x3 := ((0xffffffffffffe + arg1[2]) - arg2[2])
	x4 := ((0xffffffffffffe + arg1[3]) - arg2[3])
	x5 := ((0xffffffffffffe + arg1[4]) - arg2[4])
	out1[0] = x1
	out1[1] = x2
	out1[2] = x3
	out1[3] = x4
	out1[4] = x5
}

fe_opp :: proc "contextless" (out1: ^Loose_Field_Element, arg1: ^Tight_Field_Element) {
	x1 := (0xfffffffffffda - arg1[0])
	x2 := (0xffffffffffffe - arg1[1])
	x3 := (0xffffffffffffe - arg1[2])
	x4 := (0xffffffffffffe - arg1[3])
	x5 := (0xffffffffffffe - arg1[4])
	out1[0] = x1
	out1[1] = x2
	out1[2] = x3
	out1[3] = x4
	out1[4] = x5
}

@(optimization_mode = "none")
fe_cond_assign :: #force_no_inline proc "contextless" (
	out1, arg1: ^Tight_Field_Element,
	arg2: int,
) {
	x1 := fiat.cmovznz_u64(fiat.u1(arg2), out1[0], arg1[0])
	x2 := fiat.cmovznz_u64(fiat.u1(arg2), out1[1], arg1[1])
	x3 := fiat.cmovznz_u64(fiat.u1(arg2), out1[2], arg1[2])
	x4 := fiat.cmovznz_u64(fiat.u1(arg2), out1[3], arg1[3])
	x5 := fiat.cmovznz_u64(fiat.u1(arg2), out1[4], arg1[4])
	out1[0] = x1
	out1[1] = x2
	out1[2] = x3
	out1[3] = x4
	out1[4] = x5
}

fe_to_bytes :: proc "contextless" (out1: ^[32]byte, arg1: ^Tight_Field_Element) {
	x1, x2 := _subborrowx_u51(0x0, arg1[0], 0x7ffffffffffed)
	x3, x4 := _subborrowx_u51(x2, arg1[1], 0x7ffffffffffff)
	x5, x6 := _subborrowx_u51(x4, arg1[2], 0x7ffffffffffff)
	x7, x8 := _subborrowx_u51(x6, arg1[3], 0x7ffffffffffff)
	x9, x10 := _subborrowx_u51(x8, arg1[4], 0x7ffffffffffff)
	x11 := fiat.cmovznz_u64(x10, u64(0x0), 0xffffffffffffffff)
	x12, x13 := _addcarryx_u51(0x0, x1, (x11 & 0x7ffffffffffed))
	x14, x15 := _addcarryx_u51(x13, x3, (x11 & 0x7ffffffffffff))
	x16, x17 := _addcarryx_u51(x15, x5, (x11 & 0x7ffffffffffff))
	x18, x19 := _addcarryx_u51(x17, x7, (x11 & 0x7ffffffffffff))
	x20, _ := _addcarryx_u51(x19, x9, (x11 & 0x7ffffffffffff))
	x22 := (x20 << 4)
	x23 := (x18 * u64(0x2))
	x24 := (x16 << 6)
	x25 := (x14 << 3)
	x26 := (u8(x12) & 0xff)
	x27 := (x12 >> 8)
	x28 := (u8(x27) & 0xff)
	x29 := (x27 >> 8)
	x30 := (u8(x29) & 0xff)
	x31 := (x29 >> 8)
	x32 := (u8(x31) & 0xff)
	x33 := (x31 >> 8)
	x34 := (u8(x33) & 0xff)
	x35 := (x33 >> 8)
	x36 := (u8(x35) & 0xff)
	x37 := u8((x35 >> 8))
	x38 := (x25 + u64(x37))
	x39 := (u8(x38) & 0xff)
	x40 := (x38 >> 8)
	x41 := (u8(x40) & 0xff)
	x42 := (x40 >> 8)
	x43 := (u8(x42) & 0xff)
	x44 := (x42 >> 8)
	x45 := (u8(x44) & 0xff)
	x46 := (x44 >> 8)
	x47 := (u8(x46) & 0xff)
	x48 := (x46 >> 8)
	x49 := (u8(x48) & 0xff)
	x50 := u8((x48 >> 8))
	x51 := (x24 + u64(x50))
	x52 := (u8(x51) & 0xff)
	x53 := (x51 >> 8)
	x54 := (u8(x53) & 0xff)
	x55 := (x53 >> 8)
	x56 := (u8(x55) & 0xff)
	x57 := (x55 >> 8)
	x58 := (u8(x57) & 0xff)
	x59 := (x57 >> 8)
	x60 := (u8(x59) & 0xff)
	x61 := (x59 >> 8)
	x62 := (u8(x61) & 0xff)
	x63 := (x61 >> 8)
	x64 := (u8(x63) & 0xff)
	x65 := fiat.u1((x63 >> 8))
	x66 := (x23 + u64(x65))
	x67 := (u8(x66) & 0xff)
	x68 := (x66 >> 8)
	x69 := (u8(x68) & 0xff)
	x70 := (x68 >> 8)
	x71 := (u8(x70) & 0xff)
	x72 := (x70 >> 8)
	x73 := (u8(x72) & 0xff)
	x74 := (x72 >> 8)
	x75 := (u8(x74) & 0xff)
	x76 := (x74 >> 8)
	x77 := (u8(x76) & 0xff)
	x78 := u8((x76 >> 8))
	x79 := (x22 + u64(x78))
	x80 := (u8(x79) & 0xff)
	x81 := (x79 >> 8)
	x82 := (u8(x81) & 0xff)
	x83 := (x81 >> 8)
	x84 := (u8(x83) & 0xff)
	x85 := (x83 >> 8)
	x86 := (u8(x85) & 0xff)
	x87 := (x85 >> 8)
	x88 := (u8(x87) & 0xff)
	x89 := (x87 >> 8)
	x90 := (u8(x89) & 0xff)
	x91 := u8((x89 >> 8))
	out1[0] = x26
	out1[1] = x28
	out1[2] = x30
	out1[3] = x32
	out1[4] = x34
	out1[5] = x36
	out1[6] = x39
	out1[7] = x41
	out1[8] = x43
	out1[9] = x45
	out1[10] = x47
	out1[11] = x49
	out1[12] = x52
	out1[13] = x54
	out1[14] = x56
	out1[15] = x58
	out1[16] = x60
	out1[17] = x62
	out1[18] = x64
	out1[19] = x67
	out1[20] = x69
	out1[21] = x71
	out1[22] = x73
	out1[23] = x75
	out1[24] = x77
	out1[25] = x80
	out1[26] = x82
	out1[27] = x84
	out1[28] = x86
	out1[29] = x88
	out1[30] = x90
	out1[31] = x91
}

_fe_from_bytes :: proc "contextless" (out1: ^Tight_Field_Element, arg1: ^[32]byte) {
	x1 := (u64(arg1[31]) << 44)
	x2 := (u64(arg1[30]) << 36)
	x3 := (u64(arg1[29]) << 28)
	x4 := (u64(arg1[28]) << 20)
	x5 := (u64(arg1[27]) << 12)
	x6 := (u64(arg1[26]) << 4)
	x7 := (u64(arg1[25]) << 47)
	x8 := (u64(arg1[24]) << 39)
	x9 := (u64(arg1[23]) << 31)
	x10 := (u64(arg1[22]) << 23)
	x11 := (u64(arg1[21]) << 15)
	x12 := (u64(arg1[20]) << 7)
	x13 := (u64(arg1[19]) << 50)
	x14 := (u64(arg1[18]) << 42)
	x15 := (u64(arg1[17]) << 34)
	x16 := (u64(arg1[16]) << 26)
	x17 := (u64(arg1[15]) << 18)
	x18 := (u64(arg1[14]) << 10)
	x19 := (u64(arg1[13]) << 2)
	x20 := (u64(arg1[12]) << 45)
	x21 := (u64(arg1[11]) << 37)
	x22 := (u64(arg1[10]) << 29)
	x23 := (u64(arg1[9]) << 21)
	x24 := (u64(arg1[8]) << 13)
	x25 := (u64(arg1[7]) << 5)
	x26 := (u64(arg1[6]) << 48)
	x27 := (u64(arg1[5]) << 40)
	x28 := (u64(arg1[4]) << 32)
	x29 := (u64(arg1[3]) << 24)
	x30 := (u64(arg1[2]) << 16)
	x31 := (u64(arg1[1]) << 8)
	x32 := arg1[0]
	x33 := (x31 + u64(x32))
	x34 := (x30 + x33)
	x35 := (x29 + x34)
	x36 := (x28 + x35)
	x37 := (x27 + x36)
	x38 := (x26 + x37)
	x39 := (x38 & 0x7ffffffffffff)
	x40 := u8((x38 >> 51))
	x41 := (x25 + u64(x40))
	x42 := (x24 + x41)
	x43 := (x23 + x42)
	x44 := (x22 + x43)
	x45 := (x21 + x44)
	x46 := (x20 + x45)
	x47 := (x46 & 0x7ffffffffffff)
	x48 := u8((x46 >> 51))
	x49 := (x19 + u64(x48))
	x50 := (x18 + x49)
	x51 := (x17 + x50)
	x52 := (x16 + x51)
	x53 := (x15 + x52)
	x54 := (x14 + x53)
	x55 := (x13 + x54)
	x56 := (x55 & 0x7ffffffffffff)
	x57 := u8((x55 >> 51))
	x58 := (x12 + u64(x57))
	x59 := (x11 + x58)
	x60 := (x10 + x59)
	x61 := (x9 + x60)
	x62 := (x8 + x61)
	x63 := (x7 + x62)
	x64 := (x63 & 0x7ffffffffffff)
	x65 := u8((x63 >> 51))
	x66 := (x6 + u64(x65))
	x67 := (x5 + x66)
	x68 := (x4 + x67)
	x69 := (x3 + x68)
	x70 := (x2 + x69)
	x71 := (x1 + x70)
	out1[0] = x39
	out1[1] = x47
	out1[2] = x56
	out1[3] = x64
	out1[4] = x71
}

fe_relax :: proc "contextless" (out1: ^Loose_Field_Element, arg1: ^Tight_Field_Element) {
	x1 := arg1[0]
	x2 := arg1[1]
	x3 := arg1[2]
	x4 := arg1[3]
	x5 := arg1[4]
	out1[0] = x1
	out1[1] = x2
	out1[2] = x3
	out1[3] = x4
	out1[4] = x5
}

fe_carry_scmul_121666 :: proc "contextless" (
	out1: ^Tight_Field_Element,
	arg1: ^Loose_Field_Element,
) {
	x2, x1 := bits.mul_u64(0x1db42, arg1[4])
	x4, x3 := bits.mul_u64(0x1db42, arg1[3])
	x6, x5 := bits.mul_u64(0x1db42, arg1[2])
	x8, x7 := bits.mul_u64(0x1db42, arg1[1])
	x10, x9 := bits.mul_u64(0x1db42, arg1[0])
	x11 := ((x9 >> 51) | ((x10 << 13) & 0xffffffffffffffff))
	x12 := (x9 & 0x7ffffffffffff)
	x13, x14 := bits.add_u64(x11, x7, u64(0x0))
	x15 := (u64(fiat.u1(x14)) + x8)
	x16 := ((x13 >> 51) | ((x15 << 13) & 0xffffffffffffffff))
	x17 := (x13 & 0x7ffffffffffff)
	x18, x19 := bits.add_u64(x16, x5, u64(0x0))
	x20 := (u64(fiat.u1(x19)) + x6)
	x21 := ((x18 >> 51) | ((x20 << 13) & 0xffffffffffffffff))
	x22 := (x18 & 0x7ffffffffffff)
	x23, x24 := bits.add_u64(x21, x3, u64(0x0))
	x25 := (u64(fiat.u1(x24)) + x4)
	x26 := ((x23 >> 51) | ((x25 << 13) & 0xffffffffffffffff))
	x27 := (x23 & 0x7ffffffffffff)
	x28, x29 := bits.add_u64(x26, x1, u64(0x0))
	x30 := (u64(fiat.u1(x29)) + x2)
	x31 := ((x28 >> 51) | ((x30 << 13) & 0xffffffffffffffff))
	x32 := (x28 & 0x7ffffffffffff)
	x33 := (x31 * 0x13)
	x34 := (x12 + x33)
	x35 := fiat.u1((x34 >> 51))
	x36 := (x34 & 0x7ffffffffffff)
	x37 := (u64(x35) + x17)
	x38 := fiat.u1((x37 >> 51))
	x39 := (x37 & 0x7ffffffffffff)
	x40 := (u64(x38) + x22)
	out1[0] = x36
	out1[1] = x39
	out1[2] = x40
	out1[3] = x27
	out1[4] = x32
}
