package tests_bifrost

import "core:bytes"
import "core:testing"
import "core:time"
import http "vendor:bifrost/http"

Header_Write_Test :: struct {
	h: http.Header,
	exclude: map[string]bool,
	expected: string,
}

header_write_tests := []Header_Write_Test{
	{h = http.Header{}, exclude = nil, expected = ""},
	{
		h = http.Header{
			"Content-Type" = []string{"text/html; charset=UTF-8"},
			"Content-Length" = []string{"0"},
		},
		exclude = nil,
		expected = "Content-Length: 0\r\nContent-Type: text/html; charset=UTF-8\r\n",
	},
	{
		h = http.Header{
			"Content-Length" = []string{"0", "1", "2"},
		},
		exclude = nil,
		expected = "Content-Length: 0\r\nContent-Length: 1\r\nContent-Length: 2\r\n",
	},
	{
		h = http.Header{
			"Expires" = []string{"-1"},
			"Content-Length" = []string{"0"},
			"Content-Encoding" = []string{"gzip"},
		},
		exclude = map[string]bool{"Content-Length" = true},
		expected = "Content-Encoding: gzip\r\nExpires: -1\r\n",
	},
	{
		h = http.Header{
			"Expires" = []string{"-1"},
			"Content-Length" = []string{"0", "1", "2"},
			"Content-Encoding" = []string{"gzip"},
		},
		exclude = map[string]bool{"Content-Length" = true},
		expected = "Content-Encoding: gzip\r\nExpires: -1\r\n",
	},
	{
		h = http.Header{
			"Expires" = []string{"-1"},
			"Content-Length" = []string{"0"},
			"Content-Encoding" = []string{"gzip"},
		},
		exclude = map[string]bool{"Content-Length" = true, "Expires" = true, "Content-Encoding" = true},
		expected = "",
	},
	{
		h = http.Header{
			"Nil" = nil,
			"Empty" = []string{},
			"Blank" = []string{""},
			"Double-Blank" = []string{"", ""},
		},
		exclude = nil,
		expected = "Blank: \r\nDouble-Blank: \r\nDouble-Blank: \r\n",
	},
	{
		h = http.Header{
			"k1" = []string{"1a", "1b"},
			"k2" = []string{"2a", "2b"},
			"k3" = []string{"3a", "3b"},
			"k4" = []string{"4a", "4b"},
			"k5" = []string{"5a", "5b"},
			"k6" = []string{"6a", "6b"},
			"k7" = []string{"7a", "7b"},
			"k8" = []string{"8a", "8b"},
			"k9" = []string{"9a", "9b"},
		},
		exclude = map[string]bool{"k5" = true},
		expected = "k1: 1a\r\nk1: 1b\r\nk2: 2a\r\nk2: 2b\r\nk3: 3a\r\nk3: 3b\r\n" +
			"k4: 4a\r\nk4: 4b\r\nk6: 6a\r\nk6: 6b\r\n" +
			"k7: 7a\r\nk7: 7b\r\nk8: 8a\r\nk8: 8b\r\nk9: 9a\r\nk9: 9b\r\n",
	},
	{
		h = http.Header{
			"Content-Type" = []string{"text/html; charset=UTF-8"},
			"NewlineInValue" = []string{"1\r\nBar: 2"},
			"NewlineInKey\r\n" = []string{"1"},
			"Colon:InKey" = []string{"1"},
			"Evil: 1\r\nSmuggledValue" = []string{"1"},
		},
		exclude = nil,
		expected = "Content-Type: text/html; charset=UTF-8\r\n" +
			"NewlineInValue: 1  Bar: 2\r\n",
	},
}

@(test)
test_header_write_subset :: proc(t: ^testing.T) {
	buf: bytes.Buffer
	for i in 0..<len(header_write_tests) {
		test := header_write_tests[i]
		bytes.buffer_init_allocator(&buf, 0, 512)
		http.header_write_subset(&buf, test.h, test.exclude)
		got := string(bytes.buffer_to_bytes(&buf))
		ev(t, got, test.expected)
		bytes.buffer_destroy(&buf)
	}
}

Has_Token_Test :: struct {
	header: string,
	token: string,
	want: bool,
}

has_token_tests := []Has_Token_Test{
	{header = "", token = "", want = false},
	{header = "", token = "foo", want = false},
	{header = "foo", token = "foo", want = true},
	{header = "foo ", token = "foo", want = true},
	{header = " foo", token = "foo", want = true},
	{header = " foo ", token = "foo", want = true},
	{header = "foo,bar", token = "foo", want = true},
	{header = "bar,foo", token = "foo", want = true},
	{header = "bar, foo", token = "foo", want = true},
	{header = "bar,foo, baz", token = "foo", want = true},
	{header = "bar, foo,baz", token = "foo", want = true},
	{header = "bar,foo, baz", token = "foo", want = true},
	{header = "bar, foo, baz", token = "foo", want = true},
	{header = "FOO", token = "foo", want = true},
	{header = "FOO ", token = "foo", want = true},
	{header = " FOO", token = "foo", want = true},
	{header = " FOO ", token = "foo", want = true},
	{header = "FOO,BAR", token = "foo", want = true},
	{header = "BAR,FOO", token = "foo", want = true},
	{header = "BAR, FOO", token = "foo", want = true},
	{header = "BAR,FOO, baz", token = "foo", want = true},
	{header = "BAR, FOO,BAZ", token = "foo", want = true},
	{header = "BAR,FOO, BAZ", token = "foo", want = true},
	{header = "BAR, FOO, BAZ", token = "foo", want = true},
	{header = "foobar", token = "foo", want = false},
	{header = "barfoo ", token = "foo", want = false},
}

@(test)
test_has_token :: proc(t: ^testing.T) {
	for tt in has_token_tests {
		h := http.Header{"Test" = []string{tt.header}}
		got := http.header_has_token(h, "Test", tt.token)
		ev(t, got, tt.want)
	}
}

Parse_Time_Test :: struct {
	h: http.Header,
	err: bool,
}

parse_time_tests := []Parse_Time_Test{
	{h = http.Header{"Date" = []string{""}}, err = true},
	{h = http.Header{"Date" = []string{"invalid"}}, err = true},
	{h = http.Header{"Date" = []string{"1994-11-06T08:49:37Z00:00"}}, err = true},
	{h = http.Header{"Date" = []string{"Sun, 06 Nov 1994 08:49:37 GMT"}}, err = false},
	{h = http.Header{"Date" = []string{"Sunday, 06-Nov-94 08:49:37 GMT"}}, err = false},
	{h = http.Header{"Date" = []string{"Sun Nov  6 08:49:37 1994"}}, err = false},
}

@(test)
test_parse_time :: proc(t: ^testing.T) {
	expect, ok := time.components_to_time(1994, 11, 6, 8, 49, 37)
	ev(t, ok, true)
	for i in 0..<len(parse_time_tests) {
		test := parse_time_tests[i]
		date_str, _ := http.header_get(test.h, "Date")
		got, ok_parse := http.parse_time(date_str)
		if test.err {
			ev(t, ok_parse, false)
			continue
		}
		ev(t, ok_parse, true)
		ev(t, got, expect)
	}
}
