#+build windows
package sys_windows

// Bindings for the various common Win32 dialogs.
// See: https://learn.microsoft.com/en-us/windows/win32/dlgbox/using-common-dialog-boxes
// Corresponds to Commdlg.h

foreign import "system:Comdlg32.lib"

// OpenFile/SaveFile dialogs

LPOFNHOOKPROC :: #type proc "system" (hdlg: HWND, msg: u32, wparam: WPARAM, lparam: LPARAM) -> UINT_PTR

OPENFILENAMEW :: struct {
	lStructSize:            DWORD,
	hwndOwner:              HWND,
	hInstance:              HINSTANCE,
	lpstrFilter:            LPCWSTR,
	lpstrCustomFilter:      LPWSTR,
	nMaxCustFilter:         DWORD,
	nFilterIndex:           DWORD,
	lpstrFile:              LPWSTR,
	nMaxFile:               DWORD,
	lpstrFileTitle:         LPWSTR,
	nMaxFileTitle:          DWORD,
	lpstrInitialDir:        LPCWSTR,
	lpstrTitle:             LPCWSTR,
	Flags:                  DWORD,
	nFileOffset:            WORD,
	nFileExtension:         WORD,
	lpstrDefExt:            LPCWSTR,
	lCustData:              LPARAM,
	lpfnHook:               LPOFNHOOKPROC,
	lpTemplateName:         LPCWSTR,
	pvReserved:             rawptr,
	dwReserved:             DWORD,
	FlagsEx:                DWORD,
}

@(default_calling_convention="system")
foreign Comdlg32 {
	GetOpenFileNameW     :: proc(arg1: ^OPENFILENAMEW) -> BOOL ---
	GetSaveFileNameW     :: proc(arg1: ^OPENFILENAMEW) -> BOOL ---

	GetFileTitleW        :: proc(s: LPCWSTR, Buf: LPWSTR, cchSize: WORD) -> c_short ---
}

OPEN_TITLE :: "Select file to open"
OPEN_FLAGS :: u32(OFN_PATHMUSTEXIST | OFN_FILEMUSTEXIST)
OPEN_FLAGS_MULTI :: OPEN_FLAGS | OFN_ALLOWMULTISELECT | OFN_EXPLORER

SAVE_TITLE :: "Select file to save"
SAVE_FLAGS :: u32(OFN_OVERWRITEPROMPT | OFN_EXPLORER)
SAVE_EXT   :: "txt"

OFN_ALLOWMULTISELECT     :: 0x00000200 // NOTE(Jeroen): Without OFN_EXPLORER it uses the Win3 dialog.
OFN_CREATEPROMPT         :: 0x00002000
OFN_DONTADDTORECENT      :: 0x02000000
OFN_ENABLEHOOK           :: 0x00000020
OFN_ENABLEINCLUDENOTIFY  :: 0x00400000
OFN_ENABLESIZING         :: 0x00800000
OFN_ENABLETEMPLATE       :: 0x00000040
OFN_ENABLETEMPLATEHANDLE :: 0x00000080
OFN_EXPLORER             :: 0x00080000
OFN_EXTENSIONDIFFERENT   :: 0x00000400
OFN_FILEMUSTEXIST        :: 0x00001000
OFN_FORCESHOWHIDDEN      :: 0x10000000
OFN_HIDEREADONLY         :: 0x00000004
OFN_LONGNAMES            :: 0x00200000
OFN_NOCHANGEDIR          :: 0x00000008
OFN_NODEREFERENCELINKS   :: 0x00100000
OFN_NOLONGNAMES          :: 0x00040000
OFN_NONETWORKBUTTON      :: 0x00020000
OFN_NOREADONLYRETURN     :: 0x00008000
OFN_NOTESTFILECREATE     :: 0x00010000
OFN_NOVALIDATE           :: 0x00000100
OFN_OVERWRITEPROMPT      :: 0x00000002
OFN_PATHMUSTEXIST        :: 0x00000800
OFN_READONLY             :: 0x00000001
OFN_SHAREAWARE           :: 0x00004000
OFN_SHOWHELP             :: 0x00000010

// Choose Color dialog

LPCCHOOKPROC :: #type proc "system" (hwnd: HWND, msg: UINT, wParam: WPARAM, lParam: LPARAM) -> UINT_PTR

