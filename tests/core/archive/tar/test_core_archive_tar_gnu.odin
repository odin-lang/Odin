package test_core_archive_tar

import "core:archive"
import "core:archive/tar"
import "core:bytes"
import "core:compress"
import "core:fmt"
import "core:hash"
import "core:io"
import "core:strings"
import "core:testing"
import "core:time"

GNU_MAGIC        :: "ustar  \x00"
USTAR_MAGIC      :: "ustar\x0000"
SPARSE_REAL_SIZE :: 4_194_304
SPARSE_CRC       :: 0xd714bd47

Got :: struct {
	path:        string,
	link:        string,
	type:        archive.Entry_Type,
	size:        i64,
	supported:   bool,
	info:        archive.File_Info,
	data:        []u8,
	extract_err: archive.Error,
}

Gots :: struct {
	members: [dynamic]Got,
	comment: string,
	err:     archive.Error,
}

@(test)
test_gnu_corpus :: proc(t: ^testing.T) {
	ids := list_path(t, "gnu-ids.tar")
	defer listing_destroy(&ids)
	testing.expectf(t, ids.err == nil && ids.count == 4, "gnu-ids: %v, %d members", ids.err, ids.count)
	big := ids.entries["ids/big-ids.txt"]
	testing.expect_value(t, big.info.uid, 3_000_000)
	testing.expect_value(t, big.info.gid, 3_000_001)
	old := ids.entries["ids/1960.txt"]
	testing.expect_value(t, time.to_unix_seconds(old.info.modification_time), -315_619_200)
	future := ids.entries["ids/2300.txt"]
	testing.expectf(t, time.to_unix_seconds(future.info.modification_time) > 9_000_000_000, "2300.txt mtime %v", future.info.modification_time)

	incremental := list_path(t, "gnu-incremental.tar")
	defer listing_destroy(&incremental)
	testing.expectf(t, incremental.err == nil && incremental.count == 14, "gnu-incremental: %v, %d members", incremental.err, incremental.count)
	for path in ([?]string{"tree", "tree/emptydir", "tree/sub", "tree/sub/deep"}) {
		dir := incremental.entries[path]
		testing.expectf(t, dir.type == .Directory && dir.size == 0 && dir.data_len == 0, "gnu-incremental: %s %v", path, dir)
	}
	one := incremental.entries["tree/ONE.TXT"]
	testing.expect_value(t, time.to_unix_seconds(one.info.access_time), 1_794_156_220)

	label: tar.Reader
	testing.expect_value(t, tar.open(&label, asset("gnu-label.tar")), nil)
	testing.expect_value(t, tar.info(&label).comment, "")
	it := tar.iterator_create(&label)
	count := 0
	for fi, index in tar.iterate(&it) {
		if count == 0 {
			testing.expectf(t, index == 0 && fi.path == "tree", "gnu-label first member %d %q", index, fi.path)
		}
		count += 1
	}
	_, label_err := tar.iterator_error(&it)
	tar.iterator_destroy(&it)
	testing.expect_value(t, label_err, nil)
	testing.expect_value(t, count, 14)
	testing.expect_value(t, tar.info(&label).comment, "ODIN")
	testing.expect_value(t, tar.info(&label).member_count, 14)
	tar.close(&label)

	Volume :: struct {
		file:      string,
		comment:   string,
		members:   []string,
		supported: []bool,
		err:       archive.Error,
	}
	volumes := [?]Volume{
		{"gnu-multivolume-1.tar", "ODIN-MV Volume 1", {"mv", "mv/RANDOM.BIN"},          {true, true},  archive.Tar_Error.Truncated},
		{"gnu-multivolume-2.tar", "ODIN-MV Volume 2", {"mv/RANDOM.BIN", "mv/TEXT.TXT"}, {false, true}, archive.Tar_Error.Truncated},
		{"gnu-multivolume-3.tar", "ODIN-MV Volume 3", {"mv/TEXT.TXT"},                  {false},       nil},
	}
	for v in volumes {
		got := read_members(t, asset(v.file))
		defer gots_destroy(&got)
		testing.expectf(t, got.err == v.err, "%s: %v, want %v", v.file, got.err, v.err)
		testing.expectf(t, got.comment == v.comment, "%s: comment %q", v.file, got.comment)
		testing.expectf(t, len(got.members) == len(v.members), "%s: %d members", v.file, len(got.members))
		for m, i in got.members {
			if i >= len(v.members) {
				break
			}
			testing.expectf(t, m.path == v.members[i] && m.supported == v.supported[i], "%s: member %d %q supported %v", v.file, i, m.path, m.supported)
			if !m.supported {
				testing.expectf(t, m.extract_err == archive.Tar_Error.Unsupported_GNU_Extension, "%s: %q extract %v", v.file, m.path, m.extract_err)
			}
		}
	}
}

