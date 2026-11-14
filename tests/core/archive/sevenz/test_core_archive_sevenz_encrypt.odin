package test_core_archive_sevenz

import "core:archive"
import "core:archive/sevenz"
import "core:bytes"
import "core:compress"
import "core:fmt"
import "core:mem"
import "core:strings"
import "core:testing"

WRITE_PASSWORD :: "Ostrich-Sesame-42"
OTHER_PASSWORD :: "Pelican-Quartz-77"

Header_Mode :: struct {
	unencrypted: bool,
	plain:       bool,
}

Secret_Scan :: struct {
	backing: mem.Allocator,
	sizes:   map[rawptr]int,
	needles: [8][]u8,
	count:   int,
	hits:    int,
}

AES_Info :: struct {
	properties: []u8,
	folder:     int,
	position:   int,
}

@(test)
test_write_encrypted :: proc(t: ^testing.T) {
	text   := write_text()
	random := write_random(70_000, 5)
	defer delete(random)
	modes := [?]Header_Mode{{false, false}, {true, false}, {false, true}, {true, true}}
	for method in WRITE_METHODS {
		for solid in ([?]bool{false, true}) {
			for mode in modes {
				label := fmt.tprintf("%v solid=%v unencrypted=%v plain=%v", method, solid, mode.unencrypted, mode.plain)
				m := Memory_File{seekable = true}
				defer delete(m.data)
				sw: sevenz.Writer
				options := sevenz.Writer_Options{
					method             = method,
					solid              = solid,
					password           = WRITE_PASSWORD,
					kdf_power          = 1,
					unencrypted_header = mode.unencrypted,
					plain_header       = mode.plain,
				}
				if !testing.expectf(t, sevenz.create(&sw, memory_stream(&m), options) == nil, "%s: create", label) {
					continue
				}
				testing.expect_value(t, sevenz.write_entry(&sw, "text.txt", text), nil)
				testing.expect_value(t, sevenz.write_entry(&sw, archive.File_Info{path = "dir", type = .Directory}), nil)
				testing.expect_value(t, sevenz.write_entry(&sw, "dir/random.bin", random), nil)
				testing.expect_value(t, sevenz.write_entry(&sw, "empty.txt", []u8{}), nil)
				testing.expect_value(t, sevenz.commit(&sw), nil)
				sevenz.close(&sw)
				check_written(t, label, m.data[:], {
					{name = "text.txt",       type = .Regular,   content = text,   method = method, encrypted = true},
					{name = "dir",            type = .Directory},
					{name = "dir/random.bin", type = .Regular,   content = random, method = method, encrypted = true},
					{name = "empty.txt",      type = .Regular},
				}, WRITE_PASSWORD)
				check_locked(t, label, m.data[:], !mode.unencrypted)
				testing.expectf(t, bytes.index(m.data[:], text[:64]) < 0, "%s: plaintext in the archive", label)
				name := utf16_bytes("random.bin")
				defer delete(name)
				visible := bytes.index(m.data[:], name) >= 0
				if !mode.unencrypted {
					testing.expectf(t, !visible, "%s: names visible in an encrypted header", label)
				} else if mode.plain {
					testing.expectf(t, visible, "%s: names missing from a plain header", label)
				}
				folders := 2 if !solid || method == .Store else 1
				testing.expectf(t, count_folders(m.data[:], WRITE_PASSWORD) == folders, "%s: folders", label)
			}
		}
	}
}

