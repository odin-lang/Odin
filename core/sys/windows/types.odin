// +build windows
package sys_windows

import "core:c"

c_char     :: c.char
c_uchar    :: c.uchar
c_int      :: c.int
c_uint     :: c.uint
c_long     :: c.long
c_longlong :: c.longlong
c_ulong    :: c.ulong
c_short    :: c.short
c_ushort   :: c.ushort
size_t     :: c.size_t
wchar_t    :: c.wchar_t

DWORD :: c_ulong
HANDLE :: distinct LPVOID
HINSTANCE :: HANDLE
HMODULE :: distinct HINSTANCE
HRESULT :: distinct LONG
HWND :: distinct HANDLE
HDC :: distinct HANDLE
HMONITOR :: distinct HANDLE
HICON :: distinct HANDLE
HCURSOR :: distinct HANDLE
HMENU :: distinct HANDLE
HBRUSH :: distinct HANDLE
HGDIOBJ :: distinct HANDLE
HBITMAP :: distinct HANDLE
HGLOBAL :: distinct HANDLE
BOOL :: distinct b32
BYTE :: distinct u8
BOOLEAN :: distinct b8
GROUP :: distinct c_uint
LARGE_INTEGER :: distinct c_longlong
LONG :: c_long
UINT :: c_uint
INT  :: c_int
SHORT :: c_short
USHORT :: c_ushort
WCHAR :: wchar_t
SIZE_T :: uint
PSIZE_T :: ^SIZE_T
WORD :: u16
CHAR :: c_char
ULONG_PTR :: uint
PULONG_PTR :: ^ULONG_PTR
LPULONG_PTR :: ^ULONG_PTR
DWORD_PTR :: ULONG_PTR
LONG_PTR :: int
UINT_PTR :: uintptr
ULONG :: c_ulong
UCHAR :: BYTE
NTSTATUS :: c.long
LPARAM :: LONG_PTR
WPARAM :: UINT_PTR
LRESULT :: LONG_PTR
LPRECT :: ^RECT

UINT8  ::  u8
UINT16 :: u16
UINT32 :: u32
UINT64 :: u64

INT8  ::  i8
INT16 :: i16
INT32 :: i32
INT64 :: i64


ULONG64 :: u64
LONG64  :: i64

PDWORD_PTR :: ^DWORD_PTR
ATOM :: distinct WORD

wstring :: [^]WCHAR

PBYTE :: ^BYTE
LPBYTE :: ^BYTE
PBOOL :: ^BOOL
LPBOOL :: ^BOOL
LPCSTR :: cstring
LPCWSTR :: wstring
LPCTSTR :: wstring
LPDWORD :: ^DWORD
PCSTR :: cstring
PCWSTR :: wstring
PDWORD :: ^DWORD
LPHANDLE :: ^HANDLE
LPOVERLAPPED :: ^OVERLAPPED
LPPROCESS_INFORMATION :: ^PROCESS_INFORMATION
PSECURITY_ATTRIBUTES :: ^SECURITY_ATTRIBUTES
LPSECURITY_ATTRIBUTES :: ^SECURITY_ATTRIBUTES
LPSTARTUPINFO :: ^STARTUPINFO
VOID :: rawptr
PVOID :: rawptr
LPVOID :: rawptr
PINT :: ^INT
LPINT :: ^INT
PUINT :: ^UINT
LPUINT :: ^UINT
LPWCH :: ^WCHAR
LPWORD :: ^WORD
PULONG :: ^ULONG
LPWIN32_FIND_DATAW :: ^WIN32_FIND_DATAW
LPWSADATA :: ^WSADATA
LPWSAPROTOCOL_INFO :: ^WSAPROTOCOL_INFO
LPSTR :: ^CHAR
LPWSTR :: ^WCHAR
LPFILETIME :: ^FILETIME
LPWSABUF :: ^WSABUF
LPWSAOVERLAPPED :: distinct rawptr
LPWSAOVERLAPPED_COMPLETION_ROUTINE :: distinct rawptr
LPCVOID :: rawptr

PCONDITION_VARIABLE :: ^CONDITION_VARIABLE
PLARGE_INTEGER :: ^LARGE_INTEGER
PSRWLOCK :: ^SRWLOCK

SOCKET :: distinct uintptr // TODO
socklen_t :: c_int
ADDRESS_FAMILY :: USHORT

TRUE  :: BOOL(true)
FALSE :: BOOL(false)

SIZE :: struct {
	cx: LONG,
	cy: LONG,
}
PSIZE  :: ^SIZE
LPSIZE :: ^SIZE

FILE_ATTRIBUTE_READONLY: DWORD : 0x00000001
FILE_ATTRIBUTE_HIDDEN: DWORD : 0x00000002
FILE_ATTRIBUTE_SYSTEM: DWORD : 0x00000004
FILE_ATTRIBUTE_DIRECTORY: DWORD : 0x00000010
FILE_ATTRIBUTE_ARCHIVE: DWORD : 0x00000020
FILE_ATTRIBUTE_DEVICE: DWORD : 0x00000040
FILE_ATTRIBUTE_NORMAL: DWORD : 0x00000080
FILE_ATTRIBUTE_TEMPORARY: DWORD : 0x00000100
FILE_ATTRIBUTE_SPARSE_FILE: DWORD : 0x00000200
FILE_ATTRIBUTE_REPARSE_Point: DWORD : 0x00000400
FILE_ATTRIBUTE_REPARSE_POINT: DWORD : 0x00000400
FILE_ATTRIBUTE_COMPRESSED: DWORD : 0x00000800
FILE_ATTRIBUTE_OFFLINE: DWORD : 0x00001000
FILE_ATTRIBUTE_NOT_CONTENT_INDEXED: DWORD : 0x00002000
FILE_ATTRIBUTE_ENCRYPTED: DWORD : 0x00004000

FILE_SHARE_READ: DWORD : 0x00000001
FILE_SHARE_WRITE: DWORD : 0x00000002
FILE_SHARE_DELETE: DWORD : 0x00000004
FILE_GENERIC_ALL: DWORD : 0x10000000
FILE_GENERIC_EXECUTE: DWORD : 0x20000000
FILE_GENERIC_READ: DWORD : 0x80000000

CREATE_NEW: DWORD : 1
CREATE_ALWAYS: DWORD : 2
OPEN_ALWAYS: DWORD : 4
OPEN_EXISTING: DWORD : 3
TRUNCATE_EXISTING: DWORD : 5



FILE_WRITE_DATA: DWORD : 0x00000002
FILE_APPEND_DATA: DWORD : 0x00000004
FILE_WRITE_EA: DWORD : 0x00000010
FILE_WRITE_ATTRIBUTES: DWORD : 0x00000100
READ_CONTROL: DWORD : 0x00020000
SYNCHRONIZE: DWORD : 0x00100000
GENERIC_READ: DWORD : 0x80000000
GENERIC_WRITE: DWORD : 0x40000000
STANDARD_RIGHTS_WRITE: DWORD : READ_CONTROL
FILE_GENERIC_WRITE: DWORD : STANDARD_RIGHTS_WRITE |
	FILE_WRITE_DATA |
	FILE_WRITE_ATTRIBUTES |
	FILE_WRITE_EA |
	FILE_APPEND_DATA |
	SYNCHRONIZE

FILE_FLAG_OPEN_REPARSE_POINT: DWORD : 0x00200000
FILE_FLAG_BACKUP_SEMANTICS: DWORD : 0x02000000
SECURITY_SQOS_PRESENT: DWORD : 0x00100000

FIONBIO: c_ulong : 0x8004667e


GET_FILEEX_INFO_LEVELS :: distinct i32
GetFileExInfoStandard: GET_FILEEX_INFO_LEVELS : 0
GetFileExMaxInfoLevel: GET_FILEEX_INFO_LEVELS : 1


WNDPROC :: #type proc "stdcall" (HWND, UINT, WPARAM, LPARAM) -> LRESULT

WNDCLASSA :: struct {
	style: UINT,
	lpfnWndProc: WNDPROC,
	cbClsExtra: c_int,
	cbWndExtra: c_int,
	hInstance: HINSTANCE,
	hIcon: HICON,
	hCursor: HCURSOR,
	hbrBackground: HBRUSH,
	lpszMenuName: LPCSTR,
	lpszClassName: LPCSTR,
}

WNDCLASSW :: struct {
	style: UINT,
	lpfnWndProc: WNDPROC,
	cbClsExtra: c_int,
	cbWndExtra: c_int,
	hInstance: HINSTANCE,
	hIcon: HICON,
	hCursor: HCURSOR,
	hbrBackground: HBRUSH,
	lpszMenuName: LPCWSTR,
	lpszClassName: LPCWSTR,
}

