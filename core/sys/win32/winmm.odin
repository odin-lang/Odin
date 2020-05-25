// +build windows
package win32

foreign import "system:winmm.lib"


@(default_calling_convention = "std")
foreign winmm {
	timeGetTime :: proc() -> u32 ---;
}

time_get_time :: timeGetTime;
