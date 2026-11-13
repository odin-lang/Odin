/*
	Encode and decode `rune`s to/from a Unicode `&entity;`.

	This code has several procedures to map unicode runes to/from different textual encodings.
	- SGML/XML/HTML entity
	- &#<decimal>;
	- &#x<hexadecimal>;
	- &<entity name>;   (If the lookup tables are compiled in).
	Reference: [[ https://www.w3.org/2003/entities/2007xml/unicode.xml ]]

	- URL encode / decode %hex entity
	Reference: [[ https://datatracker.ietf.org/doc/html/rfc3986/#section-2.1 ]]
*/
package encoding_unicode_entity

/*
	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's license.

	List of contributors:
		Jeroen van Rijn: Initial implementation.
*/

import "base:runtime"
import "core:unicode/utf8"
import "core:unicode"
import "core:strings"
import "core:encoding/hex"

MAX_RUNE_CODEPOINT :: int(unicode.MAX_RUNE)

write_rune   :: strings.write_rune
write_string :: strings.write_string

Error :: enum u8 {
	None = 0,
	Tokenizer_Is_Nil,

	Illegal_NUL_Character,
	Illegal_UTF_Encoding,

	CDATA_Not_Terminated,
	Comment_Not_Terminated,
	Invalid_Entity_Encoding,
	Unknown_Entity,
	Buffer_Too_Small,
}

Percent_Error :: union #shared_nil {
	runtime.Allocator_Error,
	Error,
}

Tokenizer :: struct {
	r:           rune,
	w:           int,

	src:         string,
	offset:      int,
	read_offset: int,
}

CDATA_START   :: "<![CDATA["
CDATA_END     :: "]]>"

COMMENT_START :: "<!--"
COMMENT_END   :: "-->"

// By default `decode_xml` decodes the 5 predefined entities and character references, unboxes CDATA without decoding it,
// drops comments, and turns CRLF and lone CR into LF.
XML_Decode_Option :: enum u8 {
	// Keep comments in the output.
	Keep_Comments,
	// Turn each literal tab, LF and CR into a space, as XML does for CDATA attribute values (§3.3.3).
	Normalize_Attribute,
	// Like `Normalize_Attribute`, then collapse runs of spaces and trim, as XML does for other attribute types.
	Collapse_Whitespace,
	// Also decode the HTML, MathML and ISO 8879 names from `unicode.xml`.
	HTML_Entities,
	// Keep unknown names as they are, instead of returning `.Unknown_Entity`.
	Keep_Unknown_Entities,
}
XML_Decode_Options :: bit_set[XML_Decode_Option; u8]

// Decode a string that may include SGML/XML/HTML entities.
// The caller has to free the result.
decode_xml :: proc(input: string, options := XML_Decode_Options{}, allocator := context.allocator) -> (decoded: string, err: Error) {
	builder := strings.builder_make(allocator)
	defer strings.builder_destroy(&builder)
	decoded, err = decode_xml_sb(&builder, input, options, allocator)
	decoded = strings.clone(decoded, allocator)
	return
}

// Decode a string that may include SGML/XML/HTML entities into an existing `builder`.
// The returned `decoded` string is a reference into the builder's buffer, and therefore does not need to be freed individually.
decode_xml_sb :: proc(builder: ^strings.Builder, input: string, options := XML_Decode_Options{}, allocator := context.allocator) -> (decoded: string, err: Error) {
	context.allocator = allocator

	l := len(input)
	if l == 0 { return "", .None }

	string_start_in_builder := len(builder.buf)

	sink := Sink{sb = builder}
	err, _ = decode(input, options, &sink)
	return transmute(string)builder.buf[string_start_in_builder:], err
}

