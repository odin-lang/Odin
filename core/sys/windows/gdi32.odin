// +build windows
package sys_windows

foreign import gdi32 "system:Gdi32.lib"

@(default_calling_convention="stdcall")
foreign gdi32 {
	GetStockObject :: proc(i: c_int) -> HGDIOBJ ---
	SelectObject :: proc(hdc: HDC, h: HGDIOBJ) -> HGDIOBJ ---

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
	PatBlt :: proc(hdc: HDC, x, y, w, h: c_int, rop: DWORD) -> BOOL ---
}

RGB :: proc(r, g, b: u8) -> COLORREF {
	return COLORREF(COLORREF(r) | COLORREF(g) << 8 | COLORREF(b) << 16)
}
