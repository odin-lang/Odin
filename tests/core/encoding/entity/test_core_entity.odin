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

@(test)
test_unescape_html :: proc(t: ^testing.T) {
	Unescape_Case :: struct {
		src: string,
		out: string,
	}
	cases := [?]Unescape_Case{
		{"plain",          "plain"},
		{"a&",             "a&"},
		{"&",              "&"},
		{"&&amp;",         "&&"},
		{"AT&T rocks",     "AT&T rocks"},
		{"a&b",            "a&b"},
		{"&;",             "&;"},
		{"&#",             "&#"},
		{"&#;x",           "&#;x"},
		{"&#x",            "&#x"},
		{"&#x;",           "&#x;"},
		{"&#xg;",          "&#xg;"},
		{"&#1",            "\u0001"},
		{"&#65",           "A"},
		{"&#65;x",         "Ax"},
		{"&#65x",          "Ax"},
		{"&#x41;",         "A"},
		{"&#X41;",         "A"},
		{"&#x41g",         "Ag"},
		{"&#0;",           "\ufffd"},
		{"&#xd800;",       "\ufffd"},
		{"&#x10ffff;",     "\U0010ffff"},
		{"&#x110000;",     "\ufffd"},
		{"&#4294967361;",  "\ufffd"},
		{"&#00000000065;", "A"},
		{"&#x80;",         "\u20ac"},
		{"&#x81;",         "\u0081"},
		{"&#150;",         "\u2013"},
		{"&Alpha;",        "\u0391"},
		{"&Alpha",         "&Alpha"},
		{"&Alphax",        "&Alphax"},
		{"&notin;",        "\u2209"},
		{"&notit;",        "\u00acit;"},
		{"&amp",           "&"},
		{"&amp;",          "&"},
		{"&ampx",          "&x"},
		{"&AMP;&COPY",     "&\u00a9"},
		{"&apos;",         "'"},
		{"&apos",          "&apos"},
		{"&TRADE;",        "\u2122"},
		{"&TRADE",         "&TRADE"},
		{"&frac34;",       "\u00be"},
		{"&frac345",       "\u00be5"},
		{"&copy2024",      "\u00a92024"},
		{"&nGt;",          "\u226b\u20d2"},
		{"&Agr;",          "&Agr;"},
		{"&lowast;",       "\u2217"},
	}
	for c in cases {
		out, allocated, err := entity.unescape_html(c.src)
		testing.expect_value(t, err, nil)
		testing.expectf(t, out == c.out, "%q: expected %q, got %q", c.src, c.out, out)
		testing.expectf(t, allocated == (strings.index_byte(c.src, '&') >= 0), "%q: allocated = %v", c.src, allocated)
		if allocated {
			delete(out)
		}
	}
}

@(test)
test_percent_encode :: proc(t: ^testing.T) {
	Encode_Case :: struct {
		src: string,
		out: string,
	}
	cases := [?]Encode_Case{
		{"",                      ""},
		{"azAZ09-._~",            "azAZ09-._~"},
		{"a b",                   "a%20b"},
		{"%",                     "%25"},
		{"+",                     "%2B"},
		{":/?#[]@!$&'()*,;=",     "%3A%2F%3F%23%5B%5D%40%21%24%26%27%28%29%2A%2C%3B%3D"},
		{"\u00fc",                "%C3%BC"},
		{"\xff\x00",              "%FF%00"},
	}
	for c in cases {
		out, allocated, err := entity.percent_encode(c.src)
		testing.expect_value(t, err, nil)
		testing.expectf(t, out == c.out, "%q: expected %q, got %q", c.src, c.out, out)
		testing.expectf(t, allocated == (c.src != c.out), "%q: allocated = %v", c.src, allocated)
		if allocated {
			delete(out)
		}
	}
}

@(test)
test_percent_decode :: proc(t: ^testing.T) {
	Decode_Percent_Case :: struct {
		src: string,
		out: string,
		err: entity.Percent_Error,
	}
	cases := [?]Decode_Percent_Case{
		{"",             "",          nil},
		{"plain+text",   "plain+text", nil},
		{"a%20b",        "a b",       nil},
		{"%c3%bc%C3%BC", "\u00fc\u00fc", nil},
		{"%25%32%35",    "%25",       nil},
		{"%FF%00",       "\xff\x00",  nil},
		{"%",            "",          entity.Error.Invalid_Entity_Encoding},
		{"a%2",          "",          entity.Error.Invalid_Entity_Encoding},
		{"%%",           "",          entity.Error.Invalid_Entity_Encoding},
		{"%zz",          "",          entity.Error.Invalid_Entity_Encoding},
		{"%0x41",        "",          entity.Error.Invalid_Entity_Encoding},
		{"%+1",          "",          entity.Error.Invalid_Entity_Encoding},
	}
	for c in cases {
		out, allocated, err := entity.percent_decode(c.src)
		testing.expectf(t, err == c.err, "%q: expected %v, got %v", c.src, c.err, err)
		testing.expectf(t, out == c.out, "%q: expected %q, got %q", c.src, c.out, out)
		testing.expectf(t, allocated == (err == nil && c.src != c.out), "%q: allocated = %v", c.src, allocated)
		if allocated {
			delete(out)
		}
	}
}

