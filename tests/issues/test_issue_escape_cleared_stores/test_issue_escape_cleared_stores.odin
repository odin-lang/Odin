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

// Up to 64 Write-to-global paths stay exact; past 64 paths, direct paths merge per global entity without affecting other globals

Many_Globals :: struct {
	f00, f01, f02, f03, f04, f05, f06, f07, f08, f09: rawptr,
	f10, f11, f12, f13, f14, f15, f16, f17, f18, f19: rawptr,
	f20, f21, f22, f23, f24, f25, f26, f27, f28, f29: rawptr,
	f30, f31, f32, f33, f34, f35, f36, f37, f38, f39: rawptr,
	f40, f41, f42, f43, f44, f45, f46, f47, f48, f49: rawptr,
	f50, f51, f52, f53, f54, f55, f56, f57, f58, f59: rawptr,
	f60, f61, f62, f63, f64, other:                   rawptr,
}

many: Many_Globals

write_nine_fields_of_same_global :: proc() {
	many.f00 = nil; many.f01 = nil; many.f02 = nil; many.f03 = nil; many.f04 = nil
	many.f05 = nil; many.f06 = nil; many.f07 = nil; many.f08 = nil
}

write_64_fields_of_same_global :: proc() {
	many.f00 = nil; many.f01 = nil; many.f02 = nil; many.f03 = nil; many.f04 = nil
	many.f05 = nil; many.f06 = nil; many.f07 = nil; many.f08 = nil; many.f09 = nil
	many.f10 = nil; many.f11 = nil; many.f12 = nil; many.f13 = nil; many.f14 = nil
	many.f15 = nil; many.f16 = nil; many.f17 = nil; many.f18 = nil; many.f19 = nil
	many.f20 = nil; many.f21 = nil; many.f22 = nil; many.f23 = nil; many.f24 = nil
	many.f25 = nil; many.f26 = nil; many.f27 = nil; many.f28 = nil; many.f29 = nil
	many.f30 = nil; many.f31 = nil; many.f32 = nil; many.f33 = nil; many.f34 = nil
	many.f35 = nil; many.f36 = nil; many.f37 = nil; many.f38 = nil; many.f39 = nil
	many.f40 = nil; many.f41 = nil; many.f42 = nil; many.f43 = nil; many.f44 = nil
	many.f45 = nil; many.f46 = nil; many.f47 = nil; many.f48 = nil; many.f49 = nil
	many.f50 = nil; many.f51 = nil; many.f52 = nil; many.f53 = nil; many.f54 = nil
	many.f55 = nil; many.f56 = nil; many.f57 = nil; many.f58 = nil; many.f59 = nil
	many.f60 = nil; many.f61 = nil; many.f62 = nil; many.f63 = nil
}

write_many_globals :: proc() {
	write_64_fields_of_same_global()
	many.f64 = nil
}

call_write_many_globals :: proc() {
	write_many_globals()
}

write_many_and_store :: proc(p: rawptr) {
	write_many_globals()
	thing.pointer = p
}

other_field_still_warns_at_nine_fields :: proc() {
	x: int
	many.other = &x // warning
	write_nine_fields_of_same_global()
}

other_field_still_warns_at_path_limit :: proc() {
	x: int
	many.other = &x // warning
	write_64_fields_of_same_global()
}

// Known coarsening: writing >64 paths merges direct paths on `many` into whole `many`, losing this warning on `many.other`
lost_warning_other_field_past_path_limit :: proc() {
	x: int
	many.other = &x
	write_many_globals()
}

cleared_by_many_global_writes :: proc() {
	x: int
	thing.pointer = &x // warning
	write_many_globals()
}

cleared_through_many_global_writes_wrapper :: proc() {
	x: int
	thing.pointer = &x // warning
	call_write_many_globals()
}

stored_after_many_global_writes :: proc() {
	x: int
	write_many_globals()
	thing.pointer = &x // warning
}

param_not_cleared_by_many_global_writes :: proc(t: ^Thing) {
	x: int
	t.pointer = &x // warning
	write_many_globals()
}

