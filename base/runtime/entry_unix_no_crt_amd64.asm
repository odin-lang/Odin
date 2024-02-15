bits 64

extern _start_odin
global _start

section .text

;; Entry point for programs that specify -no-crt option
;; This entry point should be compatible with dynamic loaders on linux
;; The parameters the dynamic loader passes to the _start function:
;;    RDX = pointer to atexit function
;; The stack layout is as follows:
;;    +-------------------+
;;            NULL
;;    +-------------------+
;;           envp[m]
;;    +-------------------+
;;            ...
;;    +-------------------+
;;           envp[0]
;;    +-------------------+
;;            NULL
;;    +-------------------+
;;           argv[n]
;;    +-------------------+
;;            ...
;;    +-------------------+
;;           argv[0]
;;    +-------------------+
;;            argc
;;    +-------------------+ <------ RSP
;;
_start:
    ;; Mark stack frame as the top of the stack
    xor rbp, rbp
    ;; Load argc into 1st param reg, argv into 2nd param reg
    pop rdi
    mov rdx, rsi
    ;; Align stack pointer down to 16-bytes (sysv calling convention)
    and rsp, -16
    ;; Call into odin entry point
    call _start_odin
    jmp $$