#+build windows
package sys_windows

foreign import "system:Comctl32.lib"

@(default_calling_convention="system")
foreign Comctl32 {
	InitCommonControlsEx :: proc(picce: ^INITCOMMONCONTROLSEX) -> BOOL ---
	LoadIconWithScaleDown :: proc(hinst: HINSTANCE, pszName: PCWSTR, cx: c_int, cy: c_int, phico: ^HICON) -> HRESULT ---
	SetWindowSubclass :: proc(hwnd: HWND, pfnSubclass: SUBCLASSPROC, uIdSubclass: UINT_PTR, dwRefData: DWORD_PTR) ---
}

ICC_LISTVIEW_CLASSES   :: 0x00000001
ICC_TREEVIEW_CLASSES   :: 0x00000002
ICC_BAR_CLASSES        :: 0x00000004
ICC_TAB_CLASSES        :: 0x00000008
ICC_UPDOWN_CLASS       :: 0x00000010
ICC_PROGRESS_CLASS     :: 0x00000020
ICC_HOTKEY_CLASS       :: 0x00000040
ICC_ANIMATE_CLASS      :: 0x00000080
ICC_WIN95_CLASSES      :: 0x000000FF
ICC_DATE_CLASSES       :: 0x00000100
ICC_USEREX_CLASSES     :: 0x00000200
ICC_COOL_CLASSES       :: 0x00000400
ICC_INTERNET_CLASSES   :: 0x00000800
ICC_PAGESCROLLER_CLASS :: 0x00001000
ICC_NATIVEFNTCTL_CLASS :: 0x00002000
ICC_STANDARD_CLASSES   :: 0x00004000
ICC_LINK_CLASS         :: 0x00008000

INITCOMMONCONTROLSEX :: struct {
	dwSize: DWORD,
	dwICC: DWORD,
}

COMCTL32_VERSION :: 6
HINST_COMMCTRL   :: cast(HINSTANCE)(~uintptr(0))

// Common Control Class Names
WC_HEADER        :: "SysHeader32"
WC_LISTVIEW      :: "SysListView32"
WC_TREEVIEW      :: "SysTreeView32"
WC_COMBOBOXEX    :: "ComboBoxEx32"
WC_TABCONTROL    :: "SysTabControl32"
WC_IPADDRESS     :: "SysIPAddress32"
WC_PAGESCROLLER  :: "SysPager"
WC_NATIVEFONTCTL :: "NativeFontCtl"
WC_BUTTON        :: "Button"
WC_STATIC        :: "Static"
WC_EDIT          :: "Edit"
WC_LISTBOX       :: "ListBox"
WC_COMBOBOX      :: "ComboBox"
WC_SCROLLBAR     :: "ScrollBar"
WC_LINK          :: "SysLink"

TOOLBARCLASSNAME :: "ToolbarWindow32"
REBARCLASSNAME   :: "ReBarWindow32"
STATUSCLASSNAME  :: "msctls_statusbar32"

TOOLTIPS_CLASS     :: "tooltips_class32"
TRACKBAR_CLASS     :: "msctls_trackbar32"
UPDOWN_CLASS       :: "msctls_updown32"
PROGRESS_CLASS     :: "msctls_progress32"
HOTKEY_CLASS       :: "msctls_hotkey32"
ANIMATE_CLASS      :: "SysAnimate32"
MONTHCAL_CLASS     :: "SysMonthCal32"
DATETIMEPICK_CLASS :: "SysDateTimePick32"

// Common Control Constants
MSGF_COMMCTRL_BEGINDRAG   :: 0x4200
MSGF_COMMCTRL_SIZEHEADER  :: 0x4201
MSGF_COMMCTRL_DRAGSELECT  :: 0x4202
MSGF_COMMCTRL_TOOLBARCUST :: 0x4203

// Custom Draw Constants
CDRF_DODEFAULT         :: 0x00
CDRF_NEWFONT           :: 0x02
CDRF_SKIPDEFAULT       :: 0x04
CDRF_NOTIFYPOSTPAINT   :: 0x10
CDRF_NOTIFYITEMDRAW    :: 0x20
CDRF_NOTIFYSUBITEMDRAW :: 0x20
CDRF_NOTIFYPOSTERASE   :: 0x40

CDDS_PREPAINT      :: 0x00001
CDDS_POSTPAINT     :: 0x00002
CDDS_PREERASE      :: 0x00003
CDDS_POSTERASE     :: 0x00004
CDDS_ITEM          :: 0x10000
CDDS_ITEMPREPAINT  :: (CDDS_ITEM | CDDS_PREPAINT)
CDDS_ITEMPOSTPAINT :: (CDDS_ITEM | CDDS_POSTPAINT)
CDDS_ITEMPREERASE  :: (CDDS_ITEM | CDDS_PREERASE)
CDDS_ITEMPOSTERASE :: (CDDS_ITEM | CDDS_POSTERASE)
CDDS_SUBITEM       :: 0x20000

CDIS_SELECTED         :: 0x001
CDIS_GRAYED           :: 0x002
CDIS_DISABLED         :: 0x004
CDIS_CHECKED          :: 0x008
CDIS_FOCUS            :: 0x010
CDIS_DEFAULT          :: 0x020
CDIS_HOT              :: 0x040
CDIS_MARKED           :: 0x080
CDIS_INDETERMINATE    :: 0x100
CDIS_SHOWKEYBOARDCUES :: 0x200

// Image Lists
CLR_NONE    :: 0xFFFFFFFF
CLR_DEFAULT :: 0xFF000000

ILC_MASK             :: 0x00000001
ILC_COLOR            :: 0x00000000
ILC_COLORDDB         :: 0x000000FE
ILC_COLOR4           :: 0x00000004
ILC_COLOR8           :: 0x00000008
ILC_COLOR16          :: 0x00000010
ILC_COLOR24          :: 0x00000018
ILC_COLOR32          :: 0x00000020
ILC_PALETTE          :: 0x00000800
ILC_MIRROR           :: 0x00002000
ILC_PERITEMMIRROR    :: 0x00008000
ILC_ORIGINALSIZE     :: 0x00010000
ILC_HIGHQUALITYSCALE :: 0x00020000

ILD_NORMAL        :: 0x00000000
ILD_TRANSPARENT   :: 0x00000001
ILD_MASK          :: 0x00000010
ILD_IMAGE         :: 0x00000020
ILD_ROP           :: 0x00000040
ILD_BLEND25       :: 0x00000002
ILD_BLEND50       :: 0x00000004
ILD_OVERLAYMASK   :: 0x00000F00
ILD_PRESERVEALPHA :: 0x00001000
ILD_SCALE         :: 0x00002000
ILD_DPISCALE      :: 0x00004000
ILD_ASYNC         :: 0x00008000

ILD_SELECTED :: ILD_BLEND50
ILD_FOCUS    :: ILD_BLEND25
ILD_BLEND    :: ILD_BLEND50
CLR_HILIGHT  :: CLR_DEFAULT

ILS_NORMAL   :: 0x00000000
ILS_GLOW     :: 0x00000001
ILS_SHADOW   :: 0x00000002
ILS_SATURATE :: 0x00000004
ILS_ALPHA    :: 0x00000008

ILGT_NORMAL :: 0x00000000
ILGT_ASYNC  :: 0x00000001

ILCF_MOVE :: 0x00000000
ILCF_SWAP :: 0x00000001

ILP_NORMAL    :: 0
ILP_DOWNLEVEL :: 1

IMAGELISTDRAWPARAMS :: struct {
	cbSize: DWORD,
	himl: HIMAGELIST,
	i: i32,
	hdcDst: HDC,
	x: i32,
	y: i32,
	cx: i32,
	cy: i32,
	xBitmap: i32,
	yBitmap: i32,
	rgbBk: COLORREF,
	rgbFg: COLORREF,
	fStyle: UINT,
	dwRop: DWORD,
	fState: DWORD,
	Frame: DWORD,
	crEffect: COLORREF,
}
LPIMAGELISTDRAWPARAMS :: ^IMAGELISTDRAWPARAMS

IMAGEINFO :: struct {
	hbmImage: HBITMAP,
	hbmMask: HBITMAP,
	Unused1: i32,
	Unused2: i32,
	rcImage: RECT,
}
LPIMAGEINFO :: ^IMAGEINFO

@(default_calling_convention="system")
foreign Comctl32 {
	ImageList_Create :: proc(cx, cy: i32, flags: UINT, cInitial, cGrow: i32) -> HIMAGELIST ---
	ImageList_Destroy :: proc(himl: HIMAGELIST) -> BOOL ---
	ImageList_GetImageCount :: proc(himl: HIMAGELIST) -> i32 ---
	ImageList_SetImageCount :: proc(himl: HIMAGELIST, uNewCount: UINT) -> BOOL ---
	ImageList_Add :: proc(himl: HIMAGELIST, hbmImage, hbmMask: HBITMAP) -> i32 ---
	ImageList_ReplaceIcon :: proc(himl: HIMAGELIST, i: i32, hicon: HICON) -> i32 ---
	ImageList_SetBkColor :: proc(himl: HIMAGELIST, clrBk: COLORREF) -> COLORREF ---
	ImageList_GetBkColor :: proc(himl: HIMAGELIST) -> COLORREF ---
	ImageList_SetOverlayImage :: proc(himl: HIMAGELIST, iImage: i32, iOverlay: i32) -> BOOL ---
	ImageList_Draw :: proc(himl: HIMAGELIST, i: i32, hdcDst: HDC, x, y: i32, fStyle: UINT) -> BOOL ---
	ImageList_Replace :: proc(himl: HIMAGELIST, i: i32, hbmImage, hbmMask: HBITMAP) -> BOOL ---
	ImageList_AddMasked :: proc(himl: HIMAGELIST, hbmImage: HBITMAP, crMask: COLORREF) -> i32 ---
	ImageList_DrawEx :: proc(himl: HIMAGELIST, i: i32, hdcDst: HDC, x, y, dx, dy: i32, rgbBk, rgbFg: COLORREF, fStyle: UINT) -> BOOL ---
	ImageList_DrawIndirect :: proc(pimldp: ^IMAGELISTDRAWPARAMS) -> BOOL ---
	ImageList_Remove :: proc(himl: HIMAGELIST, i: i32) -> BOOL ---
	ImageList_GetIcon :: proc(himl: HIMAGELIST, i: i32, flags: UINT) -> HICON ---
	ImageList_LoadImageW :: proc(hi: HINSTANCE, lpbmp: LPCWSTR, cx, cgrow: i32, crMask: COLORREF, uType, uFlags: UINT) -> HIMAGELIST ---
	ImageList_Copy :: proc(himlDst: HIMAGELIST, iDst: i32, himlSrc: HIMAGELIST, iSrc: i32, uFlags: UINT) -> BOOL ---
	ImageList_BeginDrag :: proc(himlTrack: HIMAGELIST, iTrack, dxHotspot, dyHotspot: i32) -> BOOL ---
	ImageList_EndDrag :: proc() ---
	ImageList_DragEnter :: proc(hwndLock: HWND, x, y: i32) -> BOOL ---
	ImageList_DragLeave :: proc(hwndLock: HWND) -> BOOL ---
	ImageList_DragMove :: proc(x, y: i32) -> BOOL ---
	ImageList_SetDragCursorImage :: proc(himlDrag: HIMAGELIST, iDrag, dxHotspot, dyHotspot: i32) -> BOOL ---
	ImageList_DragShowNolock :: proc(fShow: BOOL) -> BOOL ---
	ImageList_GetDragImage :: proc(ppt, pptHotspot: ^POINT) -> HIMAGELIST ---
	ImageList_Read :: proc(pstm: ^IStream) -> HIMAGELIST ---
	ImageList_Write :: proc(himl: HIMAGELIST, pstm: ^IStream) -> BOOL ---
	ImageList_ReadEx :: proc(dwFlags: DWORD, pstm: ^IStream, riid: REFIID, ppv: PVOID) -> HRESULT ---
	ImageList_WriteEx :: proc(himl: HIMAGELIST, dwFlags: DWORD, pstm: ^IStream) -> HRESULT ---
	ImageList_GetIconSize :: proc(himl: HIMAGELIST, cx, cy: ^i32) -> BOOL ---
	ImageList_SetIconSize :: proc(himl: HIMAGELIST, cx, cy: i32) -> BOOL ---
	ImageList_GetImageInfo :: proc(himl: HIMAGELIST, i: i32, pImageInfo: ^IMAGEINFO) -> BOOL ---
	ImageList_Merge :: proc(himl1: HIMAGELIST, i1: i32, himl2: HIMAGELIST, i2: i32, dx, dy: i32) -> HIMAGELIST ---
	ImageList_Duplicate :: proc(himl: HIMAGELIST) -> HIMAGELIST ---
	HIMAGELIST_QueryInterface :: proc(himl: HIMAGELIST, riid: REFIID, ppv: rawptr) -> HRESULT ---
}

ImageList_AddIcon :: #force_inline proc "system" (himl: HIMAGELIST, hicon: HICON) -> i32 {
	return ImageList_ReplaceIcon(himl, -1, hicon)
}
ImageList_RemoveAll :: #force_inline proc "system" (himl: HIMAGELIST) -> BOOL {
	return ImageList_Remove(himl, -1)
}
ImageList_ExtractIcon :: #force_inline proc "system" (hi: HINSTANCE, himl: HIMAGELIST, i: i32) -> HICON {
	return ImageList_GetIcon(himl, i, 0)
}
ImageList_LoadBitmap :: #force_inline proc "system" (hi: HINSTANCE, lpbmp: LPCWSTR, cx, cGrow: i32, crMask: COLORREF) -> HIMAGELIST {
	return ImageList_LoadImageW(hi, lpbmp, cx, cGrow, crMask, IMAGE_BITMAP, 0)
}

// Status Bar Control
SBT_NOBORDERS    :: 0x0100
SBT_POPOUT       :: 0x0200
SBT_RTLREADING   :: 0x0400
SBT_NOTABPARSING :: 0x0800
SBT_OWNERDRAW    :: 0x1000

SBN_SIMPLEMODECHANGE :: SBN_FIRST - 0

SB_SIMPLEID :: 0xFF

@(default_calling_convention="system")
foreign Comctl32 {
	DrawStatusTextW :: proc(hDC: HDC, lprc: ^RECT, pszText: LPCWSTR, uFlags: UINT) ---
	CreateStatusWindowW :: proc(style: LONG, lpszText: LPCWSTR, hwndParent: HWND, wID: UINT) -> HWND ---
}

// Menu Help
MINSYSCOMMAND :: SC_SIZE

