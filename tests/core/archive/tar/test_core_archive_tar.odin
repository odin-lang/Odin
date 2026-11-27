package test_core_archive_tar

import "base:runtime"
import "core:archive"
import "core:archive/tar"
import "core:bytes"
import "core:compress"
import "core:compress/lz4"
import "core:compress/lzma"
import "core:compress/xz"
import "core:fmt"
import "core:hash"
import "core:io"
import "core:mem"
import "core:os"
import "core:slice"
import "core:strings"
import "core:testing"
import "core:time"

TEST_SUITE_PATH_TAR :: ODIN_ROOT + "tests/core/assets/TAR/"

README_CRC :: 0x917123cb
TEXT_CRC   :: 0x61c54dab

Entry :: struct {
	type:     archive.Entry_Type,
	size:     i64,
	mode:     u32,
	link:     string,
	crc:      u32,
	data_len: int,
	info:     archive.File_Info,
}

Listing :: struct {
	entries: map[string]Entry,
	order:   [dynamic]string,
	count:   int,
	err:     archive.Error,
}

Non_Seekable :: struct {
	inner: io.Stream,
}

Burst :: struct {
	data: []u8,
	pos:  int,
}

Sink :: struct {
	total: i64,
	crc:   u32,
}

STREAM_MEMBER_SIZE :: 64 * 1024

TREE_ARCHIVES :: [?]string{
	"gnu-b1.tar",
	"gnu-gnu.tar",
	"gnu-gnu.tar.gz",
	"gnu-incremental.tar",
	"gnu-label.tar",
	"gnu-oldgnu.tar",
	"gnu-posix-global.tar",
	"gnu-posix-members.tar.gz",
	"gnu-posix.tar",
	"gnu-posix.tar.bz2",
	"gnu-posix.tar.gz",
	"gnu-posix.tar.xz",
	"gnu-posix.tar.lzma",
	"gnu-ustar.tar",
	"gnu-v7.tar",
	"bsd-mac-default.tar",
	"bsd-mac-gnutar.tar",
	"bsd-mac-pax.tar",
	"bsd-mac-ustar.tar",
	"bsd-mac-v7.tar",
	"bsd-mac.tar.bz2",
	"bsd-mac.tar.gz",
	"bsd-mac.tar.xz",
	"bsd-win-default.tar",
	"bsd-win-gnutar.tar",
	"bsd-win-pax.tar",
	"bsd-win-ustar.tar",
	"bsd-win-v7.tar",
	"bsd-win.tar.gz",
	"pax-mac-tar.tar",
	"pax-mac-ustar.tar",
}

@(test)
test_tree_archives :: proc(t: ^testing.T) {
	for name in TREE_ARCHIVES {
		listing := list_path(t, name)
		defer listing_destroy(&listing)
		if !testing.expectf(t, listing.err == nil, "%s: %v", name, listing.err) {
			continue
		}
		bsd_win := strings.has_prefix(name, "bsd-win")

		readme, has_readme := listing.entries["tree/README.TXT"]
		hard,   has_hard   := listing.entries["tree/hard.txt"]
		testing.expectf(t, has_readme && has_hard, "%s: README.TXT %v, hard.txt %v", name, has_readme, has_hard)
		if has_readme && has_hard {
			file, link := readme, hard
			if readme.type == .Hard_Link {
				file, link = hard, readme
			}
			testing.expectf(t, file.type == .Regular && file.size == 250 && file.crc == README_CRC, "%s: hard link target %v", name, file)
			testing.expectf(t, link.type == .Hard_Link && link.size == 0, "%s: hard link %v", name, link)
			testing.expectf(t, link.link == "tree/README.TXT" || link.link == "tree/hard.txt", "%s: hard link target %q", name, link.link)
		}

		text := listing.entries["tree/TEXT.TXT"]
		testing.expectf(t, text.type == .Regular && text.size == 80_000 && text.crc == TEXT_CRC, "%s: TEXT.TXT %v", name, text)

		one := listing.entries["tree/ONE.TXT"]
		testing.expectf(t, one.type == .Regular && one.size == 1 && one.crc == hash.crc32(transmute([]u8)string("A")), "%s: ONE.TXT %v", name, one)

		empty := listing.entries["tree/EMPTY.TXT"]
		testing.expectf(t, empty.type == .Regular && empty.size == 0 && empty.data_len == 0, "%s: EMPTY.TXT %v", name, empty)

		dir := listing.entries["tree/emptydir"]
		testing.expectf(t, dir.type == .Directory && (bsd_win || dir.mode & 0o777 == 0o700), "%s: emptydir %v", name, dir)

		run := listing.entries["tree/run.sh"]
		testing.expectf(t, run.type == .Regular && (bsd_win || run.mode & 0o777 == 0o755), "%s: run.sh %v", name, run)

		license := listing.entries["tree/sub/deep/LICENSE"]
		testing.expectf(t, license.type == .Regular && (bsd_win || license.mode & 0o777 == 0o600) && license.size > 0, "%s: LICENSE %v", name, license)

		if !bsd_win {
			link := listing.entries["tree/link.txt"]
			testing.expectf(t, link.type == .Symlink && link.link == "README.TXT", "%s: link.txt %v", name, link)
			_, has_japanese := listing.entries["tree/日本語.TXT"]
			testing.expectf(t, has_japanese, "%s: no tree/日本語.TXT", name)
		}
	}
}

@(test)
test_long_names :: proc(t: ^testing.T) {
	Case :: struct {
		file:  string,
		split: bool,
		long:  bool,
		link:  bool,
	}
	cases := [?]Case{
		{"gnu-ustar.tar",      true,  false, false},
		{"gnu-posix.tar",      true,  true,  false},
		{"gnu-gnu.tar",        true,  true,  true},
		{"gnu-oldgnu.tar",     true,  true,  true},
		{"bsd-mac-pax.tar",    false, true,  false},
		{"bsd-win-pax.tar",    false, true,  false},
		{"bsd-mac-gnutar.tar", true,  true,  true},
		{"bsd-win-gnutar.tar", true,  true,  false},
	}
	for c in cases {
		listing := list_path(t, c.file)
		defer listing_destroy(&listing)
		testing.expectf(t, listing.err == nil, "%s: %v", c.file, listing.err)
		found_split := false
		found_long  := false
		found_link  := false
		for path, entry in listing.entries {
			if len(path) == 135 && strings.has_suffix(path, "/file.txt") {
				found_split = entry.type == .Regular && entry.crc == 0xdfc16252
			}
			if len(path) == 159 && strings.has_prefix(path, "long/nnnn") {
				found_long = entry.type == .Regular && entry.crc == 0x8d1f752f
			}
			if path == "long/link-long" {
				found_link = entry.type == .Symlink && len(entry.link) == 148
				testing.expectf(t, found_link, "%s: link-long %v", c.file, entry)
			}
		}
		testing.expectf(t, found_split || !c.split, "%s: no 135-byte path", c.file)
		testing.expectf(t, found_long || !c.long, "%s: no 155-byte name", c.file)
		testing.expectf(t, found_link || !c.link, "%s: no 148-byte link", c.file)
	}
}

