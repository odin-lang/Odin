package log

import "base:runtime"
import "core:fmt"

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

	if context.logger.procedure == nil || la.level < context.logger.lowest_level {
		return la.allocator.procedure(la.allocator.data, mode, size, alignment, old_memory, old_size, location)
	}

	padding := " " if la.prefix != "" else ""

	buf: [256]byte = ---

	if !la.locked {
		la.locked = true
		defer la.locked = false

		switch mode {
		case .Alloc:
			format: string
			switch la.size_fmt {
			case .Bytes: format = "%s%s>>> ALLOCATOR(mode=.Alloc, size=%d, alignment=%d)"
			case .Human: format = "%s%s>>> ALLOCATOR(mode=.Alloc, size=%m, alignment=%d)"
			}
			str := fmt.bprintf(buf[:], format, la.prefix, padding, size, alignment)
			context.logger.procedure(context.logger.data, la.level, str, context.logger.options, location)

		case .Alloc_Non_Zeroed:
			format: string
			switch la.size_fmt {
			case .Bytes: format = "%s%s>>> ALLOCATOR(mode=.Alloc_Non_Zeroed, size=%d, alignment=%d)"
			case .Human: format = "%s%s>>> ALLOCATOR(mode=.Alloc_Non_Zeroed, size=%m, alignment=%d)"
			}
			str := fmt.bprintf(buf[:], format, la.prefix, padding, size, alignment)
			context.logger.procedure(context.logger.data, la.level, str, context.logger.options, location)

		case .Free:
			if old_size != 0 {
				format: string
				switch la.size_fmt {
				case .Bytes: format = "%s%s<<< ALLOCATOR(mode=.Free, ptr=%p, size=%d)"
				case .Human: format = "%s%s<<< ALLOCATOR(mode=.Free, ptr=%p, size=%m)"
				}
				str := fmt.bprintf(buf[:], format, la.prefix, padding, old_memory, old_size)
				context.logger.procedure(context.logger.data, la.level, str, context.logger.options, location)
			} else {
				str := fmt.bprintf(buf[:], "%s%s<<< ALLOCATOR(mode=.Free, ptr=%p)", la.prefix, padding, old_memory)
				context.logger.procedure(context.logger.data, la.level, str, context.logger.options, location)
			}

		case .Free_All:
			str := fmt.bprintf(buf[:], "%s%s<<< ALLOCATOR(mode=.Free_All)", la.prefix, padding)
			context.logger.procedure(context.logger.data, la.level, str, context.logger.options, location)

		case .Resize:
			format: string
			switch la.size_fmt {
			case .Bytes: format = "%s%s>>> ALLOCATOR(mode=.Resize, ptr=%p, old_size=%d, size=%d, alignment=%d)"
			case .Human: format = "%s%s>>> ALLOCATOR(mode=.Resize, ptr=%p, old_size=%m, size=%m, alignment=%d)"
			}
			str := fmt.bprintf(buf[:], format, la.prefix, padding, old_memory, old_size, size, alignment)
			context.logger.procedure(context.logger.data, la.level, str, context.logger.options, location)

		case .Resize_Non_Zeroed:
			format: string
			switch la.size_fmt {
			case .Bytes: format = "%s%s>>> ALLOCATOR(mode=.Resize_Non_Zeroed, ptr=%p, old_size=%d, size=%d, alignment=%d)"
			case .Human: format = "%s%s>>> ALLOCATOR(mode=.Resize_Non_Zeroed, ptr=%p, old_size=%m, size=%m, alignment=%d)"
			}
			str := fmt.bprintf(buf[:], format, la.prefix, padding, old_memory, old_size, size, alignment)
			context.logger.procedure(context.logger.data, la.level, str, context.logger.options, location)

		case .Query_Features:
			str := fmt.bprintf(buf[:], "%s%sALLOCATOR(mode=.Query_Features)", la.prefix, padding)
			context.logger.procedure(context.logger.data, la.level, str, context.logger.options, location)

		case .Query_Info:
			str := fmt.bprintf(buf[:], "%s%sALLOCATOR(mode=.Query_Info)", la.prefix, padding)
			context.logger.procedure(context.logger.data, la.level, str, context.logger.options, location)
		}
	}

	data, err := la.allocator.procedure(la.allocator.data, mode, size, alignment, old_memory, old_size, location)
	if !la.locked {
		la.locked = true
		defer la.locked = false
		if err != nil {
			str := fmt.bprintf(buf[:], "%s%sALLOCATOR ERROR=%v", la.prefix, padding, err)
			context.logger.procedure(context.logger.data, la.level, str, context.logger.options, location)
		}
	}
	return data, err
}