unrelated_global_still_warns_locally :: proc() {
	x: int
	thing.pointer = &x // warning
	many.f00 = nil; many.f01 = nil; many.f02 = nil; many.f03 = nil; many.f04 = nil
	many.f05 = nil; many.f06 = nil; many.f07 = nil; many.f08 = nil; many.f09 = nil
	many.f10 = nil; many.f11 = nil; many.f12 = nil; many.f13 = nil; many.f14 = nil
	many.f15 = nil; many.f16 = nil; many.f17 = nil; many.f18 = nil; many.f19 = nil
	many.f20 = nil; many.f21 = nil; many.f22 = nil; many.f23 = nil; many.f24 = nil
	many.f25 = nil; many.f26 = nil; many.f27 = nil; many.f28 = nil; many.f29 = nil
	many.f30 = nil; many.f31 = nil; many.f32 = nil; many.f33 = nil; many.f34 = nil
	many.f35 = nil; many.f36 = nil; many.f37 = nil; many.f38 = nil; many.f39 = nil
	many.f40 = nil; many.f41 = nil; many.f42 = nil; many.f43 = nil; many.f44 = nil
	many.f45 = nil; many.f46 = nil; many.f47 = nil; many.f48 = nil; many.f49 = nil
	many.f50 = nil; many.f51 = nil; many.f52 = nil; many.f53 = nil; many.f54 = nil
	many.f55 = nil; many.f56 = nil; many.f57 = nil; many.f58 = nil; many.f59 = nil
	many.f60 = nil; many.f61 = nil; many.f62 = nil; many.f63 = nil; many.f64 = nil
}

stored_by_many_global_writes_call :: proc() {
	x: int
	write_many_and_store(&x) // warning
}

// Past 64 distinct global entities, Write-to-global flows collapse into an any-global kill

g00, g01, g02, g03, g04, g05, g06, g07, g08, g09: rawptr
g10, g11, g12, g13, g14, g15, g16, g17, g18, g19: rawptr
g20, g21, g22, g23, g24, g25, g26, g27, g28, g29: rawptr
g30, g31, g32, g33, g34, g35, g36, g37, g38, g39: rawptr
g40, g41, g42, g43, g44, g45, g46, g47, g48, g49: rawptr
g50, g51, g52, g53, g54, g55, g56, g57, g58, g59: rawptr
g60, g61, g62, g63, g64:                          rawptr

write_at_global_write_limit :: proc() {
	g00 = nil; g01 = nil; g02 = nil; g03 = nil; g04 = nil
	g05 = nil; g06 = nil; g07 = nil; g08 = nil; g09 = nil
	g10 = nil; g11 = nil; g12 = nil; g13 = nil; g14 = nil
	g15 = nil; g16 = nil; g17 = nil; g18 = nil; g19 = nil
	g20 = nil; g21 = nil; g22 = nil; g23 = nil; g24 = nil
	g25 = nil; g26 = nil; g27 = nil; g28 = nil; g29 = nil
	g30 = nil; g31 = nil; g32 = nil; g33 = nil; g34 = nil
	g35 = nil; g36 = nil; g37 = nil; g38 = nil; g39 = nil
	g40 = nil; g41 = nil; g42 = nil; g43 = nil; g44 = nil
	g45 = nil; g46 = nil; g47 = nil; g48 = nil; g49 = nil
	g50 = nil; g51 = nil; g52 = nil; g53 = nil; g54 = nil
	g55 = nil; g56 = nil; g57 = nil; g58 = nil; g59 = nil
	g60 = nil; g61 = nil; g62 = nil; g63 = nil
}

write_over_global_write_limit :: proc() {
	write_at_global_write_limit()
	g64 = nil
}

call_write_over_global_write_limit :: proc() {
	write_over_global_write_limit()
}

write_over_limit_and_store :: proc(p: rawptr) {
	write_over_global_write_limit()
	thing.pointer = p
}

warning_at_global_write_limit :: proc() {
	x: int
	thing.pointer = &x // warning
	write_at_global_write_limit()
}

