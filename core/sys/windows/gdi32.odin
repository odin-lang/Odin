// +build windows
package sys_windows

foreign import gdi32 "system:Gdi32.lib"

@(default_calling_convention="stdcall")
foreign gdi32 {
	GetStockObject :: proc(i: c_int) -> HGDIOBJ ---
	SelectObject :: proc(hdc: HDC, h: HGDIOBJ) -> HGDIOBJ ---
	DeleteObject :: proc(ho: HGDIOBJ) -> BOOL ---
	SetBkColor :: proc(hdc: HDC, color: COLORREF) -> COLORREF ---

	CreateDIBPatternBrush :: proc(h: HGLOBAL, iUsage: UINT) -> HBRUSH ---

	CreateDIBitmap :: proc(
		hdc: HDC,
		pbmih: ^BITMAPINFOHEADER,
		flInit: DWORD,
		pjBits: VOID,
		pbmi: ^BITMAPINFO,
		iUsage: UINT,
	) -> HBITMAP ---

	CreateDIBSection :: proc(
		hdc: HDC,
		pbmi: ^BITMAPINFO,
		usage: UINT,
		ppvBits: VOID,
		hSection: HANDLE,
		offset: DWORD,
	) -> HBITMAP ---

	StretchDIBits :: proc(
		hdc: HDC,
		xDest: c_int,
		yDest: c_int,
		DestWidth: c_int,
		DestHeight: c_int,
		xSrc: c_int,
		ySrc: c_int,
		SrcWidth: c_int,
		SrcHeight: c_int,
		lpBits: VOID,
		lpbmi: ^BITMAPINFO,
		iUsage: UINT,
		rop: DWORD,
	) -> c_int ---

	StretchBlt :: proc(
		hdcDest: HDC,
		xDest: c_int,
		yDest: c_int,
		wDest: c_int,
		hDest: c_int,
		hdcSrc: HDC,
		xSrc: c_int,
		ySrc: c_int,
		wSrc: c_int,
		hSrc: c_int,
		rop: DWORD,
	) -> BOOL ---

	SetPixelFormat :: proc(hdc: HDC, format: c_int, ppfd: ^PIXELFORMATDESCRIPTOR) -> BOOL ---
	ChoosePixelFormat :: proc(hdc: HDC, ppfd: ^PIXELFORMATDESCRIPTOR) -> c_int ---
	SwapBuffers :: proc(HDC) -> BOOL ---

	SetDCBrushColor :: proc(hdc: HDC, color: COLORREF) -> COLORREF ---
	GetDCBrushColor :: proc(hdc: HDC) -> COLORREF ---
	PatBlt :: proc(hdc: HDC, x, y, w, h: c_int, rop: DWORD) -> BOOL ---
	Rectangle :: proc(hdc: HDC, left, top, right, bottom: c_int) -> BOOL ---

	CreateFontW :: proc(
		cHeight, cWidth, cEscapement, cOrientation, cWeight: c_int,
		bItalic, bUnderline, bStrikeOut, iCharSet, iOutPrecision: DWORD,
		iClipPrecision, iQuality, iPitchAndFamily: DWORD,
		pszFaceName: LPCWSTR,
	) -> HFONT ---
	TextOutW :: proc(hdc: HDC, x, y: c_int, lpString: LPCWSTR, c: c_int) -> BOOL ---
}

RGB :: #force_inline proc "contextless" (r, g, b: u8) -> COLORREF {
	return transmute(COLORREF)[4]u8{r, g, b, 0}
}
