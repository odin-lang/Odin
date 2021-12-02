package xml_example

import "core:encoding/xml"
import "core:os"
import "core:path"
import "core:mem"
import "core:fmt"

/*
	Silent error handler for the parser.
*/
Error_Handler :: proc(pos: xml.Pos, fmt: string, args: ..any) {}

OPTIONS :: xml.Options{ flags = { .Ignore_Unsupported, }, expected_doctype = "unicode", }

example :: proc() {
	using fmt

	filename := path.join(ODIN_ROOT, "tests", "core", "assets", "XML", "unicode.xml")
	defer delete(filename)

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

	charlist, charlist_ok := xml.find_child_by_ident(doc.root, "charlist")
	if !charlist_ok {
		eprintln("Could not locate top-level `<charlist>` tag.")
		os.exit(1)
	}

	printf("Found `<charlist>` with %v children.\n", len(charlist.children))

	for char in charlist.children {
		if char.ident != "character" {
			eprintf("Expected `<character>`, got `<%v>`\n", char.ident)
			os.exit(1)
		}

		if _, ok := xml.find_attribute_val_by_key(char, "dec"); !ok {
			eprintln("`<character dec=\"...\">` attribute not found.")
			os.exit(1)
		}
	}
}

main :: proc() {
	using fmt

	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	context.allocator = mem.tracking_allocator(&track)

	example()

	if len(track.allocation_map) > 0 {
		println()
		for _, v in track.allocation_map {
			printf("%v Leaked %v bytes.\n", v.location, v.size)
		}
	}
	println("Done and cleaned up!")
}