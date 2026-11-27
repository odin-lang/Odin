package archive

import "base:runtime"
import "core:compress"
import "core:io"
import "core:strings"

/*
Detects an archive's format from its first bytes

An archive behind other data, such as a self-extracting `.exe`'s stub, isn't recognized; `open`
still finds a zip archive there, or a 7z archive behind an executable's stub.

Inputs:
- head: The archive's first bytes; `DETECT_HEAD_SIZE` of them are enough

Returns:
- format: The first registered format that recognizes them, trying 7z, zip and tar in that order,
  or `.Unknown`
*/
which :: proc(head: []u8) -> (format: Format) {
	for f in _detect_order {
		if _registered[f] && _procs[f].detect(head) {
			return f
		}
	}
	return .Unknown
}

/*
Opens an archive held in memory, detecting its format

Data `which` doesn't recognize opens as zip when it ends in a zip archive, as a self-extracting
`.exe` does, else as 7z when it is an executable (MZ, ELF or Mach-O) with a 7z archive starting
in its first `sevenz.SFX_SEARCH_MAX` bytes.

*Allocates Using Provided Allocator*

Inputs:
- data: The archive's bytes; they must stay valid until `close`
- options: Limits and progress callback for the decoders, see `compress.Options` (default: {})
- allocator: (default: context.allocator)
- read_options: 7z's default password and key-derivation limit; the others ignore them
  (default: {})

Returns:
- a: The archive; `close` it when done
- err: `General_Error.Unknown_Format` if no registered format recognizes it, the format's error,
  or `nil`
*/
open_from_bytes :: proc(data: []u8, options := compress.Options{}, allocator := context.allocator, read_options := Read_Options{}) -> (a: Archive, err: Error) {
	a.allocator = allocator
	err = _open_detected(&a, data[:min(len(data), DETECT_HEAD_SIZE)], data, options, read_options)
	return
}

/*
Opens an archive from a stream, detecting its format

Data `which` doesn't recognize opens as zip when it ends in a zip archive, as a self-extracting
`.exe` does, else as 7z when it is an executable (MZ, ELF or Mach-O) with a 7z archive starting
in its first `sevenz.SFX_SEARCH_MAX` bytes.

*Allocates Using Provided Allocator*

Inputs:
- s: The archive; it must seek, and stay open until `close`, which leaves it open
- options: Limits and progress callback for the decoders, see `compress.Options` (default: {})
- allocator: (default: context.allocator)
- read_options: 7z's default password and key-derivation limit; the others ignore them
  (default: {})

Returns:
- a: The archive; `close` it when done
- err: `General_Error.Not_Seekable`, `General_Error.Unknown_Format`, the format's error, or `nil`
*/
open_from_stream :: proc(s: io.Stream, options := compress.Options{}, allocator := context.allocator, read_options := Read_Options{}) -> (a: Archive, err: Error) {
	a.allocator = allocator
	head: [DETECT_HEAD_SIZE]u8
	n := _read_head(s, head[:]) or_return
	err = _open_detected(&a, head[:n], s, options, read_options)
	return
}

/*
Closes an archive and frees its memory

Inputs:
- a: The archive; a stream given to `open_from_stream` is left open
*/
close :: proc(a: ^Archive) {
	if a.format != .Unknown && a.state != nil {
		_procs[a.format].close(a)
	}
	io.close(a.file)
	a.file  = {}
	a.state = nil
}

/*
Summarizes an archive

Inputs:
- a: An open archive

Returns:
- info: Its format, member count, comment and compression method
*/
info :: proc(a: ^Archive) -> (info: Archive_Info) {
	return _procs[a.format].info(a)
}

/*
Creates an iterator over an archive's members, in storage order

NOTE: A tar reader has one position, which its iterators, `find`, `extract` and `open_member`
share; creating an iterator rewinds it.

Inputs:
- a: An open archive

Returns:
- it: The iterator; destroy it with `iterator_destroy`
*/
iterator_create :: proc(a: ^Archive) -> (it: Iterator) {
	it.archive = a
	it.err     = _procs[a.format].iterator_create(&it)
	return
}

/*
Destroys an iterator, along with the reader `open_current` returned

Inputs:
- it: The iterator
*/
iterator_destroy :: proc(it: ^Iterator) {
	if it.archive != nil {
		_procs[it.archive.format].iterator_destroy(it)
	}
	it.state = nil
}

/*
Moves to the next member

Inputs:
- it: The iterator

Returns:
- fi: The member's info; its strings last until the next `iterate` (until `close` for zip and 7z),
  so keep them with `file_info_clone`
- index: The member's index, as in `fi.handle`
- ok: `false` after the last member or on an error; `iterator_error` tells which
*/
iterate :: proc(it: ^Iterator) -> (fi: File_Info, index: int, ok: bool) {
	if it.archive == nil || it.state == nil {
		return {}, -1, false
	}
	return _procs[it.archive.format].iterate(it)
}

/*
Tells why iteration stopped

Inputs:
- it: The iterator

Returns:
- path: The path of the member the error is about, if any
- err: The error that stopped iteration, `nil` if it reached the end
*/
@(require_results)
iterator_error :: proc(it: ^Iterator) -> (path: string, err: Error) {
	if it.archive == nil || it.state == nil {
		return "", it.err
	}
	return _procs[it.archive.format].iterator_error(it)
}

