package log

import "core:runtime"

Log_Allocator :: struct {
	allocator: runtime.Allocator,
	level:     Level,
	prefix:    string,
	locked:    bool,
}

log_allocator_init :: proc(la: ^Log_Allocator, level: Level, allocator := context.allocator, prefix := "") {
	la.allocator = allocator
	la.level = level
	la.prefix = prefix
	la.locked = false
}


log_allocator :: proc(la: ^Log_Allocator) -> runtime.Allocator {
	return runtime.Allocator{
		procedure = log_allocator_proc,
		data = la,
	}
}

log_allocator_proc :: proc(allocator_data: rawptr, mode: runtime.Allocator_Mode,
                           size, alignment: int,
                           old_memory: rawptr, old_size: int, location := #caller_location) -> ([]byte, runtime.Allocator_Error)  {
	la := (^Log_Allocator)(allocator_data)

	padding := " " if la.prefix != "" else ""

	if !la.locked {
		la.locked = true
		defer la.locked = false

		switch mode {
		case .Alloc:
			logf(
				la.level,
				"%s%s>>> ALLOCATOR(mode=.Alloc, size=%d, alignment=%d)",
				la.prefix, padding, size, alignment,
				location = location,
			)
		case .Alloc_Non_Zeroed:
			logf(
				la.level,
				"%s%s>>> ALLOCATOR(mode=.Alloc_Non_Zeroed, size=%d, alignment=%d)",
				la.prefix, padding, size, alignment,
				location = location,
			)
		case .Free:
			if old_size != 0 {
				logf(
					la.level,
					"%s%s<<< ALLOCATOR(mode=.Free, ptr=%p, size=%d)",
					la.prefix, padding, old_memory, old_size,
					location = location,
				)
			} else {
				logf(
					la.level,
					"%s%s<<< ALLOCATOR(mode=.Free, ptr=%p)",
					la.prefix, padding, old_memory,
					location = location,
				)
			}
		case .Free_All:
			logf(
				la.level,
				"%s%s<<< ALLOCATOR(mode=.Free_All)",
				la.prefix, padding,
				location = location,
			)
		case .Resize:
			logf(
				la.level,
				"%s%s>>> ALLOCATOR(mode=.Resize, ptr=%p, old_size=%d, size=%d, alignment=%d)",
				la.prefix, padding, old_memory, old_size, size, alignment,
				location = location,
			)
		case .Query_Features:
			logf(
				la.level,
				"%s%ALLOCATOR(mode=.Query_Features)",
				la.prefix, padding,
				location = location,
			)
		case .Query_Info:
			logf(
				la.level,
				"%s%ALLOCATOR(mode=.Query_Info)",
				la.prefix, padding,
				location = location,
			)
		}
	}

	data, err := la.allocator.procedure(la.allocator.data, mode, size, alignment, old_memory, old_size, location)
	if !la.locked {
		la.locked = true
		defer la.locked = false
		if err != nil {
			logf(
				la.level,
				"%s%ALLOCATOR ERROR=%v",
				la.prefix, padding, error,
				location = location,
			)
		}
	}
	return data, err
}