package test_core_archive_zip

import "core:archive"
import "core:archive/zip"
import "core:compress"
import "core:compress/bzip2"
import "core:compress/deflate"
import pkzip_legacy "core:compress/pkzip-legacy"
import "core:encoding/endian"
import "core:fmt"
import "core:hash"
import "core:io"
import "core:mem"
import "core:os"
import "core:strings"
import "core:testing"

KERNEL_SIZE :: 100_000
CRAFTED_TEXT :: "The quick brown fox jumps over the lazy dog, and then it jumps over the lazy dog again."

AES_SALT_SIZE    :: 16
LZMA_SDK_VERSION :: [2]u8{19, 0}

Signature :: enum u32le {
	Local         = 0x04034b50,
	Central       = 0x02014b50,
	End           = 0x06054b50,
	Zip64_End     = 0x06064b50,
	Zip64_Locator = 0x07064b50,
}

Local_Header :: struct #packed {
	signature:         Signature,
	version_needed:    u16le,
	flags:             zip.Flags,
	method:            zip.Method,
	dos_time:          u16le,
	dos_date:          u16le,
	crc32:             u32le,
	compressed_size:   u32le,
	uncompressed_size: u32le,
	name_length:       u16le,
	extra_length:      u16le,
}

Central_Header :: struct #packed {
	signature:           Signature,
	made_by_version:     u8,
	made_by_host:        zip.Host,
	version_needed:      u16le,
	flags:               zip.Flags,
	method:              zip.Method,
	dos_time:            u16le,
	dos_date:            u16le,
	crc32:               u32le,
	compressed_size:     u32le,
	uncompressed_size:   u32le,
	name_length:         u16le,
	extra_length:        u16le,
	comment_length:      u16le,
	start_disk:          u16le,
	internal_attributes: u16le,
	external_attributes: u32le,
	local_header_offset: u32le,
}

End_Record :: struct #packed {
	signature:         Signature,
	disk:              u16le,
	central_disk:      u16le,
	entries_this_disk: u16le,
	entries_total:     u16le,
	central_size:      u32le,
	central_offset:    u32le,
	comment_length:    u16le,
}

Zip64_End_Record :: struct #packed {
	signature:         Signature,
	record_size:       u64le,
	made_by_version:   u8,
	made_by_host:      zip.Host,
	version_needed:    u16le,
	disk:              u32le,
	central_disk:      u32le,
	entries_this_disk: u64le,
	entries_total:     u64le,
	central_size:      u64le,
	central_offset:    u64le,
}

Zip64_Locator :: struct #packed {
	signature:   Signature,
	disk:        u32le,
	end_offset:  u64le,
	total_disks: u32le,
}

Crafted :: struct {
	data:    [dynamic]u8,
	central: [dynamic]u8,
	count:   int,
	zip64:   bool,
}

Crafted_Member :: struct {
	name:   string,
	method: zip.Method,
	flags:  zip.Flags,
	crc:    u32,
	packed: int,
	size:   int,
}

Local_Tamper :: enum {
	None,
	Blank,
	Zip64_Sizes,
	Name,
	Name_Length,
	Method,
	Encrypted,
	CRC,
	Compressed_Size,
	Size,
}

Member_Result :: struct {
	extract: zip.Error,
	written: i64,
	open:    zip.Error,
	read:    io.Error,
}

Legacy_Bits :: struct {
	buffer: [dynamic]u8,
	bits:   u64,
	count:  uint,
}

@(test)
test_overlap_quoted :: proc(t: ^testing.T) {
	for zip64 in ([2]bool{false, true}) {
		data, verified := quoted_overlap_bomb(t, 8, zip64)
		defer delete(data)
		testing.expectf(t, verified, "zip64 %v: member 0 inflates to its declared size and CRC", zip64)
		results := crafted_results(t, data[:])
		defer delete(results)
		if !testing.expect_value(t, len(results), 8) {
			continue
		}
		for res, i in results[:7] {
			testing.expectf(t, res.extract == Zip_Error.Overlapping_Member, "zip64 %v, member %d: extract %v", zip64, i, res.extract)
			testing.expectf(t, res.open == Zip_Error.Overlapping_Member, "zip64 %v, member %d: open %v", zip64, i, res.open)
			testing.expectf(t, res.written == 0, "zip64 %v, member %d: wrote %d", zip64, i, res.written)
		}
		expect_member_ok(t, results[7], KERNEL_SIZE, "quoted overlap, last member")
	}
}

@(test)
test_overlap_extra_field :: proc(t: ^testing.T) {
	data := extra_field_bomb(t, 8)
	defer delete(data)
	results := crafted_results(t, data[:])
	defer delete(results)
	if !testing.expect_value(t, len(results), 8) {
		return
	}
	for res, i in results[:7] {
		testing.expectf(t, res.extract == Zip_Error.Overlapping_Member, "member %d: extract %v", i, res.extract)
		testing.expectf(t, res.open == Zip_Error.Overlapping_Member, "member %d: open %v", i, res.open)
	}
	expect_member_ok(t, results[7], KERNEL_SIZE, "extra-field quoting, last member")
}

@(test)
test_overlap_full :: proc(t: ^testing.T) {
	plain_kernel, kernel := bomb_kernel(t)
	defer delete(plain_kernel)
	defer delete(kernel)
	m := Crafted_Member{name = "m00", method = .Deflate, crc = hash.crc32(plain_kernel[:]), packed = len(kernel), size = KERNEL_SIZE}
	c: Crafted
	defer crafted_destroy(&c)
	crafted_local(&c.data, m)
	append(&c.data, ..kernel[:])
	for i in 0..<8 {
		alias := m
		alias.name = fmt.tprintf("m%02d", i)
		crafted_central(&c, alias, 0)
	}
	results := crafted_results(t, crafted_finish(&c))
	defer delete(results)
	testing.expect_value(t, len(results), 8)
	for res, i in results {
		testing.expectf(t, res.extract == Zip_Error.Overlapping_Member, "member %d: extract %v", i, res.extract)
		testing.expectf(t, res.open == Zip_Error.Overlapping_Member, "member %d: open %v", i, res.open)
	}
}

