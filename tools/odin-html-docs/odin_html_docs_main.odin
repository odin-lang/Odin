package odin_html_docs

import doc "core:odin/doc-format"
import "core:fmt"
import "core:io"
import "core:os"
import "core:strings"
import "core:path/slashpath"
import "core:sort"
import "core:slice"

header:   ^doc.Header
files:    []doc.File
pkgs:     []doc.Pkg
entities: []doc.Entity
types:    []doc.Type

pkgs_to_use: map[string]^doc.Pkg // trimmed path
pkg_to_path: map[^doc.Pkg]string // trimmed path

array :: proc(a: $A/doc.Array($T)) -> []T {
	return doc.from_array(header, a)
}
str :: proc(s: $A/doc.String) -> string {
	return doc.from_string(header, s)
}

errorf :: proc(format: string, args: ..any) -> ! {
	fmt.eprintf("%s ", os.args[0])
	fmt.eprintf(format, ..args)
	fmt.eprintln()
	os.exit(1)
}

common_prefix :: proc(strs: []string) -> string {
	if len(strs) == 0 {
		return ""
	}
	n := max(int)
	for str in strs {
		n = min(n, len(str))
	}

	prefix := strs[0][:n]
	for str in strs[1:] {
		for len(prefix) != 0 && str[:len(prefix)] != prefix {
			prefix = prefix[:len(prefix)-1]
		}
		if len(prefix) == 0 {
			break
		}
	}
	return prefix
}


write_html_header :: proc(w: io.Writer, title: string) {
	fmt.wprintf(w, `<!DOCTYPE html>
<html>
<head>
	<meta charset="utf-8">
	<meta name="viewport" content="width=device-width, initial-scale=1">
	<title>%s</title>

	<script type="text/javascript" src="https://livejs.com/live.js"></script>
	<link rel="stylesheet" type="text/css" href="/style.css">

	</style>
</head>
<body>`, title)
	fmt.wprintln(w, "\n<div class=\"container\">")
	fmt.wprintln(w, "\n<a href=\"/core\">Core Directory</a>")

}

write_html_footer :: proc(w: io.Writer) {
	fmt.wprintf(w, "</div></body>\n</html>\n")
}

main :: proc() {
	if len(os.args) != 2 {
		errorf("expected 1 .odin-doc file")
	}
	data, ok := os.read_entire_file(os.args[1])
	if !ok {
		errorf("unable to read file:", os.args[1])
	}
	err: doc.Reader_Error
	header, err = doc.read_from_bytes(data)
	switch err {
	case .None:
	case .Header_Too_Small:
		errorf("file is too small for the file format")
	case .Invalid_Magic:
		errorf("invalid magic for the file format")
	case .Data_Too_Small:
		errorf("data is too small for the file format")
	case .Invalid_Version:
		errorf("invalid file format version")
	}
	files    = array(header.files)
	pkgs     = array(header.pkgs)
	entities = array(header.entities)
	types    = array(header.types)

	fullpaths: [dynamic]string
	defer delete(fullpaths)

	for pkg in pkgs[1:] {
		append(&fullpaths, str(pkg.fullpath))
	}
	path_prefix := common_prefix(fullpaths[:])

	pkgs_to_use = make(map[string]^doc.Pkg)
	for fullpath, i in fullpaths {
		path := strings.trim_prefix(fullpath, path_prefix)
		if strings.has_prefix(path, "core/") {
			pkgs_to_use[strings.trim_prefix(path, "core/")] = &pkgs[i+1]
		}
	}
	sort.map_entries_by_key(&pkgs_to_use)
	for path, pkg in pkgs_to_use {
		pkg_to_path[pkg] = path
	}

	b := strings.make_builder()
	w := strings.to_writer(&b)
	{
		strings.reset_builder(&b)
		write_html_header(w, "core library - pkg.odin-lang.org")
		write_core_directory(w)
		write_html_footer(w)
		os.make_directory("core", 0)
		os.write_entire_file("core/index.html", b.buf[:])
	}

	for path, pkg in pkgs_to_use {
		strings.reset_builder(&b)
		write_html_header(w, fmt.tprintf("package %s - pkg.odin-lang.org", path))
		write_pkg(w, path, pkg)
		write_html_footer(w)
		os.make_directory(fmt.tprintf("core/%s", path), 0)
		os.write_entire_file(fmt.tprintf("core/%s/index.html", path), b.buf[:])
	}
}