@(test)
test_crafted :: proc(t: ^testing.T) {
	Case :: struct {
		file:  string,
		path:  string,
		count: int,
	}
	cases := [?]Case{
		{"crafted-after-end.tar",       "a.txt",         1},
		{"crafted-no-end.tar",          "a.txt",         1},
		{"crafted-one-end-block.tar",   "a.txt",         1},
		{"crafted-pax-newline.tar",     "two\nlines.txt", 1},
		{"crafted-signed-checksum.tar", "",              1},
		{"crafted-v7-spaces.tar",       "v7.txt",        1},
		{"crafted-xstar.tar",           "",              1},
	}
	for c in cases {
		listing := list_path(t, c.file)
		defer listing_destroy(&listing)
		testing.expectf(t, listing.err == nil, "%s: %v", c.file, listing.err)
		testing.expectf(t, listing.count == c.count, "%s: %d members, want %d", c.file, listing.count, c.count)
		if c.path != "" {
			_, ok := listing.entries[c.path]
			testing.expectf(t, ok, "%s: no %q", c.file, c.path)
		}
	}

	xstar := list_path(t, "crafted-xstar.tar")
	defer listing_destroy(&xstar)
	if len(xstar.order) == 1 {
		path := xstar.order[0]
		testing.expectf(t, strings.has_prefix(path, "star/sss") && strings.has_suffix(path, "/file.txt"), "xstar path %q", path)
	}
}

@(test)
test_pax_fields :: proc(t: ^testing.T) {
	ids := list_path(t, "gnu-posix-ids.tar")
	defer listing_destroy(&ids)
	testing.expectf(t, ids.err == nil, "gnu-posix-ids: %v", ids.err)
	big := ids.entries["ids/big-ids.txt"]
	testing.expect_value(t, big.info.uid, 3_000_000)
	testing.expect_value(t, big.info.gid, 3_000_001)
	old := ids.entries["ids/1960.txt"]
	year, _, _ := time.date(old.info.modification_time)
	testing.expect_value(t, year, 1960)
	future := ids.entries["ids/2300.txt"]
	testing.expectf(t, time.to_unix_seconds(future.info.modification_time) > time.to_unix_seconds(old.info.modification_time), "2300.txt mtime %v", future.info.modification_time)

	global := list_path(t, "gnu-posix-global.tar")
	defer listing_destroy(&global)
	testing.expectf(t, global.err == nil, "gnu-posix-global: %v", global.err)
	for path, entry in global.entries {
		testing.expectf(t, entry.info.comment == "Made for Odin", "%s: comment %q", path, entry.info.comment)
	}

	win := list_path(t, "bsd-win-pax.tar")
	defer listing_destroy(&win)
	created := 0
	for _, entry in win.entries {
		if time.to_unix_seconds(entry.info.creation_time) != 0 {
			created += 1
		}
	}
	testing.expect_value(t, created, 1)
	text := win.entries["tree/TEXT.TXT"]
	testing.expectf(t, time.to_unix_nanoseconds(text.info.access_time) % 1_000_000_000 != 0, "bsd-win-pax access time %v", text.info.access_time)

	xattrs := list_path(t, "gnu-posix-xattrs.tar")
	defer listing_destroy(&xattrs)
	testing.expectf(t, xattrs.err == nil && xattrs.count == 2, "gnu-posix-xattrs: %v, %d members", xattrs.err, xattrs.count)
}

@(test)
test_hostile :: proc(t: ^testing.T) {
	Case :: struct {
		file: string,
		err:  archive.Error,
	}
	cases := [?]Case{
		{"hostile-checksum.tar",          archive.Tar_Error.Invalid_Checksum},
		{"hostile-octal-garbage.tar",     archive.Tar_Error.Invalid_Number},
		{"hostile-pax-badlength.tar",     archive.Tar_Error.Invalid_Pax_Record},
		{"hostile-pax-length.tar",        archive.Tar_Error.Invalid_Pax_Record},
		{"hostile-pax-noequals.tar",      archive.Tar_Error.Invalid_Pax_Record},
		{"hostile-nul-path.tar",          archive.Tar_Error.Invalid_Pax_Record},
		{"hostile-pax-huge.tar",          archive.Tar_Error.Header_Too_Large},
		{"hostile-size-base256.tar",      archive.Tar_Error.Invalid_Size},
		{"hostile-size-negative.tar",     archive.Tar_Error.Invalid_Size},
		{"hostile-longname-dotdot.tar",   nil},
		{"hostile-longname-huge.tar",     archive.Tar_Error.Header_Too_Large},
		{"hostile-sparse-map.tar",        archive.Tar_Error.Invalid_Sparse_Map},
		{"hostile-size-absurd.tar",       archive.Tar_Error.Truncated},
		{"hostile-truncated-data.tar",    archive.Tar_Error.Truncated},
		{"hostile-truncated-header.tar",  archive.Tar_Error.Truncated},
		{"hostile-absolute.tar",          nil},
		{"hostile-case-collision.tar",    nil},
		{"hostile-devices.tar",           nil},
		{"hostile-dotdot.tar",            nil},
		{"hostile-duplicates.tar",        nil},
		{"hostile-hardlink-escape.tar",   nil},
		{"hostile-hardlink-missing.tar",  nil},
		{"hostile-pax-path.tar",          nil},
		{"hostile-symlink-absolute.tar",  nil},
		{"hostile-symlink-chain.tar",     nil},
		{"hostile-symlink-escape.tar",    nil},
		{"hostile-windows-names.tar",     nil},
	}
	for c in cases {
		for source in Source_Kind {
			listing := list_path(t, c.file, source)
			defer listing_destroy(&listing)
			testing.expectf(t, listing.err == c.err, "%s via %v: %v, want %v", c.file, source, listing.err, c.err)
		}
	}

	devices := list_path(t, "hostile-devices.tar")
	defer listing_destroy(&devices)
	testing.expect_value(t, devices.entries["null"].type, archive.Entry_Type.Character_Device)
	testing.expect_value(t, devices.entries["sda"].type, archive.Entry_Type.Block_Device)
	testing.expect_value(t, devices.entries["fifo"].type, archive.Entry_Type.Named_Pipe)
	testing.expect_value(t, devices.entries["contiguous.txt"].type, archive.Entry_Type.Regular)
	testing.expect_value(t, devices.entries["unknown.bin"].type, archive.Entry_Type.Unknown)
	testing.expect_value(t, devices.entries["unknown.bin"].info.supported, false)
}