@(test)
test_overlap_near_misses :: proc(t: ^testing.T) {
	text := transmute([]u8)string(CRAFTED_TEXT)
	with_p := hash.crc32([]u8{'P'}, hash.crc32(text))

	{
		c: Crafted
		defer crafted_destroy(&c)
		a, ao := crafted_add(&c, "a.txt", .Store, CRAFTED_TEXT)
		b, bo := crafted_add(&c, "b.txt", .Store, CRAFTED_TEXT)
		a.packed += 1
		a.size   += 1
		a.crc     = with_p
		crafted_central(&c, a, ao)
		crafted_central(&c, b, bo)
		results := crafted_results(t, crafted_finish(&c))
		defer delete(results)
		if testing.expect_value(t, len(results), 2) {
			testing.expect_value(t, results[0].extract, Zip_Error.Overlapping_Member)
			testing.expect_value(t, results[0].open, Zip_Error.Overlapping_Member)
			expect_member_ok(t, results[1], len(text), "one byte into the next local header, next member")
		}
	}

	{
		c: Crafted
		defer crafted_destroy(&c)
		a, ao := crafted_add(&c, "a.txt", .Store, CRAFTED_TEXT)
		b, bo := crafted_add(&c, "b.txt", .Store, CRAFTED_TEXT)
		b.packed += 1
		b.size   += 1
		b.crc     = with_p
		crafted_central(&c, a, ao)
		crafted_central(&c, b, bo)
		results := crafted_results(t, crafted_finish(&c))
		defer delete(results)
		if testing.expect_value(t, len(results), 2) {
			expect_member_ok(t, results[0], len(text), "one byte into the CD, first member")
			testing.expect_value(t, results[1].extract, Zip_Error.Overlapping_Member)
		}
	}

	{
		c: Crafted
		defer crafted_destroy(&c)
		hidden: Crafted
		defer crafted_destroy(&hidden)
		a, ao := crafted_add(&c, "a.txt", .Store, CRAFTED_TEXT)
		x, _  := crafted_add(&hidden, "x.txt", .Store, CRAFTED_TEXT)
		central_offset := len(c.data)
		crafted_central(&c, a, ao, hidden.data[:])
		crafted_central(&c, x, central_offset + size_of(Central_Header) + len(a.name))
		results := crafted_results(t, crafted_finish(&c))
		defer delete(results)
		if testing.expect_value(t, len(results), 2) {
			expect_member_ok(t, results[0], len(text), "local header inside the CD, first member")
			testing.expect_value(t, results[1].extract, Zip_Error.Overlapping_Member)
		}
	}

	{
		c: Crafted
		defer crafted_destroy(&c)
		hidden: Crafted
		defer crafted_destroy(&hidden)
		a, ao := crafted_add(&c, "a.txt", .Store, CRAFTED_TEXT)
		y, _  := crafted_add(&hidden, "y.txt", .Store, CRAFTED_TEXT)
		central_size := 2 * size_of(Central_Header) + len(a.name) + len(y.name)
		crafted_central(&c, a, ao)
		crafted_central(&c, y, len(c.data) + central_size + size_of(End_Record))
		results := crafted_results(t, crafted_finish(&c, hidden.data[:]))
		defer delete(results)
		if testing.expect_value(t, len(results), 2) {
			expect_member_ok(t, results[0], len(text), "local header inside the end record comment, first member")
			testing.expect_value(t, results[1].extract, Zip_Error.Overlapping_Member)
		}
	}

	{
		c: Crafted
		defer crafted_destroy(&c)
		a, ao := crafted_add(&c, "a.txt", .Store, CRAFTED_TEXT)
		b := a
		b.name = "b.txt"
		crafted_central(&c, a, ao)
		crafted_central(&c, b, ao)
		results := crafted_results(t, crafted_finish(&c))
		defer delete(results)
		if testing.expect_value(t, len(results), 2) {
			testing.expect_value(t, results[0].extract, Zip_Error.Overlapping_Member)
			testing.expect_value(t, results[1].extract, Zip_Error.Overlapping_Member)
		}
	}
}