decode_xml_in_place :: proc(buf: []u8, options := XML_Decode_Options{}) -> (decoded: string, err: Error, err_offset: int) {
	measure: Sink
	err, err_offset = decode(string(buf), options, &measure)
	switch {
	case err != .None:
		return "", err, err_offset
	case measure.grows:
		return "", .Buffer_Too_Small, measure.grow_offset
	case !measure.changed:
		return string(buf), .None, 0
	}

	sink := Sink{buf = buf}
	err, err_offset = decode(string(buf), options, &sink)
	assert(err == .None && sink.w == measure.w)
	return string(buf[:sink.w]), .None, 0
}

advance :: proc(t: ^Tokenizer) -> (err: Error) {
	if t == nil { return .Tokenizer_Is_Nil }
	#no_bounds_check {
		if t.read_offset < len(t.src) {
			t.offset = t.read_offset
			t.r, t.w   = rune(t.src[t.read_offset]), 1
			switch {
			case t.r == 0:
				return .Illegal_NUL_Character
			case t.r >= utf8.RUNE_SELF:
				t.r, t.w = utf8.decode_rune_in_string(t.src[t.read_offset:])
				if t.r == utf8.RUNE_ERROR && t.w == 1 {
					return .Illegal_UTF_Encoding
				}
			}
			t.read_offset += t.w
			return .None
		} else {
			t.offset = len(t.src)
			t.r = -1
			return
		}
	}
}

xml_decode_entity :: proc(entity: string) -> (decoded: [2]rune, rune_count: int, ok: bool) {
	entity := entity
	if len(entity) == 0 { return }

	if entity[0] == '#' {
		base  := 10
		val   := 0
		entity = entity[1:]

		if len(entity) == 0 { return }

		if entity[0] == 'x' || entity[0] == 'X' {
			base = 16
			entity = entity[1:]
			if len(entity) == 0 { return }
		}

		for len(entity) > 0 {
			r := entity[0]
			switch r {
			case '0'..='9':
				val *= base
				val += int(r - '0')

			case 'a'..='f':
				if base == 10 { return }
				val *= base
				val += int(r - 'a' + 10)

			case 'A'..='F':
				if base == 10 { return }
				val *= base
				val += int(r - 'A' + 10)

			case:
				return
			}

			if val > MAX_RUNE_CODEPOINT { return  }
			entity = entity[1:]
		}
		if !is_xml_char(rune(val)) { return }
		return rune(val), 1, true
	}
	// Named entity.
	return named_xml_entity_to_rune(entity)
}


// escape_html escapes special characters like '&' to become '&amp;'.
// It escapes only 5 different characters: & ' < > and "
@(require_results)
escape_html :: proc(s: string, allocator := context.allocator, loc := #caller_location) -> (output: string, was_allocation: bool) {
	/*
		& -> &amp;
		' -> &#39; // &#39; is shorter than &apos; (NOTE: &apos; was not available until HTML 5)
		< -> &lt;
		> -> &gt;
		" -> &#34; // &#34; is shorter than &quot;
	*/

	b := transmute([]byte)s

	extra_bytes_needed := 0

	for c in b {
		switch c {
		case '&':  extra_bytes_needed += 4
		case '\'': extra_bytes_needed += 4
		case '<':  extra_bytes_needed += 3
		case '>':  extra_bytes_needed += 3
		case '"':  extra_bytes_needed += 4
		}
	}

	if extra_bytes_needed == 0 {
		return s, false
	}

	t, err := make([]byte, len(s) + extra_bytes_needed, allocator, loc)
	if err != nil {
		return
	}
	was_allocation = true

	w := 0
	for c in b {
		x := ""
		switch c {
		case '&':  x = "&amp;"
		case '\'': x = "&#39;"
		case '<':  x = "&lt;"
		case '>':  x = "&gt;"
		case '"':  x = "&#34;"
		}
		if x != "" {
			copy(t[w:], x)
			w += len(x)
		} else {
			t[w] = c
			w += 1
		}
	}
	output = string(t[0:w])
	return
}


