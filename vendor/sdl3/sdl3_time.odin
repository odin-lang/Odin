package sdl3

import "core:c"

DateTime :: struct {
	year:        c.int,  /**< Year */
	month:       c.int,  /**< Month [01-12] */
	day:         c.int,  /**< Day of the month [01-31] */
	hour:        c.int,  /**< Hour [0-23] */
	minute:      c.int,  /**< Minute [0-59] */
	second:      c.int,  /**< Seconds [0-60] */
	nanosecond:  c.int,  /**< Nanoseconds [0-999999999] */
	day_of_week: c.int,  /**< Day of the week [0-6] (0 being Sunday) */
	utc_offset:  c.int,  /**< Seconds east of UTC */
}

DateFormat :: enum c.int {
	YYYYMMDD = 0, /**< Year/Month/Day */
	DDMMYYYY = 1, /**< Day/Month/Year */
	MMDDYYYY = 2, /**< Month/Day/Year */
}

TimeFormat :: enum c.int {
	HR24 = 0, /**< 24 hour time */
	HR12 = 1, /**< 12 hour time */
}


@(default_calling_convention="c", link_prefix="SDL_", require_results)
foreign lib {
	GetDateTimeLocalePreferences :: proc(dateFormat: ^DateFormat, timeFormat: ^TimeFormat) -> bool ---
	GetCurrentTime               :: proc(ticks: ^Time) -> bool ---
	TimeToDateTime               :: proc(ticks: Time, dt: ^DateTime, localTime: bool) -> bool ---
	DateTimeToTime               :: proc(#by_ptr dt: DateTime, ticks: ^Time) -> bool ---
	TimeToWindows                :: proc(ticks: Time, dwLowDateTime, dwHighDateTime: ^Uint32) ---
	TimeFromWindows              :: proc(dwLowDateTime, dwHighDateTime: Uint32) -> Time ---
	GetDaysInMonth               :: proc(year, month: c.int) -> c.int ---
	GetDayOfYear                 :: proc(year, month, day: c.int) -> c.int ---
	GetDayOfWeek                 :: proc(year, month, day: c.int) -> c.int ---
}