WNDCLASSEXA :: struct {
	cbSize: UINT,
	style: UINT,
	lpfnWndProc: WNDPROC,
	cbClsExtra: c_int,
	cbWndExtra: c_int,
	hInstance: HINSTANCE,
	hIcon: HICON,
	hCursor: HCURSOR,
	hbrBackground: HBRUSH,
	lpszMenuName: LPCSTR,
	lpszClassName: LPCSTR,
	hIconSm: HICON,
}

WNDCLASSEXW :: struct {
	cbSize: UINT,
	style: UINT,
	lpfnWndProc: WNDPROC,
	cbClsExtra: c_int,
	cbWndExtra: c_int,
	hInstance: HINSTANCE,
	hIcon: HICON,
	hCursor: HCURSOR,
	hbrBackground: HBRUSH,
	lpszMenuName: LPCWSTR,
	lpszClassName: LPCWSTR,
	hIconSm: HICON,
}

MSG :: struct {
	hwnd: HWND,
	message: UINT,
	wParam: WPARAM,
	lParam: LPARAM,
	time: DWORD,
	pt: POINT,
}

PAINTSTRUCT :: struct {
	hdc: HDC,
	fErase: BOOL,
	rcPaint: RECT,
	fRestore: BOOL,
	fIncUpdate: BOOL,
	rgbReserved: [32]BYTE,
}

WIN32_FIND_DATAW :: struct {
	dwFileAttributes: DWORD,
	ftCreationTime: FILETIME,
	ftLastAccessTime: FILETIME,
	ftLastWriteTime: FILETIME,
	nFileSizeHigh: DWORD,
	nFileSizeLow: DWORD,
	dwReserved0: DWORD,
	dwReserved1: DWORD,
	cFileName: [260]wchar_t, // #define MAX_PATH 260
	cAlternateFileName: [14]wchar_t,
}

CREATESTRUCTA :: struct {
	lpCreateParams: LPVOID,
	hInstance:      HINSTANCE,
	hMenu:          HMENU,
	hwndParent:     HWND,
	cy:             c_int,
	cx:             c_int,
	y:              c_int,
	x:              c_int,
	style:          LONG,
	lpszName:       LPCSTR,
	lpszClass:      LPCSTR,
	dwExStyle:      DWORD,
}

CREATESTRUCTW:: struct {
	lpCreateParams: LPVOID,
	hInstance:      HINSTANCE,
	hMenu:          HMENU,
	hwndParent:     HWND,
	cy:             c_int,
	cx:             c_int,
	y:              c_int,
	x:              c_int,
	style:          LONG,
	lpszName:       LPCWSTR,
	lpszClass:      LPCWSTR,
	dwExStyle:      DWORD,
}

CS_VREDRAW         : UINT : 0x0001
CS_HREDRAW         : UINT : 0x0002
CS_DBLCLKS         : UINT : 0x0008
CS_OWNDC           : UINT : 0x0020
CS_CLASSDC         : UINT : 0x0040
CS_PARENTDC        : UINT : 0x0080
CS_NOCLOSE         : UINT : 0x0200
CS_SAVEBITS        : UINT : 0x0800
CS_BYTEALIGNCLIENT : UINT : 0x1000
CS_BYTEALIGNWINDOW : UINT : 0x2000
CS_GLOBALCLASS     : UINT : 0x4000
CS_DROPSHADOW      : UINT : 0x0002_0000

GWL_EXSTYLE    : c_int : -20
GWLP_HINSTANCE : c_int : -6
GWLP_ID        : c_int : -12
GWL_STYLE      : c_int : -16
GWLP_USERDATA  : c_int : -21
GWLP_WNDPROC   : c_int : -4

WS_BORDER           : UINT : 0x0080_0000
WS_CAPTION          : UINT : 0x00C0_0000
WS_CHILD            : UINT : 0x4000_0000
WS_CHILDWINDOW      : UINT : WS_CHILD
WS_CLIPCHILDREN     : UINT : 0x0200_0000
WS_CLIPSIBLINGS     : UINT : 0x0400_0000
WS_DISABLED         : UINT : 0x0800_0000
WS_DLGFRAME         : UINT : 0x0040_0000
WS_GROUP            : UINT : 0x0002_0000
WS_HSCROLL          : UINT : 0x0010_0000
WS_ICONIC           : UINT : 0x2000_0000
WS_MAXIMIZE         : UINT : 0x0100_0000
WS_MAXIMIZEBOX      : UINT : 0x0001_0000
WS_MINIMIZE         : UINT : 0x2000_0000
WS_MINIMIZEBOX      : UINT : 0x0002_0000
WS_OVERLAPPED       : UINT : 0x0000_0000
WS_OVERLAPPEDWINDOW : UINT : WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX
WS_POPUP			: UINT : 0x8000_0000
WS_POPUPWINDOW      : UINT : WS_POPUP | WS_BORDER | WS_SYSMENU
WS_SIZEBOX          : UINT : 0x0004_0000
WS_SYSMENU          : UINT : 0x0008_0000
WS_TABSTOP          : UINT : 0x0001_0000
WS_THICKFRAME       : UINT : 0x0004_0000
WS_TILED            : UINT : 0x0000_0000
WS_TILEDWINDOW      : UINT : WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_THICKFRAME | WS_MINIMIZE | WS_MAXIMIZE
WS_VISIBLE          : UINT : 0x1000_0000
WS_VSCROLL          : UINT : 0x0020_0000

QS_ALLEVENTS      : UINT : QS_INPUT | QS_POSTMESSAGE | QS_TIMER | QS_PAINT | QS_HOTKEY
QS_ALLINPUT       : UINT : QS_INPUT | QS_POSTMESSAGE | QS_TIMER | QS_PAINT | QS_HOTKEY | QS_SENDMESSAGE
QS_ALLPOSTMESSAGE : UINT : 0x0100
QS_HOTKEY         : UINT : 0x0080
QS_INPUT          : UINT : QS_MOUSE | QS_KEY | QS_RAWINPUT
QS_KEY            : UINT : 0x0001
QS_MOUSE          : UINT : QS_MOUSEMOVE | QS_MOUSEBUTTON
QS_MOUSEBUTTON    : UINT : 0x0004
QS_MOUSEMOVE      : UINT : 0x0002
QS_PAINT          : UINT : 0x0020
QS_POSTMESSAGE    : UINT : 0x0008
QS_RAWINPUT       : UINT : 0x0400
QS_SENDMESSAGE    : UINT : 0x0040
QS_TIMER          : UINT : 0x0010

PM_NOREMOVE : UINT : 0x0000
PM_REMOVE   : UINT : 0x0001
PM_NOYIELD  : UINT : 0x0002

PM_QS_INPUT       : UINT : QS_INPUT << 16
PM_QS_PAINT       : UINT : QS_PAINT << 16
PM_QS_POSTMESSAGE : UINT : (QS_POSTMESSAGE | QS_HOTKEY | QS_TIMER) << 16
PM_QS_SENDMESSAGE : UINT : QS_SENDMESSAGE << 16

SW_HIDE            : c_int : 0
SW_SHOWNORMAL      : c_int : SW_NORMAL
SW_NORMAL          : c_int : 1
SW_SHOWMINIMIZED   : c_int : 2
SW_SHOWMAXIMIZED   : c_int : SW_MAXIMIZE
SW_MAXIMIZE        : c_int : 3
SW_SHOWNOACTIVATE  : c_int : 4
SW_SHOW            : c_int : 5
SW_MINIMIZE        : c_int : 6
SW_SHOWMINNOACTIVE : c_int : 7
SW_SHOWNA          : c_int : 8
SW_RESTORE         : c_int : 9
SW_SHOWDEFAULT     : c_int : 10
SW_FORCEMINIMIZE   : c_int : 11

// SetWindowPos Flags
SWP_NOSIZE         :: 0x0001
SWP_NOMOVE         :: 0x0002
SWP_NOZORDER       :: 0x0004
SWP_NOREDRAW       :: 0x0008
SWP_NOACTIVATE     :: 0x0010
SWP_FRAMECHANGED   :: 0x0020 // The frame changed: send WM_NCCALCSIZE
SWP_SHOWWINDOW     :: 0x0040
SWP_HIDEWINDOW     :: 0x0080
SWP_NOCOPYBITS     :: 0x0100
SWP_NOOWNERZORDER  :: 0x0200 // Don't do owner Z ordering
SWP_NOSENDCHANGING :: 0x0400 // Don't send WM_WINDOWPOSCHANGING

SWP_DRAWFRAME    :: SWP_FRAMECHANGED
SWP_NOREPOSITION :: SWP_NOOWNERZORDER

