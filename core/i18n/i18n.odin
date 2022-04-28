package i18n
/*
	Internationalization helpers.

	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-3 license.

	List of contributors:
		Jeroen van Rijn: Initial implementation.
*/
import "core:strings"

/*
	TODO:
	- Support for more translation catalog file formats.
*/

MAX_PLURALS :: 10

/*
	Currently active catalog.
*/
ACTIVE: ^Translation

/*
	The main data structure. This can be generated from various different file formats, as long as we have a parser for them.
*/
Translation :: struct {
	k_v:    map[string][MAX_PLURALS]string,
	intern: strings.Intern,

	pluralize: proc(number: int) -> int,
}

Error :: enum {
	/*
		General return values.
	*/
	None = 0,
	Empty_Translation_Catalog,

	/*
		Couldn't find, open or read file.
	*/
	File_Error,

	/*
		File too short.
	*/
	Premature_EOF,

	/*
		GNU Gettext *.MO file errors.
	*/
	MO_File_Invalid_Signature,
	MO_File_Unsupported_Version,
	MO_File_Invalid,
	MO_File_Incorrect_Plural_Count,
}

/*
	Several ways to use:
	- get(key), which defaults to the singular form and i18n.ACTIVE catalog, or
	- get(key, number), which returns the appropriate plural from the active catalog, or
	- get(key, number, catalog) to grab text from a specific one.
*/
get :: proc(key: string, number := 0, catalog: ^Translation = ACTIVE) -> (value: string) {
	/*
		A lot of languages use singular for 1 item and plural for 0 or more than 1 items. This is our default pluralize rule.
	*/
	plural := 1 if number != 1 else 0

	if catalog.pluralize != nil {
		plural = catalog.pluralize(number)
	}
	return get_by_slot(key, plural, catalog)
}

/*
	Several ways to use:
	- get_by_slot(key), which defaults to the singular form and i18n.ACTIVE catalog, or
	- get_by_slot(key, slot), which returns the requested plural from the active catalog, or
	- get_by_slot(key, slot, catalog) to grab text from a specific one.

	If a file format parser doesn't (yet) support plural slots, each of the slots will point at the same string.
*/
get_by_slot :: proc(key: string, slot := 0, catalog: ^Translation = ACTIVE) -> (value: string) {
	if catalog == nil {
		/*
			Return the key if the catalog catalog hasn't been initialized yet.
		*/
		return key
	}

	/*
		Return the translation from the requested slot if this key is known, else return the key.
	*/
	if translations, ok := catalog.k_v[key]; ok {
		plural := min(max(0, slot), MAX_PLURALS - 1)
		return translations[plural]
	}
	return key
}

/*
	Same for destroy:
	- destroy(), to clean up the currently active catalog catalog i18n.ACTIVE
	- destroy(catalog), to clean up a specific catalog.
*/
destroy :: proc(catalog: ^Translation = ACTIVE) {
	if catalog != nil {
		strings.intern_destroy(&catalog.intern)
		delete(catalog.k_v)
		free(catalog)
	}
}