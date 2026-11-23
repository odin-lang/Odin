#+private file
package test_internal

// A conformance test of the "odin" and "contextless" calling conventions.
// The procedures below are polymorphic: every type in the tests gets its own instances, each with that type's ABI.
// A value is passed alone, among other arguments, past the argument registers, and in a variadic list.
// It is returned alone, among other results, and through `#optional_ok`.
// Every procedure is called directly and through a procedure value, from callers built with and without optimization.
// Each callee checks its arguments and `context`, and returns known values, which its caller checks.

import "base:intrinsics"
import "base:runtime"
import "core:testing"

// The seeds of the values: those passed in, and those each procedure returns
ABI_A           :: 1
ABI_B           :: 2
ABI_MANY        :: 16 // and up, one for each argument of `abi_many`
ABI_SINGLE      :: 32
ABI_MIXED       :: 33
ABI_MANY_RESULT :: 34
ABI_RESULT_0    :: 35
ABI_RESULT_2    :: 36
ABI_OPT         :: 37
ABI_CONTEXTLESS :: 38

// The `context.user_index` of every caller, which each callee with a `context` checks
ABI_MARK :: 0x0D1CC

// The scalars passed beside the values.
// They are read through a volatile load so that the optimizer cannot specialize the callees for them.
Abi_Scalars :: struct {
	x: u8,
	y: f64,
	z: i32,
	n: int,
	c: int,
}

abi_scalars := Abi_Scalars{x = 0xA5, y = 1.5, z = -7, n = 12345, c = 777}

Abi_Failure :: struct {
	count: int,
	what:  string, // the procedure or the call that saw it first
	arg:   int,    // the argument, or 100 and up for the results, or -1 for `context`
	part:  int,    // the leaf of the value, in the order `abi_walk` visits them
}

@(thread_local)
abi_failure: Abi_Failure

abi_fail :: #force_no_inline proc "contextless" (what: string, arg, part: int) {
	if abi_failure.count == 0 {
		abi_failure.what = what
		abi_failure.arg  = arg
		abi_failure.part = part
	}
	abi_failure.count += 1
}

abi_context :: #force_no_inline proc(what: string) {
	if context.user_index != ABI_MARK {
		abi_fail(what, -1, 0)
	}
}

abi_mix :: proc "contextless" (s, part: u64) -> u64 {
	x := s*0x9E3779B97F4A7C15 + part*0xBF58476D1CE4E5B9 + 1
	x ~= x >> 29
	x *= 0x94D049BB133111EB
	x ~= x >> 32
	return x
}

abi_strings  := [?]string{"", "a", "odin", "calling convention"}
abi_cstrings := [?]cstring{"", "b", "abi"}
abi_typeids  := [?]typeid{int, f64, string}

abi_at :: proc "contextless" (p: rawptr, offset: int) -> rawptr {
	return nil if p == nil else rawptr(uintptr(p) + uintptr(offset))
}

abi_put_int :: proc "contextless" (p: rawptr, size: int, x: u64) {
	switch size {
	case 1:
		intrinsics.unaligned_store((^u8)(p), u8(x))
	case 2:
		intrinsics.unaligned_store((^u16)(p), u16(x))
	case 4:
		intrinsics.unaligned_store((^u32)(p), u32(x))
	case 8:
		intrinsics.unaligned_store((^u64)(p), x)
	case 16:
		intrinsics.unaligned_store((^u128)(p), u128(x) << 64 | u128(abi_mix(x, 1)))
	}
}

Abi_Leaf :: enum {
	Int,
	Float,
	Bool,
	String,
	Cstring,
	Slice,
	Any,
	Typeid,
}

