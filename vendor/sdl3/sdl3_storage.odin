package sdl3

import "core:c"

StorageInterface :: struct {
	/* The version of this interface */
	version: Uint32,

	/* Called when the storage is closed */
	close: proc "c" (userdata: rawptr) -> bool,

	/* Optional, returns whether the storage is currently ready for access */
	ready: proc "c" (userdata: rawptr) -> bool,

	/* Enumerate a directory, optional for write-only storage */
	enumerate: proc "c" (userdata: rawptr, path: cstring, callback: EnumerateDirectoryCallback, callback_userdata: rawptr) -> bool,

	/* Get path information, optional for write-only storage */
	info: proc "c" (userdata: rawptr, path: cstring, info: ^PathInfo) -> bool,

	/* Read a file from storage, optional for write-only storage */
	read_file: proc "c" (userdata: rawptr, path: cstring, destination: rawptr, length: Uint64) -> bool,

	/* Write a file to storage, optional for read-only storage */
	write_file: proc "c" (userdata: rawptr, path: cstring, source: rawptr, length: Uint64) -> bool,

	/* Create a directory, optional for read-only storage */
	mkdir: proc "c" (userdata: rawptr, path: cstring) -> bool,

	/* Remove a file or empty directory, optional for read-only storage */
	remove: proc "c" (userdata: rawptr, path: cstring) -> bool,

	/* Rename a path, optional for read-only storage */
	rename: proc "c" (userdata: rawptr, oldpath, newpath: cstring) -> bool,

	/* Copy a file, optional for read-only storage */
	copy: proc "c" (userdata: rawptr, oldpath, newpath: cstring) -> bool,

	/* Get the space remaining, optional for read-only storage */
	space_remaining: proc "c" (userdata: rawptr) -> Uint64,
}

#assert(
        (size_of(StorageInterface) == 48 && size_of(rawptr) == 4) ||
        (size_of(StorageInterface) == 96 && size_of(rawptr) == 8),
)

Storage :: struct {}


@(default_calling_convention="c", link_prefix="SDL_", require_results)
foreign lib {
	OpenTitleStorage          :: proc(override: cstring, props: PropertiesID) -> ^Storage ---
	OpenUserStorage           :: proc(org, app: cstring, props: PropertiesID) -> ^Storage ---
	OpenFileStorage           :: proc(path: cstring) -> ^Storage ---
	OpenStorage               :: proc(iface: ^StorageInterface, userdata: rawptr) -> ^Storage ---
	CloseStorage              :: proc(storage: ^Storage) -> bool ---
	StorageReady              :: proc(storage: ^Storage) -> bool ---
	GetStorageFileSize        :: proc(storage: ^Storage, path: cstring, length: ^Uint64) -> bool ---

	CreateStorageDirectory    :: proc(storage: ^Storage, path: cstring) -> bool ---
	GetStorageSpaceRemaining  :: proc(storage: ^Storage) -> Uint64 ---
	GlobStorageDirectory      :: proc(storage: ^Storage, path: cstring, pattern: cstring, flags: GlobFlags, count: ^c.int) -> [^][^]c.char ---
}

@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	ReadStorageFile           :: proc(storage: ^Storage, path: cstring, destination: rawptr, length: Uint64) -> bool ---
	WriteStorageFile          :: proc(storage: ^Storage, path: cstring, source:      rawptr, length: Uint64) -> bool ---

	EnumerateStorageDirectory :: proc(storage: ^Storage, path: cstring, callback: EnumerateDirectoryCallback, userdata: rawptr) -> bool ---
	RemoveStoragePath         :: proc(storage: ^Storage, path: cstring) -> bool ---
	RenameStoragePath         :: proc(storage: ^Storage, oldpath, newpath: cstring) -> bool ---
	CopyStorageFile           :: proc(storage: ^Storage, oldpath, newpath: cstring) -> bool ---
	GetStoragePathInfo        :: proc(storage: ^Storage, path: cstring, info: ^PathInfo) -> bool ---
}
