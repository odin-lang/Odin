#+build !freestanding
#+build !orca
package log

import "core:encoding/ansi"
import "core:fmt"
import "core:strings"
import "core:os"
import "core:time"

/*
Strings to output when `.Level` is included in the logger options.
*/
Level_Headers := [?]string{
	 0..<10 = "[DEBUG] --- ",
	10..<20 = "[INFO ] --- ",
	20..<30 = "[WARN ] --- ",
	30..<40 = "[ERROR] --- ",
	40..<50 = "[FATAL] --- ",
}

/*
The default option set for a console logger.

It is similar to the file logger default option set, but the output includes colors.

When you use this set of options you can expect the following output:

	[LEVEL] --- [YYYY-MM-DD HH:MM:SS] [file.odin:L:proc()] Message

For example:

	[INFO ] --- [2025-01-02 12:34:56] [main.odin:8:main()] Hello World!
*/
Default_Console_Logger_Opts :: Options{
	.Level,
	.Terminal_Color,
	.Short_File_Path,
	.Line,
	.Procedure,
} | Full_Timestamp_Opts

/*
The default option set for a file logger.

It is similar to the console logger default option set, but the output is not colored.

When you use this set of options you can expect the following output:

	[LEVEL] --- [YYYY-MM-DD HH:MM:SS] [file.odin:L:proc()] Message

For example:

	[INFO ] --- [2025-01-02 12:34:56] [main.odin:8:main()] Hello World!
*/
Default_File_Logger_Opts :: Options{
	.Level,
	.Short_File_Path,
	.Line,
	.Procedure,
} | Full_Timestamp_Opts

/*
Data backing a file or console logger.
*/
File_Console_Logger_Data :: struct {
	// Handle to the file or `os.INVALID_HANDLE` for console
	file_handle:  os.Handle,
	// Identifier to include in the output
	ident: string,
}

/*
Create a logger that outputs to a file.

When no longer needed can be destroyed with `destroy_file_logger`.

Inputs:
- `h`: A handle to the output file
- `lowest`: Log level to use
- `opt`: Specifies additional data present in the log output
- `ident`: Identifier to include in the output
- `allocator`: Allocator to use for data backing the logger
*/
create_file_logger :: proc(h: os.Handle, lowest := Level.Debug, opt := Default_File_Logger_Opts, ident := "", allocator := context.allocator) -> Logger {
	data := new(File_Console_Logger_Data, allocator)
	data.file_handle = h
	data.ident = ident
	return Logger{file_console_logger_proc, data, lowest, opt}
}

/*
Destroy a logger created with `create_file_logger` and close the file handle.

Inputs:
- `log`: Logger created with `create_file_logger`
- `allocator`: Allocator passed to `create_file_logger`
*/
destroy_file_logger :: proc(log: Logger, allocator := context.allocator) {
	data := cast(^File_Console_Logger_Data)log.data
	if data.file_handle != os.INVALID_HANDLE {
		os.close(data.file_handle)
	}
	free(data, allocator)
}

/*
Create a logger that outputs to the terminal.

When no longer needed can be destroyed with `destroy_console_logger`.

Inputs:
- `lowest`: Log level to use
- `opt`: Specifies additional data present in the log output
- `ident`: Identifier to include in the output
- `allocator`: Allocator to use for data backing the logger
*/
create_console_logger :: proc(lowest := Level.Debug, opt := Default_Console_Logger_Opts, ident := "", allocator := context.allocator) -> Logger {
	data := new(File_Console_Logger_Data, allocator)
	data.file_handle = os.INVALID_HANDLE
	data.ident = ident
	return Logger{file_console_logger_proc, data, lowest, opt}
}

/*
Destroy a logger created with `create_console_logger`.

Inputs:
- `log`: Logger created with `create_console_logger`
- `allocator`: Allocator passed to `create_console_logger`
*/
destroy_console_logger :: proc(log: Logger, allocator := context.allocator) {
	free(log.data, allocator)
}

/*
Backing procedure for file and console loggers.
*/
file_console_logger_proc :: proc(logger_data: rawptr, level: Level, text: string, options: Options, location := #caller_location) {
	data := cast(^File_Console_Logger_Data)logger_data
	h: os.Handle = os.stdout if level <= Level.Error else os.stderr
	if data.file_handle != os.INVALID_HANDLE {
		h = data.file_handle
	}
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
	fmt.fprintf(h, "%s%s\n", strings.to_string(buf), text)
}

/*
Helper used to build the part of the message including the log level.
*/
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

/*
Helper used to build the part of the message including the data and time.
*/
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

/*
Helper used to build the part of the message including the file location.
*/
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
