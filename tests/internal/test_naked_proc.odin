#+build linux amd64
package test_internal

import "core:testing"

// Naked procedures get no prologue or epilogue, so the asm sees the SysV registers and stack
// exactly as the caller left them.

@(private="file")
naked_add :: proc "naked" (_: int, _: int) -> int {
	body :: asm() -> ! { lea %rax, [%rdi + %rsi]; ret }
	body()
}

@(private="file")
naked_seventh :: proc "naked" (_, _, _, _, _, _: int, _: int) -> int {
	// the seventh integer goes on the stack, right above the return address
	body :: asm() -> ! { mov %rax, [%rsp + 8]; ret }
	body()
}

@(private="file")
naked_const :: proc "naked" () -> u32 {
	body :: asm($n: u32) -> ! { mov %eax, n; ret }
	body(1234)
}

@(private="file")
naked_store :: proc "naked" (_: ^u64) {
	// falls off the end, which returns
	body :: asm() { mov [%rdi]:u64, 42 }
	body()
}

@(test)
naked_proc_called_from_odin :: proc(t: ^testing.T) {
	testing.expect_value(t, naked_add(40, 2), 42)
	testing.expect_value(t, naked_add(-1, 100), 99)
	testing.expect_value(t, naked_seventh(1, 2, 3, 4, 5, 6, 77), 77)
	testing.expect_value(t, naked_const(), u32(1234))

	x: u64
	naked_store(&x)
	testing.expect_value(t, x, u64(42))

	f := naked_add
	testing.expect_value(t, f(20, 22), 42)
}
