package test_issue_8258

import "core:testing"

@(test)
file_scope :: proc(t: ^testing.T) {
	testing.expect(t, true)
}

poly :: proc($T: typeid) {
	@(test)
	inner :: proc(t: ^testing.T) {}
}

main :: proc() {
	@(test)
	dummy :: proc(t: ^testing.T) {}

	@(cold, test)
	cold_dummy :: proc(t: ^testing.T) {}

	{
		@(test) nested :: proc(t: ^testing.T) {}
	}

	poly(int)
	poly(f32)
}
