package test_core_endian

import "core:encoding/endian"
import "core:math/rand"
import "core:testing"

NUM_RANDOM_TESTS :: 1000
SENTINEL         :: 0xAA

ref_get_unsigned :: proc(b: []byte, order: endian.Byte_Order, n: int) -> (v: u64) {
	for i in 0..<n {
		idx := i if order == .Little else n - 1 - i
		v |= u64(b[idx]) << uint(8 * i)
	}
	return
}

ref_get_signed :: proc(b: []byte, order: endian.Byte_Order, n: int) -> i64 {
	v := ref_get_unsigned(b, order, n)
	if n < 8 && v & (1 << uint(8 * n - 1)) != 0 {
		v |= ~u64(0) << uint(8 * n)
	}
	return i64(v)
}

ref_put_unsigned :: proc(b: []byte, order: endian.Byte_Order, v: u64, n: int) {
	for i in 0..<n {
		idx := i if order == .Little else n - 1 - i
		b[idx] = byte(v >> uint(8 * i))
	}
}

@(test)
test_regular_vectors :: proc(t: ^testing.T) {
	buf: [8]byte

	{
		b := []byte{0x12, 0x34}
		v, ok := endian.get_u16(b, .Little)
		testing.expect(t, ok && v == 0x3412)
		v, ok = endian.get_u16(b, .Big)
		testing.expect(t, ok && v == 0x1234)
		i, iok := endian.get_i16([]byte{0xFE, 0xFF}, .Little)
		testing.expect(t, iok && i == -2)
		i, iok = endian.get_i16([]byte{0xFF, 0xFE}, .Big)
		testing.expect(t, iok && i == -2)

		testing.expect(t, endian.put_u16(buf[:], .Little, 0x1234))
		testing.expect(t, buf[0] == 0x34 && buf[1] == 0x12)
		testing.expect(t, endian.put_u16(buf[:], .Big, 0x1234))
		testing.expect(t, buf[0] == 0x12 && buf[1] == 0x34)
		testing.expect(t, endian.put_i16(buf[:], .Little, -2))
		testing.expect(t, buf[0] == 0xFE && buf[1] == 0xFF)
	}

	{
		b := []byte{0x12, 0x34, 0x56, 0x78}
		v, ok := endian.get_u32(b, .Little)
		testing.expect(t, ok && v == 0x78563412)
		v, ok = endian.get_u32(b, .Big)
		testing.expect(t, ok && v == 0x12345678)
		i, iok := endian.get_i32([]byte{0xFE, 0xFF, 0xFF, 0xFF}, .Little)
		testing.expect(t, iok && i == -2)
		i, iok = endian.get_i32([]byte{0xFF, 0xFF, 0xFF, 0xFE}, .Big)
		testing.expect(t, iok && i == -2)

		testing.expect(t, endian.put_u32(buf[:], .Little, 0x12345678))
		testing.expect(t, buf[0] == 0x78 && buf[1] == 0x56 && buf[2] == 0x34 && buf[3] == 0x12)
		testing.expect(t, endian.put_u32(buf[:], .Big, 0x12345678))
		testing.expect(t, buf[0] == 0x12 && buf[1] == 0x34 && buf[2] == 0x56 && buf[3] == 0x78)
		testing.expect(t, endian.put_i32(buf[:], .Big, -2))
		testing.expect(t, buf[0] == 0xFF && buf[3] == 0xFE)
	}

	{
		b := []byte{0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08}
		v, ok := endian.get_u64(b, .Little)
		testing.expect(t, ok && v == 0x0807060504030201)
		v, ok = endian.get_u64(b, .Big)
		testing.expect(t, ok && v == 0x0102030405060708)
		i, iok := endian.get_i64([]byte{0xFE, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF}, .Little)
		testing.expect(t, iok && i == -2)
		i, iok = endian.get_i64([]byte{0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFE}, .Big)
		testing.expect(t, iok && i == -2)

		testing.expect(t, endian.put_u64(buf[:], .Little, 0x0102030405060708))
		testing.expect(t, buf == {8, 7, 6, 5, 4, 3, 2, 1})
		testing.expect(t, endian.put_u64(buf[:], .Big, 0x0102030405060708))
		testing.expect(t, buf == {1, 2, 3, 4, 5, 6, 7, 8})
		testing.expect(t, endian.put_i64(buf[:], .Little, -2))
		testing.expect(t, buf == {0xFE, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF})
	}

	{
		testing.expect(t, endian.put_f16(buf[:], .Big, 1.0))
		testing.expect(t, buf[0] == 0x3C && buf[1] == 0x00)
		f16v, ok16 := endian.get_f16(buf[:], .Big)
		testing.expect(t, ok16 && f16v == 1.0)
		f16v, ok16 = endian.get_f16([]byte{0x00, 0x3C}, .Little)
		testing.expect(t, ok16 && f16v == 1.0)

		testing.expect(t, endian.put_f32(buf[:], .Big, 1.0))
		testing.expect(t, buf[0] == 0x3F && buf[1] == 0x80 && buf[2] == 0 && buf[3] == 0)
		f32v, ok32 := endian.get_f32(buf[:], .Big)
		testing.expect(t, ok32 && f32v == 1.0)
		testing.expect(t, endian.put_f32(buf[:], .Little, -2.5))
		f32v, ok32 = endian.get_f32(buf[:], .Little)
		testing.expect(t, ok32 && f32v == -2.5)

		testing.expect(t, endian.put_f64(buf[:], .Big, 1.0))
		testing.expect(t, buf == {0x3F, 0xF0, 0, 0, 0, 0, 0, 0})
		f64v, ok64 := endian.get_f64(buf[:], .Big)
		testing.expect(t, ok64 && f64v == 1.0)
		testing.expect(t, endian.put_f64(buf[:], .Little, 1234.5678))
		f64v, ok64 = endian.get_f64(buf[:], .Little)
		testing.expect(t, ok64 && f64v == 1234.5678)
	}
}

