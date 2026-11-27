package test_core_archive_zip

import "core:archive"
import "core:archive/zip"
import "core:bytes"
import "core:compress"
import "core:compress/lzma"
import "core:compress/ppmd"
import "core:fmt"
import "core:io"
import "core:mem"
import "core:os"
import "core:strings"
import "core:testing"
import "core:time"
import "core:time/timezone"

WRITE_TEXT :: "The central directory lists every member, and each local header repeats its name and sizes.\n"

WRITE_METHODS :: [?]archive.Method{.Store, .Deflate, .Deflate64, .BZip2, .LZMA, .PPMd_I, .XZ}

Output_Mode :: enum u8 {
	Seekable,
	Streaming,
}

Memory_File :: struct {
	data:     [dynamic]u8,
	position: int,
	seekable: bool,
}

Zero_Reader :: struct {
	remaining: i64,
}

Hiccup_Reader :: struct {
	data:    []u8,
	pos:     int,
	hiccups: int,
	pending: int,
}

Write_Expect :: struct {
	name:       string,
	type:       archive.Entry_Type,
	content:    []u8,
	method:     archive.Method,
	link:       string,
	comment:    string,
	utf8:       bool,
	descriptor: bool,
}

Progress_Log :: struct {
	calls:     int,
	last_in:   i64,
	last_out:  i64,
	member:    int,
	cancel_at: int,
}

@(test)
test_write_methods :: proc(t: ^testing.T) {
	for method in WRITE_METHODS {
		for mode in Output_Mode {
			write_and_check(t, method, mode)
		}
	}
}

@(test)
test_write_options :: proc(t: ^testing.T) {
	text := write_text()
	m := Memory_File{seekable = true}
	defer delete(m.data)
	zw: zip.Writer
	if !testing.expect_value(t, zip.create(&zw, memory_stream(&m), zip.Writer_Options{method = .BZip2, level = 1}), nil) {
		return
	}
	defer zip.close(&zw)
	testing.expect_value(t, zip.write_entry(&zw, "default.txt", text), nil)
	testing.expect_value(t, zip.write_entry(&zw, "lzma.txt", text, zip.Entry_Options{method = .LZMA}), nil)
	testing.expect_value(t, zip.write_entry(&zw, "level.txt", text, zip.Entry_Options{level = 9}), nil)
	testing.expect_value(t, zip.write_entry(&zw, "fastest.txt", text, zip.Entry_Options{method = .Deflate, level = 1}), nil)
	testing.expect_value(t, zip.write_entry(&zw, "fast.txt", text, zip.Entry_Options{method = .Deflate, level = 2}), nil)
	testing.expect_value(t, zip.write_entry(&zw, "normal.txt", text, zip.Entry_Options{method = .Deflate}), nil)
	testing.expect_value(t, zip.write_entry(&zw, "best.txt", text, zip.Entry_Options{method = .Deflate, level = 99}), nil)
	testing.expect_value(t, zip.write_entry(&zw, "store.txt", text, zip.Entry_Options{method = .Store}), nil)
	testing.expect_value(t, zip.commit(&zw), nil)

	Option_Case :: struct {
		name:   string,
		method: zip.Method,
		flags:  zip.Flags,
		head:   string,
	}
	cases := [?]Option_Case{
		{"default.txt", .BZip2,   {},                    "BZh1"},
		{"lzma.txt",    .LZMA,    {.Option_1},           ""},
		{"level.txt",   .BZip2,   {},                    "BZh9"},
		{"fastest.txt", .Deflate, {.Option_1, .Option_2}, ""},
		{"fast.txt",    .Deflate, {.Option_2},           ""},
		{"normal.txt",  .Deflate, {},                    ""},
		{"best.txt",    .Deflate, {.Option_1},           ""},
		{"store.txt",   .Store,   {},                    ""},
	}
	r: zip.Reader
	if !testing.expect_value(t, zip.open(&r, m.data[:]), nil) {
		return
	}
	defer zip.close(&r)
	it := zip.iterator_create(&r)
	defer zip.iterator_destroy(&it)
	for fi, index in zip.iterate(&it) {
		c := cases[index]
		entry := zip.current_entry(&it)
		testing.expectf(t, fi.path == c.name, "option %d: %q", index, fi.path)
		testing.expectf(t, entry.method == c.method, "%s: method %v", c.name, entry.method)
		testing.expectf(t, entry.flags == c.flags, "%s: flags %v", c.name, entry.flags)
		if c.head != "" {
			head := string(m.data[entry.data_offset:][:len(c.head)])
			testing.expectf(t, head == c.head, "%s: stream header %q", c.name, head)
		}
		content, err := extract_to_bytes(&it)
		testing.expectf(t, err == nil && bytes.equal(content[:], text), "%s: %v", c.name, err)
		delete(content)
	}
}

@(test)
test_write_end_markers :: proc(t: ^testing.T) {
	text := write_text()
	m := Memory_File{seekable = true}
	defer delete(m.data)
	zw: zip.Writer
	if !testing.expect_value(t, zip.create(&zw, memory_stream(&m)), nil) {
		return
	}
	defer zip.close(&zw)
	inner, inner_lzma: bytes.Reader
	bytes.reader_init(&inner, text)
	bytes.reader_init(&inner_lzma, text)
	unknown      := Non_Seekable{inner = bytes.reader_to_stream(&inner)}
	unknown_lzma := Non_Seekable{inner = bytes.reader_to_stream(&inner_lzma)}
	testing.expect_value(t, zip.write_entry(&zw, "ppmd.txt", text, zip.Entry_Options{method = .PPMd_I}), nil)
	testing.expect_value(t, zip.write_entry(&zw, archive.File_Info{path = "streamed.txt", size = -1}, non_seekable_stream(&unknown), zip.Entry_Options{method = .PPMd_I}), nil)
	testing.expect_value(t, zip.write_entry(&zw, "lzma.txt", text, zip.Entry_Options{method = .LZMA}), nil)
	testing.expect_value(t, zip.write_entry(&zw, archive.File_Info{path = "streamed_lzma.txt", size = -1}, non_seekable_stream(&unknown_lzma), zip.Entry_Options{method = .LZMA}), nil)
	testing.expect_value(t, zip.commit(&zw), nil)

	r: zip.Reader
	if !testing.expect_value(t, zip.open(&r, m.data[:]), nil) {
		return
	}
	defer zip.close(&r)
	it := zip.iterator_create(&r)
	defer zip.iterator_destroy(&it)
	for fi in zip.iterate(&it) {
		entry := zip.current_entry(&it)
		raw   := m.data[entry.data_offset:][:fi.compressed_size]
		out: [dynamic]u8
		#partial switch entry.method {
		case .PPMd:
			props, props_err := ppmd.decode_properties_zip(raw)
			testing.expect_value(t, props_err, nil)
			testing.expect_value(t, ppmd.decompress_from_bytes(&out, raw[ppmd.PROPERTIES_ZIP_SIZE:], props), nil)
		case .LZMA:
			testing.expectf(t, .Option_1 in entry.flags, "%s: EOS flag", fi.path)
			props, props_err := lzma.decode_properties(raw[4:][:lzma.PROPERTIES_SIZE])
			testing.expect_value(t, props_err, nil)
			testing.expect_value(t, lzma.decompress_raw_from_bytes(&out, raw[4 + lzma.PROPERTIES_SIZE:], props), nil)
		case:
			testing.expectf(t, false, "%s: method %v", fi.path, entry.method)
		}
		testing.expectf(t, bytes.equal(out[:], text), "%s: %d bytes up to the end marker", fi.path, len(out))
		delete(out)
	}
}

