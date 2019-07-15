// +build windows
package win32

foreign import "system:comdlg32.lib"
import "core:strings"

OFN_Hook_Proc :: #type proc "stdcall" (hdlg: Hwnd, msg: u32, wparam: Wparam, lparam: Lparam) -> Uint_Ptr;

Open_File_Name_A :: struct {
	struct_size:     u32,
	hwnd_owner:      Hwnd,
	instance:        Hinstance,
	filter:          cstring,
	custom_filter:   cstring,
	max_cust_filter: u32,
	filter_index:    u32,
	file:            cstring,
	max_file:        u32,
	file_title:      cstring,
	max_file_title:  u32,
	initial_dir:     cstring,
	title:           cstring,
	flags:           u32,
	file_offset:     u16,
	file_extension:  u16,
	def_ext:         cstring,
	cust_data:       Lparam,
	hook:            OFN_Hook_Proc,
	template_name:   cstring,
	pv_reserved:     rawptr,
	dw_reserved:     u32,
	flags_ex:        u32,
}

Open_File_Name_W :: struct {
	struct_size:     u32,
	hwnd_owner:      Hwnd,
	instance:        Hinstance,
	filter:          Wstring,
	custom_filter:   Wstring,
	max_cust_filter: u32,
	filter_index:    u32,
	file:            Wstring,
	max_file:        u32,
	file_title:      Wstring,
	max_file_title:  u32,
	initial_dir:     Wstring,
	title:           Wstring,
	flags:           u32,
	file_offset:     u16,
	file_extension:  u16,
	def_ext:         Wstring,
	cust_data:       Lparam,
	hook:            OFN_Hook_Proc,
	template_name:   Wstring,
	pv_reserved:     rawptr,
	dw_reserved:     u32,
	flags_ex:        u32,
}

@(default_calling_convention = "c")
foreign comdlg32 {
	@(link_name="GetOpenFileNameA") get_open_file_name_a :: proc(arg1: ^Open_File_Name_A) -> Bool ---
	@(link_name="GetOpenFileNameW") get_open_file_name_w :: proc(arg1: ^Open_File_Name_W) -> Bool ---
	@(link_name="GetSaveFileNameA") get_save_file_name_a :: proc(arg1: ^Open_File_Name_A) -> Bool ---
	@(link_name="GetSaveFileNameW") get_save_file_name_w :: proc(arg1: ^Open_File_Name_W) -> Bool ---
	@(link_name="CommDlgExtendedError") comm_dlg_extended_error :: proc() -> u32 ---
}

OPEN_TITLE :: "Select file to open";
OPEN_FLAGS :: u32(OFN_PATHMUSTEXIST | OFN_FILEMUSTEXIST);
OPEN_FLAGS_MULTI :: u32(OPEN_FLAGS | OFN_ALLOWMULTISELECT | OFN_EXPLORER);

SAVE_TITLE :: "Select file to save";
SAVE_FLAGS :: u32(OFN_OVERWRITEPROMPT | OFN_EXPLORER);
SAVE_EXT   :: "txt";

Open_Save_Mode :: enum {
	Open = 0,
	Save = 1,
}

_open_file_dialog :: proc(title: string, dir: string,
                          filters: []string, default_filter: u32,
                          flags: u32, default_ext: string,
                          mode: Open_Save_Mode, allocator := context.temp_allocator) -> (path: string, ok: bool = true) {
	file_buf := make([]u16, MAX_PATH_WIDE, allocator);

	// Filters need to be passed as a pair of strings (title, filter)
	filter_len := u32(len(filters));
	if filter_len % 2 != 0 do return "", false;

	filter: string;
	filter = strings.join(filters, "\u0000", context.temp_allocator);
	filter = strings.concatenate({filter, "\u0000"}, context.temp_allocator);

	ofn := Open_File_Name_W{
		struct_size  = size_of(Open_File_Name_W),
		file         = Wstring(&file_buf[0]),
		max_file     = MAX_PATH_WIDE,
		title        = utf8_to_wstring(title, context.temp_allocator),
		filter       = utf8_to_wstring(filter, context.temp_allocator),
		initial_dir  = utf8_to_wstring(dir, context.temp_allocator),
		filter_index = u32(clamp(default_filter, 1, filter_len / 2)),
		def_ext      = utf8_to_wstring(default_ext, context.temp_allocator),
		flags        = u32(flags),
	};

	switch mode {
	case .Open:
		ok = bool(get_open_file_name_w(&ofn));
	case .Save:
		ok = bool(get_save_file_name_w(&ofn));
	case:
		ok = false;
	}

	if !ok {
		delete(file_buf);
		return "", false;
	}

	file_name := utf16_to_utf8(file_buf[:], allocator);
	path = strings.trim_right_null(file_name);
	return;
}

