package odin_frontend

import "core:path/filepath"
import "core:os"
import "core:sync"
import "core:fmt"
import "core:strings"
import "core:runtime"
import "core:mem"

/*
File :: struct {
	using node: Node,
	id: int,
	pkg: ^Package,

	fullpath: string,
	src:      string,

	docs: ^Comment_Group,

	pkg_decl:  ^Package_Decl,
	pkg_token: Token,
	pkg_name:  string,

	decls:   [dynamic]^Stmt,
	imports: [dynamic]^Import_Decl,
	directive_count: int,

	comments: [dynamic]^Comment_Group,

	syntax_warning_count: int,
	syntax_error_count:   int,
}
*/

Package_Kind :: enum {
	Normal,
	Runtime,
	Init,
}


Foreign_File_Kind :: enum {
	Invalid,
	Source,
}

Foreign_File :: struct {
	kind: Foreign_File_Kind,
	source: string,
}

File_Flag :: enum u32 {
	Is_Private_Pkg = 1<<0,
	Is_Private_File = 1<<1,

	Is_Test    = 1<<3,
	Is_Lazy    = 1<<4,
}
File_Flags :: bit_set[File_Flag]


File :: struct {
	id: int,

	pkg: ^Package,
	pkg_decl: ^Node,
	
	src: string,
	fullpath: string,
	filename: string,
	directory: string,
	
	tokens: [dynamic]Token,

	docs: ^Comment_Group,
}

Package :: struct {
	kind: Package_Kind,
	id: int,
	name: string,
	fullpath: string,
	files: map[string]^File,

	is_single_file: bool,
	order: int,

	file_allocator: mem.Allocator,
}

read_file :: proc(pkg: ^Package, path: string) -> (file: ^File) {
	context.allocator = pkg.file_allocator
	fullpath, fullpath_ok := filepath.abs(path)
	if !fullpath_ok {
		return nil
	}
	fmt.assertf(fullpath not_in pkg.files, "File %s already part of the package\n", fullpath)
	src, src_ok := os.read_entire_file(fullpath)	
	if !src_ok {
		return nil
	}
	file = new(File)
	file.fullpath = fullpath
	file.filename = filepath.base(file.fullpath)
	file.directory = filepath.dir(file.filename)
	file.src = string(src)
	file.tokens = make([dynamic]Token) // Note(Dragos): Maybe this can have a different allocator
	file.pkg = pkg
	pkg.files[file.fullpath] = file
	return file
}

delete_file :: proc(file: ^File) {
	fmt.assertf(file.fullpath in file.pkg.files, "File %s is not part of the package\n", file.fullpath)
	context.allocator = file.pkg.file_allocator
	delete_key(&file.pkg.files, file.fullpath)
	delete(file.fullpath)
	delete(file.directory)
	free(file)
}

read_package :: proc(path: string, file_allocator: mem.Allocator, allocator := context.allocator) -> (pkg: ^Package, ok: bool) {
	context.allocator = allocator
	pkg_path, pkg_path_ok := filepath.abs(path)
	if !pkg_path_ok {
		return nil, false
	}
	path_pattern := fmt.tprintf("%s/*.odin", pkg_path)
	matches, matches_err := filepath.glob(path_pattern, context.temp_allocator)
	if matches_err != nil {
		return nil, false
	}

	pkg = new(Package)
	pkg.fullpath = pkg_path
	pkg.files = make(map[string]^File)
	pkg.file_allocator = file_allocator
	defer if !ok {
		delete(pkg.fullpath)
		delete(pkg.files)
		free(pkg)
	}
	for match in matches {
		file := read_file(pkg, match)
		if file == nil {
			return nil, false
		}
	}

	return pkg, true
}

delete_package :: proc(pkg: ^Package, allocator := context.allocator) {
	context.allocator = allocator
}