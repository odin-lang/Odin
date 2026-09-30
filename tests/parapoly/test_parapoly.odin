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