@(default_calling_convention="system")
foreign Comctl32 {
	MenuHelp :: proc(uMsg: UINT, wParam: WPARAM, lParam: LPARAM, hMainMenu: HMENU, hInst: HINSTANCE, hwndStatus: HWND, lpwIDs: ^UINT) ---
	ShowHideMenuCtl :: proc(hWnd: HWND, uFlags: UINT_PTR, lpInfo: LPINT) -> BOOL ---
	GetEffectiveClientRect :: proc(hWnd: HWND, lprc: LPRECT, lpInfo: ^INT) ---
}

// Drag List
DL_CURSORSET  :: 0
DL_STOPCURSOR :: 1
DL_COPYCURSOR :: 2
DL_MOVECURSOR :: 3

DRAGLISTMSGSTRING :: "commctrl_DragListMsg"

@(default_calling_convention="system")
foreign Comctl32 {
	MakeDragList :: proc(hLB: HWND) -> BOOL ---
	DrawInsert :: proc(handParent: HWND, hLB: HWND, nItem: c_int) ---
	LBItemFromPt :: proc(hLB: HWND, pt: POINT, bAutoScroll: BOOL) -> c_int ---
}

// Header Control
HDTEXTFILTERW :: struct {
	pszText: LPWSTR,
	cchTextMax: INT,
}
HD_TEXTFILTERW   :: HDTEXTFILTERW
LPHDTEXTFILTERW  :: ^HDTEXTFILTERW
LPHD_TEXTFILTERW :: LPHDTEXTFILTERW

HDITEMW :: struct {
	mask: UINT,
	cxy: c_int,
	pszText: LPWSTR,
	hbm: HBITMAP,
	cchTextMax: c_int,
	fmt: c_int,
	lParam: LPARAM,
	iImage: c_int,
	iOrder: c_int,
	type: UINT,
	pvFilter: rawptr,
}
HD_ITEMW   :: HDITEMW
LPHDITEMW  :: ^HDITEMW
LPHD_ITEMW :: LPHDITEMW

HDLAYOUT :: struct {
	prc: ^RECT,
	pwpos: ^WINDOWPOS,
}
HD_LAYOUT   :: HDLAYOUT
LPHDLAYOUT  :: ^HDLAYOUT
LPHD_LAYOUT :: LPHDLAYOUT

HDHITTESTINFO :: struct {
	pt: POINT,
	flags: UINT,
	iItem: c_int,
}
HD_HITTESTINFO   :: HDHITTESTINFO
LPHDHITTESTINFO  :: ^HDHITTESTINFO
LPHD_HITTESTINFO :: LPHDHITTESTINFO

NMHEADERW :: struct {
	hdr: NMHDR,
	iItem: c_int,
	iButton: c_int,
	pitem: ^HDITEMW,
}
LPNMHEADERW  :: ^NMHEADERW
HD_NOTIFYW   :: NMHEADERW
LPHD_NOTIFYW :: LPNMHEADERW

NMHDDISPINFOW :: struct {
	hdr: NMHDR,
	iItem: c_int,
	mask: UINT,
	pszText: LPWSTR,
	cchTextMax: c_int,
	iImage: c_int,
	lParam: LPARAM,
}
LPNMHDDISPINFOW :: ^NMHDDISPINFOW

NMHDFILTERBTNCLICK :: struct {
	hdr: NMHDR,
	iItem: c_int,
	rc: RECT,
}
LPNMHDFILTERBTNCLICK :: ^NMHDFILTERBTNCLICK

Header_GetItemCount :: #force_inline proc "system" (hwndHD: HWND) -> c_int {
	return cast(c_int)SendMessageW(hwndHD, HDM_GETITEMCOUNT, 0, 0)
}
Header_InsertItem :: #force_inline proc "system" (hwndHD: HWND, i: c_int, phdi: ^HD_ITEMW) -> c_int {
	return cast(c_int)SendMessageW(hwndHD, HDM_INSERTITEMW, cast(WPARAM)i, cast(LPARAM)uintptr(phdi))
}
Header_DeleteItem :: #force_inline proc "system" (hwndHD: HWND, i: c_int) -> BOOL {
	return cast(BOOL)SendMessageW(hwndHD, HDM_DELETEITEM, cast(WPARAM)i, 0)
}
Header_GetItem :: #force_inline proc "system" (hwndHD: HWND, i: c_int, phdi: ^HD_ITEMW) -> BOOL {
	return cast(BOOL)SendMessageW(hwndHD, HDM_GETITEMW, cast(WPARAM)i, cast(LPARAM)uintptr(phdi))
}
Header_SetItem :: #force_inline proc "system" (hwndHD: HWND, i: c_int, phdi: ^HD_ITEMW) -> BOOL {
	return cast(BOOL)SendMessageW(hwndHD, HDM_SETITEMW, cast(WPARAM)i, cast(LPARAM)uintptr(phdi))
}
Header_Layout :: #force_inline proc "system" (hwndHD: HWND, playout: ^HD_LAYOUT) -> BOOL {
	return cast(BOOL)SendMessageW(hwndHD, HDM_LAYOUT, 0, cast(LPARAM)uintptr(playout))
}

Header_GetItemRect :: #force_inline proc "system" (hwnd: HWND, iItem: c_int, lprc: ^RECT) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd,HDM_GETITEMRECT,cast(WPARAM)iItem,cast(LPARAM)uintptr(lprc))
}
Header_SetImageList :: #force_inline proc "system" (hwnd: HWND, himl: HIMAGELIST) -> HIMAGELIST {
	return cast(HIMAGELIST)uintptr(SendMessageW(hwnd,HDM_SETIMAGELIST,0,cast(LPARAM)uintptr(himl)))
}
Header_GetImageList :: #force_inline proc "system" (hwnd: HWND) -> HIMAGELIST {
	return cast(HIMAGELIST)uintptr(SendMessageW(hwnd,HDM_GETIMAGELIST,0,0))
}
Header_OrderToIndex :: #force_inline proc "system" (hwnd: HWND, i: c_int) -> c_int {
	return cast(c_int)SendMessageW(hwnd,HDM_ORDERTOINDEX,cast(WPARAM)i,0)
}
Header_CreateDragImage :: #force_inline proc "system" (hwnd: HWND, i: c_int) -> HIMAGELIST {
	return cast(HIMAGELIST)uintptr(SendMessageW(hwnd,HDM_CREATEDRAGIMAGE,cast(WPARAM)i,0))
}
Header_GetOrderArray :: #force_inline proc "system" (hwnd: HWND, iCount: c_int, lpi: ^c_int) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd,HDM_GETORDERARRAY,cast(WPARAM)iCount,cast(LPARAM)uintptr(lpi))
}
Header_SetOrderArray :: #force_inline proc "system" (hwnd: HWND, iCount: c_int, lpi: ^c_int) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd,HDM_SETORDERARRAY,cast(WPARAM)iCount,cast(LPARAM)uintptr(lpi))
}
Header_SetHotDivider :: #force_inline proc "system" (hwnd: HWND, fPos: BOOL, dw: DWORD) -> c_int {
	return cast(c_int)SendMessageW(hwnd,HDM_SETHOTDIVIDER,cast(WPARAM)fPos,cast(LPARAM)dw)
}
Header_SetBitmapMargin :: #force_inline proc "system" (hwnd: HWND, iWidth: c_int) -> c_int {
	return cast(c_int)SendMessageW(hwnd,HDM_SETBITMAPMARGIN,cast(WPARAM)iWidth,0)
}
Header_GetBitmapMargin :: #force_inline proc "system" (hwnd: HWND) -> c_int {
	return cast(c_int)SendMessageW(hwnd,HDM_GETBITMAPMARGIN,0,0)
}
Header_SetUnicodeFormat :: #force_inline proc "system" (hwnd: HWND, fUnicode: BOOL) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd,HDM_SETUNICODEFORMAT,cast(WPARAM)fUnicode,0)
}
Header_GetUnicodeFormat :: #force_inline proc "system" (hwnd: HWND) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd,HDM_GETUNICODEFORMAT,0,0)
}
Header_SetFilterChangeTimeout :: #force_inline proc "system" (hwnd: HWND, i: c_int) -> c_int {
	return cast(c_int)SendMessageW(hwnd,HDM_SETFILTERCHANGETIMEOUT,0,cast(LPARAM)i)
}
Header_EditFilter :: #force_inline proc "system" (hwnd: HWND, i: c_int, fDiscardChanges: BOOL) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd,HDM_EDITFILTER,cast(WPARAM)i,MAKELPARAM(fDiscardChanges,0))
}
Header_ClearFilter :: #force_inline proc "system" (hwnd: HWND, i: c_int) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd,HDM_CLEARFILTER,cast(WPARAM)i,0)
}
Header_ClearAllFilters :: #force_inline proc "system" (hwnd: HWND) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd,HDM_CLEARFILTER,~WPARAM(0),0)
}

// Toolbar Control
COLORSCHEME :: struct {
	dwSize: DWORD,
	clrBtnHighlight: COLORREF,
	clrBtnShadow: COLORREF,
}
LPCOLORSCHEME :: ^COLORSCHEME

COLORMAP :: struct {
	from: COLORREF,
	to: COLORREF,
}
LPCOLORMAP :: ^COLORMAP

TBBUTTON :: struct {
	iBitmap: c_int,
	idCommand: c_int,
	fsState: BYTE,
	fsStyle: BYTE,
	bReserved: [size_of(uintptr) - 2]BYTE,
	dwData: DWORD_PTR,
	iString: INT_PTR,
}
PTBBUTTON   :: ^TBBUTTON
LPTBBUTTON  :: ^TBBUTTON
LPCTBBUTTON :: ^TBBUTTON

TBADDBITMAP :: struct {
	hInst: HINSTANCE,
	nID: UINT_PTR,
}
LPTBADDBITMAP :: ^TBADDBITMAP

TBSAVEPARAMSW :: struct {
	hkr: HKEY,
	pszSubKey: LPCWSTR,
	pszValueName: LPCWSTR,
}

TBINSERTMARK :: struct {
	iButton: c_int,
	dwFlags: DWORD,
}
LPTBINSERTMARK :: ^TBINSERTMARK

TBREPLACEBITMAP :: struct {
	hInstOld: HINSTANCE,
	nIDOld: UINT_PTR,
	hInstNew: HINSTANCE,
	nIDNew: UINT_PTR,
	nButtons: c_int,
}
LPTBREPLACEBITMAP :: ^TBREPLACEBITMAP

TBBUTTONINFOW :: struct {
	cbSize: UINT,
	dwMask: DWORD,
	idCommand: c_int,
	iImage: c_int,
	fsState: BYTE,
	fsStyle: BYTE,
	cx: WORD,
	lParam: DWORD_PTR,
	pszText: LPWSTR,
	cchText: c_int,
}
LPTBBUTTONINFOW :: ^TBBUTTONINFOW

TBMETRICS :: struct {
	cbSize: UINT,
	dwMask: DWORD,
	cxPad: c_int,
	cyPad: c_int,
	cxBarPad: c_int,
	cyBarPad: c_int,
	cxButtonSpacing: c_int,
	cyButtonSpacing: c_int,
}
LPTBMETRICS :: ^TBMETRICS

NMTTCUSTOMDRAW :: struct {
	nmcd: NMCUSTOMDRAW,
	uDrawFlags: UINT,
}
LPNMTTCUSTOMDRAW :: ^NMTTCUSTOMDRAW

@(default_calling_convention="system")
foreign Comctl32 {
	CreateToolbarEx :: proc(hwnd: HWND, ws: DWORD, wID: UINT, nBitmaps: c_int, hBMInst: HINSTANCE, wBMID: UINT_PTR, lpButtons: LPCTBBUTTON, iNumButtons: c_int, dxButton,dyButton: c_int, dxBitmap,dyBitmap: c_int, uStructSize: UINT) -> HWND ---
	CreateMappedBitmap :: proc(hInstance: HINSTANCE, idBitmap: INT_PTR, wFlags: UINT, lpColorMap: LPCOLORMAP, iNumMaps: c_int) -> HBITMAP ---
}

// Button Control
BUTTON_IMAGELIST_ALIGN_LEFT   :: 0
BUTTON_IMAGELIST_ALIGN_RIGHT  :: 1
BUTTON_IMAGELIST_ALIGN_TOP    :: 2
BUTTON_IMAGELIST_ALIGN_BOTTOM :: 3
BUTTON_IMAGELIST_ALIGN_CENTER :: 4

BCSIF_GLYPH :: 0x0001
BCSIF_IMAGE :: 0x0002
BCSIF_STYLE :: 0x0004
BCSIF_SIZE  :: 0x0008

BCSS_NOSPLIT   :: 0x0001
BCSS_STRETCH   :: 0x0002
BCSS_ALIGNLEFT :: 0x0004
BCSS_IMAGE     :: 0x0008

BUTTON_IMAGELIST :: struct {
	himl: HIMAGELIST,
	margin: RECT,
	uAlign: UINT,
}
PBUTTON_IMAGELIST :: ^BUTTON_IMAGELIST

BUTTON_SPLITINFO :: struct {
	mask: UINT,
	himlGlyph: HIMAGELIST,
	uSplitStyle: UINT,
	size: SIZE,
}
PBUTTON_SPLITINFO :: ^BUTTON_SPLITINFO

NMBCHOTITEM :: struct {
	hdr: NMHDR,
	dwFlags: DWORD,
}
LPNMBCHOTITEM :: ^NMBCHOTITEM

NMBCDROPDOWN :: struct {
	hdr: NMHDR,
	rcButton: RECT,
}
LPNMBCDROPDOWN :: ^NMBCDROPDOWN

// BCM_SETIMAGELIST value
BCCL_NOGLYPH :: cast(HIMAGELIST)(~uintptr(0))

