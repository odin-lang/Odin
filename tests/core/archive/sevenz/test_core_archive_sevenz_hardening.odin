package test_core_archive_sevenz

import "core:archive"
import "core:archive/sevenz"
import "core:bytes"
import "core:compress"
import "core:crypto/aes"
import "core:crypto/sha2"
import "core:hash"
import "core:io"
import "core:os"
import "core:strings"
import "core:testing"

COPY_ID    :: []u8{0x00}
UNKNOWN_ID :: []u8{0x04, 0xF7, 0x11, 0x01}

Archive_Spec :: struct {
	packed:      []u8,
	unpack_size: u64,
	coder:       []u8,
	folder_crc:  Maybe(u32),
	file_crc:    Maybe(u32),
	name:        string,
	file_count:  u64,
	depth:       int,
	header_crc:  Maybe(u32),
	header_size: u64,
	coder_bytes: []u8,
	pack_sizes:  []u64,
	streams:     []u64,
}

@(test)
test_substreams :: proc(t: ^testing.T) {
	data := pattern(1000)
	defer delete(data)
	solid := build_archive({packed = data, unpack_size = 1000, coder = COPY_ID, name = "A", streams = {300, 200}})
	defer delete(solid)
	r: sevenz.Reader
	if testing.expect_value(t, sevenz.open(&r, solid[:]), nil) {
		testing.expect_value(t, len(r.items), 3)
		it := sevenz.iterator_create(&r)
		offset := 0
		for fi in sevenz.iterate(&it) {
			got, err := extract_to_bytes(&it)
			end := offset + int(fi.size)
			testing.expectf(t, err == nil && end <= len(data) && bytes.equal(got[:], data[offset:end]), "member at %d: %v, %d bytes", offset, err, len(got))
			offset = end
			delete(got)
		}
		testing.expect_value(t, offset, 1000)
		sevenz.iterator_destroy(&it)
		sevenz.close(&r)
	}

	over := build_archive({packed = data, unpack_size = 1000, coder = COPY_ID, name = "A", streams = {600, 600}})
	defer delete(over)
	testing.expect_value(t, sevenz.open(&r, over[:]), SevenZ_Error.Size_Mismatch)
}

@(test)
test_bcj2_memory :: proc(t: ^testing.T) {
	inputs := pattern(17)
	defer delete(inputs)
	bcj2 := []u8{0x14, 0x03, 0x03, 0x01, 0x1B, 0x04, 0x01}
	built := build_archive({packed = inputs, pack_sizes = {4, 4, 4, 5}, coder_bytes = bcj2, unpack_size = 1 << 30, name = "A.EXE"})
	defer delete(built)
	r: sevenz.Reader
	if !testing.expect_value(t, sevenz.open(&r, built[:], compress.Options{max_memory = 64 << 20}), nil) {
		return
	}
	defer sevenz.close(&r)
	fi, handle, ok, _ := sevenz.find(&r, "A.EXE")
	testing.expect(t, ok && .BCJ2 in fi.filters && fi.size == 1 << 30, "A.EXE is a BCJ2 member")
	d: Discard
	testing.expect_value(t, sevenz.extract(&r, handle, discard_writer(&d)), compress.Error(compress.General_Error.Memory_Limit_Exceeded))
	testing.expect_value(t, d.count, 0)
}

