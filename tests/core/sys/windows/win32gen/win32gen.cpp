#define WIN32_LEAN_AND_MEAN // Exclude rarely-used stuff from Windows headers
#include <windows.h>
#include <timeapi.h>
#include <mmeapi.h>
#include <windns.h>
#include <commdlg.h>
#include <winver.h>
#include <shobjidl.h>
#include <shellapi.h>
#include <shlobj.h>
#include <shlwapi.h>
#include <wincrypt.h>
#include <iostream>
#include <fstream>
#include <filesystem>
#include <map>

#include <cassert>
#include <codecvt>
#include <cstdint>
#include <iostream>
#include <locale>
#include <string>
using namespace std;
using namespace std::filesystem;

static std::string ConvertLPCWSTRToString(const LPCWSTR lpcwszStr)
{
	int strLength = WideCharToMultiByte(CP_UTF8, 0, lpcwszStr, -1, nullptr, 0, nullptr, nullptr) - 1;
	string str(strLength, 0);
	WideCharToMultiByte(CP_UTF8, 0, lpcwszStr, -1, &str[0], strLength, nullptr, nullptr);
	return std::string(str);
}

#define test_proc_begin() out \
	<< endl \
	<< "@(test)" << endl \
	<< __func__ << " :: proc(t: ^testing.T) {" << endl

#define test_proc_end() out \
	<< "}" << endl

#define test_proc_using(name) out \
	<< '\t' << "using " << name << endl

#define test_proc_comment(comment) out \
	<< '\t' << "// " << comment << endl

#define expect_size(s) out \
	<< '\t' << "expect_size(t, win32." << #s << ", " \
	<< std::dec << sizeof(s) << ")" << endl

#define expect_value(s) out \
	<< '\t' << "expect_value(t, win32." << #s << ", " \
	<< "0x" << std::uppercase << std::setfill('0') << std::setw(8) << std::hex << s << ")" << endl

#define expect_value_32(s) out \
	<< '\t' << "expect_value(t, u32(win32." << #s << "), " \
	<< "0x" << std::uppercase << std::setfill('0') << std::setw(8) << std::hex << (ULONG)(ULONG_PTR)(s) << ")" << endl

#define expect_value_64(s) out \
	<< '\t' << "expect_value_64(t, u64(win32." << #s << "), " \
	<< "0x" << std::uppercase << std::setfill('0') << std::setw(8) << std::hex << (ULONGLONG)(ULONG_PTR)(s) << ")" << endl

#define expect_value_uintptr(s) out \
	<< '\t' << "expect_value_64(t, uintptr(win32." << #s << "), " \
	<< "0x" << std::uppercase << std::setfill('0') << std::setw(8) << std::hex << (ULONG_PTR)(s) << ")" << endl

#define expect_value_str(s) out \
	<< '\t' << "expect_value_str(t, win32." << #s << ", L(\"" << ConvertLPCWSTRToString(s) << "\"))" << endl

