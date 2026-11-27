package test_core_archive_tar

import "core:archive"
import "core:archive/tar"
import "core:bytes"
import "core:compress"
import "core:io"
import "core:os"
import "core:slice"
import "core:strings"
import "core:testing"
import "core:time"

Write_Source :: enum u8 {
	Bytes,
	Sized_Reader,
	Unsized_Reader,
}

Written :: struct {
	info: archive.File_Info,
	data: string,
}

Unsized :: struct {
	data:    []u8,
	pos:     int,
	hiccups: int,
	pending: int,
}

Write_Calls :: struct {
	calls:     int,
	last_in:   i64,
	cancel_at: int,
	monotonic: bool,
}

WRITE_COMPRESSIONS :: [?]archive.Method{.Store, .Deflate, .BZip2, .LZ4, .LZMA, .XZ}

@(test)
test_write_round_trip :: proc(t: ^testing.T) {
	entries := write_entries(t)
	defer delete(entries)
	for compression in WRITE_COMPRESSIONS {
		for source in Write_Source {
			out := strings.builder_make()
			defer strings.builder_destroy(&out)
			if !write_archive(t, &out, entries[:], {compression = compression}, source) {
				continue
			}
			data := out.buf[:]
			testing.expectf(t, compression != .Store || len(data) % (20 * 512) == 0, "%v: %d bytes, not whole records", compression, len(data))
			check_written(t, data, entries[:], false, compression, source)
		}
	}
}

@(test)
test_write_deterministic :: proc(t: ^testing.T) {
	entries := write_entries(t)
	defer delete(entries)
	first, second := strings.builder_make(), strings.builder_make()
	defer strings.builder_destroy(&first)
	defer strings.builder_destroy(&second)
	write_archive(t, &first, entries[:], {deterministic = true}, .Bytes)
	for &e in entries {
		e.info.modification_time = time.unix(1_234_567_890, 123)
		e.info.uid  = 4242
		e.info.user = "someone"
	}
	write_archive(t, &second, entries[:], {deterministic = true}, .Bytes)
	testing.expect(t, bytes.equal(first.buf[:], second.buf[:]), "deterministic output differs")
	check_written(t, first.buf[:], entries[:], true, .Store, .Bytes)

	base, dir_err := os.make_directory_temp("", "odin_tar_write_*", context.temp_allocator)
	if dir_err == .Unsupported {
		return
	}
	if !testing.expect_value(t, dir_err, nil) {
		return
	}
	defer os.remove_all(base)
	sub, _ := os.join_path({base, "sub"}, context.temp_allocator)
	testing.expect_value(t, os.make_directory(sub), nil)
	for name in ([?]string{"b.txt", "a.txt", "sub/c.txt"}) {
		path, _ := os.join_path({base, name}, context.temp_allocator)
		testing.expect_value(t, os.write_entire_file(path, transmute([]u8)name), nil)
	}
	walks: [2]strings.Builder
	for &walk in walks {
		walk = strings.builder_make()
		tw: tar.Writer
		if !testing.expect_value(t, tar.create(&tw, strings.to_writer(&walk), {deterministic = true}), nil) {
			continue
		}
		testing.expect_value(t, tar.write_directory(&tw, base, "root"), nil)
		testing.expect_value(t, tar.commit(&tw), nil)
		tar.close(&tw)
	}
	defer for &walk in walks {
		strings.builder_destroy(&walk)
	}
	testing.expect(t, bytes.equal(walks[0].buf[:], walks[1].buf[:]), "deterministic walks differ")

	made, _ := os.join_path({base, "made.tar"}, context.temp_allocator)
	for no_sync in ([?]bool{false, true}) {
		tw: tar.Writer
		if !testing.expect_value(t, tar.create(&tw, made, {no_sync = no_sync}), nil) {
			continue
		}
		testing.expect_value(t, tar.write_entry(&tw, "a.txt", []u8{'a'}), nil)
		testing.expect_value(t, tar.commit(&tw), nil)
		tar.close(&tw)
		made_reader: tar.Reader
		if testing.expect_value(t, tar.open(&made_reader, made), nil) {
			made_it := tar.iterator_create(&made_reader)
			count   := 0
			for _ in tar.iterate(&made_it) {
				count += 1
			}
			tar.iterator_destroy(&made_it)
			tar.close(&made_reader)
			testing.expectf(t, count == 1, "no_sync %v: %d members at a path", no_sync, count)
		}
	}

	r: tar.Reader
	if !testing.expect_value(t, tar.open(&r, walks[0].buf[:]), nil) {
		return
	}
	defer tar.close(&r)
	it := tar.iterator_create(&r)
	defer tar.iterator_destroy(&it)
	names: [dynamic]string
	defer delete(names)
	for fi in tar.iterate(&it) {
		append(&names, strings.clone(fi.path, context.temp_allocator))
	}
	want := [?]string{"root", "root/a.txt", "root/b.txt", "root/sub", "root/sub/c.txt"}
	testing.expectf(t, len(names) == len(want), "walk: %v", names[:])
	for name, i in names {
		if i < len(want) {
			testing.expectf(t, name == want[i], "walk %d: %q, want %q", i, name, want[i])
		}
	}
}

