package test_core_archive_zip

import "core:archive"
import "core:archive/zip"
import "core:bytes"
import "core:encoding/endian"
import "core:fmt"
import "core:hash"
import "core:io"
import "core:os"
import "core:slice"
import "core:strings"
import "core:testing"
import "core:time"

TORN_SECTOR     :: 512
JOURNAL_MAGIC   :: "ZIPJOURN"
JOURNAL_TAIL    :: 64 * 1024
UPDATE_UNIX_SEC :: 1_700_000_000

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

Torn_Reader :: struct {
	data:     []u8,
	position: i64,
}

Update_Entry :: struct {
	name:      string,
	content:   []u8,
	method:    archive.Method,
	directory: bool,
	streamed:  bool,
}

Member_State :: struct {
	name:    string,
	type:    archive.Entry_Type,
	content: []u8,
	err:     zip.Error,
}

Update_Paths :: struct {
	path:    string,
	journal: string,
	temp:    string,
}

@(test)
test_update_append :: proc(t: ^testing.T) {
	root, root_ok := update_root(t, "odin_zip_update_append_*")
	if !root_ok {
		return
	}
	defer os.remove_all(root)
	text   := write_text()
	random := write_random(70_000, 5)
	defer delete(random)

	before := []Update_Entry{
		{name = "text.txt",       content = text,   method = .Deflate},
		{name = "dir",            directory = true},
		{name = "dir/random.bin", content = random, method = .Store},
	}
	added := []Update_Entry{
		{name = "more.txt",     content = text,   method = .LZMA},
		{name = "streamed.bin", content = random, streamed = true},
		{name = "dir/bz.txt",   content = text,   method = .BZip2},
		{name = "empty",        directory = true},
	}
	old  := build_archive(t, before, "kept")
	want := entry_states(before, added)

	p := update_paths(root, "append.zip")
	testing.expect_value(t, os.write_entire_file(p.path, old), nil)
	zw: zip.Writer
	if testing.expect_value(t, zip.update(&zw, p.path, {deterministic = true}), nil) {
		write_entries(t, &zw, added)
		testing.expect(t, os.exists(p.journal), "journal while appending")
		testing.expect_value(t, zip.commit(&zw), nil)
		testing.expect_value(t, zip.commit(&zw), nil)
		testing.expect_value(t, zip.write_entry(&zw, "late.txt", text), io.Error.Closed)
		zip.close(&zw)
	}
	testing.expect(t, !os.exists(p.journal) && !os.exists(p.temp), "no journal or temp after the commit")
	data, read_err := os.read_entire_file(p.path, context.temp_allocator)
	testing.expect_value(t, read_err, nil)
	testing.expect(t, len(data) > len(old) && bytes.equal(data[:len(old)], old), "an append leaves the old bytes alone")
	expect_archive(t, "append/path", data, want, "kept")

	tw: Torn_Writer
	torn_init(&tw, old)
	if testing.expect_value(t, zip.update(&zw, torn_stream(&tw), {deterministic = true}), nil) {
		write_entries(t, &zw, added)
		testing.expect_value(t, zip.commit(&zw), nil)
		zip.close(&zw)
	}
	expect_archive(t, "append/stream", tw.data[:], want, "kept")
	testing.expect(t, bytes.equal(tw.data[:], data), "path and stream appends write the same bytes")

	torn_init(&tw, old)
	if testing.expect_value(t, zip.update(&zw, torn_stream(&tw), {deterministic = true, comment = "new"}), nil) {
		testing.expect_value(t, zip.commit(&zw), nil)
		zip.close(&zw)
	}
	testing.expect(t, bytes.equal(tw.data[:len(old)], old), "a comment change leaves the old bytes alone")
	expect_archive(t, "comment/stream", tw.data[:], entry_states(before), "new")

	for comment in ([]string{"", "kept"}) {
		torn_init(&tw, old)
		if testing.expect_value(t, zip.update(&zw, torn_stream(&tw), {comment = comment}), nil) {
			testing.expect_value(t, zip.commit(&zw), nil)
			zip.close(&zw)
		}
		testing.expectf(t, bytes.equal(tw.data[:], old) && torn_writes(&tw) == 0, "comment %q: an empty session writes nothing", comment)
	}
}

@(test)
test_update_modify :: proc(t: ^testing.T) {
	root, root_ok := update_root(t, "odin_zip_update_modify_*")
	if !root_ok {
		return
	}
	defer os.remove_all(root)
	text   := write_text()
	random := write_random(5_000, 7)
	defer delete(random)
	fresh := write_random(3_000, 8)
	defer delete(fresh)

	before := []Update_Entry{
		{name = "a.txt",     content = text},
		{name = "b.txt",     content = random},
		{name = "dir",       directory = true},
		{name = "dir/c.txt", content = text, method = .Store},
		{name = "d.bin",     content = random, streamed = true},
	}
	old := build_archive(t, before, "modify")
	p := update_paths(root, "modify.zip")
	testing.expect_value(t, os.write_entire_file(p.path, old), nil)

	zw: zip.Writer
	if testing.expect_value(t, zip.update(&zw, p.path, {deterministic = true}), nil) {
		testing.expect_value(t, zip.remove_entry(&zw, "b.txt"), nil)
		testing.expect_value(t, zip.remove_entry(&zw, "b.txt"), archive.General_Error.Not_Found)
		testing.expect_value(t, zip.write_entry(&zw, "a.txt", text), archive.General_Error.Exists)
		testing.expect_value(t, zip.write_entry(&zw, "./a.txt", text), archive.General_Error.Exists)
		testing.expect_value(t, zip.rename_entry(&zw, "a.txt", "dir/c.txt"), archive.General_Error.Exists)
		testing.expect_value(t, zip.rename_entry(&zw, "a.txt", "dir/"), archive.General_Error.Exists)
		testing.expect_value(t, zip.rename_entry(&zw, "nope", "x"), archive.General_Error.Not_Found)
		testing.expect_value(t, zip.rename_entry(&zw, "a.txt", "../evil"), archive.General_Error.Unsafe_Path)
		testing.expect_value(t, zip.rename_entry(&zw, "a.txt", "a.txt"), nil)
		testing.expect_value(t, zip.rename_entry(&zw, "a.txt", "ünï/cödé.txt"), nil)
		testing.expect_value(t, zip.rename_entry(&zw, "a.txt", "x"), archive.General_Error.Not_Found)
		testing.expect_value(t, zip.rename_entry(&zw, "dir", "folder"), nil)
		testing.expect_value(t, zip.write_entry(&zw, "b.txt", fresh), nil)
		testing.expect_value(t, zip.remove_entry(&zw, "d.bin"), nil)
		testing.expect_value(t, zip.write_entry(&zw, "d.bin", text), nil)
		testing.expect_value(t, zip.write_entry(&zw, "e.txt", fresh), nil)
		testing.expect_value(t, zip.rename_entry(&zw, "e.txt", "f.txt"), nil)
		testing.expect_value(t, zip.write_entry(&zw, "a.txt", fresh), nil)
		testing.expect_value(t, zip.remove_entry(&zw, "a.txt"), nil)
		testing.expect(t, os.exists(p.journal), "journal after appending in place")
		testing.expect_value(t, zip.commit(&zw), nil)
		zip.close(&zw)
	}
	testing.expect(t, !os.exists(p.journal) && !os.exists(p.temp), "no journal or temp after the rewrite")
	data, _ := os.read_entire_file(p.path, context.temp_allocator)
	want := []Member_State{
		{name = "ünï/cödé.txt", type = .Regular,   content = text},
		{name = "folder",       type = .Directory},
		{name = "dir/c.txt",    type = .Regular,   content = text},
		{name = "b.txt",        type = .Regular,   content = fresh},
		{name = "d.bin",        type = .Regular,   content = text},
		{name = "f.txt",        type = .Regular,   content = fresh},
	}
	when ODIN_OS != .Windows && ODIN_OS != .JS && ODIN_OS != .WASI {
		private := os.Permissions{.Read_User, .Write_User}
		testing.expect_value(t, os.chmod(p.path, private), nil)
		if testing.expect_value(t, zip.update(&zw, p.path), nil) {
			testing.expect_value(t, zip.rename_entry(&zw, "f.txt", "g.txt"), nil)
			testing.expect_value(t, zip.commit(&zw), nil)
			zip.close(&zw)
		}
		renamed_info, stat_err := os.stat(p.path, context.temp_allocator)
		testing.expectf(t, stat_err == nil && renamed_info.mode == private, "a rewrite keeps the mode: %v %v", renamed_info.mode, stat_err)
		if testing.expect_value(t, zip.update(&zw, p.path), nil) {
			testing.expect_value(t, zip.rename_entry(&zw, "g.txt", "f.txt"), nil)
			testing.expect_value(t, zip.commit(&zw), nil)
			zip.close(&zw)
		}
		data, _ = os.read_entire_file(p.path, context.temp_allocator)

		replaced := update_paths(root, "private.zip")
		testing.expect_value(t, os.write_entire_file(replaced.path, old), nil)
		testing.expect_value(t, os.chmod(replaced.path, private), nil)
		if testing.expect_value(t, zip.create(&zw, replaced.path), nil) {
			testing.expect_value(t, zip.write_entry(&zw, "a.txt", text), nil)
			testing.expect_value(t, zip.commit(&zw), nil)
			zip.close(&zw)
		}
		created_info, created_err := os.stat(replaced.path, context.temp_allocator)
		testing.expectf(t, created_err == nil && created_info.mode == private, "create over an archive keeps its mode: %v %v", created_info.mode, created_err)
	}
	expect_archive(t, "modify", data, want, "modify")
	expect_compact(t, "modify", data)
	expect_flags(t, "modify", data, {"ünï/cödé.txt"})

	tw: Torn_Writer
	torn_init(&tw, old)
	if testing.expect_value(t, zip.update(&zw, torn_stream(&tw)), nil) {
		testing.expect_value(t, zip.remove_entry(&zw, "a.txt"), archive.General_Error.Incompatible_Options)
		testing.expect_value(t, zip.rename_entry(&zw, "a.txt", "z.txt"), archive.General_Error.Incompatible_Options)
		testing.expect_value(t, zip.write_entry(&zw, "a.txt", text), archive.General_Error.Exists)
		zip.close(&zw)
	}
	testing.expect(t, bytes.equal(tw.data[:], old), "a stream session without additions writes nothing")

	m := Memory_File{seekable = true}
	defer delete(m.data)
	if testing.expect_value(t, zip.create(&zw, memory_stream(&m)), nil) {
		testing.expect_value(t, zip.remove_entry(&zw, "a.txt"), archive.General_Error.Incompatible_Options)
		testing.expect_value(t, zip.rename_entry(&zw, "a.txt", "z.txt"), archive.General_Error.Incompatible_Options)
		zip.close(&zw)
	}
}

