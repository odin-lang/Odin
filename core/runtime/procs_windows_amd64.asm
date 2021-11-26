global __chkstk
global _tls_index
global _fltused

section .data
	_tls_index: dd 0
	_fltused:   dd 0x9875
	

section .text
__chkstk: ; proc "c" (rawptr)
	; TODO implement correctly
	ret