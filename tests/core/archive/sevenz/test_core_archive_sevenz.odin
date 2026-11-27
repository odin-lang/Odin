package test_core_archive_sevenz

import "core:archive"
import "core:archive/sevenz"
import "core:bytes"
import "core:compress"
import "core:hash"
import "core:io"
import "core:os"
import "core:path/filepath"
import "core:strings"
import "core:testing"
import "core:time"

TEST_SUITE_PATH_7Z :: ODIN_ROOT + "tests/core/assets/7Z/"
SOURCE_TIME        :: 1_794_139_200
TEXT_CRC           :: 0x61c54dab
TEXT_SIZE          :: 80_000
PASSWORD           :: "ODIN"

SevenZ_Error :: archive.SevenZ_Error

Source_Kind :: enum u8 {
	Path,
	Bytes,
	Bytes_Progress,
	Seek_Read,
}

Corpus_Case :: struct {
	name:        string,
	members:     int,
	directories: int,
	encrypted:   int,
}

Counting :: struct {
	inner:   io.Stream,
	read:    i64,
	read_at: bool,
}

Non_Seekable :: struct {
	inner: io.Stream,
}

Progress_Log :: struct {
	calls:     [dynamic]compress.Progress,
	cancel_at: int,
}

CORPUS :: [?]Corpus_Case{
	{"aes-copy.7z",               1,  0, 1},
	{"aes.7z",                    6,  0, 5},
	{"arm-code.7z",               1,  0, 0},
	{"arm.7z",                    1,  0, 0},
	{"arm64.7z",                  1,  0, 0},
	{"armt-code.7z",              1,  0, 0},
	{"armt.7z",                   1,  0, 0},
	{"auto.7z",                   3,  0, 0},
	{"bcj-deflate.7z",            1,  0, 0},
	{"bcj-delta.7z",              1,  0, 0},
	{"bcj.7z",                    1,  0, 0},
	{"bcj2.7z",                   1,  0, 0},
	{"bzip2-mt.7z",               2,  0, 0},
	{"bzip2.7z",                  6,  0, 0},
	{"copy.7z",                   6,  0, 0},
	{"deflate.7z",                6,  0, 0},
	{"deflate64.7z",              6,  0, 0},
	{"delta-4.7z",                1,  0, 0},
	{"empty-only.7z",             2,  1, 0},
	{"empty.7z",                  0,  0, 0},
	{"header-notimes.7z",         6,  0, 0},
	{"header-plain.7z",           6,  0, 0},
	{"header-times.7z",           6,  0, 0},
	{"ia64.7z",                   1,  0, 0},
	{"libarchive-mac-bzip2.7z",   14, 4, 0},
	{"libarchive-mac-copy.7z",    14, 4, 0},
	{"libarchive-mac-deflate.7z", 14, 4, 0},
	{"libarchive-mac-lzma1.7z",   14, 4, 0},
	{"libarchive-mac-lzma2.7z",   14, 4, 0},
	{"libarchive-mac-ppmd.7z",    14, 4, 0},
	{"libarchive-win-copy.7z",    12, 4, 0},
	{"libarchive-win-deflate.7z", 12, 4, 0},
	{"lzma-lc0-lp2-pb0.7z",       1,  0, 0},
	{"lzma-lc4.7z",               1,  0, 0},
	{"lzma.7z",                   6,  0, 0},
	{"lzma2-chunks.7z",           3,  0, 0},
	{"lzma2.7z",                  6,  0, 0},
	{"ppc.7z",                    1,  0, 0},
	{"ppmd-o2.7z",                1,  0, 0},
	{"ppmd-o32.7z",               1,  0, 0},
	{"ppmd.7z",                   6,  0, 0},
	{"riscv-code.7z",             1,  0, 0},
	{"riscv.7z",                  1,  0, 0},
	{"sfx-7zS2con.exe",           6,  0, 0},
	{"sfx-7zSD.exe",              10, 4, 0},
	{"solid-2f.7z",               6,  0, 0},
	{"solid-e.7z",                6,  0, 0},
	{"solid-off.7z",              6,  0, 0},
	{"sparc.7z",                  1,  0, 0},
	{"swap2.7z",                  1,  0, 0},
	{"swap4.7z",                  1,  0, 0},
	{"tree.7z",                   10, 4, 0},
	{"x9.7z",                     3,  0, 0},
}

@(test)
test_corpus :: proc(t: ^testing.T) {
	for c in CORPUS {
		for source in Source_Kind {
			check_archive(t, c, source)
		}
	}
}

@(test)
test_encrypted_corpus :: proc(t: ^testing.T) {
	cases := [?]Corpus_Case{
		{"aes-copy.7z",    1, 0, 1},
		{"aes.7z",         6, 0, 5},
		{"aes-headers.7z", 6, 0, 5},
	}
	for c in cases {
		for source in Source_Kind {
			check_archive(t, c, source, PASSWORD)
		}
	}
}

