#+build windows
package sys_windows

foreign import gdi32 "system:Gdi32.lib"

@(default_calling_convention="system")
foreign gdi32 {
	GetDeviceCaps  :: proc(hdc: HDC, index: INT) -> INT ---
	GetStockObject :: proc(i: INT) -> HGDIOBJ ---
	SelectObject   :: proc(hdc: HDC, h: HGDIOBJ) -> HGDIOBJ ---
	DeleteObject   :: proc(ho: HGDIOBJ) -> BOOL ---
	SetBkColor     :: proc(hdc: HDC, color: COLORREF) -> COLORREF ---
	SetBkMode      :: proc(hdc: HDC, mode: BKMODE) -> INT ---

	CreateCompatibleDC :: proc(hdc: HDC) -> HDC ---
	DeleteDC           :: proc(hdc: HDC) -> BOOL ---
	CancelDC           :: proc(hdc: HDC) -> BOOL ---
	SaveDC             :: proc(hdc: HDC) -> INT ---
	RestoreDC          :: proc(hdc: HDC, nSavedDC: INT) -> BOOL ---

	CreateDIBPatternBrush :: proc(h: HGLOBAL, iUsage: UINT) -> HBRUSH ---
	CreateBitmap          :: proc(nWidth: INT, nHeight: INT, nPlanes: UINT, nBitCount: UINT, lpBits: LPVOID) -> HBITMAP ---
	CreateDIBitmap        :: proc(hdc: HDC, pbmih: ^BITMAPINFOHEADER, flInit: DWORD, pjBits: PVOID, pbmi: ^BITMAPINFO, iUsage: UINT) -> HBITMAP ---
	CreateDIBSection      :: proc(hdc: HDC, pbmi: ^BITMAPINFO, usage: UINT, ppvBits: ^PVOID, hSection: HANDLE, offset: DWORD) -> HBITMAP ---
	StretchDIBits         :: proc(hdc: HDC, xDest, yDest, DestWidth, DestHeight, xSrc, ySrc, SrcWidth, SrcHeight: INT, lpBits: LPVOID, lpbmi: ^BITMAPINFO, iUsage: UINT, rop: DWORD) -> INT ---
	StretchBlt            :: proc(hdcDest: HDC, xDest, yDest, wDest, hDest: INT, hdcSrc: HDC, xSrc, ySrc, wSrc, hSrc: INT, rop: DWORD) -> BOOL ---
	GetStretchBltMode     :: proc(hdc: HDC) -> c_int ---
	SetStretchBltMode     :: proc(hdc: HDC, mode: c_int) -> c_int ---

	GetPixel            :: proc(hdc: HDC, x, y: c_int) -> COLORREF ---
	SetPixel            :: proc(hdc: HDC, x, y: c_int, color: COLORREF) -> COLORREF ---
	SetPixelV           :: proc(hdc: HDC, x, y: c_int, color: COLORREF) -> BOOL ---

	GetPixelFormat      :: proc(hdc: HDC) -> c_int ---
	SetPixelFormat      :: proc(hdc: HDC, format: INT, ppfd: ^PIXELFORMATDESCRIPTOR) -> BOOL ---
	ChoosePixelFormat   :: proc(hdc: HDC, ppfd: ^PIXELFORMATDESCRIPTOR) -> INT ---
	DescribePixelFormat :: proc(hdc: HDC, iPixelFormat: INT, nBytes: UINT, ppfd: ^PIXELFORMATDESCRIPTOR) -> INT ---
	SwapBuffers         :: proc(hdc: HDC) -> BOOL ---

	SetDCBrushColor :: proc(hdc: HDC, color: COLORREF) -> COLORREF ---
	GetDCBrushColor :: proc(hdc: HDC) -> COLORREF ---
	PatBlt          :: proc(hdc: HDC, x, y, w, h: INT, rop: DWORD) -> BOOL ---

	CreateFontW           :: proc(cHeight, cWidth, cEscapement, cOrientation, cWeight: INT, bItalic, bUnderline, bStrikeOut, iCharSet, iOutPrecision: DWORD, iClipPrecision, iQuality, iPitchAndFamily: DWORD, pszFaceName: LPCWSTR) -> HFONT ---
	CreateFontIndirectW   :: proc(lplf: ^LOGFONTW) -> HFONT ---
	CreateFontIndirectExW :: proc(unnamedParam1: ^ENUMLOGFONTEXDVW) -> HFONT ---
	AddFontResourceW      :: proc(unnamedParam1: LPCWSTR) -> INT ---
	AddFontResourceExW    :: proc(name: LPCWSTR, fl: DWORD, res: PVOID) -> INT ---
	AddFontMemResourceEx  :: proc(pFileView: PVOID, cjSize: DWORD, pvResrved: PVOID, pNumFonts: ^DWORD) -> HANDLE ---
	EnumFontsW            :: proc(hdc: HDC, lpLogfont: LPCWSTR, lpProc: FONTENUMPROCW, lParam: LPARAM) -> INT ---
	EnumFontFamiliesW     :: proc(hdc: HDC, lpLogfont: LPCWSTR, lpProc: FONTENUMPROCW, lParam: LPARAM) -> INT ---
	EnumFontFamiliesExW   :: proc(hdc: HDC, lpLogfont: LPLOGFONTW, lpProc: FONTENUMPROCW, lParam: LPARAM, dwFlags: DWORD) -> INT ---

	TextOutW              :: proc(hdc: HDC, x, y: INT, lpString: LPCWSTR, c: INT) -> BOOL ---
	GetTextExtentPoint32W :: proc(hdc: HDC, lpString: LPCWSTR, c: INT, psizl: LPSIZE) -> BOOL ---
	GetTextMetricsW       :: proc(hdc: HDC, lptm: LPTEXTMETRICW) -> BOOL ---

	CreateSolidBrush :: proc(color: COLORREF) -> HBRUSH ---

	GetObjectW             :: proc(h: HANDLE, c: INT, pv: LPVOID) -> c_int ---
	CreateCompatibleBitmap :: proc(hdc: HDC, cx, cy: INT) -> HBITMAP ---
	BitBlt                 :: proc(hdc: HDC, x, y, cx, cy: INT, hdcSrc: HDC, x1, y1: INT, rop: DWORD) -> BOOL ---
	GetDIBits              :: proc(hdc: HDC, hbm: HBITMAP, start, cLines: UINT, lpvBits: LPVOID, lpbmi: ^BITMAPINFO, usage: UINT) -> INT ---
	SetDIBits              :: proc(hdc: HDC, hbm: HBITMAP, start: UINT, cLines: UINT, lpBits: PVOID, lpbmi: ^BITMAPINFO, ColorUse: UINT) -> INT ---
	SetDIBColorTable       :: proc(hdc: HDC, iStart: UINT, cEntries: UINT, prgbq: ^RGBQUAD) -> UINT ---
	GetDIBColorTable       :: proc(hdc: HDC, iStart: UINT, cEntries: UINT, prgbq: ^RGBQUAD) -> UINT ---

	CreatePen     :: proc(iStyle, cWidth: INT, color: COLORREF) -> HPEN ---
	ExtCreatePen  :: proc(iPenStyle, cWidth: DWORD, plbrush: ^LOGBRUSH, cStyle: DWORD, pstyle: ^DWORD) -> HPEN ---
	SetDCPenColor :: proc(hdc: HDC, color: COLORREF) -> COLORREF ---
	GetDCPenColor :: proc(hdc: HDC) -> COLORREF ---

	CreatePalette  :: proc(plpal: ^LOGPALETTE) -> HPALETTE ---
	SelectPalette  :: proc(hdc: HDC, hPal: HPALETTE, bForceBkgd: BOOL) -> HPALETTE ---
	RealizePalette :: proc(hdc: HDC) -> UINT ---

	GetTextColor :: proc(hdc: HDC) -> COLORREF ---
	SetTextColor :: proc(hdc: HDC, color: COLORREF) -> COLORREF ---

	GdiTransparentBlt :: proc(hdcDest: HDC, xoriginDest, yoriginDest, wDest, hDest: INT, hdcSrc: HDC, xoriginSrc, yoriginSrc, wSrc, hSrc: INT, crTransparent: UINT) -> BOOL ---
	GdiGradientFill   :: proc(hdc: HDC, pVertex: PTRIVERTEX, nVertex: ULONG, pMesh: PVOID, nCount: ULONG, ulMode: ULONG) -> BOOL ---
	GdiAlphaBlend     :: proc(hdcDest: HDC, xoriginDest, yoriginDest, wDest, hDest: INT, hdcSrc: HDC, xoriginSrc, yoriginSrc, wSrc, hSrc: INT, ftn: BLENDFUNCTION) -> BOOL ---

	// Filled Shape Functions
	Rectangle   :: proc(hdc: HDC, left, top, right, bottom: c_int) -> BOOL ---
	Ellipse     :: proc(hdc: HDC, left, top, right, bottom: c_int) -> BOOL ---
	RoundRect   :: proc(hdc: HDC, left, top, right, bottom, width, height: c_int) -> BOOL ---
	Pie         :: proc(hdc: HDC, left, right, top, bottom, xr1, yr1, xr2, yr2: c_int) -> BOOL ---
	Chord       :: proc(hdc: HDC, x1, y1, x2, y2, x3, y3, x4, y4: c_int) -> BOOL ---
	Polygon     :: proc(hdc: HDC, apt: [^]POINT, cpt: c_int) -> BOOL ---
	PolyPolygon :: proc(hdc: HDC, apt: [^]POINT, asz: [^]c_int, csz: c_int) -> BOOL ---

	// Line Drawing Functions
	MoveToEx   :: proc(hdc: HDC, x: i32, y: i32, lppt: ^POINT) -> BOOL ---
	LineTo     :: proc(hdc: HDC, x: i32, y: i32) -> BOOL ---
	PolylineTo :: proc(hdc: HDC, apt: [^]POINT, cpt: DWORD) -> BOOL ---

	// Color Space Functions
	SetICMMode           :: proc(hdc: HDC, mode: c_int) -> c_int ---
	CheckColorsInGamut   :: proc(hdc: HDC, lpRGBTriple: ^RGBTRIPLE, dlpBuffer: LPVOID, nCount: DWORD) -> BOOL ---
	GetColorSpace        :: proc(hdc: HDC) -> HCOLORSPACE ---
	SetColorSpace        :: proc(hdc: HDC, hcs: HCOLORSPACE) -> HCOLORSPACE ---
	GetLogColorSpaceW    :: proc(hColorSpace: HCOLORSPACE, lpBuffer: ^LOGCOLORSPACEW, nSize: WORD) -> BOOL ---
	CreateColorSpaceW    :: proc(lplcs: ^LOGCOLORSPACEW) -> HCOLORSPACE ---
	DeleteColorSpace     :: proc(hcs: HCOLORSPACE) -> BOOL ---
	GetICMProfileW       :: proc(hdc: HDC, pBufSize: LPDWORD, pszFilename: LPWSTR) -> BOOL ---
	SetICMProfileW       :: proc(hdc: HDC, lpFileName: LPWSTR) -> BOOL ---
	GetDeviceGammaRamp   :: proc(hdc: HDC, lpRamp: LPVOID) -> BOOL --- // Writes `(3 * 256 * 2)` bytes to `lpRamp`.
	SetDeviceGammaRamp   :: proc(hdc: HDC, lpRamp: LPVOID) -> BOOL --- // Reads `(3 * 256 * 2)` bytes from `lpRamp`.
	ColorMatchToTarget   :: proc(hdc: HDC, hdcTarget: HDC, action: DWORD) -> BOOL ---
	EnumICMProfilesW     :: proc(hdc: HDC, p: ICMENUMPROCW, param: LPARAM) -> c_int ---
	UpdateICMRegKeyW     :: proc(reserved: DWORD, lpszCMID: LPWSTR, lpszFileName: LPWSTR, command: UINT) -> BOOL ---
	ColorCorrectPalette  :: proc(hdc: HDC, hPal: HPALETTE, deFirst: DWORD, num: DWORD) -> BOOL ---
}