@(test)
test_write_encrypted_filters :: proc(t: ^testing.T) {
	data := write_random(100_003, 13)
	defer delete(data)
	cases := [?]Filter_Case{
		{.BCJ_X86,   0, {.BCJ_X86}},
		{.Delta,     4, {.Delta}},
		{.BCJ2,      0, {.BCJ2}},
		{.Swap4,     0, {.Swap4}},
		{.BCJ_ARM64, 0, {.BCJ_ARM64}},
	}
	for c in cases {
		for solid in ([?]bool{false, true}) {
			for unencrypted in ([?]bool{false, true}) {
				label := fmt.tprintf("%v solid=%v unencrypted=%v", c.filter, solid, unencrypted)
				m := Memory_File{seekable = true}
				defer delete(m.data)
				sw: sevenz.Writer
				options := sevenz.Writer_Options{
					method             = .LZMA2,
					solid              = solid,
					filter             = c.filter,
					delta_distance     = c.delta,
					password           = WRITE_PASSWORD,
					kdf_power          = 1,
					unencrypted_header = unencrypted,
				}
				if !testing.expectf(t, sevenz.create(&sw, memory_stream(&m), options) == nil, "%s: create", label) {
					continue
				}
				inner: bytes.Reader
				bytes.reader_init(&inner, data)
				unknown := Non_Seekable{inner = bytes.reader_to_stream(&inner)}
				testing.expectf(t, sevenz.write_entry(&sw, "a.bin", data) == nil, "%s: a.bin", label)
				testing.expectf(t, sevenz.write_entry(&sw, archive.File_Info{path = "b.bin", size = -1}, non_seekable_stream(&unknown)) == nil, "%s: b.bin", label)
				testing.expectf(t, sevenz.write_entry(&sw, "c.bin", data[:4096]) == nil, "%s: c.bin", label)
				testing.expectf(t, sevenz.commit(&sw) == nil, "%s: commit", label)
				sevenz.close(&sw)
				check_written(t, label, m.data[:], {
					{name = "a.bin", type = .Regular, content = data,        method = .LZMA2, filters = c.want, encrypted = true},
					{name = "b.bin", type = .Regular, content = data,        method = .LZMA2, filters = c.want, encrypted = true},
					{name = "c.bin", type = .Regular, content = data[:4096], method = .LZMA2, filters = c.want, encrypted = true},
				}, WRITE_PASSWORD)
				check_locked(t, label, m.data[:], !unencrypted)

				infos := aes_infos(m.data[:], WRITE_PASSWORD)
				defer delete_aes_infos(infos)
				per_folder := 4 if c.filter == .BCJ2 else 1
				folders    := count_folders(m.data[:], WRITE_PASSWORD)
				testing.expectf(t, folders > 0 && len(infos) == per_folder * folders, "%s: %d AES coders in %d folders", label, len(infos), folders)
				for info, i in infos {
					testing.expectf(t, info.position < per_folder, "%s: AES coder at position %d", label, info.position)
					for other in infos[i + 1:] {
						testing.expectf(t, !bytes.equal(info.properties[18:], other.properties[18:]), "%s: repeated IV", label)
					}
				}
			}
		}
	}
}

