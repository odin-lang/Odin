#+build !freestanding
#+build !orca
package log

import "core:encoding/ansi"
import "core:fmt"
import "core:strings"
import "core:os"
import "core:os/os2"
import "core:time"

import "base:runtime"

Level_Headers := [?]string{
	 0..<10 = "[DEBUG] --- ",
	10..<20 = "[INFO ] --- ",
	20..<30 = "[WARN ] --- ",
	30..<40 = "[ERROR] --- ",
	40..<50 = "[FATAL] --- ",
}

Default_Console_Logger_Opts :: Options{
	.Level,
	.Terminal_Color,
	.Short_File_Path,
	.Line,
	.Procedure,
} | Full_Timestamp_Opts

Default_File_Logger_Opts :: Options{
	.Level,
	.Short_File_Path,
	.Line,
	.Procedure,
} | Full_Timestamp_Opts

@private
File_Type :: enum {
	console,
	os,
	os2,
}

/*
	Implements a logger that writes to a file stream, such as stdout, or a file on the system.
	
	This logger is compatible both with `os` and `os2`.
	- To make a logger that writes to an `os.Handle` refer to `make_file_logger_os`
	- To make a logger that writes to an `^os2.File` refer to `make_file_logger_os2`
	- To make a logger that writes to `stdout` and `stderr` refer to `make_console_logger`
*/
File_Console_Logger_Data :: struct {
	type: File_Type,
	file_handle_os: os.Handle,
	file_handle_os2: ^os2.File,
	ident: string,
	close_file_on_delete: bool,
	allocator: runtime.Allocator,
}

/*
Makes a new logger that will write to the provided `os.Handle`

*Allocates Using Provided Allocator*

Inputs:
- h: An os handle that the logger will write to
- lowest: The lowest level logging to accept
- opt: The wanted logging options
- ident: An identifier that will be written alongside the logged message
- close_file_on_delete: Sets the logger to close the handle when delete_file_logger is called if `true`
- allocator: (default: context.allocator)
- loc: The caller location for debugging purposes (default: `#caller_location`)

Returns:
- res: The new file logger 
- res: An allocator error if one occured, `nil` otherwise 
*/
make_file_logger_os :: proc(h: os.Handle, lowest := Level.Debug, opt := Default_File_Logger_Opts, ident := "", close_file_on_delete := false, allocator := context.allocator, loc := #caller_location) -> (res: Logger, err: runtime.Allocator_Error) {
	data := new(File_Console_Logger_Data, allocator, loc) or_return
	data.type = .os
	data.file_handle_os = h
	data.ident = ident
	data.allocator = allocator
	data.close_file_on_delete = close_file_on_delete
	return Logger{file_console_logger_proc, data, lowest, opt}, nil
}

/*
Makes a new logger that will write to the provided `^os2.File`

*Allocates Using Provided Allocator*

Inputs:
- f: An os2 file that the logger will write to
- lowest: The lowest level logging to accept
- opt: The wanted logging options
- ident: An identifier that will be written alongside the logged message
- close_file_on_delete: Sets the logger to close the file when delete_file_logger is called if `true`
- allocator: (default: context.allocator)
- loc: The caller location for debugging purposes (default: `#caller_location`)

Returns:
- res: The new file logger 
- res: An allocator error if one occured, `nil` otherwise 
*/
make_file_logger_os2 :: proc(f: ^os2.File, lowest := Level.Debug, opt := Default_File_Logger_Opts, ident := "", close_file_on_delete := false, allocator := context.allocator, loc := #caller_location) -> (res: Logger, err: runtime.Allocator_Error) {
	data := new(File_Console_Logger_Data, allocator, loc) or_return
	data.type = .os2
	data.file_handle_os2 = f
	data.ident = ident
	data.allocator = allocator
	data.close_file_on_delete = close_file_on_delete
	return Logger{file_console_logger_proc, data, lowest, opt}, nil
}
make_file_logger :: proc {
	make_file_logger_os,
	make_file_logger_os2,
}

/*
Makes a new logger that will write to `stdout` and `stderr`. `Stdout` will be written to
if the log level is below `Level.Error`, otherwise `stderr` will be written to

*Allocates Using Provided Allocator*

Inputs:
- lowest: The lowest level logging to accept
- opt: The wanted logging options
- ident: An identifier that will be written alongside the logged message
- allocator: (default: context.allocator)
- loc: The caller location for debugging purposes (default: `#caller_location`)

Returns:
- res: The new file logger 
- res: An allocator error if one occured, `nil` otherwise 
*/
make_console_logger :: proc(lowest := Level.Debug, opt := Default_File_Logger_Opts, ident := "", allocator := context.allocator, loc := #caller_location) -> (res: Logger, err: runtime.Allocator_Error) {
	data := new(File_Console_Logger_Data, allocator, loc) or_return
	data.type = .console
	data.ident = ident
	data.allocator = allocator
	return Logger{file_console_logger_proc, data, lowest, opt}, nil
}

@(deprecated = "Use make_file_logger instead")
create_file_logger :: proc(h: os.Handle, lowest := Level.Debug, opt := Default_File_Logger_Opts, ident := "") -> (Logger) {
	logger, _ := make_file_logger(h, lowest, opt, ident, true, context.allocator)
	return logger
}

