package odinfmt

import "core:os"
import "core:odin/tokenizer"
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

print_help :: proc(args: []string) {
	if len(args) == 0 {
		fmt.eprint("odinfmt ");
	} else {
		fmt.eprintf("%s ", args[0]);
	}
	fmt.eprintln();
}

print_arg_error :: proc(args: []string, error: flag.Flag_Error) {
	switch error {
	case .None:
		print_help(args);
	case .No_Base_Struct:
		fmt.eprintln(args[0], "no base struct");
	case .Arg_Error:
		fmt.eprintln(args[0], "argument error");
	case .Arg_Unsupported_Field_Type:
		fmt.eprintln(args[0], "argument: unsupported field type");
	case .Arg_Not_Defined:
		fmt.eprintln(args[0], "argument: no defined");
	case .Arg_Non_Optional:
		fmt.eprintln(args[0], "argument: non optional");
	case .Value_Parse_Error:
		fmt.eprintln(args[0], "argument: value parse error");
	case .Tag_Error:
		fmt.eprintln(args[0], "argument: tag error");
	}
}

format_file :: proc(filepath: string) -> (string, bool) {
	if data, ok := os.read_entire_file(filepath); ok {
		return format.format(filepath, string(data), format.default_style);
	} else {
		return "", false;
	}
}

files: [dynamic]string;

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
	init_global_temporary_allocator(mem.Megabyte * 100)

	args: Args;

	if len(os.args) < 2 {
		print_help(os.args);
		os.exit(1);
	}

	if res := flag.parse(args, os.args[1:len(os.args) - 1]); res != .None {
		print_arg_error(os.args, res);
		os.exit(1);
	}

	path := os.args[len(os.args) - 1];

	tick_time := time.tick_now();

	write_failure := false;

	if os.is_file(path) {
		if _, ok := args.write.(bool); ok {
			backup_path := strings.concatenate({path, "_bk"});
			defer delete(backup_path);

			if data, ok := format_file(path); ok {
				os.rename(path, backup_path);

				if os.write_entire_file(path, transmute([]byte)data) {
					os.remove(backup_path);
				}
			} else {
				fmt.eprintf("failed to write %v", path);
				write_failure = true;
			}
		} else {
			if data, ok := format_file(path); ok {
				fmt.println(data);
			}
		}
	} else if os.is_dir(path) {
		filepath.walk(path, walk_files);

		for file in files {

			backup_path := strings.concatenate({file, "_bk"});
			defer delete(backup_path);

			if data, ok := format_file(file); ok {

				if _, ok := args.write.(bool); ok {
					os.rename(file, backup_path);

					if os.write_entire_file(file, transmute([]byte)data) {
						os.remove(backup_path);
					}
				} else {
					fmt.println(data);
				}
			} else {
				fmt.eprintf("failed to format %v", file);
				write_failure = true;
			}
		}

		fmt.printf("formatted %v files in %vms", len(files), time.duration_milliseconds(time.tick_lap_time(&tick_time)));
	} else {
		fmt.eprintf("%v is neither a directory nor a file \n", path);
		os.exit(1);
	}

	os.exit(1 if write_failure else 0);
}
