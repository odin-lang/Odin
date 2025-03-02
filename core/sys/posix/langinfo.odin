#+build linux, darwin, netbsd, openbsd, freebsd, haiku
package posix

import "core:c"

when ODIN_OS == .Darwin {
	foreign import lib "system:System.framework"
} else {
	foreign import lib "system:c"
}

// langinfo.h - language information constants

foreign lib {
	/*
	Return a pointer to a string containing information relevant to the particular language or
	cultural area defined in the current locale.

	Returns: a string that should not be freed or modified, and that can be invalidated at any time later

	Example:
		for item in posix.nl_item {
			fmt.printfln("%v: %q", item, posix.nl_langinfo(item))
		}

	Possible Output:
		CODESET: "US-ASCII"
		D_T_FMT: "%a %b %e %H:%M:%S %Y"
		D_FMT: "%m/%d/%y"
		T_FMT: "%H:%M:%S"
		T_FMT_AMPM: "%I:%M:%S %p"
		AM_STR: "AM"
		PM_STR: "PM"
		DAY_1: "Sunday"
		DAY_2: "Monday"
		DAY_3: "Tuesday"
		DAY_4: "Wednesday"
		DAY_5: "Thursday"
		DAY_6: "Friday"
		DAY_7: "Saturday"
		ABDAY_1: "Sun"
		ABDAY_2: "Mon"
		ABDAY_3: "Tue"
		ABDAY_4: "Wed"
		ABDAY_5: "Thu"
		ABDAY_6: "Fri"
		ABDAY_7: "Sat"
		MON_1: "January"
		MON_2: "February"
		MON_3: "March"
		MON_4: "April"
		MON_5: "May"
		MON_6: "June"
		MON_7: "July"
		MON_8: "August"
		MON_9: "September"
		MON_10: "October"
		MON_11: "November"
		MON_12: "December"
		ABMON_1: "Jan"
		ABMON_2: "Feb"
		ABMON_3: "Mar"
		ABMON_4: "Apr"
		ABMON_5: "May"
		ABMON_6: "Jun"
		ABMON_7: "Jul"
		ABMON_8: "Aug"
		ABMON_9: "Sep"
		ABMON_10: "Oct"
		ABMON_11: "Nov"
		ABMON_12: "Dec"
		ERA: ""
		ERA_D_FMT: ""
		ERA_D_T_FMT: ""
		ERA_T_FMT: ""
		ALT_DIGITS: ""
		RADIXCHAR: "."
		THOUSEP: ""
		YESEXPR: "^[yY]"
		NOEXPR: "^[nN]"
		CRNCYSTR: ""

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/nl_langinfo.html ]]
	*/
	nl_langinfo :: proc(nl_item) -> cstring ---
}

nl_item :: enum nl_item_t {
	CODESET     = CODESET,
	D_T_FMT     = D_T_FMT,
	D_FMT       = D_FMT,
	T_FMT       = T_FMT,
	T_FMT_AMPM  = T_FMT_AMPM,
	AM_STR      = AM_STR,
	PM_STR      = PM_STR,
	DAY_1       = DAY_1,
	DAY_2       = DAY_2,
	DAY_3       = DAY_3,
	DAY_4       = DAY_4,
	DAY_5       = DAY_5,
	DAY_6       = DAY_6,
	DAY_7       = DAY_7,
	ABDAY_1     = ABDAY_1,
	ABDAY_2     = ABDAY_2,
	ABDAY_3     = ABDAY_3,
	ABDAY_4     = ABDAY_4,
	ABDAY_5     = ABDAY_5,
	ABDAY_6     = ABDAY_6,
	ABDAY_7     = ABDAY_7,
	MON_1       = MON_1,
	MON_2       = MON_2,
	MON_3       = MON_3,
	MON_4       = MON_4,
	MON_5       = MON_5,
	MON_6       = MON_6,
	MON_7       = MON_7,
	MON_8       = MON_8,
	MON_9       = MON_9,
	MON_10      = MON_10,
	MON_11      = MON_11,
	MON_12      = MON_12,
	ABMON_1     = ABMON_1,
	ABMON_2     = ABMON_2,
	ABMON_3     = ABMON_3,
	ABMON_4     = ABMON_4,
	ABMON_5     = ABMON_5,
	ABMON_6     = ABMON_6,
	ABMON_7     = ABMON_7,
	ABMON_8     = ABMON_8,
	ABMON_9     = ABMON_9,
	ABMON_10    = ABMON_10,
	ABMON_11    = ABMON_11,
	ABMON_12    = ABMON_12,
	ERA         = ERA,
	ERA_D_FMT   = ERA_D_FMT,
	ERA_D_T_FMT = ERA_D_T_FMT,
	ERA_T_FMT   = ERA_T_FMT,
	ALT_DIGITS  = ALT_DIGITS,
	RADIXCHAR   = RADIXCHAR,
	THOUSEP     = THOUSEP,
	YESEXPR     = YESEXPR,
	NOEXPR      = NOEXPR,
	CRNCYSTR    = CRNCYSTR,
}

