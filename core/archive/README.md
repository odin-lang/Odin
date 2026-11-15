`core:archive` reads and writes archive formats in pure Odin, with no foreign dependencies. Each format is its own package. They all register with `core:archive`, which detects the format and gives one API for listing, finding and extracting members, including `extract_all` with path checks and size and ratio limits. Compression comes from `core:compress`.

# [zip](https://pkg.odin-lang.org/core/archive/zip/)

Reading:
- From a path, a byte slice or a seekable `io.Stream`
- Store, Shrink, Reduce, Implode, Deflate, Deflate64, bzip2, LZMA, PPMd and XZ
- ZipCrypto and WinZip AES (AE-1 and AE-2; 128, 192 and 256-bit keys)
- ZIP64, data descriptors and self-extracting archives
- UTF-8, Info-ZIP Unicode and code page 437 names; Unix and DOS attributes, symlinks, NTFS and Unix timestamps
- Safe to read from several threads at once

Writing:
- To a path or an `io.Stream`; one that can't seek gets data descriptors
- Store, Deflate, Deflate64, bzip2, LZMA, PPMd and XZ, falling back to Store when compressing doesn't pay
- ZIP64 when needed, archive and member comments
- WinZip AES-256 (AE-2) encryption
- A deterministic mode for reproducible archives

Updating:
- `update` appends members in place, at a path or on a seekable `io.Stream`
- At a path, `remove_entry` and `rename_entry` write a new archive and rename it over the old one

# [tar](https://pkg.odin-lang.org/core/archive/tar/)

Reading:
- From a path, a byte slice or any `io.Stream`; streams that can't seek are read in one forward pass
- V7, ustar, GNU and star headers, with pax global and local records
- GNU long names and link targets, GNU and pax sparse files
- Compressed with gzip, bzip2, LZ4 (frame), LZMA (`.lzma`) or XZ, detected from the content
- Regular files, directories, symlinks, hard links, devices and named pipes

Writing:
- To a path or an `io.Stream`, as pax (default), ustar or GNU
- Compressed with gzip, bzip2, LZ4, LZMA or XZ, or uncompressed
- Members from a byte slice or an `io.Reader`, and whole directory trees with `write_directory`
- A deterministic mode for reproducible archives

# [7z](https://pkg.odin-lang.org/core/archive/sevenz/)

Reading:
- From a path, a byte slice or a seekable `io.Stream`
- Copy, LZMA, LZMA2, PPMd, Deflate, Deflate64 and bzip2
- Filters: Delta, BCJ (x86, PowerPC, IA-64, ARM, ARM Thumb, SPARC, ARM64, RISC-V), BCJ2, Swap2 and Swap4
- Solid archives, compressed and encrypted headers, anti-items
- 7-Zip AES-256, with `max_key_derivations` in `archive.Read_Options` capping the key derivations per reader (default 16)

Writing:
- To a path or an `io.Stream`
- LZMA2 (default), LZMA, PPMd, Deflate, Deflate64, bzip2 or Copy, with the filters above picked automatically or by hand
- Solid archives, with optional size and file-count limits per folder, ordered by name or extension
- 7-Zip AES-256 encryption, with encrypted headers by default
- A deterministic mode for reproducible archives

Updating:
- `update` appends members in place, at a path or on a seekable `io.Stream`
- `write_anti_item` adds an anti-item, which marks a path as deleted
- At a path, `remove_entry` and `rename_entry` write a new archive and rename it over the old one. Untouched folders are copied as they are; a solid folder that loses only some of its members is re-encoded, with the writer's password if it was encrypted

# [transaction](https://pkg.odin-lang.org/core/archive/transaction/)

The shared machinery behind zip's and 7z's updates, so an update never leaves a broken archive behind:
- Whole-file locks: readers at a path take a shared lock and writers an exclusive one. Neither blocks; contention gives `archive.General_Error.Busy`. js and wasi have no locks.
- A sidecar journal (`<archive>-journal`) for in-place appends: it records the old length and the bytes about to be overwritten, so a reopen after a crash gives the last committed state.
- Rewrites go to `<archive>-temp`, which then replaces the original and is synced to disk.
- Readers see the archive as of the last commit, even while a journal is pending.