@(test)
test_update_duplicates :: proc(t: ^testing.T) {
	root, root_ok := update_root(t, "odin_zip_update_duplicates_*")
	if !root_ok {
		return
	}
	defer os.remove_all(root)
	text   := write_text()
	random := write_random(4_000, 9)
	defer delete(random)

	before := []Update_Entry{
		{name = "dup.txt", content = text},
		{name = "x.txt",   content = random},
		{name = "dup.txt", content = random},
	}
	old := build_archive(t, before, "")
	p := update_paths(root, "duplicates.zip")
	testing.expect_value(t, os.write_entire_file(p.path, old), nil)

	zw: zip.Writer
	if testing.expect_value(t, zip.update(&zw, p.path), nil) {
		testing.expect_value(t, zip.write_entry(&zw, "dup.txt", text), archive.General_Error.Exists)
		testing.expect_value(t, zip.rename_entry(&zw, "dup.txt", "two.txt"), nil)
		testing.expect_value(t, zip.commit(&zw), nil)
		zip.close(&zw)
	}
	data, _ := os.read_entire_file(p.path, context.temp_allocator)
	expect_archive(t, "duplicates/rename", data, {
		{name = "two.txt", type = .Regular, content = text},
		{name = "x.txt",   type = .Regular, content = random},
		{name = "two.txt", type = .Regular, content = random},
	}, "")
	expect_compact(t, "duplicates/rename", data)

	if testing.expect_value(t, zip.update(&zw, p.path), nil) {
		testing.expect_value(t, zip.remove_entry(&zw, "two.txt"), nil)
		testing.expect_value(t, zip.commit(&zw), nil)
		zip.close(&zw)
	}
	data, _ = os.read_entire_file(p.path, context.temp_allocator)
	expect_archive(t, "duplicates/remove", data, {{name = "x.txt", type = .Regular, content = random}}, "")
	expect_compact(t, "duplicates/remove", data)
}

@(test)
test_update_abort :: proc(t: ^testing.T) {
	root, root_ok := update_root(t, "odin_zip_update_abort_*")
	if !root_ok {
		return
	}
	defer os.remove_all(root)
	text   := write_text()
	random := write_random(20_000, 11)
	defer delete(random)

	before := []Update_Entry{
		{name = "a.txt", content = text},
		{name = "b.bin", content = random},
	}
	old := build_archive(t, before, "abort")
	p := update_paths(root, "abort.zip")
	record := journal_record(old)

	for session in 0..<3 {
		testing.expect_value(t, os.write_entire_file(p.path, old), nil)
		zw: zip.Writer
		if testing.expect_value(t, zip.update(&zw, p.path), nil) {
			if session != 1 {
				testing.expect_value(t, zip.write_entry(&zw, "new.txt", random), nil)
				journal, journal_err := os.read_entire_file(p.journal, context.temp_allocator)
				testing.expectf(t, journal_err == nil && bytes.equal(journal, record[:]), "session %d: journal %v %v", session, journal_err, journal)
			}
			if session != 0 {
				testing.expect_value(t, zip.remove_entry(&zw, "a.txt"), nil)
			}
			zip.close(&zw)
		}
		data, _ := os.read_entire_file(p.path, context.temp_allocator)
		testing.expectf(t, bytes.equal(data, old), "session %d: an uncommitted update leaves the archive alone", session)
		testing.expectf(t, !os.exists(p.journal) && !os.exists(p.temp), "session %d: no journal or temp after the abort", session)
	}

	big := write_random(100_000, 12)
	defer delete(big)
	tw: Torn_Writer
	torn_init(&tw, old)
	zw: zip.Writer
	if testing.expect_value(t, zip.update(&zw, torn_stream(&tw)), nil) {
		testing.expect_value(t, zip.write_entry(&zw, "new.bin", big, {method = .Store}), nil)
		zip.close(&zw)
	}
	testing.expect(t, len(tw.data) > len(old) + len(big), "the aborted member was written")
	testing.expect(t, bytes.equal(tw.data[:len(old)], old), "an aborted stream update leaves the old bytes alone")
	expect_archive(t, "abort/stream", tw.data[:], entry_states(before), "abort")
}

