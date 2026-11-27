#+build !js
package archive_sevenz

import "core:archive"
import "core:compress"
import "core:os"
import "core:slice"
import "core:strings"

// Opens a 7z archive from a path, a byte slice or a stream
open :: proc{open_from_path, open_from_bytes, open_from_stream}

// Starts a new 7z archive at a path or on a stream
create :: proc{create_from_path, create_from_stream}

// Opens a 7z archive at a path or on a stream for changes
update :: proc{update_from_path, update_from_stream}

/*
Opens a 7z archive file

The file is share-locked until `close`, except on wasi. After a crashed update, the reader sees
the last committed state, as the update's journal records it.

*Allocates Using Provided Allocator*

Inputs:
- r: The reader; `close` it when done, it is left closed on an error
- path: The archive's path
- options: Limits and progress callback for the decoders, see `compress.Options` (default: {})
- allocator: (default: context.allocator)
- read_options: The default password, which an encrypted header needs, and the key-derivation
  limit (default: {})

Returns:
- err: `General_Error.Busy` while a writer holds the file, an OS error, a `SevenZ_Error` for a
  malformed archive, `General_Error.Encrypted` or `General_Error.Wrong_Password` for an
  encrypted header, or `nil`
*/
open_from_path :: proc(r: ^Reader, path: string, options := compress.Options{}, allocator := context.allocator, read_options := archive.Read_Options{}) -> (err: Error) {
	s, length, journal := archive._open_view(path, allocator) or_return
	_init(r, options, allocator)
	r.file    = s
	r.journal = journal
	defer if err != nil {
		close(r)
	}
	_read_options(r, read_options) or_return
	r.store = {stream = s, size = length, patches = journal}
	return _load(r)
}

/*
Starts a new 7z archive at a path

The archive is written to `path` plus `archive.TEMP_SUFFIX`, which `commit` renames over
`path`. An existing archive at `path` is locked meanwhile, except on wasi.

*Allocates Using Provided Allocator*

Inputs:
- sw: The writer; `close` it when done, it is left closed on an error
- path: Where the archive goes
- options: The default method, level, filter and password, solid blocks, and more (default: {})
- allocator: (default: context.allocator)

Returns:
- err: Bad options as for `create_from_stream`, `General_Error.Busy` if another process holds
  the archive, an OS error, or `nil`
*/
create_from_path :: proc(sw: ^Writer, path: string, options: Writer_Options = {}, allocator := context.allocator) -> (err: Error) {
	sw^ = {}
	sw.allocator = allocator
	_check_writer_options(options) or_return
	sw.mode = .Create_Path
	defer if err != nil {
		close_writer(sw)
	}
	s := archive._disk_create(&sw.disk, path, options.no_sync, allocator) or_return
	return _writer_init(sw, s, options)
}

/*
Opens a 7z archive at a path to append, replace, remove or rename members

Appends happen in place, under a journal that rolls them back if the process dies before
`commit`. A replacement, remove or rename, or an old header over `UPDATE_SAVED_MAX` bytes, makes
`commit` write a new archive and rename it over the old one. The archive is locked until
`close`, except on wasi.

*Allocates Using Provided Allocator*

Inputs:
- sw: The writer; `close` it when done, it is left closed on an error
- path: The archive's path
- options: The defaults for new members, and more; `password` also opens the archive
  (default: {})
- allocator: (default: context.allocator)

Returns:
- err: Bad options as for `create_from_stream`, `General_Error.Busy` if another process holds
  the archive, an OS error, a `SevenZ_Error` for a malformed archive, or `nil`
*/
update_from_path :: proc(sw: ^Writer, path: string, options: Writer_Options = {}, allocator := context.allocator) -> (err: Error) {
	sw^ = {}
	sw.allocator = allocator
	_check_writer_options(options) or_return
	sw.mode = .Update_Path
	defer if err != nil {
		close_writer(sw)
	}
	s := archive._disk_update(&sw.disk, path, allocator) or_return
	return _update_init(sw, s, options)
}

/*
Adds a directory tree: its directories, regular files and symlinks

Other file types are skipped. With `deterministic` or `solid`, members go in sorted order; with
`solid`, files are first grouped by filter, then ordered by `solid_order`.

Inputs:
- sw: An open writer
- dir: The directory to add
- prefix: Prepended to every member path; when set, `dir` itself is added, named `prefix`
  (default: "")
- options: Every member's method, level, filter and password, in place of the writer's, and
  whether they replace the members an archive being updated has at their paths (default: {})

Returns:
- err: The first error, from the walk or from `write_entry_with_info`, or `nil`
*/
write_directory :: proc(sw: ^Writer, dir: string, prefix := "", options: Entry_Options = {}) -> (err: Error) {
	_writer_ready(sw) or_return
	setup := _resolve(sw.options, options) or_return
	_ = archive._entry_password(options.password, sw.password, sw.options.deterministic) or_return
	walk: archive.Walk
	defer archive._walk_destroy(&walk)
	archive._walk_create(&walk, dir, prefix, sw.options.deterministic || sw.options.solid, sw.allocator) or_return
	if !sw.options.solid {
		for entry in archive._walk_next(&walk) {
			_write_walked(sw, entry.name, entry.info, options, nil) or_return
		}
		return walk.err
	}
	solid := make([]Solid_Entry, len(walk.entries), sw.allocator) or_return
	defer delete(solid, sw.allocator)
	for &entry, i in solid {
		entry.entry = walk.entries[i]
		_group_walked(sw, setup, &entry) or_return
	}
	if sw.options.solid_order == .Extension {
		slice.sort_by(solid, _less_by_extension)
	} else {
		slice.sort_by(solid, _less_by_group)
	}
	for &entry in solid {
		pick := &entry.pick if entry.stream else nil
		_write_walked(sw, entry.name, entry.info, options, pick) or_return
	}
	return nil
}