@(require_results)
unescape_html :: proc(s: string, allocator := context.allocator, loc := #caller_location) -> (output: string, was_allocation: bool, err: runtime.Allocator_Error) {
	@(require_results)
	do_append :: proc(s: string, amp_idx: int, buf: ^[dynamic]byte) -> (n: int) {
		s, amp_idx := s, amp_idx

		n += len(s[:amp_idx])
		if buf != nil { append(buf, s[:amp_idx]) }
		s = s[amp_idx:]
		for len(s) > 0 {
			b, w, j := unescape_entity(s)
			n += w
			if buf != nil { append(buf, ..b[:w]) }

			s = s[j:]

			amp_idx = strings.index_byte(s, '&')
			if amp_idx < 0 {
				n += len(s)
				if buf != nil { append(buf, s) }
				break
			}
			n += amp_idx
			if buf != nil { append(buf, s[:amp_idx]) }
			s = s[amp_idx:]
		}

		return
	}

	s := s
	amp_idx := strings.index_byte(s, '&')
	if amp_idx < 0 {
		return s, false, nil
	}

	// NOTE(bill): this does a two pass in order to minimize the allocations required
	bytes_required := do_append(s, amp_idx, nil)

	buf := make([dynamic]byte, 0, bytes_required, allocator, loc) or_return
	was_allocation = true

	_ = do_append(s, amp_idx, &buf)

	assert(len(buf) == cap(buf))
	output = string(buf[:])

	return
}

// Returns an unescaped string of an encoded XML/HTML entity.
@(require_results)
unescape_entity :: proc(s: string) -> (b: [8]byte, w: int, j: int) {
	if len(s) == 0 || s[0] != '&' {
		return
	}
	b[0], w, j = '&', 1, 1

	if len(s) > 1 && s[1] == '#' { // scan numbers
		i   := 2
		hex := false
		if i < len(s) && (s[i] == 'x' || s[i] == 'X') {
			hex = true
			i  += 1
		}

		digits_start := i
		x := rune(0)
		scan_number: for i < len(s) {
			c := s[i]
			d: rune
			switch {
			case c >= '0' && c <= '9':        d = rune(c - '0')
			case hex && c >= 'a' && c <= 'f': d = rune(c - 'a' + 10)
			case hex && c >= 'A' && c <= 'F': d = rune(c - 'A' + 10)
			case:                             break scan_number
			}
			if x <= unicode.MAX_RUNE {
				x = (16 if hex else 10) * x + d
			}
			i += 1
		}

		if i == digits_start {
			return
		}
		if i < len(s) && s[i] == ';' {
			i += 1
		}

		@(static, rodata)
		windows_1252_replacement_table := [0xa0 - 0x80]rune{ // Windows-1252 -> UTF-8
			'\u20ac', '\u0081', '\u201a', '\u0192',
			'\u201e', '\u2026', '\u2020', '\u2021',
			'\u02c6', '\u2030', '\u0160', '\u2039',
			'\u0152', '\u008d', '\u017d', '\u008f',
			'\u0090', '\u2018', '\u2019', '\u201c',
			'\u201d', '\u2022', '\u2013', '\u2014',
			'\u02dc', '\u2122', '\u0161', '\u203a',
			'\u0153', '\u009d', '\u017e', '\u0178',
		}

		switch {
		case x >= 0x80 && x < 0xa0:
			x = windows_1252_replacement_table[x-0x80]
		case x == 0, x >= 0xd800 && x <= 0xdfff, x > unicode.MAX_RUNE:
			x = utf8.RUNE_ERROR
		}

		b1, w1 := utf8.encode_rune(x)
		w = copy(b[:], b1[:w1])
		j = i
		return
	}

	// Lookup by entity names

	name_end := 1
	for name_end < len(s) && is_ascii_alphanumeric(s[name_end]) {
		name_end += 1
	}
	name := s[1:name_end]

	if name_end < len(s) && s[name_end] == ';' && !is_non_html5_entity_name(name) {
		if r2, n, ok := named_xml_entity_to_rune(name); ok {
			w = encode_runes(&b, r2, n)
			j = name_end + 1
			return
		}
	}

	for l := min(len(name), HTML5_LEGACY_NAME_MAX_LENGTH); l >= 2; l -= 1 {
		if is_html5_legacy_entity_name(name[:l]) {
			r2, n, _ := named_xml_entity_to_rune(name[:l])
			w = encode_runes(&b, r2, n)
			j = 1 + l
			return
		}
	}

	return
}