Button_GetIdealSize :: #force_inline proc "system" (hwnd: HWND, psize: ^SIZE) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd, BCM_GETIDEALSIZE, 0, cast(LPARAM)uintptr(psize))
}
Button_SetImageList :: #force_inline proc "system" (hwnd: HWND, pbuttonImagelist: PBUTTON_IMAGELIST) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd, BCM_SETIMAGELIST, 0, cast(LPARAM)uintptr(pbuttonImagelist))
}
Button_GetImageList :: #force_inline proc "system" (hwnd: HWND, pbuttonImagelist: PBUTTON_IMAGELIST) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd, BCM_GETIMAGELIST, 0, cast(LPARAM)uintptr(pbuttonImagelist))
}
Button_SetTextMargin :: #force_inline proc "system" (hwnd: HWND, pmargin: ^RECT) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd, BCM_SETTEXTMARGIN, 0, cast(LPARAM)uintptr(pmargin))
}
Button_GetTextMargin :: #force_inline proc "system" (hwnd: HWND, pmargin: ^RECT) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd, BCM_GETTEXTMARGIN, 0, cast(LPARAM)uintptr(pmargin))
}
Button_SetNote :: #force_inline proc "system" (hwnd: HWND, psz: LPCWSTR) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd, BCM_SETNOTE, 0, cast(LPARAM)uintptr(psz))
}
Button_GetNote :: #force_inline proc "system" (hwnd: HWND, psz: LPCWSTR, pcc: ^c_int) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd, BCM_GETNOTE, uintptr(pcc), cast(LPARAM)uintptr(psz))
}
Button_GetNoteLength :: #force_inline proc "system" (hwnd: HWND) -> LRESULT {
	return SendMessageW(hwnd, BCM_GETNOTELENGTH, 0, 0)
}
Button_SetElevationRequiredState :: #force_inline proc "system" (hwnd: HWND, fRequired: BOOL) -> LRESULT {
	return SendMessageW(hwnd, BCM_SETSHIELD, 0, cast(LPARAM)fRequired)
}
Button_SetDropDownState :: #force_inline proc "system" (hwnd: HWND, fDropDown: BOOL) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd, BCM_SETDROPDOWNSTATE, cast(WPARAM)fDropDown, 0)
}
Button_SetSplitInfo :: #force_inline proc "system" (hwnd: HWND, psi: ^BUTTON_SPLITINFO) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd, BCM_SETSPLITINFO, 0, cast(LPARAM)uintptr(psi))
}
Button_GetSplitInfo :: #force_inline proc "system" (hwnd: HWND, psi: ^BUTTON_SPLITINFO) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd, BCM_GETSPLITINFO, 0, cast(LPARAM)uintptr(psi))
}

// Edit Control
EDITBALLOONTIP :: struct {
	cbStruct: DWORD,
	pszTitle: LPCWSTR,
	pszText: LPCWSTR,
	ttiIcon: INT,
}
PEDITBALLOONTIP :: ^EDITBALLOONTIP

Edit_SetCueBannerText :: #force_inline proc "system" (hwnd: HWND, lpcwText: LPCWSTR) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd, EM_SETCUEBANNER, 0, cast(LPARAM)uintptr(lpcwText))
}
Edit_SetCueBannerTextFocused :: #force_inline proc "system" (hwnd: HWND, lpcwText: LPCWSTR, fDrawFocused: BOOL) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd, EM_SETCUEBANNER, cast(WPARAM)fDrawFocused, cast(LPARAM)uintptr(lpcwText))
}
Edit_GetCueBannerText :: #force_inline proc "system" (hwnd: HWND, lpwText: LPWSTR, cchText: LONG) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd, EM_GETCUEBANNER, uintptr(lpwText), cast(LPARAM)cchText)
}
Edit_ShowBalloonTip :: #force_inline proc "system" (hwnd: HWND, peditballoontip: PEDITBALLOONTIP) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd, EM_SHOWBALLOONTIP, 0, cast(LPARAM)uintptr(peditballoontip))
}
Edit_HideBalloonTip :: #force_inline proc "system" (hwnd: HWND) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd, EM_HIDEBALLOONTIP, 0, 0)
}

Edit_SetHilite :: #force_inline proc "system" (hwndCtl: HWND, ichStart: c_int, ichEnd: c_int) {
	SendMessageW(hwndCtl, EM_SETHILITE, cast(WPARAM)ichStart, cast(LPARAM)ichEnd)
}
Edit_GetHilite :: #force_inline proc "system" (hwndCtl: HWND) -> DWORD {
	return cast(DWORD)SendMessageW(hwndCtl, EM_GETHILITE, 0, 0)
}

Edit_NoSetFocus :: #force_inline proc "system" (hwndCtl: HWND) {
	SendMessageW(hwndCtl, EM_NOSETFOCUS, 0, 0)
}
Edit_TakeFocus :: #force_inline proc "system" (hwndCtl: HWND) {
	SendMessageW(hwndCtl, EM_TAKEFOCUS, 0, 0)
}

// Up Down Control
@(default_calling_convention="system")
foreign Comctl32 {
	CreateUpDownControl :: proc(dwStyle: DWORD, x,y: c_int, cx,cy: c_int, hParent: HWND, nID: c_int, hInst: HINSTANCE, hBuddy: HWND, nUpper,nLower,nPos: c_int) -> HWND ---
}

// Progress Bar Control
PBRANGE :: struct {
	iLow: c_int,
	iHigh: c_int,
}
PPBRANGE :: ^PBRANGE

// Hot Key Control
HOTKEYF_SHIFT   :: 0x1
HOTKEYF_CONTROL :: 0x2
HOTKEYF_ALT     :: 0x4
HOTKEYF_EXT     :: 0x8

HKCOMB_NONE :: 0x01
HKCOMB_S    :: 0x02
HKCOMB_C    :: 0x04
HKCOMB_A    :: 0x08
HKCOMB_SC   :: 0x10
HKCOMB_SA   :: 0x20
HKCOMB_CA   :: 0x40
HKCOMB_SCA  :: 0x80

// List View Control
LVSIL_NORMAL :: 0
LVSIL_SMALL  :: 1
LVSIL_STATE  :: 2

LVIF_TEXT        :: 0x001
LVIF_IMAGE       :: 0x002
LVIF_PARAM       :: 0x004
LVIF_STATE       :: 0x008
LVIF_INDENT      :: 0x010
LVIF_GROUPID     :: 0x100
LVIF_COLUMNS     :: 0x200
LVIF_NORECOMPUTE :: 0x800

LVIS_FOCUSED     :: 0x01
LVIS_SELECTED    :: 0x02
LVIS_CUT         :: 0x04
LVIS_DROPHILITED :: 0x08
LVIS_GLOW        :: 0x10
LVIS_ACTIVATING  :: 0x20

LVIS_OVERLAYMASK    :: 0x0F00
LVIS_STATEIMAGEMASK :: 0xF000

LVNI_ALL         :: 0x000
LVNI_FOCUSED     :: 0x001
LVNI_SELECTED    :: 0x002
LVNI_CUT         :: 0x004
LVNI_DROPHILITED :: 0x008
LVNI_ABOVE       :: 0x100
LVNI_BELOW       :: 0x200
LVNI_TOLEFT      :: 0x400
LVNI_TORIGHT     :: 0x800

LVFI_PARAM     :: 0x01
LVFI_STRING    :: 0x02
LVFI_PARTIAL   :: 0x08
LVFI_WRAP      :: 0x20
LVFI_NEARESTXY :: 0x40

I_INDENTCALLBACK :: -1

I_GROUPIDCALLBACK :: -1
I_GROUPIDNONE     :: -2

LPSTR_TEXTCALLBACKW :: cast(LPWSTR)~uintptr(0)

I_IMAGECALLBACK :: -1
I_IMAGENONE     :: -2

I_COLUMNSCALLBACK :: ~UINT(0)

LVIR_BOUNDS       :: 0
LVIR_ICON         :: 1
LVIR_LABEL        :: 2
LVIR_SELECTBOUNDS :: 3

LVHT_NOWHERE         :: 0x1
LVHT_ONITEMICON      :: 0x2
LVHT_ONITEMLABEL     :: 0x4
LVHT_ONITEMSTATEICON :: 0x8
LVHT_ONITEM          :: LVHT_ONITEMICON | LVHT_ONITEMLABEL | LVHT_ONITEMSTATEICON

LVHT_ABOVE           :: 0x08
LVHT_BELOW           :: 0x10
LVHT_TORIGHT         :: 0x20
LVHT_TOLEFT          :: 0x40

LVA_DEFAULT    :: 0x0
LVA_ALIGNLEFT  :: 0x1
LVA_ALIGNTOP   :: 0x2
LVA_SNAPTOGRID :: 0x5

LVCF_FMT          :: 0x001
LVCF_WIDTH        :: 0x002
LVCF_TEXT         :: 0x004
LVCF_SUBITEM      :: 0x008
LVCF_IMAGE        :: 0x010
LVCF_ORDER        :: 0x020
LVCF_MINWIDTH     :: 0x040
LVCF_DEFAULTWIDTH :: 0x080
LVCF_IDEALWIDTH   :: 0x100

LVCFMT_LEFT            :: 0x0000000
LVCFMT_RIGHT           :: 0x0000001
LVCFMT_CENTER          :: 0x0000002
LVCFMT_FIXED_WIDTH     :: 0x0000100
LVCFMT_IMAGE           :: 0x0000800
LVCFMT_BITMAP_ON_RIGHT :: 0x0001000
LVCFMT_COL_HAS_IMAGES  :: 0x0008000
LVCFMT_NO_DPI_SCALE    :: 0x0040000
LVCFMT_FIXED_RATIO     :: 0x0080000
LVCFMT_LINE_BREAK      :: 0x0100000
LVCFMT_FILL            :: 0x0200000
LVCFMT_WRAP            :: 0x0400000
LVCFMT_NO_TITLE        :: 0x0800000
LVCFMT_SPLITBUTTON     :: 0x1000000

LVCFMT_JUSTIFYMASK        :: 0x3
LVCFMT_TILE_PLACEMENTMASK :: (LVCFMT_LINE_BREAK|LVCFMT_FILL)

LVSCW_AUTOSIZE           :: -1
LVSCW_AUTOSIZE_USEHEADER :: -2

LVSICF_NOINVALIDATEALL :: 0x1
LVSICF_NOSCROLL        :: 0x2

LVS_EX_GRIDLINES             :: 0x00000001
LVS_EX_SUBITEMIMAGES         :: 0x00000002
LVS_EX_CHECKBOXES            :: 0x00000004
LVS_EX_TRACKSELECT           :: 0x00000008
LVS_EX_HEADERDRAGDROP        :: 0x00000010
LVS_EX_FULLROWSELECT         :: 0x00000020
LVS_EX_ONECLICKACTIVATE      :: 0x00000040
LVS_EX_TWOCLICKACTIVATE      :: 0x00000080
LVS_EX_FLATSB                :: 0x00000100
LVS_EX_REGIONAL              :: 0x00000200
LVS_EX_INFOTIP               :: 0x00000400
LVS_EX_UNDERLINEHOT          :: 0x00000800
LVS_EX_UNDERLINECOLD         :: 0x00001000
LVS_EX_MULTIWORKAREAS        :: 0x00002000
LVS_EX_LABELTIP              :: 0x00004000
LVS_EX_BORDERSELECT          :: 0x00008000
LVS_EX_DOUBLEBUFFER          :: 0x00010000
LVS_EX_HIDELABELS            :: 0x00020000
LVS_EX_SINGLEROW             :: 0x00040000
LVS_EX_SNAPTOGRID            :: 0x00080000
LVS_EX_SIMPLESELECT          :: 0x00100000
LVS_EX_JUSTIFYCOLUMNS        :: 0x00200000
LVS_EX_TRANSPARENTBKGND      :: 0x00400000
LVS_EX_TRANSPARENTSHADOWTEXT :: 0x00800000
LVS_EX_AUTOAUTOARRANGE       :: 0x01000000
LVS_EX_HEADERINALLVIEWS      :: 0x02000000
LVS_EX_AUTOCHECKSELECT       :: 0x08000000
LVS_EX_AUTOSIZECOLUMNS       :: 0x10000000
LVS_EX_COLUMNSNAPPOINTS      :: 0x40000000
LVS_EX_COLUMNOVERFLOW        :: 0x80000000

LV_MAX_WORKAREAS :: 16

LVBKIF_SOURCE_NONE    :: 0x0
LVBKIF_SOURCE_HBITMAP :: 0x1
LVBKIF_SOURCE_URL     :: 0x2
LVBKIF_SOURCE_MASK    :: 0x3

LVBKIF_STYLE_NORMAL :: 0x00
LVBKIF_STYLE_TILE   :: 0x10
LVBKIF_STYLE_MASK   :: 0x10

LVBKIF_FLAG_TILEOFFSET :: 0x100

LVBKIF_TYPE_WATERMARK :: 0x10000000

LV_VIEW_ICON      :: 0x0
LV_VIEW_DETAILS   :: 0x1
LV_VIEW_SMALLICON :: 0x2
LV_VIEW_LIST      :: 0x3
LV_VIEW_TILE      :: 0x4
LV_VIEW_MAX       :: 0x4

LVGF_NONE    :: 0x00
LVGF_HEADER  :: 0x01
LVGF_FOOTER  :: 0x02
LVGF_STATE   :: 0x04
LVGF_ALIGN   :: 0x08
LVGF_GROUPID :: 0x10

LVGS_NORMAL    :: 0x0
LVGS_COLLAPSED :: 0x1
LVGS_HIDDEN    :: 0x2

LVGA_HEADER_LEFT   :: 0x1
LVGA_HEADER_CENTER :: 0x2
LVGA_HEADER_RIGHT  :: 0x4
LVGA_FOOTER_LEFT   :: 0x8
LVGA_FOOTER_CENTER :: 0x10
LVGA_FOOTER_RIGHT  :: 0x20

LVGMF_NONE        :: 0x0
LVGMF_BORDERSIZE  :: 0x1
LVGMF_BORDERCOLOR :: 0x2
LVGMF_TEXTCOLOR   :: 0x4

LVTVIF_AUTOSIZE    :: 0x0
LVTVIF_FIXEDWIDTH  :: 0x1
LVTVIF_FIXEDHEIGHT :: 0x2
LVTVIF_FIXEDSIZE   :: 0x3

LVTVIM_TILESIZE    :: 0x1
LVTVIM_COLUMNS     :: 0x2
LVTVIM_LABELMARGIN :: 0x4

LVIM_AFTER :: 0x1

LVKF_ALT     :: 0x1
LVKF_CONTROL :: 0x2
LVKF_SHIFT   :: 0x4

LVCDI_ITEM  :: 0x0
LVCDI_GROUP :: 0x1

LVCDRF_NOSELECT     :: 0x10000
LVCDRF_NOGROUPFRAME :: 0x20000