@(test)
test_filters :: proc(t: ^testing.T) {
	Want :: struct {
		file:    string,
		method:  archive.Method,
		filters: archive.Filters,
	}
	wants := [?]Want{
		{"arm-code.7z",         .LZMA2,   {.BCJ_ARM}},
		{"arm64.7z",            .LZMA2,   {.BCJ_ARM64}},
		{"armt-code.7z",        .LZMA2,   {.BCJ_ARMT}},
		{"bcj-deflate.7z",      .Deflate, {.BCJ_X86}},
		{"bcj-delta.7z",        .LZMA2,   {.BCJ_X86, .Delta}},
		{"bcj.7z",              .LZMA2,   {.BCJ_X86}},
		{"bcj2.7z",             .LZMA2,   {.BCJ2}},
		{"delta-4.7z",          .LZMA2,   {.Delta}},
		{"ia64.7z",             .LZMA2,   {.BCJ_IA64}},
		{"lzma-lc0-lp2-pb0.7z", .LZMA,    {}},
		{"ppc.7z",              .LZMA2,   {.BCJ_PPC}},
		{"ppmd-o32.7z",         .PPMd_H,  {}},
		{"riscv-code.7z",       .LZMA2,   {.BCJ_RISCV}},
		{"sparc.7z",            .LZMA2,   {.BCJ_SPARC}},
		{"swap2.7z",            .LZMA2,   {.Swap2}},
		{"swap4.7z",            .LZMA2,   {.Swap4}},
	}
	for w in wants {
		r: sevenz.Reader
		if !testing.expectf(t, sevenz.open(&r, asset(w.file)) == nil, "%s: open", w.file) {
			continue
		}
		it := sevenz.iterator_create(&r)
		for fi in sevenz.iterate(&it) {
			testing.expectf(t, fi.method == w.method && fi.filters == w.filters, "%s/%s: %v %v", w.file, fi.path, fi.method, fi.filters)
			testing.expectf(t, fi.supported && !fi.encrypted, "%s/%s: supported", w.file, fi.path)
		}
		sevenz.iterator_destroy(&it)
		sevenz.close(&r)
	}

	Info_Want :: struct {
		file:    string,
		method:  archive.Method,
	}
	infos := [?]Info_Want{
		{"bzip2.7z",     .BZip2},
		{"copy.7z",      .Store},
		{"deflate.7z",   .Deflate},
		{"deflate64.7z", .Deflate64},
		{"empty.7z",     .Unknown},
		{"lzma.7z",      .LZMA},
		{"lzma2.7z",     .LZMA2},
		{"ppmd.7z",      .PPMd_H},
		{"x9.7z",        .LZMA2},
	}
	for w in infos {
		r: sevenz.Reader
		if testing.expectf(t, sevenz.open(&r, asset(w.file)) == nil, "%s: open", w.file) {
			info := sevenz.info(&r)
			testing.expectf(t, info.format == .SevenZ && info.compression == w.method, "%s: %v", w.file, info.compression)
			sevenz.close(&r)
		}
	}
}

@(test)
test_solid_one_pass :: proc(t: ^testing.T) {
	for name in ([?]string{"lzma2.7z", "bzip2-mt.7z", "ppmd.7z", "solid-2f.7z", "x9.7z", "libarchive-mac-lzma2.7z"}) {
		f, open_err := os.open(asset(name))
		if !testing.expectf(t, open_err == nil, "%s: %v", name, open_err) {
			continue
		}
		defer os.close(f)
		c := Counting{inner = os.to_stream(f), read_at = true}
		size, _ := io.size(c.inner)
		r: sevenz.Reader
		if !testing.expectf(t, sevenz.open(&r, counting_stream(&c)) == nil, "%s: open", name) {
			continue
		}
		it := sevenz.iterator_create(&r)
		total := i64(0)
		for fi in sevenz.iterate(&it) {
			if fi.type == .Directory {
				continue
			}
			data, err := extract_to_bytes(&it)
			testing.expectf(t, err == nil && i64(len(data)) == fi.size, "%s/%s: %v", name, fi.path, err)
			total += i64(len(data))
			delete(data)
		}
		sevenz.iterator_destroy(&it)
		testing.expectf(t, c.read <= size, "%s: read %d of %d bytes extracting %d", name, c.read, size, total)

		if name == "lzma2.7z" {
			c.read = 0
			for index := len(r.items) - 1; index >= 0; index -= 1 {
				d: Discard
				testing.expect_value(t, sevenz.extract(&r, {index, r.generation}, discard_writer(&d)), nil)
			}
			testing.expectf(t, c.read > 3 * size, "%s: extract by handle re-reads the folder (%d of %d)", name, c.read, size)
		}
		sevenz.close(&r)
	}
}

