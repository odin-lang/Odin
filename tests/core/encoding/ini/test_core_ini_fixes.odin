#+feature dynamic-literals
package test_core_ini

import "base:runtime"
import "core:encoding/ini"
import "core:fmt"
import "core:io"
import "core:mem"
import "core:os"
import "core:strings"
import "core:testing"

@(test)
test_fix_load_allocation_failure :: proc(t: ^testing.T) {
	src := "top = 1\n[a]\nk1 = \"v\\t1\"\nK2 = 'lit'\nk1 = again\nplain = \"x\"\n[empty]\n[b]\nX = y\n"
	all_options := []ini.Options{
		ini.DEFAULT_OPTIONS,
		{comment = ";", key_lower_case = true},
		{comment = ";", keep_empty_sections = true},
	}
	for options in all_options {
		for once in ([]bool{false, true}) {
			loaded := false
			for n in 0..<1000 {
				fa := Failing_Allocator{backing = context.allocator, left = n, once = once}
				m, err := ini.load_map_from_string(src, failing_allocator(&fa), options)
				if err != nil {
					testing.expect_value(t, err, runtime.Allocator_Error.Out_Of_Memory)
					testing.expect(t, m == nil)
					continue
				}
				k2 := "k2" if options.key_lower_case else "K2"
				x  := "x"  if options.key_lower_case else "X"
				testing.expect_value(t, len(m), 4 if options.keep_empty_sections else 3)
				testing.expect_value(t, m[""]["top"], "1")
				testing.expect_value(t, len(m["a"]), 3)
				testing.expect_value(t, m["a"]["k1"], "again")
				testing.expect_value(t, m["a"]["plain"], "x")
				testing.expect_value(t, m["a"][k2], "lit")
				testing.expect_value(t, m["b"][x], "y")
				ini.delete_map(m)
				if !once || fa.left > 0 {
					loaded = true
					break
				}
			}
			testing.expect(t, loaded)
		}
	}
}

@(test)
test_fix_save_allocation_failure :: proc(t: ^testing.T) {
	m: ini.Map
	defer delete_test_map(m)
	put(&m, "", "g", "1")
	put(&m, "s", "k", "v")
	put(&m, "s", "q", " padded")

	want, want_err := ini.save_map_to_string(m, context.allocator)
	defer delete(want)
	testing.expect_value(t, want_err, nil)

	saved := false
	for n in 0..<100 {
		fa := Failing_Allocator{backing = context.allocator, left = n}
		data, err := ini.save_map_to_string(m, failing_allocator(&fa))
		if err != nil {
			testing.expect_value(t, err, ini.Error(runtime.Allocator_Error.Out_Of_Memory))
			testing.expect_value(t, data, "")
			continue
		}
		testing.expect_value(t, data, want)
		delete(data, failing_allocator(&fa))
		saved = true
		break
	}
	testing.expect(t, saved)

	data, err := ini.save_map_to_string(m, runtime.nil_allocator())
	testing.expect_value(t, err, ini.Error(runtime.Allocator_Error.Out_Of_Memory))
	testing.expect_value(t, data, "")
}

@(test)
test_fix_load_map_from_path :: proc(t: ^testing.T) {
	dir, dir_err := os.temp_directory(context.temp_allocator)
	if !testing.expect_value(t, dir_err, nil) {
		return
	}
	missing, join_err := os.join_path({dir, "odin_ini_test_no_such_file.ini"}, context.temp_allocator)
	if !testing.expect_value(t, join_err, nil) {
		return
	}
	m, err := ini.load_map_from_path(missing, context.allocator)
	testing.expect_value(t, err, os.Error(os.General_Error.Not_Exist))
	testing.expect(t, m == nil)

	path, ok := write_temp_ini(t, "[s]\nk = v\nk2 = \"x\"\n")
	if !ok {
		return
	}
	defer os.remove(path)

	loaded := false
	for n in 0..<1000 {
		fa := Failing_Allocator{backing = context.allocator, left = n}
		fm, ferr := ini.load_map_from_path(path, failing_allocator(&fa))
		if ferr != nil {
			testing.expect_value(t, ferr, os.Error(runtime.Allocator_Error.Out_Of_Memory))
			testing.expect(t, fm == nil)
			continue
		}
		testing.expect_value(t, fm["s"]["k"], "v")
		testing.expect_value(t, fm["s"]["k2"], "x")
		ini.delete_map(fm)
		loaded = true
		break
	}
	testing.expect(t, loaded)
}