LVN_ITEMCHANGING    :: (LVN_FIRST-0)
LVN_ITEMCHANGED     :: (LVN_FIRST-1)
LVN_INSERTITEM      :: (LVN_FIRST-2)
LVN_DELETEITEM      :: (LVN_FIRST-3)
LVN_DELETEALLITEMS  :: (LVN_FIRST-4)
LVN_BEGINLABELEDITA :: (LVN_FIRST-5)
LVN_BEGINLABELEDITW :: (LVN_FIRST-75)
LVN_ENDLABELEDITA   :: (LVN_FIRST-6)
LVN_ENDLABELEDITW   :: (LVN_FIRST-76)
LVN_COLUMNCLICK     :: (LVN_FIRST-8)
LVN_BEGINDRAG       :: (LVN_FIRST-9)
LVN_BEGINRDRAG      :: (LVN_FIRST-11)
LVN_ODCACHEHINT     :: (LVN_FIRST-13)
LVN_ODFINDITEMA     :: (LVN_FIRST-52)
LVN_ODFINDITEMW     :: (LVN_FIRST-79)
LVN_ITEMACTIVATE    :: (LVN_FIRST-14)
LVN_ODSTATECHANGED  :: (LVN_FIRST-15)
LVN_HOTTRACK        :: (LVN_FIRST-21)
LVN_GETDISPINFOA    :: (LVN_FIRST-50)
LVN_GETDISPINFOW    :: (LVN_FIRST-77)
LVN_SETDISPINFOA    :: (LVN_FIRST-51)
LVN_SETDISPINFOW    :: (LVN_FIRST-78)
LVN_KEYDOWN         :: (LVN_FIRST-55)
LVN_MARQUEEBEGIN    :: (LVN_FIRST-56)
LVN_GETINFOTIPA     :: (LVN_FIRST-57)
LVN_GETINFOTIPW     :: (LVN_FIRST-58)
LVN_BEGINSCROLL     :: (LVN_FIRST-80)
LVN_ENDSCROLL       :: (LVN_FIRST-81)

LVIF_DI_SETITEM :: 0x1000

LVGIT_UNFOLDED :: 0x1

LVITEMW :: struct {
	mask: UINT,
	iItem: c_int,
	iSubItem: c_int,
	state: UINT,
	stateMask: UINT,
	pszText: LPWSTR,
	cchTextMax: c_int,
	iImage: c_int,
	lParam: LPARAM,
	iIndent: c_int,
	iGroupId: c_int,
	cColumns: UINT,
	puColumns: PUINT,
}
LV_ITEMW   :: LVITEMW
LPLVITEMW  :: ^LVITEMW
LPLV_ITEMW :: LPLVITEMW

LVFINDINFOW :: struct {
	flags: UINT,
	psz: LPCWSTR,
	lParam: LPARAM,
	pt: POINT,
	vkDirection: UINT,
}
LPFINDINFOW  :: ^LVFINDINFOW
LV_FINDINFOW :: LVFINDINFOW

LVHITTESTINFO :: struct {
	pt: POINT,
	flags: UINT,
	iItem: c_int,
	iSubItem: c_int,
}
LV_HITTESTINFO   :: LVHITTESTINFO
LPLVHITTESTINFO  :: ^LVHITTESTINFO
LPLV_HITTESTINFO :: LPLVHITTESTINFO

LVCOLUMNW :: struct {
	mask: UINT,
	fmt: c_int,
	cx: c_int,
	pszText: LPWSTR,
	cchTextMax: c_int,
	iSubItem: c_int,
	iImage: c_int,
	iOrder: c_int,
	cxMin: c_int,
	cxDefault: c_int,
	cxIdeal: c_int,
}
LV_COLUMNW   :: LVCOLUMNW
LPLVCOLUMNW  :: ^LVCOLUMNW
LPLV_COLUMNW :: LPLVCOLUMNW

LVBKIMAGEW :: struct {
	ulFlags: ULONG,
	hbm: HBITMAP,
	pszImage: LPWSTR,
	cchImageMax: UINT,
	xOffsetPercent: c_int,
	yOffsetPercent: c_int,
}
LV_BKIMAGEW   :: LVBKIMAGEW
LPLVBKIMAGEW  :: ^LVBKIMAGEW
LPLV_BKIMAGEW :: LPLVBKIMAGEW

LVGROUP :: struct {
	cbSize: UINT,
	mask: UINT,
	pszHeader: LPWSTR,
	cchHeader: c_int,
	pszFooter: LPWSTR,
	cchFooter: c_int,
	iGroupId: c_int,
	stateMask: UINT,
	state: UINT,
	uAlign: UINT,
}
PLVGROUP :: ^LVGROUP

LVGROUPMETRICS :: struct {
	cbSize: UINT,
	mask: UINT,
	Left: UINT,
	Top: UINT,
	Right: UINT,
	Bottom: UINT,
	crLeft: COLORREF,
	crTop: COLORREF,
	crRight: COLORREF,
	crBottom: COLORREF,
	crHeader: COLORREF,
	crFooter: COLORREF,
}
PLVGROUPMETRICS :: ^LVGROUPMETRICS

LVINSERTGROUPSORTED :: struct {
	pfnGroupCompare: PFNLVGROUPCOMPARE,
	pvData: rawptr,
	lvGroup: LVGROUP,
}
PLVINSERTGROUPSORTED :: ^LVINSERTGROUPSORTED

LVTILEVIEWINFO :: struct {
	cbSize: UINT,
	dwMask: DWORD,
	dwFlags: DWORD,
	sizeTile: SIZE,
	cLines: c_int,
	rcLabelMargin: RECT,
}
PLVTILEVIEWINFO :: ^LVTILEVIEWINFO

LVTILEINFO :: struct {
	cbSize: UINT,
	iItem: c_int,
	cColumns: UINT,
	puColumns: PUINT,
}
PLVTILEINFO :: ^LVTILEINFO

LVINSERTMARK :: struct {
	cbSize: UINT,
	dwFlags: DWORD,
	iItem: c_int,
	dwReserved: DWORD,
}
LPLVINSERTMARK :: ^LVINSERTMARK

LVSETINFOTIP :: struct {
	cbSize: UINT,
	dwFlags: DWORD,
	pszText: LPWSTR,
	iItem: c_int,
	iSubItem: c_int,
}
PLVSETINFOTIP :: ^LVSETINFOTIP

NMLISTVIEW :: struct {
	hdr: NMHDR,
	iItem: c_int,
	iSubItem: c_int,
	uNewState: UINT,
	uOldState: UINT,
	uChanged: UINT,
	ptAction: POINT,
	lParam: LPARAM,
}
NM_LISTVIEW   :: NMLISTVIEW
LPNMLISTVIEW  :: ^NMLISTVIEW
LPNM_LISTVIEW :: LPNMLISTVIEW

NMITEMACTIVATE :: struct {
	hdr: NMHDR,
	iItem: c_int,
	iSubItem: c_int,
	uNewState: UINT,
	uOldState: UINT,
	uChanged: UINT,
	ptAction: POINT,
	lParam: LPARAM,
	uKeyFlags: UINT,
}
NM_ITEMACTIVATE   :: NMITEMACTIVATE
LPNMITEMACTIVATE  :: ^NMITEMACTIVATE
LPNM_ITEMACTIVATE :: LPNMITEMACTIVATE

NMLVCUSTOMDRAW :: struct {
	nmcd: NMCUSTOMDRAW,
	clrText: COLORREF,
	clrTextBk: COLORREF,
	iSubItem: c_int,
	dwItemType: DWORD,
	clrFace: COLORREF,
	iIconEffect: c_int,
	iIconPhase: c_int,
	iPartId: c_int,
	iStateId: c_int,
	rcText: RECT,
	uAlign: UINT,
}
NMLV_CUSTOMDRAW   :: NMLVCUSTOMDRAW
LPNMLVCUSTOMDRAW  :: ^NMLVCUSTOMDRAW
LPNMLV_CUSTOMDRAW :: LPNMLVCUSTOMDRAW

NMLVCACHEHINT :: struct {
	hdr: NMHDR,
	iFrom: c_int,
	iTo: c_int,
}
LPNMLVCACHEHINT :: ^NMLVCACHEHINT
NM_CACHEHINT    :: NMLVCACHEHINT
PNM_CACHEHINT   :: LPNMLVCACHEHINT
LPNM_CACHEHINT  :: LPNMLVCACHEHINT

NMLVFINDITEMW :: struct {
	hdr: NMHDR,
	iStart: c_int,
	lvfi: LVFINDINFOW,
}
LPNMLVFINDITEMW :: ^NMLVFINDITEMW
NM_FINDITEMW    :: NMLVFINDITEMW
PNM_FINDITEMW   :: LPNMLVFINDITEMW
LPNM_FINDITEMW  :: LPNMLVFINDITEMW

NMLVODSTATECHANGE :: struct {
	hdr: NMHDR,
	iFrom: c_int,
	iTo: c_int,
	uNewState: UINT,
	uOldState: UINT,
}
LPNMLVODSTATECHANGE :: ^NMLVODSTATECHANGE
NM_ODSTATECHANGE    :: NMLVODSTATECHANGE
PNM_ODSTATECHANGE   :: NMLVODSTATECHANGE
LPNM_ODSTATECHANGE  :: LPNMLVODSTATECHANGE

LVDISPINFOW :: struct {
	hdr: NMHDR,
	item: LVITEMW,
}
LV_DISPINFO      :: LVDISPINFOW
LPNMLVDISPINFOW  :: ^LVDISPINFOW

NMLVKEYDOWN :: struct #packed {
	hdr: NMHDR,
	wVKey: WORD,
	flags: UINT,
}
LV_KEYDOWN    :: NMLVKEYDOWN
LPNMLVKEYDOWN :: ^NMLVKEYDOWN

NMLVGETINFOTIPW :: struct {
	hdr: NMHDR,
	dwFlags: DWORD,
	pszText: LPWSTR,
	cchTextMax: c_int,
	iItem: c_int,
	iSubItem: c_int,
	lParam: LPARAM,
}
LPNMLVGETINFOTIPW :: ^NMLVGETINFOTIPW

NMLVSCROLL :: struct {
	hdr: NMHDR,
	dx: c_int,
	dy: c_int,
}
LPNMLVSCROLL :: ^NMLVSCROLL

PFNLVCOMPARE      :: #type proc "system" (lpItem1,lpItem2: LPARAM, lpUser: LPARAM) -> c_int
PFNLVGROUPCOMPARE :: #type proc "system" (item1,item2: c_int, user: rawptr) -> c_int

INDEXTOSTATEIMAGEMASK :: #force_inline proc "system" (i: UINT) -> UINT {
	return i << 12
}

