// A pointer stored where it outlives the procedure is not reported once something may have cleared it; each warning is
// next to a case which must stay quiet
package test_issues

import "base:intrinsics"
import "core:mem"

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
list:   [dynamic]rawptr

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

// A store is matched by where it goes, e.g. a global through a pointer to it, or what a parameter points to

set :: proc(t: ^Thing, p: rawptr) {
	t.pointer = p
}

stored_through_local_pointer :: proc() {
	x: int
	p := &thing
	p.pointer = &x
	thing.pointer = nil
}

cleared_through_local_pointer :: proc() {
	x: int
	thing.pointer = &x
	p := &thing
	p.pointer = nil
}

stored_by_call :: proc() {
	x: int
	set(&thing, &x)
	thing.pointer = nil
}

stored_by_call_through_parameter :: proc(t: ^Thing) {
	x: int
	set(t, &x)
	t.pointer = nil
}

cleared_through_element_pointer :: proc() {
	x: int
	array.elems[0] = &x
	p := &array.elems[1]
	p^ = nil
}

other_parameter :: proc(t, u: ^Thing) {
	x: int
	set(t, &x) // warning
	u.pointer = nil
}

other_field_through_local_pointer :: proc() {
	x: int
	p := &two
	p.a = &x // warning
	two.b = nil
}

// A call storing into a global is matched by where in it the call stores

set_global :: proc(p: rawptr) {
	thing.pointer = p
}

set_global_whole :: proc(p: rawptr) {
	thing = {pointer = p}
}

stored_into_global_by_call :: proc() {
	x: int
	set_global(&x)
	thing.pointer = nil
}

stored_into_global_whole_by_call :: proc() {
	x: int
	set_global_whole(&x)
	thing.pointer = nil
}

other_global :: proc() {
	x: int
	set_global(&x) // warning
	outer.inner.pointer = nil
}

// A call which may write over a pointer clears it

reset :: proc(t: ^Thing) {
	t.pointer = nil
}

reset_global :: proc() {
	thing.pointer = nil
}

reset_two_b :: proc(t: ^Two) {
	t.b = nil
}

cleared_by_call :: proc() {
	x: int
	thing.pointer = &x
	reset(&thing)
}

cleared_by_call_without_arguments :: proc() {
	x: int
	thing.pointer = &x
	reset_global()
}

local_cleared_by_call :: proc() -> Thing {
	x: int
	t: Thing
	set(&t, &x)
	reset(&t)
	return t
}

cleared_by_procedure_value :: proc() {
	x: int
	f := reset
	thing.pointer = &x
	f(&thing)
}

cleared_by_zeroing :: proc() {
	x: int
	thing.pointer = &x
	intrinsics.mem_zero(&thing, size_of(thing))
}

cleared_by_zero_item :: proc() {
	x: int
	thing.pointer = &x
	mem.zero_item(&thing)
}

cleared_bytewise :: proc() {
	x: int
	thing.pointer = &x
	mem.set(&thing, 0, size_of(thing))
}

other_field_cleared_by_call :: proc() {
	x: int
	two.a = &x // warning
	reset_two_b(&two)
}

other_pointer_cleared_by_call :: proc() {
	x: int
	thing.pointer = &x // warning
	reset(&outer.inner)
}

not_cleared_by_allocation :: proc() {
	x: int
	thing.pointer = &x // warning
	p := new(int)
	free(p)
}

// A pointer cleared on one path is taken as cleared where the paths join

cleared_on_one_path :: proc(c: bool) {
	x: int
	thing.pointer = &x
	if c {
		thing.pointer = nil
	}
}

cleared_under_the_same_condition :: proc(c: bool) {
	x: int
	if c {
		thing.pointer = &x
	}
	if c {
		thing.pointer = nil
	}
}

cleared_in_loop :: proc() {
	x: int
	array.elems[0] = &x
	for &elem in array.elems {
		elem = nil
	}
}

stored_on_the_other_path :: proc(c: bool) {
	x: int
	if c {
		thing.pointer = &x // warning
	} else {
		thing.pointer = nil
	}
}

stored_again_after_clearing :: proc(n: int) {
	x: int
	for _ in 0..<n {
		thing.pointer = nil
		thing.pointer = &x // warning
	}
}

cleared_before_early_return :: proc(c: bool) {
	x: int
	thing.pointer = &x // warning
	if c {
		thing.pointer = nil
		return
	}
}

slice_cleared_in_loop :: proc() {
	x: int
	slice[0] = &x
	for &elem in slice {
		elem = nil
	}
}

list_cleared_in_loop :: proc() {
	x: int
	list[0] = &x
	for &elem in list {
		elem = nil
	}
}

// `clear` only sets the length, leaving the pointer in the buffer
list_cleared_by_length :: proc() {
	x: int
	list[0] = &x // warning
	clear(&list)
}

// a returned pointer is not a store
local_cleared_on_one_path :: proc(c: bool) -> ^int {
	x: int
	p := &x
	if c {
		p = nil
	}
	return p // warning
}