@(test)
test_write_read_hiccups :: proc(t: ^testing.T) {
	text := "Empty reads between every chunk of this member."
	for hiccups in ([?]int{0, 3, 100, 101, max(int)}) {
		for sized in ([2]bool{false, true}) {
			m := Memory_File{seekable = true}
			defer delete(m.data)
			zw: zip.Writer
			if !testing.expect_value(t, zip.create(&zw, memory_stream(&m)), nil) {
				continue
			}
			fi := archive.File_Info{path = "a.txt", type = .Regular, size = i64(len(text)) if sized else -1}
			src := Hiccup_Reader{data = transmute([]u8)text, hiccups = hiccups}
			err := zip.write_entry(&zw, fi, hiccup_reader(&src))
			if hiccups > 100 {
				testing.expectf(t, err == io.Error.No_Progress, "%d hiccups, sized %v: %v", hiccups, sized, err)
				zip.close(&zw)
				continue
			}
			ok := testing.expectf(t, err == nil, "%d hiccups, sized %v: %v", hiccups, sized, err)
			ok  = ok && testing.expect_value(t, zip.commit(&zw), nil)
			zip.close(&zw)
			if !ok {
				continue
			}
			r: zip.Reader
			if !testing.expect_value(t, zip.open(&r, m.data[:]), nil) {
				continue
			}
			it := zip.iterator_create(&r)
			count := 0
			for _ in zip.iterate(&it) {
				got := strings.builder_make()
				testing.expect_value(t, zip.extract_current(&it, strings.to_writer(&got)), nil)
				testing.expectf(t, strings.to_string(got) == text, "%d hiccups, sized %v: %q", hiccups, sized, strings.to_string(got))
				strings.builder_destroy(&got)
				count += 1
			}
			testing.expect_value(t, count, 1)
			zip.iterator_destroy(&it)
			zip.close(&r)
		}
	}
}

@(test)
test_write_errors :: proc(t: ^testing.T) {
	text := write_text()
	m := Memory_File{seekable = true}
	defer delete(m.data)
	zw: zip.Writer
	if !testing.expect_value(t, zip.create(&zw, memory_stream(&m)), nil) {
		return
	}
	defer zip.close(&zw)
	testing.expect_value(t, zip.write_entry(&zw, "", text), Zip_Error.Invalid_Name)
	testing.expect_value(t, zip.write_entry(&zw, "/", text), Zip_Error.Invalid_Name)
	testing.expect_value(t, zip.write_entry(&zw, "./", text), Zip_Error.Invalid_Name)
	testing.expect_value(t, zip.write_entry(&zw, "a\x00b", text), Zip_Error.Invalid_Name)
	testing.expect_value(t, zip.write_entry(&zw, "../x", text), archive.General_Error.Unsafe_Path)
	testing.expect_value(t, zip.write_entry(&zw, "a/../b", text), archive.General_Error.Unsafe_Path)
	long_name := strings.repeat("n", 0x10000, context.temp_allocator)
	testing.expect_value(t, zip.write_entry(&zw, long_name, text), Zip_Error.Field_Too_Long)
	testing.expect_value(t, zip.write_entry(&zw, "x", text, zip.Entry_Options{method = .Implode}), archive.General_Error.Unsupported_Method)
	testing.expect_value(t, zip.write_entry(&zw, "x", text, zip.Entry_Options{method = .PPMd_H}), archive.General_Error.Unsupported_Method)
	testing.expect_value(t, zip.write_entry(&zw, archive.File_Info{path = "p", type = .Named_Pipe}), archive.General_Error.Unsupported_Entry)
	testing.expect_value(t, zip.write_entry(&zw, archive.File_Info{path = "d", type = .Directory}, text), archive.General_Error.Incompatible_Options)
	testing.expect_value(t, zip.write_entry(&zw, archive.File_Info{path = "l", type = .Symlink}), archive.General_Error.Incompatible_Options)

	short: bytes.Reader
	bytes.reader_init(&short, text[:5])
	testing.expect_value(t, zip.write_entry(&zw, archive.File_Info{path = "short", size = 10}, bytes.reader_to_stream(&short)), Zip_Error.Size_Mismatch)
	long: bytes.Reader
	bytes.reader_init(&long, text)
	testing.expect_value(t, zip.write_entry(&zw, archive.File_Info{path = "long", size = 10}, bytes.reader_to_stream(&long)), Zip_Error.Size_Mismatch)
	testing.expect_value(t, zip.write_entry(&zw, "ok.txt", text), nil)

	huge: bytes.Reader
	bytes.reader_init(&huge, text[:5])
	testing.expect_value(t, zip.write_entry(&zw, archive.File_Info{path = "huge", size = 32 << 20}, bytes.reader_to_stream(&huge)), Zip_Error.Size_Mismatch)
	testing.expect_value(t, zip.write_entry(&zw, "after.txt", text), Zip_Error.Size_Mismatch)
	testing.expect_value(t, zip.commit(&zw), Zip_Error.Size_Mismatch)

	streamed := make([]u8, int(zip.ONE_SHOT_MAX) * 2)
	defer delete(streamed)
	for i in 0..<len(streamed) {
		streamed[i] = text[i % len(text)]
	}
	for method in ([?]archive.Method{.Deflate, .BZip2, .LZMA, .PPMd_I}) {
		for declared in ([?]i64{i64(len(streamed)) + 1000, i64(len(streamed)) - 1000}) {
			sw: zip.Writer
			out := Memory_File{seekable = true}
			if testing.expect_value(t, zip.create(&sw, memory_stream(&out)), nil) {
				source: bytes.Reader
				bytes.reader_init(&source, streamed)
				err := zip.write_entry(&sw, archive.File_Info{path = "m", size = declared}, bytes.reader_to_stream(&source), zip.Entry_Options{method = method})
				testing.expectf(t, err == Zip_Error.Size_Mismatch, "%v, declared %d of %d: %v", method, declared, len(streamed), err)
				zip.close(&sw)
			}
			delete(out.data)
		}
	}

	bad: zip.Writer
	other := Memory_File{seekable = true}
	defer delete(other.data)
	long_comment := strings.repeat("c", 0x10000, context.temp_allocator)
	testing.expect_value(t, zip.create(&bad, memory_stream(&other), zip.Writer_Options{comment = long_comment}), Zip_Error.Field_Too_Long)
	testing.expect_value(t, zip.create(&bad, memory_stream(&other), zip.Writer_Options{method = .Implode}), archive.General_Error.Unsupported_Method)

	done: zip.Writer
	if testing.expect_value(t, zip.create(&done, memory_stream(&other)), nil) {
		testing.expect_value(t, zip.write_entry(&done, "a.txt", text), nil)
		testing.expect_value(t, zip.commit(&done), nil)
		testing.expect_value(t, zip.commit(&done), nil)
		testing.expect_value(t, zip.write_entry(&done, "b.txt", text), io.Error.Closed)
		zip.close(&done)
	}
	check_written(t, "after commit", other.data[:], {{name = "a.txt", type = .Regular, content = text, method = .Deflate}})
}

