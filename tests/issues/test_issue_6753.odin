// test issue for #6753 https://github.com/odin-lang/odin/issues/6753
package test_issues
import "core:testing"
import "core:fmt"

foo_concrete :: proc(x: int, g: proc(int) -> int) -> int {
	return g(x)
}
foo_impossible :: proc(x: int, g: proc(int, int) -> string) -> string {
	return "impossible"
}
foo_group :: proc {
	foo_concrete,
	foo_impossible,
}

f_poly :: proc(x: $T) -> T { return x }
foo_poly :: proc(x: $T, g: proc(T) -> T = f_poly) -> T {
	return g(x)
}

@test
test_issue_6753_ambiguous_poly_argument :: proc (t: ^testing.T) {
	testing.expect_value(t, foo_group(1, f_poly), 1) // should be no ambiguity whether foo_concrete or foo_impossible
}

@test
test_issue_6753_default_poly_proc :: proc (t: ^testing.T) {
	testing.expect_value(t, foo_poly(1), 1)
}

@test
test_issue_6753_parapoly_proc_variable :: proc(t: ^testing.T) {
	p: proc(int) -> int = f_poly
	testing.expect(t, p != nil, "polymorphic procedure was not instantiated")
	testing.expect_value(t, p(123), 123)
}

// -- Fixing above led to some new bugs surfacing --
@test
test_issue_6753_parapoly_proc_as_argument :: proc(t: ^testing.T) {
	testing.expect(t, foo_concrete(123, f_poly) == 123, "failed to pass poly proc as argument")
}

@test
test_issue_6753_parapoly_with_default_proc_same_generic_type_T :: proc(t: ^testing.T) {
	testing.expect_value(t, foo_poly(123), 123)
	testing.expect_value(t, foo_poly(123, f_poly), 123)
}

// all together now
describe :: proc(x: $T) -> string { return fmt.tprintf("#%v", x) }
describe_bytes :: proc(x: []byte) -> string { return "bytes" }

bar_poly  :: proc(x: $T, g: proc(x: T) -> string = describe) -> string { return g(x) }
bar_bytes :: proc(x: []byte, g: proc(x: []byte) -> string) -> string { return g(x) }
bar_group :: proc { bar_poly, bar_bytes }

@test
test_issue_6753_parapoly_default_in_group :: proc(t: ^testing.T) {
	testing.expect_value(t, bar_group(123, describe), "#123")
	testing.expect_value(t, bar_group("hi"), "#hi")
	testing.expect_value(t, bar_group([]byte{1, 2}, describe_bytes), "bytes")
}