@(test)
test_update_errors :: proc(t: ^testing.T) {
	root, root_ok := update_root(t, "odin_zip_update_errors_*")
	if !root_ok {
		return
	}
	defer os.remove_all(root)
	zw: zip.Writer
	missing := update_paths(root, "missing.zip")
	err := zip.update(&zw, missing.path)
	testing.expectf(t, is_not_exist(err), "update of a missing archive: %v", err)
	testing.expect(t, !os.exists(missing.path) && !os.exists(missing.journal) && !os.exists(missing.temp), "a failed update creates nothing")

	junk := update_paths(root, "junk.zip")
	text := write_text()
	testing.expect_value(t, os.write_entire_file(junk.path, text), nil)
	testing.expect_value(t, zip.update(&zw, junk.path), Zip_Error.End_Not_Found)
	data, _ := os.read_entire_file(junk.path, context.temp_allocator)
	testing.expect(t, bytes.equal(data, text) && !os.exists(junk.journal) && !os.exists(junk.temp), "a failed update leaves a non-archive alone")

	old := build_archive(t, {{name = "a.txt", content = text}}, "")
	m := Memory_File{seekable = false}
	defer delete(m.data)
	append(&m.data, ..old)
	testing.expect_value(t, zip.update(&zw, memory_stream(&m)), archive.General_Error.Not_Seekable)
	tr := Torn_Reader{data = old}
	testing.expect_value(t, zip.update(&zw, torn_reader(&tr)), archive.General_Error.Not_Seekable)
	testing.expect_value(t, zip.remove_entry(&zw, "a.txt"), io.Error.Closed)
	testing.expect_value(t, zip.commit(&zw), io.Error.Closed)
}

@(test)
test_update_past_end :: proc(t: ^testing.T) {
	root, root_ok := update_root(t, "odin_zip_update_past_end_*")
	if !root_ok {
		return
	}
	defer os.remove_all(root)
	text   := write_text()
	random := write_random(20_000, 13)
	defer delete(random)
	added := write_random(3_000, 14)
	defer delete(added)

	good := build_archive(t, {{name = "a.txt", content = text}, {name = "b.bin", content = random, method = .Store}}, "past")
	central := bytes.last_index(good, transmute([]u8)string("b.bin")) - size_of(zip.Central_Header)
	if !testing.expect(t, central > 0, "b.bin has a central record") {
		return
	}
	local        := int(endian.unchecked_get_u32le(good[central:][offset_of(zip.Central_Header, local_header_offset):]))
	name_length  := int(endian.unchecked_get_u16le(good[local:][offset_of(zip.Local_Header, name_length):]))
	extra_length := int(endian.unchecked_get_u16le(good[local:][offset_of(zip.Local_Header, extra_length):]))
	data_offset  := local + size_of(zip.Local_Header) + name_length + extra_length
	damage :: proc(good: []u8, central, compressed: int) -> []u8 {
		old := slice.clone(good, context.temp_allocator)
		endian.unchecked_put_u32le(old[central:][offset_of(zip.Central_Header, compressed_size):], u32(compressed))
		return old
	}
	kept  := entry_states({{name = "a.txt", content = text}, {name = "b.bin"}})
	grown := entry_states({{name = "a.txt", content = text}, {name = "b.bin"}, {name = "new.bin", content = added}})

	Past_Case :: struct {
		label:      string,
		compressed: int,
		want:       zip.Error,
	}
	cases := [?]Past_Case{
		{"past the end",  len(good) - data_offset + 1, Zip_Error.Truncated},
		{"up to the end", len(good) - data_offset,     nil},
	}
	for c in cases {
		old := damage(good, central, c.compressed)
		_, _, open_err := state_bytes(old)
		if !testing.expectf(t, open_err == nil, "%s: open %v", c.label, open_err) {
			continue
		}

		p := update_paths(root, "past.zip")
		testing.expect_value(t, os.write_entire_file(p.path, old), nil)
		zw: zip.Writer
		if testing.expect_value(t, zip.update(&zw, p.path), nil) {
			testing.expect_value(t, zip.write_entry(&zw, "new.bin", added), nil)
			commit_err := zip.commit(&zw)
			testing.expectf(t, commit_err == c.want, "%s: commit %v, want %v", c.label, commit_err, c.want)
			zip.close(&zw)
		}
		data, _ := os.read_entire_file(p.path, context.temp_allocator)
		testing.expectf(t, !os.exists(p.journal) && !os.exists(p.temp), "%s: no journal or temp", c.label)
		if c.want != nil {
			testing.expectf(t, bytes.equal(data, old), "%s: a refused append leaves the archive alone", c.label)
		} else {
			expect_damaged(t, c.label, data, grown, "b.bin")
		}

		testing.expect_value(t, os.write_entire_file(p.path, old), nil)
		if testing.expect_value(t, zip.update(&zw, p.path, {comment = "changed"}), nil) {
			commit_err := zip.commit(&zw)
			testing.expectf(t, commit_err == c.want, "%s/comment: commit %v, want %v", c.label, commit_err, c.want)
			zip.close(&zw)
		}
		data, _ = os.read_entire_file(p.path, context.temp_allocator)
		if c.want != nil {
			testing.expectf(t, bytes.equal(data, old), "%s/comment: a refused commit leaves the archive alone", c.label)
		} else {
			expect_damaged(t, fmt.tprintf("%s/comment", c.label), data, kept, "b.bin")
		}

		tw: Torn_Writer
		torn_init(&tw, old)
		if testing.expect_value(t, zip.update(&zw, torn_stream(&tw)), nil) {
			testing.expect_value(t, zip.write_entry(&zw, "new.bin", added), nil)
			commit_err := zip.commit(&zw)
			testing.expectf(t, commit_err == c.want, "%s/stream: commit %v, want %v", c.label, commit_err, c.want)
			zip.close(&zw)
		}
		testing.expectf(t, bytes.equal(tw.data[:len(old)], old), "%s/stream: the old bytes stay", c.label)
		expect_damaged(t, fmt.tprintf("%s/stream", c.label), tw.data[:], kept if c.want != nil else grown, "b.bin")
	}

	old := damage(good, central, len(good) - data_offset + 1)
	p := update_paths(root, "repair.zip")
	testing.expect_value(t, os.write_entire_file(p.path, old), nil)
	zw: zip.Writer
	if testing.expect_value(t, zip.update(&zw, p.path), nil) {
		testing.expect_value(t, zip.remove_entry(&zw, "b.bin"), nil)
		testing.expect_value(t, zip.write_entry(&zw, "new.bin", added), nil)
		testing.expect_value(t, zip.commit(&zw), nil)
		zip.close(&zw)
	}
	data, _ := os.read_entire_file(p.path, context.temp_allocator)
	expect_archive(t, "repair", data, entry_states({{name = "a.txt", content = text}, {name = "new.bin", content = added}}), "past")
	testing.expect(t, !os.exists(p.journal) && !os.exists(p.temp), "repair: no journal or temp")
}

expect_damaged :: proc(t: ^testing.T, label: string, data: []u8, want: []Member_State, damaged: string, loc := #caller_location) {
	got, _, err := state_bytes(data)
	if !testing.expectf(t, err == nil, "%s: open %v", label, err, loc = loc) {
		return
	}
	if !testing.expectf(t, len(got) == len(want), "%s: %d members, want %d", label, len(got), len(want), loc = loc) {
		return
	}
	for m, i in got {
		w := want[i]
		testing.expectf(t, m.name == w.name, "%s/%d: %q, want %q", label, i, m.name, w.name, loc = loc)
		if w.name == damaged {
			testing.expectf(t, m.err != nil, "%s/%s: reads, want an error", label, w.name, loc = loc)
		} else {
			testing.expectf(t, m.err == nil && bytes.equal(m.content, w.content), "%s/%s: %v %d bytes, want %d bytes", label, w.name, m.err, len(m.content), len(w.content), loc = loc)
		}
	}
}

