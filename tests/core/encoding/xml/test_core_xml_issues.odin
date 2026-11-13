package test_core_xml

import "core:encoding/xml"
import "core:strings"
import "core:testing"

@(test)
xml_test_attribute_entities :: proc(t: ^testing.T) {
	Case :: struct {
		text:    string,
		decoded: string,
	}

	cases := [?]Case{
		{text = `&quot; &quot;`,        decoded = `" "`},
		{text = `&lt; &amp; &gt;`,      decoded = `< & >`},
		{text = `&#34;&#32;&#x22;`,     decoded = `" "`},
		{text = `a &apos;b&apos; c`,    decoded = `a 'b' c`},
		{text = `&#x1F600; &#128512;`,  decoded = "\U0001F600 \U0001F600"},
	}

	flags := [?]xml.Option_Flags{
		{},
		{.Decode_SGML_Entities},
	}

	for c in cases {
		src := element_with_text(c.text)
		defer delete(src)

		for f in flags {
			doc, err := xml.parse_string(src, xml.Options{flags = f}, error_handler = Silent)
			defer xml.destroy(doc)

			testing.expectf(t, err == .None, "%q %v: expected None, got %v", src, f, err)
			if err != .None {
				continue
			}

			val, found := xml.find_attribute_val_by_key(doc, 0, "a")
			testing.expectf(t, found && val == c.decoded, "%q %v: expected attribute %q, got %q (found %v)", src, f, c.decoded, val, found)

			body := c.text if .Decode_SGML_Entities not_in f else c.decoded
			values := doc.elements[0].value
			testing.expectf(t, len(values) == 1, "%q %v: expected 1 value, got %v", src, f, len(values))
			if len(values) == 1 {
				got, _ := values[0].(string)
				testing.expectf(t, got == body, "%q %v: expected body %q, got %q", src, f, body, got)
			}
		}
	}
}

@(private="file")
element_with_text :: proc(text: string) -> string {
	return strings.concatenate({`<e a="`, text, `">`, text, `</e>`})
}
