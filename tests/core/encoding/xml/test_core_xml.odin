package test_core_xml

import "core:encoding/entity"
import "core:encoding/xml"
import "core:testing"
import "core:strings"
import "core:fmt"
import "core:log"
import "core:hash"
import "core:time"

Silent :: proc(pos: xml.Pos, format: string, args: ..any) {}

OPTIONS :: xml.Options{ flags = { .Ignore_Unsupported, .Intern_Comments, },
	expected_doctype = "",
}

TEST :: struct {
	filename: string,
	src:      string,
	options:  xml.Options,
	err:      xml.Error,
	crc32:    u32,
}

TEST_SUITE_PATH :: ODIN_ROOT + "tests/core/assets/"

UTF8_XML ::
	"<?xml version=\"1.0\" encoding=\"utf-8\"?>\n" +
	"<!DOCTYPE 恥ずべきフクロウ>\n" +
	"<恥ずべきフクロウ 올빼미_id=\"Foozle&#32;Barzle\">\n" +
	"<부끄러운:barzle>\n" +
	"\t<name foo:bar=\"birmese\">ရှက်စရာ ဇီးကွက်</name>\n" +
	"\t<nickname>Owl of Shame</nickname>\n" +
	"\t<data>More CDATA <![CDATA[<greeting>Hello, world!</greeting><![CDATA] <$]]> Nonsense.</data>\n" +
	"</부끄러운:barzle>\n" +
	"</恥ずべきフクロウ>\n"

ENTITIES_HTML ::
	"<html>\n" +
	"\t<head>\n" +
	"\t\t<title>Entity Reference Test</title>\n" +
	"\t\t<style>\n" +
	"\t\t\tbody {\n" +
	"\t\t\t\tbackground: #000; color: #eee;\n" +
	"\t\t\t\twidth: 40%;\n" +
	"\t\t\t\tmargin-left:  auto;\n" +
	"\t\t\t\tmargin-right: auto;\n" +
	"\t\t\t\tfont-size: 14pt;\n" +
	"\t\t\t}\n" +
	"\t\t</style>\n" +
	"\t</head>\n" +
	"\t<body>\n" +
	"\t\t<h1>Entity Reference Test</h1>\n" +
	"\t\t<div id=\"test_cdata_in_comment\" foo=\"\">\n" +
	"\t\t\tFoozle]!&#32;&copy;&#x20;<!-- <![CDATA[&#32;&reg;&#x20;]]> -->42&amp;;1234&amp;\n" +
	"\t\t</div>\n" +
	"\t\t<!-- foo attribute should be empty but present -->\n" +
	"\t\t<!-- EXPECTED: Foozle]! © 42&;1234& -->\n" +
	"\t\t<div id=\"test_cdata_unwrap_and_passthrough\">\n" +
	"\t\t\tFoozle]!&#32;&copy;&#x20;<![CDATA[BOX&#32;&reg;&#x20;/BOX]]>42&amp;;1234&amp;\n" +
	"\t\t</div>\n" +
	"\t\t<!-- EXPECTED: Foozle]! © BOX ® /BOX42&;1234& -->\n" +
	"\t\t<div>\n" +
	"\t\t\t&verbar; &vert; &VerticalLine; &fjlig; &grave; &bsol; &reg; &rhov; &CounterClockwiseContourIntegral; &bsemi;\n" +
	"\t\t</div>\n" +
	"\t\t<div> H<![CDATA[ellope!]]>Hellope!</div>\n" +
	"\t\t<div>\tH<![CDATA[ellope!]]>Hellope!</div>\n" +
	"\t\t<div> H<![CDATA[ellope!]]>Hellope! </div>\n" +
	"\t\t<div>\tH<![CDATA[ellope!]]>Hellope!\t</div>\n" +
	"\t\t<div>H<![CDATA[ellope!]]>Hellope! </div>\n" +
	"\t</body>\n" +
	"</html>"

