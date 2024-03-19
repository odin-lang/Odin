// Generates Documentation

gb_global int print_entity_kind_ordering[Entity_Count] = {
	/*Invalid*/     -1,
	/*Constant*/    0,
	/*Variable*/    1,
	/*TypeName*/    4,
	/*Procedure*/   2,
	/*ProcGroup*/   3,
	/*Builtin*/     -1,
	/*ImportName*/  -1,
	/*LibraryName*/ -1,
	/*Nil*/         -1,
	/*Label*/       -1,
};
gb_global char const *print_entity_names[Entity_Count] = {
	/*Invalid*/     "",
	/*Constant*/    "constants",
	/*Variable*/    "variables",
	/*TypeName*/    "types",
	/*Procedure*/   "procedures",
	/*ProcGroup*/   "proc_group",
	/*Builtin*/     "",
	/*ImportName*/  "import names",
	/*LibraryName*/ "library names",
	/*Nil*/         "",
	/*Label*/       "",
};


gb_internal GB_COMPARE_PROC(cmp_entities_for_printing) {
	GB_ASSERT(a != nullptr);
	GB_ASSERT(b != nullptr);
	Entity *x = *cast(Entity **)a;
	Entity *y = *cast(Entity **)b;
	int res = 0;
	if (x->pkg != y->pkg) {
		if (x->pkg == nullptr) {
			return -1;
		}
		if (y->pkg == nullptr) {
			return +1;
		}
		res = string_compare(x->pkg->name, y->pkg->name);
		if (res != 0) {
			return res;
		}
	}
	int ox = print_entity_kind_ordering[x->kind];
	int oy = print_entity_kind_ordering[y->kind];
	res = ox - oy;
	if (res == 0) {
		res = string_compare(x->token.string, y->token.string);
	}
	return res;
}

gb_internal GB_COMPARE_PROC(cmp_ast_package_by_name) {
	GB_ASSERT(a != nullptr);
	GB_ASSERT(b != nullptr);
	AstPackage *x = *cast(AstPackage **)a;
	AstPackage *y = *cast(AstPackage **)b;
	return string_compare(x->name, y->name);
}

#include "docs_format.cpp"
#include "docs_writer.cpp"

gb_internal void print_doc_line(i32 indent, String const &data) {
	while (indent --> 0) {
		gb_printf("\t");
	}
	gb_file_write(gb_file_get_standard(gbFileStandard_Output), data.text, data.len);
	gb_printf("\n");
}

gb_internal void print_doc_line(i32 indent, char const *fmt, ...) {
	while (indent --> 0) {
		gb_printf("\t");
	}
	va_list va;
	va_start(va, fmt);
	gb_printf_va(fmt, va);
	va_end(va);
	gb_printf("\n");
}
gb_internal void print_doc_line_no_newline(i32 indent, String const &data) {
	while (indent --> 0) {
		gb_printf("\t");
	}
	gb_file_write(gb_file_get_standard(gbFileStandard_Output), data.text, data.len);
}


gb_internal bool print_doc_comment_group_string(i32 indent, CommentGroup *g) {
	if (g == nullptr) {
		return false;
	}
	isize len = 0;
	for_array(i, g->list) {
		String comment = g->list[i].string;
		len += comment.len;
		len += 1; // for \n
	}
	if (len <= g->list.count) {
		return false;
	}

	isize count = 0;
	for_array(i, g->list) {
		String comment = g->list[i].string;
		String original_comment = comment;

		bool slash_slash = false;
		if (comment[1] == '/') {
			slash_slash = true;
			comment.text += 2;
			comment.len  -= 2;
		} else if (comment[1] == '*') {
			comment.text += 2;
			comment.len  -= 4;
		}

		// Ignore the first space
		if (comment.len > 0 && comment[0] == ' ') {
			comment.text += 1;
			comment.len  -= 1;
		}

		if (slash_slash) {
			if (string_starts_with(comment, str_lit("+"))) {
				continue;
			}
			if (string_starts_with(comment, str_lit("@("))) {
				continue;
			}
		}

		if (slash_slash) {
			print_doc_line(indent, comment);
			count += 1;
		} else {
			isize pos = 0;
			for (; pos < comment.len; pos++) {
				isize end = pos;
				for (; end < comment.len; end++) {
					if (comment[end] == '\n') {
						break;
					}
				}
				String line = substring(comment, pos, end);
				pos = end;
				String trimmed_line = string_trim_whitespace(line);
				if (trimmed_line.len == 0) {
					if (count == 0) {
						continue;
					}
				}
				/*
				 * Remove comments with
				 * styles
				 * like this
				 */
				if (string_starts_with(line, str_lit("* "))) {
					line = substring(line, 2, line.len);
				}

				print_doc_line(indent, line);
				count += 1;
			}
		}
	}

	if (count > 0) {
		print_doc_line(0, "");
		return true;
	}
	return false;
}




gb_internal void print_doc_expr(Ast *expr) {
	gbString s = nullptr;
	if (build_context.cmd_doc_flags & CmdDocFlag_Short) {
		s = expr_to_string_shorthand(expr);
	} else {
		s = expr_to_string(expr);
	}
	gb_file_write(gb_file_get_standard(gbFileStandard_Output), s, gb_string_length(s));
	gb_string_free(s);
}

