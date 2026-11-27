package test_core_archive_sevenz

import "core:archive"
import "core:archive/sevenz"
import "core:bytes"
import "core:compress"
import "core:encoding/endian"
import "core:fmt"
import "core:hash"
import "core:io"
import "core:os"
import "core:slice"
import "core:strings"
import "core:testing"

TORN_SECTOR :: 512

Update_Entry :: struct {
	name:      string,
	content:   []u8,
	method:    archive.Method,
	filter:    sevenz.Filter_Choice,
	delta:     int,
	directory: bool,
	link:      string,
	password:  Maybe(string),
	encrypted: bool,
	filters:   archive.Filters,
}

Update_Paths :: struct {
	path:    string,
	journal: string,
	temp:    string,
}

Torn_Op :: struct {
	offset: i64,
	start:  int,
	length: int,
	flush:  bool,
}

Torn_Writer :: struct {
	initial:  []u8,
	data:     [dynamic]u8,
	log:      [dynamic]u8,
	ops:      [dynamic]Torn_Op,
	position: i64,
}

@(test)
test_update_append :: proc(t: ^testing.T) {
	root, root_ok := update_root(t, "odin_7z_update_append_*")
	if !root_ok {
		return
	}
	defer os.remove_all(root)
	text   := write_text()
	random := write_random(30_000, 21)
	defer delete(random)

	before := []Update_Entry{
		{name = "a.txt", content = text, method = .LZMA2},
		{name = "b.bin", content = random, method = .Store},
		{name = "d",     directory = true},
		{name = "empty"},
	}
	added := []Update_Entry{
		{name = "c.txt",   content = text, method = .PPMd_H},
		{name = "d/l",     link = "../a.txt"},
		{name = "d/e.bin", content = random, method = .LZMA},
	}
	old := make_7z(t, before)
	start := data_start_of(old)
	p := update_paths(root, "append.7z")

	for use_stream in ([?]bool{false, true}) {
		label := "append/stream" if use_stream else "append/path"
		data: []u8
		sw: sevenz.Writer
		tw: Torn_Writer
		if use_stream {
			torn_init(&tw, old)
			if testing.expect_value(t, sevenz.update(&sw, torn_stream(&tw)), nil) {
				write_updates(t, &sw, added)
				testing.expect_value(t, sevenz.write_anti_item(&sw, "gone.txt"), nil)
				testing.expect_value(t, sevenz.write_anti_item(&sw, "gone", true), nil)
				testing.expect_value(t, sevenz.commit(&sw), nil)
				sevenz.close(&sw)
			}
			data = tw.data[:]
		} else {
			testing.expect_value(t, os.write_entire_file(p.path, old), nil)
			if testing.expect_value(t, sevenz.update(&sw, p.path), nil) {
				write_updates(t, &sw, added)
				testing.expect_value(t, sevenz.write_anti_item(&sw, "gone.txt"), nil)
				testing.expect_value(t, sevenz.write_anti_item(&sw, "gone", true), nil)
				testing.expect_value(t, sevenz.commit(&sw), nil)
				sevenz.close(&sw)
			}
			testing.expectf(t, !os.exists(p.journal) && !os.exists(p.temp), "%s: no journal or temp after the commit", label)
			data, _ = os.read_entire_file(p.path, context.temp_allocator)
		}
		want := update_expect(before, added)
		append_anti(&want, "gone.txt", "gone")
		check_written(t, label, data, want[:])
		testing.expectf(t, len(data) > start && bytes.equal(data[32:start], old[32:start]), "%s: the old packed streams stay in place", label)
		testing.expectf(t, count_folders(data) == count_folders(old) + 3, "%s: %d folders", label, count_folders(data))
	}

	for use_stream in ([?]bool{false, true}) {
		data: []u8
		sw: sevenz.Writer
		tw: Torn_Writer
		if use_stream {
			torn_init(&tw, old)
			if testing.expect_value(t, sevenz.update(&sw, torn_stream(&tw)), nil) {
				testing.expect_value(t, sevenz.commit(&sw), nil)
				sevenz.close(&sw)
			}
			data = tw.data[:]
			testing.expect_value(t, torn_writes(&tw), 0)
		} else {
			testing.expect_value(t, os.write_entire_file(p.path, old), nil)
			if testing.expect_value(t, sevenz.update(&sw, p.path), nil) {
				testing.expect_value(t, sevenz.commit(&sw), nil)
				sevenz.close(&sw)
			}
			data, _ = os.read_entire_file(p.path, context.temp_allocator)
		}
		testing.expectf(t, bytes.equal(data, old), "unchanged update (stream %v) leaves the archive alone", use_stream)
	}

	empty := make_7z(t, nil)
	more  := make_7z(t, {{name = "d", directory = true}})
	for base, i in ([?][]u8{empty, more}) {
		testing.expect_value(t, os.write_entire_file(p.path, base), nil)
		sw: sevenz.Writer
		if testing.expect_value(t, sevenz.update(&sw, p.path), nil) {
			write_updates(t, &sw, added[:1])
			testing.expect_value(t, sevenz.commit(&sw), nil)
			sevenz.close(&sw)
		}
		data, _ := os.read_entire_file(p.path, context.temp_allocator)
		if i == 0 {
			check_written(t, "append/empty", data, update_expect(added[:1]))
		} else {
			check_written(t, "append/no streams", data, update_expect({{name = "d", directory = true}}, added[:1]))
		}
	}

	testing.expect_value(t, os.write_entire_file(p.path, old), nil)
	for round in 0..<3 {
		sw: sevenz.Writer
		if testing.expect_value(t, sevenz.update(&sw, p.path, {solid = true}), nil) {
			testing.expect_value(t, sevenz.write_entry(&sw, fmt.tprintf("round%d.txt", round), text), nil)
			testing.expect_value(t, sevenz.write_entry(&sw, fmt.tprintf("round%d.bin", round), random), nil)
			testing.expect_value(t, sevenz.commit(&sw), nil)
			sevenz.close(&sw)
		}
	}
	data, _ := os.read_entire_file(p.path, context.temp_allocator)
	want := make([dynamic]Write_Expect, context.temp_allocator)
	append(&want, ..update_expect(before))
	for round in 0..<3 {
		append(&want, Write_Expect{name = fmt.tprintf("round%d.txt", round), type = .Regular, content = text})
		append(&want, Write_Expect{name = fmt.tprintf("round%d.bin", round), type = .Regular, content = random})
	}
	check_written(t, "append/rounds", data, want[:])
	testing.expectf(t, count_folders(data) == count_folders(old) + 3, "append/rounds: %d folders", count_folders(data))
}

