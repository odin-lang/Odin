/*
A minimal archive tool on `core:archive`: lists a zip archive, tests it, unpacks one member, or
creates or updates an archive.

Build it with `odin build core/archive/example -out:mini`, then run:

	mini list   <archive>             lists the format and the members: sizes, methods, times
	                                  and CRC-32s
	mini test   <archive>             decompresses every member and checks its CRC-32
	mini unpack <archive> <path>      writes one member to the current directory, under its
	                                  base name, unless a file of that name exists
	mini create <archive> <path>...   packs files and directory trees into a new archive, with
	                                  the format's default options, unless the archive exists
	mini update <archive> <path>...   adds files and directory trees to a zip archive,
	                                  replacing the members it has at the same paths
	mini -help                        shows the usage

`archive.open` tells the formats apart by their contents, self-extracting zip archives included.
A format's package registers it with `core:archive` when imported.

Reading goes through `core:archive`, which has no writers, so `create` and `update` call the
format's own package. `create` takes the format from the name, which must end in `.zip`, and
`update` from the archive's contents.

`core:archive` reads encrypted zip archives, but this tool takes no password. A program passes
one in `archive.Read_Options` to `archive.extract` or `archive.extract_current`. Without one,
encrypted members are listed but don't test or unpack.
*/
package mini

import "core:archive"
import "core:archive/zip"
import "core:flags"
import "core:fmt"
import "core:io"
import "core:os"
import "core:strings"
import "core:time"

Command :: enum {
	list,
	test,
	unpack,
	create,
	update,
}

Options :: struct {
	command:  Command `args:"pos=0,required"`,
	archive:  string  `args:"pos=1,required"`,
	overflow: [dynamic]string,
}

USAGE :: `usage:
  mini list   <archive>             lists the format and the members: sizes, methods, times
                                    and CRC-32s
  mini test   <archive>             decompresses every member and checks its CRC-32
  mini unpack <archive> <path>      writes one member to the current directory, under its
                                    base name, unless a file of that name exists
  mini create <archive> <path>...   packs files and directory trees into a new archive, with
                                    the format's default options, unless the archive exists
  mini update <archive> <path>...   adds files and directory trees to a zip archive,
                                    replacing the members it has at the same paths
  mini -help                        shows the usage
`

main :: proc() {
	options: Options
	flags.register_flag_checker(check_paths)
	if err := flags.parse(&options, os.args[1:]); err != nil {
		usage(err)
	}
	paths := options.overflow[:]

	if options.command == .create || options.command == .update {
		if !pack(options.archive, paths, options.command == .update) {
			os.exit(1)
		}
		return
	}
	a, err := archive.open(options.archive)
	if err != nil {
		fmt.eprintfln("%v: %v", options.archive, err)
		os.exit(1)
	}
	ok := false
	#partial switch options.command {
	case .list:   ok = list(&a)
	case .test:   ok = test(&a)
	case .unpack: ok = unpack(&a, paths[0])
	}
	archive.close(&a)
	if !ok {
		os.exit(1)
	}
}

usage :: proc(err: flags.Error) -> ! {
	if _, help := err.(flags.Help_Request); help {
		fmt.print(USAGE)
		os.exit(0)
	}
	fmt.eprint(USAGE)
	if len(os.args) > 1 {
		flags.print_errors(Options, err, os.args[0])
	}
	os.exit(2)
}

check_paths :: proc(model: rawptr, name: string, value: any, args_tag: string) -> (error: string) {
	options := (^Options)(model)
	if name != "command" {
		return ""
	}
	switch options.command {
	case .list, .test:
		if len(options.overflow) != 0 {
			return "`list` and `test` take only the archive."
		}
	case .unpack:
		if len(options.overflow) != 1 {
			return "`unpack` takes one member's path."
		}
	case .create, .update:
		if len(options.overflow) == 0 {
			return "`create` and `update` take one or more files or directories."
		}
	}
	return ""
}

list :: proc(a: ^archive.Archive) -> bool {
	info := archive.info(a)
	fmt.printfln("%v archive", info.format)
	if info.comment != "" {
		fmt.println(info.comment)
	}
	fmt.println("  Length    Packed  Method            Date        Time      CRC-32    Name")
	fmt.println("--------  --------  ----------------  ----------  --------  --------  ----")
	count, size: i64
	it := archive.iterator_create(a)
	defer archive.iterator_destroy(&it)
	for fi in archive.iterate(&it) {
		date: [time.MIN_YYYY_DATE_LEN]u8
		clock: [time.MIN_HMS_LEN]u8
		crc, has_crc := fi.crc32.?
		fmt.printfln("%8d  %8s  %-16s  %s  %s  %8s  %s%s%s",
			fi.size, fmt.tprint(fi.compressed_size) if fi.compressed_size >= 0 else "-",
			method_name(fi, info.compression if info.format == .Tar else fi.method),
			time.to_string_yyyy_mm_dd(fi.modification_time, date[:]), time.to_string_hms(fi.modification_time, clock[:]),
			fmt.tprintf("%08x", crc) if has_crc else "-", fi.path,
			"/" if fi.type == .Directory else "", fmt.tprintf(" -> %s", fi.link_target) if fi.link_target != "" else "")
		count += 1
		size  += fi.size
	}
	if path, iterate_err := archive.iterator_error(&it); iterate_err != nil {
		fmt.eprintfln("%v: %v", path, iterate_err)
		return false
	}
	fmt.printfln("%d members, %d bytes", count, size)
	return true
}

