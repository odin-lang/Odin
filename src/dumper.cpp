enum JSONStartLine {
	JSON_WithCommaNewLine,
	JSON_WithJustNewLine,
	JSON_WithNothing,
};

struct AstDumper {
	Array<gbString> buffers;
	PtrMap<Ast*, u32> ast_to_id;
	int indent;
	String indent_string;
	bool omit_defaults;
	bool no_ids;
	isize buffer_size;

	bool sexp_attributes;
	JSONStartLine json_start_line;
	bool xml_newline_before_end_attributes;

	void (*begin_dump)(AstDumper *dumper, String name, int version);
	void (*end_dump)(AstDumper *dumper, String name);
	void (*begin_multi_field)(AstDumper *dumper, String name);
	void (*end_multi_field)(AstDumper *dumper, String name);
	void (*add_empty_multi_field)(AstDumper *dumper, String name);
	void (*begin_field)(AstDumper *dumper, String name);
	void (*end_field)(AstDumper *dumper, String name);
	void (*add_empty_field)(AstDumper *dumper, String name);
	void (*add_string_attribute)(AstDumper *dumper, String name, String value);
	void (*add_int_attribute)(AstDumper *dumper, String name, i64 value);
	void (*add_inline_value)(AstDumper *dumper, String name, String value);
	void (*open_object_and_begin_attributes)(AstDumper *dumper, String type);
	void (*end_attributes_and_close_object)(AstDumper *dumper, String type);
	void (*end_attributes)(AstDumper *dumper, String type);
	void (*close_object)(AstDumper *dumper, String type);
};

gb_internal void ast_dumper_write_string(AstDumper *dumper, String str) {
	GB_ASSERT(dumper->buffers.count > 0);
	gbString *buffer = &dumper->buffers[dumper->buffers.count - 1];
	isize left = str.len;
	isize to_write = gb_min(left, gb_string_available_space(*buffer));
	*buffer = gb_string_append_length(*buffer, str.text, to_write);
	isize written = to_write;
	left -= to_write;
	while (left > 0) {
		buffer = array_add_and_get(&dumper->buffers);
		*buffer = gb_string_make_reserve(temporary_allocator(), dumper->buffer_size);
		to_write = gb_min(left, gb_string_available_space(*buffer));
		*buffer = gb_string_append_length(*buffer, str.text + written, to_write);
		written += to_write;
		left -= to_write;
	}
}

#define WRITE_LIT_STR(dumper, lit_str) ast_dumper_write_string(dumper, STR_LIT(lit_str))
#define WRITE_STRING(file, string) ast_dumper_write_string(file, string)

gb_internal void write_indent(AstDumper *dumper, int indent) {
	for (int i = 0; i < indent; i++) {
		WRITE_STRING(dumper, dumper->indent_string);
	}
}

// sexp output

gb_internal void dump_sexp_symbol(AstDumper *dumper, String name) {
	isize prev = 0;
	for (isize i = 0; i < name.len; i++) {
		switch (name.text[i]) {
		case '#':
			WRITE_STRING(dumper, substring(name, prev, i));
			prev = i + 1;
			break;
		case ' ':
			WRITE_STRING(dumper, substring(name, prev, i));
			WRITE_LIT_STR(dumper, "-");
			prev = i + 1;
			break;
		}
	}
	WRITE_STRING(dumper, substring(name, prev, name.len));
}

gb_internal void dump_sexp_string(AstDumper *dumper, String string) {
	// TODO: figure out if there is anything else to do other than
	// escaping double quotes
	isize prev = 0;
	for (isize i = 0; i < string.len; i++) {
		if (string.text[i] == '"') {
			WRITE_STRING(dumper, substring(string, prev, i));
			WRITE_LIT_STR(dumper, "\\\"");
			prev = i + 1;
		}
	}
	WRITE_STRING(dumper, substring(string, prev, string.len));
}

gb_internal void dump_i64(AstDumper *dumper, i64 num) {
	char buf[21] = {};
	gb_i64_to_str(num, buf, 10);
	String str = make_string(cast(u8 *)buf, -1);
	WRITE_STRING(dumper, str);
}

gb_internal void ast_dumper_sexp_begin_dump(AstDumper *dumper, String name, int version) {
	WRITE_LIT_STR(dumper, "(");
	dump_sexp_symbol(dumper, name);
	WRITE_LIT_STR(dumper, " (version ");
	dump_i64(dumper, version);
	WRITE_LIT_STR(dumper, ") (");
	dumper->indent++;
}

gb_internal void ast_dumper_sexp_end_dump(AstDumper *dumper, String name) {
	dumper->indent--;
	WRITE_LIT_STR(dumper, "))");
}

gb_internal void sexp_new_line(AstDumper *dumper) {
	if (dumper->sexp_attributes) {
		WRITE_LIT_STR(dumper, " ");
	} else {
		WRITE_LIT_STR(dumper, "\n");
		write_indent(dumper, dumper->indent);
	}
}

gb_internal void ast_dumper_sexp_begin_multi_field(AstDumper *dumper, String name) {
	sexp_new_line(dumper);
	WRITE_LIT_STR(dumper, "(");
	dump_sexp_symbol(dumper, name);
	WRITE_LIT_STR(dumper, " (");
	dumper->indent++;
}

gb_internal void ast_dumper_sexp_end_multi_field(AstDumper *dumper, String name) {
	WRITE_LIT_STR(dumper, "))");
	dumper->indent--;
}

gb_internal void ast_dumper_sexp_add_empty_multi_field(AstDumper *dumper, String name) {
	sexp_new_line(dumper);
	WRITE_LIT_STR(dumper, "(");
	dump_sexp_symbol(dumper, name);
	WRITE_LIT_STR(dumper, "\n");
	write_indent(dumper, dumper->indent + 1);
	WRITE_LIT_STR(dumper, "())");
}

gb_internal void ast_dumper_sexp_begin_field(AstDumper *dumper, String name) {
	sexp_new_line(dumper);
	WRITE_LIT_STR(dumper, "(");
	dump_sexp_symbol(dumper, name);
	dumper->indent++;
}

gb_internal void ast_dumper_sexp_end_field(AstDumper *dumper, String name) {
	WRITE_LIT_STR(dumper, ")");
	dumper->indent--;
}

gb_internal void ast_dumper_sexp_add_empty_field(AstDumper *dumper, String name) {
	sexp_new_line(dumper);
	WRITE_LIT_STR(dumper, "(");
	dump_sexp_symbol(dumper, name);
	WRITE_LIT_STR(dumper, "())");
}

gb_internal void ast_dumper_sexp_add_string_attribute(AstDumper *dumper, String name, String value) {
	sexp_new_line(dumper);
	WRITE_LIT_STR(dumper, "(");
	dump_sexp_symbol(dumper, name);
	WRITE_LIT_STR(dumper, " \"");
	dump_sexp_string(dumper, value);
	WRITE_LIT_STR(dumper, "\")");
}

gb_internal void ast_dumper_sexp_add_int_attribute(AstDumper *dumper, String name, i64 value) {
	sexp_new_line(dumper);
	WRITE_LIT_STR(dumper, "(");
	dump_sexp_symbol(dumper, name);
	WRITE_LIT_STR(dumper, " ");
	dump_i64(dumper, value);
	WRITE_LIT_STR(dumper, ")");
}

gb_internal void ast_dumper_sexp_add_inline_value(AstDumper *dumper, String name, String value) {
	sexp_new_line(dumper);
	WRITE_LIT_STR(dumper, "(\"");
	dump_sexp_string(dumper, value);
	WRITE_LIT_STR(dumper, "\")");
}

gb_internal void ast_dumper_sexp_open_object_and_begin_attributes(AstDumper *dumper, String type) {
	sexp_new_line(dumper);
	WRITE_LIT_STR(dumper, "(");
	dump_sexp_symbol(dumper, type);
	dumper->indent++;
	dumper->sexp_attributes = true;
}

gb_internal void ast_dumper_sexp_end_attributes_and_close_object(AstDumper *dumper, String type) {
	dumper->sexp_attributes = false;
	WRITE_LIT_STR(dumper, ")");
	dumper->indent--;
}

gb_internal void ast_dumper_sexp_end_attributes(AstDumper *dumper, String type) {
	dumper->sexp_attributes = false;
}

gb_internal void ast_dumper_sexp_close_object(AstDumper *dumper, String type) {
	WRITE_LIT_STR(dumper, ")");
	dumper->indent--;
}

// json output

gb_internal void dump_json_value(AstDumper* dumper, String name) {
	// TODO: figure out if there is anything else to do other than
	// escaping double quotes
	isize prev = 0;
	for (isize i = 0; i < name.len; i++) {
		switch (name.text[i]) {
		case '"':
			WRITE_STRING(dumper, substring(name, prev, i));
			WRITE_LIT_STR(dumper, "\\");
			prev = i;
			break;
		case '\\':
			WRITE_STRING(dumper, substring(name, prev, i));
			WRITE_LIT_STR(dumper, "\\");
			prev = i;
			break;
#define JSON_ESCAPE_CASE(c, e) \
		case c: \
			WRITE_STRING(dumper, substring(name, prev, i)); \
			WRITE_LIT_STR(dumper, e); \
			prev = i + 1; \
			break
		JSON_ESCAPE_CASE('\n', "\\n");
		JSON_ESCAPE_CASE('\b', "\\b");
		JSON_ESCAPE_CASE('\r', "\\r");
		JSON_ESCAPE_CASE('\f', "\\f");
		JSON_ESCAPE_CASE('\t', "\\t");
#undef JSON_ESCAPE_CASE
		}
	}
	WRITE_STRING(dumper, substring(name, prev, name.len));
}

