package test_core_archive_tar

import "core:archive"
import "core:hash"
import "core:os"
import "core:strings"
import "core:testing"

Extracted :: struct {
	path: string,
	type: archive.Entry_Type,
	err:  archive.Error,
}

@(test)
test_check_member_path :: proc(t: ^testing.T) {
	Case :: struct {
		path:    string,
		unix:    bool,
		windows: bool,
	}
	cases := [?]Case{
		{"a.txt",                true,  true},
		{"a/b/c",                true,  true},
		{"./a",                  true,  true},
		{"a/",                   true,  true},
		{"a//b",                 true,  true},
		{"a/./b",                true,  true},
		{"",                     true,  true},
		{".",                    true,  true},
		{".hidden",              true,  true},
		{"/etc/passwd",          false, false},
		{"//evil.txt",           false, false},
		{"../evil.txt",          false, false},
		{"a/../b",               false, false},
		{"a/..",                 false, false},
		{"./a/./../../evil.txt", false, false},
		{"a\x00b",               false, false},
		{"C:/evil.txt",          true,  false},
		{"C:\\evil.txt",         true,  false},
		{"C:evil.txt",           true,  false},
		{"\\\\server\\share\\x", true,  false},
		{"\\evil.txt",           true,  false},
		{"a\\..\\..\\evil.txt",  true,  false},
		{"back\\slash.txt",      true,  true},
		{"a:stream.txt",         true,  false},
		{"CON",                  true,  false},
		{"con",                  true,  false},
		{"aux.txt",              true,  false},
		{"NUL.tar.gz",           true,  false},
		{"dir/PRN",              true,  false},
		{"CON .txt",             true,  false},
		{"COM0",                 true,  false},
		{"COM1",                 true,  false},
		{"lpt9.log",             true,  false},
		{"COM\u00b9",            true,  false},
		{"LPT\u00b3.txt",        true,  false},
		{"CONIN$",               true,  false},
		{"conout$.txt",          true,  false},
		{"COM",                  true,  true},
		{"COM10",                true,  true},
		{"CONSOLE",              true,  true},
		{"auxiliary.txt",        true,  true},
		{"nul_file",             true,  true},
		{"trailing.",            true,  false},
		{"trailing ",            true,  false},
		{"a./b",                 true,  false},
		{"a /b",                 true,  false},
		{"...",                  true,  false},
		{".. ",                  true,  false},
		{"two\nlines.txt",       true,  false},
		{"ctrl\x01char.txt",     true,  false},
		{"what?.txt",            true,  false},
		{"star*.txt",            true,  false},
		{"pipe|.txt",            true,  false},
		{"<lt>.txt",             true,  false},
		{"quote\".txt",          true,  false},
	}
	for c in cases {
		unix_err    := archive.check_member_path(c.path, false)
		windows_err := archive.check_member_path(c.path, true)
		testing.expectf(t, unix_err == (nil if c.unix else archive.Error(archive.General_Error.Unsafe_Path)), "%q on Unix: %v", c.path, unix_err)
		testing.expectf(t, windows_err == (nil if c.windows else archive.Error(archive.General_Error.Unsafe_Path)), "%q on Windows: %v", c.path, windows_err)
	}
}

