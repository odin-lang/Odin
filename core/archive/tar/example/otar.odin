/*
A minimal tar tool on `core:archive/tar`: lists a tar archive, tests it, unpacks one member, or
creates an archive.

Build it with `odin build core/archive/tar/example -out:otar`, then run:

	otar list   <archive.tar>             lists the members: sizes, owners, times and link targets
	otar test   <archive.tar>             reads every member through to the end
	otar unpack <archive.tar> <path>      writes one member to the current directory, under its
	                                      base name, unless a file of that name exists
	otar create <archive.tar> <path>...   packs files and directory trees into a new archive,
	                                      with the default options, unless the archive exists
	otar -help                            shows the usage

An archive to read may be compressed with gzip, bzip2, LZ4, LZMA or XZ. tar stores its members
uncompressed, so the method listed for every member is the whole archive's, and only that
compression has a checksum `test` can check. `create` writes an uncompressed pax archive.
`core:archive/tar` can't update an archive, so there is no `update` command.
*/
package otar

import "core:archive"
import "core:archive/tar"
import "core:flags"
import "core:fmt"
import "core:io"
import "core:os"
import "core:time"

Command :: enum {
	list,
	test,
	unpack,
	create,
}

Options :: struct {
	command:  Command `args:"pos=0,required"`,
	archive:  string  `args:"pos=1,required"`,
	overflow: [dynamic]string,
}

USAGE :: `usage:
  otar list   <archive.tar>             lists the members: sizes, owners, times and link targets
  otar test   <archive.tar>             reads every member through to the end
  otar unpack <archive.tar> <path>      writes one member to the current directory, under its
                                        base name, unless a file of that name exists
  otar create <archive.tar> <path>...   packs files and directory trees into a new archive,
                                        with the default options, unless the archive exists
  otar -help                            shows the usage
`

main :: proc() {
	options: Options
	flags.register_flag_checker(check_paths)
	if err := flags.parse(&options, os.args[1:]); err != nil {
		usage(err)
	}
	paths := options.overflow[:]

	if options.command == .create {
		if at, err := pack(options.archive, paths); err != nil {
			fmt.eprintfln("%v: %v", at, err)
			os.exit(1)
		}
		fmt.printfln("created %v", options.archive)
		return
	}
	r: tar.Reader
	if err := tar.open(&r, options.archive); err != nil {
		fmt.eprintfln("%v: %v", options.archive, err)
		os.exit(1)
	}
	ok := false
	#partial switch options.command {
	case .list:   ok = list(&r)
	case .test:   ok = test(&r)
	case .unpack: ok = unpack(&r, paths[0])
	}
	tar.close(&r)
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
	case .create:
		if len(options.overflow) == 0 {
			return "`create` takes one or more files or directories."
		}
	}
	return ""
}

list :: proc(r: ^tar.Reader) -> bool {
	method := tar.info(r).compression
	fmt.println("  Length  Method  Date        Time      Owner              Name")
	fmt.println("--------  ------  ----------  --------  -----------------  ----")
	count, size: i64
	it := tar.iterator_create(r)
	defer tar.iterator_destroy(&it)
	for fi in tar.iterate(&it) {
		date: [time.MIN_YYYY_DATE_LEN]u8
		clock: [time.MIN_HMS_LEN]u8
		fmt.printfln("%8d  %-6v  %s  %s  %-17s  %s%s%s",
			fi.size, method,
			time.to_string_yyyy_mm_dd(fi.modification_time, date[:]), time.to_string_hms(fi.modification_time, clock[:]),
			fmt.tprintf("%s/%s", fi.user, fi.group), fi.path,
			"/" if fi.type == .Directory else "", fmt.tprintf(" -> %s", fi.link_target) if fi.link_target != "" else "")
		count += 1
		size  += fi.size
	}
	if path, err := tar.iterator_error(&it); err != nil {
		fmt.eprintfln("%v: %v", path, err)
		return false
	}
	fmt.printfln("%d members, %d bytes", count, size)
	return true
}

test :: proc(r: ^tar.Reader) -> bool {
	failed := 0
	it := tar.iterator_create(r)
	defer tar.iterator_destroy(&it)
	for fi in tar.iterate(&it) {
		sink: io.Counting_Stream
		if err := tar.extract_current(&it, io.counting_stream_init(&sink, {})); err != nil {
			fmt.printfln("    testing: %-40s  %v", fi.path, err)
			failed += 1
		} else {
			fmt.printfln("    testing: %-40s  OK", fi.path)
		}
	}
	if path, err := tar.iterator_error(&it); err != nil {
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

unpack :: proc(r: ^tar.Reader, path: string) -> bool {
	fi, handle, found, err := tar.find(r, path)
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
	err = tar.extract(r, handle, os.to_stream(f))
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

pack :: proc(path: string, sources: []string) -> (at: string, err: tar.Error) {
	at = path
	if os.exists(path) {
		return at, archive.General_Error.Exists
	}
	tw: tar.Writer
	tar.create(&tw, path) or_return
	defer tar.close(&tw)

	for source in sources {
		at = source
		info := os.stat(source, context.temp_allocator) or_return
		if info.type == .Directory {
			tar.write_directory(&tw, source, info.name) or_return
		} else {
			f := os.open(source) or_return
			defer os.close(f)
			fi := archive.File_Info{path = info.name, type = .Regular, size = info.size, modification_time = info.modification_time}
			tar.write_entry(&tw, fi, os.to_reader(f)) or_return
		}
	}
	at = path
	return at, tar.commit(&tw)
}
