package tar

import "core:archive"
import "core:compress"
import "core:compress/bzip2"
import "core:compress/deflate"
import "core:compress/lz4"
import "core:compress/lzma"
import "core:compress/xz"
import "core:io"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"
import "core:time"
import "core:unicode/utf8"

create_from_path :: proc(tw: ^Writer, path: string, options: Writer_Options = {}, allocator := context.allocator) -> (err: Error) {
	tw^ = {}
	tw.allocator = allocator
	_check_options(options) or_return
	tw.path = strings.clone(path, allocator) or_return
	f, create_err := os.create(path)
	if create_err != nil {
		close_writer(tw)
		return create_err
	}
	tw.file = f
	if err = _writer_init(tw, os.to_stream(f), options); err != nil {
		close_writer(tw)
	}
	return
}

create_from_stream :: proc(tw: ^Writer, s: io.Stream, options: Writer_Options = {}, allocator := context.allocator) -> (err: Error) {
	tw^ = {}
	tw.allocator = allocator
	_check_options(options) or_return
	if err = _writer_init(tw, s, options); err != nil {
		close_writer(tw)
	}
	return
}

create :: proc{create_from_path, create_from_stream}

write_entry_with_info :: proc(tw: ^Writer, fi: archive.File_Info, data: Entry_Data = nil) -> (err: Error) {
	_writer_ready(tw) or_return
	start := tw.written
	defer if err != nil && tw.written != start {
		tw.err = err
	}
	return _write_member(tw, fi, data)
}

write_entry_simple :: proc(tw: ^Writer, name: string, data: Entry_Data = nil) -> (err: Error) {
	fi: archive.File_Info
	fi.path              = name
	fi.type              = .Regular
	fi.modification_time = time.now()
	fi.size              = -1
	return write_entry_with_info(tw, fi, data)
}

write_entry :: proc{write_entry_with_info, write_entry_simple}

write_directory :: proc(tw: ^Writer, dir: string, prefix := "") -> (err: Error) {
	_writer_ready(tw) or_return
	root, root_err := os.get_absolute_path(dir, tw.allocator)
	if root_err != nil {
		return root_err
	}
	defer delete(root, tw.allocator)
	base := strings.trim(prefix, "/")
	if base != "" {
		info, stat_err := os.stat(root, tw.allocator)
		if stat_err != nil {
			return stat_err
		}
		defer os.file_info_delete(info, tw.allocator)
		fi: archive.File_Info
		fi.path              = base
		fi.type              = .Directory
		fi.unix_mode         = transmute(u32)info.mode & archive.UNIX_PERMISSION_MASK
		fi.modification_time = info.modification_time
		write_entry_with_info(tw, fi, nil) or_return
	}

	walker := os.walker_create(root)
	defer os.walker_destroy(&walker)
	if !tw.options.deterministic {
		for info in os.walker_walk(&walker) {
			if _, walk_err := os.walker_error(&walker); walk_err != nil {
				return walk_err
			}
			_walk_name(tw, root, base, info.fullpath) or_return
			_write_walked(tw, string(tw.walk_name[:]), info) or_return
		}
	} else {
		walked: [dynamic]Walked_Entry
		walked.allocator = tw.allocator
		defer {
			for entry in walked {
				delete(entry.name, tw.allocator)
				os.file_info_delete(entry.info, tw.allocator)
			}
			delete(walked)
		}
		for info in os.walker_walk(&walker) {
			if _, walk_err := os.walker_error(&walker); walk_err != nil {
				return walk_err
			}
			_walk_name(tw, root, base, info.fullpath) or_return
			entry: Walked_Entry
			entry.name = strings.clone(string(tw.walk_name[:]), tw.allocator) or_return
			cloned, clone_err := os.file_info_clone(info, tw.allocator)
			if clone_err != nil {
				delete(entry.name, tw.allocator)
				return clone_err
			}
			entry.info = cloned
			if _, append_err := append(&walked, entry); append_err != nil {
				delete(entry.name, tw.allocator)
				os.file_info_delete(entry.info, tw.allocator)
				return append_err
			}
		}
		slice.sort_by(walked[:], proc(a, b: Walked_Entry) -> bool {
			return a.name < b.name
		})
		for entry in walked {
			_write_walked(tw, entry.name, entry.info) or_return
		}
	}
	if _, walk_err := os.walker_error(&walker); walk_err != nil {
		return walk_err
	}
	return nil
}

