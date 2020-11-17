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


GB_COMPARE_PROC(cmp_entities_for_printing) {
	GB_ASSERT(a != nullptr);
	GB_ASSERT(b != nullptr);
	Entity *x = *cast(Entity **)a;
	Entity *y = *cast(Entity **)b;
	int res = 0;
	res = string_compare(x->pkg->name, y->pkg->name);
	if (res != 0) {
		return res;
	}
	int ox = print_entity_kind_ordering[x->kind];
	int oy = print_entity_kind_ordering[y->kind];
	if (ox < oy) {
		return -1;
	} else if (ox > oy) {
		return +1;
	}
	res = string_compare(x->token.string, y->token.string);
	return res;
}


gbString expr_to_string(Ast *expression);
gbString type_to_string(Type *type);

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

void generate_documentation(Checker *c) {
	CheckerInfo *info = &c->info;

}