@(require_results)
RGB :: #force_inline proc "contextless" (#any_int r, g, b: int) -> COLORREF {
	return COLORREF(DWORD(BYTE(r)) | (DWORD(BYTE(g)) << 8) | (DWORD(BYTE(b)) << 16))
}

@(require_results)
PALETTERGB :: #force_inline proc "contextless" (#any_int r, g, b: int) -> COLORREF {
	return 0x02000000 | RGB(r, g, b)
}

@(require_results)
PALETTEINDEX :: #force_inline proc "contextless" (#any_int i: int) -> COLORREF {
	return COLORREF(DWORD(0x01000000) | DWORD(WORD(i)))
}

// Device Parameters for `GetDeviceCaps()`

DRIVERVERSION    :: 0     // Device driver version
TECHNOLOGY       :: 2     // Device classification
HORZSIZE         :: 4     // Horizontal size in millimeters
VERTSIZE         :: 6     // Vertical size in millimeters
HORZRES          :: 8     // Horizontal width in pixels
VERTRES          :: 10    // Vertical height in pixels
BITSPIXEL        :: 12    // Number of bits per pixel
PLANES           :: 14    // Number of planes
NUMBRUSHES       :: 16    // Number of brushes the device has
NUMPENS          :: 18    // Number of pens the device has
NUMMARKERS       :: 20    // Number of markers the device has
NUMFONTS         :: 22    // Number of fonts the device has
NUMCOLORS        :: 24    // Number of colors the device supports
PDEVICESIZE      :: 26    // Size required for device descriptor
CURVECAPS        :: 28    // Curve capabilities
LINECAPS         :: 30    // Line capabilities
POLYGONALCAPS    :: 32    // Polygonal capabilities
TEXTCAPS         :: 34    // Text capabilities
CLIPCAPS         :: 36    // Clipping capabilities
RASTERCAPS       :: 38    // Bitblt capabilities
ASPECTX          :: 40    // Length of the X leg
ASPECTY          :: 42    // Length of the Y leg
ASPECTXY         :: 44    // Length of the hypotenuse

