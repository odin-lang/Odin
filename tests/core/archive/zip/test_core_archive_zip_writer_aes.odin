package test_core_archive_zip

import "core:archive"
import "core:archive/zip"
import "core:bytes"
import "core:crypto/pbkdf2"
import "core:fmt"
import "core:mem"
import "core:strings"
import "core:testing"

AES_PASSWORD   :: "Ostrich-Sesame-42"
AES_OTHER      :: "Pelican-Quartz-77"
AES_PLAIN_TEXT :: "This member is written without a password, next to encrypted ones.\n"

Aes_Expect :: struct {
	name:     string,
	type:     archive.Entry_Type,
	content:  []u8,
	method:   archive.Method,
	password: string,
}

Raw_Member :: struct {
	name:            string,
	central_version: u16,
	central_flags:   u16,
	central_method:  u16,
	central_crc:     u32,
	local_version:   u16,
	local_flags:     u16,
	local_method:    u16,
	local_crc:       u32,
	compressed:      u32,
	size:            u32,
	central_aes:     []u8,
	local_aes:       []u8,
	data:            int,
}

Secret_Scan :: struct {
	backing: mem.Allocator,
	sizes:   map[rawptr]int,
	needles: [8][]u8,
	count:   int,
	hits:    int,
}

@(test)
test_write_aes :: proc(t: ^testing.T) {
	text       := write_text()
	plain      := transmute([]u8)strings.repeat(AES_PLAIN_TEXT, 16, context.temp_allocator)
	big_text   := transmute([]u8)strings.repeat(WRITE_TEXT, int(zip.ONE_SHOT_MAX) / len(WRITE_TEXT) + 64, context.temp_allocator)
	random     := write_random(40_000, 7)
	big_random := write_random(int(zip.ONE_SHOT_MAX) + 50_000, 8)
	defer {
		delete(random)
		delete(big_random)
	}
	for method in WRITE_METHODS {
		for mode in Output_Mode {
			label    := fmt.tprintf("%v/%v", method, mode)
			seekable := mode == .Seekable
			one_shot := method == .XZ
			m := Memory_File{seekable = seekable}
			defer delete(m.data)
			zw: zip.Writer
			if !testing.expectf(t, zip.create(&zw, memory_stream(&m), zip.Writer_Options{method = method, password = AES_PASSWORD}) == nil, "%s: create", label) {
				continue
			}
			inner: bytes.Reader
			bytes.reader_init(&inner, text)
			unknown := Non_Seekable{inner = bytes.reader_to_stream(&inner)}
			testing.expectf(t, zip.write_entry(&zw, "empty.txt") == nil, "%s: empty.txt", label)
			testing.expectf(t, zip.write_entry(&zw, "text.txt", text) == nil, "%s: text.txt", label)
			testing.expectf(t, zip.write_entry(&zw, "random.bin", random) == nil, "%s: random.bin", label)
			testing.expectf(t, zip.write_entry(&zw, "big.txt", big_text) == nil, "%s: big.txt", label)
			testing.expectf(t, zip.write_entry(&zw, "big.bin", big_random) == nil, "%s: big.bin", label)
			testing.expectf(t, zip.write_entry(&zw, archive.File_Info{path = "unknown.txt", size = -1}, non_seekable_stream(&unknown)) == nil, "%s: unknown.txt", label)
			testing.expectf(t, zip.write_entry(&zw, archive.File_Info{path = "dir", type = .Directory}) == nil, "%s: dir", label)
			testing.expectf(t, zip.write_entry(&zw, archive.File_Info{path = "dir/link", type = .Symlink, link_target = "../text.txt"}) == nil, "%s: link", label)
			testing.expectf(t, zip.write_entry(&zw, "plain.txt", plain, {password = ""}) == nil, "%s: plain.txt", label)
			testing.expectf(t, zip.write_entry(&zw, "other.txt", text, {password = AES_OTHER}) == nil, "%s: other.txt", label)
			testing.expectf(t, zip.commit(&zw) == nil, "%s: commit", label)
			zip.close(&zw)

			big_kept := method if !seekable && !one_shot else archive.Method.Store
			check_aes(t, label, m.data[:], {
				{name = "empty.txt",   method = .Store,   password = AES_PASSWORD},
				{name = "text.txt",    method = method,   password = AES_PASSWORD, content = text},
				{name = "random.bin",  method = .Store,   password = AES_PASSWORD, content = random},
				{name = "big.txt",     method = method,   password = AES_PASSWORD, content = big_text},
				{name = "big.bin",     method = big_kept, password = AES_PASSWORD, content = big_random},
				{name = "unknown.txt", method = method,   password = AES_PASSWORD, content = text},
				{name = "dir/",        method = .Store,   type = .Directory},
				{name = "dir/link",    method = .Store,   password = AES_PASSWORD, content = transmute([]u8)string("../text.txt"), type = .Symlink},
				{name = "plain.txt",   method = method,   content = plain},
				{name = "other.txt",   method = method,   password = AES_OTHER, content = text},
			})
			testing.expectf(t, bytes.index(m.data[:], text[:64]) < 0, "%s: text.txt in the clear", label)
			testing.expectf(t, bytes.index(m.data[:], random[:64]) < 0, "%s: random.bin in the clear", label)
			testing.expectf(t, bytes.index(m.data[:], big_random[:64]) < 0, "%s: big.bin in the clear", label)
		}
	}
}

