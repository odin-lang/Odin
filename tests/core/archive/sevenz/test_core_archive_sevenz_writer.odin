package test_core_archive_sevenz

import "core:archive"
import "core:archive/sevenz"
import "core:bytes"
import "core:compress"
import "core:compress/bzip2"
import "core:compress/deflate"
import "core:compress/lzma"
import "core:compress/ppmd"
import "core:fmt"
import "core:io"
import "core:os"
import "core:strings"
import "core:testing"
import "core:time"

WRITE_TEXT :: "Each folder packs its streams, and the header lists every file with its size and CRC.\n"

WRITE_METHODS :: [?]archive.Method{.Store, .LZMA2, .LZMA, .PPMd_H, .BZip2, .Deflate, .Deflate64}

Memory_File :: struct {
	data:     [dynamic]u8,
	position: int,
	seekable: bool,
}

Write_Expect :: struct {
	name:      string,
	type:      archive.Entry_Type,
	content:   []u8,
	method:    archive.Method,
	filters:   archive.Filters,
	mode:      u32,
	dos:       u32,
	link:      string,
	encrypted: bool,
}

Filter_Case :: struct {
	filter: sevenz.Filter_Choice,
	delta:  int,
	want:   archive.Filters,
}

Sniff_Case :: struct {
	name:  string,
	data:  []u8,
	want:  archive.Filters,
	high:  archive.Filters,
}

@(test)
test_write_methods :: proc(t: ^testing.T) {
	text   := write_text()
	random := write_random(70_000, 3)
	defer delete(random)
	for method in WRITE_METHODS {
		for solid in ([?]bool{false, true}) {
			for plain in ([?]bool{false, true}) {
				label := fmt.tprintf("%v solid=%v plain=%v", method, solid, plain)
				m := Memory_File{seekable = true}
				defer delete(m.data)
				sw: sevenz.Writer
				options := sevenz.Writer_Options{method = method, solid = solid, plain_header = plain}
				if !testing.expectf(t, sevenz.create(&sw, memory_stream(&m), options) == nil, "%s: create", label) {
					continue
				}
				inner: bytes.Reader
				bytes.reader_init(&inner, text)
				unknown := Non_Seekable{inner = bytes.reader_to_stream(&inner)}
				testing.expect_value(t, sevenz.write_entry(&sw, "text.txt", text), nil)
				testing.expect_value(t, sevenz.write_entry(&sw, archive.File_Info{path = "dir", type = .Directory}), nil)
				testing.expect_value(t, sevenz.write_entry(&sw, "dir/random.bin", random), nil)
				testing.expect_value(t, sevenz.write_entry(&sw, "empty.txt", []u8{}), nil)
				testing.expect_value(t, sevenz.write_entry(&sw, archive.File_Info{path = "streamed.txt", size = -1}, non_seekable_stream(&unknown)), nil)
				testing.expect_value(t, sevenz.commit(&sw), nil)
				sevenz.close(&sw)
				check_written(t, label, m.data[:], {
					{name = "text.txt",       type = .Regular,   content = text,   method = method},
					{name = "dir",            type = .Directory},
					{name = "dir/random.bin", type = .Regular,   content = random, method = method},
					{name = "empty.txt",      type = .Regular},
					{name = "streamed.txt",   type = .Regular,   content = text,   method = method},
				})
				folders := 3 if !solid || method == .Store else 1
				got     := count_folders(m.data[:])
				testing.expectf(t, got == folders, "%s: %d folders, want %d", label, got, folders)
			}
		}
	}
}

@(test)
test_write_filters :: proc(t: ^testing.T) {
	data := write_random(100_003, 11)
	defer delete(data)
	cases := [?]Filter_Case{
		{.None,      0, {}},
		{.Delta,     0, {.Delta}},
		{.Delta,     3, {.Delta}},
		{.BCJ_X86,   0, {.BCJ_X86}},
		{.BCJ_PPC,   0, {.BCJ_PPC}},
		{.BCJ_IA64,  0, {.BCJ_IA64}},
		{.BCJ_ARM,   0, {.BCJ_ARM}},
		{.BCJ_ARMT,  0, {.BCJ_ARMT}},
		{.BCJ_SPARC, 0, {.BCJ_SPARC}},
		{.BCJ_ARM64, 0, {.BCJ_ARM64}},
		{.BCJ_RISCV, 0, {.BCJ_RISCV}},
		{.BCJ2,      0, {.BCJ2}},
		{.Swap2,     0, {.Swap2}},
		{.Swap4,     0, {.Swap4}},
	}
	for c in cases {
		for method in ([?]archive.Method{.LZMA2, .Store, .Deflate}) {
			for solid in ([?]bool{false, true}) {
				label := fmt.tprintf("%v %v solid=%v", c.filter, method, solid)
				m := Memory_File{seekable = true}
				defer delete(m.data)
				sw: sevenz.Writer
				options := sevenz.Writer_Options{method = method, solid = solid, filter = c.filter, delta_distance = c.delta}
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
					{name = "a.bin", type = .Regular, content = data,        method = method, filters = c.want},
					{name = "b.bin", type = .Regular, content = data,        method = method, filters = c.want},
					{name = "c.bin", type = .Regular, content = data[:4096], method = method, filters = c.want},
				})
			}
		}
	}
}

