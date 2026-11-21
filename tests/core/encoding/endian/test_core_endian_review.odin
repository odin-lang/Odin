package test_core_endian

import "core:encoding/endian"
import "core:math/rand"
import "core:testing"

@(test)
test_review_unaligned_fixed :: proc(t: ^testing.T) {
	rand.reset(0xE4D1A5)
	for _ in 0..<NUM_RANDOM_TESTS {
		v := rand.uint64()
		for off in 0..<8 {
			for order in endian.Byte_Order {
				for size in ([]int{2, 4, 8}) {
					backing: [24]byte
					for &x in backing { x = SENTINEL }
					expected := backing
					ref_put_unsigned(expected[off:][:size], order, v, size)
					b := backing[off:][:size]

					ok: bool
					switch size {
					case 2: ok = endian.put_u16(b, order, u16(v))
					case 4: ok = endian.put_u32(b, order, u32(v))
					case 8: ok = endian.put_u64(b, order, v)
					}
					testing.expectf(t, ok && backing == expected, "put size %d off %d %v: %x, want %x", size, off, order, backing, expected)

					want := ref_get_unsigned(b, order, size)
					got: u64
					switch size {
					case 2: r, rok := endian.get_u16(b, order); got = u64(r); ok = rok
					case 4: r, rok := endian.get_u32(b, order); got = u64(r); ok = rok
					case 8: got, ok = endian.get_u64(b, order)
					}
					testing.expectf(t, ok && got == want, "get size %d off %d %v: %x, want %x", size, off, order, got, want)

					unchecked: u64
					switch {
					case size == 2 && order == .Little: unchecked = u64(endian.unchecked_get_u16le(b))
					case size == 2 && order == .Big:    unchecked = u64(endian.unchecked_get_u16be(b))
					case size == 4 && order == .Little: unchecked = u64(endian.unchecked_get_u32le(b))
					case size == 4 && order == .Big:    unchecked = u64(endian.unchecked_get_u32be(b))
					case size == 8 && order == .Little: unchecked = endian.unchecked_get_u64le(b)
					case size == 8 && order == .Big:    unchecked = endian.unchecked_get_u64be(b)
					}
					testing.expectf(t, unchecked == want, "unchecked get size %d off %d %v: %x, want %x", size, off, order, unchecked, want)
				}
			}
		}
	}
}

check_unaligned_generic :: proc(t: ^testing.T, $N: int) {
	BYTES :: N / 8
	rand.reset(u64(N) + 0x100)
	for _ in 0..<NUM_RANDOM_TESTS / 10 {
		v := rand.uint64()
		for off in 0..<8 {
			for order in endian.Byte_Order {
				backing: [24]byte
				for &x in backing { x = SENTINEL }
				expected := backing
				ref_put_unsigned(expected[off:][:BYTES], order, v, BYTES)
				b := backing[off:][:BYTES]

				testing.expectf(t, endian.put_unsigned(b, order, v, N) && backing == expected, "N=%v off %d %v put_unsigned: %x, want %x", N, off, order, backing, expected)
				for &x in backing { x = SENTINEL }
				testing.expectf(t, endian.put_signed(b, order, i64(v), N) && backing == expected, "N=%v off %d %v put_signed: %x, want %x", N, off, order, backing, expected)

				want := ref_get_unsigned(b, order, BYTES)
				u, uok := endian.get_unsigned(b, order, N)
				testing.expectf(t, uok && u == want, "N=%v off %d %v get_unsigned: %x, want %x", N, off, order, u, want)
				s, sok := endian.get_signed(b, order, N)
				testing.expectf(t, sok && s == ref_get_signed(b, order, BYTES), "N=%v off %d %v get_signed: %x", N, off, order, s)
			}
		}
	}
}

