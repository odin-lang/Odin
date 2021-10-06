// +build windows
package win32

foreign import "system:winmm.lib"


@(default_calling_convention = "std")
foreign winmm {
    @(link_name="timeBeginPeriod") time_begin_period :: proc(period: u32) -> u32 ---

	@(link_name="timeGetTime") time_get_time :: proc() -> u32 ---
}
