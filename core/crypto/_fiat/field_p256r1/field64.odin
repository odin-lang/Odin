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

package field_p256r1

// The file provides arithmetic on the field Z/(2^256 - 2^224 + 2^192 + 2^96 - 1)
// using a 64-bit Montgomery form internal representation.  It is derived
// primarily from the machine generated Golang output from the fiat-crypto
// project.
//
// While the base implementation is provably correct, this implementation
// makes no such claims as the port and optimizations were done by hand.
//
// WARNING: While big-endian is the common representation used for this
// curve, the fiat output uses least-significant-limb first.

import fiat "core:crypto/_fiat"
import "core:math/bits"

// ELL is the saturated representation of the field order, least-significant
// limb first.
ELL :: [4]u64{0xffffffffffffffff, 0xffffffff, 0x0, 0xffffffff00000001}

Montgomery_Domain_Field_Element :: distinct [4]u64
Non_Montgomery_Domain_Field_Element :: distinct [4]u64

fe_mul :: proc "contextless" (out1, arg1, arg2: ^Montgomery_Domain_Field_Element) {
	x1 := arg1[1]
	x2 := arg1[2]
	x3 := arg1[3]
	x4 := arg1[0]
	x6, x5 := bits.mul_u64(x4, arg2[3])
	x8, x7 := bits.mul_u64(x4, arg2[2])
	x10, x9 := bits.mul_u64(x4, arg2[1])
	x12, x11 := bits.mul_u64(x4, arg2[0])
	x13, x14 := bits.add_u64(x12, x9, u64(0x0))
	x15, x16 := bits.add_u64(x10, x7, u64(fiat.u1(x14)))
	x17, x18 := bits.add_u64(x8, x5, u64(fiat.u1(x16)))
	x19 := (u64(fiat.u1(x18)) + x6)
	x21, x20 := bits.mul_u64(x11, 0xffffffff00000001)
	x23, x22 := bits.mul_u64(x11, 0xffffffff)
	x25, x24 := bits.mul_u64(x11, 0xffffffffffffffff)
	x26, x27 := bits.add_u64(x25, x22, u64(0x0))
	x28 := (u64(fiat.u1(x27)) + x23)
	_, x30 := bits.add_u64(x11, x24, u64(0x0))
	x31, x32 := bits.add_u64(x13, x26, u64(fiat.u1(x30)))
	x33, x34 := bits.add_u64(x15, x28, u64(fiat.u1(x32)))
	x35, x36 := bits.add_u64(x17, x20, u64(fiat.u1(x34)))
	x37, x38 := bits.add_u64(x19, x21, u64(fiat.u1(x36)))
	x40, x39 := bits.mul_u64(x1, arg2[3])
	x42, x41 := bits.mul_u64(x1, arg2[2])
	x44, x43 := bits.mul_u64(x1, arg2[1])
	x46, x45 := bits.mul_u64(x1, arg2[0])
	x47, x48 := bits.add_u64(x46, x43, u64(0x0))
	x49, x50 := bits.add_u64(x44, x41, u64(fiat.u1(x48)))
	x51, x52 := bits.add_u64(x42, x39, u64(fiat.u1(x50)))
	x53 := (u64(fiat.u1(x52)) + x40)
	x54, x55 := bits.add_u64(x31, x45, u64(0x0))
	x56, x57 := bits.add_u64(x33, x47, u64(fiat.u1(x55)))
	x58, x59 := bits.add_u64(x35, x49, u64(fiat.u1(x57)))
	x60, x61 := bits.add_u64(x37, x51, u64(fiat.u1(x59)))
	x62, x63 := bits.add_u64(u64(fiat.u1(x38)), x53, u64(fiat.u1(x61)))
	x65, x64 := bits.mul_u64(x54, 0xffffffff00000001)
	x67, x66 := bits.mul_u64(x54, 0xffffffff)
	x69, x68 := bits.mul_u64(x54, 0xffffffffffffffff)
	x70, x71 := bits.add_u64(x69, x66, u64(0x0))
	x72 := (u64(fiat.u1(x71)) + x67)
	_, x74 := bits.add_u64(x54, x68, u64(0x0))
	x75, x76 := bits.add_u64(x56, x70, u64(fiat.u1(x74)))
	x77, x78 := bits.add_u64(x58, x72, u64(fiat.u1(x76)))
	x79, x80 := bits.add_u64(x60, x64, u64(fiat.u1(x78)))
	x81, x82 := bits.add_u64(x62, x65, u64(fiat.u1(x80)))
	x83 := (u64(fiat.u1(x82)) + u64(fiat.u1(x63)))
	x85, x84 := bits.mul_u64(x2, arg2[3])
	x87, x86 := bits.mul_u64(x2, arg2[2])
	x89, x88 := bits.mul_u64(x2, arg2[1])
	x91, x90 := bits.mul_u64(x2, arg2[0])
	x92, x93 := bits.add_u64(x91, x88, u64(0x0))
	x94, x95 := bits.add_u64(x89, x86, u64(fiat.u1(x93)))
	x96, x97 := bits.add_u64(x87, x84, u64(fiat.u1(x95)))
	x98 := (u64(fiat.u1(x97)) + x85)
	x99, x100 := bits.add_u64(x75, x90, u64(0x0))
	x101, x102 := bits.add_u64(x77, x92, u64(fiat.u1(x100)))
	x103, x104 := bits.add_u64(x79, x94, u64(fiat.u1(x102)))
	x105, x106 := bits.add_u64(x81, x96, u64(fiat.u1(x104)))
	x107, x108 := bits.add_u64(x83, x98, u64(fiat.u1(x106)))
	x110, x109 := bits.mul_u64(x99, 0xffffffff00000001)
	x112, x111 := bits.mul_u64(x99, 0xffffffff)
	x114, x113 := bits.mul_u64(x99, 0xffffffffffffffff)
	x115, x116 := bits.add_u64(x114, x111, u64(0x0))
	x117 := (u64(fiat.u1(x116)) + x112)
	_, x119 := bits.add_u64(x99, x113, u64(0x0))
	x120, x121 := bits.add_u64(x101, x115, u64(fiat.u1(x119)))
	x122, x123 := bits.add_u64(x103, x117, u64(fiat.u1(x121)))
	x124, x125 := bits.add_u64(x105, x109, u64(fiat.u1(x123)))
	x126, x127 := bits.add_u64(x107, x110, u64(fiat.u1(x125)))
	x128 := (u64(fiat.u1(x127)) + u64(fiat.u1(x108)))
	x130, x129 := bits.mul_u64(x3, arg2[3])
	x132, x131 := bits.mul_u64(x3, arg2[2])
	x134, x133 := bits.mul_u64(x3, arg2[1])
	x136, x135 := bits.mul_u64(x3, arg2[0])
	x137, x138 := bits.add_u64(x136, x133, u64(0x0))
	x139, x140 := bits.add_u64(x134, x131, u64(fiat.u1(x138)))
	x141, x142 := bits.add_u64(x132, x129, u64(fiat.u1(x140)))
	x143 := (u64(fiat.u1(x142)) + x130)
	x144, x145 := bits.add_u64(x120, x135, u64(0x0))
	x146, x147 := bits.add_u64(x122, x137, u64(fiat.u1(x145)))
	x148, x149 := bits.add_u64(x124, x139, u64(fiat.u1(x147)))
	x150, x151 := bits.add_u64(x126, x141, u64(fiat.u1(x149)))
	x152, x153 := bits.add_u64(x128, x143, u64(fiat.u1(x151)))
	x155, x154 := bits.mul_u64(x144, 0xffffffff00000001)
	x157, x156 := bits.mul_u64(x144, 0xffffffff)
	x159, x158 := bits.mul_u64(x144, 0xffffffffffffffff)
	x160, x161 := bits.add_u64(x159, x156, u64(0x0))
	x162 := (u64(fiat.u1(x161)) + x157)
	_, x164 := bits.add_u64(x144, x158, u64(0x0))
	x165, x166 := bits.add_u64(x146, x160, u64(fiat.u1(x164)))
	x167, x168 := bits.add_u64(x148, x162, u64(fiat.u1(x166)))
	x169, x170 := bits.add_u64(x150, x154, u64(fiat.u1(x168)))
	x171, x172 := bits.add_u64(x152, x155, u64(fiat.u1(x170)))
	x173 := (u64(fiat.u1(x172)) + u64(fiat.u1(x153)))
	x174, x175 := bits.sub_u64(x165, 0xffffffffffffffff, u64(0x0))
	x176, x177 := bits.sub_u64(x167, 0xffffffff, u64(fiat.u1(x175)))
	x178, x179 := bits.sub_u64(x169, u64(0x0), u64(fiat.u1(x177)))
	x180, x181 := bits.sub_u64(x171, 0xffffffff00000001, u64(fiat.u1(x179)))
	_, x183 := bits.sub_u64(x173, u64(0x0), u64(fiat.u1(x181)))
	x184 := fiat.cmovznz_u64(fiat.u1(x183), x174, x165)
	x185 := fiat.cmovznz_u64(fiat.u1(x183), x176, x167)
	x186 := fiat.cmovznz_u64(fiat.u1(x183), x178, x169)
	x187 := fiat.cmovznz_u64(fiat.u1(x183), x180, x171)
	out1[0] = x184
	out1[1] = x185
	out1[2] = x186
	out1[3] = x187
}