commit :: proc(tw: ^Writer) -> (err: Error) {
	if tw.committed {
		return nil
	}
	_writer_ready(tw) or_return
	defer if err != nil {
		tw.err = err
	}
	zero: [BLOCK_SIZE]u8
	for _ in 0..<2 {
		_emit(tw, zero[:]) or_return
	}
	for tw.written % RECORD_SIZE != 0 {
		_emit(tw, zero[:]) or_return
	}
	#partial switch tw.options.compression {
	case .Deflate:
		deflate.deflate_writer_finish(&tw.deflate) or_return
	case .BZip2:
		bzip2.writer_finish(&tw.bzip2) or_return
	case .LZ4:
		lz4.frame_writer_finish(&tw.lz4) or_return
	case .LZMA:
		lzma.writer_finish(&tw.lzma) or_return
	case .XZ:
		xz.writer_finish(&tw.xz) or_return
	}
	tw.committed = true
	return nil
}

close_writer :: proc(tw: ^Writer) {
	if tw.active {
		#partial switch tw.options.compression {
		case .Deflate:
			deflate.deflate_writer_destroy(&tw.deflate)
		case .BZip2:
			bzip2.writer_destroy(&tw.bzip2)
		case .LZ4:
			lz4.frame_writer_destroy(&tw.lz4)
		case .LZMA:
			lzma.writer_destroy(&tw.lzma)
		case .XZ:
			xz.writer_destroy(&tw.xz)
		}
	}
	if tw.file != nil {
		os.close(tw.file)
		if !tw.committed {
			os.remove(tw.path)
		}
	}
	delete(tw.path, tw.allocator)
	delete(tw.records)
	delete(tw.name)
	delete(tw.walk_name)
	delete(tw.chunk, tw.allocator)
	tw^ = {}
}

@(private)
_check_options :: proc(options: Writer_Options) -> (err: Error) {
	if options.options.progress_interval < 0 {
		return archive.General_Error.Incompatible_Options
	}
	switch options.format {
	case .Pax, .Ustar, .GNU:
	case:
		return archive.General_Error.Incompatible_Options
	}
	level, has_level := options.level.?
	#partial switch options.compression {
	case .Unknown, .Store:
		if has_level {
			return archive.General_Error.Incompatible_Options
		}
	case .Deflate:
		if has_level && (level < int(deflate.Deflate_Level.Stored) || level > int(deflate.Deflate_Level.Best)) {
			return archive.General_Error.Incompatible_Options
		}
	case .BZip2:
		if has_level && (level < int(bzip2.Level.Fastest) || level > int(bzip2.Level.Best)) {
			return archive.General_Error.Incompatible_Options
		}
	case .LZ4:
		if has_level && (level < int(lz4.Level.Fastest) || level > int(lz4.Level.Best)) {
			return archive.General_Error.Incompatible_Options
		}
	case .LZMA, .XZ:
		if has_level && (level < int(lzma.Level.Fastest) || level > int(lzma.Level.Best)) {
			return archive.General_Error.Incompatible_Options
		}
	case:
		return archive.General_Error.Unsupported_Method
	}
	return nil
}