@(test)
test_overlap_legit_layouts :: proc(t: ^testing.T) {
	size := len(CRAFTED_TEXT)

	{
		c: Crafted
		defer crafted_destroy(&c)
		a, ao := crafted_add(&c, "a.txt", .Deflate, CRAFTED_TEXT)
		b, bo := crafted_add(&c, "b.txt", .Store, CRAFTED_TEXT)
		d, do_ := crafted_add(&c, "c.txt", .Deflate, CRAFTED_TEXT)
		crafted_central(&c, d, do_)
		crafted_central(&c, b, bo)
		crafted_central(&c, a, ao)
		expect_all_ok(t, crafted_finish(&c), {size, size, size}, "reversed CD order")
	}

	{
		c: Crafted
		defer crafted_destroy(&c)
		junk := [13]u8{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12}
		a, ao := crafted_add(&c, "a.txt", .Deflate, CRAFTED_TEXT)
		append(&c.data, ..junk[:])
		b, bo := crafted_add(&c, "b.txt", .Store, CRAFTED_TEXT)
		append(&c.data, ..junk[:])
		crafted_central(&c, a, ao)
		crafted_central(&c, b, bo)
		expect_all_ok(t, crafted_finish(&c), {size, size}, "gaps between members")
	}

	{
		c: Crafted
		defer crafted_destroy(&c)
		padding: [37]u8
		padding[0], padding[1], padding[2] = 0x35, 0xD9, 33
		a, ao := crafted_add(&c, "a.txt", .Store, CRAFTED_TEXT, padding[:])
		b, bo := crafted_add(&c, "b.txt", .Deflate, CRAFTED_TEXT, padding[:])
		crafted_central(&c, a, ao)
		crafted_central(&c, b, bo)
		expect_all_ok(t, crafted_finish(&c), {size, size}, "local extra longer than the CD's")
	}

	{
		c: Crafted
		defer crafted_destroy(&c)
		a, ao := crafted_add(&c, "a.txt", .Deflate, CRAFTED_TEXT, descriptor = true)
		b, bo := crafted_add(&c, "b.txt", .Store, CRAFTED_TEXT, descriptor = true)
		crafted_central(&c, a, ao)
		crafted_central(&c, b, bo)
		expect_all_ok(t, crafted_finish(&c), {size, size}, "data descriptors")
	}

	{
		c: Crafted
		defer crafted_destroy(&c)
		e1, e1o := crafted_add(&c, "e1", .Store, "")
		e2, e2o := crafted_add(&c, "e2", .Store, "")
		e3, e3o := crafted_add(&c, "e3", .Deflate, "")
		a,  ao  := crafted_add(&c, "a.txt", .Store, CRAFTED_TEXT)
		crafted_central(&c, e1, e1o)
		crafted_central(&c, e2, e2o)
		crafted_central(&c, e3, e3o)
		crafted_central(&c, a, ao)
		expect_all_ok(t, crafted_finish(&c), {0, 0, 0, size}, "empty members back to back")
	}

	for absolute in ([2]bool{false, true}) {
		junk: [100]u8
		c: Crafted
		defer crafted_destroy(&c)
		if absolute {
			append(&c.data, ..junk[:])
		}
		a, ao := crafted_add(&c, "a.txt", .Deflate, CRAFTED_TEXT)
		b, bo := crafted_add(&c, "b.txt", .Store, CRAFTED_TEXT)
		crafted_central(&c, a, ao)
		crafted_central(&c, b, bo)
		archive := crafted_finish(&c)
		if absolute {
			expect_all_ok(t, archive, {size, size}, "prepended data, absolute offsets")
		} else {
			shifted := make([]u8, len(junk) + len(archive))
			defer delete(shifted)
			copy(shifted[len(junk):], archive)
			expect_all_ok(t, shifted, {size, size}, "prepended data, relative offsets")
		}
	}

	{
		c := Crafted{zip64 = true}
		defer crafted_destroy(&c)
		a, ao := crafted_add(&c, "a.txt", .Deflate, CRAFTED_TEXT)
		b, bo := crafted_add(&c, "b.txt", .Store, CRAFTED_TEXT)
		crafted_central(&c, a, ao)
		crafted_central(&c, b, bo)
		expect_all_ok(t, crafted_finish(&c), {size, size}, "zip64 end records")
	}

	{
		members: Crafted
		defer crafted_destroy(&members)
		a, ao := crafted_add(&members, "a.txt", .Deflate, CRAFTED_TEXT)
		b, bo := crafted_add(&members, "b.txt", .Store, CRAFTED_TEXT)
		central_size := 2 * size_of(Central_Header) + len(a.name) + len(b.name)
		c: Crafted
		defer crafted_destroy(&c)
		crafted_central(&c, a, central_size + ao)
		crafted_central(&c, b, central_size + bo)
		append(&c.data, ..c.central[:])
		append(&c.data, ..members.data[:])
		crafted_end(&c, 0)
		expect_all_ok(t, c.data[:], {size, size}, "central directory in front")
	}
}

@(test)
test_declared_size_binding :: proc(t: ^testing.T) {
	text := "hello, hello, hello, world"
	for method in ([2]zip.Method{.Deflate, .BZip2}) {
		for declared in ([2]int{0, 3}) {
			c: Crafted
			defer crafted_destroy(&c)
			m, mo := crafted_add(&c, "a.txt", method, text, descriptor = true)
			m.size = declared
			m.crc  = hash.crc32(transmute([]u8)text[:declared])
			crafted_central(&c, m, mo)
			results := crafted_results(t, crafted_finish(&c))
			defer delete(results)
			if !testing.expect_value(t, len(results), 1) {
				continue
			}
			res := results[0]
			testing.expectf(t, res.extract == Zip_Error.Size_Mismatch, "%v, declared %d: extract %v", method, declared, res.extract)
			testing.expectf(t, res.written <= i64(declared), "%v, declared %d: wrote %d", method, declared, res.written)
			testing.expectf(t, res.open == nil && res.read != nil, "%v, declared %d: open %v, read %v", method, declared, res.open, res.read)
		}
	}
}

bomb_kernel :: proc(t: ^testing.T) -> (plain, packed: [dynamic]u8) {
	resize(&plain, KERNEL_SIZE)
	mem.set(raw_data(plain), 'a', KERNEL_SIZE)
	testing.expect_value(t, deflate.compress_raw_to_dynamic(&packed, plain[:]), nil)
	return
}

