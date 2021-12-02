package unicode_entity_example

import "core:encoding/xml"
import "core:encoding/entity"
import "core:strings"
import "core:mem"
import "core:fmt"
import "core:time"

OPTIONS  :: xml.Options{
	flags            = {
		.Ignore_Unsupported, .Intern_Comments,
	},
	expected_doctype = "",
}

doc_print :: proc(doc: ^xml.Document) {
	buf: strings.Builder
	defer strings.destroy_builder(&buf)
	w := strings.to_writer(&buf)

	xml.print(w, doc)
	fmt.println(strings.to_string(buf))
}

_entities :: proc() {
	doc: ^xml.Document
	err: xml.Error

	DOC :: #load("../../../../tests/core/assets/XML/unicode.xml")

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
	using fmt

	doc, err := xml.parse(#load("test.html"))
	defer xml.destroy(doc)
	doc_print(doc)

	if false {
		val := doc.root.children[1].children[2].value

		println()
		replaced, ok := entity.decode_xml(val)
		defer delete(replaced)

		printf("Before:      '%v', Err: %v\n", val, err)
		printf("Passthrough: '%v'\nOK: %v\n", replaced, ok)
		println()
	}

	if false {
		val := doc.root.children[1].children[2].value

		println()
		replaced, ok := entity.decode_xml(val, { .CDATA_Unbox })
		defer delete(replaced)

		printf("Before:      '%v', Err: %v\n", val, err)
		printf("CDATA_Unbox: '%v'\nOK: %v\n", replaced, ok)
		println()
	}

	if true {
		val := doc.root.children[1].children[2].value

		println()
		replaced, ok := entity.decode_xml(val, { .CDATA_Unbox, .CDATA_Decode })
		defer delete(replaced)

		printf("Before: '%v', Err: %v\n", val, err)
		printf("CDATA_Decode: '%v'\nOK: %v\n", replaced, ok)
		println()
	}

	if true {
		val := doc.root.children[1].children[1].value

		println()
		replaced, ok := entity.decode_xml(val, { .Comment_Strip })
		defer delete(replaced)

		printf("Before: '%v', Err: %v\n", val, err)
		printf("Comment_Strip: '%v'\nOK: %v\n", replaced, ok)
		println()
	}
}

main :: proc() {
	using fmt

	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	context.allocator = mem.tracking_allocator(&track)

	_main()
	//_entities()

	if len(track.allocation_map) > 0 {
		println()
		for _, v in track.allocation_map {
			printf("%v Leaked %v bytes.\n", v.location, v.size)
		}
	}	
}