gb_internal void ast_dumper_json_start_new_line(AstDumper *dumper) {
	switch (dumper->json_start_line) {
	case JSON_WithCommaNewLine:
		WRITE_LIT_STR(dumper, ",\n");
		write_indent(dumper, dumper->indent);
		break;
	case JSON_WithJustNewLine:
		WRITE_LIT_STR(dumper, "\n");
		write_indent(dumper, dumper->indent);
		break;
	case JSON_WithNothing:
		break;
	}
	dumper->json_start_line = JSON_WithCommaNewLine;
}

gb_internal void ast_dumper_json_begin_multi_field(AstDumper *dumper, String name);
gb_internal void ast_dumper_json_end_multi_field(AstDumper *dumper, String name);
gb_internal void ast_dumper_json_begin_field(AstDumper *dumper, String name);
gb_internal void ast_dumper_json_end_field(AstDumper *dumper, String name);

gb_internal void ast_dumper_json_begin_dump(AstDumper *dumper, String name, int version) {
	WRITE_LIT_STR(dumper, "{");
	dumper->indent++;
	dumper->json_start_line = JSON_WithJustNewLine;
	ast_dumper_json_begin_field(dumper, STR_LIT("version"));
	dump_i64(dumper, version);
	dumper->json_start_line = JSON_WithCommaNewLine;
	ast_dumper_json_begin_multi_field(dumper, name);
}

gb_internal void ast_dumper_json_end_dump(AstDumper *dumper, String name) {
	ast_dumper_json_end_multi_field(dumper, name);
	dumper->indent--;
	WRITE_LIT_STR(dumper, "\n}");
}

gb_internal void ast_dumper_json_begin_multi_field(AstDumper *dumper, String name) {
	ast_dumper_json_start_new_line(dumper);
	WRITE_LIT_STR(dumper, "\"");
	dump_json_value(dumper, name);
	WRITE_LIT_STR(dumper, "\": [");
	dumper->indent++;
	dumper->json_start_line = JSON_WithJustNewLine;
}

gb_internal void ast_dumper_json_end_multi_field(AstDumper *dumper, String name) {
	dumper->indent--;
	WRITE_LIT_STR(dumper, "\n");
	write_indent(dumper, dumper->indent);
	WRITE_LIT_STR(dumper, "]");
}

gb_internal void ast_dumper_json_add_empty_multi_field(AstDumper *dumper, String name) {
	ast_dumper_json_start_new_line(dumper);
	WRITE_LIT_STR(dumper, "\"");
	dump_json_value(dumper, name);
	WRITE_LIT_STR(dumper, "\": []");
}

gb_internal void ast_dumper_json_begin_field(AstDumper *dumper, String name) {
	ast_dumper_json_start_new_line(dumper);
	WRITE_LIT_STR(dumper, "\"");
	dump_json_value(dumper, name);
	WRITE_LIT_STR(dumper, "\": ");
	dumper->json_start_line = JSON_WithNothing;
}

gb_internal void ast_dumper_json_end_field(AstDumper *dumper, String name) {
	// Nothing to do
}

gb_internal void ast_dumper_json_add_empty_field(AstDumper *dumper, String name) {
	ast_dumper_json_start_new_line(dumper);
	WRITE_LIT_STR(dumper, "\"");
	dump_json_value(dumper, name);
	WRITE_LIT_STR(dumper, "\": null");
}

gb_internal void ast_dumper_json_add_string_attribute(AstDumper *dumper, String name, String value) {
	ast_dumper_json_start_new_line(dumper);
	WRITE_LIT_STR(dumper, "\"");
	dump_json_value(dumper, name);
	WRITE_LIT_STR(dumper, "\": \"");
	dump_json_value(dumper, value);
	WRITE_LIT_STR(dumper, "\"");
}

gb_internal void ast_dumper_json_add_int_attribute(AstDumper *dumper, String name, i64 value) {
	ast_dumper_json_start_new_line(dumper);
	WRITE_LIT_STR(dumper, "\"");
	dump_json_value(dumper, name);
	WRITE_LIT_STR(dumper, "\": ");
	dump_i64(dumper, value);
	WRITE_LIT_STR(dumper, "");
}

gb_internal void ast_dumper_json_add_inline_value(AstDumper *dumper, String name, String value) {
	ast_dumper_json_start_new_line(dumper);
	WRITE_LIT_STR(dumper, "\"");
	dump_json_value(dumper, value);
	WRITE_LIT_STR(dumper, "\"");
}

gb_internal void ast_dumper_json_open_object_and_begin_attributes(AstDumper *dumper, String type) {
	ast_dumper_json_start_new_line(dumper);
	WRITE_LIT_STR(dumper, "{");
	dumper->indent++;
	dumper->json_start_line = JSON_WithJustNewLine;
	ast_dumper_json_add_string_attribute(dumper, STR_LIT("obj-type"), type);
}

gb_internal void ast_dumper_json_end_attributes_and_close_object(AstDumper *dumper, String type) {
	dumper->indent--;
	WRITE_LIT_STR(dumper, "\n");
	write_indent(dumper, dumper->indent);
	WRITE_LIT_STR(dumper, "}");
}

gb_internal void ast_dumper_json_end_attributes(AstDumper *dumper, String type) {
	// Nothing to do.
}

gb_internal void ast_dumper_json_close_object(AstDumper *dumper, String type) {
	ast_dumper_json_end_attributes_and_close_object(dumper, type);
}

// xml output

gb_internal void dump_xml_name(AstDumper *dumper, String name) {
	isize prev = 0;
	for (isize i = 0; i < name.len; i++) {
		switch (name.text[i]) {
		case '#':
			WRITE_STRING(dumper, substring(name, prev, i));
			prev = i + 1;
			break;
		case ' ':
			WRITE_STRING(dumper, substring(name, prev, i));
			WRITE_LIT_STR(dumper, "_");
			prev = i + 1;
			break;
		}
	}
	WRITE_STRING(dumper, substring(name, prev, name.len));
}

gb_internal void dump_xml_data(AstDumper *dumper, String value) {
	isize prev = 0;
	String replacement = STR_LIT("");
	for (isize i = 0; i < value.len; i++) {
		switch (value.text[i]) {
		case '<':
			replacement = STR_LIT("&lt;");
			break;
		case '>':
			replacement = STR_LIT("&gt;");
			break;
		case '"':
			replacement = STR_LIT("&quot;");
			break;
		case '\'':
			replacement = STR_LIT("&apos;");
			break;
		case '&':
			replacement = STR_LIT("&amp;");
			break;
		}
		if (replacement.len > 0) {
			WRITE_STRING(dumper, substring(value, prev, i));
			WRITE_STRING(dumper, replacement);
			replacement.len = 0;
			prev = i + 1;
		}
	}
	WRITE_STRING(dumper, substring(value, prev, value.len));
}

gb_internal void ast_dumper_xml_begin_dump(AstDumper *dumper, String name, int version) {
	WRITE_LIT_STR(dumper, "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<");
	dump_xml_name(dumper, name);
	WRITE_LIT_STR(dumper, " version=\"");
	dump_i64(dumper, version);
	WRITE_LIT_STR(dumper, "\">");
	dumper->indent++;
}

gb_internal void ast_dumper_xml_end_dump(AstDumper *dumper, String name) {
	dumper->indent--;
	WRITE_LIT_STR(dumper, "</");
	dump_xml_name(dumper, name);
	WRITE_LIT_STR(dumper, ">");
}

gb_internal void ast_dumper_xml_begin_multi_field(AstDumper *dumper, String name) {
	WRITE_LIT_STR(dumper, "\n");
	write_indent(dumper, dumper->indent);
	WRITE_LIT_STR(dumper, "<");
	dump_xml_name(dumper, name);
	dumper->indent++;
	WRITE_LIT_STR(dumper, ">");
}

gb_internal void ast_dumper_xml_end_multi_field(AstDumper *dumper, String name) {
	dumper->indent--;
	WRITE_LIT_STR(dumper, "\n");
	write_indent(dumper, dumper->indent);
	WRITE_LIT_STR(dumper, "</");
	dump_xml_name(dumper, name);
	WRITE_LIT_STR(dumper, ">");
}

gb_internal void ast_dumper_xml_add_empty_multi_field(AstDumper *dumper, String name) {
	WRITE_LIT_STR(dumper, "\n");
	write_indent(dumper, dumper->indent);
	WRITE_LIT_STR(dumper, "<");
	dump_xml_name(dumper, name);
	WRITE_LIT_STR(dumper, "/>");
}

gb_internal void ast_dumper_xml_begin_field(AstDumper *dumper, String name) {
	ast_dumper_xml_begin_multi_field(dumper, name);
}

gb_internal void ast_dumper_xml_end_field(AstDumper *dumper, String name) {
	ast_dumper_xml_end_multi_field(dumper, name);
}

gb_internal void ast_dumper_xml_add_empty_field(AstDumper *dumper, String name) {
	ast_dumper_xml_add_empty_multi_field(dumper, name);
}

gb_internal void ast_dumper_xml_add_string_attribute(AstDumper *dumper, String name, String value) {
	WRITE_LIT_STR(dumper, "\n");
	write_indent(dumper, dumper->indent);
	dump_xml_name(dumper, name);
	WRITE_LIT_STR(dumper, "=\"");
	dump_xml_data(dumper, value);
	WRITE_LIT_STR(dumper, "\"");
	dumper->xml_newline_before_end_attributes = true;
}

