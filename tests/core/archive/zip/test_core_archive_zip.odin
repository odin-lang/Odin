package test_core_archive_zip

import "core:archive"
import "core:archive/zip"
import "core:bytes"
import "core:compress"
import "core:hash"
import "core:io"
import "core:os"
import "core:path/filepath"
import "core:strings"
import "core:testing"
import "core:time"
import "core:time/datetime"
import "core:time/timezone"

TEST_SUITE_PATH_ZIP :: ODIN_ROOT + "tests/core/assets/ZIP/"
SLIM_TESTS          :: #config(ODIN_TEST_SLIM, ODIN_ARCH == .riscv64)

LICENSE_CRC :: 0xb047bfa7
SMALL_CRC   :: 0x917123cb
TEXT_CRC    :: 0x61c54dab
SAME_CRC    :: 0x6733dede

CET := datetime.TZ_Region{
	name  = "CET",
	rrule = {
		has_dst    = true,
		std_name   = "CET",
		std_offset = 3600,
		std_date   = {type = .Month_Week_Day, month = 3,  week = 5, day = 0, time = 7200},
		dst_name   = "CEST",
		dst_offset = 7200,
		dst_date   = {type = .Month_Week_Day, month = 10, week = 5, day = 0, time = 10800},
	},
}

Source_Kind :: enum u8 {
	Path,
	Bytes,
}

Corpus_Case :: struct {
	name:        string,
	members:     int,
	encrypted:   int,
	unsupported: int,
}

Discard :: struct {
	count: i64,
}

Non_Seekable :: struct {
	inner: io.Stream,
}