gb_internal void print_doc_package(CheckerInfo *info, AstPackage *pkg) {
	if (pkg == nullptr) {
		return;
	}

	print_doc_line(0, "package %.*s", LIT(pkg->name));


	for_array(i, pkg->files) {
		AstFile *f = pkg->files[i];
		if (f->pkg_decl) {
			GB_ASSERT(f->pkg_decl->kind == Ast_PackageDecl);
			print_doc_comment_group_string(1, f->pkg_decl->PackageDecl.docs);
		}
	}

	if (pkg->scope != nullptr) {
		auto entities = array_make<Entity *>(heap_allocator(), 0, pkg->scope->elements.count);
		defer (array_free(&entities));
		for (auto const &entry : pkg->scope->elements) {
			Entity *e = entry.value;
			switch (e->kind) {
			case Entity_Invalid:
			case Entity_Builtin:
			case Entity_Nil:
			case Entity_Label:
				continue;
			case Entity_Constant:
			case Entity_Variable:
			case Entity_TypeName:
			case Entity_Procedure:
			case Entity_ProcGroup:
			case Entity_ImportName:
			case Entity_LibraryName:
				// Fine
				break;
			}
			if (e->pkg != pkg) {
				continue;
			}
			if (!is_entity_exported(e)) {
				continue;
			}
			array_add(&entities, e);
		}
		array_sort(entities, cmp_entities_for_printing);

		bool show_docs = (build_context.cmd_doc_flags & CmdDocFlag_Short) == 0;

		EntityKind curr_entity_kind = Entity_Invalid;
		for (Entity *e : entities) {
			if (curr_entity_kind != e->kind) {
				if (curr_entity_kind != Entity_Invalid) {
					print_doc_line(0, "");
				}
				curr_entity_kind = e->kind;
				print_doc_line(1, "%s", print_entity_names[e->kind]);
			}

			Ast *type_expr = nullptr;
			Ast *init_expr = nullptr;
			Ast *decl_node = nullptr;
			CommentGroup *comment = nullptr;
			CommentGroup *docs = nullptr;
			if (e->decl_info != nullptr) {
				type_expr = e->decl_info->type_expr;
				init_expr = e->decl_info->init_expr;
				decl_node = e->decl_info->decl_node;
				comment = e->decl_info->comment;
				docs = e->decl_info->docs;
			}
			GB_ASSERT(type_expr != nullptr || init_expr != nullptr);

			print_doc_line_no_newline(2, e->token.string);
			if (type_expr != nullptr) {
				gbString t = expr_to_string(type_expr);
				gb_printf(": %s ", t);
				gb_string_free(t);
			} else {
				gb_printf(" :");
			}
			if (e->kind == Entity_Variable) {
				if (init_expr != nullptr) {
					gb_printf("= ");
					print_doc_expr(init_expr);
				}
			} else {
				gb_printf(": ");
				print_doc_expr(init_expr);
			}

			gb_printf("\n");

			if (show_docs) {
				print_doc_comment_group_string(3, docs);
			}
		}
		print_doc_line(0, "");
	}

	if (pkg->fullpath.len != 0) {
		print_doc_line(0, "");
		print_doc_line(1, "fullpath:");
		print_doc_line(2, "%.*s", LIT(pkg->fullpath));
		print_doc_line(1, "files:");
		for_array(i, pkg->files) {
			AstFile *f = pkg->files[i];
			String filename = remove_directory_from_path(f->fullpath);
			print_doc_line(2, filename);
		}
	}

}

gb_internal void generate_documentation(Checker *c) {
	CheckerInfo *info = &c->info;

	if (build_context.cmd_doc_flags & CmdDocFlag_DocFormat) {
		String init_fullpath = c->parser->init_fullpath;
		String output_name = {};
		String output_base = {};

		if (build_context.out_filepath.len == 0) {
			output_name = remove_directory_from_path(init_fullpath);
			output_name = remove_extension_from_path(output_name);
			output_name = string_trim_whitespace(output_name);
			if (output_name.len == 0) {
				output_name = info->init_scope->pkg->name;
			}
			output_base = output_name;
		} else {
			output_name = build_context.out_filepath;
			output_name = string_trim_whitespace(output_name);
			if (output_name.len == 0) {
				output_name = info->init_scope->pkg->name;
			}
			isize pos = string_extension_position(output_name);
			if (pos < 0) {
				output_base = output_name;
			} else {
				output_base = substring(output_name, 0, pos);
			}
		}

		output_base = path_to_full_path(permanent_allocator(), output_base);

		gbString output_file_path = gb_string_make_length(heap_allocator(), output_base.text, output_base.len);
		output_file_path = gb_string_appendc(output_file_path, ".odin-doc");
		defer (gb_string_free(output_file_path));

		odin_doc_write(info, output_file_path);
	} else {
		auto pkgs = array_make<AstPackage *>(permanent_allocator(), 0, info->packages.count);
		for (auto const &entry : info->packages) {
			AstPackage *pkg = entry.value;
			if (build_context.cmd_doc_flags & CmdDocFlag_AllPackages) {
				array_add(&pkgs, pkg);
			} else {
				if (pkg->kind == Package_Init) {
					array_add(&pkgs, pkg);
				} else if (pkg->is_extra) {
					array_add(&pkgs, pkg);
				}
			}
		}

		array_sort(pkgs, cmp_ast_package_by_name);

		for_array(i, pkgs) {
			print_doc_package(info, pkgs[i]);
		}
	}
}
