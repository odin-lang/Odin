// Class methods returning `instancetype`, called in each way. `pkg.Type_method()` used to hit an assertion
// in the checker and, for any class method, in the backend.
package test_issue_objc_class_method_calls

import "pkg"

main :: proc() {
	a := pkg.String.make()
	b := pkg.String_make()
	c := pkg.MutableString.make() // sent to the subclass
	d := pkg.make_string()

	#assert(type_of(a) == ^pkg.String)
	#assert(type_of(b) == ^pkg.String)
	#assert(type_of(c) == ^pkg.MutableString)

	_, _, _, _ = a, b, c, d
}