@(test)
test_encoded_headers :: proc(t: ^testing.T) {
	data := pattern(1000)
	defer delete(data)
	spec := Archive_Spec{packed = data, unpack_size = 1000, coder = COPY_ID, file_crc = hash.crc32(data), name = "A.BIN"}
	for depth in 1..=5 {
		spec.depth = depth
		built := build_archive(spec)
		defer delete(built)
		r: sevenz.Reader
		err := sevenz.open(&r, built[:])
		if depth > 4 {
			testing.expectf(t, err == SevenZ_Error.Header_Too_Deep, "depth %d: %v", depth, err)
			continue
		}
		if !testing.expectf(t, err == nil, "depth %d: %v", depth, err) {
			continue
		}
		_, handle, ok, _ := sevenz.find(&r, "A.BIN")
		sink := strings.builder_make()
		testing.expectf(t, ok && sevenz.extract(&r, handle, strings.to_writer(&sink)) == nil && bytes.equal(sink.buf[:], data), "depth %d: A.BIN", depth)
		strings.builder_destroy(&sink)
		sevenz.close(&r)
	}

	spec.depth      = 1
	spec.header_crc = 0x12345678
	bad_crc := build_archive(spec)
	defer delete(bad_crc)
	r: sevenz.Reader
	testing.expect_value(t, sevenz.open(&r, bad_crc[:]), SevenZ_Error.CRC_Mismatch)

	spec.header_crc  = nil
	spec.header_size = 1 << 20
	too_big := build_archive(spec)
	defer delete(too_big)
	testing.expect_value(t, sevenz.open(&r, too_big[:], compress.Options{max_memory = 1 << 19}), SevenZ_Error.Header_Too_Large)

	spec.header_size = 0
	spec.name        = strings.repeat("N", 300, context.temp_allocator)
	long := build_archive(spec)
	defer delete(long)
	testing.expect_value(t, sevenz.open(&r, long[:], compress.Options{max_memory = 200}), SevenZ_Error.Header_Too_Large)
}

@(test)
test_built_archive :: proc(t: ^testing.T) {
	data := pattern(1000)
	defer delete(data)
	built := build_archive({packed = data, unpack_size = 1000, coder = COPY_ID, file_crc = hash.crc32(data), name = "A.BIN"})
	defer delete(built)
	r: sevenz.Reader
	if !testing.expect_value(t, sevenz.open(&r, built[:]), nil) {
		return
	}
	defer sevenz.close(&r)
	fi, handle, ok, _ := sevenz.find(&r, "A.BIN")
	testing.expect(t, ok && fi.size == 1000 && fi.method == .Store, "find A.BIN")
	sink := strings.builder_make()
	defer strings.builder_destroy(&sink)
	testing.expect_value(t, sevenz.extract(&r, handle, strings.to_writer(&sink)), nil)
	testing.expect(t, bytes.equal(sink.buf[:], data), "A.BIN data")
}

@(test)
test_data_before_size_mismatch :: proc(t: ^testing.T) {
	data := pattern(1000)
	defer delete(data)
	built := build_archive({packed = data, unpack_size = 2000, coder = COPY_ID, name = "A.BIN"})
	defer delete(built)
	r: sevenz.Reader
	if !testing.expect_value(t, sevenz.open(&r, built[:]), nil) {
		return
	}
	defer sevenz.close(&r)
	_, handle, ok, _ := sevenz.find(&r, "A.BIN")
	testing.expect(t, ok, "find A.BIN")

	m, open_err := sevenz.open_member(&r, handle)
	if testing.expect_value(t, open_err, nil) {
		buf: [4096]u8
		n, err := io.read(m, buf[:])
		testing.expectf(t, n == 1000 && err == nil && bytes.equal(buf[:n], data), "first read: %d %v", n, err)
		n, err = io.read(m, buf[:])
		testing.expectf(t, n == 0 && err == .Unknown, "second read: %d %v", n, err)
		sevenz.close_member(m)
	}

	sink := strings.builder_make()
	defer strings.builder_destroy(&sink)
	testing.expect_value(t, sevenz.extract(&r, handle, strings.to_writer(&sink)), SevenZ_Error.Size_Mismatch)
	testing.expect(t, bytes.equal(sink.buf[:], data), "extract writes the data before the error")
}

