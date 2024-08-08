// +build windows
package sys_windows

import "core:math/fixed"

foreign import gdi32 "system:Gdi32.lib"

@(default_calling_convention="system")
foreign gdi32 {
	GetDeviceCaps :: proc(hdc: HDC, index: INT) -> INT ---
	GetStockObject :: proc(i: INT) -> HGDIOBJ ---
	SelectObject :: proc(hdc: HDC, h: HGDIOBJ) -> HGDIOBJ ---
	DeleteObject :: proc(ho: HGDIOBJ) -> BOOL ---
	SetBkColor :: proc(hdc: HDC, color: COLORREF) -> COLORREF ---
	SetBkMode :: proc(hdc: HDC, mode: BKMODE) -> INT ---

	CreateCompatibleDC :: proc(hdc: HDC) -> HDC ---
	DeleteDC :: proc(hdc: HDC) -> BOOL ---
	CancelDC :: proc(hdc: HDC) -> BOOL ---
	SaveDC :: proc(hdc: HDC) -> INT ---
	RestoreDC :: proc(hdc: HDC, nSavedDC: INT) -> BOOL ---

	CreateDIBPatternBrush :: proc(h: HGLOBAL, iUsage: UINT) -> HBRUSH ---
	CreateDIBitmap :: proc(hdc: HDC, pbmih: ^BITMAPINFOHEADER, flInit: DWORD, pjBits: VOID, pbmi: ^BITMAPINFO, iUsage: UINT) -> HBITMAP ---
	CreateDIBSection :: proc(hdc: HDC, pbmi: ^BITMAPINFO, usage: UINT, ppvBits: VOID, hSection: HANDLE, offset: DWORD) -> HBITMAP ---
	StretchDIBits :: proc(hdc: HDC, xDest, yDest, DestWidth, DestHeight, xSrc, ySrc, SrcWidth, SrcHeight: INT, lpBits: VOID, lpbmi: ^BITMAPINFO, iUsage: UINT, rop: DWORD) -> INT ---
	StretchBlt :: proc(hdcDest: HDC, xDest, yDest, wDest, hDest: INT, hdcSrc: HDC, xSrc, ySrc, wSrc, hSrc: INT, rop: DWORD) -> BOOL ---

	SetPixelFormat :: proc(hdc: HDC, format: INT, ppfd: ^PIXELFORMATDESCRIPTOR) -> BOOL ---
	ChoosePixelFormat :: proc(hdc: HDC, ppfd: ^PIXELFORMATDESCRIPTOR) -> INT ---
	DescribePixelFormat :: proc(hdc: HDC, iPixelFormat: INT, nBytes: UINT, ppfd: ^PIXELFORMATDESCRIPTOR) -> INT ---
	SwapBuffers :: proc(hdc: HDC) -> BOOL ---

	SetDCBrushColor :: proc(hdc: HDC, color: COLORREF) -> COLORREF ---
	GetDCBrushColor :: proc(hdc: HDC) -> COLORREF ---
	PatBlt :: proc(hdc: HDC, x, y, w, h: INT, rop: DWORD) -> BOOL ---
	Rectangle :: proc(hdc: HDC, left, top, right, bottom: INT) -> BOOL ---

	CreateFontW :: proc(cHeight, cWidth, cEscapement, cOrientation, cWeight: INT, bItalic, bUnderline, bStrikeOut, iCharSet, iOutPrecision: DWORD, iClipPrecision, iQuality, iPitchAndFamily: DWORD, pszFaceName: LPCWSTR) -> HFONT ---
	CreateFontIndirectW :: proc(lplf: ^LOGFONTW) -> HFONT ---
	CreateFontIndirectExW :: proc(unnamedParam1: ^ENUMLOGFONTEXDVW) -> HFONT ---
	AddFontResourceW :: proc(unnamedParam1: LPCWSTR) -> INT ---
	AddFontResourceExW :: proc(name: LPCWSTR, fl: DWORD, res: PVOID) -> INT ---
	AddFontMemResourceEx :: proc(pFileView: PVOID, cjSize: DWORD, pvResrved: PVOID, pNumFonts: ^DWORD) -> HANDLE ---
	EnumFontsW :: proc(hdc: HDC, lpLogfont: LPCWSTR, lpProc: FONTENUMPROCW, lParam: LPARAM) -> INT ---
	EnumFontFamiliesW :: proc(hdc: HDC, lpLogfont: LPCWSTR, lpProc: FONTENUMPROCW, lParam: LPARAM) -> INT ---
	EnumFontFamiliesExW :: proc(hdc: HDC, lpLogfont: LPLOGFONTW, lpProc: FONTENUMPROCW, lParam: LPARAM, dwFlags: DWORD) -> INT ---

	TextOutW :: proc(hdc: HDC, x, y: INT, lpString: LPCWSTR, c: INT) -> BOOL ---
	GetTextExtentPoint32W :: proc(hdc: HDC, lpString: LPCWSTR, c: INT, psizl: LPSIZE) -> BOOL ---
	GetTextMetricsW :: proc(hdc: HDC, lptm: LPTEXTMETRICW) -> BOOL ---

	CreateSolidBrush :: proc(color: COLORREF) -> HBRUSH ---

	GetObjectW :: proc(h: HANDLE, c: INT, pv: LPVOID) -> int ---
	CreateCompatibleBitmap :: proc(hdc: HDC, cx, cy: INT) -> HBITMAP ---
	BitBlt :: proc(hdc: HDC, x, y, cx, cy: INT, hdcSrc: HDC, x1, y1: INT, rop: DWORD) -> BOOL ---
	GetDIBits :: proc(hdc: HDC, hbm: HBITMAP, start, cLines: UINT, lpvBits: LPVOID, lpbmi: ^BITMAPINFO, usage: UINT) -> INT ---
	SetDIBits :: proc(hdc: HDC, hbm: HBITMAP, start: UINT, cLines: UINT, lpBits: VOID, lpbmi: ^BITMAPINFO, ColorUse: UINT) -> INT ---
	SetDIBColorTable :: proc(hdc: HDC, iStart: UINT, cEntries: UINT, prgbq: ^RGBQUAD) -> UINT ---
	GetDIBColorTable :: proc(hdc: HDC, iStart: UINT, cEntries: UINT, prgbq: ^RGBQUAD) -> UINT ---

	CreatePen :: proc(iStyle, cWidth: INT, color: COLORREF) -> HPEN ---
	ExtCreatePen :: proc(iPenStyle, cWidth: DWORD, plbrush: ^LOGBRUSH, cStyle: DWORD, pstyle: ^DWORD) -> HPEN ---
	SetDCPenColor :: proc(hdc: HDC, color: COLORREF) -> COLORREF ---
	GetDCPenColor :: proc(hdc: HDC) -> COLORREF ---

	CreatePalette :: proc(plpal: ^LOGPALETTE) -> HPALETTE ---
	SelectPalette :: proc(hdc: HDC, hPal: HPALETTE, bForceBkgd: BOOL) -> HPALETTE ---
	RealizePalette :: proc(hdc: HDC) -> UINT ---

	SetTextColor :: proc(hdc: HDC, color: COLORREF) -> COLORREF ---
	RoundRect :: proc(hdc: HDC, left: INT, top: INT, right: INT, bottom: INT, width: INT, height: INT) -> BOOL ---
	SetPixel :: proc(hdc: HDC, x: INT, y: INT, color: COLORREF) -> COLORREF ---

	GdiTransparentBlt :: proc(hdcDest: HDC, xoriginDest, yoriginDest, wDest, hDest: INT, hdcSrc: HDC, xoriginSrc, yoriginSrc, wSrc, hSrc: INT, crTransparent: UINT) -> BOOL ---
	GdiGradientFill :: proc(hdc: HDC, pVertex: PTRIVERTEX, nVertex: ULONG, pMesh: PVOID, nCount: ULONG, ulMode: ULONG) -> BOOL ---
	GdiAlphaBlend :: proc(hdcDest: HDC, xoriginDest, yoriginDest, wDest, hDest: INT, hdcSrc: HDC, xoriginSrc, yoriginSrc, wSrc, hSrc: INT, ftn: BLENDFUNCTION) -> BOOL ---
}

