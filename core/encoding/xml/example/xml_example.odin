package xml_example

import "core:encoding/xml"
import "core:mem"
import "core:strings"
import "core:fmt"

Error_Handler :: proc(pos: xml.Pos, fmt: string, args: ..any) {

}

FILENAME :: "../../../../tests/core/assets/xml/nl_NL-xliff-1.0.xliff"
DOC      :: #load(FILENAME)

OPTIONS  :: xml.Options{
	flags            = {
		.Ignore_Unsupported, .Intern_Comments,
	},
	expected_doctype = "",
}

_main :: proc() {
	using fmt

	println("--- DOCUMENT TO PARSE  ---")
	println(string(DOC))
	println("--- /DOCUMENT TO PARSE ---\n")

	doc, err := xml.parse(DOC, OPTIONS, FILENAME, Error_Handler)
	defer xml.destroy(doc)

	buf: strings.Builder
	defer strings.destroy_builder(&buf)
	w := strings.to_writer(&buf)

	xml.print(w, doc)
	println(strings.to_string(buf))

	if err != .None {
		printf("Parse error: %v\n", err)
	} else {
		println("DONE!")
	}
}

main :: proc() {
	using fmt

	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	context.allocator = mem.tracking_allocator(&track)

	_main()

	if len(track.allocation_map) > 0 {
		println()
		for _, v in track.allocation_map {
			printf("%v Leaked %v bytes.\n", v.location, v.size)
		}
	}	
}