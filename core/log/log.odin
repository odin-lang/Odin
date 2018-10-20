package log

Level :: enum {
	Debug,
	Info,
	Warning,
	Error,
	Fatal,
}

Option :: enum {
	Level,
	Time,
	File,
	Line,
	Procedure,
}
Options :: bit_set[Option];

Logger_Proc :: #type proc(data: rawptr, level: Level, ident, text: string, options: Options, location := #caller_location);

Logger :: struct {
	procedure: Logger_Proc,
	data:      rawptr,
}


nil_logger_proc :: proc(data: rawptr, level: Level, ident, text: string, options: Options, location := #caller_location) {
	// Do nothing
}

nil_logger :: proc() -> Logger {
	return Logger{nil_logger_proc, nil};
}