@(test)
test_sparse_corpus :: proc(t: ^testing.T) {
	Case :: struct {
		file:   string,
		stored: i64,
	}
	cases := [?]Case{
		{"gnu-sparse.tar",           24_576},
		{"gnu-sparse-posix-0.0.tar", 24_576},
		{"gnu-sparse-posix-0.1.tar", 24_576},
		{"gnu-sparse-posix-1.0.tar", 25_088},
	}
	for c in cases {
		for source in Source_Kind {
			listing := list_path(t, c.file, source)
			defer listing_destroy(&listing)
			testing.expectf(t, listing.err == nil && listing.count == 2, "%s via %v: %v, %d members", c.file, source, listing.err, listing.count)
			sparse := listing.entries["sparse/sparse.bin"]
			testing.expectf(t, sparse.type == .Regular && sparse.info.supported, "%s via %v: %v", c.file, source, sparse)
			testing.expectf(t, sparse.size == SPARSE_REAL_SIZE && sparse.data_len == SPARSE_REAL_SIZE && sparse.crc == SPARSE_CRC, "%s via %v: size %d, %d bytes, crc %08x", c.file, source, sparse.size, sparse.data_len, sparse.crc)
			if source != .Generic {
				testing.expectf(t, sparse.info.compressed_size == c.stored, "%s via %v: compressed size %d", c.file, source, sparse.info.compressed_size)
			}
		}

		r: tar.Reader
		if !testing.expect_value(t, tar.open(&r, asset(c.file)), nil) {
			continue
		}
		defer tar.close(&r)
		fi, handle, ok, find_err := tar.find(&r, "sparse/sparse.bin")
		testing.expectf(t, ok && find_err == nil && fi.size == SPARSE_REAL_SIZE, "%s: find %v %v", c.file, ok, find_err)
		member, open_err := tar.open_member(&r, handle)
		testing.expect_value(t, open_err, nil)
		size, size_err := io.size(member)
		testing.expectf(t, size == SPARSE_REAL_SIZE && size_err == nil, "%s: io.size %d %v", c.file, size, size_err)
		crc, total, read_err := read_chunked(member, 1)
		testing.expectf(t, read_err == nil && total == SPARSE_REAL_SIZE && crc == SPARSE_CRC, "%s: chunked %v %d %08x", c.file, read_err, total, crc)

		buf: bytes.Buffer
		testing.expect_value(t, tar.extract(&r, handle, bytes.buffer_to_stream(&buf)), nil)
		testing.expectf(t, hash.crc32(bytes.buffer_to_bytes(&buf)) == SPARSE_CRC, "%s: extract by handle", c.file)
		bytes.buffer_destroy(&buf)

		it := tar.iterator_create(&r)
		for item in tar.iterate(&it) {
			if item.path != "sparse/sparse.bin" {
				continue
			}
			head := make([]u8, 524_300)
			defer delete(head)
			reader, reader_err := tar.open_current(&it)
			testing.expect_value(t, reader_err, nil)
			n, head_err := io.read_full(reader, head)
			testing.expectf(t, n == len(head) && head_err == nil, "%s: head %d %v", c.file, n, head_err)
			rest: bytes.Buffer
			testing.expect_value(t, tar.extract_current(&it, bytes.buffer_to_stream(&rest)), nil)
			joined := hash.crc32(bytes.buffer_to_bytes(&rest), hash.crc32(head))
			testing.expectf(t, joined == SPARSE_CRC && n + bytes.buffer_length(&rest) == SPARSE_REAL_SIZE, "%s: read then extract", c.file)
			bytes.buffer_destroy(&rest)
		}
		_, it_err := tar.iterator_error(&it)
		testing.expect_value(t, it_err, nil)
		tar.iterator_destroy(&it)
	}
}

@(test)
test_gnu_long_names :: proc(t: ^testing.T) {
	data: [dynamic]u8
	defer delete(data)
	raw_member(&data, "././@LongLink", "from-longlink/a.txt\x00", 'L', GNU_MAGIC)
	add_records(&data, 'x', {{"path", "from-pax/a.txt"}})
	raw_member(&data, "header/a.txt", "A", '0', GNU_MAGIC)
	add_records(&data, 'x', {{"path", "from-pax/b.txt"}})
	raw_member(&data, "././@LongLink", "from-longlink/b.txt\x00", 'L', GNU_MAGIC)
	raw_member(&data, "header/b.txt", "B", '0', GNU_MAGIC)
	raw_member(&data, "././@LongLink", "first/c.txt\x00", 'L', GNU_MAGIC)
	raw_member(&data, "././@LongLink", "second/c.txt\x00junk", 'L', GNU_MAGIC)
	raw_member(&data, "header/c.txt", "C", '0', GNU_MAGIC)
	long_link := strings.repeat("t", 300, context.temp_allocator)
	raw_member(&data, "././@LongLink", strings.concatenate({long_link, "\x00"}, context.temp_allocator), 'K', GNU_MAGIC)
	link := raw_member(&data, "link", "", '2', GNU_MAGIC)
	copy(data[link + 157:][:100], "short-target")
	fix_checksum(data[link:][:512])
	raw_member(&data, "././@LongLink", "ignored-target\x00", 'K', GNU_MAGIC)
	add_records(&data, 'x', {{"linkpath", "pax-target"}})
	raw_member(&data, "link2", "", '2', GNU_MAGIC)
	long_dir := strings.repeat("d", 150, context.temp_allocator)
	raw_member(&data, "././@LongLink", strings.concatenate({long_dir, "/\x00"}, context.temp_allocator), 'L', GNU_MAGIC)
	raw_member(&data, "dddd", "", '5', GNU_MAGIC)
	raw_member(&data, "././@LongLink", "ustar/long.txt\x00", 'L', GNU_MAGIC)
	raw_member(&data, "short.txt", "U", '0', USTAR_MAGIC)
	raw_member(&data, "././@LongLink", "", 'L', GNU_MAGIC)
	raw_member(&data, "empty-long.txt", "E", '0', GNU_MAGIC)
	resize(&data, len(data) + 1024)

	got := read_members(t, data[:])
	defer gots_destroy(&got)
	testing.expect_value(t, got.err, nil)
	Want :: struct {
		path: string,
		link: string,
		type: archive.Entry_Type,
		data: string,
	}
	wants := [?]Want{
		{"from-pax/a.txt", "", .Regular, "A"},
		{"from-pax/b.txt", "", .Regular, "B"},
		{"second/c.txt", "", .Regular, "C"},
		{"link", long_link, .Symlink, ""},
		{"link2", "pax-target", .Symlink, ""},
		{long_dir, "", .Directory, ""},
		{"ustar/long.txt", "", .Regular, "U"},
		{"", "", .Regular, "E"},
	}
	testing.expectf(t, len(got.members) == len(wants), "%d members", len(got.members))
	for w, i in wants {
		if i >= len(got.members) {
			break
		}
		m := got.members[i]
		testing.expectf(t, m.path == w.path && m.link == w.link && m.type == w.type && string(m.data) == w.data, "member %d: %q %q %v %q", i, m.path, m.link, m.type, string(m.data))
	}
}