static void verify_win32_type_sizes(ofstream& out) {
	test_proc_begin();
	test_proc_comment("minwindef.h");
	expect_size(ULONG);	  // unsigned long
	expect_size(PULONG);  // unsigned long*
	expect_size(USHORT);  // unsigned short
	expect_size(PUSHORT); // unsigned short*
	expect_size(UCHAR);	  // unsigned char
	// expect_size(PUCHAR);
	// expect_size(PSZ);
	expect_size(DWORD); // unsigned long
	expect_size(BOOL);	// int
	expect_size(BYTE);	// unsigned char
	expect_size(WORD);	// unsigned short
#ifdef PROPVARIANT
	expect_size(FLOAT); // float
	expect_size(DOUBLE); // double
	expect_size(DATE); // double
#endif
	// expect_size(PFLOAT);
	expect_size(PBOOL);
	expect_size(LPBOOL);
	expect_size(PBYTE);
	expect_size(LPBYTE);
	expect_size(PINT);
	expect_size(LPINT);
	// expect_size(PWORD);
	expect_size(LPWORD);
	// expect_size(LPLONG);
	expect_size(PDWORD);
	expect_size(LPDWORD);
	expect_size(LPVOID);
	expect_size(LPCVOID);

	expect_size(INT);	// int
	expect_size(UINT);	// unsigned int
	expect_size(PUINT); // unsigned int*

	expect_size(UINT_PTR); // unsigned __int64
	expect_size(LONG_PTR); // __int64

	expect_size(HANDLE);  // void *
	expect_size(WPARAM);  // unsigned __int64
	expect_size(LPARAM);  // __int64
	expect_size(LRESULT); // __int64

	expect_size(LPHANDLE);
	expect_size(HGLOBAL); // void *
	// expect_size(HLOCAL);
	// expect_size(GLOBALHANDLE);
	// expect_size(LOCALHANDLE);

	expect_size(ATOM); // unsigned short
	expect_size(HKEY);
	expect_size(PHKEY);
	// expect_size(HMETAFILE);
	expect_size(HINSTANCE);
	expect_size(HMODULE);
	expect_size(HRGN);
	expect_size(HRSRC);
	// expect_size(HSPRITE);
	// expect_size(HLSURF);
	// expect_size(HSTR);
	// expect_size(HTASK);
	// expect_size(HWINSTA);
	// expect_size(HKL);

	//expect_size(HFILE);

	test_proc_comment("windef.h");
	expect_size(HWND);
	expect_size(HHOOK);
	expect_size(HGDIOBJ);
	expect_size(HBITMAP);
	expect_size(HPALETTE);
	expect_size(HBRUSH);
	expect_size(HPEN);
	expect_size(HFONT);
	expect_size(HICON);
	expect_size(HMENU);
	expect_size(HCURSOR);
	expect_size(COLORREF);
	expect_size(RECT);
	expect_size(POINT);
	expect_size(SIZE);

	test_proc_comment("wtypes.h");
	expect_size(DECIMAL);
#ifdef PROPVARIANT
	expect_size(CY);
#endif

	test_proc_comment("fileapi.h");
	expect_size(WIN32_FILE_ATTRIBUTE_DATA);

	test_proc_comment("libloaderapi.h");
	expect_size(ENUMRESNAMEPROCW);
	expect_size(ENUMRESTYPEPROCW);

	test_proc_comment("minwinbase.h");
	expect_size(SYSTEMTIME);
	expect_size(WIN32_FIND_DATAW);
	expect_size(CRITICAL_SECTION);
	// expect_size(PROCESS_HEAP_ENTRY);
	expect_size(REASON_CONTEXT);

	test_proc_comment("guiddef.h");
	expect_size(GUID);
	expect_size(IID);
	expect_size(CLSID);
	test_proc_comment("combaseapi.h");
	expect_size(SCODE);
#ifdef PROPVARIANT
	expect_size(VARTYPE);
	expect_size(VARIANT_BOOL);
	expect_size(CLIPDATA);
	expect_size(SAFEARRAYBOUND);
	expect_size(SAFEARRAY);
	expect_size(CAPROPVARIANT);
	expect_size(PROPVARIANT);
#endif
	test_proc_comment("commdlg.h");
	expect_size(OPENFILENAMEW);
	// test_proc_comment("windns.h");
	// expect_size(DNS_RECORDA);
	// expect_size(DNS_RECORDW);
	// SHCreateLibrary
	test_proc_comment("wtypesbase.h");
	expect_size(OLECHAR);
	//test_proc_comment("objbase.h");
	//expect_value(COINIT_MULTITHREADED);
	//expect_value(COINIT_APARTMENTTHREADED);
	//expect_value(COINIT_DISABLE_OLE1DDE);
	//expect_value(COINIT_SPEED_OVER_MEMORY);
	test_proc_end();
}

static void verify_macros(ofstream& out) {
	test_proc_begin();
	test_proc_comment("minwindef.h");
	expect_value(MAKEWORD(1, 2));
	expect_value(MAKEWORD(0x1111, 0x2222));
	expect_value(MAKELONG(1, 2));
	expect_value(MAKELONG(0x1111, 0x2222));
	expect_value(LOWORD(0x12345678));
	expect_value(HIWORD(0x12345678));
	expect_value_32(LOBYTE(0x1234));
	expect_value_32(HIBYTE(0x1234));
	test_proc_comment("winuser.h");
	expect_value(MAKEWPARAM(1, 2));
	expect_value(MAKEWPARAM(0x1111, 0x2222));
	expect_value(MAKELPARAM(1, 2));
	expect_value(MAKELPARAM(0x1111, 0x2222));
	expect_value(MAKELRESULT(1, 2));
	expect_value(MAKELRESULT(0x1111, 0x2222));
	test_proc_comment("winnt.h");
	expect_value(MAKELCID(1, 2));
	expect_value(MAKELCID(0x1111, 0x2222));
	expect_value(MAKELANGID(1, 2));
	expect_value(MAKELANGID(0x111, 0x222));
	expect_value(LANGIDFROMLCID(0x12345678));
	test_proc_end();
}

static void verify_winnt(ofstream& out) {
	test_proc_begin();
	test_proc_comment("winnt.h");
	expect_size(CHAR);
	expect_size(SHORT);
	expect_size(LONG);
	expect_size(INT);
	expect_size(WCHAR);
	// expect_size(LONGLONG);
	expect_size(ULONGLONG);
	expect_size(LARGE_INTEGER);
	expect_size(PLARGE_INTEGER);
	expect_size(ULARGE_INTEGER);
	expect_size(PULARGE_INTEGER);
	expect_size(BOOLEAN);
	expect_size(HANDLE);
	expect_size(PHANDLE);
	expect_size(HRESULT);
	// expect_size(CCHAR);
	expect_size(LCID);
	expect_size(LANGID);

	expect_size(LUID);
	expect_size(SECURITY_INFORMATION);
	expect_size(ACCESS_MASK);
	expect_size(REGSAM);
	expect_value(LANG_NEUTRAL);
	expect_value(LANG_INVARIANT);
	expect_value(SUBLANG_NEUTRAL);
	expect_value(SUBLANG_DEFAULT);
	test_proc_end();
}

