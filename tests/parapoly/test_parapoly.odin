package test_parapoly

// Regression tests for the parametric-polymorphism substitution engine. Each exercises a case that was
// fixed or newly supported; several are run *through codegen* (not just type-checked) because the bugs
// they guard against (e.g. a map's uninitialized internal types, a dropped #sparse flag) were invisible
// to type-checking and only surfaced at code generation / runtime.
//
// This package is intentionally NOT part of the CI test set (tests/internal, tests/core, ...); run it
// directly with:  odin test tests/parapoly

import "core:testing"
import "core:reflect"

// --- helpers (package-level: polymorphic procs/types must be top-level) -----------------------------

PP_Dir :: enum { N, E, S, W }
PP_E   :: enum { A = 1, B = 3, C = 7 } // non-contiguous -> requires #sparse

PP_Stack :: struct($T: typeid) { data: [dynamic]T }
PP_Base  :: struct($T: typeid) { x: T }
PP_Bar   :: struct($X: typeid) { v: X }
PP_Foo   :: struct($T: typeid) { item: T }
PP_DArr  :: distinct [dynamic]int

pp_map_use :: proc(m: ^map[$K]$V, k: K, v: V) -> (V, bool, int) {
	m[k] = v
	r, ok := m[k]
	return r, ok, len(m^)
}
pp_sparse :: proc(a: #sparse[PP_E]$T) -> (T, bool) {
	info := type_info_of(type_of(a))
	ea := info.variant.(reflect.Type_Info_Enumerated_Array)
	return a[.C], ea.is_sparse
}
pp_union_first :: proc(u: union{$T, int}) -> T { v, _ := u.(T); return v }
pp_union_pair  :: proc(u: union{$A, $B}) -> (typeid, typeid) { return A, B }
pp_struct_sum  :: proc(s: struct{x: $T, y: T}) -> T { return s.x + s.y }
pp_struct_grid :: proc(s: struct{cell: $T, row: [3]T, tbl: [2][2]T}) -> typeid { return T }
pp_bitfield    :: proc(b: bit_field $T { a: u8 | 3, c: u8 | 5 }) -> u8 { return b.a + b.c }
pp_grab        :: proc(a: [$N]$T) -> T { for v in a { return v }; z: T; return z }
pp_ptr         :: proc(p: ^$T)  -> typeid { return T }
pp_mp          :: proc(p: [^]$T) -> typeid { return T }
pp_cg_proc     :: proc(f: $P/proc(_: $A) -> $R) -> (typeid, typeid) { return A, R }
pp_cg_stack    :: proc(s: $T/PP_Stack($U)) -> typeid { return U }
pp_cg_bare     :: proc(s: $T/PP_Stack) -> int { return len(s.data) }
pp_cg_record   :: proc(f: PP_Foo($T/PP_Bar($U))) -> typeid { return U }
pp_cg_distinct :: proc(a: $T/[dynamic]$E) -> typeid { return E }
pp_using       :: proc(s: struct{ using b: $P/PP_Base($T), z: int }) -> T { return s.x }
pp_ho          :: proc(a: int) -> bool { return a > 0 }

// --- tests ------------------------------------------------------------------------------------------

@test
parapoly_poly_map :: proc(t: ^testing.T) { // guards the map codegen crash (init_map_internal_types)
	m := make(map[string]int); defer delete(m)
	r, ok, n := pp_map_use(&m, "a", 7)
	testing.expect(t, r == 7 && ok && n == 1, "poly map insert/lookup/len")
	m["b"] = 3
	total := 0
	for _, v in m { total += v }
	testing.expect(t, total == 10, "poly map for-range")
}

@test
parapoly_sparse_enum_array :: proc(t: ^testing.T) { // guards the dropped is_sparse
	x: #sparse[PP_E]int
	x[.C] = 42
	v, is_sparse := pp_sparse(x)
	testing.expect(t, v == 42, "sparse enum array indexing")
	testing.expect(t, is_sparse, "resolved #sparse array keeps is_sparse")
}

@test
parapoly_anon_union :: proc(t: ^testing.T) {
	u: union{f32, int} = f32(2.5)
	testing.expect(t, pp_union_first(u) == 2.5, "anon union $T inference + variant extract")
	a, b := pp_union_pair(u)
	testing.expect(t, a == f32 && b == int, "two-var anon union")
}