@(private)
_writer_init :: proc(tw: ^Writer, s: io.Stream, options: Writer_Options) -> (err: Error) {
	tw.records.allocator   = tw.allocator
	tw.name.allocator      = tw.allocator
	tw.walk_name.allocator = tw.allocator
	tw.options = options
	if .Write not_in io.query(s) {
		return io.Error.Unsupported
	}
	tw.stream = s
	tw.out    = s

	codec := options.options
	codec.progress      = nil
	codec.progress_data = nil
	level, has_level := options.level.?
	#partial switch options.compression {
	case .Deflate:
		deflate_level := deflate.Deflate_Level(level) if has_level else .Default
		deflate.deflate_writer_init(&tw.deflate, s, .Gzip, deflate_level, codec, tw.allocator) or_return
		tw.out = deflate.deflate_writer_to_stream(&tw.deflate)
	case .BZip2:
		bzip2_level := bzip2.Level(level) if has_level else .Default
		bzip2.writer_init(&tw.bzip2, s, bzip2_level, codec, tw.allocator) or_return
		tw.out = bzip2.writer_to_stream(&tw.bzip2)
	case .LZ4:
		lz4_level := lz4.Level(level) if has_level else .Default
		lz4.frame_writer_init(&tw.lz4, s, lz4_level, {flags = lz4.DEFAULT_FRAME_FLAGS}, -1, codec, nil, tw.allocator) or_return
		tw.out = lz4.frame_writer_to_stream(&tw.lz4)
	case .LZMA:
		lzma_level := lzma.Level(level) if has_level else .Default
		lzma.writer_init(&tw.lzma, s, lzma_level, -1, codec, tw.allocator) or_return
		tw.out = lzma.writer_to_stream(&tw.lzma)
	case .XZ:
		xz_level := xz.Level(level) if has_level else .Default
		xz.writer_init(&tw.xz, s, xz_level, {}, codec, tw.allocator) or_return
		tw.out = xz.writer_to_stream(&tw.xz)
	}
	tw.active = true
	return nil
}

@(private)
_writer_ready :: proc(tw: ^Writer) -> (err: Error) {
	if !tw.active || tw.committed {
		return io.Error.Closed
	}
	return tw.err
}

@(private)
_write_member :: proc(tw: ^Writer, fi: archive.File_Info, data: Entry_Data) -> (err: Error) {
	p: Pending_Entry
	p.type = .Regular if fi.type == .Unknown else fi.type
	switch p.type {
	case .Regular:          p.typeflag = '0'
	case .Hard_Link:        p.typeflag = '1'
	case .Symlink:          p.typeflag = '2'
	case .Character_Device: p.typeflag = '3'
	case .Block_Device:     p.typeflag = '4'
	case .Directory:        p.typeflag = '5'
	case .Named_Pipe:       p.typeflag = '6'
	case .Unknown, .Anti:
		return archive.General_Error.Unsupported_Entry
	}
	if p.type == .Symlink || p.type == .Hard_Link {
		if len(fi.link_target) == 0 {
			return archive.General_Error.Incompatible_Options
		}
		if strings.index_byte(fi.link_target, 0) >= 0 {
			return Tar_Error.Invalid_Name
		}
	}
	_entry_name(tw, fi.path, p.type == .Directory) or_return
	p.name = string(tw.name[:])

	buffer: [dynamic]u8
	buffer.allocator = tw.allocator
	defer delete(buffer)
	input: []u8
	reader: io.Reader
	switch d in data {
	case []u8:
		if p.type != .Regular && len(d) > 0 {
			return archive.General_Error.Incompatible_Options
		}
		input  = d
		p.size = i64(len(d))
	case io.Reader:
		if p.type != .Regular {
			return archive.General_Error.Incompatible_Options
		}
		p.size = fi.size
		if p.size < 0 {
			if size, size_err := io.size(d); size_err == nil && size >= 0 {
				p.size = size
			}
		}
		if p.size < 0 {
			_read_unknown(tw, d, &buffer) or_return
			input  = buffer[:]
			p.size = i64(len(buffer))
		} else {
			reader = d
		}
	}

	_build_header(tw, &p, fi) or_return
	if p.long_name {
		_emit_long(tw, 'L', p.name) or_return
	}
	if p.long_link {
		_emit_long(tw, 'K', fi.link_target) or_return
	}
	if len(tw.records) > 0 {
		_emit_records(tw, &p) or_return
	}
	_emit(tw, tw.block[:]) or_return

	p.next = i64(compress.progress_interval(tw.options.options))
	if reader.procedure != nil {
		_copy_reader(tw, &p, reader) or_return
	} else {
		step := WRITE_CHUNK_SIZE
		if tw.options.options.progress != nil {
			step = clamp(compress.progress_interval(tw.options.options), 1, WRITE_CHUNK_SIZE)
		}
		for done := 0; done < len(input); {
			n := min(len(input) - done, step)
			_emit(tw, input[done:][:n]) or_return
			done += n
			_progress(tw, &p, i64(done)) or_return
		}
	}
	_pad(tw, p.size) or_return
	tw.archive_in += p.size
	tw.count      += 1
	return nil
}

