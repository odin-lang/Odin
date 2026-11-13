package test_core_xml

import "core:encoding/entity"
import "core:encoding/xml"
import "core:testing"

@(test)
xml_test_cdata_illegal_characters :: proc(t: ^testing.T) {
	Case :: struct {
		cdata: string,
		src:   string,
		err:   entity.Error,
	}

	cases := [?]Case{
		{cdata = "<![CDATA[a\xffb]]>",         src = "<a>x<![CDATA[a\xffb]]>y</a>",         err = .Illegal_UTF_Encoding},
		{cdata = "<![CDATA[a\x00b]]>",         src = "<a>x<![CDATA[a\x00b]]>y</a>",         err = .Illegal_NUL_Character},
	}

	decode_options := [?]entity.XML_Decode_Options{
		{},
		{.Unbox_CDATA},
		{.Unbox_CDATA, .Decode_CDATA},
	}

	flags := [?]xml.Option_Flags{
		{.Ignore_Unsupported},
		{.Ignore_Unsupported, .Decode_SGML_Entities},
		{.Ignore_Unsupported, .Unbox_CDATA},
		{.Ignore_Unsupported, .Unbox_CDATA, .Decode_SGML_Entities},
	}

	for c in cases {
		for o in decode_options {
			decoded, err := entity.decode_xml(c.cdata, o)
			delete(decoded)
			testing.expectf(t, err == c.err, "%q %v: expected %v, got %v", c.cdata, o, c.err, err)
		}

		expected := c.src[len("<a>"):][:len(c.src) - len("<a></a>")]
		for f in flags {
			doc, err := xml.parse_string(c.src, xml.Options{flags = f}, error_handler = Silent)
			defer xml.destroy(doc)

			testing.expectf(t, err == .None, "%q %v: expected None, got %v", c.src, f, err)
			if err == .None {
				values := doc.elements[0].value
				testing.expectf(t, len(values) == 1, "%q %v: expected 1 value, got %v", c.src, f, len(values))
				if len(values) == 1 {
					got, _ := values[0].(string)
					testing.expectf(t, got == expected, "%q %v: expected %q, got %q", c.src, f, expected, got)
				}
			}
		}
	}
}