// Known coarsening: writing >64 separate globals collapses to an any-global kill, losing this warning on `thing`
lost_warning_past_global_write_limit :: proc() {
	x: int
	thing.pointer = &x
	write_over_global_write_limit()
}

lost_warning_past_global_write_limit_wrapper :: proc() {
	x: int
	thing.pointer = &x
	call_write_over_global_write_limit()
}

stored_after_global_write_limit :: proc() {
	x: int
	write_over_global_write_limit()
	thing.pointer = &x // warning
}

param_not_cleared_past_global_write_limit :: proc(t: ^Thing) {
	x: int
	t.pointer = &x // warning
	write_over_global_write_limit()
}

stored_by_call_past_global_write_limit :: proc() {
	x: int
	write_over_limit_and_store(&x) // warning
}

through_global_pointer_at_limit :: proc() {
	x: int
	holder.ptr.pointer = &x // warning
	write_at_global_write_limit()
}

// Known coarsening: past the any-global limit, earlier stores through a global pointer are also cleared
lost_warning_through_global_pointer_past_limit :: proc() {
	x: int
	holder.ptr.pointer = &x
	write_over_global_write_limit()
}

// Past 64 distinct deref writes through a global pointer, summaries also collapse into an any-global kill

many_ptr: ^Many_Globals

write_at_deref_write_limit :: proc() {
	many_ptr.f00 = nil; many_ptr.f01 = nil; many_ptr.f02 = nil; many_ptr.f03 = nil; many_ptr.f04 = nil
	many_ptr.f05 = nil; many_ptr.f06 = nil; many_ptr.f07 = nil; many_ptr.f08 = nil; many_ptr.f09 = nil
	many_ptr.f10 = nil; many_ptr.f11 = nil; many_ptr.f12 = nil; many_ptr.f13 = nil; many_ptr.f14 = nil
	many_ptr.f15 = nil; many_ptr.f16 = nil; many_ptr.f17 = nil; many_ptr.f18 = nil; many_ptr.f19 = nil
	many_ptr.f20 = nil; many_ptr.f21 = nil; many_ptr.f22 = nil; many_ptr.f23 = nil; many_ptr.f24 = nil
	many_ptr.f25 = nil; many_ptr.f26 = nil; many_ptr.f27 = nil; many_ptr.f28 = nil; many_ptr.f29 = nil
	many_ptr.f30 = nil; many_ptr.f31 = nil; many_ptr.f32 = nil; many_ptr.f33 = nil; many_ptr.f34 = nil
	many_ptr.f35 = nil; many_ptr.f36 = nil; many_ptr.f37 = nil; many_ptr.f38 = nil; many_ptr.f39 = nil
	many_ptr.f40 = nil; many_ptr.f41 = nil; many_ptr.f42 = nil; many_ptr.f43 = nil; many_ptr.f44 = nil
	many_ptr.f45 = nil; many_ptr.f46 = nil; many_ptr.f47 = nil; many_ptr.f48 = nil; many_ptr.f49 = nil
	many_ptr.f50 = nil; many_ptr.f51 = nil; many_ptr.f52 = nil; many_ptr.f53 = nil; many_ptr.f54 = nil
	many_ptr.f55 = nil; many_ptr.f56 = nil; many_ptr.f57 = nil; many_ptr.f58 = nil; many_ptr.f59 = nil
	many_ptr.f60 = nil; many_ptr.f61 = nil; many_ptr.f62 = nil; many_ptr.f63 = nil
}

write_over_deref_write_limit :: proc() {
	write_at_deref_write_limit()
	many_ptr.f64 = nil
}

warning_at_deref_write_limit :: proc() {
	x: int
	thing.pointer = &x // warning
	write_at_deref_write_limit()
}

// Known coarsening: writing >64 deref paths through global pointers collapses to an any-global kill, losing this warning on `thing`
lost_warning_past_deref_write_limit :: proc() {
	x: int
	thing.pointer = &x
	write_over_deref_write_limit()
}
