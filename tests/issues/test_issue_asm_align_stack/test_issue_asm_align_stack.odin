#+build amd64
package test_issue_asm_align_stack

// Each of these needs #align_stack and lacks it: 4 errors
pushes :: asm() [
	#preserve %rbx,
	#volatile,
] {
	push %rbx
	pop %rbx
}

calls_out :: asm(f: proc "c" ()) [
	#volatile,
] {
	call f
}

calls_label :: asm(x: u64) -> (r: u64) [
	x -> r = %rax,
] {
	call .double
	jmp .done
.double:
	add %rax, %rax
	ret
.done:
}

moves_stack_pointer :: asm() [
	#volatile,
] {
	sub %rsp, 16
	add %rsp, 16
}

// Each of these declares it, as it needs to
pushes_aligned :: asm() [
	#preserve %rbx,
	#volatile,
	#align_stack,
] {
	push %rbx
	pop %rbx
}

calls_out_aligned :: asm(f: proc "c" ()) [
	#volatile,
	#align_stack,
] {
	call f
}

// Returning does not write below the stack pointer, so this needs nothing
returns :: asm() -> ! [
	#volatile,
] {
	ret
}

// Nothing here touches the stack: 1 warning
redundant :: asm(x: u64) -> (r: u64) [
	x -> r,
	#align_stack,
] {
	add r, 1
}

nothing :: proc "c" () {}

main :: proc() {
	pushes()
	calls_out(nothing)
	_ = calls_label(1)
	moves_stack_pointer()
	pushes_aligned()
	calls_out_aligned(nothing)
	_ = redundant(1)
	if redundant(0) == 0 {
		returns()
	}
}
