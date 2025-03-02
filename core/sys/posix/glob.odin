#+build linux, darwin, netbsd, openbsd, freebsd, haiku
package posix

import "core:c"

when ODIN_OS == .Darwin {
	foreign import lib "system:System.framework"
} else {
	foreign import lib "system:c"
}

// glob.h - pathname pattern-matching types

foreign lib {
	/*
	The glob() function is a pathname generator that shall implement the rules defined in 
	[[ XCU Pattern Matching Notation; https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_13 ]],
	with optional support for rule 3 in XCU [[ Patterns Used for Filename Expansion; https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_13_03 ]].

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/glob.html ]]
	*/
	@(link_name=LGLOB)
	glob :: proc(
		pattern: cstring,
		flags:   Glob_Flags,
		errfunc: proc "c" (epath: cstring, eerrno: Errno) -> b32 = nil, // Return `true` to abort the glob().
		pglob:   ^glob_t,
	) -> Glob_Result ---

	/*
	Free the glob results.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/glob.html ]]
	*/
	@(link_name=LGLOBFREE)
	globfree :: proc(^glob_t) ---
}

Glob_Flag_Bits :: enum c.int {
	// Append pathnames generated to the ones from a previous call to glob().
	APPEND   = log2(GLOB_APPEND),
	// Make use of pglob->gl_offs. If this flag is set, pglob->gl_offs is used to specify how many null pointers to add to the beginning of pglob->gl_pathv.
	// In other words, pglob->gl_pathv shall point to pglob->gl_offs null pointers, followed by pglob->gl_pathc pathname pointers, followed by a null pointer.
	DOOFFS   = log2(GLOB_DOOFFS),
	// Cause glob() to return when it encounters a directory that it cannot open or read. Ordinarily,
	// glob() continues to find matches.
	ERR      = log2(GLOB_ERR),
	// Each pathname that is a directory that matches pattern shall have a <slash> appended.
	MARK     = log2(GLOB_MARK),
	// Supports rule 3 in [[ XCU Patterns Used for Filename Expansion; https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_13_03 ]].
	// If pattern does not match any pathname, then glob() shall return a list consisting of only pattern,
	// and the number of matched pathnames is 1.
	NOCHECK  = log2(GLOB_NOCHECK),
	// Disable backslash escaping.
	NOESCAPE = log2(GLOB_NOESCAPE),
	// Ordinarily, glob() sorts the matching pathnames according to the current setting of the
	// LC_COLLATE category; see XBD LC_COLLATE. When this flag is used,
	// the order of pathnames returned is unspecified.
	NOSORT   = log2(GLOB_NOSORT),
}
Glob_Flags :: bit_set[Glob_Flag_Bits; c.int]

Glob_Result :: enum c.int {
	SUCCESS = 0,
	ABORTED = GLOB_ABORTED,
	NOMATCH = GLOB_NOMATCH,
	NOSPACE = GLOB_NOSPACE,
}

when ODIN_OS == .NetBSD {
	@(private) LGLOB     :: "__glob30"
	@(private) LGLOBFREE :: "__globfree30"
} else {
	@(private) LGLOB     :: "glob" + INODE_SUFFIX
	@(private) LGLOBFREE :: "globfree"
}