@(test)
test_gnu_numbers :: proc(t: ^testing.T) {
	data: [dynamic]u8
	defer delete(data)
	ids := raw_member(&data, "ids.txt", "ids", '0', GNU_MAGIC)
	copy(data[ids + 108:][:8], []u8{0x80, 0, 0, 0, 0, 0x2d, 0xc6, 0xc0})
	copy(data[ids + 116:][:8], []u8{0xbf, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff})
	for &b in data[ids + 136:][:12] {
		b = 0xff
	}
	copy(data[ids + 345:][:12], "15274123274\x00")
	fix_checksum(data[ids:][:512])
	sized := raw_member(&data, "sized.txt", "hello", '0', GNU_MAGIC)
	copy(data[sized + 124:][:12], []u8{0x80, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5})
	copy(data[sized + 345:][:12], "garbage!!!!\x00")
	fix_checksum(data[sized:][:512])
	device := raw_member(&data, "dev", "", '3', GNU_MAGIC)
	copy(data[device + 329:][:8], []u8{0x80, 0, 0, 0, 0xff, 0xff, 0xff, 0xff})
	copy(data[device + 337:][:8], []u8{0x80, 0, 0, 0, 0, 0, 0x12, 0x34})
	fix_checksum(data[device:][:512])
	resize(&data, len(data) + 1024)

	got := read_members(t, data[:])
	defer gots_destroy(&got)
	testing.expect_value(t, got.err, nil)
	if testing.expect_value(t, len(got.members), 3) {
		first := got.members[0].info
		testing.expect_value(t, first.uid, 3_000_000)
		testing.expect_value(t, first.gid, i64(1) << 62 - 1)
		testing.expect_value(t, time.to_unix_seconds(first.modification_time), -1)
		testing.expect_value(t, time.to_unix_seconds(first.access_time), 1_794_156_220)
		second := got.members[1]
		testing.expectf(t, second.size == 5 && string(second.data) == "hello", "base-256 size: %d %q", second.size, string(second.data))
		testing.expect_value(t, time.to_unix_seconds(second.info.access_time), 0)
		testing.expect_value(t, got.members[2].info.device, [2]u32{max(u32), 0x1234})
	}

	Bad :: struct {
		offset: int,
		field:  []u8,
		err:    archive.Error,
	}
	bads := [?]Bad{
		{108, {0x80, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff}, nil},
		{108, {0xc0, 0, 0, 0, 0, 0, 0, 0},                      archive.Tar_Error.Invalid_Number},
		{108, {0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff}, archive.Tar_Error.Invalid_Number},
		{100, {0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff}, archive.Tar_Error.Invalid_Number},
		{136, {0x80, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0},          archive.Tar_Error.Invalid_Number},
		{136, {0xff, 0xff, 0xff, 0xfe, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff}, archive.Tar_Error.Invalid_Number},
		{136, {0xff, 0xff, 0xff, 0xff, 0x7f, 0, 0, 0, 0, 0, 0, 0}, archive.Tar_Error.Invalid_Number},
		{136, {0x80, 0, 0, 0, 0x7f, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff}, nil},
		{124, {0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xfb}, archive.Tar_Error.Invalid_Size},
		{124, {0x80, 0, 0, 0, 0x7f, 0xff, 0xff, 0xff, 0xff, 0xff, 0xfe, 0x00}, archive.Tar_Error.Invalid_Size},
		{124, {0x80, 0, 0, 0, 0x7f, 0xff, 0xff, 0xff, 0xff, 0xff, 0xfd, 0xff}, archive.Tar_Error.Truncated},
		{329, {0x80, 0, 0, 1, 0, 0, 0, 0},                      archive.Tar_Error.Invalid_Number},
	}
	for bad, i in bads {
		one: [dynamic]u8
		defer delete(one)
		h := raw_member(&one, "bad", "", '0' if bad.offset == 124 else '3', GNU_MAGIC)
		copy(one[h + bad.offset:][:len(bad.field)], bad.field)
		fix_checksum(one[h:][:512])
		resize(&one, len(one) + 1024)
		for source in ([2]bool{false, true}) {
			bad_got := read_members(t, one[:], source)
			testing.expectf(t, bad_got.err == bad.err, "case %d (stream %v): %v, want %v", i, source, bad_got.err, bad.err)
			gots_destroy(&bad_got)
		}
	}
}

