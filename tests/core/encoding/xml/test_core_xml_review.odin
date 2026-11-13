package test_core_xml

import "core:encoding/xml"
import "core:fmt"
import "core:io"
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
		{src = "<a>x<![CDATA[<y>]]>z</a>",     flags = {.Ignore_Unsupported},   tree = `a{"x<y>z"}`},
		{src = "<a><![CDATA[<y>]]>z</a>",      flags = {.Ignore_Unsupported},   tree = `a{"<y>z"}`},
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
		{src = "<a>p<!--x\r\ny-->q</a>", flags = {.Keep_Tag_Body_Comments}, tree = `a{"p<!--x\ny-->q"}`},
		{src = "<a>p<![CDATA[x\r\ny]]>q</a>",                       tree = `a{"px\nyq"}`},
		{src = "<a>p<![CDATA[x\ry]]>q</a>",                         tree = `a{"px\nyq"}`},
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
		{src = "<a:b:c x:y:z=\"1\" w:=\"2\"></a:b:c>",               tree = `a:b:c[x:y:z="1" w:="2"]{}`},
		{src = "<a:/>",                                              tree = "a:{}"},
		{src = "<a::b/>",                                            tree = "a::b{}"},
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
		{src = "<!DOCTYPE a><a/>",                                          tree = "a{}"},
		{src = "<!DOCTYPE a[]><a/>",                                        tree = "a{}"},
		{src = "<!DOCTYPE a\n[ ]\n><a/>",                                   tree = "a{}"},
		{src = "<!DOCTYPE a SYSTEM \"a[.dtd\"><a/>",                        tree = "a{}"},
		{src = "<!DOCTYPE a PUBLIC 'p' 'a.dtd' [<!ELEMENT a ANY>]><a/>",    tree = "a{}"},
		{src = "<!DOCTYPE a#><a/>",                                         err  = .Unexpected_Token},
		{src = "<!DOCTYPE a/><a/>",                                         err  = .Unexpected_Token},
		{src = "<!DOCTYPE a [><a/>",                                        err  = .Unexpected_Token},
		{src = "<!DOCTYPE a [<!ELEMENT a ANY>><a/>",                        err  = .Unexpected_Token},
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
		{src = "<a>x<!--c--><!--d-->y</a>",                                  tree = `a{"xy"}`},
		{src = "<a>x<!--c--><!--d-->y</a>",     flags = {.Intern_Comments}, tree = `a{"x",!"c",!"d","y"}`},
		{src = "<a>x<!--c--><!--d-->y</a>",     flags = {.Keep_Tag_Body_Comments}, tree = `a{"x<!--c--><!--d-->y"}`},
		{src = "<a>x<!--c--><b/></a>",                                       tree = `a{"x",b{}}`},
		{src = "<a>x<![CDATA[1]]><![CDATA[2]]><b/></a>",                     tree = `a{"x12",b{}}`},
		{src = "<a>x<!---->y</a>",                                           tree = `a{"xy"}`},
		{src = "<a>x<!---y-->z</a>",                                         tree = `a{"xz"}`},
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

