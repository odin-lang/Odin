package test_encoding_base32

import "core:encoding/base32"
import "core:strings"
import "core:testing"

@(private="file")
Alphabet :: struct {
	name:    string,
	symbols: string,
	enc:     [32]byte,
	dec:     [256]i8,
}

@(private="file")
alphabets :: proc() -> [2]Alphabet {
	return {
		{"standard",     "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567", base32.ENC_TABLE,     base32.DEC_TABLE},
		{"extended hex", "0123456789ABCDEFGHIJKLMNOPQRSTUV", base32.ENC_HEX_TABLE, base32.DEC_HEX_TABLE},
	}
}

@(private="file")
reference_encode :: proc(sb: ^strings.Builder, data: []byte, symbols: string, pad: bool) -> string {
	strings.builder_reset(sb)
	bits: u64
	count: uint
	for b in data {
		bits = (bits << 8) | u64(b)
		count += 8
		for count >= 5 {
			count -= 5
			strings.write_byte(sb, symbols[(bits >> count) & 31])
		}
	}
	if count > 0 {
		strings.write_byte(sb, symbols[(bits << (5 - count)) & 31])
	}
	for pad && strings.builder_len(sb^) % 8 != 0 {
		strings.write_byte(sb, base32.PADDING)
	}
	return strings.to_string(sb^)
}

@(test)
test_review_tables :: proc(t: ^testing.T) {
	list := alphabets()
	for &a in list {
		testing.expectf(t, string(a.enc[:]) == a.symbols, "%s encoding table: %q", a.name, string(a.enc[:]))
		for c in 0..<256 {
			want := i8(strings.index_byte(a.symbols, byte(c)))
			testing.expectf(t, a.dec[c] == want, "%s decoding table[%i]: got %i, want %i", a.name, c, a.dec[c], want)
		}
	}
}

@(test)
test_review_every_length :: proc(t: ^testing.T) {
	data: [40]byte
	for &b, i in data {
		b = byte(i * 73 + 41)
	}

	reference := strings.builder_make()
	defer strings.builder_destroy(&reference)
	out := strings.builder_make()
	defer strings.builder_destroy(&out)
	buf: [64]byte

	padded_options   := [?]base32.Decode_Options{{}, {.Strict}}
	unpadded_options := [?]base32.Decode_Options{{}, {.No_Padding}, {.Strict, .No_Padding}}

	list := alphabets()
	for &a in list {
		for n in 0..=len(data) {
			plain := data[:n]
			for pad in ([]bool{true, false}) {
				want := reference_encode(&reference, plain, a.symbols, pad)
				enc_options := base32.Encode_Options{} if pad else {.No_Padding}

				testing.expectf(t, base32.encoded_len(plain, enc_options) == len(want),
					"%s, %i bytes, padded %v: encoded_len %i, want %i", a.name, n, pad, base32.encoded_len(plain, enc_options), len(want))

				encoded := base32.encode(plain, a.enc, options = enc_options)
				testing.expectf(t, encoded == want, "%s, %i bytes, padded %v: encode gave %q, want %q", a.name, n, pad, encoded, want)
				delete(encoded)

				into_buf, buf_err := base32.encode_into_buf(buf[:], plain, a.enc, enc_options)
				testing.expectf(t, buf_err == nil && string(into_buf) == want,
					"%s, %i bytes, padded %v: encode_into_buf gave %v %q, want %q", a.name, n, pad, buf_err, string(into_buf), want)

				strings.builder_reset(&out)
				w_err := base32.encode_into(strings.to_writer(&out), plain, a.enc, enc_options)
				testing.expectf(t, w_err == .None && strings.to_string(out) == want,
					"%s, %i bytes, padded %v: encode_into gave %v %q, want %q", a.name, n, pad, w_err, strings.to_string(out), want)

				options_list := padded_options[:] if pad else unpadded_options[:]
				for options in options_list {
					length, len_err := base32.decoded_len(want, a.dec, options)
					testing.expectf(t, len_err == .None && length == n,
						"%s, decoded_len(%q, %v): %v %i, want %i", a.name, want, options, len_err, length, n)

					decoded, err := base32.decode(want, a.dec, options = options)
					testing.expectf(t, err == nil && string(decoded) == string(plain),
						"%s, decode(%q, %v): %v %v, want %v", a.name, want, options, err, decoded, plain)
					delete(decoded)

					into, into_err := base32.decode_into_buf(buf[:n], want, a.dec, options)
					testing.expectf(t, into_err == nil && string(into) == string(plain),
						"%s, decode_into_buf(%q, %v): %v %v, want %v", a.name, want, options, into_err, into, plain)

					strings.builder_reset(&out)
					dw_err := base32.decode_into(strings.to_writer(&out), want, a.dec, options)
					testing.expectf(t, dw_err == nil && strings.to_string(out) == string(plain),
						"%s, decode_into(%q, %v): %v %q, want %v", a.name, want, options, dw_err, strings.to_string(out), plain)
				}
			}
		}
	}
}