@(test)
test_time_limits :: proc(t: ^testing.T) {
	Case :: struct {
		field:  []u8,
		record: string,
		nanos:  i64,
	}
	cases := [?]Case{
		{{0x80, 0, 0, 0, 0, 0, 0, 0x02, 0x25, 0xc1, 0x7d, 0x04}, "", 9_223_372_036_000_000_000},
		{{0x80, 0, 0, 0, 0, 0, 0, 0x02, 0x25, 0xc1, 0x7d, 0x05}, "", max(i64)},
		{{0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xfd, 0xda, 0x3e, 0x82, 0xfc}, "", -9_223_372_036_000_000_000},
		{{0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xfd, 0xda, 0x3e, 0x82, 0xfb}, "", min(i64)},
		{nil, "9223372036.854775807", max(i64)},
		{nil, "9223372036.854775808", max(i64)},
		{nil, "9223372037", max(i64)},
		{nil, "-9223372036.854775808", min(i64)},
		{nil, "-9223372036.854775809", min(i64)},
		{nil, "-1.5", -1_500_000_000},
	}
	for c, i in cases {
		data: [dynamic]u8
		defer delete(data)
		if c.field != nil {
			h := raw_member(&data, "t.txt", "t", '0', GNU_MAGIC)
			copy(data[h + 136:][:12], c.field)
			fix_checksum(data[h:][:512])
		} else {
			add_records(&data, 'x', {{"mtime", c.record}})
			raw_member(&data, "t.txt", "t", '0', USTAR_MAGIC)
		}
		resize(&data, len(data) + 1024)
		got := read_members(t, data[:])
		defer gots_destroy(&got)
		if testing.expectf(t, got.err == nil && len(got.members) == 1, "case %d: %v, %d members", i, got.err, len(got.members)) {
			nanos := time.time_to_unix_nano(got.members[0].info.modification_time)
			testing.expectf(t, nanos == c.nanos, "case %d: mtime %d, want %d", i, nanos, c.nanos)
		}
	}
}

@(test)
test_gnu_types :: proc(t: ^testing.T) {
	data: [dynamic]u8
	defer delete(data)
	raw_member(&data, "VOLUME", "", 'V', "\x00\x00\x00\x00\x00\x00\x00\x00")
	raw_member(&data, "dir/", "Ya.txt\x00Nb.txt\x00Dsub\x00\x00", 'D', GNU_MAGIC)
	raw_member(&data, "a.txt", "after dumpdir", '0', GNU_MAGIC)
	raw_member(&data, "LABEL-TWO", "label data", 'V', GNU_MAGIC)
	raw_member(&data, "names", "obsolete names", 'N', GNU_MAGIC)
	part := raw_member(&data, "part.bin", "continued", 'M', GNU_MAGIC)
	copy(data[part + 369:][:12], "00000001000\x00")
	fix_checksum(data[part:][:512])
	raw_member(&data, "z.txt", "last", '0', GNU_MAGIC)
	resize(&data, len(data) + 1024)

	got := read_members(t, data[:])
	defer gots_destroy(&got)
	testing.expect_value(t, got.err, nil)
	testing.expect_value(t, got.comment, "VOLUME")
	Want :: struct {
		path:      string,
		type:      archive.Entry_Type,
		size:      i64,
		supported: bool,
		data:      string,
		err:       archive.Error,
	}
	wants := [?]Want{
		{"dir",      .Directory, 0,  true,  "",              nil},
		{"a.txt",    .Regular,   13, true,  "after dumpdir", nil},
		{"names",    .Unknown,   14, false, "",              nil},
		{"part.bin", .Regular,   9,  false, "",              archive.Tar_Error.Unsupported_GNU_Extension},
		{"z.txt",    .Regular,   4,  true,  "last",          nil},
	}
	testing.expectf(t, len(got.members) == len(wants), "%d members", len(got.members))
	for w, i in wants {
		if i >= len(got.members) {
			break
		}
		m := got.members[i]
		testing.expectf(t, m.path == w.path && m.type == w.type && m.size == w.size && m.supported == w.supported, "member %d: %q %v %d %v", i, m.path, m.type, m.size, m.supported)
		testing.expectf(t, string(m.data) == w.data && m.extract_err == w.err, "member %d: %q %v", i, string(m.data), m.extract_err)
		testing.expect_value(t, m.info.handle.index, i)
	}

	dir_reader: tar.Reader
	testing.expect_value(t, tar.open(&dir_reader, data[:]), nil)
	defer tar.close(&dir_reader)
	_, handle, found, _ := tar.find(&dir_reader, "dir")
	testing.expect(t, found, "find dir")
	buf: bytes.Buffer
	defer bytes.buffer_destroy(&buf)
	testing.expect_value(t, tar.extract(&dir_reader, handle, bytes.buffer_to_stream(&buf)), nil)
	testing.expect_value(t, bytes.buffer_length(&buf), 0)
	_, handle, found, _ = tar.find(&dir_reader, "a.txt")
	testing.expect(t, found, "find a.txt after dir")
	testing.expect_value(t, tar.extract(&dir_reader, handle, bytes.buffer_to_stream(&buf)), nil)
	testing.expect_value(t, string(bytes.buffer_to_bytes(&buf)), "after dumpdir")
}