gb_internal void ast_dumper_xml_add_int_attribute(AstDumper *dumper, String name, i64 value) {
	WRITE_LIT_STR(dumper, "\n");
	write_indent(dumper, dumper->indent);
	dump_xml_name(dumper, name);
	WRITE_LIT_STR(dumper, "=\"");
	dump_i64(dumper, value);
	WRITE_LIT_STR(dumper, "\"");
	dumper->xml_newline_before_end_attributes = true;
}

gb_internal void ast_dumper_xml_add_inline_value(AstDumper *dumper, String name, String value) {
	WRITE_LIT_STR(dumper, "\n");
	write_indent(dumper, dumper->indent);
	WRITE_LIT_STR(dumper, "<");
	dump_xml_name(dumper, name);
	WRITE_LIT_STR(dumper, ">");
	dump_xml_data(dumper, value);
	WRITE_LIT_STR(dumper, "</");
	dump_xml_name(dumper, name);
	WRITE_LIT_STR(dumper, ">");
}

gb_internal void ast_dumper_xml_open_object_and_begin_attributes(AstDumper *dumper, String type) {
	WRITE_LIT_STR(dumper, "\n");
	write_indent(dumper, dumper->indent);
	WRITE_LIT_STR(dumper, "<");
	dump_xml_name(dumper, type);
	dumper->indent++;
}

gb_internal void ast_dumper_xml_before_attributes_end(AstDumper *dumper) {
	if (!dumper->xml_newline_before_end_attributes) {
		return;
	}
	dumper->xml_newline_before_end_attributes = false;
	WRITE_LIT_STR(dumper, "\n");
	write_indent(dumper, dumper->indent - 1);
}

gb_internal void ast_dumper_xml_end_attributes_and_close_object(AstDumper *dumper, String type) {
	ast_dumper_xml_before_attributes_end(dumper);
	WRITE_LIT_STR(dumper, "/>");
	dumper->indent--;
}

gb_internal void ast_dumper_xml_end_attributes(AstDumper *dumper, String type) {
	ast_dumper_xml_before_attributes_end(dumper);
	WRITE_LIT_STR(dumper, ">");
}

gb_internal void ast_dumper_xml_close_object(AstDumper *dumper, String type) {
	dumper->indent--;
	WRITE_LIT_STR(dumper, "\n");
	write_indent(dumper, dumper->indent);
	WRITE_LIT_STR(dumper, "</");
	dump_xml_name(dumper, type);
	WRITE_LIT_STR(dumper, ">");
}

gb_internal void ast_dumper_init(AstDumper *dumper, bool omit_defaults, bool no_ids, DumpAstFormat format) {
	isize buffer_size = 0;
	if (format == DumpAstFormat_Default) {
		format = DumpAstFormat_SEXP;
	}
	// these buffer size seem to be enough for ~90% of files from
	// odin standard library
	switch (format) {
	case DumpAstFormat_SEXP:
		buffer_size = omit_defaults ? 256 * 1024 : 784 * 1024;
		break;
	case DumpAstFormat_JSON:
		buffer_size = omit_defaults ? 448 * 1024 : 1280 * 1024;
		break;
	case DumpAstFormat_XML:
		buffer_size = omit_defaults ? 448 * 1024 : 1280 * 1024;
		break;
	default:
		GB_PANIC("unreachable");
	}
	// gbstring will add 1 for null terminator
	buffer_size--;
	GB_ASSERT(buffer_size > 0);
	array_init(&dumper->buffers, temporary_allocator(), 1);
	dumper->buffers[0] = gb_string_make_reserve(temporary_allocator(), buffer_size);
	// 4096 is large enough for ~90% of files from odin standard
	// library
	map_init(&dumper->ast_to_id, 4096);
	dumper->indent = 0;
	dumper->indent_string = STR_LIT("\t");
	dumper->omit_defaults = omit_defaults;
	dumper->no_ids = no_ids;
	dumper->buffer_size = buffer_size;

	switch (format) {
	case DumpAstFormat_SEXP:
		dumper->begin_dump = ast_dumper_sexp_begin_dump;
		dumper->end_dump = ast_dumper_sexp_end_dump;
		dumper->begin_multi_field = ast_dumper_sexp_begin_multi_field;
		dumper->end_multi_field = ast_dumper_sexp_end_multi_field;
		dumper->add_empty_multi_field = ast_dumper_sexp_add_empty_multi_field;
		dumper->begin_field = ast_dumper_sexp_begin_field;
		dumper->end_field = ast_dumper_sexp_end_field;
		dumper->add_empty_field = ast_dumper_sexp_add_empty_field;
		dumper->add_string_attribute = ast_dumper_sexp_add_string_attribute;
		dumper->add_int_attribute = ast_dumper_sexp_add_int_attribute;
		dumper->add_inline_value = ast_dumper_sexp_add_inline_value;
		dumper->open_object_and_begin_attributes = ast_dumper_sexp_open_object_and_begin_attributes;
		dumper->end_attributes_and_close_object = ast_dumper_sexp_end_attributes_and_close_object;
		dumper->end_attributes = ast_dumper_sexp_end_attributes;
		dumper->close_object = ast_dumper_sexp_close_object;
		break;
	case DumpAstFormat_JSON:
		dumper->begin_dump = ast_dumper_json_begin_dump;
		dumper->end_dump = ast_dumper_json_end_dump;
		dumper->begin_multi_field = ast_dumper_json_begin_multi_field;
		dumper->end_multi_field = ast_dumper_json_end_multi_field;
		dumper->add_empty_multi_field = ast_dumper_json_add_empty_multi_field;
		dumper->begin_field = ast_dumper_json_begin_field;
		dumper->end_field = ast_dumper_json_end_field;
		dumper->add_empty_field = ast_dumper_json_add_empty_field;
		dumper->add_string_attribute = ast_dumper_json_add_string_attribute;
		dumper->add_int_attribute = ast_dumper_json_add_int_attribute;
		dumper->add_inline_value = ast_dumper_json_add_inline_value;
		dumper->open_object_and_begin_attributes = ast_dumper_json_open_object_and_begin_attributes;
		dumper->end_attributes_and_close_object = ast_dumper_json_end_attributes_and_close_object;
		dumper->end_attributes = ast_dumper_json_end_attributes;
		dumper->close_object = ast_dumper_json_close_object;
		break;
	case DumpAstFormat_XML:
		dumper->begin_dump = ast_dumper_xml_begin_dump;
		dumper->end_dump = ast_dumper_xml_end_dump;
		dumper->begin_multi_field = ast_dumper_xml_begin_multi_field;
		dumper->end_multi_field = ast_dumper_xml_end_multi_field;
		dumper->add_empty_multi_field = ast_dumper_xml_add_empty_multi_field;
		dumper->begin_field = ast_dumper_xml_begin_field;
		dumper->end_field = ast_dumper_xml_end_field;
		dumper->add_empty_field = ast_dumper_xml_add_empty_field;
		dumper->add_string_attribute = ast_dumper_xml_add_string_attribute;
		dumper->add_int_attribute = ast_dumper_xml_add_int_attribute;
		dumper->add_inline_value = ast_dumper_xml_add_inline_value;
		dumper->open_object_and_begin_attributes = ast_dumper_xml_open_object_and_begin_attributes;
		dumper->end_attributes_and_close_object = ast_dumper_xml_end_attributes_and_close_object;
		dumper->end_attributes = ast_dumper_xml_end_attributes;
		dumper->close_object = ast_dumper_xml_close_object;
		break;
	default:
		GB_PANIC("unreachable");
	}
}

gb_internal void ast_dumper_begin_dump(AstDumper *dumper, String name, int version) {
	dumper->begin_dump(dumper, name, version);
}

gb_internal void ast_dumper_end_dump(AstDumper *dumper, String name) {
	dumper->end_dump(dumper, name);
}

gb_internal void ast_dumper_begin_multi_field(AstDumper *dumper, String name) {
	dumper->begin_multi_field(dumper, name);
}

gb_internal void ast_dumper_end_multi_field(AstDumper *dumper, String name) {
	dumper->end_multi_field(dumper, name);
}

gb_internal void ast_dumper_add_empty_multi_field(AstDumper *dumper, String name) {
	dumper->add_empty_multi_field(dumper, name);
}

gb_internal void ast_dumper_begin_field(AstDumper *dumper, String name) {
	dumper->begin_field(dumper, name);
}

gb_internal void ast_dumper_end_field(AstDumper *dumper, String name) {
	dumper->end_field(dumper, name);
}

gb_internal void ast_dumper_add_empty_field(AstDumper *dumper, String name) {
	dumper->add_empty_field(dumper, name);
}

gb_internal void ast_dumper_add_string_attribute(AstDumper *dumper, String name, String value) {
	dumper->add_string_attribute(dumper, name, value);
}

gb_internal void ast_dumper_add_int_attribute(AstDumper *dumper, String name, i64 value) {
	dumper->add_int_attribute(dumper, name, value);
}

gb_internal void ast_dumper_add_inline_value(AstDumper *dumper, String name, String value) {
	dumper->add_inline_value(dumper, name, value);
}

gb_internal void ast_dumper_open_object_and_begin_attributes(AstDumper *dumper, String type) {
	dumper->open_object_and_begin_attributes(dumper, type);
}

gb_internal void ast_dumper_end_attributes_and_close_object(AstDumper *dumper, String type) {
	dumper->end_attributes_and_close_object(dumper, type);
}

