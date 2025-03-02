package sdl3

import "core:c"

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
	GPU,

	/* Reserved for future SDL library use */
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
			MYAPP_CATEGORY_AWESOME1 = CUSTOM,
			MYAPP_CATEGORY_AWESOME2,
			MYAPP_CATEGORY_AWESOME3,
			...
		};
	*/
	CUSTOM,
}

LogPriority :: enum c.int {
	INVALID,
	TRACE,
	VERBOSE,
	DEBUG,
	INFO,
	WARN,
	ERROR,
	CRITICAL,
}

LogOutputFunction :: #type proc "c" (userdata: rawptr, category: LogCategory, priority: LogPriority, message: cstring)

@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	SetLogPriorities            :: proc(priority: LogPriority) ---
	SetLogPriority              :: proc(category: LogCategory, priority: LogPriority) ---
	GetLogPriority              :: proc(category: LogCategory) -> LogPriority ---
	ResetLogPriorities          :: proc() ---
	SetLogPriorityPrefix        :: proc(priority: LogPriority, prefix: cstring) -> bool ---
	Log                         :: proc(fmt: cstring, #c_vararg args: ..any) ---
	LogTrace                    :: proc(category: c.int, fmt: cstring, #c_vararg args: ..any) ---
	LogVerbose                  :: proc(category: c.int, fmt: cstring, #c_vararg args: ..any) ---
	LogDebug                    :: proc(category: c.int, fmt: cstring, #c_vararg args: ..any) ---
	LogInfo                     :: proc(category: c.int, fmt: cstring, #c_vararg args: ..any) ---
	LogWarn                     :: proc(category: c.int, fmt: cstring, #c_vararg args: ..any) ---
	LogError                    :: proc(category: c.int, fmt: cstring, #c_vararg args: ..any) ---
	LogCritical                 :: proc(category: c.int, fmt: cstring, #c_vararg args: ..any) ---
	LogMessage                  :: proc(category: c.int, priority: LogPriority, fmt: cstring, #c_vararg args: ..any) ---
	LogMessageV                 :: proc(category: c.int, priority: LogPriority, fmt: cstring, ap: c.va_list) ---
	GetDefaultLogOutputFunction :: proc() -> LogOutputFunction ---
	GetLogOutputFunction        :: proc(callback: ^LogOutputFunction, userdata: ^rawptr) ---
	SetLogOutputFunction        :: proc(callback: LogOutputFunction, userdata: rawptr) ---
}