@(test)
test_output_limit :: proc(t: ^testing.T) {
	LIMIT :: 90_000
	r: sevenz.Reader
	if !testing.expect_value(t, sevenz.open(&r, asset("lzma2.7z"), compress.Options{max_output_size = LIMIT}), nil) {
		return
	}
	defer sevenz.close(&r)
	testing.expect_value(t, len(r.streams.folders), 1)
	testing.expect(t, r.streams.folders[0].unpack_size > LIMIT, "the solid folder is larger than the limit")

	it := sevenz.iterator_create(&r)
	defer sevenz.iterator_destroy(&it)
	refused, passed := 0, 0
	for fi in sevenz.iterate(&it) {
		data, err := extract_to_bytes(&it)
		if fi.size > LIMIT {
			refused += 1
			testing.expectf(t, err == compress.Error(compress.General_Error.Output_Too_Short) && len(data) == 0, "%s: %v, %d bytes", fi.path, err, len(data))
			_, open_err := sevenz.open_current(&it)
			testing.expectf(t, open_err == compress.Error(compress.General_Error.Output_Too_Short), "%s: open_current %v", fi.path, open_err)
		} else {
			passed += 1
			crc, _ := fi.crc32.?
			testing.expectf(t, err == nil && hash.crc32(data[:]) == crc, "%s: %v", fi.path, err)
		}
		delete(data)
	}
	testing.expect_value(t, refused, 1)
	testing.expect_value(t, passed, 5)
}

@(test)
test_memory_limit :: proc(t: ^testing.T) {
	r: sevenz.Reader
	if !testing.expect_value(t, sevenz.open(&r, asset("x9.7z"), compress.Options{max_memory = 200_000}), nil) {
		return
	}
	defer sevenz.close(&r)
	sink := strings.builder_make()
	defer strings.builder_destroy(&sink)

	fi, handle, ok, _ := sevenz.find(&r, "PROG.EXE")
	testing.expect(t, ok && .BCJ2 in fi.filters, "find PROG.EXE")
	testing.expect_value(t, sevenz.extract(&r, handle, strings.to_writer(&sink)), compress.Error(compress.General_Error.Memory_Limit_Exceeded))
	testing.expect_value(t, len(sink.buf), 0)

	_, handle, ok, _ = sevenz.find(&r, "TEXT.TXT")
	testing.expect(t, ok, "find TEXT.TXT")
	testing.expect_value(t, sevenz.extract(&r, handle, strings.to_writer(&sink)), nil)
	testing.expect_value(t, hash.crc32(sink.buf[:]), TEXT_CRC)
}

@(test)
test_encrypted :: proc(t: ^testing.T) {
	r: sevenz.Reader
	testing.expect_value(t, sevenz.open(&r, asset("aes-headers.7z")), archive.General_Error.Encrypted)
	testing.expect_value(t, sevenz.open(&r, asset("aes-headers.7z"), compress.Options{}, context.allocator, archive.Read_Options{password = "odin"}), archive.General_Error.Wrong_Password)

	if !testing.expect_value(t, sevenz.open(&r, asset("aes.7z")), nil) {
		return
	}
	fi, handle, ok, _ := sevenz.find(&r, "TEXT.TXT")
	testing.expect(t, ok && fi.encrypted && fi.supported && fi.method == .LZMA2, "TEXT.TXT is encrypted LZMA2")
	sink := strings.builder_make()
	defer strings.builder_destroy(&sink)
	testing.expect_value(t, sevenz.extract(&r, handle, strings.to_writer(&sink)), archive.General_Error.Encrypted)
	_, open_err := sevenz.open_member(&r, handle)
	testing.expect_value(t, open_err, archive.General_Error.Encrypted)
	testing.expect_value(t, sevenz.extract(&r, handle, strings.to_writer(&sink), {password = "odin"}), archive.General_Error.Wrong_Password)
	strings.builder_reset(&sink)
	testing.expect_value(t, sevenz.extract(&r, handle, strings.to_writer(&sink), {password = PASSWORD}), nil)
	testing.expect_value(t, hash.crc32(sink.buf[:]), TEXT_CRC)

	fi, handle, ok, _ = sevenz.find(&r, "EMPTY.TXT")
	testing.expect(t, ok && !fi.encrypted && fi.supported && fi.size == 0, "EMPTY.TXT has no stream")
	testing.expect_value(t, sevenz.extract(&r, handle, strings.to_writer(&sink)), nil)
	sevenz.close(&r)

	if !testing.expect_value(t, sevenz.open(&r, asset("aes.7z"), compress.Options{}, context.allocator, archive.Read_Options{password = "odin"}), nil) {
		return
	}
	it := sevenz.iterator_create(&r)
	for member in sevenz.iterate(&it) {
		if member.path != "TEXT.TXT" {
			continue
		}
		strings.builder_reset(&sink)
		testing.expect_value(t, sevenz.extract_current(&it, strings.to_writer(&sink)), archive.General_Error.Wrong_Password)
		strings.builder_reset(&sink)
		testing.expect_value(t, sevenz.extract_current(&it, strings.to_writer(&sink), {password = PASSWORD}), nil)
		testing.expect_value(t, hash.crc32(sink.buf[:]), TEXT_CRC)
		strings.builder_reset(&sink)
		testing.expect_value(t, sevenz.extract_current(&it, strings.to_writer(&sink)), archive.General_Error.Wrong_Password)
	}
	sevenz.iterator_destroy(&it)
	sevenz.close(&r)

	if testing.expect_value(t, sevenz.open(&r, asset("aes-copy.7z")), nil) {
		_, handle, ok, _ = sevenz.find(&r, "TEXT.TXT")
		testing.expect(t, ok, "find TEXT.TXT in aes-copy.7z")
		strings.builder_reset(&sink)
		testing.expect_value(t, sevenz.extract(&r, handle, strings.to_writer(&sink), {password = "odin"}), archive.General_Error.Wrong_Password)
		sevenz.close(&r)
	}

	a, a_err := archive.open(asset("aes-headers.7z"), compress.Options{}, context.allocator, archive.Read_Options{password = PASSWORD})
	if testing.expect_value(t, a_err, nil) {
		fi, handle, ok, _ = archive.find(&a, "TEXT.TXT")
		testing.expect(t, ok && fi.encrypted, "find TEXT.TXT through archive.open")
		strings.builder_reset(&sink)
		testing.expect_value(t, archive.extract(&a, handle, strings.to_writer(&sink)), nil)
		testing.expect_value(t, hash.crc32(sink.buf[:]), TEXT_CRC)
		archive.close(&a)
	}
}

