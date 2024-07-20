//+build linux, darwin, freebsd, openbsd, netbsd
package directx_dxc
import "core:c"

FILETIME :: struct {
	dwLowDateTime: DWORD,
	dwHighDateTime: DWORD,
}

GUID :: struct {
	Data1: DWORD,
	Data2: WORD,
	Data3: WORD,
	Data4: [8]BYTE,
}

BYTE            :: distinct u8
WORD            :: u16
DWORD           :: u32
BOOL            :: distinct b32
SIZE_T          :: uint
ULONG           :: c.ulong
CLSID           :: GUID
IID             :: GUID
LONG            :: distinct c.long
HRESULT         :: distinct LONG
wstring         :: [^]c.wchar_t
BSTR            :: wstring

IUnknown :: struct {
	using _iunknown_vtable: ^IUnknown_VTable,
}
IUnknown_VTable :: struct {
	QueryInterface: proc "c" (this: ^IUnknown, riid: ^IID, ppvObject: ^rawptr) -> HRESULT,
	AddRef:         proc "c" (this: ^IUnknown) -> ULONG,
	Release:        proc "c" (this: ^IUnknown) -> ULONG,
}
