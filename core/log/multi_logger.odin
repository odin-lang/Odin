package log

import "base:runtime"
import "core:slice"
import "core:mem"

Multi_Logger_Data :: struct {
	loggers: []Logger,
	allocator: runtime.Allocator,
}

@(deprecated = "Use make_multi_logger instead")
create_multi_logger :: proc(logs: ..Logger) -> Logger {
	logger, _ := make_multi_logger(..logs, allocator = context.allocator)
	return logger
}

/*
Makes a new logger that will write to several other loggers.

*Allocates Using Provided Allocator*

Inputs:
- logs: The loggers this logger will write to
- allocator: (default: context.allocator)
- loc: The caller location for debugging purposes (default: `#caller_location`)

Returns:
- res: The new multi logger 
- err: An allocator error if one occured, `nil` otherwise 
*/
make_multi_logger :: proc(logs: ..Logger, allocator := context.allocator, loc := #caller_location) -> (res: Logger, err: runtime.Allocator_Error) {
	// NOTE(lperlind): we allocate the entire logger in a single allocation so we have only one
	// allocation error to be handled. This is NOT for performance
	logger_size := mem.align_forward_int(size_of(Multi_Logger_Data), align_of(Logger))
	content_size := len(mem.slice_to_bytes(logs))

	data_bytes := make([]byte, logger_size + content_size, allocator, loc) or_return
	data := cast(^Multi_Logger_Data)raw_data(data_bytes)
	data.loggers = slice.reinterpret([]Logger, data_bytes[logger_size:])
	assert(len(data.loggers) == len(logs))
	copy(data.loggers, logs)
	data.allocator = allocator

	return Logger{multi_logger_proc, data, Level.Debug, nil}, nil
}

/*
Deletes a logger made with `make_multi_logger`.

Inputs:
- log: The logger to delete
- loc: The caller location for debugging purposes (default: `#caller_location`)
*/
delete_multi_logger :: proc(log: Logger, loc := #caller_location) {
	data := (^Multi_Logger_Data)(log.data)
	free(data, data.allocator, loc)
}
destroy_multi_logger :: delete_multi_logger

multi_logger_proc :: proc(logger_data: rawptr, level: Level, text: string,
                          options: Options, location := #caller_location) {
	data := cast(^Multi_Logger_Data)logger_data
	for log in data.loggers {
		if level < log.lowest_level {
			return
		}
		log.procedure(log.data, level, text, log.options, location)
	}
}
