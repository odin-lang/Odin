package test_core_ini

import "core:encoding/ini"
import "core:os"
import "core:strings"
import "core:testing"

@(test)
test_review_iterate_lines :: proc(t: ^testing.T) {
	src := "global = 1\r\n\r\n; comment\r\n  [s]  \r\nctrl+= = zoom\r\na=b = c\r\nk = v ; note\r\nno equals sign\r\nkey=value\r\n   indented   =   x   \r\n[open\r\nin_open = 1\r\n[t] junk\r\nin_t = 2\r\nempty =\r\n"
	expected := [][3]string{
		{"",     "global",   "1"},
		{"s",    "ctrl+=",   "zoom"},
		{"s",    "a=b",      "c"},
		{"s",    "k",        "v ; note"},
		{"s",    "key",      "value"},
		{"s",    "indented", "x"},
		{"open", "in_open",  "1"},
		{"t",    "in_t",     "2"},
		{"t",    "empty",    ""},
	}
	it := ini.iterator_from_string(src)
	i := 0
	for key, value in ini.iterate(&it) {
		if i < len(expected) {
			testing.expect_value(t, it.section, expected[i][0])
			testing.expect_value(t, key,        expected[i][1])
			testing.expect_value(t, value,      expected[i][2])
		}
		i += 1
	}
	testing.expect_value(t, i, len(expected))
	testing.expect_value(t, it.section, "")
}

@(test)
test_review_comment_options :: proc(t: ^testing.T) {
	src := "; a = 1\n# b = 2\n// c = 3\nd = 4\n"
	cases := []struct{comment: string, keys: []string}{
		{";",  {"# b", "// c", "d"}},
		{"#",  {"; a", "// c", "d"}},
		{"//", {"; a", "# b", "d"}},
		{"",   {"; a", "# b", "// c", "d"}},
	}
	for c in cases {
		it := ini.iterator_from_string(src, {comment = c.comment})
		i := 0
		for key in ini.iterate(&it) {
			if i < len(c.keys) {
				testing.expect_value(t, key, c.keys[i])
			}
			i += 1
		}
		testing.expect_value(t, i, len(c.keys))
	}
}

@(test)
test_review_load_values :: proc(t: ^testing.T) {
	src := "d = \"x\\ty\"\ni = 'a\\tb'\ne = \"unterminated\nf = \"a\" trailing\ng = 'it''s'\nh = \"ab'\nr = `raw`\nj = 'J'\nu = \"\\u00e9\"\nn =\n"
	m, err := ini.load_map_from_string(src, context.allocator)
	defer ini.delete_map(m)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, len(m[""]), 10)
	testing.expect_value(t, m[""]["d"], "x\ty")
	testing.expect_value(t, m[""]["i"], `a\tb`)
	testing.expect_value(t, m[""]["e"], `"unterminated`)
	testing.expect_value(t, m[""]["f"], `"a" trailing`)
	testing.expect_value(t, m[""]["g"], `'it''s'`)
	testing.expect_value(t, m[""]["h"], `"ab'`)
	testing.expect_value(t, m[""]["r"], "`raw`")
	testing.expect_value(t, m[""]["j"], "J")
	testing.expect_value(t, m[""]["u"], "é")
	testing.expect_value(t, m[""]["n"], "")
}

@(test)
test_review_key_lower_case :: proc(t: ^testing.T) {
	options := ini.DEFAULT_OPTIONS
	options.key_lower_case = true
	m, err := ini.load_map_from_string("[Sec]\nKey = VaLuE\n", context.allocator, options)
	defer ini.delete_map(m)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, m["Sec"]["key"], "VaLuE")
}

@(test)
test_review_duplicate_sections_merge :: proc(t: ^testing.T) {
	m, err := ini.load_map_from_string("[a]\nx = 1\n[b]\ny = 2\n[a]\nz = 3\n", context.allocator)
	defer ini.delete_map(m)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, len(m), 2)
	testing.expect_value(t, len(m["a"]), 2)
	testing.expect_value(t, m["a"]["x"], "1")
	testing.expect_value(t, m["a"]["z"], "3")
	testing.expect_value(t, m["b"]["y"], "2")
}

@(test)
test_review_load_nothing :: proc(t: ^testing.T) {
	for src in ([]string{"", "\n\n", "; only a comment\n", "no pairs here\n", "[section only]\n"}) {
		m, err := ini.load_map_from_string(src, context.allocator)
		testing.expect_value(t, err, nil)
		testing.expect_value(t, len(m), 0)
		ini.delete_map(m)
	}
	ini.delete_map(nil)
}

@(test)
test_review_write_counts :: proc(t: ^testing.T) {
	b := strings.builder_make()
	defer strings.builder_destroy(&b)
	w := strings.to_writer(&b)
	total := 0

	n, err := ini.write_section(w, "s", &total)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, n, 4)

	n, err = ini.write_pair(w, "k", "v", &total)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, n, 6)

	n, err = ini.write_pair(w, "q", " v ", &total)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, n, 10)

	n, err = ini.write_pair(w, "i", 42, &total)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, n, 7)

	n, err = ini.write_pair(w, "b", false, &total)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, n, 10)

	want := "[s]\nk = v\nq = \" v \"\ni = 42\nb = false\n"
	testing.expect_value(t, strings.to_string(b), want)
	testing.expect_value(t, total, len(want))
}

@(test)
test_review_save_map :: proc(t: ^testing.T) {
	m: ini.Map
	defer delete_test_map(m)
	put(&m, "LOG", "level", "devel")

	text, err := ini.save_map_to_string(m, context.allocator)
	defer delete(text)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, text, "[LOG]\nlevel = devel\n")

	g: ini.Map
	defer delete_test_map(g)
	put(&g, "", "k", "v")
	gtext, gerr := ini.save_map_to_string(g, context.allocator)
	defer delete(gtext)
	testing.expect_value(t, gerr, nil)
	testing.expect_value(t, gtext, "k = v\n")

	empty_text, empty_err := ini.save_map_to_string(nil, context.allocator)
	testing.expect_value(t, empty_err, nil)
	testing.expect_value(t, empty_text, "")
}

@(test)
test_review_load_map_from_path :: proc(t: ^testing.T) {
	path, ok := write_temp_ini(t, "[LOG]\r\nlevel = \"devel\"\r\n\r\n[USER]\r\nfirst_name = John\r\n")
	if !ok {
		return
	}
	defer os.remove(path)

	options := ini.DEFAULT_OPTIONS
	options.key_lower_case = true
	m, err := ini.load_map_from_path(path, context.allocator, options)
	defer ini.delete_map(m)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, len(m), 2)
	testing.expect_value(t, m["LOG"]["level"], "devel")
	testing.expect_value(t, m["USER"]["first_name"], "John")
}
