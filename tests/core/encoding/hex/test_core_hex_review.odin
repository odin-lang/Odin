package test_core_hex

import "core:encoding/hex"
import "core:fmt"
import "core:strings"
import "core:testing"

@(private="file")
DIGITS := "0123456789abcdefABCDEF"

@(private="file")
ref_digit :: proc(c: byte) -> int {
	i := strings.index_byte(DIGITS, c)
	if i < 16 {
		return i
	}
	return i - 6
}

@(private="file")
every_byte :: proc() -> (all: [256]byte) {
	for &b, i in all {
		b = byte(i)
	}
	return
}

@(test)
test_review_encode_every_byte :: proc(t: ^testing.T) {
	all := every_byte()
	want_lower := strings.builder_make()
	defer strings.builder_destroy(&want_lower)
	want_upper := strings.builder_make()
	defer strings.builder_destroy(&want_upper)
	for b in all {
		fmt.sbprintf(&want_lower, "%02x", b)
		fmt.sbprintf(&want_upper, "%02X", b)
	}

	lower := hex.encode(all[:])
	defer delete(lower)
	testing.expect_value(t, string(lower), strings.to_string(want_lower))
	upper := hex.encode_upper(all[:])
	defer delete(upper)
	testing.expect_value(t, string(upper), strings.to_string(want_upper))

	sb := strings.builder_make()
	defer strings.builder_destroy(&sb)
	err := hex.encode_into_writer(strings.to_writer(&sb), all[:])
	testing.expect(t, err == .None && strings.to_string(sb) == strings.to_string(want_lower), "encode_into_writer")
	strings.builder_reset(&sb)
	err = hex.encode_upper_into_writer(strings.to_writer(&sb), all[:])
	testing.expect(t, err == .None && strings.to_string(sb) == strings.to_string(want_upper), "encode_upper_into_writer")
}

@(test)
test_review_empty_input :: proc(t: ^testing.T) {
	enc, enc_err := hex.encode(nil)
	testing.expect(t, len(enc) == 0 && enc_err == .None, "encode(nil)")
	enc, enc_err = hex.encode_upper(nil)
	testing.expect(t, len(enc) == 0 && enc_err == .None, "encode_upper(nil)")

	sb := strings.builder_make()
	defer strings.builder_destroy(&sb)
	testing.expect(t, hex.encode_into_writer(strings.to_writer(&sb), nil) == .None, "encode_into_writer(nil)")
	testing.expect(t, hex.encode_upper_into_writer(strings.to_writer(&sb), nil) == .None, "encode_upper_into_writer(nil)")
	testing.expect(t, strings.builder_len(sb) == 0, "the writer procs wrote for empty input")

	dec, dec_err := hex.decode(nil)
	testing.expect(t, len(dec) == 0 && dec_err == nil, "decode(nil)")
	buf, ok := hex.decode_into_buffer(nil, nil)
	testing.expect(t, len(buf) == 0 && ok, "decode_into_buffer(nil, nil)")
	_, ok = hex.decode_sequence("")
	testing.expect(t, !ok, "decode_sequence(\"\")")
}

@(test)
test_review_decode_every_byte :: proc(t: ^testing.T) {
	all := every_byte()
	lower := hex.encode(all[:])
	defer delete(lower)
	upper := hex.encode_upper(all[:])
	defer delete(upper)
	mixed := make([]byte, len(lower))
	defer delete(mixed)
	for i in 0..<len(mixed) {
		mixed[i] = lower[i] if i % 3 == 0 else upper[i]
	}

	for src in ([][]byte{lower, upper, mixed}) {
		dec, err := hex.decode(src)
		testing.expectf(t, err == nil && string(dec) == string(all[:]), "decode(%s): %v", src, err)
		delete(dec)

		buf: [256]byte
		got, ok := hex.decode_into_buffer(src, buf[:])
		testing.expectf(t, ok && string(got) == string(all[:]), "decode_into_buffer(%s): %v", src, ok)
	}
}

@(test)
test_review_decode_invalid_characters :: proc(t: ^testing.T) {
	for c in 0..<256 {
		if ref_digit(byte(c)) >= 0 {
			continue
		}
		for pos in 0..<4 {
			src := [4]byte{'4', '1', '4', '2'}
			src[pos] = byte(c)

			dec, err := hex.decode(src[:])
			testing.expectf(t, err == hex.Decode_Error.Invalid_Character && dec == nil, "decode(%q): %v", src[:], err)
			delete(dec)

			buf := [2]byte{'X', 'X'}
			got, ok := hex.decode_into_buffer(src[:], buf[:])
			want_buf := "XX" if pos < 2 else "AX"
			testing.expectf(t, !ok && got == nil && string(buf[:]) == want_buf, "decode_into_buffer(%q): %v, buffer %q", src[:], ok, buf[:])
		}
	}
}

@(test)
test_review_decode_into_buffer :: proc(t: ^testing.T) {
	even := "414243"
	odd := "41424"
	buf := [4]byte{'X', 'X', 'X', 'X'}

	got, ok := hex.decode_into_buffer(transmute([]byte)odd, buf[:])
	testing.expect(t, !ok && got == nil && string(buf[:]) == "XXXX", "odd length")

	got, ok = hex.decode_into_buffer(transmute([]byte)even, buf[:2])
	testing.expect(t, !ok && got == nil && string(buf[:]) == "XXXX", "buffer one byte short")

	got, ok = hex.decode_into_buffer(transmute([]byte)even, buf[:])
	testing.expect(t, ok && string(got) == "ABC", "larger buffer")
	testing.expect(t, raw_data(got) == raw_data(buf[:]), "the result isn't a slice of the buffer")
	testing.expect(t, buf[3] == 'X', "the buffer's tail was written")

	in_place := [6]byte{'6', '1', '6', '2', '6', '3'}
	got, ok = hex.decode_into_buffer(in_place[:], in_place[:])
	testing.expect(t, ok && string(got) == "abc", "in place")
}

@(test)
test_review_decode_sequence :: proc(t: ^testing.T) {
	for hi in 0..<256 {
		for lo in 0..<256 {
			a := ref_digit(byte(hi))
			b := ref_digit(byte(lo))
			want_ok := a >= 0 && b >= 0
			s := [4]byte{'0', 'x', byte(hi), byte(lo)}
			for prefix in ([]byte{'x', 'X'}) {
				s[1] = prefix
				for str in ([]string{string(s[2:]), string(s[:])}) {
					got, ok := hex.decode_sequence(str)
					testing.expectf(t, ok == want_ok && (!ok || int(got) == a * 16 + b), "decode_sequence(%q): %x, %v", str, got, ok)
				}
			}
		}
	}

	for str in ([]string{"0", "0x", "0X", "0x0", "0x123", "123", "x23", "0x0x", " 23", "23 ", "+1"}) {
		_, ok := hex.decode_sequence(str)
		testing.expectf(t, !ok, "decode_sequence(%q) should fail", str)
	}
}
