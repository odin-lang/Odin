#+build windows
package sys_windows

foreign import version "system:version.lib"

@(default_calling_convention = "system")
foreign version {
	GetFileVersionInfoSizeW :: proc(lpwstrFilename: LPCWSTR, lpdwHandle: LPDWORD) -> DWORD ---
	GetFileVersionInfoW :: proc(lptstrFilename: LPCWSTR, dwHandle: DWORD, dwLen: DWORD, lpData: LPVOID) -> BOOL ---

	GetFileVersionInfoSizeExW :: proc(dwFlags: FILE_VER_GET_FLAGS, lpwstrFilename: LPCWSTR, lpdwHandle: LPDWORD) -> DWORD ---
	GetFileVersionInfoExW :: proc(dwFlags: FILE_VER_GET_FLAGS, lpwstrFilename: LPCWSTR, dwHandle, dwLen: DWORD, lpData: LPVOID) -> DWORD ---

	VerLanguageNameW :: proc(wLang: DWORD, szLang: LPWSTR, cchLang: DWORD) -> DWORD ---
	VerQueryValueW :: proc(pBlock: LPCVOID, lpSubBlock: LPCWSTR, lplpBuffer: ^LPVOID, puLen: PUINT) -> BOOL ---
}

FILE_VER_GET :: enum DWORD {LOCALISED, NEUTRAL, PREFETCHED}
FILE_VER_GET_FLAGS :: bit_set[FILE_VER_GET; DWORD]

/* ----- Symbols ----- */
VS_FILE_INFO            :: RT_VERSION
VS_VERSION_INFO         :: 1
VS_USER_DEFINED         :: 100

VS_FFI_SIGNATURE : DWORD : 0xFEEF04BD

VS_FFI_STRUCVERSION     :: 0x00010000
VS_FFI_FILEFLAGSMASK    :: 0x0000003F

/* ----- VS_VERSION.dwFileFlags ----- */
VS_FILEFLAG :: enum DWORD {
	DEBUG,
	PRERELEASE,
	PATCHED,
	PRIVATEBUILD,
	INFOINFERRED,
	SPECIALBUILD,
}
VS_FILEFLAGS :: bit_set[VS_FILEFLAG;DWORD]

/* ----- VS_VERSION.dwFileOS ----- */
VOS :: enum WORD {
	UNKNOWN = 0x0000,
	DOS     = 0x0001,
	OS216   = 0x0002,
	OS232   = 0x0003,
	NT      = 0x0004,
	WINCE   = 0x0005,
}
VOS2 :: enum WORD {
	BASE      = 0x0000,
	WINDOWS16 = 0x0001,
	PM16      = 0x0002,
	PM32      = 0x0003,
	WINDOWS32 = 0x0004,
}

/* ----- VS_VERSION.dwFileType ----- */
VFT :: enum DWORD {
	UNKNOWN    = 0x00000000,
	APP        = 0x00000001,
	DLL        = 0x00000002,
	DRV        = 0x00000003,
	FONT       = 0x00000004,
	VXD        = 0x00000005,
	STATIC_LIB = 0x00000007,
}

/* ----- VS_VERSION.dwFileSubtype for VFT_WINDOWS_DRV ----- */
VFT2_WINDOWS_DRV :: enum DWORD {
	UNKNOWN               = 0x00000000,
	DRV_PRINTER           = 0x00000001,
	DRV_KEYBOARD          = 0x00000002,
	DRV_LANGUAGE          = 0x00000003,
	DRV_DISPLAY           = 0x00000004,
	DRV_MOUSE             = 0x00000005,
	DRV_NETWORK           = 0x00000006,
	DRV_SYSTEM            = 0x00000007,
	DRV_INSTALLABLE       = 0x00000008,
	DRV_SOUND             = 0x00000009,
	DRV_COMM              = 0x0000000A,
	DRV_INPUTMETHOD       = 0x0000000B,
	DRV_VERSIONED_PRINTER = 0x0000000C,
}

/* ----- VS_VERSION.dwFileSubtype for VFT_WINDOWS_FONT ----- */
VFT2_WINDOWS_FONT :: enum DWORD {
	FONT_RASTER   = 0x00000001,
	FONT_VECTOR   = 0x00000002,
	FONT_TRUETYPE = 0x00000003,
}
