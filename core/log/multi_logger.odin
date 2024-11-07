package log

import "base:runtime"
import "core:slice"
import "core:mem"

Multi_Logger_Data :: struct {
	loggers: []Logger,
	allocator: runtime.Allocator
}

create_multi_logger :: proc(logs: ..Logger) -> Logger {
	logger, _ := make_multi_logger(..logs, allocator = context.allocator)
	return logger
}

make_multi_logger :: proc(logs: ..Logger, allocator := context.allocator) -> (res: Logger, err: runtime.Allocator_Error) {
	logger_size := mem.align_forward_int(size_of(Multi_Logger_Data), align_of(Logger))
	content_size := len(mem.slice_to_bytes(logs))

	data_bytes := make([]byte, logger_size + content_size, allocator) or_return
	data := cast(^Multi_Logger_Data)raw_data(data_bytes)
	data.loggers = slice.reinterpret([]Logger, data_bytes[logger_size:])
	assert(len(data.loggers) == len(logs))
	copy(data.loggers, logs)
	data.allocator = allocator

	return Logger{multi_logger_proc, data, Level.Debug, nil}, nil
}

delete_multi_logger :: proc(log: Logger) {
	data := (^Multi_Logger_Data)(log.data)
	free(data, data.allocator)
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