@test
parapoly_anon_struct :: proc(t: ^testing.T) {
	testing.expect(t, pp_struct_sum(struct{x: int, y: int}{3, 4}) == 7, "anon struct field poly + use")
	g: struct{cell: u8, row: [3]u8, tbl: [2][2]u8}
	testing.expect(t, pp_struct_grid(g) == u8, "anon struct reused var across nested compound")
}

@test
parapoly_bit_field_backing :: proc(t: ^testing.T) {
	x: bit_field u16 { a: u8 | 3, c: u8 | 5 }
	x.a = 5; x.c = 9
	testing.expect(t, pp_bitfield(x) == 14, "poly bit_field backing + field access")
}

@test
parapoly_array_enum_ambiguity :: proc(t: ^testing.T) { // the [$N]$T fixed-vs-enumerated ambiguity
	testing.expect(t, pp_grab([3]int{10, 20, 30}) == 10, "[$N]$T fixed array")
	ea: [PP_Dir]int
	ea[.N] = 7
	testing.expect(t, pp_grab(ea) == 7, "[$N]$T enumerated array")
}

@test
parapoly_ptr_multipointer :: proc(t: ^testing.T) {
	x: int
	arr: [4]int
	m: [^]int = &arr[0]
	testing.expect(t, pp_ptr(&x) == int, "^$T <- ^int")
	testing.expect(t, pp_ptr(m)  == int, "^$T <- [^]int (cross-kind)")
	testing.expect(t, pp_mp(m)   == int, "[^]$T <- [^]int")
	testing.expect(t, pp_mp(&x)  == int, "[^]$T <- ^int (cross-kind)")
}

@test
parapoly_constrained_generics :: proc(t: ^testing.T) {
	a, r := pp_cg_proc(pp_ho)
	testing.expect(t, a == int && r == bool, "$P/proc($A)->$R")
	s: PP_Stack(f32)
	testing.expect(t, pp_cg_stack(s) == f32, "$T/PP_Stack($U)")
	s2: PP_Stack(u8)
	testing.expect(t, pp_cg_bare(s2) == 0, "$T/PP_Stack bare-template constraint")
	f: PP_Foo(PP_Bar(int))
	testing.expect(t, pp_cg_record(f) == int, "PP_Foo($T/PP_Bar($U)) record-param constraint")
	d: PP_DArr
	testing.expect(t, pp_cg_distinct(d) == int, "$T/[dynamic]$E through a distinct type")
}

@test
parapoly_using_constraint :: proc(t: ^testing.T) { // using on a constrained-generic field
	v: struct{ using b: PP_Base(int), z: int }
	v.x = 42
	testing.expect(t, pp_using(v) == 42, "using $P/PP_Base($T) + promoted-member access")
}

// --- deferred untyped-argument inference ------------------------------------------------------------
// An untyped argument (`{...}`, `.Member`, or a ternary whose branches are both untyped) passed to a
// polymorphic parameter whose type is only known after substitution is left unchecked and resolved
// from that parameter's type once it is determined from the other arguments. Covers single procedures,
// procedure groups (including the `append` builtin), variadics, named/reversed arguments, and the
// nested/ternary/implicit-selector forms. All run through codegen.

pp_def_push :: proc(a: ^[dynamic]$E, e: E)            { append(a, e) }
pp_def_two  :: proc(a: ^[dynamic]$E, x: E, y: E)      { append(a, x); append(a, y) }
pp_def_var  :: proc(a: ^[dynamic]$E, xs: ..E)         { for x in xs { append(a, x) } }
pp_def_one  :: proc(a: ^[dynamic]$E, e: E)   -> string { append(a, e); return "one" }
pp_def_many :: proc(a: ^[dynamic]$E, e: ..E) -> string { for x in e { append(a, x) }; return "many" }
pp_def_group :: proc{pp_def_one, pp_def_many}

@test
parapoly_deferred_single :: proc(t: ^testing.T) { // untyped `{...}` resolved from a poly parameter
	a: [dynamic][3]int; defer delete(a)
	pp_def_push(&a, {1, 2, 3})           // positional
	pp_def_push(a = &a, e = {4, 5, 6})   // named
	pp_def_push(e = {7, 8, 9}, a = &a)   // reversed: literal before the determining arg
	testing.expect(t, len(a) == 3, "single-proc deferred literal count")
	testing.expect(t, a[0] == [3]int{1, 2, 3} && a[2] == [3]int{7, 8, 9}, "single-proc deferred literal values")
}

