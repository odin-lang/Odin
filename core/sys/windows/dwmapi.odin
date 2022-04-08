// +build windows
package sys_windows

foreign import dwmapi "system:Dwmapi.lib"

@(default_calling_convention="stdcall")
foreign dwmapi {
	DwmFlush :: proc() -> HRESULT ---
}
