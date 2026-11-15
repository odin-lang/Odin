package archive_sevenz

import "core:archive"
import "core:archive/transaction"
import "core:compress/lzma"
import "core:compress/ppmd"
import "core:encoding/endian"
import "core:io"
import "core:os"
import "core:slice"
import "core:strings"

update_from_path :: proc(sw: ^Writer, path: string, options: Writer_Options = {}, allocator := context.allocator) -> (err: Error) {
	sw^ = {}
	sw.allocator = allocator
	_check_writer_options(options) or_return
	sw.mode = .Update_Path
	defer if err != nil {
		close_writer(sw)
	}
	sw.path         = strings.clone(path, allocator) or_return
	sw.temp_path    = transaction.sibling_path(path, transaction.TEMP_SUFFIX, allocator) or_return
	sw.journal_path = transaction.sibling_path(path, transaction.JOURNAL_SUFFIX, allocator) or_return
	sw.file = transaction.lock_open(path, .Exclusive, false, allocator) or_return
	transaction.recover(sw.file, sw.journal_path, allocator) or_return
	transaction.clear_stale(sw.temp_path, allocator) or_return
	return _update_init(sw, os.to_stream(sw.file), options)
}

update_from_stream :: proc(sw: ^Writer, s: io.Stream, options: Writer_Options = {}, allocator := context.allocator) -> (err: Error) {
	sw^ = {}
	sw.allocator = allocator
	_check_writer_options(options) or_return
	sw.mode = .Update_Stream
	if err = _update_init(sw, s, options); err != nil {
		close_writer(sw)
	}
	return
}

update :: proc{update_from_path, update_from_stream}

remove_entry :: proc(sw: ^Writer, path: string) -> (err: Error) {
	_writer_ready(sw) or_return
	if sw.mode != .Update_Path {
		return archive.General_Error.Incompatible_Options
	}
	want := archive.clean_member_path(path)
	head := _old_head(sw, want) or_return
	delete_key(&sw.heads, want)
	for i := head; i >= 0; i = sw.slots[i].next {
		sw.slots[i].removed = true
	}
	sw.modified = true
	return nil
}

rename_entry :: proc(sw: ^Writer, old_path, new_path: string) -> (err: Error) {
	_writer_ready(sw) or_return
	if sw.mode != .Update_Path {
		return archive.General_Error.Incompatible_Options
	}
	want := archive.clean_member_path(old_path)
	head := _old_head(sw, want) or_return
	_entry_name(sw, new_path) or_return
	target := archive.clean_member_path(string(sw.name[:]))
	if target == want {
		return nil
	}
	if target in sw.heads {
		return archive.General_Error.Exists
	}

	count := 0
	for i := head; i >= 0; i = sw.slots[i].next {
		count += 1
	}
	names := make([][]u8, count, sw.allocator) or_return
	defer delete(names, sw.allocator)
	made := 0
	defer if err != nil {
		for name in names[:made] {
			delete(name, sw.allocator)
		}
	}
	for _ in 0..<count {
		names[made] = slice.clone(sw.name[:], sw.allocator) or_return
		made += 1
	}
	reserve(&sw.heads, len(sw.heads) + 1) or_return

	delete_key(&sw.heads, want)
	k := 0
	for i := head; i >= 0; i = sw.slots[i].next {
		slot := &sw.slots[i]
		delete(slot.raw_name, sw.allocator)
		slot.raw_name = names[k]
		slot.name     = archive.clean_member_path(string(slot.raw_name))
		slot.renamed  = true
		k += 1
	}
	sw.heads[sw.slots[head].name] = head
	sw.modified = true
	return nil
}

write_anti_item :: proc(sw: ^Writer, path: string, directory := false) -> (err: Error) {
	_writer_ready(sw) or_return
	_entry_name(sw, path) or_return
	_name_check(sw) or_return
	return _add_file(sw, Out_File{is_anti = true, is_directory = directory, no_attributes = true})
}

@(private)
_is_update :: proc "contextless" (sw: ^Writer) -> bool {
	return sw.mode == .Update_Path || sw.mode == .Update_Stream
}

@(private)
_old_head :: proc(sw: ^Writer, want: string) -> (head: int, err: Error) {
	found: bool
	head, found = sw.heads[want]
	if !found {
		return -1, archive.General_Error.Not_Found
	}
	for i := head; i >= 0; i = sw.slots[i].next {
		if sw.slots[i].item < 0 {
			return -1, archive.General_Error.Incompatible_Options
		}
	}
	return
}