ListView_GetItem :: #force_inline proc "system" (hwnd: HWND, pitem: ^LV_ITEMW) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd, LVM_GETITEMW, 0, cast(LPARAM)uintptr(pitem))
}
ListView_SetItem :: #force_inline proc "system" (hwnd: HWND, pitem: ^LV_ITEMW) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd, LVM_SETITEMW, 0, cast(LPARAM)uintptr(pitem))
}
ListView_InsertItem :: #force_inline proc "system" (hwnd: HWND, pitem: ^LV_ITEMW) -> c_int {
	return cast(c_int)SendMessageW(hwnd, LVM_INSERTITEMW, 0, cast(LPARAM)uintptr(pitem))
}
ListView_DeleteItem :: #force_inline proc "system" (hwnd: HWND, i: c_int) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd, LVM_DELETEITEM, cast(WPARAM)i, 0)
}
ListView_DeleteAllItems :: #force_inline proc "system" (hwnd: HWND) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd, LVM_DELETEALLITEMS, 0, 0)
}
ListView_GetCallbackMask :: #force_inline proc "system" (hwnd: HWND) -> UINT {
	return cast(UINT)SendMessageW(hwnd, LVM_GETCALLBACKMASK, 0, 0)
}
ListView_SetCallbackMask :: #force_inline proc "system" (hwnd: HWND, mask: UINT) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd, LVM_SETCALLBACKMASK, cast(WPARAM)mask, 0)
}
ListView_GetNextItem :: #force_inline proc "system" (hwnd: HWND, i: c_int, flags: UINT) -> c_int {
	return cast(c_int)SendMessageW(hwnd, LVM_GETNEXTITEM, cast(WPARAM)i, MAKELPARAM(flags,0))
}
ListView_FindItem :: #force_inline proc "system" (hwnd: HWND, iStart: c_int, plvfi: ^LV_FINDINFOW) -> c_int {
	return cast(c_int)SendMessageW(hwnd, LVM_FINDITEMW, cast(WPARAM)iStart, cast(LPARAM)uintptr(plvfi))
}
ListView_GetItemRect :: #force_inline proc "system" (hwnd: HWND, i: c_int, prc: ^RECT, code: c_int) -> BOOL {
	if prc != nil {
		prc.left = code
	}
	return cast(BOOL)SendMessageW(hwnd, LVM_GETITEMRECT, cast(WPARAM)i, cast(LPARAM)uintptr(prc))
}
ListView_SetItemPosition :: #force_inline proc "system" (hwnd: HWND, i: c_int, x,y: c_int) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd, LVM_SETITEMPOSITION, cast(WPARAM)i, MAKELPARAM(x,y))
}
ListView_GetItemPosition :: #force_inline proc "system" (hwnd: HWND, i: c_int, ppt: ^POINT) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd, LVM_GETITEMPOSITION, cast(WPARAM)i, cast(LPARAM)uintptr(ppt))
}
ListView_GetStringWidth :: #force_inline proc "system" (hwndLV: HWND, psz: LPCWSTR) -> c_int {
	return cast(c_int)SendMessageW(hwndLV, LVM_GETSTRINGWIDTHW, 0, cast(LPARAM)uintptr(psz))
}
ListView_HitTest :: #force_inline proc "system" (hwndLV: HWND, pinfo: ^LV_HITTESTINFO) -> c_int {
	return cast(c_int)SendMessageW(hwndLV, LVM_HITTEST, 0, cast(LPARAM)uintptr(pinfo))
}
ListView_EnsureVisible :: #force_inline proc "system" (hwndLV: HWND, i: c_int, fPartialOK: BOOL) -> BOOL {
	return cast(BOOL)SendMessageW(hwndLV, LVM_ENSUREVISIBLE, cast(WPARAM)i, MAKELPARAM(fPartialOK,0))
}
ListView_Scroll :: #force_inline proc "system" (hwndLV: HWND, dx,dy: c_int) -> BOOL {
	return cast(BOOL)SendMessageW(hwndLV, LVM_SCROLL, cast(WPARAM)dx, cast(LPARAM)dy)
}
ListView_RedrawItems :: #force_inline proc "system" (hwndLV: HWND, iFirst,iLast: c_int) -> BOOL {
	return cast(BOOL)SendMessageW(hwndLV, LVM_REDRAWITEMS, cast(WPARAM)iFirst, cast(LPARAM)iLast)
}
ListView_Arrange :: #force_inline proc "system" (hwndLV: HWND, code: UINT) -> BOOL {
	return cast(BOOL)SendMessageW(hwndLV, LVM_ARRANGE, cast(WPARAM)code, 0)
}
ListView_EditLabel :: #force_inline proc "system" (hwndLV: HWND, i: c_int) -> HWND {
	return cast(HWND)uintptr(SendMessageW(hwndLV, LVM_EDITLABELW, cast(WPARAM)i, 0))
}
ListView_GetEditControl :: #force_inline proc "system" (hwndLV: HWND) -> HWND {
	return cast(HWND)uintptr(SendMessageW(hwndLV, LVM_GETEDITCONTROL, 0, 0))
}
ListView_GetColumn :: #force_inline proc "system" (hwnd: HWND, iCol: c_int, pcol: ^LV_COLUMNW) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd, LVM_GETCOLUMNW, cast(WPARAM)iCol, cast(LPARAM)uintptr(pcol))
}
ListView_SetColumn :: #force_inline proc "system" (hwnd: HWND, iCol: c_int, pcol: ^LV_COLUMNW) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd, LVM_SETCOLUMNW, cast(WPARAM)iCol, cast(LPARAM)uintptr(pcol))
}
ListView_InsertColumn :: #force_inline proc "system" (hwnd: HWND, iCol: c_int, pcol: ^LV_COLUMNW) -> c_int {
	return cast(c_int)SendMessageW(hwnd, LVM_INSERTCOLUMNW, cast(WPARAM)iCol, cast(LPARAM)uintptr(pcol))
}
ListView_DeleteColumn :: #force_inline proc "system" (hwnd: HWND, iCol: c_int) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd, LVM_DELETECOLUMN, cast(WPARAM)iCol, 0)
}
ListView_GetColumnWidth :: #force_inline proc "system" (hwnd: HWND, iCol: c_int) -> c_int {
	return cast(c_int)SendMessageW(hwnd, LVM_GETCOLUMNWIDTH, cast(WPARAM)iCol, 0)
}
ListView_SetColumnWidth :: #force_inline proc "system" (hwnd: HWND, iCol: c_int, cx: c_int) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd, LVM_SETCOLUMNWIDTH, cast(WPARAM)iCol, MAKELPARAM(cx,0))
}
ListView_GetHeader :: #force_inline proc "system" (hwnd: HWND) -> HWND {
	return cast(HWND)uintptr(SendMessageW(hwnd, LVM_GETHEADER, 0, 0))
}
ListView_CreateDragImage :: #force_inline proc "system" (hwnd: HWND, i: c_int, lpptUpLeft: LPPOINT) -> HIMAGELIST {
	return cast(HIMAGELIST)uintptr(SendMessageW(hwnd, LVM_CREATEDRAGIMAGE, cast(WPARAM)i, cast(LPARAM)uintptr(lpptUpLeft)))
}
ListView_GetViewRect :: #force_inline proc "system" (hwnd: HWND, prc: ^RECT) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd, LVM_GETVIEWRECT, 0, cast(LPARAM)uintptr(prc))
}
ListView_GetTextColor :: #force_inline proc "system" (hwnd: HWND) -> COLORREF {
	return cast(COLORREF)SendMessageW(hwnd, LVM_GETTEXTCOLOR, 0, 0)
}
ListView_SetTextColor :: #force_inline proc "system" (hwnd: HWND, clrText: COLORREF) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd, LVM_SETTEXTCOLOR, 0, cast(LPARAM)clrText)
}
ListView_GetTextBkColor :: #force_inline proc "system" (hwnd: HWND) -> COLORREF {
	return cast(COLORREF)SendMessageW(hwnd, LVM_GETTEXTBKCOLOR, 0, 0)
}
ListView_SetTextBkColor :: #force_inline proc "system" (hwnd: HWND, clrTextBk: COLORREF) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd, LVM_SETTEXTBKCOLOR, 0, cast(LPARAM)clrTextBk)
}
ListView_GetTopIndex :: #force_inline proc "system" (hwndLV: HWND) -> c_int {
	return cast(c_int)SendMessageW(hwndLV, LVM_GETTOPINDEX, 0, 0)
}
ListView_GetCountPerPage :: #force_inline proc "system" (hwndLV: HWND) -> c_int {
	return cast(c_int)SendMessageW(hwndLV, LVM_GETCOUNTPERPAGE, 0, 0)
}
ListView_GetOrigin :: #force_inline proc "system" (hwndLV: HWND, ppt: ^POINT) -> BOOL {
	return cast(BOOL)SendMessageW(hwndLV, LVM_GETORIGIN, 0, cast(LPARAM)uintptr(ppt))
}
ListView_Update :: #force_inline proc "system" (hwndLV: HWND, i: c_int) -> BOOL {
	return cast(BOOL)SendMessageW(hwndLV, LVM_UPDATE, cast(WPARAM)i, 0)
}
ListView_SetItemState :: #force_inline proc "system" (hwndLV: HWND, i: c_int, data: UINT, mask: UINT) {
	item := LV_ITEMW {
		stateMask = mask,
		state     = data,
	}
	SendMessageW(hwndLV, LVM_SETITEMSTATE, cast(WPARAM)i, cast(LPARAM)uintptr(&item))
}
ListView_SetCheckState :: #force_inline proc "system" (hwndLV: HWND, i: c_int, fCheck: BOOL) {
	ListView_SetItemState(hwndLV, i, INDEXTOSTATEIMAGEMASK(2 if fCheck else 1), LVIS_STATEIMAGEMASK)
}
ListView_GetItemState :: #force_inline proc "system" (hwndLV: HWND, i: c_int, mask: UINT) -> UINT {
	return cast(UINT)SendMessageW(hwndLV, LVM_GETITEMSTATE, cast(WPARAM)i, cast(LPARAM)mask)
}
ListView_GetCheckState :: #force_inline proc "system" (hwndLV: HWND, i: c_int) -> UINT {
	return ((cast(UINT)SendMessageW(hwndLV, LVM_GETITEMSTATE, cast(WPARAM)i, cast(LPARAM)LVIS_STATEIMAGEMASK)) >> 12) - 1
}
ListView_GetItemText :: #force_inline proc "system" (hwndLV: HWND, i: c_int, iSubItem: c_int, pszText: LPWSTR, cchTextMax: c_int) {
	item := LV_ITEMW {
		iSubItem   = iSubItem,
		cchTextMax = cchTextMax,
		pszText    = pszText,
	}
	SendMessageW(hwndLV, LVM_GETITEMTEXTW, cast(WPARAM)i, cast(LPARAM)uintptr(&item))
}
ListView_SetItemText :: #force_inline proc "system" (hwndLV: HWND, i: c_int, iSubItem: c_int, pszText: LPWSTR) {
	item := LV_ITEMW {
		iSubItem = iSubItem,
		pszText  = pszText,
	}
	SendMessageW(hwndLV, LVM_SETITEMTEXTW, cast(WPARAM)i, cast(LPARAM)uintptr(&item))
}
ListView_SetItemCount :: #force_inline proc "system" (hwndLV: HWND, cItems: c_int) {
	SendMessageW(hwndLV, LVM_SETITEMCOUNT, cast(WPARAM)cItems, 0)
}
ListView_SetItemCountEx :: #force_inline proc "system" (hwndLV: HWND, cItems: c_int, dwFlags: DWORD) {
	SendMessageW(hwndLV, LVM_SETITEMCOUNT, cast(WPARAM)cItems, cast(LPARAM)dwFlags)
}
ListView_SortItems :: #force_inline proc "system" (hwndLV: HWND, pfnCompare: PFNLVCOMPARE, lpUser: LPARAM) -> BOOL {
	return cast(BOOL)SendMessageW(hwndLV, LVM_SORTITEMS, cast(WPARAM)lpUser, cast(LPARAM)transmute(uintptr)(pfnCompare))
}
ListView_SetItemPosition32 :: #force_inline proc "system" (hwndLV: HWND, i: c_int, x0,y0: c_int) {
	ptNewPos := POINT {
		x = x0,
		y = y0,
	}
	SendMessageW(hwndLV, LVM_SETITEMPOSITION32, cast(WPARAM)i, cast(LPARAM)uintptr(&ptNewPos))
}
ListView_GetSelectedCount :: #force_inline proc "system" (hwndLV: HWND) -> UINT {
	return cast(UINT)SendMessageW(hwndLV, LVM_GETSELECTEDCOUNT, 0, 0)
}
ListView_GetItemSpacing :: #force_inline proc "system" (hwndLV: HWND, fSmall: BOOL) -> DWORD {
	return cast(DWORD)SendMessageW(hwndLV, LVM_GETITEMSPACING, cast(WPARAM)fSmall, 0)
}
ListView_GetISearchString :: #force_inline proc "system" (hwndLV: HWND, lpsz: LPWSTR) -> BOOL {
	return cast(BOOL)SendMessageW(hwndLV, LVM_GETISEARCHSTRINGW, 0, cast(LPARAM)uintptr(lpsz))
}
ListView_SetIconSpacing :: #force_inline proc "system" (hwndLV: HWND, cx,cy: c_int) -> DWORD {
	return cast(DWORD)SendMessageW(hwndLV, LVM_SETICONSPACING, 0, cast(LPARAM)MAKELONG(cx,cy))
}
ListView_SetExtendedListViewStyle :: #force_inline proc "system" (hwndLV: HWND, dw: DWORD) -> DWORD {
	return cast(DWORD)SendMessageW(hwndLV, LVM_SETEXTENDEDLISTVIEWSTYLE, 0, cast(LPARAM)dw)
}
ListView_SetExtendedListViewStyleEx :: #force_inline proc "system" (hwndLV: HWND, dwMask: DWORD, dw: DWORD) -> DWORD {
	return cast(DWORD)SendMessageW(hwndLV, LVM_SETEXTENDEDLISTVIEWSTYLE, cast(WPARAM)dwMask, cast(LPARAM)dw)
}
ListView_GetSubItemRect :: #force_inline proc "system" (hwnd: HWND, iItem: c_int, iSubItem: c_int, code: c_int, prc: LPRECT) -> BOOL {
	if prc != nil {
		prc.top  = iSubItem
		prc.left = code
	}
	return cast(BOOL)SendMessageW(hwnd, LVM_GETSUBITEMRECT, cast(WPARAM)iItem, cast(LPARAM)uintptr(prc))
}
ListView_SubItemHitTest :: #force_inline proc "system" (hwnd: HWND, plvhti: LPLVHITTESTINFO) -> c_int {
	return cast(c_int)SendMessageW(hwnd, LVM_SUBITEMHITTEST, 0, cast(LPARAM)uintptr(plvhti))
}
ListView_SetColumnOrderArray :: #force_inline proc "system" (hwnd: HWND, iCount: c_int, pi: LPINT) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd, LVM_SETCOLUMNORDERARRAY, cast(WPARAM)iCount, cast(LPARAM)uintptr(pi))
}
ListView_GetColumnOrderArray :: #force_inline proc "system" (hwnd: HWND, iCount: c_int, pi: LPINT) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd, LVM_GETCOLUMNORDERARRAY, cast(WPARAM)iCount, cast(LPARAM)uintptr(pi))
}
ListView_SetHotItem :: #force_inline proc "system" (hwnd: HWND, i: c_int) -> c_int {
	return cast(c_int)SendMessageW(hwnd, LVM_SETHOTITEM, cast(WPARAM)i, 0)
}
ListView_GetHotItem :: #force_inline proc "system" (hwnd: HWND) -> c_int {
	return cast(c_int)SendMessageW(hwnd, LVM_GETHOTITEM, 0, 0)
}
ListView_SetHotCursor :: #force_inline proc "system" (hwnd: HWND, hcur: HCURSOR) -> HCURSOR {
	return cast(HCURSOR)uintptr(SendMessageW(hwnd, LVM_SETHOTCURSOR, 0, cast(LPARAM)uintptr(hcur)))
}
ListView_GetHotCursor :: #force_inline proc "system" (hwnd: HWND) -> HCURSOR {
	return cast(HCURSOR)uintptr(SendMessageW(hwnd, LVM_GETHOTCURSOR, 0, 0))
}
ListView_ApproximateViewRect :: #force_inline proc "system" (hwnd: HWND, iWidth,iHeight: c_int, iCount: c_int) -> DWORD {
	return cast(DWORD)SendMessageW(hwnd, LVM_APPROXIMATEVIEWRECT, cast(WPARAM)iCount, MAKELPARAM(iWidth,iHeight))
}
ListView_SetWorkAreas :: #force_inline proc "system" (hwnd: HWND, nWorkAreas: UINT, prc: ^RECT) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd, LVM_SETWORKAREAS, cast(WPARAM)nWorkAreas, cast(LPARAM)uintptr(prc))
}
ListView_GetWorkAreas :: #force_inline proc "system" (hwnd: HWND, nWorkAreas: UINT, prc: ^RECT) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd, LVM_GETWORKAREAS, cast(WPARAM)nWorkAreas, cast(LPARAM)uintptr(prc))
}
ListView_GetNumberOfWorkAreas :: #force_inline proc "system" (hwnd: HWND, pnWorkAreas: ^UINT) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd, LVM_GETNUMBEROFWORKAREAS, 0, cast(LPARAM)uintptr(pnWorkAreas))
}
ListView_GetSelectionMark :: #force_inline proc "system" (hwnd: HWND) -> c_int {
	return cast(c_int)SendMessageW(hwnd, LVM_GETSELECTIONMARK, 0, 0)
}
ListView_SetSelectionMark :: #force_inline proc "system" (hwnd: HWND, i: c_int) -> c_int {
	return cast(c_int)SendMessageW(hwnd, LVM_SETSELECTIONMARK, 0, cast(LPARAM)i)
}
ListView_SetHoverTime :: #force_inline proc "system" (hwndLV: HWND, dwHoverTimeMs: DWORD) -> DWORD {
	return cast(DWORD)SendMessageW(hwndLV, LVM_SETHOVERTIME, 0, cast(LPARAM)dwHoverTimeMs)
}
ListView_GetHoverTime :: #force_inline proc "system" (hwndLV: HWND) -> DWORD {
	return cast(DWORD)SendMessageW(hwndLV, LVM_GETHOVERTIME, 0, 0)
}
ListView_SetToolTips :: #force_inline proc "system" (hwndLV: HWND, hwndNewHwnd: HWND) -> HWND {
	return cast(HWND)uintptr(SendMessageW(hwndLV, LVM_SETTOOLTIPS, cast(WPARAM)hwndNewHwnd, 0))
}
ListView_GetToolTips :: #force_inline proc "system" (hwndLV: HWND) -> HWND {
	return cast(HWND)uintptr(SendMessageW(hwndLV, LVM_GETTOOLTIPS, 0, 0))
}
ListView_SortItemsEx :: #force_inline proc "system" (hwndLV: HWND, pfnCompare: PFNLVCOMPARE, lpUser: LPARAM) -> BOOL {
	return cast(BOOL)SendMessageW(hwndLV, LVM_SORTITEMSEX, cast(WPARAM)lpUser, cast(LPARAM)transmute(uintptr)(pfnCompare))
}
ListView_SetSelectedColumn :: #force_inline proc "system" (hwnd: HWND, iCol: c_int) {
	SendMessageW(hwnd, LVM_SETSELECTEDCOLUMN, cast(WPARAM)iCol, 0)
}
ListView_SetView :: #force_inline proc "system" (hwnd: HWND, iView: DWORD) -> c_int {
	return cast(c_int)SendMessageW(hwnd, LVM_SETVIEW, cast(WPARAM)iView, 0)
}
ListView_GetView :: #force_inline proc "system" (hwnd: HWND) -> DWORD {
	return cast(DWORD)SendMessageW(hwnd, LVM_GETVIEW, 0, 0)
}
ListView_InsertGroup :: #force_inline proc "system" (hwnd: HWND, index: c_int, pgrp: PLVGROUP) -> c_int {
	return cast(c_int)SendMessageW(hwnd, LVM_INSERTGROUP, cast(WPARAM)index, cast(LPARAM)uintptr(pgrp))
}
ListView_SetGroupInfo :: #force_inline proc "system" (hwnd: HWND, iGroupId: c_int, pgrp: PLVGROUP) -> c_int {
	return cast(c_int)SendMessageW(hwnd, LVM_SETGROUPINFO, cast(WPARAM)iGroupId, cast(LPARAM)uintptr(pgrp))
}
ListView_GetGroupInfo :: #force_inline proc "system" (hwnd: HWND, iGroupId: c_int, pgrp: PLVGROUP) -> c_int {
	return cast(c_int)SendMessageW(hwnd, LVM_GETGROUPINFO, cast(WPARAM)iGroupId, cast(LPARAM)uintptr(pgrp))
}
ListView_RemoveGroup :: #force_inline proc "system" (hwnd: HWND, iGroupId: c_int) -> c_int {
	return cast(c_int)SendMessageW(hwnd, LVM_REMOVEGROUP, cast(WPARAM)iGroupId, 0)
}
ListView_MoveGroup :: #force_inline proc "system" (hwnd: HWND, iGroupId: c_int, toIndex: c_int) {
	SendMessageW(hwnd, LVM_MOVEGROUP, cast(WPARAM)iGroupId, cast(LPARAM)toIndex)
}
ListView_MoveItemToGroup :: #force_inline proc "system" (hwnd: HWND, idItemFrom: c_int, idGroupTo: c_int) {
	SendMessageW(hwnd, LVM_MOVEITEMTOGROUP, cast(WPARAM)idItemFrom, cast(LPARAM)idGroupTo)
}
ListView_SetGroupMetrics :: #force_inline proc "system" (hwnd: HWND, pGroupMetrics: PLVGROUPMETRICS) {
	SendMessageW(hwnd, LVM_SETGROUPMETRICS, 0, cast(LPARAM)uintptr(pGroupMetrics))
}
ListView_GetGroupMetrics :: #force_inline proc "system" (hwnd: HWND, pGroupMetrics: PLVGROUPMETRICS) {
	SendMessageW(hwnd, LVM_GETGROUPMETRICS, 0, cast(LPARAM)uintptr(pGroupMetrics))
}
ListView_EnableGroupView :: #force_inline proc "system" (hwnd: HWND, fEnable: BOOL) -> c_int {
	return cast(c_int)SendMessageW(hwnd, LVM_ENABLEGROUPVIEW, cast(WPARAM)fEnable, 0)
}
ListView_SortGroups :: #force_inline proc "system" (hwnd: HWND, pfnGroupCompare: PFNLVGROUPCOMPARE, pUser: rawptr) -> c_int {
	return cast(c_int)SendMessageW(hwnd, LVM_SORTGROUPS, transmute(uintptr)(pfnGroupCompare), cast(LPARAM)uintptr(pUser))
}
ListView_InsertGroupSorted :: #force_inline proc "system" (hwnd: HWND, structInsert: PLVINSERTGROUPSORTED) {
	SendMessageW(hwnd, LVM_INSERTGROUPSORTED, uintptr(structInsert), 0)
}
ListView_RemoveAllGroups :: #force_inline proc "system" (hwnd: HWND) {
	SendMessageW(hwnd, LVM_REMOVEALLGROUPS, 0, 0)
}
ListView_HasGroup :: #force_inline proc "system" (hwnd: HWND, dwGroupId: c_int) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd, LVM_HASGROUP, cast(WPARAM)dwGroupId, 0)
}
ListView_SetTileViewInfo :: #force_inline proc "system" (hwnd: HWND, ptvi: PLVTILEVIEWINFO) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd, LVM_SETTILEVIEWINFO, 0, cast(LPARAM)uintptr(ptvi))
}
ListView_GetTileViewInfo :: #force_inline proc "system" (hwnd: HWND, ptvi: PLVTILEVIEWINFO) {
	SendMessageW(hwnd, LVM_GETTILEVIEWINFO, 0, cast(LPARAM)uintptr(ptvi))
}
ListView_SetTileInfo :: #force_inline proc "system" (hwnd: HWND, pti: PLVTILEINFO) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd, LVM_SETTILEINFO, 0, cast(LPARAM)uintptr(pti))
}
ListView_GetTileInfo :: #force_inline proc "system" (hwnd: HWND, pti: PLVTILEINFO) {
	SendMessageW(hwnd, LVM_GETTILEINFO, 0, cast(LPARAM)uintptr(pti))
}
ListView_SetInsertMark :: #force_inline proc "system" (hwnd: HWND, lvim: LPLVINSERTMARK) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd, LVM_SETINSERTMARK, 0, cast(LPARAM)uintptr(lvim))
}
ListView_GetInsertMark :: #force_inline proc "system" (hwnd: HWND, lvim: LPLVINSERTMARK) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd, LVM_GETINSERTMARK, 0, cast(LPARAM)uintptr(lvim))
}
ListView_InsertMarkHitTest :: #force_inline proc "system" (hwnd: HWND, point: LPPOINT, lvim: LPLVINSERTMARK) -> c_int {
	return cast(c_int)SendMessageW(hwnd, LVM_INSERTMARKHITTEST, uintptr(point), cast(LPARAM)uintptr(lvim))
}
ListView_GetInsertMarkRect :: #force_inline proc "system" (hwnd: HWND, rc: LPRECT) -> c_int {
	return cast(c_int)SendMessageW(hwnd, LVM_GETINSERTMARKRECT, 0, cast(LPARAM)uintptr(rc))
}
ListView_SetInsertMarkColor :: #force_inline proc "system" (hwnd: HWND, color: COLORREF) -> COLORREF {
	return cast(COLORREF)SendMessageW(hwnd, LVM_SETINSERTMARKCOLOR, 0, cast(LPARAM)color)
}
ListView_GetInsertMarkColor :: #force_inline proc "system" (hwnd: HWND) -> COLORREF {
	return cast(COLORREF)SendMessageW(hwnd, LVM_GETINSERTMARKCOLOR, 0, 0)
}
ListView_SetInfoTip :: #force_inline proc "system" (hwndLV: HWND, plvInfoTip: PLVSETINFOTIP) -> BOOL {
	return cast(BOOL)SendMessageW(hwndLV, LVM_SETINFOTIP, 0, cast(LPARAM)uintptr(plvInfoTip))
}
ListView_GetSelectedColumn :: #force_inline proc "system" (hwnd: HWND) -> UINT {
	return cast(UINT)SendMessageW(hwnd, LVM_GETSELECTEDCOLUMN, 0, 0)
}
ListView_IsGroupViewEnabled :: #force_inline proc "system" (hwnd: HWND) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd, LVM_ISGROUPVIEWENABLED, 0, 0)
}
ListView_GetOutlineColor :: #force_inline proc "system" (hwnd: HWND) -> COLORREF {
	return cast(COLORREF)SendMessageW(hwnd, LVM_GETOUTLINECOLOR, 0, 0)
}
ListView_SetOutlineColor :: #force_inline proc "system" (hwnd: HWND, color: COLORREF) -> COLORREF {
	return cast(COLORREF)SendMessageW(hwnd, LVM_SETOUTLINECOLOR, 0, cast(LPARAM)color)
}
ListView_CancelEditLabel :: #force_inline proc "system" (hwnd: HWND) {
	SendMessageW(hwnd, LVM_CANCELEDITLABEL, 0, 0)
}
ListView_MapIndexToID :: #force_inline proc "system" (hwnd: HWND, index: UINT) -> UINT {
	return cast(UINT)SendMessageW(hwnd, LVM_MAPINDEXTOID, cast(WPARAM)index, 0)
}
ListView_MapIDToIndex :: #force_inline proc "system" (hwnd: HWND, id: UINT) -> UINT {
	return cast(UINT)SendMessageW(hwnd, LVM_MAPIDTOINDEX, cast(WPARAM)id, 0)
}
ListView_IsItemVisible :: #force_inline proc "system" (hwnd: HWND, index: UINT) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd, LVM_ISITEMVISIBLE, cast(WPARAM)index, 0)
}