@(test)
test_write_deterministic :: proc(t: ^testing.T) {
	text := write_text()
	outputs: [2]Memory_File
	defer for &o in outputs {
		delete(o.data)
	}
	for &o, round in outputs {
		o.seekable = true
		zw: zip.Writer
		if !testing.expect_value(t, zip.create(&zw, memory_stream(&o), zip.Writer_Options{deterministic = true}), nil) {
			return
		}
		fi := archive.File_Info{
			path              = "owned.txt",
			uid               = 1000 + i64(round),
			gid               = 1000,
			modification_time = time.unix(1_700_000_000 + i64(round), 0),
			access_time       = time.unix(1_700_000_000, 0),
			creation_time     = time.unix(1_700_000_000, 0),
		}
		testing.expect_value(t, zip.write_entry(&zw, "simple.txt", text), nil)
		testing.expect_value(t, zip.write_entry(&zw, fi, text), nil)
		testing.expect_value(t, zip.commit(&zw), nil)
		zip.close(&zw)
		time.sleep(2 * time.Millisecond)
	}
	testing.expect(t, bytes.equal(outputs[0].data[:], outputs[1].data[:]), "deterministic outputs differ")

	r: zip.Reader
	if !testing.expect_value(t, zip.open(&r, outputs[0].data[:]), nil) {
		return
	}
	defer zip.close(&r)
	fi, _, ok, _ := zip.find(&r, "owned.txt")
	testing.expect(t, ok, "find owned.txt")
	testing.expect_value(t, fi.modification_time, time.unix(315_532_800, 0))
	testing.expect_value(t, fi.uid, 0)
	testing.expect_value(t, fi.gid, 0)
	dos := central_dos_times(outputs[0].data[:])
	defer delete(dos)
	if testing.expect_value(t, len(dos), 2) {
		testing.expect_value(t, dos[1], [2]u16{0, 1 << 5 | 1})
	}
}

@(test)
test_dos_time_local :: proc(t: ^testing.T) {
	winter := time.unix(1_700_000_000, 0)
	summer := time.unix(1_688_212_800, 0)
	winter_dos := [2]u16{23 << 11 | 13 << 5 | 10, 43 << 9 | 11 << 5 | 14}
	summer_dos := [2]u16{14 << 11, 43 << 9 | 7 << 5 | 1}

	out: Memory_File
	defer delete(out.data)
	out.seekable = true
	zw: zip.Writer
	if !testing.expect_value(t, zip.create(&zw, memory_stream(&out)), nil) {
		return
	}
	timezone.region_destroy(zw.zone, zw.allocator)
	zw.zone = &CET
	testing.expect_value(t, zip.write_entry(&zw, archive.File_Info{path = "winter.txt", modification_time = winter}), nil)
	testing.expect_value(t, zip.write_entry(&zw, archive.File_Info{path = "summer.txt", modification_time = summer}), nil)
	testing.expect_value(t, zip.commit(&zw), nil)
	zw.zone = nil
	zip.close(&zw)

	dos := central_dos_times(out.data[:])
	defer delete(dos)
	if testing.expect_value(t, len(dos), 2) {
		testing.expect_value(t, dos[0], winter_dos)
		testing.expect_value(t, dos[1], summer_dos)
	}
	r: zip.Reader
	if testing.expect_value(t, zip.open(&r, out.data[:]), nil) {
		fi, _, ok, _ := zip.find(&r, "summer.txt")
		testing.expect(t, ok, "find summer.txt")
		testing.expect_value(t, fi.modification_time, summer)
		zip.close(&r)
	}

	Case :: struct {
		dos:  [2]u16,
		want: time.Time,
	}
	for c in ([2]Case{{winter_dos, winter}, {summer_dos, summer}}) {
		data := dos_only_zip(c.dos[0], c.dos[1])
		defer delete(data)
		dr: zip.Reader
		if !testing.expect_value(t, zip.open(&dr, data[:]), nil) {
			continue
		}
		timezone.region_destroy(dr.zone, dr.allocator)
		dr.zone = &CET
		fi, _, ok, _ := zip.find(&dr, "a")
		testing.expect(t, ok, "find a")
		testing.expect_value(t, fi.modification_time, c.want)
		dr.zone = nil
		zip.close(&dr)
	}
}