@(test)
test_write_sniff :: proc(t: ^testing.T) {
	cases := [?]Sniff_Case{
		{"pe-x64",       make_pe(0x8664, 4096),         {.BCJ_X86},   {.BCJ2}},
		{"pe-x86",       make_pe(0x014C, 4096),         {.BCJ_X86},   {.BCJ2}},
		{"pe-arm64",     make_pe(0xAA64, 4096),         {.BCJ_ARM64}, {.BCJ_ARM64}},
		{"pe-armt",      make_pe(0x01C4, 4096),         {.BCJ_ARMT},  {.BCJ_ARMT}},
		{"pe-riscv",     make_pe(0x5064, 4096),         {.BCJ_RISCV}, {.BCJ_RISCV}},
		{"pe-ia64",      make_pe(0x0200, 4096),         {.BCJ_IA64},  {.BCJ_IA64}},
		{"pe-ia64-odd",  make_pe(0x0200, 4097),         {},           {}},
		{"elf-x64",      make_elf(62, false, 4096),     {.BCJ_X86},   {.BCJ2}},
		{"elf-arm",      make_elf(40, false, 4096),     {.BCJ_ARM},   {.BCJ_ARM}},
		{"elf-arm64",    make_elf(183, false, 4096),    {.BCJ_ARM64}, {.BCJ_ARM64}},
		{"elf-riscv",    make_elf(243, false, 4096),    {.BCJ_RISCV}, {.BCJ_RISCV}},
		{"elf-ppc",      make_elf(20, true, 4096),      {.BCJ_PPC},   {.BCJ_PPC}},
		{"elf-ppc-le",   make_elf(20, false, 4096),     {},           {}},
		{"elf-sparc",    make_elf(2, true, 4096),       {.BCJ_SPARC}, {.BCJ_SPARC}},
		{"macho-arm64",  make_macho(0x0100_000C, 4096), {.BCJ_ARM64}, {.BCJ_ARM64}},
		{"macho-x64",    make_macho(0x0100_0007, 4096), {.BCJ_X86},   {.BCJ2}},
		{"wav",          make_wav(2, 16, 4099),         {.Delta},     {.Delta}},
		{"wav-24",       make_wav(1, 20, 4096),         {},           {}},
		{"short",        make_pe(0x8664, 511),          {},           {}},
	}
	defer for c in cases {
		delete(c.data)
	}
	for c in cases {
		Default_Level :: struct {
			method: archive.Method,
			level:  int,
		}
		defaults := [?]Default_Level{
			{.LZMA2,     int(lzma.Level.Default)},
			{.LZMA,      int(lzma.Level.Default)},
			{.PPMd_H,    int(ppmd.Level.Default)},
			{.BZip2,     int(bzip2.Level.Default)},
			{.Deflate,   int(deflate.Deflate_Level.Default)},
			{.Deflate64, int(deflate.Deflate_Level.Default)},
		}
		for d in defaults {
			for level in ([?]Maybe(int){d.level - 1, d.level, nil}) {
				method := d.method
				want   := c.want if level == d.level - 1 else c.high
				label  := fmt.tprintf("%s level %v %v", c.name, level, method)
				m := Memory_File{seekable = true}
				defer delete(m.data)
				sw: sevenz.Writer
				if !testing.expectf(t, sevenz.create(&sw, memory_stream(&m), sevenz.Writer_Options{method = method, level = level}) == nil, "%s: create", label) {
					continue
				}
				testing.expectf(t, sevenz.write_entry(&sw, c.name, c.data) == nil, "%s: write", label)
				testing.expectf(t, sevenz.commit(&sw) == nil, "%s: commit", label)
				sevenz.close(&sw)
				check_written(t, label, m.data[:], {{name = c.name, type = .Regular, content = c.data, method = method, filters = want}})
			}
		}
		m := Memory_File{seekable = true}
		defer delete(m.data)
		sw: sevenz.Writer
		if testing.expect_value(t, sevenz.create(&sw, memory_stream(&m), sevenz.Writer_Options{method = .Store, level = 9}), nil) {
			testing.expect_value(t, sevenz.write_entry(&sw, c.name, c.data), nil)
			testing.expect_value(t, sevenz.commit(&sw), nil)
			sevenz.close(&sw)
			check_written(t, c.name, m.data[:], {{name = c.name, type = .Regular, content = c.data, method = .Store}})
		}
	}
}

@(test)
test_write_auto :: proc(t: ^testing.T) {
	r: sevenz.Reader
	if !testing.expect_value(t, sevenz.open(&r, asset("auto.7z")), nil) {
		return
	}
	defer sevenz.close(&r)
	names    := [3]string{"TEXT.TXT", "TONE.WAV", "PROG.EXE"}
	contents: [3][dynamic]u8
	defer for c in contents {
		delete(c)
	}
	for name, i in names {
		_, handle, ok, _ := sevenz.find(&r, name)
		if !testing.expectf(t, ok, "find %s", name) {
			return
		}
		sink := strings.builder_make()
		testing.expect_value(t, sevenz.extract(&r, handle, strings.to_writer(&sink)), nil)
		contents[i] = sink.buf
	}
	for level in ([?]int{int(lzma.Level.Default) - 1, int(lzma.Level.Default)}) {
		for solid in ([?]bool{false, true}) {
			label := fmt.tprintf("auto level %d solid=%v", level, solid)
			m := Memory_File{seekable = true}
			defer delete(m.data)
			sw: sevenz.Writer
			if !testing.expect_value(t, sevenz.create(&sw, memory_stream(&m), sevenz.Writer_Options{level = level, solid = solid}), nil) {
				continue
			}
			for name, i in names {
				testing.expectf(t, sevenz.write_entry(&sw, name, contents[i][:]) == nil, "%s: %s", label, name)
			}
			testing.expect_value(t, sevenz.commit(&sw), nil)
			sevenz.close(&sw)
			exe := archive.Filters{.BCJ2} if level == int(lzma.Level.Default) else {.BCJ_X86}
			check_written(t, label, m.data[:], {
				{name = "TEXT.TXT", type = .Regular, content = contents[0][:], method = .LZMA2},
				{name = "TONE.WAV", type = .Regular, content = contents[1][:], method = .LZMA2, filters = {.Delta}},
				{name = "PROG.EXE", type = .Regular, content = contents[2][:], method = .LZMA2, filters = exe},
			})
			testing.expectf(t, count_folders(m.data[:]) == 3, "%s: %d folders", label, count_folders(m.data[:]))
		}
	}
}

@(test)
test_write_solid_limits :: proc(t: ^testing.T) {
	text := write_text()
	Limit_Case :: struct {
		options: sevenz.Writer_Options,
		entries: [5]sevenz.Entry_Options,
		folders: int,
	}
	cases := [?]Limit_Case{
		{{solid = true}, {}, 1},
		{{solid = true, solid_files = 2}, {}, 3},
		{{solid = true, solid_size = i64(len(text)) * 2 + 1}, {}, 3},
		{{solid = true, method = .Store}, {}, 5},
		{{solid = true, method = .Store, solid_size = 1 << 20}, {}, 1},
		{{solid = true}, {{}, {method = .BZip2}, {}, {}, {}}, 3},
		{{solid = true}, {{}, {}, {level = 8}, {level = 8}, {}}, 3},
		{{solid = true}, {{}, {}, {filter = .Delta, delta_distance = 2}, {}, {}}, 3},
		{{solid = true, method = .BZip2}, {{}, {method = .BZip2}, {method = .BZip2, level = 9}, {}, {}}, 1},
		{{solid = true}, {{}, {}, {filter = .BCJ_ARM}, {filter = .BCJ_ARM}, {}}, 3},
	}
	for c, index in cases {
		label := fmt.tprintf("solid case %d", index)
		m := Memory_File{seekable = true}
		defer delete(m.data)
		sw: sevenz.Writer
		if !testing.expectf(t, sevenz.create(&sw, memory_stream(&m), c.options) == nil, "%s: create", label) {
			continue
		}
		expected: [5]Write_Expect
		for options, i in c.entries {
			name := fmt.tprintf("file%d.txt", i)
			testing.expectf(t, sevenz.write_entry(&sw, name, text, options) == nil, "%s: %s", label, name)
			expected[i] = {name = name, type = .Regular, content = text}
			#partial switch options.filter {
			case .Delta:   expected[i].filters = {.Delta}
			case .BCJ_ARM: expected[i].filters = {.BCJ_ARM}
			}
		}
		testing.expectf(t, sevenz.commit(&sw) == nil, "%s: commit", label)
		sevenz.close(&sw)
		check_written(t, label, m.data[:], expected[:])
		got := count_folders(m.data[:])
		testing.expectf(t, got == c.folders, "%s: %d folders, want %d", label, got, c.folders)
	}

	odd := text[:len(text) - 1]
	m := Memory_File{seekable = true}
	defer delete(m.data)
	sw: sevenz.Writer
	if testing.expect_value(t, sevenz.create(&sw, memory_stream(&m), sevenz.Writer_Options{solid = true, filter = .BCJ_ARM}), nil) {
		for name in ([?]string{"a", "b"}) {
			inner: bytes.Reader
			bytes.reader_init(&inner, odd)
			unknown := Non_Seekable{inner = bytes.reader_to_stream(&inner)}
			testing.expect_value(t, sevenz.write_entry(&sw, archive.File_Info{path = name, size = -1}, non_seekable_stream(&unknown)), nil)
		}
		testing.expect_value(t, sevenz.commit(&sw), nil)
		sevenz.close(&sw)
		check_written(t, "misaligned", m.data[:], {
			{name = "a", type = .Regular, content = odd, filters = {.BCJ_ARM}},
			{name = "b", type = .Regular, content = odd, filters = {.BCJ_ARM}},
		})
		testing.expect_value(t, count_folders(m.data[:]), 2)
	}
}