@(private="file")
encode_runes :: proc(b: ^[8]byte, r: [2]rune, n: int) -> (w: int) {
	for i in 0..<n {
		b1, w1 := utf8.encode_rune(r[i])
		w += copy(b[w:], b1[:w1])
	}
	return
}

@(private="file")
is_ascii_alphanumeric :: #force_inline proc(c: u8) -> bool {
	return (c >= '0' && c <= '9') || (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')
}

// Unlike `net.percent_encode`, this encodes bytes rather than runes, so invalid UTF-8 survives a round trip
// instead of turning into `%EF%BF%BD`, and it returns `s` itself, without allocating, when nothing needs escaping.
@(require_results)
percent_encode :: proc(s: string, allocator := context.allocator, loc := #caller_location) -> (output: string, was_allocation: bool, err: runtime.Allocator_Error) {
	escaped := 0
	for i in 0..<len(s) {
		if !is_unreserved(s[i]) {
			escaped += 1
		}
	}
	if escaped == 0 {
		return s, false, nil
	}

	b := strings.builder_make(0, len(s) + 2 * escaped, allocator, loc) or_return
	w := strings.to_writer(&b)
	for i in 0..<len(s) {
		if is_unreserved(s[i]) {
			strings.write_byte(&b, s[i])
		} else {
			strings.write_byte(&b, '%')
			hex.encode_upper_into_writer(w, transmute([]byte)s[i:i + 1])
		}
	}
	assert(len(b.buf) == cap(b.buf))
	return strings.to_string(b), true, nil
}

// Unlike `net.percent_decode`, `%%` is `.Invalid_Entity_Encoding` instead of `%`, allocation failures are returned,
// and `s` itself is returned, without allocating, when it holds no `%`.
@(require_results)
percent_decode :: proc(s: string, allocator := context.allocator, loc := #caller_location) -> (output: string, was_allocation: bool, err: Percent_Error) {
	escaped := 0
	for i := 0; i < len(s); i += 1 {
		if s[i] == '%' {
			if _, ok := hex.decode_sequence(s[i + 1:min(i + 3, len(s))]); !ok {
				return "", false, .Invalid_Entity_Encoding
			}
			escaped += 1
			i += 2
		}
	}
	if escaped == 0 {
		return s, false, nil
	}

	buf := make([]byte, len(s) - 2 * escaped, allocator, loc) or_return
	w := 0
	for i := 0; i < len(s); i += 1 {
		if s[i] == '%' {
			buf[w], _ = hex.decode_sequence(s[i + 1:i + 3])
			i += 2
		} else {
			buf[w] = s[i]
		}
		w += 1
	}
	return string(buf), true, nil
}

@(private="file")
is_unreserved :: #force_inline proc(c: u8) -> bool {
	return is_ascii_alphanumeric(c) || c == '-' || c == '.' || c == '_' || c == '~'
}

@(private="file")
Sink :: struct {
	buf:         []u8,
	sb:          ^strings.Builder,
	w:           int,
	normalize:   bool,
	collapse:    bool,
	space:       bool,
	started:     bool,
	changed:     bool,
	grows:       bool,
	grow_offset: int,
}

@(private="file")
emit :: #force_inline proc(s: ^Sink, text: string) {
	if s.sb != nil {
		write_string(s.sb, text)
	} else if s.buf != nil {
		copy(s.buf[s.w:], text)
	}
	s.w += len(text)
}