fe_square :: proc "contextless" (out1, arg1: ^Montgomery_Domain_Field_Element) {
	x1 := arg1[1]
	x2 := arg1[2]
	x3 := arg1[3]
	x4 := arg1[0]
	x6, x5 := bits.mul_u64(x4, arg1[3])
	x8, x7 := bits.mul_u64(x4, arg1[2])
	x10, x9 := bits.mul_u64(x4, arg1[1])
	x12, x11 := bits.mul_u64(x4, arg1[0])
	x13, x14 := bits.add_u64(x12, x9, u64(0x0))
	x15, x16 := bits.add_u64(x10, x7, u64(fiat.u1(x14)))
	x17, x18 := bits.add_u64(x8, x5, u64(fiat.u1(x16)))
	x19 := (u64(fiat.u1(x18)) + x6)
	x21, x20 := bits.mul_u64(x11, 0xffffffff00000001)
	x23, x22 := bits.mul_u64(x11, 0xffffffff)
	x25, x24 := bits.mul_u64(x11, 0xffffffffffffffff)
	x26, x27 := bits.add_u64(x25, x22, u64(0x0))
	x28 := (u64(fiat.u1(x27)) + x23)
	_, x30 := bits.add_u64(x11, x24, u64(0x0))
	x31, x32 := bits.add_u64(x13, x26, u64(fiat.u1(x30)))
	x33, x34 := bits.add_u64(x15, x28, u64(fiat.u1(x32)))
	x35, x36 := bits.add_u64(x17, x20, u64(fiat.u1(x34)))
	x37, x38 := bits.add_u64(x19, x21, u64(fiat.u1(x36)))
	x40, x39 := bits.mul_u64(x1, arg1[3])
	x42, x41 := bits.mul_u64(x1, arg1[2])
	x44, x43 := bits.mul_u64(x1, arg1[1])
	x46, x45 := bits.mul_u64(x1, arg1[0])
	x47, x48 := bits.add_u64(x46, x43, u64(0x0))
	x49, x50 := bits.add_u64(x44, x41, u64(fiat.u1(x48)))
	x51, x52 := bits.add_u64(x42, x39, u64(fiat.u1(x50)))
	x53 := (u64(fiat.u1(x52)) + x40)
	x54, x55 := bits.add_u64(x31, x45, u64(0x0))
	x56, x57 := bits.add_u64(x33, x47, u64(fiat.u1(x55)))
	x58, x59 := bits.add_u64(x35, x49, u64(fiat.u1(x57)))
	x60, x61 := bits.add_u64(x37, x51, u64(fiat.u1(x59)))
	x62, x63 := bits.add_u64(u64(fiat.u1(x38)), x53, u64(fiat.u1(x61)))
	x65, x64 := bits.mul_u64(x54, 0xffffffff00000001)
	x67, x66 := bits.mul_u64(x54, 0xffffffff)
	x69, x68 := bits.mul_u64(x54, 0xffffffffffffffff)
	x70, x71 := bits.add_u64(x69, x66, u64(0x0))
	x72 := (u64(fiat.u1(x71)) + x67)
	_, x74 := bits.add_u64(x54, x68, u64(0x0))
	x75, x76 := bits.add_u64(x56, x70, u64(fiat.u1(x74)))
	x77, x78 := bits.add_u64(x58, x72, u64(fiat.u1(x76)))
	x79, x80 := bits.add_u64(x60, x64, u64(fiat.u1(x78)))
	x81, x82 := bits.add_u64(x62, x65, u64(fiat.u1(x80)))
	x83 := (u64(fiat.u1(x82)) + u64(fiat.u1(x63)))
	x85, x84 := bits.mul_u64(x2, arg1[3])
	x87, x86 := bits.mul_u64(x2, arg1[2])
	x89, x88 := bits.mul_u64(x2, arg1[1])
	x91, x90 := bits.mul_u64(x2, arg1[0])
	x92, x93 := bits.add_u64(x91, x88, u64(0x0))
	x94, x95 := bits.add_u64(x89, x86, u64(fiat.u1(x93)))
	x96, x97 := bits.add_u64(x87, x84, u64(fiat.u1(x95)))
	x98 := (u64(fiat.u1(x97)) + x85)
	x99, x100 := bits.add_u64(x75, x90, u64(0x0))
	x101, x102 := bits.add_u64(x77, x92, u64(fiat.u1(x100)))
	x103, x104 := bits.add_u64(x79, x94, u64(fiat.u1(x102)))
	x105, x106 := bits.add_u64(x81, x96, u64(fiat.u1(x104)))
	x107, x108 := bits.add_u64(x83, x98, u64(fiat.u1(x106)))
	x110, x109 := bits.mul_u64(x99, 0xffffffff00000001)
	x112, x111 := bits.mul_u64(x99, 0xffffffff)
	x114, x113 := bits.mul_u64(x99, 0xffffffffffffffff)
	x115, x116 := bits.add_u64(x114, x111, u64(0x0))
	x117 := (u64(fiat.u1(x116)) + x112)
	_, x119 := bits.add_u64(x99, x113, u64(0x0))
	x120, x121 := bits.add_u64(x101, x115, u64(fiat.u1(x119)))
	x122, x123 := bits.add_u64(x103, x117, u64(fiat.u1(x121)))
	x124, x125 := bits.add_u64(x105, x109, u64(fiat.u1(x123)))
	x126, x127 := bits.add_u64(x107, x110, u64(fiat.u1(x125)))
	x128 := (u64(fiat.u1(x127)) + u64(fiat.u1(x108)))
	x130, x129 := bits.mul_u64(x3, arg1[3])
	x132, x131 := bits.mul_u64(x3, arg1[2])
	x134, x133 := bits.mul_u64(x3, arg1[1])
	x136, x135 := bits.mul_u64(x3, arg1[0])
	x137, x138 := bits.add_u64(x136, x133, u64(0x0))
	x139, x140 := bits.add_u64(x134, x131, u64(fiat.u1(x138)))
	x141, x142 := bits.add_u64(x132, x129, u64(fiat.u1(x140)))
	x143 := (u64(fiat.u1(x142)) + x130)
	x144, x145 := bits.add_u64(x120, x135, u64(0x0))
	x146, x147 := bits.add_u64(x122, x137, u64(fiat.u1(x145)))
	x148, x149 := bits.add_u64(x124, x139, u64(fiat.u1(x147)))
	x150, x151 := bits.add_u64(x126, x141, u64(fiat.u1(x149)))
	x152, x153 := bits.add_u64(x128, x143, u64(fiat.u1(x151)))
	x155, x154 := bits.mul_u64(x144, 0xffffffff00000001)
	x157, x156 := bits.mul_u64(x144, 0xffffffff)
	x159, x158 := bits.mul_u64(x144, 0xffffffffffffffff)
	x160, x161 := bits.add_u64(x159, x156, u64(0x0))
	x162 := (u64(fiat.u1(x161)) + x157)
	_, x164 := bits.add_u64(x144, x158, u64(0x0))
	x165, x166 := bits.add_u64(x146, x160, u64(fiat.u1(x164)))
	x167, x168 := bits.add_u64(x148, x162, u64(fiat.u1(x166)))
	x169, x170 := bits.add_u64(x150, x154, u64(fiat.u1(x168)))
	x171, x172 := bits.add_u64(x152, x155, u64(fiat.u1(x170)))
	x173 := (u64(fiat.u1(x172)) + u64(fiat.u1(x153)))
	x174, x175 := bits.sub_u64(x165, 0xffffffffffffffff, u64(0x0))
	x176, x177 := bits.sub_u64(x167, 0xffffffff, u64(fiat.u1(x175)))
	x178, x179 := bits.sub_u64(x169, u64(0x0), u64(fiat.u1(x177)))
	x180, x181 := bits.sub_u64(x171, 0xffffffff00000001, u64(fiat.u1(x179)))
	_, x183 := bits.sub_u64(x173, u64(0x0), u64(fiat.u1(x181)))
	x184 := fiat.cmovznz_u64(fiat.u1(x183), x174, x165)
	x185 := fiat.cmovznz_u64(fiat.u1(x183), x176, x167)
	x186 := fiat.cmovznz_u64(fiat.u1(x183), x178, x169)
	x187 := fiat.cmovznz_u64(fiat.u1(x183), x180, x171)
	out1[0] = x184
	out1[1] = x185
	out1[2] = x186
	out1[3] = x187
}

