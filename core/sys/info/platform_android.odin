#+private
#+build linux:android
package sysinfo

import "core:strings"

foreign import libc "system:c"

@(default_calling_convention="c")
foreign libc {
	__system_property_get :: proc(name: cstring, value: [^]u8) -> i32 ---
}

// Writes the Android release and API level, like `Android 14 (API level 34)`, and returns the release's version.
_android_version :: proc(b: ^strings.Builder) -> Version {
	PROP_VALUE_MAX :: 92

	release, sdk: [PROP_VALUE_MAX]u8
	release_len := __system_property_get("ro.build.version.release", &release[0])
	sdk_len     := __system_property_get("ro.build.version.sdk",     &sdk[0])

	strings.write_string(b, "Android")
	if release_len > 0 {
		strings.write_byte(b, ' ')
		strings.write_string(b, string(release[:release_len]))
	}
	if sdk_len > 0 {
		strings.write_string(b, " (API level ")
		strings.write_string(b, string(sdk[:sdk_len]))
		strings.write_byte(b, ')')
	}
	return _parse_version(string(release[:max(release_len, 0)]))
}