@test
parapoly_deferred_multiple :: proc(t: ^testing.T) { // several untyped literals in one call
	a: [dynamic][2]int; defer delete(a)
	pp_def_two(&a, {1, 2}, {3, 4})           // two positional, shared elem type
	pp_def_var(&a, {5, 6}, {7, 8}, {9, 10})  // variadic, three literals
	testing.expect(t, len(a) == 5, "multiple deferred literals count")
	testing.expect(t, a[1] == [2]int{3, 4} && a[4] == [2]int{9, 10}, "multiple deferred literals values")
}

@test
parapoly_deferred_ternary :: proc(t: ^testing.T) { // both-branch-untyped ternaries as the deferred arg
	a: [dynamic][2]int; defer delete(a)
	c := true
	pp_def_push(&a, c ? {1, 2} : {3, 4})                 // ?:
	pp_def_push(&a, {5, 6} if !c else {7, 8})            // if/else
	pp_def_push(&a, {9, 9} when ODIN_DEBUG else {8, 8})  // when (a[2], value depends on build)
	pp_def_push(&a, c ? {1, 1} : (c ? {2, 2} : {3, 3}))  // nested
	testing.expect(t, a[0] == [2]int{1, 2}, "ternary ?: deferred arg")
	testing.expect(t, a[1] == [2]int{7, 8}, "ternary if/else deferred arg")
	testing.expect(t, a[3] == [2]int{1, 1}, "nested ternary deferred arg")
}

@test
parapoly_deferred_implicit_selector :: proc(t: ^testing.T) { // `.Member` resolved from a poly parameter
	a: [dynamic]PP_Dir; defer delete(a)
	c := false
	pp_def_push(&a, .E)           // implicit selector
	pp_def_push(&a, c ? .N : .W)  // ternary of selectors
	testing.expect(t, a[0] == .E && a[1] == .W, "implicit-selector deferred arg")
}

@test
parapoly_deferred_empty :: proc(t: ^testing.T) { // empty `{}` -> zero value of the resolved type
	a: [dynamic][3]int; defer delete(a)
	pp_def_push(&a, {})
	testing.expect(t, a[0] == [3]int{0, 0, 0}, "empty compound literal deferred arg")
}

@test
parapoly_deferred_append_group :: proc(t: ^testing.T) { // the `append` builtin (procedure group)
	a: [dynamic][3]int; defer delete(a)
	append(&a, {1, 2, 3})                   // positional -> append_elem
	append(&a, {4, 5, 6}, {7, 8, 9})        // variadic   -> append_elems
	append(array = &a, arg = {10, 11, 12})  // named
	testing.expect(t, len(a) == 4, "append group deferred literal count")
	testing.expect(t, a[0] == [3]int{1, 2, 3} && a[3] == [3]int{10, 11, 12}, "append group deferred literal values")
}

@test
parapoly_deferred_group_ranking :: proc(t: ^testing.T) { // variadic vs non-variadic overload ranking
	a: [dynamic][2]int; defer delete(a)
	r1 := pp_def_group(&a, {1, 2})          // one literal -> non-variadic wins (variadic score penalty)
	r2 := pp_def_group(&a, {3, 4}, {5, 6})  // two literals -> only the variadic overload fits the arity
	testing.expect(t, r1 == "one", "single deferred literal picks non-variadic overload")
	testing.expect(t, r2 == "many", "multiple deferred literals pick variadic overload")
}

@test
parapoly_deferred_or_else :: proc(t: ^testing.T) { // or_else default self-types from the left operand
	m := make(map[string][2]int); defer delete(m)
	m["p"] = {1, 2}
	a: [dynamic][2]int; defer delete(a)
	pp_def_push(&a, m["p"]      or_else {9, 9})  // present -> {1,2}
	pp_def_push(&a, m["absent"] or_else {7, 8})  // missing -> {7,8}
	testing.expect(t, a[0] == [2]int{1, 2} && a[1] == [2]int{7, 8}, "or_else default resolved")
}

pp_is_sparse :: proc(x: $T) -> bool {
	#partial switch v in type_info_of(T).variant {
	case reflect.Type_Info_Enumerated_Array: return v.is_sparse
	}
	return false
}

