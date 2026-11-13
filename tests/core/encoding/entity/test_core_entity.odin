package test_core_entity

import "core:encoding/entity"
import "core:testing"

Decode_Case :: struct {
	src:     string,
	options: entity.XML_Decode_Options,
	out:     string,
	err:     entity.Error,
}

@(private="file")
run_decode_cases :: proc(t: ^testing.T, cases: []Decode_Case, loc := #caller_location) {
	for c in cases {
		out, err := entity.decode_xml(c.src, c.options)
		defer delete(out)
		testing.expectf(t, err == c.err, "%q %v: expected %v, got %v", c.src, c.options, c.err, err, loc=loc)
		if err == .None && c.err == .None {
			testing.expectf(t, out == c.out, "%q %v: expected %q, got %q", c.src, c.options, c.out, out, loc=loc)
		}
	}
}

@(test)
test_decode_xml_bom :: proc(t: ^testing.T) {
	cases := [?]Decode_Case{
		{src = "a\xef\xbb\xbfb&amp;",                 out = "a\xef\xbb\xbfb&"},
		{src = "\xef\xbb\xbf&lt;",                    out = "\xef\xbb\xbf<"},
		{src = "<![CDATA[a\xef\xbb\xbfb]]>&amp;",     out = "<![CDATA[a\xef\xbb\xbfb]]>&"},
	}
	run_decode_cases(t, cases[:])
}