@(test)
xml_test_review_tag_syntax :: proc(t: ^testing.T) {
	cases := [?]Review_Case{
		{src = "< a/>",                    err  = .Unexpected_Token},
		{src = "<a></ a>",                 err  = .Unexpected_Token},
		{src = "<a/ >",                    err  = .Unexpected_Token},
		{src = "<a / >",                   err  = .Unexpected_Token},
		{src = "<! DOCTYPE a><a/>",        err  = .Unexpected_Token},
		{src = "<? pi?><a/>",              err  = .Unexpected_Token},
		{src = "<a />",                    tree = "a{}"},
		{src = "<a\n></a\t>",              tree = "a{}"},
		{src = "<a b=\"1\"c=\"2\"/>",      err  = .Unexpected_Token},
		{src = "<a b='1'c='2'/>",          err  = .Unexpected_Token},
		{src = "<a b=\"1\" c=\"2\"/>",     tree = `a[b="1" c="2"]{}`},
		{src = "<a b = '1'\n\tc\n=\"2\"/>", tree = `a[b="1" c="2"]{}`},
		{src = "<a b=\"x<y\"/>",           err  = .Invalid_Tag_Value},
		{src = "<a b='x<y'/>",             err  = .Invalid_Tag_Value},
		{src = "<a b='x\"y' c=\"x'y\"/>",  tree = `a[b="x\"y" c="x'y"]{}`},
		{src = "<a b=\"]]>\"/>",           tree = `a[b="]]>"]{}`},
		{src = "<a b=1/>",                 err  = .Unexpected_Token},
		{src = "<a \"x\"></a>",            err  = .Unexpected_Token},
		{src = "<a b=\"c\" =></a>",        err  = .Unexpected_Token},
		{src = "<a b=\"1",                 err  = .Premature_EOF},
		{src = "<a>x]]>y</a>",             err  = .Unexpected_Token},
		{src = "<a><![CDATA[x]]>]]></a>",  err  = .Unexpected_Token},
		{src = "<a>x]]y]>z</a>",           tree = `a{"x]]y]>z"}`},
		{src = "<a><!-- ]]> --></a>",      tree = "a{}"},
		{src = "<a>x<!-- ]]> -->y</a>",    tree = `a{"xy"}`},
		{src = "<a><?Xml x?></a>",         err  = .Invalid_Prolog},
		{src = "<a><?pi&x?></a>",          err  = .Unexpected_Token},
		{src = "<a><?pi?></a>",            tree = "a{}"},
		{src = "<a><?xml-pi x?></a>",      tree = "a{}"},
	}
	run_review_cases(t, cases[:])

	last_error_pos = {}
	doc, err := xml.parse_string("<a\n b=\"x\n<\"/>", error_handler = remember_pos)
	defer xml.destroy(doc)
	testing.expect_value(t, err, xml.Error.Invalid_Tag_Value)
	testing.expect_value(t, last_error_pos.line, 3)
	testing.expect_value(t, last_error_pos.column, 1)
}

@(test)
xml_test_review_xml_declaration :: proc(t: ^testing.T) {
	cases := [?]Review_Case{
		{src = "<?xml version=\"1.0\"?><a/>",                                         tree = "a{}"},
		{src = "<?xml version='1.1' encoding='UTF-8' standalone='yes' ?><a/>",        tree = "a{}"},
		{src = "<?xml version=\"1.0\" standalone=\"no\"?><a/>",                       tree = "a{}"},
		{src = "<?xml version=\"1.5\"?><a/>",                                         tree = "a{}"},
		{src = "<?xml\tversion = \"1.0\"\nencoding=\"x-a.b_c-1\"\n?><a/>",            tree = "a{}"},
		{src = "<?XML version=\"1.0\"?><a/>",                                         err  = .Invalid_Prolog},
		{src = "<?xml version=\"2.0\"?><a/>",                                         err  = .Unsupported_Version},
		{src = "<?xml version=\"1.\"?><a/>",                                          err  = .Unsupported_Version},
		{src = "<?xml version=\"1.0 \"?><a/>",                                        err  = .Unsupported_Version},
		{src = "<?xml version=\"1.0a\"?><a/>",                                        err  = .Unsupported_Version},
		{src = "<?xml?><a/>",                                                         err  = .Invalid_Prolog},
		{src = "<?xml ?><a/>",                                                        err  = .Invalid_Prolog},
		{src = "<?xml encoding=\"utf-8\"?><a/>",                                      err  = .Invalid_Prolog},
		{src = "<?xml encoding=\"utf-8\" version=\"1.0\"?><a/>",                      err  = .Invalid_Prolog},
		{src = "<?xml version=\"1.0\" standalone=\"yes\" encoding=\"utf-8\"?><a/>",   err  = .Invalid_Prolog},
		{src = "<?xml version=\"1.0\" version=\"1.0\"?><a/>",                         err  = .Invalid_Prolog},
		{src = "<?xml version=\"1.0\" foo=\"bar\"?><a/>",                             err  = .Invalid_Prolog},
		{src = "<?xml version=\"1.0\" encoding=\"8bit\"?><a/>",                       err  = .Invalid_Prolog},
		{src = "<?xml version=\"1.0\" encoding=\"\"?><a/>",                           err  = .Invalid_Prolog},
		{src = "<?xml version=\"1.0\" encoding=\"utf 8\"?><a/>",                      err  = .Invalid_Prolog},
		{src = "<?xml version=\"1.0\" standalone=\"maybe\"?><a/>",                    err  = .Invalid_Prolog},
		{src = "<?xml version=\"1.0\"encoding=\"utf-8\"?><a/>",                       err  = .Invalid_Prolog},
		{src = "<?xml version=\"1.0\"? ><a/>",                                        err  = .Unexpected_Token},
		{src = "<?xmlversion=\"1.0\"?><a/>",                                          err  = .Unexpected_Token},
		{src = "<?xml version=\"1.<0\"?><a/>",                                        err  = .Invalid_Tag_Value},
	}
	run_review_cases(t, cases[:])

	doc, err := xml.parse_string("<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?><a/>", error_handler = Silent)
	defer xml.destroy(doc)
	testing.expect_value(t, err, xml.Error.None)
	if err == .None {
		testing.expect_value(t, len(doc.prologue), 3)
		testing.expect_value(t, doc.encoding, xml.Encoding.UTF_8)
		if len(doc.prologue) == 3 {
			testing.expect_value(t, doc.prologue[0].val, "1.0")
			testing.expect_value(t, doc.prologue[1].val, "UTF-8")
			testing.expect_value(t, doc.prologue[2].key, "standalone")
		}
	}
}