@(test)
test_gnu_limits :: proc(t: ^testing.T) {
	big := strings.repeat("n", 700_000, context.temp_allocator)
	name := strings.concatenate({big, "\x00"}, context.temp_allocator)
	pad := strings.repeat("p", 400_000, context.temp_allocator)

	Case :: struct {
		with_records: bool,
		twice:        bool,
		err:          archive.Error,
	}
	for c in ([?]Case{{false, false, nil}, {false, true, nil}, {true, false, archive.Tar_Error.Header_Too_Large}}) {
		data: [dynamic]u8
		defer delete(data)
		if c.with_records {
			add_records(&data, 'x', {{"comment", pad}})
		}
		raw_member(&data, "././@LongLink", name, 'L', GNU_MAGIC)
		if c.twice {
			raw_member(&data, "././@LongLink", name, 'L', GNU_MAGIC)
		}
		raw_member(&data, "short", "x", '0', GNU_MAGIC)
		resize(&data, len(data) + 1024)
		got := read_members(t, data[:])
		testing.expectf(t, got.err == c.err, "%v: %v", c, got.err)
		if c.err == nil && testing.expect_value(t, len(got.members), 1) {
			testing.expect_value(t, got.members[0].path, big)
		}
		gots_destroy(&got)
	}

	small: [dynamic]u8
	defer delete(small)
	raw_member(&small, "././@LongLink", "a-name-longer-than-the-limit.txt\x00", 'K', GNU_MAGIC)
	raw_member(&small, "link", "", '2', GNU_MAGIC)
	resize(&small, len(small) + 1024)
	r: tar.Reader
	testing.expect_value(t, tar.open(&r, small[:], compress.Options{max_memory = 16}), nil)
	it := tar.iterator_create(&r)
	for _ in tar.iterate(&it) {
	}
	_, err := tar.iterator_error(&it)
	testing.expect_value(t, err, archive.Error(archive.Tar_Error.Header_Too_Large))
	tar.iterator_destroy(&it)
	tar.close(&r)
}

@(test)
test_gnu_sparse :: proc(t: ^testing.T) {
	regions := [?][2]i64{{0, 3}, {10, 4}, {20, 0}, {30, 5}}
	payload := "abcdefghijkl"

	many: [dynamic][2]i64
	defer delete(many)
	many_payload: [dynamic]u8
	defer delete(many_payload)
	for i in 0..<30 {
		append(&many, [2]i64{i64(i) * 7 + 2, 3})
		append(&many_payload, u8('A' + i % 26), u8('a' + i % 26), u8('0' + i % 10))
	}

	Case :: struct {
		regions: [][2]i64,
		payload: string,
		real:    i64,
		stored:  int,
		tamper:  enum {None, Garbage, Extended_At_End},
		err:     archive.Error,
	}
	cases := [?]Case{
		{regions[:], payload, 40, -1, .None, nil},
		{many[:], string(many_payload[:]), 300, -1, .None, nil},
		{nil, "", 100, -1, .None, nil},
		{{{0, 4}, {2, 4}}, "abcdefgh", 10, -1, .None, archive.Tar_Error.Invalid_Sparse_Map},
		{{{0, 4}, {8, 4}}, "abcdefgh", 10, -1, .None, archive.Tar_Error.Invalid_Sparse_Map},
		{{{0, 4}}, "abcd", 10, 5, .None, archive.Tar_Error.Invalid_Sparse_Map},
		{{{0, 4}}, "abcd", 10, -1, .Garbage, archive.Tar_Error.Invalid_Sparse_Map},
		{{{0, 4}}, "abcd", 10, -1, .Extended_At_End, archive.Tar_Error.Truncated},
	}
	for c, i in cases {
		data: [dynamic]u8
		defer delete(data)
		header := old_sparse_member(&data, "sparse.bin", c.regions, c.payload, c.real, c.stored)
		switch c.tamper {
		case .None:
		case .Garbage:
			copy(data[header + 386:][:3], "9x9")
			fix_checksum(data[header:][:512])
		case .Extended_At_End:
			data[header + 482] = 1
			fix_checksum(data[header:][:512])
			resize(&data, header + 512)
		}
		if c.tamper != .Extended_At_End {
			raw_member(&data, "after.txt", "after", '0', GNU_MAGIC)
			resize(&data, len(data) + 1024)
		}
		check_sparse_case(t, fmt.tprintf("old GNU case %d", i), data[:], c.regions, c.payload, c.real, c.err)
	}

	huge: [dynamic]u8
	defer delete(huge)
	old_sparse_member(&huge, "huge.bin", {{1 << 32 - 4, 4}}, "tail", 1 << 32, -1)
	resize(&huge, len(huge) + 1024)
	r: tar.Reader
	testing.expect_value(t, tar.open(&r, huge[:]), nil)
	it := tar.iterator_create(&r)
	fi, _, ok := tar.iterate(&it)
	testing.expectf(t, ok && fi.size == 1 << 32 && fi.compressed_size == 4, "huge sparse: %v %d %d", ok, fi.size, fi.compressed_size)
	reader, open_err := tar.open_current(&it)
	testing.expect_value(t, open_err, nil)
	head: [4096]u8
	n, head_err := io.read_full(reader, head[:])
	testing.expectf(t, n == len(head) && head_err == nil && bytes.count(head[:], {0}) == len(head), "huge sparse head %d %v", n, head_err)
	tar.iterator_destroy(&it)
	tar.close(&r)
}

