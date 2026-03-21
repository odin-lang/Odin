package xml_tools

import      "core:encoding/xml"
import      "core:os"
import path "core:path/filepath"
import      "core:strings"
import      "core:strconv"
import      "core:slice"
import      "core:fmt"

GENERATED :: `/*
	------ GENERATED ------ DO NOT EDIT ------ GENERATED ------ DO NOT EDIT ------ GENERATED ------
*/`

TABLE_FILE_PROLOG :: `/*
	This file is generated from "https://github.com/w3c/xml-entities/blob/gh-pages/unicode.xml".

	UPDATE:
		- Ensure the XML file was downloaded using "tests\core\download_assets.py", given the path to the "tests\assets" directory.
		- Run "core/unicode/tools/generate_entity_table.odin"

	Odin unicode generated tables: https://github.com/odin-lang/Odin/tree/master/core/encoding/entity

		Copyright David Carlisle 1999-2025

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

// Silent error handler for the parser.
Error_Handler :: proc(pos: xml.Pos, fmt: string, args: ..any) {}

OPTIONS :: xml.Options{ flags = { .Ignore_Unsupported, }, expected_doctype = "unicode", }

Entity :: struct {
	codepoints:  [2]rune,
	name:        string, // &name;
	description: string,
}

Character :: struct {
	codepoint:   rune,
	category:    string,
	description: string,
}

main :: proc() {
	filename, err_xml := path.join({ODIN_ROOT, "tests", "core", "assets", "XML", "unicode.xml"}, context.allocator)
	defer delete(filename)

	if err_xml != .None {
		fmt.eprintfln("Join path error for unicode.xml: %v", err_xml)
		os.exit(1)
	}

	doc, err := xml.load_from_file(filename, OPTIONS, Error_Handler)
	defer xml.destroy(doc)

	if err != .None {
		fmt.eprintfln("Load/Parse error: %v", err)
		if err == .File_Error {
			fmt.eprintfln("%q not found. Did you run \"tests\\download_assets.py\"?", filename)
		}
		os.exit(1)
	}

	fmt.printfln("%q loaded and parsed.", filename)

	charlist_id, charlist_ok := xml.find_child_by_ident(doc, 0, "charlist")
	if !charlist_ok {
		fmt.eprintln("Could not locate top-level `<charlist>` tag.")
		os.exit(1)
	}

	charlist := doc.elements[charlist_id]

	fmt.printfln("Found `<charlist>` with %v children.", len(charlist.value))

	// These are for `core:encoding/entity`, and only keep track of codepoints which have
	// one or more <entity> children pointing to it.
	//
	// This means that this array can have the same codepoint appear more than once, e.g.
	// `Aring` and `angst` are both a capital A with a circle. The latter is the Angstrom symbol.
	entities: [dynamic]Entity
	defer delete(entities)
	entity_map: map[string]Entity
	defer delete(entity_map)

	min_name_length := max(int)
	max_name_length := min(int)
	shortest_name: string
	longest_name:  string

	// This is for `core:unicode`'s tables and has all children of `<charlist>`
	characters: [dynamic]Character
	defer delete(characters)

	for char_id in charlist.value {
		id := char_id.(xml.Element_ID)
		char := doc.elements[id]

		if char.ident != "character" {
			fmt.eprintfln("Expected `<charlist>` child to be `<character>`, got `<%v>`", char.ident)
			os.exit(1)
		}

		// `dec` is the codepoint, or codepoints separated by a `-`.
		codepoint_string, ok := xml.find_attribute_val_by_key(doc, id, "dec")
		if !ok {
			fmt.eprintln("`<character dec=\"...\">` attribute not found.")
			os.exit(1)
		}

		r1, _, r2 := strings.partition(codepoint_string, "-")

		codepoint, codepoint2: int
		codepoint, _ = strconv.parse_int(r1)
		if r2 != "" {
			codepoint2, _ = strconv.parse_int(r2)
		}

		// This is the description we add to `core:encoding/entity`'s generated table
		desc, desc_ok := xml.find_child_by_ident(doc, id, "description")
		assert(desc_ok)
		description := ""
		if len(doc.elements[desc].value) == 1 {
			description = doc.elements[desc].value[0].(string)
		}

		// For us to be interested in a character for `core:unicode`, it has to have `<unicodedata category="..">`
		//
		// Not present for e.g. MULTIPLE CHARACTER OPERATOR: arccos
		// and some maths characters without a character category
		if unicodedata, unicodedata_ok := xml.find_child_by_ident(doc, id, "unicodedata"); unicodedata_ok {
			// Not present for some math characters, e.g. codepoint: 10913-824, desc: "DOUBLE NESTED LESS-THAN with slash"
			if category_string, category_ok := xml.find_attribute_val_by_key(doc, unicodedata, "category"); category_ok {
				// These should only consist of a single rune.
				assert(codepoint2 == 0)
				append(&characters, Character{
					codepoint   = rune(codepoint),
					description = description,
					category    = category_string,
				})
			}
		}

		// For us to be interested in this codepoint for `core:encoding/entity`, it has to have at least one `<entity>`.
		nth := 0
		for {
			character_entity := xml.find_child_by_ident(doc, id, "entity", nth) or_break
			nth += 1
			name := xml.find_attribute_val_by_key(doc, character_entity, "id") or_continue
			if len(name) == 0 {
				// Invalid name. Skip.
				continue
			}

			if len(name) > max_name_length { longest_name  = name }
			if len(name) < min_name_length { shortest_name = name }

			min_name_length = min(min_name_length, len(name))
			max_name_length = max(max_name_length, len(name))

			if name in entity_map {
				continue
			}

			e := Entity{
				name        = name,
				codepoints  = {rune(codepoint), rune(codepoint2)},
				description = description,
			}

			entity_map[name] = e
			append(&entities, e)
		}
	}

	write_encoding_entitities_table(entities[:], shortest_name, longest_name, min_name_length, max_name_length)
	fmt.println()
	write_unicode_category_tables(characters[:])

	// Not a library, no need to clean up.
}

