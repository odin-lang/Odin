package test_core_json

import "core:encoding/json"
import "core:testing"

@(test)
test_unicode_quoting :: proc(t: ^testing.T) {
	Case :: struct {
		input, want: string,
	}
	cases := [?]Case {
		{"あφ♥😀e\u0301", "\"あφ♥😀e\u0301\""},
		{"\x00\x01\a\e\v", "\"\\u0000\\u0001\\u0007\\u001b\\u000b\""},
		{"\b\f\n\r\t", "\"\\b\\f\\n\\r\\t\""},
		{"\"\\'", "\"\\\"\\\\'\""},
		{"\u00a0\u2028\u2029", "\"\\u00a0\\u2028\\u2029\""},
		{"\U0001d173", "\"\\ud834\\udd73\""},
	}
	for c in cases {
		out, err := json.marshal(c.input)
		defer delete(out)
		testing.expect_value(t, err, nil) or_continue
		testing.expect_value(t, string(out), c.want)

		back: string
		unmarshal_err := json.unmarshal(out, &back)
		defer delete(back)
		testing.expect_value(t, unmarshal_err, nil)
		testing.expect_value(t, back, c.input)
	}
}
