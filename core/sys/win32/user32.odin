// +build windows
package win32

foreign import "system:user32.lib"


Menu_Bar_Info :: struct {
	size: u32,
	bar: Rect,
	menu: Hmenu,
	wnd_menu: Hwnd,
	using fields: bit_field {
		bar_focused: 1,
		focuses:     1,
	},
}

Menu_Item_Info_A :: struct {
	size:          u32,
	mask:          u32,
	type:          u32,
	state:         u32,
	id:            u32,
	submenu:       Hmenu,
	bmp_checked:   Hbitmap,
	bmp_unchecked: Hbitmap,
	item_data:     u32,
	type_data:     cstring,
	cch:           u32,
}
Menu_Item_Info_W :: struct {
	size:          u32,
	mask:          u32,
	type:          u32,
	state:         u32,
	id:            u32,
	submenu:       Hmenu,
	bmp_checked:   Hbitmap,
	bmp_unchecked: Hbitmap,
	item_data:     u32,
	type_data:     Wstring,
	cch:           u32,
}

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
	@(link_name="GetDesktopWindow") get_desktop_window  :: proc() -> Hwnd ---;
	@(link_name="ShowCursor")       show_cursor         :: proc(show: Bool) ---;
	@(link_name="GetCursorPos")     get_cursor_pos      :: proc(p: ^Point) -> Bool ---;
	@(link_name="SetCursorPos")     set_cursor_pos      :: proc(x, y: i32) -> Bool ---;
	@(link_name="ScreenToClient")   screen_to_client    :: proc(h: Hwnd, p: ^Point) -> Bool ---;
	@(link_name="ClientToScreen")   client_to_screen    :: proc(h: Hwnd, p: ^Point) -> Bool ---;
	@(link_name="PostQuitMessage")  post_quit_message   :: proc(exit_code: i32) ---;
	@(link_name="SetWindowTextA")   set_window_text_a   :: proc(hwnd: Hwnd, c_string: cstring) -> Bool ---;
	@(link_name="SetWindowTextW")   set_window_text_w   :: proc(hwnd: Hwnd, c_string: Wstring) -> Bool ---;
	@(link_name="RegisterClassExA") register_class_ex_a :: proc(wc: ^Wnd_Class_Ex_A) -> i16 ---;
	@(link_name="RegisterClassExW") register_class_ex_w :: proc(wc: ^Wnd_Class_Ex_W) -> i16 ---;

	@(link_name="CreateWindowExA")
	create_window_ex_a :: proc(ex_style: u32,
	                           class_name, title: cstring,
	                           style: u32,
	                           x, y, w, h: i32,
	                           parent: Hwnd, menu: Hmenu, instance: Hinstance,
	                           param: rawptr) -> Hwnd ---;

	@(link_name="CreateWindowExW")
	create_window_ex_w :: proc(ex_style: u32,
	                           class_name, title: Wstring,
	                           style: u32,
	                           x, y, w, h: i32,
	                           parent: Hwnd, menu: Hmenu, instance: Hinstance,
	                           param: rawptr) -> Hwnd ---;

	@(link_name="ShowWindow")       show_window        :: proc(hwnd: Hwnd, cmd_show: i32) -> Bool ---;
	@(link_name="TranslateMessage") translate_message  :: proc(msg: ^Msg) -> Bool ---;
	@(link_name="DispatchMessageA") dispatch_message_a :: proc(msg: ^Msg) -> Lresult ---;
	@(link_name="DispatchMessageW") dispatch_message_w :: proc(msg: ^Msg) -> Lresult ---;
	@(link_name="UpdateWindow")     update_window      :: proc(hwnd: Hwnd) -> Bool ---;
	@(link_name="GetMessageA")      get_message_a      :: proc(msg: ^Msg, hwnd: Hwnd, msg_filter_min, msg_filter_max: u32) -> Bool ---;
	@(link_name="GetMessageW")      get_message_w      :: proc(msg: ^Msg, hwnd: Hwnd, msg_filter_min, msg_filter_max: u32) -> Bool ---;

	@(link_name="PeekMessageA") peek_message_a :: proc(msg: ^Msg, hwnd: Hwnd, msg_filter_min, msg_filter_max, remove_msg: u32) -> Bool ---;
	@(link_name="PeekMessageW") peek_message_w :: proc(msg: ^Msg, hwnd: Hwnd, msg_filter_min, msg_filter_max, remove_msg: u32) -> Bool ---;


	@(link_name="PostMessageA") post_message_a :: proc(hwnd: Hwnd, msg, wparam, lparam: u32) -> Bool ---;
	@(link_name="PostMessageW") post_message_w :: proc(hwnd: Hwnd, msg, wparam, lparam: u32) -> Bool ---;

	@(link_name="DefWindowProcA") def_window_proc_a :: proc(hwnd: Hwnd, msg: u32, wparam: Wparam, lparam: Lparam) -> Lresult ---;
	@(link_name="DefWindowProcW") def_window_proc_w :: proc(hwnd: Hwnd, msg: u32, wparam: Wparam, lparam: Lparam) -> Lresult ---;

	@(link_name="AdjustWindowRect") adjust_window_rect :: proc(rect: ^Rect, style: u32, menu: Bool) -> Bool ---;
	@(link_name="GetActiveWindow")  get_active_window  :: proc() -> Hwnd ---;

	@(link_name="DestroyWindow")       destroy_window        :: proc(wnd: Hwnd) -> Bool ---;
	@(link_name="DescribePixelFormat") describe_pixel_format :: proc(dc: Hdc, pixel_format: i32, bytes: u32, pfd: ^Pixel_Format_Descriptor) -> i32 ---;

	@(link_name="GetMonitorInfoA")  get_monitor_info_a  :: proc(monitor: Hmonitor, mi: ^Monitor_Info) -> Bool ---;
	@(link_name="MonitorFromWindow") monitor_from_window :: proc(wnd: Hwnd, flags: u32) -> Hmonitor ---;

	@(link_name="SetWindowPos") set_window_pos :: proc(wnd: Hwnd, wndInsertAfter: Hwnd, x, y, width, height: i32, flags: u32) ---;

	@(link_name="GetWindowPlacement") get_window_placement  :: proc(wnd: Hwnd, wndpl: ^Window_Placement) -> Bool ---;
	@(link_name="SetWindowPlacement") set_window_placement  :: proc(wnd: Hwnd, wndpl: ^Window_Placement) -> Bool ---;
	@(link_name="GetWindowRect")      get_window_rect       :: proc(wnd: Hwnd, rect: ^Rect) -> Bool ---;

	@(link_name="GetWindowLongPtrA") get_window_long_ptr_a :: proc(wnd: Hwnd, index: i32) -> Long_Ptr ---;
	@(link_name="SetWindowLongPtrA") set_window_long_ptr_a :: proc(wnd: Hwnd, index: i32, new: Long_Ptr) -> Long_Ptr ---;
	@(link_name="GetWindowLongPtrW") get_window_long_ptr_w :: proc(wnd: Hwnd, index: i32) -> Long_Ptr ---;
	@(link_name="SetWindowLongPtrW") set_window_long_ptr_w :: proc(wnd: Hwnd, index: i32, new: Long_Ptr) -> Long_Ptr ---;

	@(link_name="GetWindowText") get_window_text :: proc(wnd: Hwnd, str: cstring, maxCount: i32) -> i32 ---;

	@(link_name="GetClientRect") get_client_rect :: proc(hwnd: Hwnd, rect: ^Rect) -> Bool ---;

	@(link_name="GetDC")     get_dc     :: proc(h: Hwnd) -> Hdc ---;
	@(link_name="ReleaseDC") release_dc :: proc(wnd: Hwnd, hdc: Hdc) -> i32 ---;

	@(link_name="MapVirtualKeyA") map_virtual_key_a :: proc(scancode: u32, map_type: u32) -> u32 ---;
	@(link_name="MapVirtualKeyW") map_virtual_key_w :: proc(scancode: u32, map_type: u32) -> u32 ---;

	@(link_name="GetKeyState")      get_key_state       :: proc(v_key: i32) -> i16 ---;
	@(link_name="GetAsyncKeyState") get_async_key_state :: proc(v_key: i32) -> i16 ---;

	@(link_name="SetForegroundWindow") set_foreground_window :: proc(h: Hwnd) -> Bool ---;
	@(link_name="SetFocus")            set_focus             :: proc(h: Hwnd) -> Hwnd ---;


    @(link_name="LoadImageA")       load_image_a        :: proc(instance: Hinstance, name: cstring, type_: u32, x_desired, y_desired : i32, load : u32) -> Handle ---;
    @(link_name="LoadIconA")        load_icon_a         :: proc(instance: Hinstance, icon_name: cstring) -> Hicon ---;
    @(link_name="DestroyIcon")      destroy_icon        :: proc(icon: Hicon) -> Bool ---;

    @(link_name="LoadCursorA")      load_cursor_a       :: proc(instance: Hinstance, cursor_name: cstring) -> Hcursor ---;
    @(link_name="LoadCursorW")      load_cursor_w       :: proc(instance: Hinstance, cursor_name: Wstring) -> Hcursor ---;
	@(link_name="GetCursor")        get_cursor          :: proc() -> Hcursor ---;
	@(link_name="SetCursor")        set_cursor          :: proc(cursor: Hcursor) -> Hcursor ---;

	@(link_name="RegisterRawInputDevices") register_raw_input_devices :: proc(raw_input_device: ^Raw_Input_Device, num_devices, size: u32) -> Bool ---;

	@(link_name="GetRawInputData") get_raw_input_data :: proc(raw_input: Hrawinput, command: u32, data: rawptr, size: ^u32, size_header: u32) -> u32 ---;

	@(link_name="MapVirtualKeyExW") map_virtual_key_ex_w :: proc(code, map_type: u32, hkl: HKL) ---;
	@(link_name="MapVirtualKeyExA") map_virtual_key_ex_a :: proc(code, map_type: u32, hkl: HKL) ---;

	@(link_name="EnumDisplayMonitors") enum_display_monitors :: proc(hdc: Hdc,  rect: ^Rect, enum_proc: Monitor_Enum_Proc, lparam: Lparam) -> bool ---;
}

