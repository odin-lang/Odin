package test_core_text_i18n

import "base:runtime"
import "core:encoding/endian"
import "core:os"
import "core:slice"
import "core:testing"
import "core:text/i18n"

T :: i18n.get
Tn :: i18n.get_n

Test :: struct {
	section: string,
	key:     string,
	val:     string,
	n:       int,
}

Test_Suite :: struct {
	file:    string,
	loader:  proc(string, i18n.Parse_Options, proc(int) -> int, runtime.Allocator) -> (^i18n.Translation, i18n.Error),
	plural:  proc(int) -> int,
	err:     i18n.Error,
	options: i18n.Parse_Options,
	tests:   []Test,
}

TEST_SUITE_PATH :: ODIN_ROOT + "tests/core/assets/I18N/"

@(test)
test_custom_pluralizer :: proc(t: ^testing.T) {
	// Custom pluralizer for plur.mo
	plur_mo_pluralizer :: proc(n: int) -> (slot: int) {
		switch {
		case n == 1:                       return 0
		case n != 0 && n % 1_000_000 == 0: return 1
		case:                              return 2
		}
	}

	test(t, {
		file   = TEST_SUITE_PATH + "plur.mo",
		loader = i18n.parse_mo_file,
		plural = plur_mo_pluralizer,
		tests  = {
			// These are in the catalog.
			{"", "Message1",                      "This is message 1",             1},
			{"", "Message1",                      "This is message 1 - plural A",  1_000_000},
			{"", "Message1",                      "This is message 1 - plural B",  42},
			{"", "Message1/plural",               "This is message 1",             1},
			{"", "Message1/plural",               "This is message 1 - plural A",  1_000_000},
			{"", "Message1/plural",               "This is message 1 - plural B",  42},

			// This isn't in the catalog, so should return the key.
			{"", "Come visit us on Discord!",     "Come visit us on Discord!",      1},
		},
	})
}

@(test)
test_mixed_context :: proc(t: ^testing.T) {
	test(t, {
		file   = TEST_SUITE_PATH + "mixed_context.mo",
		loader = i18n.parse_mo_file,
		plural = nil,
		tests  = {
			// These are in the catalog.
			{"",        "Message1",               "This is message 1 without Context",-1},
			{"Context", "Message1",               "This is message 1 with Context",   -1},

			// This isn't in the catalog, so should ruturn the key.
			{"", "Come visit us on Discord!",     "Come visit us on Discord!",        -1},
		},
	})
}

@(test)
test_mixed_context_dupe :: proc(t: ^testing.T) {
	test(t, {
		file    = TEST_SUITE_PATH + "mixed_context.mo",
		loader  = i18n.parse_mo_file,
		plural  = nil,
		// Message1 exists twice, once within Context, which has been merged into ""
		err     = .Duplicate_Key,
		options = {merge_sections = true},
	})
}

@(test)
test_mo_contextual_plurals :: proc(t: ^testing.T) {
	test(t, {
		file   = TEST_SUITE_PATH + "contextual_plurals.mo",
		loader = i18n.parse_mo_file,
		plural = nil,
		tests  = {
			{"A", "item",  "A items",           2},
			{"A", "items", "A items",           2},
			{"B", "items", "B items",           2},
			{"",  "items", "items",             2},
			{"",  "plain", "Plain translation", -1},
		},
	})
}

@(test)
test_nl_mo :: proc(t: ^testing.T) {
	test(t, {
		file   = TEST_SUITE_PATH + "nl_NL.mo",
		loader = i18n.parse_mo_file,
		plural = nil, // Default pluralizer
		tests  = {
			// These are in the catalog.
			{"", "There are 69,105 leaves here.", "Er zijn hier 69.105 bladeren.", -1},
			{"", "Hellope, World!",               "Hallo, Wereld!",                -1},
			{"", "There is %d leaf.\n",           "Er is %d blad.\n",               1},
			{"", "There are %d leaves.\n",        "Er is %d blad.\n",               1},
			{"", "There is %d leaf.\n",           "Er zijn %d bladeren.\n",        42},
			{"", "There are %d leaves.\n",        "Er zijn %d bladeren.\n",        42},

			// This isn't in the catalog, so should ruturn the key.
			{"", "Come visit us on Discord!",     "Come visit us on Discord!",     -1},
		},
	})
}