// Writes the next leaf into `want`, and compares it with the same leaf of `have` when there is one
abi_leaf :: proc "contextless" (want, have: rawptr, kind: Abi_Leaf, size: int, s: u64, part: ^int, what: string, arg: int) {
	x := abi_mix(s, u64(part^))
	switch kind {
	case .Int:
		abi_put_int(want, size, x)
	case .Float:
		f := f64(x % 1024) * 0.5 + 0.25
		switch size {
		case 2:
			intrinsics.unaligned_store((^f16)(want), f16(f))
		case 4:
			intrinsics.unaligned_store((^f32)(want), f32(f))
		case 8:
			intrinsics.unaligned_store((^f64)(want), f)
		}
	case .Bool:
		abi_put_int(want, size, x & 1)
	case .String:
		intrinsics.unaligned_store((^string)(want), abi_strings[x % len(abi_strings)])
	case .Cstring:
		intrinsics.unaligned_store((^cstring)(want), abi_cstrings[x % len(abi_cstrings)])
	case .Slice:
		intrinsics.unaligned_store((^runtime.Raw_Slice)(want), runtime.Raw_Slice{rawptr(uintptr(x)), int(x % 4096)})
	case .Any:
		intrinsics.unaligned_store((^runtime.Raw_Any)(want), runtime.Raw_Any{rawptr(uintptr(x)), abi_typeids[x % len(abi_typeids)]})
	case .Typeid:
		intrinsics.unaligned_store((^typeid)(want), abi_typeids[x % len(abi_typeids)])
	}
	if have != nil && !abi_same(want, have, size) {
		abi_fail(what, arg, part^)
	}
	part^ += 1
}

abi_same :: proc "contextless" (a, b: rawptr, n: int) -> bool {
	x, y := ([^]u8)(a), ([^]u8)(b)
	for i in 0..<n {
		if x[i] != y[i] {
			return false
		}
	}
	return true
}

// Writes the value made from the seed `s` into `want`, one leaf at a time.
// With `have`, each leaf is also compared with the same leaf of `have`, which skips the padding.
// It is not inlined: specializing it for every type only costs compile time.
abi_walk :: #force_no_inline proc "contextless" (want, have: rawptr, type: ^runtime.Type_Info, s: u64, part: ^int, what: string, arg: int) {
	info := runtime.type_info_base(type)
	#partial switch v in info.variant {
	case ^runtime.Type_Info_Integer, ^runtime.Type_Info_Rune, ^runtime.Type_Info_Enum, ^runtime.Type_Info_Bit_Set, ^runtime.Type_Info_Bit_Field, ^runtime.Type_Info_Pointer, ^runtime.Type_Info_Multi_Pointer, ^runtime.Type_Info_Procedure:
		abi_leaf(want, have, .Int, info.size, s, part, what, arg)
	case ^runtime.Type_Info_Float:
		abi_leaf(want, have, .Float, info.size, s, part, what, arg)
	case ^runtime.Type_Info_Complex:
		for i in 0..<2 {
			abi_leaf(abi_at(want, i*info.size/2), abi_at(have, i*info.size/2), .Float, info.size/2, s, part, what, arg)
		}
	case ^runtime.Type_Info_Quaternion:
		for i in 0..<4 {
			abi_leaf(abi_at(want, i*info.size/4), abi_at(have, i*info.size/4), .Float, info.size/4, s, part, what, arg)
		}
	case ^runtime.Type_Info_Boolean:
		abi_leaf(want, have, .Bool, info.size, s, part, what, arg)
	case ^runtime.Type_Info_String:
		abi_leaf(want, have, .Cstring if v.is_cstring else .String, info.size, s, part, what, arg)
	case ^runtime.Type_Info_Slice:
		abi_leaf(want, have, .Slice, info.size, s, part, what, arg)
	case ^runtime.Type_Info_Any:
		abi_leaf(want, have, .Any, info.size, s, part, what, arg)
	case ^runtime.Type_Info_Type_Id:
		abi_leaf(want, have, .Typeid, info.size, s, part, what, arg)
	case ^runtime.Type_Info_Array:
		for i in 0..<v.count {
			abi_walk(abi_at(want, i*v.elem_size), abi_at(have, i*v.elem_size), v.elem, s, part, what, arg)
		}
	case ^runtime.Type_Info_Simd_Vector:
		for i in 0..<v.count {
			abi_walk(abi_at(want, i*v.elem_size), abi_at(have, i*v.elem_size), v.elem, s, part, what, arg)
		}
	case ^runtime.Type_Info_Matrix:
		majors, minors := v.column_count, v.row_count
		if v.layout == .Row_Major {
			majors, minors = minors, majors
		}
		for major in 0..<majors {
			for minor in 0..<minors {
				offset := (major*v.elem_stride + minor)*v.elem_size
				abi_walk(abi_at(want, offset), abi_at(have, offset), v.elem, s, part, what, arg)
			}
		}
	case ^runtime.Type_Info_Struct:
		count := int(v.field_count)
		if .raw_union in v.flags {
			// NOTE(bill): Only the first member is set and compared.
			count = min(count, 1)
		}
		for i in 0..<count {
			offset := int(v.offsets[i])
			abi_walk(abi_at(want, offset), abi_at(have, offset), v.types[i], s, part, what, arg)
		}
	case ^runtime.Type_Info_Union:
		// NOTE(bill): The tag is a leaf of its own.
		// Only the chosen variant's leaves follow it.
		nil_choices := 0 if v.no_nil else 1
		choice := int(abi_mix(s, u64(part^)) % u64(len(v.variants) + nil_choices))
		tag := abi_at(want, int(v.tag_offset))
		abi_put_int(tag, v.tag_type.size, u64(choice))
		if have != nil && !abi_same(tag, abi_at(have, int(v.tag_offset)), v.tag_type.size) {
			abi_fail(what, arg, part^)
		}
		part^ += 1
		if choice >= nil_choices {
			abi_walk(want, have, v.variants[choice - nil_choices], s, part, what, arg)
		}
	case:
		abi_fail("a type abi_walk does not handle", arg, part^)
	}
}