quoted_overlap_bomb :: proc(t: ^testing.T, n: int, zip64: bool) -> (data: [dynamic]u8, verified: bool) {
	plain, packed := bomb_kernel(t)
	defer delete(plain)
	defer delete(packed)

	headers := make([][dynamic]u8, n)
	members := make([]Crafted_Member, n)
	defer {
		for &h in headers {
			delete(h)
		}
		delete(headers)
		delete(members)
	}
	for i := n - 1; i >= 0; i -= 1 {
		if i < n - 1 {
			next  := headers[i + 1][:]
			quote := [5]u8{0, u8(len(next)), u8(len(next) >> 8), ~u8(len(next)), ~u8(len(next) >> 8)}
			inject_at_elems(&packed, 0, ..next)
			inject_at_elems(&packed, 0, ..quote[:])
			inject_at_elems(&plain, 0, ..next)
		}
		members[i] = {name = fmt.tprintf("m%02d", i), method = .Deflate, crc = hash.crc32(plain[:]), packed = len(packed), size = len(plain)}
		crafted_local(&headers[i], members[i])
	}

	out: [dynamic]u8
	inflate_err := deflate.decompress_raw_from_bytes(&out, packed[:])
	verified = inflate_err == nil && len(out) == members[0].size && hash.crc32(out[:]) == members[0].crc
	delete(out)

	c := Crafted{zip64 = zip64}
	append(&c.data, ..headers[0][:])
	append(&c.data, ..packed[:])
	offset := 0
	for i in 0..<n {
		crafted_central(&c, members[i], offset)
		offset += len(headers[i]) + 5
	}
	crafted_finish(&c)
	delete(c.central)
	return c.data, verified
}

extra_field_bomb :: proc(t: ^testing.T, n: int) -> (data: [dynamic]u8) {
	plain, packed := bomb_kernel(t)
	defer delete(plain)
	defer delete(packed)

	members := make([]Crafted_Member, n)
	defer delete(members)
	nested: [dynamic]u8
	defer delete(nested)
	for i := n - 1; i >= 0; i -= 1 {
		members[i] = {name = fmt.tprintf("m%02d", i), method = .Deflate, crc = hash.crc32(plain[:]), packed = len(packed), size = len(plain)}
		header: [dynamic]u8
		crafted_local(&header, members[i], nested[:])
		delete(nested)
		nested = header
	}

	c: Crafted
	append(&c.data, ..nested[:])
	append(&c.data, ..packed[:])
	offset := 0
	for m in members {
		crafted_central(&c, m, offset)
		offset += size_of(Local_Header) + len(m.name)
	}
	crafted_finish(&c)
	delete(c.central)
	return c.data
}

@(test)
test_local_header_mismatch :: proc(t: ^testing.T) {
	for tamper in Local_Tamper {
		c: Crafted
		defer crafted_destroy(&c)
		m, mo := crafted_add(&c, "a.txt", .Deflate, CRAFTED_TEXT)
		h := c.data[mo:]
		switch tamper {
		case .None:
		case .Blank:
			endian.unchecked_put_u32le(h[offset_of(Local_Header, crc32):], 0)
			endian.unchecked_put_u32le(h[offset_of(Local_Header, compressed_size):], 0)
			endian.unchecked_put_u32le(h[offset_of(Local_Header, uncompressed_size):], 0)
		case .Zip64_Sizes:
			endian.unchecked_put_u32le(h[offset_of(Local_Header, compressed_size):], 0xFFFF_FFFF)
			endian.unchecked_put_u32le(h[offset_of(Local_Header, uncompressed_size):], 0xFFFF_FFFF)
		case .Name:
			h[size_of(Local_Header)] = 'b'
		case .Name_Length:
			m.name = "a.txt2"
		case .Method:
			endian.unchecked_put_u16le(h[offset_of(Local_Header, method):], u16(zip.Method.Store))
		case .Encrypted:
			h[offset_of(Local_Header, flags)] |= 1
		case .CRC:
			endian.unchecked_put_u32le(h[offset_of(Local_Header, crc32):], m.crc ~ 1)
		case .Compressed_Size:
			endian.unchecked_put_u32le(h[offset_of(Local_Header, compressed_size):], u32(m.packed + 1))
		case .Size:
			endian.unchecked_put_u32le(h[offset_of(Local_Header, uncompressed_size):], u32(m.size - 1))
		}
		crafted_central(&c, m, mo)
		results := crafted_results(t, crafted_finish(&c))
		defer delete(results)
		if !testing.expectf(t, len(results) == 1, "%v: %d members listed", tamper, len(results)) {
			continue
		}
		res := results[0]
		switch tamper {
		case .None, .Blank, .Zip64_Sizes:
			expect_member_ok(t, res, len(CRAFTED_TEXT), fmt.tprint(tamper))
		case .Name, .Name_Length, .Method, .Encrypted, .CRC, .Compressed_Size, .Size:
			testing.expectf(t, res.extract == Zip_Error.Local_Header_Mismatch && res.written == 0, "%v: extract %v, wrote %d", tamper, res.extract, res.written)
			testing.expectf(t, res.open == Zip_Error.Local_Header_Mismatch, "%v: open %v", tamper, res.open)
		}
	}
}

