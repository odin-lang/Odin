// +build windows
package win32

foreign import "system:comdlg32.lib"

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

	@(link_name="CommDlgExtendedError") comm_dlg_extended_error :: proc() -> u32 ---
}

OFN_ALLOWMULTISELECT     :: 0x00000200;
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
