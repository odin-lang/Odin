package xml_example

import "core:encoding/xml"
import "core:os"
import path "core:path/filepath"
import "core:mem"
import "core:strings"
import "core:strconv"
import "core:slice"
import "core:fmt"

/*
	Silent error handler for the parser.
*/
Error_Handler :: proc(pos: xml.Pos, fmt: string, args: ..any) {}

OPTIONS :: xml.Options{ flags = { .Ignore_Unsupported, }, expected_doctype = "unicode", }

Entity :: struct {
	name:        string,
	codepoints:  [2]rune,
	description: string,
}

generate_encoding_entity_table :: proc() {
	filename := path.join({ODIN_ROOT, "tests", "core", "assets", "XML", "unicode.xml"})
	defer delete(filename)

	generated_filename := path.join({ODIN_ROOT, "core", "encoding", "entity", "generated.odin"})
	defer delete(generated_filename)

	doc, err := xml.load_from_file(filename, OPTIONS, Error_Handler)
	defer xml.destroy(doc)

	if err != .None {
		fmt.printf("Load/Parse error: %v\n", err)
		if err == .File_Error {
			fmt.printf("\"%v\" not found. Did you run \"tests\\download_assets.py\"?", filename)
		}
		os.exit(1)
	}

	fmt.printf("\"%v\" loaded and parsed.\n", filename)

	generated_buf: strings.Builder
	defer strings.builder_destroy(&generated_buf)
	w := strings.to_writer(&generated_buf)

	charlist_id, charlist_ok := xml.find_child_by_ident(doc, 0, "charlist")
	if !charlist_ok {
		fmt.eprintln("Could not locate top-level `<charlist>` tag.")
		os.exit(1)
	}

	charlist := doc.elements[charlist_id]

	fmt.printf("Found `<charlist>` with %v children.\n", len(charlist.value))

	entity_map: map[string]Entity
	defer delete(entity_map)

	names: [dynamic]string
	defer delete(names)

	min_name_length := max(int)
	max_name_length := min(int)
	shortest_name: string
	longest_name:  string

	count := 0
	for char_id in charlist.value {
		id := char_id.(xml.Element_ID)
		char := doc.elements[id]

		if char.ident != "character" {
			fmt.eprintf("Expected `<character>`, got `<%v>`\n", char.ident)
			os.exit(1)
		}

		if codepoint_string, ok := xml.find_attribute_val_by_key(doc, id, "dec"); !ok {
			fmt.eprintln("`<character id=\"...\">` attribute not found.")
			os.exit(1)
		} else {
			r1, _, r2 := strings.partition(codepoint_string, "-")

			codepoint, codepoint2: int
			codepoint, _ = strconv.parse_int(r1)
			if r2 != "" {
				codepoint2, _ = strconv.parse_int(r2)
			}

			desc, desc_ok := xml.find_child_by_ident(doc, id, "description")
			description := ""
			if len(doc.elements[desc].value) == 1 {
				description = doc.elements[desc].value[0].(string)
			}

			/*
				For us to be interested in this codepoint, it has to have at least one entity.
			*/

			nth := 0
			for {
				character_entity := xml.find_child_by_ident(doc, id, "entity", nth) or_break
				nth += 1
				name := xml.find_attribute_val_by_key(doc, character_entity, "id") or_continue
				if len(name) == 0 {
					/*
						Invalid name. Skip.
					*/
					continue
				}

				if name == "\"\"" {
					fmt.printf("%#v\n", char)
					fmt.printf("%#v\n", character_entity)
				}

				if len(name) > max_name_length { longest_name  = name }
				if len(name) < min_name_length { shortest_name = name }

				min_name_length = min(min_name_length, len(name))
				max_name_length = max(max_name_length, len(name))

				e := Entity{
					name        = name,
					codepoints  = {rune(codepoint), rune(codepoint2)},
					description = description,
				}

				if name in entity_map {
					continue
				}

				entity_map[name] = e
				append(&names, name)
				count += 1
			}
		}
	}

	/*
		Sort by name.
	*/
	slice.sort(names[:])

	fmt.printf("Found %v unique `&name;` -> rune mappings.\n", count)
	fmt.printf("Shortest name: %v (%v)\n", shortest_name, min_name_length)
	fmt.printf("Longest name:  %v (%v)\n", longest_name,  max_name_length)

	/*
		Generate table.
	*/
	fmt.wprintln(w, "package encoding_unicode_entity")
	fmt.wprintln(w, "")
	fmt.wprintln(w, GENERATED)
	fmt.wprintln(w, "")
	fmt.wprintf (w, TABLE_FILE_PROLOG)
	fmt.wprintln(w, "")

	fmt.wprintf (w, "// `&%v;`\n", shortest_name)
	fmt.wprintf (w, "XML_NAME_TO_RUNE_MIN_LENGTH :: %v\n", min_name_length)
	fmt.wprintf (w, "// `&%v;`\n", longest_name)
	fmt.wprintf (w, "XML_NAME_TO_RUNE_MAX_LENGTH :: %v\n", max_name_length)
	fmt.wprintln(w, "")

	fmt.wprintln(w,
`
/*
	Input:
		entity_name - a string, like "copy" that describes a user-encoded Unicode entity as used in XML.

	Returns:
		"decoded"    - The decoded runes if found by name, or all zero otherwise.
		"rune_count" - The number of decoded runes
		"ok"         - true if found, false if not.

	IMPORTANT: XML processors (including browsers) treat these names as case-sensitive. So do we.
*/
named_xml_entity_to_rune :: proc(name: string) -> (decoded: [2]rune, rune_count: int, ok: bool) {
	/*
		Early out if the name is too short or too long.
		min as a precaution in case the generated table has a bogus value.
	*/
	if len(name) < min(1, XML_NAME_TO_RUNE_MIN_LENGTH) || len(name) > XML_NAME_TO_RUNE_MAX_LENGTH {
		return
	}

	switch rune(name[0]) {`)

	prefix := '?'
	should_close := false

	for v in names {
		if rune(v[0]) != prefix {
			if should_close {
				fmt.wprintln(w, "\t\t}\n")
			}

			prefix = rune(v[0])
			fmt.wprintf (w, "\tcase '%v':\n", prefix)
			fmt.wprintln(w, "\t\tswitch name {")
		}

		e := entity_map[v]

		fmt.wprintf(w, "\t\tcase \"%v\":", e.name)
		for i := len(e.name); i < max_name_length; i += 1 {
			fmt.wprintf(w, " ")
		}
		fmt.wprintf(w, " // %v\n", e.description)
		if e.codepoints[1] != 0 {
			fmt.wprintf(w, "\t\t\treturn {{%q, %q}}, 2, true\n", e.codepoints[0], e.codepoints[1])
		} else {
			fmt.wprintf(w, "\t\t\treturn {{%q, 0}}, 1, true\n", e.codepoints[0])
		}

		should_close = true
	}
	fmt.wprintln(w, "\t\t}")
	fmt.wprintln(w, "\t}")
	fmt.wprintln(w, "\treturn")
	fmt.wprintln(w, "}\n")
	fmt.wprintln(w, GENERATED)

	fmt.println()
	fmt.println(strings.to_string(generated_buf))
	fmt.println()

	written := os.write_entire_file(generated_filename, transmute([]byte)strings.to_string(generated_buf))

	if written {
		fmt.printf("Successfully written generated \"%v\".\n", generated_filename)
	} else {
		fmt.printf("Failed to write generated \"%v\".\n", generated_filename)
	}
}