select_file_to_open :: proc(title := OPEN_TITLE, dir := ".",
                            filters := []string{"All Files", "*.*"}, default_filter := u32(1),
                            flags := OPEN_FLAGS, allocator := context.temp_allocator) -> (path: string, ok: bool) {

	path, ok = _open_file_dialog(title, dir, filters, default_filter, flags, "", Open_Save_Mode.Open, allocator);
	return;
}

select_file_to_save :: proc(title := SAVE_TITLE, dir := ".",
							filters := []string{"All Files", "*.*"}, default_filter := u32(1),
							flags := SAVE_FLAGS, default_ext := SAVE_EXT,
							allocator := context.temp_allocator) -> (path: string, ok: bool) {

	path, ok = _open_file_dialog(title, dir, filters, default_filter, flags, default_ext, Open_Save_Mode.Save, allocator);
	return;
}

// TODO: Implement convenience function for select_file_to_open with ALLOW_MULTI_SELECT that takes
//       it output of the form "path\u0000\file1u\0000file2" and turns it into []string with the path + file pre-concatenated for you.

OFN_ALLOWMULTISELECT     :: 0x00000200; // NOTE(Jeroen): Without OFN_EXPLORER it uses the Win3 dialog.
OFN_CREATEPROMPT         :: 0x00002000;
OFN_DONTADDTORECENT      :: 0x02000000;
OFN_ENABLEHOOK           :: 0x00000020;
OFN_ENABLEINCLUDENOTIFY  :: 0x00400000;
OFN_ENABLESIZING         :: 0x00800000;
OFN_ENABLETEMPLATE       :: 0x00000040;
OFN_ENABLETEMPLATEHANDLE :: 0x00000080;
OFN_EXPLORER             :: 0x00080000;
OFN_EXTENSIONDIFFERENT   :: 0x00000400;
OFN_FILEMUSTEXIST        :: 0x00001000;
OFN_FORCESHOWHIDDEN      :: 0x10000000;
OFN_HIDEREADONLY         :: 0x00000004;
OFN_LONGNAMES            :: 0x00200000;
OFN_NOCHANGEDIR          :: 0x00000008;
OFN_NODEREFERENCELINKS   :: 0x00100000;
OFN_NOLONGNAMES          :: 0x00040000;
OFN_NONETWORKBUTTON      :: 0x00020000;
OFN_NOREADONLYRETURN     :: 0x00008000;
OFN_NOTESTFILECREATE     :: 0x00010000;
OFN_NOVALIDATE           :: 0x00000100;
OFN_OVERWRITEPROMPT      :: 0x00000002;
OFN_PATHMUSTEXIST        :: 0x00000800;
OFN_READONLY             :: 0x00000001;
OFN_SHAREAWARE           :: 0x00004000;
OFN_SHOWHELP             :: 0x00000010;

CDERR_DIALOGFAILURE      :: 0x0000FFFF;
CDERR_GENERALCODES       :: 0x00000000;
CDERR_STRUCTSIZE         :: 0x00000001;
CDERR_INITIALIZATION     :: 0x00000002;
CDERR_NOTEMPLATE         :: 0x00000003;
CDERR_NOHINSTANCE        :: 0x00000004;
CDERR_LOADSTRFAILURE     :: 0x00000005;
CDERR_FINDRESFAILURE     :: 0x00000006;
CDERR_LOADRESFAILURE     :: 0x00000007;
CDERR_LOCKRESFAILURE     :: 0x00000008;
CDERR_MEMALLOCFAILURE    :: 0x00000009;
CDERR_MEMLOCKFAILURE     :: 0x0000000A;
CDERR_NOHOOK             :: 0x0000000B;
CDERR_REGISTERMSGFAIL    :: 0x0000000C;
