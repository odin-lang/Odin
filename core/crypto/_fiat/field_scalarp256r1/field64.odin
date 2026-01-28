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

package field_scalarp256r1

// The file provides arithmetic on the field Z/(2^256 - 2^224 + 2^192 -
// 89188191075325690597107910205041859247) using a 64-bit Montgomery form
// internal representation.  It is derived primarily from the machine
// generated Golang output from the fiat-crypto project.
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
ELL :: [4]u64{0xf3b9cac2fc632551, 0xbce6faada7179e84, 0xffffffffffffffff, 0xffffffff00000000}

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
	_, x20 := bits.mul_u64(x11, 0xccd1c8aaee00bc4f)
	x23, x22 := bits.mul_u64(x20, 0xffffffff00000000)
	x25, x24 := bits.mul_u64(x20, 0xffffffffffffffff)
	x27, x26 := bits.mul_u64(x20, 0xbce6faada7179e84)
	x29, x28 := bits.mul_u64(x20, 0xf3b9cac2fc632551)
	x30, x31 := bits.add_u64(x29, x26, u64(0x0))
	x32, x33 := bits.add_u64(x27, x24, u64(fiat.u1(x31)))
	x34, x35 := bits.add_u64(x25, x22, u64(fiat.u1(x33)))
	x36 := (u64(fiat.u1(x35)) + x23)
	_, x38 := bits.add_u64(x11, x28, u64(0x0))
	x39, x40 := bits.add_u64(x13, x30, u64(fiat.u1(x38)))
	x41, x42 := bits.add_u64(x15, x32, u64(fiat.u1(x40)))
	x43, x44 := bits.add_u64(x17, x34, u64(fiat.u1(x42)))
	x45, x46 := bits.add_u64(x19, x36, u64(fiat.u1(x44)))
	x48, x47 := bits.mul_u64(x1, arg2[3])
	x50, x49 := bits.mul_u64(x1, arg2[2])
	x52, x51 := bits.mul_u64(x1, arg2[1])
	x54, x53 := bits.mul_u64(x1, arg2[0])
	x55, x56 := bits.add_u64(x54, x51, u64(0x0))
	x57, x58 := bits.add_u64(x52, x49, u64(fiat.u1(x56)))
	x59, x60 := bits.add_u64(x50, x47, u64(fiat.u1(x58)))
	x61 := (u64(fiat.u1(x60)) + x48)
	x62, x63 := bits.add_u64(x39, x53, u64(0x0))
	x64, x65 := bits.add_u64(x41, x55, u64(fiat.u1(x63)))
	x66, x67 := bits.add_u64(x43, x57, u64(fiat.u1(x65)))
	x68, x69 := bits.add_u64(x45, x59, u64(fiat.u1(x67)))
	x70, x71 := bits.add_u64(u64(fiat.u1(x46)), x61, u64(fiat.u1(x69)))
	_, x72 := bits.mul_u64(x62, 0xccd1c8aaee00bc4f)
	x75, x74 := bits.mul_u64(x72, 0xffffffff00000000)
	x77, x76 := bits.mul_u64(x72, 0xffffffffffffffff)
	x79, x78 := bits.mul_u64(x72, 0xbce6faada7179e84)
	x81, x80 := bits.mul_u64(x72, 0xf3b9cac2fc632551)
	x82, x83 := bits.add_u64(x81, x78, u64(0x0))
	x84, x85 := bits.add_u64(x79, x76, u64(fiat.u1(x83)))
	x86, x87 := bits.add_u64(x77, x74, u64(fiat.u1(x85)))
	x88 := (u64(fiat.u1(x87)) + x75)
	_, x90 := bits.add_u64(x62, x80, u64(0x0))
	x91, x92 := bits.add_u64(x64, x82, u64(fiat.u1(x90)))
	x93, x94 := bits.add_u64(x66, x84, u64(fiat.u1(x92)))
	x95, x96 := bits.add_u64(x68, x86, u64(fiat.u1(x94)))
	x97, x98 := bits.add_u64(x70, x88, u64(fiat.u1(x96)))
	x99 := (u64(fiat.u1(x98)) + u64(fiat.u1(x71)))
	x101, x100 := bits.mul_u64(x2, arg2[3])
	x103, x102 := bits.mul_u64(x2, arg2[2])
	x105, x104 := bits.mul_u64(x2, arg2[1])
	x107, x106 := bits.mul_u64(x2, arg2[0])
	x108, x109 := bits.add_u64(x107, x104, u64(0x0))
	x110, x111 := bits.add_u64(x105, x102, u64(fiat.u1(x109)))
	x112, x113 := bits.add_u64(x103, x100, u64(fiat.u1(x111)))
	x114 := (u64(fiat.u1(x113)) + x101)
	x115, x116 := bits.add_u64(x91, x106, u64(0x0))
	x117, x118 := bits.add_u64(x93, x108, u64(fiat.u1(x116)))
	x119, x120 := bits.add_u64(x95, x110, u64(fiat.u1(x118)))
	x121, x122 := bits.add_u64(x97, x112, u64(fiat.u1(x120)))
	x123, x124 := bits.add_u64(x99, x114, u64(fiat.u1(x122)))
	_, x125 := bits.mul_u64(x115, 0xccd1c8aaee00bc4f)
	x128, x127 := bits.mul_u64(x125, 0xffffffff00000000)
	x130, x129 := bits.mul_u64(x125, 0xffffffffffffffff)
	x132, x131 := bits.mul_u64(x125, 0xbce6faada7179e84)
	x134, x133 := bits.mul_u64(x125, 0xf3b9cac2fc632551)
	x135, x136 := bits.add_u64(x134, x131, u64(0x0))
	x137, x138 := bits.add_u64(x132, x129, u64(fiat.u1(x136)))
	x139, x140 := bits.add_u64(x130, x127, u64(fiat.u1(x138)))
	x141 := (u64(fiat.u1(x140)) + x128)
	_, x143 := bits.add_u64(x115, x133, u64(0x0))
	x144, x145 := bits.add_u64(x117, x135, u64(fiat.u1(x143)))
	x146, x147 := bits.add_u64(x119, x137, u64(fiat.u1(x145)))
	x148, x149 := bits.add_u64(x121, x139, u64(fiat.u1(x147)))
	x150, x151 := bits.add_u64(x123, x141, u64(fiat.u1(x149)))
	x152 := (u64(fiat.u1(x151)) + u64(fiat.u1(x124)))
	x154, x153 := bits.mul_u64(x3, arg2[3])
	x156, x155 := bits.mul_u64(x3, arg2[2])
	x158, x157 := bits.mul_u64(x3, arg2[1])
	x160, x159 := bits.mul_u64(x3, arg2[0])
	x161, x162 := bits.add_u64(x160, x157, u64(0x0))
	x163, x164 := bits.add_u64(x158, x155, u64(fiat.u1(x162)))
	x165, x166 := bits.add_u64(x156, x153, u64(fiat.u1(x164)))
	x167 := (u64(fiat.u1(x166)) + x154)
	x168, x169 := bits.add_u64(x144, x159, u64(0x0))
	x170, x171 := bits.add_u64(x146, x161, u64(fiat.u1(x169)))
	x172, x173 := bits.add_u64(x148, x163, u64(fiat.u1(x171)))
	x174, x175 := bits.add_u64(x150, x165, u64(fiat.u1(x173)))
	x176, x177 := bits.add_u64(x152, x167, u64(fiat.u1(x175)))
	_, x178 := bits.mul_u64(x168, 0xccd1c8aaee00bc4f)
	x181, x180 := bits.mul_u64(x178, 0xffffffff00000000)
	x183, x182 := bits.mul_u64(x178, 0xffffffffffffffff)
	x185, x184 := bits.mul_u64(x178, 0xbce6faada7179e84)
	x187, x186 := bits.mul_u64(x178, 0xf3b9cac2fc632551)
	x188, x189 := bits.add_u64(x187, x184, u64(0x0))
	x190, x191 := bits.add_u64(x185, x182, u64(fiat.u1(x189)))
	x192, x193 := bits.add_u64(x183, x180, u64(fiat.u1(x191)))
	x194 := (u64(fiat.u1(x193)) + x181)
	_, x196 := bits.add_u64(x168, x186, u64(0x0))
	x197, x198 := bits.add_u64(x170, x188, u64(fiat.u1(x196)))
	x199, x200 := bits.add_u64(x172, x190, u64(fiat.u1(x198)))
	x201, x202 := bits.add_u64(x174, x192, u64(fiat.u1(x200)))
	x203, x204 := bits.add_u64(x176, x194, u64(fiat.u1(x202)))
	x205 := (u64(fiat.u1(x204)) + u64(fiat.u1(x177)))
	x206, x207 := bits.sub_u64(x197, 0xf3b9cac2fc632551, u64(0x0))
	x208, x209 := bits.sub_u64(x199, 0xbce6faada7179e84, u64(fiat.u1(x207)))
	x210, x211 := bits.sub_u64(x201, 0xffffffffffffffff, u64(fiat.u1(x209)))
	x212, x213 := bits.sub_u64(x203, 0xffffffff00000000, u64(fiat.u1(x211)))
	_, x215 := bits.sub_u64(x205, u64(0x0), u64(fiat.u1(x213)))
	x216 := fiat.cmovznz_u64(fiat.u1(x215), x206, x197)
	x217 := fiat.cmovznz_u64(fiat.u1(x215), x208, x199)
	x218 := fiat.cmovznz_u64(fiat.u1(x215), x210, x201)
	x219 := fiat.cmovznz_u64(fiat.u1(x215), x212, x203)
	out1[0] = x216
	out1[1] = x217
	out1[2] = x218
	out1[3] = x219
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
	_, x20 := bits.mul_u64(x11, 0xccd1c8aaee00bc4f)
	x23, x22 := bits.mul_u64(x20, 0xffffffff00000000)
	x25, x24 := bits.mul_u64(x20, 0xffffffffffffffff)
	x27, x26 := bits.mul_u64(x20, 0xbce6faada7179e84)
	x29, x28 := bits.mul_u64(x20, 0xf3b9cac2fc632551)
	x30, x31 := bits.add_u64(x29, x26, u64(0x0))
	x32, x33 := bits.add_u64(x27, x24, u64(fiat.u1(x31)))
	x34, x35 := bits.add_u64(x25, x22, u64(fiat.u1(x33)))
	x36 := (u64(fiat.u1(x35)) + x23)
	_, x38 := bits.add_u64(x11, x28, u64(0x0))
	x39, x40 := bits.add_u64(x13, x30, u64(fiat.u1(x38)))
	x41, x42 := bits.add_u64(x15, x32, u64(fiat.u1(x40)))
	x43, x44 := bits.add_u64(x17, x34, u64(fiat.u1(x42)))
	x45, x46 := bits.add_u64(x19, x36, u64(fiat.u1(x44)))
	x48, x47 := bits.mul_u64(x1, arg1[3])
	x50, x49 := bits.mul_u64(x1, arg1[2])
	x52, x51 := bits.mul_u64(x1, arg1[1])
	x54, x53 := bits.mul_u64(x1, arg1[0])
	x55, x56 := bits.add_u64(x54, x51, u64(0x0))
	x57, x58 := bits.add_u64(x52, x49, u64(fiat.u1(x56)))
	x59, x60 := bits.add_u64(x50, x47, u64(fiat.u1(x58)))
	x61 := (u64(fiat.u1(x60)) + x48)
	x62, x63 := bits.add_u64(x39, x53, u64(0x0))
	x64, x65 := bits.add_u64(x41, x55, u64(fiat.u1(x63)))
	x66, x67 := bits.add_u64(x43, x57, u64(fiat.u1(x65)))
	x68, x69 := bits.add_u64(x45, x59, u64(fiat.u1(x67)))
	x70, x71 := bits.add_u64(u64(fiat.u1(x46)), x61, u64(fiat.u1(x69)))
	_, x72 := bits.mul_u64(x62, 0xccd1c8aaee00bc4f)
	x75, x74 := bits.mul_u64(x72, 0xffffffff00000000)
	x77, x76 := bits.mul_u64(x72, 0xffffffffffffffff)
	x79, x78 := bits.mul_u64(x72, 0xbce6faada7179e84)
	x81, x80 := bits.mul_u64(x72, 0xf3b9cac2fc632551)
	x82, x83 := bits.add_u64(x81, x78, u64(0x0))
	x84, x85 := bits.add_u64(x79, x76, u64(fiat.u1(x83)))
	x86, x87 := bits.add_u64(x77, x74, u64(fiat.u1(x85)))
	x88 := (u64(fiat.u1(x87)) + x75)
	_, x90 := bits.add_u64(x62, x80, u64(0x0))
	x91, x92 := bits.add_u64(x64, x82, u64(fiat.u1(x90)))
	x93, x94 := bits.add_u64(x66, x84, u64(fiat.u1(x92)))
	x95, x96 := bits.add_u64(x68, x86, u64(fiat.u1(x94)))
	x97, x98 := bits.add_u64(x70, x88, u64(fiat.u1(x96)))
	x99 := (u64(fiat.u1(x98)) + u64(fiat.u1(x71)))
	x101, x100 := bits.mul_u64(x2, arg1[3])
	x103, x102 := bits.mul_u64(x2, arg1[2])
	x105, x104 := bits.mul_u64(x2, arg1[1])
	x107, x106 := bits.mul_u64(x2, arg1[0])
	x108, x109 := bits.add_u64(x107, x104, u64(0x0))
	x110, x111 := bits.add_u64(x105, x102, u64(fiat.u1(x109)))
	x112, x113 := bits.add_u64(x103, x100, u64(fiat.u1(x111)))
	x114 := (u64(fiat.u1(x113)) + x101)
	x115, x116 := bits.add_u64(x91, x106, u64(0x0))
	x117, x118 := bits.add_u64(x93, x108, u64(fiat.u1(x116)))
	x119, x120 := bits.add_u64(x95, x110, u64(fiat.u1(x118)))
	x121, x122 := bits.add_u64(x97, x112, u64(fiat.u1(x120)))
	x123, x124 := bits.add_u64(x99, x114, u64(fiat.u1(x122)))
	_, x125 := bits.mul_u64(x115, 0xccd1c8aaee00bc4f)
	x128, x127 := bits.mul_u64(x125, 0xffffffff00000000)
	x130, x129 := bits.mul_u64(x125, 0xffffffffffffffff)
	x132, x131 := bits.mul_u64(x125, 0xbce6faada7179e84)
	x134, x133 := bits.mul_u64(x125, 0xf3b9cac2fc632551)
	x135, x136 := bits.add_u64(x134, x131, u64(0x0))
	x137, x138 := bits.add_u64(x132, x129, u64(fiat.u1(x136)))
	x139, x140 := bits.add_u64(x130, x127, u64(fiat.u1(x138)))
	x141 := (u64(fiat.u1(x140)) + x128)
	_, x143 := bits.add_u64(x115, x133, u64(0x0))
	x144, x145 := bits.add_u64(x117, x135, u64(fiat.u1(x143)))
	x146, x147 := bits.add_u64(x119, x137, u64(fiat.u1(x145)))
	x148, x149 := bits.add_u64(x121, x139, u64(fiat.u1(x147)))
	x150, x151 := bits.add_u64(x123, x141, u64(fiat.u1(x149)))
	x152 := (u64(fiat.u1(x151)) + u64(fiat.u1(x124)))
	x154, x153 := bits.mul_u64(x3, arg1[3])
	x156, x155 := bits.mul_u64(x3, arg1[2])
	x158, x157 := bits.mul_u64(x3, arg1[1])
	x160, x159 := bits.mul_u64(x3, arg1[0])
	x161, x162 := bits.add_u64(x160, x157, u64(0x0))
	x163, x164 := bits.add_u64(x158, x155, u64(fiat.u1(x162)))
	x165, x166 := bits.add_u64(x156, x153, u64(fiat.u1(x164)))
	x167 := (u64(fiat.u1(x166)) + x154)
	x168, x169 := bits.add_u64(x144, x159, u64(0x0))
	x170, x171 := bits.add_u64(x146, x161, u64(fiat.u1(x169)))
	x172, x173 := bits.add_u64(x148, x163, u64(fiat.u1(x171)))
	x174, x175 := bits.add_u64(x150, x165, u64(fiat.u1(x173)))
	x176, x177 := bits.add_u64(x152, x167, u64(fiat.u1(x175)))
	_, x178 := bits.mul_u64(x168, 0xccd1c8aaee00bc4f)
	x181, x180 := bits.mul_u64(x178, 0xffffffff00000000)
	x183, x182 := bits.mul_u64(x178, 0xffffffffffffffff)
	x185, x184 := bits.mul_u64(x178, 0xbce6faada7179e84)
	x187, x186 := bits.mul_u64(x178, 0xf3b9cac2fc632551)
	x188, x189 := bits.add_u64(x187, x184, u64(0x0))
	x190, x191 := bits.add_u64(x185, x182, u64(fiat.u1(x189)))
	x192, x193 := bits.add_u64(x183, x180, u64(fiat.u1(x191)))
	x194 := (u64(fiat.u1(x193)) + x181)
	_, x196 := bits.add_u64(x168, x186, u64(0x0))
	x197, x198 := bits.add_u64(x170, x188, u64(fiat.u1(x196)))
	x199, x200 := bits.add_u64(x172, x190, u64(fiat.u1(x198)))
	x201, x202 := bits.add_u64(x174, x192, u64(fiat.u1(x200)))
	x203, x204 := bits.add_u64(x176, x194, u64(fiat.u1(x202)))
	x205 := (u64(fiat.u1(x204)) + u64(fiat.u1(x177)))
	x206, x207 := bits.sub_u64(x197, 0xf3b9cac2fc632551, u64(0x0))
	x208, x209 := bits.sub_u64(x199, 0xbce6faada7179e84, u64(fiat.u1(x207)))
	x210, x211 := bits.sub_u64(x201, 0xffffffffffffffff, u64(fiat.u1(x209)))
	x212, x213 := bits.sub_u64(x203, 0xffffffff00000000, u64(fiat.u1(x211)))
	_, x215 := bits.sub_u64(x205, u64(0x0), u64(fiat.u1(x213)))
	x216 := fiat.cmovznz_u64(fiat.u1(x215), x206, x197)
	x217 := fiat.cmovznz_u64(fiat.u1(x215), x208, x199)
	x218 := fiat.cmovznz_u64(fiat.u1(x215), x210, x201)
	x219 := fiat.cmovznz_u64(fiat.u1(x215), x212, x203)
	out1[0] = x216
	out1[1] = x217
	out1[2] = x218
	out1[3] = x219
}