@(test)
test_update_modify :: proc(t: ^testing.T) {
	root, root_ok := update_root(t, "odin_7z_update_modify_*")
	if !root_ok {
		return
	}
	defer os.remove_all(root)
	text   := write_text()
	random := write_random(30_000, 22)
	defer delete(random)

	before := []Update_Entry{
		{name = "a.txt",   content = text,   method = .LZMA2},
		{name = "b.bin",   content = random, method = .Store},
		{name = "c.txt",   content = text,   method = .PPMd_H},
		{name = "d",       directory = true},
		{name = "d/l",     link = "../a.txt"},
		{name = "e.empty"},
	}
	old := make_7z(t, before)
	p := update_paths(root, "modify.7z")

	sw: sevenz.Writer
	testing.expect_value(t, os.write_entire_file(p.path, old), nil)
	if testing.expect_value(t, sevenz.update(&sw, p.path), nil) {
		testing.expect_value(t, sevenz.remove_entry(&sw, "a.txt"), nil)
		testing.expect_value(t, sevenz.remove_entry(&sw, "e.empty"), nil)
		testing.expect_value(t, sevenz.commit(&sw), nil)
		sevenz.close(&sw)
	}
	data, _ := os.read_entire_file(p.path, context.temp_allocator)
	check_written(t, "modify/remove", data, update_expect(before[1:5]))
	testing.expectf(t, count_folders(data) == count_folders(old) - 1, "modify/remove: %d folders", count_folders(data))
	testing.expect(t, !os.exists(p.journal) && !os.exists(p.temp), "modify/remove: no journal or temp after the commit")

	testing.expect_value(t, os.write_entire_file(p.path, old), nil)
	if testing.expect_value(t, sevenz.update(&sw, p.path), nil) {
		testing.expect_value(t, sevenz.rename_entry(&sw, "c.txt", "d/c2.txt"), nil)
		testing.expect_value(t, sevenz.rename_entry(&sw, "/d/l", "d/link"), archive.General_Error.Not_Found)
		testing.expect_value(t, sevenz.rename_entry(&sw, "d/l/", "d/link"), nil)
		testing.expect_value(t, sevenz.rename_entry(&sw, "b.bin", "b.bin"), nil)
		testing.expect_value(t, sevenz.write_entry(&sw, "c.txt", random), nil)
		testing.expect_value(t, sevenz.commit(&sw), nil)
		sevenz.close(&sw)
	}
	data, _ = os.read_entire_file(p.path, context.temp_allocator)
	renamed := slice.clone(before, context.temp_allocator)
	renamed[2].name = "d/c2.txt"
	renamed[4].name = "d/link"
	want := update_expect(renamed, {{name = "c.txt", content = random}})
	check_written(t, "modify/rename", data, want)
	testing.expect(t, bytes.equal(data[32:data_start_of(old)], old[32:data_start_of(old)]), "modify/rename: folders copied unchanged")

	testing.expect_value(t, os.write_entire_file(p.path, old), nil)
	if testing.expect_value(t, sevenz.update(&sw, p.path), nil) {
		testing.expect_value(t, sevenz.remove_entry(&sw, "b.bin"), nil)
		testing.expect_value(t, sevenz.write_entry(&sw, "b.bin", text, {method = .BZip2}), nil)
		testing.expect_value(t, sevenz.commit(&sw), nil)
		sevenz.close(&sw)
	}
	data, _ = os.read_entire_file(p.path, context.temp_allocator)
	replaced := make([dynamic]Update_Entry, context.temp_allocator)
	append(&replaced, before[0])
	append(&replaced, ..before[2:])
	append(&replaced, Update_Entry{name = "b.bin", content = text, method = .BZip2})
	check_written(t, "modify/replace", data, update_expect(replaced[:]))

	testing.expect_value(t, os.write_entire_file(p.path, old), nil)
	if testing.expect_value(t, sevenz.update(&sw, p.path), nil) {
		for e in before {
			testing.expect_value(t, sevenz.remove_entry(&sw, e.name), nil)
		}
		testing.expect_value(t, sevenz.commit(&sw), nil)
		sevenz.close(&sw)
	}
	data, _ = os.read_entire_file(p.path, context.temp_allocator)
	check_written(t, "modify/remove all", data, nil)
	testing.expect_value(t, len(data), 32)

	dupes := make_7z(t, {{name = "x.txt", content = text}, {name = "x.txt", content = random}, {name = "y.txt", content = text}})
	testing.expect_value(t, os.write_entire_file(p.path, dupes), nil)
	if testing.expect_value(t, sevenz.update(&sw, p.path), nil) {
		testing.expect_value(t, sevenz.write_entry(&sw, "x.txt", text), archive.General_Error.Exists)
		testing.expect_value(t, sevenz.remove_entry(&sw, "x.txt"), nil)
		testing.expect_value(t, sevenz.remove_entry(&sw, "x.txt"), archive.General_Error.Not_Found)
		testing.expect_value(t, sevenz.write_entry(&sw, "x.txt", random), nil)
		testing.expect_value(t, sevenz.commit(&sw), nil)
		sevenz.close(&sw)
	}
	data, _ = os.read_entire_file(p.path, context.temp_allocator)
	check_written(t, "modify/duplicates", data, update_expect({{name = "y.txt", content = text}, {name = "x.txt", content = random}}))
}

