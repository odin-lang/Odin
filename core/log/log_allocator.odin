package log

import "core:runtime"

Log_Allocator_Format :: enum {
	Bytes, // Actual number of bytes.
	Human, // Bytes in human units like bytes, kibibytes, etc. as appropriate.
}

Log_Allocator :: struct {
	allocator: runtime.Allocator,
	level:     Level,
	prefix:    string,
	locked:    bool,
	size_fmt:  Log_Allocator_Format,
}

log_allocator_init :: proc(la: ^Log_Allocator, level: Level, size_fmt := Log_Allocator_Format.Bytes,
                           allocator := context.allocator, prefix := "") {
	la.allocator = allocator
	la.level = level
	la.prefix = prefix
	la.locked = false
	la.size_fmt = size_fmt
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
			fmt: string
			switch la.size_fmt {
			case .Bytes: fmt = "%s%s>>> ALLOCATOR(mode=.Alloc, size=%d, alignment=%d)"
			case .Human: fmt = "%s%s>>> ALLOCATOR(mode=.Alloc, size=%m, alignment=%d)"
			}
			logf(la.level, fmt, la.prefix, padding, size, alignment, location = location)
		case .Alloc_Non_Zeroed:
			fmt: string
			switch la.size_fmt {
			case .Bytes: fmt = "%s%s>>> ALLOCATOR(mode=.Alloc_Non_Zeroed, size=%d, alignment=%d)"
			case .Human: fmt = "%s%s>>> ALLOCATOR(mode=.Alloc_Non_Zeroed, size=%m, alignment=%d)"
			}
			logf(la.level, fmt, la.prefix, padding, size, alignment, location = location)
		case .Free:
			if old_size != 0 {
				fmt: string
				switch la.size_fmt {
				case .Bytes: fmt = "%s%s<<< ALLOCATOR(mode=.Free, ptr=%p, size=%d)"
				case .Human: fmt = "%s%s<<< ALLOCATOR(mode=.Free, ptr=%p, size=%m)"
				}
				logf(la.level, fmt, la.prefix, padding, old_memory, old_size, location = location)
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
			fmt: string
			switch la.size_fmt {
			case .Bytes: fmt = "%s%s>>> ALLOCATOR(mode=.Resize, ptr=%p, old_size=%d, size=%d, alignment=%d)"
			case .Human: fmt = "%s%s>>> ALLOCATOR(mode=.Resize, ptr=%p, old_size=%m, size=%m, alignment=%d)"
			}
			logf(la.level, fmt, la.prefix, padding, old_memory, old_size, size, alignment, location = location)

		case .Query_Features:
			logf(
				la.level,
				"%s%sALLOCATOR(mode=.Query_Features)",
				la.prefix, padding,
				location = location,
			)
		case .Query_Info:
			logf(
				la.level,
				"%s%sALLOCATOR(mode=.Query_Info)",
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
				"%s%sALLOCATOR ERROR=%v",
				la.prefix, padding, err,
				location = location,
			)
		}
	}
	return data, err
}
