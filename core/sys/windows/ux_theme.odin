#+build windows
package sys_windows

foreign import uxtheme "system:UxTheme.lib"

MARGINS :: struct {
	cxLeftWidth:    c_int,
	cxRightWidth:   c_int,
	cyTopHeight:    c_int,
	cyBottomHeight: c_int,
}
PMARGINS :: ^MARGINS

@(default_calling_convention="system")
foreign uxtheme {
	IsThemeActive  :: proc() -> BOOL ---
	SetWindowTheme :: proc(hWnd: HWND, pszSubAppName, pszSubIdList: LPCWSTR) -> HRESULT ---
}
