#+private
#+build freebsd
package time

import "core:c"

foreign import libc "system:c"
foreign libc {
	@(link_name="sysctlbyname") _sysctlbyname :: proc(path: cstring, oldp: rawptr, oldlenp: rawptr, newp: rawptr, newlen: int) -> c.int ---
}

_get_tsc_frequency :: proc "contextless" () -> (u64, bool) {
	tmp_freq : u64 = 0
	tmp_size : i64 = size_of(tmp_freq)
	ret := _sysctlbyname("machdep.tsc_freq", &tmp_freq, &tmp_size, nil, 0)
	if ret < 0 {
		return 0, false
	}

	return tmp_freq, true
}