@(deprecated = "Use make_console_logger instead")
create_console_logger :: proc(lowest := Level.Debug, opt := Default_Console_Logger_Opts, ident := "") -> Logger {
	logger, _ := make_file_logger(os.INVALID_HANDLE, lowest, opt, ident, true, context.allocator)
	return logger
}

/*
Deletes a logger made with `make_console_logger` and `make_file_logger`.
If a logger was created with `make_file_logger` and `close_file_on_delete` was
set to true then the logger will try to close the file handle it was provided.

Inputs:
- log: The logger to delete
*/
delete_console_logger :: proc(log: Logger) {
	data := cast(^File_Console_Logger_Data)log.data
	if data.close_file_on_delete {
		switch data.type {
		case .console:
		case .os: os.close(data.file_handle_os)
		case .os2: os2.close(data.file_handle_os2)
		}
	}
	free(data, data.allocator)
}
@(deprecated = "Use delete_console_logger instead")
destroy_console_logger :: proc(log: Logger) {
	delete_console_logger(log)
}
@(deprecated = "Use delete_file_logger instead")
destroy_file_logger :: proc(log: Logger) {
	delete_file_logger(log)
}
delete_file_logger :: delete_console_logger

file_console_logger_proc :: proc(logger_data: rawptr, level: Level, text: string, options: Options, location := #caller_location) {
	data := cast(^File_Console_Logger_Data)logger_data
	backing: [1024]byte //NOTE(Hoej): 1024 might be too much for a header backing, unless somebody has really long paths.
	buf := strings.builder_from_bytes(backing[:])

	do_level_header(options, &buf, level)

	when time.IS_SUPPORTED {
		do_time_header(options, &buf, time.now())
	}

	do_location_header(options, &buf, location)

	if .Thread_Id in options {
		// NOTE(Oskar): not using context.thread_id here since that could be
		// incorrect when replacing context for a thread.
		fmt.sbprintf(&buf, "[{}] ", os.current_thread_id())
	}

	if data.ident != "" {
		fmt.sbprintf(&buf, "[%s] ", data.ident)
	}

	//TODO(Hoej): When we have better atomics and such, make this thread-safe
	switch data.type {
	case .console: fmt.fprintf(level < Level.Error ? os.stdout : os.stderr, "%s%s\n", strings.to_string(buf), text)
	case .os: fmt.fprintf(data.file_handle_os, "%s%s\n", strings.to_string(buf), text)
	case .os2: fmt.wprintf(data.file_handle_os2.stream, "%s%s\n", strings.to_string(buf), text)
	}
}

do_level_header :: proc(opts: Options, str: ^strings.Builder, level: Level) {

	RESET     :: ansi.CSI + ansi.RESET           + ansi.SGR
	RED       :: ansi.CSI + ansi.FG_RED          + ansi.SGR
	YELLOW    :: ansi.CSI + ansi.FG_YELLOW       + ansi.SGR
	DARK_GREY :: ansi.CSI + ansi.FG_BRIGHT_BLACK + ansi.SGR

	col := RESET
	switch level {
	case .Debug:   col = DARK_GREY
	case .Info:    col = RESET
	case .Warning: col = YELLOW
	case .Error, .Fatal: col = RED
	}

	if .Level in opts {
		if .Terminal_Color in opts {
			fmt.sbprint(str, col)
		}
		fmt.sbprint(str, Level_Headers[level])
		if .Terminal_Color in opts {
			fmt.sbprint(str, RESET)
		}
	}
}

do_time_header :: proc(opts: Options, buf: ^strings.Builder, t: time.Time) {
	when time.IS_SUPPORTED {
		if Full_Timestamp_Opts & opts != nil {
			fmt.sbprint(buf, "[")
			y, m, d := time.date(t)
			h, min, s := time.clock(t)
			if .Date in opts {
				fmt.sbprintf(buf, "%d-%02d-%02d", y, m, d)
				if .Time in opts {
					fmt.sbprint(buf, " ")
				}
			}
			if .Time in opts { fmt.sbprintf(buf, "%02d:%02d:%02d", h, min, s) }
			fmt.sbprint(buf, "] ")
		}
	}
}

do_location_header :: proc(opts: Options, buf: ^strings.Builder, location := #caller_location) {
	if Location_Header_Opts & opts == nil {
		return
	}
	fmt.sbprint(buf, "[")

	file := location.file_path
	if .Short_File_Path in opts {
		last := 0
		for r, i in location.file_path {
			if r == '/' {
				last = i+1
			}
		}
		file = location.file_path[last:]
	}

	if Location_File_Opts & opts != nil {
		fmt.sbprint(buf, file)
	}
	if .Line in opts {
		if Location_File_Opts & opts != nil {
			fmt.sbprint(buf, ":")
		}
		fmt.sbprint(buf, location.line)
	}

	if .Procedure in opts {
		if (Location_File_Opts | {.Line}) & opts != nil {
			fmt.sbprint(buf, ":")
		}
		fmt.sbprintf(buf, "%s()", location.procedure)
	}

	fmt.sbprint(buf, "] ")
}
