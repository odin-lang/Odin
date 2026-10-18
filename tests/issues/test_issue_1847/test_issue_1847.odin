package test_issue_1847

import "core:testing"

Foo :: struct {
	val: int,
}

Bar :: struct {
	i:  int,
	f:  f32,
	b:  bool,
	s:  string,
	r:  rune,
	z:  complex64,
	cs: cstring,
}

Outer :: struct {
	x:     int,
	inner: Foo,
}

E :: enum {A, B, C}

// Fields and elements omitted from a constant compound literal must take their zero value
#assert(Foo{}.val == Foo{}.val)
#assert(Foo{}.val == 0)
#assert(Foo{0}.val == Foo{}.val)

BAR :: Bar{i = 3}
#assert(BAR.i == 3)
#assert(BAR.f == 0)
#assert(!BAR.b)
#assert(BAR.s == "")
#assert(BAR.r == 0)
#assert(BAR.z == 0)

#assert(Outer{}.inner.val == 0)
#assert(Outer{x = 1}.inner.val == 0)

ARR :: [4]int{1 = 7}
#assert(ARR[0] == 0)
#assert(ARR[1] == 7)
#assert(ARR.w == 0)

ENUM_ARR :: #partial [E]int{.B = 2}
#assert(ENUM_ARR[.A] == 0)
#assert(ENUM_ARR[.B] == 2)
#assert(ENUM_ARR[.C] == 0)

// Tests issue #1847 https://github.com/odin-lang/Odin/issues/1847
@(test)
test_issue_1847 :: proc(t: ^testing.T) {
	testing.expect(t, Foo{}.val == 0)
	testing.expect(t, BAR.f == 0)
	testing.expect(t, BAR.s == "")
	testing.expect(t, BAR.cs == nil)
	testing.expect(t, Outer{}.inner.val == 0)
	testing.expect(t, ARR.w == 0)
	testing.expect(t, ENUM_ARR[.C] == 0)
}