@(test)
test_entries :: proc(t: ^testing.T) {
	Want :: struct {
		file:    string,
		path:    string,
		type:    archive.Entry_Type,
		mode:    u32,
		dos:     u32,
		size:    i64,
		link:    string,
	}
	wants := [?]Want{
		{"tree.7z",                 "TREE",                .Directory, 0o40755,  0x10, 0,  ""},
		{"tree.7z",                 "TREE/EMPTYDIR",       .Directory, 0o40755,  0x10, 0,  ""},
		{"tree.7z",                 "TREE/READONLY.TXT",   .Regular,   0o100444, 0x21, 11, ""},
		{"tree.7z",                 "TREE/SUB/EMPTY.TXT",  .Regular,   0o100644, 0x20, 0,  ""},
		{"tree.7z",                 "TREE/ÜBER.TXT",       .Regular,   0o100644, 0x20, 18, ""},
		{"tree.7z",                 "TREE/日本語.TXT",     .Regular,   0o100644, 0x20, 16, ""},
		{"libarchive-mac-lzma2.7z", "tree/link.txt",       .Symlink,   0o120777, 0x20, 10, "README.TXT"},
		{"libarchive-mac-lzma2.7z", "tree/run.sh",         .Regular,   0o100755, 0x20, 20, ""},
		{"libarchive-mac-lzma2.7z", "tree/sub/deep/LICENSE", .Regular, 0o100600, 0x20, 892, ""},
		{"libarchive-mac-lzma2.7z", "tree/emptydir",       .Directory, 0o40700,  0x10, 0,  ""},
		{"empty-only.7z",           "TREE/EMPTYDIR",       .Directory, 0o40755,  0x10, 0,  ""},
		{"empty-only.7z",           "EMPTY.TXT",           .Regular,   0o100644, 0x20, 0,  ""},
	}
	for w in wants {
		r: sevenz.Reader
		if !testing.expectf(t, sevenz.open(&r, asset(w.file)) == nil, "%s: open", w.file) {
			continue
		}
		defer sevenz.close(&r)
		it := sevenz.iterator_create(&r)
		defer sevenz.iterator_destroy(&it)
		seen := false
		for fi in sevenz.iterate(&it) {
			if fi.path != w.path {
				continue
			}
			seen = true
			testing.expectf(t, fi.type == w.type, "%s/%s: type %v", w.file, w.path, fi.type)
			testing.expectf(t, fi.unix_mode == w.mode, "%s/%s: mode %o", w.file, w.path, fi.unix_mode)
			testing.expectf(t, fi.dos_attributes == w.dos, "%s/%s: attributes %x", w.file, w.path, fi.dos_attributes)
			testing.expectf(t, fi.size == w.size, "%s/%s: size %d", w.file, w.path, fi.size)
			target, link_err := sevenz.read_link(&it)
			testing.expectf(t, link_err == nil && target == w.link, "%s/%s: link %q %v", w.file, w.path, target, link_err)
			delete(target)
			found, _, ok, _ := sevenz.find(&r, w.path)
			testing.expectf(t, ok && found.path == w.path, "%s/%s: find", w.file, w.path)
		}
		testing.expectf(t, seen, "%s/%s: missing", w.file, w.path)
	}
}

