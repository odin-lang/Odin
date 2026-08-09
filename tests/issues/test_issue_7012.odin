// Tests issue https://github.com/odin-lang/Odin/issues/7012
package test_issues

import "base:intrinsics"

Foo :: struct($T: typeid) {
	x: T,
}

#assert(intrinsics.type_is_specialization_of(Foo(int), Foo))
#assert(!intrinsics.type_is_specialization_of(Foo, Foo))
#assert(!intrinsics.type_is_specialization_of(Foo(int), Foo(int)))
#assert(!intrinsics.type_is_specialization_of(i32, Foo))
