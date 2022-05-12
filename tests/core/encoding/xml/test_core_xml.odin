package test_core_xml

import "core:encoding/xml"
import "core:testing"
import "core:mem"
import "core:strings"
import "core:io"
import "core:fmt"
import "core:hash"

Silent :: proc(pos: xml.Pos, format: string, args: ..any) {}

OPTIONS :: xml.Options{ flags = { .Ignore_Unsupported, .Intern_Comments, },
	expected_doctype = "",
}

TEST_count := 0
TEST_fail  := 0

TEST :: struct {
	filename: string,
	options:  xml.Options,
	err:      xml.Error,
	crc32:    u32,
}

/*
	Relative to ODIN_ROOT
*/
TEST_FILE_PATH_PREFIX :: "tests/core/assets"

TESTS :: []TEST{
	/*
		First we test that certain files parse without error.
	*/

	{
		/*
			Tests UTF-8 idents and values.
			Test namespaced ident.
			Tests that nested partial CDATA start doesn't trip up parser.
		*/
		filename  = "XML/utf8.xml",
		options   = {
			flags = {
				.Ignore_Unsupported, .Intern_Comments,
			},
			expected_doctype = "恥ずべきフクロウ",
		},
		crc32     = 0x30d82264,
	},

	{
		/*
			Same as above.
			Unbox CDATA in data tag.
		*/
		filename  = "XML/utf8.xml",
		options   = {
			flags = {
				.Ignore_Unsupported, .Intern_Comments, .Unbox_CDATA,
			},
			expected_doctype = "恥ずべきフクロウ",
		},
		crc32     = 0xad31d8e8,
	},

	{
		/*
			Simple Qt TS translation file.
			`core:i18n` requires it to be parsed properly.
		*/
		filename  = "I18N/nl_NL-qt-ts.ts",
		options   = {
			flags = {
				.Ignore_Unsupported, .Intern_Comments, .Unbox_CDATA, .Decode_SGML_Entities,
			},
			expected_doctype = "TS",
		},
		crc32     = 0x7bce2630,
	},

	{
		/*
			Simple XLiff 1.2 file.
			`core:i18n` requires it to be parsed properly.
		*/
		filename  = "I18N/nl_NL-xliff-1.2.xliff",
		options   = {
			flags = {
				.Ignore_Unsupported, .Intern_Comments, .Unbox_CDATA, .Decode_SGML_Entities,
			},
			expected_doctype = "xliff",
		},
		crc32     = 0x43f19d61,
	},

	{
		/*
			Simple XLiff 2.0 file.
			`core:i18n` requires it to be parsed properly.
		*/
		filename  = "I18N/nl_NL-xliff-2.0.xliff",
		options   = {
			flags = {
				.Ignore_Unsupported, .Intern_Comments, .Unbox_CDATA, .Decode_SGML_Entities,
			},
			expected_doctype = "xliff",
		},
		crc32     = 0x961e7635,
	},

	{
		filename  = "XML/entities.html",
		options   = {
			flags = {
				.Ignore_Unsupported, .Intern_Comments,
			},
			expected_doctype = "html",
		},
		crc32     = 0x573c1033,
	},

	{
		filename  = "XML/entities.html",
		options   = {
			flags = {
				.Ignore_Unsupported, .Intern_Comments, .Unbox_CDATA,
			},
			expected_doctype = "html",
		},
		crc32     = 0x82588917,
	},

	{
		filename  = "XML/entities.html",
		options   = {
			flags = {
				.Ignore_Unsupported, .Intern_Comments, .Unbox_CDATA, .Decode_SGML_Entities,
			},
			expected_doctype = "html",
		},
		crc32     = 0x5e74d8a6,
	},

	/*
		Then we test that certain errors are returned as expected.
	*/
	{
		filename  = "XML/utf8.xml",
		options   = {
			flags            = {
				.Ignore_Unsupported, .Intern_Comments,
			},
			expected_doctype = "Odin",
		},
		err       = .Invalid_DocType,
		crc32     = 0x49b83d0a,
	},

	/*
		Parse the 8.2 MiB unicode.xml for good measure.
	*/
	{
		filename  = "XML/unicode.xml",
		options   = {
			flags            = {
				.Ignore_Unsupported,
			},
			expected_doctype = "",
		},
		err       = .None,
		crc32     = 0xcaa042b9,
	},
}

when ODIN_TEST {
	expect  :: testing.expect
	log     :: testing.log
} else {
	expect  :: proc(t: ^testing.T, condition: bool, message: string, loc := #caller_location) {
		TEST_count += 1
		if !condition {
			TEST_fail += 1
			fmt.printf("[%v] %v\n", loc, message)
			return
		}
	}
	log     :: proc(t: ^testing.T, v: any, loc := #caller_location) {
		fmt.printf("[%v] LOG:\n\t%v\n", loc, v)
	}
}

