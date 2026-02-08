#+build freestanding
#+build js
package i18n
/*
	Internationalization helpers.

	Copyright 2021-2022 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's license.

	List of contributors:
		Jeroen van Rijn: Initial implementation.
*/
import os "core:os/os2"

@(private)
parse_qt :: proc { parse_qt_linguist_from_bytes }

parse_mo :: proc { parse_mo_from_bytes }