// Tree View Control
HTREEITEM :: distinct rawptr

TVIF_TEXT          :: 0x01
TVIF_IMAGE         :: 0x02
TVIF_PARAM         :: 0x04
TVIF_STATE         :: 0x08
TVIF_HANDLE        :: 0x10
TVIF_SELECTEDIMAGE :: 0x20
TVIF_CHILDREN      :: 0x40
TVIF_INTEGRAL      :: 0x80

TVIS_SELECTED      :: 0x02
TVIS_CUT           :: 0x04
TVIS_DROPHILITED   :: 0x08
TVIS_BOLD          :: 0x10
TVIS_EXPANDED      :: 0x20
TVIS_EXPANDEDONCE  :: 0x40
TVIS_EXPANDPARTIAL :: 0x80

TVIS_OVERLAYMASK    :: 0x0F00
TVIS_STATEIMAGEMASK :: 0xF000
TVIS_USERMASK       :: 0xF000

I_CHILDRENCALLBACK :: (-1)

TVI_ROOT  :: cast(HTREEITEM)~uintptr(0x10000 - 1)
TVI_FIRST :: cast(HTREEITEM)~uintptr(0x0FFFF - 1)
TVI_LAST  :: cast(HTREEITEM)~uintptr(0x0FFFE - 1)
TVI_SORT  :: cast(HTREEITEM)~uintptr(0x0FFFD - 1)

TVN_SELCHANGINGA    :: (TVN_FIRST-1)
TVN_SELCHANGINGW    :: (TVN_FIRST-50)
TVN_SELCHANGEDA     :: (TVN_FIRST-2)
TVN_SELCHANGEDW     :: (TVN_FIRST-51)
TVN_GETDISPINFOA    :: (TVN_FIRST-3)
TVN_GETDISPINFOW    :: (TVN_FIRST-52)
TVN_SETDISPINFOA    :: (TVN_FIRST-4)
TVN_SETDISPINFOW    :: (TVN_FIRST-53)
TVN_ITEMEXPANDINGA  :: (TVN_FIRST-5)
TVN_ITEMEXPANDINGW  :: (TVN_FIRST-54)
TVN_ITEMEXPANDEDA   :: (TVN_FIRST-6)
TVN_ITEMEXPANDEDW   :: (TVN_FIRST-55)
TVN_BEGINDRAGA      :: (TVN_FIRST-7)
TVN_BEGINDRAGW      :: (TVN_FIRST-56)
TVN_BEGINRDRAGA     :: (TVN_FIRST-8)
TVN_BEGINRDRAGW     :: (TVN_FIRST-57)
TVN_DELETEITEMA     :: (TVN_FIRST-9)
TVN_DELETEITEMW     :: (TVN_FIRST-58)
TVN_BEGINLABELEDITA :: (TVN_FIRST-10)
TVN_BEGINLABELEDITW :: (TVN_FIRST-59)
TVN_ENDLABELEDITA   :: (TVN_FIRST-11)
TVN_ENDLABELEDITW   :: (TVN_FIRST-60)
TVN_KEYDOWN         :: (TVN_FIRST-12)
TVN_GETINFOTIPA     :: (TVN_FIRST-13)
TVN_GETINFOTIPW     :: (TVN_FIRST-14)
TVN_SINGLEEXPAND    :: (TVN_FIRST-15)

TVC_UNKNOWN    :: 0x0
TVC_BYMOUSE    :: 0x1
TVC_BYKEYBOARD :: 0x2

TVIF_DI_SETITEM :: 0x1000

TVNRET_DEFAULT :: 0
TVNRET_SKIPOLD :: 1
TVNRET_SKIPNEW :: 2

TVCDRF_NOIMAGES :: 0x10000

TVITEMW :: struct {
	mask: UINT,
	hItem: HTREEITEM,
	state: UINT,
	stateMask: UINT,
	pszText: LPWSTR,
	cchTextMax: c_int,
	iImage: c_int,
	iSelectedImage: c_int,
	cChildren: c_int,
	lParam: LPARAM,
}
TV_ITEMW   :: TVITEMW
LPTVITEMW  :: ^TVITEMW
LPTV_ITEMW :: LPTVITEMW

TVITEMEXW :: struct {
	mask: UINT,
	hItem: HTREEITEM,
	state: UINT,
	stateMask: UINT,
	pszText: LPWSTR,
	cchTextMax: c_int,
	iImage: c_int,
	iSelectedImage: c_int,
	cChildren: c_int,
	lParam: LPARAM,
	iIntegral: c_int,
}
TV_ITEMEXW   :: TVITEMEXW
LPTVITEMEXW  :: ^TVITEMEXW
LPTV_ITEMEXW :: LPTVITEMEXW

TVINSERTSTRUCTW :: struct {
	hParent: HTREEITEM,
	hInsertAfter: HTREEITEM,
	_: struct #raw_union {
	itemex: TVITEMEXW,
	item: TV_ITEMW,
	},
}
TV_INSERTSTRUCTW   :: TVINSERTSTRUCTW
LPTVINSERTSTRUCTW  :: ^TVINSERTSTRUCTW
LPTV_INSERTSTRUCTW :: LPTVINSERTSTRUCTW

TVHITTESTINFO :: struct {
	pt: POINT,
	flags: UINT,
	hItem: HTREEITEM,
}
TV_HITTESTINFO   :: TVHITTESTINFO
LPTVHITTESTINFO  :: ^TVHITTESTINFO
LPTV_HITTESTINFO :: LPTVHITTESTINFO

