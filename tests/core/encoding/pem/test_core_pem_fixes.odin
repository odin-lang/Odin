package test_core_pem

import "base:runtime"
import "core:bytes"
import "core:encoding/pem"
import "core:strings"
import "core:testing"

@(private="file")
Counting :: struct {
	backing: runtime.Allocator,
	allocs:  int,
	resizes: int,
	budget:  int,
}

@(private="file")
counting_proc :: proc(allocator_data: rawptr, mode: runtime.Allocator_Mode, size, alignment: int, old_memory: rawptr, old_size: int, loc := #caller_location) -> ([]byte, runtime.Allocator_Error) {
	c := (^Counting)(allocator_data)
	#partial switch mode {
	case .Alloc, .Alloc_Non_Zeroed:
		if c.allocs + c.resizes >= c.budget {
			return nil, .Out_Of_Memory
		}
		c.allocs += 1
	case .Resize, .Resize_Non_Zeroed:
		if c.allocs + c.resizes >= c.budget {
			return nil, .Out_Of_Memory
		}
		c.resizes += 1
	}
	return c.backing.procedure(c.backing.data, mode, size, alignment, old_memory, old_size, loc)
}

@(private="file")
counting_allocator :: proc(c: ^Counting) -> runtime.Allocator {
	return runtime.Allocator{counting_proc, c}
}

@(private="file")
wrap :: proc(label, body: string) -> []byte {
	s := strings.concatenate({"-----BEGIN ", label, "-----\n", body, "-----END ", label, "-----\n"}, context.temp_allocator)
	return transmute([]byte)s
}

@(test)
test_fix_x509_crl_label :: proc(t: ^testing.T) {
	testing.expect_value(t, pem.LABEL_X509_CRL, "X509 CRL")

	blk, _, err := pem.decode(wrap("X509 CRL", "QUFB\n"))
	defer pem.block_delete(blk)
	testing.expectf(t, err == nil, "decode failed: %v", err)
	if blk != nil {
		testing.expect_value(t, blk.label, pem.LABEL_X509_CRL)
	}
}

@(test)
test_fix_single_allocation :: proc(t: ^testing.T) {
	data := make([]byte, 4096)
	defer delete(data)
	for &b, i in data {
		b = byte(i * 7 + 1)
	}

	c := Counting{backing = context.allocator, budget = max(int)}
	encoded, enc_err := pem.encode(pem.LABEL_PRIVATE_KEY, data, allocator = counting_allocator(&c))
	defer delete(encoded)
	testing.expectf(t, enc_err == nil, "encode failed: %v", enc_err)
	testing.expect_value(t, c.allocs, 1)
	testing.expect_value(t, c.resizes, 0)

	c.allocs = 0
	blk, rest, dec_err := pem.decode(encoded, counting_allocator(&c))
	defer pem.block_delete(blk)
	testing.expectf(t, dec_err == nil, "decode failed: %v", dec_err)
	testing.expect_value(t, len(rest), 0)
	testing.expect_value(t, c.allocs, 3)
	testing.expect_value(t, c.resizes, 0)
	if blk != nil {
		testing.expect(t, bytes.equal(pem.block_bytes(blk), data))
	}
}

@(test)
test_fix_strict_base64 :: proc(t: ^testing.T) {
	full_padded := strings.concatenate({strings.repeat("A", 62, context.temp_allocator), "==\n"}, context.temp_allocator)

	cases := [?]struct {
		body: string,
		err:  pem.Decode_Error,
	}{
		{"AAAA====\n", .Bad_Data},
		{"====\n", .Bad_Data},
		{"AB==\n", .Bad_Data},
		{"AAA=AAAA\n", .Bad_Data},
		{"QUFB \n", .Bad_Data},
		{"\nQUFB\n", .Bad_Data},
		{strings.concatenate({full_padded, "QUFB\n"}, context.temp_allocator), .Missing_End_Boundary},
	}
	for c in cases {
		blk, rest, err := pem.decode(wrap("X", c.body))
		testing.expectf(t, blk == nil && rest == nil && err == c.err, "%q: got %v, want %v", c.body, err, c.err)
		pem.block_delete(blk)
	}

	blk, rest, err := pem.decode(wrap("X", full_padded))
	defer pem.block_delete(blk)
	testing.expectf(t, err == nil && len(rest) == 0, "padded full last line: %v", err)
	if blk != nil {
		testing.expect_value(t, len(blk.data), 46)
	}
}

@(test)
test_fix_label_grammar :: proc(t: ^testing.T) {
	bad := [?]string{"A--B", "A  B", "A- B", "A-----B", " A", "A ", "-A", "A-", "A\tB", "é", "A\n-----END A-----\nQUFB\n-----BEGIN A"}
	for label in bad {
		blk, rest, err := pem.decode(wrap(label, "QUFB\n"))
		testing.expectf(t, blk == nil && rest == nil && err != nil, "decode %q: %v", label, err)
		pem.block_delete(blk)

		res, enc_err := pem.encode(label, transmute([]byte)string("AAA"))
		testing.expectf(t, res == nil && enc_err == .Bad_Label, "encode %q: %v", label, enc_err)
	}

	good := [?]string{"", "A", "A-B C", "x!~", pem.LABEL_PRIVATE_KEY}
	for label in good {
		res, enc_err := pem.encode(label, transmute([]byte)string("AAA"))
		defer delete(res)
		testing.expectf(t, enc_err == nil, "encode %q: %v", label, enc_err)

		blk, rest, err := pem.decode(res)
		defer pem.block_delete(blk)
		testing.expectf(t, err == nil && len(rest) == 0, "decode %q: %v", label, err)
		if blk != nil {
			testing.expect_value(t, blk.label, label)
			testing.expect_value(t, string(pem.block_bytes(blk)), "AAA")
		}
	}
}

