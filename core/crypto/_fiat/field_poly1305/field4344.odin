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

package field_poly1305

// This file provides arithmetic on the field Z/(2^130 - 5) using
// unsaturated 64-bit integer arithmetic.  It is derived primarily
// from the machine generate Golang output from the fiat-crypto project.
//
// While the base implementation is provably correct, this implementation
// makes no such claims as the port and optimizations were done by hand.
// At some point, it may be worth adding support to fiat-crypto for
// generating Odin output.

import fiat "core:crypto/_fiat"
import "core:math/bits"

Loose_Field_Element :: distinct [3]u64
Tight_Field_Element :: distinct [3]u64

_addcarryx_u44 :: #force_inline proc "contextless" (
	arg1: fiat.u1,
	arg2, arg3: u64,
) -> (
	out1: u64,
	out2: fiat.u1,
) {
	x1 := ((u64(arg1) + arg2) + arg3)
	x2 := (x1 & 0xfffffffffff)
	x3 := fiat.u1((x1 >> 44))
	out1 = x2
	out2 = x3
	return
}

_subborrowx_u44 :: #force_inline proc "contextless" (
	arg1: fiat.u1,
	arg2, arg3: u64,
) -> (
	out1: u64,
	out2: fiat.u1,
) {
	x1 := ((i64(arg2) - i64(arg1)) - i64(arg3))
	x2 := fiat.i1((x1 >> 44))
	x3 := (u64(x1) & 0xfffffffffff)
	out1 = x3
	out2 = (0x0 - fiat.u1(x2))
	return
}

_addcarryx_u43 :: #force_inline proc "contextless" (
	arg1: fiat.u1,
	arg2, arg3: u64,
) -> (
	out1: u64,
	out2: fiat.u1,
) {
	x1 := ((u64(arg1) + arg2) + arg3)
	x2 := (x1 & 0x7ffffffffff)
	x3 := fiat.u1((x1 >> 43))
	out1 = x2
	out2 = x3
	return
}

_subborrowx_u43 :: #force_inline proc "contextless" (
	arg1: fiat.u1,
	arg2, arg3: u64,
) -> (
	out1: u64,
	out2: fiat.u1,
) {
	x1 := ((i64(arg2) - i64(arg1)) - i64(arg3))
	x2 := fiat.i1((x1 >> 43))
	x3 := (u64(x1) & 0x7ffffffffff)
	out1 = x3
	out2 = (0x0 - fiat.u1(x2))
	return
}

fe_carry_mul :: proc "contextless" (out1: ^Tight_Field_Element, arg1, arg2: ^Loose_Field_Element) {
	x2, x1 := bits.mul_u64(arg1[2], (arg2[2] * 0x5))
	x4, x3 := bits.mul_u64(arg1[2], (arg2[1] * 0xa))
	x6, x5 := bits.mul_u64(arg1[1], (arg2[2] * 0xa))
	x8, x7 := bits.mul_u64(arg1[2], arg2[0])
	x10, x9 := bits.mul_u64(arg1[1], (arg2[1] * 0x2))
	x12, x11 := bits.mul_u64(arg1[1], arg2[0])
	x14, x13 := bits.mul_u64(arg1[0], arg2[2])
	x16, x15 := bits.mul_u64(arg1[0], arg2[1])
	x18, x17 := bits.mul_u64(arg1[0], arg2[0])
	x19, x20 := bits.add_u64(x5, x3, u64(0x0))
	x21, _ := bits.add_u64(x6, x4, u64(fiat.u1(x20)))
	x23, x24 := bits.add_u64(x17, x19, u64(0x0))
	x25, _ := bits.add_u64(x18, x21, u64(fiat.u1(x24)))
	x27 := ((x23 >> 44) | ((x25 << 20) & 0xffffffffffffffff))
	x28 := (x23 & 0xfffffffffff)
	x29, x30 := bits.add_u64(x9, x7, u64(0x0))
	x31, _ := bits.add_u64(x10, x8, u64(fiat.u1(x30)))
	x33, x34 := bits.add_u64(x13, x29, u64(0x0))
	x35, _ := bits.add_u64(x14, x31, u64(fiat.u1(x34)))
	x37, x38 := bits.add_u64(x11, x1, u64(0x0))
	x39, _ := bits.add_u64(x12, x2, u64(fiat.u1(x38)))
	x41, x42 := bits.add_u64(x15, x37, u64(0x0))
	x43, _ := bits.add_u64(x16, x39, u64(fiat.u1(x42)))
	x45, x46 := bits.add_u64(x27, x41, u64(0x0))
	x47 := (u64(fiat.u1(x46)) + x43)
	x48 := ((x45 >> 43) | ((x47 << 21) & 0xffffffffffffffff))
	x49 := (x45 & 0x7ffffffffff)
	x50, x51 := bits.add_u64(x48, x33, u64(0x0))
	x52 := (u64(fiat.u1(x51)) + x35)
	x53 := ((x50 >> 43) | ((x52 << 21) & 0xffffffffffffffff))
	x54 := (x50 & 0x7ffffffffff)
	x55 := (x53 * 0x5)
	x56 := (x28 + x55)
	x57 := (x56 >> 44)
	x58 := (x56 & 0xfffffffffff)
	x59 := (x57 + x49)
	x60 := fiat.u1((x59 >> 43))
	x61 := (x59 & 0x7ffffffffff)
	x62 := (u64(x60) + x54)
	out1[0] = x58
	out1[1] = x61
	out1[2] = x62
}

