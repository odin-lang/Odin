// Tests PR #xxxx https://github.com/odin-lang/Odin/issues/xxxx
package test_issues

TEST_EXPECT_FAILURE :: #config(TEST_EXPECT_FAILURE, false)

// Interfaces
IFoo :: struct {
	foo: proc(self: ^IFoo) -> string,
}

IBar :: struct {
	bar: proc(self: ^IBar) -> string,
}


// Virtual table holders
Foo :: struct {
	using vt: IFoo,
}

// This is OK, but be careful!
Foo_Bar :: struct #raw_union {
	using vt_foo: IFoo,
	using vt_bar: IBar,
}

// Implementation via Foo
Foo_Impl :: IFoo {
	foo = proc(self: ^Foo) -> string {
		return "Foo"
	},
}

// Implementations via Foo_Bar
Foo_Bar_Foo_Impl :: IFoo {
	foo = proc(self: ^Foo_Bar) -> string {
		return "Foo_Bar: Foo"
	},
}

Foo_Bar_Bar_Impl :: IBar {
	bar = proc(self: ^Foo_Bar) -> string {
		return "Foo_Bar: Bar"
	},
}

when TEST_EXPECT_FAILURE {
	// Will not be allowed in to be used in an implementation:
	// The interface and implementation do not share the same address.
	Invalid_Foo :: struct {
		x: int,
		using vt: IFoo,
	}

	Invalid_Foo_Impl :: IFoo {
		// Will not compile:
		foo = proc(self: ^Invalid_Foo) -> string {
			return ""
		},
	}
}

import "core:testing"

@test
test_const_array_fill_assignment :: proc(t: ^testing.T) {
	foo := Foo {
		vt = Foo_Impl,
	}
	testing.expect_value(t, foo->foo(), "Foo")

	foo_bar := Foo_Bar {
		vt_foo = Foo_Bar_Foo_Impl,
	}
	testing.expect_value(t, foo_bar->foo(), "Foo_Bar: Foo")

	foo_bar.vt_bar = Foo_Bar_Bar_Impl
	testing.expect_value(t, foo_bar->bar(), "Foo_Bar: Bar")
}