@(test)
test_write_coder_options :: proc(t: ^testing.T) {
	text := write_text()
	m := Memory_File{seekable = true}
	defer delete(m.data)
	sw: sevenz.Writer
	options := sevenz.Writer_Options{lzma = sevenz.lzma_options_7zip(5)}
	if !testing.expect_value(t, sevenz.create(&sw, memory_stream(&m), options), nil) {
		return
	}
	defer sevenz.close(&sw)
	tiny := lzma.level_options(.Level_0)
	tiny.lc, tiny.lp, tiny.pb = 0, 2, 0
	small := ppmd.Properties{variant = .H, order = 4, mem_size = 1 << 20}
	testing.expect_value(t, sevenz.write_entry(&sw, "7zip-5.txt", text), nil)
	testing.expect_value(t, sevenz.write_entry(&sw, "level-1.txt", text, sevenz.Entry_Options{level = 1}), nil)
	testing.expect_value(t, sevenz.write_entry(&sw, "lzma.txt", text, sevenz.Entry_Options{method = .LZMA, lzma = tiny}), nil)
	testing.expect_value(t, sevenz.write_entry(&sw, "lzma-9.txt", text, sevenz.Entry_Options{method = .LZMA, level = 9}), nil)
	testing.expect_value(t, sevenz.write_entry(&sw, "ppmd.txt", text, sevenz.Entry_Options{method = .PPMd_H, ppmd = small}), nil)
	testing.expect_value(t, sevenz.write_entry(&sw, "ppmd-1.txt", text, sevenz.Entry_Options{method = .PPMd_H, level = 1}), nil)
	testing.expect_value(t, sevenz.write_entry(&sw, "bzip2.txt", text, sevenz.Entry_Options{method = .BZip2, level = 1}), nil)
	testing.expect_value(t, sevenz.write_entry(&sw, "deflate.txt", text, sevenz.Entry_Options{method = .Deflate, level = 0}), nil)
	testing.expect_value(t, sevenz.write_entry(&sw, "deflate64.txt", text, sevenz.Entry_Options{method = .Deflate64, level = 9}), nil)
	testing.expect_value(t, sevenz.commit(&sw), nil)
	check_written(t, "coder options", m.data[:], {
		{name = "7zip-5.txt",    type = .Regular, content = text, method = .LZMA2},
		{name = "level-1.txt",   type = .Regular, content = text, method = .LZMA2},
		{name = "lzma.txt",      type = .Regular, content = text, method = .LZMA},
		{name = "lzma-9.txt",    type = .Regular, content = text, method = .LZMA},
		{name = "ppmd.txt",      type = .Regular, content = text, method = .PPMd_H},
		{name = "ppmd-1.txt",    type = .Regular, content = text, method = .PPMd_H},
		{name = "bzip2.txt",     type = .Regular, content = text, method = .BZip2},
		{name = "deflate.txt",   type = .Regular, content = text, method = .Deflate},
		{name = "deflate64.txt", type = .Regular, content = text, method = .Deflate64},
	})

	seven := sevenz.lzma_options_7zip(5)
	testing.expect_value(t, seven.dict_size, u32(1 << 25))
	testing.expect_value(t, seven.nice_len, 32)
	testing.expect_value(t, seven.match_finder, lzma.Match_Finder_Kind.BT4)
	fast := sevenz.lzma_options_7zip(1)
	testing.expect_value(t, fast.dict_size, u32(1 << 18))
	testing.expect(t, fast.fast, "level 1 uses the fast parser")
	testing.expect_value(t, fast.match_finder, lzma.Match_Finder_Kind.HC5)
}

@(test)
test_write_names :: proc(t: ^testing.T) {
	names := [?]string{
		"plain.txt",
		"dir/日本語.txt",
		"emoji-\U0001F600.txt",
		"bad\xff\xfename",
		"escape-\uEF85.txt",
		"lone-\xc3",
	}
	m := Memory_File{seekable = true}
	defer delete(m.data)
	sw: sevenz.Writer
	if !testing.expect_value(t, sevenz.create(&sw, memory_stream(&m)), nil) {
		return
	}
	for name in names {
		testing.expectf(t, sevenz.write_entry(&sw, name, transmute([]u8)name) == nil, "write %q", name)
	}
	testing.expect_value(t, sevenz.write_entry(&sw, "/abs/./x//", []u8{1}), nil)
	when ODIN_OS == .Windows {
		testing.expect_value(t, sevenz.write_entry(&sw, "C:\\win\\path.txt", []u8{2}), nil)
	}
	testing.expect_value(t, sevenz.commit(&sw), nil)
	sevenz.close(&sw)

	r: sevenz.Reader
	if !testing.expect_value(t, sevenz.open(&r, m.data[:]), nil) {
		return
	}
	defer sevenz.close(&r)
	for name in names {
		fi, _, ok, _ := sevenz.find(&r, name)
		testing.expectf(t, ok && fi.path == name, "find %q: %v %q", name, ok, fi.path)
	}
	_, _, ok, _ := sevenz.find(&r, "abs/./x")
	testing.expect(t, ok, "leading slash and trailing slashes dropped")
	when ODIN_OS == .Windows {
		_, _, ok, _ = sevenz.find(&r, "win/path.txt")
		testing.expect(t, ok, "drive and backslashes")
	}
	bad, _, _, _ := sevenz.find(&r, "bad\xff\xfename")
	want := []u8{'b', 0, 'a', 0, 'd', 0, 0xFF, 0xEF, 0xFE, 0xEF, 'n', 0, 'a', 0, 'm', 0, 'e', 0}
	testing.expectf(t, bytes.equal(bad.raw_path, want), "raw name %x", bad.raw_path)
}

