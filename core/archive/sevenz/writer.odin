package archive_sevenz

import "base:runtime"
import "core:archive"
import "core:compress"
import "core:compress/bzip2"
import "core:compress/deflate"
import "core:compress/filters"
import "core:compress/lzma"
import "core:compress/ppmd"
import "core:crypto"
import "core:hash"
import "core:io"
import "core:strings"
import "core:time"
import "core:unicode/utf8"

/*
Starts a new 7z archive on a stream

*Allocates Using Provided Allocator*

Inputs:
- sw: The writer; `close` it when done, it is left closed on an error
- s: Where the archive goes, from its current position; it must seek, as `commit` writes the
  start header last
- options: The default method, level, filter and password, solid blocks, and more (default: {})
- allocator: (default: context.allocator)

Returns:
- err: `General_Error.Incompatible_Options` or `General_Error.Unsupported_Method` for bad
  options, `General_Error.Not_Seekable`, `io.Error.Unsupported` if `s` can't write, or `nil`
*/
create_from_stream :: proc(sw: ^Writer, s: io.Stream, options: Writer_Options = {}, allocator := context.allocator) -> (err: Error) {
	sw^ = {}
	sw.allocator = allocator
	_check_writer_options(options) or_return
	if err = _writer_init(sw, s, options); err != nil {
		close_writer(sw)
	}
	return
}

/*
Adds a member described by a `File_Info`

An error after part of the member was written stops the writer: later calls return it.

Inputs:
- sw: An open writer
- fi: The member's path, type and metadata; a regular file, a directory or a symlink. `size` may
  be -1 for a reader of unknown size
- data: A regular file's data, as bytes or a reader; `nil` for other types (default: nil)
- options: This member's method, level, filter and password, in place of the writer's, and
  whether it replaces the members an archive being updated has at its path (default: {})

Returns:
- err: `General_Error.Unsupported_Entry`, `General_Error.Incompatible_Options` for data on a
  non-file or for replacing a member in an update on a stream, `General_Error.Exists` for a path
  an update already holds, unless `replace` is set and the archive held it when opened,
  `SevenZ_Error.Size_Mismatch` if the reader doesn't give `fi.size` bytes, or `nil`
*/
write_entry_with_info :: proc(sw: ^Writer, fi: archive.File_Info, data: Entry_Data = nil, options: Entry_Options = {}) -> (err: Error) {
	return _write_entry(sw, fi, data, options, nil)
}

/*
Adds a regular file, stamped with the current time

Inputs:
- sw: An open writer
- name: The member's path
- data: The file's data, as bytes or a reader (default: nil)
- options: This member's method, level, filter and password, in place of the writer's
  (default: {})

Returns:
- err: As `write_entry_with_info`
*/
write_entry_simple :: proc(sw: ^Writer, name: string, data: Entry_Data = nil, options: Entry_Options = {}) -> (err: Error) {
	fi: archive.File_Info
	fi.path              = name
	fi.type              = .Regular
	fi.modification_time = time.now()
	switch d in data {
	case []u8:
		fi.size = i64(len(d))
	case io.Reader:
		fi.size = -1
		if size, size_err := io.size(d); size_err == nil && size >= 0 {
			fi.size = size
		}
	}
	return write_entry_with_info(sw, fi, data, options)
}

// Adds a member described by a `File_Info`, or a regular file by name
write_entry :: proc{write_entry_with_info, write_entry_simple}

/*
Finishes the archive: writes the header and, at a path, puts the archive in place

Committing again does nothing. Afterwards, only `close` is left to call.

Inputs:
- sw: An open writer

Returns:
- err: The error that stopped the writer earlier, the commit's own error, or `nil`
*/
commit :: proc(sw: ^Writer) -> (err: Error) {
	if sw.committed {
		return nil
	}
	_writer_ready(sw) or_return
	defer if err != nil {
		sw.err = err
	}
	switch sw.mode {
	case .Stream:
		_commit_archive(sw) or_return
	case .Create_Path:
		_commit_archive(sw) or_return
		archive._disk_publish(&sw.disk) or_return
	case .Update_Stream, .Update_Path:
		_commit_update(sw) or_return
	}
	sw.committed = true
	return nil
}

/*
Closes a writer and frees its memory

Without `commit`, an update is rolled back and a new archive at a path is discarded; a new
archive on a stream is left unfinished.

Inputs:
- sw: The writer; a stream given to `create_from_stream` or `update_from_stream` is left open
*/
close_writer :: proc(sw: ^Writer) {
	if sw.active && !sw.committed {
		_restore_original(sw)
	}
	archive._disk_close(&sw.disk)
	if sw.mode == .Update_Path || sw.mode == .Update_Stream {
		close_reader(&sw.old)
	}
	for slot in sw.slots {
		delete(slot.raw_name, sw.allocator)
	}
	delete(sw.slots)
	delete(sw.heads)
	delete(sw.kept)
	archive._ranges_delete(sw.saved, sw.allocator)
	_folder_destroy(sw)
	_key_cache_destroy(&sw.keys)
	archive._secret_delete(transmute([]u8)sw.password, sw.allocator)
	delete(sw.folder.call.data)
	delete(sw.folder.jump.data)
	delete(sw.folder.rc.data)
	delete(sw.pack_sizes)
	delete(sw.folders)
	delete(sw.ciphers)
	delete(sw.cipher_buffer, sw.allocator)
	delete(sw.files)
	delete(sw.names)
	delete(sw.name)
	delete(sw.header)
	delete(sw.chunk, sw.allocator)
	delete(sw.head, sw.allocator)
	delete(sw.filter_buffer, sw.allocator)
	sw^ = {}
}

@(private)
_commit_archive :: proc(sw: ^Writer) -> (err: Error) {
	if sw.folder.active {
		_folder_close(sw) or_return
	}
	start := _write_header(sw, sw.files[:], sw.names[:]) or_return
	end := sw.offset
	_seek(sw, sw.start) or_return
	_emit(sw, start[:]) or_return
	_seek(sw, end) or_return
	return _flush(sw)
}

@(private)
_write_header :: proc(sw: ^Writer, files: []Out_File, names: []u8) -> (start: [SIGNATURE_HEADER_SIZE]u8, err: Error) {
	next_offset, next_size: i64
	next_crc: u32
	if len(files) > 0 {
		_build_header(sw, files, names) or_return
		if !sw.options.plain_header || _header_encrypted(sw) {
			_encode_header(sw) or_return
		}
		next_offset = sw.offset - sw.start - SIGNATURE_HEADER_SIZE
		next_size   = i64(len(sw.header))
		next_crc    = hash.crc32(sw.header[:])
		_emit(sw, sw.header[:]) or_return
	}
	return _start_header(next_offset, next_size, next_crc), nil
}

/*
Returns the LZMA settings 7-Zip uses for a level, for `Writer_Options.lzma`

Inputs:
- level: The level, clamped to 0 through 9

Returns:
- options: 7-Zip's dictionary size, match finder and match lengths for the level
*/
lzma_options_7zip :: proc "contextless" (level: int) -> (options: lzma.Options) {
	l := clamp(level, 0, 9)
	options.lc = 3
	options.lp = 0
	options.pb = 2
	switch {
	case l <= 4:
		options.dict_size = 1 << uint(2 * l + 16)
	case l <= size_of(uintptr) / 2 + 4:
		options.dict_size = 1 << uint(l + 20)
	case:
		options.dict_size = 1 << uint(size_of(uintptr) / 2 + 24)
	}
	options.fast         = l < 5
	options.match_finder = .HC5 if l < 5 else .BT4
	options.nice_len     = 32 if l < 7 else 64
	options.depth        = (16 + options.nice_len / 2) >> (1 if options.fast else 0)
	return
}

@(private)
_writer_init :: proc(sw: ^Writer, s: io.Stream, options: Writer_Options) -> (err: Error) {
	_writer_setup(sw, s, options) or_return
	placeholder: [SIGNATURE_HEADER_SIZE]u8
	signature := SIGNATURE
	copy(placeholder[:], signature[:])
	placeholder[6] = VERSION_MAJOR
	placeholder[7] = VERSION_MINOR
	_emit(sw, placeholder[:]) or_return
	sw.active = true
	return nil
}