@(test)
test_write_aes_options :: proc(t: ^testing.T) {
	text := write_text()
	incompatible := archive.Error(archive.General_Error.Incompatible_Options)
	{
		m := Memory_File{seekable = true}
		defer delete(m.data)
		zw: zip.Writer
		err := zip.create(&zw, memory_stream(&m), zip.Writer_Options{password = AES_PASSWORD, deterministic = true})
		testing.expect_value(t, err, incompatible)
		if err == nil {
			zip.close(&zw)
		}
	}
	{
		m := Memory_File{seekable = true}
		defer delete(m.data)
		zw: zip.Writer
		if !testing.expect_value(t, zip.create(&zw, memory_stream(&m), zip.Writer_Options{deterministic = true}), nil) {
			return
		}
		testing.expect_value(t, zip.write_entry(&zw, "locked.txt", text, {password = AES_PASSWORD}), incompatible)
		testing.expect_value(t, zip.write_directory(&zw, ".", options = {password = AES_PASSWORD}), incompatible)
		testing.expect_value(t, zip.write_entry(&zw, "open.txt", text, {password = ""}), nil)
		testing.expect_value(t, zip.write_entry(&zw, "default.txt", text), nil)
		testing.expect_value(t, zip.commit(&zw), nil)
		zip.close(&zw)
		check_aes(t, "deterministic", m.data[:], {
			{name = "open.txt",    method = .Deflate, content = text},
			{name = "default.txt", method = .Deflate, content = text},
		})
	}
	{
		m := Memory_File{seekable = false}
		defer delete(m.data)
		zw: zip.Writer
		if !testing.expect_value(t, zip.create(&zw, memory_stream(&m)), nil) {
			return
		}
		testing.expect_value(t, zip.write_entry(&zw, "a.txt", text), nil)
		testing.expect_value(t, zip.write_entry(&zw, "b.txt", text, {method = .Store, password = AES_OTHER}), nil)
		testing.expect_value(t, zip.write_entry(&zw, "c.txt", text, {password = ""}), nil)
		testing.expect_value(t, zip.commit(&zw), nil)
		zip.close(&zw)
		check_aes(t, "entry password", m.data[:], {
			{name = "a.txt", method = .Deflate, content = text},
			{name = "b.txt", method = .Store,   content = text, password = AES_OTHER},
			{name = "c.txt", method = .Deflate, content = text},
		})
	}
}

@(test)
test_write_aes_tamper :: proc(t: ^testing.T) {
	text := write_text()
	m := Memory_File{seekable = true}
	defer delete(m.data)
	zw: zip.Writer
	if !testing.expect_value(t, zip.create(&zw, memory_stream(&m), zip.Writer_Options{password = AES_PASSWORD}), nil) {
		return
	}
	testing.expect_value(t, zip.write_entry(&zw, "deflate.txt", text), nil)
	testing.expect_value(t, zip.write_entry(&zw, "store.txt", text, {method = .Store}), nil)
	testing.expect_value(t, zip.commit(&zw), nil)
	zip.close(&zw)

	raw := raw_members(m.data[:])
	defer delete(raw)
	if !testing.expectf(t, len(raw) == 2, "%d members", len(raw)) {
		return
	}
	for member in raw {
		start := member.data + zip.AES_SALT_SIZE + 2
		end   := member.data + int(member.compressed)
		for at in ([?]int{start, start + 7, end - 11, end - 10, end - 1}) {
			tampered := bytes.clone(m.data[:])
			defer delete(tampered)
			tampered[at] ~= 0x20
			r: zip.Reader
			if !testing.expect_value(t, zip.open(&r, tampered), nil) {
				continue
			}
			defer zip.close(&r)
			it := zip.iterator_create(&r)
			defer zip.iterator_destroy(&it)
			for fi in zip.iterate(&it) {
				if fi.path != member.name {
					continue
				}
				content, err := extract_to_bytes(&it, {password = AES_PASSWORD})
				delete(content)
				testing.expectf(t, err == archive.General_Error.Authentication_Failed, "%s: byte %d flipped: %v", member.name, at - member.data, err)
			}
		}
	}
}

