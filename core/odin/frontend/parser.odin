package odin_frontend

import "core:sync"
import "core:fmt"
import "core:strings"

import "core:intrinsics"

import "core:path/filepath"
import "core:os"

/*c++
struct Parser {
	String                 init_fullpath;

	StringSet              imported_files; // fullpath
	BlockingMutex          imported_files_mutex;

	Array<AstPackage *>    packages;
	BlockingMutex          packages_mutex;

	std::atomic<isize>     file_to_process_count;
	std::atomic<isize>     total_token_count;
	std::atomic<isize>     total_line_count;

	// TODO(bill): What should this mutex be per?
	//  * Parser
	//  * Package
	//  * File
	BlockingMutex          file_decl_mutex;

	BlockingMutex          file_error_mutex;
	ParseFileErrorNode *   file_error_head;
	ParseFileErrorNode *   file_error_tail;
};
*/

Imported_File :: struct {
	pkg: ^Package,
	fi: os.File_Info,
	pos: Pos, // import
	index: int,
}

Collection :: struct {
	name: string,
	path: string,
}

Parser :: struct {
	init_fullpath: string,

	imported_files: map[string]bool,
	imported_files_mutex: sync.Mutex,

	collections: [dynamic]Collection,

	packages: [dynamic]^Package,
	packages_mutex: sync.Mutex,

	file_to_process_count: int,
	total_token_count: int,
	total_line_count: int,

	file_decl_mutex: sync.Mutex,

	err: Error_Handler,
	warn: Warning_Handler,
}

default_parser :: proc() -> Parser {
	return Parser {
		err = default_error_handler,
		warn = default_warning_handler,
	}
}

Stmt_Allow_Flag :: enum {
	In,
	Label,
}
Stmt_Allow_Flags :: distinct bit_set[Stmt_Allow_Flag]

Import_Decl_Kind :: enum {
	Standard,
	Using,
}

Parse_File_Error :: enum {
	None,
	Wrong_Extension,
	Invalid_File,
	Empty_File,
	Permission,
	Not_Found,
	Invalid_Token,
	General_Error,
	File_Too_Large,
	Directory_Already_Exists,
}

collection_path :: proc(p: ^Parser, name: string) -> (path: Maybe(string)) {
	for collection in p.collections {
		if collection.name == name {
			return collection.path
		}
	}
	return nil
}

import_path_to_fullpath :: proc(p: ^Parser, pkg: ^Package, path: string, allocator := context.allocator) -> (fullpath: Maybe(string)) {
	collection_and_relpath := strings.split(path, ":", context.temp_allocator)
	switch len(collection_and_relpath) {
	case 1: // Relative to the package path
		return filepath.join({pkg.fullpath, collection_and_relpath[0]}, allocator)

	case 2:
		col_path := collection_path(p, collection_and_relpath[0])
		if col_path, is_valid := col_path.?; is_valid {
			return filepath.join({col_path, collection_and_relpath[1]}, allocator)
		}
	}
	return nil
}

parser_add_collection :: proc(p: ^Parser, name: string, path: string) -> bool {
	old_path := collection_path(p, name)
	if old_path, is_valid := old_path.?; is_valid {
		error(p, NO_POS, "Redaclaration of collection %s to %s. Was %s", name, path, old_path)
		return false
	}
	append(&p.collections, Collection{name, path})
	return true
}


parser_add_file_to_process :: proc(p: ^Parser, pkg: ^Package, fi: os.File_Info, pos: Pos) {
	f := Imported_File{pkg, fi, pos, p.file_to_process_count + 1}
	p.file_to_process_count += 1
	// Todo(Dragos): add worker to pool, or process directly
}

process_imported_file :: proc(p: ^Parser, imported_file: Imported_File) -> bool {
	pkg := imported_file.pkg
	fi := imported_file.fi
	pos := imported_file.pos

	file := new(File, context.allocator)
	
	file.pkg = pkg
	file.id = imported_file.index + 1

	err_pos, file_ok := file_init(file, fi.fullpath)
	
	return true
}

file_init :: proc(file: ^File, fullpath: string) -> (err_pos: Pos, ok: bool) {
	unimplemented()
}

parser_add_package :: proc(p: ^Parser, pkg: ^Package) {
	pkg.id = len(p.packages) + 1
	append(&p.packages, pkg)
}

parse_packages :: proc(p: ^Parser, init_filename: string) -> bool {
	if init_fullpath, ok := filepath.abs(init_filename, context.allocator); ok {
		error(p, Pos{}, "Failed to get the fullpath of %s", init_filename)
		return false
	}
	
	return true
}