@(private)
_writer_setup :: proc(sw: ^Writer, s: io.Stream, options: Writer_Options) -> (err: Error) {
	sw.kept.allocator         = sw.allocator
	sw.slots.allocator        = sw.allocator
	sw.heads                  = make(map[string]int, sw.allocator)
	sw.pack_sizes.allocator   = sw.allocator
	sw.folders.allocator      = sw.allocator
	sw.files.allocator        = sw.allocator
	sw.names.allocator        = sw.allocator
	sw.name.allocator         = sw.allocator
	sw.header.allocator       = sw.allocator
	sw.folder.call.data.allocator  = sw.allocator
	sw.folder.jump.data.allocator  = sw.allocator
	sw.folder.rc.data.allocator    = sw.allocator
	sw.ciphers.allocator      = sw.allocator
	sw.keys.allocator         = sw.allocator
	sw.options = options
	sw.options.password = ""
	sw.kdf_power = options.kdf_power if options.kdf_power != 0 else AES_POWER_DEFAULT
	sw.password  = archive._secret_clone(options.password, sw.allocator) or_return

	modes := io.query(s)
	if .Write not_in modes {
		return io.Error.Unsupported
	}
	if .Seek not_in modes {
		return archive.General_Error.Not_Seekable
	}
	position, seek_err := io.seek(s, 0, .Current)
	if seek_err != nil || position < 0 {
		return archive.General_Error.Not_Seekable
	}
	sw.stream = s
	sw.start  = position
	sw.offset = position
	sw.end    = position
	return nil
}

@(private)
_check_writer_options :: proc(options: Writer_Options) -> (err: Error) {
	o := options.options
	if o.progress_interval < 0 || o.max_memory < 0 || o.max_output_size < 0 || o.chunk_size < 0 {
		return archive.General_Error.Incompatible_Options
	}
	if options.solid_size < 0 || options.solid_files < 0 || options.solid_order > .Extension {
		return archive.General_Error.Incompatible_Options
	}
	if options.kdf_power < 0 || options.kdf_power > AES_POWER_MAX {
		return archive.General_Error.Incompatible_Options
	}
	archive._check_password(options.password, options.deterministic) or_return
	_ = _resolve(options, {}) or_return
	return nil
}

@(private)
_writer_ready :: proc(sw: ^Writer) -> (err: Error) {
	if !sw.active || sw.committed {
		return io.Error.Closed
	}
	return sw.err
}

@(private)
_default_level :: proc "contextless" (method: archive.Method) -> (level: int) {
	#partial switch method {
	case .LZMA, .LZMA2:        level = int(lzma.Level.Default)
	case .PPMd_H:              level = int(ppmd.Level.Default)
	case .BZip2:               level = int(bzip2.Level.Default)
	case .Deflate, .Deflate64: level = int(deflate.Deflate_Level.Default)
	}
	return
}

@(private)
_resolve :: proc(defaults: Writer_Options, entry: Entry_Options) -> (setup: Coder_Setup, err: Error) {
	chosen    := defaults.method if defaults.method != .Unknown else .LZMA2
	wanted    := entry.method if entry.method != .Unknown else chosen
	inherit   := wanted == chosen
	requested := entry.level
	if requested == nil && inherit {
		requested = defaults.level
	}
	setup.method = wanted
	#partial switch wanted {
	case .Store:
	case .LZMA, .LZMA2:
		setup.level = clamp(requested.? or_else _default_level(wanted), int(lzma.Level.Level_0), int(lzma.Level.Level_9))
		switch {
		case entry.lzma != nil:
			setup.lzma     = entry.lzma.?
			setup.lzma_set = true
		case entry.level == nil && inherit && defaults.lzma != nil:
			setup.lzma     = defaults.lzma.?
			setup.lzma_set = true
		case:
			setup.lzma = lzma.level_options(lzma.Level(setup.level))
		}
		setup.lzma.end_marker = false
		l := setup.lzma
		if l.lc > lzma.LC_MAX || l.lp > lzma.LP_MAX || l.pb > lzma.PB_MAX || l.match_finder > .BT5 {
			return {}, archive.General_Error.Incompatible_Options
		}
		if wanted == .LZMA2 && l.lc + l.lp > lzma.LZMA2_LCLP_MAX {
			return {}, archive.General_Error.Incompatible_Options
		}
	case .PPMd_H:
		setup.level = clamp(requested.? or_else _default_level(wanted), int(ppmd.Level.Level_0), int(ppmd.Level.Level_9))
		switch {
		case entry.ppmd != nil:
			setup.ppmd     = entry.ppmd.?
			setup.ppmd_set = true
		case entry.level == nil && inherit && defaults.ppmd != nil:
			setup.ppmd     = defaults.ppmd.?
			setup.ppmd_set = true
		case:
			setup.ppmd = ppmd.level_properties(.H, ppmd.Level(setup.level))
		}
		if setup.ppmd.variant != .H {
			return {}, archive.General_Error.Incompatible_Options
		}
		if _, perr := ppmd.encode_properties_7z(setup.ppmd); perr != nil {
			return {}, archive.General_Error.Incompatible_Options
		}
	case .BZip2:
		setup.level = clamp(requested.? or_else _default_level(wanted), int(bzip2.Level.Level_1), int(bzip2.Level.Level_9))
	case .Deflate, .Deflate64:
		setup.level = clamp(requested.? or_else _default_level(wanted), int(deflate.Deflate_Level.Stored), int(deflate.Deflate_Level.Best))
	case:
		return {}, archive.General_Error.Unsupported_Method
	}
	setup.filter = defaults.filter
	setup.delta  = defaults.delta_distance
	if entry.filter != .Auto {
		setup.filter = entry.filter
		setup.delta  = entry.delta_distance
	}
	if setup.filter > .Swap4 || setup.delta < 0 || setup.delta > filters.DELTA_DISTANCE_MAX {
		return {}, archive.General_Error.Incompatible_Options
	}
	return
}

@(private)
_write_entry :: proc(sw: ^Writer, fi: archive.File_Info, data: Entry_Data, options: Entry_Options, preset: ^Filter_Pick) -> (err: Error) {
	_writer_ready(sw) or_return
	type := archive.Entry_Type.Regular if fi.type == .Unknown else fi.type
	#partial switch type {
	case .Regular, .Directory, .Symlink:
	case:
		return archive.General_Error.Unsupported_Entry
	}
	setup    := _resolve(sw.options, options) or_return
	password := archive._entry_password(options.password, sw.password, sw.options.deterministic) or_return
	_entry_name(sw, fi.path) or_return
	_name_check(sw, options.replace) or_return

	file: Out_File
	file.is_directory = type == .Directory
	file.attributes   = _attributes(fi, type)
	if !sw.options.deterministic {
		file.modification_time = _filetime(fi.modification_time)
		if sw.options.creation_time {
			file.creation_time = _filetime(fi.creation_time)
		}
		if sw.options.access_time {
			file.access_time = _filetime(fi.access_time)
		}
	}

	source:   Source
	expected: i64
	switch d in data {
	case []u8:
		if type != .Regular && len(d) > 0 {
			return archive.General_Error.Incompatible_Options
		}
		source.data = d
		expected    = i64(len(d))
	case io.Reader:
		if type != .Regular {
			return archive.General_Error.Incompatible_Options
		}
		source.reader = d
		expected      = fi.size
		if expected < 0 {
			expected = -1
			if size, size_err := io.size(d); size_err == nil && size >= 0 {
				expected = size
			}
		}
	}
	if type == .Symlink {
		if len(fi.link_target) == 0 {
			return archive.General_Error.Incompatible_Options
		}
		if len(fi.link_target) > archive.LINK_TARGET_MAX {
			return archive.General_Error.Limit_Exceeded
		}
		source   = {data = transmute([]u8)fi.link_target}
		expected = i64(len(fi.link_target))
	}
	if type == .Directory {
		_add_file(sw, file) or_return
		if err = _entry_done(sw, &file, 0); err != nil {
			sw.err = err
		}
		return
	}
	head := _read_head(sw, &source) or_return
	if len(head) == 0 {
		if expected > 0 {
			return SevenZ_Error.Size_Mismatch
		}
		_add_file(sw, file) or_return
		if err = _entry_done(sw, &file, 0); err != nil {
			sw.err = err
		}
		return
	}
	if expected == 0 || expected > 0 && i64(len(head)) > expected {
		return SevenZ_Error.Size_Mismatch
	}

	pick: Filter_Pick
	switch {
	case type == .Symlink:
		pick = {filter = .None}
	case preset != nil:
		pick = preset^
	case:
		pick = _pick_filter(sw, setup, head, expected)
	}
	_apply_pick(&setup, pick)
	if setup.filter == .BCJ2 && expected > _bcj2_cap(sw) {
		return compress.Error(compress.General_Error.Memory_Limit_Exceeded)
	}

	key: [AES_KEY_SIZE]u8
	defer crypto.zero_explicit(&key, size_of(key))
	keyed: ^[AES_KEY_SIZE]u8
	if password != "" {
		_writer_key(sw, password, &key) or_return
		keyed = &key
	}
	if sw.folder.active && !_folder_accepts(sw, setup, expected, keyed) {
		if err = _folder_close(sw); err != nil {
			sw.err = err
			return
		}
	}
	fresh     := !sw.folder.active
	out_start := sw.offset
	files     := len(sw.files)
	if fresh {
		_folder_open(sw, setup, expected, keyed) or_return
	}
	err = _folder_feed(sw, &source, head, expected, &file, out_start)
	if err == nil {
		err = _add_file(sw, file)
	}
	if err == nil && (!sw.options.solid || sw.folder.unpack >= sw.folder.limit || sw.folder.broken) {
		err = _folder_close(sw)
	}
	if err == nil {
		err = _entry_done(sw, &file, sw.offset - out_start)
	}
	if err != nil {
		if fresh && sw.offset == out_start && len(sw.files) == files {
			_folder_destroy(sw)
		} else {
			sw.err = err
		}
	}
	return
}

