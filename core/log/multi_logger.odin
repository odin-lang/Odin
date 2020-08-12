package log


Multi_Logger_Data :: struct {
	loggers: []Logger,
}

create_multi_logger :: proc(logs: ..Logger) -> Logger {
	data := new(Multi_Logger_Data);
	data.loggers = make([]Logger, len(logs));
	copy(data.loggers, logs);
	return Logger{multi_logger_proc, data, Level.Debug, nil};
}

destroy_multi_logger :: proc(log : ^Logger) {
	free(log.data);
	log^ = nil_logger();
}

multi_logger_proc :: proc(logger_data: rawptr, level: Level, text: string,
                          options: Options, location := #caller_location) {
	data := cast(^Multi_Logger_Data)logger_data;
	for log in data.loggers {
		if level < log.lowest_level {
			return;
		}
		log.procedure(log.data, level, text, log.options, location);
	}
}
