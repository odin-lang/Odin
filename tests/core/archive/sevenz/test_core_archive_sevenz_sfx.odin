package test_core_archive_sevenz

import "core:archive"
import "core:archive/sevenz"
import "core:bytes"
import "core:encoding/endian"
import "core:fmt"
import "core:hash"
import "core:os"
import "core:strings"
import "core:testing"

ELF_HEAD   :: "\x7fELF\x02\x01\x01"
MACHO_HEAD :: "\xcf\xfa\xed\xfe"
MZ_HEAD    :: "MZ\x90\x00"

SIGNATURE      :: [6]u8{'7', 'z', 0xBC, 0xAF, 0x27, 0x1C}
SFX_CHUNK_SIZE :: 64 * 1024
SNIFF_SIZE     :: 1 << 14

@(test)
test_sfx_fixtures :: proc(t: ^testing.T) {
	Fixture :: struct {
		name:    string,
		plain:   string,
		base:    i64,
		members: int,
	}
	for f in ([?]Fixture{{"sfx-7zS2con.exe", "lzma2.7z", 34_816, 6}, {"sfx-7zSD.exe", "tree.7z", 129_165, 10}}) {
		data, read_err   := os.read_entire_file(asset(f.name), context.temp_allocator)
		plain, plain_err := os.read_entire_file(asset(f.plain), context.temp_allocator)
		if !testing.expectf(t, read_err == nil && plain_err == nil, "%s: %v %v", f.name, read_err, plain_err) {
			continue
		}
		testing.expectf(t, bytes.equal(data[f.base:], plain), "%s: %s follows the stub", f.name, f.plain)
		testing.expect_value(t, archive.which(data[:archive.DETECT_HEAD_SIZE]), archive.Format.Unknown)

		r: sevenz.Reader
		if testing.expect_value(t, sevenz.open(&r, asset(f.name)), nil) {
			testing.expect_value(t, r.base, f.base)
			sevenz.close(&r)
		}
		from_path, path_err := archive.open(asset(f.name))
		expect_generic_sfx(t, f.name, &from_path, path_err, f.members)
		from_bytes, bytes_err := archive.open(data)
		expect_generic_sfx(t, f.name, &from_bytes, bytes_err, f.members)
		br: bytes.Reader
		from_stream, stream_err := archive.open(bytes.reader_init(&br, data))
		expect_generic_sfx(t, f.name, &from_stream, stream_err, f.members)
	}
}

@(test)
test_sfx_stubs :: proc(t: ^testing.T) {
	entries := []Update_Entry{{name = "a.txt", content = write_text()}, {name = "d", directory = true}}
	plain := make_7z(t, entries)
	want := update_expect(entries)
	Stub :: struct {
		kind: string,
		head: string,
		size: int,
	}
	stubs := [?]Stub{
		{"MZ",     "MZ",       2},
		{"Mach-O", MACHO_HEAD, 4},
		{"ELF",    ELF_HEAD,   1000},
		{"MZ",     MZ_HEAD,    int(SFX_CHUNK_SIZE) - 10},
		{"ELF",    ELF_HEAD,   int(SFX_CHUNK_SIZE)},
		{"Mach-O", MACHO_HEAD, int(SFX_CHUNK_SIZE) + 1},
		{"MZ",     MZ_HEAD,    int(sevenz.SFX_SEARCH_MAX) - 1},
	}
	for s in stubs {
		label := fmt.tprintf("%s stub of %d bytes", s.kind, s.size)
		data := sfx_build(s.head, s.size, plain)
		check_written(t, label, data, want)
		r: sevenz.Reader
		if testing.expectf(t, sevenz.open(&r, data) == nil, "%s: open", label) {
			testing.expectf(t, r.base == i64(s.size), "%s: base %d", label, r.base)
			sevenz.close(&r)
		}
		br: bytes.Reader
		a, err := archive.open(bytes.reader_init(&br, data))
		expect_generic_sfx(t, label, &a, err, len(entries))
	}
}

