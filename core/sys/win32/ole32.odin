// +build windows
package win32

foreign import "system:ole32.lib"

import "core:sys/win32"

succeeded :: proc (hr: win32.Hresult) -> bool {
	return hr >= 0;
}

//guiddef.h
Guid :: struct {
	data_one: u32,
	data_two: u16,
	data_three: u16,
	data_four_arr: [8]u8,
}

Iid :: distinct Guid;
Clsid :: distinct Guid;

I_Unknown :: struct {
	using vtbl: ^I_Unknown_Vtbl(I_Unknown),
}

I_Unknown_Vtbl :: struct(T: typeid) {
	query_interface: proc "std" (^T, ^Iid, rawptr) -> win32.Hresult,
	add_ref: proc "std" (^T) -> u32,
	release: proc "std" (^T) -> u32,
}

//objbase.h
Com_Init :: enum {
	Multi_Threaded = 0x0,
	Apartment_Threaded = 0x2,
	Disable_OLE1_DDE = 0x4,
	Speed_Over_Memory = 0x8,
};

Com_Class_Ctx :: enum {
	InProc_Server = 0x1,
	InProc_Handler = 0x2,
	Local_Server = 0x4,
	InProc_Server16 = 0x8,
	Remote_Server = 0x10,
	InProc_Handler16 = 0x20,
	_Reserved1 = 0x40,
	_Reserved2 = 0x80,
	_Reserved3 = 0x100,
	_Reserved4 = 0x200,
	No_Code_Download = 0x400,
	_Reserved5 = 0x800,
	No_Custom_Marshal = 0x1000,
	Enable_Code_Download = 0x2000,
	No_Failure_Log = 0x4000,
	Disable_AAA = 0x8000,
	Enable_AAA = 0x10000,
	From_Default_Context = 0x20000,
	Activate_x86_Server = 0x40000,
	Activate_32bit_Server = Activate_x86_Server,
	Activate_64bit_Server = 0x80000,
	Enable_Cloaking = 0x100000,
	App_Container = 0x400000,
	Activate_AAA_As_IU = 0x800000,
	_Reserved6 = 0x1000000,
	Activate_ARM32_Server = 0x2000000,
	Ps_Dll = 0x8000000,
}

S_OK :: 0;

//Local Unique Identifier
Luid :: struct {
	low: u32,
	high: i32, 
}

@(default_calling_convention = "std")
foreign ole32 {
	@(link_name = "ProgIDFromCLSID") com_get_prog_id_from_clsid :: proc(clsid_addr: ^Clsid, prog_id: ^win32.Wstring) -> win32.Hresult ---;
	@(link_name = "CLSIDFromProgID") com_get_clsid_from_prog_id :: proc(prog_id: ^u16, out_clsid: ^Clsid) -> win32.Hresult ---;
	@(link_name ="CoInitializeEx") com_init_ex :: proc(reserved: rawptr, co_init: Com_Init) ->win32.Hresult ---;
	@(link_name = "CoUninitialize") com_shutdown :: proc() ---;
	@(link_name = "CoCreateInstance") com_create :: proc(clsid_addr: ^Clsid, outer_unk: ^I_Unknown, ctx: Com_Class_Ctx, riid_addr: ^Iid, ppv: ^rawptr) -> win32.Hresult ---;
}
