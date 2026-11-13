package unicode_entity_example

import "core:encoding/entity"
import "core:fmt"
import "core:mem"
import "core:strings"

TEST_HTML :: #load("test.html", string)

example :: proc() {
	partial, html_err := entity.decode_xml(TEST_HTML, {.HTML_Entities})
	delete(partial)
	fmt.printfln("decode_xml of test.html: %v", html_err)

	unescaped, unescaped_allocated, unescape_err := entity.unescape_html(TEST_HTML)
	defer if unescaped_allocated { delete(unescaped) }
	if unescape_err != nil {
		fmt.eprintfln("unescape_html: %v", unescape_err)
		return
	}
	fmt.printfln("unescape_html of test.html:\n%v", unescaped)

	escaped, escaped_allocated := entity.escape_html(unescaped)
	defer if escaped_allocated { delete(escaped) }
	fmt.printfln("escape_html of that:\n%v", escaped)

	decoded, decode_err := entity.decode_xml(escaped)
	defer delete(decoded)
	expected, expected_allocated := strings.replace_all(unescaped, "\r\n", "\n")
	defer if expected_allocated { delete(expected) }
	fmt.printfln("decode_xml of that: %v, round trip with line ends normalised: %v", decode_err, decoded == expected)
}

main :: proc() {
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	context.allocator = mem.tracking_allocator(&track)

	example()

	if len(track.allocation_map) > 0 {
		fmt.println()
		for _, v in track.allocation_map {
			fmt.printf("%v Leaked %v bytes.\n", v.location, v.size)
		}
	}
}