Source_Kind :: enum {
	Path,
	Bytes,
	Stream,
	Non_Seekable,
	Generic,
}

@(test)
test_sources :: proc(t: ^testing.T) {
	for name in ([?]string{"gnu-posix.tar", "gnu-posix.tar.gz", "gnu-posix.tar.bz2", "gnu-posix.tar.lzma", "gnu-posix.tar.xz", "gnu-posix-members.tar.gz"}) {
		for source in Source_Kind {
			listing := list_path(t, name, source)
			defer listing_destroy(&listing)
			testing.expectf(t, listing.err == nil, "%s via %v: %v", name, source, listing.err)
			testing.expectf(t, listing.count == 20, "%s via %v: %d members", name, source, listing.count)
			text := listing.entries["tree/TEXT.TXT"]
			testing.expectf(t, text.crc == TEXT_CRC, "%s via %v: TEXT.TXT %v", name, source, text)
		}
	}
}

@(test)
test_find_and_extract :: proc(t: ^testing.T) {
	for name in ([?]string{"gnu-posix.tar", "gnu-posix.tar.gz", "gnu-posix.tar.bz2"}) {
		r: tar.Reader
		err := tar.open(&r, asset(name))
		testing.expectf(t, err == nil, "%s: %v", name, err)
		defer tar.close(&r)

		fi, handle, ok, find_err := tar.find(&r, "tree/TEXT.TXT")
		testing.expectf(t, ok && find_err == nil && fi.size == 80_000, "%s: find TEXT %v %v", name, ok, find_err)
		text_handle := handle

		fi, handle, ok, find_err = tar.find(&r, "./tree/EMPTY.TXT")
		testing.expectf(t, ok && find_err == nil && fi.size == 0, "%s: find EMPTY behind %v %v", name, ok, find_err)

		_, _, ok, find_err = tar.find(&r, "tree/missing")
		testing.expectf(t, !ok && find_err == nil, "%s: find missing %v %v", name, ok, find_err)

		buf: bytes.Buffer
		defer bytes.buffer_destroy(&buf)
		extract_err := tar.extract(&r, text_handle, bytes.buffer_to_stream(&buf))
		testing.expectf(t, extract_err == nil && hash.crc32(bytes.buffer_to_bytes(&buf)) == TEXT_CRC, "%s: extract by handle %v", name, extract_err)

		member, open_err := tar.open_member(&r, text_handle)
		testing.expectf(t, open_err == nil, "%s: open_member %v", name, open_err)
		data, read_err := read_stream(member)
		defer delete(data)
		testing.expectf(t, read_err == nil && hash.crc32(data[:]) == TEXT_CRC, "%s: read member %v", name, read_err)

		info := tar.info(&r)
		testing.expect_value(t, info.format, archive.Format.Tar)
	}

	data, read_err := os.read_entire_file(asset("gnu-posix.tar.gz"), context.allocator)
	testing.expect_value(t, read_err, nil)
	defer delete(data)
	reader: bytes.Reader
	wrapper := Non_Seekable{inner = bytes.reader_init(&reader, data)}
	r: tar.Reader
	err := tar.open(&r, non_seekable_stream(&wrapper))
	testing.expect_value(t, err, nil)
	defer tar.close(&r)
	_, _, ok, find_err := tar.find(&r, "tree/TEXT.TXT")
	testing.expect(t, ok && find_err == nil)
	_, _, ok, find_err = tar.find(&r, "tree/EMPTY.TXT")
	testing.expectf(t, !ok && find_err == archive.General_Error.Not_Seekable, "rewinding a pipe: %v %v", ok, find_err)
}

@(test)
test_multi_extract :: proc(t: ^testing.T) {
	for name in ([?]string{"gnu-posix.tar", "gnu-posix.tar.gz", "bsd-mac.tar.bz2"}) {
		a, err := archive.open(asset(name))
		testing.expectf(t, err == nil, "%s: %v", name, err)
		defer archive.close(&a)
		info := archive.info(&a)
		testing.expect_value(t, info.format, archive.Format.Tar)

		text_buf: [dynamic]u8
		one_buf:  [dynamic]u8
		defer delete(text_buf)
		defer delete(one_buf)
		link_out: bytes.Buffer
		defer bytes.buffer_destroy(&link_out)
		targets := [?]archive.Target{
			{path = "tree/ONE.TXT",  to = &one_buf},
			{path = "nope",          to = &one_buf},
			{path = "tree/TEXT.TXT", to = &text_buf},
			{path = "tree/link.txt", to = bytes.buffer_to_stream(&link_out)},
		}
		it := archive.extract_iterator_create(&a, targets[:])
		yielded   := 0
		link_error: archive.Error
		for target in archive.extract_iterate(&it) {
			yielded += 1
			if path, item_err := archive.extract_iterator_error(&it); item_err != nil {
				testing.expectf(t, path == "tree/link.txt", "%s: error on %q", name, path)
				link_error = item_err
				_ = target
			}
		}
		_, last := archive.extract_iterator_error(&it)
		archive.extract_iterator_destroy(&it)

		testing.expectf(t, yielded == 3, "%s: %d yielded", name, yielded)
		testing.expectf(t, link_error == archive.General_Error.Skipped_Entry_Type, "%s: link error %v", name, link_error)
		testing.expectf(t, last == archive.General_Error.Skipped_Entry_Type, "%s: last error %v", name, last)
		testing.expectf(t, targets[0].found && !targets[1].found && targets[2].found && targets[3].found, "%s: found %v", name, targets)
		testing.expectf(t, string(one_buf[:]) == "A", "%s: ONE.TXT %q", name, string(one_buf[:]))
		testing.expectf(t, hash.crc32(text_buf[:]) == TEXT_CRC, "%s: TEXT.TXT crc", name)
	}

	a, err := archive.open(asset("gnu-posix.tar"))
	testing.expect_value(t, err, nil)
	defer archive.close(&a)
	buf: bytes.Buffer
	defer bytes.buffer_destroy(&buf)
	targets := [?]archive.Target{{path = "tree/ONE.TXT", to = bytes.buffer_to_stream(&buf)}}
	many_err := archive.extract_many(&a, targets[:], {last_wins = true})
	testing.expect_value(t, many_err, archive.General_Error.Incompatible_Options)
}