@(private)
_copy_reader :: proc(tw: ^Writer, p: ^Pending_Entry, r: io.Reader) -> (err: Error) {
	chunk := _chunk(tw) or_return
	done: i64
	for done < p.size {
		want := int(min(p.size - done, i64(len(chunk))))
		n, read_err := io.read(r, chunk[:want])
		if n > 0 {
			_emit(tw, chunk[:n]) or_return
			done += i64(n)
			_progress(tw, p, done) or_return
			continue
		}
		if read_err == .EOF || read_err == .Unexpected_EOF {
			return Tar_Error.Size_Mismatch
		}
		if read_err != nil {
			return read_err
		}
	}
	probe: [1]u8
	n, probe_err := io.read(r, probe[:])
	if n > 0 {
		return Tar_Error.Size_Mismatch
	}
	if probe_err != nil && probe_err != .EOF {
		return probe_err
	}
	return nil
}

@(private)
_read_unknown :: proc(tw: ^Writer, r: io.Reader, out: ^[dynamic]u8) -> (err: Error) {
	limit := tw.options.options.max_memory
	chunk := _chunk(tw) or_return
	for {
		n, read_err := io.read(r, chunk)
		if n > 0 {
			if limit > 0 && len(out) + n > limit {
				return compress.Error(compress.General_Error.Memory_Limit_Exceeded)
			}
			append(out, ..chunk[:n]) or_return
		}
		if read_err == .EOF {
			return nil
		}
		if read_err != nil {
			return read_err
		}
	}
}

@(private)
_build_header :: proc(tw: ^Writer, p: ^Pending_Entry, fi: archive.File_Info) -> (err: Error) {
	if tw.options.format == .GNU {
		return _build_gnu_header(tw, p, fi)
	}
	clear(&tw.records)
	tw.block = {}
	b := tw.block[:]

	uid, gid := max(fi.uid, 0), max(fi.gid, 0)
	user, group := fi.user, fi.group
	mtime := fi.modification_time
	if tw.options.deterministic {
		uid, gid    = 0, 0
		user, group = "", ""
		mtime       = {}
	}
	link := fi.link_target if p.type == .Symlink || p.type == .Hard_Link else ""
	if !utf8.valid_string(p.name) || !utf8.valid_string(link) || !utf8.valid_string(user) || !utf8.valid_string(group) {
		_add_record(tw, "hdrcharset", "BINARY") or_return
	}

	name := p.name
	if !_is_ascii(name) {
		_add_record(tw, "path", name) or_return
		_put_sanitized(b[0:USTAR_NAME_MAX], name)
	} else if len(name) <= USTAR_NAME_MAX {
		copy(b[0:USTAR_NAME_MAX], name)
	} else if split := _ustar_split(name); split > 0 {
		copy(b[345:][:USTAR_PREFIX_MAX], name[:split])
		copy(b[0:USTAR_NAME_MAX], name[split + 1:])
	} else {
		_add_record(tw, "path", name) or_return
		_put_sanitized(b[0:USTAR_NAME_MAX], name)
	}

	_put_octal(b[100:108], _header_mode(p, fi))

	_put_id(tw, b[108:116], "uid", uid) or_return
	_put_id(tw, b[116:124], "gid", gid) or_return

	if p.type == .Regular && p.size > USTAR_SIZE_MAX {
		buf: [32]u8
		_add_record(tw, "size", strconv.write_int(buf[:], p.size, 10)) or_return
	} else {
		_put_octal(b[124:136], p.size if p.type == .Regular else 0)
	}

	nanos   := time.time_to_unix_nano(mtime)
	seconds := nanos / 1e9
	if tw.options.format == .Ustar {
		seconds = _floor_seconds(nanos)
		if seconds < 0 || seconds > USTAR_SIZE_MAX {
			return archive.General_Error.Incompatible_Options
		}
		_put_octal(b[136:148], seconds)
	} else if nanos % 1e9 != 0 || seconds < 0 || seconds > USTAR_SIZE_MAX {
		buf: [48]u8
		_add_record(tw, "mtime", _pax_time(buf[:], nanos)) or_return
		_put_octal(b[136:148], clamp(seconds, 0, USTAR_SIZE_MAX))
	} else {
		_put_octal(b[136:148], seconds)
	}

	b[156] = p.typeflag
	if p.type == .Symlink || p.type == .Hard_Link {
		target := fi.link_target
		if _is_ascii(target) && len(target) <= USTAR_NAME_MAX {
			copy(b[157:][:USTAR_NAME_MAX], target)
		} else {
			_add_record(tw, "linkpath", target) or_return
			_put_sanitized(b[157:][:USTAR_NAME_MAX], target)
		}
	}
	copy(b[257:263], "ustar\x00")
	copy(b[263:265], "00")
	_put_owner(tw, b[265:297], "uname", user) or_return
	_put_owner(tw, b[297:329], "gname", group) or_return
	if p.type == .Character_Device || p.type == .Block_Device {
		if i64(fi.device[0]) > USTAR_ID_MAX || i64(fi.device[1]) > USTAR_ID_MAX {
			return archive.General_Error.Incompatible_Options
		}
		_put_octal(b[329:337], i64(fi.device[0]))
		_put_octal(b[337:345], i64(fi.device[1]))
	}
	_put_checksum(b)
	if len(tw.records) > HEADER_RECORD_MAX {
		return Tar_Error.Header_Too_Large
	}
	return nil
}

