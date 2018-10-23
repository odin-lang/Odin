package log

import "core:fmt";
import "core:os";

Level_Headers := []string{
    "[DEBUG] --- ",
    "[INFO ] --- ",
    "[WARN ] --- ",
    "[ERROR] --- ",
    "[FATAL] --- ",
};

Default_Console_Logger_Opts :: Options{
    Option.Level, 
    Option.Terminal_Color,
    Option.Short_File_Path,
    Option.Line, 
    Option.Procedure, 
} | Full_Timestamp_Opts;

Default_File_Logger_Opts :: Options{
    Option.Level, 
    Option.Short_File_Path,
    Option.Line, 
    Option.Procedure, 
} | Full_Timestamp_Opts;


File_Console_Logger_Data :: struct {
    lowest_level: Level,
    file_handle:  os.Handle,
}

file_logger :: proc(h: os.Handle, lowest := Level.Debug, opt := Default_File_Logger_Opts, ident := "") -> Logger {
    data := new(File_Console_Logger_Data);
    data.lowest_level = lowest;
    data.file_handle = h;
    return Logger{file_console_logger_proc, data, opt, ident};
}
 
console_logger :: proc(lowest := Level.Debug, opt := Default_Console_Logger_Opts, ident := "") -> Logger {
    data := new(File_Console_Logger_Data);
    data.lowest_level = lowest;
    data.file_handle = os.INVALID_HANDLE;
    return Logger{file_console_logger_proc, data, opt, ident};
}

file_console_logger_proc :: proc(logger_data: rawptr, level: Level, ident: string, text: string, options: Options, location := #caller_location) {
    data := cast(^File_Console_Logger_Data)logger_data;
    if level < data.lowest_level do return;

    h : os.Handle;
    if(data.file_handle != os.INVALID_HANDLE) do h = data.file_handle;
    else                                      do h = level <= Level.Error ? os.stdout : os.stderr;
    backing: [1024]byte; //NOTE(Hoej): 1024 might be too much for a header backing, unless somebody has really long paths.
    buf := fmt.string_buffer_from_slice(backing[:]);
    
    do_level_header(options, level, &buf);


    /*if Full_Timestamp_Opts & options != nil {
        time := os.get_current_system_time();
        if Option.Date in options do fmt.sbprintf(&buf, "%d-%d-%d ", time.year, time.month, time.day);
        if Option.Time in options do fmt.sbprintf(&buf, "%d:%d:%d ", time.hour, time.minute, time.second);
    }
*/
    do_location_header(options, &buf, location);

    if ident != "" do fmt.sbprintf(&buf, "[%s] ", ident);
    //TODO(Hoej): When we have better atomics and such, make this thread-safe
    fmt.fprintf(h, "%s %s\n", fmt.to_string(buf), text); 
}

do_level_header :: proc(opts : Options, level : Level, buf : ^fmt.String_Buffer) {

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

    if Option.Level in opts {
        if Option.Terminal_Color in opts do fmt.sbprint(buf, col);
        fmt.sbprint(buf, Level_Headers[level]);
        if Option.Terminal_Color in opts do fmt.sbprint(buf, RESET);
    }
}

do_location_header :: proc(opts : Options, buf : ^fmt.String_Buffer, location := #caller_location) {
    if Location_Header_Opts & opts != nil do fmt.sbprint(buf, "["); else do return;

    file := location.file_path;
    if Option.Short_File_Path in opts {
        when os.OS == "windows" do delimiter := '\\'; else do delimiter := '/'; 
        last := 0;
        for r, i in location.file_path do if r == delimiter do last = i+1;
        file = location.file_path[last:];
    }

    if Location_File_Opts & opts != nil do fmt.sbprint(buf, file);

    if Option.Procedure in opts {
        if Location_File_Opts & opts != nil do fmt.sbprint(buf, ".");
        fmt.sbprintf(buf, "%s()", location.procedure);
    }

    if Option.Line in opts {
        if Location_File_Opts & opts != nil || Option.Procedure in opts do fmt.sbprint(buf, ":");
        fmt.sbprint(buf, location.line);
    }

    fmt.sbprint(buf, "] ");
}