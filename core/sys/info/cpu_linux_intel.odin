#+build i386, amd64
#+build linux
package sysinfo

import "base:runtime"
import "core:sys/linux"
import "core:strings"
import "core:strconv"

@(private)
_cpu_core_count :: proc "contextless" () -> (physical: int, logical: int, ok: bool) {
	context = runtime.default_context()
	fd, err := linux.open("/proc/cpuinfo", {})
	if err != .NONE { return }
	defer linux.close(fd)

	// This is probably enough right?
	buf: [4096]byte
	n, rerr := linux.read(fd, buf[:])
	if rerr != .NONE || n == 0 { return }

	physical_ok, logical_ok: bool

	str := string(buf[:n])
	for line in strings.split_lines_iterator(&str) {
		key, _, value := strings.partition(line, ":")
		key   = strings.trim_space(key)
		value = strings.trim_space(value)

		if key == "cpu cores" && !physical_ok{
			physical, physical_ok = strconv.parse_int(value)
		}

		if key == "siblings" && !logical_ok{
			logical, logical_ok = strconv.parse_int(value)
		}
	}
	return physical, logical, physical_ok || logical_ok
}