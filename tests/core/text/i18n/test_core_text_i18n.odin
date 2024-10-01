package test_core_text_i18n

import "base:runtime"
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