RGB :: #force_inline proc "contextless" (#any_int r, g, b: int) -> COLORREF {
	return COLORREF(DWORD(BYTE(r)) | (DWORD(BYTE(g)) << 8) | (DWORD(BYTE(b)) << 16))
}

PALETTERGB :: #force_inline proc "contextless" (#any_int r, g, b: int) -> COLORREF {
	return 0x02000000 | RGB(r, g, b)
}

PALETTEINDEX :: #force_inline proc "contextless" (#any_int i: int) -> COLORREF {
	return COLORREF(DWORD(0x01000000) | DWORD(WORD(i)))
}

FXPT2DOT30 :: distinct fixed.Fixed(i32, 30)

CIEXYZ :: struct {
	ciexyzX, ciexyzY, ciexyzZ: FXPT2DOT30,
}

CIEXYZTRIPLE :: struct {
	ciexyzRed, ciexyzGreen, ciexyzBlue: CIEXYZ,
}

// https://learn.microsoft.com/en-us/windows/win32/api/wingdi/ns-wingdi-bitmapv5header
BITMAPV5HEADER :: struct {
	bV5Size:          DWORD,
	bV5Width:         LONG,
	bV5Height:        LONG,
	bV5Planes:        WORD,
	bV5BitCount:      WORD,
	bV5Compression:   DWORD,
	bV5SizeImage:     DWORD,
	bV5XPelsPerMeter: LONG,
	bV5YPelsPerMeter: LONG,
	bV5ClrUsed:       DWORD,
	bV5ClrImportant:  DWORD,
	bV5RedMask:       DWORD,
	bV5GreenMask:     DWORD,
	bV5BlueMask:      DWORD,
	bV5AlphaMask:     DWORD,
	bV5CSType:        DWORD,
	bV5Endpoints:     CIEXYZTRIPLE,
	bV5GammaRed:      DWORD,
	bV5GammaGreen:    DWORD,
	bV5GammaBlue:     DWORD,
	bV5Intent:        DWORD,
	bV5ProfileData:   DWORD,
	bV5ProfileSize:   DWORD,
	bV5Reserved:      DWORD,
}