@test
parapoly_sparse_dense_dedup :: proc(t: ^testing.T) { // guards are_types_identical merging [E]T and #sparse[E]T
	dense:  [PP_Dir]int
	sparse: #sparse[PP_Dir]int
	testing.expect(t, pp_is_sparse(dense)  == false, "[E]T instantiation is not sparse")
	testing.expect(t, pp_is_sparse(sparse) == true,  "#sparse[E]T not merged with the dense instantiation")
}

pp_rec_arr  :: proc(x: PP_Bar([2]$T))       -> typeid { return T }
pp_rec_earr :: proc(x: PP_Bar([PP_Dir]$T))  -> typeid { return T }

@test
parapoly_record_compound_arg :: proc(t: ^testing.T) { // record whose polymorphic argument is a compound type
	v: PP_Bar([2]int)        // PP_Bar :: struct($X){ v: X }
	w: PP_Bar([PP_Dir]f32)
	testing.expect(t, pp_rec_arr(v)  == int, "Record([2]$T) determination (was a subst_apply crash)")
	testing.expect(t, pp_rec_earr(w) == f32, "Record([E]$T) determination")
}

PP_Vec :: struct($N: int, $name: string, $signed: bool) { data: [N]int } // non-type poly const params
pp_vec_name   :: proc(v: PP_Vec($N, $name, $signed)) -> string { return name }
pp_vec_n      :: proc(v: PP_Vec($N, $name, $signed)) -> int    { return N }
pp_vec_signed :: proc(v: PP_Vec($N, $name, $signed)) -> bool   { return signed }

@test
parapoly_record_nonint_const :: proc(t: ^testing.T) { // determine non-integer const params of a record arg
	v: PP_Vec(3, "hello", true)
	testing.expect(t, pp_vec_name(v)   == "hello", "string poly-const param determined from record arg")
	testing.expect(t, pp_vec_n(v)      == 3,       "int poly-const param determined alongside a string one")
	testing.expect(t, pp_vec_signed(v) == true,    "bool poly-const param determined from record arg")
}

// Tier-A: a bare compound literal determines a polymorphic ELEMENT type (`[K]$T`, `[]$T`), count fixed.
pp_elem_arr :: proc(a: [3]$T) -> typeid { return T }
pp_elem_sli :: proc(s: []$T)  -> typeid { return T }

@test
parapoly_elem_from_compound_lit :: proc(t: ^testing.T) {
	testing.expect(t, pp_elem_arr({1, 2, 3})  == int, "[3]$T element determined from literal")
	testing.expect(t, pp_elem_arr({-1, 2, 3}) == int, "[3]$T element from unary-over-literal")
	testing.expect(t, pp_elem_sli({1, 2, 3})  == int, "[]$T element determined from literal")
	testing.expect(t, pp_elem_sli({1.5, 2.5}) == f64, "[]$T element defaults untyped float to f64")
}

// A bare compound literal also determines a polymorphic COUNT (`[$N]$T`, `[$N]int`) from its length.
pp_cnt_both :: proc(a: [$N]$T) -> (int, typeid) { return N, T }
pp_cnt_int  :: proc(a: [$N]int) -> int { return N }

@test
parapoly_count_from_compound_lit :: proc(t: ^testing.T) {
	n1, e1 := pp_cnt_both({1, 2, 3})
	testing.expect(t, n1 == 3 && e1 == int, "[$N]$T binds N=3 and T=int from literal")
	n2, e2 := pp_cnt_both({1.5, 2.5})
	testing.expect(t, n2 == 2 && e2 == f64, "[$N]$T binds N=2 and T=f64 from literal")
	testing.expect(t, pp_cnt_int({10, 20, 30, 40}) == 4, "[$N]int binds N=4 (concrete element)")
	v := 7
	testing.expect(t, pp_cnt_int({v, v}) == 2, "[$N]int count works with non-literal elements")
}

// A constant default value for a polymorphic parameter, validated against the concrete type at instantiation.
pp_def :: proc(x: $T, y: T = 0) -> T { return y }

@test
parapoly_poly_param_default :: proc(t: ^testing.T) {
	testing.expect(t, pp_def(5)      == 0,   "untyped default resolves to the concrete param type")
	testing.expect(t, pp_def(5, 9)   == 9,   "explicit argument overrides the default")
	testing.expect(t, pp_def(2.5)    == 0.0, "same default against a different instantiation (f64)")
	testing.expect(t, pp_def(2.5, 3) == 3.0, "explicit float argument")
}
