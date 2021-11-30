package test_core_xml

import "core:encoding/xml"
import "core:testing"
import "core:mem"
import "core:fmt"

Silent :: proc(pos: xml.Pos, fmt: string, args: ..any) {
	// Custom (silent) error handler.
}

OPTIONS :: xml.Options{
	flags            = {
		.Ignore_Unsupported, .Intern_Comments,
	},
	expected_doctype = "",
}

TEST_count := 0
TEST_fail  := 0

TEST :: struct {
	filename: string,
	options:  xml.Options,
	expected: struct {
		error:        xml.Error,
		xml_version:  string,
		xml_encoding: string,
		doctype:      string,
	},
}

TESTS :: []TEST{
	/*
		First we test that certain files parse without error.
	*/
	{
		filename  = "assets/xml/utf8.xml",
		options   = OPTIONS,
		expected  = {
			error        = .None,
			xml_version  = "1.0",
			xml_encoding = "utf-8",
			doctype      = "恥ずべきフクロウ",
		},
	},
	{
		filename  = "assets/xml/nl_NL-qt-ts.ts",
		options   = OPTIONS,
		expected  = {
			error        = .None,
			xml_version  = "1.0",
			xml_encoding = "utf-8",
			doctype      = "TS",
		},
	},
	{
		filename  = "assets/xml/nl_NL-xliff-1.0.xliff",
		options   = OPTIONS,
		expected  = {
			error        = .None,
			xml_version  = "1.0",
			xml_encoding = "UTF-8",
			doctype      = "",
		},
	},
	{
		filename  = "assets/xml/nl_NL-xliff-2.0.xliff",
		options   = OPTIONS,
		expected  = {
			error        = .None,
			xml_version  = "1.0",
			xml_encoding = "utf-8",
			doctype      = "",
		},
	},

	/*
		Then we test that certain errors are returned as expected.
	*/
	{
		filename  = "assets/xml/utf8.xml",
		options   = {
			flags            = {
				.Ignore_Unsupported, .Intern_Comments,
			},
			expected_doctype = "Odin",
		},
		expected  = {
			error        = .Invalid_DocType,
			xml_version  = "1.0",
			xml_encoding = "utf-8",
			doctype      = "恥ずべきフクロウ",
		},
	},
}

when ODIN_TEST {
    expect  :: testing.expect
    log     :: testing.log
} else {
    expect  :: proc(t: ^testing.T, condition: bool, message: string, loc := #caller_location) {
        fmt.printf("[%v] ", loc)
        TEST_count += 1
        if !condition {
            TEST_fail += 1
            fmt.println(message)
            return
        }
        fmt.println(" PASS")
    }
    log     :: proc(t: ^testing.T, v: any, loc := #caller_location) {
        fmt.printf("[%v] ", loc)
        fmt.printf("log: %v\n", v)
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

    fmt.printf("%v/%v tests successful.\n", TEST_count - TEST_fail, TEST_count)
}

@test
run_tests :: proc(t: ^testing.T) {
	using fmt

	count := 0

	for test in TESTS {
		printf("Trying to parse %v\n\n", test.filename)

		doc, err := xml.parse(test.filename, test.options, Silent)
		defer xml.destroy(doc)

		err_msg := tprintf("Expected return value %v, got %v", test.expected.error, err)
		expect(t, err == test.expected.error, err_msg)

		if len(test.expected.xml_version) > 0 {
			xml_version := ""
			for attr in doc.prolog {
				if attr.key == "version" {
					xml_version = attr.val
				}
			}

			err_msg  = tprintf("Expected XML version %v, got %v", test.expected.xml_version, xml_version)
			expect(t, xml_version == test.expected.xml_version, err_msg)
		}

		if len(test.expected.xml_encoding) > 0 {
			xml_encoding := ""
			for attr in doc.prolog {
				if attr.key == "encoding" {
					xml_encoding = attr.val
				}
			}

			err_msg  = tprintf("Expected XML encoding %v, got %v", test.expected.xml_encoding, xml_encoding)
			expect(t, xml_encoding == test.expected.xml_encoding, err_msg)
		}

		err_msg  = tprintf("Expected DOCTYPE %v, got %v", test.expected.doctype, doc.doctype.ident)
		expect(t, doc.doctype.ident == test.expected.doctype, err_msg)

		/*
			File-specific tests.
		*/
		switch count {
		case 0:
			expect(t, len(doc.root.attribs) > 0, "Expected the root tag to have an attribute.")
			attr := doc.root.attribs[0]

			attr_key_expected := "올빼미_id"
			attr_val_expected := "Foozle&#32;<![CDATA[<greeting>Hello, world!\"</greeting>]]>Barzle"

			attr_err := tprintf("Expected %v, got %v", attr_key_expected, attr.key)
			expect(t, attr.key == attr_key_expected, attr_err)

			attr_err  = tprintf("Expected %v, got %v", attr_val_expected, attr.val)
			expect(t, attr.val == attr_val_expected, attr_err)

			expect(t, len(doc.root.children) > 0, "Expected the root tag to have children.")
			child := doc.root.children[0]

			first_child_ident := "부끄러운:barzle"
			attr_err  = tprintf("Expected first child tag's ident to be %v, got %v", first_child_ident, child.ident)
			expect(t, child.ident == first_child_ident, attr_err)

		case 2:
			expect(t, len(doc.root.attribs) > 0, "Expected the root tag to have an attribute.")

			{
				attr := doc.root.attribs[0]

				attr_key_expected := "version"
				attr_val_expected := "1.2"

				attr_err := tprintf("Expected %v, got %v", attr_key_expected, attr.key)
				expect(t, attr.key == attr_key_expected, attr_err)

				attr_err  = tprintf("Expected %v, got %v", attr_val_expected, attr.val)
				expect(t, attr.val == attr_val_expected, attr_err)
			}

			{
				attr := doc.root.attribs[1]

				attr_key_expected := "xmlns"
				attr_val_expected := "urn:oasis:names:tc:xliff:document:1.2"

				attr_err := tprintf("Expected %v, got %v", attr_key_expected, attr.key)
				expect(t, attr.key == attr_key_expected, attr_err)

				attr_err  = tprintf("Expected %v, got %v", attr_val_expected, attr.val)
				expect(t, attr.val == attr_val_expected, attr_err)
			}

		case 3:
			expect(t, len(doc.root.attribs) > 0, "Expected the root tag to have an attribute.")

			{
				attr := doc.root.attribs[0]

				attr_key_expected := "xmlns"
				attr_val_expected := "urn:oasis:names:tc:xliff:document:2.0"

				attr_err := tprintf("Expected %v, got %v", attr_key_expected, attr.key)
				expect(t, attr.key == attr_key_expected, attr_err)

				attr_err  = tprintf("Expected %v, got %v", attr_val_expected, attr.val)
				expect(t, attr.val == attr_val_expected, attr_err)
			}

			{
				attr := doc.root.attribs[1]

				attr_key_expected := "version"
				attr_val_expected := "2.0"

				attr_err := tprintf("Expected %v, got %v", attr_key_expected, attr.key)
				expect(t, attr.key == attr_key_expected, attr_err)

				attr_err  = tprintf("Expected %v, got %v", attr_val_expected, attr.val)
				expect(t, attr.val == attr_val_expected, attr_err)
			}
		}

		count += 1
	}
}