CHOOSECOLORW :: struct {
	lStructSize:     DWORD,
	hwndOwner:       HWND,
	hInstance:       HWND,
	rgbResult:       COLORREF,
	lpCustColors:    ^COLORREF,
	Flags:           DWORD,
	lCustData:       LPARAM,
	lpfnHook:        LPCCHOOKPROC,
	lpTemplateName:  LPCWSTR,
}

@(default_calling_convention="system")
foreign Comdlg32 {
	ChooseColorW :: proc(lpcc: ^CHOOSECOLORW) -> BOOL ---
}

// Flags for CHOOSECOLORW
CC_RGBINIT               :: 0x00000001
CC_FULLOPEN              :: 0x00000002
CC_PREVENTFULLOPEN       :: 0x00000004
CC_SHOWHELP              :: 0x00000008
CC_ENABLEHOOK            :: 0x00000010
CC_ENABLETEMPLATE        :: 0x00000020
CC_ENABLETEMPLATEHANDLE  :: 0x00000040
CC_SOLIDCOLOR            :: 0x00000080
CC_ANYCOLOR              :: 0x00000100

// Find and replace dialog

LPFRHOOKPROC :: #type proc "system" (hwnd: HWND, msg: UINT, wparam: WPARAM, lparam: LPARAM) -> UINT_PTR

FINDREPLACEW :: struct {
	lStructSize:       DWORD,         // size of this struct 0x20
	hwndOwner:         HWND,          // handle to owner's window
	hInstance:         HINSTANCE,     // instance handle of.EXE that contains cust. dlg. template
	Flags:             DWORD,         // one or more of the FR_??
	lpstrFindWhat:     LPWSTR,        // ptr. to search string
	lpstrReplaceWith:  LPWSTR,        // ptr. to replace string
	wFindWhatLen:      WORD,          // size of find buffer
	wReplaceWithLen:   WORD,          // size of replace buffer
	lCustData:         LPARAM,        // data passed to hook fn.
	lpfnHook:          LPFRHOOKPROC,  // ptr. to hook fn. or NULL
	lpTemplateName:    LPCWSTR,       // custom template name
}

// Flags for FINDREPLACEW
FR_DOWN                  :: 0x00000001
FR_WHOLEWORD             :: 0x00000002
FR_MATCHCASE             :: 0x00000004
FR_FINDNEXT              :: 0x00000008
FR_REPLACE               :: 0x00000010
FR_REPLACEALL            :: 0x00000020
FR_DIALOGTERM            :: 0x00000040
FR_SHOWHELP              :: 0x00000080
FR_ENABLEHOOK            :: 0x00000100
FR_ENABLETEMPLATE        :: 0x00000200
FR_NOUPDOWN              :: 0x00000400
FR_NOMATCHCASE           :: 0x00000800
FR_NOWHOLEWORD           :: 0x00001000
FR_ENABLETEMPLATEHANDLE  :: 0x00002000
FR_HIDEUPDOWN            :: 0x00004000
FR_HIDEMATCHCASE         :: 0x00008000
FR_HIDEWHOLEWORD         :: 0x00010000
FR_RAW                   :: 0x00020000
FR_SHOWWRAPAROUND        :: 0x00040000
FR_NOWRAPAROUND          :: 0x00080000
FR_WRAPAROUND            :: 0x00100000
FR_MATCHDIAC             :: 0x20000000
FR_MATCHKASHIDA          :: 0x40000000
FR_MATCHALEFHAMZA        :: 0x80000000

@(default_calling_convention="system")
foreign Comdlg32 {
	FindTextW :: proc(lpcc: ^FINDREPLACEW) -> HWND ---
	ReplaceTextW :: proc(lpcc: ^FINDREPLACEW) -> HWND ---
}

FINDMSGSTRINGW :: wstring("commdlg_FindReplace")

// Choose Font dialog

LPCFHOOKPROC :: #type proc "system" (hwnd: HWND, msg: UINT, wparam: WPARAM, lparam: LPARAM) -> UINT_PTR