@(test)
test_limits :: proc(t: ^testing.T) {
	r: tar.Reader
	err := tar.open(&r, asset("gnu-posix.tar"), compress.Options{max_memory = 16})
	testing.expect_value(t, err, nil)
	defer tar.close(&r)
	it := tar.iterator_create(&r)
	defer tar.iterator_destroy(&it)
	for _ in tar.iterate(&it) {
	}
	_, it_err := tar.iterator_error(&it)
	testing.expect_value(t, it_err, archive.Tar_Error.Header_Too_Large)

	too_large := archive.Error(compress.Error(compress.General_Error.Output_Too_Short))
	for name in ([?]string{"gnu-posix.tar.bz2", "gnu-posix.tar.gz", "gnu-posix.tar.lzma", "gnu-posix.tar.xz"}) {
		small: tar.Reader
		err = tar.open(&small, asset(name), compress.Options{max_output_size = 4096})
		testing.expectf(t, err == nil, "%s: open %v", name, err)
		small_it := tar.iterator_create(&small)
		for _ in tar.iterate(&small_it) {
		}
		_, small_err := tar.iterator_error(&small_it)
		testing.expectf(t, small_err == too_large, "%s over max_output_size: %v", name, small_err)
		tar.iterator_destroy(&small_it)
		tar.close(&small)
	}
}

@(test)
test_stream_memory :: proc(t: ^testing.T) {
	sizes   := [2]int{512 * 1024, 2 << 20}
	payload := stream_payload(sizes[1])
	defer delete(payload)
	want_crc: [2]u32
	for size, i in sizes {
		want_crc[i] = hash.crc32(payload[:size])
	}
	for method in ([?]archive.Method{.Deflate, .BZip2, .LZ4, .LZMA, .XZ}) {
		packed: [2][dynamic]u8
		defer for &p in packed {
			delete(p)
		}
		for size, i in sizes {
			packed[i] = stream_archive(t, method, payload[:size])
		}
		for source in ([?]Source_Kind{.Bytes, .Stream, .Non_Seekable}) {
			peaks: [2]i64
			for size, i in sizes {
				sink: Sink
				peaks[i] = stream_extract(t, packed[i][:], source, method, &sink)
				testing.expectf(t, sink.total == i64(size) && sink.crc == want_crc[i], "%v via %v, %d bytes: extracted %d bytes, crc %8x", method, source, size, sink.total, sink.crc)
			}
			testing.expectf(t, peaks[1] <= peaks[0] + 128 * 1024, "%v via %v: peak %d bytes for %d, %d bytes for %d", method, source, peaks[0], sizes[0], peaks[1], sizes[1])
		}
	}
}

@(test)
test_stream_trailer :: proc(t: ^testing.T) {
	payload := stream_payload(3 * STREAM_MEMBER_SIZE)
	defer delete(payload)
	for method in ([?]archive.Method{.Deflate, .BZip2, .LZ4, .XZ}) {
		packed := stream_archive(t, method, payload)
		defer delete(packed)
		if !testing.expectf(t, len(packed) > 16, "%v: %d bytes", method, len(packed)) {
			continue
		}
		#partial switch method {
		case .Deflate: packed[len(packed) - 8] ~= 0x01
		case .BZip2:   packed[len(packed) - 2] ~= 0x01
		case .LZ4:     packed[len(packed) - 1] ~= 0x01
		case .XZ:      packed[len(packed) - 12] ~= 0x01
		}
		for source in ([?]Source_Kind{.Bytes, .Stream, .Non_Seekable}) {
			reader: bytes.Reader
			wrapper: Non_Seekable
			r: tar.Reader
			err: archive.Error
			#partial switch source {
			case .Bytes:
				err = tar.open(&r, packed[:])
			case .Stream:
				err = tar.open(&r, bytes.reader_init(&reader, packed[:]))
			case .Non_Seekable:
				wrapper.inner = bytes.reader_init(&reader, packed[:])
				err = tar.open(&r, non_seekable_stream(&wrapper))
			}
			if !testing.expectf(t, err == nil, "%v via %v: open %v", method, source, err) {
				tar.close(&r)
				continue
			}
			it := tar.iterator_create(&r)
			sink: Sink
			count := 0
			for _ in tar.iterate(&it) {
				count += 1
				testing.expect_value(t, tar.extract_current(&it, sink_stream(&sink)), nil)
			}
			_, it_err := tar.iterator_error(&it)
			testing.expectf(t, count == 3 && sink.total == i64(len(payload)), "%v via %v: %d members, %d bytes", method, source, count, sink.total)
			testing.expectf(t, it_err != nil, "%v via %v: bad trailer not reported", method, source)
			tar.iterator_destroy(&it)
			tar.close(&r)
		}
	}
}

@(test)
test_broken_reader :: proc(t: ^testing.T) {
	data: [dynamic]u8
	defer delete(data)
	build_member(&data, "a.txt", 10)
	build_member(&data, "b.txt", 600)
	bad := len(data)
	build_member(&data, "bad.txt", 5)
	data[bad] = 'X'
	build_member(&data, "c.txt", 5)
	resize(&data, len(data) + 1024)

	r: tar.Reader
	testing.expect_value(t, tar.open_from_bytes(&r, data[:]), nil)
	defer tar.close(&r)
	it := tar.iterator_create(&r)
	defer tar.iterator_destroy(&it)
	count := 0
	for _ in tar.iterate(&it) {
		count += 1
	}
	path, err := tar.iterator_error(&it)
	testing.expect_value(t, count, 2)
	testing.expect_value(t, err, archive.Error(archive.Tar_Error.Invalid_Checksum))
	testing.expect_value(t, path, "")
	_, _, again := tar.iterate(&it)
	testing.expect(t, !again, "iterate after an error must stay done")

	fi, handle, ok, find_err := tar.find(&r, "a.txt")
	testing.expect(t, ok && find_err == nil && handle.index == 0 && fi.size == 10, "find before the break")
	_, _, ok, find_err = tar.find(&r, "c.txt")
	testing.expect(t, !ok, "c.txt is past the break")
	testing.expect_value(t, find_err, archive.Error(archive.Tar_Error.Invalid_Checksum))

	buf: bytes.Buffer
	defer bytes.buffer_destroy(&buf)
	testing.expect_value(t, tar.extract(&r, {index = 1}, bytes.buffer_to_stream(&buf)), nil)
	testing.expect_value(t, bytes.buffer_length(&buf), 600)
	testing.expect_value(t, tar.extract(&r, {index = 2}, bytes.buffer_to_stream(&buf)), archive.Error(archive.Tar_Error.Invalid_Checksum))
	testing.expect_value(t, tar.extract(&r, {index = 1}, bytes.buffer_to_stream(&buf)), nil)

	br: bytes.Reader
	ns := Non_Seekable{inner = bytes.reader_init(&br, data[:])}
	forward: tar.Reader
	testing.expect_value(t, tar.open_from_stream(&forward, non_seekable_stream(&ns)), nil)
	defer tar.close(&forward)
	forward_it := tar.iterator_create(&forward)
	defer tar.iterator_destroy(&forward_it)
	for _ in tar.iterate(&forward_it) {
	}
	_, _, ok, find_err = tar.find(&forward, "a.txt")
	testing.expect(t, !ok, "find on a forward-only reader")
	testing.expect_value(t, find_err, archive.Error(archive.General_Error.Not_Seekable))
	testing.expect_value(t, tar.extract(&forward, {index = 2}, bytes.buffer_to_stream(&buf)), archive.Error(archive.Tar_Error.Invalid_Checksum))
}