@(default_calling_convention = "c")
foreign user32 {
	@(link_name="CreateMenu")      create_menu   :: proc() -> Hmenu ---
	@(link_name="CreatePopupMenu") create_popup_menu :: proc() -> Hmenu ---
	@(link_name="DestroyMenu")     destroy_menu :: proc(menu: Hmenu) -> Bool ---
	@(link_name="DeleteMenu")      delete_menu :: proc(menu: Hmenu, position: u32, flags: u32) -> Bool ---

	@(link_name="EnableMenuItem")  enable_menu_item :: proc(menu: Hmenu, id_enable_itme: i32, enable: u32) -> Bool ---
	@(link_name="EndMenu")         end_menu :: proc() -> Bool ---
	@(link_name="GetMenu")         get_menu :: proc(wnd: Hwnd) -> Hmenu ---
	@(link_name="GetMenuBarInfo")  get_menu_bar_info :: proc(wnd: Hwnd, id_object, id_item: u32, mbi: ^Menu_Bar_Info) -> Hmenu ---
	@(link_name="GetMenuStringA")  get_menu_string_a :: proc(menu: Hmenu, id_item: u32, s: string,  cch_max: i32, flags: u32) -> i32 ---
	@(link_name="GetMenuStringW")  get_menu_string_w :: proc(menu: Hmenu, id_item: u32, s: Wstring, cch_max: i32, flags: u32) -> i32 ---
	@(link_name="GetMenuState")    get_menu_state :: proc(menu: Hmenu, id: u32, flags: u32) -> u32 ---
	@(link_name="GetMenuItemRect") get_menu_item_rect :: proc(wnd: Hwnd, menu: Hmenu, id_item: u32, item: ^Rect) -> Bool ---

	@(link_name="SetMenu")         set_menu :: proc(wnd: Hwnd, menu: Hmenu) -> Hmenu ---

	@(link_name="DrawMenuBar")     draw_menu_bar :: proc(wnd: Hwnd) -> Bool ---
	@(link_name="InsertMenuA")     insert_menu_a :: proc(menu: Hmenu, position: u32, flags: u32, id_new_item: Uint_Ptr, new_item: cstring) -> Bool ---
	@(link_name="InsertMenuW")     insert_menu_w :: proc(menu: Hmenu, position: u32, flags: u32, id_new_item: Uint_Ptr, new_item: Wstring) -> Bool ---

	@(link_name="InsertMenuItemA") insert_menu_item_a :: proc(menu: Hmenu, item: u32, by_position: bool, mi: ^Menu_Item_Info_A) -> Bool ---
	@(link_name="InsertMenuItemW") insert_menu_item_w :: proc(menu: Hmenu, item: u32, by_position: bool, mi: ^Menu_Item_Info_W) -> Bool ---

	@(link_name="AppendMenuA") append_menu_a :: proc(menu: Hmenu, flags: u32, id_new_item: Uint_Ptr, new_item: cstring) -> Bool ---
	@(link_name="AppendMenuW") append_menu_w :: proc(menu: Hmenu, flags: u32, id_new_item: Uint_Ptr, new_item: Wstring) -> Bool ---

	@(link_name="CheckMenuItem") check_menu_item :: proc(menu: Hmenu, id_check_item: u32, check: u32) -> u32 ---
	@(link_name="CheckMenuRadioItem") check_menu_radio_item :: proc(menu: Hmenu, first, last: u32, check: u32, flags: u32) -> Bool ---

	@(link_name="GetPropA") get_prop_a :: proc(wnd: Hwnd, s: cstring) -> Handle ---
	@(link_name="GetPropW") get_prop_w :: proc(wnd: Hwnd, s: Wstring) -> Handle ---


	@(link_name="MessageBoxExA") message_box_ex_a :: proc(wnd: Hwnd, text, caption: cstring, type: u32, language_id: u16) -> i32 ---
	@(link_name="MessageBoxExW") message_box_ex_w :: proc(wnd: Hwnd, text, caption: Wstring, type: u32, language_id: u16) -> i32 ---
}


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
