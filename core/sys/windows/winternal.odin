#+build windows
package sys_windows

import "base:intrinsics"

when ODIN_ARCH == .amd64 {
	NtCurrentTeb :: proc() -> ^TEB {
		return cast(^TEB) cast(uintptr) intrinsics.x86_readgsqword(cast(u32)offset_of(NT_TIB{}.Self))
	}
}

NT_TIB :: struct {
	ExceptionList        : PVOID,
	StackBase            : PVOID,
	StackLimit           : PVOID,
	SubSystemTib         : PVOID,
	using _ : struct #raw_union {
			FiberData        : PVOID,
			Version          : DWORD,
	},
	ArbitraryUserPointer : PVOID,
	Self                 : ^NT_TIB,
}

TEB :: struct {
	using _ : struct #raw_union {
		Tib                   :       NT_TIB,
		Reserved1             :   [12]PVOID,
	},
  ProcessEnvironmentBlock :       ^PEB,
  Reserved2               :  [399]PVOID,
  Reserved3               : [1952]BYTE,
  TlsSlots                :   [64]PVOID,
  Reserved4               :    [8]BYTE,
  Reserved5               :   [26]PVOID,
  ReservedForOle          :       PVOID,
  Reserved6               :    [4]PVOID,
  TlsExpansionSlots       :       PVOID,
}