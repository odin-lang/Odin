package test_core_io

import "core:io"
import "core:strconv"
import "core:strings"
import "core:testing"
import "core:unicode/utf8"

// `write_quoted_string` writes runs of runes that need no escaping in one go.
// This reference is the rune-at-a-time loop it had before, and both must agree byte for byte.
@(private="file")
ref_write_quoted_string :: proc(w: io.Writer, str: string, quote: byte = '"', n_written: ^int = nil, options: strconv.Rune_Escaping_Options = nil) -> (n: int, err: io.Error) {
	defer if n_written != nil {
		n_written^ += n
	}

	io.write_byte(w, quote, &n) or_return

	s := str
	for len(s) > 0 {
		r := cast(rune)s[0]
		width := 1
		if r >= utf8.RUNE_SELF {
			r, width = utf8.decode_rune_in_string(s)
		}
		if width == 1 && r == utf8.RUNE_ERROR {
			io.write_string(w, `\x`, &n)                     or_return
			io.write_byte(w, strconv.digits[s[0] >> 4], &n)  or_return
			io.write_byte(w, strconv.digits[s[0] & 0xf], &n) or_return
		} else {
			encoded_rune_buf: [strconv.ESCAPED_RUNE_MAX_NEEDED_BYTES]byte
			encoded_rune := strconv.encode_and_escape_rune(encoded_rune_buf[:], r, quote, options = options)
			io.write_string(w, encoded_rune, &n) or_return
		}
		s = s[width:]
	}

	io.write_byte(w, quote, &n) or_return
	return
}

@(private="file")
QUOTE_PIECES := [?]string{
	"", "a", "hello", " ", "\"", "'", "`", "\\", "<", ">", "&", "<a&b>",
	"\x00", "\a", "\b", "\e", "\f", "\n", "\r", "\t", "\v", "\x1f", "\x7f",
	"é", "héllo", "日本語", "é", "​", " ", "­", " ", "\U0001F600", "�",
	"\xff", "\x80", "\xc0\x80", "\xed\xa0\x80", "\xe2\x82", "\xf4\x90\x80\x80", "a\xffb",
	"a long run of plain ascii text that needs no escaping at all",
}

@(private="file")
QUOTE_CHARS := [?]byte{'"', '\'', '`', 0}

@(private="file")
QUOTE_OPTIONS := [?]strconv.Rune_Escaping_Options{{}, {.ascii_compatible}, {.html_safe}, {.ascii_compatible, .html_safe}}

@(private="file")
check_quoted :: proc(t: ^testing.T, s: string, quote: byte, options: strconv.Rune_Escaping_Options, limit: int) -> bool {
	got_buf, want_buf: [512]byte
	got_sb  := strings.builder_from_bytes(got_buf[:limit])
	want_sb := strings.builder_from_bytes(want_buf[:limit])

	got_count, want_count: int
	got_n,  got_err  := io.write_quoted_string(strings.to_writer(&got_sb), s, quote, &got_count, options)
	want_n, want_err := ref_write_quoted_string(strings.to_writer(&want_sb), s, quote, &want_count, options)

	got, want := strings.to_string(got_sb), strings.to_string(want_sb)
	ok := got == want && got_n == want_n && got_count == want_count && got_err == want_err
	testing.expectf(t, ok, "(%q, quote=%v, options=%v, limit=%v): got %q n=%v err=%v, want %q n=%v err=%v",
		s, quote, options, limit, got, got_n, got_err, want, want_n, want_err)
	return ok
}

@(test)
test_write_quoted_string_matches_reference :: proc(t: ^testing.T) {
	inputs: [dynamic]string
	defer delete(inputs)
	for piece in QUOTE_PIECES {
		append(&inputs, piece)
	}

	// Random concatenations of the pieces
	state := u64(0x9E3779B97F4A7C15)
	for _ in 0..<300 {
		sb := strings.builder_make(context.temp_allocator)
		state = state*6364136223846793005 + 1442695040888963407
		count := int(state >> 59) + 1
		for _ in 0..<count {
			state = state*6364136223846793005 + 1442695040888963407
			strings.write_string(&sb, QUOTE_PIECES[int(state >> 33) % len(QUOTE_PIECES)])
		}
		append(&inputs, strings.to_string(sb))
	}

	for s in inputs {
		for quote in QUOTE_CHARS {
			for options in QUOTE_OPTIONS {
				if !check_quoted(t, s, quote, options, 512) {
					return
				}
			}
		}
	}

	// A writer that fills up keeps the same prefix and count
	for s in inputs[len(QUOTE_PIECES):][:40] {
		for limit in 0..<min(len(s) + 8, 120) {
			if !check_quoted(t, s, '"', {}, limit) {
				return
			}
		}
	}
}
