package log

import "core:fmt";
import "core:runtime";

Level :: enum {
	Debug,
	Info,
	Warning,
	Error,
	Fatal,
}

Option :: enum {
    Level,
    Date,
    Time,
    Short_File_Path,
    Long_File_Path,
    Line,
    Procedure,
    Terminal_Color
}

Options :: bit_set[Option];
Full_Timestamp_Opts :: Options{
    Option.Date,
    Option.Time
};
Location_Header_Opts :: Options{
    Option.Short_File_Path,
    Option.Long_File_Path,
    Option.Line,
    Option.Procedure,
};
Location_File_Opts :: Options{
    Option.Short_File_Path,
    Option.Long_File_Path
};

Logger_Proc :: #type proc(data: rawptr, level: Level, text: string, options: Options, location := #caller_location);

Logger :: struct {
	procedure: Logger_Proc,
	data:      rawptr,
    options:   Options,
}

Multi_Logger_Data :: struct {
    loggers : []Logger,
}

create_multi_logger :: proc(logs: ..Logger) -> Logger {
    data := new(Multi_Logger_Data);
    data.loggers = make([]Logger, len(logs));
    for log, i in logs do data.loggers[i] = log;
    return Logger{multi_logger_proc, data, nil};
}

destroy_multi_logger ::proc(log : ^Logger) {
    free(log.data);
    log^ = nil_logger();
}

multi_logger_proc :: proc(logger_data: rawptr, level: Level, text: string, 
                          options: Options, location := #caller_location) {
    data := cast(^Multi_Logger_Data)logger_data;
    if data.loggers == nil || len(data.loggers) == 0 do return;
    for log in data.loggers do log.procedure(log.data, level, text, log.options, location);
}

nil_logger_proc :: proc(data: rawptr, level: Level, text: string, options: Options, location := #caller_location) {
	// Do nothing
}

nil_logger :: proc() -> Logger {
	return Logger{nil_logger_proc, nil, nil};
}

debug :: proc(fmt_str : string, args : ..any, location := #caller_location) do logf(level=Level.Debug,   fmt_str=fmt_str, args=args, location=location);
info  :: proc(fmt_str : string, args : ..any, location := #caller_location) do logf(level=Level.Info,    fmt_str=fmt_str, args=args, location=location);
warn  :: proc(fmt_str : string, args : ..any, location := #caller_location) do logf(level=Level.Warning, fmt_str=fmt_str, args=args, location=location);
error :: proc(fmt_str : string, args : ..any, location := #caller_location) do logf(level=Level.Error,   fmt_str=fmt_str, args=args, location=location);
fatal :: proc(fmt_str : string, args : ..any, location := #caller_location) do logf(level=Level.Fatal,   fmt_str=fmt_str, args=args, location=location);

logf :: proc(level : Level, fmt_str : string, args : ..any, location := #caller_location) {
    logger := context.logger;
    str := len(args) > 0 ? fmt.tprintf(fmt_str, ..args) : fmt.tprint(fmt_str); //NOTE(Hoej): While tprint isn't thread-safe, no logging is.
    logger.procedure(logger.data, level, str, logger.options, location);
}