abi_fill :: #force_no_inline proc "contextless" (p: ^$T, s: u64) {
	part := 0
	abi_walk(p, nil, type_info_of(T), s, &part, "", 0)
}

abi_check :: #force_no_inline proc "contextless" (p: ^$T, s: u64, what: string, arg: int) {
	want: T
	part := 0
	abi_walk(&want, p, type_info_of(T), s, &part, what, arg)
}

abi_single :: #force_no_inline proc(a: $T) -> T {
	abi_context("single")
	a := a
	abi_check(&a, ABI_A, "single", 0)
	r: T
	abi_fill(&r, ABI_SINGLE)
	return r
}

@(optimization_mode="none")
abi_single_none :: proc(a: $T) -> T {
	abi_context("single_none")
	a := a
	abi_check(&a, ABI_A, "single_none", 0)
	r: T
	abi_fill(&r, ABI_SINGLE)
	return r
}

// Returns its parameter
abi_echo :: #force_no_inline proc(a: $T) -> T {
	abi_context("echo")
	b := a
	abi_check(&b, ABI_A, "echo", 0)
	return a
}

// Passes its parameter on
abi_forward :: #force_no_inline proc(a: $T) -> T {
	abi_context("forward")
	return abi_echo(a)
}

abi_mixed :: #force_no_inline proc(x: u8, a: $T, y: f64, b: T, z: i32) -> (T, u8) {
	abi_context("mixed")
	if x != 0xA5 || y != 1.5 || z != -7 {
		abi_fail("mixed", 0, 0)
	}
	a, b := a, b
	abi_check(&a, ABI_A, "mixed", 1)
	abi_check(&b, ABI_B, "mixed", 3)
	r: T
	abi_fill(&r, ABI_MIXED)
	return r, x ~ 0xFF
}

@(optimization_mode="none")
abi_mixed_none :: proc(x: u8, a: $T, y: f64, b: T, z: i32) -> (T, u8) {
	abi_context("mixed_none")
	if x != 0xA5 || y != 1.5 || z != -7 {
		abi_fail("mixed_none", 0, 0)
	}
	a, b := a, b
	abi_check(&a, ABI_A, "mixed_none", 1)
	abi_check(&b, ABI_B, "mixed_none", 3)
	r: T
	abi_fill(&r, ABI_MIXED)
	return r, x ~ 0xFF
}

// More arguments than there are argument registers
abi_many :: #force_no_inline proc(a0: $T, a1, a2, a3, a4, a5, a6, a7, a8, a9: T) -> T {
	abi_context("many")
	args := [10]T{a0, a1, a2, a3, a4, a5, a6, a7, a8, a9}
	for &arg, i in args {
		abi_check(&arg, ABI_MANY + u64(i), "many", i)
	}
	r: T
	abi_fill(&r, ABI_MANY_RESULT)
	return r
}

abi_results :: #force_no_inline proc(a: $T, n: int) -> (r0: T, r1: f64, r2: T, r3: bool) {
	abi_context("results")
	a := a
	abi_check(&a, ABI_A, "results", 0)
	if n != 12345 {
		abi_fail("results", 1, 0)
	}
	abi_fill(&r0, ABI_RESULT_0)
	r1 = -2.25
	abi_fill(&r2, ABI_RESULT_2)
	r3 = true
	return
}