@(test)
test_sfx_decoys :: proc(t: ^testing.T) {
	entries := []Update_Entry{{name = "a.txt", content = write_text()}}
	STUB :: 1024
	data := sfx_build(MZ_HEAD, STUB, make_7z(t, entries))
	available := u64(len(data) - 300 - 32)
	sfx_start(data[100:], 1, 0, 0)
	sfx_start(data[200:], 0, 5, 0)
	sfx_start(data[300:], 0, available - 10, 11)
	sfx_start(data[400:], 0, 1 << 40, 1)
	sfx_start(data[500:], 0, 0, 0)
	data[500 + 8] ~= 1
	r: sevenz.Reader
	if testing.expect_value(t, sevenz.open(&r, data), nil) {
		testing.expect_value(t, r.base, STUB)
		sevenz.close(&r)
	}
	check_written(t, "decoys", data, update_expect(entries))
}

@(test)
test_sfx_rejects :: proc(t: ^testing.T) {
	plain := make_7z(t, {{name = "a.txt", content = write_text()}})
	damaged := sfx_build(MACHO_HEAD, 1000, plain)
	damaged[1000 + 20] ~= 1
	Case :: struct {
		label: string,
		data:  []u8,
	}
	cases := [?]Case{
		{"a junk prefix",                sfx_build("Not an executable", 1000, plain)},
		{"beyond the search limit",      sfx_build(ELF_HEAD, int(sevenz.SFX_SEARCH_MAX), plain)},
		{"an executable and no archive", sfx_build(MZ_HEAD, 5000, nil)},
		{"MZ alone",                     sfx_build("MZ", 2, nil)},
		{"a damaged start header",       damaged},
	}
	for c in cases {
		r: sevenz.Reader
		err := sevenz.open(&r, c.data)
		testing.expectf(t, err == SevenZ_Error.Invalid_Signature, "%s: %v", c.label, err)
		a, generic_err := archive.open(c.data)
		testing.expectf(t, generic_err == archive.General_Error.Unknown_Format && a.format == .Unknown, "%s: generic open %v %v", c.label, generic_err, a.format)
	}

	broken := sfx_build(ELF_HEAD, 1000, plain)
	broken[len(broken) - 3] ~= 1
	a, err := archive.open(broken)
	testing.expectf(t, err == SevenZ_Error.Header_CRC_Mismatch && a.format == .SevenZ, "a damaged header behind a stub: %v %v", err, a.format)
}

