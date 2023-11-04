bits 64

global __chkstk
global _tls_index
global _fltused

section .data
	_tls_index: dd 0
	_fltused:   dd 0x9875

section .text
; NOTE(flysand): The function call to __chkstk is called
; by the compiler, when we're allocating arrays larger than
; a page size. The reason is because the OS doesn't map the
; whole stack into memory all at once, but does so page-by-page.
; When the next page is touched, the CPU generates a page fault,
; which *the OS* is handling by allocating the next page in the
; stack until we reach the limit of stack size.
;
; This page is called the guard page, touching it will extend
; the size of the stack and overwrite the stack limit in the TEB.
;
; If we allocate a large enough array and start writing from the
; bottom of it, it's possible that we may start touching
; non-contiguous pages which are unmapped. OS only maps the stack
; page into the memory if the page above it was also mapped.
;
; Therefore the compilers insert this routine, the sole purpose
; of which is to step through the stack starting from the RSP
; down to the new RSP after allocation, and touch every page
; of the new allocation so that the stack is fully mapped for
; the new allocation
;
; I've gotten this code by disassembling the output of MSVC long
; time ago. I don't remember if I've cleaned it up, but it definately
; stinks.
;
; Additional notes:
;   RAX (passed as parameter) holds the allocation's size
;   GS:[0x10] references the current stack limit
;     (i.e. bottom of the stack (i.e. lowest address accessible))
;
; Also this stuff is windows-only kind of thing, because linux people
; didn't think stack that grows is cool enough for them, but the kernel
; totally supports this kind of stack.
__chkstk:
	;; Allocate 16 bytes to store values of r10 and r11
	sub   rsp, 0x10
	mov   [rsp], r10
	mov   [rsp+0x8], r11
	;; Set r10 to point to the stack as of the moment of the function call
	lea   r10, [rsp+0x18]
	;; Subtract r10 til the bottom of the stack allocation, if we overflow
	;; reset r10 to 0, we'll crash with segfault anyway
	xor   r11, r11
	sub   r10, rax
	cmovb r10, r11
	;; Load r11 with the bottom of the stack (lowest allocated address)
	mov   r11, gs:[0x10] ; NOTE(flysand): gs:[0x10] is stack limit
	;; If the bottom of the allocation is above the bottom of the stack,
	;; we don't need to probe
	cmp   r10, r11
	jnb   .end
	;; Align the bottom of the allocation down to page size
	and   r10w, 0xf000
.loop:
	;; Move the pointer to the next guard page, and touch it by loading 0
	;; into that page
	lea   r11, [r11-0x1000]
	mov   byte [r11], 0x0
	;; Did we reach the bottom of the allocation?
	cmp   r10, r11
	jnz   .loop
.end:
	;; Restore previous r10 and r11 and return
	mov   r10, [rsp]
	mov   r11, [rsp+0x8]
	add   rsp, 0x10
	ret