// Tests issue #7429: local distinct types in procedure literal values must have
// unique canonical names.
// https://github.com/odin-lang/Odin/issues/7429
package test_issues

main :: proc() {
	_ = proc() {
		Foo :: distinct string
		_ = typeid_of(Foo)
	}
	_ = proc() {
		Foo :: distinct string
		_ = typeid_of(Foo)
	}
}
