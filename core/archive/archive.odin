package archive

import "base:runtime"
import "core:compress"
import "core:io"
import "core:os"
import "core:strings"

register :: proc "contextless" (format: Format, procs: Format_Procs) {
	assert_contextless(format != .Unknown)
	assert_contextless(!_registered[format])
	assert_contextless(procs.detect != nil && procs.open_bytes != nil && procs.open_stream != nil)
	_procs[format]      = procs
	_registered[format] = true
}

which :: proc(head: []u8) -> (format: Format) {
	for f in _detect_order {
		if _registered[f] && _procs[f].detect(head) {
			return f
		}
	}
	return .Unknown
}

open_from_bytes :: proc(data: []u8, options := compress.Options{}, allocator := context.allocator, read_options := Read_Options{}) -> (a: Archive, err: Error) {
	a.allocator = allocator
	a.format    = which(data[:min(len(data), DETECT_HEAD_SIZE)])
	if a.format == .Unknown {
		return a, General_Error.Unknown_Format
	}
	err = _procs[a.format].open_bytes(&a, data, options, read_options)
	return
}

open_from_stream :: proc(s: io.Stream, options := compress.Options{}, allocator := context.allocator, read_options := Read_Options{}) -> (a: Archive, err: Error) {
	a.allocator = allocator
	a.format    = _detect_stream(s) or_return
	err = _procs[a.format].open_stream(&a, s, options, read_options)
	return
}

open_from_path :: proc(path: string, options := compress.Options{}, allocator := context.allocator, read_options := Read_Options{}) -> (a: Archive, err: Error) {
	a.allocator = allocator
	f := os.open(path) or_return
	format, detect_err := _detect_stream(os.to_stream(f))
	if detect_err != nil {
		os.close(f)
		return a, detect_err
	}
	a.format = format
	if _procs[format].open_path != nil {
		os.close(f)
		err = _procs[format].open_path(&a, path, options, read_options)
		return
	}
	if err = _procs[format].open_stream(&a, os.to_stream(f), options, read_options); err != nil {
		os.close(f)
		return
	}
	a.file = f
	return
}

@(private)
_detect_stream :: proc(s: io.Stream) -> (format: Format, err: Error) {
	start, seek_err := io.seek(s, 0, .Current)
	if seek_err != nil {
		return .Unknown, General_Error.Not_Seekable
	}
	head: [DETECT_HEAD_SIZE]u8
	n := 0
	for n < len(head) {
		got, read_err := io.read(s, head[n:])
		n += got
		if read_err == .EOF {
			break
		}
		if read_err != nil {
			if n == 0 {
				return .Unknown, read_err
			}
			break
		}
		if got == 0 {
			break
		}
	}
	if _, seek_err = io.seek(s, start, .Start); seek_err != nil {
		return .Unknown, General_Error.Not_Seekable
	}
	format = which(head[:n])
	if format == .Unknown {
		return .Unknown, General_Error.Unknown_Format
	}
	return format, nil
}

open :: proc{open_from_path, open_from_bytes, open_from_stream}

close :: proc(a: ^Archive) {
	if a.format != .Unknown && a.state != nil {
		_procs[a.format].close(a)
	}
	if a.file != nil {
		os.close(a.file)
		a.file = nil
	}
	a.state = nil
}

info :: proc(a: ^Archive) -> (info: Archive_Info) {
	return _procs[a.format].info(a)
}

iterator_create :: proc(a: ^Archive) -> (it: Iterator) {
	it.archive = a
	it.err     = _procs[a.format].iterator_create(&it)
	return
}

iterator_destroy :: proc(it: ^Iterator) {
	if it.archive != nil {
		_procs[it.archive.format].iterator_destroy(it)
	}
	it.state = nil
}

iterate :: proc(it: ^Iterator) -> (fi: File_Info, index: int, ok: bool) {
	if it.archive == nil || it.state == nil {
		return {}, -1, false
	}
	return _procs[it.archive.format].iterate(it)
}

@(require_results)
iterator_error :: proc(it: ^Iterator) -> (path: string, err: Error) {
	if it.archive == nil || it.state == nil {
		return "", it.err
	}
	return _procs[it.archive.format].iterator_error(it)
}

extract_current :: proc(it: ^Iterator, w: io.Writer, options := Read_Options{}) -> (err: Error) {
	return _procs[it.archive.format].extract_current(it, w, options)
}

open_current :: proc(it: ^Iterator, options := Read_Options{}) -> (r: io.Reader, err: Error) {
	return _procs[it.archive.format].open_current(it, options)
}