@(test)
test_times :: proc(t: ^testing.T) {
	Want :: struct {
		file:     string,
		modified: bool,
		created:  bool,
		accessed: bool,
	}
	wants := [?]Want{
		{"lzma2.7z",          true,  false, false},
		{"header-times.7z",   true,  true,  true},
		{"header-notimes.7z", false, false, false},
	}
	for w in wants {
		r: sevenz.Reader
		if !testing.expectf(t, sevenz.open(&r, asset(w.file)) == nil, "%s: open", w.file) {
			continue
		}
		fi, _, ok, _ := sevenz.find(&r, "TEXT.TXT")
		testing.expectf(t, ok, "%s: find TEXT.TXT", w.file)
		if w.modified {
			testing.expectf(t, time.to_unix_seconds(fi.modification_time) == SOURCE_TIME, "%s: mtime %v", w.file, fi.modification_time)
		} else {
			testing.expectf(t, fi.modification_time == {}, "%s: mtime %v", w.file, fi.modification_time)
		}
		testing.expectf(t, (fi.creation_time != {}) == w.created, "%s: ctime %v", w.file, fi.creation_time)
		testing.expectf(t, (fi.access_time != {}) == w.accessed, "%s: atime %v", w.file, fi.access_time)
		sevenz.close(&r)
	}
}

@(test)
test_read_sizes :: proc(t: ^testing.T) {
	for name in ([?]string{"x9.7z", "bcj-delta.7z", "bcj2.7z", "lzma2-chunks.7z", "swap2.7z", "deflate64.7z"}) {
		data, read_err := os.read_entire_file(asset(name), context.allocator)
		if !testing.expectf(t, read_err == nil, "%s: %v", name, read_err) {
			continue
		}
		defer delete(data)
		for with_progress in ([?]bool{false, true}) {
			options: compress.Options
			if with_progress {
				options.progress = progress_ignore
			}
			r: sevenz.Reader
			if !testing.expectf(t, sevenz.open(&r, data, options) == nil, "%s: open", name) {
				continue
			}
			it := sevenz.iterator_create(&r)
			for fi in sevenz.iterate(&it) {
				want, err := extract_to_bytes(&it)
				testing.expectf(t, err == nil, "%s/%s: %v", name, fi.path, err)
				for size in ([?]int{1, 7, 4096, 1 << 17}) {
					m, open_err := sevenz.open_member(&r, fi.handle)
					if !testing.expectf(t, open_err == nil, "%s/%s: open_member %v", name, fi.path, open_err) {
						continue
					}
					got, got_err := read_stream(m, size)
					testing.expectf(t, got_err == nil && bytes.equal(got[:], want[:]), "%s/%s: read size %d: %v", name, fi.path, size, got_err)
					delete(got)
					sevenz.close_member(m)
				}
				delete(want)
			}
			sevenz.iterator_destroy(&it)
			sevenz.close(&r)
		}
	}
}

@(test)
test_progress :: proc(t: ^testing.T) {
	Want :: struct {
		file:    string,
		path:    string,
		solid:   bool,
	}
	wants := [?]Want{
		{"lzma2.7z",     "TEXT.TXT", true},
		{"solid-off.7z", "TEXT.TXT", false},
		{"bcj2.7z",      "X86.BIN",  false},
		{"copy.7z",      "TEXT.TXT", false},
		{"lzma-lc4.7z",  "TEXT.TXT", false},
	}
	for w in wants {
		data, read_err := os.read_entire_file(asset(w.file), context.allocator)
		if !testing.expectf(t, read_err == nil, "%s: %v", w.file, read_err) {
			continue
		}
		defer delete(data)
		log: Progress_Log
		defer delete(log.calls)
		options := compress.Options{progress = progress_record, progress_data = &log, progress_interval = 4096}
		r: sevenz.Reader
		if !testing.expectf(t, sevenz.open(&r, data, options) == nil, "%s: open", w.file) {
			continue
		}
		defer sevenz.close(&r)
		fi, handle, ok, _ := sevenz.find(&r, w.path)
		testing.expectf(t, ok, "%s: find %s", w.file, w.path)
		m, open_err := sevenz.open_member(&r, handle)
		if !testing.expectf(t, open_err == nil, "%s: open_member %v", w.file, open_err) {
			continue
		}
		got, got_err := read_stream(m, 4096)
		testing.expectf(t, got_err == nil && i64(len(got)) == fi.size, "%s: read %v %d", w.file, got_err, len(got))
		delete(got)
		sevenz.close_member(m)
		if !testing.expectf(t, i64(len(log.calls)) >= fi.size / 4096, "%s: %d reports", w.file, len(log.calls)) {
			continue
		}
		last := log.calls[len(log.calls) - 1]
		testing.expectf(t, last.bytes_out == fi.size && last.total_out == fi.size, "%s: last %v", w.file, last)
		testing.expectf(t, last.member == w.path && last.member_index == handle.index && last.member_count == len(r.items), "%s: member %v", w.file, last)
		testing.expectf(t, last.archive_total_in == i64(len(data)) && last.archive_in <= last.archive_total_in, "%s: archive %v", w.file, last)
		item := r.items[handle.index]
		folder := r.streams.folders[item.folder]
		testing.expectf(t, item.folder_offset + item.size == folder.unpack_size, "%s: %s does not end its folder", w.file, w.path)
		folder_end := r.streams.pack_offsets[folder.first_pack] + folder.pack_size
		testing.expectf(t, last.archive_in == folder_end, "%s: archive_in %d, folder ends at %d", w.file, last.archive_in, folder_end)
		if w.solid {
			testing.expectf(t, last.total_in == -1 && fi.compressed_size == -1, "%s: solid total_in %d", w.file, last.total_in)
		} else {
			testing.expectf(t, last.total_in == fi.compressed_size && last.bytes_in == last.total_in, "%s: total_in %d bytes_in %d", w.file, last.total_in, last.bytes_in)
		}
		for i in 1..<len(log.calls) {
			a, b := log.calls[i - 1], log.calls[i]
			testing.expectf(t, b.bytes_out >= a.bytes_out && b.bytes_in >= a.bytes_in && b.archive_in >= a.archive_in, "%s: report %d goes back", w.file, i)
		}

		clear(&log.calls)
		log.cancel_at = 1
		d: Discard
		testing.expect_value(t, sevenz.extract(&r, handle, discard_writer(&d)), compress.Error(compress.General_Error.Canceled))
		testing.expect_value(t, len(log.calls), 1)
	}
}