@(thread_local, private="file")
messages: [dynamic]string

@(private="file")
remember_message :: proc(pos: xml.Pos, format: string, args: ..any) {
	last_error_pos = pos
	append(&messages, fmt.aprintf(format, ..args))
}

@(test)
xml_test_review_error_positions :: proc(t: ^testing.T) {
	Position_Case :: struct {
		src:    string,
		err:    xml.Error,
		line:   int,
		column: int,
	}
	cases := [?]Position_Case{
		{"<a>\n<!--\n\n\n",                     .Unclosed_Comment,    2, 5},
		{"<a>\n<![CDATA[\n\n",                  .Premature_EOF,       2, 1},
		{"<a\n b=\"1\"\n b=\"2\n\n\"/>",        .Duplicate_Attribute, 3, 2},
		{"<a b=\"1\" b=\"2\"/>",                .Duplicate_Attribute, 1, 10},
		{"<?xml\nversion=\"1.0\"\nencoding=\"\n\"?><a/>", .Invalid_Prolog, 3, 1},
	}
	for c in cases {
		last_error_pos = {}
		doc, err := xml.parse_string(c.src, error_handler = remember_pos)
		xml.destroy(doc)
		testing.expectf(t, err == c.err, "%q: expected %v, got %v", c.src, c.err, err)
		testing.expectf(t, last_error_pos.line == c.line && last_error_pos.column == c.column, "%q: expected %v:%v, got %v:%v", c.src, c.line, c.column, last_error_pos.line, last_error_pos.column)
	}
}

@(test)
xml_test_review_error_messages :: proc(t: ^testing.T) {
	defer {
		for m in messages {
			delete(m)
		}
		delete(messages)
		messages = nil
	}
	doc, err := xml.parse_string("<a><!\"100%v\n\"></a>", error_handler = remember_message)
	defer xml.destroy(doc)
	testing.expect_value(t, err, xml.Error.Unexpected_Token)

	found := false
	for m in messages {
		testing.expectf(t, !strings.contains(m, "%!"), "unformatted message: %q", m)
		found |= strings.contains(m, `"100%v"`)
	}
	testing.expectf(t, found, "no message quotes the literal: %q", messages[:])
}

@(test)
xml_test_review_many_attributes :: proc(t: ^testing.T) {
	Many_Case :: struct {
		count:  int,
		dup_of: int,
		dup_at: int,
		err:    xml.Error,
	}
	cases := [?]Many_Case{
		{count = 40,   dup_at = -1},
		{count = 40,   dup_of = 3,    dup_at = 35,   err = .Duplicate_Attribute},
		{count = 40,   dup_of = 33,   dup_at = 34,   err = .Duplicate_Attribute},
		{count = 40,   dup_of = 0,    dup_at = 32,   err = .Duplicate_Attribute},
		{count = 40,   dup_of = 31,   dup_at = 32,   err = .Duplicate_Attribute},
		{count = 32,   dup_of = 0,    dup_at = 31,   err = .Duplicate_Attribute},
		{count = 5000, dup_of = 4000, dup_at = 4999, err = .Duplicate_Attribute},
		{count = 5000, dup_at = -1},
	}
	for c in cases {
		b := strings.builder_make()
		defer strings.builder_destroy(&b)
		strings.write_string(&b, "<a")
		for i in 0..<c.count {
			fmt.sbprintf(&b, " k%v=\"%v\"", i == c.dup_at ? c.dup_of : i, i)
		}
		strings.write_string(&b, "/>")

		doc, err := xml.parse_string(strings.to_string(b), error_handler = Silent)
		defer xml.destroy(doc)
		testing.expectf(t, err == c.err, "%v attributes, k%v at %v: expected %v, got %v", c.count, c.dup_of, c.dup_at, c.err, err)
		if err == .None && c.err == .None {
			attribs := doc.elements[0].attribs
			testing.expect_value(t, len(attribs), c.count)
			if len(attribs) == c.count {
				last := fmt.tprintf("k%v", c.count - 1)
				testing.expect_value(t, attribs[c.count - 1].key, last)
			}
		}
	}
}

