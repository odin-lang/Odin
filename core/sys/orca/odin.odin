// File contains Odin specific helpers.

package orca

import "base:runtime"

create_odin_logger :: proc(lowest := runtime.Logger_Level.Debug, ident := "") -> runtime.Logger {
	return runtime.Logger{odin_logger_proc, nil, lowest, {}}
}

odin_logger_proc :: proc(logger_data: rawptr, level: runtime.Logger_Level, text: string, options: runtime.Logger_Options, location := #caller_location) {
	cbuf := make([]byte, len(text)+1, context.temp_allocator)
	copy(cbuf, text)
	ctext := cstring(raw_data(cbuf))

	switch level {
	case .Debug, .Info:  log_info(ctext, location)
	case .Warning:       log_warning(ctext, location)
	case:                fallthrough
	case .Error, .Fatal: log_error(ctext, location)
	}
}
