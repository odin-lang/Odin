.text

.globl _start

_start:
	ld a0, 0(sp)
	addi a1, sp, 8
	addi sp, sp, ~15
	call _start_odin
	ebreak
