#+build amd64
package test_issue_asm_call_targets

import "core:fmt"

add_c  :: proc "c" (a, b: u64) -> u64 { return a + b }
sub_c  :: proc "c" (a, b: u32) -> u32 { return a - b }
add_odin :: proc(a, b: u64) -> u64 { return a + b }

group :: proc{add_c, sub_c}

poly_c :: proc "c" (x: $T) -> T { return x }

// Accepted: a procedure by name, a procedure from another package, and untyped targets
by_name :: asm() [
	#volatile,
	#align_stack,
] {
	call add_c
}

through_register :: asm(f: rawptr) [
	f = %r11,
	#volatile,
	#align_stack,
] {
	call %r11
}

// Each of these is rejected: 8 errors, as the jump in 6 also never returns

// 1. A parameter with the Odin calling convention
odin_param :: asm(f: proc(u64)) [
	#volatile,
	#align_stack,
] {
	call f
}

// 2. A procedure with the Odin calling convention, by name
odin_by_name :: asm() [
	#volatile,
	#align_stack,
] {
	call add_odin
}

// 3. One from another package
odin_by_package :: asm() [
	#volatile,
	#align_stack,
] {
	call fmt.println
}

// 4. A procedure group
by_group :: asm() [
	#volatile,
	#align_stack,
] {
	call group
}

// 5. A polymorphic procedure
by_poly :: asm() [
	#volatile,
	#align_stack,
] {
	call poly_c
}

// 6. A procedure as the target of a jump rather than a call
jump_to_procedure :: asm() [
	#volatile,
] {
	jmp add_c
}

// 7. A procedure inside a memory operand
procedure_address :: asm() -> (r: u64) {
	lea r, [add_c]
}

takes_u64 :: proc(x: u64) {}

main :: proc() {
	by_name()
	through_register(rawptr(add_c))
	odin_param(takes_u64)
	odin_by_name()
	odin_by_package()
	by_group()
	by_poly()
	jump_to_procedure()
	_ = procedure_address()
}