@(test)
test_write_errors :: proc(t: ^testing.T) {
	out := strings.builder_make()
	defer strings.builder_destroy(&out)
	w := strings.to_writer(&out)

	tw: tar.Writer
	testing.expect_value(t, tar.create(&tw, w, {compression = .LZMA2}), archive.Error(archive.General_Error.Unsupported_Method))
	testing.expect_value(t, tar.create(&tw, w, {compression = .LZMA, level = 10}), archive.Error(archive.General_Error.Incompatible_Options))
	testing.expect_value(t, tar.create(&tw, w, {compression = .XZ, level = -1}), archive.Error(archive.General_Error.Incompatible_Options))
	testing.expect_value(t, tar.create(&tw, w, {compression = .XZ, options = {max_memory = 1024}}), archive.Error(compress.Error(compress.General_Error.Memory_Limit_Exceeded)))
	testing.expect_value(t, len(out.buf), 0)
	testing.expect_value(t, tar.create(&tw, w, {compression = .BZip2, level = 0}), archive.Error(archive.General_Error.Incompatible_Options))
	testing.expect_value(t, tar.create(&tw, w, {level = 1}), archive.Error(archive.General_Error.Incompatible_Options))

	if !testing.expect_value(t, tar.create(&tw, w, {options = {max_memory = 100}}), nil) {
		return
	}
	defer tar.close(&tw)
	testing.expect_value(t, tar.write_entry(&tw, "../escape", []u8{1}), archive.Error(archive.General_Error.Unsafe_Path))
	testing.expect_value(t, tar.write_entry(&tw, "/", []u8{1}), archive.Error(archive.Tar_Error.Invalid_Name))
	link: archive.File_Info
	link.path = "link"
	link.type = .Symlink
	testing.expect_value(t, tar.write_entry(&tw, link), archive.Error(archive.General_Error.Incompatible_Options))

	big := make([]u8, 200)
	defer delete(big)
	unsized := Unsized{data = big}
	testing.expect_value(t, tar.write_entry(&tw, "big", unsized_reader(&unsized)), archive.Error(compress.Error(compress.General_Error.Memory_Limit_Exceeded)))
	testing.expect_value(t, len(out.buf), 0)

	testing.expect_value(t, tar.write_entry(&tw, "ok", []u8{1, 2, 3}), nil)

	short: archive.File_Info
	short.path = "short"
	short.type = .Regular
	short.size = 10
	unsized = Unsized{data = big[:4]}
	testing.expect_value(t, tar.write_entry(&tw, short, unsized_reader(&unsized)), archive.Error(archive.Tar_Error.Size_Mismatch))
	testing.expect_value(t, tar.write_entry(&tw, "after", []u8{1}), archive.Error(archive.Tar_Error.Size_Mismatch))

	long_tw: tar.Writer
	long_out := strings.builder_make()
	defer strings.builder_destroy(&long_out)
	if testing.expect_value(t, tar.create(&long_tw, strings.to_writer(&long_out)), nil) {
		short.size = 2
		unsized = Unsized{data = big[:4]}
		testing.expect_value(t, tar.write_entry(&long_tw, short, unsized_reader(&unsized)), archive.Error(archive.Tar_Error.Size_Mismatch))
		tar.close(&long_tw)
	}
}

