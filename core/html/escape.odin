package html

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