@(private)
_entry_name :: proc(sw: ^Writer, path: string) -> (err: Error) {
	clear(&sw.name)
	name := path
	when ODIN_OS == .Windows {
		if len(name) >= 2 && name[1] == ':' {
			name = name[2:]
		}
	}
	append(&sw.name, name) or_return
	when ODIN_OS == .Windows {
		for &c in sw.name {
			if c == '\\' {
				c = '/'
			}
		}
	}
	start := 0
	for start < len(sw.name) {
		if sw.name[start] == '/' {
			start += 1
		} else if sw.name[start] == '.' && start + 1 < len(sw.name) && sw.name[start + 1] == '/' {
			start += 2
		} else {
			break
		}
	}
	stop := len(sw.name)
	for stop > start && sw.name[stop - 1] == '/' {
		stop -= 1
	}
	cleaned := string(sw.name[start:stop])
	if cleaned == "" || cleaned == "." || strings.index_byte(cleaned, 0) >= 0 {
		return SevenZ_Error.Invalid_Name
	}
	rest := cleaned
	for part in strings.split_iterator(&rest, "/") {
		if part == ".." {
			return archive.General_Error.Unsafe_Path
		}
	}
	n := copy(sw.name[:], sw.name[start:stop])
	resize(&sw.name, n)
	return nil
}

@(private)
_pick_filter :: proc(sw: ^Writer, setup: Coder_Setup, head: []u8, size: i64) -> (pick: Filter_Pick) {
	#partial switch setup.filter {
	case .Auto:
		if setup.method == .Store {
			return {filter = .None}
		}
		pick = _sniff(head)
		if pick.filter == .None {
			return
		}
		pick.auto = true
		align := _filter_align(pick)
		if pick.filter != .Delta && align > 1 && size >= 0 && size % i64(align) != 0 {
			return {filter = .None}
		}
		if pick.filter == .BCJ_X86 && setup.level >= _default_level(setup.method) && size >= 0 && size <= _bcj2_cap(sw) {
			pick.filter = .BCJ2
		}
	case .Delta:
		pick = {filter = .Delta, delta = max(setup.delta, 1)}
	case:
		pick = {filter = setup.filter}
	}
	return
}

@(private)
_apply_pick :: proc "contextless" (setup: ^Coder_Setup, pick: Filter_Pick) {
	setup.filter = pick.filter
	setup.delta  = pick.delta if pick.filter == .Delta else 0
	if !pick.auto || setup.lzma_set || (setup.method != .LZMA && setup.method != .LZMA2) {
		return
	}
	align := _filter_align(pick)
	bits  := 0
	switch {
	case align & 1  != 0: bits = 0
	case align & 2  != 0: bits = 1
	case align & 4  != 0: bits = 2
	case align & 8  != 0: bits = 3
	case align & 16 != 0: bits = 4
	}
	if bits == 0 {
		return
	}
	if bits > 2 || pick.filter == .Delta {
		setup.lzma.pb = u8(bits)
	}
	setup.lzma.lc = u8(3 - bits) if bits < 3 else 0
	setup.lzma.lp = u8(bits)
}

@(private)
_filter_align :: proc "contextless" (pick: Filter_Pick) -> (align: int) {
	#partial switch pick.filter {
	case .Delta:
		return pick.delta
	case .BCJ_IA64:
		return 16
	case .BCJ_ARM64, .BCJ_ARM, .BCJ_PPC, .BCJ_SPARC:
		return 4
	case .BCJ_ARMT, .BCJ_RISCV:
		return 2
	case .BCJ_X86, .BCJ2:
		return 1
	}
	return 0
}

@(private)
_filter_id :: proc "contextless" (filter: Filter_Choice) -> (id: Method_ID) {
	#partial switch filter {
	case .Delta:     return .Delta
	case .BCJ_X86:   return .BCJ_X86
	case .BCJ_PPC:   return .BCJ_PPC
	case .BCJ_IA64:  return .BCJ_IA64
	case .BCJ_ARM:   return .BCJ_ARM
	case .BCJ_ARMT:  return .BCJ_ARMT
	case .BCJ_SPARC: return .BCJ_SPARC
	case .BCJ_ARM64: return .ARM64
	case .BCJ_RISCV: return .RISCV
	case .BCJ2:      return .BCJ2
	case .Swap2:     return .Swap2
	case .Swap4:     return .Swap4
	}
	return .Copy
}

@(private)
_method_id :: proc "contextless" (method: archive.Method) -> (id: Method_ID) {
	#partial switch method {
	case .LZMA2:     return .LZMA2
	case .LZMA:      return .LZMA
	case .PPMd_H:    return .PPMd
	case .BZip2:     return .BZip2
	case .Deflate:   return .Deflate
	case .Deflate64: return .Deflate64
	}
	return .Copy
}

@(private)
_choice_arch :: proc "contextless" (filter: Filter_Choice) -> (arch: filters.Branch_Arch) {
	#partial switch filter {
	case .BCJ_PPC:   return .PowerPC
	case .BCJ_IA64:  return .IA64
	case .BCJ_ARM:   return .ARM
	case .BCJ_ARMT:  return .ARM_Thumb
	case .BCJ_SPARC: return .SPARC
	case .BCJ_ARM64: return .ARM64
	case .BCJ_RISCV: return .RISCV
	}
	return .X86
}

@(private)
_bcj2_cap :: proc "contextless" (sw: ^Writer) -> (limit: i64) {
	return i64(compress.memory_limit(sw.options.options)) / 4
}

@(private)
_solid_limit :: proc "contextless" (sw: ^Writer, setup: Coder_Setup) -> (limit: i64) {
	if !sw.options.solid {
		return 0
	}
	dict: i64
	#partial switch setup.method {
	case .LZMA, .LZMA2:
		dict = i64(setup.lzma.dict_size)
	case .PPMd_H:
		dict = i64(setup.ppmd.mem_size)
	case .Deflate:
		dict = 1 << 15
	case .Deflate64:
		dict = 1 << 16
	case .BZip2:
		dict = i64(setup.level) * 100_000
	}
	switch {
	case sw.options.solid_size > 0:
		limit = sw.options.solid_size
	case setup.method == .Store:
		return 0
	case setup.method == .LZMA2:
		chunk := clamp(dict << 2, LZMA2_CHUNK_MIN, LZMA2_CHUNK_MAX)
		chunk  = max(chunk, dict)
		chunk  = (chunk + LZMA2_CHUNK_MIN - 1) &~ (LZMA2_CHUNK_MIN - 1)
		limit  = max(min(chunk << 6, SOLID_SIZE_LZMA2_MAX), SOLID_SIZE_MIN)
	case:
		limit = max(min(dict << 7, SOLID_SIZE_MAX), SOLID_SIZE_MIN)
	}
	if setup.filter == .BCJ2 {
		limit = min(limit, _bcj2_cap(sw))
	}
	return
}

@(private)
_folder_accepts :: proc(sw: ^Writer, setup: Coder_Setup, expected: i64, key: ^[AES_KEY_SIZE]u8) -> bool {
	f := &sw.folder
	if f.setup != setup || f.broken {
		return false
	}
	if f.encrypted != (key != nil) || (key != nil && f.key != key^) {
		return false
	}
	if sw.options.solid_files > 0 && f.files >= sw.options.solid_files {
		return false
	}
	if expected >= 0 && f.unpack + expected > f.limit {
		return false
	}
	return true
}

