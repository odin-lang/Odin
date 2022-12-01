package test_strlib

import lua "core:text/lua"
import "core:testing"
import "core:fmt"
import "core:os"
import "core:io"

TEST_count: int
TEST_fail: int

// inline expect with custom props
failed :: proc(t: ^testing.T, ok: bool, loc := #caller_location) -> bool {
	TEST_count += 1
	
	if !ok {
		fmt.wprintf(t.w, "%v: ", loc)
		t.error_count += 1	
		TEST_fail += 1
	}

	return !ok
}

expect :: testing.expect

logf :: proc(t: ^testing.T, format: string, args: ..any) {
	fmt.wprintf(t.w, format, ..args)
}

// find correct byte offsets 
@test
test_find :: proc(t: ^testing.T) {
	Entry :: struct {
		s, p: string,
		offset: int,
		
		match: struct {
			start, end: int, // expected start/end
			ok: bool,
		},
	}

	ENTRIES :: [?]Entry {
		{ "", "", 0, { 0, 0, true } },
		{ "alo", "", 0, { 0, 0, true } },
		{ "a o a o a o", "a", 0, { 0, 1, true } },
		{ "a o a o a o", "a o", 1, { 4, 7, true } },
		{ "alo123alo", "12", 0, { 3, 5, true } },
		{ "alo123alo", "^12", 0, {} },

		// from https://riptutorial.com/lua/example/20535/string-find--introduction-
		{ "137'5 m47ch s0m3 d1g175", "m%d%d", 0, { 6, 9, true } },
		{ "stack overflow", "[abc]", 0, { 2, 3, true } },
		{ "stack overflow", "[^stack ]", 0, { 6, 7, true } },
		{ "hello", "o%d?", 0, { 4, 5, true } },
		{ "hello20", "o%d?", 0, { 4, 6, true } },
		{ "helllllo", "el+", 0, { 1, 7, true } },
		{ "heo", "el+", 0, {} },
		{ "helelo", "h.+l", 0, { 0, 5, true } },
		{ "helelo", "h.-l", 0, { 0, 3, true } },
	}

	captures: [lua.MAXCAPTURES]lua.Match
	for entry, i in ENTRIES {
		captures[0] = {}
		length, err := lua.find_aux(entry.s, entry.p, entry.offset, true, &captures)
		cap := captures[0]
		ok := length > 0 && err == .OK
		success := entry.match.ok == ok && entry.match.start == cap.byte_start && entry.match.end == cap.byte_end 

		if failed(t, success) {
			logf(t, "Find %d failed!\n", i)
			logf(t, "\tHAYSTACK %s\tPATTERN %s\n", entry.s, entry.p)
			logf(t, "\tSTART: %d == %d?\n", entry.match.start, cap.byte_start)
			logf(t, "\tEND: %d == %d?\n", entry.match.end, cap.byte_end)
			logf(t, "\tErr: %v\tLength %d\n", err, length)			
		}
	}
}

