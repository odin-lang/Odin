package i18n
/*
	Internationalization helpers.

	Copyright 2021-2022 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-3 license.

	List of contributors:
		Jeroen van Rijn: Initial implementation.
*/
import "core:strings"

/*
	TODO:
	- Support for more translation catalog file formats.
*/

/*
	Currently active catalog.
*/
ACTIVE: ^Translation

// Allow between 1 and 255 plural forms. Default: 10.
MAX_PLURALS :: min(max(#config(ODIN_i18N_MAX_PLURAL_FORMS, 10), 1), 255)

/*
	The main data structure. This can be generated from various different file formats, as long as we have a parser for them.
*/

Section :: map[string][]string

Translation :: struct {
	k_v:    map[string]Section, // k_v[section][key][plural_form] = ...
	intern: strings.Intern,

	pluralize: proc(number: int) -> int,
}

Error :: enum {
	/*
		General return values.
	*/
	None = 0,
	Empty_Translation_Catalog,
	Duplicate_Key,

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

	/*
		Qt Linguist *.TS file errors.
	*/
	TS_File_Parse_Error,
	TS_File_Expected_Context,
	TS_File_Expected_Context_Name,
	TS_File_Expected_Source,
	TS_File_Expected_Translation,
	TS_File_Expected_NumerusForm,
	Bad_Str,
	Bad_Id,

}

Parse_Options :: struct {
	merge_sections: bool,
}

DEFAULT_PARSE_OPTIONS :: Parse_Options{
	merge_sections = false,
}

/*
	Several ways to use:
	- get(key), which defaults to the singular form and i18n.ACTIVE catalog, or
	- get(key, number), which returns the appropriate plural from the active catalog, or
	- get(key, number, catalog) to grab text from a specific one.
*/
get_single_section :: proc(key: string, number := 1, catalog: ^Translation = ACTIVE) -> (value: string) {
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
	- get(section, key), which defaults to the singular form and i18n.ACTIVE catalog, or
	- get(section, key, number), which returns the appropriate plural from the active catalog, or
	- get(section, key, number, catalog) to grab text from a specific one.
*/
get_by_section :: proc(section, key: string, number := 1, catalog: ^Translation = ACTIVE) -> (value: string) {
	/*
		A lot of languages use singular for 1 item and plural for 0 or more than 1 items. This is our default pluralize rule.
	*/
	plural := 1 if number != 1 else 0

	if catalog.pluralize != nil {
		plural = catalog.pluralize(number)
	}
	return get_by_slot(section, key, plural, catalog)
}
get :: proc{get_single_section, get_by_section}

/*
	Several ways to use:
	- get_by_slot(key), which defaults to the singular form and i18n.ACTIVE catalog, or
	- get_by_slot(key, slot), which returns the requested plural from the active catalog, or
	- get_by_slot(key, slot, catalog) to grab text from a specific one.

	If a file format parser doesn't (yet) support plural slots, each of the slots will point at the same string.
*/
get_by_slot_single_section :: proc(key: string, slot := 0, catalog: ^Translation = ACTIVE) -> (value: string) {
	return get_by_slot_by_section("", key, slot, catalog)
}

/*
	Several ways to use:
	- get_by_slot(key), which defaults to the singular form and i18n.ACTIVE catalog, or
	- get_by_slot(key, slot), which returns the requested plural from the active catalog, or
	- get_by_slot(key, slot, catalog) to grab text from a specific one.

	If a file format parser doesn't (yet) support plural slots, each of the slots will point at the same string.
*/
get_by_slot_by_section :: proc(section, key: string, slot := 0, catalog: ^Translation = ACTIVE) -> (value: string) {
	if catalog == nil || section not_in catalog.k_v {
		/*
			Return the key if the catalog catalog hasn't been initialized yet, or the section is not present.
		*/
		return key
	}

	/*
		Return the translation from the requested slot if this key is known, else return the key.
	*/
	if translations, ok := catalog.k_v[section][key]; ok {
		plural := min(max(0, slot), len(catalog.k_v[section][key]) - 1)
		return translations[plural]
	}
	return key
}
get_by_slot :: proc{get_by_slot_single_section, get_by_slot_by_section}

/*
	Same for destroy:
	- destroy(), to clean up the currently active catalog catalog i18n.ACTIVE
	- destroy(catalog), to clean up a specific catalog.
*/
destroy :: proc(catalog: ^Translation = ACTIVE, allocator := context.allocator) {
	context.allocator = allocator

	if catalog == nil {
		return
	}

	for section in catalog.k_v {
		for key in catalog.k_v[section] {
			delete(catalog.k_v[section][key])
		}
		delete(catalog.k_v[section])
	}
	delete(catalog.k_v)
	strings.intern_destroy(&catalog.intern)
	free(catalog)
}