@(private)
_build_gnu_header :: proc(tw: ^Writer, p: ^Pending_Entry, fi: archive.File_Info) -> (err: Error) {
	clear(&tw.records)
	tw.block = {}
	b := tw.block[:]

	p.long_name = len(p.name) > USTAR_NAME_MAX
	copy(b[0:USTAR_NAME_MAX], p.name)

	_put_octal(b[100:108], _header_mode(p, fi))

	uid, gid := max(fi.uid, 0), max(fi.gid, 0)
	user, group := fi.user, fi.group
	mtime, atime := fi.modification_time, fi.access_time
	if tw.options.deterministic {
		uid, gid     = 0, 0
		user, group  = "", ""
		mtime, atime = {}, {}
	}
	_put_gnu_number(b[108:116], uid) or_return
	_put_gnu_number(b[116:124], gid) or_return
	_put_gnu_number(b[124:136], p.size if p.type == .Regular else 0) or_return
	_put_gnu_number(b[136:148], _floor_seconds(time.time_to_unix_nano(mtime))) or_return
	b[156] = p.typeflag

	long := i64(len(p.name) + 1) if p.long_name else 0
	if p.type == .Symlink || p.type == .Hard_Link {
		target := fi.link_target
		p.long_link = len(target) > USTAR_NAME_MAX
		copy(b[157:][:USTAR_NAME_MAX], target)
		if p.long_link {
			long += i64(len(target) + 1)
		}
	}
	copy(b[257:265], GNU_MAGIC)
	for owner in ([2]string{user, group}) {
		if len(owner) > USTAR_OWNER_MAX || strings.index_byte(owner, 0) >= 0 {
			return archive.General_Error.Incompatible_Options
		}
	}
	copy(b[265:297], user)
	copy(b[297:329], group)
	if p.type == .Character_Device || p.type == .Block_Device {
		_put_gnu_number(b[329:337], i64(fi.device[0])) or_return
		_put_gnu_number(b[337:345], i64(fi.device[1])) or_return
	}
	if atime_nanos := time.time_to_unix_nano(atime); atime_nanos != 0 {
		_put_gnu_number(b[345:357], _floor_seconds(atime_nanos)) or_return
	}
	_put_checksum(b)
	if long > HEADER_RECORD_MAX {
		return Tar_Error.Header_Too_Large
	}
	return nil
}