@(test)
test_update_locks :: proc(t: ^testing.T) {
	root, root_ok := update_root(t, "odin_zip_update_locks_*")
	if !root_ok {
		return
	}
	defer os.remove_all(root)
	old := build_archive(t, {{name = "a.txt", content = write_text()}}, "")
	p := update_paths(root, "locks.zip")
	testing.expect_value(t, os.write_entire_file(p.path, old), nil)

	r1, r2: zip.Reader
	zw, zw2: zip.Writer
	if testing.expect_value(t, zip.open(&r1, p.path), nil) {
		testing.expect_value(t, zip.open(&r2, p.path), nil)
		zip.close(&r2)
		testing.expect_value(t, zip.update(&zw, p.path), archive.General_Error.Busy)
		testing.expect_value(t, zip.create(&zw, p.path), archive.General_Error.Busy)
		zip.close(&r1)
	}
	generic, generic_err := archive.open(p.path)
	if testing.expect_value(t, generic_err, nil) {
		testing.expect_value(t, zip.update(&zw, p.path), archive.General_Error.Busy)
		archive.close(&generic)
	}
	if testing.expect_value(t, zip.update(&zw, p.path), nil) {
		_, held_err := archive.open(p.path)
		testing.expectf(t, held_err != nil, "a generic open while a writer holds the archive: %v", held_err)
		testing.expect_value(t, zip.open(&r1, p.path), archive.General_Error.Busy)
		testing.expect_value(t, zip.update(&zw2, p.path), archive.General_Error.Busy)
		testing.expect_value(t, zip.create(&zw2, p.path), archive.General_Error.Busy)
		zip.close(&zw)
	}
	if testing.expect_value(t, zip.create(&zw, p.path), nil) {
		testing.expect_value(t, zip.open(&r1, p.path), archive.General_Error.Busy)
		testing.expect_value(t, zip.update(&zw2, p.path), archive.General_Error.Busy)
		zip.close(&zw)
	}
	fresh := update_paths(root, "fresh.zip")
	if testing.expect_value(t, zip.create(&zw, fresh.path), nil) {
		testing.expect_value(t, zip.create(&zw2, fresh.path), archive.General_Error.Busy)
		zip.close(&zw)
	}
	if testing.expect_value(t, zip.open(&r1, p.path), nil) {
		zip.close(&r1)
	}
}

@(test)
test_update_crash_states :: proc(t: ^testing.T) {
	root, root_ok := update_root(t, "odin_zip_update_crash_*")
	if !root_ok {
		return
	}
	defer os.remove_all(root)
	text   := write_text()
	random := write_random(40_000, 13)
	defer delete(random)

	before := []Update_Entry{
		{name = "a.txt", content = text},
		{name = "b.bin", content = random},
	}
	old   := build_archive(t, before, "crash")
	inner := build_archive(t, {{name = "inner.txt", content = text}}, "inner")
	added := []Update_Entry{
		{name = "inner.zip", content = inner, method = .Store},
		{name = "c.txt",     content = text},
		{name = "d.bin",     content = random, streamed = true},
	}
	tw: Torn_Writer
	torn_init(&tw, old)
	zw: zip.Writer
	if testing.expect_value(t, zip.update(&zw, torn_stream(&tw), {deterministic = true}), nil) {
		write_entries(t, &zw, added)
		testing.expect_value(t, zip.commit(&zw), nil)
		zip.close(&zw)
	}
	final  := tw.data[:]
	record := journal_record(old)
	want   := entry_states(before)
	p := update_paths(root, "crash.zip")

	for k in 0..=len(tw.ops) {
		survivor := torn_survivor(&tw, k, u64(k) * 31 + 7)
		testing.expect_value(t, os.write_entire_file(p.path, survivor), nil)
		testing.expect_value(t, os.write_entire_file(p.journal, record[:]), nil)
		got, comment, err := state_path(p.path)
		testing.expectf(t, err == nil && comment == "crash" && states_equal(got, want), "crash after op %d: open %v", k, err)
		testing.expect(t, os.exists(p.journal), "a reader leaves the journal alone")
		generic, generic_err := archive.open(p.path)
		if testing.expectf(t, generic_err == nil, "crash after op %d: generic open %v", k, generic_err) {
			count := archive.info(&generic).member_count
			testing.expectf(t, count == len(want), "crash after op %d: generic open sees %d members, want %d", k, count, len(want))
			archive.close(&generic)
		}
		if testing.expect_value(t, zip.update(&zw, p.path), nil) {
			testing.expect(t, !os.exists(p.journal), "update consumes the journal")
			zip.close(&zw)
		}
		data, _ := os.read_entire_file(p.path, context.temp_allocator)
		testing.expectf(t, bytes.equal(data, old), "crash after op %d: recovery truncates to the old archive", k)
	}

	added_want := entry_states(before, added)
	torn := record
	torn[24] ~= 1
	for journal in ([][]u8{record[:20], torn[:], record[:], {}}) {
		testing.expect_value(t, os.write_entire_file(p.path, old), nil)
		testing.expect_value(t, os.write_entire_file(p.journal, journal), nil)
		got, _, err := state_path(p.path)
		testing.expectf(t, err == nil && states_equal(got, want), "journal %d bytes on the old archive: open %v", len(journal), err)
		if testing.expect_value(t, zip.update(&zw, p.path), nil) {
			zip.close(&zw)
		}
		data, _ := os.read_entire_file(p.path, context.temp_allocator)
		testing.expectf(t, bytes.equal(data, old) && !os.exists(p.journal), "journal %d bytes on the old archive: left alone", len(journal))
	}

	stale := slice.clone(old, context.temp_allocator)
	stale[len(stale) - 1] ~= 0xff
	stale_record := journal_record(stale)
	long_record  := journal_record(final)
	for journal, i in ([][]u8{stale_record[:], long_record[:]}) {
		target := final if i == 0 else old
		target_want := added_want if i == 0 else want
		testing.expect_value(t, os.write_entire_file(p.path, target), nil)
		testing.expect_value(t, os.write_entire_file(p.journal, journal), nil)
		got, _, err := state_path(p.path)
		testing.expectf(t, err == nil && states_equal(got, target_want), "stale journal %d: open %v", i, err)
		if testing.expect_value(t, zip.update(&zw, p.path), nil) {
			zip.close(&zw)
		}
		data, _ := os.read_entire_file(p.path, context.temp_allocator)
		testing.expectf(t, bytes.equal(data, target) && !os.exists(p.journal), "stale journal %d: archive left alone, journal removed", i)
	}

	testing.expect_value(t, os.write_entire_file(p.path, old), nil)
	testing.expect_value(t, os.write_entire_file(p.temp, final[:len(final) / 2]), nil)
	got, _, err := state_path(p.path)
	testing.expectf(t, err == nil && states_equal(got, want), "leftover temp: open %v", err)
	testing.expect(t, os.exists(p.temp), "a reader leaves a leftover temp alone")
	if testing.expect_value(t, zip.update(&zw, p.path, {deterministic = true}), nil) {
		testing.expect(t, !os.exists(p.temp), "update clears a leftover temp")
		testing.expect_value(t, zip.remove_entry(&zw, "a.txt"), nil)
		testing.expect_value(t, zip.commit(&zw), nil)
		zip.close(&zw)
	}
	data, _ := os.read_entire_file(p.path, context.temp_allocator)
	expect_archive(t, "leftover temp", data, want[1:], "crash")
	expect_compact(t, "leftover temp", data)

	testing.expect_value(t, os.write_entire_file(p.temp, final), nil)
	if testing.expect_value(t, zip.create(&zw, p.path, {comment = "created"}), nil) {
		testing.expect_value(t, zip.write_entry(&zw, "a.txt", text), nil)
		testing.expect_value(t, zip.commit(&zw), nil)
		zip.close(&zw)
	}
	data, _ = os.read_entire_file(p.path, context.temp_allocator)
	expect_archive(t, "create over a leftover temp", data, {{name = "a.txt", type = .Regular, content = text}}, "created")
	testing.expect(t, !os.exists(p.temp), "create publishes its temp")
}

