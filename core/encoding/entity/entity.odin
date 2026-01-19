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

MAX_RUNE_CODEPOINT :: int(unicode.MAX_RUNE)

write_rune   :: strings.write_rune
write_string :: strings.write_string

Error :: enum u8 {
	None = 0,
	Tokenizer_Is_Nil,

	Illegal_NUL_Character,
	Illegal_UTF_Encoding,
	Illegal_BOM,

	CDATA_Not_Terminated,
	Comment_Not_Terminated,
	Invalid_Entity_Encoding,
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

// Default: CDATA and comments are passed through unchanged.
XML_Decode_Option :: enum u8 {
	// Do not decode & entities. It decodes by default. If given, overrides `Decode_CDATA`.
	No_Entity_Decode,

	// CDATA is unboxed.
	Unbox_CDATA,

	// Unboxed CDATA is decoded as well. Ignored if `.Unbox_CDATA` is not given.
	Decode_CDATA,

	// Comments are stripped.
	Comment_Strip,

	// Normalize whitespace
	Normalize_Whitespace,
}
XML_Decode_Options :: bit_set[XML_Decode_Option; u8]

// Decode a string that may include SGML/XML/HTML entities.
// The caller has to free the result.
decode_xml :: proc(input: string, options := XML_Decode_Options{}, allocator := context.allocator) -> (decoded: string, err: Error) {
	context.allocator = allocator

	l := len(input)
	if l == 0 { return "", .None }

	builder := strings.builder_make()
	defer strings.builder_destroy(&builder)

	t := Tokenizer{src=input}
	in_data := false

	prev: rune = ' '

	loop: for {
		advance(&t) or_return
		if t.r < 0 { break loop }

		// Below here we're never inside a CDATA tag. At most we'll see the start of one,
		// but that doesn't affect the logic.
		switch t.r {
		case '<':
			/*
				Might be the start of a CDATA tag or comment.

				We don't need to check if we need to write a `<`, because if it isn't CDATA or a comment,
				it couldn't have been part of an XML tag body to be decoded here.

				Keep in mind that we could already *be* inside a CDATA tag.
				If so, write `<` as a literal and continue.
			*/
			if in_data {
				write_rune(&builder, '<')
				continue
			}
			in_data = _handle_xml_special(&t, &builder, options) or_return

		case ']':
			// If we're unboxing _and_ decoding CDATA, we'll have to check for the end tag.
			if in_data {
				if strings.has_prefix(t.src[t.offset:], CDATA_END) {
					in_data = false
					t.read_offset += len(CDATA_END) - 1
				}
				continue
			} else {
				write_rune(&builder, ']')
			}

		case:
			if in_data && .Decode_CDATA not_in options {
				// Unboxed, but undecoded.
				write_rune(&builder, t.r)
				continue
			}

			if t.r == '&' {
				if entity, entity_err := _extract_xml_entity(&t); entity_err != .None {
					// We read to the end of the string without closing the entity. Pass through as-is.
					write_string(&builder, entity)
				} else {
					if .No_Entity_Decode not_in options {
						if decoded, count, ok := xml_decode_entity(entity); ok {
							for i in 0..<count {
								write_rune(&builder, decoded[i])
							}
							continue
						}
					}

					// Literal passthrough because the decode failed or we want entities not decoded.
					write_string(&builder, "&")
					write_string(&builder, entity)
					write_string(&builder, ";")
				}
			} else {
				// Handle AV Normalization: https://www.w3.org/TR/2006/REC-xml11-20060816/#AVNormalize
				if .Normalize_Whitespace in options {
					switch t.r {
					case ' ', '\r', '\n', '\t':
						if prev != ' ' {
							write_rune(&builder, ' ')
							prev = ' '
						}
					case:
						write_rune(&builder, t.r)
						prev = t.r
					}
				} else {
					// https://www.w3.org/TR/2006/REC-xml11-20060816/#sec-line-ends
					switch t.r {
					case '\n', 0x85, 0x2028:
						write_rune(&builder, '\n')
					case '\r': // Do nothing until next character
					case:
						if prev == '\r' { // Turn a single carriage return into a \n
							write_rune(&builder, '\n')
						}
						write_rune(&builder, t.r)
					}
					prev = t.r
				}
			}
		}
	}
	return strings.clone(strings.to_string(builder), allocator), err
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
				} else if t.r == utf8.RUNE_BOM && t.offset > 0 {
					return .Illegal_BOM
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
	s := s
	if len(s) < 2 {
		return
	}
	if s[0] != '&' {
		return
	}
	j = 1

	if s[j] == '#' { // scan numbers
		j += 1
		if len(s) <= 3 { // remove `&#.`
			return
		}
		c := s[j]
		hex := false
		if c == 'x' || c == 'X' {
			hex = true
			j += 1
		}

		x := rune(0)
		scan_number: for j < len(s) {
			c = s[j]
			j += 1
			if hex {
				switch c {
				case '0'..='9': x = 16*x + rune(c) - '0';      continue scan_number
				case 'a'..='f': x = 16*x + rune(c) - 'a' + 10; continue scan_number
				case 'A'..='F': x = 16*x + rune(c) - 'A' + 10; continue scan_number
				}
			} else {
				switch c {
				case '0'..='9': x = 10*x + rune(c) - '0'; continue scan_number
				}
			}

			// Keep the ';' to check for cases which require it and cases which might not
			if c != ';' {
				j -= 1
			}
			break scan_number
		}


		if j <= 3 { // no replacement characters found
			return
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

		switch x {
		case 0x80..<0xa0:
			x = windows_1252_replacement_table[x-0x80]
		case 0, 0xd800..=0xdfff:
			x = utf8.RUNE_ERROR
		case:
			if x > 0x10ffff {
				x = utf8.RUNE_ERROR
			}

		}

		b1, w1 := utf8.encode_rune(x)
		w += copy(b[:], b1[:w1])
		return
	}

	// Lookup by entity names

	scan_ident: for j < len(s) { // scan over letters and digits
		c := s[j]
		j += 1

		switch c {
		case 'a'..='z', 'A'..='Z', '0'..='9':
			continue scan_ident
		}
		// Keep the ';' to check for cases which require it and cases which might not
		if c != ';' {
			j -= 1
		}
		break scan_ident
	}

	entity_name := s[1:j]
	if len(entity_name) == 0 {
		return
	}

	if entity_name[len(entity_name)-1] == ';' {
		entity_name = entity_name[:len(entity_name)-1]
	}

	if r2, _, ok := named_xml_entity_to_rune(entity_name); ok {
		b1, w1 := utf8.encode_rune(r2[0])
		w += copy(b[w:], b1[:w1])
		if r2[1] != 0 {
			b2, w2 := utf8.encode_rune(r2[1])
			w += copy(b[w:], b2[:w2])
		}
		return
	}

	// The longest entities that do not end with a semicolon are <=6 bytes long
	LONGEST_ENTITY_WITHOUT_SEMICOLON :: 6

	n := min(len(entity_name)-1, LONGEST_ENTITY_WITHOUT_SEMICOLON)
	for i := n; i > 1; i -= 1 {
		if r2, _, ok := named_xml_entity_to_rune(entity_name[:i]); ok {
			b1, w1 := utf8.encode_rune(r2[0])
			w += copy(b[w:], b1[:w1])
			if r2[1] != 0 {
				b2, w2 := utf8.encode_rune(r2[1])
				w += copy(b[w:], b2[:w2])
			}
			return
		}
	}

	return
}


// Private XML helper to extract `&<stuff>;` entity.
@(private="file")
_extract_xml_entity :: proc(t: ^Tokenizer) -> (entity: string, err: Error) {
	assert(t != nil && t.r == '&')

	// All of these would be in the ASCII range.
	// Even if one is not, it doesn't matter. All characters we need to compare to extract are.

	length := len(t.src)
	found  := false

	#no_bounds_check {
		for t.read_offset < length {
			if t.src[t.read_offset] == ';' {
				t.read_offset += 1
				found = true
				break
			}
			t.read_offset += 1
		}
	}

	if found {
		return string(t.src[t.offset + 1 : t.read_offset - 1]), .None
	}
	return string(t.src[t.offset : t.read_offset]), .Invalid_Entity_Encoding
}

// Private XML helper for CDATA and comments.
@(private="file")
_handle_xml_special :: proc(t: ^Tokenizer, builder: ^strings.Builder, options: XML_Decode_Options) -> (in_data: bool, err: Error) {
	assert(t != nil && t.r == '<')
	if t.read_offset + len(CDATA_START) >= len(t.src) { return false, .None }

	s := string(t.src[t.offset:])
	if strings.has_prefix(s, CDATA_START) {
		if .Unbox_CDATA in options && .Decode_CDATA in options {
			// We're unboxing _and_ decoding CDATA
			t.read_offset += len(CDATA_START) - 1
			return true, .None
		}

		// CDATA is passed through. Scan until end of CDATA.
		start_offset  := t.offset
		t.read_offset += len(CDATA_START)
		for {
			advance(t)
			if t.r < 0 {
				// error(t, offset, "[scan_string] CDATA was not terminated\n")
				return true, .CDATA_Not_Terminated
			}

			// Scan until the end of a CDATA tag.
			if s = string(t.src[t.read_offset:]); strings.has_prefix(s, CDATA_END) {
				t.read_offset += len(CDATA_END)
				cdata := string(t.src[start_offset:t.read_offset])

				if .Unbox_CDATA in options {
					cdata = cdata[len(CDATA_START):]
					cdata = cdata[:len(cdata) - len(CDATA_END)]
				}
				write_string(builder, cdata)
				return false, .None
			}
		}


	} else if strings.has_prefix(s, COMMENT_START) {
		t.read_offset += len(COMMENT_START)
		// Comment is passed through by default.
		offset := t.offset

		// Scan until end of Comment.
		for {
			advance(t) or_return
			if t.r < 0 { return true, .Comment_Not_Terminated }

			if t.read_offset + len(COMMENT_END) < len(t.src) {
				if string(t.src[t.offset:][:len(COMMENT_END)]) == COMMENT_END {
					t.read_offset += len(COMMENT_END) - 1

					if .Comment_Strip not_in options {
						comment := string(t.src[offset : t.read_offset])
						write_string(builder, comment)
					}
					return false, .None
				}
			}
		}

	}
	return false, .None
}