@(optimization_mode="none")
abi_results_none :: proc(a: $T, n: int) -> (r0: T, r1: f64, r2: T, r3: bool) {
	abi_context("results_none")
	a := a
	abi_check(&a, ABI_A, "results_none", 0)
	if n != 12345 {
		abi_fail("results_none", 1, 0)
	}
	abi_fill(&r0, ABI_RESULT_0)
	r1 = -2.25
	abi_fill(&r2, ABI_RESULT_2)
	r3 = true
	return
}

abi_opt :: #force_no_inline proc(a: $T) -> (T, bool) #optional_ok {
	abi_context("opt")
	a := a
	abi_check(&a, ABI_A, "opt", 0)
	r: T
	abi_fill(&r, ABI_OPT)
	return r, true
}

abi_contextless :: #force_no_inline proc "contextless" (n: int, a: $T) -> T {
	if n != 777 {
		abi_fail("contextless", 0, 0)
	}
	a := a
	abi_check(&a, ABI_A, "contextless", 1)
	r: T
	abi_fill(&r, ABI_CONTEXTLESS)
	return r
}

abi_variadic :: #force_no_inline proc(n: int, args: ..$T) -> T {
	abi_context("variadic")
	r: T
	if n != 3 || len(args) != 3 {
		abi_fail("variadic", 0, 0)
		return r
	}
	abi_check(&args[0], ABI_A, "variadic", 1)
	abi_check(&args[1], ABI_B, "variadic", 2)
	abi_check(&args[2], ABI_A, "variadic", 3)
	abi_fill(&r, ABI_B)
	return r
}

// The procedure values of one type's instances.
// Calls through them are made after a volatile load, which keeps them indirect.
// Taking the values also keeps the optimizer from changing the instances' signatures.
// It may do that to a procedure whose every call it sees.
// A procedure type cannot be `#optional_ok`, which leaves `abi_opt` out.
Abi_Procs :: struct($T: typeid) {
	single:      proc(a: T) -> T,
	single_none: proc(a: T) -> T,
	echo:        proc(a: T) -> T,
	forward:     proc(a: T) -> T,
	mixed:       proc(x: u8, a: T, y: f64, b: T, z: i32) -> (T, u8),
	mixed_none:  proc(x: u8, a: T, y: f64, b: T, z: i32) -> (T, u8),
	many:        proc(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9: T) -> T,
	results:     proc(a: T, n: int) -> (T, f64, T, bool),
	contextless: proc "contextless" (n: int, a: T) -> T,
	variadic:    proc(n: int, args: ..T) -> T,
}

abi_procs :: proc($T: typeid) -> Abi_Procs(T) {
	return {
		single      = abi_single,
		single_none = abi_single_none,
		echo        = abi_echo,
		forward     = abi_forward,
		mixed       = abi_mixed,
		mixed_none  = abi_mixed_none,
		many        = abi_many,
		results     = abi_results,
		contextless = abi_contextless,
		variadic    = abi_variadic,
	}
}

