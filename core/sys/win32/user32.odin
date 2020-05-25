// +build windows
package win32

foreign import "system:user32.lib"


MENUBARINFO :: struct {
	size: u32,
	bar: RECT,
	menu: HMENU,
	wnd_menu: HWND,
	using fields: bit_field {
		bar_focused: 1,
		focuses:     1,
	},
}
Menu_Bar_Info :: MENUBARINFO;

MENUITEMINFOA :: struct {
	size:          u32,
	mask:          u32,
	type:          u32,
	state:         u32,
	id:            u32,
	submenu:       HMENU,
	bmp_checked:   HBITMAP,
	bmp_unchecked: HBITMAP,
	item_data:     u32,
	type_data:     cstring,
	cch:           u32,
}
Menu_Item_Info_A :: MENUITEMINFOA;
MENUITEMINFOW :: struct {
	size:          u32,
	mask:          u32,
	type:          u32,
	state:         u32,
	id:            u32,
	submenu:       HMENU,
	bmp_checked:   HBITMAP,
	bmp_unchecked: HBITMAP,
	item_data:     u32,
	type_data:     LPCWSTR,
	cch:           u32,
}
Menu_Item_Info_W :: MENUITEMINFOW;

MF_BYCOMMAND    :: 0x00000000;
MF_BYPOSITION   :: 0x00000400;
MF_BITMAP       :: 0x00000004;
MF_CHECKED      :: 0x00000008;
MF_DISABLED     :: 0x00000002;
MF_ENABLED      :: 0x00000000;
MF_GRAYED       :: 0x00000001;
MF_MENUBARBREAK :: 0x00000020;
MF_MENUBREAK    :: 0x00000040;
MF_OWNERDRAW    :: 0x00000100;
MF_POPUP        :: 0x00000010;
MF_SEPARATOR    :: 0x00000800;
MF_STRING       :: 0x00000000;
MF_UNCHECKED    :: 0x00000000;

MB_ABORTRETRYIGNORE     :: 0x00000002;
MB_CANCELTRYCONTINUE    :: 0x00000006;
MB_HELP                 :: 0x00004000;
MB_OK                   :: 0x00000000;
MB_OKCANCEL             :: 0x00000001;
MB_RETRYCANCEL          :: 0x00000005;
MB_YESNO                :: 0x00000004;
MB_YESNOCANCEL          :: 0x00000003;

MB_ICONEXCLAMATION      :: 0x00000030;
MB_ICONWARNING          :: 0x00000030;
MB_ICONINFORMATION      :: 0x00000040;
MB_ICONASTERISK         :: 0x00000040;
MB_ICONQUESTION         :: 0x00000020;
MB_ICONSTOP             :: 0x00000010;
MB_ICONERROR            :: 0x00000010;
MB_ICONHAND             :: 0x00000010;

MB_DEFBUTTON1           :: 0x00000000;
MB_DEFBUTTON2           :: 0x00000100;
MB_DEFBUTTON3           :: 0x00000200;
MB_DEFBUTTON4           :: 0x00000300;

MB_APPLMODAL            :: 0x00000000;
MB_SYSTEMMODAL          :: 0x00001000;
MB_TASKMODAL            :: 0x00002000;

MB_DEFAULT_DESKTOP_ONLY :: 0x00020000;
MB_RIGHT                :: 0x00080000;
MB_RTLREADING           :: 0x00100000;
MB_SETFOREGROUND        :: 0x00010000;
MB_TOPMOST              :: 0x00040000;
MB_SERVICE_NOTIFICATION :: 0x00200000;