PALETTEENTRY :: struct {
	peRed, peGreen, peBlue, peFlags: BYTE,
}

LOGPALETTE :: struct {
	palVersion:    WORD,
	palNumEntries: WORD,
	palPalEntry:   []PALETTEENTRY,
}

BKMODE :: enum {
	TRANSPARENT = 1,
	OPAQUE      = 2,
}

ICONINFOEXW :: struct {
	cbSize:             DWORD,
	fIcon:              BOOL,
	xHotspot, yHotspot: DWORD,
	hbmMask, hbmColor:  HBITMAP,
	wResID:             WORD,
	szModName:          [MAX_PATH]WCHAR,
	szResName:          [MAX_PATH]WCHAR,
}
PICONINFOEXW :: ^ICONINFOEXW

AC_SRC_OVER :: 0x00
AC_SRC_ALPHA :: 0x01

TransparentBlt :: GdiTransparentBlt
GradientFill :: GdiGradientFill
AlphaBlend :: GdiAlphaBlend

COLOR16 :: USHORT
TRIVERTEX :: struct {
	x, y:                    LONG,
	Red, Green, Blue, Alpha: COLOR16,
}
PTRIVERTEX :: ^TRIVERTEX

GRADIENT_TRIANGLE :: struct {
	Vertex1, Vertex2, Vertex3: ULONG,
}
PGRADIENT_TRIANGLE :: ^GRADIENT_TRIANGLE

GRADIENT_RECT :: struct {
	UpperLeft, LowerRight: ULONG,
}
PGRADIENT_RECT :: ^GRADIENT_RECT

BLENDFUNCTION :: struct {
	BlendOp, BlendFlags, SourceConstantAlpha, AlphaFormat: BYTE,
}

GRADIENT_FILL_RECT_H    : ULONG : 0x00000000
GRADIENT_FILL_RECT_V    : ULONG : 0x00000001
GRADIENT_FILL_TRIANGLE  : ULONG : 0x00000002
GRADIENT_FILL_OP_FLAG   : ULONG : 0x000000ff

/* Brush Styles */
BS_SOLID         :: 0
BS_NULL          :: 1
BS_HOLLOW        :: BS_NULL
BS_HATCHED       :: 2
BS_PATTERN       :: 3
BS_INDEXED       :: 4
BS_DIBPATTERN    :: 5
BS_DIBPATTERNPT  :: 6
BS_PATTERN8X8    :: 7
BS_DIBPATTERN8X8 :: 8
BS_MONOPATTERN   :: 9

/* Hatch Styles */
HS_HORIZONTAL    :: 0       /* ----- */
HS_VERTICAL      :: 1       /* ||||| */
HS_FDIAGONAL     :: 2       /* \\\\\ */
HS_BDIAGONAL     :: 3       /* ///// */
HS_CROSS         :: 4       /* +++++ */
HS_DIAGCROSS     :: 5       /* xxxxx */
HS_API_MAX       :: 12

/* Pen Styles */
PS_SOLID         ::  0
PS_DASH          ::  1      /* ------- */
PS_DOT           ::  2      /* ....... */
PS_DASHDOT       ::  3      /* _._._._ */
PS_DASHDOTDOT    ::  4      /* _.._.._ */
PS_NULL          ::  5
PS_INSIDEFRAME   ::  6
PS_USERSTYLE     ::  7
PS_ALTERNATE     ::  8
PS_STYLE_MASK    ::  0x0000000F
PS_ENDCAP_ROUND  ::  0x00000000
PS_ENDCAP_SQUARE ::  0x00000100
PS_ENDCAP_FLAT   ::  0x00000200
PS_ENDCAP_MASK   ::  0x00000F00
PS_JOIN_ROUND    ::  0x00000000
PS_JOIN_BEVEL    ::  0x00001000
PS_JOIN_MITER    ::  0x00002000
PS_JOIN_MASK     ::  0x0000F000
PS_COSMETIC      ::  0x00000000
PS_GEOMETRIC     ::  0x00010000
PS_TYPE_MASK     ::  0x000F0000

