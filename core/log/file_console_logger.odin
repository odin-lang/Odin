package log

import "core:fmt";
import "core:strings";
import "core:os";
import "core:time";

Level_Headers := [?]string{
	 0..<10 = "[DEBUG] --- ",
	10..<20 = "[INFO ] --- ",
	20..<30 = "[WARN ] --- ",
	30..<40 = "[ERROR] --- ",
	40..<50 = "[FATAL] --- ",
};

Default_Console_Logger_Opts :: Options{
	.Level,
	.Terminal_Color,
	.Short_File_Path,
	.Line,
	.Procedure,
} | Full_Timestamp_Opts;

Default_File_Logger_Opts :: Options{
	.Level,
	.Short_File_Path,
	.Line,
	.Procedure,
} | Full_Timestamp_Opts;


File_Console_Logger_Data :: struct {
	file_handle:  os.Handle,
	ident: string,
}

create_file_logger :: proc(h: os.Handle, lowest := Level.Debug, opt := Default_File_Logger_Opts, ident := "") -> Logger {
	data := new(File_Console_Logger_Data);
	data.file_handle = h;
	data.ident = ident;
	return Logger{file_console_logger_proc, data, lowest, opt};
}

destroy_file_logger :: proc(log: ^Logger) {
	data := cast(^File_Console_Logger_Data)log.data;
	if data.file_handle != os.INVALID_HANDLE do os.close(data.file_handle);
	free(data);
}

create_console_logger :: proc(lowest := Level.Debug, opt := Default_Console_Logger_Opts, ident := "") -> Logger {
	data := new(File_Console_Logger_Data);
	data.file_handle = os.INVALID_HANDLE;
	data.ident = ident;
	return Logger{file_console_logger_proc, data, lowest, opt};
}

destroy_console_logger :: proc(log: ^Logger) {
	free(log.data);
}

file_console_logger_proc :: proc(logger_data: rawptr, level: Level, text: string, options: Options, location := #caller_location) {
	data := cast(^File_Console_Logger_Data)logger_data;
	h: os.Handle = os.stdout if level <= Level.Error else os.stderr;
	if data.file_handle != os.INVALID_HANDLE {
		h = data.file_handle;
	}
	backing: [1024]byte; //NOTE(Hoej): 1024 might be too much for a header backing, unless somebody has really long paths.
	buf := strings.builder_from_slice(backing[:]);

	do_level_header(options, level, &buf);

	when time.IS_SUPPORTED {
		if Full_Timestamp_Opts & options != nil {
			fmt.sbprint(&buf, "[");
			t := time.now();
			y, m, d := time.date(t);
			h, min, s := time.clock(t);
			if .Date in options do fmt.sbprintf(&buf, "%d-%02d-%02d ", y, m, d);
			if .Time in options do fmt.sbprintf(&buf, "%02d:%02d:%02d", h, min, s);
			fmt.sbprint(&buf, "] ");
		}
	}

	do_location_header(options, &buf, location);

	if .Thread_Id in options {
		// NOTE(Oskar): not using context.thread_id here since that could be
		// incorrect when replacing context for a thread.
		fmt.sbprintf(&buf, "[{}] ", os.current_thread_id());
	}

	if data.ident != "" do fmt.sbprintf(&buf, "[%s] ", data.ident);
	//TODO(Hoej): When we have better atomics and such, make this thread-safe
	fmt.fprintf(h, "%s %s\n", strings.to_string(buf), text);
}

do_level_header :: proc(opts: Options, level: Level, str: ^strings.Builder) {

	RESET     :: "\x1b[0m";
	RED       :: "\x1b[31m";
	YELLOW    :: "\x1b[33m";
	DARK_GREY :: "\x1b[90m";

	col := RESET;
	switch level {
	case .Debug:   col = DARK_GREY;
	case .Info:    col = RESET;
	case .Warning: col = YELLOW;
	case .Error, .Fatal: col = RED;
	}

	if .Level in opts {
		if .Terminal_Color in opts do fmt.sbprint(str, col);
		fmt.sbprint(str, Level_Headers[level]);
		if .Terminal_Color in opts do fmt.sbprint(str, RESET);
	}
}

do_location_header :: proc(opts: Options, buf: ^strings.Builder, location := #caller_location) {
	if Location_Header_Opts & opts != nil do fmt.sbprint(buf, "["); else do return;

	file := location.file_path;
	if .Short_File_Path in opts {
		last := 0;
		for r, i in location.file_path {
			if r == '/' {
				last = i+1;
			}
		}
		file = location.file_path[last:];
	}

	if Location_File_Opts & opts != nil {
		fmt.sbprint(buf, file);
	}
	if .Line in opts {
		if Location_File_Opts & opts != nil {
			fmt.sbprint(buf, ":");
		}
		fmt.sbprint(buf, location.line);
	}

	if .Procedure in opts {
		if (Location_File_Opts | {.Line}) & opts != nil {
			fmt.sbprint(buf, ":");
		}
		fmt.sbprintf(buf, "%s()", location.procedure);
	}

	fmt.sbprint(buf, "] ");
}
