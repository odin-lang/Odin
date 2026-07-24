bits 64

%define SYS_mmap 197

global __netbsd_sys_mmap

; This is a workaround for NetBSD's standard mmap syscall needing seven
; arguments (one of which is useless). The seventh must go on the stack,
; and our syscall intrinsics do not currently handle stack-based arguments.
section .text
__netbsd_sys_mmap:
	; These are the arguments for SYS_mmap.
	;
	; addr:  void*
	; len:   size_t
	; prot:  int
	; flags: int
	; fd:    int
	; PAD:   long (unused)
	; pos:   off_t

	; Move the flags argument into the right register.
	mov r10, rcx

	mov rax, SYS_mmap
	syscall

	; Set the DL register to true if the Carry Flag is clear.
	;
	; This is where the 2nd return value will be taken from.
	;
	; This is valid for the System V AMD64 ABI, as 128-bit return
	; values may be stored in RAX:RDX.
	setnb dl

	ret