@(test)
test_data_before_folder_crc :: proc(t: ^testing.T) {
	data := pattern(1000)
	defer delete(data)
	built := build_archive({packed = data, unpack_size = 1000, coder = COPY_ID, folder_crc = ~hash.crc32(data), name = "A.BIN"})
	defer delete(built)
	r: sevenz.Reader
	if !testing.expect_value(t, sevenz.open(&r, built[:]), nil) {
		return
	}
	defer sevenz.close(&r)
	fi, handle, ok, _ := sevenz.find(&r, "A.BIN")
	crc, has_crc := fi.crc32.?
	testing.expect(t, ok && has_crc && crc == ~hash.crc32(data), "the folder CRC is the member's")

	m, open_err := sevenz.open_member(&r, handle)
	if testing.expect_value(t, open_err, nil) {
		buf: [4096]u8
		n, err := io.read(m, buf[:])
		testing.expectf(t, n == 1000 && err == nil, "first read: %d %v", n, err)
		n, err = io.read(m, buf[:])
		testing.expectf(t, n == 0 && err == .Unknown, "second read: %d %v", n, err)
		sevenz.close_member(m)
	}

	sink := strings.builder_make()
	defer strings.builder_destroy(&sink)
	testing.expect_value(t, sevenz.extract(&r, handle, strings.to_writer(&sink)), SevenZ_Error.CRC_Mismatch)
	testing.expect_value(t, len(sink.buf), 1000)

	it := sevenz.iterator_create(&r)
	defer sevenz.iterator_destroy(&it)
	for _ in sevenz.iterate(&it) {
		got, iter_err := extract_to_bytes(&it)
		testing.expect_value(t, iter_err, SevenZ_Error.CRC_Mismatch)
		testing.expect_value(t, len(got), 1000)
		delete(got)
	}
}

@(test)
test_unread_pack_tail :: proc(t: ^testing.T) {
	data := pattern(1000)
	defer delete(data)
	packed := make([]u8, 1007)
	defer delete(packed)
	copy(packed, data)
	built := build_archive({packed = packed, unpack_size = 1000, coder = COPY_ID, file_crc = hash.crc32(data), name = "A.BIN"})
	defer delete(built)
	log: Progress_Log
	defer delete(log.calls)
	r: sevenz.Reader
	if !testing.expect_value(t, sevenz.open(&r, built[:], compress.Options{progress = progress_record, progress_data = &log}), nil) {
		return
	}
	defer sevenz.close(&r)
	fi, handle, ok, _ := sevenz.find(&r, "A.BIN")
	testing.expect(t, ok && fi.compressed_size == 1007, "find A.BIN")
	m, open_err := sevenz.open_member(&r, handle)
	if !testing.expect_value(t, open_err, nil) {
		return
	}
	got, got_err := read_stream(m, 256)
	testing.expectf(t, got_err == nil && bytes.equal(got[:], data), "read: %v %d", got_err, len(got))
	delete(got)
	sevenz.close_member(m)
	if !testing.expect(t, len(log.calls) > 0, "no progress") {
		return
	}
	last := log.calls[len(log.calls) - 1]
	testing.expectf(t, last.bytes_in == 1007 && last.total_in == 1007, "bytes_in %d total_in %d", last.bytes_in, last.total_in)
	testing.expectf(t, last.archive_in == r.streams.pack_offsets[0] + 1007, "archive_in %d", last.archive_in)
}

@(test)
test_member_limit_before_write :: proc(t: ^testing.T) {
	data := pattern(1000)
	defer delete(data)
	built := build_archive({packed = data, unpack_size = 1000, coder = COPY_ID, file_crc = hash.crc32(data), name = "A.BIN"})
	defer delete(built)
	for limit in ([?]int{999, 1000}) {
		r: sevenz.Reader
		if !testing.expect_value(t, sevenz.open(&r, built[:], compress.Options{max_output_size = limit}), nil) {
			continue
		}
		_, handle, _, _ := sevenz.find(&r, "A.BIN")
		sink := strings.builder_make()
		err := sevenz.extract(&r, handle, strings.to_writer(&sink))
		if limit < 1000 {
			testing.expectf(t, err == compress.Error(compress.General_Error.Output_Too_Short) && len(sink.buf) == 0, "limit %d: %v, %d bytes", limit, err, len(sink.buf))
		} else {
			testing.expectf(t, err == nil && bytes.equal(sink.buf[:], data), "limit %d: %v", limit, err)
		}
		strings.builder_destroy(&sink)
		sevenz.close(&r)
	}
}