@(test)
test_write_read_hiccups :: proc(t: ^testing.T) {
	text := "Empty reads between every chunk of this member."
	for hiccups in ([?]int{0, 3, 100, 101, max(int)}) {
		for sized in ([2]bool{false, true}) {
			out := strings.builder_make()
			defer strings.builder_destroy(&out)
			tw: tar.Writer
			if !testing.expect_value(t, tar.create(&tw, strings.to_writer(&out)), nil) {
				continue
			}
			fi := archive.File_Info{path = "a.txt", type = .Regular, size = i64(len(text)) if sized else -1}
			src := Unsized{data = transmute([]u8)text, hiccups = hiccups}
			err := tar.write_entry(&tw, fi, unsized_reader(&src))
			if hiccups > 100 {
				testing.expectf(t, err == io.Error.No_Progress, "%d hiccups, sized %v: %v", hiccups, sized, err)
				tar.close(&tw)
				continue
			}
			ok := testing.expectf(t, err == nil, "%d hiccups, sized %v: %v", hiccups, sized, err)
			ok  = ok && testing.expect_value(t, tar.commit(&tw), nil)
			tar.close(&tw)
			if !ok {
				continue
			}
			r: tar.Reader
			if !testing.expect_value(t, tar.open(&r, out.buf[:]), nil) {
				continue
			}
			it := tar.iterator_create(&r)
			count := 0
			for _ in tar.iterate(&it) {
				got := strings.builder_make()
				testing.expect_value(t, tar.extract_current(&it, strings.to_writer(&got)), nil)
				testing.expectf(t, strings.to_string(got) == text, "%d hiccups, sized %v: %q", hiccups, sized, strings.to_string(got))
				strings.builder_destroy(&got)
				count += 1
			}
			testing.expect_value(t, count, 1)
			tar.iterator_destroy(&it)
			tar.close(&r)
		}
	}
}

@(test)
test_write_progress :: proc(t: ^testing.T) {
	data := make([]u8, 10_000)
	defer delete(data)
	for &b, i in data {
		b = u8(i * 7)
	}
	for cancel in ([2]int{0, 3}) {
		calls := Write_Calls{cancel_at = cancel, monotonic = true}
		out := strings.builder_make()
		defer strings.builder_destroy(&out)
		tw: tar.Writer
		options := tar.Writer_Options{options = {progress = write_progress, progress_data = &calls, progress_interval = 1000}}
		if !testing.expect_value(t, tar.create(&tw, strings.to_writer(&out), options), nil) {
			continue
		}
		err := tar.write_entry(&tw, "a", data)
		if cancel == 0 {
			testing.expect_value(t, err, nil)
			testing.expect_value(t, tar.write_entry(&tw, "b", data[:10]), nil)
			testing.expect_value(t, tar.commit(&tw), nil)
			testing.expectf(t, calls.calls == 11, "%d calls", calls.calls)
			testing.expect_value(t, calls.last_in, 10_010)
		} else {
			testing.expect_value(t, err, archive.Error(compress.Error(compress.General_Error.Canceled)))
			testing.expect_value(t, calls.calls, cancel)
		}
		testing.expect(t, calls.monotonic, "progress went backwards")
		tar.close(&tw)
	}
}

@(test)
test_write_gnu :: proc(t: ^testing.T) {
	entries := write_entries(t)
	defer delete(entries)
	for &e in entries {
		if len(e.info.group) > 32 {
			e.info.group = e.info.group[:32]
		}
	}
	want := make([]Written, len(entries), context.temp_allocator)
	copy(want, entries[:])
	for &e in want {
		e.info.modification_time = time.unix(time.to_unix_seconds(e.info.modification_time), 0)
	}
	for compression in WRITE_COMPRESSIONS {
		for source in Write_Source {
			out := strings.builder_make()
			defer strings.builder_destroy(&out)
			if !write_archive(t, &out, entries[:], {compression = compression, format = .GNU}, source) {
				continue
			}
			check_written(t, out.buf[:], want, false, compression, source)
			if compression == .Store {
				flags := raw_typeflags(out.buf[:])
				testing.expectf(t, slice.count(flags.typeflags[:], 'L') == 2 && slice.count(flags.typeflags[:], 'K') == 1, "%v: typeflags %s", source, string(flags.typeflags[:]))
				testing.expectf(t, slice.count(flags.typeflags[:], 'x') == 0 && flags.all_gnu, "%v: not pure GNU: %s", source, string(flags.typeflags[:]))
			}
		}
	}

	first, second := strings.builder_make(), strings.builder_make()
	defer strings.builder_destroy(&first)
	defer strings.builder_destroy(&second)
	write_archive(t, &first, entries[:], {deterministic = true, format = .GNU}, .Bytes)
	for &e in entries {
		e.info.modification_time = time.unix(1_234_567_890, 123)
		e.info.access_time       = time.unix(1_234_567_890, 0)
		e.info.uid  = 4242
		e.info.user = "someone"
	}
	write_archive(t, &second, entries[:], {deterministic = true, format = .GNU}, .Bytes)
	testing.expect(t, bytes.equal(first.buf[:], second.buf[:]), "deterministic GNU output differs")
	check_written(t, first.buf[:], entries[:], true, .Store, .Bytes)
}