@(test)
test_extract_limits :: proc(t: ^testing.T) {
	zeros := make([]u8, 64 * 1024)
	defer delete(zeros)
	text := transmute([]u8)string(CRAFTED_TEXT)

	m := Memory_File{seekable = true}
	defer delete(m.data)
	zw: zip.Writer
	if !testing.expect_value(t, zip.create(&zw, memory_stream(&m)), nil) {
		return
	}
	testing.expect_value(t, zip.write_entry(&zw, "zeros", zeros), nil)
	testing.expect_value(t, zip.write_entry(&zw, "text", text), nil)
	testing.expect_value(t, zip.write_entry(&zw, "stored", text, {method = .Store}), nil)
	testing.expect_value(t, zip.commit(&zw), nil)
	zip.close(&zw)
	data := m.data[:]

	zeros_ratio := 0
	a, err := archive.open(data)
	if !testing.expect_value(t, err, nil) {
		return
	}
	it := archive.iterator_create(&a)
	for fi in archive.iterate(&it) {
		if fi.path == "zeros" {
			zeros_ratio = int((fi.size + fi.compressed_size - 1) / fi.compressed_size)
		}
	}
	archive.iterator_destroy(&it)
	archive.close(&a)
	if !testing.expectf(t, zeros_ratio > 10, "zeros ratio %d", zeros_ratio) {
		return
	}

	LIMIT :: archive.General_Error.Limit_Exceeded
	total := i64(len(zeros) + 2 * len(text))
	expect_limits(t, data, {}, {nil, nil, nil}, "no limits")
	expect_limits(t, data, {max_ratio = zeros_ratio}, {nil, nil, nil}, "ratio at zeros")
	expect_limits(t, data, {max_ratio = zeros_ratio - 1}, {LIMIT, nil, nil}, "ratio below zeros")
	expect_limits(t, data, {max_total_size = total}, {nil, nil, nil}, "total exact")
	expect_limits(t, data, {max_total_size = total - 1}, {nil, nil, LIMIT}, "total one short")
	expect_limits(t, data, {max_total_size = i64(len(zeros) - 1)}, {LIMIT, nil, nil}, "refused members don't count")
	ratio_one := limit_results(t, data, {max_ratio = 1})
	testing.expectf(t, ratio_one[0] == LIMIT && ratio_one[2] == nil, "ratio 1: %v", ratio_one)

	base, base_err := os.make_directory_temp("", "odin_zip_limits_*", context.temp_allocator)
	if base_err == .Unsupported {
		return
	}
	if !testing.expect_value(t, base_err, nil) {
		return
	}
	defer os.remove_all(base)
	out, _ := os.join_path({base, "out"}, context.temp_allocator)
	b, open_err := archive.open(data)
	if testing.expect_value(t, open_err, nil) {
		testing.expect_value(t, archive.extract_all(&b, out, {max_total_size = total - 1}), LIMIT)
		archive.close(&b)
		for name in ([?]string{"zeros", "text", "stored"}) {
			path, _ := os.join_path({out, name}, context.temp_allocator)
			testing.expectf(t, os.exists(path) == (name != "stored"), "%s exists: %v", name, os.exists(path))
		}
	}

	for cap in ([2]int{len(text) - 1, len(text)}) {
		r: zip.Reader
		if !testing.expect_value(t, zip.open(&r, data, compress.Options{max_output_size = cap}), nil) {
			continue
		}
		want: zip.Error = compress.Error(compress.General_Error.Output_Too_Short) if cap < len(text) else nil
		zit := zip.iterator_create(&r)
		for fi in zip.iterate(&zit) {
			if fi.path == "zeros" {
				continue
			}
			d: Discard
			got := zip.extract_current(&zit, discard_writer(&d))
			testing.expectf(t, got == want, "%s, cap %d: extract %v, want %v", fi.path, cap, got, want)
			_, open_got := zip.open_current(&zit)
			testing.expectf(t, open_got == want, "%s, cap %d: open %v, want %v", fi.path, cap, open_got, want)
		}
		zip.iterator_destroy(&zit)
		zip.close(&r)
	}
}

@(test)
test_link_target_cap :: proc(t: ^testing.T) {
	limit := strings.repeat("t", archive.LINK_TARGET_MAX, context.temp_allocator)
	over  := strings.repeat("t", archive.LINK_TARGET_MAX + 1, context.temp_allocator)

	m := Memory_File{seekable = true}
	defer delete(m.data)
	zw: zip.Writer
	if !testing.expect_value(t, zip.create(&zw, memory_stream(&m)), nil) {
		return
	}
	testing.expect_value(t, zip.write_entry(&zw, archive.File_Info{path = "limit", type = .Symlink, link_target = limit}), nil)
	testing.expect_value(t, zip.write_entry(&zw, archive.File_Info{path = "over", type = .Symlink, link_target = over}), archive.General_Error.Limit_Exceeded)
	testing.expect_value(t, zip.write_entry(&zw, "after.txt", transmute([]u8)string(CRAFTED_TEXT)), nil)
	testing.expect_value(t, zip.commit(&zw), nil)
	zip.close(&zw)

	r: zip.Reader
	if testing.expect_value(t, zip.open(&r, m.data[:]), nil) {
		it := zip.iterator_create(&r)
		names: [2]string
		seen := 0
		for fi in zip.iterate(&it) {
			if seen < len(names) {
				names[seen] = fi.path
			}
			seen += 1
			if fi.type == .Symlink {
				target, err := zip.read_link(&it)
				testing.expect_value(t, err, nil)
				testing.expect_value(t, target, limit)
				delete(target)
			}
		}
		zip.iterator_destroy(&it)
		zip.close(&r)
		testing.expect_value(t, seen, 2)
		testing.expect_value(t, names, [2]string{"limit", "after.txt"})
	}

	c: Crafted
	defer crafted_destroy(&c)
	member, local := crafted_add(&c, "over", .Store, over)
	at := len(c.central)
	crafted_central(&c, member, local)
	c.central[at + int(offset_of(Central_Header, made_by_host))] = u8(zip.Host.Unix)
	endian.unchecked_put_u32le(c.central[at + int(offset_of(Central_Header, external_attributes)):], u32(archive.UNIX_SYMLINK | 0o777) << 16)
	data := crafted_finish(&c)

	crafted: zip.Reader
	if testing.expect_value(t, zip.open(&crafted, data), nil) {
		it := zip.iterator_create(&crafted)
		seen := 0
		for fi in zip.iterate(&it) {
			seen += 1
			testing.expect_value(t, fi.type, archive.Entry_Type.Symlink)
			target, err := zip.read_link(&it)
			testing.expect_value(t, err, archive.General_Error.Limit_Exceeded)
			testing.expect_value(t, target, "")
		}
		zip.iterator_destroy(&it)
		zip.close(&crafted)
		testing.expect_value(t, seen, 1)
	}
}

