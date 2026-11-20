package test_core_varint

import "core:encoding/varint"
import "core:testing"

ILEB_Last_Byte :: struct {
	fill:  u8,
	last:  u8,
	value: i128,
}

ILEB_Valid_Last_Bytes :: []ILEB_Last_Byte{
	{0x80, 0x00, 0},
	{0x80, 0x01, i128(1) << 126},
	{0x80, 0x7e, min(i128)},
	{0x80, 0x7f, -(i128(1) << 126)},
	{0xff, 0x00, i128(1) << 126 - 1},
	{0xff, 0x01, max(i128)},
	{0xff, 0x7e, -(i128(1) << 126) - 1},
	{0xff, 0x7f, -1},
}

@(test)
ileb128_19th_byte_out_of_range :: proc(t: ^testing.T) {
	for fill in ([]u8{0x80, 0xff}) {
		buf: [varint.LEB128_MAX_BYTES]u8
		for &b in buf[:varint.LEB128_MAX_BYTES - 1] {
			b = fill
		}
		for last in 0..<256 {
			buf[varint.LEB128_MAX_BYTES - 1] = u8(last)

			want_val:  i128
			want_size: int
			want_err := varint.Error.Value_Too_Large
			for v in ILEB_Valid_Last_Bytes {
				if v.fill == fill && int(v.last) == last {
					want_val, want_size, want_err = v.value, varint.LEB128_MAX_BYTES, .None
				}
			}

			val, size, err := varint.decode_ileb128(buf[:])
			testing.expectf(t, val == want_val && size == want_size && err == want_err,
				"decode_ileb128(%02x): got %v, %v, %v, want %v, %v, %v", buf, val, size, err, want_val, want_size, want_err)

			acc: i128
			n:   int
			e := varint.Error.Buffer_Too_Small
			for b in buf {
				acc, n, e = varint.decode_ileb128(b, n, acc)
				if e != .Buffer_Too_Small {
					break
				}
			}
			testing.expectf(t, acc == want_val && n == want_size && e == want_err,
				"decode_ileb128 byte at a time (%02x): got %v, %v, %v, want %v, %v, %v", buf, acc, n, e, want_val, want_size, want_err)
		}
	}
}
