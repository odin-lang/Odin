package os2

import "base:runtime"

@(require_results)
user_home_dir :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	return _user_home_dir(allocator)
}

// application caches, logs, temporary files
@(require_results)
user_cache_dir :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	return _user_cache_dir(allocator)
}

// application assets
@(require_results)
user_data_dir :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	return _user_data_dir(allocator)
}

// application history, ui layout state, logs
@(require_results)
user_state_dir :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	return _user_state_dir(allocator)
}

@(require_results)
user_config_dir :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	return _user_config_dir(allocator)
}

@(require_results)
user_music_dir :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	return _user_music_dir(allocator)
}

@(require_results)
user_desktop_dir :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	return _user_desktop_dir(allocator)
}

@(require_results)
user_documents_dir :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	return _user_documents_dir(allocator)
}

@(require_results)
user_downloads_dir :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	return _user_downloads_dir(allocator)
}

@(require_results)
user_pictures_dir :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	return _user_pictures_dir(allocator)
}

@(require_results)
user_public_dir :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	return _user_public_dir(allocator)
}

@(require_results)
user_videos_dir :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	return _user_videos_dir(allocator)
}