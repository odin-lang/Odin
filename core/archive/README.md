`core:archive` reads and writes archive formats in pure Odin, with no foreign dependencies. Each format is its own package. They all register with `core:archive`, which detects the format and gives one API for listing, finding and extracting members, including `extract_all` with path checks and size and ratio limits. Compression comes from `core:compress`.

# Examples

Two minimal command-line tools list an archive, test it, unpack one member, create an archive from files and directory trees and update one:
- [`core:archive/example`](example/): `mini`, through `core:archive`, for zip
- [`core:archive/zip/example`](zip/example/): `ozip`, with each member's compression ratio

Build one with `odin build core/archive/example -out:mini`.

# Formats

Each format's README lists what it reads and writes, with examples:
- [`core:archive/zip`](zip/README.md) reads, writes and updates zip archives, with ZIP64 and WinZip AES ([API](https://pkg.odin-lang.org/core/archive/zip/))

# Crash-safe updates

The shared machinery behind zip's updates, so an update never leaves a broken archive behind:
- Whole-file locks: readers at a path take a shared lock and writers an exclusive one. Neither blocks; contention gives `archive.General_Error.Busy`. js and wasi have no locks.
- A sidecar journal (`<archive>-journal`) for in-place appends: it records the old length and the bytes about to be overwritten, so a reopen after a crash gives the last committed state.
- Rewrites go to `<archive>-temp`, which then replaces the original and is synced to disk.
- Readers see the archive as of the last commit, even while a journal is pending.

`create` at a path also writes to `<archive>-temp`, and `commit` renames it into place. `no_sync` in the writer's options skips the syncs to disk there, trading durability for speed; updates always sync.