ATTRIBUTE_WHITESPACE_XML ::
	"<?xml version=\"1.0\" encoding=\"utf-8\"?>\n" +
	"<!DOCTYPE foozle>\n" +
	"<foozle>Barzle\n" +
	"<부끄러운:barzle>\n" +
	"\t<name foo:bar=\"   birmese\n" +
	"\tkittens   have\n" +
	"\tfur   \">Indeed!</name>\n" +
	"</부끄러운:barzle>\n" +
	"</foozle>\n"

@(test)
xml_test_utf8_normal :: proc(t: ^testing.T) {
	run_test(t, {
		// Tests UTF-8 idents and values.
		// Test namespaced ident.
		// Tests that nested partial CDATA start doesn't trip up parser.
		filename  = "XML/utf8.xml",
		src       = UTF8_XML,
		options   = {
			flags = {
				.Ignore_Unsupported, .Intern_Comments,
			},
			expected_doctype = "恥ずべきフクロウ",
		},
		crc32     = 0x28211c7a,
	})
}

@(test)
xml_test_utf8_trim_whitespace :: proc(t: ^testing.T) {
	run_test(t, {
		// Same as above, but with `.Trim_Whitespace`.
		filename  = "XML/utf8.xml",
		src       = UTF8_XML,
		options   = {
			flags = {
				.Ignore_Unsupported, .Intern_Comments, .Trim_Whitespace,
			},
			expected_doctype = "恥ずべきフクロウ",
		},
		crc32     = 0x873198d6,
	})
}

@(test)
xml_test_nl_qt_ts :: proc(t: ^testing.T) {
	run_test(t, {
		// Simple Qt TS translation file.
		// `core:i18n` requires it to be parsed properly.
		filename  = "I18N/nl_NL-qt-ts.ts",
		options   = {
			flags = {
				.Ignore_Unsupported, .Intern_Comments, .Decode_SGML_Entities,
			},
			expected_doctype = "TS",
		},
		crc32     = 0x6f328435,
	})
}

@(test)
xml_test_xliff_1_2 :: proc(t: ^testing.T) {
	run_test(t, {
		// Simple XLiff 1.2 file.
		// `core:i18n` requires it to be parsed properly.
		filename  = "I18N/nl_NL-xliff-1.2.xliff",
		options   = {
			flags = {
				.Ignore_Unsupported, .Intern_Comments, .Decode_SGML_Entities,
			},
			expected_doctype = "xliff",
		},
		crc32     = 0x995eb569,
	})
}

@(test)
xml_test_xliff_2_0 :: proc(t: ^testing.T) {
	run_test(t, {
		// Simple XLiff 2.0 file.
		// `core:i18n` requires it to be parsed properly.
		filename  = "I18N/nl_NL-xliff-2.0.xliff",
		options   = {
			flags = {
				.Ignore_Unsupported, .Intern_Comments, .Decode_SGML_Entities,
			},
			expected_doctype = "xliff",
		},
		crc32     = 0x2a78e8ca,
	})
}

@(test)
xml_test_entities :: proc(t: ^testing.T) {
	run_test(t, {
		filename  = "XML/entities.html",
		options   = {
			flags = {
				.Ignore_Unsupported, .Intern_Comments,
			},
			expected_doctype = "html",
		},
		err       = .Unknown_Entity,
		crc32     = 0x31876be0,
	})
}

@(test)
xml_test_entities_bare_ampersand :: proc(t: ^testing.T) {
	run_test(t, {
		filename  = "XML/entities.html",
		options   = {
			flags = {
				.Ignore_Unsupported, .Intern_Comments, .Decode_SGML_Entities,
			},
			expected_doctype = "html",
		},
		err       = .Invalid_Token,
		crc32     = 0x21791738,
	})
}

@(test)
xml_test_entities_decode :: proc(t: ^testing.T) {
	run_test(t, {
		filename  = "XML/entities.html",
		src       = ENTITIES_HTML,
		options   = {
			flags = {
				.Ignore_Unsupported, .Intern_Comments, .Decode_SGML_Entities,
			},
			expected_doctype = "html",
		},
		crc32     = 0xa6fe0a49,
	})
}