@(private)
_write_walked :: proc(sw: ^Writer, name: string, info: os.File_Info, options: Entry_Options, pick: ^Filter_Pick) -> (err: Error) {
	fi: archive.File_Info
	fi.path              = name
	fi.unix_mode         = transmute(u32)info.mode & archive.UNIX_PERMISSION_MASK
	fi.modification_time = info.modification_time
	fi.access_time       = info.access_time
	fi.creation_time     = info.creation_time
	#partial switch info.type {
	case .Directory:
		fi.type = .Directory
		return _write_entry(sw, fi, nil, options, nil)
	case .Symlink:
		target, link_err := os.read_link(info.fullpath, sw.allocator)
		if link_err != nil {
			return link_err
		}
		defer delete(target, sw.allocator)
		fi.type        = .Symlink
		fi.link_target = target
		return _write_entry(sw, fi, nil, options, nil)
	case .Regular:
		f, open_err := os.open(info.fullpath)
		if open_err != nil {
			return open_err
		}
		defer os.close(f)
		fi.type = .Regular
		fi.size = info.size
		return _write_entry(sw, fi, os.to_reader(f), options, pick)
	}
	return nil
}

@(private)
_group_walked :: proc(sw: ^Writer, setup: Coder_Setup, entry: ^Solid_Entry) -> (err: Error) {
	#partial switch entry.info.type {
	case .Symlink:
		entry.stream = true
		entry.pick   = {filter = .None}
	case .Regular:
		if entry.info.size <= 0 {
			return nil
		}
		entry.stream = true
		head: []u8
		if setup.filter == .Auto && setup.method != .Store {
			f, open_err := os.open(entry.info.fullpath)
			if open_err != nil {
				return open_err
			}
			defer os.close(f)
			source := Source{reader = os.to_reader(f)}
			head = _read_head(sw, &source) or_return
		}
		entry.pick = _pick_filter(sw, setup, head, entry.info.size)
	}
	return nil
}

@(private)
_less_by_group :: proc(a, b: Solid_Entry) -> bool {
	if a.stream != b.stream {
		return !a.stream
	}
	if a.stream {
		ka, kb := _group_key(a.pick), _group_key(b.pick)
		if ka != kb {
			return ka < kb
		}
	}
	return a.name < b.name
}

@(private)
_less_by_extension :: proc(a, b: Solid_Entry) -> bool {
	if a.stream != b.stream {
		return !a.stream
	}
	if !a.stream {
		return a.name < b.name
	}
	ka, kb := _group_key(a.pick), _group_key(b.pick)
	if ka != kb {
		return ka < kb
	}
	ia, ea, na := _extension(a.name)
	ib, eb, nb := _extension(b.name)
	if ia != ib {
		return ia < ib
	}
	if ea != eb {
		return ea < eb
	}
	if na != nb {
		return na < nb
	}
	return a.name < b.name
}

@(private)
_group_key :: proc "contextless" (pick: Filter_Pick) -> (key: u64) {
	id := u64(0) if pick.filter == .None else u64(_filter_id(pick.filter))
	return id << 16 | u64(_filter_align(pick))
}

@(private)
_extension :: proc "contextless" (name: string) -> (index: int, ext, base: string) {
	slash := strings.last_index_byte(name, '/')
	base = name[slash + 1:]
	dot := strings.last_index_byte(name, '.')
	if dot <= slash {
		return 0, name[len(name):], base
	}
	ext = name[dot + 1:]
	if ext == "" {
		return
	}
	for c in transmute([]u8)ext {
		if c >= 0x80 {
			return
		}
	}
	index = len(SORT_EXTENSIONS) + 1
	for known, i in SORT_EXTENSIONS {
		if len(known) != len(ext) {
			continue
		}
		match := true
		for k in 0..<len(ext) {
			c := ext[k]
			if c >= 'A' && c <= 'Z' {
				c += 'a' - 'A'
			}
			if c != known[k] {
				match = false
				break
			}
		}
		if match {
			index = i + 1
			break
		}
	}
	return
}

@(private)
_archive_open_path :: proc(a: ^archive.Archive, path: string, options: compress.Options, read_options: archive.Read_Options) -> (err: Error) {
	r := new(Reader, a.allocator) or_return
	if err = open_from_path(r, path, options, a.allocator, read_options); err != nil {
		free(r, a.allocator)
		return
	}
	a.state = r
	return
}