static void verify_winuser(ofstream& out) {
	test_proc_begin();
	test_proc_comment("winuser.h");
	//expect_value(UOI_FLAGS);
	expect_size(USEROBJECTFLAGS);
	expect_size(MSG);
	expect_size(WINDOWPOS);
	expect_size(ACCEL);
	expect_size(MENUITEMINFOW);
	expect_size(PAINTSTRUCT);
	expect_size(CREATESTRUCTW);
	expect_size(WINDOWPLACEMENT);
	expect_size(MOUSEINPUT);
	expect_size(KEYBDINPUT);
	expect_size(HARDWAREINPUT);
	expect_size(INPUT);

	// expect_size(ICONINFO);
	// expect_size(CURSORSHAPE);
	expect_size(ICONINFOEXW);

	expect_size(CURSORINFO);
	//expect_value(CURSOR_SHOWING);
	//expect_value(CURSOR_SUPPRESSED);

	expect_size(WINDOWINFO);

	expect_size(RAWINPUTHEADER);
	//expect_size(RAWHID);
	expect_size(RAWMOUSE);
	expect_size(RAWKEYBOARD);
	expect_size(RAWINPUT);
	expect_size(RAWINPUTDEVICE);
	expect_size(RAWINPUTDEVICELIST);

	expect_size(RID_DEVICE_INFO_HID);
	expect_size(RID_DEVICE_INFO_KEYBOARD);
	expect_size(RID_DEVICE_INFO_MOUSE);
	expect_size(RID_DEVICE_INFO);
	expect_value(GET_RAWINPUT_CODE_WPARAM(0x12345678));

	expect_size(DRAWTEXTPARAMS);
	expect_size(BSMINFO);

	expect_value(BROADCAST_QUERY_DENY);
	expect_value_64(HWND_BROADCAST);
	expect_value_64(HWND_MESSAGE);

	expect_value_uintptr(MAKEINTRESOURCEW(1));
	expect_value_uintptr(MAKEINTRESOURCEW(0x12345678));

	expect_value_uintptr(RT_CURSOR);
	expect_value_uintptr(RT_BITMAP);
	expect_value_uintptr(RT_ICON);
	expect_value_uintptr(RT_MENU);
	expect_value_uintptr(RT_DIALOG);
	expect_value_uintptr(RT_STRING);
	expect_value_uintptr(RT_FONTDIR);
	expect_value_uintptr(RT_FONT);
	expect_value_uintptr(RT_ACCELERATOR);
	expect_value_uintptr(RT_RCDATA);
	expect_value_uintptr(RT_MESSAGETABLE);
	expect_value_uintptr(RT_GROUP_CURSOR);
	expect_value_uintptr(RT_GROUP_ICON);
	expect_value_uintptr(RT_VERSION);
	expect_value_uintptr(RT_DLGINCLUDE);
	expect_value_uintptr(RT_PLUGPLAY);
	expect_value_uintptr(RT_VXD);
	expect_value_uintptr(RT_ANICURSOR);
	expect_value_uintptr(RT_ANIICON);
	expect_value_uintptr(RT_MANIFEST);

	expect_value_uintptr(CREATEPROCESS_MANIFEST_RESOURCE_ID);
	expect_value_uintptr(ISOLATIONAWARE_MANIFEST_RESOURCE_ID);
	expect_value_uintptr(ISOLATIONAWARE_NOSTATICIMPORT_MANIFEST_RESOURCE_ID);
	expect_value_uintptr(ISOLATIONPOLICY_MANIFEST_RESOURCE_ID);
	expect_value_uintptr(ISOLATIONPOLICY_BROWSER_MANIFEST_RESOURCE_ID);
	expect_value_uintptr(MINIMUM_RESERVED_MANIFEST_RESOURCE_ID);
	expect_value_uintptr(MAXIMUM_RESERVED_MANIFEST_RESOURCE_ID);

	expect_value(SM_CXICON);
	expect_value(SM_CYICON);

	expect_value(LR_DEFAULTCOLOR);
	expect_value(LR_MONOCHROME);
	expect_value(LR_COLOR);
	expect_value(LR_COPYRETURNORG);
	expect_value(LR_COPYDELETEORG);
	expect_value(LR_LOADFROMFILE);
	expect_value(LR_LOADTRANSPARENT);
	expect_value(LR_DEFAULTSIZE);
	expect_value(LR_VGACOLOR);
	expect_value(LR_LOADMAP3DCOLORS);
	expect_value(LR_CREATEDIBSECTION);
	expect_value(LR_COPYFROMRESOURCE);
	expect_value(LR_SHARED);

	expect_value(NIM_ADD);
	expect_value(NIM_MODIFY);
	expect_value(NIM_DELETE);
	expect_value(NIM_SETFOCUS);
	expect_value(NIM_SETVERSION);

	expect_value(NIF_MESSAGE);
	expect_value(NIF_ICON);
	expect_value(NIF_TIP);
	expect_value(NIF_STATE);
	expect_value(NIF_INFO);
	expect_value(NIF_GUID);
	expect_value(NIF_REALTIME);
	expect_value(NIF_SHOWTIP);

	expect_value(MF_INSERT);
	expect_value(MF_CHANGE);
	expect_value(MF_APPEND);
	expect_value(MF_DELETE);
	expect_value(MF_REMOVE);
	expect_value(MF_BYCOMMAND);
	expect_value(MF_BYPOSITION);
	expect_value(MF_SEPARATOR);
	expect_value(MF_ENABLED);
	expect_value(MF_GRAYED);
	expect_value(MF_DISABLED);
	expect_value(MF_UNCHECKED);
	expect_value(MF_CHECKED);
	expect_value(MF_USECHECKBITMAPS);
	expect_value(MF_STRING);
	expect_value(MF_BITMAP);
	expect_value(MF_OWNERDRAW);
	expect_value(MF_POPUP);
	expect_value(MF_MENUBARBREAK);
	expect_value(MF_MENUBREAK);
	expect_value(MF_UNHILITE);
	expect_value(MF_HILITE);
	expect_value(MF_DEFAULT);
	expect_value(MF_SYSMENU);
	expect_value(MF_HELP);
	expect_value(MF_RIGHTJUSTIFY);
	expect_value(MF_MOUSESELECT);
	expect_value(MF_END);

	expect_value(MFS_GRAYED);
	expect_value(MFS_DISABLED);
	expect_value(MFS_CHECKED);
	expect_value(MFS_HILITE);
	expect_value(MFS_ENABLED);
	expect_value(MFS_UNCHECKED);
	expect_value(MFS_UNHILITE);
	expect_value(MFS_DEFAULT);

	expect_value(TPM_LEFTBUTTON);
	expect_value(TPM_RIGHTBUTTON);
	expect_value(TPM_LEFTALIGN);
	expect_value(TPM_CENTERALIGN);
	expect_value(TPM_RIGHTALIGN);
	expect_value(TPM_TOPALIGN);
	expect_value(TPM_VCENTERALIGN);
	expect_value(TPM_BOTTOMALIGN);

	expect_value(TPM_HORIZONTAL);
	expect_value(TPM_VERTICAL);
	expect_value(TPM_NONOTIFY);
	expect_value(TPM_RETURNCMD);
	expect_value(TPM_RECURSE);
	expect_value(TPM_HORPOSANIMATION);
	expect_value(TPM_HORNEGANIMATION);
	expect_value(TPM_VERPOSANIMATION);
	expect_value(TPM_VERNEGANIMATION);
	expect_value(TPM_NOANIMATION);
	expect_value(TPM_LAYOUTRTL);
	expect_value(TPM_WORKAREA);

	expect_value(MIIM_STATE);
	expect_value(MIIM_ID);
	expect_value(MIIM_SUBMENU);
	expect_value(MIIM_CHECKMARKS);
	expect_value(MIIM_TYPE);
	expect_value(MIIM_DATA);
	expect_value(MIIM_STRING);
	expect_value(MIIM_BITMAP);
	expect_value(MIIM_FTYPE);

	expect_value(ANSI_CHARSET);
	expect_value(DEFAULT_CHARSET);
	expect_value(SYMBOL_CHARSET);
	expect_value(SHIFTJIS_CHARSET);
	expect_value(HANGEUL_CHARSET);
	expect_value(HANGUL_CHARSET);
	expect_value(GB2312_CHARSET);
	expect_value(CHINESEBIG5_CHARSET);
	expect_value(OEM_CHARSET);
	expect_value(JOHAB_CHARSET);
	expect_value(HEBREW_CHARSET);
	expect_value(ARABIC_CHARSET);
	expect_value(GREEK_CHARSET);
	expect_value(TURKISH_CHARSET);
	expect_value(VIETNAMESE_CHARSET);
	expect_value(THAI_CHARSET);
	expect_value(EASTEUROPE_CHARSET);
	expect_value(RUSSIAN_CHARSET);
	expect_value(MAC_CHARSET);
	expect_value(BALTIC_CHARSET);

	expect_value(FS_LATIN1);
	expect_value(FS_LATIN2);
	expect_value(FS_CYRILLIC);
	expect_value(FS_GREEK);
	expect_value(FS_TURKISH);
	expect_value(FS_HEBREW);
	expect_value(FS_ARABIC);
	expect_value(FS_BALTIC);
	expect_value(FS_VIETNAMESE);
	expect_value(FS_THAI);
	expect_value(FS_JISJAPAN);
	expect_value(FS_CHINESESIMP);
	expect_value(FS_WANSUNG);
	expect_value(FS_CHINESETRAD);
	expect_value(FS_JOHAB);
	expect_value(FS_SYMBOL);

	expect_value(OUT_DEFAULT_PRECIS);
	expect_value(OUT_STRING_PRECIS);
	expect_value(OUT_CHARACTER_PRECIS);
	expect_value(OUT_STROKE_PRECIS);
	expect_value(OUT_TT_PRECIS);
	expect_value(OUT_DEVICE_PRECIS);
	expect_value(OUT_RASTER_PRECIS);
	expect_value(OUT_TT_ONLY_PRECIS);
	expect_value(OUT_OUTLINE_PRECIS);
	expect_value(OUT_SCREEN_OUTLINE_PRECIS);
	expect_value(OUT_PS_ONLY_PRECIS);

	expect_value(CLIP_DEFAULT_PRECIS);
	expect_value(CLIP_CHARACTER_PRECIS);
	expect_value(CLIP_STROKE_PRECIS);
	expect_value(CLIP_MASK);
	expect_value(CLIP_LH_ANGLES);
	expect_value(CLIP_TT_ALWAYS);
	expect_value(CLIP_DFA_DISABLE);
	expect_value(CLIP_EMBEDDED);

	expect_value(DEFAULT_QUALITY);
	expect_value(DRAFT_QUALITY);
	expect_value(PROOF_QUALITY);
	expect_value(NONANTIALIASED_QUALITY);
	expect_value(ANTIALIASED_QUALITY);
	expect_value(CLEARTYPE_QUALITY);
	expect_value(CLEARTYPE_NATURAL_QUALITY);

	expect_value(DEFAULT_PITCH);
	expect_value(FIXED_PITCH);
	expect_value(VARIABLE_PITCH);
	expect_value(MONO_FONT);

	expect_value(FF_DONTCARE);
	expect_value(FF_ROMAN);
	expect_value(FF_SWISS);
	expect_value(FF_MODERN);
	expect_value(FF_SCRIPT);
	expect_value(FF_DECORATIVE);

	test_proc_end();
}