SWP_DEFERERASE     :: 0x2000 // same as SWP_DEFERDRAWING
SWP_ASYNCWINDOWPOS :: 0x4000 // same as SWP_CREATESPB

HWND_TOP       : HWND : 0
HWND_BOTTOM    : HWND : 1
HWND_TOPMOST   : HWND : -1
HWND_NOTOPMOST : HWND : -2

CW_USEDEFAULT      : c_int : -2147483648

SIZE_RESTORED  :: 0
SIZE_MINIMIZED :: 1
SIZE_MAXIMIZED :: 2
SIZE_MAXSHOW   :: 3
SIZE_MAXHIDE   :: 4

WMSZ_LEFT        :: 1
WMSZ_RIGHT       :: 2
WMSZ_TOP         :: 3
WMSZ_TOPLEFT     :: 4
WMSZ_TOPRIGHT    :: 5
WMSZ_BOTTOM      :: 6
WMSZ_BOTTOMLEFT  :: 7
WMSZ_BOTTOMRIGHT :: 8

// Key State Masks for Mouse Messages
MK_LBUTTON  :: 0x0001
MK_RBUTTON  :: 0x0002
MK_SHIFT    :: 0x0004
MK_CONTROL  :: 0x0008
MK_MBUTTON  :: 0x0010
MK_XBUTTON1 :: 0x0020
MK_XBUTTON2 :: 0x0040

_IDC_APPSTARTING := rawptr(uintptr(32650))
_IDC_ARROW       := rawptr(uintptr(32512))
_IDC_CROSS       := rawptr(uintptr(32515))
_IDC_HAND        := rawptr(uintptr(32649))
_IDC_HELP        := rawptr(uintptr(32651))
_IDC_IBEAM       := rawptr(uintptr(32513))
_IDC_ICON        := rawptr(uintptr(32641))
_IDC_NO          := rawptr(uintptr(32648))
_IDC_SIZE        := rawptr(uintptr(32640))
_IDC_SIZEALL     := rawptr(uintptr(32646))
_IDC_SIZENESW    := rawptr(uintptr(32643))
_IDC_SIZENS      := rawptr(uintptr(32645))
_IDC_SIZENWSE    := rawptr(uintptr(32642))
_IDC_SIZEWE      := rawptr(uintptr(32644))
_IDC_UPARROW     := rawptr(uintptr(32516))
_IDC_WAIT        := rawptr(uintptr(32514))

IDC_APPSTARTING := cstring(_IDC_APPSTARTING)
IDC_ARROW       := cstring(_IDC_ARROW)
IDC_CROSS       := cstring(_IDC_CROSS)
IDC_HAND        := cstring(_IDC_HAND)
IDC_HELP        := cstring(_IDC_HELP)
IDC_IBEAM       := cstring(_IDC_IBEAM)
IDC_ICON        := cstring(_IDC_ICON)
IDC_NO          := cstring(_IDC_NO)
IDC_SIZE        := cstring(_IDC_SIZE)
IDC_SIZEALL     := cstring(_IDC_SIZEALL)
IDC_SIZENESW    := cstring(_IDC_SIZENESW)
IDC_SIZENS      := cstring(_IDC_SIZENS)
IDC_SIZENWSE    := cstring(_IDC_SIZENWSE)
IDC_SIZEWE      := cstring(_IDC_SIZEWE)
IDC_UPARROW     := cstring(_IDC_UPARROW)
IDC_WAIT        := cstring(_IDC_WAIT)


_IDI_APPLICATION := rawptr(uintptr(32512))
_IDI_HAND        := rawptr(uintptr(32513))
_IDI_QUESTION    := rawptr(uintptr(32514))
_IDI_EXCLAMATION := rawptr(uintptr(32515))
_IDI_ASTERISK    := rawptr(uintptr(32516))
_IDI_WINLOGO     := rawptr(uintptr(32517))
_IDI_SHIELD      := rawptr(uintptr(32518))
IDI_APPLICATION  := cstring(_IDI_APPLICATION)
IDI_HAND         := cstring(_IDI_HAND)
IDI_QUESTION     := cstring(_IDI_QUESTION)
IDI_EXCLAMATION  := cstring(_IDI_EXCLAMATION)
IDI_ASTERISK     := cstring(_IDI_ASTERISK)
IDI_WINLOGO      := cstring(_IDI_WINLOGO)
IDI_SHIELD       := cstring(_IDI_SHIELD)
IDI_WARNING      := IDI_EXCLAMATION
IDI_ERROR        := IDI_HAND
IDI_INFORMATION  := IDI_ASTERISK


// DIB color table identifiers
DIB_RGB_COLORS :: 0
DIB_PAL_COLORS :: 1

// constants for CreateDIBitmap
CBM_INIT :: 0x04 // initialize bitmap

// Region Flags
ERROR         :: 0
NULLREGION    :: 1
SIMPLEREGION  :: 2
COMPLEXREGION :: 3
RGN_ERROR     :: ERROR

// StretchBlt() Modes
BLACKONWHITE      :: 1
WHITEONBLACK      :: 2
COLORONCOLOR      :: 3
HALFTONE          :: 4
MAXSTRETCHBLTMODE :: 4

// Binary raster ops
R2_BLACK       :: 1  // 0
R2_NOTMERGEPEN :: 2  // DPon
R2_MASKNOTPEN  :: 3  // DPna
R2_NOTCOPYPEN  :: 4  // PN
R2_MASKPENNOT  :: 5  // PDna
R2_NOT         :: 6  // Dn
R2_XORPEN      :: 7  // DPx
R2_NOTMASKPEN  :: 8  // DPan
R2_MASKPEN     :: 9  // DPa
R2_NOTXORPEN   :: 10 // DPxn
R2_NOP         :: 11 // D
R2_MERGENOTPEN :: 12 // DPno
R2_COPYPEN     :: 13 // P
R2_MERGEPENNOT :: 14 // PDno
R2_MERGEPEN    :: 15 // DPo
R2_WHITE       :: 16 // 1
R2_LAST        :: 16

// Ternary raster operations
SRCCOPY        : DWORD : 0x00CC0020 // dest = source
SRCPAINT       : DWORD : 0x00EE0086 // dest = source OR dest
SRCAND         : DWORD : 0x008800C6 // dest = source AND dest
SRCINVERT      : DWORD : 0x00660046 // dest = source XOR dest
SRCERASE       : DWORD : 0x00440328 // dest = source AND (NOT dest)
NOTSRCCOPY     : DWORD : 0x00330008 // dest = (NOT source)
NOTSRCERASE    : DWORD : 0x001100A6 // dest = (NOT src) AND (NOT dest)
MERGECOPY      : DWORD : 0x00C000CA // dest = (source AND pattern
MERGEPAINT     : DWORD : 0x00BB0226 // dest = (NOT source) OR dest
PATCOPY        : DWORD : 0x00F00021 // dest = pattern
PATPAINT       : DWORD : 0x00FB0A09 // dest = DPSnoo
PATINVERT      : DWORD : 0x005A0049 // dest = pattern XOR dest
DSTINVERT      : DWORD : 0x00550009 // dest = (NOT dest)
BLACKNESS      : DWORD : 0x00000042 // dest = BLACK
WHITENESS      : DWORD : 0x00FF0062 // dest = WHITE
NOMIRRORBITMAP : DWORD : 0x80000000 // Do not Mirror the bitmap in this call
CAPTUREBLT     : DWORD : 0x40000000 // Include layered windows

// Stock Logical Objects
WHITE_BRUSH         :: 0
LTGRAY_BRUSH        :: 1
GRAY_BRUSH          :: 2
DKGRAY_BRUSH        :: 3
BLACK_BRUSH         :: 4
NULL_BRUSH          :: 5
HOLLOW_BRUSH        :: NULL_BRUSH
WHITE_PEN           :: 6
BLACK_PEN           :: 7
NULL_PEN            :: 8
OEM_FIXED_FONT      :: 10
ANSI_FIXED_FONT     :: 11
ANSI_VAR_FONT       :: 12
SYSTEM_FONT         :: 13
DEVICE_DEFAULT_FONT :: 14
DEFAULT_PALETTE     :: 15
SYSTEM_FIXED_FONT   :: 16
DEFAULT_GUI_FONT    :: 17
DC_BRUSH            :: 18
DC_PEN              :: 19
STOCK_LAST          :: 19

CLR_INVALID :: 0xFFFFFFFF

RGBQUAD :: struct {
	rgbBlue: BYTE,
	rgbGreen: BYTE,
	rgbRed: BYTE,
	rgbReserved: BYTE,
}