@(test)
test_regular_short_buffers :: proc(t: ^testing.T) {
	backing: [16]byte
	for &x in backing { x = SENTINEL }

	for order in endian.Byte_Order {
		ok: bool
		_, ok = endian.get_u16(backing[:1], order); testing.expect(t, !ok)
		_, ok = endian.get_u32(backing[:3], order); testing.expect(t, !ok)
		_, ok = endian.get_u64(backing[:7], order); testing.expect(t, !ok)
		_, ok = endian.get_i16(backing[:1], order); testing.expect(t, !ok)
		_, ok = endian.get_i32(backing[:3], order); testing.expect(t, !ok)
		_, ok = endian.get_i64(backing[:7], order); testing.expect(t, !ok)
		_, ok = endian.get_f16(backing[:1], order); testing.expect(t, !ok)
		_, ok = endian.get_f32(backing[:3], order); testing.expect(t, !ok)
		_, ok = endian.get_f64(backing[:7], order); testing.expect(t, !ok)

		testing.expect(t, !endian.put_u16(backing[:1], order, 1))
		testing.expect(t, !endian.put_u32(backing[:3], order, 1))
		testing.expect(t, !endian.put_u64(backing[:7], order, 1))
		testing.expect(t, !endian.put_i16(backing[:1], order, 1))
		testing.expect(t, !endian.put_i32(backing[:3], order, 1))
		testing.expect(t, !endian.put_i64(backing[:7], order, 1))
		testing.expect(t, !endian.put_f16(backing[:1], order, 1))
		testing.expect(t, !endian.put_f32(backing[:3], order, 1))
		testing.expect(t, !endian.put_f64(backing[:7], order, 1))
	}
	for b in backing {
		testing.expect(t, b == SENTINEL, "Failed put modified the buffer")
	}
}

@(test)
test_regular_roundtrip :: proc(t: ^testing.T) {
	rand.reset(0xE4D1A4)
	buf: [8]byte
	for _ in 0..<NUM_RANDOM_TESTS {
		v := rand.uint64()
		for order in endian.Byte_Order {
			testing.expect(t, endian.put_u16(buf[:], order, u16(v)))
			r16, _ := endian.get_u16(buf[:], order)
			testing.expect_value(t, r16, u16(v))

			testing.expect(t, endian.put_u32(buf[:], order, u32(v)))
			r32, _ := endian.get_u32(buf[:], order)
			testing.expect_value(t, r32, u32(v))

			testing.expect(t, endian.put_u64(buf[:], order, v))
			r64, _ := endian.get_u64(buf[:], order)
			testing.expect_value(t, r64, v)

			testing.expect(t, endian.put_i16(buf[:], order, i16(v)))
			s16, _ := endian.get_i16(buf[:], order)
			testing.expect_value(t, s16, i16(v))

			testing.expect(t, endian.put_i32(buf[:], order, i32(v)))
			s32, _ := endian.get_i32(buf[:], order)
			testing.expect_value(t, s32, i32(v))

			testing.expect(t, endian.put_i64(buf[:], order, i64(v)))
			s64, _ := endian.get_i64(buf[:], order)
			testing.expect_value(t, s64, i64(v))
		}
	}
}

