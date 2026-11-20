package test_core_xml

// Out-of-memory robustness for the parser. A failing allocator wraps a
// tracking allocator; sweeping the fail point across every allocation a parse
// makes must yield Allocation_Failed, and `destroy` must free everything the
// parse allocated before it failed.

import "base:runtime"
import "core:encoding/xml"
import "core:mem"
import "core:strings"
import "core:testing"

@(private="file")
Failing_Allocator :: struct {
	backing: runtime.Allocator,
	count:   int,
	fail_at: int,
}

@(private="file")
failing_allocator_proc :: proc(
	data: rawptr, mode: runtime.Allocator_Mode,
	size, alignment: int, old_memory: rawptr, old_size: int,
	loc := #caller_location,
) -> ([]byte, runtime.Allocator_Error) {
	fa := (^Failing_Allocator)(data)
	#partial switch mode {
	case .Alloc, .Alloc_Non_Zeroed, .Resize, .Resize_Non_Zeroed:
		if fa.count == fa.fail_at {
			fa.count += 1
			return nil, .Out_Of_Memory
		}
		fa.count += 1
	}
	return fa.backing.procedure(fa.backing.data, mode, size, alignment, old_memory, old_size, loc)
}

@(private="file")
failing_allocator :: proc(fa: ^Failing_Allocator) -> runtime.Allocator {
	return {procedure = failing_allocator_proc, data = fa}
}

// Puts every kind of allocation on the sweep: the copy of the input, the
// prologue's attributes, a comment before the root and one inside it, an
// element's attributes growing past their first 8, values and a body that go
// through a builder (one longer than a block of the strings arena), and more
// than the 1024 elements the parser makes room for at first.
@(private="file")
oom_document :: proc() -> string {
	b := strings.builder_make()
	strings.write_string(&b, `<?xml version="1.0" encoding="utf-8"?><!-- before --><r`)
	for i in 0 ..< 12 {
		strings.write_string(&b, ` a`)
		strings.write_int(&b, i)
		strings.write_string(&b, `="&amp;`)
		strings.write_int(&b, i)
		strings.write_string(&b, `"`)
	}
	strings.write_string(&b, ` long="`)
	for _ in 0 ..< 2000 {
		strings.write_byte(&b, 'x')
	}
	strings.write_string(&b, `">&lt;body&gt;`)
	for _ in 0 ..< 1100 {
		strings.write_string(&b, `<e/>`)
	}
	strings.write_string(&b, `<!-- inside --></r>`)
	return strings.to_string(b)
}

// Parses `data`, or loads the file `path` if one is given.
@(private="file")
oom_parse :: proc(data, path: string, options: xml.Options, allocator: mem.Allocator) -> (^xml.Document, xml.Error) {
	if path != "" {
		return xml.load_from_file(path, options, Silent, allocator)
	}
	return xml.parse_string(data, options, "", Silent, allocator)
}

@(private="file")
sweep_parse :: proc(t: ^testing.T, data: string, options: xml.Options, elements := -1, path := "", loc := #caller_location) {
	total: int
	{
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		defer mem.tracking_allocator_destroy(&track)
		fa := Failing_Allocator{backing = mem.tracking_allocator(&track), fail_at = -1}
		doc, err := oom_parse(data, path, options, failing_allocator(&fa))
		total = fa.count
		testing.expect_value(t, err, xml.Error.None, loc)
		if elements >= 0 {
			testing.expect_value(t, doc.element_count, xml.Element_ID(elements), loc)
		} else {
			testing.expect_value(t, doc.element_count, 1102 if .Intern_Comments in options.flags else 1101, loc)
		}
		xml.destroy(doc, failing_allocator(&fa))
		testing.expect(t, total >= 1, loc = loc)
		testing.expect_value(t, len(track.allocation_map), 0, loc)
	}

	for k in 0 ..< total {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		defer mem.tracking_allocator_destroy(&track)
		fa := Failing_Allocator{backing = mem.tracking_allocator(&track), fail_at = k}
		doc, err := oom_parse(data, path, options, failing_allocator(&fa))
		testing.expectf(t, err == .Allocation_Failed, "k=%d of %d: got %v", k, total, err, loc = loc)
		xml.destroy(doc, failing_allocator(&fa))
		testing.expectf(t, len(track.allocation_map) == 0, "k=%d of %d: %d leaked", k, total, len(track.allocation_map), loc = loc)
	}
}

// Small enough for the strings arena's smallest blocks (256 bytes), which an element's
// attributes past their first 8, and a decoded body of more than 256 bytes, outgrow.
@(private="file")
oom_small_document :: proc() -> string {
	b := strings.builder_make()
	strings.write_string(&b, `<r`)
	for i in 0 ..< 12 {
		strings.write_string(&b, ` a`)
		strings.write_int(&b, i)
		strings.write_string(&b, `="`)
		strings.write_int(&b, i)
		strings.write_string(&b, `"`)
	}
	strings.write_string(&b, `>&lt;`)
	for _ in 0 ..< 300 {
		strings.write_byte(&b, 'x')
	}
	strings.write_string(&b, `&gt;</r>`)
	return strings.to_string(b)
}

@(test)
test_oom_load_from_file :: proc(t: ^testing.T) {
	// Reading the file allocates too, and the parse takes over the data it read.
	sweep_parse(t, "", {flags = {.Ignore_Unsupported, .Intern_Comments}}, elements = 24, path = TEST_SUITE_PATH + "I18N/nl_NL-qt-ts.ts")
}

@(test)
test_oom_parse :: proc(t: ^testing.T) {
	data := oom_document()
	defer delete(data)

	sweep_parse(t, data, {flags = {.Ignore_Unsupported, .Intern_Comments, .Decode_SGML_Entities}})
	sweep_parse(t, data, {flags = {.Ignore_Unsupported, .Intern_Comments}})
	sweep_parse(t, data, {flags = {.Ignore_Unsupported}})

	small := oom_small_document()
	defer delete(small)

	sweep_parse(t, small, {flags = {.Ignore_Unsupported, .Decode_SGML_Entities}}, elements = 1)
	sweep_parse(t, small, {flags = {.Ignore_Unsupported}}, elements = 1)
}