@(private)
_name_check :: proc(sw: ^Writer) -> (err: Error) {
	if !_is_update(sw) || sw.repacking {
		return nil
	}
	if archive.clean_member_path(string(sw.name[:])) in sw.heads {
		return archive.General_Error.Exists
	}
	reserve(&sw.slots, len(sw.slots) + 1) or_return
	reserve(&sw.heads, len(sw.heads) + 1) or_return
	return nil
}

@(private)
_name_register :: proc(sw: ^Writer) -> (err: Error) {
	if !_is_update(sw) || sw.repacking {
		return nil
	}
	raw := slice.clone(sw.name[:], sw.allocator) or_return
	_slot_link(sw, {raw_name = raw, name = archive.clean_member_path(string(raw)), item = -1, next = -1})
	return nil
}

@(private)
_slot_link :: proc(sw: ^Writer, slot: Update_Slot) {
	slot := slot
	index := len(sw.slots)
	if head, found := sw.heads[slot.name]; found {
		slot.next = head
	}
	append(&sw.slots, slot)
	sw.heads[slot.name] = index
}

@(private)
_update_init :: proc(sw: ^Writer, s: io.Stream, options: Writer_Options) -> (err: Error) {
	modes := io.query(s)
	if .Write not_in modes || .Seek not_in modes {
		return archive.General_Error.Not_Seekable
	}
	read_options := options.options
	read_options.progress      = nil
	read_options.progress_data = nil
	open_from_stream(&sw.old, s, read_options, sw.allocator, {password = options.password}) or_return
	_writer_setup(sw, s, options) or_return

	streams := &sw.old.streams
	packed  := i64(0)
	for size in streams.pack_sizes {
		packed += size
	}
	sw.start      = 0
	sw.old_length = sw.old.store.size
	sw.end        = sw.old_length
	if packed > 0 {
		sw.pack_pos   = streams.pack_offsets[0] - SIGNATURE_HEADER_SIZE
		sw.data_start = streams.pack_offsets[0] + packed
	} else {
		sw.pack_pos   = sw.old_length - SIGNATURE_HEADER_SIZE
		sw.data_start = sw.old_length
	}
	if sw.mode == .Update_Path && sw.old_length - sw.data_start > UPDATE_SAVED_MAX {
		sw.data_start   = sw.old_length
		sw.must_rewrite = true
	}
	_seek(sw, sw.data_start) or_return

	reserve(&sw.slots, len(sw.old.items)) or_return
	reserve(&sw.heads, len(sw.old.items)) or_return
	for &item, i in sw.old.items {
		_slot_link(sw, {name = archive.clean_member_path(item.path), item = i, next = -1})
	}
	sw.guard  = true
	sw.active = true
	return nil
}

@(private)
_journal_begin :: proc(sw: ^Writer) -> (err: Error) {
	if !sw.guard || sw.journaled {
		return nil
	}
	ranges: [2]transaction.Range
	count := 1
	defer if err != nil {
		for r in ranges[:count] {
			delete(r.data, sw.allocator)
		}
	}
	ranges[0].data = make([]u8, SIGNATURE_HEADER_SIZE, sw.allocator) or_return
	_store_read(&sw.old.store, ranges[0].data, 0) or_return
	if sw.data_start < sw.old_length {
		count = 2
		ranges[1].offset = sw.data_start
		ranges[1].data   = make([]u8, int(sw.old_length - sw.data_start), sw.allocator) or_return
		_store_read(&sw.old.store, ranges[1].data, sw.data_start) or_return
	}
	saved := slice.clone(ranges[:count], sw.allocator) or_return
	if sw.mode == .Update_Path {
		if journal_err := transaction.journal_write(sw.journal_path, sw.file, sw.old_length, sw.data_start, saved, sw.allocator); journal_err != nil {
			delete(saved, sw.allocator)
			return journal_err
		}
	}
	sw.saved     = saved
	sw.journaled = true
	return nil
}

@(private)
_restore_original :: proc(sw: ^Writer) -> (err: Error) {
	if !sw.journaled {
		return nil
	}
	if sw.mode == .Update_Path {
		transaction.restore(sw.file, sw.old_length, sw.saved) or_return
		transaction.journal_remove(sw.journal_path, sw.allocator) or_return
	} else {
		sw.guard = false
		for r in sw.saved {
			_seek(sw, r.offset) or_return
			_emit(sw, r.data) or_return
		}
		_flush(sw) or_return
	}
	sw.journaled = false
	return nil
}