CHOOSEFONTW :: struct {
	lStructSize:     DWORD,
	hwndOwner:       HWND,          // caller's window handle
	hDC:             HDC,           // printer DC/IC or NULL
	lpLogFont:       LPLOGFONTW,    // ptr. to a LOGFONT struct
	iPointSize:      INT,           // 10 * size in points of selected font
	Flags:           DWORD,         // enum. type flags
	rgbColors:       COLORREF,      // returned text color
	lCustData:       LPARAM,        // data passed to hook fn.
	lpfnHook:        LPCFHOOKPROC,  // ptr. to hook function
	lpTemplateName:  LPCWSTR,       // custom template name
	hInstance:       HINSTANCE,     // instance handle of.EXE that contains cust. dlg. template
	lpszStyle:       LPWSTR,        // return the style field here
	                                // must be LF_FACESIZE or bigger
	nFontType:       WORD,          // same value reported to the EnumFonts call back with the extra FONTTYPE_ bits added
	___MISSING_ALIGNMENT__: WORD,
	nSizeMin:        INT,           // minimum pt size allowed &
	nSizeMax:        INT,           // max pt size allowed if CF_LIMITSIZE is used
}

@(default_calling_convention="system")
foreign Comdlg32 {
	ChooseFontW :: proc(lpcc: ^CHOOSEFONTW) -> BOOL ---
}

// Flags for CHOOSEFONTW
CF_SCREENFONTS            :: 0x00000001
CF_PRINTERFONTS           :: 0x00000002
CF_BOTH                   :: (CF_SCREENFONTS | CF_PRINTERFONTS)
CF_SHOWHELP               :: 0x00000004
CF_ENABLEHOOK             :: 0x00000008
CF_ENABLETEMPLATE         :: 0x00000010
CF_ENABLETEMPLATEHANDLE   :: 0x00000020
CF_INITTOLOGFONTSTRUCT    :: 0x00000040
CF_USESTYLE               :: 0x00000080
CF_EFFECTS                :: 0x00000100
CF_APPLY                  :: 0x00000200
CF_ANSIONLY               :: 0x00000400
CF_SCRIPTSONLY            :: CF_ANSIONLY
CF_NOVECTORFONTS          :: 0x00000800
CF_NOOEMFONTS             :: CF_NOVECTORFONTS
CF_NOSIMULATIONS          :: 0x00001000
CF_LIMITSIZE              :: 0x00002000
CF_FIXEDPITCHONLY         :: 0x00004000
CF_WYSIWYG                :: 0x00008000 // must also have CF_SCREENFONTS & CF_PRINTERFONTS
CF_FORCEFONTEXIST         :: 0x00010000
CF_SCALABLEONLY           :: 0x00020000
CF_TTONLY                 :: 0x00040000
CF_NOFACESEL              :: 0x00080000
CF_NOSTYLESEL             :: 0x00100000
CF_NOSIZESEL              :: 0x00200000
CF_SELECTSCRIPT           :: 0x00400000
CF_NOSCRIPTSEL            :: 0x00800000
CF_NOVERTFONTS            :: 0x01000000
CF_INACTIVEFONTS          :: 0x02000000

// Print dialog

LPPRINTHOOKPROC :: #type proc "system" (hwnd: HWND, msg: UINT, wparam: WPARAM, lparam: LPARAM) -> UINT_PTR
LPSETUPHOOKPROC :: #type proc "system" (hwnd: HWND, msg: UINT, wparam: WPARAM, lparam: LPARAM) -> UINT_PTR

PRINTDLGW :: struct {
	lStructSize:          DWORD,
	hwndOwner:            HWND,
	hDevMode:             HGLOBAL,
	hDevNames:            HGLOBAL,
	hDC:                  HDC,
	Flags:                DWORD,
	nFromPage:            WORD,
	nToPage:              WORD,
	nMinPage:             WORD,
	nMaxPage:             WORD,
	nCopies:              WORD,
	hInstance:            HINSTANCE,
	lCustData:            LPARAM,
	lpfnPrintHook:        LPPRINTHOOKPROC,
	lpfnSetupHook:        LPSETUPHOOKPROC,
	lpPrintTemplateName:  LPCWSTR,
	lpSetupTemplateName:  LPCWSTR,
	hPrintTemplate:       HGLOBAL,
	hSetupTemplate:       HGLOBAL,
}

PRINTPAGERANGE :: struct {
	nFromPage:  DWORD,
	nToPage:    DWORD,
}

