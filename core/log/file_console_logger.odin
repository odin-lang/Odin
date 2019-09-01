package log

import "core:fmt";
import "core:strings";
import "core:os";
import "core:time";

Level_Headers := []string{
    "[DEBUG] --- ",
    "[INFO ] --- ",
    "[WARN ] --- ",
    "[ERROR] --- ",
    "[FATAL] --- ",
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
    lowest_level: Level,
    file_handle:  os.Handle,
    ident : string,
}

create_file_logger :: proc(h: os.Handle, lowest := Level.Debug, opt := Default_File_Logger_Opts, ident := "") -> Logger {
    data := new(File_Console_Logger_Data);
    data.lowest_level = lowest;
    data.file_handle = h;
    data.ident = ident;
    return Logger{file_console_logger_proc, data, opt};
}

destroy_file_logger ::proc(log : ^Logger) {
    data := cast(^File_Console_Logger_Data)log.data;
    if data.file_handle != os.INVALID_HANDLE do os.close(data.file_handle);
    free(data);
    log^ = nil_logger();
}

create_console_logger :: proc(lowest := Level.Debug, opt := Default_Console_Logger_Opts, ident := "") -> Logger {
    data := new(File_Console_Logger_Data);
    data.lowest_level = lowest;
    data.file_handle = os.INVALID_HANDLE;
    data.ident = ident;
    return Logger{file_console_logger_proc, data, opt};
}

destroy_console_logger ::proc(log : ^Logger) {
    free(log.data);
    log^ = nil_logger();
}

file_console_logger_proc :: proc(logger_data: rawptr, level: Level, text: string, options: Options, location := #caller_location) {
    data := cast(^File_Console_Logger_Data)logger_data;
    if level < data.lowest_level do return;

    h : os.Handle;
    if(data.file_handle != os.INVALID_HANDLE) do h = data.file_handle;
    else                                      do h = level <= Level.Error ? context.stdout : context.stderr;
    backing: [1024]byte; //NOTE(Hoej): 1024 might be too much for a header backing, unless somebody has really long paths.
    buf := strings.builder_from_slice(backing[:]);

    do_level_header(options, level, &buf);

    when time.IS_SUPPORTED {
        if Full_Timestamp_Opts & options != nil {
            fmt.sbprint(&buf, "[");
            t := time.now();
            y, m, d := time.date(t);
            h, min, s := time.clock(t);
            if Option.Date in options do fmt.sbprintf(&buf, "%d-%02d-%02d ", y, m, d);
            if Option.Time in options do fmt.sbprintf(&buf, "%02d:%02d:%02d", h, min, s);
            fmt.sbprint(&buf, "] ");
        }
    }

    do_location_header(options, &buf, location);

    if data.ident != "" do fmt.sbprintf(&buf, "[%s] ", data.ident);
    //TODO(Hoej): When we have better atomics and such, make this thread-safe
    fmt.fprintf(h, "%s %s\n", strings.to_string(buf), text);
}

do_level_header :: proc(opts : Options, level : Level, str : ^strings.Builder) {

    RESET     :: "\x1b[0m";
    RED       :: "\x1b[31m";
    YELLOW    :: "\x1b[33m";
    DARK_GREY :: "\x1b[90m";

    col := RESET;
    switch level {
    case Level.Debug              : col = DARK_GREY;
    case Level.Info               : col = RESET;
    case Level.Warning            : col = YELLOW;
    case Level.Error, Level.Fatal : col = RED;
    }

    if .Level in opts {
        if .Terminal_Color in opts do fmt.sbprint(str, col);
        fmt.sbprint(str, Level_Headers[level]);
        if .Terminal_Color in opts do fmt.sbprint(str, RESET);
    }
}

do_location_header :: proc(opts : Options, buf : ^strings.Builder, location := #caller_location) {
    if Location_Header_Opts & opts != nil do fmt.sbprint(buf, "["); else do return;

    file := location.file_path;
    if .Short_File_Path in opts {
        when os.OS == "windows" do delimiter := '\\'; else do delimiter := '/';
        last := 0;
        for r, i in location.file_path do if r == delimiter do last = i+1;
        file = location.file_path[last:];
    }

    if Location_File_Opts & opts != nil do fmt.sbprint(buf, file);

    if .Procedure in opts {
        if Location_File_Opts & opts != nil do fmt.sbprint(buf, ".");
        fmt.sbprintf(buf, "%s()", location.procedure);
    }

    if .Line in opts {
        if Location_File_Opts & opts != nil || .Procedure in opts do fmt.sbprint(buf, ":");
        fmt.sbprint(buf, location.line);
    }

    fmt.sbprint(buf, "] ");
}
