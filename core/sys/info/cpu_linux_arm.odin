//+build arm32, arm64
//+build linux
package sysinfo

import "core:sys/linux"
import "core:strings"

@(init, private)
init_cpu_features :: proc() {
	fd, err := linux.open("/proc/cpuinfo", {})
	if err != .NONE { return }
	defer linux.close(fd)

	// This is probably enough right?
	buf: [4096]byte
	n, rerr := linux.read(fd, buf[:])
	if rerr != .NONE || n == 0 { return }

	features: CPU_Features
	defer cpu_features = features

	str := string(buf[:n])
	for line in strings.split_lines_iterator(&str) {
		key, _, value := strings.partition(line, ":")
		key   = strings.trim_space(key)
		value = strings.trim_space(value)

		if key != "Features" { continue }

		for feature in strings.split_by_byte_iterator(&value, ' ') {
			switch feature {
			case "asimd", "neon": features += { .asimd }
			case "fp":            features += { .floatingpoint }
			case "asimdhp":       features += { .asimdhp }
			case "asimdbf16":     features += { .bf16 }
			case "fcma":          features += { .fcma }
			case "asimdfhm":      features += { .fhm }
			case "fphp", "half":  features += { .fp16 }
			case "frint":         features += { .frint }
			case "i8mm":          features += { .i8mm }
			case "jscvt":         features += { .jscvt }
			case "asimdrdm":      features += { .rdm }

			case "flagm":  features += { .flagm }
			case "flagm2": features += { .flagm2 }
			case "crc32":  features += { .crc32 }

			case "atomics": features += { .lse }
			case "lrcpc":   features += { .lrcpc }
			case "ilrcpc":  features += { .lrcpc2 }

			case "aes":    features += { .aes }
			case "pmull":  features += { .pmull }
			case "sha1":   features += { .sha1 }
			case "sha2":   features += { .sha256 }
			case "sha3":   features += { .sha3 }
			case "sha512": features += { .sha512 }

			case "sb":   features += { .sb }
			case "ssbs": features += { .ssbs }
			}
		}
		break
	}
}