fe_add :: proc "contextless" (out1, arg1, arg2: ^Montgomery_Domain_Field_Element) {
	x1, x2 := bits.add_u64(arg1[0], arg2[0], u64(0x0))
	x3, x4 := bits.add_u64(arg1[1], arg2[1], u64(fiat.u1(x2)))
	x5, x6 := bits.add_u64(arg1[2], arg2[2], u64(fiat.u1(x4)))
	x7, x8 := bits.add_u64(arg1[3], arg2[3], u64(fiat.u1(x6)))
	x9, x10 := bits.sub_u64(x1, 0xffffffffffffffff, u64(0x0))
	x11, x12 := bits.sub_u64(x3, 0xffffffff, u64(fiat.u1(x10)))
	x13, x14 := bits.sub_u64(x5, u64(0x0), u64(fiat.u1(x12)))
	x15, x16 := bits.sub_u64(x7, 0xffffffff00000001, u64(fiat.u1(x14)))
	_, x18 := bits.sub_u64(u64(fiat.u1(x8)), u64(0x0), u64(fiat.u1(x16)))
	x19 := fiat.cmovznz_u64(fiat.u1(x18), x9, x1)
	x20 := fiat.cmovznz_u64(fiat.u1(x18), x11, x3)
	x21 := fiat.cmovznz_u64(fiat.u1(x18), x13, x5)
	x22 := fiat.cmovznz_u64(fiat.u1(x18), x15, x7)
	out1[0] = x19
	out1[1] = x20
	out1[2] = x21
	out1[3] = x22
}

