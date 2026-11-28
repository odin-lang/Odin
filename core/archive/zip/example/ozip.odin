/*
A minimal zip tool on `core:archive/zip`: lists a zip archive, tests it, unpacks one member, or
creates or updates an archive.

Build it with `odin build core/archive/zip/example -out:ozip`, then run:

	ozip list   <archive.zip>             lists the members: sizes, methods, times and CRC-32s
	ozip test   <archive.zip>             decompresses every member and checks its CRC-32
	ozip unpack <archive.zip> <path>      writes one member to the current directory, under its
	                                      base name, unless a file of that name exists
	ozip create <archive.zip> <path>...   packs files and directory trees into a new archive,
	                                      with the default options, unless the archive exists
	ozip update <archive.zip> <path>...   adds files and directory trees to an archive,
	                                      replacing the members it has at the same paths
	ozip -help                            shows the usage

Self-extracting archives open too.

`core:archive/zip` reads ZipCrypto and WinZip AES encryption, but this tool takes no password. A
program passes one in `archive.Read_Options` to `zip.extract` or `zip.extract_current`. Without
one, encrypted members are listed but don't test or unpack.
*/
package ozip

import "core:archive"
import "core:archive/zip"
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
	update,
}

Options :: struct {
	command:  Command `args:"pos=0,required"`,
	archive:  string  `args:"pos=1,required"`,
	overflow: [dynamic]string,
}

USAGE :: `usage:
  ozip list   <archive.zip>             lists the members: sizes, methods, times and CRC-32s
  ozip test   <archive.zip>             decompresses every member and checks its CRC-32
  ozip unpack <archive.zip> <path>      writes one member to the current directory, under its
                                        base name, unless a file of that name exists
  ozip create <archive.zip> <path>...   packs files and directory trees into a new archive,
                                        with the default options, unless the archive exists
  ozip update <archive.zip> <path>...   adds files and directory trees to an archive,
                                        replacing the members it has at the same paths
  ozip -help                            shows the usage
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
	r: zip.Reader
	if err := zip.open(&r, options.archive); err != nil {
		fmt.eprintfln("%v: %v", options.archive, err)
		os.exit(1)
	}
	ok := false
	#partial switch options.command {
	case .list:   ok = list(&r)
	case .test:   ok = test(&r)
	case .unpack: ok = unpack(&r, paths[0])
	}
	zip.close(&r)
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

list :: proc(r: ^zip.Reader) -> bool {
	if comment := zip.info(r).comment; comment != "" {
		fmt.println(comment)
	}
	fmt.println("  Length  Method        Size  Cmpr  Date        Time      CRC-32    Name")
	fmt.println("--------  ---------  -------  ----  ----------  --------  --------  ----")
	count, size, packed: i64
	it := zip.iterator_create(r)
	defer zip.iterator_destroy(&it)
	for fi in zip.iterate(&it) {
		date: [time.MIN_YYYY_DATE_LEN]u8
		clock: [time.MIN_HMS_LEN]u8
		crc, _ := fi.crc32.?
		fmt.printfln("%8d  %-9s  %7d  %3d%%  %s  %s  %08x  %s%s",
			fi.size, method_name(fi, zip.current_entry(&it)), fi.compressed_size, saved(fi.size, fi.compressed_size),
			time.to_string_yyyy_mm_dd(fi.modification_time, date[:]), time.to_string_hms(fi.modification_time, clock[:]),
			crc, fi.path, "/" if fi.type == .Directory else "")
		count  += 1
		size   += fi.size
		packed += fi.compressed_size
	}
	fmt.printfln("%d members, %d bytes, packed into %d (%d%% saved)", count, size, packed, saved(size, packed))
	return true
}

test :: proc(r: ^zip.Reader) -> bool {
	failed := 0
	it := zip.iterator_create(r)
	defer zip.iterator_destroy(&it)
	for fi in zip.iterate(&it) {
		sink: io.Counting_Stream
		if err := zip.extract_current(&it, io.counting_stream_init(&sink, {})); err != nil {
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

unpack :: proc(r: ^zip.Reader, path: string) -> bool {
	fi, handle, found, _ := zip.find(r, path)
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
	err := zip.extract(r, handle, os.to_stream(f))
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

pack :: proc(path: string, sources: []string, update: bool) -> (at: string, err: zip.Error) {
	at = path
	if !update && os.exists(path) {
		return at, archive.General_Error.Exists
	}
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
		info := os.stat(source, context.temp_allocator) or_return
		if info.type == .Directory {
			zip.write_directory(&zw, source, info.name, options) or_return
		} else {
			f := os.open(source) or_return
			defer os.close(f)
			fi := archive.File_Info{path = info.name, type = .Regular, size = info.size, modification_time = info.modification_time}
			zip.write_entry(&zw, fi, os.to_reader(f), options) or_return
		}
	}
	at = path
	return at, zip.commit(&zw)
}

method_name :: proc(fi: archive.File_Info, entry: ^zip.Entry) -> string {
	#partial switch fi.method {
	case .Deflate:
		levels := "NXFS"
		return fmt.tprintf("Defl:%c", levels[transmute(u16)entry.flags >> 1 & 3])
	case .Unknown:
		return fmt.tprintf("Unk:%03d", fi.method_id)
	}
	return fmt.tprint(fi.method)
}

saved :: proc(size, packed: i64) -> i64 {
	return 0 if size <= 0 else 100 - (100 * packed + size / 2) / size
}