check_value :: proc(t: ^testing.T, v: u64, $N: int) {
	BYTES :: N / 8
	mask  := ~u64(0) >> uint(64 - N)

	for order in endian.Byte_Order {
		buf: [10]byte
		for &x in buf { x = SENTINEL }
		expected := buf
		ref_put_unsigned(expected[:], order, v, BYTES)

		if order == .Little {
			endian.unchecked_put_unsigned_le(buf[:], v, N)
		} else {
			endian.unchecked_put_unsigned_be(buf[:], v, N)
		}
		testing.expectf(t, buf == expected, "N=%v %v put_unsigned(%x): got %x, expected %x", N, order, v, buf, expected)

		sbuf: [10]byte
		for &x in sbuf { x = SENTINEL }
		if order == .Little {
			endian.unchecked_put_signed_le(sbuf[:], i64(v), N)
		} else {
			endian.unchecked_put_signed_be(sbuf[:], i64(v), N)
		}
		testing.expectf(t, sbuf == expected, "N=%v %v put_signed(%x): got %x, expected %x", N, order, v, sbuf, expected)

		uv: u64
		iv: i64
		if order == .Little {
			uv = endian.unchecked_get_unsigned_le(buf[:], N)
			iv = endian.unchecked_get_signed_le(buf[:], N)
		} else {
			uv = endian.unchecked_get_unsigned_be(buf[:], N)
			iv = endian.unchecked_get_signed_be(buf[:], N)
		}
		testing.expectf(t, uv == v & mask, "N=%v %v get_unsigned: got %x, expected %x", N, order, uv, v & mask)
		testing.expectf(t, uv == ref_get_unsigned(buf[:], order, BYTES), "N=%v %v get_unsigned differs from reference", N, order)

		sign_extended := i64(v << uint(64 - N)) >> uint(64 - N)
		testing.expectf(t, iv == sign_extended, "N=%v %v get_signed: got %v, expected %v", N, order, iv, sign_extended)

		cu, cu_ok := endian.get_unsigned(buf[:], order, N)
		testing.expect(t, cu_ok && cu == uv)
		cs, cs_ok := endian.get_signed(buf[:], order, N)
		testing.expect(t, cs_ok && cs == iv)

		cbuf: [10]byte
		for &x in cbuf { x = SENTINEL }
		testing.expect(t, endian.put_unsigned(cbuf[:], order, v, N))
		testing.expect(t, cbuf == expected)
		for &x in cbuf { x = SENTINEL }
		testing.expect(t, endian.put_signed(cbuf[:], order, i64(v), N))
		testing.expect(t, cbuf == expected)

		_, exact_ok := endian.get_unsigned(buf[:BYTES], order, N)
		testing.expect(t, exact_ok)
		for &x in cbuf { x = SENTINEL }
		testing.expect(t, endian.put_unsigned(cbuf[:BYTES], order, v, N))
		testing.expect(t, cbuf == expected)

		for &x in cbuf { x = SENTINEL }
		_, short_ok := endian.get_unsigned(cbuf[:BYTES - 1], order, N)
		testing.expect(t, !short_ok)
		_, short_ok = endian.get_signed(cbuf[:BYTES - 1], order, N)
		testing.expect(t, !short_ok)
		testing.expect(t, !endian.put_unsigned(cbuf[:BYTES - 1], order, v, N))
		testing.expect(t, !endian.put_signed(cbuf[:BYTES - 1], order, i64(v), N))
		for x in cbuf { testing.expect(t, x == SENTINEL) }
	}
}

check_width :: proc(t: ^testing.T, $N: int) {
	edges := [?]u64{
		0, 1, 2, 0x7F, 0x80, 0xFF, 0x100, 0x7FFF, 0x8000, 0xFFFF,
		0x7FFF_FFFF, 0x8000_0000, 0xFFFF_FFFF,
		0x7FFF_FFFF_FFFF_FFFF, 0x8000_0000_0000_0000, 0xFFFF_FFFF_FFFF_FFFF,
		0x0123_4567_89AB_CDEF, 0xFEDC_BA98_7654_3210,
	}
	for v in edges {
		check_value(t, v, N)
	}
	rand.reset(u64(N))
	for _ in 0..<NUM_RANDOM_TESTS {
		check_value(t, rand.uint64(), N)
	}
}