gb_internal void ast_dumper_end_attributes(AstDumper *dumper, String type) {
	dumper->end_attributes(dumper, type);
}

gb_internal void ast_dumper_close_object(AstDumper *dumper, String type) {
	dumper->close_object(dumper, type);
}

gb_internal void ast_dumper_dump_ast(AstDumper *dumper, Ast *ast);

gb_internal void ast_dumper_dump_named_ast(AstDumper *dumper, String name, Ast *ast) {
	if (ast != nullptr) {
		ast_dumper_begin_field(dumper, name);
		ast_dumper_dump_ast(dumper, ast);
		ast_dumper_end_field(dumper, name);
	} else if (!dumper->omit_defaults) {
		ast_dumper_add_empty_field(dumper, name);
	}
}

gb_internal void ast_dumper_dump_named_slice_of_asts(AstDumper *dumper, String name, Slice<Ast *> asts) {
	if (asts.count > 0) {
		ast_dumper_begin_multi_field(dumper, name);
		for_array(i, asts) {
			ast_dumper_dump_ast(dumper, asts[i]);
		}
		ast_dumper_end_multi_field(dumper, name);
	} else if (!dumper->omit_defaults) {
		ast_dumper_add_empty_multi_field(dumper, name);
	}
}

gb_internal void ast_dumper_dump_token(AstDumper *dumper, String token_name, Token const& token) {
	if (dumper->omit_defaults && (token.string.len == 0)) {
		return;
	}
	ast_dumper_begin_field(dumper, token_name);
	ast_dumper_open_object_and_begin_attributes(dumper, STR_LIT("token"));
	ast_dumper_add_string_attribute(dumper, STR_LIT("string"), token.string);
	ast_dumper_add_int_attribute(dumper, STR_LIT("offset"), token.pos.offset);
	ast_dumper_add_int_attribute(dumper, STR_LIT("line"), token.pos.line);
	ast_dumper_add_int_attribute(dumper, STR_LIT("column"), token.pos.column);
	ast_dumper_end_attributes_and_close_object(dumper, STR_LIT("token"));
	ast_dumper_end_field(dumper, token_name);
}

gb_internal void ast_dumper_dump_bool(AstDumper *dumper, String name, bool value, bool default_value = false) {
	if (dumper->omit_defaults && (value == default_value)) {
		return;
	}
	String string_value = value ? STR_LIT("true") : STR_LIT("false");
	ast_dumper_add_string_attribute(dumper, name, string_value);
}

gb_internal void ast_dumper_dump_proc_inlining(AstDumper *dumper, ProcInlining inlining) {
	if (dumper->omit_defaults && (inlining == ProcInlining_none)) {
		return;
	}
	String string_value = {};
	switch (inlining) {
	case ProcInlining_none: string_value = STR_LIT("none"); break;
	case ProcInlining_inline: string_value = STR_LIT("inline"); break;
	case ProcInlining_no_inline: string_value = STR_LIT("no_inline"); break;
	}
	ast_dumper_add_string_attribute(dumper, STR_LIT("inlining"), string_value);
}

gb_internal void ast_dumper_dump_proc_tailing(AstDumper *dumper, ProcTailing tailing) {
	if (dumper->omit_defaults && (tailing == ProcTailing_none)) {
		return;
	}
	String string_value = {};
	switch (tailing) {
	case ProcTailing_none: string_value = STR_LIT("none"); break;
	case ProcTailing_must_tail: string_value = STR_LIT("must_tail"); break;
	}
	ast_dumper_add_string_attribute(dumper, STR_LIT("tailing"), string_value);
}

gb_internal void ast_dumper_dump_comment_group(AstDumper *dumper, String name, CommentGroup *group) {
	if ((group == nullptr) || (group->list.count == 0)) {
		return;
	}
	ast_dumper_begin_multi_field(dumper, name);
	for_array(i, group->list) {
		ast_dumper_add_inline_value(dumper, STR_LIT("comment"), group->list[i].string);
	}
	ast_dumper_end_multi_field(dumper, name);
}

struct ProcTagPair {
	String  name;
	ProcTag tag;
};

gb_internal void ast_dumper_dump_proc_tags(AstDumper *dumper, u64 tags) {
	ProcTagPair pairs[] = {
		{ STR_LIT("proc_tag_bounds_check"), ProcTag_bounds_check },
		{ STR_LIT("proc_tag_no_bounds_check"), ProcTag_no_bounds_check },
		{ STR_LIT("proc_tag_type_assert"), ProcTag_type_assert },
		{ STR_LIT("proc_tag_no_type_assert"), ProcTag_no_type_assert },
		{ STR_LIT("proc_tag_require_results"), ProcTag_require_results },
		{ STR_LIT("proc_tag_optional_ok"), ProcTag_optional_ok },
		{ STR_LIT("proc_tag_optional_allocator_error"), ProcTag_optional_allocator_error }
	};

	Slice<ProcTagPair> s {pairs, gb_count_of(pairs)};
	for_array(i, s) {
		ast_dumper_dump_bool(dumper, pairs[0].name, (tags & pairs[0].tag) != 0);
	}
}