static void verify_gdi32(ofstream& out) {
	test_proc_begin();
	test_proc_comment("wingdi.h");
	expect_size(DEVMODEW);
	// expect_size(RGBTRIPLE);
	expect_size(RGBQUAD);
	expect_size(PIXELFORMATDESCRIPTOR);
	expect_size(BITMAPINFOHEADER);
	expect_size(BITMAP);
	expect_size(BITMAPV5HEADER);
	expect_size(CIEXYZTRIPLE);
	expect_size(CIEXYZ);
	expect_size(FXPT2DOT30);
	expect_size(TEXTMETRICW);
	expect_size(POINTFLOAT);
	expect_size(GLYPHMETRICSFLOAT);
	// expect_size(LOGPALETTE);
	expect_size(PALETTEENTRY);
	expect_size(DESIGNVECTOR);
	expect_value(LF_FACESIZE);
	expect_value(LF_FULLFACESIZE);
	expect_size(LOGFONTW);
	expect_size(ENUMLOGFONTW);
	expect_size(ENUMLOGFONTEXW);
	expect_size(ENUMLOGFONTEXDVW);
	expect_size(NEWTEXTMETRICW);

	expect_size(LAYERPLANEDESCRIPTOR);
	expect_size(COLOR16);
	expect_size(TRIVERTEX);
	expect_size(GRADIENT_TRIANGLE);
	expect_size(GRADIENT_RECT);
	expect_size(BLENDFUNCTION);
	expect_size(DISPLAY_DEVICEW);
	expect_value(AC_SRC_OVER);
	expect_value(AC_SRC_ALPHA);
	expect_value(RGB(12, 34, 56));
	expect_value(PALETTERGB(12, 34, 56));
	expect_value(PALETTEINDEX(123));
	expect_value(GRADIENT_FILL_RECT_H);
	expect_value(GRADIENT_FILL_RECT_V);
	expect_value(GRADIENT_FILL_TRIANGLE);

	expect_value(BS_SOLID);
	expect_value(BS_NULL);
	expect_value(BS_HOLLOW);
	expect_value(BS_HATCHED);
	expect_value(BS_PATTERN);
	expect_value(BS_INDEXED);
	expect_value(BS_DIBPATTERN);
	expect_value(BS_DIBPATTERNPT);
	expect_value(BS_PATTERN8X8);
	expect_value(BS_DIBPATTERN8X8);
	expect_value(BS_MONOPATTERN);

	expect_value(HS_HORIZONTAL);
	expect_value(HS_VERTICAL);
	expect_value(HS_FDIAGONAL);
	expect_value(HS_BDIAGONAL);
	expect_value(HS_CROSS);
	expect_value(HS_DIAGCROSS);
	expect_value(HS_API_MAX);

	expect_value(PS_SOLID);
	expect_value(PS_DASH);
	expect_value(PS_DOT);
	expect_value(PS_DASHDOT);
	expect_value(PS_DASHDOTDOT);
	expect_value(PS_NULL);
	expect_value(PS_INSIDEFRAME);
	expect_value(PS_USERSTYLE);
	expect_value(PS_ALTERNATE);
	expect_value(PS_STYLE_MASK);

	expect_value(PS_ENDCAP_ROUND);
	expect_value(PS_ENDCAP_SQUARE);
	expect_value(PS_ENDCAP_FLAT);
	expect_value(PS_ENDCAP_MASK);

	expect_value(PS_JOIN_ROUND);
	expect_value(PS_JOIN_BEVEL);
	expect_value(PS_JOIN_MITER);

	expect_value(PS_COSMETIC);
	expect_value(PS_GEOMETRIC);
	expect_value(PS_TYPE_MASK);

	test_proc_comment("Binary raster ops");
	expect_value(R2_BLACK);
	expect_value(R2_NOTMERGEPEN);
	expect_value(R2_MASKNOTPEN);
	expect_value(R2_NOTCOPYPEN);
	expect_value(R2_MASKPENNOT);
	expect_value(R2_NOT);
	expect_value(R2_XORPEN);
	expect_value(R2_NOTMASKPEN);
	expect_value(R2_MASKPEN);
	expect_value(R2_NOTXORPEN);
	expect_value(R2_NOP);
	expect_value(R2_MERGENOTPEN);
	expect_value(R2_COPYPEN);
	expect_value(R2_MERGEPENNOT);
	expect_value(R2_MERGEPEN);
	expect_value(R2_WHITE);
	test_proc_comment("Ternary raster operations");
	expect_value(SRCCOPY);
	expect_value(SRCPAINT);
	expect_value(SRCAND);
	expect_value(SRCINVERT);
	expect_value(SRCERASE);
	expect_value(NOTSRCCOPY);
	expect_value(NOTSRCERASE);
	expect_value(MERGECOPY);
	expect_value(MERGEPAINT);
	expect_value(PATCOPY);
	expect_value(PATPAINT);
	expect_value(PATINVERT);
	expect_value(DSTINVERT);
	expect_value(BLACKNESS);
	expect_value(WHITENESS);
	expect_value(NOMIRRORBITMAP);
	expect_value(CAPTUREBLT);
	test_proc_comment("Region Flags");
	expect_value(ERROR);
	expect_value(NULLREGION);
	expect_value(SIMPLEREGION);
	expect_value(COMPLEXREGION);
	expect_value(RGN_ERROR);
	test_proc_comment("CombineRgn() Styles");
	expect_value(RGN_AND);
	expect_value(RGN_OR);
	expect_value(RGN_XOR);
	expect_value(RGN_DIFF);
	expect_value(RGN_COPY);
	test_proc_comment("StretchBlt() Modes");
	expect_value(BLACKONWHITE);
	expect_value(WHITEONBLACK);
	expect_value(COLORONCOLOR);
	expect_value(HALFTONE);
	//expect_value(STRETCH_ANDSCANS);
	//expect_value(STRETCH_ORSCANS);
	//expect_value(STRETCH_DELETESCANS);
	//expect_value(STRETCH_HALFTONE);
	test_proc_comment("PolyFill() Modes");
	expect_value(ALTERNATE);
	expect_value(WINDING);
	test_proc_comment("Layout Orientation Options");
	expect_value(LAYOUT_RTL);
	expect_value(LAYOUT_BTT);
	expect_value(LAYOUT_VBH);
	expect_value(LAYOUT_ORIENTATIONMASK);
	test_proc_comment("Text Alignment Options");
	expect_value(TA_NOUPDATECP);
	expect_value(TA_UPDATECP);
	expect_value(TA_LEFT);
	expect_value(TA_RIGHT);
	expect_value(TA_CENTER);
	expect_value(TA_TOP);
	expect_value(TA_BOTTOM);
	expect_value(TA_BASELINE);
	expect_value(TA_RTLREADING);
	expect_value(TA_MASK);
	test_proc_end();
}