@(test)
test_update_replace :: proc(t: ^testing.T) {
	root, root_ok := update_root(t, "odin_7z_update_replace_*")
	if !root_ok {
		return
	}
	defer os.remove_all(root)
	text   := write_text()
	random := write_random(30_000, 23)
	defer delete(random)
	fresh := write_random(9_000, 24)
	defer delete(fresh)

	before := []Update_Entry{
		{name = "a.txt",   content = text,   method = .LZMA2},
		{name = "b.bin",   content = random, method = .Store},
		{name = "c.txt",   content = text,   method = .PPMd_H},
		{name = "d",       directory = true},
		{name = "d/e.txt", content = text},
		{name = "a.txt",   content = random},
	}
	old := make_7z(t, before)
	p := update_paths(root, "replace.7z")
	replace := sevenz.Entry_Options{replace = true}

	sw: sevenz.Writer
	testing.expect_value(t, os.write_entire_file(p.path, old), nil)
	if testing.expect_value(t, sevenz.update(&sw, p.path), nil) {
		testing.expect_value(t, sevenz.write_entry(&sw, "b.bin", fresh), archive.General_Error.Exists)
		testing.expect_value(t, sevenz.write_entry(&sw, "b.bin", fresh, replace), nil)
		testing.expect_value(t, sevenz.write_entry(&sw, "b.bin", text, replace), archive.General_Error.Exists)
		testing.expect_value(t, sevenz.write_entry(&sw, "./a.txt", fresh, replace), nil)
		testing.expect_value(t, sevenz.write_entry(&sw, "new.txt", text, replace), nil)
		testing.expect_value(t, sevenz.write_entry(&sw, "new.txt", text, replace), archive.General_Error.Exists)
		testing.expect_value(t, sevenz.write_entry(&sw, archive.File_Info{path = "d/", type = .Directory}, nil, replace), nil)
		testing.expect_value(t, sevenz.write_anti_item(&sw, "c.txt"), archive.General_Error.Exists)
		testing.expect_value(t, sevenz.write_entry(&sw, archive.File_Info{path = "c.txt", type = .Named_Pipe}, nil, replace), archive.General_Error.Unsupported_Entry)
		testing.expect_value(t, sevenz.commit(&sw), nil)
		sevenz.close(&sw)
	}
	testing.expect(t, !os.exists(p.journal) && !os.exists(p.temp), "replace: no journal or temp after the commit")
	data, _ := os.read_entire_file(p.path, context.temp_allocator)
	check_written(t, "replace", data, update_expect(
		{before[2], before[4]},
		{{name = "b.bin", content = fresh}, {name = "a.txt", content = fresh}, {name = "new.txt", content = text}, {name = "d", directory = true}},
	))

	packed := []Update_Entry{{name = "x.txt", content = text}, {name = "y.txt", content = text}, {name = "z.txt", content = text}}
	solid := make_7z(t, packed, sevenz.Writer_Options{solid = true})
	testing.expect_value(t, count_folders(solid), 1)
	testing.expect_value(t, os.write_entire_file(p.path, solid), nil)
	if testing.expect_value(t, sevenz.update(&sw, p.path), nil) {
		testing.expect_value(t, sevenz.write_entry(&sw, "y.txt", fresh, replace), nil)
		testing.expect_value(t, sevenz.commit(&sw), nil)
		sevenz.close(&sw)
	}
	data, _ = os.read_entire_file(p.path, context.temp_allocator)
	check_written(t, "replace/solid", data, update_expect({{name = "y.txt", content = fresh}}, {packed[0], packed[2]}))

	tree, _  := os.join_path({root, "tree"}, context.temp_allocator)
	inner, _ := os.join_path({tree, "e.txt"}, context.temp_allocator)
	added, _ := os.join_path({tree, "n.txt"}, context.temp_allocator)
	testing.expect_value(t, os.make_directory(tree), nil)
	testing.expect_value(t, os.write_entire_file(inner, fresh), nil)
	testing.expect_value(t, os.write_entire_file(added, text), nil)
	testing.expect_value(t, os.write_entire_file(p.path, old), nil)
	if testing.expect_value(t, sevenz.update(&sw, p.path, {deterministic = true}), nil) {
		testing.expect_value(t, sevenz.write_directory(&sw, tree, "d"), archive.General_Error.Exists)
		testing.expect_value(t, sevenz.write_directory(&sw, tree, "d", replace), nil)
		testing.expect_value(t, sevenz.commit(&sw), nil)
		sevenz.close(&sw)
	}
	data, _ = os.read_entire_file(p.path, context.temp_allocator)
	check_written(t, "replace/directory", data, update_expect(
		{before[0], before[1], before[2], before[5]},
		{{name = "d", directory = true}, {name = "d/e.txt", content = fresh}, {name = "d/n.txt", content = text}},
	))

	testing.expect_value(t, os.write_entire_file(p.path, old), nil)
	if testing.expect_value(t, sevenz.update(&sw, p.path), nil) {
		short: bytes.Reader
		bytes.reader_init(&short, text[:5])
		testing.expect_value(t, sevenz.write_entry(&sw, archive.File_Info{path = "c.txt", type = .Regular, size = 10}, bytes.reader_to_stream(&short), replace), sevenz.SevenZ_Error.Size_Mismatch)
		sevenz.commit(&sw)
		sevenz.close(&sw)
	}
	check_path(t, "replace/failed", p.path, update_expect(before))

	tw: Torn_Writer
	torn_init(&tw, old)
	if testing.expect_value(t, sevenz.update(&sw, torn_stream(&tw)), nil) {
		testing.expect_value(t, sevenz.write_entry(&sw, "b.bin", fresh, replace), archive.General_Error.Incompatible_Options)
		sevenz.close(&sw)
	}
	testing.expect(t, bytes.equal(tw.data[:], old), "replace: a replacement refused on a stream writes nothing")

	twice := []Update_Entry{{name = "a.txt", content = text}, {name = "a.txt", content = fresh}}
	m := Memory_File{seekable = true}
	defer delete(m.data)
	if testing.expect_value(t, sevenz.create(&sw, memory_stream(&m)), nil) {
		for e in twice {
			testing.expect_value(t, sevenz.write_entry(&sw, e.name, e.content, replace), nil)
		}
		testing.expect_value(t, sevenz.commit(&sw), nil)
		sevenz.close(&sw)
	}
	check_written(t, "replace/create", m.data[:], update_expect(twice))
}