@(test)
test_pax_sparse :: proc(t: ^testing.T) {
	regions := [?][2]i64{{0, 3}, {10, 4}, {30, 5}, {40, 0}}
	payload := "abcdefghijkl"
	map_string := "0,3,10,4,30,5,40,0"

	pairs := [][2]string{
		{"GNU.sparse.size", "40"}, {"GNU.sparse.numblocks", "4"},
		{"GNU.sparse.offset", "0"}, {"GNU.sparse.numbytes", "3"},
		{"GNU.sparse.offset", "10"}, {"GNU.sparse.numbytes", "4"},
		{"GNU.sparse.offset", "30"}, {"GNU.sparse.numbytes", "5"},
		{"GNU.sparse.offset", "40"}, {"GNU.sparse.numbytes", "0"},
	}
	Case :: struct {
		label:   string,
		records: [][2]string,
		name:    string,
		data:    string,
		path:    string,
		err:     archive.Error,
		sparse:  bool,
	}
	map_1_0 := "4\n0\n3\n10\n4\n30\n5\n40\n0\n"
	long_map: strings.Builder
	defer strings.builder_destroy(&long_map)
	long_regions: [dynamic][2]i64
	defer delete(long_regions)
	long_payload: [dynamic]u8
	defer delete(long_payload)
	fmt.sbprintf(&long_map, "%d\n", 100)
	for i in 0..<100 {
		append(&long_regions, [2]i64{i64(i) * 1000 + 999, 1})
		append(&long_payload, u8('a' + i % 26))
		fmt.sbprintf(&long_map, "%d\n1\n", i * 1000 + 999)
	}
	cases := [?]Case{
		{"0.0", pairs, "plain.bin", payload, "plain.bin", nil, true},
		{"0.0 odd", pairs[:9], "x", payload, "", archive.Tar_Error.Invalid_Sparse_Map, true},
		{"0.0 swapped", {{"GNU.sparse.size", "40"}, {"GNU.sparse.numblocks", "1"}, {"GNU.sparse.numbytes", "3"}, {"GNU.sparse.offset", "0"}}, "x", "abc", "", archive.Tar_Error.Invalid_Sparse_Map, true},
		{"0.0 numblocks", {{"GNU.sparse.size", "40"}, {"GNU.sparse.numblocks", "2"}, {"GNU.sparse.offset", "0"}, {"GNU.sparse.numbytes", "3"}}, "x", "abc", "", archive.Tar_Error.Invalid_Sparse_Map, true},
		{"0.0 no numblocks", {{"GNU.sparse.size", "40"}, {"GNU.sparse.offset", "0"}, {"GNU.sparse.numbytes", "3"}}, "x", "abc", "", archive.Tar_Error.Invalid_Sparse_Map, true},
		{"0.0 no size", {{"GNU.sparse.numblocks", "1"}, {"GNU.sparse.offset", "0"}, {"GNU.sparse.numbytes", "3"}}, "x", "abc", "", archive.Tar_Error.Invalid_Sparse_Map, true},
		{"0.1", {{"GNU.sparse.size", "40"}, {"GNU.sparse.numblocks", "4"}, {"GNU.sparse.name", "real/name.bin"}, {"GNU.sparse.map", map_string}}, "GNUSparseFile.1/name.bin", payload, "real/name.bin", nil, true},
		{"0.1 explicit", {{"GNU.sparse.major", "0"}, {"GNU.sparse.minor", "1"}, {"GNU.sparse.size", "40"}, {"GNU.sparse.numblocks", "4"}, {"GNU.sparse.map", map_string}}, "explicit.bin", payload, "explicit.bin", nil, true},
		{"0.1 odd", {{"GNU.sparse.size", "40"}, {"GNU.sparse.numblocks", "1"}, {"GNU.sparse.map", "0,3,10"}}, "x", "abc", "", archive.Tar_Error.Invalid_Sparse_Map, true},
		{"0.1 garbage", {{"GNU.sparse.size", "40"}, {"GNU.sparse.numblocks", "1"}, {"GNU.sparse.map", "0,3x"}}, "x", "abc", "", archive.Tar_Error.Invalid_Sparse_Map, true},
		{"0.1 trailing comma", {{"GNU.sparse.size", "40"}, {"GNU.sparse.numblocks", "1"}, {"GNU.sparse.map", "0,3,"}}, "x", "abc", "", archive.Tar_Error.Invalid_Sparse_Map, true},
		{"0.1 empty", {{"GNU.sparse.size", "40"}, {"GNU.sparse.numblocks", "0"}, {"GNU.sparse.map", ""}}, "empty.bin", "", "empty.bin", nil, true},
		{"0.1 sum", {{"GNU.sparse.size", "40"}, {"GNU.sparse.numblocks", "1"}, {"GNU.sparse.map", "0,3"}}, "x", "abcd", "", archive.Tar_Error.Invalid_Sparse_Map, true},
		{"0.1 past end", {{"GNU.sparse.size", "40"}, {"GNU.sparse.numblocks", "1"}, {"GNU.sparse.map", "38,3"}}, "x", "abc", "", archive.Tar_Error.Invalid_Sparse_Map, true},
		{"1.0", {{"GNU.sparse.major", "1"}, {"GNU.sparse.minor", "0"}, {"GNU.sparse.name", "one/zero.bin"}, {"GNU.sparse.realsize", "40"}}, "GNUSparseFile.0/zero.bin", sparse_1_0(map_1_0, payload), "one/zero.bin", nil, true},
		{"1.0 long map", {{"GNU.sparse.major", "1"}, {"GNU.sparse.minor", "0"}, {"GNU.sparse.realsize", "100000"}}, "long.bin", sparse_1_0(strings.to_string(long_map), string(long_payload[:])), "long.bin", nil, true},
		{"1.0 empty", {{"GNU.sparse.major", "1"}, {"GNU.sparse.minor", "0"}, {"GNU.sparse.realsize", "7"}}, "zeros.bin", sparse_1_0("0\n", ""), "zeros.bin", nil, true},
		{"1.0 past data", {{"GNU.sparse.major", "1"}, {"GNU.sparse.minor", "0"}, {"GNU.sparse.realsize", "40"}}, "x", "4\n0\n3\n", "", archive.Tar_Error.Invalid_Sparse_Map, true},
		{"1.0 garbage", {{"GNU.sparse.major", "1"}, {"GNU.sparse.minor", "0"}, {"GNU.sparse.realsize", "40"}}, "x", sparse_1_0("1\n0\nthree\n", "abc"), "", archive.Tar_Error.Invalid_Sparse_Map, true},
		{"1.0 short", {{"GNU.sparse.major", "1"}, {"GNU.sparse.minor", "0"}, {"GNU.sparse.realsize", "40"}}, "x", sparse_1_0("2\n0\n3\n", "abc"), "", archive.Tar_Error.Invalid_Sparse_Map, true},
		{"1.0 empty line", {{"GNU.sparse.major", "1"}, {"GNU.sparse.minor", "0"}, {"GNU.sparse.realsize", "40"}}, "x", sparse_1_0("1\n\n3\n", "abc"), "", archive.Tar_Error.Invalid_Sparse_Map, true},
		{"1.0 no realsize", {{"GNU.sparse.major", "1"}, {"GNU.sparse.minor", "0"}}, "x", sparse_1_0("1\n0\n3\n", "abc"), "", archive.Tar_Error.Invalid_Sparse_Map, true},
		{"unknown version", {{"GNU.sparse.major", "2"}, {"GNU.sparse.minor", "0"}, {"GNU.sparse.realsize", "40"}}, "future.bin", "whatever", "future.bin", nil, false},
		{"keys only", {{"GNU.sparse.size", "40"}}, "keys.bin", "abc", "keys.bin", nil, false},
	}
	for c in cases {
		data: [dynamic]u8
		defer delete(data)
		add_records(&data, 'x', c.records)
		raw_member(&data, c.name, c.data, '0', USTAR_MAGIC)
		raw_member(&data, "after.txt", "after", '0', USTAR_MAGIC)
		resize(&data, len(data) + 1024)
		if c.err != nil {
			check_sparse_case(t, c.label, data[:], nil, "", 0, c.err)
			continue
		}
		if !c.sparse {
			got := read_members(t, data[:])
			defer gots_destroy(&got)
			testing.expectf(t, got.err == nil && len(got.members) == 2, "%s: %v, %d members", c.label, got.err, len(got.members))
			if len(got.members) == 2 {
				m := got.members[0]
				testing.expectf(t, m.path == c.path && !m.supported && m.extract_err == archive.Tar_Error.Unsupported_GNU_Extension, "%s: %q %v %v", c.label, m.path, m.supported, m.extract_err)
				testing.expectf(t, string(got.members[1].data) == "after", "%s: after %q", c.label, string(got.members[1].data))
			}
			continue
		}
		switch c.label {
		case "1.0 long map":
			check_sparse_case(t, c.label, data[:], long_regions[:], string(long_payload[:]), 100_000, nil, c.path)
		case "0.1 empty":
			check_sparse_case(t, c.label, data[:], nil, "", 40, nil, c.path)
		case "1.0 empty":
			check_sparse_case(t, c.label, data[:], nil, "", 7, nil, c.path)
		case:
			check_sparse_case(t, c.label, data[:], regions[:], payload, 40, nil, c.path)
		}
	}

	big: strings.Builder
	defer strings.builder_destroy(&big)
	for i in 0..<70_000 {
		fmt.sbprintf(&big, "%d,0,", i)
	}
	strings.write_string(&big, "70000,0")
	data: [dynamic]u8
	defer delete(data)
	add_records(&data, 'x', {{"GNU.sparse.size", "80000"}, {"GNU.sparse.numblocks", "70001"}, {"GNU.sparse.map", strings.to_string(big)}})
	raw_member(&data, "big-map.bin", "", '0', USTAR_MAGIC)
	resize(&data, len(data) + 1024)
	got := read_members(t, data[:])
	testing.expect_value(t, got.err, archive.Tar_Error.Header_Too_Large)
	gots_destroy(&got)

	global: [dynamic]u8
	defer delete(global)
	add_records(&global, 'g', {{"GNU.sparse.size", "40"}})
	add_records(&global, 'x', pairs)
	raw_member(&global, "global.bin", payload, '0', USTAR_MAGIC)
	resize(&global, len(global) + 1024)
	global_got := read_members(t, global[:])
	defer gots_destroy(&global_got)
	testing.expect_value(t, global_got.err, nil)
	if testing.expect_value(t, len(global_got.members), 1) {
		testing.expect(t, !global_got.members[0].supported, "a global GNU.sparse key makes later members unsupported")
	}
}

