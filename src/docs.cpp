// Generates Documentation

gbString expr_to_string(AstNode *expression);

void print_declaration(Parser *parser, AstNode *decl) {
	switch (decl->kind) {
	case_ast_node(pd, ProcDecl, decl);
		GB_ASSERT(pd->name->kind == AstNode_Ident);
		String name = pd->name->Ident.string;
		if (name.len == 0) {
			break;
		}
		if (name[0] == '_') {
			break;
		}

		for_array(i, pd->docs.list) {
			String comment = pd->docs.list[i].string;
			if (comment[1] == '/') {
				comment.text += 2;
				comment.len  -= 2;
			} else if (comment[1] == '*') {
				comment.text += 2;
				comment.len  -= 4;
			}
			comment = string_trim_whitespace(comment);

			gb_printf("%.*s\n", LIT(comment));
		}

		ast_node(proc_type, ProcType, pd->type);

		gbString params = expr_to_string(proc_type->params);
		defer (gb_string_free(params));
		gb_printf("proc %.*s(%s)", LIT(name), params);
		if (proc_type->results != NULL)  {
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
	case_end;

	case_ast_node(gd, GenDecl, decl);
	case_end;
	}
}

void generate_documentation(Parser *parser) {
	for_array(file_index, parser->files) {
		AstFile *file = &parser->files[file_index];
		Tokenizer *tokenizer = &file->tokenizer;
		String fullpath = tokenizer->fullpath;
		gb_printf("%.*s\n", LIT(fullpath));

		for_array(decl_index, file->decls) {
			AstNode *decl = file->decls[decl_index];
			print_declaration(parser, decl);
		}
	}
}