@(test)
test_write_path :: proc(t: ^testing.T) {
	root, dir_err := os.make_directory_temp("", "odin_zip_writer_path_*", context.temp_allocator)
	if dir_err == .Unsupported {
		return
	}
	if !testing.expect_value(t, dir_err, nil) {
		return
	}
	defer os.remove_all(root)
	text := write_text()

	path, _ := os.join_path({root, "made.zip"}, context.temp_allocator)
	zw: zip.Writer
	for no_sync in ([?]bool{false, true}) {
		if testing.expect_value(t, zip.create(&zw, path, {no_sync = no_sync}), nil) {
			testing.expect_value(t, zip.write_entry(&zw, "text.txt", text), nil)
			testing.expect_value(t, zip.commit(&zw), nil)
			zip.close(&zw)
			r: zip.Reader
			if testing.expect_value(t, zip.open(&r, path), nil) {
				fi, handle, ok, _ := zip.find(&r, "text.txt")
				testing.expect(t, ok && fi.size == i64(len(text)), "find text.txt")
				out := strings.builder_make()
				testing.expect_value(t, zip.extract(&r, handle, strings.to_writer(&out)), nil)
				testing.expect(t, strings.to_string(out) == string(text), "content of text.txt")
				strings.builder_destroy(&out)
				zip.close(&r)
			}
		}
	}

	dropped, _ := os.join_path({root, "dropped.zip"}, context.temp_allocator)
	dropped_temp := strings.concatenate({dropped, "-temp"}, context.temp_allocator)
	if testing.expect_value(t, zip.create(&zw, dropped), nil) {
		testing.expect_value(t, zip.write_entry(&zw, "text.txt", text), nil)
		testing.expect(t, !os.exists(dropped), "no archive before the commit")
		testing.expect(t, os.exists(dropped_temp), "temp archive exists while writing")
		zip.close(&zw)
		testing.expect(t, !os.exists(dropped), "no archive after an uncommitted close")
		testing.expect(t, !os.exists(dropped_temp), "temp archive removed on close")
	}

	if testing.expect_value(t, zip.create(&zw, path), nil) {
		testing.expect_value(t, zip.write_entry(&zw, "other.txt", text), nil)
		zip.close(&zw)
		r: zip.Reader
		if testing.expect_value(t, zip.open(&r, path), nil) {
			_, _, ok, _ := zip.find(&r, "text.txt")
			testing.expect(t, ok, "an uncommitted create keeps the existing archive")
			zip.close(&r)
		}
	}

	m := Memory_File{seekable = true}
	defer delete(m.data)
	stub := [123]u8{}
	for &b, i in stub {
		b = u8(i)
	}
	append(&m.data, ..stub[:])
	m.position = len(m.data)
	if testing.expect_value(t, zip.create(&zw, memory_stream(&m)), nil) {
		testing.expect_value(t, zip.write_entry(&zw, "text.txt", text), nil)
		testing.expect_value(t, zip.commit(&zw), nil)
		zip.close(&zw)
		check_written(t, "prepended", m.data[:], {{name = "text.txt", type = .Regular, content = text, method = .Deflate}})
	}
}

@(test)
test_write_directory :: proc(t: ^testing.T) {
	root, dir_err := os.make_directory_temp("", "odin_zip_writer_dir_*", context.temp_allocator)
	if dir_err == .Unsupported {
		return
	}
	if !testing.expect_value(t, dir_err, nil) {
		return
	}
	defer os.remove_all(root)
	text   := write_text()
	random := write_random(20_000, 7)
	defer delete(random)

	deeper, _ := os.join_path({root, "sub", "deeper"}, context.temp_allocator)
	empty,  _ := os.join_path({root, "emptydir"}, context.temp_allocator)
	a,      _ := os.join_path({root, "a.txt"}, context.temp_allocator)
	b,      _ := os.join_path({root, "sub", "b.txt"}, context.temp_allocator)
	c,      _ := os.join_path({root, "sub", "deeper", "c.bin"}, context.temp_allocator)
	testing.expect_value(t, os.make_directory_all(deeper), nil)
	testing.expect_value(t, os.make_directory(empty), nil)
	testing.expect_value(t, os.write_entire_file(a, "alpha"), nil)
	testing.expect_value(t, os.write_entire_file(b, text), nil)
	testing.expect_value(t, os.write_entire_file(c, random), nil)

	expected := make([dynamic]Write_Expect, context.temp_allocator)
	append(&expected, Write_Expect{name = "pre/", type = .Directory, method = .Store})
	append(&expected, Write_Expect{name = "pre/a.txt", type = .Regular, content = transmute([]u8)string("alpha"), method = .Store})
	append(&expected, Write_Expect{name = "pre/emptydir/", type = .Directory, method = .Store})
	when ODIN_OS != .Windows {
		link, _ := os.join_path({root, "link"}, context.temp_allocator)
		testing.expect_value(t, os.symlink("a.txt", link), nil)
		append(&expected, Write_Expect{name = "pre/link", type = .Symlink, content = transmute([]u8)string("a.txt"), method = .Store, link = "a.txt"})
	}
	append(&expected, Write_Expect{name = "pre/sub/", type = .Directory, method = .Store})
	append(&expected, Write_Expect{name = "pre/sub/b.txt", type = .Regular, content = text, method = .Deflate})
	append(&expected, Write_Expect{name = "pre/sub/deeper/", type = .Directory, method = .Store})
	append(&expected, Write_Expect{name = "pre/sub/deeper/c.bin", type = .Regular, content = random, method = .Store})

	outputs: [2]Memory_File
	defer for &o in outputs {
		delete(o.data)
	}
	for &o in outputs {
		o.seekable = true
		zw: zip.Writer
		if !testing.expect_value(t, zip.create(&zw, memory_stream(&o), zip.Writer_Options{deterministic = true}), nil) {
			return
		}
		testing.expect_value(t, zip.write_directory(&zw, root, "pre/"), nil)
		testing.expect_value(t, zip.commit(&zw), nil)
		zip.close(&zw)
	}
	check_written(t, "directory", outputs[0].data[:], expected[:])
	testing.expect(t, bytes.equal(outputs[0].data[:], outputs[1].data[:]), "deterministic directory outputs differ")

	walked := Memory_File{seekable = true}
	defer delete(walked.data)
	zw: zip.Writer
	if testing.expect_value(t, zip.create(&zw, memory_stream(&walked)), nil) {
		testing.expect_value(t, zip.write_directory(&zw, root), nil)
		testing.expect_value(t, zip.commit(&zw), nil)
		zip.close(&zw)
		r: zip.Reader
		if testing.expect_value(t, zip.open(&r, walked.data[:]), nil) {
			testing.expect_value(t, zip.info(&r).member_count, len(expected) - 1)
			for want in expected[1:] {
				_, _, ok, _ := zip.find(&r, want.name[len("pre/"):])
				testing.expectf(t, ok, "walked: %s missing", want.name)
			}
			zip.close(&r)
		}
	}
}