fe_add :: proc "contextless" (out1, arg1, arg2: ^Montgomery_Domain_Field_Element) {
	x1, x2 := bits.add_u64(arg1[0], arg2[0], u64(0x0))
	x3, x4 := bits.add_u64(arg1[1], arg2[1], u64(fiat.u1(x2)))
	x5, x6 := bits.add_u64(arg1[2], arg2[2], u64(fiat.u1(x4)))
	x7, x8 := bits.add_u64(arg1[3], arg2[3], u64(fiat.u1(x6)))
	x9, x10 := bits.sub_u64(x1, 0xf3b9cac2fc632551, u64(0x0))
	x11, x12 := bits.sub_u64(x3, 0xbce6faada7179e84, u64(fiat.u1(x10)))
	x13, x14 := bits.sub_u64(x5, 0xffffffffffffffff, u64(fiat.u1(x12)))
	x15, x16 := bits.sub_u64(x7, 0xffffffff00000000, u64(fiat.u1(x14)))
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
	x10, x11 := bits.add_u64(x1, (x9 & 0xf3b9cac2fc632551), u64(0x0))
	x12, x13 := bits.add_u64(x3, (x9 & 0xbce6faada7179e84), u64(fiat.u1(x11)))
	x14, x15 := bits.add_u64(x5, x9, u64(fiat.u1(x13)))
	x16, _ := bits.add_u64(x7, (x9 & 0xffffffff00000000), u64(fiat.u1(x15)))
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
	x10, x11 := bits.add_u64(x1, (x9 & 0xf3b9cac2fc632551), u64(0x0))
	x12, x13 := bits.add_u64(x3, (x9 & 0xbce6faada7179e84), u64(fiat.u1(x11)))
	x14, x15 := bits.add_u64(x5, x9, u64(fiat.u1(x13)))
	x16, _ := bits.add_u64(x7, (x9 & 0xffffffff00000000), u64(fiat.u1(x15)))
	out1[0] = x10
	out1[1] = x12
	out1[2] = x14
	out1[3] = x16
}