test :: proc(a: ^archive.Archive) -> bool {
	failed := 0
	it := archive.iterator_create(a)
	defer archive.iterator_destroy(&it)
	for fi in archive.iterate(&it) {
		sink: io.Counting_Stream
		if err := archive.extract_current(&it, io.counting_stream_init(&sink, {})); err != nil {
			fmt.printfln("    testing: %-40s  %v", fi.path, err)
			failed += 1
		} else {
			fmt.printfln("    testing: %-40s  OK", fi.path)
		}
	}
	if path, err := archive.iterator_error(&it); err != nil {
		fmt.printfln("    error:   %-40s  %v", path, err)
		failed += 1
	}
	if failed == 0 {
		fmt.println("No errors detected.")
	} else {
		fmt.printfln("%d errors detected.", failed)
	}
	return failed == 0
}

unpack :: proc(a: ^archive.Archive, path: string) -> bool {
	fi, handle, found, err := archive.find(a, path)
	if !found {
		if err == nil {
			err = archive.General_Error.Not_Found
		}
		fmt.eprintfln("%v: %v", path, err)
		return false
	}
	name := os.base(fi.path)
	if fi.type != .Regular || archive.check_member_path(name) != nil {
		fmt.eprintfln("%v: not a file that can be unpacked here", fi.path)
		return false
	}
	f, open_err := os.open(name, {.Write, .Create, .Excl}, os.Permissions_Default_File)
	if open_err != nil {
		fmt.eprintfln("%v: %v", name, open_err)
		return false
	}
	err = archive.extract(a, handle, os.to_stream(f))
	if close_err := os.close(f); err == nil && close_err != nil {
		err = close_err
	}
	if err != nil {
		os.remove(name)
		fmt.eprintfln("%v: %v", fi.path, err)
		return false
	}
	fmt.printfln("unpacked %v: %d bytes", name, fi.size)
	return true
}

pack :: proc(path: string, sources: []string, update: bool) -> bool {
	format := archive.Format.Unknown
	switch {
	case update:
		a, err := archive.open(path)
		if err != nil {
			fmt.eprintfln("%v: %v", path, err)
			return false
		}
		format = a.format
		archive.close(&a)
	case os.exists(path):
		fmt.eprintfln("%v: %v", path, archive.General_Error.Exists)
		return false
	case strings.has_suffix(path, ".zip"):
		format = .Zip
	}

	at:  string
	err: archive.Error
	#partial switch format {
	case .Zip:
		at, err = pack_zip(path, sources, update)
	case:
		fmt.eprintfln("%v: a new archive's name must end in .zip", path)
		return false
	}
	if err != nil {
		fmt.eprintfln("%v: %v", at, err)
		return false
	}
	fmt.printfln("%s %v archive %v", "updated" if update else "created", format, path)
	return true
}

describe :: proc(source: string) -> (fi: archive.File_Info, err: archive.Error) {
	info := os.stat(source, context.temp_allocator) or_return
	fi = {path = info.name, type = .Regular, size = info.size, modification_time = info.modification_time}
	if info.type == .Directory {
		fi.type = .Directory
	}
	return
}

pack_zip :: proc(path: string, sources: []string, update: bool) -> (at: string, err: archive.Error) {
	at = path
	zw: zip.Writer
	if update {
		zip.update(&zw, path) or_return
	} else {
		zip.create(&zw, path) or_return
	}
	defer zip.close(&zw)

	options := zip.Entry_Options{replace = update}
	for source in sources {
		at = source
		fi := describe(source) or_return
		if fi.type == .Directory {
			zip.write_directory(&zw, source, fi.path, options) or_return
		} else {
			f := os.open(source) or_return
			defer os.close(f)
			zip.write_entry(&zw, fi, os.to_reader(f), options) or_return
		}
	}
	at = path
	return at, zip.commit(&zw)
}

method_name :: proc(fi: archive.File_Info, method: archive.Method) -> string {
	b := strings.builder_make(context.temp_allocator)
	if method == .Unknown {
		fmt.sbprintf(&b, "#%x", fi.method_id)
	} else {
		fmt.sbprint(&b, method)
	}
	for filter in fi.filters {
		fmt.sbprintf(&b, "+%v", filter)
	}
	if fi.encrypted {
		strings.write_string(&b, "+Encrypted")
	}
	return strings.to_string(b)
}