@(test)
test_write_entry_passwords :: proc(t: ^testing.T) {
	text := write_text()
	m := Memory_File{seekable = true}
	defer delete(m.data)
	sw: sevenz.Writer
	options := sevenz.Writer_Options{solid = true, password = WRITE_PASSWORD, kdf_power = 1, unencrypted_header = true}
	if !testing.expect_value(t, sevenz.create(&sw, memory_stream(&m), options), nil) {
		return
	}
	testing.expect_value(t, sevenz.write_entry(&sw, "a.txt", text), nil)
	testing.expect_value(t, sevenz.write_entry(&sw, "b.txt", text, {password = ""}), nil)
	testing.expect_value(t, sevenz.write_entry(&sw, "c.txt", text, {password = OTHER_PASSWORD}), nil)
	testing.expect_value(t, sevenz.write_entry(&sw, "d.txt", text, {password = OTHER_PASSWORD}), nil)
	testing.expect_value(t, sevenz.write_entry(&sw, "e.txt", text), nil)
	testing.expect_value(t, sevenz.commit(&sw), nil)
	sevenz.close(&sw)
	testing.expect_value(t, count_folders(m.data[:]), 4)

	Expect :: struct {
		name: string,
		err:  archive.Error,
	}
	none := [?]Expect{
		{"a.txt", archive.General_Error.Encrypted},
		{"b.txt", nil},
		{"c.txt", archive.General_Error.Encrypted},
		{"d.txt", archive.General_Error.Encrypted},
		{"e.txt", archive.General_Error.Encrypted},
	}
	archive_password := [?]Expect{
		{"a.txt", nil},
		{"b.txt", nil},
		{"c.txt", archive.General_Error.Wrong_Password},
		{"d.txt", archive.General_Error.Wrong_Password},
		{"e.txt", nil},
	}
	for pass in 0..<2 {
		password := "" if pass == 0 else WRITE_PASSWORD
		expect   := none[:] if pass == 0 else archive_password[:]
		r: sevenz.Reader
		if !testing.expect_value(t, sevenz.open(&r, m.data[:], compress.Options{}, context.allocator, archive.Read_Options{password = password}), nil) {
			continue
		}
		for e in expect {
			fi, handle, ok, _ := sevenz.find(&r, e.name)
			if !testing.expectf(t, ok, "find %s", e.name) {
				continue
			}
			testing.expectf(t, fi.encrypted == (e.name != "b.txt"), "%s: encrypted %v", e.name, fi.encrypted)
			sink := strings.builder_make()
			err := sevenz.extract(&r, handle, strings.to_writer(&sink))
			testing.expectf(t, err == e.err, "%s with %q: %v, want %v", e.name, password, err, e.err)
			if err == nil {
				testing.expectf(t, bytes.equal(sink.buf[:], text), "%s: content", e.name)
			}
			strings.builder_reset(&sink)
			if e.name == "c.txt" || e.name == "d.txt" {
				testing.expect_value(t, sevenz.extract(&r, handle, strings.to_writer(&sink), {password = OTHER_PASSWORD}), nil)
				testing.expectf(t, bytes.equal(sink.buf[:], text), "%s: content with its own password", e.name)
			}
			strings.builder_destroy(&sink)
		}
		sevenz.close(&r)
	}

	clear(&m.data)
	m.position = 0
	if !testing.expect_value(t, sevenz.create(&sw, memory_stream(&m), {kdf_power = 1}), nil) {
		return
	}
	testing.expect_value(t, sevenz.write_entry(&sw, "plain.txt", text), nil)
	testing.expect_value(t, sevenz.write_entry(&sw, "locked.txt", text, {password = OTHER_PASSWORD}), nil)
	testing.expect_value(t, sevenz.commit(&sw), nil)
	sevenz.close(&sw)
	check_written(t, "entry password only", m.data[:], {
		{name = "plain.txt",  type = .Regular, content = text, method = .LZMA2},
		{name = "locked.txt", type = .Regular, content = text, method = .LZMA2, encrypted = true},
	}, OTHER_PASSWORD)
	check_locked(t, "entry password only", m.data[:], false)
}