fe_one :: proc "contextless" (out1: ^Montgomery_Domain_Field_Element) {
	out1[0] = 0xc46353d039cdaaf
	out1[1] = 0x4319055258e8617b
	out1[2] = u64(0x0)
	out1[3] = 0xffffffff
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
	_, x2 := bits.mul_u64(x1, 0xccd1c8aaee00bc4f)
	x5, x4 := bits.mul_u64(x2, 0xffffffff00000000)
	x7, x6 := bits.mul_u64(x2, 0xffffffffffffffff)
	x9, x8 := bits.mul_u64(x2, 0xbce6faada7179e84)
	x11, x10 := bits.mul_u64(x2, 0xf3b9cac2fc632551)
	x12, x13 := bits.add_u64(x11, x8, u64(0x0))
	x14, x15 := bits.add_u64(x9, x6, u64(fiat.u1(x13)))
	x16, x17 := bits.add_u64(x7, x4, u64(fiat.u1(x15)))
	_, x19 := bits.add_u64(x1, x10, u64(0x0))
	x20, x21 := bits.add_u64(u64(0x0), x12, u64(fiat.u1(x19)))
	x22, x23 := bits.add_u64(u64(0x0), x14, u64(fiat.u1(x21)))
	x24, x25 := bits.add_u64(u64(0x0), x16, u64(fiat.u1(x23)))
	x26, x27 := bits.add_u64(x20, arg1[1], u64(0x0))
	x28, x29 := bits.add_u64(x22, u64(0x0), u64(fiat.u1(x27)))
	x30, x31 := bits.add_u64(x24, u64(0x0), u64(fiat.u1(x29)))
	_, x32 := bits.mul_u64(x26, 0xccd1c8aaee00bc4f)
	x35, x34 := bits.mul_u64(x32, 0xffffffff00000000)
	x37, x36 := bits.mul_u64(x32, 0xffffffffffffffff)
	x39, x38 := bits.mul_u64(x32, 0xbce6faada7179e84)
	x41, x40 := bits.mul_u64(x32, 0xf3b9cac2fc632551)
	x42, x43 := bits.add_u64(x41, x38, u64(0x0))
	x44, x45 := bits.add_u64(x39, x36, u64(fiat.u1(x43)))
	x46, x47 := bits.add_u64(x37, x34, u64(fiat.u1(x45)))
	_, x49 := bits.add_u64(x26, x40, u64(0x0))
	x50, x51 := bits.add_u64(x28, x42, u64(fiat.u1(x49)))
	x52, x53 := bits.add_u64(x30, x44, u64(fiat.u1(x51)))
	x54, x55 := bits.add_u64((u64(fiat.u1(x31)) + (u64(fiat.u1(x25)) + (u64(fiat.u1(x17)) + x5))), x46, u64(fiat.u1(x53)))
	x56, x57 := bits.add_u64(x50, arg1[2], u64(0x0))
	x58, x59 := bits.add_u64(x52, u64(0x0), u64(fiat.u1(x57)))
	x60, x61 := bits.add_u64(x54, u64(0x0), u64(fiat.u1(x59)))
	_, x62 := bits.mul_u64(x56, 0xccd1c8aaee00bc4f)
	x65, x64 := bits.mul_u64(x62, 0xffffffff00000000)
	x67, x66 := bits.mul_u64(x62, 0xffffffffffffffff)
	x69, x68 := bits.mul_u64(x62, 0xbce6faada7179e84)
	x71, x70 := bits.mul_u64(x62, 0xf3b9cac2fc632551)
	x72, x73 := bits.add_u64(x71, x68, u64(0x0))
	x74, x75 := bits.add_u64(x69, x66, u64(fiat.u1(x73)))
	x76, x77 := bits.add_u64(x67, x64, u64(fiat.u1(x75)))
	_, x79 := bits.add_u64(x56, x70, u64(0x0))
	x80, x81 := bits.add_u64(x58, x72, u64(fiat.u1(x79)))
	x82, x83 := bits.add_u64(x60, x74, u64(fiat.u1(x81)))
	x84, x85 := bits.add_u64((u64(fiat.u1(x61)) + (u64(fiat.u1(x55)) + (u64(fiat.u1(x47)) + x35))), x76, u64(fiat.u1(x83)))
	x86, x87 := bits.add_u64(x80, arg1[3], u64(0x0))
	x88, x89 := bits.add_u64(x82, u64(0x0), u64(fiat.u1(x87)))
	x90, x91 := bits.add_u64(x84, u64(0x0), u64(fiat.u1(x89)))
	_, x92 := bits.mul_u64(x86, 0xccd1c8aaee00bc4f)
	x95, x94 := bits.mul_u64(x92, 0xffffffff00000000)
	x97, x96 := bits.mul_u64(x92, 0xffffffffffffffff)
	x99, x98 := bits.mul_u64(x92, 0xbce6faada7179e84)
	x101, x100 := bits.mul_u64(x92, 0xf3b9cac2fc632551)
	x102, x103 := bits.add_u64(x101, x98, u64(0x0))
	x104, x105 := bits.add_u64(x99, x96, u64(fiat.u1(x103)))
	x106, x107 := bits.add_u64(x97, x94, u64(fiat.u1(x105)))
	_, x109 := bits.add_u64(x86, x100, u64(0x0))
	x110, x111 := bits.add_u64(x88, x102, u64(fiat.u1(x109)))
	x112, x113 := bits.add_u64(x90, x104, u64(fiat.u1(x111)))
	x114, x115 := bits.add_u64((u64(fiat.u1(x91)) + (u64(fiat.u1(x85)) + (u64(fiat.u1(x77)) + x65))), x106, u64(fiat.u1(x113)))
	x116 := (u64(fiat.u1(x115)) + (u64(fiat.u1(x107)) + x95))
	x117, x118 := bits.sub_u64(x110, 0xf3b9cac2fc632551, u64(0x0))
	x119, x120 := bits.sub_u64(x112, 0xbce6faada7179e84, u64(fiat.u1(x118)))
	x121, x122 := bits.sub_u64(x114, 0xffffffffffffffff, u64(fiat.u1(x120)))
	x123, x124 := bits.sub_u64(x116, 0xffffffff00000000, u64(fiat.u1(x122)))
	_, x126 := bits.sub_u64(u64(0x0), u64(0x0), u64(fiat.u1(x124)))
	x127 := fiat.cmovznz_u64(fiat.u1(x126), x117, x110)
	x128 := fiat.cmovznz_u64(fiat.u1(x126), x119, x112)
	x129 := fiat.cmovznz_u64(fiat.u1(x126), x121, x114)
	x130 := fiat.cmovznz_u64(fiat.u1(x126), x123, x116)
	out1[0] = x127
	out1[1] = x128
	out1[2] = x129
	out1[3] = x130
}

