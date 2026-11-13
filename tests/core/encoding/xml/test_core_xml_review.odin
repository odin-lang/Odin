package test_core_xml

import "core:encoding/xml"
import "core:fmt"
import "core:mem"
import "core:strings"
import "core:testing"

Review_Case :: struct {
	src:   string,
	flags: xml.Option_Flags,
	err:   xml.Error,
	tree:  string,
}

@(private="file")
write_tree :: proc(b: ^strings.Builder, doc: ^xml.Document, id: xml.Element_ID) {
	el := doc.elements[id]
	if el.kind == .Comment {
		fmt.sbprint(b, "!")
		for v in el.value {
			if s, ok := v.(string); ok {
				fmt.sbprintf(b, "%q", s)
			}
		}
		return
	}
	strings.write_string(b, el.ident)
	if len(el.attribs) > 0 {
		strings.write_byte(b, '[')
		for a, i in el.attribs {
			if i > 0 {
				strings.write_byte(b, ' ')
			}
			fmt.sbprintf(b, "%v=%q", a.key, a.val)
		}
		strings.write_byte(b, ']')
	}
	strings.write_byte(b, '{')
	for v, i in el.value {
		if i > 0 {
			strings.write_byte(b, ',')
		}
		switch x in v {
		case string:         fmt.sbprintf(b, "%q", x)
		case xml.Element_ID: write_tree(b, doc, x)
		}
	}
	strings.write_byte(b, '}')
}

@(private="file")
tree :: proc(doc: ^xml.Document) -> string {
	b := strings.builder_make()
	if doc != nil && doc.element_count > 0 {
		write_tree(&b, doc, 0)
	}
	return strings.to_string(b)
}

@(private="file")
run_review_cases :: proc(t: ^testing.T, cases: []Review_Case, loc := #caller_location) {
	for c in cases {
		doc, err := xml.parse_string(c.src, xml.Options{flags = c.flags}, error_handler = Silent)
		defer xml.destroy(doc)

		testing.expectf(t, err == c.err, "%q %v: expected %v, got %v", c.src, c.flags, c.err, err, loc=loc)
		if err == .None && c.err == .None {
			got := tree(doc)
			defer delete(got)
			testing.expectf(t, got == c.tree, "%q %v: expected %v, got %v", c.src, c.flags, c.tree, got, loc=loc)
		}
	}
}

@(test)
xml_test_review_bang_bracket :: proc(t: ^testing.T) {
	cases := [?]Review_Case{
		{src = "<a><![CDTA[x]]></a>",          flags = {.Ignore_Unsupported},   tree = "a{}"},
		{src = "<a><![INCLUDE[ x ]]></a>",     flags = {.Ignore_Unsupported},   tree = "a{}"},
		{src = "<a><![CDTA[x]]></a>",          flags = {.Error_On_Unsupported}, err  = .Unhandled_Bang},
		{src = "<a><![x",                      flags = {.Ignore_Unsupported},   err  = .Premature_EOF},
		{src = "<a>x<![CDATA[<y>]]>z</a>",     flags = {.Ignore_Unsupported},   tree = `a{"x<![CDATA[<y>]]>z"}`},
		{src = "<a><![CDATA[<y>]]>z</a>",      flags = {.Ignore_Unsupported},   tree = `a{"<![CDATA[<y>]]>z"}`},
	}
	run_review_cases(t, cases[:])
}

@(test)
xml_test_review_mid_document_bom :: proc(t: ^testing.T) {
	cases := [?]Review_Case{
		{src = "<a b=\"x\xef\xbb\xbfy\">x\xef\xbb\xbfy&amp;</a>", flags = {.Decode_SGML_Entities},      tree = `a[b="x\ufeffy"]{"x\ufeffy&"}`},
		{src = "\xef\xbb\xbf<a>\xef\xbb\xbf</a>",                 flags = {.Decode_SGML_Entities},      tree = `a{"\ufeff"}`},
	}
	run_review_cases(t, cases[:])
}

@(test)
xml_test_review_destroy_uses_parse_allocator :: proc(t: ^testing.T) {
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	defer mem.tracking_allocator_destroy(&track)

	doc, err := xml.parse_string(`<a b="c">d<e/></a>`, error_handler = Silent, allocator = mem.tracking_allocator(&track))
	testing.expect_value(t, err, xml.Error.None)
	xml.destroy(doc)

	testing.expect_value(t, len(track.allocation_map), 0)
	testing.expect_value(t, len(track.bad_free_array), 0)
}