@(test)
xml_test_entities_trim_whitespace :: proc(t: ^testing.T) {
	run_test(t, {
		filename  = "XML/entities.html",
		src       = ENTITIES_HTML,
		options   = {
			flags = {
				.Ignore_Unsupported, .Intern_Comments, .Decode_SGML_Entities, .Trim_Whitespace,
			},
			expected_doctype = "html",
		},
		crc32     = 0x7aa5f81e,
	})
}

@(test)
xml_test_attribute_whitespace :: proc(t: ^testing.T) {
	run_test(t, {
		// Same as above.
		// Unbox CDATA in data tag.
		filename  = "XML/attribute-whitespace.xml",
		src       = ATTRIBUTE_WHITESPACE_XML,
		options   = {
			flags = {},
			expected_doctype = "foozle",
		},
		crc32     = 0xa202c48e,
	})
}

@(test)
xml_test_attribute_whitespace_trim :: proc(t: ^testing.T) {
	run_test(t, {
		filename  = "XML/attribute-whitespace.xml",
		src       = ATTRIBUTE_WHITESPACE_XML,
		options   = {
			flags = {.Trim_Whitespace},
			expected_doctype = "foozle",
		},
		crc32     = 0x8f5fd6c1,
	})
}

@(test)
xml_test_invalid_doctype :: proc(t: ^testing.T) {
	run_test(t, {
		filename  = "XML/utf8.xml",
		options   = {
			flags            = {
				.Ignore_Unsupported, .Intern_Comments,
			},
			expected_doctype = "Odin",
		},
		err       = .Invalid_DocType,
		crc32     = 0x49b83d0a,
	})
}

@(test)
xml_test_unicode :: proc(t: ^testing.T) {
	run_test(t, {
		filename  = "XML/unicode.xml",
		options   = {
			flags            = {
				.Ignore_Unsupported,
			},
			expected_doctype = "",
		},
		err       = .None,
		crc32     = 0x687119cd,
	})
}

@(test)
xml_test_cdata_edge_cases :: proc(t: ^testing.T) {
	Case :: struct {
		src:   string,
		err:   xml.Error,
		value: string,
		kept:  string,
	}

	cases := [?]Case{
		{src = `<a>x <![CDATA[l]]></a>`,                value = `x l`},
		{src = `<a>x <![CDATA[]]></a>`,                 value = `x `},
		{src = `<a>x <![CDATA[ab]]></a>`,               value = `x ab`},
		{src = `<a>x <![CDATA[]]><!-- c --> y</a>`,     value = `x  y`, kept = `x <!-- c --> y`},
		{src = `<a>x <![CDATA[]]><![CDATA[z]]> y</a>`,  value = `x z y`},
		{src = `<a>x <![CDATA[a<]]> y</a>`,             value = `x a< y`},
		{src = `<a>x <![CDATA[]]]>y</a>`,               value = `x ]y`},
		{src = `<a>x <![CDATA[a]b]]>y</a>`,             value = `x a]by`},
		{src = "<a>x <![CDATA[l\nm]]>y</a>",             value = "x l\nmy"},
		{src = `<a>x <![CDATA[&amp;]]>y</a>`,           value = `x &amp;y`},
		{src = `<a>x <![CDATA[unterminated</a>`,         err   = .Premature_EOF},
	}

	flag_sets := [?]xml.Option_Flags{
		{.Ignore_Unsupported},
		{.Ignore_Unsupported, .Decode_SGML_Entities},
		{.Ignore_Unsupported, .Keep_Tag_Body_Comments},
	}

	for c in cases {
		for flags in flag_sets {
			doc, err := xml.parse_string(c.src, xml.Options{flags = flags}, error_handler = Silent)
			defer xml.destroy(doc)

			testing.expectf(t, err == c.err, "%q %v: expected %v, got %v", c.src, flags, c.err, err)
			if c.err == .None && err == .None {
				expected := c.value
				if .Keep_Tag_Body_Comments in flags && c.kept != "" {
					expected = c.kept
				}
				values := doc.elements[0].value
				testing.expectf(t, len(values) == 1, "%q %v: expected 1 value, got %v", c.src, flags, len(values))
				if len(values) == 1 {
					got, _ := values[0].(string)
					testing.expectf(t, got == expected, "%q %v: expected %q, got %q", c.src, flags, expected, got)
				}
			}
		}
	}
}