@(test)
test_legacy_bomb_memory :: proc(t: ^testing.T) {
	when SLIM_TESTS {
		return
	}
	Bomb :: struct {
		method: zip.Method,
		units:  [2]int,
	}
	bombs := [?]Bomb{
		{.Shrink,   {1_250, 5_650}},
		{.Reduce_1, {2_000, 40_000}},
		{.Implode,  {2_500, 50_000}},
	}
	for b in bombs {
		peaks: [2][2]i64
		sizes: [2]int
		for units, i in b.units {
			packed, size := legacy_bomb(b.method, units)
			defer delete(packed)
			sizes[i] = size
			crc := legacy_bomb_crc(size)

			c: Crafted
			defer crafted_destroy(&c)
			m := Crafted_Member{name = "bomb", method = b.method, crc = crc, packed = len(packed), size = size}
			local := crafted_local(&c.data, m)
			append(&c.data, ..packed[:])
			crafted_central(&c, m, local)
			data := crafted_finish(&c)

			for mode in 0..<2 {
				track: mem.Tracking_Allocator
				mem.tracking_allocator_init(&track, context.allocator)
				defer mem.tracking_allocator_destroy(&track)
				r: zip.Reader
				if !testing.expect_value(t, zip.open(&r, data, {}, mem.tracking_allocator(&track)), nil) {
					continue
				}
				_, handle, ok, _ := zip.find(&r, "bomb")
				testing.expectf(t, ok, "%v: find bomb", b.method)
				if mode == 0 {
					d: Discard
					testing.expect_value(t, zip.extract(&r, handle, discard_writer(&d)), nil)
					testing.expectf(t, d.count == i64(size), "%v extract: %d bytes, want %d", b.method, d.count, size)
				} else {
					rd, open_err := zip.open_member(&r, handle, {}, mem.tracking_allocator(&track))
					if testing.expect_value(t, open_err, nil) {
						chunk: [4096]u8
						got: int
						got_crc: u32
						for {
							n, read_err := io.read(rd, chunk[:])
							got_crc = hash.crc32(chunk[:n], got_crc)
							got += n
							if read_err == .EOF {
								break
							}
							if !testing.expectf(t, read_err == nil, "%v read: %v", b.method, read_err) {
								break
							}
						}
						testing.expectf(t, got == size && got_crc == crc, "%v read: %d bytes, want %d, CRC %08x, want %08x", b.method, got, size, got_crc, crc)
						zip.close_member(rd)
					}
				}
				zip.close(&r)
				testing.expectf(t, len(track.allocation_map) == 0, "%v, mode %d, size %d: %d allocations left", b.method, mode, size, len(track.allocation_map))
				peaks[mode][i] = track.peak_memory_allocated
			}
		}
		for p, mode in peaks {
			testing.expectf(t, p[1] == p[0] && p[1] <= 256 * 1024, "%v, mode %d: peaks %v for sizes %v", b.method, mode, p, sizes)
		}
	}
}

@(test)
test_member_tail :: proc(t: ^testing.T) {
	text := write_text()
	for method in WRITE_METHODS {
		m := Memory_File{seekable = true}
		defer delete(m.data)
		zw: zip.Writer
		if !testing.expect_value(t, zip.create(&zw, memory_stream(&m)), nil) {
			continue
		}
		testing.expect_value(t, zip.write_entry(&zw, "a.txt", text, {method = method}), nil)
		testing.expect_value(t, zip.commit(&zw), nil)
		zip.close(&zw)
		raw := raw_members(m.data[:])
		defer delete(raw)
		if !testing.expectf(t, len(raw) == 1 && raw[0].local_flags & 8 == 0, "%v: one member with its sizes up front", method) {
			continue
		}
		expect_member_tail(t, fmt.tprint(method), m.data[:], raw[0].data + int(raw[0].compressed), len(text), hash.crc32(text), method != .XZ)
	}

	for method in ([?]zip.Method{.Shrink, .Reduce_1, .Implode}) {
		packed, size := legacy_bomb(method, 40)
		defer delete(packed)
		c: Crafted
		defer crafted_destroy(&c)
		m := Crafted_Member{name = "a.txt", method = method, crc = legacy_bomb_crc(size), packed = len(packed), size = size}
		local := crafted_local(&c.data, m)
		append(&c.data, ..packed[:])
		end := len(c.data)
		crafted_central(&c, m, local)
		expect_member_tail(t, fmt.tprint(method), crafted_finish(&c), end, size, m.crc, true)
	}
}

expect_member_tail :: proc(t: ^testing.T, name: string, base: []u8, end, size: int, crc: u32, mismatch: bool) {
	for tail in ([?]int{0, 1, 5}) {
		data: [dynamic]u8
		defer delete(data)
		append(&data, ..base[:end])
		for _ in 0..<tail {
			append(&data, 0x5A)
		}
		append(&data, ..base[end:])
		eocd       := len(data) - 22
		central    := int(get_u32(data[:], eocd + 16)) + tail
		compressed := get_u32(data[:], 18) + u32(tail)
		endian.unchecked_put_u32le(data[18:], compressed)
		endian.unchecked_put_u32le(data[central + 20:], compressed)
		endian.unchecked_put_u32le(data[eocd + 16:], u32(central))

		for store in Stream_Store {
			label := fmt.tprintf("%s/%v/tail %d", name, store, tail)
			r: zip.Reader
			rs := Recording_Stream{data = data[:]}
			defer delete(rs.reads)
			if !testing.expectf(t, stream_open(&r, store, data[:], &rs, {}) == nil, "%s: open", label) {
				continue
			}
			defer zip.close(&r)
			_, handle, _, _ := zip.find(&r, "a.txt")
			b := strings.builder_make()
			extract_err := zip.extract(&r, handle, strings.to_writer(&b))
			extracted   := len(b.buf) == size && hash.crc32(b.buf[:]) == crc
			strings.builder_destroy(&b)

			read_err: io.Error = .Unknown
			read_ok := false
			if member, open_err := zip.open_member(&r, handle); open_err == nil {
				got: [dynamic]u8
				got, read_err = stream_read_all(member, 4093)
				read_ok = len(got) == size && hash.crc32(got[:]) == crc
				delete(got)
				zip.close_member(member)
			}

			switch {
			case tail == 0:
				testing.expectf(t, extract_err == nil && extracted, "%s: extract %v", label, extract_err)
				testing.expectf(t, read_err == nil && read_ok, "%s: read %v", label, read_err)
			case mismatch:
				testing.expectf(t, extract_err == Zip_Error.Size_Mismatch, "%s: extract %v", label, extract_err)
				testing.expectf(t, read_err != nil, "%s: read %v", label, read_err)
			case:
				testing.expectf(t, extract_err != nil && read_err != nil, "%s: extract %v, read %v", label, extract_err, read_err)
			}
		}
	}
}

