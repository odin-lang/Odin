	.section __TEXT,__text

	; NOTE(laytan): this should ideally be the -minimum-os-version flag but there is no nice way of preprocessing assembly in Odin.
	; 10 seems to be the lowest it goes and I don't see it mess with any targeted os version so this seems fine.
	.build_version macos, 10, 0

	.extern __start_odin

	.global _main
	.align 2
_main:
	mov x5, sp       ; use x5 as the stack pointer

	str x0, [x5]     ; get argc into x0 (kernel passes 32-bit int argc as 64-bits on stack to keep alignment)
	str x1, [x5, #8] ; get argv into x1

	and sp, x5, #~15 ; force 16-byte alignment of the stack
	
	bl __start_odin  ; call into Odin entry point
	ret              ; should never get here
