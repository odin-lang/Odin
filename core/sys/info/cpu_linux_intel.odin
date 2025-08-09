#+build i386, amd64
#+build linux
package sysinfo

import "base:runtime"
import "core:sys/linux"
import "core:strings"
import "core:strconv"

@(init, private)
init_cpu_core_count :: proc "contextless" () {
	context = runtime.default_context()

	fd, err := linux.open("/proc/cpuinfo", {})
	if err != .NONE { return }
	defer linux.close(fd)

	// This is probably enough right?
	buf: [4096]byte
	n, rerr := linux.read(fd, buf[:])
	if rerr != .NONE || n == 0 { return }

	str := string(buf[:n])
	for line in strings.split_lines_iterator(&str) {
		key, _, value := strings.partition(line, ":")
		key   = strings.trim_space(key)
		value = strings.trim_space(value)

		if key == "cpu cores" {
			if num_physical_cores, ok := strconv.parse_int(value); ok {
				cpu.physical_cores = num_physical_cores
			}
		}

		if key == "siblings" {
			if num_logical_cores, ok := strconv.parse_int(value); ok {
				cpu.logical_cores = num_logical_cores
			}
		}
	}
}