@(test)
test_write_progress :: proc(t: ^testing.T) {
	text := write_text()
	log: Progress_Log
	m := Memory_File{seekable = true}
	defer delete(m.data)
	options: zip.Writer_Options
	options.options.progress          = write_progress
	options.options.progress_data     = &log
	options.options.progress_interval = 1024
	zw: zip.Writer
	if !testing.expect_value(t, zip.create(&zw, memory_stream(&m), options), nil) {
		return
	}
	testing.expect_value(t, zip.write_entry(&zw, "a.txt", text), nil)
	testing.expect_value(t, log.calls, 1)
	testing.expect_value(t, log.last_in, i64(len(text)))
	inner: bytes.Reader
	bytes.reader_init(&inner, text)
	unknown := Non_Seekable{inner = bytes.reader_to_stream(&inner)}
	testing.expect_value(t, zip.write_entry(&zw, archive.File_Info{path = "b.txt", size = -1}, non_seekable_stream(&unknown)), nil)
	testing.expect_value(t, log.calls, 3)
	testing.expect_value(t, log.last_in, i64(len(text)))
	testing.expect(t, log.last_out > 0 && log.last_out < i64(len(text)), "compressed size reported")
	testing.expect_value(t, log.member, 1)
	testing.expect_value(t, zip.commit(&zw), nil)
	zip.close(&zw)

	canceled := Progress_Log{cancel_at = 1}
	options.options.progress_data = &canceled
	other := Memory_File{seekable = true}
	defer delete(other.data)
	if testing.expect_value(t, zip.create(&zw, memory_stream(&other), options), nil) {
		want := compress.Error(compress.General_Error.Canceled)
		testing.expect_value(t, zip.write_entry(&zw, "a.txt", text), want)
		testing.expect_value(t, zip.write_entry(&zw, "b.txt", text), want)
		testing.expect_value(t, zip.commit(&zw), want)
		zip.close(&zw)
	}
}

@(test)
test_write_many :: proc(t: ^testing.T) {
	COUNT :: 70_000
	m := Memory_File{seekable = true}
	defer delete(m.data)
	zw: zip.Writer
	if !testing.expect_value(t, zip.create(&zw, memory_stream(&m), zip.Writer_Options{deterministic = true}), nil) {
		return
	}
	defer zip.close(&zw)
	for i in 0..<COUNT {
		if zip.write_entry(&zw, fmt.tprintf("e/%05d", i)) != nil {
			testing.fail_now(t, "write_entry failed")
		}
	}
	testing.expect_value(t, zip.commit(&zw), nil)
	end := m.data[len(m.data) - 22:]
	testing.expect_value(t, u16(end[10]) | u16(end[11]) << 8, 0xFFFF)
	r: zip.Reader
	if testing.expect_value(t, zip.open(&r, m.data[:]), nil) {
		testing.expect_value(t, zip.info(&r).member_count, COUNT)
		_, _, ok, _ := zip.find(&r, "e/69999")
		testing.expect(t, ok, "find e/69999")
		zip.close(&r)
	}
}

@(test)
test_write_streamed :: proc(t: ^testing.T) {
	when SLIM_TESTS {
		return
	}
	SIZE :: 17 << 20
	random := write_random(SIZE, 3)
	defer delete(random)
	text := make([]u8, SIZE)
	defer delete(text)
	line := WRITE_TEXT
	for i in 0..<SIZE {
		text[i] = line[i % len(line)]
	}
	for mode in Output_Mode {
		m := Memory_File{seekable = mode == .Seekable}
		defer delete(m.data)
		zw: zip.Writer
		if !testing.expect_value(t, zip.create(&zw, memory_stream(&m), zip.Writer_Options{level = 1}), nil) {
			return
		}
		seekable_random: bytes.Reader
		bytes.reader_init(&seekable_random, random)
		testing.expect_value(t, zip.write_entry(&zw, "random.bin", random), nil)
		testing.expect_value(t, zip.write_entry(&zw, "text.txt", text), nil)
		testing.expect_value(t, zip.write_entry(&zw, "reader.bin", bytes.reader_to_stream(&seekable_random)), nil)
		testing.expect_value(t, zip.commit(&zw), nil)
		zip.close(&zw)
		fallback: archive.Method = .Store if mode == .Seekable else .Deflate
		label := fmt.tprintf("streamed/%v", mode)
		check_written(t, label, m.data[:], {
			{name = "random.bin", type = .Regular, content = random, method = fallback, descriptor = mode == .Streaming},
			{name = "text.txt",   type = .Regular, content = text,   method = .Deflate, descriptor = mode == .Streaming},
			{name = "reader.bin", type = .Regular, content = random, method = fallback, descriptor = mode == .Streaming},
		})
	}
}

