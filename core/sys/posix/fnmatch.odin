package posix

import "core:c"

when ODIN_OS == .Darwin {
	foreign import lib "system:System.framework"
} else {
	foreign import lib "system:c"
}

// fnmatch.h - filename-matching types

foreign lib {
	/*
	Match patterns as described in XCU [[ Patterns Matching a Single Character; https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_13_01 ]] 
	// and [[ Patterns Matching Multiple Characters; https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_13_02 ]].
	It checks the string specified by the string argument to see if it matches the pattern specified by the pattern argument.

	Returns: 0 when matched. if there is no match, fnmatch() shall return FNM_NOMATCH. Non-zero on other errors.

	Example:
		assert(posix.fnmatch("*.odin", "foo.odin", {}) == 0)
		assert(posix.fnmatch("*.txt",  "foo.odin", {}) == posix.FNM_NOMATCH)

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/fnmatch.html ]]
	*/
	fnmatch :: proc(pattern: cstring, string: cstring, flags: FNM_Flags) -> c.int ---
}

FNM_Flag_Bits :: enum c.int {
	// A <slash> character ( '/' ) in string shall be explicitly matched by a <slash> in pattern;
	// it shall not be matched by either the <asterisk> or <question-mark> special characters,
	// nor by a bracket expression.
	PATHNAME = log2(FNM_PATHNAME),

	// A leading <period> ( '.' ) in string shall match a <period> in pattern;
	// as described by rule 2 in XCU [[ Patterns Used for Filename Expansion; https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_13_03 ]]
	// where the location of "leading" is indicated by the value of PATHNAME:
	// 1. If PATHNAME is set, a <period> is "leading" if it is the first character in string or if it immediately follows a <slash>.
	// 2. If PATHNAME is not set, a <period> is "leading" only if it is the first character of string.
	PERIOD   = log2(FNM_PERIOD),

	// A <backslash> character shall be treated as an ordinary character.
	NOESCAPE = log2(FNM_NOESCAPE),
}
FNM_Flags :: bit_set[FNM_Flag_Bits; c.int]

when ODIN_OS == .Darwin || ODIN_OS == .FreeBSD || ODIN_OS == .NetBSD || ODIN_OS == .OpenBSD {

	FNM_NOMATCH  :: 1

	FNM_PATHNAME :: 0x02
	FNM_PERIOD   :: 0x04
	FNM_NOESCAPE :: 0x01

} else {
	#panic("posix is unimplemented for the current target")
}
