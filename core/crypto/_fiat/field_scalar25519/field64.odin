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

package field_scalar25519

// The file provides arithmetic on the field Z/(2^252+27742317777372353535851937790883648493)
// using a 64-bit Montgomery form internal representation.  It is derived
// primarily from the machine generated Golang output from the fiat-crypto
// project.
//
// While the base implementation is provably correct, this implementation
// makes no such claims as the port and optimizations were done by hand.

import fiat "core:crypto/_fiat"
import "core:math/bits"

// ELL is the saturated representation of the field order, least-significant
// limb first.
ELL :: [4]u64{0x5812631a5cf5d3ed, 0x14def9dea2f79cd6, 0x0, 0x1000000000000000}

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
	_, x20 := bits.mul_u64(x11, 0xd2b51da312547e1b)
	x23, x22 := bits.mul_u64(x20, 0x1000000000000000)
	x25, x24 := bits.mul_u64(x20, 0x14def9dea2f79cd6)
	x27, x26 := bits.mul_u64(x20, 0x5812631a5cf5d3ed)
	x28, x29 := bits.add_u64(x27, x24, u64(0x0))
	x30 := (u64(fiat.u1(x29)) + x25)
	_, x32 := bits.add_u64(x11, x26, u64(0x0))
	x33, x34 := bits.add_u64(x13, x28, u64(fiat.u1(x32)))
	x35, x36 := bits.add_u64(x15, x30, u64(fiat.u1(x34)))
	x37, x38 := bits.add_u64(x17, x22, u64(fiat.u1(x36)))
	x39, x40 := bits.add_u64(x19, x23, u64(fiat.u1(x38)))
	x42, x41 := bits.mul_u64(x1, arg2[3])
	x44, x43 := bits.mul_u64(x1, arg2[2])
	x46, x45 := bits.mul_u64(x1, arg2[1])
	x48, x47 := bits.mul_u64(x1, arg2[0])
	x49, x50 := bits.add_u64(x48, x45, u64(0x0))
	x51, x52 := bits.add_u64(x46, x43, u64(fiat.u1(x50)))
	x53, x54 := bits.add_u64(x44, x41, u64(fiat.u1(x52)))
	x55 := (u64(fiat.u1(x54)) + x42)
	x56, x57 := bits.add_u64(x33, x47, u64(0x0))
	x58, x59 := bits.add_u64(x35, x49, u64(fiat.u1(x57)))
	x60, x61 := bits.add_u64(x37, x51, u64(fiat.u1(x59)))
	x62, x63 := bits.add_u64(x39, x53, u64(fiat.u1(x61)))
	x64, x65 := bits.add_u64(u64(fiat.u1(x40)), x55, u64(fiat.u1(x63)))
	_, x66 := bits.mul_u64(x56, 0xd2b51da312547e1b)
	x69, x68 := bits.mul_u64(x66, 0x1000000000000000)
	x71, x70 := bits.mul_u64(x66, 0x14def9dea2f79cd6)
	x73, x72 := bits.mul_u64(x66, 0x5812631a5cf5d3ed)
	x74, x75 := bits.add_u64(x73, x70, u64(0x0))
	x76 := (u64(fiat.u1(x75)) + x71)
	_, x78 := bits.add_u64(x56, x72, u64(0x0))
	x79, x80 := bits.add_u64(x58, x74, u64(fiat.u1(x78)))
	x81, x82 := bits.add_u64(x60, x76, u64(fiat.u1(x80)))
	x83, x84 := bits.add_u64(x62, x68, u64(fiat.u1(x82)))
	x85, x86 := bits.add_u64(x64, x69, u64(fiat.u1(x84)))
	x87 := (u64(fiat.u1(x86)) + u64(fiat.u1(x65)))
	x89, x88 := bits.mul_u64(x2, arg2[3])
	x91, x90 := bits.mul_u64(x2, arg2[2])
	x93, x92 := bits.mul_u64(x2, arg2[1])
	x95, x94 := bits.mul_u64(x2, arg2[0])
	x96, x97 := bits.add_u64(x95, x92, u64(0x0))
	x98, x99 := bits.add_u64(x93, x90, u64(fiat.u1(x97)))
	x100, x101 := bits.add_u64(x91, x88, u64(fiat.u1(x99)))
	x102 := (u64(fiat.u1(x101)) + x89)
	x103, x104 := bits.add_u64(x79, x94, u64(0x0))
	x105, x106 := bits.add_u64(x81, x96, u64(fiat.u1(x104)))
	x107, x108 := bits.add_u64(x83, x98, u64(fiat.u1(x106)))
	x109, x110 := bits.add_u64(x85, x100, u64(fiat.u1(x108)))
	x111, x112 := bits.add_u64(x87, x102, u64(fiat.u1(x110)))
	_, x113 := bits.mul_u64(x103, 0xd2b51da312547e1b)
	x116, x115 := bits.mul_u64(x113, 0x1000000000000000)
	x118, x117 := bits.mul_u64(x113, 0x14def9dea2f79cd6)
	x120, x119 := bits.mul_u64(x113, 0x5812631a5cf5d3ed)
	x121, x122 := bits.add_u64(x120, x117, u64(0x0))
	x123 := (u64(fiat.u1(x122)) + x118)
	_, x125 := bits.add_u64(x103, x119, u64(0x0))
	x126, x127 := bits.add_u64(x105, x121, u64(fiat.u1(x125)))
	x128, x129 := bits.add_u64(x107, x123, u64(fiat.u1(x127)))
	x130, x131 := bits.add_u64(x109, x115, u64(fiat.u1(x129)))
	x132, x133 := bits.add_u64(x111, x116, u64(fiat.u1(x131)))
	x134 := (u64(fiat.u1(x133)) + u64(fiat.u1(x112)))
	x136, x135 := bits.mul_u64(x3, arg2[3])
	x138, x137 := bits.mul_u64(x3, arg2[2])
	x140, x139 := bits.mul_u64(x3, arg2[1])
	x142, x141 := bits.mul_u64(x3, arg2[0])
	x143, x144 := bits.add_u64(x142, x139, u64(0x0))
	x145, x146 := bits.add_u64(x140, x137, u64(fiat.u1(x144)))
	x147, x148 := bits.add_u64(x138, x135, u64(fiat.u1(x146)))
	x149 := (u64(fiat.u1(x148)) + x136)
	x150, x151 := bits.add_u64(x126, x141, u64(0x0))
	x152, x153 := bits.add_u64(x128, x143, u64(fiat.u1(x151)))
	x154, x155 := bits.add_u64(x130, x145, u64(fiat.u1(x153)))
	x156, x157 := bits.add_u64(x132, x147, u64(fiat.u1(x155)))
	x158, x159 := bits.add_u64(x134, x149, u64(fiat.u1(x157)))
	_, x160 := bits.mul_u64(x150, 0xd2b51da312547e1b)
	x163, x162 := bits.mul_u64(x160, 0x1000000000000000)
	x165, x164 := bits.mul_u64(x160, 0x14def9dea2f79cd6)
	x167, x166 := bits.mul_u64(x160, 0x5812631a5cf5d3ed)
	x168, x169 := bits.add_u64(x167, x164, u64(0x0))
	x170 := (u64(fiat.u1(x169)) + x165)
	_, x172 := bits.add_u64(x150, x166, u64(0x0))
	x173, x174 := bits.add_u64(x152, x168, u64(fiat.u1(x172)))
	x175, x176 := bits.add_u64(x154, x170, u64(fiat.u1(x174)))
	x177, x178 := bits.add_u64(x156, x162, u64(fiat.u1(x176)))
	x179, x180 := bits.add_u64(x158, x163, u64(fiat.u1(x178)))
	x181 := (u64(fiat.u1(x180)) + u64(fiat.u1(x159)))
	x182, x183 := bits.sub_u64(x173, 0x5812631a5cf5d3ed, u64(0x0))
	x184, x185 := bits.sub_u64(x175, 0x14def9dea2f79cd6, u64(fiat.u1(x183)))
	x186, x187 := bits.sub_u64(x177, u64(0x0), u64(fiat.u1(x185)))
	x188, x189 := bits.sub_u64(x179, 0x1000000000000000, u64(fiat.u1(x187)))
	_, x191 := bits.sub_u64(x181, u64(0x0), u64(fiat.u1(x189)))
	x192 := fiat.cmovznz_u64(fiat.u1(x191), x182, x173)
	x193 := fiat.cmovznz_u64(fiat.u1(x191), x184, x175)
	x194 := fiat.cmovznz_u64(fiat.u1(x191), x186, x177)
	x195 := fiat.cmovznz_u64(fiat.u1(x191), x188, x179)
	out1[0] = x192
	out1[1] = x193
	out1[2] = x194
	out1[3] = x195
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
	_, x20 := bits.mul_u64(x11, 0xd2b51da312547e1b)
	x23, x22 := bits.mul_u64(x20, 0x1000000000000000)
	x25, x24 := bits.mul_u64(x20, 0x14def9dea2f79cd6)
	x27, x26 := bits.mul_u64(x20, 0x5812631a5cf5d3ed)
	x28, x29 := bits.add_u64(x27, x24, u64(0x0))
	x30 := (u64(fiat.u1(x29)) + x25)
	_, x32 := bits.add_u64(x11, x26, u64(0x0))
	x33, x34 := bits.add_u64(x13, x28, u64(fiat.u1(x32)))
	x35, x36 := bits.add_u64(x15, x30, u64(fiat.u1(x34)))
	x37, x38 := bits.add_u64(x17, x22, u64(fiat.u1(x36)))
	x39, x40 := bits.add_u64(x19, x23, u64(fiat.u1(x38)))
	x42, x41 := bits.mul_u64(x1, arg1[3])
	x44, x43 := bits.mul_u64(x1, arg1[2])
	x46, x45 := bits.mul_u64(x1, arg1[1])
	x48, x47 := bits.mul_u64(x1, arg1[0])
	x49, x50 := bits.add_u64(x48, x45, u64(0x0))
	x51, x52 := bits.add_u64(x46, x43, u64(fiat.u1(x50)))
	x53, x54 := bits.add_u64(x44, x41, u64(fiat.u1(x52)))
	x55 := (u64(fiat.u1(x54)) + x42)
	x56, x57 := bits.add_u64(x33, x47, u64(0x0))
	x58, x59 := bits.add_u64(x35, x49, u64(fiat.u1(x57)))
	x60, x61 := bits.add_u64(x37, x51, u64(fiat.u1(x59)))
	x62, x63 := bits.add_u64(x39, x53, u64(fiat.u1(x61)))
	x64, x65 := bits.add_u64(u64(fiat.u1(x40)), x55, u64(fiat.u1(x63)))
	_, x66 := bits.mul_u64(x56, 0xd2b51da312547e1b)
	x69, x68 := bits.mul_u64(x66, 0x1000000000000000)
	x71, x70 := bits.mul_u64(x66, 0x14def9dea2f79cd6)
	x73, x72 := bits.mul_u64(x66, 0x5812631a5cf5d3ed)
	x74, x75 := bits.add_u64(x73, x70, u64(0x0))
	x76 := (u64(fiat.u1(x75)) + x71)
	_, x78 := bits.add_u64(x56, x72, u64(0x0))
	x79, x80 := bits.add_u64(x58, x74, u64(fiat.u1(x78)))
	x81, x82 := bits.add_u64(x60, x76, u64(fiat.u1(x80)))
	x83, x84 := bits.add_u64(x62, x68, u64(fiat.u1(x82)))
	x85, x86 := bits.add_u64(x64, x69, u64(fiat.u1(x84)))
	x87 := (u64(fiat.u1(x86)) + u64(fiat.u1(x65)))
	x89, x88 := bits.mul_u64(x2, arg1[3])
	x91, x90 := bits.mul_u64(x2, arg1[2])
	x93, x92 := bits.mul_u64(x2, arg1[1])
	x95, x94 := bits.mul_u64(x2, arg1[0])
	x96, x97 := bits.add_u64(x95, x92, u64(0x0))
	x98, x99 := bits.add_u64(x93, x90, u64(fiat.u1(x97)))
	x100, x101 := bits.add_u64(x91, x88, u64(fiat.u1(x99)))
	x102 := (u64(fiat.u1(x101)) + x89)
	x103, x104 := bits.add_u64(x79, x94, u64(0x0))
	x105, x106 := bits.add_u64(x81, x96, u64(fiat.u1(x104)))
	x107, x108 := bits.add_u64(x83, x98, u64(fiat.u1(x106)))
	x109, x110 := bits.add_u64(x85, x100, u64(fiat.u1(x108)))
	x111, x112 := bits.add_u64(x87, x102, u64(fiat.u1(x110)))
	_, x113 := bits.mul_u64(x103, 0xd2b51da312547e1b)
	x116, x115 := bits.mul_u64(x113, 0x1000000000000000)
	x118, x117 := bits.mul_u64(x113, 0x14def9dea2f79cd6)
	x120, x119 := bits.mul_u64(x113, 0x5812631a5cf5d3ed)
	x121, x122 := bits.add_u64(x120, x117, u64(0x0))
	x123 := (u64(fiat.u1(x122)) + x118)
	_, x125 := bits.add_u64(x103, x119, u64(0x0))
	x126, x127 := bits.add_u64(x105, x121, u64(fiat.u1(x125)))
	x128, x129 := bits.add_u64(x107, x123, u64(fiat.u1(x127)))
	x130, x131 := bits.add_u64(x109, x115, u64(fiat.u1(x129)))
	x132, x133 := bits.add_u64(x111, x116, u64(fiat.u1(x131)))
	x134 := (u64(fiat.u1(x133)) + u64(fiat.u1(x112)))
	x136, x135 := bits.mul_u64(x3, arg1[3])
	x138, x137 := bits.mul_u64(x3, arg1[2])
	x140, x139 := bits.mul_u64(x3, arg1[1])
	x142, x141 := bits.mul_u64(x3, arg1[0])
	x143, x144 := bits.add_u64(x142, x139, u64(0x0))
	x145, x146 := bits.add_u64(x140, x137, u64(fiat.u1(x144)))
	x147, x148 := bits.add_u64(x138, x135, u64(fiat.u1(x146)))
	x149 := (u64(fiat.u1(x148)) + x136)
	x150, x151 := bits.add_u64(x126, x141, u64(0x0))
	x152, x153 := bits.add_u64(x128, x143, u64(fiat.u1(x151)))
	x154, x155 := bits.add_u64(x130, x145, u64(fiat.u1(x153)))
	x156, x157 := bits.add_u64(x132, x147, u64(fiat.u1(x155)))
	x158, x159 := bits.add_u64(x134, x149, u64(fiat.u1(x157)))
	_, x160 := bits.mul_u64(x150, 0xd2b51da312547e1b)
	x163, x162 := bits.mul_u64(x160, 0x1000000000000000)
	x165, x164 := bits.mul_u64(x160, 0x14def9dea2f79cd6)
	x167, x166 := bits.mul_u64(x160, 0x5812631a5cf5d3ed)
	x168, x169 := bits.add_u64(x167, x164, u64(0x0))
	x170 := (u64(fiat.u1(x169)) + x165)
	_, x172 := bits.add_u64(x150, x166, u64(0x0))
	x173, x174 := bits.add_u64(x152, x168, u64(fiat.u1(x172)))
	x175, x176 := bits.add_u64(x154, x170, u64(fiat.u1(x174)))
	x177, x178 := bits.add_u64(x156, x162, u64(fiat.u1(x176)))
	x179, x180 := bits.add_u64(x158, x163, u64(fiat.u1(x178)))
	x181 := (u64(fiat.u1(x180)) + u64(fiat.u1(x159)))
	x182, x183 := bits.sub_u64(x173, 0x5812631a5cf5d3ed, u64(0x0))
	x184, x185 := bits.sub_u64(x175, 0x14def9dea2f79cd6, u64(fiat.u1(x183)))
	x186, x187 := bits.sub_u64(x177, u64(0x0), u64(fiat.u1(x185)))
	x188, x189 := bits.sub_u64(x179, 0x1000000000000000, u64(fiat.u1(x187)))
	_, x191 := bits.sub_u64(x181, u64(0x0), u64(fiat.u1(x189)))
	x192 := fiat.cmovznz_u64(fiat.u1(x191), x182, x173)
	x193 := fiat.cmovznz_u64(fiat.u1(x191), x184, x175)
	x194 := fiat.cmovznz_u64(fiat.u1(x191), x186, x177)
	x195 := fiat.cmovznz_u64(fiat.u1(x191), x188, x179)
	out1[0] = x192
	out1[1] = x193
	out1[2] = x194
	out1[3] = x195
}