@(private="file")
emit_content :: proc(s: ^Sink, text: string) {
	if len(text) == 0 {
		return
	}
	if s.collapse {
		if s.space && s.started {
			emit(s, " ")
		}
		s.space   = false
		s.started = true
	}
	emit(s, text)
}

@(private="file")
emit_whitespace :: proc(s: ^Sink, c: u8) {
	switch {
	case s.collapse:
		s.space   = true
		s.changed = true
	case s.normalize:
		emit(s, " ")
		s.changed |= c != ' '
	case:
		emit(s, "\n")
		s.changed = true
	}
}

@(private="file")
decode :: proc(src: string, options: XML_Decode_Options, s: ^Sink) -> (err: Error, err_offset: int) {
	s.collapse  = .Collapse_Whitespace in options
	s.normalize = s.collapse || .Normalize_Attribute in options
	return decode_span(s, src, 0, len(src), true, options)
}

@(private="file")
decode_span :: proc(s: ^Sink, src: string, from, to: int, markup: bool, options: XML_Decode_Options) -> (err: Error, err_offset: int) {
	i, run := from, from
	for i < to {
		c := src[i]
		switch c {
		case '&':
			if !markup {
				i += 1
				continue
			}
			emit_content(s, src[run:i])
			decoded, count, length, ref_err := parse_reference(src[i:to], options)
			if ref_err != .None {
				return ref_err, i
			}
			if count == 0 {
				emit_content(s, src[i:][:length])
			} else {
				s.changed = true
				written := 0
				for r in decoded[:count] {
					if s.collapse && r == ' ' {
						s.space = true
						continue
					}
					bytes, n := utf8.encode_rune(r)
					written += n
					emit_content(s, string(bytes[:n]))
				}
				if written > length && !s.grows {
					s.grows       = true
					s.grow_offset = i
				}
			}
			i  += length
			run = i

		case '<':
			if !markup {
				i += 1
				continue
			}
			rest := src[i:to]
			if strings.has_prefix(rest, CDATA_START) {
				emit_content(s, src[run:i])
				start := i + len(CDATA_START)
				end   := strings.index(src[start:to], CDATA_END)
				if end < 0 {
					return .CDATA_Not_Terminated, i
				}
				s.changed = true
				if span_err, span_offset := decode_span(s, src, start, start + end, false, options); span_err != .None {
					return span_err, span_offset
				}
				i  = start + end + len(CDATA_END)
				run = i
			} else if strings.has_prefix(rest, COMMENT_START) {
				emit_content(s, src[run:i])
				end := strings.index(src[i + len(COMMENT_START):to], COMMENT_END)
				if end < 0 {
					return .Comment_Not_Terminated, i
				}
				next := i + len(COMMENT_START) + end + len(COMMENT_END)
				span_err:    Error
				span_offset: int
				if .Keep_Comments in options {
					span_err, span_offset = decode_span(s, src, i, next, false, options)
				} else {
					s.changed = true
					span_err, span_offset = validate_span(src, i, next)
				}
				if span_err != .None {
					return span_err, span_offset
				}
				i  = next
				run = i
			} else {
				i += 1
			}

		case '\r':
			emit_content(s, src[run:i])
			s.changed = true
			if i + 1 < to && src[i + 1] == '\n' {
				i  += 1
				run = i
				continue
			}
			emit_whitespace(s, '\n')
			i  += 1
			run = i

		case '\t', '\n', ' ':
			if !s.normalize || (c == ' ' && !s.collapse) {
				i += 1
				continue
			}
			emit_content(s, src[run:i])
			emit_whitespace(s, c)
			i  += 1
			run = i

		case 0:
			return .Illegal_NUL_Character, i

		case utf8.RUNE_SELF..=0xff:
			r, w := utf8.decode_rune_in_string(src[i:to])
			if r == utf8.RUNE_ERROR && w == 1 {
				return .Illegal_UTF_Encoding, i
			}
			i += w

		case:
			i += 1
		}
	}
	emit_content(s, src[run:to])
	return .None, 0
}

