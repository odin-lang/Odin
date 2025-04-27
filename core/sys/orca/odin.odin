// File contains Odin specific helpers.

package orca

import "base:runtime"

create_odin_logger :: proc(lowest := runtime.Logger_Level.Debug, ident := "") -> runtime.Logger {
	return runtime.Logger{odin_logger_proc, nil, lowest, {}}
}

log_typed :: proc "contextless" (level: log_level, msg: cstring, loc := #caller_location) {
	log_ext(
		level,
		cstring(raw_data(loc.procedure)),
		cstring(raw_data(loc.file_path)),
		loc.line,
		msg,
	)
}

odin_logger_proc :: proc(logger_data: rawptr, level: runtime.Logger_Level, text: string, options: runtime.Logger_Options, location := #caller_location) {
	cbuf := make([]byte, len(text)+1, context.temp_allocator)
	copy(cbuf, text)
	ctext := cstring(raw_data(cbuf))

	switch level {
	case .Debug, .Info: log_typed(.INFO, ctext, location)
	case .Warning:       log_typed(.WARNING, ctext, location)
	case:                fallthrough
	case .Error, .Fatal: log_typed(.ERROR, ctext, location)
	}
}