@(test)
test_update_torn_stream :: proc(t: ^testing.T) {
	text   := write_text()
	random := write_random(100_000, 17)
	defer delete(random)
	before := []Update_Entry{
		{name = "a.txt", content = text},
		{name = "dir",   directory = true},
	}
	added := []Update_Entry{
		{name = "b.bin",     content = random, method = .Store},
		{name = "c.txt",     content = text,   streamed = true},
		{name = "dir/d.bin", content = random, streamed = true},
	}
	known := [][]u8{text, random, {}}
	old := build_archive(t, before, "torn")

	for comment in ([]string{"", "changed"}) {
		tw: Torn_Writer
		torn_init(&tw, old)
		zw: zip.Writer
		session: []Update_Entry
		if comment == "" {
			session = added
		}
		if testing.expect_value(t, zip.update(&zw, torn_stream(&tw), {deterministic = true, comment = comment}), nil) {
			write_entries(t, &zw, session)
			testing.expect_value(t, zip.commit(&zw), nil)
			zip.close(&zw)
		}
		label := fmt.tprintf("update %q", comment)
		first_central := torn_order(t, label, &tw, i64(len(old)))
		check_survivors(t, label, &tw, first_central, entry_states(before), entry_states(before, session), known)
	}

	tw: Torn_Writer
	torn_init(&tw, nil)
	zw: zip.Writer
	if testing.expect_value(t, zip.create(&zw, torn_stream(&tw), {deterministic = true}), nil) {
		write_entries(t, &zw, added)
		testing.expect_value(t, zip.commit(&zw), nil)
		zip.close(&zw)
	}
	first_central := torn_order(t, "create", &tw, 0)
	check_survivors(t, "create", &tw, first_central, nil, entry_states(added), known)
}

@(test)
test_update_sfx :: proc(t: ^testing.T) {
	root, root_ok := update_root(t, "odin_zip_update_sfx_*")
	if !root_ok {
		return
	}
	defer os.remove_all(root)
	text := write_text()
	extra := []Update_Entry{{name = "added.txt", content = text}}

	original, read_err := os.read_entire_file(asset("archives/pkzip204-sfx.exe"), context.temp_allocator)
	if !testing.expect_value(t, read_err, nil) {
		return
	}
	stub := bytes.index(original, {'P', 'K', 3, 4})
	testing.expect(t, stub > 0, "the SFX archive has a stub")
	stub = max(stub, 0)
	start, comment, err := state_bytes(original)
	if !testing.expect_value(t, err, nil) {
		return
	}

	p := update_paths(root, "sfx.exe")
	testing.expect_value(t, os.write_entire_file(p.path, original), nil)
	zw: zip.Writer
	if testing.expect_value(t, zip.update(&zw, p.path, {deterministic = true}), nil) {
		write_entries(t, &zw, extra)
		testing.expect_value(t, zip.commit(&zw), nil)
		zip.close(&zw)
	}
	appended, _ := os.read_entire_file(p.path, context.temp_allocator)
	testing.expect(t, len(appended) > len(original) && bytes.equal(appended[:len(original)], original), "sfx: append keeps the old bytes")
	with_added := concat_states(start, entry_states(extra))
	expect_archive(t, "sfx/append", appended, with_added, comment)

	if testing.expect_value(t, zip.update(&zw, p.path), nil) {
		testing.expect_value(t, zip.rename_entry(&zw, start[0].name, "renamed"), nil)
		testing.expect_value(t, zip.commit(&zw), nil)
		zip.close(&zw)
	}
	rewritten, _ := os.read_entire_file(p.path, context.temp_allocator)
	testing.expect(t, len(rewritten) > stub && bytes.equal(rewritten[:stub], original[:stub]), "sfx: rewrite keeps the stub")
	renamed := rename_states(with_added, start[0].name, "renamed")
	expect_archive(t, "sfx/rewrite", rewritten, renamed, comment)
	expect_compact(t, "sfx/rewrite", rewritten)

	PREFIX :: 300
	plain := build_archive(t, {{name = "a.txt", content = text}, {name = "b", directory = true}}, "relative")
	prefixed := make([]u8, PREFIX + len(plain), context.temp_allocator)
	for &b, i in prefixed[:PREFIX] {
		b = u8(i * 7)
	}
	copy(prefixed[PREFIX:], plain)
	relative := update_paths(root, "relative.zip")
	testing.expect_value(t, os.write_entire_file(relative.path, prefixed), nil)
	if testing.expect_value(t, zip.update(&zw, relative.path, {deterministic = true}), nil) {
		write_entries(t, &zw, extra)
		testing.expect_value(t, zip.commit(&zw), nil)
		zip.close(&zw)
	}
	data, _ := os.read_entire_file(relative.path, context.temp_allocator)
	testing.expect(t, bytes.equal(data[:len(prefixed)], prefixed), "relative: append keeps the old bytes")
	testing.expect(t, relative_offsets(data, PREFIX), "relative: appended offsets stay relative to the prefix")
	relative_want := entry_states({{name = "a.txt", content = text}, {name = "b", directory = true}}, extra)
	expect_archive(t, "relative/append", data, relative_want, "relative")

	if testing.expect_value(t, zip.update(&zw, relative.path), nil) {
		testing.expect_value(t, zip.remove_entry(&zw, "a.txt"), nil)
		testing.expect_value(t, zip.commit(&zw), nil)
		zip.close(&zw)
	}
	data, _ = os.read_entire_file(relative.path, context.temp_allocator)
	testing.expect(t, bytes.equal(data[:PREFIX], prefixed[:PREFIX]), "relative: rewrite keeps the prefix")
	testing.expect(t, relative_offsets(data, PREFIX), "relative: rewritten offsets stay relative to the prefix")
	expect_archive(t, "relative/rewrite", data, relative_want[1:], "relative")
	expect_compact(t, "relative/rewrite", data)

	empty := build_archive(t, nil, "")
	stubbed := make([]u8, PREFIX + len(empty), context.temp_allocator)
	copy(stubbed[:PREFIX], prefixed[:PREFIX])
	copy(stubbed[PREFIX:], empty)
	put_le32(stubbed[len(stubbed) - 6:], PREFIX)
	empty_paths := update_paths(root, "empty.exe")
	testing.expect_value(t, os.write_entire_file(empty_paths.path, stubbed), nil)
	if testing.expect_value(t, zip.update(&zw, empty_paths.path), nil) {
		testing.expect_value(t, zip.write_entry(&zw, "gone.txt", text), nil)
		testing.expect_value(t, zip.remove_entry(&zw, "gone.txt"), nil)
		testing.expect_value(t, zip.commit(&zw), nil)
		zip.close(&zw)
	}
	data, _ = os.read_entire_file(empty_paths.path, context.temp_allocator)
	testing.expect(t, len(data) >= PREFIX && bytes.equal(data[:PREFIX], stubbed[:PREFIX]), "an emptied archive keeps its stub")
	expect_archive(t, "empty stub", data, nil, "")
	expect_compact(t, "empty stub", data)
}