write_core_directory :: proc(w: io.Writer) {
	Node :: struct {
		dir: string,
		path: string,
		name: string,
		pkg: ^doc.Pkg,
		next: ^Node,
		first_child: ^Node,
	}
	add_child :: proc(parent: ^Node, child: ^Node) -> ^Node {
		assert(parent != nil)
		end := &parent.first_child
		for end^ != nil {
			end = &end^.next
		}
		child.next = end^
		end^ = child
		return child
	}

	root: Node
	for path, pkg in pkgs_to_use {
		dir, _, inner := strings.partition(path, "/")

		node: ^Node = nil
		for node = root.first_child; node != nil; node = node.next {
			if node.dir == dir {
				break
			}
		}
		if inner == "" {
			if node == nil {
				add_child(&root, new_clone(Node{
					dir  = dir,
					name = dir,
					path = path,
					pkg  = pkg,
				}))
			} else {
				node.dir  = dir
				node.name = dir
				node.path = path
				node.pkg  = pkg
			}
		} else {
			if node == nil {
				node = add_child(&root, new_clone(Node{
					dir  = dir,
					name = dir,
				}))
			}
			assert(node != nil)
			child := add_child(node, new_clone(Node{
				dir  = dir,
				name = inner,
				path = path,
				pkg  = pkg,
			}))
		}
	}


	fmt.wprintln(w, "<h2>Directories</h2>")

	fmt.wprintln(w, "\t<table>")
	fmt.wprintln(w, "\t\t<tbody>")

	for dir := root.first_child; dir != nil; dir = dir.next {
		if dir.first_child != nil {
			fmt.wprint(w, `<tr aria-controls="`)
			for child := dir.first_child; child != nil; child = child.next {
				fmt.wprintf(w, "pkg-%s ", str(child.pkg.name))
			}
			fmt.wprint(w, `" class="directory-pkg"><td class="pkg-name" data-aria-owns="`)
			for child := dir.first_child; child != nil; child = child.next {
				fmt.wprintf(w, "pkg-%s ", str(child.pkg.name))
			}
			fmt.wprintf(w, `" id="pkg-%s">`, dir.dir)
		} else {
			fmt.wprintf(w, `<tr id="pkg-%s" class="directory-pkg"><td class="pkg-name">`, dir.dir)
		}

		if dir.pkg != nil {
			fmt.wprintf(w, `<a href="/core/%s">%s</a>`, dir.path, dir.name)
		} else {
			fmt.wprintf(w, "%s", dir.name)
		}
		fmt.wprintf(w, "</td>")
		if dir.pkg != nil {
			line_doc, _, _ := strings.partition(str(dir.pkg.docs), "\n")
			line_doc = strings.trim_space(line_doc)
			if line_doc != "" {
				fmt.wprintf(w, `<td class="pkg-line-doc">%s</td>`, line_doc)
			}
		}
		fmt.wprintf(w, "</tr>\n")

		for child := dir.first_child; child != nil; child = child.next {
			assert(child.pkg != nil)
			fmt.wprintf(w, `<tr id="pkg-%s" class="directory-pkg directory-child"><td class="pkg-name">`, str(child.pkg.name))
			fmt.wprintf(w, `<a href="/core/%s/">%s</a>`, child.path, child.name)
			fmt.wprintf(w, "</td>")

			line_doc, _, _ := strings.partition(str(child.pkg.docs), "\n")
			line_doc = strings.trim_space(line_doc)
			if line_doc != "" {
				fmt.wprintf(w, `<td class="pkg-line-doc">%s</td>`, line_doc)
			}

			fmt.wprintf(w, "</tr>\n")
		}
	}

	fmt.wprintln(w, "\t\t</tbody>")
	fmt.wprintln(w, "\t</table>")
}

is_entity_blank :: proc(e: doc.Entity_Index) -> bool {
	name := str(entities[e].name)
	return name == "" || name == "_"
}

Write_Type_Flag :: enum {
	Is_Results,
	Variadic,
}
Write_Type_Flags :: distinct bit_set[Write_Type_Flag]

