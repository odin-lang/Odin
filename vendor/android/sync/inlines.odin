#+build linux
package android_sync

// The `inline` functions of `<android/sync.h>`, which no library exports.

// The `info.num_fences` fences of `info`.
sync_get_fence_info :: proc "contextless" (info: ^sync_file_info_t) -> [^]sync_fence_info {
	return ([^]sync_fence_info)(uintptr(info.sync_fence_info))
}
