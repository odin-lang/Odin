package os2

import "base:runtime"
@(require) import win32 "core:sys/windows"

_local_appdata :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	guid := win32.FOLDERID_LocalAppData
	return _get_known_folder_path(&guid, allocator)
}

_local_appdata_or_roaming :: proc(allocator: runtime.Allocator, roaming: bool) -> (dir: string, err: Error) {
	guid := win32.FOLDERID_LocalAppData
	if roaming {
		guid = win32.FOLDERID_RoamingAppData
	}
	return _get_known_folder_path(&guid, allocator)
}

_user_config_dir :: _local_appdata_or_roaming
_user_data_dir :: _local_appdata_or_roaming

_user_state_dir :: _local_appdata
_user_log_dir :: _local_appdata
_user_cache_dir :: _local_appdata

_user_home_dir :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	guid := win32.FOLDERID_Profile
	return _get_known_folder_path(&guid, allocator)
}

_user_music_dir :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	guid := win32.FOLDERID_Music
	return _get_known_folder_path(&guid, allocator)
}

_user_desktop_dir :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	guid := win32.FOLDERID_Desktop
	return _get_known_folder_path(&guid, allocator)
}

_user_documents_dir :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	guid := win32.FOLDERID_Documents
	return _get_known_folder_path(&guid, allocator)
}

_user_downloads_dir :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	guid := win32.FOLDERID_Downloads
	return _get_known_folder_path(&guid, allocator)
}

_user_pictures_dir :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	guid := win32.FOLDERID_Pictures
	return _get_known_folder_path(&guid, allocator)
}

_user_public_dir :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	guid := win32.FOLDERID_Public
	return _get_known_folder_path(&guid, allocator)
}

_user_videos_dir :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	guid := win32.FOLDERID_Videos
	return _get_known_folder_path(&guid, allocator)
}

_get_known_folder_path :: proc(rfid: win32.REFKNOWNFOLDERID, allocator: runtime.Allocator) -> (dir: string, err: Error) {
	// https://learn.microsoft.com/en-us/windows/win32/api/shlobj_core/nf-shlobj_core-shgetknownfolderpath
	// See also `known_folders.odin` in `core:sys/windows` for the GUIDs.
	path_w: win32.LPWSTR
	res  := win32.SHGetKnownFolderPath(rfid, 0, nil, &path_w)
	defer win32.CoTaskMemFree(path_w)

	if res != 0 {
		return "", .Invalid_Path
	}

	return win32_wstring_to_utf8(cstring16(path_w), allocator)
}