when ODIN_OS == .Darwin || ODIN_OS == .FreeBSD || ODIN_OS == .Haiku {

	// NOTE: declared with `_t` so we can enumerate the real `nl_info`.
	nl_item_t :: distinct c.int

	CODESET    :: 0
	D_T_FMT    :: 1
	D_FMT      :: 2
	T_FMT      :: 3
	T_FMT_AMPM :: 4
	AM_STR     :: 5
	PM_STR     :: 6

	DAY_1 :: 7
	DAY_2 :: 8
	DAY_3 :: 9
	DAY_4 :: 10
	DAY_5 :: 11
	DAY_6 :: 12
	DAY_7 :: 13

	ABDAY_1 :: 14
	ABDAY_2 :: 15
	ABDAY_3 :: 16
	ABDAY_4 :: 17
	ABDAY_5 :: 18
	ABDAY_6 :: 19
	ABDAY_7 :: 20

	MON_1  :: 21
	MON_2  :: 22
	MON_3  :: 23
	MON_4  :: 24
	MON_5  :: 25
	MON_6  :: 26
	MON_7  :: 27
	MON_8  :: 28
	MON_9  :: 29
	MON_10 :: 30
	MON_11 :: 31
	MON_12 :: 32

	ABMON_1  :: 33
	ABMON_2  :: 34
	ABMON_3  :: 35
	ABMON_4  :: 36
	ABMON_5  :: 37
	ABMON_6  :: 38
	ABMON_7  :: 39
	ABMON_8  :: 40
	ABMON_9  :: 41
	ABMON_10 :: 42
	ABMON_11 :: 43
	ABMON_12 :: 44

	ERA         :: 45
	ERA_D_FMT   :: 46
	ERA_D_T_FMT :: 47
	ERA_T_FMT   :: 48
	ALT_DIGITS  :: 49

	RADIXCHAR :: 50
	THOUSEP   :: 51

	YESEXPR :: 52
	NOEXPR  :: 53

	CRNCYSTR :: 54 when ODIN_OS == .Haiku else 56

} else when ODIN_OS == .NetBSD || ODIN_OS == .OpenBSD {

	// NOTE: declared with `_t` so we can enumerate the real `nl_info`.
	nl_item_t :: distinct c.int

	CODESET    :: 51
	D_T_FMT    :: 0
	D_FMT      :: 1
	T_FMT      :: 2
	T_FMT_AMPM :: 3
	AM_STR     :: 4
	PM_STR     :: 5

	DAY_1 :: 6
	DAY_2 :: 7
	DAY_3 :: 8
	DAY_4 :: 9
	DAY_5 :: 10
	DAY_6 :: 11
	DAY_7 :: 12

	ABDAY_1 :: 13
	ABDAY_2 :: 14
	ABDAY_3 :: 15
	ABDAY_4 :: 16
	ABDAY_5 :: 17
	ABDAY_6 :: 18
	ABDAY_7 :: 19	

	MON_1  :: 20
	MON_2  :: 21
	MON_3  :: 22
	MON_4  :: 23
	MON_5  :: 24
	MON_6  :: 25
	MON_7  :: 26
	MON_8  :: 27
	MON_9  :: 28
	MON_10 :: 29
	MON_11 :: 30
	MON_12 :: 31

	ABMON_1  :: 32
	ABMON_2  :: 33
	ABMON_3  :: 34
	ABMON_4  :: 35
	ABMON_5  :: 36
	ABMON_6  :: 37
	ABMON_7  :: 38
	ABMON_8  :: 39
	ABMON_9  :: 40
	ABMON_10 :: 41
	ABMON_11 :: 42
	ABMON_12 :: 43

	ERA         :: 52
	ERA_D_FMT   :: 53
	ERA_D_T_FMT :: 54
	ERA_T_FMT   :: 55
	ALT_DIGITS  :: 56

	RADIXCHAR :: 44
	THOUSEP   :: 45

	YESEXPR :: 47
	NOEXPR  :: 49

	CRNCYSTR :: 50	

} else when ODIN_OS == .Linux {

	// NOTE: declared with `_t` so we can enumerate the real `nl_info`.
	nl_item_t :: distinct c.int

	// NOTE: All these values are set in an enum on the Linux implementation.
	// Some depend on locale.h contants (bits/locale.h to be precise).

	// NOTE: ABDAY_1 is set to LC_TIME << 16 (LC_TIME is 2) on the enum group of
	// the Linux implementation.
	ABDAY_1 :: 0x20_000
	ABDAY_2 :: 0x20_001
	ABDAY_3 :: 0x20_002
	ABDAY_4 :: 0x20_003
	ABDAY_5 :: 0x20_004
	ABDAY_6 :: 0x20_005
	ABDAY_7 :: 0x20_006

	DAY_1 :: 0x20_007
	DAY_2 :: 0x20_008
	DAY_3 :: 0x20_009
	DAY_4 :: 0x20_00A
	DAY_5 :: 0x20_00B
	DAY_6 :: 0x20_00C
	DAY_7 :: 0x20_00D

	ABMON_1  :: 0x20_00E
	ABMON_2  :: 0x20_010
	ABMON_3  :: 0x20_011
	ABMON_4  :: 0x20_012
	ABMON_5  :: 0x20_013
	ABMON_6  :: 0x20_014
	ABMON_7  :: 0x20_015
	ABMON_8  :: 0x20_016
	ABMON_9  :: 0x20_017
	ABMON_10 :: 0x20_018
	ABMON_11 :: 0x20_019
	ABMON_12 :: 0x20_01A

	MON_1  :: 0x20_01B
	MON_2  :: 0x20_01C
	MON_3  :: 0x20_01D
	MON_4  :: 0x20_01E
	MON_5  :: 0x20_020
	MON_6  :: 0x20_021
	MON_7  :: 0x20_022
	MON_8  :: 0x20_023
	MON_9  :: 0x20_024
	MON_10 :: 0x20_025
	MON_11 :: 0x20_026
	MON_12 :: 0x20_027

	AM_STR :: 0x20_028
	PM_STR :: 0x20_029

	D_T_FMT    :: 0x20_02A
	D_FMT      :: 0x20_02B
	T_FMT      :: 0x20_02C
	T_FMT_AMPM :: 0x20_02D

	ERA         :: 0x20_02E
	ERA_D_FMT   :: 0x20_030
	ALT_DIGITS  :: 0x20_031
	ERA_D_T_FMT :: 0x20_032
	ERA_T_FMT   :: 0x20_033

	// NOTE: CODESET is the 16th member of the enum group starting with value
	// LC_CTYPE << 16, LC_CTYPE is 0.
	CODESET :: 0x0F

	// NOTE: CRNCYSTR is the 16th member of the enum group starting with value
	// LC_MONETARY << 16, LC_MONETARY is 4.
	CRNCYSTR :: 0x40_00F

	// NOTE: RADIXCHAR is the 1st member of the enum group starting with value
	// LC_NUMERIC << 16, LC_NUMERIC is 1.
	RADIXCHAR :: 0x10_000
	THOUSEP   :: 0x10_001

	// NOTE: YESEXPR is the 1st member of the enum group starting with value
	// LC_MESSAGES << 16, LC_MESSAGES is 5.
	YESEXPR :: 0x50_000
	NOEXPR  :: 0x50_001

} else {
	#panic("posix is unimplemented for the current target")
}