@(test)
test_unknown_method :: proc(t: ^testing.T) {
	data := pattern(100)
	defer delete(data)
	built := build_archive({packed = data, unpack_size = 100, coder = UNKNOWN_ID, name = "A.BIN"})
	defer delete(built)
	r: sevenz.Reader
	if !testing.expect_value(t, sevenz.open(&r, built[:]), nil) {
		return
	}
	defer sevenz.close(&r)
	fi, handle, ok, _ := sevenz.find(&r, "A.BIN")
	testing.expect(t, ok && !fi.supported && !fi.encrypted && fi.method == .Unknown && fi.method_id == 0x04F71101, "A.BIN is unsupported")
	sink := strings.builder_make()
	defer strings.builder_destroy(&sink)
	testing.expect_value(t, sevenz.extract(&r, handle, strings.to_writer(&sink)), archive.General_Error.Unsupported_Method)
	_, open_err := sevenz.open_member(&r, handle)
	testing.expect_value(t, open_err, archive.General_Error.Unsupported_Method)
}

@(test)
test_malformed :: proc(t: ^testing.T) {
	data := pattern(100)
	defer delete(data)
	built := build_archive({packed = data, unpack_size = 100, coder = COPY_ID, name = "A.BIN"})
	defer delete(built)
	work := make([]u8, len(built))
	defer delete(work)
	r: sevenz.Reader

	copy(work, built[:])
	work[0] = 'X'
	testing.expect_value(t, sevenz.open(&r, work), SevenZ_Error.Invalid_Signature)

	copy(work, built[:])
	work[6] = 1
	testing.expect_value(t, sevenz.open(&r, work), SevenZ_Error.Unsupported_Version)

	copy(work, built[:])
	work[20] ~= 1
	testing.expect_value(t, sevenz.open(&r, work), SevenZ_Error.Header_CRC_Mismatch)

	copy(work, built[:])
	work[len(work) - 3] ~= 1
	testing.expect_value(t, sevenz.open(&r, work), SevenZ_Error.Header_CRC_Mismatch)

	testing.expect_value(t, sevenz.open(&r, built[:len(built) - 1]), SevenZ_Error.Truncated)
	testing.expect_value(t, sevenz.open(&r, built[:31]), SevenZ_Error.Invalid_Signature)

	many := build_archive({packed = data, unpack_size = 100, coder = COPY_ID, name = "A.BIN", file_count = 1 << 40})
	defer delete(many)
	testing.expect_value(t, sevenz.open(&r, many[:]), SevenZ_Error.Invalid_Header)
}

@(test)
test_corruption :: proc(t: ^testing.T) {
	names := [?]string{"copy.7z", "lzma.7z", "lzma2.7z", "ppmd.7z", "bzip2.7z", "deflate.7z", "deflate64.7z", "bcj2.7z", "x9.7z", "swap4.7z", "delta-4.7z", "lzma2-chunks.7z", "solid-2f.7z", "libarchive-mac-ppmd.7z"}
	FLIPS :: 40
	seed := u64(0x9E3779B97F4A7C15)
	for name in names {
		data, read_err := os.read_entire_file(asset(name), context.allocator)
		if !testing.expectf(t, read_err == nil, "%s: %v", name, read_err) {
			continue
		}
		defer delete(data)
		r: sevenz.Reader
		if !testing.expectf(t, sevenz.open(&r, data) == nil, "%s: open", name) {
			continue
		}
		packed_end := r.header_start
		sevenz.close(&r)
		work := make([]u8, len(data))
		defer delete(work)
		for _ in 0..<FLIPS {
			copy(work, data)
			seed = seed * 6364136223846793005 + 1442695040888963407
			at := 32 + int((seed >> 33) % u64(packed_end - 32))
			work[at] ~= u8(1) << ((seed >> 29) & 7)
			check_corrupt(t, name, work)
		}
	}
}