@(test)
xml_test_review_caller_keeps_input :: proc(t: ^testing.T) {
	data := make([]u8, 16)
	defer delete(data)
	copy(data, `<a b="c">d</a>`)

	doc, err := xml.parse_bytes(data[:14], xml.Options{flags = {.Input_May_Be_Modified}}, error_handler = Silent)
	testing.expect_value(t, err, xml.Error.None)
	xml.destroy(doc)
}

@(test)
xml_test_review_line_ends :: proc(t: ^testing.T) {
	cases := [?]Review_Case{
		{src = "<a>p\r\nq\rr\n\rs</a>",                             tree = `a{"p\nq\nr\n\ns"}`},
		{src = "<a>p\r\nq\rr</a>",  flags = {.Decode_SGML_Entities}, tree = `a{"p\nq\nr"}`},
		{src = "<a>p<!--x\r\ny-->q</a>", flags = {.Keep_Tag_Body_Comments, .Unbox_CDATA}, tree = `a{"p<!--x\ny-->q"}`},
		{src = "<a>p<![CDATA[x\r\ny]]>q</a>",                       tree = `a{"p<![CDATA[x\ny]]>q"}`},
		{src = "<a>p<![CDATA[x\ry]]>q</a>", flags = {.Unbox_CDATA},  tree = `a{"px\nyq"}`},
		{src = "\r\n<a>x</a>\r\n",                                  tree = `a{"x"}`},
	}
	run_review_cases(t, cases[:])
}

@(thread_local, private="file")
last_error_pos: xml.Pos

@(private="file")
remember_pos :: proc(pos: xml.Pos, format: string, args: ..any) {
	last_error_pos = pos
}

@(test)
xml_test_review_illegal_characters :: proc(t: ^testing.T) {
	Case :: struct {
		src:    string,
		line:   int,
		column: int,
	}
	cases := [?]Case{
		{"<a>\x00</a>",            1, 4},
		{"<a>\x01</a>",            1, 4},
		{"<a>\x1f</a>",            1, 4},
		{"<a>\xff</a>",            1, 4},
		{"<a>\xc0\x80</a>",        1, 4},
		{"<a>\xed\xa0\x80</a>",    1, 4},
		{"<a>\xef\xbf\xbe</a>",    1, 4},
		{"<a>\xef\xbf\xbf</a>",    1, 4},
		{"<a b=\"\x02\"/>",        1, 7},
		{"<a>\r\nx\r\nyz\x0b</a>", 3, 3},
		{"<a>\r\nx\rabc\x0c</a>",  3, 4},
	}
	for c in cases {
		last_error_pos = {}
		doc, err := xml.parse_string(c.src, error_handler = remember_pos)
		xml.destroy(doc)
		testing.expectf(t, err == .Invalid_Token, "%q: expected Invalid_Token, got %v", c.src, err)
		testing.expectf(t, last_error_pos.line == c.line && last_error_pos.column == c.column, "%q: expected %v:%v, got %v:%v", c.src, c.line, c.column, last_error_pos.line, last_error_pos.column)
	}

	legal := [?]string{
		"<a>\t\x7f\xc2\x80\xc2\x85\xe2\x80\xa8\xef\xbf\xbd\xf4\x8f\xbf\xbd</a>",
	}
	for src in legal {
		doc, err := xml.parse_string(src, error_handler = Silent)
		xml.destroy(doc)
		testing.expectf(t, err == .None, "%q: expected None, got %v", src, err)
	}
}

@(test)
xml_test_review_input_may_be_modified :: proc(t: ^testing.T) {
	doc, err := xml.parse_string("<a>x\r\ny</a>", xml.Options{flags = {.Input_May_Be_Modified}}, error_handler = Silent)
	testing.expect_value(t, err, xml.Error.None)
	xml.destroy(doc)

	data := make([]u8, 11)
	defer delete(data)
	copy(data, "<a>x\r\ny</a>")
	doc, err = xml.parse_bytes(data, xml.Options{flags = {.Input_May_Be_Modified}}, error_handler = Silent)
	defer xml.destroy(doc)
	testing.expect_value(t, err, xml.Error.None)
	testing.expect_value(t, string(data[:10]), "<a>x\ny</a>")
	if err == .None && len(doc.elements[0].value) == 1 {
		value := doc.elements[0].value[0].(string)
		testing.expect_value(t, value, "x\ny")
		testing.expect(t, raw_data(value) == &data[3], "the value should point into the caller's buffer")
	}
}

