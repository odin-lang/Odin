#+build windows
package sys_windows

foreign import shlwapi "system:shlwapi.lib"

@(default_calling_convention="system")
foreign shlwapi {
	PathFileExistsW    :: proc(pszPath: wstring) -> BOOL ---
	PathFindExtensionW :: proc(pszPath: wstring) -> wstring ---
	PathFindFileNameW  :: proc(pszPath: wstring) -> wstring ---
	SHAutoComplete     :: proc(hwndEdit: HWND, dwFlags: DWORD) -> LWSTDAPI ---

	AssocCreate            :: proc(clsid: CLSID, riid: REFIID, ppv: ^rawptr) -> HRESULT ---
	SHGetAssocKeys         :: proc(pqa: ^IQueryAssociations, rgKeys: [^]HKEY, cKeys: DWORD) -> HRESULT ---
	AssocQueryStringW      :: proc(flags: ASSOCF, str: ASSOCSTR, pszAssoc: LPCWSTR, pszExtra: LPCWSTR, pszOut: LPWSTR, pcchOut: ^DWORD) -> LWSTDAPI ---
	AssocQueryStringByKeyW :: proc(flags: ASSOCF, str: ASSOCSTR, hkAssoc: HKEY, pszExtra: LPCWSTR, pszOut: LPWSTR, pcchOut: ^DWORD) -> HRESULT ---
	AssocQueryKeyW         :: proc(flags: ASSOCF, key: ASSOCKEY, pszAssoc: LPCWSTR, pszExtra: LPCWSTR, phkeyOut: ^HKEY) -> HRESULT ---
	AssocIsDangerous       :: proc(pszAssoc: PCWSTR) -> HRESULT ---
	AssocGetPerceivedType  :: proc(pszExt: PCWSTR, ptype: ^PERCEIVED, pflag: ^PERCEIVEDFLAG, ppszType: ^PWSTR) -> HRESULT ---
}
