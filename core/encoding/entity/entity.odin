package encoding_unicode_entity
/*
	A unicode entity encoder/decoder

	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-3 license.

	This code has several procedures to map unicode runes to/from different textual encodings.
	- SGML/XML/HTML entity
	-- &#<decimal>;
	-- &#x<hexadecimal>;
	-- &<entity name>;   (If the lookup tables are compiled in).
	Reference: https://www.w3.org/2003/entities/2007xml/unicode.xml	

	- URL encode / decode %hex entity
	Reference: https://datatracker.ietf.org/doc/html/rfc3986/#section-2.1

	List of contributors:
		Jeroen van Rijn: Initial implementation.
*/

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
				If so, write `>` as a literal and continue.
			*/
			if in_data {
				write_rune(&builder, '<')
				continue
			}
			in_data = _handle_xml_special(&t, &builder, options) or_return

		case ']':
			// If we're unboxing _and_ decoding CDATA, we'll have to check for the end tag.
			if in_data {
				if t.read_offset + len(CDATA_END) < len(t.src) {
					if string(t.src[t.offset:][:len(CDATA_END)]) == CDATA_END {
						in_data = false
						t.read_offset += len(CDATA_END) - 1
					}
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
						if decoded, ok := xml_decode_entity(entity); ok {
							write_rune(&builder, decoded)
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

xml_decode_entity :: proc(entity: string) -> (decoded: rune, ok: bool) {
	entity := entity
	if len(entity) == 0 { return -1, false }

	switch entity[0] {
	case '#':
		base  := 10
		val   := 0
		entity = entity[1:]

		if len(entity) == 0 { return -1, false }

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
				if base == 10 { return -1, false }
				val *= base
				val += int(r - 'a' + 10)

			case 'A'..='F':
				if base == 10 { return -1, false }
				val *= base
				val += int(r - 'A' + 10)

			case:
				return -1, false
			}

			if val > MAX_RUNE_CODEPOINT { return -1, false }
			entity = entity[1:]
		}
		return rune(val), true

	case:
		// Named entity.
		return named_xml_entity_to_rune(entity)
	}
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

	if string(t.src[t.offset:][:len(CDATA_START)]) == CDATA_START {
		t.read_offset += len(CDATA_START) - 1

		if .Unbox_CDATA in options && .Decode_CDATA in options {
			// We're unboxing _and_ decoding CDATA
			return true, .None
		}

		// CDATA is passed through.
		offset := t.offset

		// Scan until end of CDATA.
		for {
			advance(t) or_return
			if t.r < 0 { return true, .CDATA_Not_Terminated }

			if t.read_offset + len(CDATA_END) < len(t.src) {
				if string(t.src[t.offset:][:len(CDATA_END)]) == CDATA_END {
					t.read_offset += len(CDATA_END) - 1

					cdata := string(t.src[offset : t.read_offset])
	
					if .Unbox_CDATA in options {
						cdata = cdata[len(CDATA_START):]
						cdata = cdata[:len(cdata) - len(CDATA_END)]
					}

					write_string(builder, cdata)
					return false, .None
				}
			}
		}

	} else if string(t.src[t.offset:][:len(COMMENT_START)]) == COMMENT_START {
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