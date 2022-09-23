package test_core_odin_parser

import "core:testing"
import "core:fmt"
import "core:os"
import "core:odin/parser"


expect  :: testing.expect
log     :: testing.log

main :: proc() {
	t := testing.T{}
	test_parse_demo(&t)

	if t.error_count > 0 {
		os.exit(1)
	}
}


@test
test_parse_demo :: proc(t: ^testing.T) {
	pkg, ok := parser.parse_package_from_path("examples/demo")
	
	expect(t, ok == true, "parser.parse_package_from_path failed")

	for key, value in pkg.files {
		expect(t, value.syntax_error_count == 0, fmt.tprintf("%v should contain zero errors", key))
	}
}