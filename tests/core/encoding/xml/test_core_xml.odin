package test_core_xml

import "core:encoding/xml"
import "core:testing"
import "core:strings"
import "core:io"
import "core:fmt"
import "core:log"
import "core:hash"

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
		crc32     = 0x05373317,
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
		crc32     = 0x350ca83e,
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
		crc32     = 0x7f58db7d,
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
		crc32     = 0x73070b55,
	})
}

@(private)
run_test :: proc(t: ^testing.T, test: TEST) {
	path := strings.concatenate({TEST_SUITE_PATH, test.filename})
	defer delete(path)

	doc, err := xml.load_from_file(path, test.options, Silent)
	defer xml.destroy(doc)

	tree_string := doc_to_string(doc)
	tree_bytes  := transmute([]u8)tree_string
	defer delete(tree_bytes)

	crc32 := hash.crc32(tree_bytes)

	failed := err != test.err
	testing.expectf(t, err == test.err, "%v: Expected return value %v, got %v", test.filename, test.err, err)

	failed |= crc32 != test.crc32
	testing.expectf(t, crc32 == test.crc32, "%v: Expected CRC 0x%08x, got 0x%08x, with options %v", test.filename, test.crc32, crc32, test.options)

	if failed {
		// Don't fully print big trees.
		tree_string = tree_string[:min(2_048, len(tree_string))]
		log.error(tree_string)
	}
}

@(private)
doc_to_string :: proc(doc: ^xml.Document) -> (result: string) {
	/*
		Effectively a clone of the debug printer in the xml package.
		We duplicate it here so that the way it prints an XML document to a string is stable.

		This way we can hash the output. If it changes, it means that the document or how it was parsed changed,
		not how it was printed. One less source of variability.
	*/
	print :: proc(writer: io.Writer, doc: ^xml.Document) -> (written: int, err: io.Error) {
		if doc == nil { return }

		written += fmt.wprintf(writer, "[XML Prolog]\n")

		for attr in doc.prologue {
			written += fmt.wprintf(writer, "\t%v: %v\n", attr.key, attr.val)
		}

		written += fmt.wprintf(writer, "[Encoding] %v\n", doc.encoding)

		if len(doc.doctype.ident) > 0 {
			written += fmt.wprintf(writer, "[DOCTYPE]  %v\n", doc.doctype.ident)

			if len(doc.doctype.rest) > 0 {
				fmt.wprintf(writer, "\t%v\n", doc.doctype.rest)
			}
		}

		for comment in doc.comments {
			written += fmt.wprintf(writer, "[Pre-root comment]  %v\n", comment)
		}

		if doc.element_count > 0 {
			fmt.wprintln(writer, " --- ")
			print_element(writer, doc, 0)
			fmt.wprintln(writer, " --- ")
		}

		return written, .None
	}

	print_element :: proc(writer: io.Writer, doc: ^xml.Document, element_id: xml.Element_ID, indent := 0) -> (written: int, err: io.Error) {
		tab :: proc(writer: io.Writer, indent: int) {
			for _ in 0..=indent {
				fmt.wprintf(writer, "\t")
			}
		}

		tab(writer, indent)

		element := doc.elements[element_id]

		if element.kind == .Element {
			fmt.wprintf(writer, "<%v>\n", element.ident)

			for value in element.value {
				switch v in value {
				case string:
					tab(writer, indent + 1)
					fmt.wprintf(writer, "[Value] %v\n", v)
				case xml.Element_ID:
					print_element(writer, doc, v, indent + 1)
				}
			}

			for attr in element.attribs {
				tab(writer, indent + 1)
				fmt.wprintf(writer, "[Attr] %v: %v\n", attr.key, attr.val)
			}
		} else if element.kind == .Comment {
			fmt.wprintf(writer, "[COMMENT] %v\n", element.value)
		}

		return written, .None
	}

	buf: strings.Builder
	defer strings.builder_destroy(&buf)

	print(strings.to_writer(&buf), doc)
	return strings.clone(strings.to_string(buf))
}