@(private)
_abort :: proc(sw: ^Writer) {
	#partial switch sw.mode {
	case .Update_Path:
		transaction.remove_held(&sw.temp, sw.temp_path)
		if sw.file != nil {
			_restore_original(sw)
		}
	case .Update_Stream:
		_restore_original(sw)
	}
}

@(private)
_commit_update :: proc(sw: ^Writer) -> (err: Error) {
	if sw.folder.active {
		_folder_close(sw) or_return
	}
	switch {
	case len(sw.files) == 0 && !sw.modified:
		_restore_original(sw) or_return
	case sw.modified || sw.must_rewrite:
		_commit_rewrite(sw) or_return
	case:
		_commit_in_place(sw) or_return
	}
	if sw.mode == .Update_Path && sw.file != nil {
		os.close(sw.file)
		sw.file = nil
	}
	return nil
}

@(private)
_commit_in_place :: proc(sw: ^Writer) -> (err: Error) {
	_journal_begin(sw) or_return
	clear(&sw.kept)
	for _, i in sw.old.streams.folders {
		append(&sw.kept, i) or_return
	}
	files: [dynamic]Out_File
	names: [dynamic]u8
	files.allocator = sw.allocator
	names.allocator = sw.allocator
	defer {
		delete(files)
		delete(names)
	}
	_update_files(sw, &files, &names, true) or_return
	start := _write_header(sw, files[:], names[:]) or_return
	end := sw.offset
	_flush(sw) or_return
	if sw.mode == .Update_Path {
		if end < sw.end {
			if truncate_err := os.truncate(sw.file, end); truncate_err != nil {
				return truncate_err
			}
			sw.end = end
		}
		if sync_err := os.sync(sw.file); sync_err != nil {
			return sync_err
		}
	}
	_seek(sw, 0) or_return
	_emit(sw, start[:]) or_return
	_seek(sw, end) or_return
	_flush(sw) or_return
	if sw.mode == .Update_Path {
		if sync_err := os.sync(sw.file); sync_err != nil {
			return sync_err
		}
		transaction.journal_remove(sw.journal_path, sw.allocator) or_return
	}
	sw.journaled = false
	return nil
}

@(private)
_commit_rewrite :: proc(sw: ^Writer) -> (err: Error) {
	old     := &sw.old
	streams := &old.streams
	survivors := make([]int, len(streams.folders), sw.allocator) or_return
	defer delete(survivors, sw.allocator)
	for &slot in sw.slots[:len(old.items)] {
		item := &old.items[slot.item]
		if !slot.removed && item.has_stream {
			survivors[item.folder] += 1
		}
	}
	clear(&sw.kept)
	for f, i in streams.folders {
		if survivors[i] > 0 && survivors[i] == f.stream_count {
			append(&sw.kept, i) or_return
		}
	}
	for f, i in streams.folders {
		if survivors[i] > 0 && survivors[i] < f.stream_count {
			_repack(sw, i) or_return
		}
	}
	if sw.folder.active {
		_folder_close(sw) or_return
	}
	data_end := sw.offset
	original := sw.stream

	sw.temp = transaction.lock_open(sw.temp_path, .Exclusive, true, sw.allocator) or_return
	if truncate_err := os.truncate(sw.temp, 0); truncate_err != nil {
		return truncate_err
	}
	sw.stream   = os.to_stream(sw.temp)
	sw.guard    = false
	sw.start    = 0
	sw.offset   = 0
	sw.end      = 0
	sw.pack_pos = 0
	placeholder: [SIGNATURE_HEADER_SIZE]u8
	_emit(sw, placeholder[:]) or_return
	chunk := _chunk(sw) or_return
	for index in sw.kept {
		f := &streams.folders[index]
		_copy_out(sw, original, streams.pack_offsets[f.first_pack], f.pack_size, chunk) or_return
	}
	_copy_out(sw, original, sw.data_start, data_end - sw.data_start, chunk) or_return

	files: [dynamic]Out_File
	names: [dynamic]u8
	files.allocator = sw.allocator
	names.allocator = sw.allocator
	defer {
		delete(files)
		delete(names)
	}
	_update_files(sw, &files, &names, false) or_return
	start := _write_header(sw, files[:], names[:]) or_return
	end := sw.offset
	_seek(sw, 0) or_return
	_emit(sw, start[:]) or_return
	_seek(sw, end) or_return
	_flush(sw) or_return
	if sync_err := os.sync(sw.temp); sync_err != nil {
		return sync_err
	}
	_restore_original(sw) or_return
	return transaction.publish(sw.temp_path, sw.path, &sw.temp, &sw.file, sw.allocator)
}

