package log

import "base:runtime"
import "core:fmt"

/*
A cutoff point for what messages the logger will log or ignore.

Defined in `package runtime` as it is used in the `context`. This is to prevent an import definition cycle.

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
Specifies additional data present in the log output.

Defined in `package runtime` as it is used in the `context`. This is to prevent an import definition cycle.

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
Specifies additional data present in the log output.

Defined in `package runtime` as it is used in the `context`. This is to prevent an import definition cycle.

	Options :: bit_set[Option];
*/
Options :: runtime.Logger_Options

/*
A preset option set for a logger.

When you use this set of options you can expect the following output:

	[YYYY-MM-DD HH:MM:SS] Message

For example:

	[2025-01-02 12:34:56] Hello World!
*/
Full_Timestamp_Opts :: Options{
	.Date,
	.Time,
}

/*
A preset option set for a logger.

When you use this set of options you can expect the following output:

	[file.odin:L:proc()] Message

For example:

	[main.odin:8:main()] Hello World!
*/
Location_Header_Opts :: Options{
	.Short_File_Path,
	.Long_File_Path,
	.Line,
	.Procedure,
}

/*
A preset option set for a logger.

When you use this set of options you can expect the following output:

	[file.odin] Message

For example:

	[main.odin] Hello World!
*/
Location_File_Opts :: Options{
	.Short_File_Path,
	.Long_File_Path,
}

/*
Implementation of the logger.

Defined in `package runtime` as it is used in the `context`. This is to prevent an import definition cycle.

	Logger_Proc :: #type proc(data: rawptr, level: Level, text: string, options: Options, location := #caller_location);
*/
Logger_Proc :: runtime.Logger_Proc

/*
Data backing the logger.

Defined in `package runtime` as it is used in the `context`. This is to prevent an import definition cycle.

	Logger :: struct {
		// Implementation
		procedure:    Logger_Proc,
		// Configuration data passed to the implementation
		data:         rawptr,
		// Minimum level for messages passed to the implementation
		lowest_level: Level,
		// Additional data present in the log output
		options:      Logger_Options,
	}
*/
Logger :: runtime.Logger

/*
Do nothing.

Defined in `package runtime` as it is used in the `context`. This is to prevent an import definition cycle.
*/
nil_logger_proc :: runtime.default_logger_proc

/*
Create a logger that does nothing.
*/
nil_logger :: proc() -> Logger {
	return Logger{nil_logger_proc, nil, Level.Debug, nil}
}

/*
Log a formatted message at the `Debug` level.

Inputs:
- `fmt_str`: A format string, e.g. `"a: %v, b: %v"
- `args`: Arguments for the format string
- `location`: Location of the caller
*/
debugf :: proc(fmt_str: string, args: ..any, location := #caller_location) {
	logf(.Debug,   fmt_str, ..args, location=location)
}

/*
Log a formatted message at the `Info` level.

Inputs:
- `fmt_str`: A format string, e.g. `"a: %v, b: %v"
- `args`: Arguments for the format string
- `location`: Location of the caller
*/
infof  :: proc(fmt_str: string, args: ..any, location := #caller_location) {
	logf(.Info,    fmt_str, ..args, location=location)
}

/*
Log a formatted message at the `Warn` level.

Inputs:
- `fmt_str`: A format string, e.g. `"a: %v, b: %v"
- `args`: Arguments for the format string
- `location`: Location of the caller
*/
warnf  :: proc(fmt_str: string, args: ..any, location := #caller_location) {
	logf(.Warning, fmt_str, ..args, location=location)
}

/*
Log a formatted message at the `Error` level.

Inputs:
- `fmt_str`: A format string, e.g. `"a: %v, b: %v"
- `args`: Arguments for the format string
- `location`: Location of the caller
*/
errorf :: proc(fmt_str: string, args: ..any, location := #caller_location) {
	logf(.Error,   fmt_str, ..args, location=location)
}

/*
Log a formatted message at the `Fatal` level.

Inputs:
- `fmt_str`: A format string, e.g. `"a: %v, b: %v"
- `args`: Arguments for the format string
- `location`: Location of the caller
*/
fatalf :: proc(fmt_str: string, args: ..any, location := #caller_location) {
	logf(.Fatal,   fmt_str, ..args, location=location)
}

/*
Log a message at the `Debug` level.

Inputs:
- `args`: values to be concatenated into the output
- `sep`: separator to use when concatenating
- `location`: Location of the caller
*/
debug :: proc(args: ..any, sep := " ", location := #caller_location) {
	log(.Debug,   ..args, sep=sep, location=location)
}

/*
Log a message at the `Info` level.

Inputs:
- `args`: values to be concatenated into the output
- `sep`: separator to use when concatenating
- `location`: Location of the caller
*/
info  :: proc(args: ..any, sep := " ", location := #caller_location) {
	log(.Info,    ..args, sep=sep, location=location)
}