fe_add :: proc "contextless" (out1, arg1, arg2: ^Montgomery_Domain_Field_Element) {
	x1, x2 := bits.add_u64(arg1[0], arg2[0], u64(0x0))
	x3, x4 := bits.add_u64(arg1[1], arg2[1], u64(fiat.u1(x2)))
	x5, x6 := bits.add_u64(arg1[2], arg2[2], u64(fiat.u1(x4)))
	x7, x8 := bits.add_u64(arg1[3], arg2[3], u64(fiat.u1(x6)))
	x9, x10 := bits.sub_u64(x1, 0x5812631a5cf5d3ed, u64(0x0))
	x11, x12 := bits.sub_u64(x3, 0x14def9dea2f79cd6, u64(fiat.u1(x10)))
	x13, x14 := bits.sub_u64(x5, u64(0x0), u64(fiat.u1(x12)))
	x15, x16 := bits.sub_u64(x7, 0x1000000000000000, u64(fiat.u1(x14)))
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
	x10, x11 := bits.add_u64(x1, (x9 & 0x5812631a5cf5d3ed), u64(0x0))
	x12, x13 := bits.add_u64(x3, (x9 & 0x14def9dea2f79cd6), u64(fiat.u1(x11)))
	x14, x15 := bits.add_u64(x5, u64(0x0), u64(fiat.u1(x13)))
	x16, _ := bits.add_u64(x7, (x9 & 0x1000000000000000), u64(fiat.u1(x15)))
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
	x10, x11 := bits.add_u64(x1, (x9 & 0x5812631a5cf5d3ed), u64(0x0))
	x12, x13 := bits.add_u64(x3, (x9 & 0x14def9dea2f79cd6), u64(fiat.u1(x11)))
	x14, x15 := bits.add_u64(x5, u64(0x0), u64(fiat.u1(x13)))
	x16, _ := bits.add_u64(x7, (x9 & 0x1000000000000000), u64(fiat.u1(x15)))
	out1[0] = x10
	out1[1] = x12
	out1[2] = x14
	out1[3] = x16
}

