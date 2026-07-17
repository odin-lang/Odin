// Tests issue #6484 https://github.com/odin-lang/Odin/pull/6484
package test_issues

foreign import lib "this_library_does_not_exist"

foreign lib {
	foo :: proc(int) ---
	when true {}
	when true {}
	bar :: proc() ---
}

foo_bar :: proc {
	foo,
	bar,
}