PIXELFORMATDESCRIPTOR :: struct {
	nSize: WORD,
	nVersion: WORD,
	dwFlags: DWORD,
	iPixelType: BYTE,
	cColorBits: BYTE,
	cRedBits: BYTE,
	cRedShift: BYTE,
	cGreenBits: BYTE,
	cGreenShift: BYTE,
	cBlueBits: BYTE,
	cBlueShift: BYTE,
	cAlphaBits: BYTE,
	cAlphaShift: BYTE,
	cAccumBits: BYTE,
	cAccumRedBits: BYTE,
	cAccumGreenBits: BYTE,
	cAccumBlueBits: BYTE,
	cAccumAlphaBits: BYTE,
	cDepthBits: BYTE,
	cStencilBits: BYTE,
	cAuxBuffers: BYTE,
	iLayerType: BYTE,
	bReserved: BYTE,
	dwLayerMask: DWORD,
	dwVisibleMask: DWORD,
	dwDamageMask: DWORD,
}

BITMAPINFOHEADER :: struct {
	biSize: DWORD,
	biWidth: LONG,
	biHeight: LONG,
	biPlanes: WORD,
	biBitCount: WORD,
	biCompression: DWORD,
	biSizeImage: DWORD,
	biXPelsPerMeter: LONG,
	biYPelsPerMeter: LONG,
	biClrUsed: DWORD,
	biClrImportant: DWORD,
}

BITMAPINFO :: struct {
	bmiHeader: BITMAPINFOHEADER,
	bmiColors: [1]RGBQUAD,
}

// pixel types
PFD_TYPE_RGBA       :: 0
PFD_TYPE_COLORINDEX :: 1

// layer types
PFD_MAIN_PLANE     :: 0
PFD_OVERLAY_PLANE  :: 1
PFD_UNDERLAY_PLANE :: -1

// PIXELFORMATDESCRIPTOR flags
PFD_DOUBLEBUFFER         :: 0x00000001
PFD_STEREO               :: 0x00000002
PFD_DRAW_TO_WINDOW       :: 0x00000004
PFD_DRAW_TO_BITMAP       :: 0x00000008
PFD_SUPPORT_GDI          :: 0x00000010
PFD_SUPPORT_OPENGL       :: 0x00000020
PFD_GENERIC_FORMAT       :: 0x00000040
PFD_NEED_PALETTE         :: 0x00000080
PFD_NEED_SYSTEM_PALETTE  :: 0x00000100
PFD_SWAP_EXCHANGE        :: 0x00000200
PFD_SWAP_COPY            :: 0x00000400
PFD_SWAP_LAYER_BUFFERS   :: 0x00000800
PFD_GENERIC_ACCELERATED  :: 0x00001000
PFD_SUPPORT_DIRECTDRAW   :: 0x00002000
PFD_DIRECT3D_ACCELERATED :: 0x00004000
PFD_SUPPORT_COMPOSITION  :: 0x00008000

// PIXELFORMATDESCRIPTOR flags for use in ChoosePixelFormat only
PFD_DEPTH_DONTCARE        :: 0x20000000
PFD_DOUBLEBUFFER_DONTCARE :: 0x40000000
PFD_STEREO_DONTCARE       :: 0x80000000

// constants for the biCompression field
BI_RGB       :: 0
BI_RLE8      :: 1
BI_RLE4      :: 2
BI_BITFIELDS :: 3
BI_JPEG      :: 4
BI_PNG       :: 5

WSA_FLAG_OVERLAPPED: DWORD : 0x01
WSA_FLAG_NO_HANDLE_INHERIT: DWORD : 0x80

WSADESCRIPTION_LEN :: 256
WSASYS_STATUS_LEN :: 128
WSAPROTOCOL_LEN: DWORD : 255
INVALID_SOCKET :: ~SOCKET(0)

WSAEACCES: c_int : 10013
WSAEINVAL: c_int : 10022
WSAEWOULDBLOCK: c_int : 10035
WSAEPROTOTYPE: c_int : 10041
WSAEADDRINUSE: c_int : 10048
WSAEADDRNOTAVAIL: c_int : 10049
WSAECONNABORTED: c_int : 10053
WSAECONNRESET: c_int : 10054
WSAENOTCONN: c_int : 10057
WSAESHUTDOWN: c_int : 10058
WSAETIMEDOUT: c_int : 10060
WSAECONNREFUSED: c_int : 10061

MAX_PROTOCOL_CHAIN: DWORD : 7

MAXIMUM_REPARSE_DATA_BUFFER_SIZE :: 16 * 1024
FSCTL_GET_REPARSE_POINT: DWORD : 0x900a8
IO_REPARSE_TAG_SYMLINK: DWORD : 0xa000000c
IO_REPARSE_TAG_MOUNT_POINT: DWORD : 0xa0000003
SYMLINK_FLAG_RELATIVE: DWORD : 0x00000001
FSCTL_SET_REPARSE_POINT: DWORD : 0x900a4

SYMBOLIC_LINK_FLAG_DIRECTORY: DWORD : 0x1
SYMBOLIC_LINK_FLAG_ALLOW_UNPRIVILEGED_CREATE: DWORD : 0x2

STD_INPUT_HANDLE:  DWORD : ~DWORD(0) -10 + 1
STD_OUTPUT_HANDLE: DWORD : ~DWORD(0) -11 + 1
STD_ERROR_HANDLE:  DWORD : ~DWORD(0) -12 + 1

PROGRESS_CONTINUE: DWORD : 0

ERROR_FILE_NOT_FOUND: DWORD : 2
ERROR_PATH_NOT_FOUND: DWORD : 3
ERROR_ACCESS_DENIED: DWORD : 5
ERROR_NOT_ENOUGH_MEMORY: DWORD : 8
ERROR_INVALID_HANDLE: DWORD : 6
ERROR_NO_MORE_FILES: DWORD : 18
ERROR_SHARING_VIOLATION: DWORD : 32
ERROR_LOCK_VIOLATION: DWORD : 33
ERROR_HANDLE_EOF: DWORD : 38
ERROR_NOT_SUPPORTED: DWORD : 50
ERROR_FILE_EXISTS: DWORD : 80
ERROR_INVALID_PARAMETER: DWORD : 87
ERROR_BROKEN_PIPE: DWORD : 109
ERROR_CALL_NOT_IMPLEMENTED: DWORD : 120
ERROR_INSUFFICIENT_BUFFER: DWORD : 122
ERROR_INVALID_NAME: DWORD : 123
ERROR_LOCK_FAILED: DWORD : 167
ERROR_ALREADY_EXISTS: DWORD : 183
ERROR_NO_DATA: DWORD : 232
ERROR_ENVVAR_NOT_FOUND: DWORD : 203
ERROR_OPERATION_ABORTED: DWORD : 995
ERROR_IO_PENDING: DWORD : 997
ERROR_TIMEOUT: DWORD : 0x5B4
ERROR_NO_UNICODE_TRANSLATION: DWORD : 1113

E_NOTIMPL :: HRESULT(-0x7fff_bfff) // 0x8000_4001

INVALID_HANDLE :: HANDLE(~uintptr(0))
INVALID_HANDLE_VALUE :: INVALID_HANDLE

FACILITY_NT_BIT: DWORD : 0x1000_0000

FORMAT_MESSAGE_FROM_SYSTEM: DWORD : 0x00001000
FORMAT_MESSAGE_FROM_HMODULE: DWORD : 0x00000800
FORMAT_MESSAGE_IGNORE_INSERTS: DWORD : 0x00000200

TLS_OUT_OF_INDEXES: DWORD : 0xFFFFFFFF

DLL_THREAD_DETACH: DWORD : 3
DLL_PROCESS_DETACH: DWORD : 0
CREATE_SUSPENDED :: DWORD(0x00000004)

INFINITE :: ~DWORD(0)

DUPLICATE_SAME_ACCESS: DWORD : 0x00000002

CONDITION_VARIABLE_INIT :: CONDITION_VARIABLE{}
SRWLOCK_INIT :: SRWLOCK{}

DETACHED_PROCESS: DWORD : 0x00000008
CREATE_NEW_PROCESS_GROUP: DWORD : 0x00000200
CREATE_UNICODE_ENVIRONMENT: DWORD : 0x00000400
STARTF_USESTDHANDLES: DWORD : 0x00000100