abi_run :: proc($T: typeid) {
	context.user_index = ABI_MARK
	k := intrinsics.volatile_load(&abi_scalars)
	p := abi_procs(T)
	a, b: T
	abi_fill(&a, ABI_A)
	abi_fill(&b, ABI_B)
	many: [10]T
	for &v, i in many {
		abi_fill(&v, ABI_MANY + u64(i))
	}

	r1 := abi_single(a)
	abi_check(&r1, ABI_SINGLE, "single, declared", 100)
	r2: T
	r2 = abi_single(a)
	abi_check(&r2, ABI_SINGLE, "single, assigned", 100)
	r3: [3]T
	r3[1] = abi_single(a)
	abi_check(&r3[1], ABI_SINGLE, "single, into an element", 100)
	zero: T
	if !abi_same(&r3[0], &zero, size_of(T)) || !abi_same(&r3[2], &zero, size_of(T)) {
		abi_fail("single, next to the element", 100, -1)
	}
	r4 := abi_single_none(a)
	abi_check(&r4, ABI_SINGLE, "single_none", 100)
	r5 := abi_echo(abi_echo(a))
	abi_check(&r5, ABI_A, "echo, nested", 100)
	r6 := abi_forward(a)
	abi_check(&r6, ABI_A, "forward", 100)

	m1, x1 := abi_mixed(k.x, a, k.y, b, k.z)
	abi_check(&m1, ABI_MIXED, "mixed, declared", 100)
	m2: T
	x2: u8
	m2, x2 = abi_mixed(k.x, a, k.y, b, k.z)
	abi_check(&m2, ABI_MIXED, "mixed, assigned", 100)
	m3, _ := abi_mixed(k.x, a, k.y, b, k.z)
	abi_check(&m3, ABI_MIXED, "mixed, first result only", 100)
	_, x4 := abi_mixed(k.x, a, k.y, b, k.z)
	m5, x5 := abi_mixed_none(k.x, a, k.y, b, k.z)
	abi_check(&m5, ABI_MIXED, "mixed_none", 100)
	if x1 != 0x5A || x2 != 0x5A || x4 != 0x5A || x5 != 0x5A {
		abi_fail("mixed", 101, 0)
	}

	n1 := abi_many(many[0], many[1], many[2], many[3], many[4], many[5], many[6], many[7], many[8], many[9])
	abi_check(&n1, ABI_MANY_RESULT, "many", 100)

	q0, q1, q2, q3 := abi_results(a, k.n)
	abi_check(&q0, ABI_RESULT_0, "results", 100)
	abi_check(&q2, ABI_RESULT_2, "results", 102)
	s0, s1, s2, s3 := abi_results_none(a, k.n)
	abi_check(&s0, ABI_RESULT_0, "results_none", 100)
	abi_check(&s2, ABI_RESULT_2, "results_none", 102)
	if q1 != -2.25 || !q3 || s1 != -2.25 || !s3 {
		abi_fail("results", 101, 0)
	}

	o1 := abi_opt(a)
	abi_check(&o1, ABI_OPT, "opt, one value", 100)
	o2, ok := abi_opt(a)
	abi_check(&o2, ABI_OPT, "opt, two values", 100)
	if !ok {
		abi_fail("opt, two values", 101, 0)
	}

	c1 := abi_contextless(k.c, a)
	abi_check(&c1, ABI_CONTEXTLESS, "contextless", 100)

	v1 := abi_variadic(3, a, b, a)
	abi_check(&v1, ABI_B, "variadic", 100)

	i1 := intrinsics.volatile_load(&p.single)(a)
	abi_check(&i1, ABI_SINGLE, "single, through a procedure value", 100)
	i2 := intrinsics.volatile_load(&p.single_none)(a)
	abi_check(&i2, ABI_SINGLE, "single_none, through a procedure value", 100)
	i3 := intrinsics.volatile_load(&p.echo)(a)
	abi_check(&i3, ABI_A, "echo, through a procedure value", 100)
	i4 := intrinsics.volatile_load(&p.forward)(a)
	abi_check(&i4, ABI_A, "forward, through a procedure value", 100)
	i5, x6 := intrinsics.volatile_load(&p.mixed)(k.x, a, k.y, b, k.z)
	abi_check(&i5, ABI_MIXED, "mixed, through a procedure value", 100)
	i6, x7 := intrinsics.volatile_load(&p.mixed_none)(k.x, a, k.y, b, k.z)
	abi_check(&i6, ABI_MIXED, "mixed_none, through a procedure value", 100)
	if x6 != 0x5A || x7 != 0x5A {
		abi_fail("mixed, through a procedure value", 101, 0)
	}
	i7 := intrinsics.volatile_load(&p.many)(many[0], many[1], many[2], many[3], many[4], many[5], many[6], many[7], many[8], many[9])
	abi_check(&i7, ABI_MANY_RESULT, "many, through a procedure value", 100)
	j0, j1, j2, j3 := intrinsics.volatile_load(&p.results)(a, k.n)
	abi_check(&j0, ABI_RESULT_0, "results, through a procedure value", 100)
	abi_check(&j2, ABI_RESULT_2, "results, through a procedure value", 102)
	if j1 != -2.25 || !j3 {
		abi_fail("results, through a procedure value", 101, 0)
	}
	i9 := intrinsics.volatile_load(&p.contextless)(k.c, a)
	abi_check(&i9, ABI_CONTEXTLESS, "contextless, through a procedure value", 100)
	i10 := intrinsics.volatile_load(&p.variadic)(3, a, b, a)
	abi_check(&i10, ABI_B, "variadic, through a procedure value", 100)

	if context.user_index != ABI_MARK {
		abi_fail("abi_run", -1, 0)
	}
}