@(test)
test_update_repack :: proc(t: ^testing.T) {
	root, root_ok := update_root(t, "odin_7z_update_repack_*")
	if !root_ok {
		return
	}
	defer os.remove_all(root)
	text   := write_text()
	random := write_random(50_000, 23)
	defer delete(random)
	pe := make_pe(0x8664, 16384)
	defer delete(pe)
	p := update_paths(root, "repack.7z")

	for method in WRITE_METHODS {
		before := []Update_Entry{
			{name = "a.txt", content = text,   method = method},
			{name = "b.bin", content = random, method = method},
			{name = "c.txt", content = text,   method = method},
			{name = "d",     directory = true},
		}
		check_repack(t, fmt.tprintf("repack/%v", method), p, before, {solid = true}, {"b.bin"}, "")
	}

	filter_cases := [?]struct {
		filter:  sevenz.Filter_Choice,
		delta:   int,
		data:    []u8,
		filters: archive.Filters,
	}{
		{.Delta,   4, random, {.Delta}},
		{.BCJ_X86, 0, pe,     {.BCJ_X86}},
		{.BCJ2,    0, pe,     {.BCJ2}},
		{.Swap4,   0, random, {.Swap4}},
	}
	for c in filter_cases {
		before := []Update_Entry{
			{name = "a.bin", content = c.data, method = .LZMA, filter = c.filter, delta = c.delta, filters = c.filters},
			{name = "b.bin", content = c.data, method = .LZMA, filter = c.filter, delta = c.delta, filters = c.filters},
			{name = "c.bin", content = c.data, method = .LZMA, filter = c.filter, delta = c.delta, filters = c.filters},
		}
		check_repack(t, fmt.tprintf("repack/%v", c.filter), p, before, {solid = true}, {"a.bin"}, "")
	}

	mixed := []Update_Entry{
		{name = "s1.txt", content = text,   encrypted = true},
		{name = "s2.bin", content = random, encrypted = true},
		{name = "p1.txt", content = text,   password = ""},
		{name = "p2.bin", content = random, password = ""},
	}
	check_repack(t, "repack/encrypted", p, mixed, {solid = true, password = WRITE_PASSWORD}, {"s1.txt", "p1.txt"}, WRITE_PASSWORD)

	locked := make_7z(t, mixed[:2], {solid = true, password = WRITE_PASSWORD, unencrypted_header = true})
	testing.expect_value(t, os.write_entire_file(p.path, locked), nil)
	sw: sevenz.Writer
	if testing.expect_value(t, sevenz.update(&sw, p.path), nil) {
		testing.expect_value(t, sevenz.remove_entry(&sw, "s1.txt"), nil)
		commit_err := sevenz.commit(&sw)
		testing.expectf(t, commit_err == archive.General_Error.Encrypted, "repack without the password: %v", commit_err)
		sevenz.close(&sw)
	}
	data, _ := os.read_entire_file(p.path, context.temp_allocator)
	testing.expect(t, bytes.equal(data, locked), "a failed repack leaves the archive alone")
	testing.expect(t, !os.exists(p.journal) && !os.exists(p.temp), "a failed repack leaves no journal or temp")

	testing.expect_value(t, os.write_entire_file(p.path, locked), nil)
	if testing.expect_value(t, sevenz.update(&sw, p.path, {password = OTHER_PASSWORD}), nil) {
		testing.expect_value(t, sevenz.remove_entry(&sw, "s1.txt"), nil)
		commit_err := sevenz.commit(&sw)
		testing.expectf(t, commit_err != nil, "repack with the wrong password: %v", commit_err)
		sevenz.close(&sw)
	}
	data, _ = os.read_entire_file(p.path, context.temp_allocator)
	testing.expect(t, bytes.equal(data, locked), "a repack with the wrong password leaves the archive alone")
}

@(test)
test_update_abort :: proc(t: ^testing.T) {
	root, root_ok := update_root(t, "odin_7z_update_abort_*")
	if !root_ok {
		return
	}
	defer os.remove_all(root)
	text   := write_text()
	random := write_random(20_000, 24)
	defer delete(random)

	before := []Update_Entry{
		{name = "a.txt", content = text},
		{name = "b.bin", content = random},
	}
	old := make_7z(t, before)
	p := update_paths(root, "abort.7z")
	record := journal_expect(old, data_start_of(old))

	for session in 0..<3 {
		testing.expect_value(t, os.write_entire_file(p.path, old), nil)
		sw: sevenz.Writer
		if testing.expect_value(t, sevenz.update(&sw, p.path), nil) {
			testing.expect(t, !os.exists(p.journal), "no journal before the first write")
			if session != 1 {
				testing.expect_value(t, sevenz.write_entry(&sw, "new.bin", random), nil)
				journal, journal_err := os.read_entire_file(p.journal, context.temp_allocator)
				testing.expectf(t, journal_err == nil && bytes.equal(journal, record), "session %d: journal %v, %d bytes, want %d", session, journal_err, len(journal), len(record))
			}
			if session != 0 {
				testing.expect_value(t, sevenz.remove_entry(&sw, "a.txt"), nil)
			}
			sevenz.close(&sw)
		}
		data, _ := os.read_entire_file(p.path, context.temp_allocator)
		testing.expectf(t, bytes.equal(data, old), "session %d: an uncommitted update leaves the archive alone", session)
		testing.expectf(t, !os.exists(p.journal) && !os.exists(p.temp), "session %d: no journal or temp after the abort", session)
	}

	big := write_random(100_000, 25)
	defer delete(big)
	tw: Torn_Writer
	torn_init(&tw, old)
	sw: sevenz.Writer
	if testing.expect_value(t, sevenz.update(&sw, torn_stream(&tw)), nil) {
		testing.expect_value(t, sevenz.write_entry(&sw, "new.bin", big, {method = .Store}), nil)
		sevenz.close(&sw)
	}
	testing.expect(t, len(tw.data) > len(old) + len(big) / 2, "the aborted entry was written")
	testing.expect(t, bytes.equal(tw.data[:len(old)], old), "an aborted stream update restores the old bytes")
	check_written(t, "abort/stream", tw.data[:], update_expect(before))
}