@(test)
test_fix_delete_map_allocator :: proc(t: ^testing.T) {
	a, b: mem.Tracking_Allocator
	mem.tracking_allocator_init(&a, context.allocator)
	defer mem.tracking_allocator_destroy(&a)
	mem.tracking_allocator_init(&b, context.allocator)
	defer mem.tracking_allocator_destroy(&b)

	m, err := ini.load_map_from_string("[s]\nk = v\n[t]\nx = y\n", mem.tracking_allocator(&a))
	testing.expect_value(t, err, nil)
	{
		context.allocator = mem.tracking_allocator(&b)
		ini.delete_map(m)
	}
	testing.expect_value(t, len(a.allocation_map), 0)
	testing.expect_value(t, len(a.bad_free_array), 0)
	testing.expect_value(t, len(b.allocation_map), 0)
	testing.expect_value(t, len(b.bad_free_array), 0)
}

@(test)
test_fix_duplicate_keys :: proc(t: ^testing.T) {
	src := "k = one\nk = two\nK = three\n"
	m, err := ini.load_map_from_string(src, context.allocator)
	defer ini.delete_map(m)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, len(m[""]), 2)
	testing.expect_value(t, m[""]["k"], "two")
	testing.expect_value(t, m[""]["K"], "three")

	options := ini.DEFAULT_OPTIONS
	options.key_lower_case = true
	lm, lerr := ini.load_map_from_string(src, context.allocator, options)
	defer ini.delete_map(lm)
	testing.expect_value(t, lerr, nil)
	testing.expect_value(t, len(lm[""]), 1)
	testing.expect_value(t, lm[""]["k"], "three")
}

@(test)
test_fix_round_trip :: proc(t: ^testing.T) {
	values := []string{
		`"hi"`, `'hi'`, `"hi`, `'`, `"`, "line1\nline2", "a\r\nb", "cr\rmid", "\n",
		" lead", "trail ", "\ttab", "tab\t", " nbsp", "nbsp ",
		`\`, `\t`, "\"\xff", "\xff\xfe", "", "plain", "a = b", "x;y", "[not a section]", "tab\tinside",
	}
	keys := []string{
		"[draft]", `"quoted"`, `'single'`, " space", "space ", "a =b", `a"b=c`, `a'b=c`, `a"b`, `a'b`,
		"multi\nline", "cr\rkey", "", "ctrl+=", "a=b", "=", "==", "x\\y", " nb", "tab\tkey",
		`"a =b" = c`, "k", "\xff", "[",
	}
	sections := []string{"", "s", "a[b", "x y", "[[x", "s=t", "\"q\"", "'q'", ";not a comment"}

	m: ini.Map
	defer delete_test_map(m)
	for value, i in values {
		put(&m, "values", fmt.tprintf("v%d", i), value)
	}
	for key in keys {
		put(&m, "keys", key, "x")
	}
	for section in sections {
		put(&m, section, "k", section)
	}
	round_trip(t, m)
}

@(test)
test_fix_global_section_first :: proc(t: ^testing.T) {
	m: ini.Map
	defer delete_test_map(m)
	put(&m, "", "g", "1")
	for i in 0..<32 {
		put(&m, fmt.tprintf("s%d", i), "k", "v")
	}
	text, err := ini.save_map_to_string(m, context.allocator)
	defer delete(text)
	testing.expect_value(t, err, nil)
	testing.expect(t, strings.has_prefix(text, "g = 1\n"))
	testing.expect(t, !strings.contains(text, "[]"))
	round_trip(t, m)
}

@(test)
test_fix_invalid_section_names :: proc(t: ^testing.T) {
	names := []string{"a]b", "]", "a\nb", "a\rb", " a", "a ", "\ta", "a "}
	for name in names {
		m: ini.Map
		put(&m, "ok", "k", "v")
		put(&m, name, "k", "v")

		data, err := ini.save_map_to_string(m, context.allocator)
		testing.expect_value(t, err, ini.Error(ini.Write_Error.Invalid_Section_Name))
		testing.expect_value(t, data, "")

		b := strings.builder_make()
		n, werr := ini.write_map(strings.to_writer(&b), m)
		testing.expect_value(t, werr, ini.Error(ini.Write_Error.Invalid_Section_Name))
		testing.expect_value(t, n, 0)
		testing.expect_value(t, strings.to_string(b), "")

		total := 0
		sn, serr := ini.write_section(strings.to_writer(&b), name, &total)
		testing.expect_value(t, serr, ini.Error(ini.Write_Error.Invalid_Section_Name))
		testing.expect_value(t, sn, 0)
		testing.expect_value(t, total, 0)
		testing.expect_value(t, strings.to_string(b), "")

		strings.builder_destroy(&b)
		delete_test_map(m)
	}
}

