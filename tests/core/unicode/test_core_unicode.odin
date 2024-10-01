package test_core_unicode

import "core:log"
import "core:testing"
import "core:unicode/utf8"

Test_Case :: struct {
	str: string,
	expected_clusters: int,
}

run_test_cases :: proc(t: ^testing.T, test_cases: []Test_Case, loc := #caller_location) {
	failed := 0
	for c, i in test_cases {
		log.debugf("(#% 4i) %q ...", i, c.str)
		result, _, _ := utf8.grapheme_count(c.str)
		if !testing.expectf(t, result == c.expected_clusters,
			"(#% 4i) graphemes: %i != %i, %q %s", i, result, c.expected_clusters, c.str, c.str,
			loc = loc) {
			failed += 1
		}
	}

	log.logf(.Error if failed > 0 else .Info, "% 4i/% 4i test cases failed.", failed, len(test_cases), location = loc)
}

@test
test_official_gcb_cases :: proc(t: ^testing.T) {
	run_test_cases(t, official_grapheme_break_test_cases)
}

@test
test_official_emoji_cases :: proc(t: ^testing.T) {
	run_test_cases(t, official_emoji_test_cases)
}

@test
test_grapheme_byte_index_segmentation :: proc(t: ^testing.T) {
	SAMPLE_1 :: "\U0001F600"
	SAMPLE_2 :: "\U0001F3F4\U000E0067\U000E0062\U000E0065\U000E006E\U000E0067\U000E007F"
	SAMPLE_3 :: "\U0001F468\U0001F3FB\u200D\U0001F9B0"

	str := SAMPLE_1 + SAMPLE_2 + SAMPLE_3 + SAMPLE_2 + SAMPLE_1

	graphemes, _, _, _ := utf8.decode_grapheme_clusters(str)
	defer delete(graphemes)

	defer if testing.failed(t) {
		log.infof("%#v\n%q\n%v", graphemes, str, transmute([]u8)str)
	}
	if !testing.expect_value(t, len(graphemes), 5) {
		return
	}

	testing.expect_value(t, graphemes[0].rune_index, 0)
	testing.expect_value(t, graphemes[1].rune_index, 1)
	testing.expect_value(t, graphemes[2].rune_index, 8)
	testing.expect_value(t, graphemes[3].rune_index, 12)
	testing.expect_value(t, graphemes[4].rune_index, 19)

	grapheme_1 := str[graphemes[0].byte_index:graphemes[1].byte_index]
	grapheme_2 := str[graphemes[1].byte_index:graphemes[2].byte_index]
	grapheme_3 := str[graphemes[2].byte_index:graphemes[3].byte_index]
	grapheme_4 := str[graphemes[3].byte_index:graphemes[4].byte_index]
	grapheme_5 := str[graphemes[4].byte_index:]

	testing.expectf(t, grapheme_1 == SAMPLE_1, "expected %q, got %q", SAMPLE_1, grapheme_1)
	testing.expectf(t, grapheme_2 == SAMPLE_2, "expected %q, got %q", SAMPLE_2, grapheme_2)
	testing.expectf(t, grapheme_3 == SAMPLE_3, "expected %q, got %q", SAMPLE_3, grapheme_3)
	testing.expectf(t, grapheme_4 == SAMPLE_2, "expected %q, got %q", SAMPLE_2, grapheme_2)
	testing.expectf(t, grapheme_5 == SAMPLE_1, "expected %q, got %q", SAMPLE_1, grapheme_1)
}

@test
test_width :: proc(t: ^testing.T) {
	{
		str := "He\u200dllo"
		graphemes, _, width := utf8.grapheme_count(str)
		testing.expect_value(t, graphemes, 5)
		testing.expect_value(t, width, 5)
	}

	{
		// Note that a zero-width space is still considered a grapheme as far
		// as the specification is concerned.
		str := "He\u200bllo"
		graphemes, _, width := utf8.grapheme_count(str)
		testing.expect_value(t, graphemes, 6)
		testing.expect_value(t, width, 5)
	}

	{
		str := "\U0001F926\U0001F3FC\u200D\u2642"
		graphemes, _, width := utf8.grapheme_count(str)
		testing.expect_value(t, graphemes, 1)
		testing.expect_value(t, width, 2)
	}

	{
		str := "H̷e̶l̵l̸o̴p̵e̷ ̸w̶o̸r̵l̶d̵!̴"
		graphemes, _, width := utf8.grapheme_count(str)
		testing.expect_value(t, graphemes, 14)
		testing.expect_value(t, width, 14)
	}

	{
		str := "aカ.ヒフ"
		graphemes, grapheme_count, _, width := utf8.decode_grapheme_clusters(str)
		defer delete(graphemes)
		testing.expect_value(t, grapheme_count, 5)
		testing.expect_value(t, width, 8)
		if grapheme_count == 5 {
			testing.expect_value(t, graphemes[0].width, 1)
			testing.expect_value(t, graphemes[1].width, 2)
			testing.expect_value(t, graphemes[2].width, 1)
			testing.expect_value(t, graphemes[3].width, 2)
			testing.expect_value(t, graphemes[4].width, 2)
		}
	}

	{
		str := "いろはにほへ"
		graphemes, _, width := utf8.grapheme_count(str)
		testing.expect_value(t, graphemes, 6)
		testing.expect_value(t, width, 12)
	}

	{
		str := "舍利弗，是諸法空相，不生不滅，不垢不淨，不增不減。"
		graphemes, _, width := utf8.grapheme_count(str)
		testing.expect_value(t, graphemes, 25)
		testing.expect_value(t, width, 50)
	}
}