@(test)
test_no_sync :: proc(t: ^testing.T) {
	text := write_text()
	for no_sync in ([?]bool{false, true}) {
		tw: Torn_Writer
		torn_init(&tw, nil)
		sw: sevenz.Writer
		if !testing.expect_value(t, sevenz.create(&sw, torn_stream(&tw), {no_sync = no_sync}), nil) {
			continue
		}
		testing.expect_value(t, sevenz.write_entry(&sw, "a.txt", text), nil)
		testing.expect_value(t, sevenz.commit(&sw), nil)
		sevenz.close(&sw)
		created := len(tw.ops) - torn_writes(&tw)
		testing.expectf(t, (created == 0) == no_sync, "create, no_sync %v: %d flushes", no_sync, created)

		if testing.expect_value(t, sevenz.update(&sw, torn_stream(&tw), {no_sync = no_sync}), nil) {
			testing.expect_value(t, sevenz.write_entry(&sw, "b.txt", text), nil)
			testing.expect_value(t, sevenz.commit(&sw), nil)
			sevenz.close(&sw)
		}
		updated := len(tw.ops) - torn_writes(&tw) - created
		testing.expectf(t, updated > 0, "update, no_sync %v: %d flushes", no_sync, updated)

		r: sevenz.Reader
		if testing.expect_value(t, sevenz.open(&r, tw.data[:]), nil) {
			_, _, a, _ := sevenz.find(&r, "a.txt")
			_, _, b, _ := sevenz.find(&r, "b.txt")
			testing.expectf(t, a && b, "no_sync %v: a.txt %v, b.txt %v", no_sync, a, b)
			sevenz.close(&r)
		}
	}
}

@(test)
test_update_errors :: proc(t: ^testing.T) {
	root, root_ok := update_root(t, "odin_7z_update_errors_*")
	if !root_ok {
		return
	}
	defer os.remove_all(root)
	text := write_text()
	old := make_7z(t, {{name = "a.txt", content = text}, {name = "b.txt", content = text}})
	p := update_paths(root, "errors.7z")

	sw: sevenz.Writer
	missing_err := sevenz.update(&sw, p.path)
	testing.expectf(t, is_not_exist(missing_err), "update of a missing archive: %v", missing_err)

	testing.expect_value(t, os.write_entire_file(p.path, text), nil)
	bad_err := sevenz.update(&sw, p.path)
	testing.expectf(t, bad_err != nil, "update of a non-archive: %v", bad_err)
	data, _ := os.read_entire_file(p.path, context.temp_allocator)
	testing.expect(t, bytes.equal(data, text), "a failed update leaves the file alone")

	m := Memory_File{seekable = false}
	testing.expect_value(t, sevenz.update(&sw, memory_stream(&m)), archive.General_Error.Not_Seekable)
	delete(m.data)

	tw: Torn_Writer
	torn_init(&tw, old)
	if testing.expect_value(t, sevenz.update(&sw, torn_stream(&tw)), nil) {
		testing.expect_value(t, sevenz.remove_entry(&sw, "a.txt"), archive.General_Error.Incompatible_Options)
		testing.expect_value(t, sevenz.rename_entry(&sw, "a.txt", "c.txt"), archive.General_Error.Incompatible_Options)
		testing.expect_value(t, sevenz.write_entry(&sw, "a.txt", text), archive.General_Error.Exists)
		testing.expect_value(t, sevenz.write_anti_item(&sw, "/b.txt"), archive.General_Error.Exists)
		sevenz.close(&sw)
	}

	testing.expect_value(t, os.write_entire_file(p.path, old), nil)
	if testing.expect_value(t, sevenz.update(&sw, p.path), nil) {
		testing.expect_value(t, sevenz.remove_entry(&sw, "c.txt"), archive.General_Error.Not_Found)
		testing.expect_value(t, sevenz.rename_entry(&sw, "c.txt", "d.txt"), archive.General_Error.Not_Found)
		testing.expect_value(t, sevenz.rename_entry(&sw, "a.txt", "b.txt"), archive.General_Error.Exists)
		testing.expect_value(t, sevenz.write_entry(&sw, "new.txt", text), nil)
		testing.expect_value(t, sevenz.write_entry(&sw, "new.txt", text), archive.General_Error.Exists)
		testing.expect_value(t, sevenz.remove_entry(&sw, "new.txt"), archive.General_Error.Incompatible_Options)
		testing.expect_value(t, sevenz.rename_entry(&sw, "new.txt", "other.txt"), archive.General_Error.Incompatible_Options)
		testing.expect_value(t, sevenz.rename_entry(&sw, "a.txt", "new.txt"), archive.General_Error.Exists)
		testing.expect_value(t, sevenz.remove_entry(&sw, "a.txt"), nil)
		testing.expect_value(t, sevenz.write_entry(&sw, "a.txt", text), nil)
		testing.expect_value(t, sevenz.rename_entry(&sw, "b.txt", "c.txt"), nil)
		testing.expect_value(t, sevenz.write_entry(&sw, "b.txt", text), nil)
		testing.expect_value(t, sevenz.write_entry(&sw, "c.txt", text), archive.General_Error.Exists)
		testing.expect_value(t, sevenz.commit(&sw), nil)
		sevenz.close(&sw)
	}
	data, _ = os.read_entire_file(p.path, context.temp_allocator)
	check_written(t, "errors/session", data, update_expect({{name = "c.txt", content = text}, {name = "new.txt", content = text}, {name = "a.txt", content = text}, {name = "b.txt", content = text}}))
}

@(test)
test_update_locks :: proc(t: ^testing.T) {
	root, root_ok := update_root(t, "odin_7z_update_locks_*")
	if !root_ok {
		return
	}
	defer os.remove_all(root)
	old := make_7z(t, {{name = "a.txt", content = write_text()}})
	p := update_paths(root, "locks.7z")
	testing.expect_value(t, os.write_entire_file(p.path, old), nil)

	r1, r2: sevenz.Reader
	sw, sw2: sevenz.Writer
	if testing.expect_value(t, sevenz.open(&r1, p.path), nil) {
		testing.expect_value(t, sevenz.open(&r2, p.path), nil)
		sevenz.close(&r2)
		testing.expect_value(t, sevenz.update(&sw, p.path), archive.General_Error.Busy)
		testing.expect_value(t, sevenz.create(&sw, p.path), archive.General_Error.Busy)
		sevenz.close(&r1)
	}
	generic, generic_err := archive.open(p.path)
	if testing.expect_value(t, generic_err, nil) {
		testing.expect_value(t, sevenz.update(&sw, p.path), archive.General_Error.Busy)
		archive.close(&generic)
	}
	if testing.expect_value(t, sevenz.update(&sw, p.path), nil) {
		_, held_err := archive.open(p.path)
		testing.expectf(t, held_err != nil, "a generic open while a writer holds the archive: %v", held_err)
		testing.expect_value(t, sevenz.open(&r1, p.path), archive.General_Error.Busy)
		testing.expect_value(t, sevenz.update(&sw2, p.path), archive.General_Error.Busy)
		testing.expect_value(t, sevenz.create(&sw2, p.path), archive.General_Error.Busy)
		sevenz.close(&sw)
	}
	if testing.expect_value(t, sevenz.create(&sw, p.path), nil) {
		testing.expect_value(t, sevenz.open(&r1, p.path), archive.General_Error.Busy)
		testing.expect_value(t, sevenz.update(&sw2, p.path), archive.General_Error.Busy)
		sevenz.close(&sw)
	}
	fresh := update_paths(root, "fresh.7z")
	if testing.expect_value(t, sevenz.create(&sw, fresh.path), nil) {
		testing.expect_value(t, sevenz.create(&sw2, fresh.path), archive.General_Error.Busy)
		sevenz.close(&sw)
	}
	if testing.expect_value(t, sevenz.open(&r1, p.path), nil) {
		sevenz.close(&r1)
	}
}

