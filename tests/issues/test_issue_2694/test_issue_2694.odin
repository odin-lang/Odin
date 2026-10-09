package test_issues

import "core:fmt"
import "core:encoding/json"
import "core:log"
import "core:mem"
import "core:testing"

// This is a minimal reproduction of the code in #2694.
// It exemplifies the original problem as briefly as possible.

SAMPLE_JSON :: `
{
	"foo": 0,
	"things": [
		{ "a": "ZZZZ"},
	]
}
`

@test
test_issue_2694 :: proc(t: ^testing.T) {
	into: struct {
		foo: int,
		things: []json.Object,
	}

	scratch := new(mem.Scratch_Allocator)
	defer free(scratch)
	if mem.scratch_allocator_init(scratch, 4 * mem.Megabyte) != .None {
		log.error("unable to initialize scratch allocator")
		return
	}
	defer mem.scratch_allocator_destroy(scratch)

	err := json.unmarshal_string(SAMPLE_JSON, &into, allocator = mem.scratch_allocator(scratch))
	testing.expect(t, err == nil)

	output := fmt.tprintf("%v", into)
	expected := `{foo = 0, things = [map[a="ZZZZ"]]}`
	testing.expectf(t, output == expected, "\n\texpected: %q\n\tgot:      %q", expected, output)
}