@(test)
test_write_aes_secrets_freed :: proc(t: ^testing.T) {
	text := write_text()
	big  := write_random(int(zip.ONE_SHOT_MAX) + 10_000, 9)
	defer delete(big)
	scan := Secret_Scan{backing = context.allocator}
	scan.sizes.allocator = context.allocator
	defer delete(scan.sizes)
	scan_add(&scan, transmute([]u8)string(AES_PASSWORD))
	scan_add(&scan, transmute([]u8)string(AES_OTHER))

	m := Memory_File{seekable = true}
	defer delete(m.data)
	{
		context.allocator = secret_scan_allocator(&scan)
		zw: zip.Writer
		if testing.expect_value(t, zip.create(&zw, memory_stream(&m), zip.Writer_Options{password = AES_PASSWORD}), nil) {
			testing.expect_value(t, zip.write_entry(&zw, "a.txt", text), nil)
			testing.expect_value(t, zip.write_entry(&zw, "b.bin", big, {password = AES_OTHER}), nil)
			testing.expect_value(t, zip.commit(&zw), nil)
			zip.close(&zw)
		}
	}
	testing.expectf(t, scan.hits == 0, "writer freed %d blocks holding a password", scan.hits)

	raw := raw_members(m.data[:])
	defer delete(raw)
	if !testing.expectf(t, len(raw) == 2, "%d members", len(raw)) {
		return
	}
	keys: [2][2 * 32 + 2]u8
	pbkdf2.derive(.Insecure_SHA1, transmute([]u8)string(AES_PASSWORD), m.data[raw[0].data:][:zip.AES_SALT_SIZE], 1000, keys[0][:])
	pbkdf2.derive(.Insecure_SHA1, transmute([]u8)string(AES_OTHER), m.data[raw[1].data:][:zip.AES_SALT_SIZE], 1000, keys[1][:])
	for &key in keys {
		scan_add(&scan, key[:32])
		scan_add(&scan, key[32:64])
	}

	{
		context.allocator = secret_scan_allocator(&scan)
		r: zip.Reader
		if testing.expect_value(t, zip.open(&r, m.data[:]), nil) {
			it := zip.iterator_create(&r)
			for fi in zip.iterate(&it) {
				password := AES_OTHER if fi.path == "b.bin" else AES_PASSWORD
				want     := big if fi.path == "b.bin" else text
				content, err := extract_to_bytes(&it, {password = password})
				testing.expectf(t, err == nil && bytes.equal(content[:], want), "%s: extract %v", fi.path, err)
				delete(content)
				_, handle, found, _ := zip.find(&r, fi.path)
				testing.expectf(t, found, "%s: find", fi.path)
				member, open_err := zip.open_member(&r, handle, {password = password})
				if testing.expectf(t, open_err == nil, "%s: open_member %v", fi.path, open_err) {
					streamed, read_err := read_stream(member)
					testing.expectf(t, read_err == nil && bytes.equal(streamed[:], want), "%s: stream %v", fi.path, read_err)
					delete(streamed)
					zip.close_member(member)
				}
			}
			zip.iterator_destroy(&it)
			zip.close(&r)
		}
	}
	testing.expectf(t, scan.hits == 0, "reader freed %d blocks holding a password or key", scan.hits)
}