@(default_calling_convention = "std")
foreign user32 {
	GetDesktopWindow :: proc() -> HWND ---;
	ShowCursor       :: proc(show: BOOL) ---;
	GetCursorPos     :: proc(p: ^POINT) -> BOOL ---;
	SetCursorPos     :: proc(x, y: i32) -> BOOL ---;
	ScreenToClient   :: proc(h: HWND, p: ^POINT) -> BOOL ---;
	ClientToScreen   :: proc(h: HWND, p: ^POINT) -> BOOL ---;
	PostQuitMessage  :: proc(exit_code: i32) ---;
	SetWindowTextA   :: proc(hwnd: HWND, c_string: cstring) -> BOOL ---;
	SetWindowTextW   :: proc(hwnd: HWND, c_string: LPCWSTR) -> BOOL ---;
	RegisterClassA   :: proc(wc: ^WNDCLASSA) -> i16 ---;
	RegisterClassW   :: proc(wc: ^WNDCLASSW) -> i16 ---;
	RegisterClassExA :: proc(wc: ^WNDCLASSEXA) -> i16 ---;
	RegisterClassExW :: proc(wc: ^WNDCLASSEXW) -> i16 ---;

	CreateWindowExA :: proc(ex_style: u32,
	                        class_name, title: cstring,
	                        style: u32,
	                        x, y, w, h: i32,
	                        parent: HWND, menu: HMENU, instance: HINSTANCE,
	                        param: rawptr) -> HWND ---;

	CreateWindowExW :: proc(ex_style: u32,
	                        class_name, title: LPCWSTR,
	                        style: u32,
	                        x, y, w, h: i32,
	                        parent: HWND, menu: HMENU, instance: HINSTANCE,
	                        param: rawptr) -> HWND ---;

	DestroyWindow :: proc(wnd: HWND) -> BOOL ---;

	ShowWindow       :: proc(hwnd: HWND, cmd_show: i32) -> BOOL ---;
	TranslateMessage :: proc(msg: ^MSG) -> BOOL ---;
	DispatchMessageA :: proc(msg: ^MSG) -> LRESULT ---;
	DispatchMessageW :: proc(msg: ^MSG) -> LRESULT ---;
	UpdateWindow     :: proc(hwnd: HWND) -> BOOL ---;

	GetMessageA  :: proc(msg: ^MSG, hwnd: HWND, msg_filter_min, msg_filter_max: u32) -> BOOL ---;
	GetMessageW  :: proc(msg: ^MSG, hwnd: HWND, msg_filter_min, msg_filter_max: u32) -> BOOL ---;
	PeekMessageA :: proc(msg: ^MSG, hwnd: HWND, msg_filter_min, msg_filter_max, remove_msg: u32) -> BOOL ---;
	PeekMessageW :: proc(msg: ^MSG, hwnd: HWND, msg_filter_min, msg_filter_max, remove_msg: u32) -> BOOL ---;

	PostMessageA :: proc(hwnd: HWND, msg: u32, wparam: WPARAM, lparam: LPARAM) -> BOOL ---;
	PostMessageW :: proc(hwnd: HWND, msg: u32, wparam: WPARAM, lparam: LPARAM) -> BOOL ---;
	SendMessageA :: proc(hwnd: HWND, msg: u32, wparam: WPARAM, lparam: LPARAM) -> BOOL ---;
	SendMessageW :: proc(hwnd: HWND, msg: u32, wparam: WPARAM, lparam: LPARAM) -> BOOL ---;

	DefWindowProcA :: proc(hwnd: HWND, msg: u32, wparam: WPARAM, lparam: LPARAM) -> LRESULT ---;
	DefWindowProcW :: proc(hwnd: HWND, msg: u32, wparam: WPARAM, lparam: LPARAM) -> LRESULT ---;

	AdjustWindowRect :: proc(rect: ^RECT, style: u32, menu: BOOL) -> BOOL ---;
	GetActiveWindow  :: proc() -> HWND ---;

	DescribePixelFormat :: proc(dc: HDC, pixel_format: i32, bytes: u32, pfd: ^PIXELFORMATDESCRIPTOR) -> i32 ---;

	GetMonitorInfoA   :: proc(monitor: HMONITOR, mi: ^MONITORINFO) -> BOOL ---;
	MonitorFromWindow :: proc(wnd: HWND, flags: u32) -> HMONITOR ---;

	SetWindowPos :: proc(wnd: HWND, wndInsertAfter: HWND, x, y, width, height: i32, flags: u32) ---;

	GetWindowPlacement :: proc(wnd: HWND, wndpl: ^WINDOWPLACEMENT) -> BOOL ---;
	SetWindowPlacement :: proc(wnd: HWND, wndpl: ^WINDOWPLACEMENT) -> BOOL ---;
	GetWindowRect      :: proc(wnd: HWND, rect: ^RECT) -> BOOL ---;

	GetWindowLongPtrA :: proc(wnd: HWND, index: i32) -> Long_Ptr ---;
	SetWindowLongPtrA :: proc(wnd: HWND, index: i32, new: Long_Ptr) -> Long_Ptr ---;
	GetWindowLongPtrW :: proc(wnd: HWND, index: i32) -> Long_Ptr ---;
	SetWindowLongPtrW :: proc(wnd: HWND, index: i32, new: Long_Ptr) -> Long_Ptr ---;

	GetWindowText :: proc(wnd: HWND, str: cstring, maxCount: i32) -> i32 ---;

	GetClientRect :: proc(hwnd: HWND, rect: ^RECT) -> BOOL ---;

	GetDC     :: proc(h: HWND) -> HDC ---;
	ReleaseDC :: proc(wnd: HWND, hdc: HDC) -> i32 ---;

	MapVirtualKeyA :: proc(scancode: u32, map_type: u32) -> u32 ---;
	MapVirtualKeyW :: proc(scancode: u32, map_type: u32) -> u32 ---;

	GetKeyState      :: proc(v_key: i32) -> i16 ---;
	GetAsyncKeyState :: proc(v_key: i32) -> i16 ---;

	SetForegroundWindow :: proc(h: HWND) -> BOOL ---;
	SetFocus            :: proc(h: HWND) -> HWND ---;


    LoadImageA  :: proc(instance: HINSTANCE, name: cstring, type_: u32, x_desired, y_desired : i32, load : u32) -> HANDLE ---;
    LoadIconA   :: proc(instance: HINSTANCE, icon_name: cstring) -> HICON ---;
    DestroyIcon :: proc(icon: HICON) -> BOOL ---;

    LoadCursorA :: proc(instance: HINSTANCE, cursor_name: cstring) -> HCURSOR ---;
    LoadCursorW :: proc(instance: HINSTANCE, cursor_name: LPCWSTR) -> HCURSOR ---;
	GetCursor   :: proc() -> HCURSOR ---;
	SetCursor   :: proc(cursor: HCURSOR) -> HCURSOR ---;

	RegisterRawInputDevices :: proc(raw_input_device: ^RAWINPUTDEVICE, num_devices, size: u32) -> BOOL ---;

	GetRawInputData :: proc(raw_input: HRAWINPUT, command: u32, data: rawptr, size: ^u32, size_header: u32) -> u32 ---;

	MapVirtualKeyExW :: proc(code, map_type: u32, hkl: HKL) ---;
	MapVirtualKeyExA :: proc(code, map_type: u32, hkl: HKL) ---;

	EnumDisplayMonitors :: proc(hdc: HDC, rect: ^RECT, enum_proc: MONITORENUMPROC, lparam: LPARAM) -> bool ---;
}