@(test)
test_fix_key_lower_case_quoted :: proc(t: ^testing.T) {
	options := ini.DEFAULT_OPTIONS
	options.key_lower_case = true
	m, err := ini.load_map_from_string("\"Foo Bar\" = 1\n'MiXeD' = 2\n\"A\\tB\" = 3\n", context.allocator, options)
	defer ini.delete_map(m)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, len(m[""]), 3)
	testing.expect_value(t, m[""]["foo bar"], "1")
	testing.expect_value(t, m[""]["mixed"], "2")
	testing.expect_value(t, m[""]["a\tb"], "3")
}

@(test)
test_fix_quoted_key_split :: proc(t: ^testing.T) {
	src := "\"a =b\" = c\n\"x\\\"=y\" = z\n'p = q' = r\n\"e=\"=f\n\"no close = v\nk='s =t'\n"
	expected := [][2]string{
		{`"a =b"`,     "c"},
		{`"x\"=y"`,    "z"},
		{`'p = q'`,    "r"},
		{`"e="`,       "f"},
		{`"no close`,  "v"},
		{"k",          `'s =t'`},
	}
	it := ini.iterator_from_string(src)
	i := 0
	for key, value in ini.iterate(&it) {
		if i < len(expected) {
			testing.expect_value(t, key,   expected[i][0])
			testing.expect_value(t, value, expected[i][1])
		}
		i += 1
	}
	testing.expect_value(t, i, len(expected))

	m, err := ini.load_map_from_string(src, context.allocator)
	defer ini.delete_map(m)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, m[""]["a =b"], "c")
	testing.expect_value(t, m[""][`x"=y`], "z")
	testing.expect_value(t, m[""]["p = q"], "r")
	testing.expect_value(t, m[""]["e="], "f")
	testing.expect_value(t, m[""][`"no close`], "v")
	testing.expect_value(t, m[""]["k"], "s =t")
}

@(test)
test_fix_section_names_trimmed :: proc(t: ^testing.T) {
	m, err := ini.load_map_from_string("[ LOG ]\nlevel = devel\n[\tUSER\t]\nname = x\n", context.allocator)
	defer ini.delete_map(m)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, len(m), 2)
	testing.expect_value(t, m["LOG"]["level"], "devel")
	testing.expect_value(t, m["USER"]["name"], "x")
}

@(test)
test_fix_write_pair_errors :: proc(t: ^testing.T) {
	check :: proc(t: ^testing.T, full: string, write: proc(w: io.Writer) -> (int, ini.Error), loc := #caller_location) {
		for budget in 0..=len(full) {
			bw := Budget_Writer{left = budget, fail_call = -1}
			n, err := write(budget_writer(&bw))
			testing.expect_value(t, n, budget, loc)
			if budget < len(full) {
				testing.expect_value(t, err, ini.Error(io.Error.Short_Write), loc)
			} else {
				testing.expect_value(t, err, nil, loc)
			}
			testing.expect_value(t, string(bw.buf[:bw.len]), full[:budget], loc)
		}

		counter := Budget_Writer{left = len(full), fail_call = -1}
		_, _ = write(budget_writer(&counter))
		for call in 0..<counter.calls {
			bw := Budget_Writer{left = len(full), fail_call = call}
			n, err := write(budget_writer(&bw))
			testing.expect_value(t, err, ini.Error(io.Error.Short_Write), loc)
			testing.expect_value(t, n, bw.len, loc)
			testing.expect_value(t, string(bw.buf[:bw.len]), full[:min(bw.len, len(full))], loc)
		}
	}
	check(t, "k = 12345\n", proc(w: io.Writer) -> (int, ini.Error) { return ini.write_pair(w, "k", 12345) })
	check(t, "k = true\n",  proc(w: io.Writer) -> (int, ini.Error) { return ini.write_pair(w, "k", true) })
	check(t, "k = 1.5\n",   proc(w: io.Writer) -> (int, ini.Error) { return ini.write_pair(w, "k", 1.5) })
	check(t, "\"a =b\" = \" v \"\n", proc(w: io.Writer) -> (int, ini.Error) { return ini.write_pair(w, "a =b", " v ") })
}

@(test)
test_fix_empty_sections :: proc(t: ^testing.T) {
	src := "[empty]\n[s]\nk = v\n[also empty]\n"
	m, err := ini.load_map_from_string(src, context.allocator)
	defer ini.delete_map(m)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, len(m), 1)
	testing.expect_value(t, m["s"]["k"], "v")

	options := ini.DEFAULT_OPTIONS
	options.keep_empty_sections = true
	km, kerr := ini.load_map_from_string(src, context.allocator, options)
	defer ini.delete_map(km)
	testing.expect_value(t, kerr, nil)
	testing.expect_value(t, len(km), 3)
	empty, has_empty := km["empty"]
	testing.expect(t, has_empty)
	testing.expect_value(t, len(empty), 0)
	also, has_also := km["also empty"]
	testing.expect(t, has_also)
	testing.expect_value(t, len(also), 0)

	rm: ini.Map
	defer delete_test_map(rm)
	rm["empty"] = {}
	rm[""] = {}
	put(&rm, "s", "k", "v")
	round_trip(t, rm, options)
}