fe_sub :: proc "contextless" (out1, arg1, arg2: ^Montgomery_Domain_Field_Element) {
	x1, x2 := bits.sub_u64(arg1[0], arg2[0], u64(0x0))
	x3, x4 := bits.sub_u64(arg1[1], arg2[1], u64(fiat.u1(x2)))
	x5, x6 := bits.sub_u64(arg1[2], arg2[2], u64(fiat.u1(x4)))
	x7, x8 := bits.sub_u64(arg1[3], arg2[3], u64(fiat.u1(x6)))
	x9 := fiat.cmovznz_u64(fiat.u1(x8), u64(0x0), 0xffffffffffffffff)
	x10, x11 := bits.add_u64(x1, x9, u64(0x0))
	x12, x13 := bits.add_u64(x3, (x9 & 0xffffffff), u64(fiat.u1(x11)))
	x14, x15 := bits.add_u64(x5, u64(0x0), u64(fiat.u1(x13)))
	x16, _ := bits.add_u64(x7, (x9 & 0xffffffff00000001), u64(fiat.u1(x15)))
	out1[0] = x10
	out1[1] = x12
	out1[2] = x14
	out1[3] = x16
}

fe_opp :: proc "contextless" (out1, arg1: ^Montgomery_Domain_Field_Element) {
	x1, x2 := bits.sub_u64(u64(0x0), arg1[0], u64(0x0))
	x3, x4 := bits.sub_u64(u64(0x0), arg1[1], u64(fiat.u1(x2)))
	x5, x6 := bits.sub_u64(u64(0x0), arg1[2], u64(fiat.u1(x4)))
	x7, x8 := bits.sub_u64(u64(0x0), arg1[3], u64(fiat.u1(x6)))
	x9 := fiat.cmovznz_u64(fiat.u1(x8), u64(0x0), 0xffffffffffffffff)
	x10, x11 := bits.add_u64(x1, x9, u64(0x0))
	x12, x13 := bits.add_u64(x3, (x9 & 0xffffffff), u64(fiat.u1(x11)))
	x14, x15 := bits.add_u64(x5, u64(0x0), u64(fiat.u1(x13)))
	x16, _ := bits.add_u64(x7, (x9 & 0xffffffff00000001), u64(fiat.u1(x15)))
	out1[0] = x10
	out1[1] = x12
	out1[2] = x14
	out1[3] = x16
}