fe_one :: proc "contextless" (out1: ^Montgomery_Domain_Field_Element) {
	out1[0] = 0xd6ec31748d98951d
	out1[1] = 0xc6ef5bf4737dcf70
	out1[2] = 0xfffffffffffffffe
	out1[3] = 0xfffffffffffffff
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
	_, x2 := bits.mul_u64(x1, 0xd2b51da312547e1b)
	x5, x4 := bits.mul_u64(x2, 0x1000000000000000)
	x7, x6 := bits.mul_u64(x2, 0x14def9dea2f79cd6)
	x9, x8 := bits.mul_u64(x2, 0x5812631a5cf5d3ed)
	x10, x11 := bits.add_u64(x9, x6, u64(0x0))
	_, x13 := bits.add_u64(x1, x8, u64(0x0))
	x14, x15 := bits.add_u64(u64(0x0), x10, u64(fiat.u1(x13)))
	x16, x17 := bits.add_u64(x14, arg1[1], u64(0x0))
	_, x18 := bits.mul_u64(x16, 0xd2b51da312547e1b)
	x21, x20 := bits.mul_u64(x18, 0x1000000000000000)
	x23, x22 := bits.mul_u64(x18, 0x14def9dea2f79cd6)
	x25, x24 := bits.mul_u64(x18, 0x5812631a5cf5d3ed)
	x26, x27 := bits.add_u64(x25, x22, u64(0x0))
	_, x29 := bits.add_u64(x16, x24, u64(0x0))
	x30, x31 := bits.add_u64(
		(u64(fiat.u1(x17)) + (u64(fiat.u1(x15)) + (u64(fiat.u1(x11)) + x7))),
		x26,
		u64(fiat.u1(x29)),
	)
	x32, x33 := bits.add_u64(x4, (u64(fiat.u1(x27)) + x23), u64(fiat.u1(x31)))
	x34, x35 := bits.add_u64(x5, x20, u64(fiat.u1(x33)))
	x36, x37 := bits.add_u64(x30, arg1[2], u64(0x0))
	x38, x39 := bits.add_u64(x32, u64(0x0), u64(fiat.u1(x37)))
	x40, x41 := bits.add_u64(x34, u64(0x0), u64(fiat.u1(x39)))
	_, x42 := bits.mul_u64(x36, 0xd2b51da312547e1b)
	x45, x44 := bits.mul_u64(x42, 0x1000000000000000)
	x47, x46 := bits.mul_u64(x42, 0x14def9dea2f79cd6)
	x49, x48 := bits.mul_u64(x42, 0x5812631a5cf5d3ed)
	x50, x51 := bits.add_u64(x49, x46, u64(0x0))
	_, x53 := bits.add_u64(x36, x48, u64(0x0))
	x54, x55 := bits.add_u64(x38, x50, u64(fiat.u1(x53)))
	x56, x57 := bits.add_u64(x40, (u64(fiat.u1(x51)) + x47), u64(fiat.u1(x55)))
	x58, x59 := bits.add_u64(
		(u64(fiat.u1(x41)) + (u64(fiat.u1(x35)) + x21)),
		x44,
		u64(fiat.u1(x57)),
	)
	x60, x61 := bits.add_u64(x54, arg1[3], u64(0x0))
	x62, x63 := bits.add_u64(x56, u64(0x0), u64(fiat.u1(x61)))
	x64, x65 := bits.add_u64(x58, u64(0x0), u64(fiat.u1(x63)))
	_, x66 := bits.mul_u64(x60, 0xd2b51da312547e1b)
	x69, x68 := bits.mul_u64(x66, 0x1000000000000000)
	x71, x70 := bits.mul_u64(x66, 0x14def9dea2f79cd6)
	x73, x72 := bits.mul_u64(x66, 0x5812631a5cf5d3ed)
	x74, x75 := bits.add_u64(x73, x70, u64(0x0))
	_, x77 := bits.add_u64(x60, x72, u64(0x0))
	x78, x79 := bits.add_u64(x62, x74, u64(fiat.u1(x77)))
	x80, x81 := bits.add_u64(x64, (u64(fiat.u1(x75)) + x71), u64(fiat.u1(x79)))
	x82, x83 := bits.add_u64(
		(u64(fiat.u1(x65)) + (u64(fiat.u1(x59)) + x45)),
		x68,
		u64(fiat.u1(x81)),
	)
	x84 := (u64(fiat.u1(x83)) + x69)
	x85, x86 := bits.sub_u64(x78, 0x5812631a5cf5d3ed, u64(0x0))
	x87, x88 := bits.sub_u64(x80, 0x14def9dea2f79cd6, u64(fiat.u1(x86)))
	x89, x90 := bits.sub_u64(x82, u64(0x0), u64(fiat.u1(x88)))
	x91, x92 := bits.sub_u64(x84, 0x1000000000000000, u64(fiat.u1(x90)))
	_, x94 := bits.sub_u64(u64(0x0), u64(0x0), u64(fiat.u1(x92)))
	x95 := fiat.cmovznz_u64(fiat.u1(x94), x85, x78)
	x96 := fiat.cmovznz_u64(fiat.u1(x94), x87, x80)
	x97 := fiat.cmovznz_u64(fiat.u1(x94), x89, x82)
	x98 := fiat.cmovznz_u64(fiat.u1(x94), x91, x84)
	out1[0] = x95
	out1[1] = x96
	out1[2] = x97
	out1[3] = x98
}