@(test)
test_extract_hostile :: proc(t: ^testing.T) {
	base, base_ok := extract_temp(t, "odin_tar_extract_hostile_*")
	if !base_ok {
		return
	}
	defer os.remove_all(base)

	U :: archive.General_Error.Unsafe_Path
	S :: archive.General_Error.Skipped_Entry_Type
	E :: archive.General_Error.Exists
	W := windows_only(U)
	C := archive.Error(nil)
	if case_insensitive(t, base) {
		C = E
	}

	Case :: struct {
		file:    string,
		err:     archive.Error,
		members: []archive.Error,
	}
	cases := [?]Case{
		{"hostile-absolute.tar",         nil, {U, W, W, W, W, U}},
		{"hostile-case-collision.tar",   nil, {nil, C, C, nil, C}},
		{"hostile-devices.tar",          nil, {S, S, S, nil, S}},
		{"hostile-dotdot.tar",           nil, {U, U, U}},
		{"hostile-duplicates.tar",       nil, {nil, E, nil, E, nil, E}},
		{"hostile-hardlink-escape.tar",  nil, {S, S}},
		{"hostile-hardlink-missing.tar", nil, {S, S}},
		{"hostile-pax-path.tar",         nil, {U, S}},
		{"hostile-symlink-absolute.tar", nil, {S, nil}},
		{"hostile-symlink-chain.tar",    nil, {S, S, nil, S, nil}},
		{"hostile-symlink-escape.tar",   nil, {S, nil}},
		{"hostile-windows-names.tar",    nil, {W, W, W, W, W, W, W, W, nil, W, W, W, W, W, W}},
		{"crafted-after-end.tar",        nil, {nil}},
		{"crafted-no-end.tar",           nil, {nil}},
		{"crafted-one-end-block.tar",    nil, {nil}},
		{"crafted-pax-newline.tar",      nil, {W}},
		{"crafted-signed-checksum.tar",  nil, {nil}},
		{"crafted-v7-spaces.tar",        nil, {nil}},
		{"crafted-xstar.tar",            nil, {nil}},
		{"hostile-checksum.tar",         archive.Tar_Error.Invalid_Checksum,          nil},
		{"hostile-octal-garbage.tar",    archive.Tar_Error.Invalid_Number,            nil},
		{"hostile-pax-badlength.tar",    archive.Tar_Error.Invalid_Pax_Record,        nil},
		{"hostile-pax-length.tar",       archive.Tar_Error.Invalid_Pax_Record,        nil},
		{"hostile-pax-noequals.tar",     archive.Tar_Error.Invalid_Pax_Record,        nil},
		{"hostile-nul-path.tar",         archive.Tar_Error.Invalid_Pax_Record,        nil},
		{"hostile-pax-huge.tar",         archive.Tar_Error.Header_Too_Large,          nil},
		{"hostile-size-base256.tar",     archive.Tar_Error.Unsupported_GNU_Extension, nil},
		{"hostile-size-negative.tar",    archive.Tar_Error.Unsupported_GNU_Extension, nil},
		{"hostile-longname-dotdot.tar",  archive.Tar_Error.Unsupported_GNU_Extension, nil},
		{"hostile-longname-huge.tar",    archive.Tar_Error.Unsupported_GNU_Extension, nil},
		{"hostile-sparse-map.tar",       archive.Tar_Error.Unsupported_GNU_Extension, nil},
		{"hostile-size-absurd.tar",      archive.Tar_Error.Truncated,                 nil},
		{"hostile-truncated-data.tar",   archive.Tar_Error.Truncated,                 nil},
		{"hostile-truncated-header.tar", archive.Tar_Error.Truncated,                 nil},
	}
	for c in cases {
		dir, _ := os.join_path({base, c.file}, context.temp_allocator)
		out, _ := os.join_path({dir, "out"}, context.temp_allocator)
		got, err := extract_each(asset(c.file), out)
		testing.expectf(t, err == c.err, "%s: %v, want %v", c.file, err, c.err)
		if c.members != nil {
			testing.expectf(t, len(got) == len(c.members), "%s: %d members, want %d", c.file, len(got), len(c.members))
			for g, i in got {
				if i < len(c.members) {
					testing.expectf(t, g.err == c.members[i], "%s: %q: %v, want %v", c.file, g.path, g.err, c.members[i])
				}
			}
		}
		expect_contained(t, c.file, dir)
	}

	escape, _ := os.join_path({base, "hostile-symlink-escape.tar", "out", "escape"}, context.temp_allocator)
	testing.expect(t, os.is_directory(escape), "escape is not a directory")
	same, _ := os.join_path({base, "hostile-duplicates.tar", "out", "same.txt"}, context.temp_allocator)
	first, _ := os.read_entire_file(same, context.temp_allocator)
	testing.expectf(t, string(first) == "first\n", "same.txt %q", string(first))
}

