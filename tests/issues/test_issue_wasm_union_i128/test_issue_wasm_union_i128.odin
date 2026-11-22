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

	if failures > 0 {
		runtime.trap()
	}
}