LPPRINTPAGERANGE :: #type ^PRINTPAGERANGE
HPROPSHEETPAGE :: distinct LPVOID

PRINTDLGEXW :: struct {
	lStructSize:          DWORD,             // size of structure in bytes
	hwndOwner:            HWND,              // caller's window handle
	hDevMode:             HGLOBAL,           // handle to DevMode
	hDevNames:            HGLOBAL,           // handle to DevNames
	hDC:                  HDC,               // printer DC/IC or NULL
	Flags:                DWORD,             // PD_ flags
	Flags2:               DWORD,             // reserved
	ExclusionFlags:       DWORD,             // items to exclude from driver pages
	nPageRanges:          DWORD,             // number of page ranges
	nMaxPageRanges:       DWORD,             // max number of page ranges
	lpPageRanges:         LPPRINTPAGERANGE,  // array of page ranges
	nMinPage:             DWORD,             // min page number
	nMaxPage:             DWORD,             // max page number
	nCopies:              DWORD,             // number of copies
	hInstance:            HINSTANCE,         // instance handle
	lpPrintTemplateName:  LPCWSTR,           // template name for app specific area
	lpCallback:           LPUNKNOWN,         // app callback interface
	nPropertyPages:       DWORD,             // number of app property pages in lphPropertyPages
	lphPropertyPages:     ^HPROPSHEETPAGE,   // array of app property page handles
	nStartPage:           DWORD,             // start page id
	dwResultAction:       DWORD,             // result action if S_OK is returned
}

// Device Names structure for PrintDlg and PrintDlgEx.
DEVNAMES :: struct {
	wDriverOffset: WORD,
	wDeviceOffset: WORD,
	wOutputOffset: WORD,
	wDefault:      WORD,
}

@(default_calling_convention="system")
foreign Comdlg32 {
	PrintDlgW :: proc(lpcc: ^PRINTDLGW) -> BOOL ---
	PrintDlgExW :: proc(lpcc: ^PRINTDLGEXW) -> HRESULT ---
}

// Flags for PRINTDLGW and PRINTDLGEXW
PD_ALLPAGES                    :: 0x00000000
PD_SELECTION                   :: 0x00000001
PD_PAGENUMS                    :: 0x00000002
PD_NOSELECTION                 :: 0x00000004
PD_NOPAGENUMS                  :: 0x00000008
PD_COLLATE                     :: 0x00000010
PD_PRINTTOFILE                 :: 0x00000020
PD_PRINTSETUP                  :: 0x00000040
PD_NOWARNING                   :: 0x00000080
PD_RETURNDC                    :: 0x00000100
PD_RETURNIC                    :: 0x00000200
PD_RETURNDEFAULT               :: 0x00000400
PD_SHOWHELP                    :: 0x00000800
PD_ENABLEPRINTHOOK             :: 0x00001000
PD_ENABLESETUPHOOK             :: 0x00002000
PD_ENABLEPRINTTEMPLATE         :: 0x00004000
PD_ENABLESETUPTEMPLATE         :: 0x00008000
PD_ENABLEPRINTTEMPLATEHANDLE   :: 0x00010000
PD_ENABLESETUPTEMPLATEHANDLE   :: 0x00020000
PD_USEDEVMODECOPIES            :: 0x00040000
PD_USEDEVMODECOPIESANDCOLLATE  :: 0x00040000
PD_DISABLEPRINTTOFILE          :: 0x00080000
PD_HIDEPRINTTOFILE             :: 0x00100000
PD_NONETWORKBUTTON             :: 0x00200000
PD_CURRENTPAGE                 :: 0x00400000
PD_NOCURRENTPAGE               :: 0x00800000
PD_EXCLUSIONFLAGS              :: 0x01000000
PD_USELARGETEMPLATE            :: 0x10000000

//  Define the start page for the print dialog when using PrintDlgEx.
START_PAGE_GENERAL             :: 0xffffffff

//  Result action ids for PrintDlgEx.
PD_RESULT_CANCEL               :: 0
PD_RESULT_PRINT                :: 1
PD_RESULT_APPLY                :: 2

// Page Setup dialog