@(test)
test_escape_html :: proc(t: ^testing.T) {
	Escape_Case :: struct {
		src: string,
		out: string,
	}
	cases := [?]Escape_Case{
		{"",                                 ""},
		{"plain text",                       "plain text"},
		{"&",                                "&amp;"},
		{"'",                                "&#39;"},
		{"<",                                "&lt;"},
		{">",                                "&gt;"},
		{"\"",                               "&#34;"},
		{"&amp;",                            "&amp;amp;"},
		{"<a href=\"x\">Tom & Jerry's</a>",  "&lt;a href=&#34;x&#34;&gt;Tom &amp; Jerry&#39;s&lt;/a&gt;"},
		{"\u00e9\xff\x00",                   "\u00e9\xff\x00"},
	}
	for c in cases {
		out, allocated := entity.escape_html(c.src)
		testing.expectf(t, out == c.out, "%q: expected %q, got %q", c.src, c.out, out)
		testing.expectf(t, allocated == (c.src != c.out), "%q: allocated = %v", c.src, allocated)

		back, back_allocated, back_err := entity.unescape_html(out)
		testing.expect_value(t, back_err, nil)
		testing.expectf(t, back == c.src, "%q: round trip gave %q", c.src, back)
		if back_allocated {
			delete(back)
		}
		if allocated {
			delete(out)
		}
	}
}

@(test)
test_unescape_entity :: proc(t: ^testing.T) {
	Entity_Case :: struct {
		src:      string,
		out:      string,
		consumed: int,
	}
	cases := [?]Entity_Case{
		{"",           "",                0},
		{"x&amp;",     "",                0},
		{"&",          "&",               1},
		{"& x",        "&",               1},
		{"&#;",        "&",               1},
		{"&#x;",       "&",               1},
		{"&nosuch;",   "&",               1},
		{"&amp;rest",  "&",               5},
		{"&amp rest",  "&",               4},
		{"&#65;x",     "A",               5},
		{"&#65x",      "A",               4},
		{"&#x41;",     "A",               6},
		{"&#x10ffff;", "\U0010ffff",      10},
		{"&#0;",       "\ufffd",          4},
		{"&#x80;",     "\u20ac",          6},
		{"&notit;",    "\u00ac",          4},
		{"&nGt;",      "\u226b\u20d2",    5},
	}
	for c in cases {
		b, w, j := entity.unescape_entity(c.src)
		testing.expectf(t, string(b[:w]) == c.out && j == c.consumed, "%q: expected %q and %v consumed, got %q and %v", c.src, c.out, c.consumed, string(b[:w]), j)
	}
}

@(test)
test_xml_decode_entity :: proc(t: ^testing.T) {
	Rune_Case :: struct {
		src:   string,
		runes: [2]rune,
		count: int,
		ok:    bool,
	}
	cases := [?]Rune_Case{
		{"amp",                    {'&', 0},                  1, true},
		{"#65",                    {'A', 0},                  1, true},
		{"#x41",                   {'A', 0},                  1, true},
		{"#9",                     {'\t', 0},                 1, true},
		{"#x10FFFF",               {'\U0010ffff', 0},         1, true},
		{"nGt",                    {'\u226b', '\u20d2'},      2, true},
		{"",                       {},                        0, false},
		{"#",                      {},                        0, false},
		{"#x",                     {},                        0, false},
		{"#6a",                    {},                        0, false},
		{"#xg",                    {},                        0, false},
		{"#0",                     {},                        0, false},
		{"#xD800",                 {},                        0, false},
		{"#xFFFE",                 {},                        0, false},
		{"#x110000",               {},                        0, false},
		{"#99999999999999999999",  {},                        0, false},
		{"nosuch",                 {},                        0, false},
	}
	for c in cases {
		runes, count, ok := entity.xml_decode_entity(c.src)
		testing.expectf(t, ok == c.ok, "%q: expected ok = %v, got %v", c.src, c.ok, ok)
		if ok && c.ok {
			testing.expectf(t, count == c.count && runes[0] == c.runes[0] && (count < 2 || runes[1] == c.runes[1]), "%q: expected %v %v, got %v %v", c.src, c.runes, c.count, runes, count)
		}
	}
}

@(test)
test_decode_xml_sb :: proc(t: ^testing.T) {
	builder := strings.builder_make()
	defer strings.builder_destroy(&builder)
	strings.write_string(&builder, "pre:")

	decoded, err := entity.decode_xml_sb(&builder, "a&amp;b<![CDATA[&lt;]]>")
	testing.expect_value(t, err, entity.Error.None)
	testing.expect_value(t, decoded, "a&b&lt;")
	testing.expect_value(t, strings.to_string(builder), "pre:a&b&lt;")

	empty, empty_err := entity.decode_xml_sb(&builder, "")
	testing.expect_value(t, empty_err, entity.Error.None)
	testing.expect_value(t, empty, "")
	testing.expect_value(t, strings.to_string(builder), "pre:a&b&lt;")

	html, html_err := entity.decode_xml_sb(&builder, "&copy;", {.HTML_Entities})
	testing.expect_value(t, html_err, entity.Error.None)
	testing.expect_value(t, html, "\u00a9")
	testing.expect_value(t, strings.to_string(builder), "pre:a&b&lt;\u00a9")

	_, bad_err := entity.decode_xml_sb(&builder, "x&bad;")
	testing.expect_value(t, bad_err, entity.Error.Unknown_Entity)
}