@(test)
test_clean_paths :: proc(t: ^testing.T) {
	data: [dynamic]u8
	defer delete(data)
	build_member(&data, "./a.txt", 10)
	build_member(&data, "./dir/", 0, '5')
	build_member(&data, ".//b.txt", 5)
	build_member(&data, "./", 0, '5')
	resize(&data, len(data) + 1024)

	Want :: struct {
		path: string,
		raw:  string,
	}
	wants := [?]Want{{"a.txt", "./a.txt"}, {"dir", "./dir/"}, {"b.txt", ".//b.txt"}, {"", "./"}}
	r: tar.Reader
	testing.expect_value(t, tar.open_from_bytes(&r, data[:]), nil)
	defer tar.close(&r)
	it := tar.iterator_create(&r)
	defer tar.iterator_destroy(&it)
	count := 0
	for fi, i in tar.iterate(&it) {
		count += 1
		if i < len(wants) {
			testing.expectf(t, fi.path == wants[i].path && string(fi.raw_path) == wants[i].raw, "member %d: %q, raw %q", i, fi.path, string(fi.raw_path))
		}
	}
	testing.expect_value(t, count, len(wants))
	fi, _, ok, err := tar.find(&r, "./dir/")
	testing.expectf(t, ok && err == nil && fi.path == "dir", "find ./dir/: %v %v %q", ok, err, fi.path)
}

@(test)
test_error_path :: proc(t: ^testing.T) {
	data: [dynamic]u8
	defer delete(data)
	long := pax_record("path", "long/pax/name/here.txt")
	defer delete(long)
	build_member(&data, "PaxHeaders/one", len(long), 'x')
	append(&data, long)
	pad_block(&data)
	build_member(&data, "short.txt", 10)
	big := pax_record("comment", strings.repeat("z", 3000, context.temp_allocator))
	defer delete(big)
	build_member(&data, "PaxHeaders/two", len(big), 'x')
	append(&data, big)
	pad_block(&data)
	bad := len(data)
	build_member(&data, "bad-number.txt", 5)
	data[bad + 124] = '9'
	fix_checksum(data[bad:][:512])
	resize(&data, len(data) + 1024)

	r: tar.Reader
	testing.expect_value(t, tar.open_from_bytes(&r, data[:]), nil)
	defer tar.close(&r)
	it := tar.iterator_create(&r)
	defer tar.iterator_destroy(&it)
	fi, _, ok := tar.iterate(&it)
	testing.expect(t, ok && fi.path == "long/pax/name/here.txt", "pax path")
	_, _, ok = tar.iterate(&it)
	testing.expect(t, !ok, "bad number must end iteration")
	path, err := tar.iterator_error(&it)
	testing.expect_value(t, err, archive.Error(archive.Tar_Error.Invalid_Number))
	testing.expect_value(t, path, "bad-number.txt")

	truncated: [dynamic]u8
	defer delete(truncated)
	build_member(&truncated, "trunc.txt", 2000)
	resize(&truncated, 512 + 100)
	for stream in ([]bool{false, true}) {
		tr: tar.Reader
		br: bytes.Reader
		ns := Non_Seekable{inner = bytes.reader_init(&br, truncated[:])}
		if stream {
			testing.expect_value(t, tar.open_from_stream(&tr, non_seekable_stream(&ns)), nil)
		} else {
			testing.expect_value(t, tar.open_from_bytes(&tr, truncated[:]), nil)
		}
		tit := tar.iterator_create(&tr)
		tfi, _, tok := tar.iterate(&tit)
		testing.expect(t, tok && tfi.path == "trunc.txt", "truncated member is listed")
		_, _, tok = tar.iterate(&tit)
		tpath, terr := tar.iterator_error(&tit)
		testing.expect(t, !tok, "truncated data must end iteration")
		testing.expect_value(t, terr, archive.Error(archive.Tar_Error.Truncated))
		testing.expect_value(t, tpath, "trunc.txt")
		tar.iterator_destroy(&tit)
		tar.close(&tr)
	}
}

@(test)
test_iterator_create_error :: proc(t: ^testing.T) {
	data: [dynamic]u8
	defer delete(data)
	build_member(&data, "a.txt", 10)
	resize(&data, len(data) + 1024)
	a, err := archive.open_from_bytes(data[:])
	testing.expect_value(t, err, nil)
	defer archive.close(&a)
	saved := a.allocator
	a.allocator = failing_allocator()
	it := archive.iterator_create(&a)
	_, index, ok := archive.iterate(&it)
	_, it_err := archive.iterator_error(&it)
	archive.iterator_destroy(&it)
	a.allocator = saved
	testing.expect(t, !ok && index == -1, "iterate without state")
	testing.expect_value(t, it_err, archive.Error(runtime.Allocator_Error.Out_Of_Memory))
}

@(test)
test_data_before_error :: proc(t: ^testing.T) {
	for members in 1..=2 {
		data: [dynamic]u8
		defer delete(data)
		build_member(&data, "a.txt", 10)
		if members == 2 {
			build_member(&data, "b.txt", 10)
		}
		burst := Burst{data = data[:]}
		r: tar.Reader
		testing.expect_value(t, tar.open_from_stream(&r, burst_stream(&burst)), nil)
		it := tar.iterator_create(&r)
		count := 0
		for _ in tar.iterate(&it) {
			count += 1
			buf: bytes.Buffer
			testing.expect_value(t, tar.extract_current(&it, bytes.buffer_to_stream(&buf)), nil)
			testing.expect_value(t, bytes.buffer_length(&buf), 10)
			bytes.buffer_destroy(&buf)
		}
		_, err := tar.iterator_error(&it)
		testing.expect_value(t, count, members)
		testing.expect_value(t, err, archive.Error(io.Error.Unknown))
		tar.iterator_destroy(&it)
		tar.close(&r)
	}
}