@(private)
_header_mode :: proc "contextless" (p: ^Pending_Entry, fi: archive.File_Info) -> i64 {
	mode := fi.unix_mode & archive.UNIX_PERMISSION_MASK
	if mode == 0 {
		#partial switch p.type {
		case .Directory: mode = 0o755
		case .Symlink:   mode = 0o777
		case:            mode = 0o644
		}
	}
	return i64(mode)
}

@(private)
_emit_long :: proc(tw: ^Writer, typeflag: u8, value: string) -> (err: Error) {
	header: [BLOCK_SIZE]u8
	b := header[:]
	copy(b[0:], GNU_LONG_NAME)
	_put_octal(b[100:108], 0o644)
	_put_octal(b[108:116], 0)
	_put_octal(b[116:124], 0)
	_put_octal(b[124:136], i64(len(value) + 1))
	_put_octal(b[136:148], 0)
	b[156] = typeflag
	copy(b[257:265], GNU_MAGIC)
	copy(b[265:297], "root")
	copy(b[297:329], "root")
	_put_checksum(b)
	_emit(tw, b) or_return
	_emit(tw, transmute([]u8)value) or_return
	terminator := [1]u8{0}
	_emit(tw, terminator[:]) or_return
	return _pad(tw, i64(len(value) + 1))
}

@(private)
_put_gnu_number :: proc "contextless" (field: []u8, value: i64) -> (err: Error) {
	digits := uint(len(field) - 1)
	if value >= 0 && value < i64(1) << (3 * digits) {
		_put_octal(field, value)
		return nil
	}
	if len(field) <= 8 && (value > GNU_BASE256_8_MAX || value < -GNU_BASE256_8_MAX - 1) {
		return archive.General_Error.Incompatible_Options
	}
	v := value
	for i := len(field) - 1; i >= 0; i -= 1 {
		field[i] = u8(v & 0xff)
		v >>= 8
	}
	field[0] |= 0x80
	return nil
}

@(private)
_floor_seconds :: proc "contextless" (nanos: i64) -> (seconds: i64) {
	seconds = nanos / 1e9
	if nanos % 1e9 < 0 {
		seconds -= 1
	}
	return
}

@(private)
_emit_records :: proc(tw: ^Writer, p: ^Pending_Entry) -> (err: Error) {
	header: [BLOCK_SIZE]u8
	b := header[:]
	PAX_PREFIX :: "PaxHeaders/"
	base := p.name
	for len(base) > 0 && base[len(base) - 1] == '/' {
		base = base[:len(base) - 1]
	}
	if slash := strings.last_index_byte(base, '/'); slash >= 0 {
		base = base[slash + 1:]
	}
	copy(b[0:], PAX_PREFIX)
	_put_sanitized(b[len(PAX_PREFIX):USTAR_NAME_MAX], base)
	_put_octal(b[100:108], 0o644)
	_put_octal(b[108:116], 0)
	_put_octal(b[116:124], 0)
	_put_octal(b[124:136], i64(len(tw.records)))
	copy(b[136:148], tw.block[136:148])
	b[156] = 'x'
	copy(b[257:263], "ustar\x00")
	copy(b[263:265], "00")
	_put_checksum(b)
	_emit(tw, b) or_return
	_emit(tw, tw.records[:]) or_return
	return _pad(tw, i64(len(tw.records)))
}

@(private)
_add_record :: proc(tw: ^Writer, key, value: string) -> (err: Error) {
	if tw.options.format == .Ustar {
		return archive.General_Error.Incompatible_Options
	}
	body   := len(key) + len(value) + 3
	digits := len_digits(body)
	for len_digits(body + digits) != digits {
		digits += 1
	}
	buf: [32]u8
	append(&tw.records, strconv.write_int(buf[:], i64(body + digits), 10)) or_return
	append(&tw.records, ' ') or_return
	append(&tw.records, key) or_return
	append(&tw.records, '=') or_return
	append(&tw.records, value) or_return
	append(&tw.records, '\n') or_return
	return nil

	len_digits :: proc "contextless" (n: int) -> (digits: int) {
		n := n
		for {
			digits += 1
			n /= 10
			if n == 0 {
				return
			}
		}
	}
}