check_sparse_case :: proc(t: ^testing.T, label: string, data: []u8, regions: [][2]i64, payload: string, real: i64, want: archive.Error, path := "", loc := #caller_location) {
	for stream in ([2]bool{false, true}) {
		got := read_members(t, data, stream)
		defer gots_destroy(&got)
		testing.expectf(t, got.err == want, "%s (stream %v): %v, want %v", label, stream, got.err, want, loc = loc)
		if want != nil {
			continue
		}
		if !testing.expectf(t, len(got.members) == 2, "%s: %d members", label, len(got.members), loc = loc) {
			continue
		}
		m := got.members[0]
		expected := expand(regions, payload, real)
		testing.expectf(t, m.supported && m.size == real && m.extract_err == nil, "%s: %v %d %v", label, m.supported, m.size, m.extract_err, loc = loc)
		testing.expectf(t, bytes.equal(m.data, expected), "%s: content %q", label, string(m.data[:min(len(m.data), 64)]), loc = loc)
		if path != "" {
			testing.expectf(t, m.path == path, "%s: path %q", label, m.path, loc = loc)
		}
		testing.expectf(t, string(got.members[1].data) == "after", "%s: after %q", label, string(got.members[1].data), loc = loc)

		r: tar.Reader
		testing.expect_value(t, tar.open(&r, data), nil, loc = loc)
		it := tar.iterator_create(&r)
		if _, _, ok := tar.iterate(&it); ok {
			reader, _ := tar.open_current(&it)
			chunked: [dynamic]u8
			chunk: [5]u8
			for step := 1; ; step = step % 5 + 1 {
				n, read_err := io.read(reader, chunk[:step])
				append(&chunked, ..chunk[:n])
				if read_err != nil {
					testing.expectf(t, read_err == .EOF, "%s: chunked read %v", label, read_err, loc = loc)
					break
				}
			}
			testing.expectf(t, bytes.equal(chunked[:], expected), "%s: chunked content", label, loc = loc)
			delete(chunked)
		}
		tar.iterator_destroy(&it)
		tar.close(&r)
	}
}