AF_INET: c_int : 2
AF_INET6: c_int : 23
SD_BOTH: c_int : 2
SD_RECEIVE: c_int : 0
SD_SEND: c_int : 1
SOCK_DGRAM: c_int : 2
SOCK_STREAM: c_int : 1
SOL_SOCKET: c_int : 0xffff
SO_RCVTIMEO: c_int : 0x1006
SO_SNDTIMEO: c_int : 0x1005
SO_REUSEADDR: c_int : 0x0004
IPPROTO_IP: c_int : 0
IPPROTO_TCP: c_int : 6
IPPROTO_IPV6: c_int : 41
TCP_NODELAY: c_int : 0x0001
IP_TTL: c_int : 4
IPV6_V6ONLY: c_int : 27
SO_ERROR: c_int : 0x1007
SO_BROADCAST: c_int : 0x0020
IP_MULTICAST_LOOP: c_int : 11
IPV6_MULTICAST_LOOP: c_int : 11
IP_MULTICAST_TTL: c_int : 10
IP_ADD_MEMBERSHIP: c_int : 12
IP_DROP_MEMBERSHIP: c_int : 13
IPV6_ADD_MEMBERSHIP: c_int : 12
IPV6_DROP_MEMBERSHIP: c_int : 13
MSG_PEEK: c_int : 0x2

ip_mreq :: struct {
	imr_multiaddr: in_addr,
	imr_interface: in_addr,
}

ipv6_mreq :: struct {
	ipv6mr_multiaddr: in6_addr,
	ipv6mr_interface: c_uint,
}

VOLUME_NAME_DOS: DWORD : 0x0
MOVEFILE_REPLACE_EXISTING: DWORD : 1

FILE_BEGIN: DWORD : 0
FILE_CURRENT: DWORD : 1
FILE_END: DWORD : 2

WAIT_OBJECT_0: DWORD : 0x00000000
WAIT_TIMEOUT: DWORD : 258
WAIT_FAILED: DWORD : 0xFFFFFFFF

PIPE_ACCESS_INBOUND: DWORD : 0x00000001
PIPE_ACCESS_OUTBOUND: DWORD : 0x00000002
FILE_FLAG_FIRST_PIPE_INSTANCE: DWORD : 0x00080000
FILE_FLAG_OVERLAPPED: DWORD : 0x40000000
PIPE_WAIT: DWORD : 0x00000000
PIPE_TYPE_BYTE: DWORD : 0x00000000
PIPE_REJECT_REMOTE_CLIENTS: DWORD : 0x00000008
PIPE_READMODE_BYTE: DWORD : 0x00000000

FD_SETSIZE :: 64

STACK_SIZE_PARAM_IS_A_RESERVATION: DWORD : 0x00010000

INVALID_SET_FILE_POINTER :: ~DWORD(0)

HEAP_ZERO_MEMORY: DWORD : 0x00000008

HANDLE_FLAG_INHERIT: DWORD : 0x00000001
HANDLE_FLAG_PROTECT_FROM_CLOSE :: 0x00000002

TOKEN_READ: DWORD : 0x20008

CP_ACP        :: 0     // default to ANSI code page
CP_OEMCP      :: 1     // default to OEM  code page
CP_MACCP      :: 2     // default to MAC  code page
CP_THREAD_ACP :: 3     // current thread's ANSI code page
CP_SYMBOL     :: 42    // SYMBOL translations
CP_UTF7       :: 65000 // UTF-7 translation
CP_UTF8       :: 65001 // UTF-8 translation

MB_ERR_INVALID_CHARS :: 8
WC_ERR_INVALID_CHARS :: 128


MAX_PATH :: 0x00000104
MAX_PATH_WIDE :: 0x8000

INVALID_FILE_ATTRIBUTES  :: -1

FILE_TYPE_DISK :: 0x0001
FILE_TYPE_CHAR :: 0x0002
FILE_TYPE_PIPE :: 0x0003

RECT  :: struct {left, top, right, bottom: LONG}
POINT :: struct {x, y: LONG}

WINDOWPOS :: struct {
	hwnd: HWND,
	hwndInsertAfter: HWND,
	x: c_int,
	y: c_int,
	cx: c_int,
	cy: c_int,
	flags: UINT,
}

when size_of(uintptr) == 4 {
	WSADATA :: struct {
		wVersion: WORD,
		wHighVersion: WORD,
		szDescription: [WSADESCRIPTION_LEN + 1]u8,
		szSystemStatus: [WSASYS_STATUS_LEN + 1]u8,
		iMaxSockets: u16,
		iMaxUdpDg: u16,
		lpVendorInfo: ^u8,
	}
} else when size_of(uintptr) == 8 {
	WSADATA :: struct {
		wVersion: WORD,
		wHighVersion: WORD,
		iMaxSockets: u16,
		iMaxUdpDg: u16,
		lpVendorInfo: ^u8,
		szDescription: [WSADESCRIPTION_LEN + 1]u8,
		szSystemStatus: [WSASYS_STATUS_LEN + 1]u8,
	}
} else {
	#panic("unknown word size")
}

WSABUF :: struct {
	len: ULONG,
	buf: ^CHAR,
}

WSAPROTOCOL_INFO :: struct {
	dwServiceFlags1: DWORD,
	dwServiceFlags2: DWORD,
	dwServiceFlags3: DWORD,
	dwServiceFlags4: DWORD,
	dwProviderFlags: DWORD,
	ProviderId: GUID,
	dwCatalogEntryId: DWORD,
	ProtocolChain: WSAPROTOCOLCHAIN,
	iVersion: c_int,
	iAddressFamily: c_int,
	iMaxSockAddr: c_int,
	iMinSockAddr: c_int,
	iSocketType: c_int,
	iProtocol: c_int,
	iProtocolMaxOffset: c_int,
	iNetworkByteOrder: c_int,
	iSecurityScheme: c_int,
	dwMessageSize: DWORD,
	dwProviderReserved: DWORD,
	szProtocol: [WSAPROTOCOL_LEN + 1]u16,
}

WIN32_FILE_ATTRIBUTE_DATA :: struct {
	dwFileAttributes: DWORD,
	ftCreationTime: FILETIME,
	ftLastAccessTime: FILETIME,
	ftLastWriteTime: FILETIME,
	nFileSizeHigh: DWORD,
	nFileSizeLow: DWORD,
}

FILE_INFO_BY_HANDLE_CLASS :: enum c_int {
	FileBasicInfo = 0,
	FileStandardInfo = 1,
	FileNameInfo = 2,
	FileRenameInfo = 3,
	FileDispositionInfo = 4,
	FileAllocationInfo = 5,
	FileEndOfFileInfo = 6,
	FileStreamInfo = 7,
	FileCompressionInfo = 8,
	FileAttributeTagInfo = 9,
	FileIdBothDirectoryInfo = 10,        // 0xA
	FileIdBothDirectoryRestartInfo = 11, // 0xB
	FileIoPriorityHintInfo = 12,         // 0xC
	FileRemoteProtocolInfo = 13,         // 0xD
	FileFullDirectoryInfo = 14,          // 0xE
	FileFullDirectoryRestartInfo = 15,   // 0xF
	FileStorageInfo = 16,                // 0x10
	FileAlignmentInfo = 17,              // 0x11
	FileIdInfo = 18,                     // 0x12
	FileIdExtdDirectoryInfo = 19,        // 0x13
	FileIdExtdDirectoryRestartInfo = 20, // 0x14
	MaximumFileInfoByHandlesClass,
}

FILE_BASIC_INFO :: struct {
	CreationTime: LARGE_INTEGER,
	LastAccessTime: LARGE_INTEGER,
	LastWriteTime: LARGE_INTEGER,
	ChangeTime: LARGE_INTEGER,
	FileAttributes: DWORD,
}

FILE_END_OF_FILE_INFO :: struct {
	EndOfFile: LARGE_INTEGER,
}

REPARSE_DATA_BUFFER :: struct {
	ReparseTag: c_uint,
	ReparseDataLength: c_ushort,
	Reserved: c_ushort,
	rest: [0]byte,
}

SYMBOLIC_LINK_REPARSE_BUFFER :: struct {
	SubstituteNameOffset: c_ushort,
	SubstituteNameLength: c_ushort,
	PrintNameOffset: c_ushort,
	PrintNameLength: c_ushort,
	Flags: c_ulong,
	PathBuffer: WCHAR,
}

MOUNT_POINT_REPARSE_BUFFER :: struct {
	SubstituteNameOffset: c_ushort,
	SubstituteNameLength: c_ushort,
	PrintNameOffset: c_ushort,
	PrintNameLength: c_ushort,
	PathBuffer: WCHAR,
}

LPPROGRESS_ROUTINE :: #type proc "stdcall" (
	TotalFileSize: LARGE_INTEGER,
	TotalBytesTransferred: LARGE_INTEGER,
	StreamSize: LARGE_INTEGER,
	StreamBytesTransferred: LARGE_INTEGER,
	dwStreamNumber: DWORD,
	dwCallbackReason: DWORD,
	hSourceFile: HANDLE,
	hDestinationFile: HANDLE,
	lpData: LPVOID,
) -> DWORD