@(test)
test_extract_all :: proc(t: ^testing.T) {
	base, base_ok := extract_temp(t, "odin_tar_extract_all_*")
	if !base_ok {
		return
	}
	defer os.remove_all(base)
	out, _ := os.join_path({base, "out"}, context.temp_allocator)

	a, err := archive.open(asset("gnu-posix.tar"))
	if !testing.expect_value(t, err, nil) {
		return
	}
	testing.expect_value(t, archive.extract_all(&a, out), archive.General_Error.Skipped_Entry_Type)
	archive.close(&a)

	expect_file_crc(t, out, "tree/TEXT.TXT", TEXT_CRC)
	expect_file_crc(t, out, "tree/README.TXT", README_CRC)
	expect_file(t, out, "tree/ONE.TXT", "A")
	expect_file(t, out, "tree/EMPTY.TXT", "")
	for name in ([?]string{"tree/emptydir", "tree/sub/deep"}) {
		path, _ := os.join_path({out, name}, context.temp_allocator)
		testing.expectf(t, os.is_directory(path), "%s is not a directory", name)
	}
	for name in ([?]string{"tree/hard.txt", "tree/link.txt"}) {
		path, _ := os.join_path({out, name}, context.temp_allocator)
		testing.expectf(t, !os.exists(path), "%s exists", name)
	}

	again, again_err := extract_each(asset("gnu-posix.tar"), out)
	testing.expect_value(t, again_err, nil)
	for g in again {
		want := archive.Error(archive.General_Error.Skipped_Entry_Type)
		#partial switch g.type {
		case .Regular:   want = archive.General_Error.Exists
		case .Directory: want = nil
		}
		testing.expectf(t, g.err == want, "again: %q: %v, want %v", g.path, g.err, want)
	}

	one, _ := os.join_path({out, "tree", "ONE.TXT"}, context.temp_allocator)
	testing.expect_value(t, os.write_entire_file(one, "changed"), nil)
	replaced, replaced_err := extract_each(asset("gnu-posix.tar"), out, true)
	testing.expect_value(t, replaced_err, nil)
	for g in replaced {
		if g.type == .Regular || g.type == .Directory {
			testing.expectf(t, g.err == nil, "overwrite: %q: %v", g.path, g.err)
		}
	}
	expect_file(t, out, "tree/ONE.TXT", "A")
	expect_file_crc(t, out, "tree/TEXT.TXT", TEXT_CRC)

	testing.expect_value(t, os.write_entire_file(one, "changed"), nil)
	a, err = archive.open(asset("gnu-posix.tar"))
	if !testing.expect_value(t, err, nil) {
		return
	}
	defer archive.close(&a)
	d, d_err := archive.extractor_create(out)
	if !testing.expect_value(t, d_err, nil) {
		return
	}
	defer archive.extractor_destroy(&d)
	it := archive.iterator_create(&a)
	defer archive.iterator_destroy(&it)
	asked := 0
	for fi in archive.iterate(&it) {
		item_err := archive.extract_current_to_dir(&d, &it, fi, fi.path)
		if item_err == archive.General_Error.Exists && archive.clean_member_path(fi.path) == "tree/ONE.TXT" {
			asked += 1
			item_err = archive.extract_current_to_dir(&d, &it, fi, fi.path, overwrite = true)
			testing.expect_value(t, item_err, nil)
		}
	}
	testing.expect_value(t, asked, 1)
	expect_file(t, out, "tree/ONE.TXT", "A")
}