@(test) test_width_8  :: proc(t: ^testing.T) { check_width(t, 8)  }
@(test) test_width_16 :: proc(t: ^testing.T) { check_width(t, 16) }
@(test) test_width_24 :: proc(t: ^testing.T) { check_width(t, 24) }
@(test) test_width_32 :: proc(t: ^testing.T) { check_width(t, 32) }
@(test) test_width_40 :: proc(t: ^testing.T) { check_width(t, 40) }
@(test) test_width_48 :: proc(t: ^testing.T) { check_width(t, 48) }
@(test) test_width_56 :: proc(t: ^testing.T) { check_width(t, 56) }
@(test) test_width_64 :: proc(t: ^testing.T) { check_width(t, 64) }

@(test)
test_generic_vectors :: proc(t: ^testing.T) {
	b := []byte{0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08}
	testing.expect_value(t, endian.unchecked_get_unsigned_le(b, 8),  0x01)
	testing.expect_value(t, endian.unchecked_get_unsigned_be(b, 8),  0x01)
	testing.expect_value(t, endian.unchecked_get_unsigned_le(b, 24), 0x030201)
	testing.expect_value(t, endian.unchecked_get_unsigned_be(b, 24), 0x010203)
	testing.expect_value(t, endian.unchecked_get_unsigned_le(b, 40), 0x0504030201)
	testing.expect_value(t, endian.unchecked_get_unsigned_be(b, 40), 0x0102030405)
	testing.expect_value(t, endian.unchecked_get_unsigned_le(b, 56), 0x07060504030201)
	testing.expect_value(t, endian.unchecked_get_unsigned_be(b, 56), 0x01020304050607)

	testing.expect_value(t, endian.unchecked_get_signed_le([]byte{0xFD, 0xFF, 0xFF}, 24), -3)
	testing.expect_value(t, endian.unchecked_get_unsigned_le([]byte{0xFD, 0xFF, 0xFF}, 24), 0xFFFFFD)
	testing.expect_value(t, endian.unchecked_get_signed_be([]byte{0xFF, 0xFF, 0xFD}, 24), -3)
	testing.expect_value(t, endian.unchecked_get_signed_be([]byte{0x80}, 8), -128)
	testing.expect_value(t, endian.unchecked_get_signed_be([]byte{0x7F}, 8), 127)

	buf: [4]byte
	endian.unchecked_put_unsigned_le(buf[:], 0xAABBCCDD_11223344, 24)
	testing.expect(t, buf == {0x44, 0x33, 0x22, 0x00})
	endian.unchecked_put_unsigned_be(buf[:], 0xAABBCCDD_11223344, 24)
	testing.expect(t, buf == {0x22, 0x33, 0x44, 0x00})
	endian.unchecked_put_signed_le(buf[:], -2, 16)
	testing.expect(t, buf[0] == 0xFE && buf[1] == 0xFF)
	endian.unchecked_put_signed_be(buf[:], -2, 16)
	testing.expect(t, buf[0] == 0xFF && buf[1] == 0xFE)
}