@(test)
test_generic :: proc(t: ^testing.T) {
	a, err := archive.open(asset("solid-2f.7z"))
	if !testing.expect_value(t, err, nil) {
		return
	}
	defer archive.close(&a)
	testing.expect_value(t, a.format, archive.Format.SevenZ)
	testing.expect_value(t, archive.info(&a).member_count, 6)

	it := archive.iterator_create(&a)
	count := 0
	for fi in archive.iterate(&it) {
		r, open_err := archive.open_current(&it)
		testing.expectf(t, open_err == nil, "%s: %v", fi.path, open_err)
		data, read_err := read_stream(r, 4096)
		crc, _ := fi.crc32.?
		testing.expectf(t, read_err == nil && i64(len(data)) == fi.size && hash.crc32(data[:]) == crc, "%s: %v %d", fi.path, read_err, len(data))
		delete(data)
		count += 1
	}
	archive.iterator_destroy(&it)
	testing.expect_value(t, count, 6)

	fi, handle, ok, find_err := archive.find(&a, "./TEXT.TXT")
	if testing.expect(t, ok && find_err == nil, "find TEXT.TXT") {
		testing.expect_value(t, fi.size, TEXT_SIZE)
		sink := strings.builder_make()
		defer strings.builder_destroy(&sink)
		testing.expect_value(t, archive.extract(&a, handle, strings.to_writer(&sink)), nil)
		testing.expect_value(t, hash.crc32(sink.buf[:]), TEXT_CRC)

		r, open_err := archive.open_member(&a, handle)
		if testing.expect_value(t, open_err, nil) {
			size, _ := io.size(r)
			testing.expect_value(t, size, TEXT_SIZE)
			data, read_err := read_stream(r, 4096)
			testing.expect(t, read_err == nil && hash.crc32(data[:]) == TEXT_CRC, "open_member data")
			delete(data)
			archive.close_member(r)
		}
	}

	buf: [dynamic]u8
	defer delete(buf)
	targets := []archive.Target{
		{path = "LICENSE", to = &buf},
		{path = "missing", to = &buf},
	}
	testing.expect_value(t, archive.extract_many(&a, targets), nil)
	testing.expect(t, targets[0].found && !targets[1].found, "extract_many found flags")
	testing.expect_value(t, hash.crc32(buf[:]), 0xb047bfa7)

	data, read_err := os.read_entire_file(asset("lzma.7z"), context.allocator)
	if testing.expect_value(t, read_err, nil) {
		defer delete(data)
		b, open_err := archive.open(data)
		if testing.expect_value(t, open_err, nil) {
			testing.expect_value(t, b.format, archive.Format.SevenZ)
			archive.close(&b)
		}
	}
}

@(test)
test_handles :: proc(t: ^testing.T) {
	r: sevenz.Reader
	if !testing.expect_value(t, sevenz.open(&r, asset("lzma.7z")), nil) {
		return
	}
	defer sevenz.close(&r)
	it := sevenz.iterator_create(&r)
	defer sevenz.iterator_destroy(&it)
	sink := strings.builder_make()
	defer strings.builder_destroy(&sink)
	testing.expect_value(t, sevenz.extract_current(&it, strings.to_writer(&sink)), archive.General_Error.No_Current_Member)
	_, open_err := sevenz.open_current(&it)
	testing.expect_value(t, open_err, archive.General_Error.No_Current_Member)
	testing.expect(t, sevenz.current_entry(&it) == nil, "no current entry")
	for _ in sevenz.iterate(&it) {
	}
	testing.expect(t, sevenz.current_entry(&it) == nil, "no current entry after the end")

	_, handle, ok, _ := sevenz.find(&r, "TEXT.TXT")
	testing.expect(t, ok, "find TEXT.TXT")
	stale := handle
	stale.generation += 1
	testing.expect_value(t, sevenz.extract(&r, stale, strings.to_writer(&sink)), archive.General_Error.Not_Found)
	_, stale_err := sevenz.open_member(&r, stale)
	testing.expect_value(t, stale_err, archive.General_Error.Not_Found)
	_, _, ok, _ = sevenz.find(&r, "missing")
	testing.expect(t, !ok, "find missing")
}

