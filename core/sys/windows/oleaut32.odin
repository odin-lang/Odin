#+build windows
package sys_windows

foreign import oleaut32 "system:OleAut32.lib"

@(default_calling_convention="system")
foreign oleaut32 {
	SysFreeString :: proc(bstrString: BSTR) ---
}