@(test)
test_extract_no_follow :: proc(t: ^testing.T) {
	base, base_ok := extract_temp(t, "odin_tar_extract_follow_*")
	if !base_ok {
		return
	}
	defer os.remove_all(base)
	out,     _ := os.join_path({base, "out"}, context.temp_allocator)
	tree,    _ := os.join_path({out, "tree"}, context.temp_allocator)
	one,     _ := os.join_path({tree, "ONE.TXT"}, context.temp_allocator)
	sub,     _ := os.join_path({tree, "sub"}, context.temp_allocator)
	outside, _ := os.join_path({base, "outside.txt"}, context.temp_allocator)
	away,    _ := os.join_path({base, "away"}, context.temp_allocator)
	testing.expect_value(t, os.make_directory_all(tree), nil)
	testing.expect_value(t, os.make_directory(away), nil)
	testing.expect_value(t, os.write_entire_file(outside, "outside"), nil)

	if !testing.expect_value(t, os.link(outside, one), nil) {
		return
	}
	got, err := extract_each(asset("gnu-posix.tar"), out, true)
	testing.expect_value(t, err, nil)
	expect_member(t, got, "tree/ONE.TXT", nil)
	expect_file(t, out, "tree/ONE.TXT", "A")
	expect_file(t, base, "outside.txt", "outside")
	testing.expect_value(t, os.remove(one), nil)

	symlink_err := os.symlink(outside, one)
	if symlink_err == .Unsupported || !testing.expect_value(t, symlink_err, nil) {
		return
	}
	got, err = extract_each(asset("gnu-posix.tar"), out)
	testing.expect_value(t, err, nil)
	expect_member(t, got, "tree/ONE.TXT", archive.General_Error.Exists)
	expect_file(t, base, "outside.txt", "outside")

	got, err = extract_each(asset("gnu-posix.tar"), out, true)
	testing.expect_value(t, err, nil)
	expect_member(t, got, "tree/ONE.TXT", nil)
	info, info_err := os.lstat(one, context.temp_allocator)
	testing.expect_value(t, info_err, nil)
	testing.expect_value(t, info.type, os.File_Type.Regular)
	expect_file(t, out, "tree/ONE.TXT", "A")
	expect_file(t, base, "outside.txt", "outside")

	testing.expect_value(t, os.remove_all(sub), nil)
	testing.expect_value(t, os.symlink(away, sub), nil)
	got, err = extract_each(asset("gnu-posix.tar"), out)
	testing.expect_value(t, err, nil)
	expect_member(t, got, "tree/sub", archive.General_Error.Exists)
	expect_member(t, got, "tree/sub/deep", archive.General_Error.Unsafe_Path)
	expect_member(t, got, "tree/sub/deep/LICENSE", archive.General_Error.Unsafe_Path)
	expect_empty(t, away)

	got, err = extract_each(asset("gnu-posix.tar"), out, true)
	testing.expect_value(t, err, nil)
	expect_member(t, got, "tree/sub", nil)
	expect_member(t, got, "tree/sub/deep/LICENSE", nil)
	expect_empty(t, away)
	info, info_err = os.lstat(sub, context.temp_allocator)
	testing.expect_value(t, info_err, nil)
	testing.expect_value(t, info.type, os.File_Type.Directory)
}

@(test)
test_extract_limits :: proc(t: ^testing.T) {
	for name in ([2]string{"gnu-posix.tar", "gnu-posix.tar.gz"}) {
		for options, k in ([3]archive.Extract_Options{{max_ratio = 1}, {max_total_size = 1}, {}}) {
			a, err := archive.open(asset(name))
			if !testing.expect_value(t, err, nil) {
				return
			}
			one, text: [dynamic]u8
			targets := []archive.Target{{path = "tree/ONE.TXT", to = &one}, {path = "tree/TEXT.TXT", to = &text}}
			errs: [2]archive.Error
			it := archive.extract_iterator_create(&a, targets, options)
			for _, i in archive.extract_iterate(&it) {
				_, errs[i] = archive.extract_iterator_error(&it)
			}
			archive.extract_iterator_destroy(&it)
			archive.close(&a)
			want_text: archive.Error = archive.General_Error.Limit_Exceeded if k == 1 else nil
			testing.expectf(t, errs[0] == nil && string(one[:]) == "A", "%s, %v: ONE.TXT %v %q", name, options, errs[0], string(one[:]))
			testing.expectf(t, errs[1] == want_text, "%s, %v: TEXT.TXT %v, want %v", name, options, errs[1], want_text)
			delete(one)
			delete(text)
		}
	}
}