// Window Message IDs for the LPPAGEPAINTHOOK
WM_PSD_PAGESETUPDLG     :: (WM_USER  )
WM_PSD_FULLPAGERECT     :: (WM_USER+1)
WM_PSD_MINMARGINRECT    :: (WM_USER+2)
WM_PSD_MARGINRECT       :: (WM_USER+3)
WM_PSD_GREEKTEXTRECT    :: (WM_USER+4)
WM_PSD_ENVSTAMPRECT     :: (WM_USER+5)
WM_PSD_YAFULLPAGERECT   :: (WM_USER+6)

LPPAGEPAINTHOOK :: #type proc "system" (hwnd: HWND, msg: UINT, wparam: WPARAM, lparam: LPARAM) -> UINT_PTR
LPPAGESETUPHOOK :: #type proc "system" (hwnd: HWND, msg: UINT, wparam: WPARAM, lparam: LPARAM) -> UINT_PTR

PAGESETUPDLGW :: struct {
	lStructSize:              DWORD,
	hwndOwner:                HWND,
	hDevMode:                 HGLOBAL,
	hDevNames:                HGLOBAL,
	Flags:                    DWORD,
	ptPaperSize:              POINT,
	rtMinMargin:              RECT,
	rtMargin:                 RECT,
	hInstance:                HINSTANCE,
	lCustData:                LPARAM,
	lpfnPageSetupHook:        LPPAGESETUPHOOK,
	lpfnPagePaintHook:        LPPAGEPAINTHOOK,
	lpPageSetupTemplateName:  LPCWSTR,
	hPageSetupTemplate:       HGLOBAL,
}

@(default_calling_convention="system")
foreign Comdlg32 {
	PageSetupDlgW :: proc(lpcc: ^PAGESETUPDLGW) -> BOOL ---
}

PSD_DEFAULTMINMARGINS              :: 0x00000000 // default (printer's)
PSD_INWININIINTLMEASURE            :: 0x00000000 // 1st of 4 possible

PSD_MINMARGINS                     :: 0x00000001 // use caller's
PSD_MARGINS                        :: 0x00000002 // use caller's
PSD_INTHOUSANDTHSOFINCHES          :: 0x00000004 // 2nd of 4 possible
PSD_INHUNDREDTHSOFMILLIMETERS      :: 0x00000008 // 3rd of 4 possible
PSD_DISABLEMARGINS                 :: 0x00000010
PSD_DISABLEPRINTER                 :: 0x00000020
PSD_NOWARNING                      :: 0x00000080 // must be same as PD_*
PSD_DISABLEORIENTATION             :: 0x00000100
PSD_RETURNDEFAULT                  :: 0x00000400 // must be same as PD_*
PSD_DISABLEPAPER                   :: 0x00000200
PSD_SHOWHELP                       :: 0x00000800 // must be same as PD_*
PSD_ENABLEPAGESETUPHOOK            :: 0x00002000 // must be same as PD_*
PSD_ENABLEPAGESETUPTEMPLATE        :: 0x00008000 // must be same as PD_*
PSD_ENABLEPAGESETUPTEMPLATEHANDLE  :: 0x00020000 // must be same as PD_*
PSD_ENABLEPAGEPAINTHOOK            :: 0x00040000
PSD_DISABLEPAGEPAINTING            :: 0x00080000
PSD_NONETWORKBUTTON                :: 0x00200000 // must be same as PD_*

// Common error codes for all comdlg32 dialogs (CommDlgExtendedError)

@(default_calling_convention="system")
foreign Comdlg32 {
	CommDlgExtendedError :: proc() -> u32 ---
}

CDERR_DIALOGFAILURE      :: 0x0000FFFF
CDERR_GENERALCODES       :: 0x00000000
CDERR_STRUCTSIZE         :: 0x00000001
CDERR_INITIALIZATION     :: 0x00000002
CDERR_NOTEMPLATE         :: 0x00000003
CDERR_NOHINSTANCE        :: 0x00000004
CDERR_LOADSTRFAILURE     :: 0x00000005
CDERR_FINDRESFAILURE     :: 0x00000006
CDERR_LOADRESFAILURE     :: 0x00000007
CDERR_LOCKRESFAILURE     :: 0x00000008
CDERR_MEMALLOCFAILURE    :: 0x00000009
CDERR_MEMLOCKFAILURE     :: 0x0000000A
CDERR_NOHOOK             :: 0x0000000B
CDERR_REGISTERMSGFAIL    :: 0x0000000C
