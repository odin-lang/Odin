.extern _start_odin

.globl _start

.section .text
_start:
    mov x29, xzr
    ldr x0, [sp]
    add x1, sp, #8
    and x2, sp, #-16
    mov sp, x2
    bl _start_odin
    brk #0