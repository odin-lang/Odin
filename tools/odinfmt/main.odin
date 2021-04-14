package odinfmt

import "core:os"
import "core:odin/format"
import "core:fmt"
import "core:strings"
import "core:path/filepath"
import "core:time"
import "core:mem"

import "flag"

Args :: struct {
    write: Maybe(bool) `flag:"w" usage:"write the new format to file"`,
}

print_help :: proc() {

}

print_arg_error :: proc(error: flag.Flag_Error) {
    fmt.println(error);
}

format_file :: proc(filepath: string) -> ([] u8, bool) {

    if data, ok := os.read_entire_file(filepath); ok {
        return format.format(data, format.default_style);
    }

    else {
        return {}, false;
    }

}

files: [dynamic] string;

walk_files :: proc(info: os.File_Info, in_err: os.Errno) -> (err: os.Errno, skip_dir: bool) {

    if info.is_dir {
        return 0, false;
    }

    if filepath.ext(info.name) != ".odin" {
        return 0, false;
    }

    append(&files, strings.clone(info.fullpath));

    return 0, false;
}

main :: proc() {

    init_global_temporary_allocator(mem.megabytes(100));

    args: Args;

    if len(os.args) < 2 {
        print_help();
        os.exit(1);
    }

    if res := flag.parse(args, os.args[1:len(os.args)-1]); res != .None {
        print_arg_error(res);
        os.exit(1);
    }

    path := os.args[len(os.args)-1];

    tick_time := time.tick_now();

    if os.is_file(path) {

        if _, ok := args.write.(bool); ok {

            backup_path := strings.concatenate({path, "_bk"}, context.temp_allocator);

            if data, ok := format_file(path); ok {

                 os.rename(path, backup_path);

                if os.write_entire_file(path, data) {
                    os.remove(backup_path);
                }

            }

            else {
                fmt.eprintf("failed to write %v", path);
            }

        }

        else {

            if data, ok := format_file(path); ok {
                fmt.println(transmute(string)data);
            }

        }

    }

    else if os.is_dir(path) {

        filepath.walk(path, walk_files);

        for file in files {

            fmt.println(file);

            backup_path := strings.concatenate({file, "_bk"}, context.temp_allocator);

            if data, ok := format_file(file); ok {

                if _, ok := args.write.(bool); ok {
                    os.rename(file, backup_path);

                    if os.write_entire_file(file, data) {
                        os.remove(backup_path);
                    }
                }

                else {
                    fmt.println(transmute(string)data);
                }


            } else {
                fmt.eprintf("failed to format %v", file);
            }

            free_all(context.temp_allocator);
        }

        fmt.printf("formatted %v files in %vms", len(files), time.duration_milliseconds(time.tick_lap_time(&tick_time)));

    }

    else{
        fmt.eprintf("%v is neither a directory nor a file \n", path);
        os.exit(1);
    }

    os.exit(0);
}