@(test)
test_update_corpus :: proc(t: ^testing.T) {
	root, root_ok := update_root(t, "odin_zip_update_corpus_*")
	if !root_ok {
		return
	}
	defer os.remove_all(root)
	text := write_text()
	for c, i in CORPUS {
		original, read_err := os.read_entire_file(asset(c.name), context.temp_allocator)
		if !testing.expectf(t, read_err == nil, "%s: read %v", c.name, read_err) {
			continue
		}
		start, comment, err := state_bytes(original)
		if !testing.expectf(t, err == nil && len(start) > 0, "%s: open %v", c.name, err) {
			continue
		}
		wide := ""
		for m in start[1:] {
			if m.name != start[0].name && strings.index_proc(m.name, proc(r: rune) -> bool { return r >= 0x80 }) >= 0 {
				wide = m.name
				break
			}
		}
		p := update_paths(root, fmt.tprintf("corpus-%d.zip", i))
		testing.expect_value(t, os.write_entire_file(p.path, original), nil)
		zw: zip.Writer
		if testing.expectf(t, zip.update(&zw, p.path) == nil, "%s: update", c.name) {
			rename_err := zip.rename_entry(&zw, start[0].name, "renamed-first")
			testing.expectf(t, rename_err == nil, "%s: rename %q %v", c.name, start[0].name, rename_err)
			if wide != "" {
				rename_err = zip.rename_entry(&zw, wide, "renamed-wide")
				testing.expectf(t, rename_err == nil, "%s: rename %q %v", c.name, wide, rename_err)
			}
			commit_err := zip.commit(&zw)
			testing.expectf(t, commit_err == nil, "%s: commit %v", c.name, commit_err)
			zip.close(&zw)
		}
		renamed, _ := os.read_entire_file(p.path, context.temp_allocator)
		want := rename_states(start, start[0].name, "renamed-first")
		if wide != "" {
			want = rename_states(want, wide, "renamed-wide")
		}
		expect_archive(t, fmt.tprintf("%s/rewrite", c.name), renamed, want, comment)
		expect_compact(t, c.name, renamed)
		expect_no_unicode_path(t, c.name, renamed, "renamed-first")
		expect_no_unicode_path(t, c.name, renamed, "renamed-wide")

		if testing.expectf(t, zip.update(&zw, p.path, {deterministic = true}) == nil, "%s: update", c.name) {
			testing.expect_value(t, zip.write_entry(&zw, "appended.txt", text), nil)
			commit_err := zip.commit(&zw)
			testing.expectf(t, commit_err == nil, "%s: commit %v", c.name, commit_err)
			zip.close(&zw)
		}
		appended, _ := os.read_entire_file(p.path, context.temp_allocator)
		testing.expectf(t, len(appended) > len(renamed) && bytes.equal(appended[:len(renamed)], renamed), "%s: append keeps the old bytes", c.name)
		expect_archive(t, fmt.tprintf("%s/append", c.name), appended, concat_states(want, {{name = "appended.txt", type = .Regular, content = text}}), comment)
		os.remove(p.path)
	}
}

@(test)
test_update_large :: proc(t: ^testing.T) {
	when SLIM_TESTS {
		return
	}
	root, root_ok := update_root(t, "odin_zip_update_large_*")
	if !root_ok {
		return
	}
	defer os.remove_all(root)

	big, big_err := os.read_entire_file(asset("archives/iz-4.5GiB.zip"), context.temp_allocator)
	if testing.expect_value(t, big_err, nil) {
		p := update_paths(root, "big.zip")
		testing.expect_value(t, os.write_entire_file(p.path, big), nil)
		zw: zip.Writer
		if testing.expect_value(t, zip.update(&zw, p.path), nil) {
			testing.expect_value(t, zip.rename_entry(&zw, "zeros-4.5GiB.bin", "renamed.bin"), nil)
			testing.expect_value(t, zip.commit(&zw), nil)
			zip.close(&zw)
		}
		r: zip.Reader
		if testing.expect_value(t, zip.open(&r, p.path), nil) {
			fi, handle, ok, _ := zip.find(&r, "renamed.bin")
			testing.expect(t, ok, "find renamed.bin")
			testing.expect_value(t, fi.size, 4_831_838_208)
			d: Discard
			testing.expect_value(t, zip.extract(&r, handle, discard_writer(&d)), nil)
			testing.expect_value(t, d.count, 4_831_838_208)
			zip.close(&r)
		}
		big_out, _ := os.read_entire_file(p.path, context.temp_allocator)
		expect_compact(t, "iz-4.5GiB.zip", big_out)
	}

	many, many_err := os.read_entire_file(asset("archives/iz-70000-entries.zip"), context.temp_allocator)
	if !testing.expect_value(t, many_err, nil) {
		return
	}
	first, last: string
	count: int
	{
		r: zip.Reader
		if !testing.expect_value(t, zip.open(&r, many), nil) {
			return
		}
		it := zip.iterator_create(&r)
		for fi, index in zip.iterate(&it) {
			if index == 0 {
				first = strings.clone(fi.path, context.temp_allocator)
			}
			last  = strings.clone(fi.path, context.temp_allocator)
			count = index + 1
		}
		zip.iterator_destroy(&it)
		zip.close(&r)
	}
	testing.expect(t, count > 0xffff, "the archive needs a Zip64 count")
	p := update_paths(root, "many.zip")
	testing.expect_value(t, os.write_entire_file(p.path, many), nil)
	zw: zip.Writer
	if testing.expect_value(t, zip.update(&zw, p.path), nil) {
		testing.expect_value(t, zip.remove_entry(&zw, first), nil)
		testing.expect_value(t, zip.commit(&zw), nil)
		zip.close(&zw)
	}
	if testing.expect_value(t, zip.update(&zw, p.path), nil) {
		testing.expect_value(t, zip.write_entry(&zw, "appended.txt", write_text()), nil)
		testing.expect_value(t, zip.commit(&zw), nil)
		zip.close(&zw)
	}
	r: zip.Reader
	if testing.expect_value(t, zip.open(&r, p.path), nil) {
		defer zip.close(&r)
		testing.expect_value(t, zip.info(&r).member_count, count)
		_, _, gone, _ := zip.find(&r, first)
		testing.expect(t, !gone, "the removed member is gone")
		for name in ([]string{last, "appended.txt"}) {
			_, handle, found, _ := zip.find(&r, name)
			testing.expectf(t, found, "find %s", name)
			d: Discard
			testing.expect_value(t, zip.extract(&r, handle, discard_writer(&d)), nil)
		}
	}
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
	p.path, _  = os.join_path({root, name}, context.temp_allocator)
	p.journal  = strings.concatenate({p.path, "-journal"}, context.temp_allocator)
	p.temp     = strings.concatenate({p.path, "-temp"}, context.temp_allocator)
	return
}

is_not_exist :: proc(err: zip.Error) -> bool {
	os_err, is_os := err.(os.Error)
	if !is_os {
		return false
	}
	general, is_general := os_err.(os.General_Error)
	return is_general && general == .Not_Exist
}

journal_record :: proc(old: []u8) -> (record: [28]u8) {
	tail := min(len(old), JOURNAL_TAIL)
	copy(record[:8], JOURNAL_MAGIC)
	endian.unchecked_put_u64le(record[8:], u64(len(old)))
	endian.unchecked_put_u32le(record[16:], u32(tail))
	endian.unchecked_put_u32le(record[20:], hash.crc32(old[len(old) - tail:]))
	endian.unchecked_put_u32le(record[24:], hash.crc32(record[:24]))
	return
}

put_le32 :: proc(b: []u8, v: u32) {
	endian.unchecked_put_u32le(b, v)
}

get_u64 :: proc(b: []u8, at: int) -> u64 {
	return u64(get_u32(b, at)) | u64(get_u32(b, at + 4)) << 32
}

