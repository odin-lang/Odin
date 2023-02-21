//+private
//+build windows
package time

import "core:intrinsics"
import win32 "core:sys/windows"

_x86_get_tsc_frequency :: proc "contextless" () -> (u64, bool) {
	qpc_begin: win32.LARGE_INTEGER
	win32.QueryPerformanceCounter(&qpc_begin)
	tsc_begin := intrinsics.read_cycle_counter()

	win32.Sleep(2)

	qpc_end: win32.LARGE_INTEGER
	win32.QueryPerformanceCounter(&qpc_end)
	tsc_end := intrinsics.read_cycle_counter()

	qpc_frequency: win32.LARGE_INTEGER
	win32.QueryPerformanceFrequency(&qpc_frequency)

	frequency = u64((u128(tsc_end - tsc_begin) * u128(qpc_frequency)) / u128(qpc_end - qpc_begin))
	return frequency, true
}
