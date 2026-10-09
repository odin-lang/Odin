package odin_libc

import "core:c"

@(require, linkage="strong", link_name="wcslen")
wcslen :: proc "c" (str: [^]c.wchar_t) -> uint {
	n: uint
	for str[n] != 0 {
		n += 1
	}
	return n
}

// "C" locale semantics: code points 0..=0x7F convert to one byte each; anything
// else fails with EILSEQ, as wcsrtombs does in the "C" locale.
@(require, linkage="strong", link_name="wcsrtombs")
wcsrtombs :: proc "c" (dst: [^]byte, src: ^[^]c.wchar_t, len: uint, ps: rawptr) -> uint {
	s := src^
	n: uint
	for {
		ch := s[n]
		if ch < 0 || ch > 0x7F {
			_errno = EILSEQ
			return max(uint)
		}
		if dst != nil {
			if n >= len {
				src^ = s[n:]
				return n
			}
			dst[n] = byte(ch)
		}
		if ch == 0 {
			if dst != nil {
				src^ = nil
			}
			return n
		}
		n += 1
	}
}
