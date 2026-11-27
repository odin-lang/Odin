`core:archive/zip` reads, writes and updates zip archives in pure Odin, following version 6.3.10 of [PKWARE's APPNOTE](https://pkware.cachefly.net/webdocs/APPNOTE/APPNOTE-6.3.10.TXT). Importing it also registers zip with [`core:archive`](../), which opens zip, tar and 7z through one API and unpacks whole archives safely with `extract_all`. The API is documented at [pkg.odin-lang.org](https://pkg.odin-lang.org/core/archive/zip/).

# Reading

```odin
// Writes every `.txt` file in a zip archive to standard output
read_texts :: proc(path: string) -> (err: zip.Error) {
	r: zip.Reader
	zip.open(&r, path) or_return
	defer zip.close(&r)

	it := zip.iterator_create(&r)
	defer zip.iterator_destroy(&it)
	for fi in zip.iterate(&it) {
		if fi.type == .Regular && strings.has_suffix(fi.path, ".txt") {
			zip.extract_current(&it, os.to_stream(os.stdout)) or_return
		}
	}
	return nil
}
```

- From a path, a byte slice or a seekable `io.Stream`, self-extracting archives included
- Store, Shrink, Reduce, Implode, Deflate, Deflate64, bzip2, LZMA, PPMd and XZ
- ZipCrypto and WinZip AES (AE-1 and AE-2; 128, 192 and 256-bit keys), with the password in `archive.Read_Options`
- ZIP64 and data descriptors
- UTF-8, Info-ZIP Unicode and code page 437 names; Unix and DOS attributes, symlinks, NTFS and Unix timestamps
- `extract_current` writes a member to an `io.Writer` or into a `[dynamic]u8`, and `open_current` streams it through an `io.Reader`; `find` looks one up by path for `extract` or `open_member`
- Extraction checks the CRC-32, and a WinZip AES member's MAC. Packed data the decoder didn't read fails with `Zip_Error.Size_Mismatch`
- Several threads can read one archive at once

# Writing

```odin
pack :: proc(path: string) -> (err: zip.Error) {
	zw: zip.Writer
	zip.create(&zw, path, zip.Writer_Options{method = .Deflate, level = 9}) or_return
	defer zip.close(&zw)

	text := "Hello, world\n"
	zip.write_entry(&zw, "hello.txt", transmute([]u8)text) or_return
	zip.write_directory(&zw, "assets", "assets") or_return
	return zip.commit(&zw)
}
```

- To a path or an `io.Stream`; one that can't seek gets data descriptors
- Store, Deflate (the default), Deflate64, bzip2, LZMA, PPMd and XZ, for the archive or per member, falling back to Store when compressing doesn't pay
- Members from a byte slice or an `io.Reader`, and whole directory trees with `write_directory`
- ZIP64 when needed, archive and member comments
- WinZip AES-256 (AE-2) encryption, for the archive or per member
- `deterministic` writes reproducible archives; `no_sync` skips the syncs to disk
- At a path, the archive is written to `<archive>-temp` and `commit` puts it in place; `close` without `commit` discards it

# Updating

- `update` opens an existing archive and appends members in place, at a path or on a seekable `io.Stream`
- At a path, a member written with `replace` in its `Entry_Options` takes the place of those the archive had at its path, in a tree from `write_directory` too; without it, a path the archive holds gives `archive.General_Error.Exists`
- At a path, a replacement, `remove_entry` and `rename_entry` make `commit` write a new archive and rename it over the old one
- A crash during an update at a path leaves the last committed archive, or the one before
- At a path, readers take a shared lock and writers an exclusive one, except on wasi; a lock held elsewhere gives `archive.General_Error.Busy`

# Format details

`current_entry` gives what `archive.File_Info` leaves out about the iterator's current member, as a `zip.Entry`: the general purpose flags, the method and host system as stored, the raw name and comment, where the local header and the data start, and the extra fields of both headers, which `next_extra` walks.

# Not supported

- Archives split over several disks
- PKWARE's strong encryption and masked headers
- Methods beyond those above, such as Zstandard
- Writing Shrink, Reduce, Implode or ZipCrypto: they are read only
- Paths on js, where only byte slices and streams work

# Example

[`example`](example/) holds `ozip`, a minimal zip tool that lists an archive, tests it, unpacks one member, or creates or updates an archive from files and directory trees. Build it with `odin build core/archive/zip/example -out:ozip`.
