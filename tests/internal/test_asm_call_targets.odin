#+build amd64
package test_internal

import "core:c/libc"
import "core:testing"

@(private="file")
add_c :: proc "c" (a, b: u64) -> u64 {
	return a + b
}

when ODIN_OS == .Windows {
	// The first two integer arguments are in rcx and rdx, with 32 bytes of shadow space above the return address
	@(private="file")
	add_by_name :: asm(a, b: u64) -> (r: u64) [
		a = %rcx,
		b = %rdx,
		r = %rax,
		#align_stack,
	] {
		sub %rsp, 32
		call add_c
		add %rsp, 32
	}

	@(private="file")
	strlen_by_package :: asm(s: cstring) -> (r: uint) [
		s = %rcx,
		r = %rax,
		#align_stack,
	] {
		sub %rsp, 32
		call libc.strlen
		add %rsp, 32
	}

	@(private="file")
	add_through_register :: asm(f: rawptr, a, b: u64) -> (r: u64) [
		f = %r11,
		a = %rcx,
		b = %rdx,
		r = %rax,
		#align_stack,
	] {
		sub %rsp, 32
		call %r11
		add %rsp, 32
	}

	@(private="file")
	add_through_memory :: asm(f: ^rawptr, a, b: u64) -> (r: u64) [
		a = %rcx,
		b = %rdx,
		r = %rax,
		#align_stack,
	] {
		sub %rsp, 32
		call [f]:u64
		add %rsp, 32
	}

	@(private="file")
	add_through_pointer :: asm(f: rawptr, a, b: u64) -> (r: u64) [
		a = %rcx,
		b = %rdx,
		r = %rax,
		#align_stack,
	] {
		sub %rsp, 32
		call f
		add %rsp, 32
	}
} else {
	// The first two integer arguments are in rdi and rsi
	@(private="file")
	add_by_name :: asm(a, b: u64) -> (r: u64) [
		a = %rdi,
		b = %rsi,
		r = %rax,
		#align_stack,
	] {
		call add_c
	}

	@(private="file")
	strlen_by_package :: asm(s: cstring) -> (r: uint) [
		s = %rdi,
		r = %rax,
		#align_stack,
	] {
		call libc.strlen
	}

	@(private="file")
	add_through_register :: asm(f: rawptr, a, b: u64) -> (r: u64) [
		f = %r11,
		a = %rdi,
		b = %rsi,
		r = %rax,
		#align_stack,
	] {
		call %r11
	}

	@(private="file")
	add_through_memory :: asm(f: ^rawptr, a, b: u64) -> (r: u64) [
		a = %rdi,
		b = %rsi,
		r = %rax,
		#align_stack,
	] {
		call [f]:u64
	}

	@(private="file")
	add_through_pointer :: asm(f: rawptr, a, b: u64) -> (r: u64) [
		a = %rdi,
		b = %rsi,
		r = %rax,
		#align_stack,
	] {
		call f
	}
}

@(test)
asm_call_targets :: proc(t: ^testing.T) {
	f := rawptr(add_c)

	testing.expect_value(t, add_by_name(40, 2), u64(42))
	testing.expect_value(t, strlen_by_package("hellope"), uint(7))
	testing.expect_value(t, add_through_register(f, 40, 2), u64(42))
	testing.expect_value(t, add_through_memory(&f, 40, 2), u64(42))
	testing.expect_value(t, add_through_pointer(f, 40, 2), u64(42))
}
