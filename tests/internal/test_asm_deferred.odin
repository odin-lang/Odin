#+build amd64
package test_internal

import "core:testing"

// Like a procedure body, the specification block and body of an `asm` template are checked after its signature:
// once all of the procedure body it is within has been checked, otherwise with the procedure bodies.
// Some of these did not compile when the body was checked along with the signature, and the rest cover
// each of the places a body is now checked from.

// The body names a constant which needs the template's own signature, in either order
ASM_DEFERRED_K_BEFORE :: size_of(asm_deferred_k_before(0))
asm_deferred_k_before :: asm(a: u64) -> (r: u64) [a -> r] { add r, ASM_DEFERRED_K_BEFORE }

asm_deferred_k_after :: asm(a: u64) -> (r: u64) [a -> r] { add r, ASM_DEFERRED_K_AFTER }
ASM_DEFERRED_K_AFTER :: size_of(asm_deferred_k_after(0))

// An anonymous template outside of any procedure body
asm_deferred_global_var := asm(a: u64) -> (r: u64) [a -> r] { add r, ASM_DEFERRED_GLOBAL_K }(1)
ASM_DEFERRED_GLOBAL_K :: 6

// Names only from `test_asm_deferred_lazy.odin` and a type declared after it, in the specification block and body
asm_deferred_lazy_load :: asm(p: ^u32) -> (r: u32) [t: Asm_Deferred_Scratch] { mov t, [p]:Asm_Deferred_Lazy_U32; add t, ASM_DEFERRED_LAZY_K; mov r, t }
Asm_Deferred_Scratch :: distinct u32

ASM_DEFERRED_SHADOWED :: 1

@(test)
asm_deferred_global :: proc(t: ^testing.T) {
	testing.expect_value(t, ASM_DEFERRED_K_BEFORE, 8)
	testing.expect_value(t, ASM_DEFERRED_K_AFTER, 8)
	testing.expect_value(t, asm_deferred_k_before(1), u64(9))
	testing.expect_value(t, asm_deferred_k_after(1), u64(9))
	testing.expect_value(t, asm_deferred_global_var, u64(7))
}

@(test)
asm_deferred_local :: proc(t: ^testing.T) {
	// A local constant declared after the template naming it, which also shadows a global one
	add_shadowed :: asm(a: u64) -> (r: u64) [a -> r] { add r, ASM_DEFERRED_SHADOWED }
	ASM_DEFERRED_SHADOWED :: 2

	anonymous := asm(a: u64) -> (r: u64) [a -> r] { add r, ANONYMOUS_LATER }(1)
	ANONYMOUS_LATER :: 20

	nested :: proc() -> u64 {
		add_inner :: asm(a: u64) -> (r: u64) [a -> r] { add r, INNER_LATER }
		INNER_LATER :: 100
		return add_inner(0)
	}

	testing.expect_value(t, add_shadowed(1), u64(3))
	testing.expect_value(t, anonymous, u64(21))
	testing.expect_value(t, nested(), u64(100))
}

@(test)
asm_deferred_lazy :: proc(t: ^testing.T) {
	x := u32(77)
	testing.expect_value(t, asm_deferred_lazy_load(&x), u32(117))
	// A template of a lazy file is first checked from within a procedure body
	testing.expect_value(t, asm_deferred_lazy_add(2), u64(42))
}
