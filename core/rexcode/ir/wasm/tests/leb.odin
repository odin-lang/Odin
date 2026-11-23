package rexcode_wasm_tests

import "core:math/rand"
import "core:slice"
import "core:testing"
import wasm ".."

@(test)
test_leb_width_limits :: proc(t: ^testing.T) {
	Case :: struct {
		bytes:  []u8,
		bits:   uint,
		signed: bool,
		ok:     bool,
		value:  u64,
	}
	cases := [?]Case{
		{{0x80, 0x80, 0x80, 0x80, 0x00}, 32, false, true, 0},
		{{0xff, 0xff, 0xff, 0xff, 0x0f}, 32, false, true, 0xffff_ffff},
		{{0xff, 0xff, 0xff, 0xff, 0x1f}, 32, false, false, 0},
		{{0x80, 0x80, 0x80, 0x80, 0x80, 0x00}, 32, false, false, 0},
		{{0x80}, 32, false, false, 0},
		{{}, 32, false, false, 0},
		{{0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x01}, 64, false, true, max(u64)},
		{{0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x02}, 64, false, false, 0},
		{{0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x00}, 64, false, false, 0},
		{{0xff, 0xff, 0xff, 0xff, 0x07}, 32, true, true, u64(max(i32))},
		{{0x80, 0x80, 0x80, 0x80, 0x78}, 32, true, true, transmute(u64)i64(min(i32))},
		{{0xff, 0xff, 0xff, 0xff, 0x0f}, 32, true, false, 0},
		{{0x80, 0x80, 0x80, 0x80, 0x70}, 32, true, false, 0},
		{{0x7f}, 32, true, true, max(u64)},
		{{0xff, 0xff, 0xff, 0xff, 0x7f}, 32, true, true, max(u64)},
		{{0x80, 0x80, 0x80, 0x80, 0x00}, 32, true, true, 0},
		{{0xff, 0xff, 0xff, 0xff, 0x0f}, 33, true, true, 0xffff_ffff},
		{{0x80, 0x80, 0x80, 0x80, 0x70}, 33, true, true, transmute(u64)i64(-1 << 32)},
		{{0xff, 0xff, 0xff, 0xff, 0x1f}, 33, true, false, 0},
		{{0x80, 0x80, 0x80, 0x80, 0x20}, 33, true, false, 0},
		{{0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x00}, 64, true, true, u64(max(i64))},
		{{0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x7f}, 64, true, true, transmute(u64)min(i64)},
		{{0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x01}, 64, true, false, 0},
		{{0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x40}, 64, true, false, 0},
	}
	for c in cases {
		off: u32
		value: u64
		ok: bool
		if c.signed {
			v: i64
			v, ok = wasm.read_sleb(c.bytes, &off, c.bits)
			value = u64(v)
		} else {
			value, ok = wasm.read_uleb(c.bytes, &off, c.bits)
		}
		testing.expectf(t, ok == c.ok, "% x as %s%d: ok = %v, want %v", c.bytes, "s" if c.signed else "u", c.bits, ok, c.ok)
		if ok && c.ok {
			testing.expectf(t, value == c.value, "% x as %s%d: %x, want %x", c.bytes, "s" if c.signed else "u", c.bits, value, c.value)
			testing.expectf(t, off == u32(len(c.bytes)), "% x as %s%d: consumed %d bytes", c.bytes, "s" if c.signed else "u", c.bits, off)
		}
	}
}

@(test)
test_leb_against_reference :: proc(t: ^testing.T) {
	widths := [?]uint{32, 33, 64}
	for _ in 0..<100_000 {
		bits := widths[rand.int_max(len(widths))]
		raw := rand.uint64() >> uint(rand.int_max(64))

		if bits != 33 {
			u := raw if bits == 64 else raw & 0xffff_ffff
			check_uleb(t, u, bits)
			if bits == 32 {
				wide := u | 1 << 32
				off: u32
				_, ok := wasm.read_uleb(ref_uleb(wide, 0), &off, 32)
				testing.expectf(t, !ok, "%x read as u32", wide)
			}
		}

		s := i64(raw)
		if rand.int_max(2) == 1 {
			s = -s - 1
		}
		if bits < 64 {
			lo, hi := -(i64(1) << (bits - 1)), (i64(1) << (bits - 1)) - 1
			if s < lo || s > hi {
				off: u32
				_, ok := wasm.read_sleb(ref_sleb(s, 0), &off, bits)
				testing.expectf(t, !ok, "%d read as s%d", s, bits)
				s = s % (hi + 1)
			}
		}
		check_sleb(t, s, bits)
	}
}

