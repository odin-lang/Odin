package html

import "base:runtime"
import "core:fmt"
import "core:strings"
import "core:unicode/utf8"

// escape_string escapes special characters like '&' to become '&amp;'.
// It escapes only 5 different characters: & ' < > and ".
@(require_results)
escape_string :: proc(s: string, allocator := context.allocator, loc := #caller_location) -> (output: string, was_allocation: bool) {
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
		s := ""
		switch c {
		case '&':  s = "&amp;"
		case '\'': s = "&#39;"
		case '<':  s = "&lt;"
		case '>':  s = "&gt;"
		case '"':  s = "&#34;"
		}
		if s != "" {
			copy(t[w:], s)
			w += len(s)
		} else {
			t[w] = c
			w += 1
		}
	}
	output = string(t[0:w])
	return
}

@(require_results)
unescape_string :: proc(s: string, entity_map: Entity_Map, allocator := context.allocator, loc := #caller_location) -> (output: string, was_allocation: bool, err: runtime.Allocator_Error) {
	@(require_results)
	do_append :: proc(s: string, amp_idx: int, entity_map: Entity_Map, buf: ^[dynamic]byte) -> (n: int) {
		s, amp_idx := s, amp_idx

		n += len(s[:amp_idx])
		if buf != nil { append(buf, s[:amp_idx]) }
		s = s[amp_idx:]
		for len(s) > 0 {
			b, w, j := unescape_entity(s, entity_map)
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
	bytes_required := do_append(s, amp_idx, entity_map, nil)

	buf := make([dynamic]byte, 0, bytes_required, allocator, loc) or_return
	was_allocation = true

	_ = do_append(s, amp_idx, entity_map, &buf)

	assert(len(buf) == cap(buf))
	output = string(buf[:])

	return
}

// Returns an unescaped string of an encoded HTML entity.
@(require_results)
unescape_entity :: proc(s: string, entity_map: Entity_Map) -> (b: [8]byte, w: int, j: int) {
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

	if r, ok := entity_map.entity1[entity_name]; ok {
		b1, w1 := utf8.encode_rune(r)
		copy(b[:], b1[:w1])
		w = w1
		return
	}

	if r2, ok := entity_map.entity2[entity_name]; ok {
		b1, w1 := utf8.encode_rune(r2[0])
		b2, w2 := utf8.encode_rune(r2[1])
		w += copy(b[w:], b1[:w1])
		w += copy(b[w:], b2[:w2])
		return
	}

	// The longest entities that do not end with a semicolon are <=6 bytes long
	LONGEST_ENTITY_WITHOUT_SEMICOLON :: 6

	n := min(len(entity_name)-1, LONGEST_ENTITY_WITHOUT_SEMICOLON)
	for i := n; i > 1; i -= 1 {
		if r, ok := entity_map.entity1[entity_name[:i]]; ok {
			b1, w1 := utf8.encode_rune(r)
			copy(b[:], b1[:w1])
			w = w1
			return
		}
	}

	return
}