check_corrupt :: proc(t: ^testing.T, name: string, data: []u8) {
	r: sevenz.Reader
	if sevenz.open(&r, data) != nil {
		return
	}
	defer sevenz.close(&r)
	it := sevenz.iterator_create(&r)
	defer sevenz.iterator_destroy(&it)
	for fi in sevenz.iterate(&it) {
		if fi.type == .Directory {
			continue
		}
		got, err := extract_to_bytes(&it)
		if err == nil {
			testing.expectf(t, i64(len(got)) == fi.size, "%s/%s: corrupt archive gave %d bytes", name, fi.path, len(got))
			if crc, ok := fi.crc32.?; ok {
				testing.expectf(t, hash.crc32(got[:]) == crc, "%s/%s: corrupt archive passed with a bad CRC", name, fi.path)
			}
		}
		m, open_err := sevenz.open_member(&r, fi.handle)
		if open_err == nil {
			streamed, read_err := read_stream(m, 4096)
			testing.expectf(t, (read_err == nil) == (err == nil), "%s/%s: open_member %v, extract %v", name, fi.path, read_err, err)
			if read_err == nil && err == nil {
				testing.expectf(t, bytes.equal(streamed[:], got[:]), "%s/%s: open_member data differs", name, fi.path)
			}
			delete(streamed)
			sevenz.close_member(m)
		} else {
			testing.expectf(t, err != nil, "%s/%s: open_member %v, extract nil", name, fi.path, open_err)
		}
		delete(got)
	}
}

@(test)
test_aes_folders :: proc(t: ^testing.T) {
	data := pattern(96)
	defer delete(data)
	salt := []u8{'S', 'A', 'L', 'T'}
	iv   := []u8{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15}
	Case :: struct {
		name:  string,
		power: u8,
		salt:  []u8,
		iv:    []u8,
		bare:  bool,
	}
	cases := [?]Case{
		{"raw key",       0x3F, salt, iv,  false},
		{"one round",     0,    salt, iv,  false},
		{"no salt",       4,    nil,  iv,  false},
		{"no iv",         2,    salt, nil, false},
		{"power only",    1,    nil,  nil, false},
		{"no properties", 0,    nil,  nil, true},
	}
	for c in cases {
		packed := aes_encrypt(data, c.power, c.salt, c.iv, PASSWORD)
		defer delete(packed)
		coder := aes_coder(c.power, c.salt, c.iv, c.bare)
		defer delete(coder)
		built := build_archive({packed = packed, unpack_size = u64(len(data)), coder_bytes = coder[:], folder_crc = hash.crc32(data), name = "A.BIN"})
		defer delete(built)
		r: sevenz.Reader
		if !testing.expectf(t, sevenz.open(&r, built[:]) == nil, "%s: open", c.name) {
			continue
		}
		fi, handle, ok, _ := sevenz.find(&r, "A.BIN")
		testing.expectf(t, ok && fi.encrypted && fi.supported, "%s: A.BIN is encrypted", c.name)
		sink := strings.builder_make()
		testing.expectf(t, sevenz.extract(&r, handle, strings.to_writer(&sink)) == archive.General_Error.Encrypted, "%s: no password", c.name)
		strings.builder_reset(&sink)
		testing.expectf(t, sevenz.extract(&r, handle, strings.to_writer(&sink), {password = "odin"}) == archive.General_Error.Wrong_Password, "%s: wrong password", c.name)
		strings.builder_reset(&sink)
		err := sevenz.extract(&r, handle, strings.to_writer(&sink), {password = PASSWORD})
		testing.expectf(t, err == nil && bytes.equal(sink.buf[:], data), "%s: %v", c.name, err)
		strings.builder_destroy(&sink)
		sevenz.close(&r)
	}

	Bad :: struct {
		name:   string,
		coder:  []u8,
		packed: int,
		want:   archive.Error,
	}
	bads := [?]Bad{
		{"power over the cap", {0x24, 0x06, 0xF1, 0x07, 0x01, 0x01, 25},         16, archive.General_Error.Limit_Exceeded},
		{"power 63 is raw",    {0x24, 0x06, 0xF1, 0x07, 0x01, 0x01, 0x3F},       16, archive.General_Error.Wrong_Password},
		{"short properties",   {0x24, 0x06, 0xF1, 0x07, 0x01, 0x02, 0xC1, 0x00}, 16, SevenZ_Error.Invalid_Folder},
		{"flagless extra",     {0x24, 0x06, 0xF1, 0x07, 0x01, 0x02, 0x01, 0x00}, 16, SevenZ_Error.Invalid_Folder},
		{"flags, no sizes",    {0x24, 0x06, 0xF1, 0x07, 0x01, 0x01, 0x41},       16, SevenZ_Error.Invalid_Folder},
		{"partial block",      {0x24, 0x06, 0xF1, 0x07, 0x01, 0x01, 0x01},       15, SevenZ_Error.Invalid_Folder},
	}
	for b in bads {
		packed := pattern(b.packed)
		defer delete(packed)
		built := build_archive({packed = packed, unpack_size = u64(b.packed), coder_bytes = b.coder, folder_crc = 0, name = "A.BIN"})
		defer delete(built)
		r: sevenz.Reader
		if !testing.expectf(t, sevenz.open(&r, built[:]) == nil, "%s: open", b.name) {
			continue
		}
		_, handle, ok, _ := sevenz.find(&r, "A.BIN")
		testing.expectf(t, ok, "%s: find", b.name)
		sink := strings.builder_make()
		err := sevenz.extract(&r, handle, strings.to_writer(&sink), {password = PASSWORD})
		testing.expectf(t, err == b.want, "%s: %v, want %v", b.name, err, b.want)
		strings.builder_destroy(&sink)
		sevenz.close(&r)
	}
}