CORPUS :: [?]Corpus_Case{
	{"archives/7z-aes128.zip",                       6,  6, 0},
	{"archives/7z-aes192-stored.zip",                6,  6, 0},
	{"archives/7z-aes256.zip",                       6,  6, 0},
	{"archives/7z-bzip2.zip",                        6,  0, 0},
	{"archives/7z-deflate64.zip",                    13, 0, 0},
	{"archives/7z-lzma.zip",                         6,  0, 0},
	{"archives/7z-ppmd.zip",                         6,  0, 0},
	{"archives/7z-store.zip",                        13, 0, 0},
	{"archives/7z-utf8.zip",                         7,  0, 0},
	{"archives/7z-xz-code.zip",                      2,  0, 2},
	{"archives/7z-xz.zip",                           4,  0, 1},
	{"archives/7z-zipcrypto.zip",                    6,  6, 0},
	{"archives/ditto-utf8.zip",                      13, 0, 0},
	{"archives/ditto.zip",                           12, 0, 0},
	{"archives/explorer-cp437.zip",                  9,  0, 0},
	{"archives/iz-nodirs-9.zip",                     10, 0, 0},
	{"archives/iz-store.zip",                        14, 0, 0},
	{"archives/iz-stream-zip64.zip",                 4,  0, 0},
	{"archives/iz-stream.zip",                       6,  0, 0},
	{"archives/iz-unix.zip",                         9,  0, 0},
	{"archives/iz-utf8.zip",                         7,  0, 0},
	{"archives/iz-zip64.zip",                        6,  0, 0},
	{"archives/iz-zipcrypto.zip",                    14, 10, 0},
	{"archives/libarchive-mac-aes256.zip",           14, 8, 0},
	{"archives/libarchive-mac-deflate.zip",          14, 0, 0},
	{"archives/libarchive-mac-store.zip",            14, 0, 0},
	{"archives/libarchive-mac-zipcrypto.zip",        14, 8, 0},
	{"archives/libarchive-win-aes256.zip",           12, 7, 0},
	{"archives/libarchive-win-deflate.zip",          12, 0, 0},
	{"archives/libarchive-win-store.zip",            12, 0, 0},
	{"archives/libarchive-win-zipcrypto.zip",        12, 7, 0},
	{"archives/pkzip110-sfx.exe",                    2,  0, 0},
	{"archives/pkzip110-zipcrypto-implode.zip",      4,  4, 0},
	{"archives/pkzip110-zipcrypto-shrink.zip",       4,  4, 0},
	{"archives/pkzip204-comment-fake-signatures.zip", 2, 0, 0},
	{"archives/pkzip204-comments.zip",               2,  0, 0},
	{"archives/pkzip204-paths.zip",                  6,  0, 0},
	{"archives/pkzip204-sfx.exe",                    2,  0, 0},
	{"archives/pkzip204-zipcrypto-deflate.zip",      5,  5, 0},
	{"archives/pkzip204-zipcrypto-store.zip",        5,  5, 0},
	{"archives/powershell51.zip",                    11, 0, 0},
	{"archives/pwsh7.zip",                           11, 0, 0},
	{"archives/xz-bcj.zip",                          3,  0, 3},
	{"archives/xz-sha256-multiblock.zip",            1,  0, 1},
	{"pkzip-legacy.zip",                             40, 0, 0},
	{"deflate.zip",                                  39, 0, 0},
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
test_methods :: proc(t: ^testing.T) {
	methods: bit_set[archive.Method]
	for name in ([?]string{"pkzip-legacy.zip", "deflate.zip"}) {
		r: zip.Reader
		err := zip.open(&r, asset(name))
		if !testing.expectf(t, err == nil, "%s: open %v", name, err) {
			continue
		}
		defer zip.close(&r)
		it := zip.iterator_create(&r)
		defer zip.iterator_destroy(&it)
		for fi in zip.iterate(&it) {
			methods += {fi.method}
			data, extract_err := extract_to_bytes(&it)
			defer delete(data)
			testing.expectf(t, extract_err == nil, "%s/%s: %v", name, fi.path, extract_err)
			crc, has_crc := fi.crc32.?
			testing.expectf(t, has_crc && hash.crc32(data[:]) == crc, "%s/%s: CRC", name, fi.path)
		}
	}
	testing.expect_value(t, methods, bit_set[archive.Method]{.Store, .Shrink, .Reduce, .Implode, .Deflate, .Deflate64})
}

@(test)
test_names :: proc(t: ^testing.T) {
	Want :: struct {
		archive: string,
		path:    string,
	}
	wants := [?]Want{
		{"archives/7z-utf8.zip",              "unicode/日本語のファイル.txt"},
		{"archives/7z-utf8.zip",              "unicode/emoji 😀 file.txt"},
		{"archives/iz-utf8.zip",              "unicode/café naïve résumé.txt"},
		{"archives/ditto-utf8.zip",           "unicode/Ωμέγα αλφα.txt"},
		{"archives/explorer-cp437.zip",       "Explorer/café naïve résumé.txt"},
		{"archives/explorer-cp437.zip",       "Explorer/Sub folder/Ünïcödé ß.txt"},
		{"archives/libarchive-win-deflate.zip", "tree/ÜBER.TXT"},
		{"archives/powershell51.zip",         "tree/sub/deep/LICENSE"},
		{"archives/powershell51.zip",         "tree/日本語.TXT"},
		{"archives/pwsh7.zip",                "tree/sub/deep/LICENSE"},
	}
	for w in wants {
		r: zip.Reader
		err := zip.open(&r, asset(w.archive))
		if !testing.expectf(t, err == nil, "%s: open %v", w.archive, err) {
			continue
		}
		fi, _, ok, find_err := zip.find(&r, w.path)
		testing.expectf(t, ok && find_err == nil, "%s: %q not found (%v)", w.archive, w.path, find_err)
		testing.expectf(t, !ok || fi.path == w.path, "%s: got %q", w.archive, fi.path)
		zip.close(&r)
	}

	r: zip.Reader
	if err := zip.open(&r, asset("archives/powershell51.zip")); testing.expect_value(t, err, nil) {
		fi, _, ok, _ := zip.find(&r, "tree/sub/deep/LICENSE")
		testing.expect(t, ok && strings.contains(string(fi.raw_path), "\\"), "powershell51: raw path keeps backslashes")
		zip.close(&r)
	}
}

@(test)
test_unix :: proc(t: ^testing.T) {
	Want :: struct {
		path: string,
		type: archive.Entry_Type,
		mode: u32,
		link: string,
	}
	wants := [?]Want{
		{"unix/",             .Directory, 0o40755,  ""},
		{"unix/link-inside",  .Symlink,   0o120755, "LICENSE"},
		{"unix/link-escape",  .Symlink,   0o120755, "../../../etc/passwd"},
		{"unix/link-to-dir",  .Symlink,   0o120755, "bin"},
		{"unix/bin/run.sh",   .Regular,   0o100755, ""},
		{"unix/private.txt",  .Regular,   0o100600, ""},
		{"unix/empty/",       .Directory, 0o40755,  ""},
	}
	r: zip.Reader
	err := zip.open(&r, asset("archives/iz-unix.zip"))
	if !testing.expect_value(t, err, nil) {
		return
	}
	defer zip.close(&r)
	it := zip.iterator_create(&r)
	defer zip.iterator_destroy(&it)
	seen := 0
	for fi in zip.iterate(&it) {
		testing.expectf(t, fi.uid == 501 && fi.gid == 20, "%s: uid %d gid %d", fi.path, fi.uid, fi.gid)
		testing.expectf(t, fi.extended_metadata, "%s: extended_metadata", fi.path)
		for w in wants {
			if w.path != fi.path {
				continue
			}
			seen += 1
			testing.expectf(t, fi.type == w.type, "%s: type %v", fi.path, fi.type)
			testing.expectf(t, fi.unix_mode == w.mode, "%s: mode %o", fi.path, fi.unix_mode)
			target, link_err := zip.read_link(&it)
			testing.expectf(t, link_err == nil && target == w.link, "%s: link %q %v", fi.path, target, link_err)
			delete(target)
		}

		entry := zip.current_entry(&it)
		testing.expect(t, entry != nil && entry.has_local, "current_entry has the local header")
		ids: [dynamic]zip.Extra_ID
		defer delete(ids)
		extra := entry.local_extra
		for id in zip.next_extra(&extra) {
			append(&ids, id)
		}
		testing.expectf(t, len(ids) == 2 && ids[0] == .Timestamp && ids[1] == .Unix, "%s: local extras %v", fi.path, ids[:])
	}
	testing.expect_value(t, seen, len(wants))
}

@(test)
test_times :: proc(t: ^testing.T) {
	Want :: struct {
		archive: string,
		path:    string,
		time:    i64,
		cet:     bool,
	}
	wants := [?]Want{
		{"archives/7z-utf8.zip",          "unicode/emoji 😀 file.txt", 1_794_014_043_022_204_500, false},
		{"archives/iz-unix.zip",          "unix/LICENSE",              1_794_014_097_000_000_000, false},
		{"archives/ditto.zip",            "mac/LICENSE",               1_794_014_097_000_000_000, false},
		{"archives/pkzip204-paths.zip",   "TREE/LICENSE",              1_793_665_814_000_000_000, true},
	}
	for w in wants {
		r: zip.Reader
		err := zip.open(&r, asset(w.archive))
		if !testing.expectf(t, err == nil, "%s: open %v", w.archive, err) {
			continue
		}
		if w.cet {
			timezone.region_destroy(r.zone, r.allocator)
			r.zone = &CET
		}
		fi, _, ok, _ := zip.find(&r, w.path)
		testing.expectf(t, ok, "%s: %q not found", w.archive, w.path)
		testing.expectf(t, time.to_unix_nanoseconds(fi.modification_time) == w.time, "%s/%s: mtime %v", w.archive, w.path, fi.modification_time)
		if w.cet {
			r.zone = nil
		}
		zip.close(&r)
	}
}

@(test)
test_structure :: proc(t: ^testing.T) {
	r: zip.Reader
	err := zip.open(&r, asset("archives/iz-70000-entries.zip"))
	if testing.expect_value(t, err, nil) {
		testing.expect_value(t, zip.info(&r).member_count, 70_001)
		testing.expect(t, r.zip64, "70000 entries: ZIP64 end record")
		fi, _, ok, _ := zip.find(&r, "many/69999.txt")
		testing.expect(t, ok && fi.size == 0, "70000 entries: find")
		zip.close(&r)
	}

	err = zip.open(&r, asset("archives/iz-stream-zip64.zip"))
	if testing.expect_value(t, err, nil) {
		testing.expect(t, !r.zip64, "streamed ZIP64 has no ZIP64 end record")
		zip.close(&r)
	}

	err = zip.open(&r, asset("archives/pkzip204-comment-fake-signatures.zip"))
	if testing.expect_value(t, err, nil) {
		comment := zip.info(&r).comment
		testing.expectf(t, strings.has_prefix(comment, "Archive comment with a fake") && strings.contains(comment, "PK\x05\x06"), "comment %q", comment)
		zip.close(&r)
	}

	err = zip.open(&r, asset("archives/pkzip204-comments.zip"))
	if testing.expect_value(t, err, nil) {
		testing.expect_value(t, zip.info(&r).comment, "ZIP file with file + archive comments")
		it := zip.iterator_create(&r)
		for fi in zip.iterate(&it) {
			testing.expectf(t, fi.comment != "" && fi.extended_metadata, "%s: file comment %q", fi.path, fi.comment)
		}
		zip.iterator_destroy(&it)
		zip.close(&r)
	}

	err = zip.open(&r, asset("archives/iz-split.zip"))
	testing.expect_value(t, err, Zip_Error.Split_Archive)
	err = zip.open(&r, asset("archives/iz-split.z01"))
	testing.expect_value(t, err, Zip_Error.End_Not_Found)
}

@(test)
test_prepended :: proc(t: ^testing.T) {
	for name in ([?]string{"archives/iz-store.zip", "archives/iz-zip64.zip", "archives/7z-deflate64.zip"}) {
		data, read_err := os.read_entire_file(asset(name), context.allocator)
		if !testing.expectf(t, read_err == nil, "%s: %v", name, read_err) {
			continue
		}
		defer delete(data)
		shifted := make([]u8, len(data) + 777)
		defer delete(shifted)
		copy(shifted[777:], data)
		c := Corpus_Case{name = name, members = -1}
		check_bytes(t, c, shifted)
	}
}

@(test)
test_generic :: proc(t: ^testing.T) {
	a, err := archive.open(asset("archives/7z-deflate64.zip"))
	if !testing.expect_value(t, err, nil) {
		return
	}
	defer archive.close(&a)
	testing.expect_value(t, a.format, archive.Format.Zip)
	testing.expect_value(t, archive.info(&a).member_count, 13)

	it := archive.iterator_create(&a)
	count := 0
	for fi in archive.iterate(&it) {
		if fi.type != .Regular {
			continue
		}
		r, open_err := archive.open_current(&it)
		testing.expectf(t, open_err == nil, "%s: %v", fi.path, open_err)
		data, read_err := read_stream(r)
		testing.expectf(t, read_err == nil && i64(len(data)) == fi.size, "%s: %v %d", fi.path, read_err, len(data))
		delete(data)
		count += 1
	}
	archive.iterator_destroy(&it)
	testing.expect_value(t, count, 9)

	fi, handle, ok, find_err := archive.find(&a, "./tree/TEXT.TXT")
	if testing.expect(t, ok && find_err == nil, "find tree/TEXT.TXT") {
		testing.expect_value(t, fi.size, 80_000)
		sink := strings.builder_make()
		defer strings.builder_destroy(&sink)
		testing.expect_value(t, archive.extract(&a, handle, strings.to_writer(&sink)), nil)
		testing.expect_value(t, hash.crc32(sink.buf[:]), TEXT_CRC)

		r, open_err := archive.open_member(&a, handle)
		if testing.expect_value(t, open_err, nil) {
			size, _ := io.size(r)
			testing.expect_value(t, size, 80_000)
			data, read_err := read_stream(r)
			testing.expect(t, read_err == nil && hash.crc32(data[:]) == TEXT_CRC, "open_member data")
			delete(data)
			archive.close_member(r)
		}
	}

	buf: [dynamic]u8
	defer delete(buf)
	targets := []archive.Target{
		{path = "tree/sub/deep/LICENSE", to = &buf},
		{path = "tree/missing", to = &buf},
	}
	many_err := archive.extract_many(&a, targets)
	testing.expect_value(t, many_err, nil)
	testing.expect(t, targets[0].found && !targets[1].found, "extract_many found flags")
	testing.expect_value(t, hash.crc32(buf[:]), LICENSE_CRC)

	data, read_err := os.read_entire_file(asset("archives/iz-utf8.zip"), context.allocator)
	if testing.expect_value(t, read_err, nil) {
		defer delete(data)
		b, open_err := archive.open(data)
		if testing.expect_value(t, open_err, nil) {
			testing.expect_value(t, b.format, archive.Format.Zip)
			archive.close(&b)
		}
	}
}

@(test)
test_handles :: proc(t: ^testing.T) {
	r: zip.Reader
	err := zip.open(&r, asset("archives/7z-lzma.zip"))
	if !testing.expect_value(t, err, nil) {
		return
	}
	defer zip.close(&r)

	it := zip.iterator_create(&r)
	defer zip.iterator_destroy(&it)
	sink := strings.builder_make()
	defer strings.builder_destroy(&sink)
	testing.expect_value(t, zip.extract_current(&it, strings.to_writer(&sink)), archive.General_Error.No_Current_Member)
	_, open_err := zip.open_current(&it)
	testing.expect_value(t, open_err, archive.General_Error.No_Current_Member)
	testing.expect(t, zip.current_entry(&it) == nil, "no current entry")
	for _ in zip.iterate(&it) {
	}
	testing.expect(t, zip.current_entry(&it) == nil, "no current entry after the end")

	fi, handle, ok, _ := zip.find(&r, "TEXT.TXT")
	testing.expect(t, ok && fi.method == .LZMA, "find TEXT.TXT")
	stale := handle
	stale.generation += 1
	testing.expect_value(t, zip.extract(&r, stale, strings.to_writer(&sink)), archive.General_Error.Not_Found)
	_, stale_err := zip.open_member(&r, stale)
	testing.expect_value(t, stale_err, archive.General_Error.Not_Found)

	m, member_err := zip.open_member(&r, handle)
	if testing.expect_value(t, member_err, nil) {
		data, read_err := read_stream(m)
		testing.expect(t, read_err == nil && hash.crc32(data[:]) == TEXT_CRC, "LZMA member reader")
		delete(data)
		zip.close_member(m)
	}

	limited: zip.Reader
	if testing.expect_value(t, zip.open(&limited, asset("archives/7z-lzma.zip"), compress.Options{max_output_size = 1000}), nil) {
		_, h, _, _ := zip.find(&limited, "TEXT.TXT")
		limit_err := zip.extract(&limited, h, strings.to_writer(&sink))
		testing.expectf(t, limit_err != nil, "output limit: %v", limit_err)
		zip.close(&limited)
	}
}

@(test)
test_corrupt :: proc(t: ^testing.T) {
	data, read_err := os.read_entire_file(asset("archives/7z-store.zip"), context.allocator)
	if !testing.expect_value(t, read_err, nil) {
		return
	}
	defer delete(data)

	r: zip.Reader
	testing.expect_value(t, zip.open(&r, data[:len(data) - 30]), Zip_Error.End_Not_Found)
	testing.expect_value(t, zip.open(&r, data[:10]), Zip_Error.End_Not_Found)

	text := bytes.index(data, transmute([]u8)string("tree/TEXT.TXT"))
	testing.expect(t, text > 30, "local header of tree/TEXT.TXT")
	local := text - size_of(zip.Local_Header)

	flipped := make([]u8, len(data))
	defer delete(flipped)
	copy(flipped, data)
	name_length  := int(data[local + 26]) | int(data[local + 27]) << 8
	extra_length := int(data[local + 28]) | int(data[local + 29]) << 8
	flipped[local + size_of(zip.Local_Header) + name_length + extra_length + 1000] ~= 0x55
	if testing.expect_value(t, zip.open(&r, flipped), nil) {
		_, handle, _, _ := zip.find(&r, "tree/TEXT.TXT")
		sink := strings.builder_make()
		testing.expect_value(t, zip.extract(&r, handle, strings.to_writer(&sink)), Zip_Error.CRC_Mismatch)
		strings.builder_destroy(&sink)
		m, open_err := zip.open_member(&r, handle)
		if testing.expect_value(t, open_err, nil) {
			partial, stream_err := read_stream(m)
			testing.expect_value(t, stream_err, io.Error.Unknown)
			delete(partial)
			zip.close_member(m)
		}
		zip.close(&r)
	}

	copy(flipped, data)
	flipped[local] = 'X'
	if testing.expect_value(t, zip.open(&r, flipped), nil) {
		_, handle, _, _ := zip.find(&r, "tree/TEXT.TXT")
		sink := strings.builder_make()
		testing.expect_value(t, zip.extract(&r, handle, strings.to_writer(&sink)), Zip_Error.Invalid_Local_Header)
		strings.builder_destroy(&sink)
		zip.close(&r)
	}

	f, open_err := os.open(asset("archives/7z-store.zip"))
	if testing.expect_value(t, open_err, nil) {
		ns := Non_Seekable{inner = os.to_stream(f)}
		testing.expect_value(t, zip.open(&r, non_seekable_stream(&ns)), archive.General_Error.Not_Seekable)
		os.close(f)
	}
}

@(test)
test_large :: proc(t: ^testing.T) {
	when SLIM_TESTS {
		return
	}
	r: zip.Reader
	err := zip.open(&r, asset("archives/iz-4.5GiB.zip"))
	if !testing.expect_value(t, err, nil) {
		return
	}
	defer zip.close(&r)
	fi, handle, ok, _ := zip.find(&r, "zeros-4.5GiB.bin")
	testing.expect(t, ok, "find zeros-4.5GiB.bin")
	testing.expect_value(t, fi.size, 4_831_838_208)
	d: Discard
	testing.expect_value(t, zip.extract(&r, handle, discard_writer(&d)), nil)
	testing.expect_value(t, d.count, 4_831_838_208)
}

check_archive :: proc(t: ^testing.T, c: Corpus_Case, source: Source_Kind) {
	switch source {
	case .Path:
		r: zip.Reader
		err := zip.open(&r, asset(c.name))
		if !testing.expectf(t, err == nil, "%s: open %v", c.name, err) {
			return
		}
		defer zip.close(&r)
		check_reader(t, c, &r)
	case .Bytes:
		data, read_err := os.read_entire_file(asset(c.name), context.allocator)
		if !testing.expectf(t, read_err == nil, "%s: %v", c.name, read_err) {
			return
		}
		defer delete(data)
		check_bytes(t, c, data)
	}
}

check_bytes :: proc(t: ^testing.T, c: Corpus_Case, data: []u8) {
	r: zip.Reader
	err := zip.open(&r, data)
	if !testing.expectf(t, err == nil, "%s: open from bytes %v", c.name, err) {
		return
	}
	defer zip.close(&r)
	check_reader(t, c, &r)
}

check_reader :: proc(t: ^testing.T, c: Corpus_Case, r: ^zip.Reader) {
	it := zip.iterator_create(r)
	defer zip.iterator_destroy(&it)
	members, encrypted, unsupported := 0, 0, 0
	for fi, index in zip.iterate(&it) {
		testing.expectf(t, index == members && fi.handle.index == index, "%s: index %d", c.name, index)
		members += 1
		data, extract_err := extract_to_bytes(&it)
		defer delete(data)
		switch {
		case fi.encrypted:
			encrypted += 1
			testing.expectf(t, extract_err == archive.General_Error.Encrypted && !fi.supported, "%s/%s: %v", c.name, fi.path, extract_err)
			continue
		case fi.method == .XZ:
			unsupported += 1
			testing.expectf(t, extract_err == archive.General_Error.Unsupported_Method && !fi.supported, "%s/%s: %v", c.name, fi.path, extract_err)
			continue
		}
		if !testing.expectf(t, extract_err == nil && fi.supported, "%s/%s: %v", c.name, fi.path, extract_err) {
			continue
		}
		testing.expectf(t, i64(len(data)) == fi.size, "%s/%s: size %d", c.name, fi.path, len(data))
		crc, _ := fi.crc32.?
		testing.expectf(t, hash.crc32(data[:]) == crc, "%s/%s: CRC", c.name, fi.path)
		if want, known := known_crc(fi.path); known && fi.type == .Regular {
			testing.expectf(t, crc == want, "%s/%s: content CRC %08x", c.name, fi.path, crc)
		}

		reader, open_err := zip.open_current(&it)
		if testing.expectf(t, open_err == nil, "%s/%s: open_current %v", c.name, fi.path, open_err) {
			streamed, read_err := read_stream(reader)
			testing.expectf(t, read_err == nil && bytes.equal(streamed[:], data[:]), "%s/%s: open_current %v", c.name, fi.path, read_err)
			delete(streamed)
		}

		found, handle, ok, find_err := zip.find(r, fi.path)
		testing.expectf(t, ok && find_err == nil && found.path == fi.path, "%s/%s: find", c.name, fi.path)
		if ok && handle.index == index {
			m, member_err := zip.open_member(r, handle)
			if testing.expectf(t, member_err == nil, "%s/%s: open_member %v", c.name, fi.path, member_err) {
				streamed, read_err := read_stream(m)
				testing.expectf(t, read_err == nil && bytes.equal(streamed[:], data[:]), "%s/%s: open_member %v", c.name, fi.path, read_err)
				delete(streamed)
				zip.close_member(m)
			}
		}
	}
	path, iter_err := zip.iterator_error(&it)
	testing.expectf(t, iter_err == nil, "%s: iterator %s %v", c.name, path, iter_err)
	if c.members >= 0 {
		testing.expectf(t, members == c.members, "%s: %d members", c.name, members)
	}
	testing.expectf(t, encrypted == c.encrypted, "%s: %d encrypted", c.name, encrypted)
	testing.expectf(t, unsupported == c.unsupported, "%s: %d unsupported", c.name, unsupported)
}

known_crc :: proc(path: string) -> (crc: u32, ok: bool) {
	switch filepath.base(path) {
	case "LICENSE":                         return LICENSE_CRC, true
	case "TEXT.TXT":                        return TEXT_CRC, true
	case "SAME.BIN":                        return SAME_CRC, true
	case "SMALL.TXT", "README.TXT", "hard.txt": return SMALL_CRC, true
	}
	return
}

extract_to_bytes :: proc(it: ^zip.Iterator) -> (data: [dynamic]u8, err: zip.Error) {
	sink := strings.builder_make()
	err = zip.extract_current(it, strings.to_writer(&sink))
	return sink.buf, err
}

asset :: proc(name: string) -> string {
	return strings.concatenate({TEST_SUITE_PATH_ZIP, name}, context.temp_allocator)
}

read_stream :: proc(r: io.Reader) -> (data: [dynamic]u8, err: io.Error) {
	chunk: [4096]u8
	for {
		n, read_err := io.read(r, chunk[:])
		append(&data, ..chunk[:n])
		if read_err == .EOF {
			return data, nil
		}
		if read_err != nil {
			return data, read_err
		}
	}
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

Zip_Error :: archive.Zip_Error
