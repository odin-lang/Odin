#+build linux
package android

// The `inline` functions of the NDK headers, which no library exports.

// API level 31.
ANativeWindow_clearFrameRate :: proc "contextless" (window: ^ANativeWindow) -> i32 {
	return ANativeWindow_setFrameRateWithChangeStrategy(
		window,
		0,
		ANATIVEWINDOW_FRAME_RATE_COMPATIBILITY_DEFAULT,
		ANATIVEWINDOW_CHANGE_FRAME_RATE_ONLY_IF_SEAMLESS,
	)
}

__android_log_id_is_valid :: proc "contextless" (log_id: log_id_t) -> bool {
	return log_id >= LOG_ID_MIN && log_id < LOG_ID_MAX
}