extract_temp :: proc(t: ^testing.T, pattern: string) -> (base: string, ok: bool) {
	err: os.Error
	base, err = os.make_directory_temp("", pattern, context.temp_allocator)
	if err == .Unsupported {
		return
	}
	ok = testing.expect_value(t, err, nil)
	return
}

extract_each :: proc(path, out: string, overwrite := false) -> (got: [dynamic]Extracted, err: archive.Error) {
	got = make([dynamic]Extracted, context.temp_allocator)
	a := archive.open(path) or_return
	defer archive.close(&a)
	d := archive.extractor_create(out, {overwrite = overwrite}) or_return
	defer archive.extractor_destroy(&d)
	it := archive.iterator_create(&a)
	defer archive.iterator_destroy(&it)
	for fi in archive.iterate(&it) {
		item_err := archive.extract_current_to_dir(&d, &it, fi, fi.path)
		append(&got, Extracted{strings.clone(fi.path, context.temp_allocator), fi.type, item_err})
	}
	_, err = archive.iterator_error(&it)
	return
}

windows_only :: proc(err: archive.Error) -> archive.Error {
	when ODIN_OS == .Windows {
		return err
	} else {
		return nil
	}
}

case_insensitive :: proc(t: ^testing.T, base: string) -> bool {
	lower, _ := os.join_path({base, "probe"}, context.temp_allocator)
	upper, _ := os.join_path({base, "PROBE"}, context.temp_allocator)
	testing.expect_value(t, os.write_entire_file(lower, ""), nil)
	defer os.remove(lower)
	return os.exists(upper)
}

expect_contained :: proc(t: ^testing.T, label, dir: string) {
	entries, err := os.read_all_directory_by_path(dir, context.temp_allocator)
	if !testing.expectf(t, err == nil, "%s: %v", label, err) {
		return
	}
	if !testing.expectf(t, len(entries) == 1 && entries[0].name == "out" && entries[0].type == .Directory, "%s: %d entries next to out", label, len(entries)) {
		return
	}
	expect_no_links(t, label, entries[0].fullpath)
}

expect_no_links :: proc(t: ^testing.T, label, dir: string) {
	entries, err := os.read_all_directory_by_path(dir, context.temp_allocator)
	if !testing.expectf(t, err == nil, "%s: %s: %v", label, dir, err) {
		return
	}
	for e in entries {
		testing.expectf(t, e.type == .Regular || e.type == .Directory, "%s: %s is %v", label, e.fullpath, e.type)
		if e.type == .Directory {
			expect_no_links(t, label, e.fullpath)
		}
	}
}

expect_empty :: proc(t: ^testing.T, dir: string) {
	entries, err := os.read_all_directory_by_path(dir, context.temp_allocator)
	testing.expect_value(t, err, nil)
	testing.expectf(t, len(entries) == 0, "%s has %d entries", dir, len(entries))
}

expect_member :: proc(t: ^testing.T, got: [dynamic]Extracted, path: string, want: archive.Error) {
	for g in got {
		if archive.clean_member_path(g.path) == path {
			testing.expectf(t, g.err == want, "%q: %v, want %v", path, g.err, want)
			return
		}
	}
	testing.expectf(t, false, "%q not extracted", path)
}

expect_file :: proc(t: ^testing.T, dir, name, want: string) {
	path, _ := os.join_path({dir, name}, context.temp_allocator)
	data, err := os.read_entire_file(path, context.temp_allocator)
	testing.expectf(t, err == nil && string(data) == want, "%s: %q, %v; want %q", name, string(data), err, want)
}

expect_file_crc :: proc(t: ^testing.T, dir, name: string, want: u32) {
	path, _ := os.join_path({dir, name}, context.temp_allocator)
	data, err := os.read_entire_file(path, context.temp_allocator)
	testing.expectf(t, err == nil && hash.crc32(data) == want, "%s: crc %08x, %v; want %08x", name, hash.crc32(data), err, want)
}
