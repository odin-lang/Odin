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
	options:  xml.Options,
	err:      xml.Error,
	crc32:    u32,
}

TEST_SUITE_PATH :: ODIN_ROOT + "tests/core/assets/"

@(test)
xml_test_utf8_normal :: proc(t: ^testing.T) {
	run_test(t, {
		// Tests UTF-8 idents and values.
		// Test namespaced ident.
		// Tests that nested partial CDATA start doesn't trip up parser.
		filename  = "XML/utf8.xml",
		options   = {
			flags = {
				.Ignore_Unsupported, .Intern_Comments,
			},
			expected_doctype = "恥ずべきフクロウ",
		},
		crc32     = 0xefa55f27,
	})
}

@(test)
xml_test_utf8_unbox_cdata :: proc(t: ^testing.T) {
	run_test(t, {
		// Same as above.
		// Unbox CDATA in data tag.
		filename  = "XML/utf8.xml",
		options   = {
			flags = {
				.Ignore_Unsupported, .Intern_Comments, .Unbox_CDATA,
			},
			expected_doctype = "恥ずべきフクロウ",
		},
		crc32     = 0x2dd27770,
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
				.Ignore_Unsupported, .Intern_Comments, .Unbox_CDATA, .Decode_SGML_Entities,
			},
			expected_doctype = "TS",
		},
		crc32     = 0x859b7443,
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
				.Ignore_Unsupported, .Intern_Comments, .Unbox_CDATA, .Decode_SGML_Entities,
			},
			expected_doctype = "xliff",
		},
		crc32     = 0x3deaf329,
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
				.Ignore_Unsupported, .Intern_Comments, .Unbox_CDATA, .Decode_SGML_Entities,
			},
			expected_doctype = "xliff",
		},
		crc32     = 0x0c55e287,
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
		crc32     = 0x98791215,
	})
}

@(test)
xml_test_entities_unbox :: proc(t: ^testing.T) {
	run_test(t, {
		filename  = "XML/entities.html",
		options   = {
			flags = {
				.Ignore_Unsupported, .Intern_Comments, .Unbox_CDATA,
			},
			expected_doctype = "html",
		},
		crc32     = 0x5fd5ab4e,
	})
}

@(test)
xml_test_entities_unbox_decode :: proc(t: ^testing.T) {
	run_test(t, {
		filename  = "XML/entities.html",
		options   = {
			flags = {
				.Ignore_Unsupported, .Intern_Comments, .Unbox_CDATA, .Decode_SGML_Entities,
			},
			expected_doctype = "html",
		},
		crc32     = 0xda1ac384,
	})
}

@(test)
xml_test_attribute_whitespace :: proc(t: ^testing.T) {
	run_test(t, {
		// Same as above.
		// Unbox CDATA in data tag.
		filename  = "XML/attribute-whitespace.xml",
		options   = {
			flags = {},
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
		crc32     = 0x738664b1,
	})
}

@(private)
run_test :: proc(t: ^testing.T, test: TEST, loc := #caller_location) {
	path := strings.concatenate({TEST_SUITE_PATH, test.filename})
	defer delete(path)

	sw: time.Stopwatch

	log.infof("Starting xml.load_from_file...")
	time.stopwatch_reset(&sw)
	time.stopwatch_start(&sw)
	doc, err := xml.load_from_file(path, test.options, Silent)
	log.infof("Finished xml.load_from_file: %v", time.stopwatch_duration(sw))
	defer {
		log.infof("Starting xml.destroy...")
		time.stopwatch_reset(&sw)
		time.stopwatch_start(&sw)
		xml.destroy(doc)
		log.infof("Finished xml.destroy: %v", time.stopwatch_duration(sw))
	}

	log.infof("Starting doc_to_string...")
	time.stopwatch_reset(&sw)
	time.stopwatch_start(&sw)
	tree_string := doc_to_string(doc, capacity = 20_000_000)
	log.infof("Finished doc_to_string: %v", time.stopwatch_duration(sw))
	defer delete(tree_string)

	log.infof("Starting hash.crc32...")
	time.stopwatch_reset(&sw)
	time.stopwatch_start(&sw)
	tree_bytes  := transmute([]u8)tree_string
	crc32 := hash.crc32(tree_bytes)
	log.infof("Finished hash.crc32: %v", time.stopwatch_duration(sw))

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
	normalized_entity_decode, _ := entity.decode_xml(s, {.Normalize_Whitespace})
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
			fmt.sbprintf(writer, "[COMMENT] %v\n", element.value)
		}
	}

	buf: strings.Builder
	if capacity > 0 {
		strings.builder_init_len_cap(&buf, 0, capacity)
	}

	print(&buf, doc)

	result = strings.to_string(buf)
	if len(result) < capacity - 1000 {
		log.infof("Document converted to debug string - result length: %v", len(result))
	} else {
		log.warnf("Document converted to debug string - result length: %v - initial string builder capacity: %v - please increase capacity for better test performance.", len(result), capacity)
	}
	return
}