@(test)
test_write_metadata :: proc(t: ^testing.T) {
	text := write_text()
	m := Memory_File{seekable = true}
	defer delete(m.data)
	sw: sevenz.Writer
	if !testing.expect_value(t, sevenz.create(&sw, memory_stream(&m)), nil) {
		return
	}
	testing.expect_value(t, sevenz.write_entry(&sw, archive.File_Info{path = "run.sh", unix_mode = 0o755}, text), nil)
	testing.expect_value(t, sevenz.write_entry(&sw, archive.File_Info{path = "ro.txt", dos_attributes = archive.DOS_READ_ONLY}, text), nil)
	testing.expect_value(t, sevenz.write_entry(&sw, archive.File_Info{path = "private", type = .Directory, unix_mode = 0o700}), nil)
	testing.expect_value(t, sevenz.write_entry(&sw, archive.File_Info{path = "link", type = .Symlink, link_target = "run.sh"}), nil)
	testing.expect_value(t, sevenz.write_entry(&sw, archive.File_Info{path = "full", unix_mode = 0o100640 | 0o4000}, []u8{}), nil)
	testing.expect_value(t, sevenz.commit(&sw), nil)
	sevenz.close(&sw)
	check_written(t, "metadata", m.data[:], {
		{name = "run.sh",  type = .Regular,   content = text, method = .LZMA2, mode = 0o100755, dos = 0x20},
		{name = "ro.txt",  type = .Regular,   content = text, method = .LZMA2, mode = 0o100444, dos = 0x01},
		{name = "private", type = .Directory, mode = 0o40700,  dos = 0x10},
		{name = "link",    type = .Symlink,   content = transmute([]u8)string("run.sh"), mode = 0o120777, link = "run.sh"},
		{name = "full",    type = .Regular,   mode = 0o104640},
	})
}

@(test)
test_write_times :: proc(t: ^testing.T) {
	modified := time.unix(SOURCE_TIME, 0)
	created  := time.unix(SOURCE_TIME - 3600, 500)
	accessed := time.unix(SOURCE_TIME + 3600, 0)
	Time_Case :: struct {
		options:  sevenz.Writer_Options,
		modified: bool,
		created:  bool,
		accessed: bool,
	}
	cases := [?]Time_Case{
		{{}, true, false, false},
		{{creation_time = true}, true, true, false},
		{{creation_time = true, access_time = true}, true, true, true},
		{{creation_time = true, access_time = true, deterministic = true}, false, false, false},
	}
	for c, index in cases {
		m := Memory_File{seekable = true}
		defer delete(m.data)
		sw: sevenz.Writer
		if !testing.expect_value(t, sevenz.create(&sw, memory_stream(&m), c.options), nil) {
			continue
		}
		fi := archive.File_Info{path = "timed.txt", modification_time = modified, creation_time = created, access_time = accessed}
		testing.expect_value(t, sevenz.write_entry(&sw, fi, transmute([]u8)string("timed")), nil)
		testing.expect_value(t, sevenz.write_entry(&sw, archive.File_Info{path = "untimed.txt"}, transmute([]u8)string("untimed")), nil)
		testing.expect_value(t, sevenz.commit(&sw), nil)
		sevenz.close(&sw)
		r: sevenz.Reader
		if !testing.expect_value(t, sevenz.open(&r, m.data[:]), nil) {
			continue
		}
		got, _, ok, _ := sevenz.find(&r, "timed.txt")
		testing.expectf(t, ok, "case %d: find", index)
		testing.expectf(t, (got.modification_time == modified) == c.modified && (got.modification_time == {}) == !c.modified, "case %d: mtime %v", index, got.modification_time)
		testing.expectf(t, (got.creation_time == created) == c.created && (got.creation_time == {}) == !c.created, "case %d: ctime %v", index, got.creation_time)
		testing.expectf(t, (got.access_time == accessed) == c.accessed && (got.access_time == {}) == !c.accessed, "case %d: atime %v", index, got.access_time)
		none, _, _, _ := sevenz.find(&r, "untimed.txt")
		testing.expectf(t, none.modification_time == {} && none.creation_time == {} && none.access_time == {}, "case %d: untimed %v", index, none.modification_time)
		sevenz.close(&r)
	}

	outputs: [2]Memory_File
	defer for &o in outputs {
		delete(o.data)
	}
	for &o, round in outputs {
		o.seekable = true
		sw: sevenz.Writer
		if !testing.expect_value(t, sevenz.create(&sw, memory_stream(&o), sevenz.Writer_Options{deterministic = true, creation_time = true}), nil) {
			return
		}
		fi := archive.File_Info{path = "owned.txt", uid = 1000 + i64(round), modification_time = time.unix(SOURCE_TIME + i64(round), 0)}
		testing.expect_value(t, sevenz.write_entry(&sw, "simple.txt", write_text()), nil)
		testing.expect_value(t, sevenz.write_entry(&sw, fi, write_text()), nil)
		testing.expect_value(t, sevenz.commit(&sw), nil)
		sevenz.close(&sw)
	}
	testing.expect(t, bytes.equal(outputs[0].data[:], outputs[1].data[:]), "deterministic outputs differ")
}