/*
Writes the current member's data to a writer, decompressed and checked

Inputs:
- it: The iterator, on the member `iterate` returned last
- w: Where the member's data is written
- options: The member's password, if encrypted (default: {})

Returns:
- err: `General_Error.No_Current_Member` if `iterate` hasn't returned a member, or the member's
  error, or `nil`
*/
extract_current :: proc(it: ^Iterator, w: io.Writer, options := Read_Options{}) -> (err: Error) {
	return _procs[it.archive.format].extract_current(it, w, options)
}

/*
Opens the current member's data as a reader, which decompresses as it is read

Inputs:
- it: The iterator, on the member `iterate` returned last
- options: The member's password, if encrypted (default: {})

Returns:
- r: The member's reader; it belongs to the iterator and lasts until the next `iterate` or
  `open_current`
- err: `General_Error.No_Current_Member` if `iterate` hasn't returned a member, or the member's
  error, or `nil`
*/
open_current :: proc(it: ^Iterator, options := Read_Options{}) -> (r: io.Reader, err: Error) {
	return _procs[it.archive.format].open_current(it, options)
}

/*
Reads the current member's link target

*Allocates Using Provided Allocator*

Inputs:
- it: The iterator, on the member `iterate` returned last
- options: The member's password, if encrypted (default: {})
- allocator: (default: context.allocator)

Returns:
- target: The symlink's target (tar: also a hard link's), empty for other members; `delete` it
- err: `General_Error.No_Current_Member` if `iterate` hasn't returned a member, or the member's
  error, or `nil`
*/
read_link :: proc(it: ^Iterator, options := Read_Options{}, allocator := context.allocator) -> (target: string, err: Error) {
	return _procs[it.archive.format].read_link(it, options, allocator)
}

/*
Finds a member by path

NOTE: Of several members with the path, zip and 7z find the first.

tar finds the next one after its current member, wrapping around. Searching forward first
saves decompressing a compressed tar again from the start, and lets `tar.find` work on a pipe.

Inputs:
- a: An open archive
- path: The member's path, ignoring a leading `./` or trailing `/`

Returns:
- fi: The member's info; its strings last as long as those from `iterate`
- handle: The member, for `extract` and `open_member`
- ok: `false` if no member has the path
- err: An error reading the archive (tar), or `nil`
*/
find :: proc(a: ^Archive, path: string) -> (fi: File_Info, handle: Handle, ok: bool, err: Error) {
	return _procs[a.format].find(a, path)
}

/*
Writes a member's data to a writer, decompressed and checked

Inputs:
- a: An open archive
- handle: The member, from `File_Info.handle` or `find`
- w: Where the member's data is written
- options: The member's password, if encrypted (default: {})

Returns:
- err: `General_Error.Not_Found` for a stale handle, the member's error, or `nil`
*/
extract :: proc(a: ^Archive, handle: Handle, w: io.Writer, options := Read_Options{}) -> (err: Error) {
	return _procs[a.format].extract(a, handle, w, options)
}

/*
Opens a member's data as a reader, which decompresses as it is read

Inputs:
- a: An open archive
- handle: The member, from `File_Info.handle` or `find`
- options: The member's password, if encrypted (default: {})

Returns:
- r: The member's reader; close it with `close_member`
- err: `General_Error.Not_Found` for a stale handle, the member's error, or `nil`
*/
open_member :: proc(a: ^Archive, handle: Handle, options := Read_Options{}) -> (r: io.Reader, err: Error) {
	return _procs[a.format].open_member(a, handle, options)
}

/*
Closes a reader from `open_member` and frees it

Inputs:
- r: The member's reader
*/
close_member :: proc(r: io.Reader) {
	io.destroy(r)
}

/*
Clones a member's info, so it outlives the iterator or reader it came from

*Allocates Using Provided Allocator*

Inputs:
- fi: The member's info
- allocator: The allocator for its strings

Returns:
- cloned: The clone; free it with `file_info_delete`
- err: An allocator error if one occurred, `nil` otherwise
*/
file_info_clone :: proc(fi: File_Info, allocator: runtime.Allocator) -> (cloned: File_Info, err: runtime.Allocator_Error) {
	cloned = {
		"", nil, "", "",
		fi.type, fi.size, fi.compressed_size, fi.method, fi.method_id, fi.filters,
		fi.encrypted, fi.supported, fi.extended_metadata, fi.crc32,
		fi.unix_mode, fi.dos_attributes, fi.uid, fi.gid, "", "", fi.device,
		fi.modification_time, fi.creation_time, fi.access_time,
		fi.handle,
	}
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

/*
Frees a member's info from `file_info_clone`

Inputs:
- fi: The clone
- allocator: The allocator given to `file_info_clone`
*/
file_info_delete :: proc(fi: File_Info, allocator: runtime.Allocator) {
	delete(fi.path, allocator)
	delete(fi.raw_path, allocator)
	delete(fi.link_target, allocator)
	delete(fi.comment, allocator)
	delete(fi.user, allocator)
	delete(fi.group, allocator)
}