CONDITION_VARIABLE :: struct {
	ptr: LPVOID,
}
SRWLOCK :: struct {
	ptr: LPVOID,
}
CRITICAL_SECTION :: struct {
	CriticalSectionDebug: LPVOID,
	LockCount: LONG,
	RecursionCount: LONG,
	OwningThread: HANDLE,
	LockSemaphore: HANDLE,
	SpinCount: ULONG_PTR,
}

REPARSE_MOUNTPOINT_DATA_BUFFER :: struct {
	ReparseTag: DWORD,
	ReparseDataLength: DWORD,
	Reserved: WORD,
	ReparseTargetLength: WORD,
	ReparseTargetMaximumLength: WORD,
	Reserved1: WORD,
	ReparseTarget: WCHAR,
}

GUID :: struct {
	Data1: DWORD,
	Data2: WORD,
	Data3: WORD,
	Data4: [8]BYTE,
}

LUID :: struct {
	LowPart:  DWORD,
	HighPart: LONG,
}

PLUID :: ^LUID

PGUID   :: ^GUID
PCGUID  :: ^GUID
LPGUID  :: ^GUID
LPCGUID :: ^GUID


WSAPROTOCOLCHAIN :: struct {
	ChainLen: c_int,
	ChainEntries: [MAX_PROTOCOL_CHAIN]DWORD,
}

SECURITY_ATTRIBUTES :: struct {
	nLength: DWORD,
	lpSecurityDescriptor: LPVOID,
	bInheritHandle: BOOL,
}

PROCESS_INFORMATION :: struct {
	hProcess: HANDLE,
	hThread: HANDLE,
	dwProcessId: DWORD,
	dwThreadId: DWORD,
}

// FYI: This is STARTUPINFOW, not STARTUPINFOA
STARTUPINFO :: struct {
	cb: DWORD,
	lpReserved: LPWSTR,
	lpDesktop: LPWSTR,
	lpTitle: LPWSTR,
	dwX: DWORD,
	dwY: DWORD,
	dwXSize: DWORD,
	dwYSize: DWORD,
	dwXCountChars: DWORD,
	dwYCountChars: DWORD,
	dwFillAttribute: DWORD,
	dwFlags: DWORD,
	wShowWindow: WORD,
	cbReserved2: WORD,
	lpReserved2: LPBYTE,
	hStdInput: HANDLE,
	hStdOutput: HANDLE,
	hStdError: HANDLE,
}

SOCKADDR :: struct {
	sa_family: ADDRESS_FAMILY,
	sa_data: [14]CHAR,
}

FILETIME :: struct {
	dwLowDateTime: DWORD,
	dwHighDateTime: DWORD,
}

FILETIME_as_unix_nanoseconds :: proc "contextless" (ft: FILETIME) -> i64 {
	t := i64(u64(ft.dwLowDateTime) | u64(ft.dwHighDateTime) << 32)
	return (t - 0x019db1ded53e8000) * 100
}

OVERLAPPED :: struct {
	Internal: ^c_ulong,
	InternalHigh: ^c_ulong,
	Offset: DWORD,
	OffsetHigh: DWORD,
	hEvent: HANDLE,
}

ADDRESS_MODE :: enum c_int {
	AddrMode1616,
	AddrMode1632,
	AddrModeReal,
	AddrModeFlat,
}

SOCKADDR_STORAGE_LH :: struct {
	ss_family: ADDRESS_FAMILY,
	__ss_pad1: [6]CHAR,
	__ss_align: i64,
	__ss_pad2: [112]CHAR,
}

ADDRINFOA :: struct {
	ai_flags: c_int,
	ai_family: c_int,
	ai_socktype: c_int,
	ai_protocol: c_int,
	ai_addrlen: size_t,
	ai_canonname: ^c_char,
	ai_addr: ^SOCKADDR,
	ai_next: ^ADDRINFOA,
}

sockaddr_in :: struct {
	sin_family: ADDRESS_FAMILY,
	sin_port: USHORT,
	sin_addr: in_addr,
	sin_zero: [8]CHAR,
}

sockaddr_in6 :: struct {
	sin6_family: ADDRESS_FAMILY,
	sin6_port: USHORT,
	sin6_flowinfo: c_ulong,
	sin6_addr: in6_addr,
	sin6_scope_id: c_ulong,
}

in_addr :: struct {
	s_addr: u32,
}

in6_addr :: struct {
	s6_addr: [16]u8,
}

EXCEPTION_DISPOSITION :: enum c_int {
	ExceptionContinueExecution,
	ExceptionContinueSearch,
	ExceptionNestedException,
	ExceptionCollidedUnwind,
}

fd_set :: struct {
	fd_count: c_uint,
	fd_array: [FD_SETSIZE]SOCKET,
}

timeval :: struct {
	tv_sec: c_long,
	tv_usec: c_long,
}


EXCEPTION_CONTINUE_SEARCH: LONG : 0
EXCEPTION_CONTINUE_EXECUTION: LONG : -1
EXCEPTION_EXECUTE_HANDLER: LONG : 1

EXCEPTION_MAXIMUM_PARAMETERS :: 15

EXCEPTION_DATATYPE_MISALIGNMENT     :: 0x80000002
EXCEPTION_BREAKPOINT                :: 0x80000003
EXCEPTION_ACCESS_VIOLATION          :: 0xC0000005
EXCEPTION_ILLEGAL_INSTRUCTION       :: 0xC000001D
EXCEPTION_ARRAY_BOUNDS_EXCEEDED     :: 0xC000008C
EXCEPTION_INT_DIVIDE_BY_ZERO        :: 0xC0000094
EXCEPTION_INT_OVERFLOW              :: 0xC0000095
EXCEPTION_STACK_OVERFLOW            :: 0xC00000FD
STATUS_PRIVILEGED_INSTRUCTION       :: 0xC0000096


EXCEPTION_RECORD :: struct {
	ExceptionCode: DWORD,
	ExceptionFlags: DWORD,
	ExceptionRecord: ^EXCEPTION_RECORD,
	ExceptionAddress: LPVOID,
	NumberParameters: DWORD,
	ExceptionInformation: [EXCEPTION_MAXIMUM_PARAMETERS]LPVOID,
}

CONTEXT :: struct{} // TODO(bill)

EXCEPTION_POINTERS :: struct {
	ExceptionRecord: ^EXCEPTION_RECORD,
	ContextRecord: ^CONTEXT,
}

PVECTORED_EXCEPTION_HANDLER :: #type proc "stdcall" (ExceptionInfo: ^EXCEPTION_POINTERS) -> LONG

CONSOLE_READCONSOLE_CONTROL :: struct {
	nLength: ULONG,
	nInitialChars: ULONG,
	dwCtrlWakeupMask: ULONG,
	dwControlKeyState: ULONG,
}

PCONSOLE_READCONSOLE_CONTROL :: ^CONSOLE_READCONSOLE_CONTROL

BY_HANDLE_FILE_INFORMATION :: struct {
	dwFileAttributes: DWORD,
	ftCreationTime: FILETIME,
	ftLastAccessTime: FILETIME,
	ftLastWriteTime: FILETIME,
	dwVolumeSerialNumber: DWORD,
	nFileSizeHigh: DWORD,
	nFileSizeLow: DWORD,
	nNumberOfLinks: DWORD,
	nFileIndexHigh: DWORD,
	nFileIndexLow: DWORD,
}

LPBY_HANDLE_FILE_INFORMATION :: ^BY_HANDLE_FILE_INFORMATION

FILE_STANDARD_INFO :: struct {
	AllocationSize: LARGE_INTEGER,
	EndOfFile: LARGE_INTEGER,
	NumberOfLinks: DWORD,
	DeletePending: BOOLEAN,
	Directory: BOOLEAN,
}

FILE_ATTRIBUTE_TAG_INFO :: struct {
	FileAttributes: DWORD,
	ReparseTag: DWORD,
}



// https://docs.microsoft.com/en-gb/windows/win32/api/sysinfoapi/ns-sysinfoapi-system_info
SYSTEM_INFO :: struct {
	using _: struct #raw_union {
		dwOemID: DWORD,
		using _: struct #raw_union {
			wProcessorArchitecture: WORD,
			wReserved: WORD, // reserved
		},
	},
	dwPageSize: DWORD,
	lpMinimumApplicationAddress: LPVOID,
	lpMaximumApplicationAddress: LPVOID,
	dwActiveProcessorMask: DWORD_PTR,
	dwNumberOfProcessors: DWORD,
	dwProcessorType: DWORD,
	dwAllocationGranularity: DWORD,
	wProcessorLevel: WORD,
	wProcessorRevision: WORD,
}