@(private)
_folder_open :: proc(sw: ^Writer, setup: Coder_Setup, expected: i64, key: ^[AES_KEY_SIZE]u8) -> (err: Error) {
	_journal_begin(sw) or_return
	f := &sw.folder
	call, jump, rc := f.call.data, f.jump.data, f.rc.data
	f^ = {}
	f.call.data, f.jump.data, f.rc.data = call, jump, rc
	f.setup  = setup
	f.limit  = _solid_limit(sw, setup)
	f.sink   = {writer = sw}
	clear(&f.call.data)
	clear(&f.jump.data)
	clear(&f.rc.data)
	folder := &f.folder
	size   := expected if !sw.options.solid else -1
	if key != nil {
		f.encrypted      = true
		f.key            = key^
		f.sink.cipher    = &f.cipher
		folder.encrypted = true
		_cipher_init(&f.cipher, &f.key)
		_cipher_begin(&f.cipher, &f.ciphered.ivs[0])
	}
	if setup.filter == .BCJ2 {
		folder.bcj2        = true
		folder.coder_count = 4
		folder.coders[0]   = {id = .LZMA, in_streams = 1}
		folder.coders[1]   = {id = .LZMA, in_streams = 1}
		folder.coders[2]   = {id = _method_id(setup.method), in_streams = 1}
		folder.coders[3]   = {id = .BCJ2, in_streams = 4}
		main_setup := setup
		if size >= 0 && i64(main_setup.lzma.dict_size) > size {
			main_setup.lzma.dict_size = u32(max(size, lzma.DICT_SIZE_MIN))
		}
		bcj2_main := &folder.coders[2]
		if bcj2_main.properties_size, err = _encoder_init(&f.encoder, sw, main_setup, -1, size, _sink_writer(&f.sink), bcj2_main.properties[:]); err != nil {
			_folder_destroy(sw)
			return
		}
		if err = _bcj2_init(sw); err != nil {
			_folder_destroy(sw)
			return
		}
		f.active = true
		return nil
	}
	main := &folder.coders[0]
	main^ = {id = _method_id(setup.method), in_streams = 1}
	folder.coder_count = 1
	if setup.filter != .None {
		folder.coder_count = 2
		filter := &folder.coders[1]
		filter^ = {id = _filter_id(setup.filter), in_streams = 1}
		if setup.filter == .Delta {
			filter.properties[0]   = u8(setup.delta - 1)
			filter.properties_size = 1
		}
		if err = _stage_init(sw, setup); err != nil {
			_folder_destroy(sw)
			return
		}
	}
	if main.properties_size, err = _encoder_init(&f.encoder, sw, setup, size, size, _sink_writer(&f.sink), main.properties[:]); err != nil {
		_folder_destroy(sw)
		return
	}
	f.active = true
	return nil
}

@(private)
_filter_buffer_options :: proc(sw: ^Writer) -> (options: compress.Options, err: Error) {
	if sw.filter_buffer == nil {
		sw.filter_buffer = make([]u8, FILTER_BUFFER_SIZE, sw.allocator) or_return
	}
	options = _codec_options(sw)
	options.buffer = sw.filter_buffer
	return
}

@(private)
_stage_init :: proc(sw: ^Writer, setup: Coder_Setup) -> (err: Error) {
	f := &sw.folder
	options := _filter_buffer_options(sw) or_return
	filter: filters.Filter
	#partial switch setup.filter {
	case .Delta:
		filter = filters.Delta_Filter{distance = setup.delta}
	case .Swap2:
		filter = filters.Swap_Filter.Swap2
	case .Swap4:
		filter = filters.Swap_Filter.Swap4
	case:
		filter = filters.Branch_Filter{arch = _choice_arch(setup.filter)}
	}
	return filters.writer_init(&f.stage, _encoder_writer(&f.encoder), filter, .Encode, options, sw.allocator)
}

@(private)
_bcj2_init :: proc(sw: ^Writer) -> (err: Error) {
	f := &sw.folder
	options := _filter_buffer_options(sw) or_return
	return filters.bcj2_writer_init(&f.bcj2, _encoder_writer(&f.encoder), _dynamic_writer(&f.call), _dynamic_writer(&f.jump), _dynamic_writer(&f.rc), options = options, allocator = sw.allocator)
}

@(private)
_folder_feed :: proc(sw: ^Writer, source: ^Source, head: []u8, expected: i64, file: ^Out_File, out_start: i64) -> (err: Error) {
	f := &sw.folder
	interval  := i64(compress.progress_interval(sw.options.options))
	crc       := hash.crc32(head)
	total     := i64(len(head))
	reported  := i64(0)
	_folder_write(sw, head) or_return
	chunk := _chunk(sw) or_return
	for {
		if total - reported >= interval {
			_progress(sw, len(sw.files), total, expected, sw.offset - out_start, sw.archive_in + total) or_return
			reported = total
		}
		data, read_err := _source_next(source, chunk)
		if len(data) > 0 {
			crc    = hash.crc32(data, crc)
			total += i64(len(data))
			if expected >= 0 && total > expected {
				return SevenZ_Error.Size_Mismatch
			}
			_folder_write(sw, data) or_return
		}
		if read_err == .EOF {
			break
		}
		if read_err != nil {
			return read_err
		}
	}
	if expected >= 0 && total != expected {
		return SevenZ_Error.Size_Mismatch
	}
	f.unpack += total
	f.files  += 1
	f.folder.stream_count += 1
	align := _filter_align({filter = f.setup.filter, delta = f.setup.delta})
	if f.setup.filter != .Delta && align > 1 && total % i64(align) != 0 {
		f.broken = true
	}
	file.size       = total
	file.crc        = crc
	file.has_stream = true
	return nil
}

@(private)
_folder_write :: proc(sw: ^Writer, data: []u8) -> (err: Error) {
	f := &sw.folder
	if f.folder.bcj2 {
		if f.bcj2_in + i64(len(data)) > _bcj2_cap(sw) {
			return compress.Error(compress.General_Error.Memory_Limit_Exceeded)
		}
		f.bcj2_in += i64(len(data))
		_, bcj2_err := filters.bcj2_writer_write(&f.bcj2, data)
		return _stage_error(f, bcj2_err)
	}
	if f.folder.coder_count == 1 {
		return _encoder_write(&f.encoder, data)
	}
	_, filter_err := filters.writer_write(&f.stage, data)
	return _stage_error(f, filter_err)
}

@(private)
_folder_close :: proc(sw: ^Writer) -> (err: Error) {
	f := &sw.folder
	defer _folder_destroy(sw)
	folder := &f.folder
	if folder.bcj2 {
		_folder_close_bcj2(sw) or_return
	} else {
		if folder.coder_count == 2 {
			_stage_error(f, filters.writer_finish(&f.stage)) or_return
		}
		_encoder_finish(&f.encoder) or_return
		_pack_finish(sw, 0) or_return
		for &c in folder.coders[:folder.coder_count] {
			c.unpack_size = f.unpack
		}
	}
	if f.encrypted {
		append(&sw.ciphers, f.ciphered) or_return
	}
	append(&sw.folders, folder^) or_return
	return nil
}

@(private)
_folder_close_bcj2 :: proc(sw: ^Writer) -> (err: Error) {
	f := &sw.folder
	folder := &f.folder
	_stage_error(f, filters.bcj2_writer_finish(&f.bcj2)) or_return
	_encoder_finish(&f.encoder) or_return
	_pack_finish(sw, 0) or_return

	_pack_emit(sw, f.rc.data[:], 1) or_return
	_pack_lzma(sw, f.call.data[:], &folder.coders[1], 2) or_return
	_pack_lzma(sw, f.jump.data[:], &folder.coders[0], 3) or_return

	folder.coders[0].unpack_size = i64(len(f.jump.data))
	folder.coders[1].unpack_size = i64(len(f.call.data))
	folder.coders[2].unpack_size = f.bcj2.written[.Main]
	folder.coders[3].unpack_size = f.unpack
	return nil
}

@(private)
_pack_lzma :: proc(sw: ^Writer, data: []u8, coder: ^Out_Coder, stream: int) -> (err: Error) {
	packed: [dynamic]u8
	packed.allocator = sw.allocator
	defer delete(packed)
	props   := lzma.compress_raw_to_dynamic(&packed, data, BCJ2_LZMA_OPTIONS, allocator = sw.allocator) or_return
	encoded := lzma.encode_properties(props)
	coder.properties_size = copy(coder.properties[:], encoded[:])
	return _pack_emit(sw, packed[:], stream)
}

@(private)
_pack_emit :: proc(sw: ^Writer, data: []u8, stream: int) -> (err: Error) {
	f := &sw.folder
	if f.encrypted {
		_cipher_begin(&f.cipher, &f.ciphered.ivs[stream])
	}
	if _, write_err := io.write_full(_sink_writer(&f.sink), data); write_err != nil {
		return write_err
	}
	return _pack_finish(sw, stream)
}

@(private)
_pack_finish :: proc(sw: ^Writer, stream: int) -> (err: Error) {
	f := &sw.folder
	if f.encrypted {
		f.ciphered.unpack_sizes[stream] = f.cipher.plain
		_cipher_finish(&f.sink) or_return
	}
	append(&sw.pack_sizes, f.sink.count) or_return
	f.sink.count = 0
	return nil
}

