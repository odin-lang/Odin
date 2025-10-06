#+build !freestanding
#+build !orca
package log

import "base:runtime"
import "core:fmt"
import "core:strings"
import "core:os"
import "core:terminal"
import "core:terminal/ansi"
import "core:time"

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


File_Console_Logger_Data :: struct {
	file_handle:  os.Handle,
	ident: string,
}

@(private) global_subtract_stdout_options: Options
@(private) global_subtract_stderr_options: Options

@(init, private)
init_standard_stream_status :: proc "contextless" () {
	// NOTE(Feoramund): While it is technically possible for these streams to
	// be redirected during the runtime of the program, the cost of checking on
	// every single log message is not worth it to support such an
	// uncommonly-used feature.
	if terminal.color_enabled {
		context = runtime.default_context()

		// This is done this way because it's possible that only one of these
		// streams could be redirected to a file.
		if !terminal.is_terminal(os.stdout) {
			global_subtract_stdout_options = {.Terminal_Color}
		}
		if !terminal.is_terminal(os.stderr) {
			global_subtract_stderr_options = {.Terminal_Color}
		}
	} else {
		// Override any terminal coloring.
		global_subtract_stdout_options = {.Terminal_Color}
		global_subtract_stderr_options = {.Terminal_Color}
	}
}

create_file_logger :: proc(h: os.Handle, lowest := Level.Debug, opt := Default_File_Logger_Opts, ident := "", allocator := context.allocator) -> Logger {
	data := new(File_Console_Logger_Data, allocator)
	data.file_handle = h
	data.ident = ident
	return Logger{file_logger_proc, data, lowest, opt}
}

destroy_file_logger :: proc(log: Logger, allocator := context.allocator) {
	data := cast(^File_Console_Logger_Data)log.data
	if data.file_handle != os.INVALID_HANDLE {
		os.close(data.file_handle)
	}
	free(data, allocator)
}

create_console_logger :: proc(lowest := Level.Debug, opt := Default_Console_Logger_Opts, ident := "", allocator := context.allocator) -> Logger {
	data := new(File_Console_Logger_Data, allocator)
	data.file_handle = os.INVALID_HANDLE
	data.ident = ident
	return Logger{console_logger_proc, data, lowest, opt}
}

destroy_console_logger :: proc(log: Logger, allocator := context.allocator) {
	free(log.data, allocator)
}

@(private)
_file_console_logger_proc :: proc(h: os.Handle, ident: string, level: Level, text: string, options: Options, location: runtime.Source_Code_Location) {
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

	if ident != "" {
		fmt.sbprintf(&buf, "[%s] ", ident)
	}
	//TODO(Hoej): When we have better atomics and such, make this thread-safe
	fmt.fprintf(h, "%s%s\n", strings.to_string(buf), text)
}

file_logger_proc :: proc(logger_data: rawptr, level: Level, text: string, options: Options, location := #caller_location) {
	data := cast(^File_Console_Logger_Data)logger_data
	_file_console_logger_proc(data.file_handle, data.ident, level, text, options, location)
}

console_logger_proc :: proc(logger_data: rawptr, level: Level, text: string, options: Options, location := #caller_location) {
	options := options
	data := cast(^File_Console_Logger_Data)logger_data
	h: os.Handle = ---
	if level < Level.Error {
		h = os.stdout
		options -= global_subtract_stdout_options
	} else {
		h = os.stderr
		options -= global_subtract_stderr_options
	}
	_file_console_logger_proc(h, data.ident, level, text, options, location)
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
