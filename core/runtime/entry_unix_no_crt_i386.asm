bits 32

extern _start_odin
global _start

section .text

;; NOTE(flysand): For description see the corresponding *_amd64.asm file
;; also I didn't test this on x86-32
_start:
    xor ebp, rbp
    pop ecx
    mov eax, esp
    and esp, -16
    push eax
    push ecx
    call _start_odin
    jmp $$