gb_internal void ast_dumper_dump_ast(AstDumper *dumper, Ast *ast) {
	{
		u32 *saved_id = map_get(&dumper->ast_to_id, ast);
		if (saved_id != nullptr) {
			// this seems to happen for selector call
			// expressions
			ast_dumper_open_object_and_begin_attributes(dumper, STR_LIT("already visited"));
			if (!dumper->no_ids) {
				ast_dumper_add_int_attribute(dumper, STR_LIT("id"), cast(i64)*saved_id);
			}
			ast_dumper_end_attributes_and_close_object(dumper, STR_LIT("already visited"));
			return;
		}
	}
	String type = ast_strings[ast->kind];
	ast_dumper_open_object_and_begin_attributes(dumper, type);
	if (!dumper->no_ids) {
		ast_dumper_add_int_attribute(dumper, STR_LIT("id"), cast(i64)dumper->ast_to_id.count);
	}
	map_set(&dumper->ast_to_id, ast, dumper->ast_to_id.count);
	ast_dumper_dump_bool(dumper, STR_LIT("state_flag_bounds_check"), (ast->state_flags & StateFlag_bounds_check) != 0);
	ast_dumper_dump_bool(dumper, STR_LIT("state_flag_no_bounds_check"), (ast->state_flags & StateFlag_no_bounds_check) != 0);
	ast_dumper_dump_bool(dumper, STR_LIT("state_flag_type_assert"), (ast->state_flags & StateFlag_type_assert) != 0);
	ast_dumper_dump_bool(dumper, STR_LIT("state_flag_no_type_assert"), (ast->state_flags & StateFlag_no_type_assert) != 0);
	switch (ast->kind) {
	default:
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_add_empty_field(dumper, STR_LIT("TODO"));
		break;
	case Ast_Ident:
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("token"), ast->Ident.token);
		break;
	case Ast_Implicit:
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("token"), ast->Implicit);
		break;
	case Ast_Uninit:
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("token"), ast->Uninit);
		break;
	case Ast_BasicLit:
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("token"), ast->BasicLit.token);
		break;
	case Ast_BasicDirective:
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("token"), ast->BasicLit.token);
		ast_dumper_dump_token(dumper, STR_LIT("name"), ast->BasicLit.token);
		break;
	case Ast_Ellipsis:
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("token"), ast->Ellipsis.token);
		ast_dumper_dump_named_ast(dumper, STR_LIT("expr"), ast->Ellipsis.expr);
		break;
	case Ast_ProcGroup:
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("token"), ast->ProcGroup.token);
		ast_dumper_dump_token(dumper, STR_LIT("open"), ast->ProcGroup.open);
		ast_dumper_dump_token(dumper, STR_LIT("close"), ast->ProcGroup.close);
		ast_dumper_dump_named_slice_of_asts(dumper, STR_LIT("args"), ast->ProcGroup.args);
		break;
	case Ast_ProcLit:
		ast_dumper_dump_proc_tags(dumper, ast->ProcLit.tags);
		ast_dumper_dump_proc_inlining(dumper, ast->ProcLit.inlining);
		ast_dumper_dump_proc_tailing(dumper, ast->ProcLit.tailing);
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("where_token"), ast->ProcLit.where_token);
		ast_dumper_dump_named_ast(dumper, STR_LIT("type"), ast->ProcLit.type);
		ast_dumper_dump_named_ast(dumper, STR_LIT("body"), ast->ProcLit.body);
		ast_dumper_dump_named_slice_of_asts(dumper, STR_LIT("where_clauses"), ast->ProcLit.where_clauses);
		break;
	case Ast_CompoundLit:
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("open"), ast->CompoundLit.open);
		ast_dumper_dump_token(dumper, STR_LIT("close"), ast->CompoundLit.close);
		ast_dumper_dump_named_ast(dumper, STR_LIT("type"), ast->CompoundLit.type);
		ast_dumper_dump_named_slice_of_asts(dumper, STR_LIT("elems"), ast->CompoundLit.elems);
		ast_dumper_dump_named_ast(dumper, STR_LIT("tag"), ast->CompoundLit.tag);
		break;
	case Ast_BadExpr:
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("begin"), ast->BadExpr.begin);
		ast_dumper_dump_token(dumper, STR_LIT("end"), ast->BadExpr.end);
		break;
	case Ast_TagExpr:
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("token"), ast->TagExpr.token);
		ast_dumper_dump_token(dumper, STR_LIT("name"), ast->TagExpr.name);
		ast_dumper_dump_named_ast(dumper, STR_LIT("expr"), ast->TagExpr.expr);
		break;
	case Ast_UnaryExpr:
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("op"), ast->UnaryExpr.op);
		ast_dumper_dump_named_ast(dumper, STR_LIT("expr"), ast->UnaryExpr.expr);
		break;
	case Ast_BinaryExpr:
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("op"), ast->UnaryExpr.op);
		ast_dumper_dump_named_ast(dumper, STR_LIT("left"), ast->BinaryExpr.left);
		ast_dumper_dump_named_ast(dumper, STR_LIT("right"), ast->BinaryExpr.right);
		break;
	case Ast_ParenExpr:
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("open"), ast->ParenExpr.open);
		ast_dumper_dump_token(dumper, STR_LIT("close"), ast->ParenExpr.close);
		ast_dumper_dump_named_ast(dumper, STR_LIT("expr"), ast->ParenExpr.expr);
		break;
	case Ast_SelectorExpr:
		// swizzle and is bit set are not set by parser
		if (0) {
			if (ast->SelectorExpr.swizzle_indices != 0) {
				ast_dumper_add_int_attribute(dumper, STR_LIT("swizzle_index_0"), cast(i64)((ast->SelectorExpr.swizzle_indices >> 0) & 0x3));
				ast_dumper_add_int_attribute(dumper, STR_LIT("swizzle_index_1"), cast(i64)((ast->SelectorExpr.swizzle_indices >> 2) & 0x3));
				ast_dumper_add_int_attribute(dumper, STR_LIT("swizzle_index_2"), cast(i64)((ast->SelectorExpr.swizzle_indices >> 4) & 0x3));
				ast_dumper_add_int_attribute(dumper, STR_LIT("swizzle_index_3"), cast(i64)((ast->SelectorExpr.swizzle_indices >> 6) & 0x3));
			}
			ast_dumper_dump_bool(dumper, STR_LIT("is_bit_field"), ast->SelectorExpr.is_bit_field);
		}
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("token"), ast->SelectorExpr.token);
		ast_dumper_dump_named_ast(dumper, STR_LIT("expr"), ast->SelectorExpr.expr);
		ast_dumper_dump_named_ast(dumper, STR_LIT("selector"), ast->SelectorExpr.selector);
		break;
	case Ast_ImplicitSelectorExpr:
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("token"), ast->ImplicitSelectorExpr.token);
		ast_dumper_dump_named_ast(dumper, STR_LIT("selector"), ast->ImplicitSelectorExpr.selector);
		break;
	case Ast_SelectorCallExpr:
		// not set by parser
		if (0) {
			ast_dumper_dump_bool(dumper, STR_LIT("modified_call"), ast->SelectorCallExpr.modified_call);
		}
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("token"), ast->SelectorCallExpr.token);
		ast_dumper_dump_named_ast(dumper, STR_LIT("expr"), ast->SelectorCallExpr.expr);
		ast_dumper_dump_named_ast(dumper, STR_LIT("call"), ast->SelectorCallExpr.call);
		break;
	case Ast_IndexExpr:
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("open"), ast->IndexExpr.open);
		ast_dumper_dump_token(dumper, STR_LIT("close"), ast->IndexExpr.close);
		ast_dumper_dump_named_ast(dumper, STR_LIT("expr"), ast->IndexExpr.expr);
		ast_dumper_dump_named_ast(dumper, STR_LIT("index"), ast->IndexExpr.index);
		break;
	case Ast_DerefExpr:
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("op"), ast->DerefExpr.op);
		ast_dumper_dump_named_ast(dumper, STR_LIT("expr"), ast->DerefExpr.expr);
		break;
	case Ast_SliceExpr:
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("open"), ast->SliceExpr.open);
		ast_dumper_dump_token(dumper, STR_LIT("close"), ast->SliceExpr.close);
		ast_dumper_dump_token(dumper, STR_LIT("interval"), ast->SliceExpr.interval);
		ast_dumper_dump_named_ast(dumper, STR_LIT("expr"), ast->SliceExpr.expr);
		ast_dumper_dump_named_ast(dumper, STR_LIT("low"), ast->SliceExpr.low);
		ast_dumper_dump_named_ast(dumper, STR_LIT("high"), ast->SliceExpr.high);
		break;
	case Ast_CallExpr:
		ast_dumper_dump_proc_inlining(dumper, ast->CallExpr.inlining);
		ast_dumper_dump_proc_tailing(dumper, ast->CallExpr.tailing);
		// not set by parser
		if (0) {
			ast_dumper_dump_bool(dumper, STR_LIT("optional_ok_one"), ast->CallExpr.optional_ok_one);
			ast_dumper_dump_bool(dumper, STR_LIT("was_selector"), ast->CallExpr.was_selector);
		}
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("open"), ast->CallExpr.open);
		ast_dumper_dump_token(dumper, STR_LIT("close"), ast->CallExpr.close);
		ast_dumper_dump_token(dumper, STR_LIT("ellipsis"), ast->CallExpr.ellipsis);
		ast_dumper_dump_named_ast(dumper, STR_LIT("proc"), ast->CallExpr.proc);
		ast_dumper_dump_named_slice_of_asts(dumper, STR_LIT("args"), ast->CallExpr.args);
		break;
	case Ast_FieldValue:
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("eq"), ast->FieldValue.eq);
		ast_dumper_dump_named_ast(dumper, STR_LIT("field"), ast->FieldValue.field);
		ast_dumper_dump_named_ast(dumper, STR_LIT("value"), ast->FieldValue.value);
		break;
	case Ast_EnumFieldValue:
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_named_ast(dumper, STR_LIT("name"), ast->EnumFieldValue.name);
		ast_dumper_dump_named_ast(dumper, STR_LIT("value"), ast->EnumFieldValue.value);
		ast_dumper_dump_comment_group(dumper, STR_LIT("docs"), ast->EnumFieldValue.docs);
		ast_dumper_dump_comment_group(dumper, STR_LIT("comment"), ast->EnumFieldValue.comment);
		break;
	case Ast_TernaryIfExpr:
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_named_ast(dumper, STR_LIT("x"), ast->TernaryIfExpr.x);
		ast_dumper_dump_named_ast(dumper, STR_LIT("cond"), ast->TernaryIfExpr.cond);
		ast_dumper_dump_named_ast(dumper, STR_LIT("y"), ast->TernaryIfExpr.y);
		break;
	case Ast_TernaryWhenExpr:
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_named_ast(dumper, STR_LIT("x"), ast->TernaryWhenExpr.x);
		ast_dumper_dump_named_ast(dumper, STR_LIT("cond"), ast->TernaryWhenExpr.cond);
		ast_dumper_dump_named_ast(dumper, STR_LIT("y"), ast->TernaryWhenExpr.y);
		break;
	case Ast_OrElseExpr:
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("token"), ast->OrElseExpr.token);
		ast_dumper_dump_named_ast(dumper, STR_LIT("x"), ast->OrElseExpr.x);
		ast_dumper_dump_named_ast(dumper, STR_LIT("y"), ast->OrElseExpr.y);
		break;
	case Ast_OrReturnExpr:
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("token"), ast->OrReturnExpr.token);
		ast_dumper_dump_named_ast(dumper, STR_LIT("expr"), ast->OrReturnExpr.expr);
		break;
	case Ast_OrBranchExpr:
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("token"), ast->OrBranchExpr.token);
		ast_dumper_dump_named_ast(dumper, STR_LIT("expr"), ast->OrBranchExpr.expr);
		ast_dumper_dump_named_ast(dumper, STR_LIT("label"), ast->OrBranchExpr.label);
		break;
	case Ast_TypeAssertion:
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("dot"), ast->TypeAssertion.dot);
		ast_dumper_dump_named_ast(dumper, STR_LIT("expr"), ast->TypeAssertion.expr);
		ast_dumper_dump_named_ast(dumper, STR_LIT("type"), ast->TypeAssertion.type);
		break;
	case Ast_TypeCast:
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("token"), ast->TypeCast.token);
		ast_dumper_dump_named_ast(dumper, STR_LIT("type"), ast->TypeCast.type);
		ast_dumper_dump_named_ast(dumper, STR_LIT("expr"), ast->TypeCast.expr);
		break;
	case Ast_AutoCast:
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("token"), ast->AutoCast.token);
		ast_dumper_dump_named_ast(dumper, STR_LIT("expr"), ast->AutoCast.expr);
		break;
	case Ast_InlineAsmExpr:
		ast_dumper_dump_bool(dumper, STR_LIT("has_side_effects"), ast->InlineAsmExpr.has_side_effects);
		ast_dumper_dump_bool(dumper, STR_LIT("is_align_stack"), ast->InlineAsmExpr.is_align_stack);
		{
			if (!dumper->omit_defaults || (ast->InlineAsmExpr.dialect != InlineAsmDialect_Default)) {
				String dialect_string = {};
				switch (ast->InlineAsmExpr.dialect) {
				case InlineAsmDialect_Default: dialect_string = STR_LIT("Default"); break;
				case InlineAsmDialect_ATT: dialect_string = STR_LIT("ATT"); break;
				case InlineAsmDialect_Intel: dialect_string = STR_LIT("Intel"); break;
				}
				ast_dumper_add_string_attribute(dumper, STR_LIT("dialect"), dialect_string);
			}
		}
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("token"), ast->InlineAsmExpr.token);
		ast_dumper_dump_token(dumper, STR_LIT("open"), ast->InlineAsmExpr.open);
		ast_dumper_dump_token(dumper, STR_LIT("close"), ast->InlineAsmExpr.close);
		ast_dumper_dump_named_slice_of_asts(dumper, STR_LIT("param_types"), ast->InlineAsmExpr.param_types);
		ast_dumper_dump_named_ast(dumper, STR_LIT("return_type"), ast->InlineAsmExpr.return_type);
		ast_dumper_dump_named_ast(dumper, STR_LIT("asm_string"), ast->InlineAsmExpr.asm_string);
		ast_dumper_dump_named_ast(dumper, STR_LIT("constraints_string"), ast->InlineAsmExpr.constraints_string);
		break;
	case Ast_MatrixIndexExpr:
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("open"), ast->MatrixIndexExpr.open);
		ast_dumper_dump_token(dumper, STR_LIT("close"), ast->MatrixIndexExpr.close);
		ast_dumper_dump_named_ast(dumper, STR_LIT("expr"), ast->MatrixIndexExpr.expr);
		ast_dumper_dump_named_ast(dumper, STR_LIT("row_index"), ast->MatrixIndexExpr.row_index);
		ast_dumper_dump_named_ast(dumper, STR_LIT("column_index"), ast->MatrixIndexExpr.column_index);
		break;
	case Ast_BadStmt:
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("begin"), ast->BadStmt.begin);
		ast_dumper_dump_token(dumper, STR_LIT("end"), ast->BadStmt.end);
		break;
	case Ast_EmptyStmt:
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("token"), ast->EmptyStmt.token);
		break;
	case Ast_ExprStmt:
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_named_ast(dumper, STR_LIT("expr"), ast->ExprStmt.expr);
		break;
	case Ast_AssignStmt:
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("op"), ast->AssignStmt.op);
		ast_dumper_dump_named_slice_of_asts(dumper, STR_LIT("lhs_exprs"), ast->AssignStmt.lhs);
		ast_dumper_dump_named_slice_of_asts(dumper, STR_LIT("rhs_exprs"), ast->AssignStmt.rhs);
		break;
	case Ast_BlockStmt:
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("open"), ast->BlockStmt.open);
		ast_dumper_dump_token(dumper, STR_LIT("close"), ast->BlockStmt.close);
		ast_dumper_dump_named_slice_of_asts(dumper, STR_LIT("stmts"), ast->BlockStmt.stmts);
		ast_dumper_dump_named_ast(dumper, STR_LIT("label"), ast->BlockStmt.label);
		break;
	case Ast_IfStmt:
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("token"), ast->IfStmt.token);
		ast_dumper_dump_named_ast(dumper, STR_LIT("label"), ast->IfStmt.label);
		ast_dumper_dump_named_ast(dumper, STR_LIT("init"), ast->IfStmt.init);
		ast_dumper_dump_named_ast(dumper, STR_LIT("cond"), ast->IfStmt.cond);
		ast_dumper_dump_named_ast(dumper, STR_LIT("body"), ast->IfStmt.body);
		ast_dumper_dump_named_ast(dumper, STR_LIT("else_stmt"), ast->IfStmt.else_stmt);
		break;
	case Ast_WhenStmt:
		// not set by parser
		if (0) {
			ast_dumper_dump_bool(dumper, STR_LIT("is_cond_determined"), ast->WhenStmt.is_cond_determined);
			ast_dumper_dump_bool(dumper, STR_LIT("determined_cond"), ast->WhenStmt.determined_cond);
		}
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("token"), ast->WhenStmt.token);
		ast_dumper_dump_named_ast(dumper, STR_LIT("cond"), ast->WhenStmt.cond);
		ast_dumper_dump_named_ast(dumper, STR_LIT("body"), ast->WhenStmt.body);
		ast_dumper_dump_named_ast(dumper, STR_LIT("else_stmt"), ast->WhenStmt.else_stmt);
		break;
	case Ast_ReturnStmt:
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("token"), ast->ReturnStmt.token);
		ast_dumper_dump_named_slice_of_asts(dumper, STR_LIT("results"), ast->ReturnStmt.results);
		break;
	case Ast_ForStmt:
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("token"), ast->ForStmt.token);
		ast_dumper_dump_named_ast(dumper, STR_LIT("label"), ast->ForStmt.label);
		ast_dumper_dump_named_ast(dumper, STR_LIT("init"), ast->ForStmt.init);
		ast_dumper_dump_named_ast(dumper, STR_LIT("cond"), ast->ForStmt.cond);
		ast_dumper_dump_named_ast(dumper, STR_LIT("post"), ast->ForStmt.post);
		ast_dumper_dump_named_ast(dumper, STR_LIT("body"), ast->ForStmt.body);
		break;
	case Ast_RangeStmt:
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("token"), ast->RangeStmt.token);
		ast_dumper_dump_token(dumper, STR_LIT("in_token"), ast->RangeStmt.in_token);
		ast_dumper_dump_bool(dumper, STR_LIT("reverse"), ast->RangeStmt.reverse);
		ast_dumper_dump_named_ast(dumper, STR_LIT("label"), ast->RangeStmt.label);
		ast_dumper_dump_named_ast(dumper, STR_LIT("init"), ast->RangeStmt.init);
		ast_dumper_dump_named_slice_of_asts(dumper, STR_LIT("vals"), ast->RangeStmt.vals);
		ast_dumper_dump_named_ast(dumper, STR_LIT("expr"), ast->RangeStmt.expr);
		ast_dumper_dump_named_ast(dumper, STR_LIT("body"), ast->RangeStmt.body);
		break;
	case Ast_UnrollRangeStmt:
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("unroll_token"), ast->UnrollRangeStmt.unroll_token);
		ast_dumper_dump_token(dumper, STR_LIT("for_token"), ast->UnrollRangeStmt.for_token);
		ast_dumper_dump_token(dumper, STR_LIT("in_token"), ast->UnrollRangeStmt.in_token);
		ast_dumper_dump_named_ast(dumper, STR_LIT("init"), ast->UnrollRangeStmt.init);
		ast_dumper_dump_named_slice_of_asts(dumper, STR_LIT("args"), ast->UnrollRangeStmt.args);
		ast_dumper_dump_named_ast(dumper, STR_LIT("val0"), ast->UnrollRangeStmt.val0);
		ast_dumper_dump_named_ast(dumper, STR_LIT("val1"), ast->UnrollRangeStmt.val1);
		ast_dumper_dump_named_ast(dumper, STR_LIT("expr"), ast->UnrollRangeStmt.expr);
		ast_dumper_dump_named_ast(dumper, STR_LIT("body"), ast->UnrollRangeStmt.body);
		break;
	case Ast_CaseClause:
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("token"), ast->CaseClause.token);
		ast_dumper_dump_named_slice_of_asts(dumper, STR_LIT("list"), ast->CaseClause.list);
		ast_dumper_dump_named_slice_of_asts(dumper, STR_LIT("stmts"), ast->CaseClause.stmts);
		break;
	case Ast_SwitchStmt:
		ast_dumper_dump_bool(dumper, STR_LIT("partial"), ast->SwitchStmt.partial);
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("token"), ast->SwitchStmt.token);
		ast_dumper_dump_named_ast(dumper, STR_LIT("label"), ast->SwitchStmt.label);
		ast_dumper_dump_named_ast(dumper, STR_LIT("init"), ast->SwitchStmt.init);
		ast_dumper_dump_named_ast(dumper, STR_LIT("tag"), ast->SwitchStmt.tag);
		ast_dumper_dump_named_ast(dumper, STR_LIT("body"), ast->SwitchStmt.body);
		break;
	case Ast_TypeSwitchStmt:
		ast_dumper_dump_bool(dumper, STR_LIT("partial"), ast->TypeSwitchStmt.partial);
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("token"), ast->TypeSwitchStmt.token);
		ast_dumper_dump_named_ast(dumper, STR_LIT("label"), ast->TypeSwitchStmt.label);
		ast_dumper_dump_named_ast(dumper, STR_LIT("tag"), ast->TypeSwitchStmt.tag);
		ast_dumper_dump_named_ast(dumper, STR_LIT("body"), ast->TypeSwitchStmt.body);
		break;
	case Ast_DeferStmt:
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("token"), ast->DeferStmt.token);
		ast_dumper_dump_named_ast(dumper, STR_LIT("stmt"), ast->DeferStmt.stmt);
		break;
	case Ast_BranchStmt:
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("token"), ast->BranchStmt.token);
		ast_dumper_dump_named_ast(dumper, STR_LIT("label"), ast->BranchStmt.label);
		break;
	case Ast_UsingStmt:
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("token"), ast->UsingStmt.token);
		ast_dumper_dump_named_slice_of_asts(dumper, STR_LIT("list"), ast->UsingStmt.list);
		break;
	case Ast_BadDecl:
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("begin"), ast->BadDecl.begin);
		ast_dumper_dump_token(dumper, STR_LIT("end"), ast->BadDecl.end);
		break;
	case Ast_ForeignBlockDecl:
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("token"), ast->ForeignBlockDecl.token);
		ast_dumper_dump_named_ast(dumper, STR_LIT("foreign_library"), ast->ForeignBlockDecl.foreign_library);
		ast_dumper_dump_named_ast(dumper, STR_LIT("body"), ast->ForeignBlockDecl.body);
		ast_dumper_dump_named_slice_of_asts(dumper, STR_LIT("attributes"), slice_from_array(ast->ForeignBlockDecl.attributes));
		break;
	case Ast_Label:
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("token"), ast->Label.token);
		ast_dumper_dump_named_ast(dumper, STR_LIT("name"), ast->Label.name);
		break;
	case Ast_ValueDecl:
		ast_dumper_dump_bool(dumper, STR_LIT("is_using"), ast->ValueDecl.is_using);
		ast_dumper_dump_bool(dumper, STR_LIT("is_mutable"), ast->ValueDecl.is_mutable);
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_named_slice_of_asts(dumper, STR_LIT("names"), ast->ValueDecl.names);
		ast_dumper_dump_named_ast(dumper, STR_LIT("type"), ast->ValueDecl.type);
		ast_dumper_dump_named_slice_of_asts(dumper, STR_LIT("values"), ast->ValueDecl.values);
		ast_dumper_dump_named_slice_of_asts(dumper, STR_LIT("attributes"), slice_from_array(ast->ValueDecl.attributes));
		ast_dumper_dump_comment_group(dumper, STR_LIT("docs"), ast->ValueDecl.docs);
		ast_dumper_dump_comment_group(dumper, STR_LIT("comment"), ast->ValueDecl.comment);
		break;
	case Ast_PackageDecl:
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("token"), ast->PackageDecl.token);
		ast_dumper_dump_token(dumper, STR_LIT("name"), ast->PackageDecl.name);
		ast_dumper_dump_comment_group(dumper, STR_LIT("docs"), ast->PackageDecl.docs);
		ast_dumper_dump_comment_group(dumper, STR_LIT("comment"), ast->PackageDecl.comment);
		break;
	case Ast_ImportDecl:
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("token"), ast->ImportDecl.token);
		ast_dumper_dump_token(dumper, STR_LIT("relpath"), ast->ImportDecl.relpath);
		ast_dumper_dump_token(dumper, STR_LIT("import_name"), ast->ImportDecl.import_name);
		ast_dumper_dump_named_slice_of_asts(dumper, STR_LIT("attributes"), slice_from_array(ast->ImportDecl.attributes));
		ast_dumper_dump_comment_group(dumper, STR_LIT("docs"), ast->ImportDecl.docs);
		ast_dumper_dump_comment_group(dumper, STR_LIT("comment"), ast->ImportDecl.comment);
		break;
	case Ast_ForeignImportDecl:
		ast_dumper_dump_bool(dumper, STR_LIT("multiple_filepaths"), ast->ForeignImportDecl.multiple_filepaths);
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("token"), ast->ForeignImportDecl.token);
		ast_dumper_dump_token(dumper, STR_LIT("library_name"), ast->ForeignImportDecl.library_name);
		ast_dumper_dump_named_slice_of_asts(dumper, STR_LIT("filepaths"), ast->ForeignImportDecl.filepaths);
		ast_dumper_dump_named_slice_of_asts(dumper, STR_LIT("attributes"), slice_from_array(ast->ForeignImportDecl.attributes));
		ast_dumper_dump_comment_group(dumper, STR_LIT("docs"), ast->ForeignImportDecl.docs);
		ast_dumper_dump_comment_group(dumper, STR_LIT("comment"), ast->ForeignImportDecl.comment);
		break;
	case Ast_Attribute:
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("token"), ast->Attribute.token);
		ast_dumper_dump_token(dumper, STR_LIT("open"), ast->Attribute.open);
		ast_dumper_dump_token(dumper, STR_LIT("close"), ast->Attribute.close);
		ast_dumper_dump_named_slice_of_asts(dumper, STR_LIT("elems"), ast->Attribute.elems);
		break;
	case Ast_Field:
		ast_dumper_dump_bool(dumper, STR_LIT("flag_using"), (ast->Field.flags & FieldFlag_using) != 0);
		ast_dumper_dump_bool(dumper, STR_LIT("flag_no_alias"), (ast->Field.flags & FieldFlag_no_alias) != 0);
		ast_dumper_dump_bool(dumper, STR_LIT("flag_no_capture"), (ast->Field.flags & FieldFlag_no_capture) != 0);
		ast_dumper_dump_bool(dumper, STR_LIT("flag_c_vararg"), (ast->Field.flags & FieldFlag_c_vararg) != 0);
		ast_dumper_dump_bool(dumper, STR_LIT("flag_const"), (ast->Field.flags & FieldFlag_const) != 0);
		ast_dumper_dump_bool(dumper, STR_LIT("flag_any_int"), (ast->Field.flags & FieldFlag_any_int) != 0);
		ast_dumper_dump_bool(dumper, STR_LIT("flag_subtype"), (ast->Field.flags & FieldFlag_subtype) != 0);
		ast_dumper_dump_bool(dumper, STR_LIT("flag_by_ptr"), (ast->Field.flags & FieldFlag_by_ptr) != 0);
		ast_dumper_dump_bool(dumper, STR_LIT("flag_no_broadcast"), (ast->Field.flags & FieldFlag_no_broadcast) != 0);
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("tag"), ast->Field.tag);
		ast_dumper_dump_named_slice_of_asts(dumper, STR_LIT("names"), ast->Field.names);
		ast_dumper_dump_named_ast(dumper, STR_LIT("type"), ast->Field.type);
		ast_dumper_dump_named_ast(dumper, STR_LIT("default_value"), ast->Field.default_value);
		ast_dumper_dump_comment_group(dumper, STR_LIT("docs"), ast->Field.docs);
		ast_dumper_dump_comment_group(dumper, STR_LIT("comment"), ast->Field.comment);
		break;
	case Ast_BitFieldField:
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("tag"), ast->BitFieldField.tag);
		ast_dumper_dump_named_ast(dumper, STR_LIT("name"), ast->BitFieldField.name);
		ast_dumper_dump_named_ast(dumper, STR_LIT("type"), ast->BitFieldField.type);
		ast_dumper_dump_named_ast(dumper, STR_LIT("bit_size"), ast->BitFieldField.bit_size);
		ast_dumper_dump_comment_group(dumper, STR_LIT("docs"), ast->BitFieldField.docs);
		ast_dumper_dump_comment_group(dumper, STR_LIT("comment"), ast->BitFieldField.comment);
		break;
	case Ast_FieldList:
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("token"), ast->FieldList.token);
		ast_dumper_dump_named_slice_of_asts(dumper, STR_LIT("list"), ast->FieldList.list);
		break;
	case Ast_TypeidType:
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("token"), ast->TypeidType.token);
		ast_dumper_dump_named_ast(dumper, STR_LIT("specialization"), ast->TypeidType.specialization);
		break;
	case Ast_HelperType:
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("token"), ast->HelperType.token);
		ast_dumper_dump_named_ast(dumper, STR_LIT("type"), ast->HelperType.type);
		break;
	case Ast_DistinctType:
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("token"), ast->DistinctType.token);
		ast_dumper_dump_named_ast(dumper, STR_LIT("type"), ast->DistinctType.type);
		break;
	case Ast_PolyType:
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("token"), ast->PolyType.token);
		ast_dumper_dump_named_ast(dumper, STR_LIT("type"), ast->PolyType.type);
		ast_dumper_dump_named_ast(dumper, STR_LIT("specialization"), ast->PolyType.specialization);
		break;
	case Ast_ProcType:
		ast_dumper_dump_proc_tags(dumper, ast->ProcType.tags);
		{
			String cc_string = {};
			switch (ast->ProcType.calling_convention) {
			case ProcCC_Invalid: cc_string = STR_LIT("Invalid"); break;
			case ProcCC_Odin: cc_string = STR_LIT("Odin"); break;
			case ProcCC_Contextless: cc_string = STR_LIT("Contextless"); break;
			case ProcCC_CDecl: cc_string = STR_LIT("CDecl"); break;
			case ProcCC_StdCall: cc_string = STR_LIT("StdCall"); break;
			case ProcCC_FastCall: cc_string = STR_LIT("FastCall"); break;
			case ProcCC_None: cc_string = STR_LIT("None"); break;
			case ProcCC_Naked: cc_string = STR_LIT("Naked"); break;
			case ProcCC_InlineAsm: cc_string = STR_LIT("InlineAsm"); break;
			case ProcCC_Win64: cc_string = STR_LIT("Win64"); break;
			case ProcCC_SysV: cc_string = STR_LIT("SysV"); break;
			case ProcCC_PreserveNone: cc_string = STR_LIT("PreserveNone"); break;
			case ProcCC_PreserveMost: cc_string = STR_LIT("PreserveMost"); break;
			case ProcCC_PreserveAll: cc_string = STR_LIT("PreserveAll"); break;
			case ProcCC_ForeignBlockDefault: cc_string = STR_LIT("ForeignBlockDefault"); break;
			}
			ast_dumper_add_string_attribute(dumper, STR_LIT("calling_convention"), cc_string);
		}
		ast_dumper_dump_bool(dumper, STR_LIT("generic"), ast->ProcType.generic);
		ast_dumper_dump_bool(dumper, STR_LIT("diverging"), ast->ProcType.diverging);
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("token"), ast->ProcType.token);
		ast_dumper_dump_named_ast(dumper, STR_LIT("params"), ast->ProcType.params);
		ast_dumper_dump_named_ast(dumper, STR_LIT("results"), ast->ProcType.results);
		break;
	case Ast_PointerType:
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("token"), ast->PointerType.token);
		ast_dumper_dump_named_ast(dumper, STR_LIT("type"), ast->PointerType.type);
		ast_dumper_dump_named_ast(dumper, STR_LIT("tag"), ast->PointerType.tag);
		break;
	case Ast_RelativeType:
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_named_ast(dumper, STR_LIT("type"), ast->RelativeType.type);
		ast_dumper_dump_named_ast(dumper, STR_LIT("tag"), ast->RelativeType.tag);
		break;
	case Ast_MultiPointerType:
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("token"), ast->MultiPointerType.token);
		ast_dumper_dump_named_ast(dumper, STR_LIT("type"), ast->MultiPointerType.type);
		break;
	case Ast_ArrayType:
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("token"), ast->ArrayType.token);
		ast_dumper_dump_named_ast(dumper, STR_LIT("count"), ast->ArrayType.count);
		ast_dumper_dump_named_ast(dumper, STR_LIT("elem"), ast->ArrayType.elem);
		ast_dumper_dump_named_ast(dumper, STR_LIT("tag"), ast->ArrayType.tag);
		break;
	case Ast_DynamicArrayType:
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("token"), ast->DynamicArrayType.token);
		ast_dumper_dump_named_ast(dumper, STR_LIT("elem"), ast->DynamicArrayType.elem);
		ast_dumper_dump_named_ast(dumper, STR_LIT("tag"), ast->DynamicArrayType.tag);
		break;
	case Ast_StructType:
		ast_dumper_add_int_attribute(dumper, STR_LIT("field_count"), cast(i64)ast->StructType.field_count);
		ast_dumper_dump_bool(dumper, STR_LIT("is_packed"), ast->StructType.is_packed);
		ast_dumper_dump_bool(dumper, STR_LIT("is_raw_union"), ast->StructType.is_raw_union);
		ast_dumper_dump_bool(dumper, STR_LIT("is_no_copy"), ast->StructType.is_no_copy);
		ast_dumper_dump_bool(dumper, STR_LIT("is_all_or_none"), ast->StructType.is_all_or_none);
		ast_dumper_dump_bool(dumper, STR_LIT("is_simple"), ast->StructType.is_simple);
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("token"), ast->StructType.token);
		ast_dumper_dump_token(dumper, STR_LIT("where_token"), ast->StructType.where_token);
		ast_dumper_dump_named_slice_of_asts(dumper, STR_LIT("fields"), ast->StructType.fields);
		ast_dumper_dump_named_ast(dumper, STR_LIT("polymorphic_params"), ast->StructType.polymorphic_params);
		ast_dumper_dump_named_ast(dumper, STR_LIT("align"), ast->StructType.align);
		ast_dumper_dump_named_ast(dumper, STR_LIT("min_field_align"), ast->StructType.min_field_align);
		ast_dumper_dump_named_ast(dumper, STR_LIT("max_field_align"), ast->StructType.max_field_align);
		ast_dumper_dump_named_slice_of_asts(dumper, STR_LIT("where_clauses"), ast->StructType.where_clauses);
		break;
	case Ast_UnionType:
		{
			if (!dumper->omit_defaults || (ast->UnionType.kind != UnionType_Normal)) {
				String kind_string = {};
				switch (ast->UnionType.kind) {
				case UnionType_Normal: kind_string = STR_LIT("Normal"); break;
				case UnionType_no_nil: kind_string = STR_LIT("no_nil"); break;
				case UnionType_shared_nil: kind_string = STR_LIT("shared_nil"); break;
				}
				ast_dumper_add_string_attribute(dumper, STR_LIT("kind"), kind_string);
			}
		}
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("token"), ast->UnionType.token);
		ast_dumper_dump_token(dumper, STR_LIT("where_token"), ast->UnionType.where_token);
		ast_dumper_dump_named_slice_of_asts(dumper, STR_LIT("variants"), ast->UnionType.variants);
		ast_dumper_dump_named_ast(dumper, STR_LIT("polymorphic_params"), ast->UnionType.polymorphic_params);
		ast_dumper_dump_named_ast(dumper, STR_LIT("align"), ast->UnionType.align);
		ast_dumper_dump_named_slice_of_asts(dumper, STR_LIT("where_clauses"), ast->UnionType.where_clauses);
		break;
	case Ast_EnumType:
		ast_dumper_dump_bool(dumper, STR_LIT("is_using"), ast->EnumType.is_using);
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("token"), ast->EnumType.token);
		ast_dumper_dump_named_ast(dumper, STR_LIT("base_type"), ast->EnumType.base_type);
		ast_dumper_dump_named_slice_of_asts(dumper, STR_LIT("fields"), ast->EnumType.fields);
		break;
	case Ast_BitSetType:
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("token"), ast->BitSetType.token);
		ast_dumper_dump_named_ast(dumper, STR_LIT("elem"), ast->BitSetType.elem);
		ast_dumper_dump_named_ast(dumper, STR_LIT("underlying"), ast->BitSetType.underlying);
		break;
	case Ast_BitFieldType:
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("token"), ast->BitFieldType.token);
		ast_dumper_dump_token(dumper, STR_LIT("open"), ast->BitFieldType.open);
		ast_dumper_dump_token(dumper, STR_LIT("close"), ast->BitFieldType.close);
		ast_dumper_dump_named_ast(dumper, STR_LIT("backing_type"), ast->BitFieldType.backing_type);
		ast_dumper_dump_named_slice_of_asts(dumper, STR_LIT("fields"), ast->BitFieldType.fields);
		break;
	case Ast_MapType:
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("token"), ast->MapType.token);
		ast_dumper_dump_named_ast(dumper, STR_LIT("count"), ast->MapType.count);
		ast_dumper_dump_named_ast(dumper, STR_LIT("key"), ast->MapType.key);
		ast_dumper_dump_named_ast(dumper, STR_LIT("value"), ast->MapType.value);
		break;
	case Ast_MatrixType:
		ast_dumper_dump_bool(dumper, STR_LIT("is_row_major"), ast->MatrixType.is_row_major);
		ast_dumper_end_attributes(dumper, type);
		ast_dumper_dump_token(dumper, STR_LIT("token"), ast->MatrixType.token);
		ast_dumper_dump_named_ast(dumper, STR_LIT("row_count"), ast->MatrixType.row_count);
		ast_dumper_dump_named_ast(dumper, STR_LIT("column_count"), ast->MatrixType.column_count);
		ast_dumper_dump_named_ast(dumper, STR_LIT("elem"), ast->MatrixType.elem);
		break;
	}
	ast_dumper_close_object(dumper, type);
}