@(private)
_put_id :: proc(tw: ^Writer, field: []u8, key: string, id: i64) -> (err: Error) {
	if id > USTAR_ID_MAX {
		buf: [32]u8
		_add_record(tw, key, strconv.write_int(buf[:], id, 10)) or_return
		_put_octal(field, 0)
		return nil
	}
	_put_octal(field, id)
	return nil
}

@(private)
_put_owner :: proc(tw: ^Writer, field: []u8, key, name: string) -> (err: Error) {
	if strings.index_byte(name, 0) >= 0 {
		return archive.General_Error.Incompatible_Options
	}
	if _is_ascii(name) && len(name) <= len(field) {
		copy(field, name)
		return nil
	}
	_add_record(tw, key, name) or_return
	_put_sanitized(field, name)
	return nil
}

@(private)
_ustar_split :: proc "contextless" (name: string) -> (split: int) {
	for i := min(USTAR_PREFIX_MAX, len(name) - 1); i > 0; i -= 1 {
		if name[i] != '/' {
			continue
		}
		rest := len(name) - i - 1
		if rest > USTAR_NAME_MAX {
			return 0
		}
		if rest > 0 {
			return i
		}
	}
	return 0
}

@(private)
_pax_time :: proc(buf: []u8, nanos: i64) -> string {
	b := strings.builder_from_bytes(buf)
	magnitude := u64(nanos) if nanos >= 0 else u64(-(nanos + 1)) + 1
	if nanos < 0 {
		strings.write_byte(&b, '-')
	}
	strings.write_u64(&b, magnitude / 1e9)
	fraction := magnitude % 1e9
	if fraction != 0 {
		digits: [9]u8
		for i := 8; i >= 0; i -= 1 {
			digits[i] = u8('0' + fraction % 10)
			fraction /= 10
		}
		end := 9
		for digits[end - 1] == '0' {
			end -= 1
		}
		strings.write_byte(&b, '.')
		strings.write_bytes(&b, digits[:end])
	}
	return strings.to_string(b)
}

@(private)
_put_octal :: proc "contextless" (field: []u8, value: i64) {
	v := u64(value)
	for i := len(field) - 2; i >= 0; i -= 1 {
		field[i] = u8('0' + v & 7)
		v >>= 3
	}
	field[len(field) - 1] = 0
}

@(private)
_put_checksum :: proc "contextless" (b: []u8) {
	for i in 148..<156 {
		b[i] = ' '
	}
	sum: i64
	for c in b {
		sum += i64(c)
	}
	_put_octal(b[148:155], sum)
	b[155] = ' '
}

@(private)
_put_sanitized :: proc "contextless" (field: []u8, s: string) {
	n := min(len(field), len(s))
	for i in 0..<n {
		c := s[i]
		field[i] = c if c >= 0x20 && c < 0x7f else '_'
	}
}

@(private)
_is_ascii :: proc "contextless" (s: string) -> bool {
	for i in 0..<len(s) {
		if s[i] >= 0x80 || s[i] == 0 {
			return false
		}
	}
	return true
}

@(private)
_emit :: proc(tw: ^Writer, p: []u8) -> (err: Error) {
	if _, write_err := io.write_full(tw.out, p); write_err != nil {
		return write_err
	}
	tw.written += i64(len(p))
	return nil
}

@(private)
_pad :: proc(tw: ^Writer, size: i64) -> (err: Error) {
	zero: [BLOCK_SIZE]u8
	if rest := size % BLOCK_SIZE; rest != 0 {
		return _emit(tw, zero[:BLOCK_SIZE - rest])
	}
	return nil
}

@(private)
_chunk :: proc(tw: ^Writer) -> (chunk: []u8, err: Error) {
	if tw.chunk == nil {
		tw.chunk = make([]u8, WRITE_CHUNK_SIZE, tw.allocator) or_return
	}
	return tw.chunk, nil
}