@(private="file")
validate_span :: proc(src: string, from, to: int) -> (err: Error, err_offset: int) {
	for i := from; i < to; {
		c := src[i]
		switch {
		case c == 0:
			return .Illegal_NUL_Character, i
		case c >= utf8.RUNE_SELF:
			r, w := utf8.decode_rune_in_string(src[i:to])
			if r == utf8.RUNE_ERROR && w == 1 {
				return .Illegal_UTF_Encoding, i
			}
			i += w
		case:
			i += 1
		}
	}
	return .None, 0
}

@(private="file")
parse_reference :: proc(s: string, options: XML_Decode_Options) -> (decoded: [2]rune, rune_count: int, length: int, err: Error) {
	assert(len(s) > 0 && s[0] == '&')
	i := 1
	if i < len(s) && s[i] == '#' {
		i += 1
		hex := i < len(s) && s[i] == 'x'
		if hex {
			i += 1
		}
		digits := i
		digit_loop: for i < len(s) {
			switch s[i] {
			case '0'..='9':
			case 'a'..='f', 'A'..='F':
				if !hex {
					break digit_loop
				}
			case:
				break digit_loop
			}
			i += 1
		}
		if i == digits || i >= len(s) || s[i] != ';' {
			return {}, 0, 0, .Invalid_Entity_Encoding
		}
		ok: bool
		decoded, rune_count, ok = xml_decode_entity(s[1:i])
		if !ok {
			return {}, 0, 0, .Invalid_Entity_Encoding
		}
		return decoded, rune_count, i + 1, .None
	}

	r, w := utf8.decode_rune_in_string(s[i:])
	if w == 0 || (r == utf8.RUNE_ERROR && w == 1) || !is_name_start_char(r) {
		return {}, 0, 0, .Invalid_Entity_Encoding
	}
	i += w
	for i < len(s) {
		r, w = utf8.decode_rune_in_string(s[i:])
		if (r == utf8.RUNE_ERROR && w == 1) || !is_name_char(r) {
			break
		}
		i += w
	}
	if i >= len(s) || s[i] != ';' {
		return {}, 0, 0, .Invalid_Entity_Encoding
	}
	length = i + 1

	switch s[1:i] {
	case "lt":   return {'<',  0}, 1, length, .None
	case "gt":   return {'>',  0}, 1, length, .None
	case "amp":  return {'&',  0}, 1, length, .None
	case "apos": return {'\'', 0}, 1, length, .None
	case "quot": return {'"',  0}, 1, length, .None
	}
	if .HTML_Entities in options {
		if named, count, ok := named_xml_entity_to_rune(s[1:i]); ok {
			return named, count, length, .None
		}
	}
	if .Keep_Unknown_Entities in options {
		return {}, 0, length, .None
	}
	return {}, 0, 0, .Unknown_Entity
}

@(private="file")
is_xml_char :: proc(r: rune) -> bool {
	switch r {
	case 0x9, 0xa, 0xd, 0x20..=0xd7ff, 0xe000..=0xfffd, 0x10000..=0x10ffff:
		return true
	}
	return false
}

@(private="file")
is_name_start_char :: proc(r: rune) -> bool {
	switch r {
	case 'A'..='Z', 'a'..='z', '_', ':',
	     0xc0..=0xd6, 0xd8..=0xf6, 0xf8..=0x2ff, 0x370..=0x37d, 0x37f..=0x1fff, 0x200c..=0x200d,
	     0x2070..=0x218f, 0x2c00..=0x2fef, 0x3001..=0xd7ff, 0xf900..=0xfdcf, 0xfdf0..=0xfffd, 0x10000..=0xeffff:
		return true
	}
	return false
}

@(private="file")
is_name_char :: proc(r: rune) -> bool {
	switch r {
	case '-', '.', '0'..='9', 0xb7, 0x300..=0x36f, 0x203f..=0x2040:
		return true
	}
	return is_name_start_char(r)
}