@(private)
_copy_out :: proc(sw: ^Writer, src: io.Stream, from, count: i64, chunk: []u8) -> (err: Error) {
	done: i64
	for done < count {
		n := int(min(count - done, i64(len(chunk))))
		got := 0
		for got < n {
			read, read_err := io.read_at(src, chunk[got:n], from + done + i64(got))
			got += read
			if got == n {
				break
			}
			if read_err == .EOF || read_err == .Unexpected_EOF || (read_err == nil && read == 0) {
				return SevenZ_Error.Truncated
			}
			if read_err != nil {
				return read_err
			}
		}
		_emit(sw, chunk[:n]) or_return
		done += i64(n)
	}
	return nil
}

@(private)
_update_files :: proc(sw: ^Writer, files: ^[dynamic]Out_File, names: ^[dynamic]u8, all_old: bool) -> (err: Error) {
	old := &sw.old
	kept := make([]bool, len(old.streams.folders), sw.allocator) or_return
	defer delete(kept, sw.allocator)
	for index in sw.kept {
		kept[index] = true
	}
	reserve(files, len(old.items) + len(sw.files)) or_return
	for &slot in sw.slots[:len(old.items)] {
		item := &old.items[slot.item]
		if slot.removed {
			continue
		}
		if !all_old && item.has_stream && !kept[item.folder] {
			continue
		}
		append(files, _old_file(item)) or_return
		if slot.renamed {
			_append_name(names, slot.raw_name) or_return
		} else {
			reserve(names, len(names) + len(item.raw_path) + 2) or_return
			append(names, ..item.raw_path)
			append(names, 0, 0)
		}
	}
	append(files, ..sw.files[:]) or_return
	append(names, ..sw.names[:]) or_return
	return nil
}

@(private)
_old_file :: proc(item: ^Item) -> (file: Out_File) {
	crc, has_crc := item.crc.?
	attributes, has_attributes := item.attributes.?
	file.size              = item.size
	file.crc               = crc
	file.no_crc            = !has_crc
	file.attributes        = attributes
	file.no_attributes     = !has_attributes
	file.modification_time = item.modification_time.? or_else 0
	file.creation_time     = item.creation_time.? or_else 0
	file.access_time       = item.access_time.? or_else 0
	file.has_stream        = item.has_stream
	file.is_directory      = item.is_directory
	file.is_anti           = item.is_anti
	return
}

@(private)
_repack :: proc(sw: ^Writer, index: int) -> (err: Error) {
	old := &sw.old
	f   := &old.streams.folders[index]
	entry, pick, own := _folder_entry(sw, f)
	if sw.folder.active {
		_folder_close(sw) or_return
	}
	saved := sw.options
	sw.options.solid       = true
	sw.options.solid_size  = max(i64)
	sw.options.solid_files = 0
	sw.repacking = true
	defer {
		sw.options   = saved
		sw.repacking = false
	}
	d: Folder_Decoder
	_decoder_init(&d, &old.store, &old.streams, index, old.options, sw.allocator, &old.keys, old.password) or_return
	defer _decoder_destroy(&d)
	preset := &pick if own else nil
	for &slot in sw.slots[:len(old.items)] {
		item := &old.items[slot.item]
		if slot.removed || !item.has_stream || item.folder != index {
			continue
		}
		_decoder_skip(&d, item.folder_offset) or_return
		fi := _info(old, slot.item)
		if slot.renamed {
			fi.path = string(slot.raw_name)
		}
		data: Entry_Data
		m: Member
		if fi.type == .Symlink {
			fi.link_target = _read_link(old, slot.item, &d, sw.allocator, old.password) or_return
		} else {
			fi.type = .Regular
			_member_init(&m, old, slot.item, &d, sw.allocator, old.password) or_return
			data = io.Reader(_member_stream(&m))
		}
		err = _write_entry(sw, fi, data, entry, preset)
		_member_destroy(&m)
		if fi.type == .Symlink {
			delete(fi.link_target, sw.allocator)
		}
		if err != nil {
			return
		}
		file := &sw.files[len(sw.files) - 1]
		meta := _old_file(item)
		file.attributes        = meta.attributes
		file.no_attributes     = meta.no_attributes
		file.modification_time = meta.modification_time
		file.creation_time     = meta.creation_time
		file.access_time       = meta.access_time
	}
	if sw.folder.active {
		_folder_close(sw) or_return
	}
	return nil
}