get_desktop_window         :: GetDesktopWindow;
show_cursor                :: ShowCursor;
get_cursor_pos             :: GetCursorPos;
set_cursor_pos             :: SetCursorPos;
screen_to_client           :: ScreenToClient;
client_to_screen           :: ClientToScreen;
post_quit_message          :: PostQuitMessage;
set_window_text_a          :: SetWindowTextA;
set_window_text_w          :: SetWindowTextW;
register_class_a           :: RegisterClassA;
register_class_w           :: RegisterClassW;
register_class_ex_a        :: RegisterClassExA;
register_class_ex_w        :: RegisterClassExW;
create_window_ex_a         :: CreateWindowExA;
create_window_ex_w         :: CreateWindowExW;
destroy_window             :: DestroyWindow;
show_window                :: ShowWindow;
translate_message          :: TranslateMessage;
dispatch_message_a         :: DispatchMessageA;
dispatch_message_w         :: DispatchMessageW;
update_window              :: UpdateWindow;
get_message_a              :: GetMessageA;
get_message_w              :: GetMessageW;
peek_message_a             :: PeekMessageA;
peek_message_w             :: PeekMessageW;
post_message_a             :: PostMessageA;
post_message_w             :: PostMessageW;
send_message_a             :: SendMessageA;
send_message_w             :: SendMessageW;
def_window_proc_a          :: DefWindowProcA;
def_window_proc_w          :: DefWindowProcW;
adjust_window_rect         :: AdjustWindowRect;
get_active_window          :: GetActiveWindow;
describe_pixel_format      :: DescribePixelFormat;
get_monitor_info_a         :: GetMonitorInfoA;
monitor_from_window        :: MonitorFromWindow;
set_window_pos             :: SetWindowPos;
get_window_placement       :: GetWindowPlacement;
set_window_placement       :: SetWindowPlacement;
get_window_rect            :: GetWindowRect;
get_window_long_ptr_a      :: GetWindowLongPtrA;
set_window_long_ptr_a      :: SetWindowLongPtrA;
get_window_long_ptr_w      :: GetWindowLongPtrW;
set_window_long_ptr_w      :: SetWindowLongPtrW;
get_window_text            :: GetWindowText;
get_client_rect            :: GetClientRect;
get_dc                     :: GetDC;
release_dc                 :: ReleaseDC;
map_virtual_key_a          :: MapVirtualKeyA;
map_virtual_key_w          :: MapVirtualKeyW;
get_key_state              :: GetKeyState;
get_async_key_state        :: GetAsyncKeyState;
set_foreground_window      :: SetForegroundWindow;
set_focus                  :: SetFocus;
load_image_a               :: LoadImageA;
load_icon_a                :: LoadIconA;
destroy_icon               :: DestroyIcon;
load_cursor_a              :: LoadCursorA;
load_cursor_w              :: LoadCursorW;
get_cursor                 :: GetCursor;
set_cursor                 :: SetCursor;
register_raw_input_devices :: RegisterRawInputDevices;
get_raw_input_data         :: GetRawInputData;
map_virtual_key_ex_w       :: MapVirtualKeyExW;
map_virtual_key_ex_a       :: MapVirtualKeyExA;
enum_display_monitors      :: EnumDisplayMonitors;