@(private)
_progress :: proc(tw: ^Writer, p: ^Pending_Entry, done: i64) -> (err: Error) {
	options := tw.options.options
	if options.progress == nil || (done < p.next && done != p.size) {
		return nil
	}
	interval := i64(compress.progress_interval(options))
	p.next = done + interval if interval < max(i64) - done else max(i64)
	progress := compress.Progress{
		bytes_in         = done,
		bytes_out        = done,
		total_in         = p.size,
		total_out        = p.size,
		member           = p.name,
		member_index     = int(tw.count),
		member_count     = -1,
		archive_in       = tw.archive_in + done,
		archive_total_in = -1,
	}
	if options.progress(progress, options.progress_data) {
		return compress.Error(compress.General_Error.Canceled)
	}
	return nil
}

@(private)
_entry_name :: proc(tw: ^Writer, path: string, directory: bool) -> (err: Error) {
	clear(&tw.name)
	name := path
	when ODIN_OS == .Windows {
		if len(name) >= 2 && name[1] == ':' {
			name = name[2:]
		}
	}
	append(&tw.name, name) or_return
	when ODIN_OS == .Windows {
		for &c in tw.name {
			if c == '\\' {
				c = '/'
			}
		}
	}
	start := 0
	for start < len(tw.name) {
		if tw.name[start] == '/' {
			start += 1
		} else if tw.name[start] == '.' && start + 1 < len(tw.name) && tw.name[start + 1] == '/' {
			start += 2
		} else {
			break
		}
	}
	stop := len(tw.name)
	for stop > start && tw.name[stop - 1] == '/' {
		stop -= 1
	}
	cleaned := string(tw.name[start:stop])
	if cleaned == "" || cleaned == "." || strings.index_byte(cleaned, 0) >= 0 {
		return Tar_Error.Invalid_Name
	}
	rest := cleaned
	for part in strings.split_iterator(&rest, "/") {
		if part == ".." {
			return archive.General_Error.Unsafe_Path
		}
	}
	n := copy(tw.name[:], tw.name[start:stop])
	resize(&tw.name, n)
	if directory {
		append(&tw.name, '/') or_return
	}
	return nil
}

@(private)
_walk_name :: proc(tw: ^Writer, root, base, fullpath: string) -> (err: Error) {
	if !strings.has_prefix(fullpath, root) {
		return Tar_Error.Invalid_Name
	}
	rel := fullpath[len(root):]
	for len(rel) > 0 && (rel[0] == '/' || rel[0] == os.Path_Separator) {
		rel = rel[1:]
	}
	clear(&tw.walk_name)
	if base != "" {
		append(&tw.walk_name, base) or_return
		append(&tw.walk_name, '/') or_return
	}
	start := len(tw.walk_name)
	append(&tw.walk_name, rel) or_return
	for &c in tw.walk_name[start:] {
		if c == os.Path_Separator {
			c = '/'
		}
	}
	return nil
}

@(private)
_write_walked :: proc(tw: ^Writer, name: string, info: os.File_Info) -> (err: Error) {
	fi: archive.File_Info
	fi.path              = name
	fi.unix_mode         = transmute(u32)info.mode & archive.UNIX_PERMISSION_MASK
	fi.modification_time = info.modification_time
	#partial switch info.type {
	case .Directory:
		fi.type = .Directory
		return write_entry_with_info(tw, fi, nil)
	case .Symlink:
		target, link_err := os.read_link(info.fullpath, tw.allocator)
		if link_err != nil {
			return link_err
		}
		defer delete(target, tw.allocator)
		fi.type        = .Symlink
		fi.link_target = target
		return write_entry_with_info(tw, fi, nil)
	case .Regular:
		f, open_err := os.open(info.fullpath)
		if open_err != nil {
			return open_err
		}
		defer os.close(f)
		fi.type = .Regular
		fi.size = info.size
		return write_entry_with_info(tw, fi, os.to_reader(f))
	}
	return nil
}
