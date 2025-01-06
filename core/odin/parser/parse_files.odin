package odin_parser

import "core:odin/tokenizer"
import "core:odin/ast"
import "core:path/filepath"
import "core:fmt"
import "core:os"
import "core:slice"
import "core:strings"

collect_package :: proc(path: string) -> (pkg: ^ast.Package, success: bool) {
	NO_POS :: tokenizer.Pos{}

	pkg_path, pkg_path_ok := filepath.abs(path)
	if !pkg_path_ok {
		return
	}

	path_pattern := fmt.tprintf("%s/*.odin", pkg_path)
	matches, err := filepath.glob(path_pattern)
	defer delete(matches)

	if err != nil {
		return
	}

	pkg = ast.new(ast.Package, NO_POS, NO_POS)
	pkg.fullpath = pkg_path

	for match in matches {
		src: []byte
		fullpath, ok := filepath.abs(match)
		if !ok {
			return
		}

		src, ok = os.read_entire_file(fullpath)
		if !ok {
			delete(fullpath)
			return
		}
		if strings.trim_space(string(src)) == "" {
			delete(fullpath)
			delete(src)
			continue
		}

		file := ast.new(ast.File, NO_POS, NO_POS)
		file.pkg = pkg
		file.src = string(src)
		file.fullpath = fullpath
		pkg.files[fullpath] = file
	}

	success = true
	return
}

parse_package :: proc(pkg: ^ast.Package, p: ^Parser = nil) -> bool {
	p := p
	if p == nil {
		p = &Parser{}
		p^ = default_parser()
	}

	ok := true

	files := make([]^ast.File, len(pkg.files), context.temp_allocator)
	i := 0
	for _, file in pkg.files {
		files[i] = file
		i += 1
	}
	slice.sort(files)

	for file in files {
		if !parse_file(p, file) {
			ok = false
		}
		if pkg.name == "" {
			pkg.name = file.pkg_decl.name
		} else if pkg.name != file.pkg_decl.name {
			error(p, file.pkg_decl.pos, "different package name, expected '%s', got '%s'", pkg.name, file.pkg_decl.name)
		}
	}

	return ok
}

parse_package_from_path :: proc(path: string, p: ^Parser = nil) -> (pkg: ^ast.Package, ok: bool) {
	pkg, ok = collect_package(path)
	if !ok {
		return
	}
	ok = parse_package(pkg, p)
	return
}
