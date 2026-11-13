package test_core_xml

import "core:encoding/xml"
import "core:fmt"
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