@(test)
test_update_crash_states :: proc(t: ^testing.T) {
	root, root_ok := update_root(t, "odin_7z_update_crash_*")
	if !root_ok {
		return
	}
	defer os.remove_all(root)
	text   := write_text()
	random := write_random(40_000, 26)
	defer delete(random)

	before := []Update_Entry{
		{name = "a.txt", content = text},
		{name = "b.bin", content = random, method = .Store},
	}
	added := []Update_Entry{
		{name = "c.txt", content = text},
		{name = "d.bin", content = random, method = .Store},
		{name = "e",     directory = true},
	}
	old := make_7z(t, before)
	record := journal_expect(old, data_start_of(old))
	want := update_expect(before)
	p := update_paths(root, "crash.7z")

	tw: Torn_Writer
	torn_init(&tw, old)
	sw: sevenz.Writer
	if testing.expect_value(t, sevenz.update(&sw, torn_stream(&tw), {deterministic = true}), nil) {
		write_updates(t, &sw, added)
		testing.expect_value(t, sevenz.commit(&sw), nil)
		sevenz.close(&sw)
	}
	final := tw.data[:]
	added_want := update_expect(before, added)
	check_written(t, "crash/final", final, added_want)
	testing.expectf(t, torn_writes(&tw) >= 3, "crash: %d writes", torn_writes(&tw))

	for k in 0..=len(tw.ops) {
		label := fmt.tprintf("crash after op %d", k)
		survivor := torn_survivor(&tw, k, u64(k) * 31 + 7)
		testing.expect_value(t, os.write_entire_file(p.path, survivor), nil)
		testing.expect_value(t, os.write_entire_file(p.journal, record), nil)
		check_path(t, label, p.path, want)
		testing.expect(t, os.exists(p.journal), "a reader leaves the journal alone")
		generic, generic_err := archive.open(p.path)
		if testing.expectf(t, generic_err == nil, "%s: generic open %v", label, generic_err) {
			count := archive.info(&generic).member_count
			testing.expectf(t, count == len(want), "%s: generic open sees %d members, want %d", label, count, len(want))
			archive.close(&generic)
		}
		if testing.expect_value(t, sevenz.update(&sw, p.path), nil) {
			testing.expect(t, !os.exists(p.journal), "update consumes the journal")
			sevenz.close(&sw)
		}
		data, _ := os.read_entire_file(p.path, context.temp_allocator)
		testing.expectf(t, bytes.equal(data, old), "%s: recovery restores the old archive", label)
	}

	header := slice.clone(record, context.temp_allocator)
	header[24] ~= 1
	saved := slice.clone(record, context.temp_allocator)
	saved[len(saved) - 1] ~= 1
	for journal in ([][]u8{record[:20], header, saved, record[:len(record) - 1], {}}) {
		testing.expect_value(t, os.write_entire_file(p.path, old), nil)
		testing.expect_value(t, os.write_entire_file(p.journal, journal), nil)
		check_path(t, fmt.tprintf("journal %d bytes on the old archive", len(journal)), p.path, want)
		if testing.expect_value(t, sevenz.update(&sw, p.path), nil) {
			sevenz.close(&sw)
		}
		data, _ := os.read_entire_file(p.path, context.temp_allocator)
		testing.expectf(t, bytes.equal(data, old) && !os.exists(p.journal), "journal %d bytes on the old archive: left alone", len(journal))
	}

	stale := slice.clone(old, context.temp_allocator)
	stale[data_start_of(old) - 1] ~= 0xff
	stale_record := journal_expect(stale, data_start_of(stale))
	long_record  := journal_expect(final, data_start_of(final))
	for journal, i in ([][]u8{stale_record, long_record}) {
		target := final if i == 0 else old
		target_want := added_want if i == 0 else want
		testing.expect_value(t, os.write_entire_file(p.path, target), nil)
		testing.expect_value(t, os.write_entire_file(p.journal, journal), nil)
		check_path(t, fmt.tprintf("stale journal %d", i), p.path, target_want)
		if testing.expect_value(t, sevenz.update(&sw, p.path), nil) {
			sevenz.close(&sw)
		}
		data, _ := os.read_entire_file(p.path, context.temp_allocator)
		testing.expectf(t, bytes.equal(data, target) && !os.exists(p.journal), "stale journal %d: archive left alone, journal removed", i)
	}

	testing.expect_value(t, os.write_entire_file(p.path, old), nil)
	testing.expect_value(t, os.write_entire_file(p.temp, final[:len(final) / 2]), nil)
	check_path(t, "leftover temp", p.path, want)
	testing.expect(t, os.exists(p.temp), "a reader leaves a leftover temp alone")
	if testing.expect_value(t, sevenz.update(&sw, p.path), nil) {
		testing.expect(t, !os.exists(p.temp), "update clears a leftover temp")
		testing.expect_value(t, sevenz.remove_entry(&sw, "a.txt"), nil)
		testing.expect_value(t, sevenz.commit(&sw), nil)
		sevenz.close(&sw)
	}
	data, _ := os.read_entire_file(p.path, context.temp_allocator)
	check_written(t, "leftover temp", data, want[1:])

	testing.expect_value(t, os.write_entire_file(p.temp, final), nil)
	if testing.expect_value(t, sevenz.create(&sw, p.path), nil) {
		testing.expect_value(t, sevenz.write_entry(&sw, "a.txt", text), nil)
		testing.expect_value(t, sevenz.commit(&sw), nil)
		sevenz.close(&sw)
	}
	data, _ = os.read_entire_file(p.path, context.temp_allocator)
	check_written(t, "create over a leftover temp", data, want[:1])
	testing.expect(t, !os.exists(p.temp), "create publishes its temp")
}

