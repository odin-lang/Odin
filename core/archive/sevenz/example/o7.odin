/*
A minimal 7z tool on `core:archive/sevenz`: lists a 7z archive, tests it, unpacks one member, or
creates or updates an archive.

Build it with `odin build core/archive/sevenz/example -out:o7`, then run:

	o7 list   <archive.7z>             lists the members: sizes, methods, blocks, times and CRC-32s
	o7 test   <archive.7z>             decompresses every member and checks its CRC-32
	o7 unpack <archive.7z> <path>      writes one member to the current directory, under its
	                                   base name, unless a file of that name exists
	o7 create <archive.7z> <path>...   packs files and directory trees into a new archive, with
	                                   the default options, unless the archive exists
	o7 update <archive.7z> <path>...   adds files and directory trees to an archive, replacing
	                                   the members it has at the same paths
	o7 -help                           shows the usage

A solid archive packs many members into one block, which has a packed size where its members
have none. `test` decodes each block once.

`core:archive/sevenz` reads 7-Zip AES-256 encryption, but this tool takes no password. A program
passes one in `archive.Read_Options`: to `sevenz.open` for an encrypted header, and to
`sevenz.extract` or `sevenz.extract_current` for encrypted members. Without one, an archive with
an encrypted header doesn't open, and encrypted members are listed but don't test or unpack.
*/
package o7

import "core:archive"
import "core:archive/sevenz"
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
  o7 list   <archive.7z>             lists the members: sizes, methods, blocks, times and CRC-32s
  o7 test   <archive.7z>             decompresses every member and checks its CRC-32
  o7 unpack <archive.7z> <path>      writes one member to the current directory, under its
                                     base name, unless a file of that name exists
  o7 create <archive.7z> <path>...   packs files and directory trees into a new archive, with
                                     the default options, unless the archive exists
  o7 update <archive.7z> <path>...   adds files and directory trees to an archive, replacing
                                     the members it has at the same paths
  o7 -help                           shows the usage
`

main :: proc() {
	options: Options
	flags.register_flag_checker(check_paths)
	if err := flags.parse(&options, os.args[1:]); err != nil {
		usage(err)
	}
	paths := options.overflow[:]

	if options.command == .create || options.command == .update {
		if at, err := pack(options.archive, paths, options.command == .update); err != nil {
			fmt.eprintfln("%v: %v", at, err)
			os.exit(1)
		}
		fmt.printfln("%v %v", "updated" if options.command == .update else "created", options.archive)
		return
	}
	r: sevenz.Reader
	if err := sevenz.open(&r, options.archive); err != nil {
		fmt.eprintfln("%v: %v", options.archive, err)
		os.exit(1)
	}
	ok := false
	#partial switch options.command {
	case .list:   ok = list(&r)
	case .test:   ok = test(&r)
	case .unpack: ok = unpack(&r, paths[0])
	}
	sevenz.close(&r)
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

list :: proc(r: ^sevenz.Reader) -> bool {
	fmt.println("  Length    Packed  Method            Block  Date        Time      CRC-32    Name")
	fmt.println("--------  --------  ----------------  -----  ----------  --------  --------  ----")
	count, size: i64
	it := sevenz.iterator_create(r)
	defer sevenz.iterator_destroy(&it)
	for fi in sevenz.iterate(&it) {
		date: [time.MIN_YYYY_DATE_LEN]u8
		clock: [time.MIN_HMS_LEN]u8
		block := sevenz.current_entry(&it).folder
		crc, has_crc := fi.crc32.?
		fmt.printfln("%8d  %8s  %-16s  %5s  %s  %s  %8s  %s%s",
			fi.size, fmt.tprint(fi.compressed_size) if fi.compressed_size >= 0 else "-",
			method_name(fi) if block >= 0 else "-", fmt.tprint(block) if block >= 0 else "-",
			time.to_string_yyyy_mm_dd(fi.modification_time, date[:]), time.to_string_hms(fi.modification_time, clock[:]),
			fmt.tprintf("%08x", crc) if has_crc else "-", fi.path, "/" if fi.type == .Directory else "")
		count += 1
		size  += fi.size
	}
	fmt.printfln("%d members, %d bytes", count, size)
	return true
}

test :: proc(r: ^sevenz.Reader) -> bool {
	failed := 0
	it := sevenz.iterator_create(r)
	defer sevenz.iterator_destroy(&it)
	for fi in sevenz.iterate(&it) {
		sink: io.Counting_Stream
		if err := sevenz.extract_current(&it, io.counting_stream_init(&sink, {})); err != nil {
			fmt.printfln("    testing: %-40s  %v", fi.path, err)
			failed += 1
		} else {
			fmt.printfln("    testing: %-40s  OK", fi.path)
		}
	}
	if failed == 0 {
		fmt.println("No errors detected.")
	} else {
		fmt.printfln("%d errors detected.", failed)
	}
	return failed == 0
}

unpack :: proc(r: ^sevenz.Reader, path: string) -> bool {
	fi, handle, found, _ := sevenz.find(r, path)
	if !found {
		fmt.eprintfln("%v: %v", path, archive.General_Error.Not_Found)
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
	err := sevenz.extract(r, handle, os.to_stream(f))
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

pack :: proc(path: string, sources: []string, update: bool) -> (at: string, err: sevenz.Error) {
	at = path
	if !update && os.exists(path) {
		return at, archive.General_Error.Exists
	}
	sw: sevenz.Writer
	if update {
		sevenz.update(&sw, path) or_return
	} else {
		sevenz.create(&sw, path) or_return
	}
	defer sevenz.close(&sw)

	options := sevenz.Entry_Options{replace = update}
	for source in sources {
		at = source
		info := os.stat(source, context.temp_allocator) or_return
		if info.type == .Directory {
			sevenz.write_directory(&sw, source, info.name, options) or_return
		} else {
			f := os.open(source) or_return
			defer os.close(f)
			fi := archive.File_Info{path = info.name, type = .Regular, size = info.size, modification_time = info.modification_time}
			sevenz.write_entry(&sw, fi, os.to_reader(f), options) or_return
		}
	}
	at = path
	return at, sevenz.commit(&sw)
}

method_name :: proc(fi: archive.File_Info) -> string {
	b := strings.builder_make(context.temp_allocator)
	fmt.sbprint(&b, fi.method)
	for filter in fi.filters {
		fmt.sbprintf(&b, "+%v", filter)
	}
	if fi.encrypted {
		strings.write_string(&b, "+AES")
	}
	return strings.to_string(b)
}