expect_compact :: proc(t: ^testing.T, label: string, data: []u8, loc := #caller_location) {
	Span :: struct {
		local:      int,
		data_end:   int,
		descriptor: bool,
		crc:        u32,
	}
	end := len(data) - 22
	for end >= 0 && !(get_u32(data, end) == 0x06054b50 && end + 22 + int(get_u16(data, end + 20)) == len(data)) {
		end -= 1
	}
	if !testing.expectf(t, end >= 0, "%s: no end record", label, loc = loc) {
		return
	}
	count  := u64(get_u16(data, end + 10))
	size   := u64(get_u32(data, end + 12))
	offset := u64(get_u32(data, end + 16))
	directory_end := end
	if end >= 76 && get_u32(data, end - 20) == 0x07064b50 && get_u32(data, end - 76) == 0x06064b50 {
		directory_end = end - 76
		count  = get_u64(data, directory_end + 32)
		size   = get_u64(data, directory_end + 40)
		offset = get_u64(data, directory_end + 48)
	}
	central := directory_end - int(size)
	base    := central - int(offset)
	spans := make([dynamic]Span, context.temp_allocator)
	at := central
	for _ in 0..<count {
		if !testing.expectf(t, at + 46 <= directory_end && get_u32(data, at) == 0x02014b50, "%s: central header at %d", label, at, loc = loc) {
			return
		}
		flags      := get_u16(data, at + 8)
		compressed := u64(get_u32(data, at + 20))
		plain      := u64(get_u32(data, at + 24))
		local      := u64(get_u32(data, at + 42))
		n, m, k    := int(get_u16(data, at + 28)), int(get_u16(data, at + 30)), int(get_u16(data, at + 32))
		extra := data[at + 46 + n:][:m]
		for len(extra) >= 4 {
			id     := get_u16(extra, 0)
			length := int(get_u16(extra, 2))
			if id == 1 {
				field := 4
				if plain == 0xffff_ffff {
					plain = get_u64(extra, field)
					field += 8
				}
				if compressed == 0xffff_ffff {
					compressed = get_u64(extra, field)
					field += 8
				}
				if local == 0xffff_ffff {
					local = get_u64(extra, field)
				}
			}
			extra = extra[min(4 + length, len(extra)):]
		}
		header := int(local) + base
		if !testing.expectf(t, header >= 0 && header + 30 <= central && get_u32(data, header) == 0x04034b50, "%s: local header at %d", label, header, loc = loc) {
			return
		}
		start := header + 30 + int(get_u16(data, header + 26)) + int(get_u16(data, header + 28))
		append(&spans, Span{local = header, data_end = start + int(compressed), descriptor = flags & 8 != 0, crc = get_u32(data, at + 16)})
		at += 46 + n + m + k
	}
	slice.sort_by(spans[:], proc(a, b: Span) -> bool {
		return a.local < b.local
	})
	for s, i in spans {
		next := central if i + 1 == len(spans) else spans[i + 1].local
		gap  := next - s.data_end
		if !s.descriptor {
			testing.expectf(t, gap == 0, "%s: %d bytes after the member at %d", label, gap, s.local, loc = loc)
			continue
		}
		signed := gap == 16 || gap == 24
		valid  := (gap == 12 || gap == 16 || gap == 20 || gap == 24) && (!signed || get_u32(data, s.data_end) == 0x08074b50)
		valid   = valid && get_u32(data, s.data_end + (4 if signed else 0)) == s.crc
		testing.expectf(t, valid, "%s: %d bytes after the member at %d are not its data descriptor", label, gap, s.local, loc = loc)
	}
}

relative_offsets :: proc(data: []u8, prefix: int) -> bool {
	end := bytes.last_index(data, {'P', 'K', 5, 6})
	if end < 0 || end + 22 > len(data) {
		return false
	}
	size   := int(get_u32(data, end + 12))
	offset := int(get_u32(data, end + 16))
	count  := int(get_u16(data, end + 10))
	if end - size != offset + prefix {
		return false
	}
	at := end - size
	for _ in 0..<count {
		if at + 46 > end || get_u32(data, at) != 0x02014b50 {
			return false
		}
		local := int(get_u32(data, at + 42)) + prefix
		if local + 4 > len(data) || get_u32(data, local) != 0x04034b50 {
			return false
		}
		at += 46 + int(get_u16(data, at + 28)) + int(get_u16(data, at + 30)) + int(get_u16(data, at + 32))
	}
	return at == end
}

build_archive :: proc(t: ^testing.T, entries: []Update_Entry, comment: string) -> []u8 {
	tw: Torn_Writer
	torn_init(&tw, nil)
	zw: zip.Writer
	if testing.expect_value(t, zip.create(&zw, torn_stream(&tw), {deterministic = true, comment = comment}), nil) {
		write_entries(t, &zw, entries)
		testing.expect_value(t, zip.commit(&zw), nil)
		zip.close(&zw)
	}
	return tw.data[:]
}

write_entries :: proc(t: ^testing.T, zw: ^zip.Writer, entries: []Update_Entry) {
	for e in entries {
		err := write_update_entry(zw, e)
		testing.expectf(t, err == nil, "write %s: %v", e.name, err)
	}
}

write_update_entry :: proc(zw: ^zip.Writer, e: Update_Entry) -> zip.Error {
	fi: archive.File_Info
	fi.path              = e.name
	fi.type              = .Regular
	fi.modification_time = time.unix(UPDATE_UNIX_SEC, 0)
	if e.directory {
		fi.type = .Directory
		return zip.write_entry(zw, fi)
	}
	fi.size = i64(len(e.content))
	if e.streamed {
		fi.size = -1
		br: bytes.Reader
		bytes.reader_init(&br, e.content)
		ns := Non_Seekable{inner = bytes.reader_to_stream(&br)}
		return zip.write_entry(zw, fi, non_seekable_stream(&ns), {method = e.method})
	}
	return zip.write_entry(zw, fi, e.content, {method = e.method})
}

entry_states :: proc(lists: ..[]Update_Entry) -> []Member_State {
	states := make([dynamic]Member_State, context.temp_allocator)
	for list in lists {
		for e in list {
			kind := archive.Entry_Type.Directory if e.directory else archive.Entry_Type.Regular
			append(&states, Member_State{
				name    = archive.clean_member_path(e.name),
				type    = kind,
				content = e.content,
			})
		}
	}
	return states[:]
}

concat_states :: proc(a, b: []Member_State) -> []Member_State {
	states := make([]Member_State, len(a) + len(b), context.temp_allocator)
	copy(states, a)
	copy(states[len(a):], b)
	return states
}

rename_states :: proc(states: []Member_State, from, to: string) -> []Member_State {
	renamed := slice.clone(states, context.temp_allocator)
	for &m in renamed {
		if m.name == from {
			m.name = to
		}
	}
	return renamed
}

states_equal :: proc(a, b: []Member_State) -> bool {
	if len(a) != len(b) {
		return false
	}
	for m, i in a {
		if m.name != b[i].name || m.type != b[i].type || m.err != b[i].err || !bytes.equal(m.content, b[i].content) {
			return false
		}
	}
	return true
}

state_bytes :: proc(data: []u8, use_stream := false) -> (members: []Member_State, comment: string, err: zip.Error) {
	r: zip.Reader
	tr := Torn_Reader{data = data}
	if use_stream {
		err = zip.open(&r, torn_reader(&tr))
	} else {
		err = zip.open(&r, data)
	}
	if err != nil {
		return
	}
	defer zip.close(&r)
	return read_state(&r)
}