aes_coder :: proc(power: u8, salt, iv: []u8, bare: bool) -> (out: [dynamic]u8) {
	if bare {
		append(&out, 0x04, 0x06, 0xF1, 0x07, 0x01)
		return
	}
	props: [dynamic]u8
	defer delete(props)
	b0 := power
	if len(salt) > 0 {
		b0 |= 0x80
	}
	if len(iv) > 0 {
		b0 |= 0x40
	}
	append(&props, b0)
	if len(salt) > 0 || len(iv) > 0 {
		s := len(salt) - 1 if len(salt) > 0 else 0
		v := len(iv) - 1 if len(iv) > 0 else 0
		append(&props, u8(s << 4 | v))
		append(&props, ..salt)
		append(&props, ..iv)
	}
	append(&out, 0x24, 0x06, 0xF1, 0x07, 0x01, u8(len(props)))
	append(&out, ..props[:])
	return
}

aes_encrypt :: proc(data: []u8, power: u8, salt, iv: []u8, password: string) -> (out: []u8) {
	key := aes_key(power, salt, password)
	ecb: aes.Context_ECB
	aes.init_ecb(&ecb, key[:])
	defer aes.reset_ecb(&ecb)
	chain: [16]u8
	copy(chain[:], iv)
	out = make([]u8, len(data))
	for i := 0; i < len(data); i += 16 {
		block: [16]u8
		for k in 0..<16 {
			block[k] = data[i + k] ~ chain[k]
		}
		aes.encrypt_ecb(&ecb, out[i:][:16], block[:])
		copy(chain[:], out[i:][:16])
	}
	return
}

aes_key :: proc(power: u8, salt: []u8, password: string) -> (key: [32]u8) {
	encoded: [dynamic]u8
	defer delete(encoded)
	for c in transmute([]u8)password {
		append(&encoded, c, 0)
	}
	if power == 0x3F {
		n := copy(key[:], salt)
		copy(key[n:], encoded[:])
	} else {
		buf: [dynamic]u8
		defer delete(buf)
		append(&buf, ..salt)
		append(&buf, ..encoded[:])
		resize(&buf, len(buf) + 8)
		counter := buf[len(buf) - 8:]
		ctx: sha2.Context_256
		sha2.init_256(&ctx)
		for round in 0..<u64(1) << power {
			for &b, k in counter {
				b = u8(round >> (8 * uint(k)))
			}
			sha2.update(&ctx, buf[:])
		}
		sha2.final(&ctx, key[:])
	}
	return
}

pattern :: proc(n: int) -> (data: []u8) {
	data = make([]u8, n)
	for &b, i in data {
		b = u8(i * 7 + i / 13)
	}
	return
}

put_number :: proc(b: ^[dynamic]u8, v: u64) {
	if v < 0x80 {
		append(b, u8(v))
		return
	}
	append(b, 0xFF)
	for i in 0..<8 {
		append(b, u8(v >> (8 * uint(i))))
	}
}