@test
test_match :: proc(t: ^testing.T) {
	Entry :: struct {
		s, p: string,
		result: string, // expected start/end
		ok: bool,	
	}

	ENTRIES :: [?]Entry {
		// star
		{ "aaab", ".*b", "aaab", true },
		{ "aaa", ".*a", "aaa", true },
		{ "b", ".*b", "b", true },
		
		// plus
		{ "aaab", ".+b", "aaab", true },
		{ "aaa", ".+a", "aaa", true },
		{ "b", ".+b", "", false },
		
		// question
		{ "aaab", ".?b", "ab", true },
		{ "aaa", ".?a", "aa", true },
		{ "b", ".?b", "b", true },

		// CLASSES, checking shorted invalid patterns
		{ "a", "%", "", false },

		// %a letter (A-Z, a-z)
		{ "letterS", "%a+", "letterS", true },
		{ "Let123", "%a+", "Let", true },
		{ "Let123", "%A+", "123", true },

		// %c control characters (\n, \t, \r)
		{ "\n", "%c", "\n", true },
		{ "\t", "%c", "\t", true },
		{ "\t", "%C", "", false },
		{ "a", "%C", "a", true },

		// %d digit characters (0-9)
		{ "0123", "%d+", "0123", true },
		{ "abcd", "%D+", "abcd", true },
		{ "ab23", "%d+", "23", true },

		// %l lower characters (a-z)
		{ "lowerCASE", "%l+", "lower", true }, 
		{ "LOWERcase", "%l+", "case", true }, 
		{ "LOWERcase", "%L+", "LOWER", true }, 

		// %p punctionation characters (!, ?, &, ...)
		{ "!?&", "%p+", "!?&", true },
		{ "abc!abc", "%p", "!", true },
		{ "!abc!", "%P+", "abc", true },

		// %s space characters
		{ " ", "%s", " ", true },
		{ "a", "%S", "a", true },
		{ "abc   ", "%s+", "   ", true },

		// %u upper characters (A-Z)
		{ "lowerCASE", "%u+", "CASE", true }, 
		{ "LOWERcase", "%u+", "LOWER", true }, 
		{ "LOWERcase", "%U+", "case", true },

		// %w alpha numeric (A-Z, a-z, 0-9)
		{ "0123", "%w+", "0123", true },
		{ "abcd", "%W+", "", false },
		{ "ab23", "%w+", "ab23", true },		

		// %x hexadecimal digits (0x1A, ...)
		{ "3", "%x", "3", true },
		{ "9f", "%x+", "9f", true },
		{ "9g", "%x+", "9", true },
		{ "9g", "%X+", "g", true },

		// random tests
		{ "f123", "%D", "f", true },
		{ "f123", "%d", "1", true },
		{ "f123", "%d+", "123", true },
		{ "foo 123 bar", "%d%d%d", "123", true },
		{ "Uppercase", "%u", "U", true },
		{ "abcd", "[bc][bc]", "bc", true },
		{ "abcd", "[^ad]", "b", true },
		{ "123", "[0-9]", "1", true },

		// end of line
		{ "testing this", "this$", "this", true },
		{ "testing this ", "this$", "", false },
		{ "testing this$", "this%$$", "this$", true },

		// start of line
		{ "testing this", "^testing", "testing", true },
		{ " testing this", "^testing", "", false },
		{ "testing this", "^%w+", "testing", true },
		{ " testing this", "^%w+", "", false },

		// balanced string %b
		{ "testing (this) out", "%b()", "(this)", true },
		{ "testing athisz out", "%baz", "athisz", true },
		{ "testing _this_ out", "%b__", "_this_", true },
		{ "testing _this_ out", "%b_", "", false },
	}

	captures: [lua.MAXCAPTURES]lua.Match
	for entry, i in ENTRIES {
		captures[0] = {}
		length, err := lua.find_aux(entry.s, entry.p, 0, false, &captures)
		ok := length > 0 && err == .OK
		result := entry.s[captures[0].byte_start:captures[0].byte_end]
		success := entry.ok == ok && result == entry.result

		if failed(t, success) {
			logf(t, "Match %d failed!\n", i)
			logf(t, "\tHAYSTACK %s\tPATTERN %s\n", entry.s, entry.p)
			logf(t, "\tResults: WANTED %s\tGOT %s\n", entry.result, result)
			logf(t, "\tErr: %v\tLength %d\n", err, length)
		}
	}
}

@test
test_captures :: proc(t: ^testing.T) {
	Temp :: struct {
		pattern: string,
		captures: [lua.MAXCAPTURES]lua.Match,
	}

	// match all captures
	compare_captures :: proc(t: ^testing.T, test: ^Temp, haystack: string, comp: []string, loc := #caller_location) {
		length, err := lua.find_aux(haystack, test.pattern, 0, false, &test.captures)
		if failed(t, len(comp) == length) {
			logf(t, "Captures Compare Failed -> Lengths %d != %d\n", len(comp), length)
		}

		for i in 0..<length {
			cap := test.captures[i]
			text := haystack[cap.byte_start:cap.byte_end]

			if failed(t, comp[i] == text) {
				logf(t, "Capture don't equal -> %s != %s\n", comp[i], text)
			}
		}
	}

	// match to expected results
	matches :: proc(t: ^testing.T, test: ^Temp, haystack: string, ok: bool, loc := #caller_location) {
		length, err := lua.find_aux(haystack, test.pattern, 0, false, &test.captures)
		result := length > 0 && err == .OK

		if failed(t, result == ok) {
			logf(t, "Capture match failed!\n")
			logf(t, "\tErr: %v\n", err)
			logf(t, "\tLength: %v\n", length)
		}
	}

	temp := Temp { pattern = "(one).+" }
	compare_captures(t, &temp, " one two", { "one two", "one" })
	compare_captures(t, &temp, "three", {})
	
	matches(t, &temp, "one dog", true)
	matches(t, &temp, "dog one ", true)
	matches(t, &temp, "dog one", false)
	
	temp.pattern = "^(%a+)"
	matches(t, &temp, "one dog", true)
	matches(t, &temp, " one dog", false)

	// multiple captures
	{
		haystack := " 233   hello dolly"
		pattern := "%s*(%d+)%s+(%S+)"
		captures: [lua.MAXCAPTURES]lua.Match
		lua.find_aux(haystack, pattern, 0, false, &captures)
		cap1 := captures[1]
		cap2 := captures[2]
		text1 := haystack[cap1.byte_start:cap1.byte_end]
		text2 := haystack[cap2.byte_start:cap2.byte_end]
		expect(t, text1 == "233", "Multi-Capture failed at 1")
		expect(t, text2 == "hello", "Multi-Capture failed at 2")
	}
}

