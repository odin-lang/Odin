package log

import "core:runtime"

Log_Allocator :: struct {
	allocator: runtime.Allocator,
	level:     Level,
	prefix:    string,
}

log_allocator_init :: proc(la: ^Log_Allocator, level: Level, allocator := context.allocator, prefix := "") {
	la.allocator = allocator
	la.level = level
	la.prefix = prefix
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

	switch mode {
	case .Alloc:
		logf(
			level=la.level,
			fmt_str = "%s%s>>> ALLOCATOR(mode=.Alloc, size=%d, alignment=%d)",
			args = {la.prefix, " " if la.prefix != "" else "", size, alignment},
			location = location,
		)
	case .Free:
		if old_size != 0 {
			logf(
				level=la.level,
				fmt_str = "%s%s<<< ALLOCATOR(mode=.Free, ptr=%p, size=%d)",
				args = {la.prefix, " " if la.prefix != "" else "", old_memory, old_size},
				location = location,
			)
		} else {
			logf(
				level=la.level,
				fmt_str = "%s%s<<< ALLOCATOR(mode=.Free, ptr=%p)",
				args = {la.prefix, " " if la.prefix != "" else "", old_memory},
				location = location,
			)
		}
	case .Free_All:
		logf(
			level=la.level,
			fmt_str = "%s%s<<< ALLOCATOR(mode=.Free_All)",
			args = {la.prefix, " " if la.prefix != "" else ""},
			location = location,
		)
	case .Resize:
		logf(
			level=la.level,
			fmt_str = "%s%s>>> ALLOCATOR(mode=.Resize, ptr=%p, old_size=%d, size=%d, alignment=%d)",
			args = {la.prefix, " " if la.prefix != "" else "", old_memory, old_size, size, alignment},
			location = location,
		)
	case .Query_Features:
		logf(
			level=la.level,
			fmt_str = "%s%ALLOCATOR(mode=.Query_Features)",
			args = {la.prefix, " " if la.prefix != "" else ""},
			location = location,
		)
	case .Query_Info:
		logf(
			level=la.level,
			fmt_str = "%s%ALLOCATOR(mode=.Query_Info)",
			args = {la.prefix, " " if la.prefix != "" else ""},
			location = location,
		)
	}

	return la.allocator.procedure(la.allocator.data, mode, size, alignment, old_memory, old_size, location)
}