// +build windows
package win32

foreign import "system:ole32.lib"

//objbase.h
Com_Init :: enum {
	Multi_Threaded = 0x0,
	Apartment_Threaded = 0x2,
	Disable_OLE1_DDE = 0x4,
	Speed_Over_Memory = 0x8,
};

@(default_calling_convention = "std")
foreign ole32 {
	@(link_name ="CoInitializeEx") com_init_ex :: proc(reserved: rawptr, co_init: Com_Init) ->Hresult ---;
	@(link_name = "CoUninitialize") com_shutdown :: proc() ---;
}
