package xml_example

import "core:encoding/xml"
import "core:os"
import "core:path"
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
	codepoint:   rune,
	description: string,
}

generate_encoding_entity_table :: proc() {
	using fmt

	filename := path.join(ODIN_ROOT, "tests", "core", "assets", "XML", "unicode.xml")
	defer delete(filename)

	generated_filename := path.join(ODIN_ROOT, "core", "encoding", "entity", "generated.odin")
	defer delete(generated_filename)

	doc, err := xml.parse(filename, OPTIONS, Error_Handler)
	defer xml.destroy(doc)

	if err != .None {
		printf("Load/Parse error: %v\n", err)
		if err == .File_Error {
			printf("\"%v\" not found. Did you run \"tests\\download_assets.py\"?", filename)
		}
		os.exit(1)
	}

	printf("\"%v\" loaded and parsed.\n", filename)

	generated_buf: strings.Builder
	defer strings.destroy_builder(&generated_buf)
	w := strings.to_writer(&generated_buf)

	charlist, charlist_ok := xml.find_child_by_ident(doc.root, "charlist")
	if !charlist_ok {
		eprintln("Could not locate top-level `<charlist>` tag.")
		os.exit(1)
	}

	printf("Found `<charlist>` with %v children.\n", len(charlist.children))

	entity_map: map[string]Entity
	names: [dynamic]string

	min_name_length := max(int)
	max_name_length := min(int)
	shortest_name: string
	longest_name:  string

	count := 0
	for char in charlist.children {
		if char.ident != "character" {
			eprintf("Expected `<character>`, got `<%v>`\n", char.ident)
			os.exit(1)
		}

		if codepoint_string, ok := xml.find_attribute_val_by_key(char, "dec"); !ok {
			eprintln("`<character id=\"...\">` attribute not found.")
			os.exit(1)
		} else {
			codepoint := strconv.atoi(codepoint_string)

			desc, desc_ok := xml.find_child_by_ident(char, "description")
			description   := desc.value if desc_ok else ""

			/*
				For us to be interested in this codepoint, it has to have at least one entity.
			*/

			nth := 0
			for {
				character_entity, entity_ok := xml.find_child_by_ident(char, "entity", nth)
				if !entity_ok { break }

				nth   += 1
				if name, name_ok := xml.find_attribute_val_by_key(character_entity, "id"); name_ok {

					if len(name) == 0 {
						/*
							Invalid name. Skip.
						*/
						continue
					}

					if name == "\"\"" {
						printf("%#v\n", char)
						printf("%#v\n", character_entity)
					}

					if len(name) > max_name_length { longest_name  = name }
					if len(name) < min_name_length { shortest_name = name }

					min_name_length = min(min_name_length, len(name))
					max_name_length = max(max_name_length, len(name))

					e := Entity{
						name        = name,
						codepoint   = rune(codepoint),
						description = description,
					}

					if _, seen := entity_map[name]; seen {
						continue
					}

					entity_map[name] = e
					append(&names, name)
					count += 1
				}
			}
		}
	}

	/*
		Sort by name.
	*/
	slice.sort(names[:])

	printf("Found %v unique `&name;` -> rune mappings.\n", count)
	printf("Shortest name: %v (%v)\n", shortest_name, min_name_length)
	printf("Longest name:  %v (%v)\n", longest_name,  max_name_length)

	// println(rune_to_string(1234))

	/*
		Generate table.
	*/
	wprintln(w, "package unicode_entity")
	wprintln(w, "")
	wprintln(w, GENERATED)
	wprintln(w, "")
	wprintf (w, TABLE_FILE_PROLOG)
	wprintln(w, "")

	wprintf (w, "// `&%v;`\n", shortest_name)
	wprintf (w, "XML_NAME_TO_RUNE_MIN_LENGTH :: %v\n", min_name_length)
	wprintf (w, "// `&%v;`\n", longest_name)
	wprintf (w, "XML_NAME_TO_RUNE_MAX_LENGTH :: %v\n", max_name_length)
	wprintln(w, "")

	wprintln(w,
`
/*
	Input:
		entity_name - a string, like "copy" that describes a user-encoded Unicode entity as used in XML.

	Output:
		"decoded" - The decoded rune if found by name, or -1 otherwise.
		"ok"      - true if found, false if not.

	IMPORTANT: XML processors (including browsers) treat these names as case-sensitive. So do we.
*/
named_xml_entity_to_rune :: proc(name: string) -> (decoded: rune, ok: bool) {
	/*
		Early out if the name is too short or too long.
		min as a precaution in case the generated table has a bogus value.
	*/
	if len(name) < min(1, XML_NAME_TO_RUNE_MIN_LENGTH) || len(name) > XML_NAME_TO_RUNE_MAX_LENGTH {
		return -1, false
	}

	switch rune(name[0]) {
`)

	prefix := '?'
	should_close := false

	for v in names {
		if rune(v[0]) != prefix {
			if should_close {
				wprintln(w, "\t\t}\n")
			}

			prefix = rune(v[0])
			wprintf (w, "\tcase '%v':\n", prefix)
			wprintln(w, "\t\tswitch name {")
		}

		e := entity_map[v]

		wprintf(w, "\t\t\tcase \"%v\": \n",     e.name)
		wprintf(w, "\t\t\t\t// %v\n",           e.description)
		wprintf(w, "\t\t\t\treturn %v, true\n", rune_to_string(e.codepoint))

		should_close = true
	}
	wprintln(w, "\t\t}")
	wprintln(w, "\t}")
	wprintln(w, "\treturn -1, false")
	wprintln(w, "}\n")
	wprintln(w, GENERATED)

	println()
	println(strings.to_string(generated_buf))
	println()

	written := os.write_entire_file(generated_filename, transmute([]byte)strings.to_string(generated_buf))

	if written {
		fmt.printf("Successfully written generated \"%v\".", generated_filename)
	} else {
		fmt.printf("Failed to write generated \"%v\".", generated_filename)
	}

	delete(entity_map)
	delete(names)
	for name in &names {
		free(&name)
	}
}