LOGPIXELSX       :: 88    // Logical pixels/inch in X
LOGPIXELSY       :: 90    // Logical pixels/inch in Y

SIZEPALETTE      :: 104   // Number of entries in physical palette
NUMRESERVED      :: 106   // Number of reserved entries in palette
COLORRES         :: 108   // Actual color resolution

// Printing related DeviceCaps. These replace the appropriate Escapes

PHYSICALWIDTH    :: 110   // Physical Width in device units
PHYSICALHEIGHT   :: 111   // Physical Height in device units
PHYSICALOFFSETX  :: 112   // Physical Printable Area x margin
PHYSICALOFFSETY  :: 113   // Physical Printable Area y margin
SCALINGFACTORX   :: 114   // Scaling factor x
SCALINGFACTORY   :: 115   // Scaling factor y

// Display driver specific

VREFRESH         :: 116   // Current vertical refresh rate of the display device (for displays only) in Hz
DESKTOPVERTRES   :: 117   // Horizontal width of entire desktop in pixels
DESKTOPHORZRES   :: 118   // Vertical height of entire desktop in pixels
BLTALIGNMENT     :: 119   // Preferred blt alignment

SHADEBLENDCAPS   :: 120   // Shading and blending caps
COLORMGMTCAPS    :: 121   // Color Management caps

