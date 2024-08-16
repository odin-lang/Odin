package log

import "base:runtime"
import "core:fmt"


// NOTE(bill, 2019-12-31): These are defined in `package runtime` as they are used in the `context`. This is to prevent an import definition cycle.

/*
Logger_Level :: enum {
	Debug   = 0,
	Info    = 10,
	Warning = 20,
	Error   = 30,
	Fatal   = 40,
}
*/
Level :: runtime.Logger_Level

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
Option :: runtime.Logger_Option

/*
Options :: bit_set[Option];
*/
Options :: runtime.Logger_Options

Full_Timestamp_Opts :: Options{
	.Date,
	.Time,
}
Location_Header_Opts :: Options{
	.Short_File_Path,
	.Long_File_Path,
	.Line,
	.Procedure,
}
Location_File_Opts :: Options{
	.Short_File_Path,
	.Long_File_Path,
}


/*
Logger_Proc :: #type proc(data: rawptr, level: Level, text: string, options: Options, location := #caller_location);
*/
Logger_Proc :: runtime.Logger_Proc

/*
Logger :: struct {
	procedure:    Logger_Proc,
	data:         rawptr,
	lowest_level: Level,
	options:      Logger_Options,
}
*/
Logger :: runtime.Logger

nil_logger_proc :: runtime.default_logger_proc

nil_logger :: proc() -> Logger {
	return Logger{nil_logger_proc, nil, Level.Debug, nil}
}

debugf :: proc(fmt_str: string, args: ..any, location := #caller_location) {
	logf(.Debug,   fmt_str, ..args, location=location)
}
infof  :: proc(fmt_str: string, args: ..any, location := #caller_location) {
	logf(.Info,    fmt_str, ..args, location=location)
}
warnf  :: proc(fmt_str: string, args: ..any, location := #caller_location) {
	logf(.Warning, fmt_str, ..args, location=location)
}
errorf :: proc(fmt_str: string, args: ..any, location := #caller_location) {
	logf(.Error,   fmt_str, ..args, location=location)
}
fatalf :: proc(fmt_str: string, args: ..any, location := #caller_location) {
	logf(.Fatal,   fmt_str, ..args, location=location)
}

debug :: proc(args: ..any, sep := " ", location := #caller_location) {
	log(.Debug,   ..args, sep=sep, location=location)
}
info  :: proc(args: ..any, sep := " ", location := #caller_location) {
	log(.Info,    ..args, sep=sep, location=location)
}
warn  :: proc(args: ..any, sep := " ", location := #caller_location) {
	log(.Warning, ..args, sep=sep, location=location)
}
error :: proc(args: ..any, sep := " ", location := #caller_location) {
	log(.Error,   ..args, sep=sep, location=location)
}
fatal :: proc(args: ..any, sep := " ", location := #caller_location) {
	log(.Fatal,   ..args, sep=sep, location=location)
}

panic :: proc(args: ..any, location := #caller_location) -> ! {
	log(.Fatal, ..args, location=location)
	runtime.panic("log.panic", location)
}
panicf :: proc(fmt_str: string, args: ..any, location := #caller_location) -> ! {
	logf(.Fatal, fmt_str, ..args, location=location)
	runtime.panic("log.panicf", location)
}

@(disabled=ODIN_DISABLE_ASSERT)
assert :: proc(condition: bool, message := "", loc := #caller_location) {
	if !condition {
		@(cold)
		internal :: proc(message: string, loc: runtime.Source_Code_Location) {
			p := context.assertion_failure_proc
			if p == nil {
				p = runtime.default_assertion_failure_proc
			}
			log(.Fatal, message, location=loc)
			p("runtime assertion", message, loc)
		}
		internal(message, loc)
	}
}

@(disabled=ODIN_DISABLE_ASSERT)
assertf :: proc(condition: bool, fmt_str: string, args: ..any, loc := #caller_location) {
	if !condition {
		// NOTE(dragos): We are using the same trick as in builtin.assert
		// to improve performance to make the CPU not
		// execute speculatively, making it about an order of
		// magnitude faster
		@(cold)
		internal :: proc(loc: runtime.Source_Code_Location, fmt_str: string, args: ..any) {
			p := context.assertion_failure_proc
			if p == nil {
				p = runtime.default_assertion_failure_proc
			}
			message := fmt.tprintf(fmt_str, ..args)
			log(.Fatal, message, location=loc)
			p("Runtime assertion", message, loc)
		}
		internal(loc, fmt_str, ..args)
	}
}



log :: proc(level: Level, args: ..any, sep := " ", location := #caller_location) {
	logger := context.logger
	if logger.procedure == nil || logger.procedure == nil_logger_proc {
		return
	}
	if level < logger.lowest_level {
		return
	}
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	str := fmt.tprint(..args, sep=sep) //NOTE(Hoej): While tprint isn't thread-safe, no logging is.
	logger.procedure(logger.data, level, str, logger.options, location)
}

logf :: proc(level: Level, fmt_str: string, args: ..any, location := #caller_location) {
	logger := context.logger
	if logger.procedure == nil || logger.procedure == nil_logger_proc {
		return
	}
	if level < logger.lowest_level {
		return
	}
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	str := fmt.tprintf(fmt_str, ..args)
	logger.procedure(logger.data, level, str, logger.options, location)
}