@(private)
_folder_destroy :: proc(sw: ^Writer) {
	f := &sw.folder
	_encoder_destroy(&f.encoder)
	filters.writer_destroy(&f.stage)
	filters.bcj2_writer_destroy(&f.bcj2)
	_cipher_destroy(&f.cipher)
	crypto.zero_explicit(&f.key, size_of(f.key))
	call, jump, rc := f.call.data, f.jump.data, f.rc.data
	clear(&call)
	clear(&jump)
	clear(&rc)
	f^ = {}
	f.call.data, f.jump.data, f.rc.data = call, jump, rc
}

@(private)
_codec_options :: proc "contextless" (sw: ^Writer) -> (options: compress.Options) {
	options = sw.options.options
	options.progress      = nil
	options.progress_data = nil
	return
}

@(private)
_encoder_init :: proc(e: ^Encoder, sw: ^Writer, setup: Coder_Setup, size, hint: i64, w: io.Writer, properties: []u8) -> (properties_size: int, err: Error) {
	e.method = setup.method
	e.w      = w
	options := _codec_options(sw)
	#partial switch setup.method {
	case .LZMA2:
		props := lzma.writer_init_lzma2(&e.lzma, w, setup.lzma, size, options, sw.allocator) or_return
		properties[0] = lzma.lzma2_dict_prop(props.dict_size)
		return 1, nil
	case .LZMA:
		props   := lzma.writer_init_raw(&e.lzma, w, setup.lzma, size, options, sw.allocator) or_return
		encoded := lzma.encode_properties(props)
		return copy(properties, encoded[:]), nil
	case .PPMd_H:
		props := setup.ppmd
		if !setup.ppmd_set && hint >= 0 {
			props = ppmd.level_properties(.H, ppmd.Level(setup.level), int(min(hint, i64(max(int)))))
		}
		encoded := ppmd.encode_properties_7z(props) or_return
		ppmd.writer_init(&e.ppmd, w, props, false, options, sw.allocator) or_return
		return copy(properties, encoded[:]), nil
	case .BZip2:
		bzip2.writer_init(&e.bzip2, w, bzip2.Level(setup.level), options, sw.allocator) or_return
	case .Deflate:
		deflate.writer_init(&e.deflate, w, .Raw, deflate.Deflate_Level(setup.level), options, sw.allocator) or_return
	case .Deflate64:
		deflate.writer_init(&e.deflate, w, .Raw64, deflate.Deflate_Level(setup.level), options, sw.allocator) or_return
	}
	return 0, nil
}

@(private)
_encoder_write :: proc(e: ^Encoder, data: []u8) -> (err: Error) {
	#partial switch e.method {
	case .Store:
		if _, write_err := io.write_full(e.w, data); write_err != nil {
			return write_err
		}
	case .Deflate, .Deflate64:
		_ = deflate.writer_write(&e.deflate, data) or_return
	case .BZip2:
		_ = bzip2.writer_write(&e.bzip2, data) or_return
	case .LZMA, .LZMA2:
		_ = lzma.writer_write(&e.lzma, data) or_return
	case .PPMd_H:
		_ = ppmd.writer_write(&e.ppmd, data) or_return
	}
	return nil
}

@(private)
_encoder_finish :: proc(e: ^Encoder) -> (err: Error) {
	#partial switch e.method {
	case .Deflate, .Deflate64:
		deflate.writer_finish(&e.deflate) or_return
	case .BZip2:
		bzip2.writer_finish(&e.bzip2) or_return
	case .LZMA, .LZMA2:
		lzma.writer_finish(&e.lzma) or_return
	case .PPMd_H:
		ppmd.writer_finish(&e.ppmd) or_return
	}
	return nil
}

@(private)
_encoder_destroy :: proc(e: ^Encoder) {
	deflate.writer_destroy(&e.deflate)
	bzip2.writer_destroy(&e.bzip2)
	lzma.writer_destroy(&e.lzma)
	ppmd.writer_destroy(&e.ppmd)
}

@(private)
_stage_error :: proc(f: ^Open_Folder, err: compress.Error) -> Error {
	if err == nil {
		return nil
	}
	for stashed in ([?]Error{f.encoder.err, f.call.err, f.jump.err, f.rc.err}) {
		if stashed != nil {
			return stashed
		}
	}
	return err
}

@(private)
_encoder_writer :: proc(e: ^Encoder) -> (w: io.Writer) {
	w.data      = e
	w.procedure = _encoder_proc
	return
}

@(private)
_encoder_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	e := (^Encoder)(stream_data)
	#partial switch mode {
	case .Write:
		if write_err := _encoder_write(e, p); write_err != nil {
			e.err = write_err
			return 0, .Unknown
		}
		return i64(len(p)), nil
	case .Query:
		return io.query_utility({.Write, .Query})
	}
	return 0, .Unsupported
}

@(private)
_dynamic_writer :: proc(sink: ^Side_Sink) -> (w: io.Writer) {
	w.data      = sink
	w.procedure = _dynamic_proc
	return
}

@(private)
_dynamic_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	sink := (^Side_Sink)(stream_data)
	#partial switch mode {
	case .Write:
		if _, append_err := append(&sink.data, ..p); append_err != nil {
			sink.err = append_err
			return 0, .Unknown
		}
		return i64(len(p)), nil
	case .Query:
		return io.query_utility({.Write, .Query})
	}
	return 0, .Unsupported
}

@(private)
_sink_writer :: proc(sink: ^Pack_Sink) -> (w: io.Writer) {
	w.data      = sink
	w.procedure = _sink_proc
	return
}

@(private)
_sink_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	sink := (^Pack_Sink)(stream_data)
	#partial switch mode {
	case .Write:
		if sink.cipher != nil {
			if write_err := _cipher_write(sink, p); write_err != nil {
				return 0, write_err
			}
			return i64(len(p)), nil
		}
		before := sink.count
		write_err := _sink_emit(sink, p)
		return sink.count - before, write_err
	case .Flush:
		return 0, nil
	case .Query:
		return io.query_utility({.Write, .Flush, .Query})
	}
	return 0, .Unsupported
}

@(private)
_sink_emit :: proc(sink: ^Pack_Sink, p: []u8) -> (err: io.Error) {
	sw := sink.writer
	written, write_err := io.write_full(sw.stream, p)
	sink.count += i64(written)
	sw.offset  += i64(written)
	sw.end      = max(sw.end, sw.offset)
	return write_err
}

@(private)
_read_head :: proc(sw: ^Writer, source: ^Source) -> (head: []u8, err: Error) {
	if source.reader.procedure == nil {
		n := min(len(source.data), SNIFF_SIZE)
		source.position = n
		return source.data[:n], nil
	}
	if sw.head == nil {
		sw.head = make([]u8, SNIFF_SIZE, sw.allocator) or_return
	}
	n     := 0
	zeros := 0
	for n < len(sw.head) {
		m, read_err := io.read(source.reader, sw.head[n:])
		n += m
		if read_err == .EOF {
			source.eof = true
			break
		}
		if read_err != nil {
			return nil, read_err
		}
		if m > 0 {
			zeros = 0
		} else {
			zeros += 1
			if zeros > ZERO_READS_MAX {
				return nil, io.Error.No_Progress
			}
		}
	}
	return sw.head[:n], nil
}

@(private)
_source_next :: proc(source: ^Source, chunk: []u8) -> (data: []u8, err: io.Error) {
	if source.reader.procedure == nil {
		if source.position >= len(source.data) {
			return nil, .EOF
		}
		n := min(len(source.data) - source.position, len(chunk))
		data = source.data[source.position:][:n]
		source.position += n
		return data, nil
	}
	if source.eof {
		return nil, .EOF
	}
	for _ in 0..=ZERO_READS_MAX {
		n, read_err := io.read(source.reader, chunk)
		if read_err == .EOF {
			source.eof = true
		}
		if n > 0 || read_err != nil {
			return chunk[:n], read_err
		}
	}
	return nil, .No_Progress
}

@(private)
_chunk :: proc(sw: ^Writer) -> (chunk: []u8, err: Error) {
	if sw.chunk == nil {
		sw.chunk = make([]u8, COPY_CHUNK_SIZE, sw.allocator) or_return
	}
	return sw.chunk, nil
}

@(private)
_add_file :: proc(sw: ^Writer, file: Out_File) -> (err: Error) {
	_name_register(sw) or_return
	mark := len(sw.names)
	defer if err != nil {
		resize(&sw.names, mark)
	}
	_append_name(&sw.names, sw.name[:]) or_return
	append(&sw.files, file) or_return
	sw.archive_in += file.size
	return nil
}

