package xml_example

import "core:encoding/xml"
import "core:os"
import "core:mem"
import "core:fmt"
import "core:time"
import "core:strings"
import "core:hash"

example :: proc() {
	using fmt

	doc: ^xml.Document
	err: xml.Error

	DOC :: #load("../../../../tests/core/assets/XML/unicode.xml")

	parse_duration: time.Duration
	{
		time.SCOPED_TICK_DURATION(&parse_duration)
		doc, err = xml.parse(DOC, xml.Options{flags={.Ignore_Unsupported}})
	}
	defer xml.destroy(doc)

	ms := time.duration_milliseconds(parse_duration)
	speed := (f64(1000.0) / ms) * f64(len(DOC)) / 1_024.0 / 1_024.0
	fmt.printf("Parse time: %v bytes in %.2f ms (%.2f MiB/s).\n", len(DOC), ms, speed)

	if err != .None {
		printf("Load/Parse error: %v\n", err)
		if err == .File_Error {
			println("\"unicode.xml\" not found. Did you run \"tests\\download_assets.py\"?")
		}
		os.exit(1)
	}

	println("\"unicode.xml\" loaded and parsed.")

	charlist, charlist_ok := xml.find_child_by_ident(doc.root, "charlist")
	if !charlist_ok {
		eprintln("Could not locate top-level `<charlist>` tag.")
		os.exit(1)
	}

	printf("Found `<charlist>` with %v children.\n", len(charlist.children))

	crc32 := doc_hash(doc)
	printf("[%v] CRC32: 0x%08x\n", "🎉" if crc32 == 0xcaa042b9 else "🤬", crc32)
}

doc_hash :: proc(doc: ^xml.Document, print := false) -> (crc32: u32) {
	buf: strings.Builder
	defer strings.destroy_builder(&buf)
	w := strings.to_writer(&buf)

	xml.print(w, doc)
	tree := strings.to_string(buf)
	if print { fmt.println(tree) }
	return hash.crc32(transmute([]u8)tree)
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