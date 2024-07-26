package sys_windows

foreign import "system:Ole32.lib"

//objbase.h
// Note(Dragos): https://learn.microsoft.com/en-us/windows/win32/api/objbase/ne-objbase-coinit makes you believe that MULTITHREADED == 3. That is wrong. See definition of objbase.h
/*
typedef enum tagCOINIT
{
	COINIT_APARTMENTTHREADED  = 0x2,      // Apartment model

#if  (_WIN32_WINNT >= 0x0400 ) || defined(_WIN32_DCOM) // DCOM
	// These constants are only valid on Windows NT 4.0
	COINIT_MULTITHREADED      = COINITBASE_MULTITHREADED,
	COINIT_DISABLE_OLE1DDE    = 0x4,      // Don't use DDE for Ole1 support.
	COINIT_SPEED_OVER_MEMORY  = 0x8,      // Trade memory for speed.
#endif // DCOM
} COINIT;
*/
// Where COINITBASE_MULTITHREADED == 0x00
COINIT :: enum DWORD {
	APARTMENTTHREADED = 0x2,
	MULTITHREADED     = 0,
	DISABLE_OLE1DDE   = 0x4,
	SPEED_OVER_MEMORY = 0x8,
}

IUnknown :: struct {
	using _iunknown_vtable: ^IUnknown_VTable,
}

IUnknownVtbl :: IUnknown_VTable
IUnknown_VTable :: struct {
	QueryInterface: proc "system" (This: ^IUnknown, riid: REFIID, ppvObject: ^rawptr) -> HRESULT,
	AddRef:         proc "system" (This: ^IUnknown) -> ULONG,
	Release:        proc "system" (This: ^IUnknown) -> ULONG,
}

LPUNKNOWN :: ^IUnknown

@(default_calling_convention="system")
foreign Ole32 {
	CoInitialize :: proc(reserved: rawptr = nil) -> HRESULT ---
	CoInitializeEx :: proc(reserved: rawptr = nil, co_init: COINIT = .APARTMENTTHREADED) -> HRESULT ---
	CoUninitialize :: proc() ---

	CoCreateInstance :: proc(
		rclsid: REFCLSID,
		pUnkOuter: LPUNKNOWN,
		dwClsContext: DWORD,
		riid: REFIID,
		ppv: ^LPVOID,
	) -> HRESULT ---

	CoTaskMemFree :: proc(pv: rawptr) ---

	CLSIDFromProgID :: proc(lpszProgID: LPCOLESTR, lpclsid: LPCLSID) -> HRESULT ---
	CLSIDFromProgIDEx :: proc(lpszProgID, LPCOLESTR, lpclsid: LPCLSID) -> HRESULT ---
	CLSIDFromString :: proc(lpsz: LPOLESTR, pclsid: LPCLSID) -> HRESULT ---
	IIDFromString :: proc(lpsz: LPOLESTR, lpiid: LPIID) -> HRESULT ---
	ProgIDFromCLSID :: proc(clsid: REFCLSID, lplpszProgID: ^LPOLESTR) -> HRESULT ---
	StringFromCLSID :: proc(rclsid: REFCLSID, lplpsz: ^LPOLESTR) -> HRESULT ---
	StringFromGUID2 :: proc(rclsid: REFCLSID, lplpsz: LPOLESTR, cchMax: INT) -> INT ---
	StringFromIID :: proc(rclsid: REFIID, lplpsz: ^LPOLESTR) -> HRESULT ---

	PropVariantClear :: proc(pvar: ^PROPVARIANT) -> HRESULT ---
	PropVariantCopy :: proc(pvarDest: ^PROPVARIANT, pvarSrc: ^PROPVARIANT) -> HRESULT ---
	FreePropVariantArray :: proc(cVariants: ULONG, rgvars: ^PROPVARIANT) -> HRESULT ---
}