@(test)
xml_test_review_document_structure :: proc(t: ^testing.T) {
	cases := [?]Review_Case{
		{src = "<a><b>",                                                  err  = .Premature_EOF},
		{src = "<a><b></b>",                                              err  = .Premature_EOF},
		{src = "<a/></a>",                                                err  = .Mismatched_Closing_Tag},
		{src = "</a>",                                                    err  = .Mismatched_Closing_Tag},
		{src = "<a/><b/>",                                                err  = .Unexpected_Token},
		{src = "<a></a><b/>",                                             err  = .Unexpected_Token},
		{src = "x<a/>",                                                   err  = .Unexpected_Token},
		{src = "<a/>x",                                                   err  = .Unexpected_Token},
		{src = "<![CDATA[x]]><a/>",                                       err  = .Unexpected_Token},
		{src = "<a/><![CDATA[x]]>",                                       err  = .Unexpected_Token},
		{src = "",                                                        err  = .Premature_EOF},
		{src = " \n\t",                                                   err  = .Premature_EOF},
		{src = "<!--c-->",                     flags = {.Intern_Comments}, err  = .Premature_EOF},
		{src = "<?xml version=\"1.0\"?>",                                 err  = .Premature_EOF},
		{src = "<a/><?xml version=\"1.0\"?>",                             err  = .Invalid_Prolog},
		{src = "<a/><?xml version=\"1.0\"?>",  flags = {.Must_Have_Prolog}, err = .Invalid_Prolog},
		{src = " <?xml version=\"1.0\"?><a/>",                            err  = .Invalid_Prolog},
		{src = "<?xml version=\"1.0\"?><?xml version=\"1.0\"?><a/>",      err  = .Too_Many_Prologs},
		{src = "<?xml version=\"1.0\"?><?xml encoding=\"utf-8\"?><a/>",   err  = .Too_Many_Prologs},
		{src = "<?xml version=\"1.0\"?><?xml-stylesheet href=\"a.css\"?><r/>", tree = "r{}"},
		{src = "<?xml version=\"1.0\"?><a>x<?pi y?>z</a>",                tree = `a{"x","z"}`},
		{src = "\n<a/>\n",                                                tree = "a{}"},
		{src = "<!--b--><a/><!--c-->",         flags = {.Intern_Comments}, tree = "a{}"},
		{src = "<a><b/><c></c></a>",                                      tree = "a{b{},c{}}"},
	}
	run_review_cases(t, cases[:])

	doc, err := xml.parse_string("<!--b--><a><!--x--></a><!--c-->", xml.Options{flags = {.Intern_Comments}}, error_handler = Silent)
	defer xml.destroy(doc)
	testing.expect_value(t, err, xml.Error.None)
	testing.expect_value(t, len(doc.comments), 2)
	if len(doc.comments) == 2 {
		testing.expect_value(t, doc.comments[0], "b")
		testing.expect_value(t, doc.comments[1], "c")
	}
}

@(test)
xml_test_review_names :: proc(t: ^testing.T) {
	cases := [?]Review_Case{
		{src = "<maven.compiler.source>17</maven.compiler.source>", tree = `maven.compiler.source{"17"}`},
		{src = "<a.b c.d=\"1\"/>",                                   tree = `a.b[c.d="1"]{}`},
		{src = "<a\u00b7b/>",                                        tree = "a\u00b7b{}"},
		{src = "<a\u0301b/>",                                        tree = "a\u0301b{}"},
		{src = "<a\u203fb/>",                                        tree = "a\u203fb{}"},
		{src = "<:a/>",                                              tree = ":a{}"},
		{src = "<_a-b.c:d/>",                                        tree = "_a-b.c:d{}"},
		{src = "<\u00c0\u037f\u3001\U00010000/>",                    tree = "\u00c0\u037f\u3001\U00010000{}"},
		{src = "<.a/>",                                              err  = .Unexpected_Token},
		{src = "<1a/>",                                              err  = .Unexpected_Token},
		{src = "<-a/>",                                              err  = .Unexpected_Token},
		{src = "<\u00b7a/>",                                         err  = .Unexpected_Token},
		{src = "<\u0301a/>",                                         err  = .Unexpected_Token},
		{src = "<a\u037eb/>",                                        err  = .Unexpected_Token},
		{src = "<a\u00d7b/>",                                        err  = .Unexpected_Token},
	}
	run_review_cases(t, cases[:])
}

