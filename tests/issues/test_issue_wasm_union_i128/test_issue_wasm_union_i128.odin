package test_issue_wasm_union_i128

import "base:runtime"
import "core:fmt"

E :: enum i32 {None, Bad}

Shared :: union #shared_nil {
	runtime.Allocator_Error,
	E,
}

Small :: struct {a, b, c: u8}

No_Nil :: union #no_nil {u16, Small}

Nested :: union {Shared, f64}

Wide :: struct {a: u8, b: i128}

Wide_Unsigned :: struct {a: u8, b: u128be}

Holder :: union {u64, Wide}

failures := 0

expect :: proc(ok: bool, what: string, loc := #caller_location) {
	if !ok {
		fmt.eprintfln("%v: %s", loc, what)
		failures += 1
	}
}

take_shared :: proc(e: Shared) -> bool {
	return e != nil
}

take_shared_c :: proc "c" (e: Shared) -> bool {
	return e != nil
}

take_no_nil :: proc(u: No_Nil) -> (Small, u16) {
	switch v in u {
	case Small: return v, 0
	case u16:   return {}, v
	}
	return {}, 0
}

take_nested :: proc(n: Nested) -> E {
	if s, ok := n.(Shared); ok {
		if e, ok2 := s.(E); ok2 {
			return e
		}
	}
	return .None
}

take_holder :: proc(h: Holder) -> i128 {
	if w, ok := h.(Wide); ok {
		return w.b
	}
	return 0
}

main :: proc() {
	expect(take_shared(Shared(runtime.Allocator_Error.Out_Of_Memory)), "Allocator_Error constant")
	expect(take_shared(E.Bad), "implicit enum constant")
	expect(!take_shared(nil), "nil")
	expect(take_shared_c(Shared(E.Bad)), "enum constant, \"c\" call")

	s, n := take_no_nil(No_Nil(Small{1, 2, 3}))
	expect(s == Small{1, 2, 3} && n == 0, "#no_nil struct constant")
	s, n = take_no_nil(No_Nil(u16(0xbeef)))
	expect(s == {} && n == 0xbeef, "#no_nil u16 constant")

	expect(take_nested(Nested(Shared(E.Bad))) == .Bad, "nested union constant")

	w := Wide{7, -5}
	expect((^i128)(uintptr(&w) + offset_of(Wide, b))^ == -5, "i128 field at offset_of")
	expect(fmt.tprint(w) == "Wide{a = 7, b = -5}", "i128 field through reflection")

	wu := Wide_Unsigned{9, 0xfedc_ba98_7654_3210_0123_4567_89ab_cdef}
	expect((^u128be)(uintptr(&wu) + offset_of(Wide_Unsigned, b))^ == wu.b, "u128be field at offset_of")

	expect(take_holder(Holder(Wide{7, -5})) == -5, "union constant holding i128")
	expect(take_holder(w) == -5, "union variable holding i128")

	if failures > 0 {
		runtime.trap()
	}
}
