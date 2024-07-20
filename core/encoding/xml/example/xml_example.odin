package xml_example

import "core:encoding/xml"
import "core:mem"
import "core:fmt"
import "core:time"
import "core:strings"
import "core:hash"

N :: 1

example :: proc() {
	using fmt

	docs:  [N]^xml.Document
	errs:  [N]xml.Error
	times: [N]time.Duration

	defer for round in 0..<N {
		xml.destroy(docs[round])
	}

	DOC :: #load("../../../../tests/core/assets/XML/utf8.xml")
	input := DOC

	for round in 0..<N {
		start := time.tick_now()

		docs[round], errs[round] = xml.parse(input, xml.Options{
			flags={.Ignore_Unsupported},
			expected_doctype = "",
		})

		end   := time.tick_now()
		times[round] = time.tick_diff(start, end)
	}

	fastest := max(time.Duration)
	slowest := time.Duration(0)
	total   := time.Duration(0)

	for round in 0..<N {
		fastest = min(fastest, times[round])
		slowest = max(slowest, times[round])
		total  += times[round]
	}

	fastest_ms := time.duration_milliseconds(fastest)
	slowest_ms := time.duration_milliseconds(slowest)
	average_ms := time.duration_milliseconds(time.Duration(f64(total) / f64(N)))

	fastest_speed := (f64(1000.0) / fastest_ms) * f64(len(DOC)) / 1_024.0 / 1_024.0
	slowest_speed := (f64(1000.0) / slowest_ms) * f64(len(DOC)) / 1_024.0 / 1_024.0
	average_speed := (f64(1000.0) / average_ms) * f64(len(DOC)) / 1_024.0 / 1_024.0

	fmt.printf("N = %v\n", N)
	fmt.printf("[Fastest]: %v bytes in %.2f ms (%.2f MiB/s).\n", len(input), fastest_ms, fastest_speed)
	fmt.printf("[Slowest]: %v bytes in %.2f ms (%.2f MiB/s).\n", len(input), slowest_ms, slowest_speed)
	fmt.printf("[Average]: %v bytes in %.2f ms (%.2f MiB/s).\n", len(input), average_ms, average_speed)

	if errs[0] != .None {
		printf("Load/Parse error: %v\n", errs[0])
		if errs[0] == .File_Error {
			println("\"unicode.xml\" not found. Did you run \"tests\\download_assets.py\"?")
		}
		return
	}

	charlist, charlist_ok := xml.find_child_by_ident(docs[0], 0, "charlist")
	if !charlist_ok {
	 	eprintln("Could not locate top-level `<charlist>` tag.")
	 	return
	}

	printf("Found `<charlist>` with %v children, %v elements total\n", len(docs[0].elements[charlist].value), docs[0].element_count)

	crc32 := doc_hash(docs[0], false)
	printf("[%v] CRC32: 0x%08x\n", "🎉" if crc32 == 0x420dbac5 else "🤬", crc32)

	for round in 0..<N {
		defer xml.destroy(docs[round])
	}
}

doc_hash :: proc(doc: ^xml.Document, print := false) -> (crc32: u32) {
	buf: strings.Builder
	defer strings.builder_destroy(&buf)
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
