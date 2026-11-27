package archive

import "base:runtime"
import "core:compress"
import "core:crypto"
import "core:io"

Format_Procs :: struct {
	detect:           proc(head: []u8) -> bool,
	open_bytes:       proc(a: ^Archive, data: []u8, options: compress.Options, read_options: Read_Options) -> Error,
	open_stream:      proc(a: ^Archive, s: io.Stream, options: compress.Options, read_options: Read_Options) -> Error,
	open_path:        proc(a: ^Archive, path: string, options: compress.Options, read_options: Read_Options) -> Error,
	close:            proc(a: ^Archive),
	info:             proc(a: ^Archive) -> Archive_Info,
	iterator_create:  proc(it: ^Iterator) -> Error,
	iterator_destroy: proc(it: ^Iterator),
	iterate:          proc(it: ^Iterator) -> (fi: File_Info, index: int, ok: bool),
	iterator_error:   proc(it: ^Iterator) -> (path: string, err: Error),
	extract_current:  proc(it: ^Iterator, w: io.Writer, options: Read_Options) -> Error,
	open_current:     proc(it: ^Iterator, options: Read_Options) -> (r: io.Reader, err: Error),
	read_link:        proc(it: ^Iterator, options: Read_Options, allocator: runtime.Allocator) -> (target: string, err: Error),
	find:             proc(a: ^Archive, path: string) -> (fi: File_Info, handle: Handle, ok: bool, err: Error),
	extract:          proc(a: ^Archive, handle: Handle, w: io.Writer, options: Read_Options) -> Error,
	open_member:      proc(a: ^Archive, handle: Handle, options: Read_Options) -> (r: io.Reader, err: Error),
}

_register :: proc "contextless" (format: Format, procs: Format_Procs) {
	assert_contextless(format != .Unknown)
	assert_contextless(!_registered[format])
	assert_contextless(procs.detect != nil && procs.open_bytes != nil && procs.open_stream != nil)
	_procs[format]      = procs
	_registered[format] = true
}

_clean_member_path :: proc "contextless" (path: string) -> (cleaned: string) {
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

_unix_type_bits :: proc "contextless" (type: Entry_Type) -> (bits: u32) {
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

_dos_attributes_from_unix :: proc "contextless" (unix_mode: u32, type: Entry_Type) -> (attributes: u32) {
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

_unix_mode_from_dos :: proc "contextless" (attributes: u32) -> (unix_mode: u32) {
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

_secret_clone :: proc(secret: string, allocator: runtime.Allocator) -> (clone: string, err: runtime.Allocator_Error) {
	if secret == "" {
		return "", nil
	}
	buf := make([]u8, len(secret), allocator) or_return
	copy(buf, secret)
	return string(buf), nil
}

_secret_delete :: proc(secret: []u8, allocator: runtime.Allocator) {
	if len(secret) == 0 {
		return
	}
	crypto.zero_explicit(raw_data(secret), len(secret))
	delete(secret, allocator)
}

_check_password :: proc(password: string, deterministic: bool) -> (err: Error) {
	if password == "" {
		return nil
	}
	if deterministic {
		return General_Error.Incompatible_Options
	}
	if !crypto.HAS_RAND_BYTES {
		return General_Error.Unsupported_Method
	}
	return nil
}

_entry_password :: proc(entry: Maybe(string), password: string, deterministic: bool) -> (result: string, err: Error) {
	result = entry.? or_else password
	_check_password(result, deterministic) or_return
	return
}
