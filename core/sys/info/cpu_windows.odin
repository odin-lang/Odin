package sysinfo

import sys "core:sys/windows"
import "base:intrinsics"

@(private)
_cpu_core_count :: proc "contextless" () -> (physical: int, logical: int, ok: bool) {
	// Reportedly, Windows Server supports a maximum of 256 logical cores.
	// The most scratch memory we need therefore is 8192 bytes = 256 * size_of(sys.SYSTEM_LOGICAL_PROCESSOR_INFORMATION)
	infos: [256]sys.SYSTEM_LOGICAL_PROCESSOR_INFORMATION

	// Query for the required buffer size.
	returned_length: sys.DWORD
	sys.GetLogicalProcessorInformation(nil, &returned_length)

	if int(returned_length) > size_of(infos) {
		return 0, 0, false
	}

	count := int(returned_length) / size_of(sys.SYSTEM_LOGICAL_PROCESSOR_INFORMATION)

	// If it still doesn't work, return
	if ok := sys.GetLogicalProcessorInformation(raw_data(infos[:]), &returned_length); !ok {
		return 0, 0, false
	}

	for info in infos[:count] {
		#partial switch info.Relationship {
		case .RelationProcessorCore: physical += 1
		case .RelationNumaNode:      logical  += int(intrinsics.count_ones(info.ProcessorMask))
		}
	}

	return physical, logical, true
}