static void verify_winmm(ofstream& out) {
	test_proc_begin();
	test_proc_comment("timeapi.h");
	expect_size(TIMECAPS);
	test_proc_comment("mmsyscom.h");
	expect_size(MMVERSION);
	expect_size(MMTIME);
	test_proc_comment("mmeapi.h");
	expect_size(WAVEFORMATEX);
	expect_size(WAVEHDR);
	expect_size(WAVEINCAPSW);
	expect_size(WAVEOUTCAPSW);
	test_proc_end();
}

static void verify_advapi32(ofstream& out) {
	test_proc_begin();
	test_proc_comment("wincrypt.h");
	expect_size(HCRYPTPROV);
	test_proc_end();
}

static void verify_winnls(ofstream& out) {
	test_proc_begin();
	test_proc_comment("winnls.h");
	expect_value(CP_ACP);
	expect_value(CP_OEMCP);
	expect_value(CP_MACCP);
	expect_value(CP_THREAD_ACP);
	expect_value(CP_SYMBOL);
	expect_value(CP_UTF7);
	expect_value(CP_UTF8);
	expect_value(MAX_DEFAULTCHAR);
	expect_value(MAX_LEADBYTES);
	expect_value(LOCALE_NAME_MAX_LENGTH);
	expect_value(LOCALE_NAME_USER_DEFAULT);
	expect_value_str(LOCALE_NAME_INVARIANT);
	expect_value_str(LOCALE_NAME_SYSTEM_DEFAULT);
	expect_size(LCTYPE);
	expect_size(CPINFOEXW);
	test_proc_end();
}