@(test)
test_unsupported_sources :: proc(t: ^testing.T) {
	r: sevenz.Reader
	testing.expect_value(t, sevenz.open(&r, asset("volumes.7z.001")), SevenZ_Error.Truncated)

	f, open_err := os.open(asset("lzma.7z"))
	if testing.expect_value(t, open_err, nil) {
		ns := Non_Seekable{inner = os.to_stream(f)}
		testing.expect_value(t, sevenz.open(&r, non_seekable_stream(&ns)), archive.General_Error.Not_Seekable)
		os.close(f)
	}
	testing.expect_value(t, sevenz.open(&r, asset("lzma.7z"), compress.Options{max_output_size = -1}), archive.General_Error.Incompatible_Options)
}

check_archive :: proc(t: ^testing.T, c: Corpus_Case, source: Source_Kind, password := "") {
	read_options := archive.Read_Options{password = password}
	r: sevenz.Reader
	switch source {
	case .Path:
		err := sevenz.open(&r, asset(c.name), compress.Options{}, context.allocator, read_options)
		if !testing.expectf(t, err == nil, "%s: open %v", c.name, err) {
			return
		}
		check_reader(t, c, &r, password)
		sevenz.close(&r)
	case .Bytes, .Bytes_Progress:
		data, read_err := os.read_entire_file(asset(c.name), context.allocator)
		if !testing.expectf(t, read_err == nil, "%s: %v", c.name, read_err) {
			return
		}
		defer delete(data)
		options: compress.Options
		if source == .Bytes_Progress {
			options.progress          = progress_ignore
			options.progress_interval = 4096
		}
		err := sevenz.open(&r, data, options, context.allocator, read_options)
		if !testing.expectf(t, err == nil, "%s: open from bytes %v", c.name, err) {
			return
		}
		check_reader(t, c, &r, password)
		sevenz.close(&r)
	case .Seek_Read:
		f, open_err := os.open(asset(c.name))
		if !testing.expectf(t, open_err == nil, "%s: %v", c.name, open_err) {
			return
		}
		defer os.close(f)
		counting := Counting{inner = os.to_stream(f)}
		err := sevenz.open(&r, counting_stream(&counting), compress.Options{}, context.allocator, read_options)
		if !testing.expectf(t, err == nil, "%s: open from seek and read %v", c.name, err) {
			return
		}
		check_reader(t, c, &r, password)
		sevenz.close(&r)
	}
}

check_reader :: proc(t: ^testing.T, c: Corpus_Case, r: ^sevenz.Reader, password: string) {
	it := sevenz.iterator_create(r)
	defer sevenz.iterator_destroy(&it)
	members, directories, encrypted := 0, 0, 0
	for fi, index in sevenz.iterate(&it) {
		testing.expectf(t, index == members && fi.handle.index == index, "%s: index %d", c.name, index)
		members += 1
		if fi.type == .Directory {
			directories += 1
			continue
		}
		data, extract_err := extract_to_bytes(&it)
		defer delete(data)
		if fi.encrypted {
			encrypted += 1
			if password == "" {
				testing.expectf(t, fi.supported && extract_err == archive.General_Error.Encrypted && len(data) == 0, "%s/%s: encrypted %v", c.name, fi.path, extract_err)
				continue
			}
		}
		if !testing.expectf(t, extract_err == nil && fi.supported, "%s/%s: %v", c.name, fi.path, extract_err) {
			continue
		}
		testing.expectf(t, i64(len(data)) == fi.size, "%s/%s: size %d", c.name, fi.path, len(data))
		crc := hash.crc32(data[:])
		if stored, has_crc := fi.crc32.?; has_crc {
			testing.expectf(t, crc == stored, "%s/%s: CRC", c.name, fi.path)
		}
		if want, known := known_crc(fi.path); known && fi.type == .Regular {
			testing.expectf(t, crc == want, "%s/%s: content CRC %08x", c.name, fi.path, crc)
		}

		reader, open_err := sevenz.open_current(&it)
		if testing.expectf(t, open_err == nil, "%s/%s: open_current %v", c.name, fi.path, open_err) {
			streamed, read_err := read_stream(reader, 4096)
			testing.expectf(t, read_err == nil && bytes.equal(streamed[:], data[:]), "%s/%s: open_current %v", c.name, fi.path, read_err)
			delete(streamed)
		}

		found, handle, ok, find_err := sevenz.find(r, fi.path)
		testing.expectf(t, ok && find_err == nil && found.path == fi.path, "%s/%s: find", c.name, fi.path)
		if ok && handle.index == index {
			m, member_err := sevenz.open_member(r, handle)
			if testing.expectf(t, member_err == nil, "%s/%s: open_member %v", c.name, fi.path, member_err) {
				streamed, read_err := read_stream(m, 4096)
				testing.expectf(t, read_err == nil && bytes.equal(streamed[:], data[:]), "%s/%s: open_member %v", c.name, fi.path, read_err)
				delete(streamed)
				sevenz.close_member(m)
			}
		}
	}
	path, iter_err := sevenz.iterator_error(&it)
	testing.expectf(t, iter_err == nil, "%s: iterator %s %v", c.name, path, iter_err)
	testing.expectf(t, members == c.members, "%s: %d members", c.name, members)
	testing.expectf(t, directories == c.directories, "%s: %d directories", c.name, directories)
	testing.expectf(t, encrypted == c.encrypted, "%s: %d encrypted", c.name, encrypted)
}

