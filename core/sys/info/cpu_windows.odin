package sysinfo

import sys "core:sys/windows"
import "base:intrinsics"
import "base:runtime"

@(init, private)
init_cpu_core_count :: proc "contextless" () {
	context = runtime.default_context()

	infos: []sys.SYSTEM_LOGICAL_PROCESSOR_INFORMATION
	defer delete(infos)

	returned_length: sys.DWORD
	// Query for the required buffer size.
	if ok := sys.GetLogicalProcessorInformation(raw_data(infos), &returned_length); !ok {
		infos = make([]sys.SYSTEM_LOGICAL_PROCESSOR_INFORMATION, returned_length / size_of(sys.SYSTEM_LOGICAL_PROCESSOR_INFORMATION))
	}

	// If it still doesn't work, return
	if ok := sys.GetLogicalProcessorInformation(raw_data(infos), &returned_length); !ok {
		return
	}

	for info in infos {
		#partial switch info.Relationship {
		case .RelationProcessorCore: cpu.physical_cores += 1
		case .RelationNumaNode:      cpu.logical_cores  += int(intrinsics.count_ones(info.ProcessorMask))
		}
	}
}