@(private)
_append_name :: proc(out: ^[dynamic]u8, name: []u8) -> (err: runtime.Allocator_Error) {
	reserve(out, len(out) + 2 * len(name) + 2) or_return
	i := 0
	for i < len(name) {
		r, n := utf8.decode_rune(name[i:])
		if r == utf8.RUNE_ERROR && n == 1 || r >= ESCAPE_FIRST && r <= ESCAPE_LAST {
			for b in name[i:][:n] {
				_put_u16(out, ESCAPE_BASE + u16(b))
			}
		} else if r >= 0x10000 {
			v := u32(r) - 0x10000
			_put_u16(out, 0xD800 + u16(v >> 10))
			_put_u16(out, 0xDC00 + u16(v & 0x3FF))
		} else {
			_put_u16(out, u16(r))
		}
		i += n
	}
	_put_u16(out, 0)
	return nil
}

@(private)
_attributes :: proc "contextless" (fi: archive.File_Info, type: archive.Entry_Type) -> (attributes: u32) {
	mode := fi.unix_mode
	if mode == 0 {
		switch {
		case fi.dos_attributes != 0:
			mode = archive._unix_mode_from_dos(fi.dos_attributes | (archive.DOS_DIRECTORY if type == .Directory else 0))
		case type == .Directory:
			mode = 0o755
		case type == .Symlink:
			mode = 0o777
		case:
			mode = 0o644
		}
	}
	mode = mode & archive.UNIX_PERMISSION_MASK | archive._unix_type_bits(type)
	dos := fi.dos_attributes & 0x7FFF
	if dos == 0 {
		dos = archive._dos_attributes_from_unix(mode, type)
	}
	if type == .Directory {
		dos |= archive.DOS_DIRECTORY
	} else {
		dos &~= archive.DOS_DIRECTORY
	}
	return dos | UNIX_EXTENSION | mode << 16
}

@(private)
_filetime :: proc "contextless" (t: time.Time) -> (filetime: u64) {
	if t == {} {
		return 0
	}
	ticks := time.time_to_unix_nano(t) / 100 + NTFS_EPOCH_DELTA
	return u64(ticks) if ticks > 0 else 0
}

@(private)
_entry_done :: proc(sw: ^Writer, file: ^Out_File, bytes_out: i64) -> (err: Error) {
	return _progress(sw, len(sw.files) - 1, file.size, file.size, bytes_out, sw.archive_in)
}

@(private)
_progress :: proc(sw: ^Writer, index: int, bytes_in, total_in, bytes_out, archive_in: i64) -> (err: Error) {
	options := sw.options.options
	if options.progress == nil {
		return nil
	}
	progress := compress.Progress{
		bytes_in         = bytes_in,
		bytes_out        = bytes_out,
		total_in         = total_in,
		total_out        = -1,
		member           = string(sw.name[:]),
		member_index     = index,
		member_count     = -1,
		archive_in       = archive_in,
		archive_total_in = -1,
	}
	if options.progress(progress, options.progress_data) {
		sw.err = compress.Error(compress.General_Error.Canceled)
		return sw.err
	}
	return nil
}

@(private)
_build_header :: proc(sw: ^Writer, files: []Out_File, names: []u8) -> (err: Error) {
	buf := &sw.header
	clear(buf)
	old := &sw.old.streams
	bound := 256 + 320 * len(sw.folders) + 240 * len(sw.ciphers) + 10 * len(sw.pack_sizes) + 52 * len(files) + len(names)
	for index in sw.kept {
		f := &old.folders[index]
		bound += 64 + 20 * f.coder_count + 20 * f.bind_count + 20 * f.packed_count
		for c in old.coders[f.first_coder:][:f.coder_count] {
			bound += len(c.properties)
		}
	}
	reserve(buf, bound) or_return

	_put_id(buf, .Header)
	if len(sw.kept) + len(sw.folders) > 0 {
		pack_count := len(sw.pack_sizes)
		for index in sw.kept {
			pack_count += old.folders[index].packed_count
		}
		_put_id(buf, .Main_Streams)
		_put_id(buf, .Pack_Info)
		_put_number(buf, u64(sw.pack_pos))
		_put_number(buf, u64(pack_count))
		_put_id(buf, .Size)
		for index in sw.kept {
			f := &old.folders[index]
			for size in old.pack_sizes[f.first_pack:][:f.packed_count] {
				_put_number(buf, u64(size))
			}
		}
		for size in sw.pack_sizes {
			_put_number(buf, u64(size))
		}
		_put_id(buf, .End)

		_put_id(buf, .Unpack_Info)
		_put_id(buf, .Folder)
		_put_number(buf, u64(len(sw.kept) + len(sw.folders)))
		append(buf, 0)
		for index in sw.kept {
			_put_old_folder(buf, old, &old.folders[index])
		}
		cipher_index := 0
		for &folder in sw.folders {
			cipher: ^Out_Cipher
			if folder.encrypted {
				cipher = &sw.ciphers[cipher_index]
				cipher_index += 1
			}
			_put_folder(sw, buf, &folder, cipher)
		}
		_put_id(buf, .Coders_Unpack_Size)
		for index in sw.kept {
			f := &old.folders[index]
			for c in old.coders[f.first_coder:][:f.coder_count] {
				_put_number(buf, u64(c.unpack_size))
			}
		}
		cipher_index = 0
		for &folder in sw.folders {
			cipher: ^Out_Cipher
			if folder.encrypted {
				cipher = &sw.ciphers[cipher_index]
				cipher_index += 1
			}
			_put_unpack_sizes(buf, &folder, cipher)
		}
		_put_id(buf, .End)

		_put_id(buf, .Substreams_Info)
		multiple := false
		for index in sw.kept {
			if old.folders[index].stream_count != 1 {
				multiple = true
			}
		}
		for folder in sw.folders {
			if folder.stream_count != 1 {
				multiple = true
			}
		}
		if multiple {
			_put_id(buf, .Num_Unpack_Stream)
			for index in sw.kept {
				_put_number(buf, u64(old.folders[index].stream_count))
			}
			for folder in sw.folders {
				_put_number(buf, u64(folder.stream_count))
			}
			_put_id(buf, .Size)
			index := 0
			for k in 0..<len(sw.kept) + len(sw.folders) {
				count := old.folders[sw.kept[k]].stream_count if k < len(sw.kept) else sw.folders[k - len(sw.kept)].stream_count
				for j in 0..<count {
					for !files[index].has_stream {
						index += 1
					}
					if j + 1 < count {
						_put_number(buf, u64(files[index].size))
					}
					index += 1
				}
			}
		}
		streams, digests := 0, 0
		for file in files {
			if file.has_stream {
				streams += 1
				if !file.no_crc {
					digests += 1
				}
			}
		}
		if digests > 0 {
			_put_id(buf, .CRC)
			if digests == streams {
				append(buf, 1)
			} else {
				append(buf, 0)
				bits, mask := u8(0), u8(0x80)
				for file in files {
					if !file.has_stream {
						continue
					}
					if !file.no_crc {
						bits |= mask
					}
					mask >>= 1
					if mask == 0 {
						append(buf, bits)
						bits, mask = 0, 0x80
					}
				}
				if mask != 0x80 {
					append(buf, bits)
				}
			}
			for file in files {
				if file.has_stream && !file.no_crc {
					_put_u32(buf, file.crc)
				}
			}
		}
		_put_id(buf, .End)
		_put_id(buf, .End)
	}

	_put_id(buf, .Files_Info)
	_put_number(buf, u64(len(files)))
	empty, empty_files, anti := 0, 0, 0
	for file in files {
		if !file.has_stream {
			empty += 1
			if !file.is_directory {
				empty_files += 1
			}
			if file.is_anti {
				anti += 1
			}
		}
	}
	if empty > 0 {
		_put_id(buf, .Empty_Stream)
		_put_number(buf, u64((len(files) + 7) / 8))
		bits, mask := u8(0), u8(0x80)
		for file in files {
			if !file.has_stream {
				bits |= mask
			}
			mask >>= 1
			if mask == 0 {
				append(buf, bits)
				bits, mask = 0, 0x80
			}
		}
		if mask != 0x80 {
			append(buf, bits)
		}
		if empty_files > 0 {
			_put_empty_bits(buf, files, .Empty_File, empty)
		}
		if anti > 0 {
			_put_empty_bits(buf, files, .Anti, empty)
		}
	}

	_put_id(buf, .Name)
	_put_number(buf, u64(len(names) + 1))
	append(buf, 0)
	append(buf, ..names)

	_put_times(buf, files, .Creation_Time)
	_put_times(buf, files, .Access_Time)
	_put_times(buf, files, .Modification_Time)

	attributes := 0
	for file in files {
		if !file.no_attributes {
			attributes += 1
		}
	}
	if attributes > 0 {
		vector := 0 if attributes == len(files) else (len(files) + 7) / 8
		_put_id(buf, .Attributes)
		_put_number(buf, u64(4 * attributes + vector + 2))
		if vector == 0 {
			append(buf, 1)
		} else {
			append(buf, 0)
			bits, mask := u8(0), u8(0x80)
			for file in files {
				if !file.no_attributes {
					bits |= mask
				}
				mask >>= 1
				if mask == 0 {
					append(buf, bits)
					bits, mask = 0, 0x80
				}
			}
			if mask != 0x80 {
				append(buf, bits)
			}
		}
		append(buf, 0)
		for file in files {
			if !file.no_attributes {
				_put_u32(buf, file.attributes)
			}
		}
	}
	_put_id(buf, .End)
	_put_id(buf, .End)
	return nil
}

