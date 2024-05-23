package test_core_text_i18n

import "core:mem"
import "core:fmt"
import "core:os"
import "core:testing"
import "core:text/i18n"

TEST_count := 0
TEST_fail  := 0

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
		fmt.printf("[%v] ", loc)
		fmt.printf("log: %v\n", v)
	}
}
T :: i18n.get

Test :: struct {
	section: string,
	key:     string,
	val:     string,
	n:       int,
}

Test_Suite :: struct {
	file:    string,
	loader:  proc(string, i18n.Parse_Options, proc(int) -> int, mem.Allocator) -> (^i18n.Translation, i18n.Error),
	plural:  proc(int) -> int,
	err:     i18n.Error,
	options: i18n.Parse_Options,
	tests:   []Test,
}

// Custom pluralizer for plur.mo
plur_mo_pluralizer :: proc(n: int) -> (slot: int) {
	switch {
	case n == 1:                       return 0
	case n != 0 && n % 1_000_000 == 0: return 1
	case:                              return 2
	}
}

TESTS := []Test_Suite{
	{
		file   = "assets/I18N/plur.mo",
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

			// This isn't in the catalog, so should ruturn the key.
			{"", "Come visit us on Discord!",     "Come visit us on Discord!",      1},
		},
	},

	{
		file   = "assets/I18N/mixed_context.mo",
		loader = i18n.parse_mo_file,
		plural = nil,
		tests  = {
			// These are in the catalog.
			{"",        "Message1",               "This is message 1 without Context", 1},
			{"Context", "Message1",               "This is message 1 with Context",    1},

			// This isn't in the catalog, so should ruturn the key.
			{"", "Come visit us on Discord!",     "Come visit us on Discord!",         1},
		},
	},

	{
		file    = "assets/I18N/mixed_context.mo",
		loader  = i18n.parse_mo_file,
		plural  = nil,
		// Message1 exists twice, once within Context, which has been merged into ""
		err     = .Duplicate_Key,
		options = {merge_sections = true},
	},

	{
		file   = "assets/I18N/nl_NL.mo",
		loader = i18n.parse_mo_file,
		plural = nil, // Default pluralizer
		tests  = {
			// These are in the catalog.
			{"", "There are 69,105 leaves here.", "Er zijn hier 69.105 bladeren.",  1},
			{"", "Hellope, World!",               "Hallo, Wereld!",                 1},
			{"", "There is %d leaf.\n",           "Er is %d blad.\n",               1},
			{"", "There are %d leaves.\n",        "Er is %d blad.\n",               1},
			{"", "There is %d leaf.\n",           "Er zijn %d bladeren.\n",        42},
			{"", "There are %d leaves.\n",        "Er zijn %d bladeren.\n",        42},

			// This isn't in the catalog, so should ruturn the key.
			{"", "Come visit us on Discord!",     "Come visit us on Discord!",      1},
		},
	},


	// QT Linguist with default loader options.
	{
		file   = "assets/I18N/nl_NL-qt-ts.ts",
		loader = i18n.parse_qt_linguist_file,
		plural = nil, // Default pluralizer
		tests  = {
			// These are in the catalog.
			{"Page",          "Text for translation",           "Tekst om te vertalen",        1},
			{"Page",          "Also text to translate",         "Ook tekst om te vertalen",    1},
			{"installscript", "99 bottles of beer on the wall", "99 flessen bier op de muur",  1},
			{"apple_count",   "%d apple(s)",                    "%d appel",                    1},
			{"apple_count",   "%d apple(s)",                    "%d appels",                  42},

			// These aren't in the catalog, so should ruturn the key.
			{"",              "Come visit us on Discord!",      "Come visit us on Discord!",   1},
			{"Fake_Section",  "Come visit us on Discord!",      "Come visit us on Discord!",   1},
		},
	},

	// QT Linguist, merging sections.
	{
		file    = "assets/I18N/nl_NL-qt-ts.ts",
		loader  = i18n.parse_qt_linguist_file,
		plural  = nil, // Default pluralizer
		options = {merge_sections = true},
		tests   = {
			// All of them are now in section "", lookup with original section should return the key.
			{"",              "Text for translation",           "Tekst om te vertalen",            1},
			{"",              "Also text to translate",         "Ook tekst om te vertalen",        1},
			{"",              "99 bottles of beer on the wall", "99 flessen bier op de muur",      1},
			{"",              "%d apple(s)",                    "%d appel",                        1},
			{"",              "%d apple(s)",                    "%d appels",                      42},

			// All of them are now in section "", lookup with original section should return the key.
			{"Page",          "Text for translation",           "Text for translation",            1},
			{"Page",          "Also text to translate",         "Also text to translate",          1},
			{"installscript", "99 bottles of beer on the wall", "99 bottles of beer on the wall",  1},
			{"apple_count",   "%d apple(s)",                    "%d apple(s)",                     1},
			{"apple_count",   "%d apple(s)",                    "%d apple(s)",                    42},
		},
	},

	// QT Linguist, merging sections. Expecting .Duplicate_Key error because same key exists in more than 1 section.
	{
		file    = "assets/I18N/duplicate-key.ts",
		loader  = i18n.parse_qt_linguist_file,
		plural  = nil, // Default pluralizer
		options = {merge_sections = true},
		err     = .Duplicate_Key,
	},

	// QT Linguist, not merging sections. Shouldn't return error despite same key existing in more than 1 section.
	{
		file    = "assets/I18N/duplicate-key.ts",
		loader  = i18n.parse_qt_linguist_file,
		plural  = nil, // Default pluralizer
	},
}

@test
tests :: proc(t: ^testing.T) {
	cat: ^i18n.Translation
	err: i18n.Error

	for suite in TESTS {
		cat, err = suite.loader(suite.file, suite.options, suite.plural, context.allocator)

		msg := fmt.tprintf("Expected loading %v to return %v, got %v", suite.file, suite.err, err)
		expect(t, err == suite.err, msg)

		if err == .None {
			for test in suite.tests {
				val := T(test.section, test.key, test.n, cat)

				msg  = fmt.tprintf("Expected key `%v` from section `%v`'s form for value `%v` to equal `%v`, got `%v`", test.key, test.section, test.n, test.val, val)
				expect(t, val == test.val, msg)
			}
		}
		i18n.destroy(cat)
	}
}

main :: proc() {
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	context.allocator = mem.tracking_allocator(&track)

	t := testing.T{}
	tests(&t)

	fmt.printf("%v/%v tests successful.\n", TEST_count - TEST_fail, TEST_count)
	if TEST_fail > 0 {
		os.exit(1)
	}

	if len(track.allocation_map) > 0 {
		fmt.println()
		for _, v in track.allocation_map {
			fmt.printf("%v Leaked %v bytes.\n", v.location, v.size)
		}
	}
}