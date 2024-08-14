package posix

import "core:c"

when ODIN_OS == .Darwin {
	foreign import lib "system:System.framework"
} else {
	foreign import lib "system:c"
}

// wordexp.h - word-expansion type

foreign lib {
	/*
	Perform word expansion.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/wordexp.html ]]
	*/
	wordexp :: proc(words: cstring, pwordexp: ^wordexp_t, flags: WRDE_Flags) -> WRDE_Errno ---

	/*
	Free the space allocated during word expansion.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/wordexp.html ]]
	*/
	wordfree :: proc(pwordexp: ^wordexp_t) ---
}

WRDE_Flag_Bits :: enum c.int {
	// Appends words to those previously generated.
	APPEND  = log2(WRDE_APPEND),
	// Number of null pointers to prepend to we_wordv.
	DOOFFS  = log2(WRDE_DOOFFS),
	// Fail if command substitution is requested.
	NOCMD   = log2(WRDE_NOCMD),
	// The pwordexp argument was passed to a previous successful call to wordexp(),
	// and has not been passed to wordfree().
	REUSE   = log2(WRDE_REUSE),
	// Do not redirect stderr to /dev/null.
	SHOWERR = log2(WRDE_SHOWERR),
	// Report error on attempt to expand an undefined shell variable.
	UNDEF   = log2(WRDE_UNDEF),
}
WRDE_Flags :: bit_set[WRDE_Flag_Bits; c.int]

WRDE_Errno :: enum c.int {
	OK      = 0,
	// One of the unquoted characters- <newline>, '|', '&', ';', '<', '>', '(', ')', '{', '}' -
	// appears in words in an inappropriate context.
	BADCHAR = WRDE_BADCHAR,
	// Reference to undefined shell variable when WRDE_UNDEF is set in flags.
	BADVAL  = WRDE_BADVAL,
	// Command substitution requested when WRDE_NOCMD was set in flags.
	CMDSUB  = WRDE_CMDSUB,
	// Attempt to allocate memory failed.
	NOSPACE = WRDE_NOSPACE,
	// Shell syntax error, such as unbalanced parentheses or an unterminated string.
	SYNTAX  = WRDE_SYNTAX,
}

when ODIN_OS == .Darwin {

	wordexp_t :: struct {
		we_wordc: c.size_t,   /* [PSX] count of words matched by words */
		we_wordv: [^]cstring, /* [PSX] pointer to list of expanded words */
		we_offs:  c.size_t,   /* [PSX] slots to reserve at the beginning of we_wordv */
	}

	WRDE_APPEND  :: 0x01
	WRDE_DOOFFS  :: 0x02
	WRDE_NOCMD   :: 0x04
	WRDE_REUSE   :: 0x08
	WRDE_SHOWERR :: 0x10
	WRDE_UNDEF   :: 0x20

	WRDE_BADCHAR :: 1
	WRDE_BADVAL  :: 2
	WRDE_CMDSUB  :: 3
	WRDE_NOSPACE :: 4
	WRDE_SYNTAX  :: 6

} else when ODIN_OS == .FreeBSD || ODIN_OS == .NetBSD || ODIN_OS == .OpenBSD {

	wordexp_t :: struct {
		we_wordc:   c.size_t,   /* [PSX] count of words matched by words */
		we_wordv:   [^]cstring, /* [PSX] pointer to list of expanded words */
		we_offs:    c.size_t,   /* [PSX] slots to reserve at the beginning of we_wordv */
		we_strings: [^]byte,    /* storage for wordv strings */
		we_nbytes:  c.size_t,   /* size of we_strings */
	}

	WRDE_APPEND  :: 0x01
	WRDE_DOOFFS  :: 0x02
	WRDE_NOCMD   :: 0x04
	WRDE_REUSE   :: 0x08
	WRDE_SHOWERR :: 0x10
	WRDE_UNDEF   :: 0x20

	WRDE_BADCHAR :: 1
	WRDE_BADVAL  :: 2
	WRDE_CMDSUB  :: 3
	WRDE_NOSPACE :: 4
	WRDE_SYNTAX  :: 6

} else {
	#panic("posix is unimplemented for the current target")
}
