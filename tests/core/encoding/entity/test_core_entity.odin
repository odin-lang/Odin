package test_core_entity

import "core:encoding/entity"
import "core:strings"
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
		{src = "<![CDATA[a\xef\xbb\xbfb]]>&amp;",     out = "a\xef\xbb\xbfb&"},
	}
	run_decode_cases(t, cases[:])
}

@(test)
test_decode_xml_markup :: proc(t: ^testing.T) {
	cases := [?]Decode_Case{
		{src = "x<y",                                          out = "x<y"},
		{src = "x<!--c-->",                                    out = "x"},
		{src = "x<!--c-->",           options = {.Keep_Comments}, out = "x<!--c-->"},
		{src = "a<!---->",                                     out = "a"},
		{src = "a<!-- c -->b",                                 out = "ab"},
		{src = "a<!-- &bad; -->b",                             out = "ab"},
		{src = "a<!--x",                                       err = .Comment_Not_Terminated},
		{src = "a<!--\x00-->",                                 err = .Illegal_NUL_Character},
		{src = "<![CDATA[x&amp;]]>",                           out = "x&amp;"},
		{src = "<![CDATA[x&amp;",                              err = .CDATA_Not_Terminated},
		{src = "<![CDATA[<!--c-->]]>",                         out = "<!--c-->"},
		{src = "<![CDATA[a\xffb]]>",                           err = .Illegal_UTF_Encoding},
		{src = "a]]>b",                                        out = "a]]>b"},
	}
	run_decode_cases(t, cases[:])
}

@(test)
test_decode_xml_references :: proc(t: ^testing.T) {
	cases := [?]Decode_Case{
		{src = "&lt;&gt;&amp;&apos;&quot;",                            out = "<>&'\""},
		{src = "&#65;&#x41;&#x4a;&#x4A;",                              out = "AAJJ"},
		{src = "&#9;&#10;&#13;",                                       out = "\t\n\r"},
		{src = "&#x10FFFF;&#xFEFF;",                                   out = "\U0010ffff\ufeff"},
		{src = "a&#13;x",                                              out = "a\rx"},
		{src = "Tom & Jerry",                                          err = .Invalid_Entity_Encoding},
		{src = "&;",                                                   err = .Invalid_Entity_Encoding},
		{src = "&amp",                                                 err = .Invalid_Entity_Encoding},
		{src = "& amp;",                                               err = .Invalid_Entity_Encoding},
		{src = "&#;",                                                  err = .Invalid_Entity_Encoding},
		{src = "&#x;",                                                 err = .Invalid_Entity_Encoding},
		{src = "&#X41;",                                               err = .Invalid_Entity_Encoding},
		{src = "&#65",                                                 err = .Invalid_Entity_Encoding},
		{src = "&#6a;",                                                err = .Invalid_Entity_Encoding},
		{src = "&#0;",                                                 err = .Invalid_Entity_Encoding},
		{src = "&#1;",                                                 err = .Invalid_Entity_Encoding},
		{src = "&#xD800;",                                             err = .Invalid_Entity_Encoding},
		{src = "&#xFFFE;",                                             err = .Invalid_Entity_Encoding},
		{src = "&#x110000;",                                           err = .Invalid_Entity_Encoding},
		{src = "&#99999999999999999999;",                              err = .Invalid_Entity_Encoding},
		{src = "&copy;",                                               err = .Unknown_Entity},
		{src = "&copy;",              options = {.HTML_Entities},         out = "\u00a9"},
		{src = "&nvlt;",              options = {.HTML_Entities},         out = "<\u20d2"},
		{src = "&nosuch;",            options = {.HTML_Entities},         err = .Unknown_Entity},
		{src = "&nosuch;&copy;",      options = {.Keep_Unknown_Entities}, out = "&nosuch;&copy;"},
		{src = "&\u00e9;",                                             err = .Unknown_Entity},
		{src = "&\u00e9;",            options = {.Keep_Unknown_Entities}, out = "&\u00e9;"},
		{src = "&\xff;",              options = {.Keep_Unknown_Entities}, err = .Invalid_Entity_Encoding},
	}
	run_decode_cases(t, cases[:])
}

@(test)
test_decode_xml_line_ends :: proc(t: ^testing.T) {
	cases := [?]Decode_Case{
		{src = "a\r&amp;",            out = "a\n&"},
		{src = "a\r",                 out = "a\n"},
		{src = "a\r\nb\r\r\nc",       out = "a\nb\n\nc"},
		{src = "a\r<!--c-->\nb",      out = "a\n\nb"},
		{src = "<![CDATA[a\r\nb]]>",  out = "a\nb"},
		{src = "a\u0085b\u2028c",     out = "a\u0085b\u2028c"},
	}
	run_decode_cases(t, cases[:])
}

