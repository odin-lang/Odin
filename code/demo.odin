#foreign_system_library "winmm" when ODIN_OS == "windows";
#import win32 "sys/windows.odin" when ODIN_OS == "windows";
#import "fmt.odin";

timeGetTime :: proc() -> u32 #foreign #dll_import
GetSystemTimeAsFileTime :: proc(SystemTimeAsFileTime : ^win32.FILETIME) #foreign #dll_import

GetCommandLineArguments :: proc() -> []string {
    argString := win32.GetCommandLineA();
    fullArgString := to_odin_string(argString);
    // Count Spaces
    for r : fullArgString {
        fmt.println(r);
    }
}

to_odin_string :: proc(c: ^byte) -> string {
    s: string;
    s.data = c;
    while (c + s.count)^ != 0 {
        s.count += 1;
    }
    return s;
}
//("Hellope!\x00" as string).data

MAGIC_VALUE :: 0xCA5E713F;

timing_file_header :: struct #ordered {
    MagicValue : u32;
}

timing_file_date :: struct #ordered {
    E : [2]u32;
}

timing_file_entry_flag :: enum {
    Complete = 0x1,
    NoErrors = 0x2,
}

timing_file_entry :: struct #ordered {
    StarDate : timing_file_date;
    Flags : u32;
    MillisecondsElapsed : u32;
}

timing_entry_array :: struct #ordered {
    Entries : []timing_file_entry;
}

GetClock :: proc () -> u32 {
    return timeGetTime();
}

GetDate :: proc() -> timing_file_date {
    Result : timing_file_date;
    FileTime : win32.FILETIME;
    GetSystemTimeAsFileTime(^FileTime);

    Result.E[0] = FileTime.lo;
    Result.E[1] = FileTime.hi;

    return Result;
}

main :: proc () {
    EntryClock := GetClock();
    GetCommandLineArguments();
}