@(private)
_put_empty_bits :: proc(buf: ^[dynamic]u8, files: []Out_File, id: Property_ID, empty: int) {
	_put_id(buf, id)
	_put_number(buf, u64((empty + 7) / 8))
	bits, mask := u8(0), u8(0x80)
	for file in files {
		if file.has_stream {
			continue
		}
		set := file.is_anti if id == .Anti else !file.is_directory
		if set {
			bits |= mask
		}
		mask >>= 1
		if mask == 0 {
			append(buf, bits)
			bits, mask = 0, 0x80
		}
	}
	if mask != 0x80 {
		append(buf, bits)
	}
}

@(private)
_put_old_folder :: proc(buf: ^[dynamic]u8, s: ^Streams, f: ^Folder) {
	_put_number(buf, u64(f.coder_count))
	for c in s.coders[f.first_coder:][:f.coder_count] {
		_put_coder(buf, Method_ID(c.id), c.in_streams, c.properties)
	}
	for b in s.bind_pairs[f.first_bind:][:f.bind_count] {
		_put_number(buf, u64(b.in_index))
		_put_number(buf, u64(b.out_index))
	}
	if f.packed_count > 1 {
		for index in s.packed[f.first_packed:][:f.packed_count] {
			_put_number(buf, u64(index))
		}
	}
}

@(private)
_put_times :: proc(buf: ^[dynamic]u8, files: []Out_File, id: Property_ID) {
	defined := 0
	for &file in files {
		if _file_time(&file, id) != 0 {
			defined += 1
		}
	}
	if defined == 0 {
		return
	}
	vector := 0 if defined == len(files) else (len(files) + 7) / 8
	_put_id(buf, id)
	_put_number(buf, u64(8 * defined + vector + 2))
	if vector == 0 {
		append(buf, 1)
	} else {
		append(buf, 0)
		bits, mask := u8(0), u8(0x80)
		for &file in files {
			if _file_time(&file, id) != 0 {
				bits |= mask
			}
			mask >>= 1
			if mask == 0 {
				append(buf, bits)
				bits, mask = 0, 0x80
			}
		}
		if mask != 0x80 {
			append(buf, bits)
		}
	}
	append(buf, 0)
	for &file in files {
		if t := _file_time(&file, id); t != 0 {
			_put_u64(buf, t)
		}
	}
}

@(private)
_file_time :: proc "contextless" (file: ^Out_File, id: Property_ID) -> (filetime: u64) {
	#partial switch id {
	case .Creation_Time: return file.creation_time
	case .Access_Time:   return file.access_time
	}
	return file.modification_time
}

@(private)
_put_folder :: proc(sw: ^Writer, buf: ^[dynamic]u8, folder: ^Out_Folder, cipher: ^Out_Cipher) {
	packs := BCJ2_PACK_STREAMS if folder.bcj2 else 1
	shift := u64(0)
	count := folder.coder_count
	if cipher != nil {
		shift  = u64(packs)
		count += packs
		properties: [AES_PROPERTIES_MAX]u8
		_put_number(buf, u64(count))
		for p in 0..<packs {
			n := _aes_properties(properties[:], sw.kdf_power, sw.salt[:], cipher.ivs[p][:])
			_put_coder(buf, .AES, 1, properties[:n])
		}
	} else {
		_put_number(buf, u64(count))
	}
	for &c in folder.coders[:folder.coder_count] {
		_put_coder(buf, c.id, c.in_streams, c.properties[:c.properties_size])
	}
	packed := [BCJ2_PACK_STREAMS]u64{2, 6, 1, 0}
	if folder.bcj2 {
		bonds := [3][2]u64{{5, 0}, {4, 1}, {3, 2}}
		for bond in bonds {
			_put_number(buf, bond[0] + shift)
			_put_number(buf, bond[1] + shift)
		}
	} else {
		packed[0] = 0
		if folder.coder_count == 2 {
			_put_number(buf, 1 + shift)
			_put_number(buf, 0 + shift)
		}
	}
	if cipher != nil {
		for p in 0..<packs {
			_put_number(buf, packed[p] + shift)
			_put_number(buf, u64(p))
			packed[p] = u64(p)
		}
	}
	if packs > 1 {
		for index in packed {
			_put_number(buf, index)
		}
	}
}

@(private)
_put_coder :: proc(buf: ^[dynamic]u8, method: Method_ID, in_streams: int, properties: []u8) {
	id   := u64(method)
	size := 1
	for size < 8 && id >> (8 * uint(size)) != 0 {
		size += 1
	}
	flags := u8(size)
	if in_streams != 1 {
		flags |= 0x10
	}
	if len(properties) > 0 {
		flags |= 0x20
	}
	append(buf, flags)
	for k in 0..<size {
		append(buf, u8(id >> (8 * uint(size - 1 - k))))
	}
	if in_streams != 1 {
		_put_number(buf, u64(in_streams))
		_put_number(buf, 1)
	}
	if len(properties) > 0 {
		_put_number(buf, u64(len(properties)))
		append(buf, ..properties)
	}
}

@(private)
_put_unpack_sizes :: proc(buf: ^[dynamic]u8, folder: ^Out_Folder, cipher: ^Out_Cipher) {
	if cipher != nil {
		packs := BCJ2_PACK_STREAMS if folder.bcj2 else 1
		for size in cipher.unpack_sizes[:packs] {
			_put_number(buf, u64(size))
		}
	}
	for c in folder.coders[:folder.coder_count] {
		_put_number(buf, u64(c.unpack_size))
	}
}

@(private)
_encode_header :: proc(sw: ^Writer) -> (err: Error) {
	packed: [dynamic]u8
	packed.allocator = sw.allocator
	defer delete(packed)
	crc      := hash.crc32(sw.header[:])
	size     := len(sw.header)
	pack_pos := sw.offset - sw.start - SIGNATURE_HEADER_SIZE
	folder   := Out_Folder{coder_count = 1}
	main     := &folder.coders[0]
	main^ = {id = .Copy, in_streams = 1, unpack_size = i64(size)}
	data := sw.header[:]
	if !sw.options.plain_header {
		props   := lzma.compress_raw_to_dynamic(&packed, sw.header[:], HEADER_LZMA_OPTIONS, allocator = sw.allocator) or_return
		encoded := lzma.encode_properties(props)
		main.id              = .LZMA
		main.properties_size = copy(main.properties[:], encoded[:])
		data = packed[:]
	}

	pack_size := i64(len(data))
	ciphered: Out_Cipher
	cipher:   ^Out_Cipher
	if _header_encrypted(sw) {
		key: [AES_KEY_SIZE]u8
		defer crypto.zero_explicit(&key, size_of(key))
		_writer_key(sw, sw.password, &key) or_return
		state: Pack_Cipher
		defer _cipher_destroy(&state)
		_cipher_init(&state, &key)
		_cipher_begin(&state, &ciphered.ivs[0])
		sink := Pack_Sink{writer = sw, cipher = &state}
		_cipher_write(&sink, data) or_return
		_cipher_finish(&sink) or_return
		ciphered.unpack_sizes[0] = state.plain
		pack_size        = sink.count
		folder.encrypted = true
		cipher           = &ciphered
	} else {
		_emit(sw, data) or_return
	}

	buf := &sw.header
	clear(buf)
	reserve(buf, 256) or_return
	_put_id(buf, .Encoded_Header)
	_put_id(buf, .Pack_Info)
	_put_number(buf, u64(pack_pos))
	_put_number(buf, 1)
	_put_id(buf, .Size)
	_put_number(buf, u64(pack_size))
	_put_id(buf, .End)
	_put_id(buf, .Unpack_Info)
	_put_id(buf, .Folder)
	_put_number(buf, 1)
	append(buf, 0)
	_put_folder(sw, buf, &folder, cipher)
	_put_id(buf, .Coders_Unpack_Size)
	_put_unpack_sizes(buf, &folder, cipher)
	_put_id(buf, .CRC)
	append(buf, 1)
	_put_u32(buf, crc)
	_put_id(buf, .End)
	_put_id(buf, .End)
	return nil
}