@(test)
test_review_every_symbol_in_every_position :: proc(t: ^testing.T) {
	list := alphabets()
	for &a in list {
		for pos in 0..<8 {
			for v in 0..<32 {
				bits := u64(v) << uint(35 - 5 * pos)
				plain: [5]byte
				for &b, i in plain {
					b = byte(bits >> uint(32 - 8 * i))
				}
				want: [8]byte
				for &c in want {
					c = a.symbols[0]
				}
				want[pos] = a.symbols[v]

				encoded := base32.encode(plain[:], a.enc)
				testing.expectf(t, encoded == string(want[:]),
					"%s, symbol %i at %i: encode gave %q, want %q", a.name, v, pos, encoded, string(want[:]))
				delete(encoded)

				decoded, err := base32.decode(string(want[:]), a.dec, options = {.Strict})
				testing.expectf(t, err == nil && string(decoded) == string(plain[:]),
					"%s, decode(%q): %v %v, want %v", a.name, string(want[:]), err, decoded, plain)
				delete(decoded)
			}
		}
	}
}

@(test)
test_review_invalid_bytes :: proc(t: ^testing.T) {
	list := alphabets()
	for &a in list {
		for c in 0..<256 {
			if c == base32.PADDING || strings.index_byte(a.symbols, byte(c)) >= 0 {
				continue
			}
			for pos in 0..<8 {
				src: [8]byte
				for &s in src {
					s = a.symbols[0]
				}
				src[pos] = byte(c)
				for options in ([]base32.Decode_Options{{}, {.Strict}}) {
					decoded, err := base32.decode(string(src[:]), a.dec, options = options)
					testing.expectf(t, err == base32.Decode_Error.Invalid_Character,
						"%s, byte %i at %i, %v: got %v", a.name, c, pos, options, err)
					delete(decoded)
				}
			}
		}

		for pos in 0..<7 {
			src: [8]byte
			for &s in src {
				s = a.symbols[0]
			}
			src[pos] = base32.PADDING
			for options in ([]base32.Decode_Options{{}, {.Strict}}) {
				decoded, err := base32.decode(string(src[:]), a.dec, options = options)
				testing.expectf(t, err == base32.Decode_Error.Invalid_Padding,
					"%s, decode(%q, %v): got %v", a.name, string(src[:]), options, err)
				delete(decoded)
			}
		}
	}
}

@(test)
test_review_trailing_bits :: proc(t: ^testing.T) {
	cases := [?]struct {
		symbols, unused, bytes: int,
	}{
		{2, 2, 1},
		{4, 4, 2},
		{5, 1, 3},
		{7, 3, 4},
	}

	list := alphabets()
	for &a in list {
		for c in cases {
			mask := (1 << uint(c.unused)) - 1
			for v in 0..<32 {
				src: [8]byte
				for &s in src {
					s = base32.PADDING
				}
				for i in 0..<c.symbols - 1 {
					src[i] = a.symbols[0]
				}
				src[c.symbols - 1] = a.symbols[v]
				canonical := src
				canonical[c.symbols - 1] = a.symbols[v &~ mask]

				want, want_err := base32.decode(string(canonical[:]), a.dec, options = {.Strict})
				testing.expectf(t, want_err == nil && len(want) == c.bytes,
					"%s, decode(%q, {{.Strict}}): %v %v", a.name, string(canonical[:]), want_err, want)

				lenient, lenient_err := base32.decode(string(src[:]), a.dec)
				testing.expectf(t, lenient_err == nil && string(lenient) == string(want),
					"%s, decode(%q): %v %v, want %v", a.name, string(src[:]), lenient_err, lenient, want)

				strict, strict_err := base32.decode(string(src[:]), a.dec, options = {.Strict})
				if v & mask == 0 {
					testing.expectf(t, strict_err == nil && string(strict) == string(want),
						"%s, decode(%q, {{.Strict}}): %v %v, want %v", a.name, string(src[:]), strict_err, strict, want)
				} else {
					testing.expectf(t, strict_err == base32.Decode_Error.Non_Canonical,
						"%s, decode(%q, {{.Strict}}): got %v", a.name, string(src[:]), strict_err)
				}

				delete(want)
				delete(lenient)
				delete(strict)
			}
		}
	}
}