write_type :: proc(w: io.Writer, pkg: doc.Pkg_Index, type: doc.Type, flags: Write_Type_Flags) {
	type_entites := array(type.entities)
	type_types := array(type.types)
	switch type.kind {
	case .Invalid:
		// ignore
	case .Basic:
		type_flags := transmute(doc.Type_Flags_Basic)type.flags
		if .Untyped in type_flags {
			io.write_string(w, str(type.name))
		} else {
			fmt.wprintf(w, `<a href="">%s</a>`, str(type.name))
		}
	case .Named:
		e := entities[type_entites[0]]
		name := str(type.name)
		fmt.wprintf(w, `<span>`)
		tn_pkg := files[e.pos.file].pkg
		if tn_pkg != pkg {
			fmt.wprintf(w, `%s.`, str(pkgs[pkg].name))
		}
		fmt.wprintf(w, `<a href="/core/{0:s}/#{1:s}">{1:s}</a></span>`, pkg_to_path[&pkgs[tn_pkg]], name)
	case .Generic:
		name := str(type.name)
		io.write_byte(w, '$')
		io.write_string(w, name)
		if len(array(type.types)) == 1 {
			io.write_byte(w, '/')
			write_type(w, pkg, types[type_types[0]], flags)
		}
	case .Pointer:
		io.write_byte(w, '^')
		write_type(w, pkg, types[type_types[0]], flags)
	case .Array:
		assert(type.elem_count_len == 1)
		io.write_byte(w, '[')
		io.write_uint(w, uint(type.elem_counts[0]))
		io.write_byte(w, ']')
		write_type(w, pkg, types[type_types[0]], flags)
	case .Enumerated_Array:
		io.write_byte(w, '[')
		write_type(w, pkg, types[type_types[0]], flags)
		io.write_byte(w, ']')
		write_type(w, pkg, types[type_types[1]], flags)
	case .Slice:
		if .Variadic in flags {
			io.write_string(w, "..")
		} else {
			io.write_string(w, "[]")
		}
		write_type(w, pkg, types[type_types[0]], flags - {.Variadic})
	case .Dynamic_Array:
		io.write_string(w, "[dynamic]")
		write_type(w, pkg, types[type_types[0]], flags)
	case .Map:
		io.write_string(w, "map[")
		write_type(w, pkg, types[type_types[0]], flags)
		io.write_byte(w, ']')
		write_type(w, pkg, types[type_types[1]], flags)
	case .Struct:
		type_flags := transmute(doc.Type_Flags_Struct)type.flags
		io.write_string(w, "struct {}")
	case .Union:
		type_flags := transmute(doc.Type_Flags_Union)type.flags
		io.write_string(w, "union {}")
	case .Enum:
		io.write_string(w, "enum {}")
	case .Tuple:
		entity_indices := type_entites
		if len(entity_indices) == 0 {
			return
		}
		require_parens := (.Is_Results in flags) && (len(entity_indices) > 1 || !is_entity_blank(entity_indices[0]))
		if require_parens { io.write_byte(w, '(') }
		for entity_index, i in entity_indices {
			e := &entities[entity_index]
			name := str(e.name)

			if i > 0 {
				io.write_string(w, ", ")
			}
			if .Param_Using     in e.flags { io.write_string(w, "using ")      }
			if .Param_Const     in e.flags { io.write_string(w, "#const ")     }
			if .Param_Auto_Cast in e.flags { io.write_string(w, "#auto_cast ") }
			if .Param_CVararg   in e.flags { io.write_string(w, "#c_vararg ")  }
			if .Param_No_Alias  in e.flags { io.write_string(w, "#no_alias ")  }
			if .Param_Any_Int   in e.flags { io.write_string(w, "#any_int ")   }

			if name != "" {
				io.write_string(w, name)
				io.write_string(w, ": ")
			}
			param_flags := flags - {.Is_Results}
			if .Param_Ellipsis in e.flags {
				param_flags += {.Variadic}
			}
			write_type(w, pkg, types[e.type], param_flags)
		}
		if require_parens { io.write_byte(w, ')') }

	case .Proc:
		type_flags := transmute(doc.Type_Flags_Proc)type.flags
		io.write_string(w, "proc")
		cc := str(type.calling_convention)
		if cc != "" {
			io.write_byte(w, ' ')
			io.write_quoted_string(w, cc)
			io.write_byte(w, ' ')
		}
		params := array(type.types)[0]
		results := array(type.types)[1]
		io.write_byte(w, '(')
		write_type(w, pkg, types[params], flags)
		io.write_byte(w, ')')
		if results != 0 {
			assert(.Diverging not_in type_flags)
			io.write_string(w, " -> ")
			write_type(w, pkg, types[results], flags+{.Is_Results})
		}
		if .Diverging in type_flags {
			io.write_string(w, " -> !")
		}
		if .Optional_Ok in type_flags {
			io.write_string(w, " #optional_ok")
		}

	case .Bit_Set:
		type_flags := transmute(doc.Type_Flags_Bit_Set)type.flags
	case .Simd_Vector:
		io.write_string(w, "#simd[")
		io.write_uint(w, uint(type.elem_counts[0]))
		io.write_byte(w, ']')
	case .SOA_Struct_Fixed:
		io.write_string(w, "#soa[")
		io.write_uint(w, uint(type.elem_counts[0]))
		io.write_byte(w, ']')
	case .SOA_Struct_Slice:
		io.write_string(w, "#soa[]")
	case .SOA_Struct_Dynamic:
		io.write_string(w, "#soa[dynamic]")
	case .Relative_Pointer:
		io.write_string(w, "#relative(")
		write_type(w, pkg, types[type_types[1]], flags)
		io.write_string(w, ") ")
		write_type(w, pkg, types[type_types[0]], flags)
	case .Relative_Slice:
		io.write_string(w, "#relative(")
		write_type(w, pkg, types[type_types[1]], flags)
		io.write_string(w, ") ")
		write_type(w, pkg, types[type_types[0]], flags)
	case .Multi_Pointer:
		io.write_string(w, "[^]")
		write_type(w, pkg, types[type_types[0]], flags)
	case .Matrix:
		io.write_string(w, "matrix[")
		io.write_uint(w, uint(type.elem_counts[0]))
		io.write_string(w, ", ")
		io.write_uint(w, uint(type.elem_counts[1]))
		io.write_string(w, "]")
		write_type(w, pkg, types[type_types[0]], flags)
	}
}