@(test)
test_write_errors :: proc(t: ^testing.T) {
	text := write_text()
	m := Memory_File{seekable = true}
	defer delete(m.data)
	sw: sevenz.Writer
	if !testing.expect_value(t, sevenz.create(&sw, memory_stream(&m)), nil) {
		return
	}
	defer sevenz.close(&sw)
	testing.expect_value(t, sevenz.write_entry(&sw, "", text), SevenZ_Error.Invalid_Name)
	testing.expect_value(t, sevenz.write_entry(&sw, "/", text), SevenZ_Error.Invalid_Name)
	testing.expect_value(t, sevenz.write_entry(&sw, "./", text), SevenZ_Error.Invalid_Name)
	testing.expect_value(t, sevenz.write_entry(&sw, ".", text), SevenZ_Error.Invalid_Name)
	testing.expect_value(t, sevenz.write_entry(&sw, "a\x00b", text), SevenZ_Error.Invalid_Name)
	testing.expect_value(t, sevenz.write_entry(&sw, "../x", text), archive.General_Error.Unsafe_Path)
	testing.expect_value(t, sevenz.write_entry(&sw, "a/../b", text), archive.General_Error.Unsafe_Path)
	for method in ([?]archive.Method{.Implode, .PPMd_I, .XZ, .LZ4, .Shrink}) {
		testing.expectf(t, sevenz.write_entry(&sw, "x", text, sevenz.Entry_Options{method = method}) == archive.General_Error.Unsupported_Method, "%v", method)
	}
	testing.expect_value(t, sevenz.write_entry(&sw, archive.File_Info{path = "p", type = .Named_Pipe}), archive.General_Error.Unsupported_Entry)
	testing.expect_value(t, sevenz.write_entry(&sw, archive.File_Info{path = "h", type = .Hard_Link}), archive.General_Error.Unsupported_Entry)
	testing.expect_value(t, sevenz.write_entry(&sw, archive.File_Info{path = "d", type = .Directory}, text), archive.General_Error.Incompatible_Options)
	testing.expect_value(t, sevenz.write_entry(&sw, archive.File_Info{path = "l", type = .Symlink}), archive.General_Error.Incompatible_Options)
	long_target := strings.repeat("t", 4097, context.temp_allocator)
	testing.expect_value(t, sevenz.write_entry(&sw, archive.File_Info{path = "l", type = .Symlink, link_target = long_target}), archive.General_Error.Limit_Exceeded)
	bad_lzma := lzma.level_options(.Default)
	bad_lzma.lc = 4
	bad_lzma.lp = 1
	testing.expect_value(t, sevenz.write_entry(&sw, "x", text, sevenz.Entry_Options{lzma = bad_lzma}), archive.General_Error.Incompatible_Options)
	testing.expect_value(t, sevenz.write_entry(&sw, "x", text, sevenz.Entry_Options{method = .LZMA, lzma = bad_lzma}), nil)
	testing.expect_value(t, sevenz.write_entry(&sw, "x", text, sevenz.Entry_Options{method = .PPMd_H, ppmd = ppmd.Properties{variant = .I, order = 6, mem_size = 1 << 24}}), archive.General_Error.Incompatible_Options)
	testing.expect_value(t, sevenz.write_entry(&sw, "x", text, sevenz.Entry_Options{method = .PPMd_H, ppmd = ppmd.Properties{variant = .H, order = 1, mem_size = 1 << 24}}), archive.General_Error.Incompatible_Options)
	testing.expect_value(t, sevenz.write_entry(&sw, "x", text, sevenz.Entry_Options{filter = .Delta, delta_distance = 257}), archive.General_Error.Incompatible_Options)
	testing.expect_value(t, sevenz.write_entry(&sw, "x", text, sevenz.Entry_Options{filter = sevenz.Filter_Choice(99)}), archive.General_Error.Incompatible_Options)

	short: bytes.Reader
	bytes.reader_init(&short, text[:5])
	testing.expect_value(t, sevenz.write_entry(&sw, archive.File_Info{path = "short", size = 10}, bytes.reader_to_stream(&short)), SevenZ_Error.Size_Mismatch)
	long: bytes.Reader
	bytes.reader_init(&long, text)
	testing.expect_value(t, sevenz.write_entry(&sw, archive.File_Info{path = "long", size = 10}, bytes.reader_to_stream(&long)), SevenZ_Error.Size_Mismatch)
	none: bytes.Reader
	bytes.reader_init(&none, nil)
	testing.expect_value(t, sevenz.write_entry(&sw, archive.File_Info{path = "none", size = 10}, bytes.reader_to_stream(&none)), SevenZ_Error.Size_Mismatch)
	testing.expect_value(t, sevenz.write_entry(&sw, "ok.txt", text), nil)

	huge: bytes.Reader
	bytes.reader_init(&huge, text[:5])
	testing.expect_value(t, sevenz.write_entry(&sw, archive.File_Info{path = "huge", size = 32 << 20}, bytes.reader_to_stream(&huge), sevenz.Entry_Options{method = .Store}), SevenZ_Error.Size_Mismatch)
	testing.expect_value(t, sevenz.write_entry(&sw, "after.txt", text), SevenZ_Error.Size_Mismatch)
	testing.expect_value(t, sevenz.commit(&sw), SevenZ_Error.Size_Mismatch)

	bad: sevenz.Writer
	other := Memory_File{seekable = true}
	defer delete(other.data)
	testing.expect_value(t, sevenz.create(&bad, memory_stream(&other), sevenz.Writer_Options{method = .Implode}), archive.General_Error.Unsupported_Method)
	testing.expect_value(t, sevenz.create(&bad, memory_stream(&other), sevenz.Writer_Options{solid_size = -1}), archive.General_Error.Incompatible_Options)
	testing.expect_value(t, sevenz.create(&bad, memory_stream(&other), sevenz.Writer_Options{solid_order = sevenz.Solid_Order(7)}), archive.General_Error.Incompatible_Options)
	testing.expect_value(t, sevenz.create(&bad, memory_stream(&other), sevenz.Writer_Options{delta_distance = -1, filter = .Delta}), archive.General_Error.Incompatible_Options)
	pipe := Memory_File{}
	testing.expect_value(t, sevenz.create(&bad, memory_stream(&pipe)), archive.General_Error.Not_Seekable)
	testing.expect_value(t, len(pipe.data), 0)

	limited: sevenz.Writer
	small := sevenz.Writer_Options{method = .Store, filter = .BCJ2}
	small.options.max_memory = 64 << 10
	if testing.expect_value(t, sevenz.create(&limited, memory_stream(&other), small), nil) {
		big := write_random(32 << 10, 5)
		defer delete(big)
		testing.expect_value(t, sevenz.write_entry(&limited, "big", big), compress.Error(compress.General_Error.Memory_Limit_Exceeded))
		known: bytes.Reader
		bytes.reader_init(&known, big)
		testing.expect_value(t, sevenz.write_entry(&limited, archive.File_Info{path = "big", size = i64(len(big))}, bytes.reader_to_stream(&known)), compress.Error(compress.General_Error.Memory_Limit_Exceeded))
		testing.expect_value(t, known.i, i64(sevenz.SNIFF_SIZE))
		inner: bytes.Reader
		bytes.reader_init(&inner, big)
		unknown := Non_Seekable{inner = bytes.reader_to_stream(&inner)}
		testing.expect_value(t, sevenz.write_entry(&limited, archive.File_Info{path = "big", size = -1}, non_seekable_stream(&unknown)), compress.Error(compress.General_Error.Memory_Limit_Exceeded))
		testing.expect_value(t, sevenz.write_entry(&limited, "small", big[:1000]), nil)
		testing.expect_value(t, sevenz.commit(&limited), nil)
		sevenz.close(&limited)
		check_written(t, "bcj2 limit", other.data[:], {{name = "small", type = .Regular, content = big[:1000], method = .Store, filters = {.BCJ2}}})
	}

	tight := sevenz.Writer_Options{solid = true, filter = .BCJ2}
	tight.options.max_memory = 128 << 10
	tight_out := Memory_File{seekable = true}
	defer delete(tight_out.data)
	if testing.expect_value(t, sevenz.create(&limited, memory_stream(&tight_out), tight), nil) {
		testing.expect_value(t, sevenz.write_entry(&limited, "a", text[:1000]), compress.Error(compress.General_Error.Memory_Limit_Exceeded))
		testing.expect_value(t, limited.err, nil)
		testing.expect_value(t, sevenz.commit(&limited), nil)
		sevenz.close(&limited)
		check_written(t, "bcj2 coder limit", tight_out.data[:], {})
	}

	split := sevenz.Writer_Options{method = .Store, filter = .BCJ2, solid = true, solid_size = 1 << 20}
	split.options.max_memory = 64 << 10
	split_out := Memory_File{seekable = true}
	defer delete(split_out.data)
	if testing.expect_value(t, sevenz.create(&limited, memory_stream(&split_out), split), nil) {
		one := write_random(10 << 10, 6)
		defer delete(one)
		two := write_random(10 << 10, 7)
		defer delete(two)
		testing.expect_value(t, sevenz.write_entry(&limited, "one", one), nil)
		testing.expect_value(t, sevenz.write_entry(&limited, "two", two), nil)
		testing.expect_value(t, sevenz.commit(&limited), nil)
		sevenz.close(&limited)
		check_written(t, "bcj2 solid split", split_out.data[:], {
			{name = "one", type = .Regular, content = one, method = .Store, filters = {.BCJ2}},
			{name = "two", type = .Regular, content = two, method = .Store, filters = {.BCJ2}},
		})
	}

	done: sevenz.Writer
	final := Memory_File{seekable = true}
	defer delete(final.data)
	if testing.expect_value(t, sevenz.create(&done, memory_stream(&final)), nil) {
		testing.expect_value(t, sevenz.write_entry(&done, "a.txt", text), nil)
		testing.expect_value(t, sevenz.commit(&done), nil)
		testing.expect_value(t, sevenz.commit(&done), nil)
		testing.expect_value(t, sevenz.write_entry(&done, "b.txt", text), io.Error.Closed)
		sevenz.close(&done)
	}
	check_written(t, "after commit", final.data[:], {{name = "a.txt", type = .Regular, content = text, method = .LZMA2}})
}

