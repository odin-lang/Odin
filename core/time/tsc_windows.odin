//+private
//+build windows
package time

import "core:intrinsics"
import win32 "core:sys/windows"

_get_tsc_frequency :: proc "contextless" () -> u64 {
	@(static) frequency : u64 = 0
	if frequency > 0 {
		return frequency
	}

	qpc_begin: win32.LARGE_INTEGER
	win32.QueryPerformanceCounter(&qpc_begin)
	tsc_begin := intrinsics.read_cycle_counter()

	win32.Sleep(2)

	qpc_end: win32.LARGE_INTEGER
	win32.QueryPerformanceCounter(&qpc_end)
	tsc_end := intrinsics.read_cycle_counter()

	qpc_frequency: win32.LARGE_INTEGER
	win32.QueryPerformanceFrequency(&qpc_frequency)

	frequency = ((tsc_end - tsc_begin) * qpc_frequency) / (qpc_end - qpc_begin)
	return frequency
}