write_docs :: proc(w: io.Writer, pkg: ^doc.Pkg, docs: string) {
	if docs == "" {
		return
	}
	it := docs
	was_code := true
	was_paragraph := true
	for line in strings.split_iterator(&it, "\n") {
		if strings.has_prefix(line, "\t") {
			if !was_code {
				was_code = true;
				fmt.wprint(w, `<pre class="doc-code"><code>`)
			}
			fmt.wprintf(w, "%s\n", strings.trim_prefix(line, "\t"))
			continue
		} else if was_code {
			was_code = false
			fmt.wprintln(w, "</code></pre>")
		}
		text := strings.trim_space(line)
		if text == "" {
			if was_paragraph {
				was_paragraph = false
				fmt.wprintln(w, "</p>")
			}
			continue
		}
		if !was_paragraph {
			fmt.wprintln(w, "<p>")
		}
		assert(!was_code)
		was_paragraph = true
		fmt.wprintln(w, text)
	}
	if was_code {
		// assert(!was_paragraph, str(pkg.name))
		was_code = false
		fmt.wprintln(w, "</code>")
	} else if was_paragraph {
		fmt.wprintln(w, "</p>")
	}
}

write_pkg :: proc(w: io.Writer, path: string, pkg: ^doc.Pkg) {
	fmt.wprintf(w, "<h1>package core:%s</h1>\n", path)
	fmt.wprintln(w, "<h2>Documentation</h2>")
	docs := strings.trim_space(str(pkg.docs))
	if docs != "" {
		fmt.wprintln(w, "<h3>Overview</h3>")
		fmt.wprintln(w, "<div id=\"pkg-overview\">")
		defer fmt.wprintln(w, "</div>")

		write_docs(w, pkg, docs)
	}

	fmt.wprintln(w, "<h3>Index</h3>")
	fmt.wprintln(w, `<section class="documentation-index">`)
	pkg_procs:       [dynamic]^doc.Entity
	pkg_proc_groups: [dynamic]^doc.Entity
	pkg_types:       [dynamic]^doc.Entity
	pkg_vars:        [dynamic]^doc.Entity
	pkg_consts:      [dynamic]^doc.Entity

	for entity_index in array(pkg.entities) {
		e := &entities[entity_index]
		name := str(e.name)
		if name == "" || name[0] == '_' {
			continue
		}
		switch e.kind {
		case .Invalid, .Import_Name, .Library_Name:
			// ignore
		case .Constant:   append(&pkg_consts, e)
		case .Variable:   append(&pkg_vars, e)
		case .Type_Name:  append(&pkg_types, e)
		case .Procedure:  append(&pkg_procs, e)
		case .Proc_Group: append(&pkg_proc_groups, e)
		}
	}

	entity_key :: proc(e: ^doc.Entity) -> string {
		return str(e.name)
	}

	slice.sort_by_key(pkg_procs[:],       entity_key)
	slice.sort_by_key(pkg_proc_groups[:], entity_key)
	slice.sort_by_key(pkg_types[:],       entity_key)
	slice.sort_by_key(pkg_vars[:],        entity_key)
	slice.sort_by_key(pkg_consts[:],      entity_key)

	print_index :: proc(w: io.Writer, name: string, entities: []^doc.Entity) {
		fmt.wprintf(w, "<h4>%s</h4>\n", name)
		fmt.wprintln(w, `<section class="documentation-index">`)
		fmt.wprintln(w, "<ul>")
		for e in entities {
			name := str(e.name)
			fmt.wprintf(w, "<li><a href=\"#{0:s}\">{0:s}</a></li>\n", name)
		}
		fmt.wprintln(w, "</ul>")
		fmt.wprintln(w, "</section>")
	}


	print_index(w, "Procedures",       pkg_procs[:])
	print_index(w, "Procedure Groups", pkg_proc_groups[:])
	print_index(w, "Types",            pkg_types[:])
	print_index(w, "Variables",        pkg_vars[:])
	print_index(w, "Constants",        pkg_consts[:])

	fmt.wprintln(w, "</section>")


	print_entity :: proc(w: io.Writer, e: ^doc.Entity) {
		pkg := &pkgs[files[e.pos.file].pkg]
		name := str(e.name)
		fmt.wprintf(w, "<h4 id=\"{0:s}\"><a href=\"#{0:s}\">{0:s}</a></h3>\n", name)
		switch e.kind {
		case .Invalid, .Import_Name, .Library_Name:
			// ignore
		case .Constant:
		case .Variable:
		case .Type_Name:
		case .Procedure:
			fmt.wprint(w, "<pre>")
			fmt.wprintf(w, "%s :: ", name)
			write_type(w, files[e.pos.file].pkg, types[e.type], nil)
			where_clauses := array(e.where_clauses)
			if len(where_clauses) != 0 {
				io.write_string(w, " where ")
				for clause, i in where_clauses {
					if i > 0 {
						io.write_string(w, ", ")
					}
					io.write_string(w, str(clause))
				}
			}

			fmt.wprint(w, " {…}")
			fmt.wprintln(w, "</pre>")
		case .Proc_Group:
		}

		write_docs(w, pkg, strings.trim_space(str(e.docs)))
	}
	print_entities :: proc(w: io.Writer, title: string, entities: []^doc.Entity) {
		fmt.wprintf(w, "<h3>%s</h3>\n", title)
		fmt.wprintln(w, `<section class="documentation">`)
		for e in entities {
			print_entity(w, e)
		}
		fmt.wprintln(w, "</section>")
	}

	print_entities(w, "Procedures",       pkg_procs[:])
	print_entities(w, "Procedure Groups", pkg_proc_groups[:])
	print_entities(w, "Types",            pkg_types[:])
	print_entities(w, "Variables",        pkg_vars[:])
	print_entities(w, "Constants",        pkg_consts[:])


	fmt.wprintln(w, "<h3>Source Files</h3>")
	fmt.wprintln(w, "<ul>")
	for file_index in array(pkg.files) {
		file := files[file_index]
		filename := slashpath.base(str(file.name))
		fmt.wprintf(w, `<li><a href="https://github.com/odin-lang/Odin/tree/master/core/%s/%s">%s</a></li>`, path, filename, filename)
		fmt.wprintln(w)
	}
	fmt.wprintln(w, "</ul>")

}