@(private)
_start_header :: proc(next_offset, next_size: i64, next_crc: u32) -> (h: [SIGNATURE_HEADER_SIZE]u8) {
	signature := SIGNATURE
	copy(h[:], signature[:])
	h[6] = VERSION_MAJOR
	h[7] = VERSION_MINOR
	for i in 0..<8 {
		h[12 + i] = u8(u64(next_offset) >> (8 * uint(i)))
		h[20 + i] = u8(u64(next_size) >> (8 * uint(i)))
	}
	for i in 0..<4 {
		h[28 + i] = u8(next_crc >> (8 * uint(i)))
	}
	crc := hash.crc32(h[12:])
	for i in 0..<4 {
		h[8 + i] = u8(crc >> (8 * uint(i)))
	}
	return
}

@(private)
_sniff :: proc "contextless" (b: []u8) -> (pick: Filter_Pick) {
	if filter, ok := _sniff_pe(b); ok {
		return {filter = filter}
	}
	if filter, ok := _sniff_elf(b); ok {
		return {filter = filter}
	}
	if filter, ok := _sniff_macho(b); ok {
		return {filter = filter}
	}
	if delta, ok := _sniff_wav(b); ok {
		return {filter = .Delta, delta = delta}
	}
	return {filter = .None}
}

@(private)
_sniff_pe :: proc "contextless" (b: []u8) -> (filter: Filter_Choice, ok: bool) {
	if len(b) < 512 || _get16(b, 0, false) != 0x5A4D {
		return
	}
	pe_offset := _get32(b, 0x3C, false)
	if pe_offset >= 0x1000 || int(pe_offset) + 512 > len(b) || pe_offset & 7 != 0 {
		return
	}
	p := int(pe_offset)
	if _get32(b, p, false) != 0x00004550 {
		return
	}
	p += 4
	machine := _get16(b, p, false)
	switch machine {
	case 0x014C, 0x8664: filter = .BCJ_X86
	case 0xAA64:         filter = .BCJ_ARM64
	case 0x01C0, 0x01C2: filter = .BCJ_ARM
	case 0x01C4:         filter = .BCJ_ARMT
	case 0x5032, 0x5064: filter = .BCJ_RISCV
	case 0x0200:         filter = .BCJ_IA64
	case:
		return
	}
	sections := int(_get16(b, p + 2, false))
	optional := int(_get16(b, p + 16, false))
	if optional > 1 << 10 {
		return .None, false
	}
	p += 20
	magic := _get16(b, p, false)
	if magic != 0x10B && magic != 0x20B {
		return .None, false
	}
	if p + optional <= len(b) && sections <= 64 && machine == 0x8664 {
		p += optional
		for _ in 0..<sections {
			if p + 40 > len(b) {
				break
			}
			if string(b[p:][:8]) == ".a64xrm\x00" {
				filter = .BCJ_ARM64
				break
			}
			p += 40
		}
	}
	return filter, true
}

@(private)
_sniff_elf :: proc "contextless" (b: []u8) -> (filter: Filter_Choice, ok: bool) {
	if len(b) < 512 || b[6] != 1 || _get32(b, 0, false) != 0x464C457F {
		return
	}
	if b[4] != 1 && b[4] != 2 {
		return
	}
	be: bool
	switch b[5] {
	case 1: be = false
	case 2: be = true
	case:
		return
	}
	switch _get16(b, 0x12, be) {
	case 3, 6, 62:
		filter = .BCJ_X86
	case 2, 18, 43:
		filter = .BCJ_SPARC
	case 20, 21:
		if !be {
			return .None, false
		}
		filter = .BCJ_PPC
	case 40:
		if be {
			return .None, false
		}
		filter = .BCJ_ARM
	case 183:
		if be {
			return .None, false
		}
		filter = .BCJ_ARM64
	case 243:
		if be {
			return .None, false
		}
		filter = .BCJ_RISCV
	case:
		return
	}
	return filter, true
}

@(private)
_sniff_macho :: proc "contextless" (b: []u8) -> (filter: Filter_Choice, ok: bool) {
	if len(b) < 512 {
		return
	}
	be: bool
	switch _get32(b, 0, false) {
	case 0xCEFAEDFE, 0xCFFAEDFE: be = true
	case 0xFEEDFACE, 0xFEEDFACF: be = false
	case:
		return
	}
	switch _get32(b, 4, be) {
	case 7, 0x0100_0007:
		filter = .BCJ_X86
	case 12:
		if be {
			return .None, false
		}
		filter = .BCJ_ARM
	case 14:
		if !be {
			return .None, false
		}
		filter = .BCJ_SPARC
	case 18, 0x0100_0012:
		if !be {
			return .None, false
		}
		filter = .BCJ_PPC
	case 0x0100_000C:
		if be {
			return .None, false
		}
		filter = .BCJ_ARM64
	case:
		return
	}
	if _get32(b, 0x14, be) > 1 << 24 || _get32(b, 0x10, be) > 1 << 18 {
		return .None, false
	}
	return filter, true
}

@(private)
_sniff_wav :: proc "contextless" (b: []u8) -> (delta: int, ok: bool) {
	if len(b) < 0x2C {
		return
	}
	if _get32(b, 0, false) != 0x46464952 || _get32(b, 8, false) != 0x45564157 || _get32(b, 0xC, false) != 0x20746D66 {
		return
	}
	size := _get32(b, 0x10, false)
	if size < 0x10 || size > 0x12 || _get16(b, 0x14, false) != 1 {
		return
	}
	channels := u32(_get16(b, 0x16, false))
	bits     := u32(_get16(b, 0x22, false))
	if bits & 7 != 0 {
		return
	}
	distance := channels * (bits >> 3)
	if distance == 0 || distance > 256 {
		return
	}
	pos := u64(0x14) + u64(size)
	for _ in 0..<10 {
		if pos + 8 > u64(len(b)) {
			return
		}
		size = _get32(b, int(pos) + 4, false)
		if _get32(b, int(pos), false) == 0x61746164 {
			return int(distance), true
		}
		if size > 1 << 16 {
			return
		}
		pos += u64(size) + 8
	}
	return
}

@(private)
_get16 :: #force_inline proc "contextless" (b: []u8, pos: int, be: bool) -> (value: u16) {
	if be {
		return u16(b[pos]) << 8 | u16(b[pos + 1])
	}
	return u16(b[pos]) | u16(b[pos + 1]) << 8
}

@(private)
_get32 :: #force_inline proc "contextless" (b: []u8, pos: int, be: bool) -> (value: u32) {
	if be {
		return u32(b[pos]) << 24 | u32(b[pos + 1]) << 16 | u32(b[pos + 2]) << 8 | u32(b[pos + 3])
	}
	return u32(b[pos]) | u32(b[pos + 1]) << 8 | u32(b[pos + 2]) << 16 | u32(b[pos + 3]) << 24
}

@(private)
_put_id :: proc(buf: ^[dynamic]u8, id: Property_ID) {
	append(buf, u8(id))
}

@(private)
_put_number :: proc(buf: ^[dynamic]u8, value: u64) {
	first := u8(0)
	mask  := u8(0x80)
	count := 0
	for count < 8 {
		if value < u64(1) << (7 * uint(count + 1)) {
			first |= u8(value >> (8 * uint(count)))
			break
		}
		first |= mask
		mask >>= 1
		count += 1
	}
	append(buf, first)
	for k in 0..<count {
		append(buf, u8(value >> (8 * uint(k))))
	}
}

@(private)
_put_u16 :: proc(buf: ^[dynamic]u8, v: u16) {
	append(buf, u8(v), u8(v >> 8))
}

@(private)
_put_u32 :: proc(buf: ^[dynamic]u8, v: u32) {
	append(buf, u8(v), u8(v >> 8), u8(v >> 16), u8(v >> 24))
}

@(private)
_put_u64 :: proc(buf: ^[dynamic]u8, v: u64) {
	_put_u32(buf, u32(v))
	_put_u32(buf, u32(v >> 32))
}

@(private)
_emit :: proc(sw: ^Writer, p: []u8) -> (err: Error) {
	_journal_begin(sw) or_return
	n, write_err := io.write_full(sw.stream, p)
	sw.offset += i64(n)
	sw.end     = max(sw.end, sw.offset)
	if write_err != nil {
		return write_err
	}
	return nil
}

@(private)
_seek :: proc(sw: ^Writer, offset: i64) -> (err: Error) {
	if _, seek_err := io.seek(sw.stream, offset, .Start); seek_err != nil {
		return seek_err
	}
	sw.offset = offset
	return nil
}

@(private)
_flush :: proc(sw: ^Writer) -> (err: Error) {
	if sw.options.no_sync {
		return nil
	}
	flush_err := io.flush(sw.stream)
	if flush_err != nil && flush_err != .Unsupported && flush_err != .Empty {
		return flush_err
	}
	return nil
}