@(test)
test_iterator_rewind :: proc(t: ^testing.T) {
	data: [dynamic]u8
	defer delete(data)
	build_member(&data, "a.txt", 10)
	build_member(&data, "b.txt", 20)
	build_member(&data, "c.txt", 30)
	resize(&data, len(data) + 1024)

	r: tar.Reader
	testing.expect_value(t, tar.open_from_bytes(&r, data[:]), nil)
	defer tar.close(&r)
	for pass in 0..<2 {
		it := tar.iterator_create(&r)
		count := 0
		for _ in tar.iterate(&it) {
			count += 1
		}
		_, err := tar.iterator_error(&it)
		testing.expectf(t, count == 3 && err == nil, "pass %v: %v members, %v", pass, count, err)
		tar.iterator_destroy(&it)
	}
	_, _, ok, find_err := tar.find(&r, "b.txt")
	testing.expect(t, ok && find_err == nil, "find b.txt")
	it := tar.iterator_create(&r)
	fi, index, first := tar.iterate(&it)
	testing.expect(t, first && index == 0 && fi.path == "a.txt", "an iterator after find starts at a.txt")
	tar.iterator_destroy(&it)

	a, open_err := archive.open_from_bytes(data[:])
	testing.expect_value(t, open_err, nil)
	defer archive.close(&a)
	git := archive.iterator_create(&a)
	for _ in archive.iterate(&git) {
	}
	archive.iterator_destroy(&git)
	_, _, found, _ := archive.find(&a, "b.txt")
	testing.expect(t, found, "generic find b.txt")
	a_buf, c_buf: [dynamic]u8
	defer delete(a_buf)
	defer delete(c_buf)
	targets := [?]archive.Target{{path = "a.txt", to = &a_buf}, {path = "c.txt", to = &c_buf}}
	testing.expect_value(t, archive.extract_many(&a, targets[:]), nil)
	testing.expect(t, targets[0].found && targets[1].found, "extract_many after iterate and find")
	testing.expect_value(t, len(a_buf), 10)
	testing.expect_value(t, len(c_buf), 30)

	br: bytes.Reader
	ns := Non_Seekable{inner = bytes.reader_init(&br, data[:])}
	pipe: tar.Reader
	testing.expect_value(t, tar.open_from_stream(&pipe, non_seekable_stream(&ns)), nil)
	defer tar.close(&pipe)
	first_it := tar.iterator_create(&pipe)
	_, _, more := tar.iterate(&first_it)
	testing.expect(t, more, "first member from a pipe")
	tar.iterator_destroy(&first_it)
	second := tar.iterator_create(&pipe)
	defer tar.iterator_destroy(&second)
	_, _, again := tar.iterate(&second)
	_, pipe_err := tar.iterator_error(&second)
	testing.expect(t, !again, "a pipe can't start over")
	testing.expect_value(t, pipe_err, archive.Error(archive.General_Error.Not_Seekable))
}

@(test)
test_pax_records :: proc(t: ^testing.T) {
	data: [dynamic]u8
	defer delete(data)
	add_records(&data, 'g', {{"uname", "alice"}, {"mtime", "1000000000"}})
	build_member(&data, "a.txt", 1)
	add_records(&data, 'g', {{"uname", "bob"}})
	build_member(&data, "b.txt", 1)
	add_records(&data, 'g', {{"uname", ""}})
	build_member(&data, "c.txt", 1)
	build_member(&data, "d.txt", 1)
	add_records(&data, 'x', {{"path", "long/e.txt"}, {"SCHILY.xattr.user.test", "1"}})
	build_member(&data, "e.txt", 1)
	resize(&data, len(data) + 1024)

	Want :: struct {
		path:     string,
		user:     string,
		extended: bool,
		global:   [][2]string,
		local:    [][2]string,
	}
	wants := []Want{
		{"a.txt",      "alice", true,  {{"uname", "alice"}, {"mtime", "1000000000"}}, nil},
		{"b.txt",      "bob",   true,  {{"uname", "bob"}},                            nil},
		{"c.txt",      "root",  true,  {{"uname", ""}},                               nil},
		{"d.txt",      "root",  false, nil,                                           nil},
		{"long/e.txt", "root",  true,  nil, {{"path", "long/e.txt"}, {"SCHILY.xattr.user.test", "1"}}},
	}

	r: tar.Reader
	testing.expect_value(t, tar.open_from_bytes(&r, data[:]), nil)
	defer tar.close(&r)
	it := tar.iterator_create(&r)
	defer tar.iterator_destroy(&it)
	testing.expect(t, tar.current_entry(&it) == nil, "entry before the first member")
	count := 0
	for fi, i in tar.iterate(&it) {
		count += 1
		if i >= len(wants) {
			break
		}
		want := wants[i]
		testing.expectf(t, fi.path == want.path && fi.user == want.user, "member %v: %q %q", i, fi.path, fi.user)
		testing.expectf(t, time.to_unix_seconds(fi.modification_time) == 1_000_000_000, "member %v: mtime %v", i, fi.modification_time)
		testing.expectf(t, fi.extended_metadata == want.extended, "member %v: extended_metadata %v", i, fi.extended_metadata)
		entry  := tar.current_entry(&it)
		global := record_list(entry.global_records)
		local  := record_list(entry.local_records)
		testing.expectf(t, slice.equal(global[:], want.global), "member %v: global records %v", i, global)
		testing.expectf(t, slice.equal(local[:], want.local), "member %v: local records %v", i, local)
		delete(global)
		delete(local)
	}
	_, err := tar.iterator_error(&it)
	testing.expect_value(t, count, len(wants))
	testing.expect_value(t, err, nil)
	testing.expect(t, tar.current_entry(&it) == nil, "entry after the last member")

	padded := transmute([]u8)string("11 a=bcdef\n\x00\x00\x00")
	key, value, ok := tar.next_record(&padded)
	testing.expect(t, ok && key == "a" && value == "bcdef", "first record")
	_, _, ok = tar.next_record(&padded)
	testing.expect(t, !ok && len(padded) == 3, "zero padding ends the records")
}

