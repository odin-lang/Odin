//+build riscv64
//+build linux
package sysinfo

import "base:intrinsics"

import "core:sys/linux"

@(init, private)
init_cpu_features :: proc() {
	_features: CPU_Features
	defer cpu_features = _features

	HWCAP_Bits :: enum u64 {
		I = 'I' - 'A',
		M = 'M' - 'A',
		A = 'A' - 'A',
		F = 'F' - 'A',
		D = 'D' - 'A',
		C = 'C' - 'A',
		V = 'V' - 'A',
	}
	HWCAP :: bit_set[HWCAP_Bits; u64]

	// Read HWCAP for base extensions, we can get this info through hwprobe too but that is Linux 6.4+ only.
	{
		fd, err := linux.open("/proc/self/auxv", {})
		if err != .NONE { return }
		defer linux.close(fd)

		// This is probably enough right?
		buf: [4096]byte
		n, rerr := linux.read(fd, buf[:])
		if rerr != .NONE || n == 0 { return }

		ulong     :: u64
		AT_HWCAP  :: 16

		auxv := buf[:n]
		for len(auxv) >= size_of(ulong)*2 {
			key := intrinsics.unaligned_load((^ulong)(&auxv[0]))
			val := intrinsics.unaligned_load((^ulong)(&auxv[size_of(ulong)]))
			auxv = auxv[2*size_of(ulong):]

			if key != AT_HWCAP {
				continue
			}

			cap := transmute(HWCAP)(val)
			if .I in cap {
				_features += { .I }
			}
			if .M in cap {
				_features += { .M }
			}
			if .A in cap {
				_features += { .A }
			}
			if .F in cap {
				_features += { .F }
			}
			if .D in cap {
				_features += { .D }
			}
			if .C in cap {
				_features += { .C }
			}
			if .V in cap {
				_features += { .V }
			}
			break
		}
	}

	// hwprobe for other features.
	{
		pairs := []linux.RISCV_HWProbe{
			{ key = .IMA_EXT_0 },
			{ key = .CPUPERF_0 },
			{ key = .MISALIGNED_SCALAR_PERF },
		}
		err := linux.riscv_hwprobe(raw_data(pairs), len(pairs), 0, nil, {})
		if err != nil {
			assert(err == .ENOSYS, "unexpected error from riscv_hwprobe()")
			return
		}

		assert(pairs[0].key == .IMA_EXT_0)
		exts := pairs[0].value.ima_ext_0
		exts -= { .FD, .C, .V }
		_features += transmute(CPU_Features)exts

		if pairs[2].key == .MISALIGNED_SCALAR_PERF {
			if pairs[2].value.misaligned_scalar_perf == .FAST {
				_features += { .Misaligned_Supported, .Misaligned_Fast }
			} else if pairs[2].value.misaligned_scalar_perf != .UNSUPPORTED {
				_features += { .Misaligned_Supported }
			}
		} else {
			assert(pairs[1].key == .CPUPERF_0)
			if .FAST in pairs[1].value.cpu_perf_0 {
				_features += { .Misaligned_Supported, .Misaligned_Fast }
			} else if .UNSUPPORTED not_in pairs[1].value.cpu_perf_0 {
				_features += { .Misaligned_Supported }
			}
		}
	}
}

@(init, private)
init_cpu_name :: proc() {
	cpu_name = "RISCV64"
}