@(test)
test_sfx_update :: proc(t: ^testing.T) {
	root, root_ok := update_root(t, "odin_7z_sfx_update_*")
	if !root_ok {
		return
	}
	defer os.remove_all(root)
	text   := write_text()
	random := write_random(30_000, 31)
	defer delete(random)

	before := []Update_Entry{
		{name = "a.txt", content = text},
		{name = "b.bin", content = random, method = .Store},
	}
	added := []Update_Entry{{name = "c.txt", content = text, method = .PPMd_H}}
	renamed := []Update_Entry{before[0], {name = "c.bin", content = random, method = .Store}}
	STUB :: 5000
	old := sfx_build(ELF_HEAD, STUB, make_7z(t, before))
	start := data_start_of(old)
	p := update_paths(root, "sfx.exe")

	Edit :: enum {
		Append,
		Remove,
		Rename,
	}
	wants := [Edit][]Write_Expect{
		.Append = update_expect(before, added),
		.Remove = update_expect(before[1:]),
		.Rename = update_expect(renamed),
	}
	for edit in Edit {
		label := fmt.tprintf("sfx %v", edit)
		testing.expect_value(t, os.write_entire_file(p.path, old), nil)
		sw: sevenz.Writer
		if testing.expect_value(t, sevenz.update(&sw, p.path), nil) {
			switch edit {
			case .Append: write_updates(t, &sw, added)
			case .Remove: testing.expect_value(t, sevenz.remove_entry(&sw, "a.txt"), nil)
			case .Rename: testing.expect_value(t, sevenz.rename_entry(&sw, "b.bin", "c.bin"), nil)
			}
			testing.expect_value(t, sevenz.commit(&sw), nil)
			sevenz.close(&sw)
		}
		data, _ := os.read_entire_file(p.path, context.temp_allocator)
		testing.expectf(t, len(data) > STUB && bytes.equal(data[:STUB], old[:STUB]), "%s: the stub stays", label)
		check_written(t, label, data, wants[edit])
		a, err := archive.open(data)
		expect_generic_sfx(t, label, &a, err, len(wants[edit]))
		if edit == .Append {
			testing.expectf(t, len(data) > start && bytes.equal(data[STUB + 32:start], old[STUB + 32:start]), "%s: the old packed streams stay in place", label)
		}
	}

	tw: Torn_Writer
	torn_init(&tw, old)
	sw: sevenz.Writer
	if testing.expect_value(t, sevenz.update(&sw, torn_stream(&tw)), nil) {
		testing.expect_value(t, sevenz.commit(&sw), nil)
		sevenz.close(&sw)
	}
	testing.expect_value(t, torn_writes(&tw), 0)

	torn_init(&tw, old)
	if testing.expect_value(t, sevenz.update(&sw, torn_stream(&tw), {deterministic = true}), nil) {
		write_updates(t, &sw, added)
		testing.expect_value(t, sevenz.commit(&sw), nil)
		sevenz.close(&sw)
	}
	testing.expect(t, bytes.equal(tw.data[:STUB], old[:STUB]), "sfx append/stream: the stub stays")
	check_written(t, "sfx append/stream", tw.data[:], wants[.Append])

	record := journal_expect(old, start, STUB)
	want := update_expect(before)
	for k in 0..=len(tw.ops) {
		label := fmt.tprintf("sfx crash after op %d", k)
		testing.expect_value(t, os.write_entire_file(p.path, torn_survivor(&tw, k, u64(k) * 31 + 7)), nil)
		testing.expect_value(t, os.write_entire_file(p.journal, record), nil)
		check_path(t, label, p.path, want)
		if testing.expect_value(t, sevenz.update(&sw, p.path), nil) {
			sevenz.close(&sw)
		}
		data, _ := os.read_entire_file(p.path, context.temp_allocator)
		testing.expectf(t, bytes.equal(data, old) && !os.exists(p.journal), "%s: recovery restores the old archive", label)
	}
}

sfx_build :: proc(head: string, size: int, plain: []u8) -> []u8 {
	data := make([]u8, size + len(plain), context.temp_allocator)
	for &b, i in data[:size] {
		b = u8(i * 7 + i / 13)
	}
	copy(data, head)
	if size >= 64 {
		signature := SIGNATURE
		copy(data[size / 2:], signature[:])
	}
	copy(data[size:], plain)
	return data
}

sfx_start :: proc(b: []u8, version: u8, next_offset, next_size: u64) {
	signature := SIGNATURE
	copy(b, signature[:])
	b[6], b[7] = version, 4
	endian.unchecked_put_u64le(b[12:], next_offset)
	endian.unchecked_put_u64le(b[20:], next_size)
	endian.unchecked_put_u32le(b[28:], 0)
	endian.unchecked_put_u32le(b[8:], hash.crc32(b[12:32]))
}

expect_generic_sfx :: proc(t: ^testing.T, label: string, a: ^archive.Archive, err: archive.Error, members: int) {
	if !testing.expectf(t, err == nil, "%s: generic open %v", label, err) {
		return
	}
	defer archive.close(a)
	testing.expectf(t, a.format == .SevenZ, "%s: format %v", label, a.format)
	it := archive.iterator_create(a)
	defer archive.iterator_destroy(&it)
	count := 0
	for fi in archive.iterate(&it) {
		count += 1
		if fi.type != .Regular {
			continue
		}
		sink := strings.builder_make()
		extract_err := archive.extract_current(&it, strings.to_writer(&sink))
		crc, has_crc := fi.crc32.?
		testing.expectf(t, extract_err == nil && i64(len(sink.buf)) == fi.size && (!has_crc || hash.crc32(sink.buf[:]) == crc), "%s/%s: %v", label, fi.path, extract_err)
		strings.builder_destroy(&sink)
	}
	testing.expectf(t, count == members, "%s: %d members, want %d", label, count, members)
}