GENERATED :: `/*
	------ GENERATED ------ DO NOT EDIT ------ GENERATED ------ DO NOT EDIT ------ GENERATED ------
*/`

TABLE_FILE_PROLOG :: `/*
	This file is generated from "https://github.com/w3c/xml-entities/blob/gh-pages/unicode.xml".
	
	UPDATE:
		- Ensure the XML file was downloaded using "tests\core\download_assets.py".
		- Run "core/unicode/tools/generate_entity_table.odin"

	Odin unicode generated tables: https://github.com/odin-lang/Odin/tree/master/core/encoding/entity

		Copyright David Carlisle 1999-2023

		Use and distribution of this code are permitted under the terms of the
		W3C Software Notice and License.
		http://www.w3.org/Consortium/Legal/2002/copyright-software-20021231.html



		This file is a collection of information about how to map
		Unicode entities to LaTeX, and various SGML/XML entity
		sets (ISO and MathML/HTML). A Unicode character may be mapped
		to several entities.

		Originally designed by Sebastian Rahtz in conjunction with
		Barbara Beeton for the STIX project

	See also: LICENSE_table.md
*/
`

is_dotted_name :: proc(name: string) -> (dotted: bool) {
	for r in name {
		if r == '.' { return true}
	}
	return false
}

main :: proc() {
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	context.allocator = mem.tracking_allocator(&track)

	generate_encoding_entity_table()

	if len(track.allocation_map) > 0 {
		fmt.println()
		for _, v in track.allocation_map {
			fmt.printf("%v Leaked %v bytes.\n", v.location, v.size)
		}
	}
	fmt.println("Done and cleaned up!")
}