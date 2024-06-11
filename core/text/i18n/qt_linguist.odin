package i18n
/*
	A parser for Qt Linguist TS files.

	Copyright 2022 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-3 license.

	A from-scratch implementation based after the specification found here:
		https://doc.qt.io/qt-5/linguist-ts-file-format.html

	List of contributors:
		Jeroen van Rijn: Initial implementation.
*/
import "core:os"
import "core:encoding/xml"
import "core:strings"

TS_XML_Options := xml.Options{
	flags = {
		.Input_May_Be_Modified,
		.Must_Have_Prolog,
		.Must_Have_DocType,
		.Ignore_Unsupported,
		.Unbox_CDATA,
		.Decode_SGML_Entities,
	},
	expected_doctype = "TS",
}

parse_qt_linguist_from_bytes :: proc(data: []byte, options := DEFAULT_PARSE_OPTIONS, pluralizer: proc(int) -> int = nil, allocator := context.allocator) -> (translation: ^Translation, err: Error) {
	context.allocator = allocator

	get_str :: proc(val: xml.Value, intern: ^strings.Intern) -> (str: string, err: Error) {
		v, ok := val.(string)
		if ok {
			if intern != nil {
				v, _ = strings.intern_get(intern, v)
			}
			return v, .None
		}
		return "", .Bad_Str
	}

	get_id :: proc(val: xml.Value) -> (str: xml.Element_ID, err: Error) {
		v, ok := val.(xml.Element_ID)
		if ok {
			return v, .None
		}
		return 0, .Bad_Id
	}

	ts, xml_err := xml.parse(data, TS_XML_Options)
	defer xml.destroy(ts)

	if xml_err != .None || ts.element_count < 1 || ts.elements[0].ident != "TS" || len(ts.elements[0].value) == 0 {
		return nil, .TS_File_Parse_Error
	}

	/*
		Initalize Translation, interner and optional pluralizer.
	*/
	translation = new(Translation)
	translation.pluralize = pluralizer
	strings.intern_init(&translation.intern, allocator, allocator)

	section: ^Section

	for value in ts.elements[0].value {
		child_id := get_id(value) or_return

		// These should be <context>s.

		if ts.elements[child_id].ident != "context" {
			return translation, .TS_File_Expected_Context
		}

		// Find section name.
		section_name_id, section_name_found := xml.find_child_by_ident(ts, child_id, "name")
		if !section_name_found {
			return translation, .TS_File_Expected_Context_Name,
		}

		section_name, _ := strings.intern_get(&translation.intern, "")
		if !options.merge_sections {
			section_name = get_str(ts.elements[section_name_id].value[0], &translation.intern) or_return
		}

		if section_name not_in translation.k_v {
			translation.k_v[section_name] = {}
		}
		section = &translation.k_v[section_name]

		// Find messages in section.
		nth: int
		for {
			message_id := xml.find_child_by_ident(ts, child_id, "message", nth) or_break

			numerus_tag, _ := xml.find_attribute_val_by_key(ts, message_id, "numerus")
			has_plurals := numerus_tag == "yes"

			// We must have a <source> = key
			source_id, source_found := xml.find_child_by_ident(ts, message_id, "source")
			if !source_found {
				return translation, .TS_File_Expected_Source
			}

			// We must have a <translation>
			translation_id, translation_found := xml.find_child_by_ident(ts, message_id, "translation")
			if !translation_found {
				return translation, .TS_File_Expected_Translation
			}

			source := get_str(ts.elements[source_id].value[0], &translation.intern) or_return

			xlat := ""
			if !has_plurals {
				xlat = get_str(ts.elements[translation_id].value[0], &translation.intern) or_return
			}

			if source in section {
				return translation, .Duplicate_Key
			}

			if has_plurals {
				if xlat != "" {
					return translation, .TS_File_Expected_NumerusForm
				}

				num_plurals: int
				for {
					xml.find_child_by_ident(ts, translation_id, "numerusform", num_plurals) or_break
					num_plurals += 1
				}

				if num_plurals < 2 {
					return translation, .TS_File_Expected_NumerusForm
				}
				section[source] = make([]string, num_plurals)

				num_plurals = 0
				for {
					numerus_id := xml.find_child_by_ident(ts, translation_id, "numerusform", num_plurals) or_break
					numerus := get_str(ts.elements[numerus_id].value[0], &translation.intern) or_return
					section[source][num_plurals] = numerus

					num_plurals += 1
				}
			} else {
				// Single translation
				section[source] = make([]string, 1)
				section[source][0] = xlat
			}

			nth += 1
		}
	}

	return
}

parse_qt_linguist_file :: proc(filename: string, options := DEFAULT_PARSE_OPTIONS, pluralizer: proc(int) -> int = nil, allocator := context.allocator) -> (translation: ^Translation, err: Error) {
	context.allocator = allocator

	data, data_ok := os.read_entire_file(filename)
	if !data_ok { return {}, .File_Error }

	return parse_qt_linguist_from_bytes(data, options, pluralizer, allocator)
}

parse_qt :: proc { parse_qt_linguist_file, parse_qt_linguist_from_bytes }