// https://docs.microsoft.com/en-us/windows-hardware/drivers/ddi/wdm/ns-wdm-_osversioninfoexw
OSVERSIONINFOEXW :: struct {
	dwOSVersionInfoSize: ULONG,
	dwMajorVersion:      ULONG,
	dwMinorVersion:      ULONG,
	dwBuildNumber:       ULONG,
	dwPlatformId:        ULONG,
	szCSDVersion:        [128]WCHAR,
	wServicePackMajor:   USHORT,
	wServicePackMinor:   USHORT,
	wSuiteMask:          USHORT,
	wProductType:        UCHAR,
	wReserved:           UCHAR,
}

// https://docs.microsoft.com/en-us/windows/win32/api/winnt/ns-winnt-quota_limits
// Used in LogonUserExW
PQUOTA_LIMITS :: struct {
	PagedPoolLimit: SIZE_T,
	NonPagedPoolLimit: SIZE_T,
	MinimumWorkingSetSize: SIZE_T,
	MaximumWorkingSetSize: SIZE_T,
	PagefileLimit: SIZE_T,
	TimeLimit: LARGE_INTEGER,
}

Logon32_Type :: enum DWORD {
	INTERACTIVE       = 2,
	NETWORK           = 3,
	BATCH             = 4,
	SERVICE           = 5,
	UNLOCK            = 7,
	NETWORK_CLEARTEXT = 8,
	NEW_CREDENTIALS   = 9,
}

Logon32_Provider :: enum DWORD {
	DEFAULT = 0,
	WINNT35 = 1,
	WINNT40 = 2,
	WINNT50 = 3,
	VIRTUAL = 4,
}

// https://docs.microsoft.com/en-us/windows/win32/api/profinfo/ns-profinfo-profileinfow
// Used in LoadUserProfileW

PROFILEINFOW :: struct {
	dwSize: DWORD,
	dwFlags: DWORD,
	lpUserName: LPWSTR,
	lpProfilePath: LPWSTR,
	lpDefaultPath: LPWSTR,
	lpServerName: LPWSTR,
	lpPolicyPath: LPWSTR,
	hProfile: HANDLE,
}

// Used in LookupAccountNameW
SID_NAME_USE :: distinct DWORD

SID_TYPE :: enum SID_NAME_USE {
	User = 1,
	Group,
	Domain,
	Alias,
	WellKnownGroup,
	DeletedAccount,
	Invalid,
	Unknown,
	Computer,
	Label,
	LogonSession,
}

SECURITY_MAX_SID_SIZE :: 68

// https://docs.microsoft.com/en-us/windows/win32/api/winnt/ns-winnt-sid
SID :: struct #packed {
	Revision: byte,
	SubAuthorityCount: byte,
	IdentifierAuthority: SID_IDENTIFIER_AUTHORITY,
	SubAuthority: [15]DWORD, // Array of DWORDs
}
#assert(size_of(SID) == SECURITY_MAX_SID_SIZE)

SID_IDENTIFIER_AUTHORITY :: struct #packed {
	Value: [6]u8,
}

// For NetAPI32
// https://github.com/tpn/winsdk-10/blob/master/Include/10.0.14393.0/shared/lmerr.h
// https://github.com/tpn/winsdk-10/blob/master/Include/10.0.14393.0/shared/LMaccess.h

UNLEN      :: 256        // Maximum user name length
LM20_UNLEN ::  20        // LM 2.0 Maximum user name length

GNLEN      :: UNLEN      // Group name
LM20_GNLEN :: LM20_UNLEN // LM 2.0 Group name

PWLEN      :: 256        // Maximum password length
LM20_PWLEN ::  14        // LM 2.0 Maximum password length

USER_PRIV :: enum DWORD {
	Guest = 0,
	User  = 1,
	Admin = 2,
	Mask  = 0x3,
}

USER_INFO_FLAG :: enum DWORD {
	Script                          = 0,  // 1 <<  0: 0x0001,
	AccountDisable                  = 1,  // 1 <<  1: 0x0002,
	HomeDir_Required                = 3,  // 1 <<  3: 0x0008,
	Lockout                         = 4,  // 1 <<  4: 0x0010,
	Passwd_NotReqd                  = 5,  // 1 <<  5: 0x0020,
	Passwd_Cant_Change              = 6,  // 1 <<  6: 0x0040,
	Encrypted_Text_Password_Allowed = 7,  // 1 <<  7: 0x0080,

	Temp_Duplicate_Account          = 8,  // 1 <<  8: 0x0100,
	Normal_Account                  = 9,  // 1 <<  9: 0x0200,
	InterDomain_Trust_Account       = 11, // 1 << 11: 0x0800,
	Workstation_Trust_Account       = 12, // 1 << 12: 0x1000,
	Server_Trust_Account            = 13, // 1 << 13: 0x2000,
}
USER_INFO_FLAGS :: distinct bit_set[USER_INFO_FLAG]

USER_INFO_1 :: struct #packed {
	name: LPWSTR,
	password: LPWSTR,     // Max password length is defined in LM20_PWLEN.
	password_age: DWORD,
	priv: USER_PRIV,
	home_dir: LPWSTR,
	comment: LPWSTR,
	flags: USER_INFO_FLAGS,
	script_path: LPWSTR,
}
// #assert(size_of(USER_INFO_1) == 50)

LOCALGROUP_MEMBERS_INFO_0 :: struct #packed {
	sid: ^SID,
}

