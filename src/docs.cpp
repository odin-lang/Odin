// Generates Documentation

gbString expr_to_string(AstNode *expression);

String alloc_comment_group_string(gbAllocator a, CommentGroup g) {
	isize len = 0;
	for_array(i, g.list) {
		String comment = g.list[i].string;
		len += comment.len;
		len += 1; // for \n
	}
	if (len == 0) {
		return make_string(nullptr, 0);
	}

	u8 *text = gb_alloc_array(a, u8, len+1);
	len = 0;
	for_array(i, g.list) {
		String comment = g.list[i].string;
		if (comment[1] == '/') {
			comment.text += 2;
			comment.len  -= 2;
		} else if (comment[1] == '*') {
			comment.text += 2;
			comment.len  -= 4;
		}
		comment = string_trim_whitespace(comment);
		gb_memmove(text+len, comment.text, comment.len);
		len += comment.len;
		text[len++] = '\n';
	}
	return make_string(text, len);
}

#if 0
void print_type_spec(AstNode *spec) {
	ast_node(ts, TypeSpec, spec);
	GB_ASSERT(ts->name->kind == AstNode_Ident);
	String name = ts->name->Ident.string;
	if (name.len == 0) {
		return;
	}
	if (name[0] == '_') {
		return;
	}
	gb_printf("type %.*s\n", LIT(name));
}

void print_proc_decl(AstNodeProcDecl *pd) {
	GB_ASSERT(pd->name->kind == AstNode_Ident);
	String name = pd->name->Ident.string;
	if (name.len == 0) {
		return;
	}
	if (name[0] == '_') {
		return;
	}

	String docs = alloc_comment_group_string(heap_allocator(), pd->docs);
	defer (gb_free(heap_allocator(), docs.text));

	if (docs.len > 0) {
		gb_file_write(&gb__std_files[gbFileStandard_Output], docs.text, docs.len);
	} else {
		return;
	}

	ast_node(proc_type, ProcType, pd->type);

	gbString params = expr_to_string(proc_type->params);
	defer (gb_string_free(params));
	gb_printf("proc %.*s(%s)", LIT(name), params);
	if (proc_type->results != nullptr)  {
		ast_node(fl, FieldList, proc_type->results);
		isize count = fl->list.count;
		if (count > 0) {
			gbString results = expr_to_string(proc_type->results);
			defer (gb_string_free(results));
			gb_printf(" -> ");
			if (count != 1) {
				gb_printf("(");
			}
			gb_printf("%s", results);
			if (count != 1) {
				gb_printf(")");
			}
		}
	}
	gb_printf("\n\n");
}
#endif
void print_declaration(AstNode *decl) {
}

void generate_documentation(Parser *parser) {
	for_array(file_index, parser->files) {
		AstFile *file = parser->files[file_index];
		Tokenizer *tokenizer = &file->tokenizer;
		String fullpath = tokenizer->fullpath;
		gb_printf("%.*s\n", LIT(fullpath));

		for_array(decl_index, file->decls) {
			AstNode *decl = file->decls[decl_index];
			print_declaration(decl);
		}
	}
}