@(test) test_review_unaligned_generic_8  :: proc(t: ^testing.T) { check_unaligned_generic(t, 8)  }
@(test) test_review_unaligned_generic_24 :: proc(t: ^testing.T) { check_unaligned_generic(t, 24) }
@(test) test_review_unaligned_generic_40 :: proc(t: ^testing.T) { check_unaligned_generic(t, 40) }
@(test) test_review_unaligned_generic_56 :: proc(t: ^testing.T) { check_unaligned_generic(t, 56) }
@(test) test_review_unaligned_generic_64 :: proc(t: ^testing.T) { check_unaligned_generic(t, 64) }

@(test)
test_review_float_bits :: proc(t: ^testing.T) {
	f16s := []f16{0h0000, 0h8000, 0h7c00, 0hfc00, 0h0001, 0h83ff, 0h7e00, 0h7c01, 0hfd55}
	f32s := []f32{0h00000000, 0h80000000, 0h7f800000, 0hff800000, 0h00000001, 0h807fffff, 0h7fc00000, 0h7f800001, 0hffa5a5a5}
	f64s := []f64{
		0h0000000000000000, 0h8000000000000000, 0h7ff0000000000000, 0hfff0000000000000, 0h0000000000000001,
		0h800fffffffffffff, 0h7ff8000000000000, 0h7ff0000000000001, 0hfff5a5a5a5a5a5a5,
	}
	for order in endian.Byte_Order {
		for f in f16s {
			bits := u64(transmute(u16)f)
			buf, want: [2]byte
			ref_put_unsigned(want[:], order, bits, 2)
			testing.expectf(t, endian.put_f16(buf[:], order, f) && buf == want, "put_f16 %4x %v: %x", bits, order, buf)
			g, ok := endian.get_f16(want[:], order)
			testing.expectf(t, ok && u64(transmute(u16)g) == bits, "get_f16 %4x %v: %4x", bits, order, transmute(u16)g)
		}
		for f in f32s {
			bits := u64(transmute(u32)f)
			buf, want: [4]byte
			ref_put_unsigned(want[:], order, bits, 4)
			testing.expectf(t, endian.put_f32(buf[:], order, f) && buf == want, "put_f32 %8x %v: %x", bits, order, buf)
			g, ok := endian.get_f32(want[:], order)
			testing.expectf(t, ok && u64(transmute(u32)g) == bits, "get_f32 %8x %v: %8x", bits, order, transmute(u32)g)
		}
		for f in f64s {
			bits := transmute(u64)f
			buf, want: [8]byte
			ref_put_unsigned(want[:], order, bits, 8)
			testing.expectf(t, endian.put_f64(buf[:], order, f) && buf == want, "put_f64 %16x %v: %x", bits, order, buf)
			g, ok := endian.get_f64(want[:], order)
			testing.expectf(t, ok && transmute(u64)g == bits, "get_f64 %16x %v: %16x", bits, order, transmute(u64)g)
		}
	}
}

@(test)
test_review_platform_byte_order :: proc(t: ^testing.T) {
	native := transmute([4]byte)u32(0x11223344)
	v, ok := endian.get_u32(native[:], endian.PLATFORM_BYTE_ORDER)
	testing.expect(t, ok && v == 0x11223344)
	when ODIN_ENDIAN == .Little {
		testing.expect_value(t, endian.PLATFORM_BYTE_ORDER, endian.Byte_Order.Little)
	} else {
		testing.expect_value(t, endian.PLATFORM_BYTE_ORDER, endian.Byte_Order.Big)
	}
}

@(test)
test_review_doc_example :: proc(t: ^testing.T) {
	example :: proc() -> (file_order: endian.Byte_Order, first, second: u16, ok: bool) {
		buf: [100]u8
		endian.put_u16(buf[:], .Little, 16) or_return

		file_order = .Little if buf[0] == 0 else .Big
		first = endian.get_u16(buf[1:], file_order) or_return

		second = endian.get_u16(buf[:], .Big) or_return
		return file_order, first, second, true
	}
	file_order, first, second, ok := example()
	testing.expect(t, ok)
	testing.expect_value(t, file_order, endian.Byte_Order.Big)
	testing.expect_value(t, first, 0)
	testing.expect_value(t, second, 0x1000)
}
