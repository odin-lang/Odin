package sdl2

import "core:c"

when ODIN_OS == .Windows {
	@(ignore_duplicates)
	foreign import lib "SDL2.lib"
} else {
	@(ignore_duplicates)
	foreign import lib "system:SDL2"
}

MAX_LOG_MESSAGE :: 4096

LogCategory :: enum c.int {
	APPLICATION,
	ERROR,
	ASSERT,
	SYSTEM,
	AUDIO,
	VIDEO,
	RENDER,
	INPUT,
	TEST,

	/* Reserved for future SDL library use */
	RESERVED1,
	RESERVED2,
	RESERVED3,
	RESERVED4,
	RESERVED5,
	RESERVED6,
	RESERVED7,
	RESERVED8,
	RESERVED9,
	RESERVED10,

	/* Beyond this point is reserved for application use, e.g.
	enum {
		MYAPP_CATEGORY_AWESOME1 = SDL_LOG_CATEGORY_CUSTOM,
		MYAPP_CATEGORY_AWESOME2,
		MYAPP_CATEGORY_AWESOME3,
		...
	};
	*/
	CUSTOM,
}

LogPriority :: enum c.int {
	DEFAULT = 0, // CUSTOM ONE
	VERBOSE = 1,
	DEBUG,
	INFO,
	WARN,
	ERROR,
	CRITICAL,
	NUM,
}

LogOutputFunction :: proc "c" (userdata: rawptr, category: LogCategory, priority: LogPriority, message: cstring)


@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	LogSetAllPriority    :: proc(priority: LogPriority) ---
	LogSetPriority       :: proc(category: c.int, priority: LogPriority) ---
	LogGetPriority       :: proc(category: c.int) -> LogPriority ---
	LogResetPriorities   :: proc() ---
	Log                  :: proc(fmt: cstring, #c_vararg args: ..any) ---
	LogVerbose           :: proc(category: c.int, fmt: cstring, #c_vararg args: ..any) ---
	LogDebug             :: proc(category: c.int, fmt: cstring, #c_vararg args: ..any) ---
	LogInfo              :: proc(category: c.int, fmt: cstring, #c_vararg args: ..any) ---
	LogWarn              :: proc(category: c.int, fmt: cstring, #c_vararg args: ..any) ---
	LogError             :: proc(category: c.int, fmt: cstring, #c_vararg args: ..any) ---
	LogCritical          :: proc(category: c.int, fmt: cstring, #c_vararg args: ..any) ---
	LogMessage           :: proc(category: c.int, priority: LogPriority, fmt: cstring, #c_vararg args: ..any) ---
	// LogMessageV          :: proc(category: c.int, priority: LogPriority, fmt: cstring, ap: va_list) ---
	LogGetOutputFunction :: proc(callback: ^LogOutputFunction, userdata: ^rawptr) ---
	LogSetOutputFunction :: proc(callback: LogOutputFunction, userdata: rawptr) ---
}