// Some of the same calls, from a caller built without optimization
@(optimization_mode="none")
abi_run_none :: proc($T: typeid) {
	context.user_index = ABI_MARK
	k := intrinsics.volatile_load(&abi_scalars)
	p := abi_procs(T)
	a, b: T
	abi_fill(&a, ABI_A)
	abi_fill(&b, ABI_B)
	many: [10]T
	for &v, i in many {
		abi_fill(&v, ABI_MANY + u64(i))
	}

	r1 := abi_single(a)
	abi_check(&r1, ABI_SINGLE, "single, from optimization_mode none", 100)
	r2 := abi_single_none(a)
	abi_check(&r2, ABI_SINGLE, "single_none, from optimization_mode none", 100)
	r3 := abi_echo(abi_echo(a))
	abi_check(&r3, ABI_A, "echo, nested, from optimization_mode none", 100)
	m1, x1 := abi_mixed(k.x, a, k.y, b, k.z)
	abi_check(&m1, ABI_MIXED, "mixed, from optimization_mode none", 100)
	m2, x2 := abi_mixed_none(k.x, a, k.y, b, k.z)
	abi_check(&m2, ABI_MIXED, "mixed_none, from optimization_mode none", 100)
	if x1 != 0x5A || x2 != 0x5A {
		abi_fail("mixed, from optimization_mode none", 101, 0)
	}
	n1 := abi_many(many[0], many[1], many[2], many[3], many[4], many[5], many[6], many[7], many[8], many[9])
	abi_check(&n1, ABI_MANY_RESULT, "many, from optimization_mode none", 100)
	q0, q1, q2, q3 := abi_results(a, k.n)
	abi_check(&q0, ABI_RESULT_0, "results, from optimization_mode none", 100)
	abi_check(&q2, ABI_RESULT_2, "results, from optimization_mode none", 102)
	if q1 != -2.25 || !q3 {
		abi_fail("results, from optimization_mode none", 101, 0)
	}
	o1, ok := abi_opt(a)
	abi_check(&o1, ABI_OPT, "opt, from optimization_mode none", 100)
	if !ok {
		abi_fail("opt, from optimization_mode none", 101, 0)
	}
	c1 := abi_contextless(k.c, a)
	abi_check(&c1, ABI_CONTEXTLESS, "contextless, from optimization_mode none", 100)
	i1 := intrinsics.volatile_load(&p.single)(a)
	abi_check(&i1, ABI_SINGLE, "single, through a procedure value, from optimization_mode none", 100)
	i2, x3 := intrinsics.volatile_load(&p.mixed)(k.x, a, k.y, b, k.z)
	abi_check(&i2, ABI_MIXED, "mixed, through a procedure value, from optimization_mode none", 100)
	if x3 != 0x5A {
		abi_fail("mixed, through a procedure value, from optimization_mode none", 101, 0)
	}
	j0, j1, j2, j3 := intrinsics.volatile_load(&p.results)(a, k.n)
	abi_check(&j0, ABI_RESULT_0, "results, through a procedure value, from optimization_mode none", 100)
	abi_check(&j2, ABI_RESULT_2, "results, through a procedure value, from optimization_mode none", 102)
	if j1 != -2.25 || !j3 {
		abi_fail("results, through a procedure value, from optimization_mode none", 101, 0)
	}

	if context.user_index != ABI_MARK {
		abi_fail("abi_run_none", -1, 0)
	}
}

abi_test :: proc(t: ^testing.T, $T: typeid, loc := #caller_location) {
	abi_run(T)
	f := abi_failure
	abi_failure = {}
	testing.expectf(t, f.count == 0, "%v: %d mismatches, the first in %s, argument %d, part %d", typeid_of(T), f.count, f.what, f.arg, f.part, loc = loc)

	abi_run_none(T)
	f = abi_failure
	abi_failure = {}
	testing.expectf(t, f.count == 0, "%v: %d mismatches, the first in %s, argument %d, part %d", typeid_of(T), f.count, f.what, f.arg, f.part, loc = loc)
}

Abi_Enum :: enum u8 {A, B, C, D}

Abi_Union :: union {i32, f64, string}