@(test)
test_update_trailing :: proc(t: ^testing.T) {
	root, root_ok := update_root(t, "odin_7z_update_trailing_*")
	if !root_ok {
		return
	}
	defer os.remove_all(root)
	text := write_text()
	before := []Update_Entry{{name = "a.txt", content = text}}
	old := make_7z(t, before)
	p := update_paths(root, "trailing.7z")

	padded := make([]u8, len(old) + 65 << 20)
	defer delete(padded)
	copy(padded, old)
	testing.expect_value(t, os.write_entire_file(p.path, padded), nil)
	check_path(t, "trailing/open", p.path, update_expect(before))
	sw: sevenz.Writer
	if testing.expect_value(t, sevenz.update(&sw, p.path), nil) {
		testing.expect_value(t, sevenz.write_entry(&sw, "b.txt", text), nil)
		journal, _ := os.read_entire_file(p.journal, context.temp_allocator)
		testing.expectf(t, len(journal) == 40 + 20 + 32, "trailing: journal is %d bytes", len(journal))
		testing.expect_value(t, sevenz.commit(&sw), nil)
		sevenz.close(&sw)
	}
	data, _ := os.read_entire_file(p.path, context.temp_allocator)
	check_written(t, "trailing/update", data, update_expect(before, {{name = "b.txt", content = text}}))
	testing.expectf(t, len(data) < len(old) + 4096, "trailing: rewrite drops the padding, %d bytes", len(data))
	testing.expect(t, !os.exists(p.journal) && !os.exists(p.temp), "trailing: no journal or temp after the commit")
}

update_root :: proc(t: ^testing.T, pattern: string) -> (root: string, ok: bool) {
	dir, err := os.make_directory_temp("", pattern, context.temp_allocator)
	if err == .Unsupported {
		return "", false
	}
	if !testing.expect_value(t, err, nil) {
		return "", false
	}
	return dir, true
}

update_paths :: proc(root, name: string) -> (p: Update_Paths) {
	p.path, _ = os.join_path({root, name}, context.temp_allocator)
	p.journal = strings.concatenate({p.path, "-journal"}, context.temp_allocator)
	p.temp    = strings.concatenate({p.path, "-temp"}, context.temp_allocator)
	return
}

is_not_exist :: proc(err: archive.Error) -> bool {
	os_err, is_os := err.(os.Error)
	if !is_os {
		return false
	}
	general, is_general := os_err.(os.General_Error)
	return is_general && general == .Not_Exist
}

make_7z :: proc(t: ^testing.T, entries: []Update_Entry, options: sevenz.Writer_Options = {}) -> []u8 {
	m := Memory_File{seekable = true}
	defer delete(m.data)
	sw: sevenz.Writer
	if testing.expect_value(t, sevenz.create(&sw, memory_stream(&m), options), nil) {
		write_updates(t, &sw, entries)
		testing.expect_value(t, sevenz.commit(&sw), nil)
		sevenz.close(&sw)
	}
	return slice.clone(m.data[:], context.temp_allocator)
}

write_updates :: proc(t: ^testing.T, sw: ^sevenz.Writer, entries: []Update_Entry, loc := #caller_location) {
	for e in entries {
		testing.expect_value(t, write_update(sw, e), nil, loc)
	}
}

write_update :: proc(sw: ^sevenz.Writer, e: Update_Entry) -> archive.Error {
	switch {
	case e.directory:
		return sevenz.write_entry(sw, archive.File_Info{path = e.name, type = .Directory})
	case e.link != "":
		return sevenz.write_entry(sw, archive.File_Info{path = e.name, type = .Symlink, link_target = e.link})
	}
	return sevenz.write_entry(sw, e.name, e.content, sevenz.Entry_Options{method = e.method, filter = e.filter, delta_distance = e.delta, password = e.password})
}

update_expect :: proc(lists: ..[]Update_Entry) -> []Write_Expect {
	out := make([dynamic]Write_Expect, context.temp_allocator)
	for list in lists {
		for e in list {
			w := Write_Expect{name = e.name, type = .Regular, content = e.content, method = e.method, filters = e.filters, encrypted = e.encrypted}
			switch {
			case e.directory:
				w.type      = .Directory
				w.method    = .Unknown
				w.encrypted = false
			case e.link != "":
				w.type    = .Symlink
				w.link    = e.link
				w.content = transmute([]u8)e.link
				w.method  = .Unknown
			case len(e.content) == 0:
				w.method    = .Unknown
				w.encrypted = false
			}
			append(&out, w)
		}
	}
	return out[:]
}

append_anti :: proc(want: ^[]Write_Expect, names: ..string) {
	out := make([dynamic]Write_Expect, context.temp_allocator)
	append(&out, ..want^)
	for name in names {
		append(&out, Write_Expect{name = name, type = .Anti})
	}
	want^ = out[:]
}

check_repack :: proc(t: ^testing.T, label: string, p: Update_Paths, before: []Update_Entry, options: sevenz.Writer_Options, removed: []string, password: string) {
	old := make_7z(t, before, options)
	testing.expect_value(t, os.write_entire_file(p.path, old), nil)
	sw: sevenz.Writer
	if testing.expectf(t, sevenz.update(&sw, p.path, {password = password}) == nil, "%s: update", label) {
		for name in removed {
			testing.expectf(t, sevenz.remove_entry(&sw, name) == nil, "%s: remove %s", label, name)
		}
		commit_err := sevenz.commit(&sw)
		testing.expectf(t, commit_err == nil, "%s: commit %v", label, commit_err)
		sevenz.close(&sw)
	}
	data, _ := os.read_entire_file(p.path, context.temp_allocator)
	streams := 0
	for e in before {
		if len(e.content) > 0 {
			streams += 1
		}
	}
	solid := count_folders(old, password) < streams
	kept := make([dynamic]Update_Entry, context.temp_allocator)
	repacked := make([dynamic]Update_Entry, context.temp_allocator)
	for e in before {
		if slice.contains(removed, e.name) {
			continue
		}
		if solid && len(e.content) > 0 {
			append(&repacked, e)
		} else {
			append(&kept, e)
		}
	}
	check_written(t, label, data, update_expect(kept[:], repacked[:]), password)
	folders := count_folders(old, password) if solid else count_folders(old, password) - len(removed)
	testing.expectf(t, count_folders(data, password) == folders, "%s: %d folders, want %d", label, count_folders(data, password), folders)
}

