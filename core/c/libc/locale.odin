package libc

import "core:c"

when ODIN_OS == .Windows {
	foreign import libc "system:libucrt.lib"
} else when ODIN_OS == .Darwin {
	foreign import libc "system:System.framework"
} else {
	foreign import libc "system:c"
}

// locale.h - category macros

foreign libc {
	/*
	Sets the components of an object with the type lconv with the values appropriate for the
	formatting of numeric quantities (monetary and otherwise) according to the rules of the current
	locale.

	Returns: a pointer to the lconv structure, might be invalidated by subsequent calls to localeconv() and setlocale()

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/localeconv.html ]]
	*/
	localeconv :: proc() -> ^lconv ---

	/*
	Selects the appropriate piece of the global locale, as specified by the category and locale arguments,
	and can be used to change or query the entire global locale or portions thereof.

	Returns: the current locale if `locale` is `nil`, the set locale otherwise

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/setlocale.html ]]
	*/
	@(link_name=LSETLOCALE)
	setlocale :: proc(category: Locale_Category, locale: cstring) -> cstring ---
}

Locale_Category :: enum c.int {
	ALL      = LC_ALL,
	COLLATE  = LC_COLLATE,
	CTYPE    = LC_CTYPE,
	MESSAGES = LC_MESSAGES,
	MONETARY = LC_MONETARY,
	NUMERIC  = LC_NUMERIC,
	TIME     = LC_TIME,
}

when ODIN_OS == .NetBSD {
	@(private) LSETLOCALE :: "__setlocale50"
} else {
	@(private) LSETLOCALE :: "setlocale"
}

when ODIN_OS == .Windows {
	lconv :: struct {
		decimal_point:        cstring,
		thousand_sep:         cstring,
		grouping:             cstring,
		int_curr_symbol:      cstring,
		currency_symbol:      cstring,
		mon_decimal_points:   cstring,
		mon_thousands_sep:    cstring,
		mon_grouping:         cstring,
		positive_sign:        cstring,
		negative_sign:        cstring,
		int_frac_digits:      c.char,
		frac_digits:          c.char,
		p_cs_precedes:        c.char,
		p_sep_by_space:       c.char,
		n_cs_precedes:        c.char,
		n_sep_by_space:       c.char,
		p_sign_posn:          c.char,
		n_sign_posn:          c.char,
		_W_decimal_point:     [^]u16 `fmt:"s,0"`,
		_W_thousands_sep:     [^]u16 `fmt:"s,0"`,
		_W_int_curr_symbol:   [^]u16 `fmt:"s,0"`,
		_W_currency_symbol:   [^]u16 `fmt:"s,0"`,
		_W_mon_decimal_point: [^]u16 `fmt:"s,0"`,
		_W_mon_thousands_sep: [^]u16 `fmt:"s,0"`,
		_W_positive_sign:     [^]u16 `fmt:"s,0"`,
		_W_negative_sign:     [^]u16 `fmt:"s,0"`,
	}
} else {
	lconv :: struct {
		decimal_point:       cstring,
		thousand_sep:        cstring,
		grouping:            cstring,
		int_curr_symbol:     cstring,
		currency_symbol:     cstring,
		mon_decimal_points:  cstring,
		mon_thousands_sep:   cstring,
		mon_grouping:        cstring,
		positive_sign:       cstring,
		negative_sign:       cstring,
		int_frac_digits:     c.char,
		frac_digits:         c.char,
		p_cs_precedes:       c.char,
		p_sep_by_space:      c.char,
		n_cs_precedes:       c.char,
		n_sep_by_space:      c.char,
		p_sign_posn:         c.char,
		n_sign_posn:         c.char,
		_int_p_cs_precedes:  c.char,
		_int_n_cs_precedes:  c.char,
		_int_p_sep_by_space: c.char,
		_int_n_sep_by_space: c.char,
		_int_p_sign_posn:    c.char,
		_int_n_sign_posn:    c.char,
	}
}

when ODIN_OS == .Darwin || ODIN_OS == .FreeBSD || ODIN_OS == .NetBSD  || ODIN_OS == .OpenBSD || ODIN_OS == .Windows {

	LC_ALL      :: 0
	LC_COLLATE  :: 1
	LC_CTYPE    :: 2
	LC_MESSAGES :: 6
	LC_MONETARY :: 3
	LC_NUMERIC  :: 4
	LC_TIME     :: 5

} else when ODIN_OS == .Linux {

	LC_CTYPE    :: 0
	LC_NUMERIC  :: 1
	LC_TIME     :: 2
	LC_COLLATE  :: 3
	LC_MONETARY :: 4
	LC_MESSAGES :: 5
	LC_ALL      :: 6

}