gb_internal void ast_dumper_dump_file_tags(AstDumper *dumper, Array<Token> const& tags) {
	if (tags.count > 0) {
		ast_dumper_open_object_and_begin_attributes(dumper, STR_LIT("file tags"));
		ast_dumper_end_attributes(dumper, STR_LIT("file tags"));
		ast_dumper_begin_multi_field(dumper, STR_LIT("tags"));
		for (Token const &tok : tags) {
			ast_dumper_add_inline_value(dumper, STR_LIT("tag"), tok.string);
		}
		ast_dumper_end_multi_field(dumper, STR_LIT("tags"));
		ast_dumper_close_object(dumper, STR_LIT("file tags"));
	} else if (!dumper->omit_defaults) {
		ast_dumper_open_object_and_begin_attributes(dumper, STR_LIT("file tags"));
		ast_dumper_end_attributes(dumper, STR_LIT("file tags"));
		ast_dumper_add_empty_multi_field(dumper, STR_LIT("tags"));
		ast_dumper_close_object(dumper, STR_LIT("file tags"));
	}
}

gb_internal void dump_ast(AstFile *f, Array<Token> const& tags) {
	TEMPORARY_ALLOCATOR_GUARD();
	GB_ASSERT(f->pkg != nullptr);
	String path = concatenate4_strings(temporary_allocator(),
		build_context.build_paths[BuildPath_Output].basename,
		STR_LIT("/"),
		build_context.build_paths[BuildPath_Output].name,
		STR_LIT("-")
	);
	path = concatenate4_strings(temporary_allocator(),
		path,
		f->package_name,
		STR_LIT("-"),
		path_remove_extension(f->filename));
	path = concatenate_strings(temporary_allocator(),
		path,
		STR_LIT(".ast"));

	gbFile ast_dump_file = {};
	gbFileError err = gb_file_create(&ast_dump_file, cast(char const *)path.text);
	if (err != gbFileError_None) {
		error(nullptr, "failed to dump ast for %.*s", LIT(f->fullpath));
		return;
	}
	defer (gb_file_close(&ast_dump_file));
	AstDumper dumper = {};
	ast_dumper_init(&dumper, build_context.dump_ast_omit_defaults, build_context.dump_ast_no_ids, build_context.dump_ast_format);
	ast_dumper_begin_dump(&dumper, STR_LIT("source file"), 1);
	ast_dumper_dump_file_tags(&dumper, tags);
	ast_dumper_dump_ast(&dumper, f->pkg_decl);
	for_array(i, f->decls) {
		ast_dumper_dump_ast(&dumper, f->decls[i]);
	}
	ast_dumper_end_dump(&dumper, STR_LIT("source file"));
	WRITE_LIT_STR(&dumper, "\n");
	for_array(i, dumper.buffers) {
		if (!gb_file_write(&ast_dump_file, dumper.buffers[i], gb_string_length(dumper.buffers[i]))) {
			error(nullptr, "failed to write ast to file %.*s", LIT(path));
		}
	}
}

gb_internal void maybe_dump_ast(AstFile *f, Array<Token> const& tags) {
	if (!build_context.dump_ast) {
		return;
	}
	if (build_context.ast_dump_packages.count > 0) {
		StringSet *files = string_map_get(&build_context.ast_dump_packages, f->package_name);
		if (files == nullptr) {
			return;
		}
		if (files->entries.count > 0 && !string_set_exists(files, f->filename)) {
			return;
		}
	}
	dump_ast(f, tags);
}

#undef WRITE_STRING
#undef WRITE_LIT_STR
