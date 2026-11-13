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