FXPT16DOT16 :: distinct i32 // fixed.Fixed(i32, 16)
FXPT2DOT30  :: distinct i32 // fixed.Fixed(i32, 30)

CIEXYZ :: struct {
	ciexyzX, ciexyzY, ciexyzZ: FXPT2DOT30,
}

CIEXYZTRIPLE :: struct {
	ciexyzRed, ciexyzGreen, ciexyzBlue: CIEXYZ,
}

BITMAPCOREHEADER :: struct {
	bcSize:      DWORD, // used to get to color table
	bcWidth:     WORD,
	bcHeight:    WORD,
	bcPlanes:    WORD,
	bcBitCount:  WORD,
}

BITMAPCOREINFO :: struct($num_color_table_entries: int) {
	bmciHeader:  BITMAPCOREHEADER,
	bmciColors:  [num_color_table_entries]RGBTRIPLE,
}

BITMAPFILEHEADER :: struct {
	bfType:       WORD,
	bfSize:       DWORD,
	bfReserved1:  WORD,
	bfReserved2:  WORD,
	bfOffBits:    DWORD,
}

BITMAPV4HEADER :: struct {
	bV4Size:           DWORD,
	bV4Width:          LONG,
	bV4Height:         LONG,
	bV4Planes:         WORD,
	bV4BitCount:       WORD,
	bV4V4Compression:  DWORD,
	bV4SizeImage:      DWORD,
	bV4XPelsPerMeter:  LONG,
	bV4YPelsPerMeter:  LONG,
	bV4ClrUsed:        DWORD,
	bV4ClrImportant:   DWORD,
	bV4RedMask:        DWORD,
	bV4GreenMask:      DWORD,
	bV4BlueMask:       DWORD,
	bV4AlphaMask:      DWORD,
	bV4CSType:         DWORD,
	bV4Endpoints:      CIEXYZTRIPLE,
	bV4GammaRed:       DWORD,
	bV4GammaGreen:     DWORD,
	bV4GammaBlue:      DWORD,
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

// Values for `bV5CSType`

PROFILE_LINKED                   :: 0x4C494E4B // 'LINK'
PROFILE_EMBEDDED                 :: 0x4D424544 // 'MBED'

ICM_OFF                          :: 1
ICM_ON                           :: 2
ICM_QUERY                        :: 3
ICM_DONE_OUTSIDEDC               :: 4

ICMENUMPROCW :: #type proc "system" (name: LPWSTR, lparam: LPARAM) -> c_int

// Image Color Matching color definitions

CS_ENABLE                        :: 0x00000001
CS_DISABLE                       :: 0x00000002
CS_DELETE_TRANSFORM              :: 0x00000003

// Logcolorspace signature

LCS_SIGNATURE                    :: 0x50534F43 // 'PSOC'

// Logcolorspace lcsType values

LCS_sRGB                         :: 0x73524742 // 'sRGB'
LCS_WINDOWS_COLOR_SPACE          :: 0x57696E20 // 'Win ' - Windows default color space

LCSCSTYPE :: #type LONG

LCS_CALIBRATED_RGB               :: 0x00000000

LCSGAMUTMATCH :: #type LONG

LCS_GM_BUSINESS                  :: 0x00000001
LCS_GM_GRAPHICS                  :: 0x00000002
LCS_GM_IMAGES                    :: 0x00000004
LCS_GM_ABS_COLORIMETRIC          :: 0x00000008

// ICM Defines for results from `CheckColorInGamut()`

CM_OUT_OF_GAMUT                  :: 255
CM_IN_GAMUT                      :: 0

// `UpdateICMRegKey` Constants

ICM_ADDPROFILE                   :: 1
ICM_DELETEPROFILE                :: 2
ICM_QUERYPROFILE                 :: 3
ICM_SETDEFAULTPROFILE            :: 4
ICM_REGISTERICMATCHER            :: 5
ICM_UNREGISTERICMATCHER          :: 6
ICM_QUERYMATCH                   :: 7

// Macros to retrieve CMYK values from a `COLORREF`

GetKValue :: #force_inline proc "contextless" (cmyk: COLORREF) -> BYTE { return cast(BYTE)(cmyk      ) }
GetYValue :: #force_inline proc "contextless" (cmyk: COLORREF) -> BYTE { return cast(BYTE)(cmyk >>  8) }
GetMValue :: #force_inline proc "contextless" (cmyk: COLORREF) -> BYTE { return cast(BYTE)(cmyk >> 16) }
GetCValue :: #force_inline proc "contextless" (cmyk: COLORREF) -> BYTE { return cast(BYTE)(cmyk >> 24) }

CMYK :: #force_inline proc "contextless" (c, m, y, k: BYTE) -> COLORREF {
	return cast(DWORD)k | cast(DWORD)y << 8 | cast(DWORD)m << 16 | cast(DWORD)c << 24
}

