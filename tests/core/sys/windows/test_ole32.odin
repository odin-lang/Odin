//+build windows
package test_core_sys_windows

import "base:intrinsics"
import win32 "core:sys/windows"
import "core:testing"

@(test)
string_from_clsid :: proc(t: ^testing.T) {
	p: win32.LPOLESTR
	hr := win32.StringFromCLSID(win32.CLSID_FileOpenDialog, &p)
	defer if p != nil {win32.CoTaskMemFree(p)}

	testing.expectf(t, win32.SUCCEEDED(hr), "%x (should be: %x)", u32(hr), 0)
	testing.expectf(t, p != nil, "%v is nil", p)

	str, err := win32.wstring_to_utf8(p, 38)
	testing.expectf(t, err == .None, "%v (should be: %x)", err, 0)
	exp :: "{DC1C5A9C-E88A-4DDE-A5A1-60F82A20AEF7}"
	testing.expectf(t, str == exp, "%v (should be: %v)", str, exp)
}

@(test)
clsid_from_string :: proc(t: ^testing.T) {
	iid: win32.IID
	hr := win32.CLSIDFromString(L("{D20BEEC4-5CA8-4905-AE3B-BF251EA09B53}"), &iid)
	testing.expectf(t, win32.SUCCEEDED(hr), "%x (should be: %x)", u32(hr), 0)
	exp := win32.FOLDERID_NetworkFolder
	testing.expectf(t, iid == exp, "%v (should be: %v)", iid, exp)
}

@(test)
string_from_iid :: proc(t: ^testing.T) {
	p: win32.LPOLESTR
	hr := win32.StringFromIID(win32.IID_IFileDialog, &p)
	defer if p != nil {win32.CoTaskMemFree(p)}

	testing.expectf(t, win32.SUCCEEDED(hr), "%x (should be: %x)", u32(hr), 0)
	testing.expectf(t, p != nil, "%v is nil", p)

	str, err := win32.wstring_to_utf8(p, 40)
	testing.expectf(t, err == .None, "%v (should be: %x)", err, 0)
	exp :: "{42F85136-DB7E-439C-85F1-E4075D135FC8}"
	testing.expectf(t, str == exp, "%v (should be: %v)", str, exp)
}

@(test)
iid_from_string :: proc(t: ^testing.T) {
	iid: win32.IID
	hr := win32.IIDFromString(L("{D20BEEC4-5CA8-4905-AE3B-BF251EA09B53}"), &iid)
	testing.expectf(t, win32.SUCCEEDED(hr), "%x (should be: %x)", u32(hr), 0)
	exp := win32.FOLDERID_NetworkFolder
	testing.expectf(t, iid == exp, "%v (should be: %v)", iid, exp)
}

@(test)
verify_coinit :: proc(t: ^testing.T) {
	expect_value(t, win32.COINIT.MULTITHREADED, 0x00000000)
	expect_value(t, win32.COINIT.APARTMENTTHREADED, 0x00000002)
	expect_value(t, win32.COINIT.DISABLE_OLE1DDE, 0x00000004)
	expect_value(t, win32.COINIT.SPEED_OVER_MEMORY, 0x00000008)
}
