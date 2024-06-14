// +build windows
package sys_windows

LCTYPE :: distinct DWORD

LOCALE_NAME_MAX_LENGTH     :: 85
LOCALE_NAME_USER_DEFAULT   :: 0
LOCALE_NAME_INVARIANT      : wstring = L("")
LOCALE_NAME_SYSTEM_DEFAULT : wstring = L("!x-sys-default-locale")

// String Length Maximums.
// 5 ranges, 2 bytes ea., 0 term.
MAX_LEADBYTES   :: 12
// single or double byte
MAX_DEFAULTCHAR :: 2

CPINFOEXW :: struct{
	// Maximum length, in bytes, of a character in the code page.
	MaxCharSize: UINT,
	// The default is usually the "?" character for the code page.
	DefaultChar: [MAX_DEFAULTCHAR]BYTE,
	// A fixed-length array of lead byte ranges, for which the number of lead byte ranges is variable.
	LeadByte: [MAX_LEADBYTES]BYTE,
	// The default is usually the "?" character or the katakana middle dot character.
	UnicodeDefaultChar: WCHAR,
	// Code page value. This value reflects the code page passed to the GetCPInfoEx function.
	CodePage: CODEPAGE,
	// Full name of the code page.
	CodePageName: [MAX_PATH]WCHAR,
}
LPCPINFOEXW :: ^CPINFOEXW