@(test)
test_cross_check :: proc(t: ^testing.T) {
	rand.reset(0xC805)
	for _ in 0..<NUM_RANDOM_TESTS {
		src: [8]byte
		for &x in src { x = byte(rand.uint32()) }
		v := rand.uint64()
		s := src[:]

		testing.expect_value(t, endian.unchecked_get_unsigned_le(s, 8),  u64(src[0]))
		testing.expect_value(t, endian.unchecked_get_unsigned_be(s, 8),  u64(src[0]))
		testing.expect_value(t, endian.unchecked_get_unsigned_le(s, 16), u64(endian.unchecked_get_u16le(s)))
		testing.expect_value(t, endian.unchecked_get_unsigned_le(s, 32), u64(endian.unchecked_get_u32le(s)))
		testing.expect_value(t, endian.unchecked_get_unsigned_le(s, 64), endian.unchecked_get_u64le(s))
		testing.expect_value(t, endian.unchecked_get_unsigned_be(s, 16), u64(endian.unchecked_get_u16be(s)))
		testing.expect_value(t, endian.unchecked_get_unsigned_be(s, 32), u64(endian.unchecked_get_u32be(s)))
		testing.expect_value(t, endian.unchecked_get_unsigned_be(s, 64), endian.unchecked_get_u64be(s))

		testing.expect_value(t, endian.unchecked_get_signed_le(s, 8),  i64(i8(src[0])))
		testing.expect_value(t, endian.unchecked_get_signed_be(s, 8),  i64(i8(src[0])))
		testing.expect_value(t, endian.unchecked_get_signed_le(s, 16), i64(i16(endian.unchecked_get_u16le(s))))
		testing.expect_value(t, endian.unchecked_get_signed_le(s, 32), i64(i32(endian.unchecked_get_u32le(s))))
		testing.expect_value(t, endian.unchecked_get_signed_le(s, 64), i64(endian.unchecked_get_u64le(s)))
		testing.expect_value(t, endian.unchecked_get_signed_be(s, 16), i64(i16(endian.unchecked_get_u16be(s))))
		testing.expect_value(t, endian.unchecked_get_signed_be(s, 32), i64(i32(endian.unchecked_get_u32be(s))))
		testing.expect_value(t, endian.unchecked_get_signed_be(s, 64), i64(endian.unchecked_get_u64be(s)))

		for order in endian.Byte_Order {
			u16v, _ := endian.get_u16(s, order)
			u32v, _ := endian.get_u32(s, order)
			u64v, _ := endian.get_u64(s, order)
			i16v, _ := endian.get_i16(s, order)
			i32v, _ := endian.get_i32(s, order)
			i64v, _ := endian.get_i64(s, order)

			g16, _ := endian.get_unsigned(s, order, 16)
			g32, _ := endian.get_unsigned(s, order, 32)
			g64, _ := endian.get_unsigned(s, order, 64)
			testing.expect_value(t, g16, u64(u16v))
			testing.expect_value(t, g32, u64(u32v))
			testing.expect_value(t, g64, u64v)

			sg16, _ := endian.get_signed(s, order, 16)
			sg32, _ := endian.get_signed(s, order, 32)
			sg64, _ := endian.get_signed(s, order, 64)
			testing.expect_value(t, sg16, i64(i16v))
			testing.expect_value(t, sg32, i64(i32v))
			testing.expect_value(t, sg64, i64v)

			a, b: [8]byte
			endian.put_u16(a[:], order, u16(v));  endian.put_unsigned(b[:], order, v, 16)
			testing.expect(t, a == b)
			a, b = {}, {}
			endian.put_u32(a[:], order, u32(v));  endian.put_unsigned(b[:], order, v, 32)
			testing.expect(t, a == b)
			a, b = {}, {}
			endian.put_u64(a[:], order, v);       endian.put_unsigned(b[:], order, v, 64)
			testing.expect(t, a == b)
			a, b = {}, {}
			endian.put_i16(a[:], order, i16(v));  endian.put_signed(b[:], order, i64(i16(v)), 16)
			testing.expect(t, a == b)
			a, b = {}, {}
			endian.put_i32(a[:], order, i32(v));  endian.put_signed(b[:], order, i64(i32(v)), 32)
			testing.expect(t, a == b)
			a, b = {}, {}
			endian.put_i64(a[:], order, i64(v));  endian.put_signed(b[:], order, i64(v), 64)
			testing.expect(t, a == b)
		}

		a, b: [8]byte
		endian.unchecked_put_u16le(a[:], u16(v)); endian.unchecked_put_unsigned_le(b[:], v, 16)
		testing.expect(t, a == b)
		a, b = {}, {}
		endian.unchecked_put_u32le(a[:], u32(v)); endian.unchecked_put_unsigned_le(b[:], v, 32)
		testing.expect(t, a == b)
		a, b = {}, {}
		endian.unchecked_put_u64le(a[:], v);      endian.unchecked_put_unsigned_le(b[:], v, 64)
		testing.expect(t, a == b)
		a, b = {}, {}
		endian.unchecked_put_u16be(a[:], u16(v)); endian.unchecked_put_unsigned_be(b[:], v, 16)
		testing.expect(t, a == b)
		a, b = {}, {}
		endian.unchecked_put_u32be(a[:], u32(v)); endian.unchecked_put_unsigned_be(b[:], v, 32)
		testing.expect(t, a == b)
		a, b = {}, {}
		endian.unchecked_put_u64be(a[:], v);      endian.unchecked_put_unsigned_be(b[:], v, 64)
		testing.expect(t, a == b)
		a, b = {}, {}
		endian.unchecked_put_u32le(a[:], u32(v)); endian.unchecked_put_signed_le(b[:], i64(i32(v)), 32)
		testing.expect(t, a == b)
		a, b = {}, {}
		endian.unchecked_put_u64be(a[:], v);      endian.unchecked_put_signed_be(b[:], i64(v), 64)
		testing.expect(t, a == b)
	}
}