@(test)
test_pax_record_cap :: proc(t: ^testing.T) {
	data: [dynamic]u8
	defer delete(data)
	filler := strings.repeat("z", 2000, context.temp_allocator)
	for i in 0..<1500 {
		add_records(&data, 'g', {{"comment", filler}, {"uname", "even" if i % 2 == 0 else "odd"}})
		build_member(&data, "m.txt", 1)
	}
	resize(&data, len(data) + 1024)

	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	defer mem.tracking_allocator_destroy(&track)
	r: tar.Reader
	testing.expect_value(t, tar.open_from_bytes(&r, data[:], allocator = mem.tracking_allocator(&track)), nil)
	it := tar.iterator_create(&r)
	count := 0
	for fi, i in tar.iterate(&it) {
		count += 1
		testing.expectf(t, fi.comment == filler && fi.user == ("even" if i % 2 == 0 else "odd"), "member %v: %q", i, fi.user)
	}
	_, err := tar.iterator_error(&it)
	tar.iterator_destroy(&it)
	tar.close(&r)
	testing.expect_value(t, count, 1500)
	testing.expect_value(t, err, nil)
	testing.expectf(t, track.peak_memory_allocated < 256 * 1024, "peak %v bytes for %v bytes of global records", track.peak_memory_allocated, 1500 * 2000)

	half := strings.repeat("y", 600_000, context.temp_allocator)
	for together in ([]bool{false, true}) {
		big: [dynamic]u8
		defer delete(big)
		add_records(&big, 'g', {{"comment", half}})
		if !together {
			build_member(&big, "one.txt", 1)
		}
		add_records(&big, 'x', {{"comment", half}})
		build_member(&big, "two.txt", 1)
		resize(&big, len(big) + 1024)
		br: tar.Reader
		testing.expect_value(t, tar.open_from_bytes(&br, big[:]), nil)
		bit := tar.iterator_create(&br)
		members := 0
		for _ in tar.iterate(&bit) {
			members += 1
		}
		_, big_err := tar.iterator_error(&bit)
		if together {
			testing.expect_value(t, members, 0)
			testing.expect_value(t, big_err, archive.Error(archive.Tar_Error.Header_Too_Large))
		} else {
			testing.expect_value(t, members, 2)
			testing.expect_value(t, big_err, nil)
		}
		tar.iterator_destroy(&bit)
		tar.close(&br)
	}
}

list_path :: proc(t: ^testing.T, name: string, source := Source_Kind.Path) -> (listing: Listing) {
	path := asset(name)
	data: []u8
	defer delete(data)
	file: ^os.File
	defer if file != nil {
		os.close(file)
	}
	reader: bytes.Reader
	wrapper: Non_Seekable

	if source == .Generic {
		a, err := archive.open(path)
		if err != nil {
			listing.err = err
			return
		}
		defer archive.close(&a)
		it := archive.iterator_create(&a)
		defer archive.iterator_destroy(&it)
		for fi in archive.iterate(&it) {
			listing_add(t, &listing, fi, &it, nil)
		}
		_, listing.err = archive.iterator_error(&it)
		return
	}

	r: tar.Reader
	err: archive.Error
	switch source {
	case .Path:
		err = tar.open(&r, path)
	case .Bytes:
		read_err: os.Error
		data, read_err = os.read_entire_file(path, context.allocator)
		testing.expect_value(t, read_err, nil)
		err = tar.open(&r, data)
	case .Stream:
		open_err: os.Error
		file, open_err = os.open(path)
		testing.expect_value(t, open_err, nil)
		err = tar.open(&r, os.to_stream(file))
	case .Non_Seekable:
		read_err: os.Error
		data, read_err = os.read_entire_file(path, context.allocator)
		testing.expect_value(t, read_err, nil)
		wrapper.inner = bytes.reader_init(&reader, data)
		err = tar.open(&r, non_seekable_stream(&wrapper))
	case .Generic:
	}
	defer tar.close(&r)
	if err != nil {
		listing.err = err
		return
	}
	it := tar.iterator_create(&r)
	defer tar.iterator_destroy(&it)
	for fi in tar.iterate(&it) {
		listing_add(t, &listing, fi, nil, &it)
	}
	_, listing.err = tar.iterator_error(&it)
	return
}

listing_add :: proc(t: ^testing.T, listing: ^Listing, fi: archive.File_Info, generic: ^archive.Iterator, it: ^tar.Iterator) {
	entry := Entry{
		type = fi.type,
		size = fi.size,
		mode = fi.unix_mode,
	}
	cloned, clone_err := archive.file_info_clone(fi, context.allocator)
	testing.expect_value(t, clone_err, nil)
	entry.info = cloned
	entry.link = cloned.link_target
	listing.count += 1
	if fi.type == .Regular && fi.supported {
		buf: bytes.Buffer
		defer bytes.buffer_destroy(&buf)
		extract_err: archive.Error
		if generic != nil {
			extract_err = archive.extract_current(generic, bytes.buffer_to_stream(&buf))
		} else {
			extract_err = tar.extract_current(it, bytes.buffer_to_stream(&buf))
		}
		if extract_err != nil {
			listing.err = extract_err
		}
		data := bytes.buffer_to_bytes(&buf)
		entry.crc      = hash.crc32(data)
		entry.data_len = len(data)
	}
	if cloned.path in listing.entries {
		archive.file_info_delete(cloned, context.allocator)
		return
	}
	append(&listing.order, cloned.path)
	listing.entries[cloned.path] = entry
}

listing_destroy :: proc(listing: ^Listing) {
	for _, entry in listing.entries {
		archive.file_info_delete(entry.info, context.allocator)
	}
	delete(listing.entries)
	delete(listing.order)
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

asset :: proc(name: string) -> string {
	return strings.concatenate({TEST_SUITE_PATH_TAR, name}, context.temp_allocator)
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

build_member :: proc(out: ^[dynamic]u8, name: string, size: int, typeflag := u8('0')) {
	start := len(out)
	resize(out, start + 512)
	h := out[start:][:512]
	copy(h[0:100], name)
	copy(h[100:108], "0000644\x00")
	copy(h[108:116], "0000000\x00")
	copy(h[116:124], "0000000\x00")
	fmt.bprintf(h[124:135], "%011o", size)
	copy(h[136:148], "00000000000\x00")
	h[156] = typeflag
	copy(h[257:265], "ustar\x0000")
	copy(h[265:297], "root")
	fix_checksum(h)
	if typeflag == '0' {
		for i in 0..<size {
			append(out, u8('a' + i % 26))
		}
		pad_block(out)
	}
}

fix_checksum :: proc(h: []u8) {
	for i in 148..<156 {
		h[i] = ' '
	}
	sum := 0
	for b in h[:512] {
		sum += int(b)
	}
	fmt.bprintf(h[148:154], "%06o", sum)
	h[154] = 0
}

pad_block :: proc(out: ^[dynamic]u8) {
	for len(out) % 512 != 0 {
		append(out, 0)
	}
}

pax_record :: proc(key, value: string) -> string {
	body   := len(key) + len(value) + 3
	length := body + 1
	for len(fmt.tprint(length)) + body != length {
		length = len(fmt.tprint(length)) + body
	}
	return fmt.aprintf("%v %v=%v\n", length, key, value)
}

add_records :: proc(out: ^[dynamic]u8, typeflag: u8, records: [][2]string) {
	body: [dynamic]u8
	defer delete(body)
	for record in records {
		line := pax_record(record[0], record[1])
		append(&body, line)
		delete(line)
	}
	build_member(out, "PaxHeaders/records", len(body), typeflag)
	append(out, ..body[:])
	pad_block(out)
}

record_list :: proc(records: []u8) -> (list: [dynamic][2]string) {
	rest := records
	for key, value in tar.next_record(&rest) {
		append(&list, [2]string{key, value})
	}
	return
}

burst_stream :: proc(b: ^Burst) -> (s: io.Stream) {
	s.data      = b
	s.procedure = burst_proc
	return
}

burst_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	b := (^Burst)(stream_data)
	#partial switch mode {
	case .Read:
		if b.pos >= len(b.data) {
			return 0, .Unknown
		}
		count := copy(p, b.data[b.pos:])
		b.pos += count
		if b.pos == len(b.data) {
			return i64(count), .Unknown
		}
		return i64(count), nil
	case .Query:
		return io.query_utility({.Read, .Query})
	}
	return 0, .Unsupported
}