@(test)
test_write_empty :: proc(t: ^testing.T) {
	m := Memory_File{seekable = true}
	defer delete(m.data)
	sw: sevenz.Writer
	if !testing.expect_value(t, sevenz.create(&sw, memory_stream(&m)), nil) {
		return
	}
	testing.expect_value(t, sevenz.commit(&sw), nil)
	sevenz.close(&sw)
	want, read_err := os.read_entire_file(asset("empty.7z"), context.allocator)
	if !testing.expect_value(t, read_err, nil) {
		return
	}
	defer delete(want)
	testing.expectf(t, bytes.equal(m.data[:], want), "empty archive %x", m.data[:])

	only := Memory_File{seekable = true}
	defer delete(only.data)
	if testing.expect_value(t, sevenz.create(&sw, memory_stream(&only)), nil) {
		testing.expect_value(t, sevenz.write_entry(&sw, archive.File_Info{path = "EMPTY.TXT"}, []u8{}), nil)
		testing.expect_value(t, sevenz.write_entry(&sw, archive.File_Info{path = "TREE", type = .Directory}), nil)
		testing.expect_value(t, sevenz.commit(&sw), nil)
		sevenz.close(&sw)
		check_written(t, "empty only", only.data[:], {
			{name = "EMPTY.TXT", type = .Regular},
			{name = "TREE",      type = .Directory},
		})
	}
}

@(test)
test_write_path :: proc(t: ^testing.T) {
	root, dir_err := os.make_directory_temp("", "odin_7z_writer_path_*", context.temp_allocator)
	if dir_err == .Unsupported {
		return
	}
	if !testing.expect_value(t, dir_err, nil) {
		return
	}
	defer os.remove_all(root)
	text := write_text()

	path, _ := os.join_path({root, "made.7z"}, context.temp_allocator)
	sw: sevenz.Writer
	if testing.expect_value(t, sevenz.create(&sw, path), nil) {
		testing.expect_value(t, sevenz.write_entry(&sw, "text.txt", text), nil)
		testing.expect_value(t, sevenz.commit(&sw), nil)
		sevenz.close(&sw)
		r: sevenz.Reader
		if testing.expect_value(t, sevenz.open(&r, path), nil) {
			fi, handle, ok, _ := sevenz.find(&r, "text.txt")
			testing.expect(t, ok && fi.size == i64(len(text)), "find text.txt")
			out := strings.builder_make()
			testing.expect_value(t, sevenz.extract(&r, handle, strings.to_writer(&out)), nil)
			testing.expect(t, strings.to_string(out) == string(text), "content of text.txt")
			strings.builder_destroy(&out)
			sevenz.close(&r)
		}
	}

	dropped, _ := os.join_path({root, "dropped.7z"}, context.temp_allocator)
	dropped_temp := strings.concatenate({dropped, "-temp"}, context.temp_allocator)
	if testing.expect_value(t, sevenz.create(&sw, dropped), nil) {
		testing.expect_value(t, sevenz.write_entry(&sw, "text.txt", text), nil)
		testing.expect(t, !os.exists(dropped), "no archive before the commit")
		testing.expect(t, os.exists(dropped_temp), "temp archive exists while writing")
		sevenz.close(&sw)
		testing.expect(t, !os.exists(dropped), "no archive after an uncommitted close")
		testing.expect(t, !os.exists(dropped_temp), "temp archive removed on close")
	}

	m := Memory_File{seekable = true}
	defer delete(m.data)
	stub := [123]u8{}
	for &b, i in stub {
		b = u8(i)
	}
	append(&m.data, ..stub[:])
	m.position = len(m.data)
	if testing.expect_value(t, sevenz.create(&sw, memory_stream(&m)), nil) {
		testing.expect_value(t, sevenz.write_entry(&sw, "text.txt", text), nil)
		testing.expect_value(t, sevenz.commit(&sw), nil)
		sevenz.close(&sw)
		testing.expect(t, bytes.equal(m.data[:123], stub[:]), "prefix kept")
		check_written(t, "prepended", m.data[123:], {{name = "text.txt", type = .Regular, content = text, method = .LZMA2}})
	}
}