@(test)
xml_test_review_text_whitespace :: proc(t: ^testing.T) {
	cases := [?]Review_Case{
		{src = "<a> x <b/> y </a>",                                                   tree = `a{" x ",b{}," y "}`},
		{src = "<a> x <b/> y </a>",       flags = {.Trim_Whitespace},                 tree = `a{"x",b{},"y"}`},
		{src = "<a>\n  <b/>\n</a>",                                                   tree = `a{"\n  ",b{},"\n"}`},
		{src = "<a>\n  <b/>\n</a>",       flags = {.Trim_Whitespace},                 tree = `a{b{}}`},
		{src = "<a>\n <!--c-->\n</a>",                                                tree = `a{"\n \n"}`},
		{src = "<a>\n <!--c-->\n</a>",    flags = {.Intern_Comments},                 tree = `a{"\n ",!"c","\n"}`},
		{src = "<a>\n <!--c-->\n</a>",    flags = {.Intern_Comments, .Trim_Whitespace}, tree = `a{!"c"}`},
		{src = "<a>x <!--c--> y</a>",     flags = {.Intern_Comments, .Keep_Tag_Body_Comments}, tree = `a{"x <!--c--> y"}`},
		{src = "<a b=\" x\ty\nz \"/>",                                                tree = `a[b=" x y z "]{}`},
		{src = "<a b=\" x\ty\nz \"/>",    flags = {.Trim_Whitespace},                 tree = `a[b="x y z"]{}`},
		{src = "<a b=\"&#10;&#9;\"/>",                                                tree = `a[b="\n\t"]{}`},
		{src = "<a b=\"a&#32; b\"/>",                                                 tree = `a[b="a  b"]{}`},
		{src = "<a b=\"a&#32; b\"/>",     flags = {.Trim_Whitespace},                 tree = `a[b="a b"]{}`},
	}
	run_review_cases(t, cases[:])
}

@(test)
xml_test_review_references :: proc(t: ^testing.T) {
	cases := [?]Review_Case{
		{src = "<a>&lt;&#65;<![CDATA[&amp;]]></a>",                                         tree = `a{"<A&amp;"}`},
		{src = "<a>&</a>",                                                                   err  = .Invalid_Token},
		{src = "<a>&;</a>",                                                                  err  = .Invalid_Token},
		{src = "<a>&amp</a>",                                                                err  = .Invalid_Token},
		{src = "<a>&#0;</a>",                                                                err  = .Invalid_Token},
		{src = "<a b=\"&\"/>",                                                               err  = .Invalid_Token},
		{src = "<a>&copy;</a>",                                                              err  = .Unknown_Entity},
		{src = "<a>&copy;</a>",                        flags = {.Decode_SGML_Entities},      tree = "a{\"\u00a9\"}"},
		{src = "<a b=\"&copy;\"/>",                                                          err  = .Unknown_Entity},
		{src = "<a b=\"&copy;\"/>",                    flags = {.Decode_SGML_Entities},      tree = "a[b=\"\u00a9\"]{}"},
		{src = "<a>&nosuch;</a>",                      flags = {.Decode_SGML_Entities},      err  = .Unknown_Entity},
		{src = "<a b=\"&nGt;\">&nGt;</a>",             flags = {.Decode_SGML_Entities},      tree = "a[b=\"\u226b\\u20d2\"]{\"\u226b\\u20d2\"}"},
		{src = "<!DOCTYPE a [<!ENTITY e \"x\">]><a b=\"&e;\">&e;</a>", flags = {.Ignore_Unsupported}, tree = `a[b="&e;"]{"&e;"}`},
		{src = "<!DOCTYPE a SYSTEM \"a.dtd\"><a>&e;</a>",          flags = {.Ignore_Unsupported}, tree = `a{"&e;"}`},
		{src = "<!DOCTYPE a [<!ENTITY e \"x\">]><a>&e;</a>",       flags = {.Error_On_Unsupported}, err = .Unknown_Entity},
		{src = "<!DOCTYPE a [<!ENTITY e \"x\">]><a>&e;</a>",                                 err  = .Unknown_Entity},
		{src = "<!DOCTYPE a><a>&e;</a>",                           flags = {.Ignore_Unsupported}, err = .Unknown_Entity},
	}
	run_review_cases(t, cases[:])
}