fe_to_montgomery :: proc "contextless" (
	out1: ^Montgomery_Domain_Field_Element,
	arg1: ^Non_Montgomery_Domain_Field_Element,
) {
	x1 := arg1[1]
	x2 := arg1[2]
	x3 := arg1[3]
	x4 := arg1[0]
	x6, x5 := bits.mul_u64(x4, 0x399411b7c309a3d)
	x8, x7 := bits.mul_u64(x4, 0xceec73d217f5be65)
	x10, x9 := bits.mul_u64(x4, 0xd00e1ba768859347)
	x12, x11 := bits.mul_u64(x4, 0xa40611e3449c0f01)
	x13, x14 := bits.add_u64(x12, x9, u64(0x0))
	x15, x16 := bits.add_u64(x10, x7, u64(fiat.u1(x14)))
	x17, x18 := bits.add_u64(x8, x5, u64(fiat.u1(x16)))
	_, x19 := bits.mul_u64(x11, 0xd2b51da312547e1b)
	x22, x21 := bits.mul_u64(x19, 0x1000000000000000)
	x24, x23 := bits.mul_u64(x19, 0x14def9dea2f79cd6)
	x26, x25 := bits.mul_u64(x19, 0x5812631a5cf5d3ed)
	x27, x28 := bits.add_u64(x26, x23, u64(0x0))
	_, x30 := bits.add_u64(x11, x25, u64(0x0))
	x31, x32 := bits.add_u64(x13, x27, u64(fiat.u1(x30)))
	x33, x34 := bits.add_u64(x15, (u64(fiat.u1(x28)) + x24), u64(fiat.u1(x32)))
	x35, x36 := bits.add_u64(x17, x21, u64(fiat.u1(x34)))
	x38, x37 := bits.mul_u64(x1, 0x399411b7c309a3d)
	x40, x39 := bits.mul_u64(x1, 0xceec73d217f5be65)
	x42, x41 := bits.mul_u64(x1, 0xd00e1ba768859347)
	x44, x43 := bits.mul_u64(x1, 0xa40611e3449c0f01)
	x45, x46 := bits.add_u64(x44, x41, u64(0x0))
	x47, x48 := bits.add_u64(x42, x39, u64(fiat.u1(x46)))
	x49, x50 := bits.add_u64(x40, x37, u64(fiat.u1(x48)))
	x51, x52 := bits.add_u64(x31, x43, u64(0x0))
	x53, x54 := bits.add_u64(x33, x45, u64(fiat.u1(x52)))
	x55, x56 := bits.add_u64(x35, x47, u64(fiat.u1(x54)))
	x57, x58 := bits.add_u64(
		((u64(fiat.u1(x36)) + (u64(fiat.u1(x18)) + x6)) + x22),
		x49,
		u64(fiat.u1(x56)),
	)
	_, x59 := bits.mul_u64(x51, 0xd2b51da312547e1b)
	x62, x61 := bits.mul_u64(x59, 0x1000000000000000)
	x64, x63 := bits.mul_u64(x59, 0x14def9dea2f79cd6)
	x66, x65 := bits.mul_u64(x59, 0x5812631a5cf5d3ed)
	x67, x68 := bits.add_u64(x66, x63, u64(0x0))
	_, x70 := bits.add_u64(x51, x65, u64(0x0))
	x71, x72 := bits.add_u64(x53, x67, u64(fiat.u1(x70)))
	x73, x74 := bits.add_u64(x55, (u64(fiat.u1(x68)) + x64), u64(fiat.u1(x72)))
	x75, x76 := bits.add_u64(x57, x61, u64(fiat.u1(x74)))
	x78, x77 := bits.mul_u64(x2, 0x399411b7c309a3d)
	x80, x79 := bits.mul_u64(x2, 0xceec73d217f5be65)
	x82, x81 := bits.mul_u64(x2, 0xd00e1ba768859347)
	x84, x83 := bits.mul_u64(x2, 0xa40611e3449c0f01)
	x85, x86 := bits.add_u64(x84, x81, u64(0x0))
	x87, x88 := bits.add_u64(x82, x79, u64(fiat.u1(x86)))
	x89, x90 := bits.add_u64(x80, x77, u64(fiat.u1(x88)))
	x91, x92 := bits.add_u64(x71, x83, u64(0x0))
	x93, x94 := bits.add_u64(x73, x85, u64(fiat.u1(x92)))
	x95, x96 := bits.add_u64(x75, x87, u64(fiat.u1(x94)))
	x97, x98 := bits.add_u64(
		((u64(fiat.u1(x76)) + (u64(fiat.u1(x58)) + (u64(fiat.u1(x50)) + x38))) + x62),
		x89,
		u64(fiat.u1(x96)),
	)
	_, x99 := bits.mul_u64(x91, 0xd2b51da312547e1b)
	x102, x101 := bits.mul_u64(x99, 0x1000000000000000)
	x104, x103 := bits.mul_u64(x99, 0x14def9dea2f79cd6)
	x106, x105 := bits.mul_u64(x99, 0x5812631a5cf5d3ed)
	x107, x108 := bits.add_u64(x106, x103, u64(0x0))
	_, x110 := bits.add_u64(x91, x105, u64(0x0))
	x111, x112 := bits.add_u64(x93, x107, u64(fiat.u1(x110)))
	x113, x114 := bits.add_u64(x95, (u64(fiat.u1(x108)) + x104), u64(fiat.u1(x112)))
	x115, x116 := bits.add_u64(x97, x101, u64(fiat.u1(x114)))
	x118, x117 := bits.mul_u64(x3, 0x399411b7c309a3d)
	x120, x119 := bits.mul_u64(x3, 0xceec73d217f5be65)
	x122, x121 := bits.mul_u64(x3, 0xd00e1ba768859347)
	x124, x123 := bits.mul_u64(x3, 0xa40611e3449c0f01)
	x125, x126 := bits.add_u64(x124, x121, u64(0x0))
	x127, x128 := bits.add_u64(x122, x119, u64(fiat.u1(x126)))
	x129, x130 := bits.add_u64(x120, x117, u64(fiat.u1(x128)))
	x131, x132 := bits.add_u64(x111, x123, u64(0x0))
	x133, x134 := bits.add_u64(x113, x125, u64(fiat.u1(x132)))
	x135, x136 := bits.add_u64(x115, x127, u64(fiat.u1(x134)))
	x137, x138 := bits.add_u64(
		((u64(fiat.u1(x116)) + (u64(fiat.u1(x98)) + (u64(fiat.u1(x90)) + x78))) + x102),
		x129,
		u64(fiat.u1(x136)),
	)
	_, x139 := bits.mul_u64(x131, 0xd2b51da312547e1b)
	x142, x141 := bits.mul_u64(x139, 0x1000000000000000)
	x144, x143 := bits.mul_u64(x139, 0x14def9dea2f79cd6)
	x146, x145 := bits.mul_u64(x139, 0x5812631a5cf5d3ed)
	x147, x148 := bits.add_u64(x146, x143, u64(0x0))
	_, x150 := bits.add_u64(x131, x145, u64(0x0))
	x151, x152 := bits.add_u64(x133, x147, u64(fiat.u1(x150)))
	x153, x154 := bits.add_u64(x135, (u64(fiat.u1(x148)) + x144), u64(fiat.u1(x152)))
	x155, x156 := bits.add_u64(x137, x141, u64(fiat.u1(x154)))
	x157 := ((u64(fiat.u1(x156)) + (u64(fiat.u1(x138)) + (u64(fiat.u1(x130)) + x118))) + x142)
	x158, x159 := bits.sub_u64(x151, 0x5812631a5cf5d3ed, u64(0x0))
	x160, x161 := bits.sub_u64(x153, 0x14def9dea2f79cd6, u64(fiat.u1(x159)))
	x162, x163 := bits.sub_u64(x155, u64(0x0), u64(fiat.u1(x161)))
	x164, x165 := bits.sub_u64(x157, 0x1000000000000000, u64(fiat.u1(x163)))
	_, x167 := bits.sub_u64(u64(0x0), u64(0x0), u64(fiat.u1(x165)))
	x168 := fiat.cmovznz_u64(fiat.u1(x167), x158, x151)
	x169 := fiat.cmovznz_u64(fiat.u1(x167), x160, x153)
	x170 := fiat.cmovznz_u64(fiat.u1(x167), x162, x155)
	x171 := fiat.cmovznz_u64(fiat.u1(x167), x164, x157)
	out1[0] = x168
	out1[1] = x169
	out1[2] = x170
	out1[3] = x171
}