fe_one :: proc "contextless" (out1: ^Montgomery_Domain_Field_Element) {
	out1[0] = 0x1
	out1[1] = 0xffffffff00000000
	out1[2] = 0xffffffffffffffff
	out1[3] = 0xfffffffe
}

fe_non_zero :: proc "contextless" (arg1: ^Montgomery_Domain_Field_Element) -> u64 {
	return arg1[0] | (arg1[1] | (arg1[2] | arg1[3]))
}

@(optimization_mode = "none")
fe_cond_assign :: #force_no_inline proc "contextless" (
	out1, arg1: ^Montgomery_Domain_Field_Element,
	arg2: int,
) {
	x1 := fiat.cmovznz_u64(fiat.u1(arg2), out1[0], arg1[0])
	x2 := fiat.cmovznz_u64(fiat.u1(arg2), out1[1], arg1[1])
	x3 := fiat.cmovznz_u64(fiat.u1(arg2), out1[2], arg1[2])
	x4 := fiat.cmovznz_u64(fiat.u1(arg2), out1[3], arg1[3])
	out1[0] = x1
	out1[1] = x2
	out1[2] = x3
	out1[3] = x4
}

fe_from_montgomery :: proc "contextless" (
	out1: ^Non_Montgomery_Domain_Field_Element,
	arg1: ^Montgomery_Domain_Field_Element,
) {
	x1 := arg1[0]
	x3, x2 := bits.mul_u64(x1, 0xffffffff00000001)
	x5, x4 := bits.mul_u64(x1, 0xffffffff)
	x7, x6 := bits.mul_u64(x1, 0xffffffffffffffff)
	x8, x9 := bits.add_u64(x7, x4, u64(0x0))
	_, x11 := bits.add_u64(x1, x6, u64(0x0))
	x12, x13 := bits.add_u64(u64(0x0), x8, u64(fiat.u1(x11)))
	x14, x15 := bits.add_u64(x12, arg1[1], u64(0x0))
	x17, x16 := bits.mul_u64(x14, 0xffffffff00000001)
	x19, x18 := bits.mul_u64(x14, 0xffffffff)
	x21, x20 := bits.mul_u64(x14, 0xffffffffffffffff)
	x22, x23 := bits.add_u64(x21, x18, u64(0x0))
	_, x25 := bits.add_u64(x14, x20, u64(0x0))
	x26, x27 := bits.add_u64((u64(fiat.u1(x15)) + (u64(fiat.u1(x13)) + (u64(fiat.u1(x9)) + x5))), x22, u64(fiat.u1(x25)))
	x28, x29 := bits.add_u64(x2, (u64(fiat.u1(x23)) + x19), u64(fiat.u1(x27)))
	x30, x31 := bits.add_u64(x3, x16, u64(fiat.u1(x29)))
	x32, x33 := bits.add_u64(x26, arg1[2], u64(0x0))
	x34, x35 := bits.add_u64(x28, u64(0x0), u64(fiat.u1(x33)))
	x36, x37 := bits.add_u64(x30, u64(0x0), u64(fiat.u1(x35)))
	x39, x38 := bits.mul_u64(x32, 0xffffffff00000001)
	x41, x40 := bits.mul_u64(x32, 0xffffffff)
	x43, x42 := bits.mul_u64(x32, 0xffffffffffffffff)
	x44, x45 := bits.add_u64(x43, x40, u64(0x0))
	_, x47 := bits.add_u64(x32, x42, u64(0x0))
	x48, x49 := bits.add_u64(x34, x44, u64(fiat.u1(x47)))
	x50, x51 := bits.add_u64(x36, (u64(fiat.u1(x45)) + x41), u64(fiat.u1(x49)))
	x52, x53 := bits.add_u64((u64(fiat.u1(x37)) + (u64(fiat.u1(x31)) + x17)), x38, u64(fiat.u1(x51)))
	x54, x55 := bits.add_u64(x48, arg1[3], u64(0x0))
	x56, x57 := bits.add_u64(x50, u64(0x0), u64(fiat.u1(x55)))
	x58, x59 := bits.add_u64(x52, u64(0x0), u64(fiat.u1(x57)))
	x61, x60 := bits.mul_u64(x54, 0xffffffff00000001)
	x63, x62 := bits.mul_u64(x54, 0xffffffff)
	x65, x64 := bits.mul_u64(x54, 0xffffffffffffffff)
	x66, x67 := bits.add_u64(x65, x62, u64(0x0))
	_, x69 := bits.add_u64(x54, x64, u64(0x0))
	x70, x71 := bits.add_u64(x56, x66, u64(fiat.u1(x69)))
	x72, x73 := bits.add_u64(x58, (u64(fiat.u1(x67)) + x63), u64(fiat.u1(x71)))
	x74, x75 := bits.add_u64((u64(fiat.u1(x59)) + (u64(fiat.u1(x53)) + x39)), x60, u64(fiat.u1(x73)))
	x76 := (u64(fiat.u1(x75)) + x61)
	x77, x78 := bits.sub_u64(x70, 0xffffffffffffffff, u64(0x0))
	x79, x80 := bits.sub_u64(x72, 0xffffffff, u64(fiat.u1(x78)))
	x81, x82 := bits.sub_u64(x74, u64(0x0), u64(fiat.u1(x80)))
	x83, x84 := bits.sub_u64(x76, 0xffffffff00000001, u64(fiat.u1(x82)))
	_, x86 := bits.sub_u64(u64(0x0), u64(0x0), u64(fiat.u1(x84)))
	x87 := fiat.cmovznz_u64(fiat.u1(x86), x77, x70)
	x88 := fiat.cmovznz_u64(fiat.u1(x86), x79, x72)
	x89 := fiat.cmovznz_u64(fiat.u1(x86), x81, x74)
	x90 := fiat.cmovznz_u64(fiat.u1(x86), x83, x76)
	out1[0] = x87
	out1[1] = x88
	out1[2] = x89
	out1[3] = x90
}