NET_API_STATUS :: enum DWORD {
	Success = 0,
	ERROR_ACCESS_DENIED = 5,
	MemberInAlias = 1378,
	NetNotStarted = 2102,
	UnknownServer = 2103,
	ShareMem = 2104,
	NoNetworkResource = 2105,
	RemoteOnly = 2106,
	DevNotRedirected = 2107,
	ServerNotStarted = 2114,
	ItemNotFound = 2115,
	UnknownDevDir = 2116,
	RedirectedPath = 2117,
	DuplicateShare = 2118,
	NoRoom = 2119,
	TooManyItems = 2121,
	InvalidMaxUsers = 2122,
	BufTooSmall = 2123,
	RemoteErr = 2127,
	LanmanIniError = 2131,
	NetworkError = 2136,
	WkstaInconsistentState = 2137,
	WkstaNotStarted = 2138,
	BrowserNotStarted = 2139,
	InternalError = 2140,
	BadTransactConfig = 2141,
	InvalidAPI = 2142,
	BadEventName = 2143,
	DupNameReboot = 2144,
	CfgCompNotFound = 2146,
	CfgParamNotFound = 2147,
	LineTooLong = 2149,
	QNotFound = 2150,
	JobNotFound = 2151,
	DestNotFound = 2152,
	DestExists = 2153,
	QExists = 2154,
	QNoRoom = 2155,
	JobNoRoom = 2156,
	DestNoRoom = 2157,
	DestIdle = 2158,
	DestInvalidOp = 2159,
	ProcNoRespond = 2160,
	SpoolerNotLoaded = 2161,
	DestInvalidState = 2162,
	QInvalidState = 2163,
	JobInvalidState = 2164,
	SpoolNoMemory = 2165,
	DriverNotFound = 2166,
	DataTypeInvalid = 2167,
	ProcNotFound = 2168,
	ServiceTableLocked = 2180,
	ServiceTableFull = 2181,
	ServiceInstalled = 2182,
	ServiceEntryLocked = 2183,
	ServiceNotInstalled = 2184,
	BadServiceName = 2185,
	ServiceCtlTimeout = 2186,
	ServiceCtlBusy = 2187,
	BadServiceProgName = 2188,
	ServiceNotCtrl = 2189,
	ServiceKillProc = 2190,
	ServiceCtlNotValid = 2191,
	NotInDispatchTbl = 2192,
	BadControlRecv = 2193,
	ServiceNotStarting = 2194,
	AlreadyLoggedOn = 2200,
	NotLoggedOn = 2201,
	BadUsername = 2202,
	BadPassword = 2203,
	UnableToAddName_W = 2204,
	UnableToAddName_F = 2205,
	UnableToDelName_W = 2206,
	UnableToDelName_F = 2207,
	LogonsPaused = 2209,
	LogonServerConflict = 2210,
	LogonNoUserPath = 2211,
	LogonScriptError = 2212,
	StandaloneLogon = 2214,
	LogonServerNotFound = 2215,
	LogonDomainExists = 2216,
	NonValidatedLogon = 2217,
	ACFNotFound = 2219,
	GroupNotFound = 2220,
	UserNotFound = 2221,
	ResourceNotFound = 2222,
	GroupExists = 2223,
	UserExists = 2224,
	ResourceExists = 2225,
	NotPrimary = 2226,
	ACFNotLoaded = 2227,
	ACFNoRoom = 2228,
	ACFFileIOFail = 2229,
	ACFTooManyLists = 2230,
	UserLogon = 2231,
	ACFNoParent = 2232,
	CanNotGrowSegment = 2233,
	SpeGroupOp = 2234,
	NotInCache = 2235,
	UserInGroup = 2236,
	UserNotInGroup = 2237,
	AccountUndefined = 2238,
	AccountExpired = 2239,
	InvalidWorkstation = 2240,
	InvalidLogonHours = 2241,
	PasswordExpired = 2242,
	PasswordCantChange = 2243,
	PasswordHistConflict = 2244,
	PasswordTooShort = 2245,
	PasswordTooRecent = 2246,
	InvalidDatabase = 2247,
	DatabaseUpToDate = 2248,
	SyncRequired = 2249,
	UseNotFound = 2250,
	BadAsgType = 2251,
	DeviceIsShared = 2252,
	SameAsComputerName = 2253,
	NoComputerName = 2270,
	MsgAlreadyStarted = 2271,
	MsgInitFailed = 2272,
	NameNotFound = 2273,
	AlreadyForwarded = 2274,
	AddForwarded = 2275,
	AlreadyExists = 2276,
	TooManyNames = 2277,
	DelComputerName = 2278,
	LocalForward = 2279,
	GrpMsgProcessor = 2280,
	PausedRemote = 2281,
	BadReceive = 2282,
	NameInUse = 2283,
	MsgNotStarted = 2284,
	NotLocalName = 2285,
	NoForwardName = 2286,
	RemoteFull = 2287,
	NameNotForwarded = 2288,
	TruncatedBroadcast = 2289,
	InvalidDevice = 2294,
	WriteFault = 2295,
	DuplicateName = 2297,
	DeleteLater = 2298,
	IncompleteDel = 2299,
	MultipleNets = 2300,
	NetNameNotFound = 2310,
	DeviceNotShared = 2311,
	ClientNameNotFound = 2312,
	FileIdNotFound = 2314,
	ExecFailure = 2315,
	TmpFile = 2316,
	TooMuchData = 2317,
	DeviceShareConflict = 2318,
	BrowserTableIncomplete = 2319,
	NotLocalDomain = 2320,
	IsDfsShare = 2321,
	DevInvalidOpCode = 2331,
	DevNotFound = 2332,
	DevNotOpen = 2333,
	BadQueueDevString = 2334,
	BadQueuePriority = 2335,
	NoCommDevs = 2337,
	QueueNotFound = 2338,
	BadDevString = 2340,
	BadDev = 2341,
	InUseBySpooler = 2342,
	CommDevInUse = 2343,
	InvalidComputer = 2351,
	MaxLenExceeded = 2354,
	BadComponent = 2356,
	CantType = 2357,
	TooManyEntries = 2362,
	ProfileFileTooBig = 2370,
	ProfileOffset = 2371,
	ProfileCleanup = 2372,
	ProfileUnknownCmd = 2373,
	ProfileLoadErr = 2374,
	ProfileSaveErr = 2375,
	LogOverflow = 2377,
	LogFileChanged = 2378,
	LogFileCorrupt = 2379,
	SourceIsDir = 2380,
	BadSource = 2381,
	BadDest = 2382,
	DifferentServers = 2383,
	RunSrvPaused = 2385,
	ErrCommRunSrv = 2389,
	ErrorExecingGhost = 2391,
	ShareNotFound = 2392,
	InvalidLana = 2400,
	OpenFiles = 2401,
	ActiveConns = 2402,
	BadPasswordCore = 2403,
	DevInUse = 2404,
	LocalDrive = 2405,
	AlertExists = 2430,
	TooManyAlerts = 2431,
	NoSuchAlert = 2432,
	BadRecipient = 2433,
	AcctLimitExceeded = 2434,
	InvalidLogSeek = 2440,
	BadUasConfig = 2450,
	InvalidUASOp = 2451,
	LastAdmin = 2452,
	DCNotFound = 2453,
	LogonTrackingError = 2454,
	NetlogonNotStarted = 2455,
	CanNotGrowUASFile = 2456,
	TimeDiffAtDC = 2457,
	PasswordMismatch = 2458,
	NoSuchServer = 2460,
	NoSuchSession = 2461,
	NoSuchConnection = 2462,
	TooManyServers = 2463,
	TooManySessions = 2464,
	TooManyConnections = 2465,
	TooManyFiles = 2466,
	NoAlternateServers = 2467,
	TryDownLevel = 2470,
	UPSDriverNotStarted = 2480,
	UPSInvalidConfig = 2481,
	UPSInvalidCommPort = 2482,
	UPSSignalAsserted = 2483,
	UPSShutdownFailed = 2484,
	BadDosRetCode = 2500,
	ProgNeedsExtraMem = 2501,
	BadDosFunction = 2502,
	RemoteBootFailed = 2503,
	BadFileCheckSum = 2504,
	NoRplBootSystem = 2505,
	RplLoadrNetBiosErr = 2506,
	RplLoadrDiskErr = 2507,
	ImageParamErr = 2508,
	TooManyImageParams = 2509,
	NonDosFloppyUsed = 2510,
	RplBootRestart = 2511,
	RplSrvrCallFailed = 2512,
	CantConnectRplSrvr = 2513,
	CantOpenImageFile = 2514,
	CallingRplSrvr = 2515,
	StartingRplBoot = 2516,
	RplBootServiceTerm = 2517,
	RplBootStartFailed = 2518,
	RPL_CONNECTED = 2519,
	BrowserConfiguredToNotRun = 2550,
	RplNoAdaptersStarted = 2610,
	RplBadRegistry = 2611,
	RplBadDatabase = 2612,
	RplRplfilesShare = 2613,
	RplNotRplServer = 2614,
	RplCannotEnum = 2615,
	RplWkstaInfoCorrupted = 2616,
	RplWkstaNotFound = 2617,
	RplWkstaNameUnavailable = 2618,
	RplProfileInfoCorrupted = 2619,
	RplProfileNotFound = 2620,
	RplProfileNameUnavailable = 2621,
	RplProfileNotEmpty = 2622,
	RplConfigInfoCorrupted = 2623,
	RplConfigNotFound = 2624,
	RplAdapterInfoCorrupted = 2625,
	RplInternal = 2626,
	RplVendorInfoCorrupted = 2627,
	RplBootInfoCorrupted = 2628,
	RplWkstaNeedsUserAcct = 2629,
	RplNeedsRPLUSERAcct = 2630,
	RplBootNotFound = 2631,
	RplIncompatibleProfile = 2632,
	RplAdapterNameUnavailable = 2633,
	RplConfigNotEmpty = 2634,
	RplBootInUse = 2635,
	RplBackupDatabase = 2636,
	RplAdapterNotFound = 2637,
	RplVendorNotFound = 2638,
	RplVendorNameUnavailable = 2639,
	RplBootNameUnavailable = 2640,
	RplConfigNameUnavailable = 2641,
	DfsInternalCorruption = 2660,
	DfsVolumeDataCorrupt = 2661,
	DfsNoSuchVolume = 2662,
	DfsVolumeAlreadyExists = 2663,
	DfsAlreadyShared = 2664,
	DfsNoSuchShare = 2665,
	DfsNotALeafVolume = 2666,
	DfsLeafVolume = 2667,
	DfsVolumeHasMultipleServers = 2668,
	DfsCantCreateJunctionPoint = 2669,
	DfsServerNotDfsAware = 2670,
	DfsBadRenamePath = 2671,
	DfsVolumeIsOffline = 2672,
	DfsNoSuchServer = 2673,
	DfsCyclicalName = 2674,
	DfsNotSupportedInServerDfs = 2675,
	DfsDuplicateService = 2676,
	DfsCantRemoveLastServerShare = 2677,
	DfsVolumeIsInterDfs = 2678,
	DfsInconsistent = 2679,
	DfsServerUpgraded = 2680,
	DfsDataIsIdentical = 2681,
	DfsCantRemoveDfsRoot = 2682,
	DfsChildOrParentInDfs = 2683,
	DfsInternalError = 2690,
	SetupAlreadyJoined = 2691,
	SetupNotJoined = 2692,
	SetupDomainController = 2693,
	DefaultJoinRequired = 2694,
	InvalidWorkgroupName = 2695,
	NameUsesIncompatibleCodePage = 2696,
	ComputerAccountNotFound = 2697,
	PersonalSku = 2698,
	SetupCheckDNSConfig = 2699,
	PasswordMustChange = 2701,
	AccountLockedOut = 2702,
	PasswordTooLong = 2703,
	PasswordNotComplexEnough = 2704,
	PasswordFilterError = 2705,
}


SYSTEMTIME :: struct {
	year:         WORD,
	month:        WORD,
	day_of_week:  WORD,
	day:          WORD,
	hour:         WORD,
	minute:       WORD,
	second:       WORD,
	milliseconds: WORD,
}
