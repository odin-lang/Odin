#+build windows
#+build i386, amd64
package sys_windows

NtCurrentTeb :: proc() -> ^TEB {
	return cast(^TEB) cast(uintptr) __readgsqword(offset_of(NT_TIB{}.Self))
}

foreign import ass "winternal_amd64.asm"

@(default_calling_convention="c")
foreign ass {
	__readfsbyte  :: proc(#any_int offset : uint) -> u8  ---
	__readfsword  :: proc(#any_int offset : uint) -> u16 ---
	__readfsdword :: proc(#any_int offset : uint) -> u32 ---
	__readfsqword :: proc(#any_int offset : uint) -> u64 ---
	__readgsbyte  :: proc(#any_int offset : uint) -> u8  ---
	__readgsword  :: proc(#any_int offset : uint) -> u16 ---
	__readgsdword :: proc(#any_int offset : uint) -> u32 ---
	__readgsqword :: proc(#any_int offset : uint) -> u64 ---
}