fe_carry_square :: proc "contextless" (out1: ^Tight_Field_Element, arg1: ^Loose_Field_Element) {
	x1 := (arg1[2] * 0x5)
	x2 := (x1 * 0x2)
	x3 := (arg1[2] * 0x2)
	x4 := (arg1[1] * 0x2)
	x6, x5 := bits.mul_u64(arg1[2], x1)
	x8, x7 := bits.mul_u64(arg1[1], (x2 * 0x2))
	x10, x9 := bits.mul_u64(arg1[1], (arg1[1] * 0x2))
	x12, x11 := bits.mul_u64(arg1[0], x3)
	x14, x13 := bits.mul_u64(arg1[0], x4)
	x16, x15 := bits.mul_u64(arg1[0], arg1[0])
	x17, x18 := bits.add_u64(x15, x7, u64(0x0))
	x19, _ := bits.add_u64(x16, x8, u64(fiat.u1(x18)))
	x21 := ((x17 >> 44) | ((x19 << 20) & 0xffffffffffffffff))
	x22 := (x17 & 0xfffffffffff)
	x23, x24 := bits.add_u64(x11, x9, u64(0x0))
	x25, _ := bits.add_u64(x12, x10, u64(fiat.u1(x24)))
	x27, x28 := bits.add_u64(x13, x5, u64(0x0))
	x29, _ := bits.add_u64(x14, x6, u64(fiat.u1(x28)))
	x31, x32 := bits.add_u64(x21, x27, u64(0x0))
	x33 := (u64(fiat.u1(x32)) + x29)
	x34 := ((x31 >> 43) | ((x33 << 21) & 0xffffffffffffffff))
	x35 := (x31 & 0x7ffffffffff)
	x36, x37 := bits.add_u64(x34, x23, u64(0x0))
	x38 := (u64(fiat.u1(x37)) + x25)
	x39 := ((x36 >> 43) | ((x38 << 21) & 0xffffffffffffffff))
	x40 := (x36 & 0x7ffffffffff)
	x41 := (x39 * 0x5)
	x42 := (x22 + x41)
	x43 := (x42 >> 44)
	x44 := (x42 & 0xfffffffffff)
	x45 := (x43 + x35)
	x46 := fiat.u1((x45 >> 43))
	x47 := (x45 & 0x7ffffffffff)
	x48 := (u64(x46) + x40)
	out1[0] = x44
	out1[1] = x47
	out1[2] = x48
}

fe_carry :: proc "contextless" (out1: ^Tight_Field_Element, arg1: ^Loose_Field_Element) {
	x1 := arg1[0]
	x2 := ((x1 >> 44) + arg1[1])
	x3 := ((x2 >> 43) + arg1[2])
	x4 := ((x1 & 0xfffffffffff) + ((x3 >> 43) * 0x5))
	x5 := (u64(fiat.u1((x4 >> 44))) + (x2 & 0x7ffffffffff))
	x6 := (x4 & 0xfffffffffff)
	x7 := (x5 & 0x7ffffffffff)
	x8 := (u64(fiat.u1((x5 >> 43))) + (x3 & 0x7ffffffffff))
	out1[0] = x6
	out1[1] = x7
	out1[2] = x8
}

fe_add :: proc "contextless" (out1: ^Loose_Field_Element, arg1, arg2: ^Tight_Field_Element) {
	x1 := (arg1[0] + arg2[0])
	x2 := (arg1[1] + arg2[1])
	x3 := (arg1[2] + arg2[2])
	out1[0] = x1
	out1[1] = x2
	out1[2] = x3
}

fe_sub :: proc "contextless" (out1: ^Loose_Field_Element, arg1, arg2: ^Tight_Field_Element) {
	x1 := ((0x1ffffffffff6 + arg1[0]) - arg2[0])
	x2 := ((0xffffffffffe + arg1[1]) - arg2[1])
	x3 := ((0xffffffffffe + arg1[2]) - arg2[2])
	out1[0] = x1
	out1[1] = x2
	out1[2] = x3
}

fe_opp :: proc "contextless" (out1: ^Loose_Field_Element, arg1: ^Tight_Field_Element) {
	x1 := (0x1ffffffffff6 - arg1[0])
	x2 := (0xffffffffffe - arg1[1])
	x3 := (0xffffffffffe - arg1[2])
	out1[0] = x1
	out1[1] = x2
	out1[2] = x3
}

@(optimization_mode = "none")
fe_cond_assign :: #force_no_inline proc "contextless" (
	out1, arg1: ^Tight_Field_Element,
	arg2: bool,
) {
	x1 := fiat.cmovznz_u64(fiat.u1(arg2), out1[0], arg1[0])
	x2 := fiat.cmovznz_u64(fiat.u1(arg2), out1[1], arg1[1])
	x3 := fiat.cmovznz_u64(fiat.u1(arg2), out1[2], arg1[2])
	out1[0] = x1
	out1[1] = x2
	out1[2] = x3
}