test_file_path :: proc(filename: string) -> (path: string) {

	path = fmt.tprintf("%v%v/%v", ODIN_ROOT, TEST_FILE_PATH_PREFIX, filename)
	temp := transmute([]u8)path

	for r, i in path {
		if r == '\\' {
			temp[i] = '/'
		}
	}
	return path
}

doc_to_string :: proc(doc: ^xml.Document) -> (result: string) {
	/*
		Effectively a clone of the debug printer in the xml package.
		We duplicate it here so that the way it prints an XML document to a string is stable.

		This way we can hash the output. If it changes, it means that the document or how it was parsed changed,
		not how it was printed. One less source of variability.
	*/
	print :: proc(writer: io.Writer, doc: ^xml.Document) -> (written: int, err: io.Error) {
		if doc == nil { return }
		using fmt

		written += wprintf(writer, "[XML Prolog]\n")

		for attr in doc.prologue {
			written += wprintf(writer, "\t%v: %v\n", attr.key, attr.val)
		}

		written += wprintf(writer, "[Encoding] %v\n", doc.encoding)

		if len(doc.doctype.ident) > 0 {
			written += wprintf(writer, "[DOCTYPE]  %v\n", doc.doctype.ident)

			if len(doc.doctype.rest) > 0 {
			 	wprintf(writer, "\t%v\n", doc.doctype.rest)
			}
		}

		for comment in doc.comments {
			written += wprintf(writer, "[Pre-root comment]  %v\n", comment)
		}

		if doc.element_count > 0 {
		 	wprintln(writer, " --- ")
		 	print_element(writer, doc, 0)
		 	wprintln(writer, " --- ")
		 }

		return written, .None
	}

	print_element :: proc(writer: io.Writer, doc: ^xml.Document, element_id: xml.Element_ID, indent := 0) -> (written: int, err: io.Error) {
		using fmt

		tab :: proc(writer: io.Writer, indent: int) {
			for _ in 0..=indent {
				wprintf(writer, "\t")
			}
		}

		tab(writer, indent)

		element := doc.elements[element_id]

		if element.kind == .Element {
			wprintf(writer, "<%v>\n", element.ident)
			if len(element.value) > 0 {
				tab(writer, indent + 1)
				wprintf(writer, "[Value] %v\n", element.value)
			}

			for attr in element.attribs {
				tab(writer, indent + 1)
				wprintf(writer, "[Attr] %v: %v\n", attr.key, attr.val)
			}

			for child in element.children {
				print_element(writer, doc, child, indent + 1)
			}
		} else if element.kind == .Comment {
			wprintf(writer, "[COMMENT] %v\n", element.value)
		}

		return written, .None
	}

	buf: strings.Builder
	defer strings.destroy_builder(&buf)

	print(strings.to_writer(&buf), doc)
	return strings.clone(strings.to_string(buf))
}

@test
run_tests :: proc(t: ^testing.T) {
	using fmt

	for test in TESTS {
		path := test_file_path(test.filename)
		log(t, fmt.tprintf("Trying to parse %v", path))

		doc, err := xml.load_from_file(path, test.options, Silent)
		defer xml.destroy(doc)

		tree_string := doc_to_string(doc)
		tree_bytes  := transmute([]u8)tree_string
		defer delete(tree_bytes)

		crc32 := hash.crc32(tree_bytes)

		failed := err != test.err
		err_msg := tprintf("Expected return value %v, got %v", test.err, err)
		expect(t, err == test.err, err_msg)

		failed |= crc32 != test.crc32
		err_msg  = tprintf("Expected CRC 0x%08x, got 0x%08x, with options %v", test.crc32, crc32, test.options)
		expect(t, crc32 == test.crc32, err_msg)

		if failed {
			/*
				Don't fully print big trees.
			*/
			tree_string = tree_string[:min(2_048, len(tree_string))]
			println(tree_string)
		}
	}
}

main :: proc() {
	t := testing.T{}

	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	context.allocator = mem.tracking_allocator(&track)

	run_tests(&t)

	if len(track.allocation_map) > 0 {
		for _, v in track.allocation_map {
			err_msg := fmt.tprintf("%v Leaked %v bytes.", v.location, v.size)
			expect(&t, false, err_msg)
		}
	}	

	fmt.printf("\n%v/%v tests successful.\n", TEST_count - TEST_fail, TEST_count)
}