state_path :: proc(path: string) -> (members: []Member_State, comment: string, err: zip.Error) {
	r: zip.Reader
	zip.open(&r, path) or_return
	defer zip.close(&r)
	return read_state(&r)
}

read_state :: proc(r: ^zip.Reader) -> (members: []Member_State, comment: string, err: zip.Error) {
	list := make([dynamic]Member_State, context.temp_allocator)
	comment = strings.clone(zip.info(r).comment, context.temp_allocator)
	it := zip.iterator_create(r)
	defer zip.iterator_destroy(&it)
	for fi in zip.iterate(&it) {
		sink := strings.builder_make_none(context.temp_allocator)
		extract_err := zip.extract_current(&it, strings.to_writer(&sink), {password = PASSWORD})
		append(&list, Member_State{
			name    = strings.clone(archive.clean_member_path(fi.path), context.temp_allocator),
			type    = fi.type,
			content = sink.buf[:],
			err     = extract_err,
		})
	}
	_, err = zip.iterator_error(&it)
	return list[:], comment, err
}

expect_archive :: proc(t: ^testing.T, label: string, data: []u8, want: []Member_State, comment: string, loc := #caller_location) {
	got, got_comment, err := state_bytes(data)
	if !testing.expectf(t, err == nil, "%s: open %v", label, err, loc = loc) {
		return
	}
	testing.expectf(t, got_comment == comment, "%s: comment %q, want %q", label, got_comment, comment, loc = loc)
	testing.expectf(t, len(got) == len(want), "%s: %d members, want %d", label, len(got), len(want), loc = loc)
	for m, i in got[:min(len(got), len(want))] {
		w := want[i]
		testing.expectf(t, m.name == w.name && m.type == w.type, "%s/%d: %q %v, want %q %v", label, i, m.name, m.type, w.name, w.type, loc = loc)
		testing.expectf(t, m.err == w.err && bytes.equal(m.content, w.content), "%s/%s: %v %d bytes, want %v %d bytes", label, w.name, m.err, len(m.content), w.err, len(w.content), loc = loc)
	}
}

expect_flags :: proc(t: ^testing.T, label: string, data: []u8, utf8: []string) {
	r: zip.Reader
	if !testing.expect_value(t, zip.open(&r, data), nil) {
		return
	}
	defer zip.close(&r)
	it := zip.iterator_create(&r)
	defer zip.iterator_destroy(&it)
	for fi in zip.iterate(&it) {
		entry := zip.current_entry(&it)
		want  := slice.contains(utf8, archive.clean_member_path(fi.path))
		local := get_u16(data, int(entry.header_offset) + 6)
		testing.expectf(t, (.UTF8 in entry.central.flags) == want, "%s/%s: central flags %v", label, fi.path, entry.central.flags)
		testing.expectf(t, (local & 0x800 != 0) == want, "%s/%s: local flags %4x", label, fi.path, local)
	}
}

expect_no_unicode_path :: proc(t: ^testing.T, label: string, data: []u8, name: string) {
	has_unicode_path :: proc(extra: []u8) -> bool {
		rest := extra
		for len(rest) >= 4 {
			if get_u16(rest, 0) == 0x7075 {
				return true
			}
			rest = rest[min(4 + int(get_u16(rest, 2)), len(rest)):]
		}
		return false
	}
	r: zip.Reader
	if !testing.expect_value(t, zip.open(&r, data), nil) {
		return
	}
	defer zip.close(&r)
	it := zip.iterator_create(&r)
	defer zip.iterator_destroy(&it)
	for fi in zip.iterate(&it) {
		if archive.clean_member_path(fi.path) != name {
			continue
		}
		entry := zip.current_entry(&it)
		at    := int(entry.header_offset)
		local := data[at + 30 + int(get_u16(data, at + 26)):][:get_u16(data, at + 28)]
		testing.expectf(t, !has_unicode_path(entry.central_extra), "%s/%s: the central header keeps a stale Unicode Path field", label, name)
		testing.expectf(t, !has_unicode_path(local), "%s/%s: the local header keeps a stale Unicode Path field", label, name)
	}
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
		return torn_seek(&tw.position, i64(len(tw.data)), offset, whence)
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

torn_reader :: proc(tr: ^Torn_Reader) -> (s: io.Stream) {
	s.data      = tr
	s.procedure = torn_reader_proc
	return
}

torn_reader_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	tr := (^Torn_Reader)(stream_data)
	#partial switch mode {
	case .Read:
		n, err = torn_read(tr.data, p, tr.position)
		tr.position += n
		return
	case .Read_At:
		return torn_read(tr.data, p, offset)
	case .Seek:
		return torn_seek(&tr.position, i64(len(tr.data)), offset, whence)
	case .Size:
		return i64(len(tr.data)), nil
	case .Query:
		return io.query_utility({.Read, .Read_At, .Seek, .Size, .Query})
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

torn_seek :: proc(position: ^i64, size, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	target: i64
	switch whence {
	case .Start:   target = offset
	case .Current: target = position^ + offset
	case .End:     target = size + offset
	}
	if target < 0 {
		return 0, .Invalid_Offset
	}
	position^ = target
	return target, nil
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

torn_order :: proc(t: ^testing.T, label: string, tw: ^Torn_Writer, old_length: i64) -> (first_central: int) {
	ops := tw.ops[:]
	first_central = len(ops)
	if !testing.expectf(t, len(ops) > 0 && ops[len(ops) - 1].flush, "%s: the last op is a flush", label) {
		return
	}
	end := bytes.last_index(tw.data[:], {'P', 'K', 5, 6})
	if !testing.expectf(t, end >= 0, "%s: no end record", label) {
		return
	}
	central := i64(end) - i64(get_u32(tw.data[:], end + 12))
	last_data := -1
	for op, i in ops {
		if op.flush {
			continue
		}
		testing.expectf(t, op.offset >= old_length, "%s: op %d writes at %d, below the old end %d", label, i, op.offset, old_length)
		if op.offset + i64(op.length) <= central {
			testing.expectf(t, first_central == len(ops), "%s: op %d writes member data after the directory", label, i)
			last_data = i
		} else {
			testing.expectf(t, op.offset >= central, "%s: op %d straddles the directory", label, i)
			first_central = min(first_central, i)
		}
	}
	flushed := false
	for op in ops[last_data + 1:first_central] {
		if op.flush {
			flushed = true
		}
	}
	testing.expectf(t, flushed, "%s: no flush between the member data and the directory", label)
	return
}

check_survivors :: proc(t: ^testing.T, label: string, tw: ^Torn_Writer, first_central: int, before, after: []Member_State, known: [][]u8) {
	for k in 0..=len(tw.ops) {
		for seed in u64(1)..=3 {
			survivor := torn_survivor(tw, k, u64(k) * 1_000 + seed)
			intact := len(survivor) >= len(tw.initial) && bytes.equal(survivor[:len(tw.initial)], tw.initial)
			testing.expectf(t, intact, "%s: crash after op %d/%d: old bytes changed", label, k, seed)
			got, _, err := state_bytes(survivor, seed % 2 == 1)
			switch {
			case k == len(tw.ops):
				testing.expectf(t, err == nil && states_equal(got, after), "%s: complete run: %v", label, err)
			case k <= first_central:
				testing.expectf(t, err != nil || states_equal(got, before), "%s: crash after op %d/%d opened something else", label, k, seed)
			case err == nil:
				for m in got {
					if m.err == nil && m.type == .Regular {
						found := false
						for content in known {
							if bytes.equal(m.content, content) {
								found = true
							}
						}
						testing.expectf(t, found, "%s: crash after op %d/%d: %q extracted unknown bytes", label, k, seed, m.name)
					}
				}
			}
		}
	}
}