@(test)
test_decode_xml_whitespace :: proc(t: ^testing.T) {
	cases := [?]Decode_Case{
		{src = "  a\t\nb  ",   options = {.Normalize_Attribute}, out = "  a  b  "},
		{src = "a\r\nb\rc",    options = {.Normalize_Attribute}, out = "a b c"},
		{src = "a&#32; b",     options = {.Normalize_Attribute}, out = "a  b"},
		{src = "a&#10;&#9;b",  options = {.Normalize_Attribute}, out = "a\n\tb"},
		{src = "  a\t\nb  ",   options = {.Collapse_Whitespace}, out = "a b"},
		{src = "a&#32; b",     options = {.Collapse_Whitespace}, out = "a b"},
		{src = "&#32;a&#32;",  options = {.Collapse_Whitespace}, out = "a"},
		{src = "a &#10; b",    options = {.Collapse_Whitespace}, out = "a \n b"},
		{src = " \t\n ",       options = {.Collapse_Whitespace}, out = ""},
		{src = "a\t b",                                          out = "a\t b"},
	}
	run_decode_cases(t, cases[:])
}

@(test)
test_decode_xml_in_place :: proc(t: ^testing.T) {
	inputs := [?]string{
		"",
		"abc",
		"a&amp;b",
		"a&#x1F600;b",
		"<![CDATA[x]]>&lt;<!--c-->y",
		"a\r\nb\rc",
		"  a\t\nb  &#32; ",
		"&nvlt;&copy;",
		"x&#13;\r\n",
		"&bad;",
	}
	option_sets := [?]entity.XML_Decode_Options{
		{},
		{.Keep_Comments},
		{.Normalize_Attribute},
		{.Collapse_Whitespace},
		{.HTML_Entities},
		{.Collapse_Whitespace, .HTML_Entities, .Keep_Comments},
		{.Keep_Unknown_Entities},
	}
	for src in inputs {
		for options in option_sets {
			want, want_err := entity.decode_xml(src, options)
			defer delete(want)

			buf := transmute([]u8)strings.clone(src)
			defer delete(buf)

			got, err, _ := entity.decode_xml_in_place(buf, options)
			testing.expectf(t, err == want_err, "%q %v: expected %v, got %v", src, options, want_err, err)
			if err == .None && want_err == .None {
				testing.expectf(t, got == want, "%q %v: expected %q, got %q", src, options, want, got)
				testing.expectf(t, len(got) == 0 || raw_data(got) == raw_data(buf), "%q %v: not decoded in place", src, options)
			} else {
				testing.expectf(t, string(buf) == src, "%q %v: buffer changed on error: %q", src, options, string(buf))
			}
		}
	}

	grow := transmute([]u8)strings.clone("a&nGt;b")
	defer delete(grow)
	got, err, offset := entity.decode_xml_in_place(grow, {.HTML_Entities})
	testing.expect_value(t, err, entity.Error.Buffer_Too_Small)
	testing.expect_value(t, offset, 1)
	testing.expect_value(t, got, "")
	testing.expect_value(t, string(grow), "a&nGt;b")

	grown, grown_err := entity.decode_xml("a&nGt;b", {.HTML_Entities})
	defer delete(grown)
	testing.expect_value(t, grown_err, entity.Error.None)
	testing.expect_value(t, grown, "a\u226b\u20d2b")

	bad := transmute([]u8)strings.clone("a&amp;b&bad;")
	defer delete(bad)
	_, bad_err, bad_offset := entity.decode_xml_in_place(bad, {})
	testing.expect_value(t, bad_err, entity.Error.Unknown_Entity)
	testing.expect_value(t, bad_offset, 7)
	testing.expect_value(t, string(bad), "a&amp;b&bad;")
}

@(test)
test_named_entity_iso_code_points :: proc(t: ^testing.T) {
	Name_Case :: struct {
		name:    string,
		decoded: rune,
	}
	cases := [?]Name_Case{
		{"lowast", 0x2217},
		{"blank",  0x2423},
		{"Aring",  0x00c5},
		{"angst",  0x00c5},
	}
	for c in cases {
		decoded, count, ok := entity.named_xml_entity_to_rune(c.name)
		testing.expectf(t, ok && count == 1 && decoded[0] == c.decoded, "&%v;: expected U+%04X, got %v (%v, %v)", c.name, c.decoded, decoded, count, ok)
	}
}
