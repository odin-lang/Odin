package os2

import "base:runtime"
@(require) import win32 "core:sys/windows"

@(require_results)
_get_known_folder_path :: proc(rfid: win32.REFKNOWNFOLDERID, allocator: runtime.Allocator) -> (dir: string, err: Error) {
	// https://learn.microsoft.com/en-us/windows/win32/api/shlobj_core/nf-shlobj_core-shgetknownfolderpath
	// See also `known_folders.odin` in `core:sys/windows` for the GUIDs.
	path_w: win32.LPWSTR
	res  := win32.SHGetKnownFolderPath(rfid, 0, nil, &path_w)
	defer win32.CoTaskMemFree(path_w)

	if res != 0 {
		return "", .Invalid_Path
	}

	dir, _ = win32.wstring_to_utf8(path_w, -1, allocator)
	return
}