@(test)
xml_test_many_attributes :: proc(t: ^testing.T) {
	// An element's attributes grow in the strings arena, whose blocks are a quarter of the input
	// (256 bytes at least): every attribute is kept, whatever the document's size.
	ATTRIBUTES :: 32

	for padding in ([?]int{0, 1_000, 2_000, 4_000, 30_000}) {
		sb := strings.builder_make()
		defer strings.builder_destroy(&sb)

		strings.write_string(&sb, "<r><e")
		for i in 0..<ATTRIBUTES {
			fmt.sbprintf(&sb, ` a%v="%v"`, i, i)
		}
		strings.write_string(&sb, "/><!--")
		for _ in 0..<padding {
			strings.write_byte(&sb, ' ')
		}
		strings.write_string(&sb, "--></r>")
		src := strings.to_string(sb)

		doc, err := xml.parse_string(src, error_handler = Silent)
		defer xml.destroy(doc)

		testing.expectf(t, err == .None, "%v bytes: expected no error, got %v", len(src), err)
		if err != .None {
			continue
		}
		attribs := doc.elements[1].attribs
		testing.expectf(t, len(attribs) == ATTRIBUTES, "%v bytes: expected %v attributes, got %v", len(src), ATTRIBUTES, len(attribs))
		for a, i in attribs {
			key, val := fmt.tprintf("a%v", i), fmt.tprintf("%v", i)
			testing.expectf(t, a.key == key && a.val == val, "%v bytes: attribute %v: expected %v=%q, got %v=%q", len(src), i, key, val, a.key, a.val)
		}
	}
}

@(private)
run_test :: proc(t: ^testing.T, test: TEST, loc := #caller_location) {
	path := strings.concatenate({TEST_SUITE_PATH, test.filename})
	defer delete(path)

	sw: time.Stopwatch

	log.debugf("Starting xml.load_from_file...")
	time.stopwatch_reset(&sw)
	time.stopwatch_start(&sw)
	doc: ^xml.Document
	err: xml.Error
	if test.src != "" {
		doc, err = xml.parse_string(test.src, test.options, test.filename, Silent)
	} else {
		doc, err = xml.load_from_file(path, test.options, Silent)
	}
	log.debugf("Finished xml.load_from_file: %v", time.stopwatch_duration(sw))
	defer {
		log.debugf("Starting xml.destroy...")
		time.stopwatch_reset(&sw)
		time.stopwatch_start(&sw)
		xml.destroy(doc)
		log.debugf("Finished xml.destroy: %v", time.stopwatch_duration(sw))
	}

	log.debugf("Starting doc_to_string...")
	time.stopwatch_reset(&sw)
	time.stopwatch_start(&sw)
	tree_string := doc_to_string(doc, capacity = 20_000_000)
	log.debugf("Finished doc_to_string: %v", time.stopwatch_duration(sw))
	defer delete(tree_string)

	log.debugf("Starting hash.crc32...")
	time.stopwatch_reset(&sw)
	time.stopwatch_start(&sw)
	tree_bytes  := transmute([]u8)tree_string
	crc32 := hash.crc32(tree_bytes)
	log.debugf("Finished hash.crc32: %v", time.stopwatch_duration(sw))

	failed := err != test.err
	testing.expectf(t, err == test.err, "%v: Expected return value %v, got %v", test.filename, test.err, err, loc=loc)

	failed |= crc32 != test.crc32
	testing.expectf(t, crc32 == test.crc32, "%v: Expected CRC 0x%08x, got 0x%08x, with options %v", test.filename, test.crc32, crc32, test.options, loc=loc)

	if failed {
		// Don't fully print big trees.
		tree_string = tree_string[:min(2_048, len(tree_string))]
		log.error(tree_string)
	}
}