limit_results :: proc(t: ^testing.T, data: []u8, options: archive.Extract_Options, loc := #caller_location) -> (errs: [3]archive.Error) {
	a, err := archive.open(data)
	if !testing.expect_value(t, err, nil, loc) {
		return
	}
	defer archive.close(&a)
	d: Discard
	buf: [dynamic]u8
	defer delete(buf)
	targets := []archive.Target{
		{path = "zeros", to = discard_writer(&d)},
		{path = "text", to = &buf},
		{path = "stored", to = discard_writer(&d)},
	}
	it := archive.extract_iterator_create(&a, targets, options)
	defer archive.extract_iterator_destroy(&it)
	for _, i in archive.extract_iterate(&it) {
		_, errs[i] = archive.extract_iterator_error(&it)
	}
	return
}

expect_limits :: proc(t: ^testing.T, data: []u8, options: archive.Extract_Options, want: [3]archive.Error, label: string, loc := #caller_location) {
	got := limit_results(t, data, options, loc)
	for name, i in ([3]string{"zeros", "text", "stored"}) {
		testing.expectf(t, got[i] == want[i], "%s: %s: %v, want %v", label, name, got[i], want[i], loc = loc)
	}
}

crafted_destroy :: proc(c: ^Crafted) {
	delete(c.data)
	delete(c.central)
}

crafted_local :: proc(buf: ^[dynamic]u8, m: Crafted_Member, extra: []u8 = nil) -> (offset: int) {
	offset = len(buf)
	h := Local_Header{
		signature         = .Local,
		version_needed    = 20,
		flags             = m.flags,
		method            = m.method,
		crc32             = u32le(m.crc),
		compressed_size   = u32le(m.packed),
		uncompressed_size = u32le(m.size),
		name_length       = u16le(len(m.name)),
		extra_length      = u16le(len(extra)),
	}
	append(buf, ..mem.ptr_to_bytes(&h))
	append(buf, m.name)
	append(buf, ..extra)
	return
}

crafted_add :: proc(c: ^Crafted, name: string, method: zip.Method, plain: string, local_extra: []u8 = nil, descriptor := false) -> (m: Crafted_Member, offset: int) {
	input := transmute([]u8)plain
	packed: [dynamic]u8
	defer delete(packed)
	if method == .Deflate {
		deflate.compress_raw_to_dynamic(&packed, input)
	} else if method == .BZip2 {
		bzip2.compress_to_dynamic(&packed, input)
	} else {
		append(&packed, ..input)
	}
	m = {name = name, method = method, crc = hash.crc32(input), packed = len(packed), size = len(input)}
	local := m
	if descriptor {
		m.flags += {.Data_Descriptor}
		local = {name = name, method = method, flags = m.flags}
	}
	offset = crafted_local(&c.data, local, local_extra)
	append(&c.data, ..packed[:])
	if descriptor {
		d: [16]u8
		endian.unchecked_put_u32le(d[0:], 0x08074b50)
		endian.unchecked_put_u32le(d[4:], m.crc)
		endian.unchecked_put_u32le(d[8:], u32(m.packed))
		endian.unchecked_put_u32le(d[12:], u32(m.size))
		append(&c.data, ..d[:])
	}
	return
}

crafted_central :: proc(c: ^Crafted, m: Crafted_Member, local: int, comment: []u8 = nil) {
	extra: [12]u8
	extra_length := 0
	offset := u32le(local)
	if c.zip64 {
		offset = 0xFFFF_FFFF
		extra[0], extra[2] = 0x01, 0x08
		endian.unchecked_put_u64le(extra[4:], u64(local))
		extra_length = len(extra)
	}
	h := Central_Header{
		signature           = .Central,
		made_by_version     = 20,
		version_needed      = 20,
		flags               = m.flags,
		method              = m.method,
		crc32               = u32le(m.crc),
		compressed_size     = u32le(m.packed),
		uncompressed_size   = u32le(m.size),
		name_length         = u16le(len(m.name)),
		extra_length        = u16le(extra_length),
		comment_length      = u16le(len(comment)),
		local_header_offset = offset,
	}
	append(&c.central, ..mem.ptr_to_bytes(&h))
	append(&c.central, m.name)
	append(&c.central, ..extra[:extra_length])
	append(&c.central, ..comment)
	c.count += 1
}

