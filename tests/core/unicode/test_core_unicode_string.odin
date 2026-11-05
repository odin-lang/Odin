package test_core_unicode

import "core:testing"
import "core:unicode/utf8"
import "core:unicode/utf8/utf8string"

@(rodata, private="file")
cases := [?]string{
	"Hello, world! 你好，世界",
	"aカ.ヒフ",
	"いろはにほへ",
	"He\u200dllo",
	"H̷e̶l̵l̸o̴p̵e̷ ̸w̶o̸r̵l̶d̵!̴",
	"舍利弗，是諸法空相，不生不滅，不垢不淨，不增不減。",
}

@(test)
test_utf8string_adjacent_runes :: proc(t: ^testing.T) {
	for str in cases {
		runes := utf8.string_to_runes(str)
		defer delete(runes)
		// next rune position special case
		{
			us := utf8string.init(&{}, str)
			for r, i in runes {
				testing.expect_value(t, utf8string.at(us, i), r)
			}
		}
		// previous rune position special case
		{
			us := utf8string.init(&{}, str)
			#reverse for r, i in runes {
				testing.expect_value(t, utf8string.at(us, i), r)
			}
		}
	}
}

@(test)
test_utf8string_non_adjacent_runes :: proc(t: ^testing.T) {
	for str in cases {
		runes := utf8.string_to_runes(str)
		defer delete(runes)
		{
			us := utf8string.init(&{}, str)
			for i := 0; i < len(runes); i += 2 {
				testing.expect_value(t, utf8string.at(us, i), runes[i])
			}
		}
		{
			us := utf8string.init(&{}, str)
			for i := 1; i < len(runes); i += 2 {
				testing.expect_value(t, utf8string.at(us, i), runes[i])
			}
		}
	}
}