static void verify_winreg(ofstream& out) {
	test_proc_begin();
	test_proc_comment("winreg.h");

	expect_value(RRF_RT_REG_NONE);
	expect_value(RRF_RT_REG_SZ);
	expect_value(RRF_RT_REG_EXPAND_SZ);
	expect_value(RRF_RT_REG_BINARY);
	expect_value(RRF_RT_REG_DWORD);
	expect_value(RRF_RT_REG_MULTI_SZ);
	expect_value(RRF_RT_REG_QWORD);
	expect_value(RRF_RT_DWORD);
	expect_value(RRF_RT_QWORD);
	expect_value(RRF_RT_ANY);
	expect_value(RRF_NOEXPAND);
	expect_value(RRF_ZEROONFAILURE);

	test_proc_comment("winnt.h");
	expect_value_32(HKEY_CLASSES_ROOT);
	expect_value_32(HKEY_CURRENT_USER);
	expect_value_32(HKEY_LOCAL_MACHINE);
	expect_value_32(HKEY_USERS);
	expect_value_32(HKEY_PERFORMANCE_DATA);
	expect_value_32(HKEY_PERFORMANCE_TEXT);
	expect_value_32(HKEY_PERFORMANCE_NLSTEXT);
	expect_value_32(HKEY_CURRENT_CONFIG);
	expect_value_32(HKEY_DYN_DATA);
	expect_value_32(HKEY_CURRENT_USER_LOCAL_SETTINGS);

	expect_value(DELETE);
	expect_value(READ_CONTROL);
	expect_value(WRITE_DAC);
	expect_value(WRITE_OWNER);
	expect_value(SYNCHRONIZE);

	expect_value(KEY_QUERY_VALUE);
	expect_value(KEY_SET_VALUE);
	expect_value(KEY_CREATE_SUB_KEY);
	expect_value(KEY_ENUMERATE_SUB_KEYS);
	expect_value(KEY_NOTIFY);
	expect_value(KEY_CREATE_LINK);
	expect_value(KEY_WOW64_32KEY);
	expect_value(KEY_WOW64_64KEY);
	expect_value(KEY_WOW64_RES);
	expect_value(KEY_READ);
	expect_value(KEY_WRITE);
	expect_value(KEY_EXECUTE);
	expect_value(KEY_ALL_ACCESS);

	// RegQueryInfoKey
	test_proc_end();
}