@(test)
test_write_lzma_streamed :: proc(t: ^testing.T) {
	LEVEL :: 3
	size  := int(zip.ONE_SHOT_MAX) * 4
	text  := make([]u8, size)
	defer delete(text)
	line  := WRITE_TEXT
	for i in 0..<size {
		text[i] = line[i % len(line)]
	}
	random := write_random(size, 5)
	defer delete(random)

	want: [dynamic]u8
	defer delete(want)
	lzma_options := lzma.level_options(lzma.Level(LEVEL))
	lzma_options.end_marker = true
	props, props_err := lzma.compress_raw_to_dynamic(&want, text, lzma_options)
	testing.expect_value(t, props_err, nil)
	encoded := lzma.encode_properties(props)

	for mode in Output_Mode {
		m := Memory_File{seekable = mode == .Seekable}
		defer delete(m.data)
		zw: zip.Writer
		if !testing.expect_value(t, zip.create(&zw, memory_stream(&m), zip.Writer_Options{method = .LZMA, level = LEVEL}), nil) {
			return
		}
		known, inner: bytes.Reader
		bytes.reader_init(&known, text)
		bytes.reader_init(&inner, text)
		unknown := Non_Seekable{inner = bytes.reader_to_stream(&inner)}
		testing.expect_value(t, zip.write_entry(&zw, "text.txt", text), nil)
		testing.expect_value(t, zip.write_entry(&zw, "known.txt", bytes.reader_to_stream(&known)), nil)
		testing.expect_value(t, zip.write_entry(&zw, archive.File_Info{path = "unknown.txt", size = -1}, non_seekable_stream(&unknown)), nil)
		testing.expect_value(t, zip.write_entry(&zw, "random.bin", random), nil)
		testing.expect_value(t, zip.commit(&zw), nil)
		zip.close(&zw)

		label    := fmt.tprintf("lzma streamed/%v", mode)
		streamed := mode == .Streaming
		fallback := archive.Method.Store if mode == .Seekable else archive.Method.LZMA
		check_written(t, label, m.data[:], {
			{name = "text.txt",    type = .Regular, method = .LZMA,   content = text,   descriptor = streamed},
			{name = "known.txt",   type = .Regular, method = .LZMA,   content = text,   descriptor = streamed},
			{name = "unknown.txt", type = .Regular, method = .LZMA,   content = text,   descriptor = streamed},
			{name = "random.bin",  type = .Regular, method = fallback, content = random, descriptor = streamed},
		})

		r: zip.Reader
		if !testing.expect_value(t, zip.open(&r, m.data[:]), nil) {
			continue
		}
		it := zip.iterator_create(&r)
		for fi in zip.iterate(&it) {
			entry := zip.current_entry(&it)
			if entry.method != .LZMA {
				continue
			}
			raw := m.data[entry.data_offset:][:fi.compressed_size]
			testing.expectf(t, .Option_1 in entry.flags, "%s/%s: EOS flag", label, fi.path)
			testing.expectf(t, bytes.equal(raw[:4], []u8{LZMA_SDK_VERSION[0], LZMA_SDK_VERSION[1], lzma.PROPERTIES_SIZE, 0}), "%s/%s: head % x", label, fi.path, raw[:4])
			if fi.path == "text.txt" || fi.path == "known.txt" {
				same := bytes.equal(raw[4:][:lzma.PROPERTIES_SIZE], encoded[:]) && bytes.equal(raw[4 + lzma.PROPERTIES_SIZE:], want[:])
				testing.expectf(t, same, "%s/%s: %d bytes differ from one shot's %d", label, fi.path, len(raw), 4 + lzma.PROPERTIES_SIZE + len(want))
			}
		}
		zip.iterator_destroy(&it)
		zip.close(&r)
	}
}

@(test)
test_write_stream_memory :: proc(t: ^testing.T) {
	when SLIM_TESTS {
		return
	}
	sizes := [2]i64{8 << 20, 32 << 20}
	for method in ([?]archive.Method{.LZMA, .XZ}) {
		slack := i64(0) if method == .LZMA else 4096
		peaks:      [2][2]i64
		read_peaks: [2][2]i64
		for size, i in sizes {
			for known, k in ([2]bool{true, false}) {
				track: mem.Tracking_Allocator
				mem.tracking_allocator_init(&track, context.allocator)
				defer mem.tracking_allocator_destroy(&track)
				m := Memory_File{seekable = true}
				reserve(&m.data, 1 << 20)
				defer delete(m.data)
				zw: zip.Writer
				if !testing.expect_value(t, zip.create(&zw, memory_stream(&m), zip.Writer_Options{method = method, level = 1}, mem.tracking_allocator(&track)), nil) {
					return
				}
				zeros := Zero_Reader{remaining = size}
				fi    := archive.File_Info{path = "zeros.bin", size = size if known else -1}
				testing.expect_value(t, zip.write_entry(&zw, fi, zero_reader(&zeros)), nil)
				testing.expect_value(t, zip.commit(&zw), nil)
				zip.close(&zw)
				testing.expectf(t, len(track.allocation_map) == 0, "%v, size %d, known %v: %d allocations left", method, size, known, len(track.allocation_map))
				peaks[k][i] = track.peak_memory_allocated

				read_track: mem.Tracking_Allocator
				mem.tracking_allocator_init(&read_track, context.allocator)
				defer mem.tracking_allocator_destroy(&read_track)
				r: zip.Reader
				if !testing.expect_value(t, zip.open(&r, m.data[:], {}, mem.tracking_allocator(&read_track)), nil) {
					continue
				}
				got, handle, ok, _ := zip.find(&r, "zeros.bin")
				testing.expect(t, ok, "find zeros.bin")
				testing.expect_value(t, got.method, method)
				d: Discard
				testing.expect_value(t, zip.extract(&r, handle, discard_writer(&d)), nil)
				testing.expect_value(t, d.count, size)
				zip.close(&r)
				read_peaks[k][i] = read_track.peak_memory_allocated
			}
		}
		for p in peaks {
			testing.expectf(t, abs(p[1] - p[0]) <= slack && p[1] < sizes[1], "%v: write peaks %v for sizes %v", method, p, sizes)
		}
		for p in read_peaks {
			testing.expectf(t, abs(p[1] - p[0]) <= slack && p[1] < sizes[0], "%v: read peaks %v for sizes %v", method, p, sizes)
		}
	}
}

@(test)
test_write_large :: proc(t: ^testing.T) {
	when SLIM_TESTS {
		return
	}
	SIZE :: 4_831_838_208
	m := Memory_File{seekable = true}
	defer delete(m.data)
	zw: zip.Writer
	if !testing.expect_value(t, zip.create(&zw, memory_stream(&m), zip.Writer_Options{level = 1}), nil) {
		return
	}
	zeros := Zero_Reader{remaining = SIZE}
	testing.expect_value(t, zip.write_entry(&zw, archive.File_Info{path = "zeros.bin", size = SIZE}, zero_reader(&zeros)), nil)
	testing.expect_value(t, zip.write_entry(&zw, "after.txt", write_text()), nil)
	testing.expect_value(t, zip.commit(&zw), nil)
	zip.close(&zw)

	r: zip.Reader
	if !testing.expect_value(t, zip.open(&r, m.data[:]), nil) {
		return
	}
	defer zip.close(&r)
	fi, handle, ok, _ := zip.find(&r, "zeros.bin")
	testing.expect(t, ok, "find zeros.bin")
	testing.expect_value(t, fi.size, SIZE)
	d: Discard
	testing.expect_value(t, zip.extract(&r, handle, discard_writer(&d)), nil)
	testing.expect_value(t, d.count, SIZE)
	_, _, after, _ := zip.find(&r, "after.txt")
	testing.expect(t, after, "find after.txt")
}