@(test)
test_write_directory :: proc(t: ^testing.T) {
	root, dir_err := os.make_directory_temp("", "odin_7z_writer_dir_*", context.temp_allocator)
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
	exe := make_pe(0x8664, 8192)
	defer delete(exe)
	wav := make_wav(2, 16, 6000)
	defer delete(wav)

	deeper, _ := os.join_path({root, "sub", "deeper"}, context.temp_allocator)
	empty,  _ := os.join_path({root, "emptydir"}, context.temp_allocator)
	testing.expect_value(t, os.make_directory_all(deeper), nil)
	testing.expect_value(t, os.make_directory(empty), nil)
	Planted :: struct {
		parts: []string,
		data:  []u8,
	}
	planted := [?]Planted{
		{{"z.txt"}, transmute([]u8)string("alpha")},
		{{"a.exe"}, exe},
		{{"sub", "b.txt"}, text},
		{{"sub", "tone.wav"}, wav},
		{{"sub", "deeper", "c.bin"}, random},
		{{"sub", "deeper", "d.c"}, text[:100]},
		{{"zero.txt"}, nil},
	}
	for p in planted {
		parts := make([dynamic]string, context.temp_allocator)
		append(&parts, root)
		append(&parts, ..p.parts)
		full, _ := os.join_path(parts[:], context.temp_allocator)
		testing.expect_value(t, os.write_entire_file(full, p.data), nil)
	}
	links := false
	when ODIN_OS != .Windows {
		link, _ := os.join_path({root, "link"}, context.temp_allocator)
		testing.expect_value(t, os.symlink("z.txt", link), nil)
		links = true
	}

	Dir_Expect :: struct {
		options: sevenz.Writer_Options,
		order:   []string,
	}
	name_order := []string{
		"pre", "pre/emptydir", "pre/sub", "pre/sub/deeper", "pre/zero.txt",
		"pre/link", "pre/sub/b.txt", "pre/sub/deeper/c.bin", "pre/sub/deeper/d.c", "pre/z.txt",
		"pre/sub/tone.wav",
		"pre/a.exe",
	}
	ext_order := []string{
		"pre", "pre/emptydir", "pre/sub", "pre/sub/deeper", "pre/zero.txt",
		"pre/link", "pre/sub/deeper/c.bin", "pre/sub/deeper/d.c", "pre/sub/b.txt", "pre/z.txt",
		"pre/sub/tone.wav",
		"pre/a.exe",
	}
	plain_order := []string{
		"pre", "pre/a.exe", "pre/emptydir", "pre/link", "pre/sub", "pre/sub/b.txt", "pre/sub/deeper",
		"pre/sub/deeper/c.bin", "pre/sub/deeper/d.c", "pre/sub/tone.wav", "pre/z.txt", "pre/zero.txt",
	}
	cases := [?]Dir_Expect{
		{{solid = true, deterministic = true}, name_order},
		{{solid = true, deterministic = true, solid_order = .Extension}, ext_order},
		{{deterministic = true}, plain_order},
	}
	for c, index in cases {
		outputs: [2]Memory_File
		defer for &o in outputs {
			delete(o.data)
		}
		for &o in outputs {
			o.seekable = true
			sw: sevenz.Writer
			if !testing.expect_value(t, sevenz.create(&sw, memory_stream(&o), c.options), nil) {
				return
			}
			testing.expect_value(t, sevenz.write_directory(&sw, root, "pre/"), nil)
			testing.expect_value(t, sevenz.commit(&sw), nil)
			sevenz.close(&sw)
		}
		testing.expectf(t, bytes.equal(outputs[0].data[:], outputs[1].data[:]), "case %d: deterministic directory outputs differ", index)
		r: sevenz.Reader
		if !testing.expect_value(t, sevenz.open(&r, outputs[0].data[:]), nil) {
			continue
		}
		it := sevenz.iterator_create(&r)
		k := 0
		for fi in sevenz.iterate(&it) {
			for !links && k < len(c.order) && c.order[k] == "pre/link" {
				k += 1
			}
			if testing.expectf(t, k < len(c.order), "case %d: extra %q", index, fi.path) {
				testing.expectf(t, fi.path == c.order[k], "case %d: entry %d is %q, want %q", index, k, fi.path, c.order[k])
			}
			k += 1
			switch fi.path {
			case "pre/a.exe":
				testing.expectf(t, fi.filters == {.BCJ2}, "case %d: a.exe filters %v", index, fi.filters)
			case "pre/sub/tone.wav":
				testing.expectf(t, fi.filters == {.Delta}, "case %d: tone.wav filters %v", index, fi.filters)
			case "pre/link":
				target, link_err := sevenz.read_link(&it)
				testing.expectf(t, link_err == nil && target == "z.txt", "case %d: link %q %v", index, target, link_err)
				delete(target)
			case "pre/sub/deeper/c.bin":
				content, err := extract_to_bytes(&it)
				testing.expectf(t, err == nil && bytes.equal(content[:], random), "case %d: c.bin %v", index, err)
				delete(content)
			}
		}
		sevenz.iterator_destroy(&it)
		if c.options.solid {
			testing.expectf(t, len(r.streams.folders) == 3, "case %d: %d folders", index, len(r.streams.folders))
		}
		sevenz.close(&r)
	}

	walked := Memory_File{seekable = true}
	defer delete(walked.data)
	sw: sevenz.Writer
	if testing.expect_value(t, sevenz.create(&sw, memory_stream(&walked)), nil) {
		testing.expect_value(t, sevenz.write_directory(&sw, root), nil)
		testing.expect_value(t, sevenz.commit(&sw), nil)
		sevenz.close(&sw)
		r: sevenz.Reader
		if testing.expect_value(t, sevenz.open(&r, walked.data[:]), nil) {
			testing.expect_value(t, sevenz.info(&r).member_count, len(plain_order) - 1 - (0 if links else 1))
			for want in plain_order[1:] {
				if want == "pre/link" && !links {
					continue
				}
				_, _, ok, _ := sevenz.find(&r, want[len("pre/"):])
				testing.expectf(t, ok, "walked: %s missing", want)
			}
			sevenz.close(&r)
		}
	}
}

@(test)
test_write_progress :: proc(t: ^testing.T) {
	text := write_text()
	log: Progress_Log
	defer delete(log.calls)
	m := Memory_File{seekable = true}
	defer delete(m.data)
	options: sevenz.Writer_Options
	options.options.progress          = progress_keep
	options.options.progress_data     = &log
	options.options.progress_interval = 1024
	sw: sevenz.Writer
	if !testing.expect_value(t, sevenz.create(&sw, memory_stream(&m), options), nil) {
		return
	}
	testing.expect_value(t, sevenz.write_entry(&sw, "a.txt", text), nil)
	testing.expect_value(t, sevenz.write_entry(&sw, archive.File_Info{path = "dir", type = .Directory}), nil)
	inner: bytes.Reader
	bytes.reader_init(&inner, text)
	unknown := Non_Seekable{inner = bytes.reader_to_stream(&inner)}
	testing.expect_value(t, sevenz.write_entry(&sw, archive.File_Info{path = "b.txt", size = -1}, non_seekable_stream(&unknown)), nil)
	testing.expect_value(t, sevenz.commit(&sw), nil)
	sevenz.close(&sw)

	size := i64(len(text))
	lasts: [3]compress.Progress
	last_archive := i64(0)
	for p in log.calls {
		testing.expectf(t, p.archive_in >= last_archive, "archive_in went back: %d after %d", p.archive_in, last_archive)
		last_archive = p.archive_in
		if testing.expectf(t, p.member_index >= 0 && p.member_index < len(lasts), "member index %d", p.member_index) {
			lasts[p.member_index] = p
		}
	}
	Final :: struct {
		member:     string,
		bytes_in:   i64,
		archive_in: i64,
		packed:     bool,
	}
	finals := [3]Final{{"a.txt", size, size, true}, {"dir", 0, size, false}, {"b.txt", size, 2 * size, true}}
	for f, i in finals {
		p := lasts[i]
		testing.expectf(t, p.member == f.member, "final %d: member %q", i, p.member)
		testing.expectf(t, p.bytes_in == f.bytes_in && p.total_in == f.bytes_in, "%s: %d of %d", f.member, p.bytes_in, p.total_in)
		testing.expectf(t, p.archive_in == f.archive_in, "%s: archive_in %d", f.member, p.archive_in)
		testing.expectf(t, (p.bytes_out > 0 && p.bytes_out < size) == f.packed, "%s: bytes_out %d", f.member, p.bytes_out)
	}
	testing.expectf(t, len(log.calls) > 3, "%d progress calls", len(log.calls))

	canceled := Progress_Log{cancel_at = 1}
	defer delete(canceled.calls)
	options.options.progress_data = &canceled
	other := Memory_File{seekable = true}
	defer delete(other.data)
	if testing.expect_value(t, sevenz.create(&sw, memory_stream(&other), options), nil) {
		want := compress.Error(compress.General_Error.Canceled)
		testing.expect_value(t, sevenz.write_entry(&sw, "a.txt", text), want)
		testing.expect_value(t, sevenz.write_entry(&sw, "b.txt", text), want)
		testing.expect_value(t, sevenz.commit(&sw), want)
		sevenz.close(&sw)
	}
}