@(default_calling_convention = "c")
foreign user32 {
	CreateMenu      :: proc() -> HMENU ---
	CreatePopupMenu :: proc() -> HMENU ---
	DestroyMenu     :: proc(menu: HMENU) -> BOOL ---
	DeleteMenu      :: proc(menu: HMENU, position: u32, flags: u32) -> BOOL ---

	EnableMenuItem  :: proc(menu: HMENU, id_enable_itme: i32, enable: u32) -> BOOL ---
	EndMenu         :: proc() -> BOOL ---
	GetMenu         :: proc(wnd: HWND) -> HMENU ---
	GetMenuBarInfo  :: proc(wnd: HWND, id_object, id_item: u32, mbi: ^MENUBARINFO) -> HMENU ---
	GetMenuStringA  :: proc(menu: HMENU, id_item: u32, s: string,  cch_max: i32, flags: u32) -> i32 ---
	GetMenuStringW  :: proc(menu: HMENU, id_item: u32, s: LPCWSTR, cch_max: i32, flags: u32) -> i32 ---
	GetMenuState    :: proc(menu: HMENU, id: u32, flags: u32) -> u32 ---
	GetMenuItemRect :: proc(wnd: HWND, menu: HMENU, id_item: u32, item: ^RECT) -> BOOL ---

	SetMenu :: proc(wnd: HWND, menu: HMENU) -> HMENU ---

	DrawMenuBar :: proc(wnd: HWND) -> BOOL ---
	InsertMenuA :: proc(menu: HMENU, position: u32, flags: u32, id_new_item: Uint_Ptr, new_item: cstring) -> BOOL ---
	InsertMenuW :: proc(menu: HMENU, position: u32, flags: u32, id_new_item: Uint_Ptr, new_item: LPCWSTR) -> BOOL ---

	InsertMenuItemA :: proc(menu: HMENU, item: u32, by_position: bool, mi: ^MENUITEMINFOA) -> BOOL ---
	InsertMenuItemW :: proc(menu: HMENU, item: u32, by_position: bool, mi: ^MENUITEMINFOW) -> BOOL ---

	AppendMenuA :: proc(menu: HMENU, flags: u32, id_new_item: Uint_Ptr, new_item: cstring) -> BOOL ---
	AppendMenuW :: proc(menu: HMENU, flags: u32, id_new_item: Uint_Ptr, new_item: LPCWSTR) -> BOOL ---

	CheckMenuItem      :: proc(menu: HMENU, id_check_item: u32, check: u32) -> u32 ---
	CheckMenuRadioItem :: proc(menu: HMENU, first, last: u32, check: u32, flags: u32) -> BOOL ---

	GetPropA :: proc(wnd: HWND, s: cstring) -> HANDLE ---
	GetPropW :: proc(wnd: HWND, s: LPCWSTR) -> HANDLE ---

	MessageBoxA :: proc(wnd: HWND, text, caption: cstring, type: u32) -> i32 ---
	MessageBoxW :: proc(wnd: HWND, text, caption: LPCWSTR, type: u32) -> i32 ---

	MessageBoxExA :: proc(wnd: HWND, text, caption: cstring, type: u32, language_id: u16) -> i32 ---
	MessageBoxExW :: proc(wnd: HWND, text, caption: LPCWSTR, type: u32, language_id: u16) -> i32 ---

	BeginPaint :: proc(wnd: HWND, paint: ^PAINTSTRUCT) -> HDC ---
	EndPaint   :: proc(wnd: HWND, paint: ^PAINTSTRUCT) -> BOOL ---
}