@(test)
test_write_gnu_fields :: proc(t: ^testing.T) {
	Case :: struct {
		label:  string,
		info:   archive.File_Info,
		offset: int,
		field:  []u8,
		err:    archive.Error,
	}
	base := archive.File_Info{path = "f", type = .Regular}
	with :: proc(fi: archive.File_Info, uid: i64 = 0, user := "", mtime := i64(0), atime := i64(0), device := [2]u32{}, type := archive.Entry_Type.Regular) -> archive.File_Info {
		fi := fi
		fi.uid               = uid
		fi.user              = user
		fi.modification_time = time.unix(0, mtime)
		fi.access_time       = time.unix(0, atime)
		fi.device            = device
		fi.type              = type
		return fi
	}
	I :: archive.General_Error.Incompatible_Options
	cases := [?]Case{
		{"octal uid",       with(base, uid = 2_097_151),           108, {'7', '7', '7', '7', '7', '7', '7', 0}, nil},
		{"base-256 uid",    with(base, uid = 3_000_000),           108, {0x80, 0, 0, 0, 0, 0x2d, 0xc6, 0xc0}, nil},
		{"largest uid",     with(base, uid = 1 << 56 - 1),         108, {0x80, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff}, nil},
		{"uid too large",   with(base, uid = 1 << 56),             0,   nil, I},
		{"negative mtime",  with(base, mtime = -1),                136, {0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff}, nil},
		{"floored mtime",   with(base, mtime = 1_999_999_999),     136, {'0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '1', 0}, nil},
		{"large mtime",     with(base, mtime = 8_589_934_592_000_000_000),     136, {0x80, 0, 0, 0, 0, 0, 0, 0x02, 0, 0, 0, 0}, nil},
		{"atime",           with(base, atime = 1_794_156_220e9),   345, {'1', '5', '2', '7', '4', '1', '2', '3', '2', '7', '4', 0}, nil},
		{"no atime",        base,                                  345, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, nil},
		{"device",          with(base, device = {max(u32), 0x1234}, type = .Block_Device), 329, {0x80, 0, 0, 0, 0xff, 0xff, 0xff, 0xff, '0', '0', '1', '1', '0', '6', '4', 0}, nil},
		{"user 32 bytes",   with(base, user = "uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu"),  265, {'u', 'u'}, nil},
		{"user 33 bytes",   with(base, user = "uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu"), 0,   nil, I},
		{"user with NUL",   with(base, user = "a\x00b"),           0,   nil, I},
		{"magic",           base,                                  257, {'u', 's', 't', 'a', 'r', ' ', ' ', 0}, nil},
	}
	for c in cases {
		out := strings.builder_make()
		defer strings.builder_destroy(&out)
		tw: tar.Writer
		if !testing.expect_value(t, tar.create(&tw, strings.to_writer(&out), {format = .GNU}), nil) {
			continue
		}
		err := tar.write_entry(&tw, c.info, nil)
		testing.expectf(t, err == c.err, "%s: %v, want %v", c.label, err, c.err)
		testing.expect_value(t, tar.write_entry(&tw, "next", []u8{'n'}), nil)
		testing.expect_value(t, tar.commit(&tw), nil)
		tar.close(&tw)
		data := out.buf[:]
		if c.err == nil {
			testing.expectf(t, bytes.equal(data[c.offset:][:len(c.field)], c.field), "%s: field % x", c.label, data[c.offset:][:len(c.field)])
		}

		r: tar.Reader
		if !testing.expect_value(t, tar.open(&r, data), nil) {
			continue
		}
		it := tar.iterator_create(&r)
		count := 0
		for fi in tar.iterate(&it) {
			count += 1
			if c.err != nil || count > 1 {
				continue
			}
			testing.expectf(t, fi.uid == c.info.uid && fi.user == c.info.user && fi.device == c.info.device, "%s: read back %d %q %v", c.label, fi.uid, fi.user, fi.device)
			testing.expectf(t, time.to_unix_seconds(fi.modification_time) == floor_seconds(c.info.modification_time), "%s: mtime %v", c.label, fi.modification_time)
			testing.expectf(t, time.to_unix_seconds(fi.access_time) == floor_seconds(c.info.access_time), "%s: atime %v", c.label, fi.access_time)
		}
		_, it_err := tar.iterator_error(&it)
		testing.expectf(t, it_err == nil && count == (1 if c.err != nil else 2), "%s: %d members, %v", c.label, count, it_err)
		tar.iterator_destroy(&it)
		tar.close(&r)
	}

	Name_Case :: struct {
		name:  string,
		link:  string,
		flags: string,
	}
	n100 := strings.repeat("n", 100, context.temp_allocator)
	n101 := strings.repeat("n", 101, context.temp_allocator)
	names := [?]Name_Case{
		{n100, "",   "0"},
		{n101, "",   "L0"},
		{"l",  n100, "2"},
		{"l",  n101, "K2"},
		{n101, n101, "LK2"},
	}
	for c in names {
		out := strings.builder_make()
		defer strings.builder_destroy(&out)
		tw: tar.Writer
		testing.expect_value(t, tar.create(&tw, strings.to_writer(&out), {format = .GNU}), nil)
		fi := archive.File_Info{path = c.name, type = .Regular}
		if c.link != "" {
			fi.type        = .Symlink
			fi.link_target = c.link
		}
		testing.expect_value(t, tar.write_entry(&tw, fi, nil), nil)
		testing.expect_value(t, tar.commit(&tw), nil)
		tar.close(&tw)
		flags := raw_typeflags(out.buf[:])
		testing.expectf(t, string(flags.typeflags[:]) == c.flags && flags.all_gnu, "%d/%d: %s", len(c.name), len(c.link), string(flags.typeflags[:]))
		data := out.buf[:]
		if c.flags[0] == 'L' || c.flags[0] == 'K' {
			value := c.name if c.flags[0] == 'L' else c.link
			testing.expect_value(t, string(data[0:13]), "././@LongLink")
			testing.expectf(t, string(data[512:][:len(value) + 1]) == strings.concatenate({value, "\x00"}, context.temp_allocator), "%s: long data", c.flags)
		}
		r: tar.Reader
		testing.expect_value(t, tar.open(&r, data), nil)
		it := tar.iterator_create(&r)
		fi_read, _, ok := tar.iterate(&it)
		testing.expectf(t, ok && fi_read.path == c.name && fi_read.link_target == c.link, "%s: read back %q %q", c.flags, fi_read.path, fi_read.link_target)
		tar.iterator_destroy(&it)
		tar.close(&r)
	}
}

@(test)
test_write_ustar :: proc(t: ^testing.T) {
	entries := write_entries(t)
	defer delete(entries)
	fits: [dynamic]Written
	defer delete(fits)
	rejected := 0
	out := strings.builder_make()
	defer strings.builder_destroy(&out)
	tw: tar.Writer
	if !testing.expect_value(t, tar.create(&tw, strings.to_writer(&out), {format = .Ustar}), nil) {
		return
	}
	for e in entries {
		data: tar.Entry_Data
		if e.info.type == .Regular {
			data = transmute([]u8)e.data
		}
		err := tar.write_entry(&tw, e.info, data)
		if err == nil {
			kept := e
			kept.info.modification_time = time.unix(time.to_unix_seconds(e.info.modification_time), 0)
			append(&fits, kept)
			continue
		}
		testing.expectf(t, err == archive.General_Error.Incompatible_Options, "%s: %v", e.info.path, err)
		rejected += 1
	}

	extra := [?]archive.File_Info{
		{path = "late.txt", type = .Regular, modification_time = time.unix(1 << 33, 0)},
		{path = "big.bin",  type = .Regular, size = 1 << 33},
		{path = "dev",      type = .Character_Device, device = {1 << 21, 0}},
	}
	big := Unsized{}
	for fi in extra {
		data: tar.Entry_Data
		if fi.size > 0 {
			data = unsized_reader(&big)
		}
		testing.expectf(t, tar.write_entry(&tw, fi, data) == archive.General_Error.Incompatible_Options, "%s accepted", fi.path)
	}
	testing.expect_value(t, tar.commit(&tw), nil)
	tar.close(&tw)

	testing.expect_value(t, rejected, 5)
	testing.expect_value(t, len(fits), len(entries) - 5)
	check_written(t, out.buf[:], fits[:], false, .Store, .Bytes)
	flags := raw_typeflags(out.buf[:])
	testing.expectf(t, slice.count(flags.typeflags[:], 'x') == 0 && slice.count(flags.typeflags[:], 'g') == 0 && !flags.all_gnu, "ustar typeflags %s", string(flags.typeflags[:]))
}

@(test)
test_write_format_errors :: proc(t: ^testing.T) {
	out := strings.builder_make()
	defer strings.builder_destroy(&out)
	tw: tar.Writer
	testing.expect_value(t, tar.create(&tw, strings.to_writer(&out), {format = tar.Write_Format(3)}), archive.Error(archive.General_Error.Incompatible_Options))

	for format in tar.Write_Format {
		if !testing.expect_value(t, tar.create(&tw, strings.to_writer(&out), {format = format}), nil) {
			continue
		}
		link := archive.File_Info{path = "link", type = .Symlink, link_target = "a\x00b"}
		testing.expect_value(t, tar.write_entry(&tw, link), archive.Error(archive.Tar_Error.Invalid_Name))
		owner := archive.File_Info{path = "owner", type = .Regular, user = "a\x00b"}
		testing.expect_value(t, tar.write_entry(&tw, owner), archive.Error(archive.General_Error.Incompatible_Options))
		owner.user  = ""
		owner.group = "a\x00b"
		testing.expect_value(t, tar.write_entry(&tw, owner), archive.Error(archive.General_Error.Incompatible_Options))
		testing.expect_value(t, tar.write_entry(&tw, "ok", []u8{'k'}), nil)
		testing.expect_value(t, tar.commit(&tw), nil)
		tar.close(&tw)
		strings.builder_reset(&out)
	}
}

@(test)
test_write_hdrcharset :: proc(t: ^testing.T) {
	Case :: struct {
		info:   archive.File_Info,
		binary: bool,
	}
	cases := [?]Case{
		{{path = "bin-\xe5\x90\xff.txt", type = .Regular}, true},
		{{path = "日本.txt", type = .Regular}, false},
		{{path = "link", type = .Symlink, link_target = "\xff"}, true},
		{{path = "link", type = .Symlink, link_target = "日本"}, false},
		{{path = "owned.txt", type = .Regular, user = "\xc3"}, true},
		{{path = "owned.txt", type = .Regular, group = "Jérôme"}, false},
	}
	for c, i in cases {
		out := strings.builder_make()
		defer strings.builder_destroy(&out)
		tw: tar.Writer
		testing.expect_value(t, tar.create(&tw, strings.to_writer(&out), {}), nil)
		testing.expect_value(t, tar.write_entry(&tw, c.info), nil)
		testing.expect_value(t, tar.commit(&tw), nil)
		tar.close(&tw)
		data := strings.to_string(out)
		testing.expectf(t, strings.has_prefix(data[512:], "21 hdrcharset=BINARY\n") == c.binary, "case %d: hdrcharset record", i)
		testing.expectf(t, strings.count(data, "hdrcharset") == int(c.binary), "case %d: hdrcharset count", i)

		r: tar.Reader
		testing.expect_value(t, tar.open(&r, transmute([]u8)data), nil)
		it := tar.iterator_create(&r)
		fi, _, ok := tar.iterate(&it)
		if testing.expectf(t, ok, "case %d: no member", i) {
			testing.expectf(t, fi.path == c.info.path && fi.link_target == c.info.link_target, "case %d: %q %q", i, fi.path, fi.link_target)
			testing.expectf(t, fi.user == c.info.user && fi.group == c.info.group, "case %d: %q %q", i, fi.user, fi.group)
		}
		tar.iterator_destroy(&it)
		tar.close(&r)

		strings.builder_reset(&out)
		testing.expect_value(t, tar.create(&tw, strings.to_writer(&out), {format = .Ustar}), nil)
		testing.expectf(t, tar.write_entry(&tw, c.info) == archive.General_Error.Incompatible_Options, "case %d: ustar accepted it", i)
		tar.close(&tw)
	}
}

Typeflags :: struct {
	typeflags: [dynamic]u8,
	all_gnu:   bool,
}

raw_typeflags :: proc(data: []u8) -> (flags: Typeflags) {
	flags.typeflags = make([dynamic]u8, context.temp_allocator)
	flags.all_gnu   = true
	pos := 0
	for pos + 512 <= len(data) {
		h := data[pos:][:512]
		if slice.all_of(h, 0) {
			break
		}
		append(&flags.typeflags, h[156])
		if string(h[257:265]) != "ustar  \x00" {
			flags.all_gnu = false
		}
		size := 0
		for c in h[124:136] {
			if c >= '0' && c <= '7' {
				size = size * 8 + int(c - '0')
			}
		}
		pos += 512 + (size + 511) / 512 * 512
	}
	return
}

floor_seconds :: proc(stamp: time.Time) -> i64 {
	nanos   := time.to_unix_nanoseconds(stamp)
	seconds := nanos / 1e9
	if nanos % 1e9 < 0 {
		seconds -= 1
	}
	return seconds
}

write_entries :: proc(t: ^testing.T) -> (entries: [dynamic]Written) {
	stamp := time.unix(1_700_000_000, 0)
	add :: proc(entries: ^[dynamic]Written, path: string, type: archive.Entry_Type, data: string, stamp: time.Time, mode: u32 = 0o644) -> ^Written {
		fi: archive.File_Info
		fi.path              = path
		fi.type              = type
		fi.size              = i64(len(data))
		fi.unix_mode         = mode
		fi.modification_time = stamp
		fi.uid               = 1000
		fi.gid               = 100
		fi.user              = "odin"
		fi.group             = "users"
		append(entries, Written{fi, data})
		return &entries[len(entries) - 1]
	}
	long_dir  := strings.repeat("d", 120, context.temp_allocator)
	long_name := strings.concatenate({long_dir, "/", strings.repeat("f", 90, context.temp_allocator)}, context.temp_allocator)
	huge_name := strings.repeat("x/", 200, context.temp_allocator)
	huge_name  = strings.concatenate({huge_name, "end.txt"}, context.temp_allocator)
	text      := strings.repeat("Odin tar writer. ", 300, context.temp_allocator)

	add(&entries, "dir", .Directory, "", stamp, 0o755)
	add(&entries, "dir/small.txt", .Regular, "hello", stamp)
	add(&entries, "dir/empty.txt", .Regular, "", stamp)
	add(&entries, "dir/block.bin", .Regular, strings.repeat("B", 512, context.temp_allocator), stamp)
	add(&entries, "dir/text.txt", .Regular, text, stamp, 0o600)
	add(&entries, long_name, .Regular, "split into prefix and name", stamp)
	add(&entries, huge_name, .Regular, "pax path", stamp)
	add(&entries, "dir/Ünïcödé ε 日本.txt", .Regular, "non-ASCII", stamp)
	add(&entries, "dir/frac.txt", .Regular, "fraction", time.unix(1_700_000_000, 250_000_000))
	add(&entries, "dir/old.txt", .Regular, "before 1970", time.unix(-86_400 * 365, 0))
	e := add(&entries, "dir/ids.txt", .Regular, "ids", stamp)
	e.info.uid   = 3_000_000
	e.info.gid   = 2_500_000
	e.info.user  = "ünïcödé"
	e.info.group = strings.repeat("g", 40, context.temp_allocator)
	e = add(&entries, "dir/link", .Symlink, "", stamp, 0o777)
	e.info.link_target = "small.txt"
	e = add(&entries, "dir/long-link", .Symlink, "", stamp, 0o777)
	e.info.link_target = huge_name
	e = add(&entries, "dir/hard", .Hard_Link, "", stamp)
	e.info.link_target = "dir/small.txt"
	add(&entries, "dir/fifo", .Named_Pipe, "", stamp)
	e = add(&entries, "dir/null", .Character_Device, "", stamp, 0o666)
	e.info.device = {1, 3}
	return
}

write_archive :: proc(t: ^testing.T, out: ^strings.Builder, entries: []Written, options: tar.Writer_Options, source: Write_Source, loc := #caller_location) -> (ok: bool) {
	tw: tar.Writer
	if !testing.expect_value(t, tar.create(&tw, strings.to_writer(out), options), nil, loc) {
		return false
	}
	defer tar.close(&tw)
	for e in entries {
		data: tar.Entry_Data
		readers: [2]bytes.Reader
		unsized: Unsized
		if e.info.type == .Regular {
			switch source {
			case .Bytes:
				data = transmute([]u8)e.data
			case .Sized_Reader:
				data = bytes.reader_init(&readers[0], transmute([]u8)e.data)
			case .Unsized_Reader:
				unsized.data = transmute([]u8)e.data
				data = unsized_reader(&unsized)
			}
		}
		fi := e.info
		if source == .Unsized_Reader {
			fi.size = -1
		}
		if !testing.expectf(t, tar.write_entry(&tw, fi, data) == nil, "%v/%v: write %s", options.compression, source, e.info.path, loc = loc) {
			return false
		}
	}
	return testing.expect_value(t, tar.commit(&tw), nil, loc)
}

check_written :: proc(t: ^testing.T, data: []u8, entries: []Written, deterministic: bool, compression: archive.Method, source: Write_Source, loc := #caller_location) {
	r: tar.Reader
	if !testing.expectf(t, tar.open(&r, data) == nil, "%v/%v: open", compression, source, loc = loc) {
		return
	}
	defer tar.close(&r)
	testing.expectf(t, r.compression == (.Store if compression == .Unknown else compression), "%v: read as %v", compression, r.compression, loc = loc)
	it := tar.iterator_create(&r)
	defer tar.iterator_destroy(&it)
	count := 0
	for fi in tar.iterate(&it) {
		if !testing.expectf(t, count < len(entries), "%v/%v: extra member %s", compression, source, fi.path, loc = loc) {
			break
		}
		want := entries[count].info
		label := want.path
		count += 1
		want_path := want.path
		testing.expectf(t, fi.path == want_path, "%v/%v: path %q, want %q", compression, source, fi.path, want_path, loc = loc)
		testing.expectf(t, fi.type == want.type, "%s: type %v", label, fi.type, loc = loc)
		testing.expectf(t, fi.unix_mode & 0o7777 == want.unix_mode, "%s: mode %o", label, fi.unix_mode, loc = loc)
		testing.expectf(t, fi.link_target == want.link_target, "%s: link %q", label, fi.link_target, loc = loc)
		if deterministic {
			testing.expectf(t, fi.uid == 0 && fi.gid == 0 && fi.user == "" && fi.group == "", "%s: owner", label, loc = loc)
			testing.expectf(t, time.time_to_unix_nano(fi.modification_time) == 0, "%s: mtime %v", label, fi.modification_time, loc = loc)
		} else {
			testing.expectf(t, fi.uid == want.uid && fi.gid == want.gid, "%s: ids %d %d", label, fi.uid, fi.gid, loc = loc)
			testing.expectf(t, fi.user == want.user && fi.group == want.group, "%s: owner %q %q", label, fi.user, fi.group, loc = loc)
			testing.expectf(t, fi.modification_time == want.modification_time, "%s: mtime %v, want %v", label, fi.modification_time, want.modification_time, loc = loc)
		}
		if want.type == .Character_Device {
			testing.expectf(t, fi.device == want.device, "%s: device %v", label, fi.device, loc = loc)
		}
		if want.type == .Regular {
			got := strings.builder_make()
			err := tar.extract_current(&it, strings.to_writer(&got))
			testing.expectf(t, err == nil && strings.to_string(got) == entries[count - 1].data, "%v/%v %s: data %v", compression, source, label, err, loc = loc)
			strings.builder_destroy(&got)
		}
	}
	_, err := tar.iterator_error(&it)
	testing.expectf(t, err == nil && count == len(entries), "%v/%v: %d members, %v", compression, source, count, err, loc = loc)
}

unsized_reader :: proc(u: ^Unsized) -> (r: io.Reader) {
	r.data      = u
	r.procedure = unsized_proc
	return
}

unsized_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	u := (^Unsized)(stream_data)
	#partial switch mode {
	case .Read:
		if u.pending < u.hiccups {
			u.pending += 1
			return 0, nil
		}
		u.pending = 0
		if u.pos >= len(u.data) {
			return 0, .EOF
		}
		got := copy(p[:min(len(p), 7)], u.data[u.pos:])
		u.pos += got
		return i64(got), nil
	case .Query:
		return io.query_utility({.Read, .Query})
	}
	return 0, .Unsupported
}

write_progress :: proc(progress: compress.Progress, user_data: rawptr) -> (cancel: bool) {
	calls := (^Write_Calls)(user_data)
	calls.calls += 1
	if progress.archive_in < calls.last_in || progress.bytes_in > progress.total_in {
		calls.monotonic = false
	}
	calls.last_in = progress.archive_in
	return calls.cancel_at != 0 && calls.calls >= calls.cancel_at
}