progress_keep :: proc(progress: compress.Progress, user_data: rawptr) -> (cancel: bool) {
	kept := progress
	kept.member = strings.clone(progress.member, context.temp_allocator)
	return progress_record(kept, user_data)
}

check_written :: proc(t: ^testing.T, label: string, data: []u8, expected: []Write_Expect, password := "") {
	r: sevenz.Reader
	if open_err := sevenz.open(&r, data, compress.Options{}, context.allocator, archive.Read_Options{password = password}); !testing.expectf(t, open_err == nil, "%s: open %v", label, open_err) {
		return
	}
	defer sevenz.close(&r)
	check_entries(t, label, &r, expected)
}

check_entries :: proc(t: ^testing.T, label: string, r: ^sevenz.Reader, expected: []Write_Expect) {
	it := sevenz.iterator_create(r)
	defer sevenz.iterator_destroy(&it)
	count := 0
	for fi, index in sevenz.iterate(&it) {
		count += 1
		if !testing.expectf(t, index < len(expected), "%s: extra entry %q", label, fi.path) {
			continue
		}
		want := expected[index]
		testing.expectf(t, fi.path == want.name, "%s: entry %d is %q, want %q", label, index, fi.path, want.name)
		testing.expectf(t, fi.type == want.type, "%s/%s: type %v", label, want.name, fi.type)
		testing.expectf(t, fi.size == i64(len(want.content)), "%s/%s: size %d", label, want.name, fi.size)
		if want.method != .Unknown {
			testing.expectf(t, fi.method == want.method, "%s/%s: method %v", label, want.name, fi.method)
		}
		testing.expectf(t, fi.filters == want.filters, "%s/%s: filters %v, want %v", label, want.name, fi.filters, want.filters)
		testing.expectf(t, fi.encrypted == want.encrypted, "%s/%s: encrypted %v", label, want.name, fi.encrypted)
		if want.mode != 0 {
			testing.expectf(t, fi.unix_mode == want.mode, "%s/%s: mode %o", label, want.name, fi.unix_mode)
		}
		if want.dos != 0 {
			testing.expectf(t, fi.dos_attributes == want.dos, "%s/%s: attributes %x", label, want.name, fi.dos_attributes)
		}
		switch want.type {
		case .Regular:
			content, err := extract_to_bytes(&it)
			testing.expectf(t, err == nil && bytes.equal(content[:], want.content), "%s/%s: content %v", label, want.name, err)
			delete(content)
		case .Symlink:
			target, link_err := sevenz.read_link(&it)
			testing.expectf(t, link_err == nil && target == want.link, "%s/%s: link %q %v", label, want.name, target, link_err)
			delete(target)
		case .Unknown, .Directory, .Hard_Link, .Named_Pipe, .Character_Device, .Block_Device, .Anti:
		}
	}
	_, it_err := sevenz.iterator_error(&it)
	testing.expectf(t, it_err == nil, "%s: iterator %v", label, it_err)
	testing.expectf(t, count == len(expected), "%s: %d entries, want %d", label, count, len(expected))
}

count_folders :: proc(data: []u8, password := "") -> int {
	r: sevenz.Reader
	if sevenz.open(&r, data, compress.Options{}, context.allocator, archive.Read_Options{password = password}) != nil {
		return -1
	}
	defer sevenz.close(&r)
	return len(r.streams.folders)
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

set_u16 :: proc(b: []u8, pos: int, v: u16, be := false) {
	if be {
		b[pos], b[pos + 1] = u8(v >> 8), u8(v)
	} else {
		b[pos], b[pos + 1] = u8(v), u8(v >> 8)
	}
}

set_u32 :: proc(b: []u8, pos: int, v: u32, be := false) {
	for i in 0..<4 {
		shift := uint(8 * (3 - i)) if be else uint(8 * i)
		b[pos + i] = u8(v >> shift)
	}
}

make_pe :: proc(machine: u16, size: int) -> (b: []u8) {
	b = write_random(size, u64(machine))
	if size < 0x100 {
		return
	}
	b[0], b[1] = 'M', 'Z'
	set_u32(b, 0x3C, 0x80)
	set_u32(b, 0x80, 0x00004550)
	set_u16(b, 0x84, machine)
	set_u16(b, 0x86, 0)
	set_u16(b, 0x94, 0xF0)
	set_u16(b, 0x98, 0x20B)
	return
}

make_elf :: proc(machine: u16, be: bool, size: int) -> (b: []u8) {
	b = write_random(size, u64(machine) + 1000)
	set_u32(b, 0, 0x464C457F)
	b[4] = 2
	b[5] = 2 if be else 1
	b[6] = 1
	set_u16(b, 0x12, machine, be)
	return
}

make_macho :: proc(cpu: u32, size: int) -> (b: []u8) {
	b = write_random(size, u64(cpu))
	set_u32(b, 0, 0xFEEDFACF)
	set_u32(b, 4, cpu)
	set_u32(b, 0x10, 4)
	set_u32(b, 0x14, 0x400)
	return
}

make_wav :: proc(channels, bits: u16, size: int) -> (b: []u8) {
	b = write_random(size, u64(channels) << 8 | u64(bits))
	set_u32(b, 0, 0x46464952)
	set_u32(b, 4, u32(size - 8))
	set_u32(b, 8, 0x45564157)
	set_u32(b, 0xC, 0x20746D66)
	set_u32(b, 0x10, 16)
	set_u16(b, 0x14, 1)
	set_u16(b, 0x16, channels)
	set_u32(b, 0x18, 44_100)
	set_u32(b, 0x1C, 44_100 * u32(channels) * u32(bits / 8))
	set_u16(b, 0x20, channels * (bits / 8))
	set_u16(b, 0x22, bits)
	set_u32(b, 0x24, 0x61746164)
	set_u32(b, 0x28, u32(size - 0x2C))
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
