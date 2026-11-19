package test_core_pem

import "core:encoding/pem"
import "core:strings"
import "core:testing"

@(private="file")
block_text :: proc(label, body: string, newline := true) -> string {
	return strings.concatenate({"-----BEGIN ", label, "-----\n", body, "-----END ", label, "-----", "\n" if newline else ""}, context.temp_allocator)
}

@(test)
test_review_label_constants :: proc(t: ^testing.T) {
	cases := [?]struct {
		constant, rfc: string,
	}{
		{pem.LABEL_CERTIFICATE,           "CERTIFICATE"},
		{pem.LABEL_X509_CRL,              "X509 CRL"},
		{pem.LABEL_CERTIFICATE_REQUEST,   "CERTIFICATE REQUEST"},
		{pem.LABEL_PKCS7,                 "PKCS7"},
		{pem.LABEL_CMS,                   "CMS"},
		{pem.LABEL_PRIVATE_KEY,           "PRIVATE KEY"},
		{pem.LABEL_ENCRYPTED_PRIVATE_KEY, "ENCRYPTED PRIVATE KEY"},
		{pem.LABEL_ATTRIBUTE_CERTIFICATE, "ATTRIBUTE CERTIFICATE"},
		{pem.LABEL_PUBLIC_KEY,            "PUBLIC KEY"},
	}
	for c in cases {
		testing.expect_value(t, c.constant, c.rfc)

		encoded, enc_err := pem.encode(c.constant, transmute([]byte)string("AAA"))
		defer delete(encoded)
		testing.expectf(t, enc_err == nil, "encode %q: %v", c.constant, enc_err)
		testing.expect_value(t, string(encoded), block_text(c.rfc, "QUFB\n"))

		blk, rest, err := pem.decode(encoded)
		defer pem.block_delete(blk)
		testing.expectf(t, err == nil && blk != nil && len(rest) == 0, "decode %q: %v", c.constant, err)
		if blk != nil {
			testing.expect_value(t, blk.label, c.rfc)
			testing.expect_value(t, string(pem.block_bytes(blk)), "AAA")
		}
	}
}

@(test)
test_review_label_bytes :: proc(t: ^testing.T) {
	for b in 0..<256 {
		middle := [3]byte{'A', byte(b), 'A'}
		alone := [1]byte{byte(b)}
		labels := [?]struct {
			label: string,
			valid: bool,
		}{
			{string(middle[:]), (b >= 0x21 && b <= 0x7e) || b == ' '},
			{string(alone[:]),  b >= 0x21 && b <= 0x7e && b != '-'},
		}
		for l in labels {
			encoded, enc_err := pem.encode(l.label, transmute([]byte)string("AAA"))
			defer delete(encoded)
			if !l.valid {
				testing.expectf(t, encoded == nil && enc_err == .Bad_Label, "encode %q: %v", l.label, enc_err)

				blk, rest, err := pem.decode(transmute([]byte)block_text(l.label, "QUFB\n"))
				testing.expectf(t, blk == nil && rest == nil && err != nil, "decode %q: %v", l.label, err)
				pem.block_delete(blk)
				continue
			}
			testing.expectf(t, enc_err == nil, "encode %q: %v", l.label, enc_err)
			testing.expect_value(t, string(encoded), block_text(l.label, "QUFB\n"))

			blk, rest, err := pem.decode(encoded)
			defer pem.block_delete(blk)
			testing.expectf(t, err == nil && blk != nil && len(rest) == 0, "decode %q: %v", l.label, err)
			if blk != nil {
				testing.expect_value(t, blk.label, l.label)
			}
		}
	}
}

@(test)
test_review_decode_errors :: proc(t: ^testing.T) {
	full := strings.repeat("A", 64, context.temp_allocator)
	long := strings.repeat("A", 68, context.temp_allocator)

	cases := [?]struct {
		input: string,
		err:   pem.Decode_Error,
	}{
		{"-----BEGIN X----\nQUFB\n-----END X-----\n",           .Bad_Boundary},
		{"-----BEGIN X-----\nQUFB\n-----END X----\n",           .Bad_Boundary},
		{"-----BEGIN X-----\nQUFB\n-----END X-----junk\n",      .Bad_Boundary},
		{"-----BEGIN -X-----\nQUFB\n-----END -X-----\n",        .Bad_Label},
		{"-----BEGIN X-----\nQUFB\n-----END -X-----\n",         .Bad_Label},
		{"-----BEGIN X-----\nQU!B\n-----END X-----\n",          .Bad_Data},
		{"-----BEGIN X-----\nQUF\n-----END X-----\n",           .Bad_Data},
		{block_text("X", strings.concatenate({long, "\n"}, context.temp_allocator)), .Bad_Data},
		{"-----BEGIN X-----\nQUFB\n-----END Y-----\n",          .Label_Mismatch},
		{"-----BEGIN X-----\nQUFB\n-----END x-----\n",          .Label_Mismatch},
		{"-----BEGIN X-----",                                   .Missing_End_Boundary},
		{"-----BEGIN X-----\n",                                 .Missing_End_Boundary},
		{"-----BEGIN X-----\nQUFB",                             .Missing_End_Boundary},
		{"-----BEGIN X-----\nQUFB\n",                           .Missing_End_Boundary},
		{"-----BEGIN X-----\nQUFB\ntext\n",                     .Missing_End_Boundary},
		{"-----BEGIN X-----\nQUFB\n-----BEGIN X-----\n",        .Missing_End_Boundary},
		{strings.concatenate({"-----BEGIN X-----\n", full, "\n"}, context.temp_allocator), .Missing_End_Boundary},
	}
	for c in cases {
		for eol in ([]string{"\n", "\r\n", "\r"}) {
			input, _ := strings.replace_all(c.input, "\n", eol, context.temp_allocator)
			blk, rest, err := pem.decode(transmute([]byte)input)
			testing.expectf(t, blk == nil && rest == nil && err == c.err, "%q: got %v, want %v", input, err, c.err)
			pem.block_delete(blk)
		}
	}
}