LOGBRUSH :: struct {
	lbStyle: UINT,
	lbColor: COLORREF,
	lbHatch: ULONG_PTR,
}
PLOGBRUSH :: ^LOGBRUSH

/* CombineRgn() Styles */
RGN_AND  :: 1
RGN_OR   :: 2
RGN_XOR  :: 3
RGN_DIFF :: 4
RGN_COPY :: 5

/* StretchBlt() Modes */
// BLACKONWHITE :: 1
// WHITEONBLACK :: 2
// COLORONCOLOR :: 3
// HALFTONE     :: 4

/* PolyFill() Modes */
ALTERNATE :: 1
WINDING   :: 2

/* Layout Orientation Options */
LAYOUT_RTL             :: 0x00000001 // Right to left
LAYOUT_BTT             :: 0x00000002 // Bottom to top
LAYOUT_VBH             :: 0x00000004 // Vertical before horizontal
LAYOUT_ORIENTATIONMASK :: (LAYOUT_RTL | LAYOUT_BTT | LAYOUT_VBH)

/* Text Alignment Options */
TA_NOUPDATECP :: 0
TA_UPDATECP   :: 1

TA_LEFT       :: 0
TA_RIGHT      :: 2
TA_CENTER     :: 6

TA_TOP        :: 0
TA_BOTTOM     :: 8
TA_BASELINE   :: 24
TA_RTLREADING :: 256
TA_MASK       :: (TA_BASELINE+TA_CENTER+TA_UPDATECP+TA_RTLREADING)

MM_MAX_NUMAXES :: 16
DESIGNVECTOR :: struct {
	dvReserved: DWORD,
	dvNumAxes:  DWORD,
	dvValues:   [MM_MAX_NUMAXES]LONG,
}

LF_FACESIZE :: 32
LF_FULLFACESIZE :: 64

LOGFONTW :: struct {
	lfHeight:         LONG,
	lfWidth:          LONG,
	lfEscapement:     LONG,
	lfOrientation:    LONG,
	lfWeight:         LONG,
	lfItalic:         BYTE,
	lfUnderline:      BYTE,
	lfStrikeOut:      BYTE,
	lfCharSet:        BYTE,
	lfOutPrecision:   BYTE,
	lfClipPrecision:  BYTE,
	lfQuality:        BYTE,
	lfPitchAndFamily: BYTE,
	lfFaceName:       [LF_FACESIZE]WCHAR,
}
LPLOGFONTW :: ^LOGFONTW

ENUMLOGFONTW :: struct {
	elfLogFont:  LOGFONTW,
	elfFullName: [LF_FULLFACESIZE]WCHAR,
	elfStyle:    [LF_FACESIZE]WCHAR,
}
LPENUMLOGFONTW :: ^ENUMLOGFONTW

ENUMLOGFONTEXW :: struct {
	elfLogFont:  LOGFONTW,
	elfFullName: [LF_FULLFACESIZE]WCHAR,
	elfStyle:    [LF_FACESIZE]WCHAR,
	elfScript:   [LF_FACESIZE]WCHAR,
}

ENUMLOGFONTEXDVW :: struct {
	elfEnumLogfontEx: ENUMLOGFONTEXW,
	elfDesignVector:  DESIGNVECTOR,
}

NEWTEXTMETRICW :: struct {
	tmHeight:           LONG,
	tmAscent:           LONG,
	tmDescent:          LONG,
	tmInternalLeading:  LONG,
	tmExternalLeading:  LONG,
	tmAveCharWidth:     LONG,
	tmMaxCharWidth:     LONG,
	tmWeight:           LONG,
	tmOverhang:         LONG,
	tmDigitizedAspectX: LONG,
	tmDigitizedAspectY: LONG,
	tmFirstChar:        WCHAR,
	tmLastChar:         WCHAR,
	tmDefaultChar:      WCHAR,
	tmBreakChar:        WCHAR,
	tmItalic:           BYTE,
	tmUnderlined:       BYTE,
	tmStruckOut:        BYTE,
	tmPitchAndFamily:   BYTE,
	tmCharSet:          BYTE,
	ntmFlags:           DWORD,
	ntmSizeEM:          UINT,
	ntmCellHeight:      UINT,
	ntmAvgWidth:        UINT,
}

FONTENUMPROCW :: #type proc(lpelf: ^ENUMLOGFONTW, lpntm: ^NEWTEXTMETRICW, FontType: DWORD, lParam: LPARAM) -> INT
