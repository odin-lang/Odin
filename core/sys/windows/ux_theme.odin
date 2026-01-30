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
	GetWindowTheme :: proc(hwnd: HWND) -> HTHEME ---
	SetWindowTheme :: proc(hWnd: HWND, pszSubAppName, pszSubIdList: LPCWSTR) -> HRESULT ---

	// Buffered painting and buffered animation
	BufferedPaintInit   :: proc() -> HRESULT ---
	BufferedPaintUnInit :: proc() -> HRESULT ---

	BeginBufferedPaint :: proc(hdcTarget: HDC, prcTarget: ^RECT, dwFormat: BP_BUFFERFORMAT, pPaintParams: ^BP_PAINTPARAMS, phdc: ^HDC) -> HPAINTBUFFER ---
	EndBufferedPaint   :: proc(hBufferedPaint: HPAINTBUFFER, fUpdateTarget: BOOL) -> HRESULT ---

	GetBufferedPaintTargetRect :: proc(hBufferedPaint: HPAINTBUFFER, prc: ^RECT) -> HRESULT ---
	GetBufferedPaintTargetDC   :: proc(hBufferedPaint: HPAINTBUFFER) -> HDC ---
	GetBufferedPaintDC         :: proc(hBufferedPaint: HPAINTBUFFER) -> HDC ---
	GetBufferedPaintBits       :: proc(hBufferedPaint, ppbBuffer: ^[^]RGBQUAD, pcxRow: ^c_int) -> HRESULT ---

	BufferedPaintClear    :: proc(hBufferedPaint: HPAINTBUFFER, prc: ^RECT) -> HRESULT ---
	BufferedPaintSetAlpha :: proc(hBufferedPaint: HPAINTBUFFER, prc: ^RECT, alpha: BYTE) -> HRESULT ---

	BufferedPaintStopAllAnimations :: proc(hwnd: HWND) -> HRESULT ---
	BeginBufferedAnimation         :: proc(hwnd: HWND, hdcTarget: HDC, prcTarget: ^RECT, dwFormat: BP_BUFFERFORMAT, pPaintParams: ^BP_PAINTPARAMS, pAnimationParams: ^BP_ANIMATIONPARAMS, phdcFrom: ^HDC, phdcTo: ^HDC) -> HANIMATIONBUFFER ---
	BufferedPaintRenderAnimation   :: proc(hwnd: HWND, hdcTarget: HDC) -> BOOL ---
}

HTHEME           :: distinct HANDLE
HPAINTBUFFER     :: distinct HANDLE
HANIMATIONBUFFER :: distinct HANDLE

BP_BUFFERFORMAT :: enum c_int {
	BPBF_COMPATIBLEBITMAP,
	BPBF_DIB,
	BPBF_TOPDOWNDIB,
	BPBF_TOPDOWNMONODIB,
}

BP_ANIMATIONSTYLE :: enum c_int {
	BPAS_NONE,
	BPAS_LINEAR,
	BPAS_CUBIC,
	BPAS_SINE,
}

// Constants for BP_PAINTPARAMS.dwFlags
BPPF_ERASE              :: 0x0001
BPPF_NOCLIP             :: 0x0002
BPPF_NONCLIENT          :: 0x0004

BP_ANIMATIONPARAMS :: struct {
	cbSize:     DWORD,
	dwFlags:    DWORD,
	style:      BP_ANIMATIONSTYLE,
	dwDuration: DWORD,
}

BP_PAINTPARAMS :: struct {
	cbSize:         DWORD,
	dwFlags:        DWORD,
	prcExclude:     ^RECT,
	pBlendFunction: ^BLENDFUNCTION,
}