GENERATED :: `/*
	------ GENERATED ------ DO NOT EDIT ------ GENERATED ------ DO NOT EDIT ------ GENERATED ------
*/`

TABLE_FILE_PROLOG :: `/*
	This file is generated from "https://www.w3.org/2003/entities/2007xml/unicode.xml".
	
	UPDATE:
		- Ensure the XML file was downloaded using "tests\core\download_assets.py".
		- Run "core/unicode/tools/generate_entity_table.odin"

	Odin unicode generated tables: https://github.com/odin-lang/Odin/tree/master/core/encoding/entity

		Copyright © 2021 World Wide Web Consortium, (Massachusetts Institute of Technology,
		European Research Consortium for Informatics and Mathematics, Keio University, Beihang).

		All Rights Reserved.

		This work is distributed under the W3C® Software License [1] in the hope that it will be useful,
		but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

		[1] http://www.w3.org/Consortium/Legal/copyright-software

	See also: LICENSE_table.md
*/
`

rune_to_string :: proc(r: rune) -> (res: string) {
	res = fmt.tprintf("%08x", int(r))
	for len(res) > 2 && res[:2] == "00" {
		res = res[2:]
	}
	return fmt.tprintf("rune(0x%v)", res)
}

is_dotted_name :: proc(name: string) -> (dotted: bool) {
	for r in name {
		if r == '.' { return true}
	}
	return false
}

main :: proc() {
	using fmt

	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	context.allocator = mem.tracking_allocator(&track)

	generate_encoding_entity_table()

	if len(track.allocation_map) > 0 {
		println()
		for _, v in track.allocation_map {
			printf("%v Leaked %v bytes.\n", v.location, v.size)
		}
	}
	println("Done and cleaned up!")
}