@(test)
test_review_empty_block :: proc(t: ^testing.T) {
	for newline in ([]bool{true, false}) {
		want := block_text("X", "", newline)
		encoded, enc_err := pem.encode("X", nil, newline)
		defer delete(encoded)
		testing.expectf(t, enc_err == nil, "encode, newline %v: %v", newline, enc_err)
		testing.expect_value(t, string(encoded), want)

		blk, rest, err := pem.decode(transmute([]byte)want)
		defer pem.block_delete(blk)
		testing.expectf(t, err == nil && blk != nil && len(rest) == 0, "decode %q: %v", want, err)
		if blk != nil {
			testing.expect_value(t, blk.label, "X")
			testing.expect_value(t, len(pem.block_bytes(blk)), 0)
		}
	}
}

@(test)
test_review_several_blocks :: proc(t: ^testing.T) {
	input := "head\n-----BEGIN A-----\nQUFB\n-----END A-----\nmiddle\n-----BEGIN B-----\nQkJC\n-----END B-----\ntail\n"
	wants := [?]struct {
		label, data, rest: string,
	}{
		{"A", "AAA", "middle\n-----BEGIN B-----\nQkJC\n-----END B-----\ntail\n"},
		{"B", "BBB", "tail\n"},
	}

	rest := transmute([]byte)input
	for w in wants {
		blk, remaining, err := pem.decode(rest)
		defer pem.block_delete(blk)
		testing.expectf(t, err == nil && blk != nil, "block %s: %v", w.label, err)
		if blk != nil {
			testing.expect_value(t, blk.label, w.label)
			testing.expect_value(t, string(pem.block_bytes(blk)), w.data)
		}
		testing.expect_value(t, string(remaining), w.rest)
		rest = remaining
	}

	blk, remaining, err := pem.decode(rest)
	testing.expect(t, blk == nil && remaining == nil && err == nil)
}

@(test)
test_review_text_before_block :: proc(t: ^testing.T) {
	text := " -----BEGIN X-----\n----BEGIN X-----\n-----BEGINX-----\n-----END X-----\n-----begin X-----\n\n"

	blk, rest, err := pem.decode(transmute([]byte)text)
	testing.expect(t, blk == nil && rest == nil && err == nil)

	input := strings.concatenate({text, block_text("X", "QUFB\n")}, context.temp_allocator)
	blk, rest, err = pem.decode(transmute([]byte)input)
	defer pem.block_delete(blk)
	testing.expectf(t, err == nil && blk != nil && len(rest) == 0, "decode: %v", err)
	if blk != nil {
		testing.expect_value(t, blk.label, "X")
		testing.expect_value(t, string(pem.block_bytes(blk)), "AAA")
	}
}

@(test)
test_review_encode_line_breaks :: proc(t: ^testing.T) {
	data: [145]byte
	full := strings.repeat("A", 64, context.temp_allocator)
	sb := strings.builder_make()
	defer strings.builder_destroy(&sb)

	for n in 0..=len(data) {
		strings.builder_reset(&sb)
		for _ in 0..<n / 48 {
			strings.write_string(&sb, full)
			strings.write_byte(&sb, '\n')
		}
		tail := n % 48
		if tail > 0 {
			for _ in 0..<tail / 3 {
				strings.write_string(&sb, "AAAA")
			}
			switch tail % 3 {
			case 1:
				strings.write_string(&sb, "AA==")
			case 2:
				strings.write_string(&sb, "AAA=")
			}
			strings.write_byte(&sb, '\n')
		}
		want := block_text("X", strings.to_string(sb))

		encoded, enc_err := pem.encode("X", data[:n])
		defer delete(encoded)
		testing.expectf(t, enc_err == nil && string(encoded) == want, "encode %i bytes: %v %q, want %q", n, enc_err, string(encoded), want)

		blk, rest, err := pem.decode(transmute([]byte)want)
		defer pem.block_delete(blk)
		testing.expectf(t, err == nil && blk != nil && len(rest) == 0, "decode %i bytes: %v", n, err)
		if blk != nil {
			testing.expectf(t, string(pem.block_bytes(blk)) == string(data[:n]), "decode %i bytes: %v", n, pem.block_bytes(blk))
		}
	}
}