@(test)
xml_test_review_decode_in_place :: proc(t: ^testing.T) {
	in_buffer :: proc(buf: []u8, s: string) -> bool {
		p := uintptr(raw_data(s))
		b := uintptr(raw_data(buf))
		return p >= b && p + uintptr(len(s)) <= b + uintptr(len(buf))
	}

	SRC :: "<a b=\"x&amp;y\">p&lt;q<![CDATA[r]]></a>"

	buf := transmute([]u8)strings.clone(SRC)
	defer delete(buf)
	doc, err := xml.parse_bytes(buf, xml.Options{flags = {.Input_May_Be_Modified}}, error_handler = Silent)
	defer xml.destroy(doc)
	testing.expect_value(t, err, xml.Error.None)
	if err == .None {
		val     := doc.elements[0].attribs[0].val
		body, _ := doc.elements[0].value[0].(string)
		testing.expect_value(t, val,  "x&y")
		testing.expect_value(t, body, "p<qr")
		testing.expect(t, in_buffer(buf, val) && in_buffer(buf, body), "values were not decoded in place")
	}

	src := strings.clone(SRC)
	defer delete(src)
	doc2, err2 := xml.parse_bytes(transmute([]u8)src, error_handler = Silent)
	defer xml.destroy(doc2)
	testing.expect_value(t, err2, xml.Error.None)
	testing.expect_value(t, src, SRC)

	doc3, err3 := xml.parse_string(src, xml.Options{flags = {.Input_May_Be_Modified}}, error_handler = Silent)
	defer xml.destroy(doc3)
	testing.expect_value(t, err3, xml.Error.None)
	testing.expect_value(t, src, SRC)
}

@(test)
xml_test_review_decode_error_positions :: proc(t: ^testing.T) {
	Position_Case :: struct {
		src:    string,
		err:    xml.Error,
		line:   int,
		column: int,
	}
	cases := [?]Position_Case{
		{"<a>\n  &nosuch;</a>",                          .Unknown_Entity,   2, 3},
		{"<a b=\"x\n &\"/>",                             .Invalid_Token,    2, 2},
		{"<a>&amp;\nxxxxxxxx<b c=\"&bad;\n\"/></a>",     .Unknown_Entity,   2, 15},
		{"<a b=\"&amp;\nxxxxxxxxx\">&bad;\n</a>",        .Unknown_Entity,   2, 12},
		{"<a b=\"&amp;\nxxxxxxxx\">yy<!--\n",            .Unclosed_Comment, 2, 17},
	}
	for c in cases {
		last_error_pos = {}
		doc, err := xml.parse_string(c.src, error_handler = remember_pos)
		xml.destroy(doc)
		testing.expectf(t, err == c.err, "%q: expected %v, got %v", c.src, c.err, err)
		testing.expectf(t, last_error_pos.line == c.line && last_error_pos.column == c.column, "%q: expected %v:%v, got %v:%v", c.src, c.line, c.column, last_error_pos.line, last_error_pos.column)
	}
}