@(test)
test_write_password_options :: proc(t: ^testing.T) {
	text := write_text()
	m := Memory_File{seekable = true}
	defer delete(m.data)
	sw: sevenz.Writer
	testing.expect_value(t, sevenz.create(&sw, memory_stream(&m), {password = WRITE_PASSWORD, deterministic = true}), archive.General_Error.Incompatible_Options)
	testing.expect_value(t, sevenz.create(&sw, memory_stream(&m), {kdf_power = -1}), archive.General_Error.Incompatible_Options)
	testing.expect_value(t, sevenz.create(&sw, memory_stream(&m), {kdf_power = 25}), archive.General_Error.Incompatible_Options)
	if testing.expect_value(t, sevenz.create(&sw, memory_stream(&m), {kdf_power = 24, password = WRITE_PASSWORD}), nil) {
		sevenz.close(&sw)
	}

	clear(&m.data)
	m.position = 0
	if !testing.expect_value(t, sevenz.create(&sw, memory_stream(&m), {deterministic = true}), nil) {
		return
	}
	testing.expect_value(t, sevenz.write_entry(&sw, "a.txt", text, {password = WRITE_PASSWORD}), archive.General_Error.Incompatible_Options)
	testing.expect_value(t, sevenz.write_entry(&sw, archive.File_Info{path = "dir", type = .Directory}, nil, {password = WRITE_PASSWORD}), archive.General_Error.Incompatible_Options)
	testing.expect_value(t, sevenz.write_directory(&sw, "does-not-exist", "", {password = WRITE_PASSWORD}), archive.General_Error.Incompatible_Options)
	testing.expect_value(t, sevenz.write_entry(&sw, "b.txt", text, {password = ""}), nil)
	testing.expect_value(t, sevenz.commit(&sw), nil)
	sevenz.close(&sw)
	check_written(t, "deterministic", m.data[:], {
		{name = "b.txt", type = .Regular, content = text, method = .LZMA2},
	})

	salts: [2][]u8
	defer {
		delete(salts[0])
		delete(salts[1])
	}
	for power, i in ([?]int{3, 0}) {
		label := fmt.tprintf("power %d", power)
		clear(&m.data)
		m.position = 0
		if !testing.expectf(t, sevenz.create(&sw, memory_stream(&m), {password = WRITE_PASSWORD, kdf_power = power}) == nil, "%s: create", label) {
			continue
		}
		testing.expect_value(t, sevenz.write_entry(&sw, "a.txt", text), nil)
		testing.expect_value(t, sevenz.write_entry(&sw, "b.txt", text, {method = .Store}), nil)
		testing.expect_value(t, sevenz.commit(&sw), nil)
		sevenz.close(&sw)
		check_written(t, label, m.data[:], {
			{name = "a.txt", type = .Regular, content = text, method = .LZMA2, encrypted = true},
			{name = "b.txt", type = .Regular, content = text, method = .Store, encrypted = true},
		}, WRITE_PASSWORD)
		infos := aes_infos(m.data[:], WRITE_PASSWORD)
		defer delete_aes_infos(infos)
		if !testing.expectf(t, len(infos) == 2, "%s: %d AES coders", label, len(infos)) {
			continue
		}
		want := u8(power) if power != 0 else 19
		for info in infos {
			p := info.properties
			testing.expectf(t, len(p) == 34 && p[0] == (want | 0xC0) && p[1] == 0xFF, "%s: properties % x", label, p[:2])
		}
		testing.expectf(t, bytes.equal(infos[0].properties[2:18], infos[1].properties[2:18]), "%s: salt differs between folders", label)
		testing.expectf(t, !bytes.equal(infos[0].properties[18:], infos[1].properties[18:]), "%s: repeated IV", label)
		salts[i] = make([]u8, 16)
		copy(salts[i], infos[0].properties[2:18])
	}
	testing.expect(t, !bytes.equal(salts[0], salts[1]), "two archives share a salt")
}