known_crc :: proc(path: string) -> (crc: u32, ok: bool) {
	switch filepath.base(path) {
	case "ARM32.BIN":                           return 0x2819a7f6, true
	case "ARM64.BIN":                           return 0x793f446d, true
	case "BINARY.BIN":                          return 0xdab9f4c0, true
	case "EMPTY.TXT":                           return 0x00000000, true
	case "LICENSE":                             return 0xb047bfa7, true
	case "ONE.TXT":                             return 0xd3d99e8b, true
	case "PCM16.BIN":                           return 0xe13dbf6a, true
	case "PROG.EXE":                            return 0x1b3cc05f, true
	case "RANDOM.BIN":                          return 0xd4029d57, true
	case "RGBA.BIN":                            return 0x70411c37, true
	case "RISCV.BIN":                           return 0xd7fc9bf8, true
	case "SAME.BIN":                            return 0x6733dede, true
	case "SMALL.TXT", "README.TXT", "hard.txt": return 0x917123cb, true
	case "TEXT.TXT":                            return TEXT_CRC,   true
	case "THUMB.BIN":                           return 0x98184d55, true
	case "TONE.WAV":                            return 0x2a5059b6, true
	case "X86.BIN":                             return 0xccb58444, true
	}
	return
}

extract_to_bytes :: proc(it: ^sevenz.Iterator) -> (data: [dynamic]u8, err: archive.Error) {
	sink := strings.builder_make()
	err = sevenz.extract_current(it, strings.to_writer(&sink))
	return sink.buf, err
}

asset :: proc(name: string) -> string {
	return strings.concatenate({TEST_SUITE_PATH_7Z, name}, context.temp_allocator)
}

read_stream :: proc(r: io.Reader, size: int) -> (data: [dynamic]u8, err: io.Error) {
	chunk := make([]u8, size)
	defer delete(chunk)
	for {
		n, read_err := io.read(r, chunk)
		append(&data, ..chunk[:n])
		if read_err == .EOF {
			return data, nil
		}
		if read_err != nil {
			return data, read_err
		}
	}
}

progress_ignore :: proc(progress: compress.Progress, user_data: rawptr) -> (cancel: bool) {
	return false
}

progress_record :: proc(progress: compress.Progress, user_data: rawptr) -> (cancel: bool) {
	log := (^Progress_Log)(user_data)
	append(&log.calls, progress)
	return log.cancel_at > 0 && len(log.calls) >= log.cancel_at
}

Discard :: struct {
	count: i64,
}

discard_writer :: proc(d: ^Discard) -> (w: io.Writer) {
	w.data      = d
	w.procedure = discard_proc
	return
}

discard_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	d := (^Discard)(stream_data)
	#partial switch mode {
	case .Write:
		d.count += i64(len(p))
		return i64(len(p)), nil
	case .Query:
		return io.query_utility({.Write, .Query})
	}
	return 0, .Unsupported
}

counting_stream :: proc(c: ^Counting) -> (s: io.Stream) {
	s.data      = c
	s.procedure = counting_proc
	return
}

counting_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	c := (^Counting)(stream_data)
	#partial switch mode {
	case .Read:
		got, read_err := io.read(c.inner, p)
		c.read += i64(got)
		return i64(got), read_err
	case .Read_At:
		if !c.read_at {
			return 0, .Unsupported
		}
		got, read_err := io.read_at(c.inner, p, offset)
		c.read += i64(got)
		return i64(got), read_err
	case .Seek:
		return io.seek(c.inner, offset, whence)
	case .Size:
		return io.size(c.inner)
	case .Query:
		if c.read_at {
			return io.query_utility({.Read, .Read_At, .Seek, .Size, .Query})
		}
		return io.query_utility({.Read, .Seek, .Size, .Query})
	}
	return 0, .Unsupported
}

non_seekable_stream :: proc(w: ^Non_Seekable) -> (s: io.Stream) {
	s.data      = w
	s.procedure = non_seekable_proc
	return
}

non_seekable_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	w := (^Non_Seekable)(stream_data)
	#partial switch mode {
	case .Read:
		got, read_err := io.read(w.inner, p)
		return i64(got), read_err
	case .Query:
		return io.query_utility({.Read, .Query})
	}
	return 0, .Unsupported
}