fe_to_montgomery :: proc "contextless" (
	out1: ^Montgomery_Domain_Field_Element,
	arg1: ^Non_Montgomery_Domain_Field_Element,
) {
	x1 := arg1[1]
	x2 := arg1[2]
	x3 := arg1[3]
	x4 := arg1[0]
	x6, x5 := bits.mul_u64(x4, 0x66e12d94f3d95620)
	x8, x7 := bits.mul_u64(x4, 0x2845b2392b6bec59)
	x10, x9 := bits.mul_u64(x4, 0x4699799c49bd6fa6)
	x12, x11 := bits.mul_u64(x4, 0x83244c95be79eea2)
	x13, x14 := bits.add_u64(x12, x9, u64(0x0))
	x15, x16 := bits.add_u64(x10, x7, u64(fiat.u1(x14)))
	x17, x18 := bits.add_u64(x8, x5, u64(fiat.u1(x16)))
	_, x19 := bits.mul_u64(x11, 0xccd1c8aaee00bc4f)
	x22, x21 := bits.mul_u64(x19, 0xffffffff00000000)
	x24, x23 := bits.mul_u64(x19, 0xffffffffffffffff)
	x26, x25 := bits.mul_u64(x19, 0xbce6faada7179e84)
	x28, x27 := bits.mul_u64(x19, 0xf3b9cac2fc632551)
	x29, x30 := bits.add_u64(x28, x25, u64(0x0))
	x31, x32 := bits.add_u64(x26, x23, u64(fiat.u1(x30)))
	x33, x34 := bits.add_u64(x24, x21, u64(fiat.u1(x32)))
	_, x36 := bits.add_u64(x11, x27, u64(0x0))
	x37, x38 := bits.add_u64(x13, x29, u64(fiat.u1(x36)))
	x39, x40 := bits.add_u64(x15, x31, u64(fiat.u1(x38)))
	x41, x42 := bits.add_u64(x17, x33, u64(fiat.u1(x40)))
	x43, x44 := bits.add_u64((u64(fiat.u1(x18)) + x6), (u64(fiat.u1(x34)) + x22), u64(fiat.u1(x42)))
	x46, x45 := bits.mul_u64(x1, 0x66e12d94f3d95620)
	x48, x47 := bits.mul_u64(x1, 0x2845b2392b6bec59)
	x50, x49 := bits.mul_u64(x1, 0x4699799c49bd6fa6)
	x52, x51 := bits.mul_u64(x1, 0x83244c95be79eea2)
	x53, x54 := bits.add_u64(x52, x49, u64(0x0))
	x55, x56 := bits.add_u64(x50, x47, u64(fiat.u1(x54)))
	x57, x58 := bits.add_u64(x48, x45, u64(fiat.u1(x56)))
	x59, x60 := bits.add_u64(x37, x51, u64(0x0))
	x61, x62 := bits.add_u64(x39, x53, u64(fiat.u1(x60)))
	x63, x64 := bits.add_u64(x41, x55, u64(fiat.u1(x62)))
	x65, x66 := bits.add_u64(x43, x57, u64(fiat.u1(x64)))
	_, x67 := bits.mul_u64(x59, 0xccd1c8aaee00bc4f)
	x70, x69 := bits.mul_u64(x67, 0xffffffff00000000)
	x72, x71 := bits.mul_u64(x67, 0xffffffffffffffff)
	x74, x73 := bits.mul_u64(x67, 0xbce6faada7179e84)
	x76, x75 := bits.mul_u64(x67, 0xf3b9cac2fc632551)
	x77, x78 := bits.add_u64(x76, x73, u64(0x0))
	x79, x80 := bits.add_u64(x74, x71, u64(fiat.u1(x78)))
	x81, x82 := bits.add_u64(x72, x69, u64(fiat.u1(x80)))
	_, x84 := bits.add_u64(x59, x75, u64(0x0))
	x85, x86 := bits.add_u64(x61, x77, u64(fiat.u1(x84)))
	x87, x88 := bits.add_u64(x63, x79, u64(fiat.u1(x86)))
	x89, x90 := bits.add_u64(x65, x81, u64(fiat.u1(x88)))
	x91, x92 := bits.add_u64(((u64(fiat.u1(x66)) + u64(fiat.u1(x44))) + (u64(fiat.u1(x58)) + x46)), (u64(fiat.u1(x82)) + x70), u64(fiat.u1(x90)))
	x94, x93 := bits.mul_u64(x2, 0x66e12d94f3d95620)
	x96, x95 := bits.mul_u64(x2, 0x2845b2392b6bec59)
	x98, x97 := bits.mul_u64(x2, 0x4699799c49bd6fa6)
	x100, x99 := bits.mul_u64(x2, 0x83244c95be79eea2)
	x101, x102 := bits.add_u64(x100, x97, u64(0x0))
	x103, x104 := bits.add_u64(x98, x95, u64(fiat.u1(x102)))
	x105, x106 := bits.add_u64(x96, x93, u64(fiat.u1(x104)))
	x107, x108 := bits.add_u64(x85, x99, u64(0x0))
	x109, x110 := bits.add_u64(x87, x101, u64(fiat.u1(x108)))
	x111, x112 := bits.add_u64(x89, x103, u64(fiat.u1(x110)))
	x113, x114 := bits.add_u64(x91, x105, u64(fiat.u1(x112)))
	_, x115 := bits.mul_u64(x107, 0xccd1c8aaee00bc4f)
	x118, x117 := bits.mul_u64(x115, 0xffffffff00000000)
	x120, x119 := bits.mul_u64(x115, 0xffffffffffffffff)
	x122, x121 := bits.mul_u64(x115, 0xbce6faada7179e84)
	x124, x123 := bits.mul_u64(x115, 0xf3b9cac2fc632551)
	x125, x126 := bits.add_u64(x124, x121, u64(0x0))
	x127, x128 := bits.add_u64(x122, x119, u64(fiat.u1(x126)))
	x129, x130 := bits.add_u64(x120, x117, u64(fiat.u1(x128)))
	_, x132 := bits.add_u64(x107, x123, u64(0x0))
	x133, x134 := bits.add_u64(x109, x125, u64(fiat.u1(x132)))
	x135, x136 := bits.add_u64(x111, x127, u64(fiat.u1(x134)))
	x137, x138 := bits.add_u64(x113, x129, u64(fiat.u1(x136)))
	x139, x140 := bits.add_u64(((u64(fiat.u1(x114)) + u64(fiat.u1(x92))) + (u64(fiat.u1(x106)) + x94)), (u64(fiat.u1(x130)) + x118), u64(fiat.u1(x138)))
	x142, x141 := bits.mul_u64(x3, 0x66e12d94f3d95620)
	x144, x143 := bits.mul_u64(x3, 0x2845b2392b6bec59)
	x146, x145 := bits.mul_u64(x3, 0x4699799c49bd6fa6)
	x148, x147 := bits.mul_u64(x3, 0x83244c95be79eea2)
	x149, x150 := bits.add_u64(x148, x145, u64(0x0))
	x151, x152 := bits.add_u64(x146, x143, u64(fiat.u1(x150)))
	x153, x154 := bits.add_u64(x144, x141, u64(fiat.u1(x152)))
	x155, x156 := bits.add_u64(x133, x147, u64(0x0))
	x157, x158 := bits.add_u64(x135, x149, u64(fiat.u1(x156)))
	x159, x160 := bits.add_u64(x137, x151, u64(fiat.u1(x158)))
	x161, x162 := bits.add_u64(x139, x153, u64(fiat.u1(x160)))
	_, x163 := bits.mul_u64(x155, 0xccd1c8aaee00bc4f)
	x166, x165 := bits.mul_u64(x163, 0xffffffff00000000)
	x168, x167 := bits.mul_u64(x163, 0xffffffffffffffff)
	x170, x169 := bits.mul_u64(x163, 0xbce6faada7179e84)
	x172, x171 := bits.mul_u64(x163, 0xf3b9cac2fc632551)
	x173, x174 := bits.add_u64(x172, x169, u64(0x0))
	x175, x176 := bits.add_u64(x170, x167, u64(fiat.u1(x174)))
	x177, x178 := bits.add_u64(x168, x165, u64(fiat.u1(x176)))
	_, x180 := bits.add_u64(x155, x171, u64(0x0))
	x181, x182 := bits.add_u64(x157, x173, u64(fiat.u1(x180)))
	x183, x184 := bits.add_u64(x159, x175, u64(fiat.u1(x182)))
	x185, x186 := bits.add_u64(x161, x177, u64(fiat.u1(x184)))
	x187, x188 := bits.add_u64(((u64(fiat.u1(x162)) + u64(fiat.u1(x140))) + (u64(fiat.u1(x154)) + x142)), (u64(fiat.u1(x178)) + x166), u64(fiat.u1(x186)))
	x189, x190 := bits.sub_u64(x181, 0xf3b9cac2fc632551, u64(0x0))
	x191, x192 := bits.sub_u64(x183, 0xbce6faada7179e84, u64(fiat.u1(x190)))
	x193, x194 := bits.sub_u64(x185, 0xffffffffffffffff, u64(fiat.u1(x192)))
	x195, x196 := bits.sub_u64(x187, 0xffffffff00000000, u64(fiat.u1(x194)))
	_, x198 := bits.sub_u64(u64(fiat.u1(x188)), u64(0x0), u64(fiat.u1(x196)))
	x199 := fiat.cmovznz_u64(fiat.u1(x198), x189, x181)
	x200 := fiat.cmovznz_u64(fiat.u1(x198), x191, x183)
	x201 := fiat.cmovznz_u64(fiat.u1(x198), x193, x185)
	x202 := fiat.cmovznz_u64(fiat.u1(x198), x195, x187)
	out1[0] = x199
	out1[1] = x200
	out1[2] = x201
	out1[3] = x202
}
