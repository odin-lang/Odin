package test_core_archive_tar

import "core:archive"
import "core:archive/tar"
import "core:bytes"
import "core:compress"
import "core:io"
import "core:os"
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
	data: []u8,
	pos:  int,
}

Write_Calls :: struct {
	calls:     int,
	last_in:   i64,
	cancel_at: int,
	monotonic: bool,
}

WRITE_COMPRESSIONS :: [?]archive.Method{.Store, .Deflate, .BZip2, .LZ4}

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
	testing.expect_value(t, tar.create(&tw, w, {compression = .LZMA}), archive.Error(archive.General_Error.Unsupported_Method))
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