create_menu           :: CreateMenu;
create_popup_menu     :: CreatePopupMenu;
destroy_menu          :: DestroyMenu;
delete_menu           :: DeleteMenu;
enable_menu_item      :: EnableMenuItem;
end_menu              :: EndMenu;
get_menu              :: GetMenu;
get_menu_bar_info     :: GetMenuBarInfo;
get_menu_string_a     :: GetMenuStringA;
get_menu_string_w     :: GetMenuStringW;
get_menu_state        :: GetMenuState;
get_menu_item_rect    :: GetMenuItemRect;
set_menu              :: SetMenu;
draw_menu_bar         :: DrawMenuBar;
insert_menu_a         :: InsertMenuA;
insert_menu_w         :: InsertMenuW;
insert_menu_item_a    :: InsertMenuItemA;
insert_menu_item_w    :: InsertMenuItemW;
append_menu_a         :: AppendMenuA;
append_menu_w         :: AppendMenuW;
check_menu_item       :: CheckMenuItem;
check_menu_radio_item :: CheckMenuRadioItem;
get_prop_a            :: GetPropA;
get_prop_w            :: GetPropW;
message_box_a         :: MessageBoxA;
message_box_w         :: MessageBoxW;
message_box_ex_a      :: MessageBoxExA;
message_box_ex_w      :: MessageBoxExW;
begin_paint           :: BeginPaint;
end_paint             :: EndPaint;


_IDC_APPSTARTING := rawptr(uintptr(32650));
_IDC_ARROW       := rawptr(uintptr(32512));
_IDC_CROSS       := rawptr(uintptr(32515));
_IDC_HAND        := rawptr(uintptr(32649));
_IDC_HELP        := rawptr(uintptr(32651));
_IDC_IBEAM       := rawptr(uintptr(32513));
_IDC_ICON        := rawptr(uintptr(32641));
_IDC_NO          := rawptr(uintptr(32648));
_IDC_SIZE        := rawptr(uintptr(32640));
_IDC_SIZEALL     := rawptr(uintptr(32646));
_IDC_SIZENESW    := rawptr(uintptr(32643));
_IDC_SIZENS      := rawptr(uintptr(32645));
_IDC_SIZENWSE    := rawptr(uintptr(32642));
_IDC_SIZEWE      := rawptr(uintptr(32644));
_IDC_UPARROW     := rawptr(uintptr(32516));
_IDC_WAIT        := rawptr(uintptr(32514));
IDC_APPSTARTING := cstring(_IDC_APPSTARTING);
IDC_ARROW       := cstring(_IDC_ARROW);
IDC_CROSS       := cstring(_IDC_CROSS);
IDC_HAND        := cstring(_IDC_HAND);
IDC_HELP        := cstring(_IDC_HELP);
IDC_IBEAM       := cstring(_IDC_IBEAM);
IDC_ICON        := cstring(_IDC_ICON);
IDC_NO          := cstring(_IDC_NO);
IDC_SIZE        := cstring(_IDC_SIZE);
IDC_SIZEALL     := cstring(_IDC_SIZEALL);
IDC_SIZENESW    := cstring(_IDC_SIZENESW);
IDC_SIZENS      := cstring(_IDC_SIZENS);
IDC_SIZENWSE    := cstring(_IDC_SIZENWSE);
IDC_SIZEWE      := cstring(_IDC_SIZEWE);
IDC_UPARROW     := cstring(_IDC_UPARROW);
IDC_WAIT        := cstring(_IDC_WAIT);