@test
test_gmatch :: proc(t: ^testing.T) {
	gmatch_check :: proc(t: ^testing.T, index: int, a: []string, b: string) {
		if failed(t, a[index] == b) {
			logf(t, "GMATCH %d failed!\n", index)
			logf(t, "\t%s != %s\n", a[index], b)
		}
	}

	{
		haystack := "testing this out 123"
		pattern := "%w+"
		s := &haystack
		captures: [lua.MAXCAPTURES]lua.Match
		output := [?]string { "testing", "this", "out", "123" }
		index: int

		for match in lua.gmatch(s, pattern, &captures) {
			gmatch_check(t, index, output[:], match)
			index += 1
		}
	}

	{
		haystack := "#afdde6"
		pattern := "%x%x"
		s := &haystack
		captures: [lua.MAXCAPTURES]lua.Match
		output := [?]string { "af", "dd", "e6" }
		index: int

		for match in lua.gmatch(s, pattern, &captures) {
			gmatch_check(t, index, output[:], match)
			index += 1
		}
	}

	{
		haystack := "testing outz captures yo outz outtz"
		pattern := "(out)z"
		s := &haystack
		captures: [lua.MAXCAPTURES]lua.Match
		output := [?]string { "out", "out" }
		index: int

		for match in lua.gmatch(s, pattern, &captures) {
			gmatch_check(t, index, output[:], match)
			index += 1
		}
	}		
}

@test
test_gsub :: proc(t: ^testing.T) {
	result := lua.gsub("testing123testing", "%d+", " sup ", context.temp_allocator)
	expect(t, result == "testing sup testing", "GSUB 0: failed")
	result = lua.gsub("testing123testing", "%a+", "345", context.temp_allocator)
	expect(t, result == "345123345", "GSUB 1: failed")
}

@test
test_gfind :: proc(t: ^testing.T) {
	haystack := "test1 123 test2 123 test3"
	pattern := "%w+" 
	captures: [lua.MAXCAPTURES]lua.Match
	s := &haystack
	output := [?]string { "test1", "123", "test2", "123", "test3" }
	index: int

	for word in lua.gfind(s, pattern, &captures) {
		if failed(t, output[index] == word) {
			logf(t, "GFIND %d failed!\n", index)
			logf(t, "\t%s != %s\n", output[index], word)
		}
		index += 1
	}
}

@test
test_frontier :: proc(t: ^testing.T) {
	Temp :: struct {
		t: ^testing.T,
		index: int,
		output: [3]string,
	}
	
	call :: proc(data: rawptr, word: string) {
		temp := cast(^Temp) data

		if failed(temp.t, word == temp.output[temp.index]) {
			logf(temp.t, "GSUB_WITH %d failed!\n", temp.index)
			logf(temp.t, "\t%s != %s\n", temp.output[temp.index], word)			
		}

		temp.index += 1
	}

	temp := Temp {
		t = t,
		output = {
			"THE",
			"QUICK",
			"JUMPS",
		},
	}

	// https://lua-users.org/wiki/FrontierPattern example taken from here
	lua.gsub_with("THE (QUICK) brOWN FOx JUMPS", "%f[%a]%u+%f[%A]", &temp, call)
}

@test
test_utf8 :: proc(t: ^testing.T) {
	// {
	// 	haystack := "恥ずべき恥フク恥ロ"
	// 	s := &haystack
	// 	captures: [lua.MAXCAPTURES]lua.Match

	// 	for word in lua.gmatch(s, "恥", &captures) {
	// 		fmt.eprintln(word)
	// 	}
	// }

	{
		haystack := "恥ずべき恥フク恥ロ"
		s := &haystack
		captures: [lua.MAXCAPTURES]lua.Match

		for word in lua.gmatch(s, "w+", &captures) {
			fmt.eprintln(word)
		}
	}

	// captures: [MAXCAPTURES]Match
	// length, err := lua.find_aux("damn, pattern,)
}

main :: proc() {
	t: testing.T
	stream := os.stream_from_handle(os.stdout)
	w := io.to_writer(stream)
	t.w = w
	
	test_find(&t)
	test_match(&t)
	test_captures(&t)
	test_gmatch(&t)
	test_gsub(&t)
	test_gfind(&t)
	test_frontier(&t)

	// test_utf8(&t)

	fmt.wprintf(w, "%v/%v tests successful.\n", TEST_count - TEST_fail, TEST_count)
	if TEST_fail > 0 {
		os.exit(1)
	}
}