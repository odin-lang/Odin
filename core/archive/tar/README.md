`core:archive/tar` reads and writes tar archives in pure Odin: v7, ustar and pax as specified by [POSIX.1-2024](https://pubs.opengroup.org/onlinepubs/9799919799/utilities/pax.html), and [GNU tar](https://www.gnu.org/software/tar/manual/html_node/Standard.html)'s. Importing it also registers tar with [`core:archive`](../), which opens zip, tar and 7z through one API and unpacks whole archives safely with `extract_all`. The API is documented at [pkg.odin-lang.org](https://pkg.odin-lang.org/core/archive/tar/).

# Reading

```odin
// Writes every `.txt` file in a tar archive, plain or compressed, to standard output
read_texts :: proc(path: string) -> (err: tar.Error) {
	r: tar.Reader
	tar.open(&r, path) or_return
	defer tar.close(&r)

	it := tar.iterator_create(&r)
	defer tar.iterator_destroy(&it)
	for fi in tar.iterate(&it) {
		if fi.type == .Regular && strings.has_suffix(fi.path, ".txt") {
			tar.extract_current(&it, os.to_stream(os.stdout)) or_return
		}
	}
	_, err = tar.iterator_error(&it)
	return
}
```

- From a path, a byte slice or any `io.Stream`; one that can't seek, such as a pipe, is read in a single forward pass
- V7, ustar, GNU and star headers, with pax global and local records
- GNU long names and link targets; GNU and pax sparse files, whose holes read as zeros
- gzip, bzip2, LZ4 (frame), LZMA (`.lzma`) and XZ compression, detected from the content
- Regular files, directories, symlinks, hard links, devices and named pipes
- `extract_current` writes a member to an `io.Writer` or into a `[dynamic]u8`, and `open_current` streams it through an `io.Reader`; `find` looks one up by path for `extract` or `open_member`
- The reader has one position, shared by its iterators, `find`, `extract` and `open_member`
- A tar's members are only known once read, so ask `iterator_error` why iteration stopped
- Unlike zip's and 7z's, a tar opened from a path isn't locked

# Writing

```odin
pack :: proc(path: string) -> (err: tar.Error) {
	tw: tar.Writer
	tar.create(&tw, path, tar.Writer_Options{compression = .XZ}) or_return
	defer tar.close(&tw)

	text := "Hello, world\n"
	tar.write_entry(&tw, "hello.txt", transmute([]u8)text) or_return
	tar.write_directory(&tw, "assets", "assets") or_return
	return tar.commit(&tw)
}
```

- To a path or any `io.Stream`, as pax (the default), ustar or GNU
- Compressed with gzip, bzip2, LZ4, LZMA or XZ, or not at all
- Members from a byte slice or an `io.Reader`, and whole directory trees with `write_directory`; a reader of unknown size is read into memory first
- `deterministic` writes reproducible archives; `no_sync` skips the syncs to disk
- At a path, the archive is written to `<archive>-temp` and `commit` puts it in place; `close` without `commit` discards it

# Format details

`current_entry` gives what `archive.File_Info` leaves out about the iterator's current member, as a `tar.Entry`: the header block as stored, its layout, the type flag, and the member's own pax records and the global ones stored just before it, which `next_record` walks. One member's pax records, long names and sparse maps may take `HEADER_RECORD_MAX` bytes, 1 MiB, or less under a lower memory limit.

# Not supported

- Updating an archive in place
- GNU multi-volume archives
- Writing sparse members
- Encryption, which tar doesn't have
- Paths on js, where only byte slices and streams work

# Example

[`example`](example/) holds `otar`, a minimal tar tool that lists an archive, tests it, unpacks one member, or creates an archive from files and directory trees. Build it with `odin build core/archive/tar/example -out:otar`.
