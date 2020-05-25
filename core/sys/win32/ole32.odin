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
    CoInitializeEx :: proc(reserved: rawptr, co_init: Com_Init) -> HRESULT ---;
    CoUninitialize :: proc() ---;
}

co_initialize_ex :: CoInitializeEx;
co_uninitialize  :: CoUninitialize;