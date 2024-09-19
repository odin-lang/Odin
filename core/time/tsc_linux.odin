#+private
#+build linux
package time

import linux "core:sys/linux"

_get_tsc_frequency :: proc "contextless" () -> (u64, bool) {
	// Get the file descriptor for the perf mapping
	perf_attr := linux.Perf_Event_Attr{}
	perf_attr.size = size_of(perf_attr)
	perf_attr.type = .HARDWARE
	perf_attr.config.hw = .INSTRUCTIONS
	perf_attr.flags = {.Disabled, .Exclude_Kernel, .Exclude_HV}
	fd, perf_errno := linux.perf_event_open(&perf_attr, linux.Pid(0), -1, linux.Fd(-1), {})
	if perf_errno != nil {
		return 0, false
	}
	defer linux.close(fd)
	// Map it into the memory
	page_size : uint = 4096
	addr, mmap_errno := linux.mmap(0, page_size, {.READ}, {.SHARED}, fd)
	if mmap_errno != nil {
		return 0, false
	}
	defer linux.munmap(addr, page_size)
	// Get the frequency from the mapped page
	event_page := cast(^linux.Perf_Event_Mmap_Page) addr
	if .User_Time not_in event_page.cap.flags {
		return 0, false
	}
	frequency := u64((u128(1_000_000_000) << u128(event_page.time_shift)) / u128(event_page.time_mult))
	return frequency, true
}