check_path :: proc(t: ^testing.T, label: string, path: string, expected: []Write_Expect, password := "") {
	r: sevenz.Reader
	if open_err := sevenz.open(&r, path, compress.Options{}, context.allocator, archive.Read_Options{password = password}); !testing.expectf(t, open_err == nil, "%s: open %v", label, open_err) {
		return
	}
	defer sevenz.close(&r)
	check_entries(t, label, &r, expected)
}

data_start_of :: proc(data: []u8) -> int {
	r: sevenz.Reader
	if sevenz.open(&r, data) != nil {
		return -1
	}
	defer sevenz.close(&r)
	if len(r.streams.pack_sizes) == 0 {
		return len(data)
	}
	end := r.streams.pack_offsets[0]
	for size in r.streams.pack_sizes {
		end += size
	}
	return int(end)
}

journal_expect :: proc(old: []u8, check_end: int, start := 0) -> []u8 {
	Span :: struct {
		offset: int,
		length: int,
	}
	spans := [2]Span{{start, 32}, {check_end, len(old) - check_end}}
	n := 2 if check_end < len(old) else 1
	tail := min(check_end - start - 32, 64 << 10)
	out := make([dynamic]u8, 40 + 20 * n, context.temp_allocator)
	copy(out[:8], "ARCJOURN")
	endian.unchecked_put_u64le(out[8:], u64(len(old)))
	endian.unchecked_put_u64le(out[16:], u64(check_end))
	endian.unchecked_put_u32le(out[24:], u32(tail))
	endian.unchecked_put_u32le(out[28:], hash.crc32(old[check_end - tail:check_end]))
	endian.unchecked_put_u32le(out[32:], u32(n))
	for s, i in spans[:n] {
		at := 36 + 20 * i
		endian.unchecked_put_u64le(out[at:], u64(s.offset))
		endian.unchecked_put_u64le(out[at + 8:], u64(s.length))
		endian.unchecked_put_u32le(out[at + 16:], hash.crc32(old[s.offset:][:s.length]))
	}
	endian.unchecked_put_u32le(out[36 + 20 * n:], hash.crc32(out[:36 + 20 * n]))
	for s in spans[:n] {
		append(&out, ..old[s.offset:][:s.length])
	}
	return out[:]
}

torn_init :: proc(tw: ^Torn_Writer, initial: []u8) {
	tw^ = {}
	tw.initial       = slice.clone(initial, context.temp_allocator)
	tw.data          = make([dynamic]u8, len(initial), context.temp_allocator)
	tw.log.allocator = context.temp_allocator
	tw.ops.allocator = context.temp_allocator
	copy(tw.data[:], initial)
}

torn_writes :: proc(tw: ^Torn_Writer) -> (count: int) {
	for op in tw.ops {
		if !op.flush {
			count += 1
		}
	}
	return
}

torn_stream :: proc(tw: ^Torn_Writer) -> (s: io.Stream) {
	s.data      = tw
	s.procedure = torn_proc
	return
}

torn_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	tw := (^Torn_Writer)(stream_data)
	#partial switch mode {
	case .Read:
		n, err = torn_read(tw.data[:], p, tw.position)
		tw.position += n
		return
	case .Read_At:
		return torn_read(tw.data[:], p, offset)
	case .Write:
		append(&tw.ops, Torn_Op{offset = tw.position, start = len(tw.log), length = len(p)})
		append(&tw.log, ..p)
		torn_apply(&tw.data, tw.position, p)
		tw.position += i64(len(p))
		return i64(len(p)), nil
	case .Seek:
		target: i64
		switch whence {
		case .Start:   target = offset
		case .Current: target = tw.position + offset
		case .End:     target = i64(len(tw.data)) + offset
		}
		if target < 0 {
			return 0, .Invalid_Offset
		}
		tw.position = target
		return target, nil
	case .Size:
		return i64(len(tw.data)), nil
	case .Flush:
		append(&tw.ops, Torn_Op{flush = true})
		return 0, nil
	case .Query:
		return io.query_utility({.Read, .Read_At, .Write, .Seek, .Size, .Flush, .Query})
	}
	return 0, .Unsupported
}

torn_read :: proc(data, p: []u8, offset: i64) -> (n: i64, err: io.Error) {
	if offset < 0 {
		return 0, .Invalid_Offset
	}
	if offset >= i64(len(data)) {
		return 0, .EOF
	}
	n = i64(copy(p, data[offset:]))
	if n < i64(len(p)) {
		err = .EOF
	}
	return
}

torn_apply :: proc(out: ^[dynamic]u8, offset: i64, data: []u8) {
	end := int(offset) + len(data)
	if end > len(out^) {
		resize(out, end)
	}
	copy(out^[offset:], data)
}

torn_survivor :: proc(tw: ^Torn_Writer, crash_after: int, seed: u64) -> []u8 {
	durable := 0
	for op, i in tw.ops[:crash_after] {
		if op.flush {
			durable = i + 1
		}
	}
	out := make([dynamic]u8, context.temp_allocator)
	append(&out, ..tw.initial)
	for op in tw.ops[:durable] {
		if !op.flush {
			torn_apply(&out, op.offset, tw.log[op.start:][:op.length])
		}
	}
	state := seed
	for op in tw.ops[durable:crash_after] {
		at   := op.offset
		data := tw.log[op.start:][:op.length]
		for len(data) > 0 {
			piece := min(len(data), int(TORN_SECTOR - at % TORN_SECTOR))
			state = state * 6364136223846793005 + 1442695040888963407
			switch state >> 62 {
			case 0, 1:
				torn_apply(&out, at, data[:piece])
			case 2:
				if int(at) + piece > len(out) {
					resize(&out, int(at) + piece)
				}
			}
			at  += i64(piece)
			data = data[piece:]
		}
	}
	return out[:]
}