read_link :: proc(it: ^Iterator, allocator := context.allocator) -> (target: string, err: Error) {
	return _procs[it.archive.format].read_link(it, allocator)
}

find :: proc(a: ^Archive, path: string) -> (fi: File_Info, handle: Handle, ok: bool, err: Error) {
	return _procs[a.format].find(a, path)
}

extract :: proc(a: ^Archive, handle: Handle, w: io.Writer, options := Read_Options{}) -> (err: Error) {
	return _procs[a.format].extract(a, handle, w, options)
}

open_member :: proc(a: ^Archive, handle: Handle, options := Read_Options{}) -> (r: io.Reader, err: Error) {
	return _procs[a.format].open_member(a, handle, options)
}

close_member :: proc(r: io.Reader) {
	io.destroy(r)
}

clean_member_path :: proc "contextless" (path: string) -> (cleaned: string) {
	cleaned = path
	for len(cleaned) >= 2 && cleaned[0] == '.' && cleaned[1] == '/' {
		cleaned = cleaned[2:]
		for len(cleaned) > 0 && cleaned[0] == '/' {
			cleaned = cleaned[1:]
		}
	}
	for len(cleaned) > 1 && cleaned[len(cleaned) - 1] == '/' {
		cleaned = cleaned[:len(cleaned) - 1]
	}
	return
}

file_info_clone :: proc(fi: File_Info, allocator: runtime.Allocator) -> (cloned: File_Info, err: runtime.Allocator_Error) {
	cloned = fi
	cloned.path        = ""
	cloned.raw_path    = nil
	cloned.link_target = ""
	cloned.comment     = ""
	cloned.user        = ""
	cloned.group       = ""
	defer if err != nil {
		file_info_delete(cloned, allocator)
	}
	cloned.path        = strings.clone(fi.path, allocator) or_return
	cloned.raw_path    = make([]u8, len(fi.raw_path), allocator) or_return
	copy(cloned.raw_path, fi.raw_path)
	cloned.link_target = strings.clone(fi.link_target, allocator) or_return
	cloned.comment     = strings.clone(fi.comment, allocator) or_return
	cloned.user        = strings.clone(fi.user, allocator) or_return
	cloned.group       = strings.clone(fi.group, allocator) or_return
	return
}

file_info_delete :: proc(fi: File_Info, allocator: runtime.Allocator) {
	delete(fi.path, allocator)
	delete(fi.raw_path, allocator)
	delete(fi.link_target, allocator)
	delete(fi.comment, allocator)
	delete(fi.user, allocator)
	delete(fi.group, allocator)
}

to_os_permissions :: proc "contextless" (fi: File_Info) -> (permissions: os.Permissions) {
	return transmute(os.Permissions)(fi.unix_mode & 0o777)
}

to_os_file_type :: proc "contextless" (fi: File_Info) -> (type: os.File_Type) {
	switch fi.type {
	case .Regular:          return .Regular
	case .Directory:        return .Directory
	case .Symlink:          return .Symlink
	case .Named_Pipe:       return .Named_Pipe
	case .Character_Device: return .Character_Device
	case .Block_Device:     return .Block_Device
	case .Hard_Link, .Anti, .Unknown:
	}
	return .Undetermined
}

unix_type_bits :: proc "contextless" (type: Entry_Type) -> (bits: u32) {
	switch type {
	case .Regular, .Hard_Link: return UNIX_REGULAR
	case .Directory:           return UNIX_DIRECTORY
	case .Symlink:             return UNIX_SYMLINK
	case .Named_Pipe:          return UNIX_NAMED_PIPE
	case .Character_Device:    return UNIX_CHARACTER_DEVICE
	case .Block_Device:        return UNIX_BLOCK_DEVICE
	case .Anti, .Unknown:
	}
	return 0
}

dos_attributes_from_unix :: proc "contextless" (unix_mode: u32, type: Entry_Type) -> (attributes: u32) {
	if type == .Directory {
		attributes |= DOS_DIRECTORY
	} else {
		attributes |= DOS_ARCHIVE
	}
	if unix_mode & 0o222 == 0 {
		attributes |= DOS_READ_ONLY
	}
	return
}

unix_mode_from_dos :: proc "contextless" (attributes: u32) -> (unix_mode: u32) {
	if attributes & DOS_DIRECTORY != 0 {
		unix_mode = UNIX_DIRECTORY | 0o755
	} else {
		unix_mode = UNIX_REGULAR | 0o644
	}
	if attributes & DOS_READ_ONLY != 0 {
		unix_mode &~= 0o222
	}
	return
}
