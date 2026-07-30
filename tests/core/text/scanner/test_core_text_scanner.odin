package test_core_text_scanner

import "core:testing"
import s "core:text/scanner"

@test 
range_operator :: proc(t: ^testing.T) {
	data := "0x00..=0xff"
	h: s.Scanner
	s.init(&h, data, "string")
	h.flags = s.Odin_Like_Tokens - {.Skip_Comments}
	testing.expect(t, s.Int == s.scan(&h), "token should be Int")
	testing.expect(t, '.' == s.scan(&h), "token should be '.'")
	testing.expect(t, '.' == s.scan(&h), "token should be '.'")
	testing.expect(t, '=' == s.scan(&h), "token should be '='")
	testing.expect(t, s.Int == s.scan(&h), "token should be Int")
	testing.expect(t, s.EOF == s.scan(&h), "token should be EOF")
}
