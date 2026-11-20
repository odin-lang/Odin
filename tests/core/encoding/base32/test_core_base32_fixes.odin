package test_encoding_base32

import "base:runtime"
import "core:encoding/base32"
import "core:io"
import "core:strings"
import "core:testing"

@(private="file")
fail_alloc :: proc(allocator_data: rawptr, mode: runtime.Allocator_Mode, size, alignment: int, old_memory: rawptr, old_size: int, loc := #caller_location) -> ([]byte, runtime.Allocator_Error) {
	#partial switch mode {
	case .Free, .Free_All:
		return nil, nil
	}
	return nil, .Out_Of_Memory
}

@(test)
test_fix_padding_after_full_quantum :: proc(t: ^testing.T) {
	cases := []struct {
		src, plain: string,
	}{
		{"MZXW6YTB=",        "fooba"},
		{"MZXW6YTB========", "fooba"},
		{"==",               ""},
		{"========",         ""},
	}
	for c in cases {
		decoded, err := base32.decode(c.src)
		testing.expectf(t, err == nil && string(decoded) == c.plain, "decode(%q): %v %q", c.src, err, decoded)
		delete(decoded)

		strict, strict_err := base32.decode(c.src, options = {.Strict})
		testing.expectf(t, strict_err == base32.Decode_Error.Invalid_Padding, "decode(%q, {{.Strict}}): %v", c.src, strict_err)
		delete(strict)
	}
}

@(test)
test_fix_allocation_failure :: proc(t: ^testing.T) {
	failing := runtime.Allocator{fail_alloc, nil}

	encoded, enc_err := base32.encode(transmute([]byte)string("fooba"), allocator = failing)
	testing.expect_value(t, enc_err, runtime.Allocator_Error.Out_Of_Memory)
	testing.expect_value(t, encoded, "")

	decoded, dec_err := base32.decode("MZXW6YTB", allocator = failing)
	testing.expect(t, dec_err == runtime.Allocator_Error.Out_Of_Memory)
	testing.expect(t, decoded == nil)
}

@(test)
test_fix_length_overflow :: proc(t: ^testing.T) {
	huge := transmute([]byte)runtime.Raw_Slice{nil, max(int)}
	testing.expect_value(t, base32.encoded_len(huge), max(int))

	largest := transmute([]byte)runtime.Raw_Slice{nil, max(int) / 8 * 5}
	testing.expect_value(t, base32.encoded_len(largest), max(int) / 8 * 8)

	n := 429_496_736
	last := [1]byte{'A'}
	start := rawptr(uintptr(&last[0]) - uintptr(n - 1))
	long := transmute(string)runtime.Raw_String{([^]byte)(start), n}
	length, err := base32.decoded_len(long)
	testing.expect_value(t, err, base32.Decode_Error.None)
	testing.expect_value(t, length, n / 8 * 5)
}

@(test)
test_fix_extended_hex_tables :: proc(t: ^testing.T) {
	cases := []struct {
		plain, encoded: string,
	}{
		{"",       ""},
		{"f",      "CO======"},
		{"fo",     "CPNG===="},
		{"foo",    "CPNMU==="},
		{"foob",   "CPNMUOG="},
		{"fooba",  "CPNMUOJ1"},
		{"foobar", "CPNMUOJ1E8======"},
	}
	for c in cases {
		encoded := base32.encode(transmute([]byte)c.plain, base32.ENC_HEX_TABLE)
		testing.expect_value(t, encoded, c.encoded)
		delete(encoded)

		decoded, err := base32.decode(c.encoded, base32.DEC_HEX_TABLE, options = {.Strict})
		testing.expectf(t, err == nil && string(decoded) == c.plain, "decode(%q): %v %q", c.encoded, err, decoded)
		delete(decoded)
	}

	zero, zero_err := base32.decode("00======", base32.DEC_HEX_TABLE)
	testing.expectf(t, zero_err == nil && len(zero) == 1 && zero[0] == 0, "decode(\"00======\"): %v %v", zero_err, zero)
	delete(zero)

	for src in ([]string{"WY======", "ZZ======"}) {
		decoded, err := base32.decode(src, base32.DEC_HEX_TABLE)
		testing.expectf(t, err == base32.Decode_Error.Invalid_Character, "decode(%q): %v", src, err)
		delete(decoded)
	}

	decoded, err := base32.decode("00======")
	testing.expect(t, err == base32.Decode_Error.Invalid_Character)
	delete(decoded)
}