TVSORTCB :: struct {
	hParent: HTREEITEM,
	lpfnCompare: PFNTVCOMPARE,
	lParam: LPARAM,
}
TV_SORTCB   :: TVSORTCB
LPTVSORTCB  :: ^TVSORTCB
LPTV_SORTCB :: LPTVSORTCB

NMTREEVIEWW :: struct {
	hdr: NMHDR,
	action: UINT,
	itemOld: TVITEMW,
	itemNew: TVITEMW,
	ptDrag: POINT,
}
NM_TREEVIEWW   :: NMTREEVIEWW
LPNMTREEVIEWW  :: ^NMTREEVIEWW
LPNM_TREEVIEWW :: LPNMTREEVIEWW

NMTVDISPINFOW :: struct {
	hdr: NMHDR,
	item: TVITEMW,
}
TV_DISPINFOW    :: NMTVDISPINFOW
LPNMTVDISPINFOW :: ^NMTVDISPINFOW

NMTVDISPINFOEXW :: struct {
	hdr: NMHDR,
	item: TVITEMEXW,
}
TV_DISPINFOEXW    :: NMTVDISPINFOEXW
LPNMTVDISPINFOEXW :: ^NMTVDISPINFOEXW

NMTVKEYDOWN :: struct #packed {
	hdr: NMHDR,
	wVKey: WORD,
	flags: UINT,
}
TV_KEYDOWN    :: NMTVKEYDOWN
LPNMTVKEYDOWN :: ^NMTVKEYDOWN

NMTVCUSTOMDRAW :: struct {
	nmcd: NMCUSTOMDRAW,
	clrText: COLORREF,
	clrTextBk: COLORREF,
	iLevel: c_int,
}
LPNMTVCUSTOMDRAW :: ^NMTVCUSTOMDRAW

NMTVGETINFOTIPW :: struct {
	hdr: NMHDR,
	pszText: LPWSTR,
	cchTextMax: c_int,
	hItem: HTREEITEM,
	lParam: LPARAM,
}
TV_GETINFOTIPW    :: NMTVGETINFOTIPW
LPNMTVGETINFOTIPW :: ^NMTVGETINFOTIPW

PFNTVCOMPARE :: #type proc "system" (lParam1,lParam2: LPARAM, lParamSort: LPARAM) -> c_int

TreeView_InsertItem :: #force_inline proc "system" (hwnd: HWND, lpis: LPTV_INSERTSTRUCTW) -> HTREEITEM {
	return cast(HTREEITEM)uintptr(SendMessageW(hwnd, TVM_INSERTITEMW, 0, cast(LPARAM)uintptr(lpis)))
}
TreeView_DeleteItem :: #force_inline proc "system" (hwnd: HWND, hitem: HTREEITEM) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd, TVM_DELETEITEM, 0, cast(LPARAM)uintptr(hitem))
}
TreeView_DeleteAllItems :: #force_inline proc "system" (hwnd: HWND) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd, TVM_DELETEITEM, 0, cast(LPARAM)transmute(uintptr)(TVI_ROOT))
}
TreeView_Expand :: #force_inline proc "system" (hwnd: HWND, hitem: HTREEITEM, code: UINT) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd, TVM_EXPAND, cast(WPARAM)code, cast(LPARAM)uintptr(hitem))
}
TreeView_GetItemRect :: #force_inline proc "system" (hwnd: HWND, hitem: HTREEITEM, prc: ^RECT, code: UINT) -> BOOL {
	alias: struct #raw_union {
		rc: ^RECT,
		hitem: ^HTREEITEM,
	}

	alias.rc     = prc
	alias.hitem^ = hitem

	return cast(BOOL)SendMessageW(hwnd, TVM_GETITEMRECT, cast(WPARAM)code, cast(LPARAM)uintptr(prc))
}
TreeView_GetCount :: #force_inline proc "system" (hwnd: HWND) -> UINT {
	return cast(UINT)SendMessageW(hwnd, TVM_GETCOUNT, 0, 0)
}
TreeView_GetIndent :: #force_inline proc "system" (hwnd: HWND) -> UINT {
	return cast(UINT)SendMessageW(hwnd, TVM_GETINDENT, 0, 0)
}
TreeView_SetIndent :: #force_inline proc "system" (hwnd: HWND, indent: UINT) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd, TVM_SETINDENT, cast(WPARAM)indent, 0)
}
TreeView_GetImageList :: #force_inline proc "system" (hwnd: HWND, iImage: INT) -> HIMAGELIST {
	return cast(HIMAGELIST)uintptr(SendMessageW(hwnd, TVM_GETIMAGELIST, cast(WPARAM)iImage, 0))
}
TreeView_SetImageList :: #force_inline proc "system" (hwnd: HWND, himl: HIMAGELIST, iImage: INT) -> HIMAGELIST {
	return cast(HIMAGELIST)uintptr(SendMessageW(hwnd, TVM_SETIMAGELIST, cast(WPARAM)iImage, cast(LPARAM)uintptr(himl)))
}
TreeView_GetNextItem :: #force_inline proc "system" (hwnd: HWND, hitem: HTREEITEM, code: UINT) -> HTREEITEM {
	return cast(HTREEITEM)uintptr(SendMessageW(hwnd, TVM_GETNEXTITEM, cast(WPARAM)code, cast(LPARAM)uintptr(hitem)))
}
TreeView_GetChild :: #force_inline proc "system" (hwnd: HWND, hitem: HTREEITEM) -> HTREEITEM {
	return TreeView_GetNextItem(hwnd, hitem, TVGN_CHILD)
}
TreeView_GetNextSibling :: #force_inline proc "system" (hwnd: HWND, hitem: HTREEITEM) -> HTREEITEM {
	return TreeView_GetNextItem(hwnd, hitem, TVGN_NEXT)
}
TreeView_GetPrevSibling :: #force_inline proc "system" (hwnd: HWND, hitem: HTREEITEM) -> HTREEITEM {
	return TreeView_GetNextItem(hwnd, hitem, TVGN_PREVIOUS)
}
TreeView_GetParent :: #force_inline proc "system" (hwnd: HWND, hitem: HTREEITEM) -> HTREEITEM {
	return TreeView_GetNextItem(hwnd, hitem, TVGN_PARENT)
}
TreeView_GetFirstVisible :: #force_inline proc "system" (hwnd: HWND) -> HTREEITEM {
	return TreeView_GetNextItem(hwnd, nil, TVGN_FIRSTVISIBLE)
}
TreeView_GetNextVisible :: #force_inline proc "system" (hwnd: HWND, hitem: HTREEITEM) -> HTREEITEM {
	return TreeView_GetNextItem(hwnd, hitem, TVGN_NEXTVISIBLE)
}
TreeView_GetPrevVisible :: #force_inline proc "system" (hwnd: HWND, hitem: HTREEITEM) -> HTREEITEM {
	return TreeView_GetNextItem(hwnd, hitem, TVGN_PREVIOUSVISIBLE)
}
TreeView_GetSelection :: #force_inline proc "system" (hwnd: HWND) -> HTREEITEM {
	return TreeView_GetNextItem(hwnd, nil, TVGN_CARET)
}
TreeView_GetDropHilight :: #force_inline proc "system" (hwnd: HWND) -> HTREEITEM {
	return TreeView_GetNextItem(hwnd, nil, TVGN_DROPHILITE)
}
TreeView_GetRoot :: #force_inline proc "system" (hwnd: HWND) -> HTREEITEM {
	return TreeView_GetNextItem(hwnd, nil, TVGN_ROOT)
}
TreeView_GetLastVisible :: #force_inline proc "system" (hwnd: HWND) -> HTREEITEM {
	return TreeView_GetNextItem(hwnd, nil, TVGN_LASTVISIBLE)
}
TreeView_Select :: #force_inline proc "system" (hwnd: HWND, hitem: HTREEITEM, code: UINT) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd, TVM_SELECTITEM, cast(WPARAM)code, cast(LPARAM)uintptr(hitem))
}
TreeView_SelectItem :: #force_inline proc "system" (hwnd: HWND, hitem: HTREEITEM) -> BOOL {
	return TreeView_Select(hwnd, hitem, TVGN_CARET)
}
TreeView_SelectDropTarget :: #force_inline proc "system" (hwnd: HWND, hitem: HTREEITEM) -> BOOL {
	return TreeView_Select(hwnd, hitem, TVGN_DROPHILITE)
}
TreeView_SelectSetFirstVisible :: #force_inline proc "system" (hwnd: HWND, hitem: HTREEITEM) -> BOOL {
	return TreeView_Select(hwnd, hitem, TVGN_FIRSTVISIBLE)
}
TreeView_GetItem :: #force_inline proc "system" (hwnd: HWND, pitem: ^TV_ITEMW) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd, TVM_GETITEMW, 0, cast(LPARAM)uintptr(pitem))
}
TreeView_SetItem :: #force_inline proc "system" (hwnd: HWND, pitem: ^TV_ITEMW) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd, TVM_SETITEMW, 0, cast(LPARAM)uintptr(pitem))
}
TreeView_EditLabel :: #force_inline proc "system" (hwnd: HWND, hitem: HTREEITEM) -> HWND {
	return cast(HWND)uintptr(SendMessageW(hwnd, TVM_EDITLABELW, 0, cast(LPARAM)uintptr(hitem)))
}
TreeView_GetEditControl :: #force_inline proc "system" (hwnd: HWND) -> HWND {
	return cast(HWND)uintptr(SendMessageW(hwnd, TVM_GETEDITCONTROL, 0, 0))
}
TreeView_GetVisibleCount :: #force_inline proc "system" (hwnd: HWND) -> UINT {
	return cast(UINT)SendMessageW(hwnd, TVM_GETVISIBLECOUNT, 0, 0)
}
TreeView_HitTest :: #force_inline proc "system" (hwnd: HWND, lpht: LPTV_HITTESTINFO) -> HTREEITEM {
	return cast(HTREEITEM)uintptr(SendMessageW(hwnd, TVM_HITTEST, 0, cast(LPARAM)uintptr(lpht)))
}
TreeView_CreateDragImage :: #force_inline proc "system" (hwnd: HWND, hitem: HTREEITEM) -> HIMAGELIST {
	return cast(HIMAGELIST)uintptr(SendMessageW(hwnd, TVM_CREATEDRAGIMAGE, 0, cast(LPARAM)uintptr(hitem)))
}
TreeView_SortChildren :: #force_inline proc "system" (hwnd: HWND, hitem: HTREEITEM, recurse: BOOL) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd, TVM_SORTCHILDREN, cast(WPARAM)recurse, cast(LPARAM)uintptr(hitem))
}
TreeView_EnsureVisible :: #force_inline proc "system" (hwnd: HWND, hitem: HTREEITEM) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd, TVM_ENSUREVISIBLE, 0, cast(LPARAM)uintptr(hitem))
}
TreeView_SortChildrenCB :: #force_inline proc "system" (hwnd: HWND, psort: LPTVSORTCB, recurse: BOOL) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd, TVM_SORTCHILDRENCB, cast(WPARAM)recurse, cast(LPARAM)uintptr(psort))
}
TreeView_EndEditLabelNow :: #force_inline proc "system" (hwnd: HWND, fCancel: BOOL) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd, TVM_ENDEDITLABELNOW, cast(WPARAM)fCancel, 0)
}
TreeView_SetToolTips :: #force_inline proc "system" (hwnd: HWND, hwndTT: HWND) -> HWND {
	return cast(HWND)uintptr(SendMessageW(hwnd, TVM_SETTOOLTIPS, uintptr(hwndTT), 0))
}
TreeView_GetToolTips :: #force_inline proc "system" (hwnd: HWND) -> HWND {
	return cast(HWND)uintptr(SendMessageW(hwnd, TVM_GETTOOLTIPS, 0, 0))
}
TreeView_GetISearchString :: #force_inline proc "system" (hwnd: HWND, lpsz: LPWSTR) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd, TVM_GETISEARCHSTRINGW, 0, cast(LPARAM)uintptr(lpsz))
}
TreeView_SetInsertMark :: #force_inline proc "system" (hwnd: HWND, hItem: HTREEITEM, fAfter: BOOL) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd, TVM_SETINSERTMARK, cast(WPARAM)fAfter, cast(LPARAM)uintptr(hItem))
}
TreeView_SetUnicodeFormat :: #force_inline proc "system" (hwnd: HWND, fUnicode: BOOL) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd, TVM_SETUNICODEFORMAT, cast(WPARAM)fUnicode, 0)
}
TreeView_GetUnicodeFormat :: #force_inline proc "system" (hwnd: HWND) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd, TVM_GETUNICODEFORMAT, 0, 0)
}
TreeView_SetItemHeight :: #force_inline proc "system" (hwnd: HWND, iHeight: c_int) -> c_int {
	return cast(c_int)SendMessageW(hwnd, TVM_SETITEMHEIGHT, cast(WPARAM)iHeight, 0)
}
TreeView_GetItemHeight :: #force_inline proc "system" (hwnd: HWND) -> c_int {
	return cast(c_int)SendMessageW(hwnd, TVM_GETITEMHEIGHT, 0, 0)
}
TreeView_SetBkColor :: #force_inline proc "system" (hwnd: HWND, clr: COLORREF) -> COLORREF {
	return cast(COLORREF)SendMessageW(hwnd, TVM_SETBKCOLOR, 0, cast(LPARAM)clr)
}
TreeView_SetTextColor :: #force_inline proc "system" (hwnd: HWND, clr: COLORREF) -> COLORREF {
	return cast(COLORREF)SendMessageW(hwnd, TVM_SETTEXTCOLOR, 0, cast(LPARAM)clr)
}
TreeView_GetBkColor :: #force_inline proc "system" (hwnd: HWND) -> COLORREF {
	return cast(COLORREF)SendMessageW(hwnd, TVM_GETBKCOLOR, 0, 0)
}
TreeView_GetTextColor :: #force_inline proc "system" (hwnd: HWND) -> COLORREF {
	return cast(COLORREF)SendMessageW(hwnd, TVM_GETTEXTCOLOR, 0, 0)
}
TreeView_SetScrollTime :: #force_inline proc "system" (hwnd: HWND, uTime: UINT) -> UINT {
	return cast(UINT)SendMessageW(hwnd, TVM_SETSCROLLTIME, cast(WPARAM)uTime, 0)
}
TreeView_GetScrollTime :: #force_inline proc "system" (hwnd: HWND) -> UINT {
	return cast(UINT)SendMessageW(hwnd, TVM_GETSCROLLTIME, 0, 0)
}
TreeView_SetInsertMarkColor :: #force_inline proc "system" (hwnd: HWND, clr: COLORREF) -> COLORREF {
	return cast(COLORREF)SendMessageW(hwnd, TVM_SETINSERTMARKCOLOR, 0, cast(LPARAM)clr)
}
TreeView_GetInsertMarkColor :: #force_inline proc "system" (hwnd: HWND) -> COLORREF {
	return cast(COLORREF)SendMessageW(hwnd, TVM_GETINSERTMARKCOLOR, 0, 0)
}
TreeView_SetItemState :: #force_inline proc "system" (hwndTV: HWND, hti: HTREEITEM, data: UINT, mask: UINT) {
	item := TVITEMW {
		mask      = TVIF_STATE,
		hItem     = hti,
		stateMask = mask,
		state     = data,
	}
	SendMessageW(hwndTV, TVM_SETITEMW, 0, cast(LPARAM)uintptr(&item))
}
TreeView_SetCheckState :: #force_inline proc "system" (hwndTV: HWND, hti: HTREEITEM, fCheck: BOOL) {
	TreeView_SetItemState(hwndTV, hti, INDEXTOSTATEIMAGEMASK(2 if fCheck else 1), TVIS_STATEIMAGEMASK)
}
TreeView_GetItemState :: #force_inline proc "system" (hwndTV: HWND, hti: HTREEITEM, mask: UINT) -> UINT {
	return cast(UINT)SendMessageW(hwndTV, TVM_GETITEMSTATE, uintptr(hti), cast(LPARAM)mask)
}
TreeView_GetCheckState :: #force_inline proc "system" (hwndTV: HWND, hti: HTREEITEM) -> UINT {
	return ((cast(UINT)SendMessageW(hwndTV, TVM_GETITEMSTATE, uintptr(hti), cast(LPARAM)TVIS_STATEIMAGEMASK)) >> 12) - 1
}
TreeView_SetLineColor :: #force_inline proc "system" (hwnd: HWND, clr: COLORREF) -> COLORREF {
	return cast(COLORREF)SendMessageW(hwnd, TVM_SETLINECOLOR, 0, cast(LPARAM)clr)
}
TreeView_GetLineColor :: #force_inline proc "system" (hwnd: HWND) -> COLORREF {
	return cast(COLORREF)SendMessageW(hwnd, TVM_GETLINECOLOR, 0, 0)
}
TreeView_MapAccIDToHTREEITEM :: #force_inline proc "system" (hwnd: HWND, id: UINT) -> HTREEITEM {
	return cast(HTREEITEM)uintptr(SendMessageW(hwnd, TVM_MAPACCIDTOHTREEITEM, cast(WPARAM)id, 0))
}
TreeView_MapHTREEITEMToAccID :: #force_inline proc "system" (hwnd: HWND, htreeitem: HTREEITEM) -> UINT {
	return cast(UINT)SendMessageW(hwnd, TVM_MAPHTREEITEMTOACCID, uintptr(htreeitem), 0)
}