@(test)
test_fix_key_lower_case_arena :: proc(t: ^testing.T) {
	buf: [4096]byte
	arena: mem.Arena
	mem.arena_init(&arena, buf[:])
	options := ini.DEFAULT_OPTIONS
	options.key_lower_case = true
	m, err := ini.load_map_from_string("[s]\nKey = v\n", mem.arena_allocator(&arena), options)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, m["s"]["key"], "v")
}

Failing_Allocator :: struct {
	backing: runtime.Allocator,
	left:    int,
	once:    bool,
}

failing_allocator :: proc(fa: ^Failing_Allocator) -> runtime.Allocator {
	return {procedure = failing_allocator_proc, data = fa}
}

failing_allocator_proc :: proc(data: rawptr, mode: runtime.Allocator_Mode, size, alignment: int, old_memory: rawptr, old_size: int, loc := #caller_location) -> ([]byte, runtime.Allocator_Error) {
	fa := (^Failing_Allocator)(data)
	#partial switch mode {
	case .Alloc, .Alloc_Non_Zeroed, .Resize, .Resize_Non_Zeroed:
		if fa.left == 0 {
			if fa.once {
				fa.left = -1
			}
			return nil, .Out_Of_Memory
		}
		if fa.left > 0 {
			fa.left -= 1
		}
	}
	return fa.backing.procedure(fa.backing.data, mode, size, alignment, old_memory, old_size, loc)
}

Budget_Writer :: struct {
	buf:       [64]byte,
	len:       int,
	left:      int,
	calls:     int,
	fail_call: int,
}

budget_writer :: proc(bw: ^Budget_Writer) -> io.Writer {
	return {procedure = budget_writer_proc, data = bw}
}

budget_writer_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	bw := (^Budget_Writer)(stream_data)
	#partial switch mode {
	case .Write:
		bw.calls += 1
		if bw.calls - 1 == bw.fail_call {
			return 0, .Short_Write
		}
		count := min(len(p), bw.left, len(bw.buf) - bw.len)
		copy(bw.buf[bw.len:], p[:count])
		bw.len  += count
		bw.left -= count
		if count < len(p) {
			err = .Short_Write
		}
		return i64(count), err
	case .Query:
		return io.query_utility({.Write, .Query})
	}
	return 0, .Unsupported
}

put :: proc(m: ^ini.Map, section, key, value: string) {
	if section not_in m^ {
		m[section] = {}
	}
	pairs := &m[section]
	pairs[key] = value
}

delete_test_map :: proc(m: ini.Map) {
	for _, pairs in m {
		delete(pairs)
	}
	delete(m)
}

round_trip :: proc(t: ^testing.T, m: ini.Map, options := ini.DEFAULT_OPTIONS, loc := #caller_location) {
	text, err := ini.save_map_to_string(m, context.allocator)
	defer delete(text)
	if !testing.expect_value(t, err, nil, loc) {
		return
	}
	back, load_err := ini.load_map_from_string(text, context.allocator, options)
	defer ini.delete_map(back)
	testing.expect_value(t, load_err, nil, loc)
	expect_maps_equal(t, back, m, text, loc)
}

expect_maps_equal :: proc(t: ^testing.T, got, want: ini.Map, text: string, loc := #caller_location) {
	testing.expectf(t, len(got) == len(want), "%d sections, want %d, from %q", len(got), len(want), text, loc = loc)
	for section, pairs in want {
		got_pairs, has := got[section]
		if !testing.expectf(t, has, "section %q missing, from %q", section, text, loc = loc) {
			continue
		}
		testing.expectf(t, len(got_pairs) == len(pairs), "section %q has %d pairs, want %d", section, len(got_pairs), len(pairs), loc = loc)
		for key, value in pairs {
			got_value, has_key := got_pairs[key]
			testing.expectf(t, has_key && got_value == value, "[%q] %q: got %q (present %v), want %q", section, key, got_value, has_key, value, loc = loc)
		}
	}
}

write_temp_ini :: proc(t: ^testing.T, data: string) -> (path: string, ok: bool) {
	f, err := os.create_temp_file("", "odin_ini_test_*.ini")
	if !testing.expect_value(t, err, nil) {
		return
	}
	path = strings.clone(os.name(f), context.temp_allocator)
	_, werr := os.write_string(f, data)
	testing.expect_value(t, werr, nil)
	testing.expect_value(t, os.close(f), nil)
	return path, werr == nil
}
