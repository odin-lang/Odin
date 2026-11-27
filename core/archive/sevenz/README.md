`core:archive/sevenz` reads, writes and updates 7z archives in pure Odin, following `DOC/7zFormat.txt` in Igor Pavlov's public domain [LZMA SDK](https://www.7-zip.org/sdk.html). Importing it also registers 7z with [`core:archive`](../), which opens zip, tar and 7z through one API and unpacks whole archives safely with `extract_all`. The API is documented at [pkg.odin-lang.org](https://pkg.odin-lang.org/core/archive/sevenz/).

# Reading

```odin
// Writes every `.txt` file in a 7z archive to standard output
read_texts :: proc(path: string) -> (err: sevenz.Error) {
	r: sevenz.Reader
	sevenz.open(&r, path) or_return
	defer sevenz.close(&r)

	it := sevenz.iterator_create(&r)
	defer sevenz.iterator_destroy(&it)
	for fi in sevenz.iterate(&it) {
		if fi.type == .Regular && strings.has_suffix(fi.path, ".txt") {
			sevenz.extract_current(&it, os.to_stream(os.stdout)) or_return
		}
	}
	return nil
}
```

- From a path, a byte slice or a seekable `io.Stream`, also behind the stub of a self-extracting executable (MZ, ELF or Mach-O) when the archive starts in its first `SFX_SEARCH_MAX` bytes, 4 MiB
- Copy, LZMA, LZMA2, PPMd, Deflate, Deflate64 and bzip2
- Filters: Delta, BCJ (x86, PowerPC, IA-64, ARM, ARM Thumb, SPARC, ARM64, RISC-V), BCJ2, Swap2 and Swap4
- Solid archives, compressed and encrypted headers, and anti-items
- 7-Zip AES-256, with the password in `archive.Read_Options`: at `open` for an encrypted header, at extraction for encrypted members. `max_key_derivations` caps the key derivations per reader (default 16)
- The iterator walks members in storage order, which decodes each solid folder only once; `find` looks a member up by path for `extract` or `open_member`
- `extract_current` writes a member to an `io.Writer` and `open_current` streams it through an `io.Reader`
- Extraction checks the CRC-32. A packed stream its coder didn't read to the end fails with `SevenZ_Error.Size_Mismatch`

# Writing

```odin
pack :: proc(path: string) -> (err: sevenz.Error) {
	sw: sevenz.Writer
	sevenz.create(&sw, path, sevenz.Writer_Options{solid = true}) or_return
	defer sevenz.close(&sw)

	text := "Hello, world\n"
	sevenz.write_entry(&sw, "hello.txt", transmute([]u8)text) or_return
	sevenz.write_directory(&sw, "assets", "assets") or_return
	return sevenz.commit(&sw)
}
```

- To a path or a seekable `io.Stream`
- LZMA2 (the default), LZMA, PPMd, Deflate, Deflate64, bzip2 or Copy, for the archive or per member, with the filters above picked from the data or by hand
- Members from a byte slice or an `io.Reader`, and whole directory trees with `write_directory`
- Solid archives, with optional size and file-count limits per folder, ordered by name or extension
- 7-Zip AES-256 encryption, of the header too unless `unencrypted_header` is set; `kdf_power` sets the key derivation's cost, 19 by default and 24 at most
- `deterministic` writes reproducible archives; `no_sync` skips the syncs to disk
- At a path, the archive is written to `<archive>-temp` and `commit` puts it in place; `close` without `commit` discards it

# Updating

- `update` opens an existing archive and appends members in place, at a path or on a seekable `io.Stream`
- `write_anti_item` adds an anti-item, which marks a path as deleted
- At a path, a member written with `replace` in its `Entry_Options` takes the place of those the archive had at its path, in a tree from `write_directory` too; without it, a path the archive holds gives `archive.General_Error.Exists`
- At a path, a replacement, `remove_entry` and `rename_entry` make `commit` write a new archive and rename it over the old one. Untouched folders are copied as they are; a solid folder that loses only some of its members is re-encoded, with the writer's password if it was encrypted
- A self-extracting archive keeps its stub
- A crash during an update at a path leaves the last committed archive
- At a path, readers take a shared lock and writers an exclusive one, except on wasi; a lock held elsewhere gives `archive.General_Error.Busy`

# Format details

`current_entry` gives what `archive.File_Info` leaves out about the iterator's current member, as a `sevenz.Entry`: the folder (solid block) its data is in and where it starts there, the name's UTF-16 bytes, the attributes and timestamps as stored, and whether it is an anti-item.

# Not supported

- Writing new self-extracting archives
- Multi-volume archives
- Methods beyond those above, such as the Zstandard and LZ4 of 7-Zip's forks
- Paths on js, where only byte slices and streams work

# Example

[`example`](example/) holds `o7`, a minimal 7z tool that lists an archive, tests it, unpacks one member, or creates or updates an archive from files and directory trees. Build it with `odin build core/archive/sevenz/example -out:o7`.