expand :: proc(regions: [][2]i64, payload: string, real: i64) -> []u8 {
	out := make([]u8, int(real), context.temp_allocator)
	pos := 0
	for region in regions {
		copy(out[region[0]:][:region[1]], payload[pos:][:region[1]])
		pos += int(region[1])
	}
	return out
}

sparse_1_0 :: proc(sparse_map, payload: string) -> string {
	padded := (len(sparse_map) + 511) / 512 * 512
	out := make([]u8, padded + len(payload), context.temp_allocator)
	copy(out, sparse_map)
	copy(out[padded:], payload)
	return string(out)
}

old_sparse_member :: proc(out: ^[dynamic]u8, name: string, regions: [][2]i64, payload: string, real: i64, stored: int) -> (header: int) {
	header = raw_member(out, name, "", 'S', GNU_MAGIC, len(payload) if stored < 0 else stored)
	resize(out, header + 512)
	h := out[header:][:512]
	fmt.bprintf(h[483:494], "%011o", real)
	in_header := min(len(regions), 4)
	for region, i in regions[:in_header] {
		fmt.bprintf(h[386 + i * 24:][:11], "%011o", region[0])
		fmt.bprintf(h[386 + i * 24 + 12:][:11], "%011o", region[1])
	}
	rest := regions[in_header:]
	h[482] = 1 if len(rest) > 0 else 0
	fix_checksum(h)
	for len(rest) > 0 {
		block := len(out)
		resize(out, block + 512)
		e := out[block:][:512]
		count := min(len(rest), 21)
		for region, i in rest[:count] {
			fmt.bprintf(e[i * 24:][:11], "%011o", region[0])
			fmt.bprintf(e[i * 24 + 12:][:11], "%011o", region[1])
		}
		rest = rest[count:]
		e[504] = 1 if len(rest) > 0 else 0
	}
	append(out, payload)
	pad_block(out)
	return
}

raw_member :: proc(out: ^[dynamic]u8, name: string, data: string, typeflag: u8, magic: string, size := -1) -> (header: int) {
	header = len(out)
	resize(out, header + 512)
	h := out[header:][:512]
	copy(h[0:100], name)
	copy(h[100:108], "0000644\x00")
	copy(h[108:116], "0001750\x00")
	copy(h[116:124], "0001750\x00")
	fmt.bprintf(h[124:135], "%011o", len(data) if size < 0 else size)
	copy(h[136:148], "15274062100\x00")
	h[156] = typeflag
	copy(h[257:265], magic)
	copy(h[265:297], "odin")
	copy(h[297:329], "odin")
	fix_checksum(h)
	append(out, data)
	pad_block(out)
	return
}

read_members :: proc(t: ^testing.T, source: union {[]u8, string}, stream := false) -> (got: Gots) {
	r: tar.Reader
	err: archive.Error
	br: bytes.Reader
	wrapper: Non_Seekable
	switch s in source {
	case []u8:
		if stream {
			wrapper.inner = bytes.reader_init(&br, s)
			err = tar.open(&r, non_seekable_stream(&wrapper))
		} else {
			err = tar.open(&r, s)
		}
	case string:
		err = tar.open(&r, s)
	}
	defer tar.close(&r)
	if err != nil {
		got.err = err
		return
	}
	it := tar.iterator_create(&r)
	defer tar.iterator_destroy(&it)
	for fi in tar.iterate(&it) {
		cloned, _ := archive.file_info_clone(fi, context.allocator)
		m := Got{
			path      = cloned.path,
			link      = cloned.link_target,
			type      = fi.type,
			size      = fi.size,
			supported = fi.supported,
			info      = cloned,
		}
		if fi.type == .Regular || fi.type == .Directory {
			buf: bytes.Buffer
			m.extract_err = tar.extract_current(&it, bytes.buffer_to_stream(&buf))
			m.data = bytes.buffer_to_bytes(&buf)
		}
		append(&got.members, m)
	}
	_, got.err = tar.iterator_error(&it)
	got.comment = strings.clone(tar.info(&r).comment)
	return
}

gots_destroy :: proc(got: ^Gots) {
	for m in got.members {
		archive.file_info_delete(m.info, context.allocator)
		delete(m.data)
	}
	delete(got.members)
	delete(got.comment)
}

read_chunked :: proc(r: io.Reader, first: int) -> (crc: u32, total: int, err: io.Error) {
	chunk: [4099]u8
	for step := first; ; step = step * 7 % len(chunk) + 1 {
		n, read_err := io.read(r, chunk[:step])
		crc    = hash.crc32(chunk[:n], crc)
		total += n
		if read_err == .EOF {
			return
		}
		if read_err != nil {
			return crc, total, read_err
		}
	}
}