Abi_Bits :: bit_field u32 {
	a: u8  | 3,
	b: u16 | 9,
	c: i32 | 20,
}

Abi_Proc :: #type proc "contextless" (x: int) -> int

Abi_u8x1        :: struct {a: u8}
Abi_u8x3        :: struct {a, b, c: u8}
Abi_u8_u32      :: struct {a: u8, b: u32}
Abi_u8_u64      :: struct {a: u8, b: u64}
Abi_u16x3       :: struct {a, b, c: u16}
Abi_u32x3       :: struct {a, b, c: u32}
Abi_u32x4       :: struct {a, b, c, d: u32}
Abi_u64x2       :: struct {a, b: u64}
Abi_ptr_int     :: struct {p: rawptr, n: int}
Abi_u64x3       :: struct {a, b, c: u64}
Abi_u64x4       :: struct {a, b, c, d: u64}
Abi_u64x8       :: struct {a: [8]u64}
Abi_f32x2       :: struct {a, b: f32}
Abi_f32x3       :: struct {a, b, c: f32}
Abi_f32x4       :: struct {a, b, c, d: f32}
Abi_f32x5       :: struct {a: [5]f32}
Abi_f32x8       :: struct {a: [8]f32}
Abi_f32x16      :: struct {a: [16]f32}
Abi_f64x2       :: struct {a, b: f64}
Abi_f64x3       :: struct {a, b, c: f64}
Abi_f64x4       :: struct {a, b, c, d: f64}
Abi_f64x5       :: struct {a: [5]f64}
Abi_f64x8       :: struct {a: [8]f64}
Abi_f32_i32     :: struct {a: f32, b: i32}
Abi_i32_f32     :: struct {a: i32, b: f32}
Abi_f32_f64     :: struct {a: f32, b: f64}
Abi_f64_f32     :: struct {a: f64, b: f32}
Abi_f64_i64     :: struct {a: f64, b: i64}
Abi_i64_f64     :: struct {a: i64, b: f64}
Abi_f32_u8_f32  :: struct {a: f32, b: u8, c: f32}
Abi_u8_f64_u16  :: struct {a: u8, b: f64, c: u16}
Abi_f32_i64_f32 :: struct {a: f32, b: i64, c: f32}
Abi_i64_f64_i64 :: struct {a: i64, b: f64, c: i64}
Abi_f64_f64_i64 :: struct {a, b: f64, c: i64}
Abi_i64x2_f64x2 :: struct {a, b: i64, c, d: f64}
Abi_f64x3_u8    :: struct {a, b, c: f64, d: u8}
Abi_f16x4       :: struct {a, b, c, d: f16}
Abi_f16_f32     :: struct {a: f16, b: f32}
Abi_bool_f32    :: struct {a: bool, b: f32}
Abi_enum_f32    :: struct {e: Abi_Enum, x: f32}
Abi_i128_u8     :: struct {a: i128, b: u8}
Abi_ptr3        :: struct {a, b, c: rawptr}
Abi_string_int  :: struct {s: string, n: int}
Abi_slice_f64   :: struct {s: []u32, f: f64}
Abi_any_int     :: struct {a: any, n: int}
Abi_nested      :: struct {a: Abi_f32x2, b: f64}
Abi_nested_arr  :: struct {a: [2]f32, b: [2]i32}
Abi_packed_u32  :: struct #packed {a: u8, b: u32}
Abi_packed_f64  :: struct #packed {a: u8, b: f64}
Abi_align16     :: struct #align(16) {a: u8}
Abi_align32     :: struct #align(32) {a: f32}
Abi_raw_union   :: struct #raw_union {a: f64, b: i64}
Abi_empty       :: struct {}

@(test)
test_abi_scalars :: proc(t: ^testing.T) {
	abi_test(t, u8)
	abi_test(t, i16)
	abi_test(t, u32)
	abi_test(t, i64)
	abi_test(t, int)
	abi_test(t, i128)
	abi_test(t, u128)
	abi_test(t, f16)
	abi_test(t, f32)
	abi_test(t, f64)
	abi_test(t, bool)
	abi_test(t, rawptr)
	abi_test(t, Abi_Enum)
	abi_test(t, string)
	abi_test(t, cstring)
	abi_test(t, []u32)
	abi_test(t, any)
	abi_test(t, typeid)
	abi_test(t, Abi_Proc)
	abi_test(t, Maybe(int))
	abi_test(t, Abi_Union)
	abi_test(t, bit_set[0..<64])
	abi_test(t, Abi_Bits)
	abi_test(t, complex64)
	abi_test(t, complex128)
	abi_test(t, quaternion128)
	abi_test(t, quaternion256)
}

