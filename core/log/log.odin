package log

import "core:runtime"
import "core:fmt"
import "core:sync"


// NOTE(bill, 2019-12-31): These are defined in `package runtime` as they are used in the `context`. This is to prevent an import definition cycle.

Level :: runtime.Logger_Level;
/*
Logger_Level :: enum {
	Debug   = 0,
	Info    = 10,
	Warning = 20,
	Error   = 30,
	Fatal   = 40,
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

nil_logger_proc :: proc(data: rawptr, level: Level, text: string, options: Options, location := #caller_location) {
	// Do nothing
}

nil_logger :: proc() -> Logger {
	return Logger{nil_logger_proc, nil, Level.Debug, nil};
}

// TODO(bill): Should these be redesigned so that they are do not rely upon `package fmt`?
debugf :: proc(fmt_str: string, args: ..any, location := #caller_location) {
	logf(level=.Debug,   fmt_str=fmt_str, args=args, location=location);
}
infof  :: proc(fmt_str: string, args: ..any, location := #caller_location) {
	logf(level=.Info,    fmt_str=fmt_str, args=args, location=location);
}
warnf  :: proc(fmt_str: string, args: ..any, location := #caller_location) {
	logf(level=.Warning, fmt_str=fmt_str, args=args, location=location);
}
errorf :: proc(fmt_str: string, args: ..any, location := #caller_location) {
	logf(level=.Error,   fmt_str=fmt_str, args=args, location=location);
}
fatalf :: proc(fmt_str: string, args: ..any, location := #caller_location) {
	logf(level=.Fatal,   fmt_str=fmt_str, args=args, location=location);
}

debug :: proc(args: ..any, sep := " ", location := #caller_location) {
	log(level=.Debug,   args=args, sep=sep, location=location);
}
info  :: proc(args: ..any, sep := " ", location := #caller_location) {
	log(level=.Info,    args=args, sep=sep, location=location);
}
warn  :: proc(args: ..any, sep := " ", location := #caller_location) {
	log(level=.Warning, args=args, sep=sep, location=location);
}
error :: proc(args: ..any, sep := " ", location := #caller_location) {
	log(level=.Error,   args=args, sep=sep, location=location);
}
fatal :: proc(args: ..any, sep := " ", location := #caller_location) {
	log(level=.Fatal,   args=args, sep=sep, location=location);
}

panic :: proc(args: ..any, location := #caller_location) -> ! {
	log(level=.Fatal, args=args, location=location);
	runtime.panic("log.panic");
}
panicf :: proc(fmt_str: string, args: ..any, location := #caller_location) -> ! {
	logf(level=.Fatal, fmt_str=fmt_str, args=args, location=location);
	runtime.panic("log.panicf");
}




log :: proc(level: Level, args: ..any, sep := " ", location := #caller_location) {
	logger := context.logger;
	if level < logger.lowest_level {
		return;
	}
	str := fmt.tprint(args=args, sep=sep); //NOTE(Hoej): While tprint isn't thread-safe, no logging is.
	logger.procedure(logger.data, level, str, logger.options, location);
}

logf :: proc(level: Level, fmt_str: string, args: ..any, location := #caller_location) {
	logger := context.logger;
	if level < logger.lowest_level {
		return;
	}
	str := fmt.tprintf(fmt_str, ..args);
	logger.procedure(logger.data, level, str, logger.options, location);
}