@(test)
xml_test_review_skipping :: proc(t: ^testing.T) {
	cases := [?]Review_Case{
		{src = "<!DOCTYPE a [ <!-- don't --> <!ELEMENT a ANY> ]><a>x</a>", tree = `a{"x"}`},
		{src = "<!DOCTYPE a [ <!ENTITY e \"x\ny\"> ]><a/>",                 tree = "a{}"},
		{src = "<!DOCTYPE a [ <!ENTITY e '<b>'> ]><a/>",                    tree = "a{}"},
		{src = "<!DOCTYPE a [ <?pi > ?> ]><a/>",                            tree = "a{}"},
		{src = "<!DOCTYPE a [ <!ENTITY e \"x",                              err  = .Premature_EOF},
		{src = "<a>x<?pi a > b?>y</a>",                                     tree = `a{"x","y"}`},
		{src = "<?pi a > b?><a/>",                                          tree = "a{}"},
		{src = "<a><?pi a > b",                                             err  = .Premature_EOF},
		{src = "<a><!FOO \"x>y\"></a>", flags = {.Ignore_Unsupported},      tree = "a{}"},
	}
	run_review_cases(t, cases[:])

	doc, err := xml.parse_string("<!DOCTYPE a [ <!-- don't --> ]><a/>", error_handler = Silent)
	defer xml.destroy(doc)
	testing.expect_value(t, err, xml.Error.None)
	if err == .None {
		testing.expect_value(t, doc.doctype.rest, "[ <!-- don't --> ]")
	}

	last_error_pos = {}
	doc2, err2 := xml.parse_string("<!DOCTYPE a [\n<!ELEMENT a ANY>\n]>\n<?pi\n?>\n<a></b>", error_handler = remember_pos)
	defer xml.destroy(doc2)
	testing.expect_value(t, err2, xml.Error.Mismatched_Closing_Tag)
	testing.expect_value(t, last_error_pos.line, 6)
}

@(test)
xml_test_review_markup_in_body :: proc(t: ^testing.T) {
	cases := [?]Review_Case{
		{src = "<a>x<!--c--><!--d-->y</a>",                                  tree = `a{"x<!--c--><!--d-->y"}`},
		{src = "<a>x<!--c--><!--d-->y</a>",     flags = {.Intern_Comments}, tree = `a{"x<!--c--><!--d-->y"}`},
		{src = "<a>x<!--c--><b/></a>",                                       tree = `a{"x<!--c-->",b{}}`},
		{src = "<a>x<![CDATA[1]]><![CDATA[2]]><b/></a>",                     tree = `a{"x<![CDATA[1]]><![CDATA[2]]>",b{}}`},
		{src = "<a>x<!---->y</a>",                                           tree = `a{"x<!---->y"}`},
		{src = "<a>x<!---y-->z</a>",                                         tree = `a{"x<!---y-->z"}`},
		{src = "<a>x<!-- y --->z</a>",                                       err  = .Invalid_Sequence_In_Comment},
		{src = "<a>x<!--c",                                                  err  = .Unclosed_Comment},
		{src = "<a>x<![CDATA[y",                                             err  = .Premature_EOF},
		{src = "<a><!--c-->x</a>",              flags = {.Intern_Comments}, tree = `a{!"c","x"}`},
		{src = "<a><!----></a>",                flags = {.Intern_Comments}, tree = `a{!""}`},
		{src = "<a><!-x --></a>",                                            err  = .Unexpected_Token},
		{src = "<a><! --x--></a>",                                           err  = .Unexpected_Token},
		{src = "<a><!- -x--></a>",                                           err  = .Unexpected_Token},
		{src = "<a><!></a>",                                                 err  = .Unexpected_Token},
		{src = "<a><!\"x\"></a>",                                            err  = .Unexpected_Token},
	}
	run_review_cases(t, cases[:])

	last_error_pos = {}
	doc, err := xml.parse_string("<a>x<![CDATA[\n\n]]><!--\n-->\n</b>", error_handler = remember_pos)
	defer xml.destroy(doc)
	testing.expect_value(t, err, xml.Error.Mismatched_Closing_Tag)
	testing.expect_value(t, last_error_pos.line, 5)
}
