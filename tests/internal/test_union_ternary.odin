package test_internal

import "core:testing"

// A union constant is built as an anonymous packed struct, which is fine everywhere that adopts the
// value's own type -- a global takes it verbatim. A phi cannot: its incoming values must have the
// phi's own named type, even though the two layouts are identical. Both the ternary and `or_else`
// build one
@(test)
union_constant_in_a_ternary :: proc(t: ^testing.T) {
	E  :: enum { None, Bad, Worse }
	EU :: union { E, string }

	f := true
	g := false

	a: EU = EU(E.Worse) if f else nil
	b: EU = EU("s") if f else nil
	c: EU = nil if g else EU(E.Worse)
	d: EU = EU(E.Worse) if f else EU(E.Bad)
	e: EU = EU(E.Worse) if g else EU(E.Bad)

	if v, ok := a.(E);      testing.expect(t, ok, "a lost its variant") { testing.expect(t, v == E.Worse, "a") }
	if v, ok := b.(string); testing.expect(t, ok, "b lost its variant") { testing.expect_value(t, v, "s") }
	if v, ok := c.(E);      testing.expect(t, ok, "c lost its variant") { testing.expect(t, v == E.Worse, "c") }
	if v, ok := d.(E);      testing.expect(t, ok, "d lost its variant") { testing.expect(t, v == E.Worse, "d") }
	if v, ok := e.(E);      testing.expect(t, ok, "e lost its variant") { testing.expect(t, v == E.Bad, "e") }

	// the arm that is not taken must not decide the result
	n: EU = EU(E.Bad) if g else nil
	_, is_enum := n.(E)
	testing.expect(t, !is_enum, "the untaken arm was selected")
}

@(test)
union_constant_in_or_else :: proc(t: ^testing.T) {
	E  :: enum { None, Bad }
	EU :: union { E, string }

	m: map[int]EU
	defer delete(m)

	missing := m[0] or_else EU(E.Bad)
	if v, ok := missing.(E); testing.expect(t, ok, "or_else default lost its variant") { testing.expect(t, v == E.Bad, "default") }

	m[1] = EU("here")
	present := m[1] or_else EU(E.Bad)
	if v, ok := present.(string); testing.expect(t, ok, "or_else present lost its variant") { testing.expect_value(t, v, "here") }
}
