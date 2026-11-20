#+build amd64
package test_issue_asm_call_flow

// A call returns, so the template needs no `-> !`, and setting up the argument is not a dead write
call_with_two :: asm(f: proc "c" (u64)) [
	#volatile,
	#align_stack,
] {
	mov %rdi, 2
	call f
}

// A pinned input may be an argument of the call, so it is used even though the body never names it
call_with :: asm(f: proc "c" (u64), x: u64) [
	x = %rdi,
	#volatile,
	#align_stack,
] {
	call f
}

// The callee may produce an output pinned to any register
call_result :: asm(f: proc "c" () -> u64) -> (r: u64) [
	r = %rax,
	#volatile,
	#align_stack,
] {
	call f
}

// Every path ends in a call to a diverging procedure
call_never :: asm(f: proc "c" () -> !) -> ! [
	#volatile,
	#align_stack,
] {
	call f
}

// A subroutine inside the template, reached by calls to its label
quadruple :: asm(x: u64) -> (r: u64) [
	x -> r = %rax,
	#align_stack,
] {
	call .double
	call .double
	jmp .done
.double:
	add %rax, %rax
	ret
.done:
}

// Declared diverging, but the procedure it calls returns: the only error
not_never :: asm(f: proc "c" ()) -> ! [
	#volatile,
	#align_stack,
] {
	call f
}

returns    :: proc "c" (x: u64) {}
forty_two  :: proc "c" () -> u64 { return 42 }
stop       :: proc "c" () -> ! { for {} }
nothing    :: proc "c" () {}

main :: proc() {
	call_with_two(returns)
	call_with(returns, 7)
	_ = call_result(forty_two)
	_ = quadruple(5)
	if call_result(forty_two) == 0 {
		call_never(stop)
	}
	if call_result(forty_two) == 1 {
		not_never(nothing)
	}
}