write_encoding_entitities_table :: proc(entities: []Entity, shortest_name, longest_name: string, min_name_length, max_name_length: int) {
	fmt.printfln("Found %v unique `&name;` -> rune mappings.", len(entities))
	fmt.printfln("Shortest name: %v (%v)", shortest_name, min_name_length)
	fmt.printfln("Longest name:  %v (%v)", longest_name,  max_name_length)

	generated_filename, err_generated := path.join({ODIN_ROOT, "core", "encoding", "entity", "generated.odin"}, context.allocator)
	defer delete(generated_filename)

	if err_generated != .None {
		fmt.eprintfln("Join path error for generated.odin: %v", err_generated)
		os.exit(1)
	}

	generated_buf: strings.Builder
	defer strings.builder_destroy(&generated_buf)
	w := strings.to_writer(&generated_buf)

	// Generate table.
	fmt.wprintln(w, "package encoding_unicode_entity")
	fmt.wprintln(w, "")
	fmt.wprintln(w, GENERATED)
	fmt.wprintln(w, "")
	fmt.wprintf (w, TABLE_FILE_PROLOG)
	fmt.wprintln(w, "")

	fmt.wprintfln(w, "// `&%v;`", shortest_name)
	fmt.wprintfln(w, "XML_NAME_TO_RUNE_MIN_LENGTH :: %v", min_name_length)
	fmt.wprintfln(w, "// `&%v;`", longest_name)
	fmt.wprintfln(w, "XML_NAME_TO_RUNE_MAX_LENGTH :: %v", max_name_length)
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

	slice.sort_by(entities, proc(a, b: Entity) -> bool {
		return a.name < b.name
	})

	for e in entities {
		if rune(e.name[0]) != prefix {
			if should_close {
				fmt.wprintln(w, "\t\t}\n")
			}

			prefix = rune(e.name[0])
			fmt.wprintfln(w, "\tcase '%v':", prefix)
			fmt.wprintln(w, "\t\tswitch name {")
		}

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
	when ODIN_DEBUG {
		fmt.println(strings.to_string(generated_buf))
		fmt.println()
	}

	written := os.write_entire_file(generated_filename, transmute([]byte)strings.to_string(generated_buf))

	if written == nil {
		fmt.printfln("Successfully written generated \"%v\".", generated_filename)
	} else {
		fmt.printfln("Failed to write generated \"%v\".", generated_filename)
	}
}

write_unicode_category_tables :: proc(characters: []Character) {
	fmt.printfln("Found %v codepoints with a category.", len(characters))

	// Sort by `category`, then `codepoints`
	slice.sort_by(characters, proc(a, b: Character) -> bool {
		return a.category < b.category && a.codepoint < b.codepoint
	})

	nd_range_start := rune(-1)
	nd_range_end   := rune(-1)
	nd_last: rune
	for c in characters {
		// Find contiguous ranges for the `Nd` category
		if c.category == "Nd" {
			defer nd_last = c.codepoint

			// New range start
			if c.codepoint != nd_last + 1 {
				nd_range_end = nd_last
				if nd_range_start != rune(-1) {
					// Found a range
					// fmt.printfln("%r (%d) - %r (%d) // %s", nd_range_start, nd_range_start, nd_range_end, nd_range_end, c.description)
				}
				nd_range_start = c.codepoint
			}
		}
	}

	/*
	Lu	Letter, Uppercase
	Ll	Letter, Lowercase
	Lt	Letter, Titlecase
	Lm	Letter, Modifier
	Lo	Letter, Other
	Mn	Mark, Nonspacing
	Mc	Mark, Spacing Combining
	Me	Mark, Enclosing
	Nd	Number, Decimal Digit
	Nl	Number, Letter
	No	Number, Other
	Pc	Punctuation, Connector
	Pd	Punctuation, Dash
	Ps	Punctuation, Open
	Pe	Punctuation, Close
	Pi	Punctuation, Initial quote (may behave like Ps or Pe depending on usage)
	Pf	Punctuation, Final quote (may behave like Ps or Pe depending on usage)
	Po	Punctuation, Other
	Sm	Symbol, Math
	Sc	Symbol, Currency
	Sk	Symbol, Modifier
	So	Symbol, Other
	Zs	Separator, Space
	Zl	Separator, Line
	Zp	Separator, Paragraph
	Cc	Other, Control
	Cf	Other, Format
	Cs	Other, Surrogate
	Co	Other, Private Use
	Cn	Other, Not Assigned (no characters in the file have this property)
	*/
}