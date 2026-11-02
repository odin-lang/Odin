// Tests that an empty field inside an inlined enum field in a struct is rejected
// in the parser instead of propagating a null to the checker where it crashed the
// compiler
package test_issue_enum_field_inlined

Valid :: struct {
	foo: enum {
		A,
		B,
		C,
	},
}

Invalid :: struct {
	foo: enum {
		A,
		B,,
		C,
	},
}