@(test)
xml_test_review_debug_print :: proc(t: ^testing.T) {
	SRC :: "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE a [<!ELEMENT a ANY>]>\n<!--top-->\n<a x=\"1\">t<!--c--><b/></a>"
	EXPECTED ::
		"[XML Prolog]\n" +
		"\tversion: 1.0\n" +
		"\tencoding: UTF-8\n" +
		"[Encoding] UTF_8\n" +
		"[DOCTYPE]  a\n" +
		"\t[<!ELEMENT a ANY>]\n" +
		"[Pre-root comment]  top\n" +
		" --- \n" +
		"\t<a>\n" +
		"\t\t[Value] t\n" +
		"\t\t[COMMENT] c\n" +
		"\t\t<b>\n" +
		"\t\t[Attr] x: 1\n" +
		" --- \n"

	doc, err := xml.parse_string(SRC, xml.Options{flags = {.Intern_Comments}}, error_handler = Silent)
	defer xml.destroy(doc)
	testing.expect_value(t, err, xml.Error.None)
	if err != .None {
		return
	}

	b := strings.builder_make()
	defer strings.builder_destroy(&b)
	written, print_err := xml.print(strings.to_writer(&b), doc)
	testing.expect_value(t, print_err, io.Error.None)
	testing.expect_value(t, strings.to_string(b), EXPECTED)
	testing.expect_value(t, written, len(EXPECTED))

	expected := EXPECTED
	for size in 0..<len(expected) {
		buf := make([]u8, size)
		defer delete(buf)
		fixed := strings.builder_from_bytes(buf)
		n, n_err := xml.print(strings.to_writer(&fixed), doc)
		testing.expectf(t, n_err != .None, "size %v: expected a write error", size)
		testing.expectf(t, n == strings.builder_len(fixed), "size %v: written %v, but %v bytes in the buffer", size, n, strings.builder_len(fixed))
		testing.expectf(t, strings.to_string(fixed) == expected[:n], "size %v: output %q", size, strings.to_string(fixed))
	}
}

@(test)
xml_test_review_find_child_by_ident :: proc(t: ^testing.T) {
	SRC :: `<a>t<b i="0"/><!--c--><c/><b i="1"><b i="x"/></b><b i="2"/></a>`

	doc, err := xml.parse_string(SRC, xml.Options{flags = {.Intern_Comments}}, error_handler = Silent)
	defer xml.destroy(doc)
	testing.expect_value(t, err, xml.Error.None)
	if err != .None {
		return
	}

	b1, b1_found := xml.find_child_by_ident(doc, 0, "b", 1)
	c,  c_found  := xml.find_child_by_ident(doc, 0, "c")
	testing.expect(t, b1_found && c_found)

	Find_Case :: struct {
		parent: xml.Element_ID,
		ident:  string,
		nth:    int,
		want:   string,
	}
	cases := [?]Find_Case{
		{0,  "b", 0, "b0"},
		{0,  "b", 1, "b1"},
		{0,  "b", 2, "b2"},
		{0,  "b", 3, ""},
		{0,  "c", 0, "c"},
		{0,  "c", 1, ""},
		{0,  "",  0, ""},
		{0,  "t", 0, ""},
		{0,  "a", 0, ""},
		{0,  "B", 0, ""},
		{b1, "b", 0, "bx"},
		{b1, "b", 1, ""},
		{c,  "b", 0, ""},
	}
	for f in cases {
		id, found := xml.find_child_by_ident(doc, f.parent, f.ident, f.nth)
		got := ""
		if found {
			i, _ := xml.find_attribute_val_by_key(doc, id, "i")
			got = fmt.tprintf("%v%v", doc.elements[id].ident, i)
		}
		testing.expectf(t, found == (f.want != "") && got == f.want, "%v %q %v: expected %q, got %q (found = %v)", f.parent, f.ident, f.nth, f.want, got, found)
	}
}

@(test)
xml_test_review_find_attribute_val_by_key :: proc(t: ^testing.T) {
	SRC :: `<a k="v" e="" amp="x&amp;y" K="upper"><b/></a>`

	doc, err := xml.parse_string(SRC, error_handler = Silent)
	defer xml.destroy(doc)
	testing.expect_value(t, err, xml.Error.None)
	if err != .None {
		return
	}

	Key_Case :: struct {
		parent: xml.Element_ID,
		key:    string,
		val:    string,
		found:  bool,
	}
	cases := [?]Key_Case{
		{0, "k",   "v",     true},
		{0, "e",   "",      true},
		{0, "amp", "x&y",   true},
		{0, "K",   "upper", true},
		{0, "x",   "",      false},
		{0, "",    "",      false},
		{1, "k",   "",      false},
	}
	for c in cases {
		val, found := xml.find_attribute_val_by_key(doc, c.parent, c.key)
		testing.expectf(t, val == c.val && found == c.found, "%v %q: expected %q %v, got %q %v", c.parent, c.key, c.val, c.found, val, found)
	}
}