static void verify_verrsrc(ofstream& out) {
	test_proc_begin();
	test_proc_comment("verrsrc.h");
	//expect_value_64(VS_FILE_INFO);
	expect_value(VS_VERSION_INFO);
	expect_value(VS_USER_DEFINED);
	expect_size(VS_FIXEDFILEINFO);
	// expect_value(VS_FF_DEBUG);
	// expect_value(VS_FF_PRERELEASE);
	// expect_value(VS_FF_PATCHED);
	expect_value(VS_FFI_SIGNATURE);
	// VFF_DEBUG
	// VFT_WINDOWS_DRV
	// VFT_WINDOWS_DLL
	test_proc_end();
}

static void verify_error_codes(ofstream& out) {
	test_proc_begin();
	test_proc_comment("winerror.h");

	expect_value(ERROR_SUCCESS);
	expect_value(NO_ERROR);
	expect_value(SEC_E_OK);
	out << endl;
	expect_value(ERROR_INVALID_FUNCTION);
	expect_value(ERROR_FILE_NOT_FOUND);
	expect_value(ERROR_PATH_NOT_FOUND);
	expect_value(ERROR_ACCESS_DENIED);
	expect_value(ERROR_INVALID_HANDLE);
	expect_value(ERROR_NOT_ENOUGH_MEMORY);
	expect_value(ERROR_INVALID_BLOCK);
	expect_value(ERROR_BAD_ENVIRONMENT);
	expect_value(ERROR_BAD_FORMAT);
	expect_value(ERROR_INVALID_ACCESS);
	expect_value(ERROR_INVALID_DATA);
	expect_value(ERROR_OUTOFMEMORY);
	expect_value(ERROR_INVALID_DRIVE);
	expect_value(ERROR_CURRENT_DIRECTORY);
	expect_value(ERROR_NO_MORE_FILES);
	expect_value(ERROR_SHARING_VIOLATION);
	expect_value(ERROR_LOCK_VIOLATION);
	expect_value(ERROR_HANDLE_EOF);
	expect_value(ERROR_NOT_SUPPORTED);
	expect_value(ERROR_FILE_EXISTS);
	expect_value(ERROR_INVALID_PARAMETER);
	expect_value(ERROR_BROKEN_PIPE);
	expect_value(ERROR_CALL_NOT_IMPLEMENTED);
	expect_value(ERROR_INSUFFICIENT_BUFFER);
	expect_value(ERROR_INVALID_NAME);
	expect_value(ERROR_BAD_ARGUMENTS);
	expect_value(ERROR_LOCK_FAILED);
	expect_value(ERROR_ALREADY_EXISTS);
	expect_value(ERROR_NO_DATA);
	expect_value(ERROR_ENVVAR_NOT_FOUND);
	expect_value(ERROR_OPERATION_ABORTED);
	expect_value(ERROR_IO_PENDING);
	expect_value(ERROR_NO_UNICODE_TRANSLATION);
	expect_value(ERROR_TIMEOUT);
	expect_value(ERROR_DATATYPE_MISMATCH);
	expect_value(ERROR_UNSUPPORTED_TYPE);
	expect_value(ERROR_NOT_SAME_OBJECT);
	expect_value(ERROR_PIPE_CONNECTED);
	expect_value(ERROR_PIPE_BUSY);
	out << endl;
	expect_value(S_OK);
	expect_value(E_NOTIMPL);
	expect_value(E_NOINTERFACE);
	expect_value(E_POINTER);
	expect_value(E_ABORT);
	expect_value(E_FAIL);
	expect_value(E_UNEXPECTED);
	expect_value(E_ACCESSDENIED);
	expect_value(E_HANDLE);
	expect_value(E_OUTOFMEMORY);
	expect_value(E_INVALIDARG);
	// out << endl;
	// expect_value(SEVERITY_SUCCESS);
	// expect_value(SEVERITY_ERROR);
	// out << endl;
	// expect_value(FACILITY_NULL);
	test_proc_end();
}