check_aes :: proc(t: ^testing.T, label: string, data: []u8, expected: []Aes_Expect) {
	r: zip.Reader
	if !testing.expectf(t, zip.open(&r, data) == nil, "%s: open", label) {
		return
	}
	defer zip.close(&r)
	it := zip.iterator_create(&r)
	defer zip.iterator_destroy(&it)
	count := 0
	for fi, index in zip.iterate(&it) {
		count += 1
		if !testing.expectf(t, index < len(expected), "%s: extra member %s", label, fi.path) {
			continue
		}
		want      := expected[index]
		name      := fmt.tprintf("%s/%s", label, want.name)
		want_type := want.type if want.type != .Unknown else archive.Entry_Type.Regular
		testing.expectf(t, archive.clean_member_path(fi.path) == archive.clean_member_path(want.name), "%s: name %q", name, fi.path)
		testing.expectf(t, fi.type == want_type, "%s: type %v", name, fi.type)
		testing.expectf(t, fi.method == want.method, "%s: method %v, want %v", name, fi.method, want.method)
		testing.expectf(t, fi.encrypted == (want.password != ""), "%s: encrypted %v", name, fi.encrypted)
		if want.password != "" {
			locked, locked_err := extract_to_bytes(&it)
			delete(locked)
			testing.expectf(t, locked_err == archive.General_Error.Encrypted, "%s: no password: %v", name, locked_err)
			wrong, wrong_err := extract_to_bytes(&it, {password = "wrong"})
			delete(wrong)
			testing.expectf(t, wrong_err == archive.General_Error.Wrong_Password || wrong_err == archive.General_Error.Authentication_Failed, "%s: wrong password: %v", name, wrong_err)
		}
		content, err := extract_to_bytes(&it, {password = want.password})
		testing.expectf(t, err == nil && bytes.equal(content[:], want.content), "%s: content %v, %d bytes", name, err, len(content))
		delete(content)
		if want_type == .Symlink && want.password == "" {
			target, link_err := zip.read_link(&it)
			testing.expectf(t, link_err == nil && target == string(want.content), "%s: link %q %v", name, target, link_err)
			delete(target)
		}
	}
	path, iter_err := zip.iterator_error(&it)
	testing.expectf(t, iter_err == nil, "%s: iterator %s %v", label, path, iter_err)
	testing.expectf(t, count == len(expected), "%s: %d members, want %d", label, count, len(expected))

	raw := raw_members(data)
	defer delete(raw)
	testing.expectf(t, len(raw) == len(expected), "%s: %d raw members", label, len(raw))
	salts: [dynamic][]u8
	defer delete(salts)
	for want, index in expected[:min(len(raw), len(expected))] {
		member := raw[index]
		name   := fmt.tprintf("%s/%s", label, want.name)
		if want.password == "" {
			testing.expectf(t, member.central_method != 99 && member.local_method != 99, "%s: method %d/%d", name, member.central_method, member.local_method)
			testing.expectf(t, member.central_flags & 1 == 0 && member.local_flags & 1 == 0, "%s: flags %x/%x", name, member.central_flags, member.local_flags)
			testing.expectf(t, member.central_aes == nil && member.local_aes == nil, "%s: AES extra field", name)
			continue
		}
		testing.expectf(t, member.central_method == 99 && member.local_method == 99, "%s: method %d/%d", name, member.central_method, member.local_method)
		testing.expectf(t, member.central_flags & 1 != 0 && member.local_flags & 1 != 0, "%s: flags %x/%x", name, member.central_flags, member.local_flags)
		testing.expectf(t, member.central_crc == 0 && member.local_crc == 0, "%s: CRC %x/%x", name, member.central_crc, member.local_crc)
		testing.expectf(t, member.central_version >= 51 && member.local_version >= 51, "%s: version needed %d/%d", name, member.central_version, member.local_version)
		if testing.expectf(t, len(member.central_aes) == 7 && bytes.equal(member.central_aes, member.local_aes), "%s: AES extra %v/%v", name, member.central_aes, member.local_aes) {
			extra := member.central_aes
			testing.expectf(t, get_u16(extra, 0) == 2 && extra[2] == 'A' && extra[3] == 'E' && extra[4] == 3, "%s: AES extra %v", name, extra)
			testing.expectf(t, get_u16(extra, 5) == zip_method_code(want.method), "%s: AES extra method %d", name, get_u16(extra, 5))
		}
		if want.method == .Store {
			testing.expectf(t, member.compressed == member.size + 28, "%s: %d bytes for %d", name, member.compressed, member.size)
		}
		salt := data[member.data:][:zip.AES_SALT_SIZE]
		for other in salts {
			testing.expectf(t, !bytes.equal(other, salt), "%s: salt reused", name)
		}
		append(&salts, salt)
	}
}

zip_method_code :: proc(method: archive.Method) -> u16 {
	#partial switch method {
	case .Store:     return 0
	case .Deflate:   return 8
	case .Deflate64: return 9
	case .BZip2:     return 12
	case .LZMA:      return 14
	case .XZ:        return 95
	case .PPMd_I:    return 98
	}
	return 0xFFFF
}