@(test)
test_nl_mo_byte_swapped :: proc(t: ^testing.T) {
	load_byte_swapped :: proc(filename: string, options: i18n.Parse_Options, pluralizer: proc(int) -> int, allocator: runtime.Allocator) -> (^i18n.Translation, i18n.Error) {
		data, err := os.read_entire_file(filename, allocator)
		if err != nil {
			return nil, .File_Error
		}
		defer delete(data, allocator)

		if len(data) < 28 {
			return nil, .MO_File_Invalid
		}
		count             := endian.unchecked_get_u32le(data[ 8:])
		original_offset   := endian.unchecked_get_u32le(data[12:])
		translated_offset := endian.unchecked_get_u32le(data[16:])
		hash_size         := endian.unchecked_get_u32le(data[20:])
		hash_offset       := endian.unchecked_get_u32le(data[24:])

		for offset := u32(0); offset < 28; offset += 4 {
			slice.reverse(data[offset:][:4])
		}
		for offset := u32(0); offset < 8 * count; offset += 4 {
			slice.reverse(data[original_offset + offset:][:4])
			slice.reverse(data[translated_offset + offset:][:4])
		}
		for offset := u32(0); offset < 4 * hash_size; offset += 4 {
			slice.reverse(data[hash_offset + offset:][:4])
		}
		return i18n.parse_mo_from_bytes(data, options, pluralizer, allocator)
	}

	test(t, {
		file   = TEST_SUITE_PATH + "nl_NL.mo",
		loader = load_byte_swapped,
		plural = nil,
		tests  = {
			{"", "There are 69,105 leaves here.", "Er zijn hier 69.105 bladeren.", -1},
			{"", "Hellope, World!",               "Hallo, Wereld!",                -1},
			{"", "There is %d leaf.\n",           "Er is %d blad.\n",               1},
			{"", "There are %d leaves.\n",        "Er is %d blad.\n",               1},
			{"", "There is %d leaf.\n",           "Er zijn %d bladeren.\n",        42},
			{"", "There are %d leaves.\n",        "Er zijn %d bladeren.\n",        42},
			{"", "Come visit us on Discord!",     "Come visit us on Discord!",     -1},
		},
	})
}

@(test)
test_qt_linguist :: proc(t: ^testing.T) {
	test(t, {
		file   = TEST_SUITE_PATH + "nl_NL-qt-ts.ts",
		loader = i18n.parse_qt_linguist_file,
		plural = nil, // Default pluralizer
		tests  = {
			// These are in the catalog.
			{"Page",          "Text for translation",           "Tekst om te vertalen",       -1},
			{"Page",          "Also text to translate",         "Ook tekst om te vertalen",   -1},
			{"installscript", "99 bottles of beer on the wall", "99 flessen bier op de muur", -1},
			{"apple_count",   "%d apple(s)",                    "%d appel",                    1},
			{"apple_count",   "%d apple(s)",                    "%d appels",                  42},

			// These aren't in the catalog, so should ruturn the key.
			{"",              "Come visit us on Discord!",      "Come visit us on Discord!",  -1},
			{"Fake_Section",  "Come visit us on Discord!",      "Come visit us on Discord!",  -1},
		},
	})
}

@(test)
test_qt_linguist_from_bytes :: proc(t: ^testing.T) {
	load_from_bytes :: proc(filename: string, options: i18n.Parse_Options, pluralizer: proc(int) -> int, allocator: runtime.Allocator) -> (^i18n.Translation, i18n.Error) {
		data, err := os.read_entire_file(filename, allocator)
		if err != nil {
			return nil, .File_Error
		}
		defer delete(data, allocator)
		return i18n.parse_qt_linguist_from_bytes(data, options, pluralizer, allocator)
	}

	test(t, {
		file   = TEST_SUITE_PATH + "nl_NL-qt-ts.ts",
		loader = load_from_bytes,
		plural = nil,
		tests  = {
			{"Page",        "Text for translation", "Tekst om te vertalen", -1},
			{"apple_count", "%d apple(s)",          "%d appels",            42},
		},
	})
}

