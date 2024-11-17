#+build windows
package sys_windows

foreign import "system:icu.lib"

UError :: enum i32 {
	U_ZERO_ERROR = 0,
}

@(default_calling_convention="system")
foreign icu {
	ucal_getWindowsTimeZoneID :: proc(id: wstring, len: i32, winid: wstring, winidCapacity: i32, status: ^UError) -> i32 ---
	ucal_getDefaultTimeZone :: proc(result: wstring, cap: i32, status: ^UError) -> i32 ---
}