failing_allocator :: proc() -> runtime.Allocator {
	return {procedure = failing_allocator_proc}
}

failing_allocator_proc :: proc(allocator_data: rawptr, mode: runtime.Allocator_Mode, size, alignment: int, old_memory: rawptr, old_size: int, location := #caller_location) -> ([]byte, runtime.Allocator_Error) {
	#partial switch mode {
	case .Alloc, .Alloc_Non_Zeroed, .Resize, .Resize_Non_Zeroed:
		return nil, .Out_Of_Memory
	}
	return nil, nil
}

stream_payload :: proc(size: int) -> (payload: []u8) {
	payload = make([]u8, size)
	alphabet := "etaoin shrdlu\ncm"
	x := u32(0x9e3779b9)
	for &b in payload {
		x = x * 1_103_515_245 + 12_345
		b = alphabet[x >> 28]
	}
	return
}

stream_archive :: proc(t: ^testing.T, method: archive.Method, payload: []u8) -> (packed: [dynamic]u8) {
	wrap    := method == .LZ4 || method == .LZMA || method == .XZ
	options := tar.Writer_Options{compression = .Store if wrap else method}
	if !wrap {
		options.level = 1
	}
	out := strings.builder_make()
	tw: tar.Writer
	if !testing.expect_value(t, tar.create(&tw, strings.to_writer(&out), options), nil) {
		return out.buf
	}
	for start := 0; start < len(payload); start += STREAM_MEMBER_SIZE {
		n := min(STREAM_MEMBER_SIZE, len(payload) - start)
		fi: archive.File_Info
		fi.path      = fmt.tprintf("m%04d.bin", start / STREAM_MEMBER_SIZE)
		fi.type      = .Regular
		fi.size      = i64(n)
		fi.unix_mode = 0o644
		testing.expect_value(t, tar.write_entry(&tw, fi, payload[start:][:n]), nil)
	}
	testing.expect_value(t, tar.commit(&tw), nil)
	tar.close(&tw)
	if !wrap {
		return out.buf
	}
	defer strings.builder_destroy(&out)
	if method == .LZ4 {
		lz4_err := lz4.compress_frame_to_dynamic(&packed, out.buf[:], .Level_1, {block_max_size = .Max_64KiB, flags = lz4.DEFAULT_FRAME_FLAGS})
		testing.expect_value(t, lz4_err, nil)
		return
	}
	if method == .XZ {
		xz_opts := xz.level_options(.Level_1)
		xz_opts.lzma2.dict_size = 64 * 1024
		xz_err := xz.compress(&packed, out.buf[:], .Level_1, xz_opts)
		testing.expect_value(t, xz_err, nil)
		return
	}
	opts := lzma.level_options(.Level_1)
	opts.dict_size = 64 * 1024
	raw: [dynamic]u8
	defer delete(raw)
	props, err := lzma.compress_raw(&raw, out.buf[:], opts)
	testing.expect_value(t, err, nil)
	header := lzma.encode_properties(props)
	append(&packed, ..header[:])
	size := u64(len(out.buf))
	for i in 0..<8 {
		append(&packed, u8(size >> (8 * uint(i))))
	}
	append(&packed, ..raw[:])
	return
}

stream_extract :: proc(t: ^testing.T, packed: []u8, source: Source_Kind, method: archive.Method, sink: ^Sink) -> (peak: i64) {
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	defer mem.tracking_allocator_destroy(&track)
	context.allocator = mem.tracking_allocator(&track)

	reader: bytes.Reader
	wrapper: Non_Seekable
	r: tar.Reader
	err: archive.Error
	#partial switch source {
	case .Bytes:
		err = tar.open(&r, packed)
	case .Stream:
		err = tar.open(&r, bytes.reader_init(&reader, packed))
	case .Non_Seekable:
		wrapper.inner = bytes.reader_init(&reader, packed)
		err = tar.open(&r, non_seekable_stream(&wrapper))
	}
	if testing.expectf(t, err == nil, "%v via %v: open %v", method, source, err) {
		testing.expectf(t, r.compression == method, "%v via %v: read as %v", method, source, r.compression)
		it := tar.iterator_create(&r)
		for _ in tar.iterate(&it) {
			extract_err := tar.extract_current(&it, sink_stream(sink))
			testing.expectf(t, extract_err == nil, "%v via %v: extract %v", method, source, extract_err)
		}
		_, it_err := tar.iterator_error(&it)
		testing.expectf(t, it_err == nil, "%v via %v: %v", method, source, it_err)
		tar.iterator_destroy(&it)
	}
	tar.close(&r)
	testing.expectf(t, len(track.allocation_map) == 0, "%v via %v: %d allocations left", method, source, len(track.allocation_map))
	return track.peak_memory_allocated
}

sink_stream :: proc(s: ^Sink) -> (stream: io.Stream) {
	stream.data      = s
	stream.procedure = sink_proc
	return
}

sink_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	s := (^Sink)(stream_data)
	#partial switch mode {
	case .Write:
		s.total += i64(len(p))
		s.crc    = hash.crc32(p, s.crc)
		return i64(len(p)), nil
	case .Query:
		return io.query_utility({.Write, .Query})
	}
	return 0, .Unsupported
}