static void verify_error_helpers(ofstream& out) {
	test_proc_begin();
	test_proc_comment("winerror.h");

	expect_value(SUCCEEDED(-1));
	expect_value(SUCCEEDED(0));
	expect_value(SUCCEEDED(1));
	out << endl;
	expect_value(FAILED(-1));
	expect_value(FAILED(0));
	expect_value(FAILED(1));
	out << endl;
	expect_value(IS_ERROR(-1));
	expect_value(IS_ERROR(0));
	expect_value(IS_ERROR(1));
	out << endl;
	expect_value(HRESULT_CODE(0xFFFFCCCC));
	expect_value(HRESULT_FACILITY(0xFFFFCCCC));
	expect_value(HRESULT_SEVERITY(0x12345678));
	expect_value(HRESULT_SEVERITY(0x87654321));
	out << endl;
	expect_value(MAKE_HRESULT(1, 2, 3));

	test_proc_end();
}

static void test_core_sys_windows(ofstream& out) {
	out << "//+build windows" << endl
		<< "package " << __func__
		<< " // generated by " << path(__FILE__).filename().replace_extension("").string() << endl
		<< endl
		<< "import \"core:testing\"" << endl
		<< "import win32 \"core:sys/windows\"" << endl;
	verify_win32_type_sizes(out);
	verify_macros(out);
	verify_winnt(out);
	verify_winuser(out);
	verify_gdi32(out);
	verify_winmm(out);
	verify_advapi32(out);
	verify_winnls(out);
	verify_winreg(out);
	verify_verrsrc(out);
	verify_error_codes(out);
	verify_error_helpers(out);
}

int main(int argc, char* argv[]) {
	if (argc < 2) { cout << "Usage: " << path(argv[0]).filename().string() << " <odin-output-file>" << endl; return -1; }
	auto filepath = path(argv[1]);
	cout << "Writing " << filepath.string() << endl;
	ofstream out(filepath);
	test_core_sys_windows(out);
	out.close();
}