// Combo Box Ex Control
CBEIF_TEXT          :: 0x01
CBEIF_IMAGE         :: 0x02
CBEIF_SELECTEDIMAGE :: 0x04
CBEIF_OVERLAY       :: 0x08
CBEIF_INDENT        :: 0x10
CBEIF_LPARAM        :: 0x20

CBEIF_DI_SETITEM :: 0x10000000

CBES_EX_NOEDITIMAGE       :: 0x01
CBES_EX_NOEDITIMAGEINDENT :: 0x02
CBES_EX_PATHWORDBREAKPROC :: 0x04
CBES_EX_NOSIZELIMIT       :: 0x08
CBES_EX_CASESENSITIVE     :: 0x10

CBEN_GETDISPINFOA :: (CBEN_FIRST - 0)
CBEN_INSERTITEM   :: (CBEN_FIRST - 1)
CBEN_DELETEITEM   :: (CBEN_FIRST - 2)
CBEN_BEGINEDIT    :: (CBEN_FIRST - 4)
CBEN_ENDEDITA     :: (CBEN_FIRST - 5)
CBEN_ENDEDITW     :: (CBEN_FIRST - 6)
CBEN_GETDISPINFOW :: (CBEN_FIRST - 7)
CBEN_DRAGBEGINA   :: (CBEN_FIRST - 8)
CBEN_DRAGBEGINW   :: (CBEN_FIRST - 9)

CBENF_KILLFOCUS :: 1
CBENF_RETURN    :: 2
CBENF_ESCAPE    :: 3
CBENF_DROPDOWN  :: 4

CBEMAXSTRLEN :: 260

COMBOBOXEXITEMW :: struct {
	mask: UINT,
	iItem: INT_PTR,
	pszText: LPWSTR,
	cchTextMax: c_int,
	iImage: c_int,
	iSelectedImage: c_int,
	iOverlay: c_int,
	iIndent: c_int,
	lParam: LPARAM,
}
PCOMBOBOXEXITEMW  :: ^COMBOBOXEXITEMW
PCCOMBOBOXEXITEMW :: ^COMBOBOXEXITEMW

NMCOMBOBOXEXW :: struct {
	hdr: NMHDR,
	ceItem: COMBOBOXEXITEMW,
}
PNMCOMBOBOXEXW :: ^NMCOMBOBOXEXW

NMCBEDRAGBEGINW :: struct {
	hdr: NMHDR,
	iItemId: c_int,
	szText: [CBEMAXSTRLEN]WCHAR,
}
PNMCBEDRAGBEGINW  :: ^NMCBEDRAGBEGINW
LPNMCBEDRAGBEGINW :: PNMCBEDRAGBEGINW

NMCBEENDEDITW :: struct {
	hdr: NMHDR,
	fChanged: BOOL,
	iNewSelection: c_int,
	szText: [CBEMAXSTRLEN]WCHAR,
	iWhy: c_int,
}
PNMCBEENDEDITW  :: ^NMCBEENDEDITW
LPNMCBEENDEDITW :: PNMCBEENDEDITW

// Tab Control
TCS_EX_FLATSEPARATORS :: 0x1
TCS_EX_REGISTERDROP   :: 0x2

TCN_KEYDOWN     :: TCN_FIRST - 0
TCN_SELCHANGE   :: TCN_FIRST - 1
TCN_SELCHANGING :: TCN_FIRST - 2
TCN_GETOBJECT   :: TCN_FIRST - 3
TCN_FOCUSCHANGE :: TCN_FIRST - 4

TCITEMHEADERW :: struct {
	mask: UINT,
	lpReserved1: UINT,
	lpReserved2: UINT,
	pszText: LPWSTR,
	cchTextMax: c_int,
	iImage: c_int,
}
TC_ITEMHEADERW   :: TCITEMHEADERW
LPTCITEMHEADERW  :: ^TCITEMHEADERW
LPTC_ITEMHEADERW :: LPTCITEMHEADERW

TCITEMW :: struct {
	mask: UINT,
	dwState: DWORD,
	dwStateMask: DWORD,
	pszText: LPWSTR,
	cchTextMax: c_int,
	iImage: c_int,
	lParam: LPARAM,
}
TC_ITEMW   :: TCITEMW
LPTCITEMW  :: ^TCITEMW
LPTC_ITEMW :: LPTCITEMW

TCHITTESTINFO :: struct {
	pt: POINT,
	flags: UINT,
}
TC_HITTESTINFO   :: TCHITTESTINFO
LPTCHITTESTINFO  :: ^TCHITTESTINFO
LPTC_HITTESTINFO :: LPTCHITTESTINFO

NMTCKEYDOWN :: struct #packed {
	hdr: NMHDR,
	wVKey: WORD,
	flags: UINT,
}
TC_KEYDOWN :: NMTCKEYDOWN

TabCtrl_GetImageList :: #force_inline proc "system" (hwnd: HWND) -> HIMAGELIST {
	return cast(HIMAGELIST)uintptr(SendMessageW(hwnd, TCM_GETIMAGELIST, 0, 0))
}
TabCtrl_SetImageList :: #force_inline proc "system" (hwnd: HWND, himl: HIMAGELIST) -> HIMAGELIST {
	return cast(HIMAGELIST)uintptr(SendMessageW(hwnd, TCM_SETIMAGELIST, 0, cast(LPARAM)uintptr(himl)))
}
TabCtrl_GetItemCount :: #force_inline proc "system" (hwnd: HWND) -> c_int {
	return cast(c_int)SendMessageW(hwnd, TCM_GETITEMCOUNT, 0, 0)
}
TabCtrl_GetItem :: #force_inline proc "system" (hwnd: HWND, iItem: c_int, pitem: ^TC_ITEMW) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd, TCM_GETITEMW, cast(WPARAM)iItem, cast(LPARAM)uintptr(pitem))
}
TabCtrl_SetItem :: #force_inline proc "system" (hwnd: HWND, iItem: c_int, pitem: ^TC_ITEMW) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd, TCM_SETITEMW, cast(WPARAM)iItem, cast(LPARAM)uintptr(pitem))
}
TabCtrl_InsertItem :: #force_inline proc "system" (hwnd: HWND, iItem: c_int, pitem: ^TC_ITEMW) -> c_int {
	return cast(c_int)SendMessageW(hwnd, TCM_INSERTITEMW, cast(WPARAM)iItem, cast(LPARAM)uintptr(pitem))
}
TabCtrl_DeleteItem :: #force_inline proc "system" (hwnd: HWND, i: c_int) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd, TCM_DELETEITEM, cast(WPARAM)i, 0)
}
TabCtrl_DeleteAllItems :: #force_inline proc "system" (hwnd: HWND) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd, TCM_DELETEALLITEMS, 0, 0)
}
TabCtrl_GetItemRect :: #force_inline proc "system" (hwnd: HWND, i: c_int, prc: ^RECT) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd, TCM_GETITEMRECT, cast(WPARAM)i, cast(LPARAM)uintptr(prc))
}
TabCtrl_GetCurSel :: #force_inline proc "system" (hwnd: HWND) -> c_int {
	return cast(c_int)SendMessageW(hwnd, TCM_GETCURSEL, 0, 0)
}
TabCtrl_SetCurSel :: #force_inline proc "system" (hwnd: HWND, i: c_int) -> c_int {
	return cast(c_int)SendMessageW(hwnd, TCM_SETCURSEL, cast(WPARAM)i, 0)
}
TabCtrl_HitTest :: #force_inline proc "system" (hwndTC: HWND, pinfo: ^TC_HITTESTINFO) -> c_int {
	return cast(c_int)SendMessageW(hwndTC, TCM_HITTEST, 0, cast(LPARAM)uintptr(pinfo))
}
TabCtrl_SetItemExtra :: #force_inline proc "system" (hwndTC: HWND, cb: c_int) -> BOOL {
	return cast(BOOL)SendMessageW(hwndTC, TCM_SETITEMEXTRA, cast(WPARAM)cb, 0)
}
TabCtrl_AdjustRect :: #force_inline proc "system" (hwnd: HWND, bLarger: BOOL, prc: ^RECT) -> c_int {
	return cast(c_int)SendMessageW(hwnd, TCM_ADJUSTRECT, cast(WPARAM)bLarger, cast(LPARAM)uintptr(prc))
}
TabCtrl_SetItemSize :: #force_inline proc "system" (hwnd: HWND, x,y: c_int) -> DWORD {
	return cast(DWORD)SendMessageW(hwnd, TCM_SETITEMSIZE, 0, MAKELPARAM(x,y))
}
TabCtrl_RemoveImage :: #force_inline proc "system" (hwnd: HWND, i: c_int) {
	SendMessageW(hwnd, TCM_REMOVEIMAGE, cast(WPARAM)i, 0)
}
TabCtrl_SetPadding :: #force_inline proc "system" (hwnd: HWND, cx,cy: c_int) {
	SendMessageW(hwnd, TCM_SETPADDING, 0, MAKELPARAM(cx,cy))
}
TabCtrl_GetRowCount :: #force_inline proc "system" (hwnd: HWND) -> c_int {
	return cast(c_int)SendMessageW(hwnd, TCM_GETROWCOUNT, 0, 0)
}
TabCtrl_GetToolTips :: #force_inline proc "system" (hwnd: HWND) -> HWND {
	return cast(HWND)uintptr(SendMessageW(hwnd, TCM_GETTOOLTIPS, 0, 0))
}
TabCtrl_SetToolTips :: #force_inline proc "system" (hwnd: HWND, hwndTT: HWND) {
	SendMessageW(hwnd, TCM_SETTOOLTIPS, uintptr(hwndTT), 0)
}
TabCtrl_GetCurFocus :: #force_inline proc "system" (hwnd: HWND) -> c_int {
	return cast(c_int)SendMessageW(hwnd, TCM_GETCURFOCUS, 0, 0)
}
TabCtrl_SetCurFocus :: #force_inline proc "system" (hwnd: HWND, i: c_int) {
	SendMessageW(hwnd, TCM_SETCURFOCUS, cast(WPARAM)i, 0)
}
TabCtrl_SetMinTabWidth :: #force_inline proc "system" (hwnd: HWND, x: c_int) -> c_int {
	return cast(c_int)SendMessageW(hwnd, TCM_SETMINTABWIDTH, 0, cast(LPARAM)x)
}
TabCtrl_DeselectAll :: #force_inline proc "system" (hwnd: HWND, fExcludeFocus: BOOL) {
	SendMessageW(hwnd, TCM_DESELECTALL, cast(WPARAM)fExcludeFocus, 0)
}
TabCtrl_HighlightItem :: #force_inline proc "system" (hwnd: HWND, i: c_int, fHighlight: BOOL) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd, TCM_HIGHLIGHTITEM, cast(WPARAM)i, cast(LPARAM)MAKELONG(fHighlight,0))
}
TabCtrl_SetExtendedStyle :: #force_inline proc "system" (hwnd: HWND, dw: DWORD) -> DWORD {
	return cast(DWORD)SendMessageW(hwnd, TCM_SETEXTENDEDSTYLE, 0, cast(LPARAM)dw)
}
TabCtrl_GetExtendedStyle :: #force_inline proc "system" (hwnd: HWND) -> DWORD {
	return cast(DWORD)SendMessageW(hwnd, TCM_GETEXTENDEDSTYLE, 0, 0)
}
TabCtrl_SetUnicodeFormat :: #force_inline proc "system" (hwnd: HWND, fUnicode: BOOL) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd, TCM_SETUNICODEFORMAT, cast(WPARAM)fUnicode, 0)
}
TabCtrl_GetUnicodeFormat :: #force_inline proc "system" (hwnd: HWND) -> BOOL {
	return cast(BOOL)SendMessageW(hwnd, TCM_GETUNICODEFORMAT, 0, 0)
}