@(test)
test_fix_options :: proc(t: ^testing.T) {
	cases := []struct {
		plain, raw: string,
	}{
		{"",       ""},
		{"f",      "MY"},
		{"fo",     "MZXQ"},
		{"foo",    "MZXW6"},
		{"foob",   "MZXW6YQ"},
		{"fooba",  "MZXW6YTB"},
		{"foobar", "MZXW6YTBOI"},
	}
	for c in cases {
		encoded := base32.encode(transmute([]byte)c.plain, options = {.No_Padding})
		testing.expect_value(t, encoded, c.raw)
		testing.expect_value(t, base32.encoded_len(transmute([]byte)c.plain, {.No_Padding}), len(c.raw))
		delete(encoded)

		for options in ([]base32.Decode_Options{{}, {.No_Padding}, {.Strict, .No_Padding}}) {
			decoded, err := base32.decode(c.raw, options = options)
			testing.expectf(t, err == nil && string(decoded) == c.plain, "decode(%q, %v): %v %q", c.raw, options, err, decoded)
			delete(decoded)
		}
	}

	errors := []struct {
		src:     string,
		options: base32.Decode_Options,
		err:     base32.Decode_Error,
	}{
		{"MY======", {.No_Padding},         .Invalid_Padding},
		{"MZXQ",     {.Strict},             .Invalid_Padding},
		{"MZXQ==",   {.Strict},             .Invalid_Padding},
		{"MZ=Q====", {},                    .Invalid_Padding},
		{"MZ!Q====", {},                    .Invalid_Character},
		{"MZ======", {.Strict},             .Non_Canonical},
		{"MZ",       {.Strict, .No_Padding}, .Non_Canonical},
		{"MZXR====", {.Strict},             .Non_Canonical},
		{"MZXW7===", {.Strict},             .Non_Canonical},
		{"MZXW6YR=", {.Strict},             .Non_Canonical},
		{"M",        {},                    .Malformed_Quantum},
		{"MZX",      {},                    .Malformed_Quantum},
		{"MZXW6Y",   {},                    .Malformed_Quantum},
		{"MZX=====", {.Strict},             .Malformed_Quantum},
	}
	for c in errors {
		decoded, err := base32.decode(c.src, options = c.options)
		testing.expectf(t, err == c.err, "decode(%q, %v): got %v, want %v", c.src, c.options, err, c.err)
		delete(decoded)
	}

	lenient, err := base32.decode("MZ======")
	testing.expectf(t, err == nil && string(lenient) == "f", "decode(\"MZ======\"): %v %q", err, lenient)
	delete(lenient)
}

@(test)
test_fix_into :: proc(t: ^testing.T) {
	buf: [16]byte
	encoded, enc_err := base32.encode_into_buf(buf[:], transmute([]byte)string("foobar"))
	testing.expectf(t, enc_err == nil && string(encoded) == "MZXW6YTBOI======", "encode_into_buf: %v %q", enc_err, encoded)
	_, short_enc := base32.encode_into_buf(buf[:15], transmute([]byte)string("foobar"))
	testing.expect(t, short_enc == io.Error.Short_Buffer)

	out: [6]byte
	decoded, dec_err := base32.decode_into_buf(out[:], "MZXW6YTBOI======")
	testing.expectf(t, dec_err == nil && string(decoded) == "foobar", "decode_into_buf: %v %q", dec_err, decoded)
	_, short_dec := base32.decode_into_buf(out[:5], "MZXW6YTBOI======")
	testing.expect(t, short_dec == io.Error.Short_Buffer)

	sb := strings.builder_make()
	defer strings.builder_destroy(&sb)
	testing.expect_value(t, base32.encode_into(strings.to_writer(&sb), transmute([]byte)string("foobar"), options = {.No_Padding}), io.Error.None)
	testing.expect_value(t, strings.to_string(sb), "MZXW6YTBOI")

	strings.builder_reset(&sb)
	testing.expect(t, base32.decode_into(strings.to_writer(&sb), "MZXW6YTBOI") == nil)
	testing.expect_value(t, strings.to_string(sb), "foobar")

	length, len_err := base32.decoded_len("MZXW6YTBOI======")
	testing.expect_value(t, len_err, base32.Decode_Error.None)
	testing.expect_value(t, length, 6)
}