@(private="file")
check_uleb :: proc(t: ^testing.T, v: u64, bits: uint) {
	min_bytes := ref_uleb(v, 0)
	buf: [16]u8
	off: u32
	wasm.write_uleb(buf[:], &off, v)
	testing.expectf(t, slice.equal(buf[:off], min_bytes), "write_uleb(%x) = % x, want % x", v, buf[:off], min_bytes)
	testing.expectf(t, wasm.uleb_size(v) == u32(len(min_bytes)), "uleb_size(%x) = %d", v, wasm.uleb_size(v))

	max_bytes := int((bits + 6) / 7)
	for n in len(min_bytes)..=max_bytes {
		b := ref_uleb(v, n)
		roff: u32
		got, ok := wasm.read_uleb(b, &roff, bits)
		testing.expectf(t, ok && got == v && roff == u32(n), "read_uleb(% x, %d) = %x, %v", b, bits, got, ok)
	}
	over := ref_uleb(v, max_bytes + 1)
	roff: u32
	_, ok := wasm.read_uleb(over, &roff, bits)
	testing.expectf(t, !ok, "read_uleb(% x, %d) accepted %d bytes", over, bits, len(over))
}

@(private="file")
check_sleb :: proc(t: ^testing.T, v: i64, bits: uint) {
	min_bytes := ref_sleb(v, 0)
	buf: [16]u8
	off: u32
	wasm.write_sleb(buf[:], &off, v)
	testing.expectf(t, slice.equal(buf[:off], min_bytes), "write_sleb(%d) = % x, want % x", v, buf[:off], min_bytes)
	testing.expectf(t, wasm.sleb_size(v) == u32(len(min_bytes)), "sleb_size(%d) = %d", v, wasm.sleb_size(v))

	max_bytes := int((bits + 6) / 7)
	for n in len(min_bytes)..=max_bytes {
		b := ref_sleb(v, n)
		roff: u32
		got, ok := wasm.read_sleb(b, &roff, bits)
		testing.expectf(t, ok && got == v && roff == u32(n), "read_sleb(% x, %d) = %d, %v", b, bits, got, ok)
	}
	over := ref_sleb(v, max_bytes + 1)
	roff: u32
	_, ok := wasm.read_sleb(over, &roff, bits)
	testing.expectf(t, !ok, "read_sleb(% x, %d) accepted %d bytes", over, bits, len(over))
}

@(private="file")
ref_uleb :: proc(v: u64, pad_to: int) -> []u8 {
	out := make([dynamic]u8, context.temp_allocator)
	v := v
	for {
		b := u8(v & 0x7f)
		v >>= 7
		append(&out, b)
		if v == 0 {
			break
		}
	}
	for len(out) < pad_to {
		append(&out, 0)
	}
	for i in 0..<len(out) - 1 {
		out[i] |= 0x80
	}
	return out[:]
}

@(private="file")
ref_sleb :: proc(v: i64, pad_to: int) -> []u8 {
	out := make([dynamic]u8, context.temp_allocator)
	v := v
	for {
		b := u8(v & 0x7f)
		v >>= 7
		append(&out, b)
		if (v == 0 && b & 0x40 == 0) || (v == -1 && b & 0x40 != 0) {
			break
		}
	}
	fill: u8 = 0x7f if v < 0 else 0
	for len(out) < pad_to {
		append(&out, fill)
	}
	for i in 0..<len(out) - 1 {
		out[i] |= 0x80
	}
	return out[:]
}
