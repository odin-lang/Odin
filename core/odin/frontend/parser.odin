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

Parser :: struct {
	init_fullpath: string,

	imported_files: map[string]bool,
	imported_files_mutex: sync.Mutex,

	packages: [dynamic]^Package,
	packages_mutex: sync.Mutex,

	file_to_process_count: int,
	total_token_count: int,
	total_line_count: int,

	file_decl_mutex: sync.Mutex,

	err: Error_Handler,
	warn: Warning_Handler,
}

/*
Parser :: struct {
	file: ^File,
	tokenizer: Tokenizer,

	warn: Warning_Handler,
	err: Error_Handler,

	prev_tok: Token,
	curr_tok: Token,

	// >= 0: In Expression
	// <  0: In Control Clause
	// NOTE(bill): Used to prevent type literals in control clauses
	expr_level: int,
	allow_range: bool,
	allow_in_expr: bool,
	in_foreign_block: bool,
	allow_type: bool,

	lead_comment: ^Comment_Group,
	line_comment: ^Comment_Group,

	curr_proc: ^Node,

	error_count: int,
	fix_count: int,
	fix_prev_pos: Pos,

	peeking: bool,
}
*/


MAX_FIX_COUNT :: 10

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

try_add_import_path :: proc(p: ^Parser, path: string, rel_path: string, pos: Pos, kind: Package_Kind = .Normal) -> ^Package {
	if path in p.imported_files {
		return nil
	}
	map_insert(&p.imported_files, path, true)

	path := strings.clone(path, context.allocator) // Todo(Dragos): Change the allocation strategy around
	
	pkg := new_node(Package, NO_POS, NO_POS)
	pkg.kind = kind
	pkg.fullpath = path
	pkg.files = make([dynamic]^File, context.allocator)
	pkg.foreign_files = make([dynamic]^Foreign_File, context.allocator)

	// Single file initial package
	if kind == .Init && filepath.ext(path) == ".odin" {
		fd, err := os.open(path, os.O_RDONLY)
		fi: os.File_Info
		if err != 0 {
			error(p, NO_POS, "Failed to open file %s", path)
			return nil
		}
		fi, err = os.fstat(fd, context.allocator)
		if err != 0 {
			error(p, NO_POS, "Failed to get file info of %s", path)
		}

		pkg.is_single_file = true
		parser_add_package(p, pkg)

	}

	return pkg
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

	file := new_node(File, NO_POS, NO_POS, context.allocator)
	
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