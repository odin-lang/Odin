//+private
//+build linux
package time

import "core:intrinsics"
import "core:sys/unix"

when ODIN_ARCH == .amd64 {
	_x86_get_tsc_frequency :: proc "contextless" () -> (u64, bool) {
		perf_attr := unix.Perf_Event_Attr{}
		perf_attr.type = u32(unix.Perf_Type_Id.Hardware)
		perf_attr.config = u64(unix.Perf_Hardware_Id.Instructions)
		perf_attr.size = size_of(perf_attr)
		perf_attr.flags = {.Disabled, .Exclude_Kernel, .Exclude_HV}
		fd := unix.sys_perf_event_open(&perf_attr, 0, -1, -1, 0)
		if fd == -1 {
			return 0, false
		}
		defer unix.sys_close(fd)

		page_size : uint = 4096
		ret := unix.sys_mmap(nil, page_size, unix.PROT_READ, unix.MAP_SHARED, fd, 0)
		if ret < 0 && ret > -4096 {
			return 0, false
		}
		addr := rawptr(uintptr(ret))
		defer unix.sys_munmap(addr, page_size)

		event_page := (^unix.Perf_Event_mmap_Page)(addr)
		if .User_Time not_in event_page.cap.flags {
			return 0, false
		}

		frequency := u64((u128(1_000_000_000) << u128(event_page.time_shift)) / u128(event_page.time_mult))
		return frequency, true
	}
}