write_and_check :: proc(t: ^testing.T, method: archive.Method, mode: Output_Mode) {
	label  := fmt.tprintf("%v/%v", method, mode)
	text   := write_text()
	random := write_random(40_000, 1)
	defer delete(random)
	streaming := mode == .Streaming

	m := Memory_File{seekable = mode == .Seekable}
	defer delete(m.data)
	zw: zip.Writer
	err := zip.create(&zw, memory_stream(&m), zip.Writer_Options{method = method, comment = "archive comment ✓"})
	if !testing.expectf(t, err == nil, "%s: create %v", label, err) {
		return
	}
	defer zip.close(&zw)

	known, inner, inner_random: bytes.Reader
	bytes.reader_init(&known, text)
	bytes.reader_init(&inner, text)
	bytes.reader_init(&inner_random, random)
	unknown        := Non_Seekable{inner = bytes.reader_to_stream(&inner)}
	unknown_random := Non_Seekable{inner = bytes.reader_to_stream(&inner_random)}
	owned := archive.File_Info{
		path              = "owned.txt",
		uid               = 1000,
		gid               = 1001,
		unix_mode         = 0o750,
		modification_time = time.unix(1_700_000_000, 0),
		access_time       = time.unix(1_700_000_100, 0),
		creation_time     = time.unix(1_600_000_000, 0),
	}
	testing.expectf(t, zip.write_entry(&zw, "empty.txt") == nil, "%s: empty.txt", label)
	testing.expectf(t, zip.write_entry(&zw, "text.txt", text) == nil, "%s: text.txt", label)
	testing.expectf(t, zip.write_entry(&zw, "random.bin", random) == nil, "%s: random.bin", label)
	testing.expectf(t, zip.write_entry(&zw, "known.txt", bytes.reader_to_stream(&known)) == nil, "%s: known.txt", label)
	testing.expectf(t, zip.write_entry(&zw, archive.File_Info{path = "unknown.txt", size = -1}, non_seekable_stream(&unknown)) == nil, "%s: unknown.txt", label)
	testing.expectf(t, zip.write_entry(&zw, archive.File_Info{path = "unknown.bin", size = -1}, non_seekable_stream(&unknown_random)) == nil, "%s: unknown.bin", label)
	testing.expectf(t, zip.write_entry(&zw, archive.File_Info{path = "dir", type = .Directory}) == nil, "%s: dir", label)
	testing.expectf(t, zip.write_entry(&zw, archive.File_Info{path = "dir/link", type = .Symlink, link_target = "../text.txt"}) == nil, "%s: link", label)
	testing.expectf(t, zip.write_entry(&zw, archive.File_Info{path = "naïve/ünïcode.txt", comment = "entry comment ✓", size = i64(len(text))}, text) == nil, "%s: unicode", label)
	testing.expectf(t, zip.write_entry(&zw, owned, text) == nil, "%s: owned.txt", label)
	err = zip.commit(&zw)
	if !testing.expectf(t, err == nil, "%s: commit %v", label, err) {
		return
	}

	check_written(t, label, m.data[:], {
		{name = "empty.txt",         type = .Regular,   method = .Store},
		{name = "text.txt",          type = .Regular,   method = method, content = text},
		{name = "random.bin",        type = .Regular,   method = .Store, content = random},
		{name = "known.txt",         type = .Regular,   method = method, content = text},
		{name = "unknown.txt",       type = .Regular,   method = method, content = text, descriptor = streaming},
		{name = "unknown.bin",       type = .Regular,   method = method, content = random, descriptor = streaming},
		{name = "dir/",              type = .Directory, method = .Store},
		{name = "dir/link",          type = .Symlink,   method = .Store, content = transmute([]u8)string("../text.txt"), link = "../text.txt"},
		{name = "naïve/ünïcode.txt", type = .Regular,   method = method, content = text, comment = "entry comment ✓", utf8 = true},
		{name = "owned.txt",         type = .Regular,   method = method, content = text},
	}, "archive comment ✓")

	r: zip.Reader
	if zip.open(&r, m.data[:]) != nil {
		return
	}
	defer zip.close(&r)
	fi, _, ok, _ := zip.find(&r, "owned.txt")
	testing.expectf(t, ok, "%s: find owned.txt", label)
	testing.expectf(t, fi.uid == 1000 && fi.gid == 1001, "%s: owner %d:%d", label, fi.uid, fi.gid)
	testing.expectf(t, fi.unix_mode == archive.UNIX_REGULAR | 0o750, "%s: mode %o", label, fi.unix_mode)
	testing.expectf(t, fi.modification_time == owned.modification_time, "%s: mtime %v", label, fi.modification_time)
	testing.expectf(t, fi.access_time == owned.access_time, "%s: atime %v", label, fi.access_time)
	testing.expectf(t, fi.creation_time == owned.creation_time, "%s: ctime %v", label, fi.creation_time)
	link, _, link_ok, _ := zip.find(&r, "dir/link")
	testing.expectf(t, link_ok && link.unix_mode == archive.UNIX_SYMLINK | 0o777, "%s: link mode %o", label, link.unix_mode)
}

check_written :: proc(t: ^testing.T, label: string, data: []u8, expected: []Write_Expect, comment := "") {
	r: zip.Reader
	err := zip.open(&r, data)
	if !testing.expectf(t, err == nil, "%s: open %v", label, err) {
		return
	}
	defer zip.close(&r)
	testing.expectf(t, zip.info(&r).comment == comment, "%s: comment %q", label, zip.info(&r).comment)
	it := zip.iterator_create(&r)
	defer zip.iterator_destroy(&it)
	count := 0
	for fi, index in zip.iterate(&it) {
		count += 1
		if !testing.expectf(t, index < len(expected), "%s: extra member %s", label, fi.path) {
			continue
		}
		want  := expected[index]
		entry := zip.current_entry(&it)
		testing.expectf(t, fi.path == archive._clean_member_path(want.name), "%s: name %q, want %q", label, fi.path, want.name)
		testing.expectf(t, fi.type == want.type, "%s/%s: type %v", label, want.name, fi.type)
		testing.expectf(t, fi.method == want.method, "%s/%s: method %v, want %v", label, want.name, fi.method, want.method)
		testing.expectf(t, fi.comment == want.comment, "%s/%s: comment %q", label, want.name, fi.comment)
		testing.expectf(t, (.UTF8 in entry.flags) == want.utf8, "%s/%s: flags %v", label, want.name, entry.flags)
		testing.expectf(t, (.Data_Descriptor in entry.flags) == want.descriptor, "%s/%s: flags %v", label, want.name, entry.flags)
		content, extract_err := extract_to_bytes(&it)
		testing.expectf(t, extract_err == nil && bytes.equal(content[:], want.content), "%s/%s: content %v, %d bytes", label, want.name, extract_err, len(content))
		delete(content)
		if want.type == .Symlink {
			target, link_err := zip.read_link(&it)
			testing.expectf(t, link_err == nil && target == want.link, "%s/%s: link %q %v", label, want.name, target, link_err)
			delete(target)
		}
	}
	path, iter_err := zip.iterator_error(&it)
	testing.expectf(t, iter_err == nil, "%s: iterator %s %v", label, path, iter_err)
	testing.expectf(t, count == len(expected), "%s: %d members, want %d", label, count, len(expected))
}