@(test)
test_abi_arrays :: proc(t: ^testing.T) {
	abi_test(t, [2]int)
	abi_test(t, [3]int)
	abi_test(t, [2]f64)
	abi_test(t, [3]f32)
	abi_test(t, [4]f32)
	abi_test(t, [5]f32)
	abi_test(t, [8]f64)
	abi_test(t, [16]f32)
	abi_test(t, [7]u8)
	abi_test(t, [16]u8)
	abi_test(t, [3]u16)
	abi_test(t, [2]u128)
	abi_test(t, matrix[2, 2]f32)
	abi_test(t, matrix[2, 3]f32)
	abi_test(t, matrix[3, 3]f32)
	abi_test(t, matrix[4, 4]f32)
	abi_test(t, matrix[2, 2]f64)
	abi_test(t, matrix[4, 4]f64)
}

@(test)
test_abi_simd :: proc(t: ^testing.T) {
	abi_test(t, #simd[2]f32)
	abi_test(t, #simd[4]f32)
	abi_test(t, #simd[2]f64)
	abi_test(t, #simd[4]i32)
	abi_test(t, #simd[16]u8)
	abi_test(t, #simd[2]i64)
	abi_test(t, #simd[8]f32)
	abi_test(t, #simd[4]f64)
	abi_test(t, #simd[8]i32)
	abi_test(t, #simd[32]u8)
	abi_test(t, #simd[16]f32)
	abi_test(t, #simd[8]f64)
}

@(test)
test_abi_records :: proc(t: ^testing.T) {
	abi_test(t, Abi_u8x1)
	abi_test(t, Abi_u8x3)
	abi_test(t, Abi_u8_u32)
	abi_test(t, Abi_u8_u64)
	abi_test(t, Abi_u16x3)
	abi_test(t, Abi_u32x3)
	abi_test(t, Abi_u32x4)
	abi_test(t, Abi_u64x2)
	abi_test(t, Abi_ptr_int)
	abi_test(t, Abi_u64x3)
	abi_test(t, Abi_u64x4)
	abi_test(t, Abi_u64x8)
	abi_test(t, Abi_f32x2)
	abi_test(t, Abi_f32x3)
	abi_test(t, Abi_f32x4)
	abi_test(t, Abi_f32x5)
	abi_test(t, Abi_f32x8)
	abi_test(t, Abi_f32x16)
	abi_test(t, Abi_f64x2)
	abi_test(t, Abi_f64x3)
	abi_test(t, Abi_f64x4)
	abi_test(t, Abi_f64x5)
	abi_test(t, Abi_f64x8)
	abi_test(t, Abi_f32_i32)
	abi_test(t, Abi_i32_f32)
	abi_test(t, Abi_f32_f64)
	abi_test(t, Abi_f64_f32)
	abi_test(t, Abi_f64_i64)
	abi_test(t, Abi_i64_f64)
	abi_test(t, Abi_f32_u8_f32)
	abi_test(t, Abi_u8_f64_u16)
	abi_test(t, Abi_f32_i64_f32)
	abi_test(t, Abi_i64_f64_i64)
	abi_test(t, Abi_f64_f64_i64)
	abi_test(t, Abi_i64x2_f64x2)
	abi_test(t, Abi_f64x3_u8)
	abi_test(t, Abi_f16x4)
	abi_test(t, Abi_f16_f32)
	abi_test(t, Abi_bool_f32)
	abi_test(t, Abi_enum_f32)
	abi_test(t, Abi_i128_u8)
	abi_test(t, Abi_ptr3)
	abi_test(t, Abi_string_int)
	abi_test(t, Abi_slice_f64)
	abi_test(t, Abi_any_int)
	abi_test(t, Abi_nested)
	abi_test(t, Abi_nested_arr)
	abi_test(t, Abi_packed_u32)
	abi_test(t, Abi_packed_f64)
	abi_test(t, Abi_align16)
	abi_test(t, Abi_align32)
	abi_test(t, Abi_raw_union)
	abi_test(t, Abi_empty)
}
