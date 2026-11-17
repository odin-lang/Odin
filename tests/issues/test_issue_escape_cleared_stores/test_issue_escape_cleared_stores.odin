// A pointer stored where it outlives the procedure is not reported once something may have cleared it; each warning is
// next to a case which must stay quiet
package test_issues

Thing :: struct {
	pointer: rawptr,
}

Two :: struct {
	a, b: rawptr,
}

Outer :: struct {
	inner: Thing,
	other: int,
}

Holder :: struct {
	ptr: ^Thing,
}

Array :: struct {
	elems: [2]rawptr,
}

thing:  Thing
two:    Two
outer:  Outer
holder: Holder
array:  Array
slice:  []rawptr

// A store clears what earlier stores put anywhere within where it stores

whole_then_field :: proc() {
	x: int
	thing = {pointer = &x}
	thing.pointer = nil
}

field_then_whole :: proc() {
	x: int
	thing.pointer = &x
	thing = {}
}

nested_then_outer :: proc() {
	x: int
	outer.inner.pointer = &x
	outer = {}
}

zero_value :: proc() {
	x: int
	thing.pointer = &x
	empty: Thing
	thing = empty
}

cleared_by_defer :: proc(early: bool) {
	x: int
	defer thing = {}
	thing.pointer = &x
	if early {
		return
	}
}

pointee_whole_then_field :: proc(t: ^Thing) {
	x: int
	t^ = {pointer = &x}
	t.pointer = nil
}

pointee_field_then_whole :: proc(t: ^Thing) {
	x: int
	t.pointer = &x
	t^ = {}
}

other_field :: proc() {
	x: int
	two.a = &x // warning
	two.b = nil
}

one_of_two :: proc() {
	x, y: int
	two = {a = &x, b = &y} // warning, about 'y'
	two.a = nil
}

// clearing a pointer leaves what is stored in the memory it pointed to
through_pointer :: proc() {
	x: int
	holder.ptr.pointer = &x // warning
	holder.ptr = nil
}

// A store to an element, whichever it is, clears what each element held

same_constant_index :: proc() {
	x: int
	array.elems[0] = &x
	array.elems[0] = nil
}

same_variable_index :: proc(i: int) {
	x: int
	array.elems[i] = &x
	array.elems[i] = nil
}

slice_element :: proc() {
	x: int
	slice[0] = &x
	slice[0] = nil
}

local_element :: proc() -> [2]rawptr {
	x: int
	elems: [2]rawptr
	elems[0] = &x
	elems[0] = nil
	return elems
}

stored_in_loop :: proc() {
	x: int
	for i in 0..<len(array.elems) {
		array.elems[i] = &x // warning
	}
}