raw_members :: proc(data: []u8) -> (members: [dynamic]Raw_Member) {
	end := len(data) - 22
	if end < 0 || get_u32(data, end) != 0x06054b50 {
		return
	}
	count := int(get_u16(data, end + 10))
	pos   := int(get_u32(data, end + 16))
	for _ in 0..<count {
		if pos + 46 > len(data) || get_u32(data, pos) != 0x02014b50 {
			break
		}
		name_length    := int(get_u16(data, pos + 28))
		extra_length   := int(get_u16(data, pos + 30))
		comment_length := int(get_u16(data, pos + 32))
		local          := int(get_u32(data, pos + 42))
		member: Raw_Member
		member.name            = string(data[pos + 46:][:name_length])
		member.central_version = get_u16(data, pos + 6)
		member.central_flags   = get_u16(data, pos + 8)
		member.central_method  = get_u16(data, pos + 10)
		member.central_crc     = get_u32(data, pos + 16)
		member.compressed      = get_u32(data, pos + 20)
		member.size            = get_u32(data, pos + 24)
		member.central_aes     = find_aes_extra(data[pos + 46 + name_length:][:extra_length])
		local_name  := int(get_u16(data, local + 26))
		local_extra := int(get_u16(data, local + 28))
		member.local_version = get_u16(data, local + 4)
		member.local_flags   = get_u16(data, local + 6)
		member.local_method  = get_u16(data, local + 8)
		member.local_crc     = get_u32(data, local + 14)
		member.local_aes     = find_aes_extra(data[local + 30 + local_name:][:local_extra])
		member.data          = local + 30 + local_name + local_extra
		append(&members, member)
		pos += 46 + name_length + extra_length + comment_length
	}
	return
}

find_aes_extra :: proc(extra: []u8) -> []u8 {
	pos := 0
	for pos + 4 <= len(extra) {
		id   := get_u16(extra, pos)
		size := int(get_u16(extra, pos + 2))
		if pos + 4 + size > len(extra) {
			return nil
		}
		if id == 0x9901 {
			return extra[pos + 4:][:size]
		}
		pos += 4 + size
	}
	return nil
}

scan_add :: proc(s: ^Secret_Scan, needle: []u8) {
	s.needles[s.count] = needle
	s.count += 1
}

scan_block :: proc(s: ^Secret_Scan, memory: rawptr, size: int) {
	if memory == nil || size <= 0 {
		return
	}
	block := ([^]u8)(memory)[:size]
	for needle in s.needles[:s.count] {
		if bytes.index(block, needle) >= 0 {
			s.hits += 1
			return
		}
	}
}

secret_scan_allocator :: proc(s: ^Secret_Scan) -> mem.Allocator {
	return {procedure = secret_scan_proc, data = s}
}

secret_scan_proc :: proc(allocator_data: rawptr, mode: mem.Allocator_Mode, size, alignment: int, old_memory: rawptr, old_size: int, location := #caller_location) -> ([]byte, mem.Allocator_Error) {
	s := (^Secret_Scan)(allocator_data)
	#partial switch mode {
	case .Alloc, .Alloc_Non_Zeroed:
		block, err := s.backing.procedure(s.backing.data, mode, size, alignment, old_memory, old_size, location)
		if err == nil && block != nil {
			s.sizes[raw_data(block)] = len(block)
		}
		return block, err
	case .Free:
		if old_memory == nil {
			return nil, nil
		}
		known := s.sizes[old_memory] or_else old_size
		scan_block(s, old_memory, known)
		delete_key(&s.sizes, old_memory)
		return s.backing.procedure(s.backing.data, .Free, 0, 0, old_memory, known, location)
	case .Resize, .Resize_Non_Zeroed:
		if old_memory == nil {
			return secret_scan_proc(allocator_data, .Alloc if mode == .Resize else .Alloc_Non_Zeroed, size, alignment, nil, 0, location)
		}
		known := s.sizes[old_memory] or_else old_size
		if size == 0 {
			return secret_scan_proc(allocator_data, .Free, 0, 0, old_memory, known, location)
		}
		block, err := secret_scan_proc(allocator_data, .Alloc if mode == .Resize else .Alloc_Non_Zeroed, size, alignment, nil, 0, location)
		if err != nil {
			return nil, err
		}
		copy(block, ([^]u8)(old_memory)[:min(known, size)])
		_, err = secret_scan_proc(allocator_data, .Free, 0, 0, old_memory, known, location)
		return block, err
	case .Free_All:
		return nil, .Mode_Not_Implemented
	}
	return s.backing.procedure(s.backing.data, mode, size, alignment, old_memory, old_size, location)
}