@(test)
test_fix_line_endings :: proc(t: ^testing.T) {
	for eol in ([]string{"\n", "\r\n", "\r"}) {
		input := strings.concatenate({"text", eol, "-----BEGIN X-----", eol, "QUFB", eol, "-----END X-----", eol, "tail"}, context.temp_allocator)
		blk, rest, err := pem.decode(transmute([]byte)input)
		defer pem.block_delete(blk)
		testing.expectf(t, err == nil, "%q: %v", eol, err)
		testing.expectf(t, string(rest) == "tail", "%q: rest %q", eol, rest)
		if blk != nil {
			testing.expect_value(t, blk.label, "X")
			testing.expect_value(t, string(pem.block_bytes(blk)), "AAA")
		}
	}
}

@(test)
test_fix_skip_bad_begin :: proc(t: ^testing.T) {
	{
		input := "-----BEGIN here is a key\n-----BEGIN A--B-----\n-----BEGIN X-----\nQUFB\n-----END X-----\n"
		blk, rest, err := pem.decode(transmute([]byte)input)
		defer pem.block_delete(blk)
		testing.expectf(t, err == nil && len(rest) == 0, "skip: %v", err)
		if blk != nil {
			testing.expect_value(t, blk.label, "X")
		}
	}

	cases := [?]struct {
		input: string,
		err:   pem.Decode_Error,
	}{
		{"-----BEGIN here is a key\ntext\n", .Bad_Boundary},
		{"-----BEGIN A--B-----\nQUFB\n-----END A--B-----\n", .Bad_Label},
		{"-----BEGIN A--B-----\n-----BEGIN oops\n", .Bad_Label},
	}
	for c in cases {
		blk, rest, err := pem.decode(transmute([]byte)c.input)
		testing.expectf(t, blk == nil && rest == nil && err == c.err, "%q: got %v, want %v", c.input, err, c.err)
		pem.block_delete(blk)
	}
}

@(test)
test_fix_block_delete_nil :: proc(t: ^testing.T) {
	blk, rest, err := pem.decode(transmute([]byte)string("no PEM here\n"))
	testing.expect(t, blk == nil && rest == nil && err == nil)
	pem.block_delete(blk)
	pem.block_delete(nil)
}

@(test)
test_fix_allocation_failure :: proc(t: ^testing.T) {
	data: [100]byte
	input, enc_err := pem.encode(pem.LABEL_CERTIFICATE, data[:])
	defer delete(input)
	testing.expectf(t, enc_err == nil, "encode failed: %v", enc_err)

	for budget in 0 ..< 3 {
		c := Counting{backing = context.allocator, budget = budget}
		blk, rest, err := pem.decode(input, counting_allocator(&c))
		testing.expectf(t, blk == nil && rest == nil && err == .Out_Of_Memory, "decode, budget %d: %v", budget, err)
		pem.block_delete(blk)
	}

	c := Counting{backing = context.allocator, budget = 0}
	res, err := pem.encode(pem.LABEL_CERTIFICATE, data[:], allocator = counting_allocator(&c))
	testing.expectf(t, res == nil && err == .Out_Of_Memory, "encode: %v", err)
}

@(test)
test_fix_length_overflow :: proc(t: ^testing.T) {
	buf: [1]byte

	fake_data := transmute([]byte)runtime.Raw_Slice{raw_data(buf[:]), max(int)}
	res, err := pem.encode("X", fake_data)
	testing.expectf(t, res == nil && err == .Out_Of_Memory, "huge data: %v", err)

	fake_label := transmute(string)runtime.Raw_String{raw_data(buf[:]), max(int) / 2}
	res, err = pem.encode(fake_label, buf[:])
	testing.expectf(t, res == nil && err == .Out_Of_Memory, "huge label: %v", err)
}

@(test)
test_fix_newline_default :: proc(t: ^testing.T) {
	a, a_err := pem.encode("A", transmute([]byte)string("AAA"))
	defer delete(a)
	b, b_err := pem.encode("B", transmute([]byte)string("BBB"))
	defer delete(b)
	testing.expect(t, a_err == nil && b_err == nil)
	testing.expect(t, len(a) > 0 && a[len(a) - 1] == '\n')

	joined := bytes.concatenate({a, b})
	defer delete(joined)

	rest := joined
	for want in ([]string{"A", "B"}) {
		blk, remaining, err := pem.decode(rest)
		defer pem.block_delete(blk)
		testing.expectf(t, err == nil && blk != nil, "block %s: %v", want, err)
		if blk != nil {
			testing.expect_value(t, blk.label, want)
		}
		rest = remaining
	}
	testing.expect_value(t, len(rest), 0)
}

@(test)
test_fix_roundtrip_lengths :: proc(t: ^testing.T) {
	data: [200]byte
	for &b, i in data {
		b = byte(i * 37 + 11)
	}

	for n in 0 ..= len(data) {
		for newline in ([]bool{false, true}) {
			encoded, enc_err := pem.encode(pem.LABEL_PUBLIC_KEY, data[:n], newline)
			defer delete(encoded)
			testing.expectf(t, enc_err == nil, "encode %d: %v", n, enc_err)

			blk, rest, err := pem.decode(encoded)
			defer pem.block_delete(blk)
			testing.expectf(t, err == nil && len(rest) == 0, "decode %d: %v", n, err)
			if blk != nil {
				testing.expectf(t, bytes.equal(pem.block_bytes(blk), data[:n]), "data %d", n)
			}
		}
	}
}