LOGCOLORSPACEW :: struct {
	lcsSignature:   DWORD,
	lcsVersion:     DWORD,
	lcsSize:        DWORD,
	lcsCSType:      LCSCSTYPE,
	lcsIntent:      LCSGAMUTMATCH,
	lcsEndpoints:   CIEXYZTRIPLE,
	lcsGammaRed:    DWORD,
	lcsGammaGreen:  DWORD,
	lcsGammaBlue:   DWORD,
	lcsFilename:    [MAX_PATH]WCHAR,
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

ICONINFO :: struct {
	fIcon:              BOOL,
	xHotspot, yHotspot: DWORD,
	hbmMask, hbmColor:  HBITMAP,
}
PICONINFO :: ^ICONINFO

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

AC_SRC_OVER  :: 0x00
AC_SRC_ALPHA :: 0x01

TransparentBlt :: GdiTransparentBlt
GradientFill   :: GdiGradientFill
AlphaBlend     :: GdiAlphaBlend

COLOR16 :: USHORT
TRIVERTEX :: struct {
	x:     LONG,
	y:     LONG,
	Red:   COLOR16,
	Green: COLOR16,
	Blue:  COLOR16,
	Alpha: COLOR16,
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
	BlendOp:             BYTE,
	BlendFlags:          BYTE,
	SourceConstantAlpha: BYTE,
	AlphaFormat:         BYTE,
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
HS_HORIZONTAL    :: 0       /* `-----` */
HS_VERTICAL      :: 1       /* `|||||` */
HS_FDIAGONAL     :: 2       /* `\\\\\` */
HS_BDIAGONAL     :: 3       /* `/////` */
HS_CROSS         :: 4       /* `+++++` */
HS_DIAGCROSS     :: 5       /* `xxxxx` */
HS_API_MAX       :: 12

/* Pen Styles */
PS_SOLID         ::  0
PS_DASH          ::  1      /* `-------` */
PS_DOT           ::  2      /* `.......` */
PS_DASHDOT       ::  3      /* `_._._._` */
PS_DASHDOTDOT    ::  4      /* `_.._.._` */
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

/* New StretchBlt() Modes */
STRETCH_ANDSCANS     :: BLACKONWHITE
STRETCH_DELETESCANS  :: COLORONCOLOR
STRETCH_HALFTONE     :: HALFTONE
STRETCH_ORSCANS      :: WHITEONBLACK

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

FONTENUMPROCW :: #type proc "system" (lpelf: ^ENUMLOGFONTW, lpntm: ^NEWTEXTMETRICW, FontType: DWORD, lParam: LPARAM) -> INT