@(test)
test_qt_linguist_merge_sections :: proc(t: ^testing.T) {
	test(t, {
		file    = TEST_SUITE_PATH + "nl_NL-qt-ts.ts",
		loader  = i18n.parse_qt_linguist_file,
		plural  = nil, // Default pluralizer
		options = {merge_sections = true},
		tests   = {
			// All of them are now in section "", lookup with original section should return the key.
			{"",              "Text for translation",           "Tekst om te vertalen",           -1},
			{"",              "Also text to translate",         "Ook tekst om te vertalen",       -1},
			{"",              "99 bottles of beer on the wall", "99 flessen bier op de muur",     -1},
			{"",              "%d apple(s)",                    "%d appel",                        1},
			{"",              "%d apple(s)",                    "%d appels",                      42},

			// All of them are now in section "", lookup with original section should return the key.
			{"Page",          "Text for translation",           "Text for translation",           -1},
			{"Page",          "Also text to translate",         "Also text to translate",         -1},
			{"installscript", "99 bottles of beer on the wall", "99 bottles of beer on the wall", -1},
			{"apple_count",   "%d apple(s)",                    "%d apple(s)",                     1},
			{"apple_count",   "%d apple(s)",                    "%d apple(s)",                    42},
		},
	})
}

@(test)
test_qt_linguist_duplicate_key_err :: proc(t: ^testing.T) {
	test(t, { // QT Linguist, merging sections. Expecting .Duplicate_Key error because same key exists in more than 1 section.
		file    = TEST_SUITE_PATH + "duplicate-key.ts",
		loader  = i18n.parse_qt_linguist_file,
		plural  = nil, // Default pluralizer
		options = {merge_sections = true},
		err     = .Duplicate_Key,
	})
}

@(test)
test_qt_linguist_duplicate_key :: proc(t: ^testing.T) {
	test(t, { // QT Linguist, not merging sections. Shouldn't return error despite same key existing in more than 1 section.
		file    = TEST_SUITE_PATH + "duplicate-key.ts",
		loader  = i18n.parse_qt_linguist_file,
		plural  = nil, // Default pluralizer
	})
}

test :: proc(t: ^testing.T, suite: Test_Suite, loc := #caller_location) {
	cat, err := suite.loader(suite.file, suite.options, suite.plural, context.allocator)
	testing.expectf(t, err == suite.err, "Expected loading %v to return %v, got %v", suite.file, suite.err, err, loc=loc)

	if err == .None {
		for test in suite.tests {
			val := test.n > -1 ? Tn(test.section, test.key, test.n, cat): T(test.section, test.key, cat)
			testing.expectf(t, val == test.val, "Expected key `%v` from section `%v`'s form for value `%v` to equal `%v`, got `%v`", test.key, test.section, test.n, test.val, val, loc=loc)
		}
	}
	i18n.destroy(cat)
}

@(test)
test_qt_linguist_text :: proc(t: ^testing.T) {
	TS ::
		"<?xml version=\"1.0\" encoding=\"utf-8\"?>\n" +
		"<!DOCTYPE TS>\n" +
		"<TS version=\"2.1\" language=\"nl\">\n" +
		"<context>\n" +
		"\t<name>Page</name>\n" +
		"\t<message>\n" +
		"\t\t<source> Hello </source>\n" +
		"\t\t<translation> Hallo </translation>\n" +
		"\t</message>\n" +
		"\t<message>\n" +
		"\t\t<source>Tom &amp; Jerry</source>\n" +
		"\t\t<translation><![CDATA[Tom &amp; Jerry]]></translation>\n" +
		"\t</message>\n" +
		"</context>\n" +
		"</TS>\n"

	cat, err := i18n.parse_qt_linguist_from_bytes(transmute([]u8)string(TS))
	defer i18n.destroy(cat)
	testing.expect_value(t, err, i18n.Error.None)
	if err == .None {
		testing.expect_value(t, T("Page", " Hello ", cat), " Hallo ")
		testing.expect_value(t, T("Page", "Tom & Jerry", cat), "Tom &amp; Jerry")
	}
}
