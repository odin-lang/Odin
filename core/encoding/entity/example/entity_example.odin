package unicode_entity_example

import "core:encoding/xml"
import "core:strings"
import "core:mem"
import "core:fmt"
import "core:time"

doc_print :: proc(doc: ^xml.Document) {
	buf: strings.Builder
	defer strings.builder_destroy(&buf)
	w := strings.to_writer(&buf)

	xml.print(w, doc)
	fmt.println(strings.to_string(buf))
}

_entities :: proc() {
	doc: ^xml.Document
	err: xml.Error

	DOC :: #load("../../../../tests/core/assets/XML/unicode.xml")

	OPTIONS  :: xml.Options{
		flags            = {
			.Ignore_Unsupported, .Intern_Comments,
		},
		expected_doctype = "",
	}

	parse_duration: time.Duration

	{
		time.SCOPED_TICK_DURATION(&parse_duration)
		doc, err = xml.parse(DOC, OPTIONS)
	}
	defer xml.destroy(doc)

	doc_print(doc)

	ms := time.duration_milliseconds(parse_duration)

	speed := (f64(1000.0) / ms) * f64(len(DOC)) / 1_024.0 / 1_024.0

	fmt.printf("Parse time: %.2f ms (%.2f MiB/s).\n", ms, speed)
	fmt.printf("Error: %v\n", err)
}

_main :: proc() {
	options := xml.Options{ flags = { .Ignore_Unsupported, .Intern_Comments, .Unbox_CDATA, .Decode_SGML_Entities }}

	doc, _ := xml.parse(#load("test.html"), options)

	defer xml.destroy(doc)
	doc_print(doc)
}

main :: proc() {
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	context.allocator = mem.tracking_allocator(&track)

	// _main()
	_entities()

	if len(track.allocation_map) > 0 {
		fmt.println()
		for _, v in track.allocation_map {
			fmt.printf("%v Leaked %v bytes.\n", v.location, v.size)
		}
	}	
}