fe_to_bytes :: proc "contextless" (out1: ^[32]byte, arg1: ^Tight_Field_Element) {
	x1, x2 := _subborrowx_u44(0x0, arg1[0], 0xffffffffffb)
	x3, x4 := _subborrowx_u43(x2, arg1[1], 0x7ffffffffff)
	x5, x6 := _subborrowx_u43(x4, arg1[2], 0x7ffffffffff)
	x7 := fiat.cmovznz_u64(x6, u64(0x0), 0xffffffffffffffff)
	x8, x9 := _addcarryx_u44(0x0, x1, (x7 & 0xffffffffffb))
	x10, x11 := _addcarryx_u43(x9, x3, (x7 & 0x7ffffffffff))
	x12, _ := _addcarryx_u43(x11, x5, (x7 & 0x7ffffffffff))
	x14 := (x12 << 7)
	x15 := (x10 << 4)
	x16 := (u8(x8) & 0xff)
	x17 := (x8 >> 8)
	x18 := (u8(x17) & 0xff)
	x19 := (x17 >> 8)
	x20 := (u8(x19) & 0xff)
	x21 := (x19 >> 8)
	x22 := (u8(x21) & 0xff)
	x23 := (x21 >> 8)
	x24 := (u8(x23) & 0xff)
	x25 := u8((x23 >> 8))
	x26 := (x15 + u64(x25))
	x27 := (u8(x26) & 0xff)
	x28 := (x26 >> 8)
	x29 := (u8(x28) & 0xff)
	x30 := (x28 >> 8)
	x31 := (u8(x30) & 0xff)
	x32 := (x30 >> 8)
	x33 := (u8(x32) & 0xff)
	x34 := (x32 >> 8)
	x35 := (u8(x34) & 0xff)
	x36 := u8((x34 >> 8))
	x37 := (x14 + u64(x36))
	x38 := (u8(x37) & 0xff)
	x39 := (x37 >> 8)
	x40 := (u8(x39) & 0xff)
	x41 := (x39 >> 8)
	x42 := (u8(x41) & 0xff)
	x43 := (x41 >> 8)
	x44 := (u8(x43) & 0xff)
	x45 := (x43 >> 8)
	x46 := (u8(x45) & 0xff)
	x47 := (x45 >> 8)
	x48 := (u8(x47) & 0xff)
	x49 := u8((x47 >> 8))
	out1[0] = x16
	out1[1] = x18
	out1[2] = x20
	out1[3] = x22
	out1[4] = x24
	out1[5] = x27
	out1[6] = x29
	out1[7] = x31
	out1[8] = x33
	out1[9] = x35
	out1[10] = x38
	out1[11] = x40
	out1[12] = x42
	out1[13] = x44
	out1[14] = x46
	out1[15] = x48
	out1[16] = x49
}

_fe_from_bytes :: proc "contextless" (out1: ^Tight_Field_Element, arg1: ^[32]byte) {
	x1 := (u64(arg1[16]) << 41)
	x2 := (u64(arg1[15]) << 33)
	x3 := (u64(arg1[14]) << 25)
	x4 := (u64(arg1[13]) << 17)
	x5 := (u64(arg1[12]) << 9)
	x6 := (u64(arg1[11]) * u64(0x2))
	x7 := (u64(arg1[10]) << 36)
	x8 := (u64(arg1[9]) << 28)
	x9 := (u64(arg1[8]) << 20)
	x10 := (u64(arg1[7]) << 12)
	x11 := (u64(arg1[6]) << 4)
	x12 := (u64(arg1[5]) << 40)
	x13 := (u64(arg1[4]) << 32)
	x14 := (u64(arg1[3]) << 24)
	x15 := (u64(arg1[2]) << 16)
	x16 := (u64(arg1[1]) << 8)
	x17 := arg1[0]
	x18 := (x16 + u64(x17))
	x19 := (x15 + x18)
	x20 := (x14 + x19)
	x21 := (x13 + x20)
	x22 := (x12 + x21)
	x23 := (x22 & 0xfffffffffff)
	x24 := u8((x22 >> 44))
	x25 := (x11 + u64(x24))
	x26 := (x10 + x25)
	x27 := (x9 + x26)
	x28 := (x8 + x27)
	x29 := (x7 + x28)
	x30 := (x29 & 0x7ffffffffff)
	x31 := fiat.u1((x29 >> 43))
	x32 := (x6 + u64(x31))
	x33 := (x5 + x32)
	x34 := (x4 + x33)
	x35 := (x3 + x34)
	x36 := (x2 + x35)
	x37 := (x1 + x36)
	out1[0] = x23
	out1[1] = x30
	out1[2] = x37
}

fe_relax :: proc "contextless" (out1: ^Loose_Field_Element, arg1: ^Tight_Field_Element) {
	x1 := arg1[0]
	x2 := arg1[1]
	x3 := arg1[2]
	out1[0] = x1
	out1[1] = x2
	out1[2] = x3
}