write_text :: proc() -> []u8 {
	text := strings.repeat(WRITE_TEXT, 64, context.temp_allocator)
	return transmute([]u8)text
}

write_random :: proc(n: int, seed: u64) -> (data: []u8) {
	data = make([]u8, n)
	state := seed
	for &b in data {
		state = state * 6364136223846793005 + 1442695040888963407
		b = u8(state >> 56)
	}
	return
}

write_progress :: proc(progress: compress.Progress, user_data: rawptr) -> (cancel: bool) {
	log := (^Progress_Log)(user_data)
	log.calls   += 1
	log.last_in  = progress.bytes_in
	log.last_out = progress.bytes_out
	log.member   = progress.member_index
	return log.cancel_at > 0 && log.calls >= log.cancel_at
}

put_u16 :: proc(b: ^[dynamic]u8, v: u16) {
	append(b, u8(v), u8(v >> 8))
}

put_u32 :: proc(b: ^[dynamic]u8, v: u32) {
	append(b, u8(v), u8(v >> 8), u8(v >> 16), u8(v >> 24))
}

get_u16 :: proc(b: []u8, at: int) -> u16 {
	return u16(b[at]) | u16(b[at + 1]) << 8
}

get_u32 :: proc(b: []u8, at: int) -> u32 {
	return u32(get_u16(b, at)) | u32(get_u16(b, at + 2)) << 16
}

dos_only_zip :: proc(dos_time, dos_date: u16) -> (b: [dynamic]u8) {
	put_u32(&b, 0x04034b50)
	put_u16(&b, 10)
	put_u16(&b, 0)
	put_u16(&b, 0)
	put_u16(&b, dos_time)
	put_u16(&b, dos_date)
	put_u32(&b, 0)
	put_u32(&b, 0)
	put_u32(&b, 0)
	put_u16(&b, 1)
	put_u16(&b, 0)
	append(&b, 'a')
	central := len(b)
	put_u32(&b, 0x02014b50)
	put_u16(&b, 20)
	put_u16(&b, 10)
	put_u16(&b, 0)
	put_u16(&b, 0)
	put_u16(&b, dos_time)
	put_u16(&b, dos_date)
	put_u32(&b, 0)
	put_u32(&b, 0)
	put_u32(&b, 0)
	put_u16(&b, 1)
	put_u16(&b, 0)
	put_u16(&b, 0)
	put_u16(&b, 0)
	put_u16(&b, 0)
	put_u32(&b, 0)
	put_u32(&b, 0)
	append(&b, 'a')
	size := len(b) - central
	put_u32(&b, 0x06054b50)
	put_u16(&b, 0)
	put_u16(&b, 0)
	put_u16(&b, 1)
	put_u16(&b, 1)
	put_u32(&b, u32(size))
	put_u32(&b, u32(central))
	put_u16(&b, 0)
	return
}

central_dos_times :: proc(data: []u8) -> (times: [dynamic][2]u16) {
	end := len(data) - 22
	if end < 0 || get_u32(data, end) != 0x06054b50 {
		return
	}
	count := int(get_u16(data, end + 10))
	pos := int(get_u32(data, end + 16))
	for _ in 0..<count {
		if pos + 46 > len(data) || get_u32(data, pos) != 0x02014b50 {
			break
		}
		append(&times, [2]u16{get_u16(data, pos + 12), get_u16(data, pos + 14)})
		pos += 46 + int(get_u16(data, pos + 28)) + int(get_u16(data, pos + 30)) + int(get_u16(data, pos + 32))
	}
	return
}

memory_stream :: proc(m: ^Memory_File) -> (s: io.Stream) {
	s.data      = m
	s.procedure = memory_proc
	return
}

memory_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	m := (^Memory_File)(stream_data)
	#partial switch mode {
	case .Write:
		end := m.position + len(p)
		if end > cap(m.data) {
			reserve(&m.data, max(end, 2 * cap(m.data)))
		}
		if end > len(m.data) {
			resize(&m.data, end)
		}
		copy(m.data[m.position:], p)
		m.position = end
		return i64(len(p)), nil
	case .Seek:
		if !m.seekable {
			return 0, .Unsupported
		}
		target: i64
		switch whence {
		case .Start:   target = offset
		case .Current: target = i64(m.position) + offset
		case .End:     target = i64(len(m.data)) + offset
		}
		if target < 0 {
			return 0, .Invalid_Offset
		}
		m.position = int(target)
		return target, nil
	case .Size:
		if !m.seekable {
			return 0, .Unsupported
		}
		return i64(len(m.data)), nil
	case .Flush:
		return 0, nil
	case .Query:
		if m.seekable {
			return io.query_utility({.Write, .Seek, .Size, .Flush, .Query})
		}
		return io.query_utility({.Write, .Flush, .Query})
	}
	return 0, .Unsupported
}

zero_reader :: proc(z: ^Zero_Reader) -> (s: io.Stream) {
	s.data      = z
	s.procedure = zero_proc
	return
}

zero_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	z := (^Zero_Reader)(stream_data)
	#partial switch mode {
	case .Read:
		if z.remaining == 0 {
			return 0, .EOF
		}
		k := int(min(i64(len(p)), z.remaining))
		for i in 0..<k {
			p[i] = 0
		}
		z.remaining -= i64(k)
		return i64(k), nil
	case .Query:
		return io.query_utility({.Read, .Query})
	}
	return 0, .Unsupported
}

hiccup_reader :: proc(h: ^Hiccup_Reader) -> (s: io.Stream) {
	s.data      = h
	s.procedure = hiccup_proc
	return
}

hiccup_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	h := (^Hiccup_Reader)(stream_data)
	#partial switch mode {
	case .Read:
		if h.pending < h.hiccups {
			h.pending += 1
			return 0, nil
		}
		h.pending = 0
		if h.pos >= len(h.data) {
			return 0, .EOF
		}
		got := copy(p[:min(len(p), 7)], h.data[h.pos:])
		h.pos += got
		return i64(got), nil
	case .Query:
		return io.query_utility({.Read, .Query})
	}
	return 0, .Unsupported
}