crafted_end :: proc(c: ^Crafted, central_offset: int, comment: []u8 = nil) {
	offset := u32le(central_offset)
	if c.zip64 {
		record_offset := len(c.data)
		record := Zip64_End_Record{
			signature         = .Zip64_End,
			record_size       = u64le(size_of(Zip64_End_Record) - 12),
			made_by_version   = 45,
			version_needed    = 45,
			entries_this_disk = u64le(c.count),
			entries_total     = u64le(c.count),
			central_size      = u64le(len(c.central)),
			central_offset    = u64le(central_offset),
		}
		append(&c.data, ..mem.ptr_to_bytes(&record))
		locator := Zip64_Locator{signature = .Zip64_Locator, end_offset = u64le(record_offset), total_disks = 1}
		append(&c.data, ..mem.ptr_to_bytes(&locator))
		offset = 0xFFFF_FFFF
	}
	end := End_Record{
		signature         = .End,
		entries_this_disk = u16le(c.count),
		entries_total     = u16le(c.count),
		central_size      = u32le(len(c.central)),
		central_offset    = offset,
		comment_length    = u16le(len(comment)),
	}
	append(&c.data, ..mem.ptr_to_bytes(&end))
	append(&c.data, ..comment)
}

crafted_finish :: proc(c: ^Crafted, comment: []u8 = nil) -> []u8 {
	central_offset := len(c.data)
	append(&c.data, ..c.central[:])
	crafted_end(c, central_offset, comment)
	return c.data[:]
}

crafted_results :: proc(t: ^testing.T, data: []u8, loc := #caller_location) -> (results: [dynamic]Member_Result) {
	r: zip.Reader
	if !testing.expect_value(t, zip.open(&r, data), nil, loc) {
		return
	}
	defer zip.close(&r)
	it := zip.iterator_create(&r)
	defer zip.iterator_destroy(&it)
	for _ in zip.iterate(&it) {
		res: Member_Result
		d: Discard
		res.extract = zip.extract_current(&it, discard_writer(&d))
		res.written = d.count
		rd, open_err := zip.open_current(&it)
		res.open = open_err
		if open_err == nil {
			chunk: [512]u8
			for {
				_, read_err := io.read(rd, chunk[:])
				if read_err == .EOF {
					break
				}
				if read_err != nil {
					res.read = read_err
					break
				}
			}
		}
		append(&results, res)
	}
	_, it_err := zip.iterator_error(&it)
	testing.expect_value(t, it_err, nil, loc)
	return
}

expect_member_ok :: proc(t: ^testing.T, res: Member_Result, size: int, label: string, loc := #caller_location) {
	testing.expectf(t, res.extract == nil && res.written == i64(size), "%s: extract %v, wrote %d of %d", label, res.extract, res.written, size, loc = loc)
	testing.expectf(t, res.open == nil && res.read == nil, "%s: open %v, read %v", label, res.open, res.read, loc = loc)
}

expect_all_ok :: proc(t: ^testing.T, data: []u8, sizes: []int, label: string, loc := #caller_location) {
	results := crafted_results(t, data, loc)
	defer delete(results)
	if !testing.expectf(t, len(results) == len(sizes), "%s: %d members, want %d", label, len(results), len(sizes), loc = loc) {
		return
	}
	for res, i in results {
		expect_member_ok(t, res, sizes[i], fmt.tprintf("%s, member %d", label, i), loc)
	}
}

legacy_bomb :: proc(method: zip.Method, units: int) -> (packed: [dynamic]u8, size: int) {
	w: Legacy_Bits
	#partial switch method {
	case .Shrink:
		code_size := uint(pkzip_legacy.SHRINK_MIN_CODE_SIZE)
		legacy_put_bits(&w, 'a', code_size)
		size = 1
		for next in pkzip_legacy.SHRINK_FIRST_FREE_CODE ..< pkzip_legacy.SHRINK_FIRST_FREE_CODE + units {
			if next == 1 << code_size {
				legacy_put_bits(&w, pkzip_legacy.SHRINK_CONTROL_CODE, code_size)
				legacy_put_bits(&w, pkzip_legacy.SHRINK_INCREASE_CODE_SIZE, code_size)
				code_size += 1
			}
			legacy_put_bits(&w, next, code_size)
			size += next - 255
		}
	case .Reduce_1:
		for _ in 0..<256 {
			legacy_put_bits(&w, 0, 6)
		}
		legacy_put_bits(&w, 'a', 8)
		size = 1
		for _ in 0..<units {
			for v in ([4]int{pkzip_legacy.REDUCE_DLE, 0x7f, 0xff, 0x00}) {
				legacy_put_bits(&w, v, 8)
			}
			size += 127 + 255 + 3
		}
	case .Implode:
		for _ in 0..<2 {
			legacy_put_bits(&w, 3, 8)
			for _ in 0..<4 {
				legacy_put_bits(&w, 0xf5, 8)
			}
		}
		legacy_put_bits(&w, 1, 1)
		legacy_put_bits(&w, 'a', 8)
		size = 1
		for _ in 0..<units {
			legacy_put_bits(&w, 0, 1)
			legacy_put_bits(&w, 0, 6)
			legacy_put_bits(&w, 0x3f, 6)
			legacy_put_bits(&w, 0, 6)
			legacy_put_bits(&w, 255, 8)
			size += 63 + 255 + 2
		}
	}
	if w.count > 0 {
		append(&w.buffer, u8(w.bits))
	}
	return w.buffer, size
}

legacy_put_bits :: proc(w: ^Legacy_Bits, value: int, bits: uint) {
	w.bits  |= u64(value) << w.count
	w.count += bits
	for w.count >= 8 {
		append(&w.buffer, u8(w.bits))
		w.bits  >>= 8
		w.count  -= 8
	}
}

legacy_bomb_crc :: proc(size: int) -> (crc: u32) {
	chunk: [4096]u8
	for &b in chunk {
		b = 'a'
	}
	for left := size; left > 0; left -= len(chunk) {
		crc = hash.crc32(chunk[:min(left, len(chunk))], crc)
	}
	return
}
