package log

/*
A container backing a multi logger.
*/
Multi_Logger_Data :: struct {
	loggers: []Logger,
}

/*
Create a logger that logs to all backing loggers.

When no longer needed can be destroyed with `destroy_multi_logger`.

Note: Logs using a multi logger take both the multi logger and the backing loggers' log levels into account.

Inputs:
- `logs` - Backing loggers passed as multiple arguments
- `allocator` - An allocator used to allocate data to store backing loggers

Returns:
- A multi logger
*/
create_multi_logger :: proc(logs: ..Logger, allocator := context.allocator) -> Logger {
	data := new(Multi_Logger_Data, allocator)
	data.loggers = make([]Logger, len(logs), allocator)
	copy(data.loggers, logs)
	return Logger{multi_logger_proc, data, Level.Debug, nil}
}

/*
Destroy a logger created with `create_multi_logger`.

Inputs:
- `log`: Logger created with `create_multi_logger`
- `allocator`: Allocator passed to `create_multi_logger`
*/
destroy_multi_logger :: proc(log: Logger, allocator := context.allocator) {
	data := (^Multi_Logger_Data)(log.data)
	delete(data.loggers, allocator)
	free(data, allocator)
}

/*
Backing procedure for the multi logger.
*/
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
