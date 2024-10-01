#+build windows
package test_core_sys_windows

import "base:intrinsics"
import win32 "core:sys/windows"
import "core:testing"

@(test)
lcid_to_local :: proc(t: ^testing.T) {
	lcid: win32.LCID = win32.MAKELANGID(0x09, win32.SUBLANG_DEFAULT)
	wname: [512]win32.WCHAR
	cc := win32.LCIDToLocaleName(lcid, &wname[0], len(wname) - 1, 0)
	testing.expectf(t, cc == 6, "%#x (should be: %#x)", u32(cc), 6)
	if cc == 0 {return}
	str, err := win32.wstring_to_utf8(win32.wstring(&wname), int(cc))
	testing.expectf(t, err == .None, "%v (should be: %x)", err, 0)
	exp :: "en-US"
	testing.expectf(t, str == exp, "%v (should be: %v)", str, exp)

	cc2 := win32.LocaleNameToLCID(L(exp), 0)
	testing.expectf(t, cc2 == 0x0409, "%#x (should be: %#x)", u32(cc2), 0x0409)

	//fmt.printfln("%0X", lcid)
}