when ODIN_OS == .Darwin {

	glob_t :: struct {
		gl_pathc:  c.size_t,                      /* [PSX] count of paths matched by pattern */
		gl_matchc: c.int,                         /* count of paths matching pattern */
		gl_offs:   c.size_t,                      /* [PSX] slots to reserve at the beginning of gl_pathv */
		gl_flags:  Glob_Flags,                    /* copy of flags parameter to glob */
		gl_pathv:  [^]cstring `fmt:"v,gl_pathc"`, /* [PSX] pointer to list of matched pathnames */

		// Non-standard alternate file system access functions:

		using _: struct #raw_union {
			gl_errfunc: proc "c" (cstring, c.int) -> c.int,
			gl_errblk:  proc "c" (cstring, c.int) -> c.int,
		},
		gl_closedir: proc "c" (dirp: DIR),
		gl_readdir:  proc "c" (dirp: DIR) -> ^dirent,
		gl_opendir:  proc "c" (path: cstring) -> DIR,
		gl_lstat:    proc "c" (path: cstring, buf: ^stat_t) -> result,
		gl_stat:     proc "c" (path: cstring, buf: ^stat_t) -> result,
	}

	GLOB_APPEND   :: 0x0001
	GLOB_DOOFFS   :: 0x0002
	GLOB_ERR      :: 0x0004
	GLOB_MARK     :: 0x0008
	GLOB_NOCHECK  :: 0x0010
	GLOB_NOESCAPE :: 0x2000
	GLOB_NOSORT   :: 0x0020

	GLOB_ABORTED :: -2
	GLOB_NOMATCH :: -3
	GLOB_NOSPACE :: -1

} else when ODIN_OS == .FreeBSD || ODIN_OS == .NetBSD || ODIN_OS == .Haiku {

	glob_t :: struct {
		gl_pathc:  c.size_t,                      /* [PSX] count of paths matched by pattern */
		gl_matchc: c.size_t,                      /* count of paths matching pattern */
		gl_offs:   c.size_t,                      /* [PSX] slots to reserve at the beginning of gl_pathv */
		gl_flags:  Glob_Flags,                    /* copy of flags parameter to glob */
		gl_pathv:  [^]cstring `fmt:"v,gl_pathc"`, /* [PSX] pointer to list of matched pathnames */

		// Non-standard alternate file system access functions:

		gl_errfunc:  proc "c" (cstring, c.int) -> c.int,

		gl_closedir: proc "c" (dirp: DIR),
		gl_readdir:  proc "c" (dirp: DIR) -> ^dirent,
		gl_opendir:  proc "c" (path: cstring) -> DIR,
		gl_lstat:    proc "c" (path: cstring, buf: ^stat_t) -> result,
		gl_stat:     proc "c" (path: cstring, buf: ^stat_t) -> result,
	}

	GLOB_APPEND   :: 0x0001
	GLOB_DOOFFS   :: 0x0002
	GLOB_ERR      :: 0x0004
	GLOB_MARK     :: 0x0008
	GLOB_NOCHECK  :: 0x0010
	GLOB_NOESCAPE :: 0x2000 when ODIN_OS == .FreeBSD || ODIN_OS == .Haiku else 0x0100
	GLOB_NOSORT   :: 0x0020

	GLOB_ABORTED :: -2
	GLOB_NOMATCH :: -3
	GLOB_NOSPACE :: -1

} else when ODIN_OS == .OpenBSD {

	glob_t :: struct {
		gl_pathc:  c.size_t,                      /* [PSX] count of paths matched by pattern */
		gl_matchc: c.size_t,                      /* count of paths matching pattern */
		gl_offs:   c.size_t,                      /* [PSX] slots to reserve at the beginning of gl_pathv */
		gl_flags:  Glob_Flags,                    /* copy of flags parameter to glob */
		gl_pathv:  [^]cstring `fmt:"v,gl_pathc"`, /* [PSX] pointer to list of matched pathnames */

		gl_statv:  [^]stat_t,

		// Non-standard alternate file system access functions:

		gl_errfunc:  proc "c" (cstring, c.int) -> c.int,

		gl_closedir: proc "c" (dirp: DIR),
		gl_readdir:  proc "c" (dirp: DIR) -> ^dirent,
		gl_opendir:  proc "c" (path: cstring) -> DIR,
		gl_lstat:    proc "c" (path: cstring, buf: ^stat_t) -> result,
		gl_stat:     proc "c" (path: cstring, buf: ^stat_t) -> result,
	}

	GLOB_APPEND   :: 0x0001
	GLOB_DOOFFS   :: 0x0002
	GLOB_ERR      :: 0x0004
	GLOB_MARK     :: 0x0008
	GLOB_NOCHECK  :: 0x0010
	GLOB_NOESCAPE :: 0x1000
	GLOB_NOSORT   :: 0x0020

	GLOB_ABORTED :: -2
	GLOB_NOMATCH :: -3
	GLOB_NOSPACE :: -1

} else when ODIN_OS == .Linux {

	glob_t :: struct {
		gl_pathc:  c.size_t,                      /* [PSX] count of paths matched by pattern */
		gl_pathv:  [^]cstring `fmt:"v,gl_pathc"`, /* [PSX] pointer to list of matched pathnames */
		gl_offs:   c.size_t,                      /* [PSX] slots to reserve at the beginning of gl_pathv */
		gl_flags:  Glob_Flags,                    /* copy of flags parameter to glob */

		// Non-standard alternate file system access functions:

		gl_closedir: proc "c" (dirp: DIR),
		gl_readdir:  proc "c" (dirp: DIR) -> ^dirent,
		gl_opendir:  proc "c" (path: cstring) -> DIR,
		gl_lstat:    proc "c" (path: cstring, buf: ^stat_t) -> result,
		gl_stat:     proc "c" (path: cstring, buf: ^stat_t) -> result,
	}

	GLOB_ERR      :: 1 << 0
	GLOB_MARK     :: 1 << 1
	GLOB_NOSORT   :: 1 << 2
	GLOB_DOOFFS   :: 1 << 3
	GLOB_NOCHECK  :: 1 << 4
	GLOB_APPEND   :: 1 << 5
	GLOB_NOESCAPE :: 1 << 6

	GLOB_NOSPACE :: 1
	GLOB_ABORTED :: 2
	GLOB_NOMATCH :: 3

}