@(test)
test_normalize_whitespace :: proc(t: ^testing.T) {
	s := "A &amp; B"
	normalized_entity_decode, _ := entity.decode_xml(s, {.Normalize_Attribute})
	defer delete(normalized_entity_decode)

	testing.expect_value(t, normalized_entity_decode, "A & B")

	s = `<hellope attr="A &amp; B">A &amp; B</hellope>`

	opts := xml.Options{
		flags = {.Ignore_Unsupported, .Decode_SGML_Entities},
	}

	doc, err := xml.parse_bytes(transmute([]byte)s, opts)
	defer xml.destroy(doc)
	assert(err == .None)

	testing.expect_value(t, doc.elements[0].value[0], "A & B")
	attr := doc.elements[0].attribs
	testing.expect_value(t, attr[0].val, "A & B")
}

@(private)
doc_to_string :: proc(doc: ^xml.Document, capacity: int) -> (result: string) {
	/*
		Effectively a clone of the debug printer in the xml package.
		We duplicate it here so that the way it prints an XML document to a string is stable.

		This way we can hash the output. If it changes, it means that the document or how it was parsed changed,
		not how it was printed. One less source of variability.
	*/
	print :: proc(writer: ^strings.Builder, doc: ^xml.Document) {
		if doc == nil { return }

		fmt.sbprintf(writer, "[XML Prolog]\n")

		for attr in doc.prologue {
			fmt.sbprintf(writer, "\t%v: %v\n", attr.key, attr.val)
		}

		fmt.sbprintf(writer, "[Encoding] %v\n", doc.encoding)

		if len(doc.doctype.ident) > 0 {
			fmt.sbprintf(writer, "[DOCTYPE]  %v\n", doc.doctype.ident)

			if len(doc.doctype.rest) > 0 {
				fmt.sbprintf(writer, "\t%v\n", doc.doctype.rest)
			}
		}

		for comment in doc.comments {
			fmt.sbprintf(writer, "[Pre-root comment]  %v\n", comment)
		}

		if doc.element_count > 0 {
			fmt.sbprintln(writer, " --- ")
			print_element(writer, doc, 0)
			fmt.sbprintln(writer, " --- ")
		}
	}

	print_element :: proc(writer: ^strings.Builder, doc: ^xml.Document, element_id: xml.Element_ID, indent := 0) {
		tab :: #force_inline proc(writer: ^strings.Builder, indent: int) {
			// PERF: Hot
			for _ in 0 ..= indent {
				#force_inline append(&writer.buf, '\t')
			}
		}

		tab(writer, indent)

		element := doc.elements[element_id]

		if element.kind == .Element {
			// PERF: lukewarm
			//fmt.wprintf(writer, "%v<%v>\n", doc_to_string_indent[indent], element.ident)
			strings.write_string(writer, "<")
			strings.write_string(writer, element.ident)
			strings.write_string(writer, ">\n")

			for value in element.value {
				switch v in value {
				case string:
					// PERF: A little bit hot
					tab(writer, indent + 1)
					//fmt.wprintf(writer, "[Value] %v\n", v)
					strings.write_string(writer, "[Value] ")
					strings.write_string(writer, v)
					strings.write_string(writer, "\n")
				case xml.Element_ID:
					print_element(writer, doc, v, indent + 1)
				}
			}

			for attr in element.attribs {
				// PERF: Hot
				tab(writer, indent + 1)
				//fmt.wprintf(writer, "[Attr] %v: %v\n", attr.key, attr.val)
				strings.write_string(writer, "[Attr] ")
				strings.write_string(writer, attr.key)
				strings.write_string(writer, ": ")
				strings.write_string(writer, attr.val)
				strings.write_string(writer, "\n")
			}
		} else if element.kind == .Comment {
			// PERF: Cold
			strings.write_string(writer, "[COMMENT] ")
			for value in element.value {
				if text, is_text := value.(string); is_text {
					strings.write_string(writer, text)
				}
			}
			strings.write_string(writer, "\n")
		}
	}

	buf: strings.Builder
	if capacity > 0 {
		strings.builder_init_len_cap(&buf, 0, capacity)
	}

	print(&buf, doc)

	result = strings.to_string(buf)
	if len(result) < capacity - 1000 {
		log.debugf("Document converted to debug string - result length: %v", len(result))
	} else {
		log.warnf("Document converted to debug string - result length: %v - initial string builder capacity: %v - please increase capacity for better test performance.", len(result), capacity)
	}
	return
}