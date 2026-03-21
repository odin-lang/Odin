#+build arm32, arm64
#+build linux
package sysinfo

import "base:runtime"
import "core:sys/linux"
import "core:strconv"
import "core:strings"

@(private)
_cpu_features :: proc "contextless" () -> (features: CPU_Features) {
	return _features
}

@(init, private)
_init_cpu_features :: proc "contextless" () {
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

		if key != "Features" { continue }

		for feature in strings.split_by_byte_iterator(&value, ' ') {
			switch feature {
			case "asimd", "neon": _features += { .asimd }
			case "fp":            _features += { .floatingpoint }
			case "asimdhp":       _features += { .asimdhp }
			case "asimdbf16":     _features += { .bf16 }
			case "fcma":          _features += { .fcma }
			case "asimdfhm":      _features += { .fhm }
			case "fphp", "half":  _features += { .fp16 }
			case "frint":         _features += { .frint }
			case "i8mm":          _features += { .i8mm }
			case "jscvt":         _features += { .jscvt }
			case "asimdrdm":      _features += { .rdm }

			case "flagm":         _features += { .flagm }
			case "flagm2":        _features += { .flagm2 }
			case "crc32":         _features += { .crc32 }

			case "atomics":       _features += { .lse }
			case "lrcpc":         _features += { .lrcpc }
			case "ilrcpc":        _features += { .lrcpc2 }

			case "aes":           _features += { .aes }
			case "pmull":         _features += { .pmull }
			case "sha1":          _features += { .sha1 }
			case "sha2":          _features += { .sha256 }
			case "sha3":          _features += { .sha3 }
			case "sha512":        _features += { .sha512 }

			case "sb":            _features += { .sb }
			case "ssbs":          _features += { .ssbs }
			}
		}
		break
	}
}

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