@(test)
test_write_secrets_freed :: proc(t: ^testing.T) {
	text := write_text()
	scan := Secret_Scan{backing = context.allocator}
	scan.sizes.allocator = context.allocator
	defer delete(scan.sizes)
	scan_add(&scan, transmute([]u8)string(WRITE_PASSWORD))
	scan_add(&scan, transmute([]u8)string(OTHER_PASSWORD))
	write_utf16 := utf16_bytes(WRITE_PASSWORD)
	other_utf16 := utf16_bytes(OTHER_PASSWORD)
	defer {
		delete(write_utf16)
		delete(other_utf16)
	}
	scan_add(&scan, write_utf16)
	scan_add(&scan, other_utf16)

	m := Memory_File{seekable = true}
	defer delete(m.data)
	{
		context.allocator = secret_scan_allocator(&scan)
		sw: sevenz.Writer
		options := sevenz.Writer_Options{password = WRITE_PASSWORD, kdf_power = 2, solid = true, level = 1}
		if testing.expect_value(t, sevenz.create(&sw, memory_stream(&m), options), nil) {
			testing.expect_value(t, sevenz.write_entry(&sw, "a.txt", text), nil)
			testing.expect_value(t, sevenz.write_entry(&sw, "b.txt", text, {password = OTHER_PASSWORD, filter = .BCJ2}), nil)
			testing.expect_value(t, sevenz.commit(&sw), nil)
			sevenz.close(&sw)
		}
	}
	testing.expectf(t, scan.hits == 0, "writer freed %d blocks holding a password", scan.hits)

	infos := aes_infos(m.data[:], WRITE_PASSWORD)
	defer delete_aes_infos(infos)
	if !testing.expectf(t, len(infos) == 5, "%d AES coders", len(infos)) {
		return
	}
	salt := infos[0].properties[2:18]
	write_key := aes_key(2, salt, WRITE_PASSWORD)
	other_key := aes_key(2, salt, OTHER_PASSWORD)
	scan_add(&scan, write_key[:])
	scan_add(&scan, other_key[:])

	{
		context.allocator = secret_scan_allocator(&scan)
		r: sevenz.Reader
		if testing.expect_value(t, sevenz.open(&r, m.data[:], compress.Options{}, context.allocator, archive.Read_Options{password = WRITE_PASSWORD}), nil) {
			it := sevenz.iterator_create(&r)
			for fi in sevenz.iterate(&it) {
				sink := strings.builder_make()
				if fi.path == "b.txt" {
					testing.expect_value(t, sevenz.extract_current(&it, strings.to_writer(&sink)), archive.General_Error.Wrong_Password)
					strings.builder_reset(&sink)
					testing.expect_value(t, sevenz.extract_current(&it, strings.to_writer(&sink), {password = OTHER_PASSWORD}), nil)
				} else {
					testing.expect_value(t, sevenz.extract_current(&it, strings.to_writer(&sink)), nil)
				}
				testing.expectf(t, bytes.equal(sink.buf[:], text), "%s: content", fi.path)
				strings.builder_destroy(&sink)
			}
			sevenz.iterator_destroy(&it)
			sevenz.close(&r)
		}
	}
	testing.expectf(t, scan.hits == 0, "reader freed %d blocks holding a password or key", scan.hits)
}

check_locked :: proc(t: ^testing.T, label: string, data: []u8, header_encrypted: bool) {
	for password in ([?]string{"", "wrong"}) {
		want := archive.Error(archive.General_Error.Encrypted if password == "" else archive.General_Error.Wrong_Password)
		r: sevenz.Reader
		open_err := sevenz.open(&r, data, compress.Options{}, context.allocator, archive.Read_Options{password = password})
		if header_encrypted {
			testing.expectf(t, open_err == want, "%s: open with %q: %v", label, password, open_err)
			if open_err == nil {
				sevenz.close(&r)
			}
			continue
		}
		if !testing.expectf(t, open_err == nil, "%s: open with %q: %v", label, password, open_err) {
			continue
		}
		it := sevenz.iterator_create(&r)
		locked := 0
		for fi in sevenz.iterate(&it) {
			if !fi.encrypted {
				continue
			}
			testing.expectf(t, fi.supported, "%s/%s: unsupported", label, fi.path)
			content, err := extract_to_bytes(&it)
			delete(content)
			testing.expectf(t, err == want, "%s/%s: extract with %q: %v", label, fi.path, password, err)
			locked += 1
		}
		sevenz.iterator_destroy(&it)
		sevenz.close(&r)
		testing.expectf(t, locked > 0, "%s: no encrypted entries", label)
	}
}

aes_infos :: proc(data: []u8, password: string) -> (infos: [dynamic]AES_Info) {
	r: sevenz.Reader
	if sevenz.open(&r, data, compress.Options{}, context.allocator, archive.Read_Options{password = password}) != nil {
		return
	}
	defer sevenz.close(&r)
	for folder, index in r.streams.folders {
		for coder, position in r.streams.coders[folder.first_coder:][:folder.coder_count] {
			if coder.kind == .AES {
				append(&infos, AES_Info{properties = bytes.clone(coder.properties), folder = index, position = position})
			}
		}
	}
	return
}

delete_aes_infos :: proc(infos: [dynamic]AES_Info) {
	for info in infos {
		delete(info.properties)
	}
	delete(infos)
}

utf16_bytes :: proc(s: string) -> (out: []u8) {
	out = make([]u8, 2 * len(s))
	for c, i in transmute([]u8)s {
		out[2 * i] = c
	}
	return
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
