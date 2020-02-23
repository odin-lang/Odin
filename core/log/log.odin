package log

import "core:runtime"
import "core:fmt"


// NOTE(bill, 2019-12-31): These are defined in `package runtime` as they are used in the `context`. This is to prevent an import definition cycle.

Level :: runtime.Logger_Level;
/*
Level :: enum {
	Debug,
	Info,
	Warning,
	Error,
	Fatal,
}
*/

Option :: runtime.Logger_Option;
/*
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
*/

Options :: runtime.Logger_Options;
/*
Options :: bit_set[Option];
*/

Full_Timestamp_Opts :: Options{
	.Date,
	.Time
};
Location_Header_Opts :: Options{
	.Short_File_Path,
	.Long_File_Path,
	.Line,
	.Procedure,
};
Location_File_Opts :: Options{
	.Short_File_Path,
	.Long_File_Path
};


Logger_Proc :: runtime.Logger_Proc;
/*
Logger_Proc :: #type proc(data: rawptr, level: Level, text: string, options: Options, location := #caller_location);
*/

Logger :: runtime.Logger;
/*
Logger :: struct {
	procedure:    Logger_Proc,
	data:      	  rawptr,
	lowest_level: Level,
	options:   	  Logger_Options,
}
*/

Multi_Logger_Data :: struct {
	loggers : []Logger,
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
	if data.loggers == nil || len(data.loggers) == 0 {
		return;
	}
	for log in data.loggers {
		log.procedure(log.data, level, text, log.options, location);
	}
}

nil_logger_proc :: proc(data: rawptr, level: Level, text: string, options: Options, location := #caller_location) {
	// Do nothing
}

nil_logger :: proc() -> Logger {
	return Logger{nil_logger_proc, nil, Level.Debug, nil};
}

// TODO(bill): Should these be redesigned so that they are do not rely upon `package fmt`?
debugf :: proc(fmt_str : string, args : ..any, location := #caller_location) do logf(level=Level.Debug,   fmt_str=fmt_str, args=args, location=location);
infof  :: proc(fmt_str : string, args : ..any, location := #caller_location) do logf(level=Level.Info,    fmt_str=fmt_str, args=args, location=location);
warnf  :: proc(fmt_str : string, args : ..any, location := #caller_location) do logf(level=Level.Warning, fmt_str=fmt_str, args=args, location=location);
errorf :: proc(fmt_str : string, args : ..any, location := #caller_location) do logf(level=Level.Error,   fmt_str=fmt_str, args=args, location=location);
fatalf :: proc(fmt_str : string, args : ..any, location := #caller_location) do logf(level=Level.Fatal,   fmt_str=fmt_str, args=args, location=location);

debug :: proc(args : ..any, location := #caller_location) do log(level=Level.Debug,   args=args, location=location);
info  :: proc(args : ..any, location := #caller_location) do log(level=Level.Info,    args=args, location=location);
warn  :: proc(args : ..any, location := #caller_location) do log(level=Level.Warning, args=args, location=location);
error :: proc(args : ..any, location := #caller_location) do log(level=Level.Error,   args=args, location=location);
fatal :: proc(args : ..any, location := #caller_location) do log(level=Level.Fatal,   args=args, location=location);

log :: proc(level : Level, args : ..any, location := #caller_location) {
	logger := context.logger;
	if level < logger.lowest_level do return;
	str := fmt.tprint(..args); //NOTE(Hoej): While tprint isn't thread-safe, no logging is.
	logger.procedure(logger.data, level, str, logger.options, location);
}

logf :: proc(level : Level, fmt_str : string, args : ..any, location := #caller_location) {
	logger := context.logger;
	if level < logger.lowest_level do return;
	str := len(args) > 0 ? fmt.tprintf(fmt_str, ..args) : fmt.tprint(fmt_str); //NOTE(Hoej): While tprint isn't thread-safe, no logging is.
	logger.procedure(logger.data, level, str, logger.options, location);
}