put_u32 :: proc(b: ^[dynamic]u8, v: u32) {
	for i in 0..<4 {
		append(b, u8(v >> (8 * uint(i))))
	}
}

put_u64 :: proc(b: ^[dynamic]u8, v: u64) {
	for i in 0..<8 {
		append(b, u8(v >> (8 * uint(i))))
	}
}

build_archive :: proc(spec: Archive_Spec) -> (out: [dynamic]u8) {
	header: [dynamic]u8
	defer delete(header)
	pack_sizes := spec.pack_sizes
	single := []u64{u64(len(spec.packed))}
	if len(pack_sizes) == 0 {
		pack_sizes = single
	}
	append(&header, 0x01, 0x04, 0x06)
	put_number(&header, 0)
	put_number(&header, u64(len(pack_sizes)))
	append(&header, 0x09)
	for size in pack_sizes {
		put_number(&header, size)
	}
	append(&header, 0x00, 0x07, 0x0B)
	put_number(&header, 1)
	append(&header, 0x00)
	put_number(&header, 1)
	if spec.coder_bytes != nil {
		append(&header, ..spec.coder_bytes)
	} else {
		append(&header, u8(len(spec.coder)))
		append(&header, ..spec.coder)
	}
	if len(pack_sizes) > 1 {
		for i in 0..<len(pack_sizes) {
			put_number(&header, u64(i))
		}
	}
	append(&header, 0x0C)
	put_number(&header, spec.unpack_size)
	if crc, ok := spec.folder_crc.?; ok {
		append(&header, 0x0A, 0x01)
		put_u32(&header, crc)
	}
	append(&header, 0x00)
	if spec.streams != nil {
		append(&header, 0x08, 0x0D)
		put_number(&header, u64(len(spec.streams) + 1))
		append(&header, 0x09)
		for size in spec.streams {
			put_number(&header, size)
		}
		append(&header, 0x00)
	} else if crc, ok := spec.file_crc.?; ok {
		append(&header, 0x08, 0x0A, 0x01)
		put_u32(&header, crc)
		append(&header, 0x00)
	}
	file_count := spec.file_count
	if file_count == 0 {
		file_count = u64(len(spec.streams) + 1)
	}
	append(&header, 0x00, 0x05)
	put_number(&header, file_count)
	names := int(file_count) if file_count <= 64 else 1
	append(&header, 0x11)
	put_number(&header, u64(1 + names * (2 * len(spec.name) + 2)))
	append(&header, 0x00)
	for _ in 0..<names {
		for c in transmute([]u8)spec.name {
			append(&header, c, 0)
		}
		append(&header, 0x00, 0x00)
	}
	append(&header, 0x00, 0x00)

	body: [dynamic]u8
	defer delete(body)
	append(&body, ..spec.packed)
	for level in 0..<spec.depth {
		position := len(body)
		append(&body, ..header[:])
		size := u64(len(header))
		crc  := hash.crc32(header[:])
		if level == spec.depth - 1 {
			if spec.header_size > 0 {
				size = spec.header_size
			}
			if c, ok := spec.header_crc.?; ok {
				crc = c
			}
		}
		clear(&header)
		append(&header, 0x17, 0x06)
		put_number(&header, u64(position))
		put_number(&header, 1)
		append(&header, 0x09)
		put_number(&header, u64(len(body) - position))
		append(&header, 0x00, 0x07, 0x0B)
		put_number(&header, 1)
		append(&header, 0x00)
		put_number(&header, 1)
		append(&header, 0x01, 0x00, 0x0C)
		put_number(&header, size)
		append(&header, 0x0A, 0x01)
		put_u32(&header, crc)
		append(&header, 0x00, 0x00)
	}

	start: [dynamic]u8
	defer delete(start)
	put_u64(&start, u64(len(body)))
	put_u64(&start, u64(len(header)))
	put_u32(&start, hash.crc32(header[:]))

	append(&out, '7', 'z', 0xBC, 0xAF, 0x27, 0x1C, 0x00, 0x04)
	put_u32(&out, hash.crc32(start[:]))
	append(&out, ..start[:])
	append(&out, ..body[:])
	append(&out, ..header[:])
	return
}
