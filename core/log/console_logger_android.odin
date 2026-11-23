#+build linux:android
#+private
package log

import "base:runtime"
import "core:fmt"
import "core:os"
import "core:strings"

foreign import liblog "system:log"

@(default_calling_convention="c")
foreign liblog {
	__android_log_write :: proc(prio: i32, tag: cstring, text: cstring) -> i32 ---
}

// `android_LogPriority` from `<android/log.h>`.

ANDROID_LOG_DEBUG :: 3
ANDROID_LOG_INFO  :: 4
ANDROID_LOG_WARN  :: 5
ANDROID_LOG_ERROR :: 6
ANDROID_LOG_FATAL :: 7

// Logcat records the level and time of every message itself. Only the location and thread headers are written.
_logcat_logger_proc :: proc(ident: string, level: Level, text: string, options: Options, location: runtime.Source_Code_Location) {

	backing: [4096]byte
	buf := strings.builder_from_bytes(backing[:len(backing)-1])

	do_location_header(options, &buf, location)

	if .Thread_Id in options {
		fmt.sbprintf(&buf, "[{}] ", os.get_current_thread_id())
	}

	strings.write_string(&buf, text)
	backing[strings.builder_len(buf)] = 0

	tag_backing: [64]byte
	tag := ident if ident != "" else "Odin"
	copy(tag_backing[:len(tag_backing)-1], tag)

	prio: i32 = ANDROID_LOG_DEBUG
	switch {
	case level >= .Fatal:   prio = ANDROID_LOG_FATAL
	case level >= .Error:   prio = ANDROID_LOG_ERROR
	case level >= .Warning: prio = ANDROID_LOG_WARN
	case level >= .Info:    prio = ANDROID_LOG_INFO
	}

	__android_log_write(prio, cstring(&tag_backing[0]), cstring(&backing[0]))
}
