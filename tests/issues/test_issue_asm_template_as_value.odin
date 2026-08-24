#+build amd64
// A named asm template got a plain `Addressing_Value`, so every value gate let it through:
// a cast, a transmute, an `auto_cast`, a blank assignment, a polymorphic parameter and a
// comparison against `nil` all passed the checker and then aborted the compiler in the
// backend, which has no value to lower for a template. Only a direct call and a listing in
// an `asm` group are legal.
package test_issues

t :: asm(a: i32) -> (v: i32) { mov v, a; }

a32 :: asm(a: i32) -> (v: i32) { mov v, a; }
a64 :: asm(a: i64) -> (v: i64) { mov v, a; }
g :: asm { a32, a64 }

G := cast(rawptr)(t)

take_rawptr :: proc(p: rawptr) {
	_ = p
}

poly :: proc(x: $T) {
	_ = size_of(T)
}

bad :: proc() {
	_ = cast(proc "c" (i32) -> i32)(t)
	_ = transmute(proc "c" (i32) -> i32)(t)
	_ = cast(rawptr)(t)
	_ = transmute(uintptr)(t)
	take_rawptr(auto_cast t)
	take_rawptr(cast(rawptr)(t))
	_ = t
	poly(t)
	if t == nil {
		take_rawptr(nil)
	}
}

// these forms must remain valid
good :: proc() -> i32 {
	x := t(1)
	y := (t)(2)
	z := g(i32(3))
	w := g(i64(4))
	v := asm(a: i32) -> (v: i32) { mov v, a; }(5)
	take_rawptr(G)
	return x + y + z + i32(w) + v
}