@(private)
_folder_entry :: proc(sw: ^Writer, f: ^Folder) -> (entry: Entry_Options, pick: Filter_Pick, own: bool) {
	s      := &sw.old.streams
	coders := s.coders[f.first_coder:][:f.coder_count]
	binds  := s.bind_pairs[f.first_bind:][:f.bind_count]
	entry.password = sw.password if f.encrypted else ""

	main: ^Coder
	index := f.unpack_coder
	for _ in 0..<f.coder_count {
		c := &coders[index]
		#partial switch c.kind {
		case .Copy, .LZMA, .LZMA2, .PPMd, .Deflate, .Deflate64, .BZip2:
			main = c
		}
		if main != nil {
			break
		}
		next := -1
		for b in binds {
			if b.in_index == c.first_in {
				next = b.out_index
				break
			}
		}
		if next < 0 {
			break
		}
		index = next
	}
	if main == nil || card(f.filters) > 1 {
		return {password = entry.password}, {}, false
	}

	props := main.properties
	#partial switch main.kind {
	case .Copy:
		entry.method = .Store
	case .LZMA:
		if len(props) < 5 || props[0] >= 9 * 5 * 5 {
			return {password = entry.password}, {}, false
		}
		options := lzma.level_options(lzma.Level(_default_level(.LZMA)))
		options.lc        = props[0] % 9
		options.lp        = props[0] / 9 % 5
		options.pb        = props[0] / 45
		options.dict_size = max(endian.unchecked_get_u32le(props[1:]), lzma.DICT_SIZE_MIN)
		entry.method = .LZMA
		entry.lzma   = options
	case .LZMA2:
		if len(props) < 1 || props[0] > 40 {
			return {password = entry.password}, {}, false
		}
		options := lzma.level_options(lzma.Level(_default_level(.LZMA2)))
		options.lc, options.lp, options.pb = 3, 0, 2
		options.dict_size = max(u32(0xFFFF_FFFF) if props[0] == 40 else (2 | u32(props[0] & 1)) << (props[0] / 2 + 11), lzma.DICT_SIZE_MIN)
		entry.method = .LZMA2
		entry.lzma   = options
	case .PPMd:
		if len(props) < 5 {
			return {password = entry.password}, {}, false
		}
		properties := ppmd.level_properties(.H)
		properties.order    = props[0]
		properties.mem_size = endian.unchecked_get_u32le(props[1:])
		entry.method = .PPMd_H
		entry.ppmd   = properties
	case .BZip2:
		entry.method = .BZip2
	case .Deflate:
		entry.method = .Deflate
	case .Deflate64:
		entry.method = .Deflate64
	}

	pick = {filter = .None}
	for filter in f.filters {
		switch filter {
		case .Delta:
			pick.filter = .Delta
			pick.delta  = 1
			for c in coders {
				if c.kind == .Delta && len(c.properties) > 0 {
					pick.delta = int(c.properties[0]) + 1
				}
			}
		case .BCJ_X86:   pick.filter = .BCJ_X86
		case .BCJ_PPC:   pick.filter = .BCJ_PPC
		case .BCJ_IA64:  pick.filter = .BCJ_IA64
		case .BCJ_ARM:   pick.filter = .BCJ_ARM
		case .BCJ_ARMT:  pick.filter = .BCJ_ARMT
		case .BCJ_SPARC: pick.filter = .BCJ_SPARC
		case .BCJ_ARM64: pick.filter = .BCJ_ARM64
		case .BCJ_RISCV: pick.filter = .BCJ_RISCV
		case .BCJ2:      pick.filter = .BCJ2
		case .Swap2:     pick.filter = .Swap2
		case .Swap4:     pick.filter = .Swap4
		}
	}
	entry.filter         = pick.filter
	entry.delta_distance = pick.delta
	return entry, pick, true
}