/*
Log a message at the `Warn` level.

Inputs:
- `args`: values to be concatenated into the output
- `sep`: separator to use when concatenating
- `location`: Location of the caller
*/
warn  :: proc(args: ..any, sep := " ", location := #caller_location) {
	log(.Warning, ..args, sep=sep, location=location)
}

/*
Log a message at the `Error` level.

Inputs:
- `args`: values to be concatenated into the output
- `sep`: separator to use when concatenating
- `location`: Location of the caller
*/
error :: proc(args: ..any, sep := " ", location := #caller_location) {
	log(.Error,   ..args, sep=sep, location=location)
}

/*
Log a message at the `Fatal` level.

Inputs:
- `args`: values to be concatenated into the output
- `sep`: separator to use when concatenating
- `location`: Location of the caller
*/
fatal :: proc(args: ..any, sep := " ", location := #caller_location) {
	log(.Fatal,   ..args, sep=sep, location=location)
}

/*
Log a message at the `Fatal` level and abort the program.

Inputs:
- `args`: values to be concatenated into the output
- `location`: Location of the caller
*/
panic :: proc(args: ..any, location := #caller_location) -> ! {
	log(.Fatal, ..args, location=location)
	runtime.panic("log.panic", location)
}

/*
Log a formatted message at the `Fatal` level and abort the program.

Inputs:
- `fmt_str`: A format string, e.g. `"a: %v, b: %v"
- `args`: Arguments for the format string
- `location`: Location of the caller
*/
panicf :: proc(fmt_str: string, args: ..any, location := #caller_location) -> ! {
	logf(.Fatal, fmt_str, ..args, location=location)
	runtime.panic("log.panicf", location)
}

/*
When condition is `false` log a message at the `Fatal` level and abort the program.

Can be disabled using `ODIN_DISABLE_ASSERT`.

Inputs:
- `condition`: A boolean to check
- `message`: Message to log when condition is false
- `loc`: Location of the caller
*/
@(disabled=ODIN_DISABLE_ASSERT)
assert :: proc(condition: bool, message := #caller_expression(condition), loc := #caller_location) {
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

/*
When condition is `false` log a formatted message at the `Fatal` level and abort the program.

Can be disabled using `ODIN_DISABLE_ASSERT`.

Inputs:
- `condition`: A boolean to check
- `fmt_str`: A format string to use when condition is false, e.g. `"a: %v, b: %v"
- `args`: Arguments for the format string
- `loc`: Location of the caller
*/
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
			p("runtime assertion", message, loc)
		}
		internal(loc, fmt_str, ..args)
	}
}

/*
When condition is `false` log a message at the `Fatal` level and abort the program.

Unlike `assert` this procedure cannot be disabled with `ODIN_DISABLE_ASSERT` and will always execute.

Inputs:
- `condition`: A boolean to check
- `message`: Message to log when condition is false
- `loc`: Location of the caller
*/
ensure :: proc(condition: bool, message := #caller_expression(condition), loc := #caller_location) {
	if !condition {
		@(cold)
		internal :: proc(message: string, loc: runtime.Source_Code_Location) {
			p := context.assertion_failure_proc
			if p == nil {
				p = runtime.default_assertion_failure_proc
			}
			log(.Fatal, message, location=loc)
			p("unsatisfied ensure", message, loc)
		}
		internal(message, loc)
	}
}

/*
When condition is `false` log a formatted message at the `Fatal` level and abort the program.

Unlike `assertf` this procedure cannot be disabled with `ODIN_DISABLE_ASSERT` and will always execute.

Inputs:
- `condition`: A boolean to check
- `fmt_str`: A format string to use when condition is false, e.g. `"a: %v, b: %v"
- `args`: Arguments for the format string
- `loc`: Location of the caller
*/
ensuref :: proc(condition: bool, fmt_str: string, args: ..any, loc := #caller_location) {
	if !condition {
		@(cold)
		internal :: proc(loc: runtime.Source_Code_Location, fmt_str: string, args: ..any) {
			p := context.assertion_failure_proc
			if p == nil {
				p = runtime.default_assertion_failure_proc
			}
			message := fmt.tprintf(fmt_str, ..args)
			log(.Fatal, message, location=loc)
			p("unsatisfied ensure", message, loc)
		}
		internal(loc, fmt_str, ..args)
	}
}

/*
Log a message at the desired level.

Inputs:
- `level`: The level of the message
- `args`: values to be concatenated into the output
- `sep`: separator to use when concatenating
- `location`: Location of the caller
*/
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

/*
Log a formatted message at the desired level.

Inputs:
- `level`: The level of the message
- `fmt_str`: A format string, e.g. `"a: %v, b: %v"
- `args`: Arguments for the format string
- `location`: Location of the caller
*/
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