fe_to_montgomery :: proc "contextless" (
	out1: ^Montgomery_Domain_Field_Element,
	arg1: ^Non_Montgomery_Domain_Field_Element,
) {
	x1 := arg1[1]
	x2 := arg1[2]
	x3 := arg1[3]
	x4 := arg1[0]
	x6, x5 := bits.mul_u64(x4, 0x4fffffffd)
	x8, x7 := bits.mul_u64(x4, 0xfffffffffffffffe)
	x10, x9 := bits.mul_u64(x4, 0xfffffffbffffffff)
	x12, x11 := bits.mul_u64(x4, 0x3)
	x13, x14 := bits.add_u64(x12, x9, u64(0x0))
	x15, x16 := bits.add_u64(x10, x7, u64(fiat.u1(x14)))
	x17, x18 := bits.add_u64(x8, x5, u64(fiat.u1(x16)))
	x20, x19 := bits.mul_u64(x11, 0xffffffff00000001)
	x22, x21 := bits.mul_u64(x11, 0xffffffff)
	x24, x23 := bits.mul_u64(x11, 0xffffffffffffffff)
	x25, x26 := bits.add_u64(x24, x21, u64(0x0))
	_, x28 := bits.add_u64(x11, x23, u64(0x0))
	x29, x30 := bits.add_u64(x13, x25, u64(fiat.u1(x28)))
	x31, x32 := bits.add_u64(x15, (u64(fiat.u1(x26)) + x22), u64(fiat.u1(x30)))
	x33, x34 := bits.add_u64(x17, x19, u64(fiat.u1(x32)))
	x35, x36 := bits.add_u64((u64(fiat.u1(x18)) + x6), x20, u64(fiat.u1(x34)))
	x38, x37 := bits.mul_u64(x1, 0x4fffffffd)
	x40, x39 := bits.mul_u64(x1, 0xfffffffffffffffe)
	x42, x41 := bits.mul_u64(x1, 0xfffffffbffffffff)
	x44, x43 := bits.mul_u64(x1, 0x3)
	x45, x46 := bits.add_u64(x44, x41, u64(0x0))
	x47, x48 := bits.add_u64(x42, x39, u64(fiat.u1(x46)))
	x49, x50 := bits.add_u64(x40, x37, u64(fiat.u1(x48)))
	x51, x52 := bits.add_u64(x29, x43, u64(0x0))
	x53, x54 := bits.add_u64(x31, x45, u64(fiat.u1(x52)))
	x55, x56 := bits.add_u64(x33, x47, u64(fiat.u1(x54)))
	x57, x58 := bits.add_u64(x35, x49, u64(fiat.u1(x56)))
	x60, x59 := bits.mul_u64(x51, 0xffffffff00000001)
	x62, x61 := bits.mul_u64(x51, 0xffffffff)
	x64, x63 := bits.mul_u64(x51, 0xffffffffffffffff)
	x65, x66 := bits.add_u64(x64, x61, u64(0x0))
	_, x68 := bits.add_u64(x51, x63, u64(0x0))
	x69, x70 := bits.add_u64(x53, x65, u64(fiat.u1(x68)))
	x71, x72 := bits.add_u64(x55, (u64(fiat.u1(x66)) + x62), u64(fiat.u1(x70)))
	x73, x74 := bits.add_u64(x57, x59, u64(fiat.u1(x72)))
	x75, x76 := bits.add_u64(((u64(fiat.u1(x58)) + u64(fiat.u1(x36))) + (u64(fiat.u1(x50)) + x38)), x60, u64(fiat.u1(x74)))
	x78, x77 := bits.mul_u64(x2, 0x4fffffffd)
	x80, x79 := bits.mul_u64(x2, 0xfffffffffffffffe)
	x82, x81 := bits.mul_u64(x2, 0xfffffffbffffffff)
	x84, x83 := bits.mul_u64(x2, 0x3)
	x85, x86 := bits.add_u64(x84, x81, u64(0x0))
	x87, x88 := bits.add_u64(x82, x79, u64(fiat.u1(x86)))
	x89, x90 := bits.add_u64(x80, x77, u64(fiat.u1(x88)))
	x91, x92 := bits.add_u64(x69, x83, u64(0x0))
	x93, x94 := bits.add_u64(x71, x85, u64(fiat.u1(x92)))
	x95, x96 := bits.add_u64(x73, x87, u64(fiat.u1(x94)))
	x97, x98 := bits.add_u64(x75, x89, u64(fiat.u1(x96)))
	x100, x99 := bits.mul_u64(x91, 0xffffffff00000001)
	x102, x101 := bits.mul_u64(x91, 0xffffffff)
	x104, x103 := bits.mul_u64(x91, 0xffffffffffffffff)
	x105, x106 := bits.add_u64(x104, x101, u64(0x0))
	_, x108 := bits.add_u64(x91, x103, u64(0x0))
	x109, x110 := bits.add_u64(x93, x105, u64(fiat.u1(x108)))
	x111, x112 := bits.add_u64(x95, (u64(fiat.u1(x106)) + x102), u64(fiat.u1(x110)))
	x113, x114 := bits.add_u64(x97, x99, u64(fiat.u1(x112)))
	x115, x116 := bits.add_u64(((u64(fiat.u1(x98)) + u64(fiat.u1(x76))) + (u64(fiat.u1(x90)) + x78)), x100, u64(fiat.u1(x114)))
	x118, x117 := bits.mul_u64(x3, 0x4fffffffd)
	x120, x119 := bits.mul_u64(x3, 0xfffffffffffffffe)
	x122, x121 := bits.mul_u64(x3, 0xfffffffbffffffff)
	x124, x123 := bits.mul_u64(x3, 0x3)
	x125, x126 := bits.add_u64(x124, x121, u64(0x0))
	x127, x128 := bits.add_u64(x122, x119, u64(fiat.u1(x126)))
	x129, x130 := bits.add_u64(x120, x117, u64(fiat.u1(x128)))
	x131, x132 := bits.add_u64(x109, x123, u64(0x0))
	x133, x134 := bits.add_u64(x111, x125, u64(fiat.u1(x132)))
	x135, x136 := bits.add_u64(x113, x127, u64(fiat.u1(x134)))
	x137, x138 := bits.add_u64(x115, x129, u64(fiat.u1(x136)))
	x140, x139 := bits.mul_u64(x131, 0xffffffff00000001)
	x142, x141 := bits.mul_u64(x131, 0xffffffff)
	x144, x143 := bits.mul_u64(x131, 0xffffffffffffffff)
	x145, x146 := bits.add_u64(x144, x141, u64(0x0))
	_, x148 := bits.add_u64(x131, x143, u64(0x0))
	x149, x150 := bits.add_u64(x133, x145, u64(fiat.u1(x148)))
	x151, x152 := bits.add_u64(x135, (u64(fiat.u1(x146)) + x142), u64(fiat.u1(x150)))
	x153, x154 := bits.add_u64(x137, x139, u64(fiat.u1(x152)))
	x155, x156 := bits.add_u64(((u64(fiat.u1(x138)) + u64(fiat.u1(x116))) + (u64(fiat.u1(x130)) + x118)), x140, u64(fiat.u1(x154)))
	x157, x158 := bits.sub_u64(x149, 0xffffffffffffffff, u64(0x0))
	x159, x160 := bits.sub_u64(x151, 0xffffffff, u64(fiat.u1(x158)))
	x161, x162 := bits.sub_u64(x153, u64(0x0), u64(fiat.u1(x160)))
	x163, x164 := bits.sub_u64(x155, 0xffffffff00000001, u64(fiat.u1(x162)))
	_, x166 := bits.sub_u64(u64(fiat.u1(x156)), u64(0x0), u64(fiat.u1(x164)))
	x167 := fiat.cmovznz_u64(fiat.u1(x166), x157, x149)
	x168 := fiat.cmovznz_u64(fiat.u1(x166), x159, x151)
	x169 := fiat.cmovznz_u64(fiat.u1(x166), x161, x153)
	x170 := fiat.cmovznz_u64(fiat.u1(x166), x163, x155)
	out1[0] = x167
	out1[1] = x168
	out1[2] = x169
	out1[3] = x170
}
