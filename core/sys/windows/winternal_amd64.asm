bits 64

global __readfsbyte
global __readfsword
global __readfsdword
global __readfsqword
global __readgsbyte
global __readgsword
global __readgsdword
global __readgsqword

section .text

;
; Read FS / Read GS "intrinsics" of cpp,
; used to obtain OS-Specific information like the ThreadInfoBlock in windows
;

__readfsbyte:
	mov al, byte fs:[rcx]
	ret

__readfsword:
	mov ax, word fs:[rcx]
	ret

__readfsdword:
	mov eax, dword fs:[rcx]
	ret

__readfsqword:
	mov rax, fs:[rcx]
	ret

__readgsbyte:
	mov al, byte gs:[rcx]
	ret

__readgsword:
	mov ax, word gs:[rcx]
	ret

__readgsdword:
	mov eax, dword gs:[rcx]
	ret

__readgsqword:
	mov rax, gs:[rcx]
	ret