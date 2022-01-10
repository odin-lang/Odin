struct ErrorCollector {
	TokenPos prev;
	std::atomic<i64>  count;
	std::atomic<i64>  warning_count;
	std::atomic<bool> in_block;
	BlockingMutex     mutex;
	BlockingMutex     error_out_mutex;
	BlockingMutex     string_mutex;
	RecursiveMutex    block_mutex;

	Array<u8> error_buffer;
	Array<String> errors;
};

gb_global ErrorCollector global_error_collector;

#define MAX_ERROR_COLLECTOR_COUNT (36)


bool any_errors(void) {
	return global_error_collector.count.load() != 0;
}

void init_global_error_collector(void) {
	mutex_init(&global_error_collector.mutex);
	mutex_init(&global_error_collector.block_mutex);
	mutex_init(&global_error_collector.error_out_mutex);
	mutex_init(&global_error_collector.string_mutex);
	array_init(&global_error_collector.errors, heap_allocator());
	array_init(&global_error_collector.error_buffer, heap_allocator());
	array_init(&global_file_path_strings, heap_allocator(), 1, 4096);
	array_init(&global_files,             heap_allocator(), 1, 4096);
}


bool set_file_path_string(i32 index, String const &path) {
	bool ok = false;
	GB_ASSERT(index >= 0);
	mutex_lock(&global_error_collector.string_mutex);

	if (index >= global_file_path_strings.count) {
		array_resize(&global_file_path_strings, index+1);
	}
	String prev = global_file_path_strings[index];
	if (prev.len == 0) {
		global_file_path_strings[index] = path;
		ok = true;
	}

	mutex_unlock(&global_error_collector.string_mutex);
	return ok;
}

bool thread_safe_set_ast_file_from_id(i32 index, AstFile *file) {
	bool ok = false;
	GB_ASSERT(index >= 0);
	mutex_lock(&global_error_collector.string_mutex);

	if (index >= global_files.count) {
		array_resize(&global_files, index+1);
	}
	AstFile *prev = global_files[index];
	if (prev == nullptr) {
		global_files[index] = file;
		ok = true;
	}

	mutex_unlock(&global_error_collector.string_mutex);
	return ok;
}

String get_file_path_string(i32 index) {
	GB_ASSERT(index >= 0);
	mutex_lock(&global_error_collector.string_mutex);

	String path = {};
	if (index < global_file_path_strings.count) {
		path = global_file_path_strings[index];
	}

	mutex_unlock(&global_error_collector.string_mutex);
	return path;
}

AstFile *thread_safe_get_ast_file_from_id(i32 index) {
	GB_ASSERT(index >= 0);
	mutex_lock(&global_error_collector.string_mutex);

	AstFile *file = nullptr;
	if (index < global_files.count) {
		file = global_files[index];
	}

	mutex_unlock(&global_error_collector.string_mutex);
	return file;
}



void begin_error_block(void) {
	mutex_lock(&global_error_collector.block_mutex);
	global_error_collector.in_block.store(true);
}

void end_error_block(void) {
	if (global_error_collector.error_buffer.count > 0) {
		isize n = global_error_collector.error_buffer.count;
		u8 *text = gb_alloc_array(permanent_allocator(), u8, n+1);
		gb_memmove(text, global_error_collector.error_buffer.data, n);
		text[n] = 0;
		String s = {text, n};
		array_add(&global_error_collector.errors, s);
		global_error_collector.error_buffer.count = 0;
	}

	global_error_collector.in_block.store(false);
	mutex_unlock(&global_error_collector.block_mutex);
}

#define ERROR_BLOCK() begin_error_block(); defer (end_error_block())


#define ERROR_OUT_PROC(name) void name(char const *fmt, va_list va)
typedef ERROR_OUT_PROC(ErrorOutProc);

ERROR_OUT_PROC(default_error_out_va) {
	gbFile *f = gb_file_get_standard(gbFileStandard_Error);

	char buf[4096] = {};
	isize len = gb_snprintf_va(buf, gb_size_of(buf), fmt, va);
	isize n = len-1;
	if (global_error_collector.in_block) {
		isize cap = global_error_collector.error_buffer.count + n;
		array_reserve(&global_error_collector.error_buffer, cap);
		u8 *data = global_error_collector.error_buffer.data + global_error_collector.error_buffer.count;
		gb_memmove(data, buf, n);
		global_error_collector.error_buffer.count += n;
	} else {
		mutex_lock(&global_error_collector.error_out_mutex);
		{
			u8 *text = gb_alloc_array(permanent_allocator(), u8, n+1);
			gb_memmove(text, buf, n);
			text[n] = 0;
			array_add(&global_error_collector.errors, make_string(text, n));
		}
		mutex_unlock(&global_error_collector.error_out_mutex);

	}
	gb_file_write(f, buf, n);
}


ErrorOutProc *error_out_va = default_error_out_va;

// NOTE: defined in build_settings.cpp
bool global_warnings_as_errors(void);
bool global_ignore_warnings(void);
bool show_error_line(void);
gbString get_file_line_as_string(TokenPos const &pos, i32 *offset);

void error_out(char const *fmt, ...) {
	va_list va;
	va_start(va, fmt);
	error_out_va(fmt, va);
	va_end(va);
}


bool show_error_on_line(TokenPos const &pos, TokenPos end) {
	if (!show_error_line()) {
		return false;
	}

	i32 offset = 0;
	gbString the_line = get_file_line_as_string(pos, &offset);
	defer (gb_string_free(the_line));

	if (the_line != nullptr) {
		String line = make_string(cast(u8 const *)the_line, gb_string_length(the_line));

		// TODO(bill): This assumes ASCII

		enum {
			MAX_LINE_LENGTH  = 76,
			MAX_TAB_WIDTH    = 8,
			ELLIPSIS_PADDING = 8
		};

		error_out("\n\t");
		if (line.len+MAX_TAB_WIDTH+ELLIPSIS_PADDING > MAX_LINE_LENGTH) {
			i32 const half_width = MAX_LINE_LENGTH/2;
			i32 left  = cast(i32)(offset);
			i32 right = cast(i32)(line.len - offset);
			left  = gb_min(left, half_width);
			right = gb_min(right, half_width);

			line.text += offset-left;
			line.len  -= offset+right-left;

			line = string_trim_whitespace(line);

			offset = left + ELLIPSIS_PADDING/2;

			error_out("... %.*s ...", LIT(line));
		} else {
			error_out("%.*s", LIT(line));
		}
		error_out("\n\t");

		for (i32 i = 0; i < offset; i++) {
			error_out(" ");
		}
		error_out("^");
		if (end.file_id == pos.file_id) {
			if (end.line > pos.line) {
				for (i32 i = offset; i < line.len; i++) {
					error_out("~");
				}
			} else if (end.line == pos.line && end.column > pos.column) {
				i32 length = gb_min(end.offset - pos.offset, cast(i32)(line.len-offset));
				for (i32 i = 1; i < length-1; i++) {
					error_out("~");
				}
				if (length > 1) {
					error_out("^");
				}
			}
		}

		error_out("\n\n");
		return true;
	}
	return false;
}

void error_va(TokenPos const &pos, TokenPos end, char const *fmt, va_list va) {
	global_error_collector.count.fetch_add(1);

	mutex_lock(&global_error_collector.mutex);
	// NOTE(bill): Duplicate error, skip it
	if (pos.line == 0) {
		error_out("Error: %s\n", gb_bprintf_va(fmt, va));
	} else if (global_error_collector.prev != pos) {
		global_error_collector.prev = pos;
		error_out("%s %s\n",
		          token_pos_to_string(pos),
		          gb_bprintf_va(fmt, va));
		show_error_on_line(pos, end);
	}
	mutex_unlock(&global_error_collector.mutex);
	if (global_error_collector.count > MAX_ERROR_COLLECTOR_COUNT) {
		gb_exit(1);
	}
}

void warning_va(TokenPos const &pos, TokenPos end, char const *fmt, va_list va) {
	if (global_warnings_as_errors()) {
		error_va(pos, end, fmt, va);
		return;
	}
	global_error_collector.warning_count.fetch_add(1);
	mutex_lock(&global_error_collector.mutex);
	if (!global_ignore_warnings()) {
		// NOTE(bill): Duplicate error, skip it
		if (pos.line == 0) {
			error_out("Warning: %s\n", gb_bprintf_va(fmt, va));
		} else if (global_error_collector.prev != pos) {
			global_error_collector.prev = pos;
			error_out("%s Warning: %s\n",
			          token_pos_to_string(pos),
			          gb_bprintf_va(fmt, va));
			show_error_on_line(pos, end);
		}
	}
	mutex_unlock(&global_error_collector.mutex);
}


void error_line_va(char const *fmt, va_list va) {
	error_out_va(fmt, va);
}

void error_no_newline_va(TokenPos const &pos, char const *fmt, va_list va) {
	mutex_lock(&global_error_collector.mutex);
	global_error_collector.count++;
	// NOTE(bill): Duplicate error, skip it
	if (pos.line == 0) {
		error_out("Error: %s", gb_bprintf_va(fmt, va));
	} else if (global_error_collector.prev != pos) {
		global_error_collector.prev = pos;
		error_out("%s %s",
		          token_pos_to_string(pos),
		          gb_bprintf_va(fmt, va));
	}
	mutex_unlock(&global_error_collector.mutex);
	if (global_error_collector.count > MAX_ERROR_COLLECTOR_COUNT) {
		gb_exit(1);
	}
}


void syntax_error_va(TokenPos const &pos, TokenPos end, char const *fmt, va_list va) {
	mutex_lock(&global_error_collector.mutex);
	global_error_collector.count++;
	// NOTE(bill): Duplicate error, skip it
	if (global_error_collector.prev != pos) {
		global_error_collector.prev = pos;
		error_out("%s Syntax Error: %s\n",
		          token_pos_to_string(pos),
		          gb_bprintf_va(fmt, va));
		show_error_on_line(pos, end);
	} else if (pos.line == 0) {
		error_out("Syntax Error: %s\n", gb_bprintf_va(fmt, va));
	}

	mutex_unlock(&global_error_collector.mutex);
	if (global_error_collector.count > MAX_ERROR_COLLECTOR_COUNT) {
		gb_exit(1);
	}
}

void syntax_warning_va(TokenPos const &pos, TokenPos end, char const *fmt, va_list va) {
	if (global_warnings_as_errors()) {
		syntax_error_va(pos, end, fmt, va);
		return;
	}
	mutex_lock(&global_error_collector.mutex);
	global_error_collector.warning_count++;
	if (!global_ignore_warnings()) {
		// NOTE(bill): Duplicate error, skip it
		if (global_error_collector.prev != pos) {
			global_error_collector.prev = pos;
			error_out("%s Syntax Warning: %s\n",
			          token_pos_to_string(pos),
			          gb_bprintf_va(fmt, va));
			show_error_on_line(pos, end);
		} else if (pos.line == 0) {
			error_out("Warning: %s\n", gb_bprintf_va(fmt, va));
		}
	}
	mutex_unlock(&global_error_collector.mutex);
}



void warning(Token const &token, char const *fmt, ...) {
	va_list va;
	va_start(va, fmt);
	warning_va(token.pos, {}, fmt, va);
	va_end(va);
}

void error(Token const &token, char const *fmt, ...) {
	va_list va;
	va_start(va, fmt);
	error_va(token.pos, {}, fmt, va);
	va_end(va);
}

void error(TokenPos pos, char const *fmt, ...) {
	va_list va;
	va_start(va, fmt);
	Token token = {};
	token.pos = pos;
	error_va(pos, {}, fmt, va);
	va_end(va);
}

void error_line(char const *fmt, ...) {
	va_list va;
	va_start(va, fmt);
	error_line_va(fmt, va);
	va_end(va);
}


void syntax_error(Token const &token, char const *fmt, ...) {
	va_list va;
	va_start(va, fmt);
	syntax_error_va(token.pos, {}, fmt, va);
	va_end(va);
}

void syntax_error(TokenPos pos, char const *fmt, ...) {
	va_list va;
	va_start(va, fmt);
	syntax_error_va(pos, {}, fmt, va);
	va_end(va);
}

void syntax_warning(Token const &token, char const *fmt, ...) {
	va_list va;
	va_start(va, fmt);
	syntax_warning_va(token.pos, {}, fmt, va);
	va_end(va);
}


void compiler_error(char const *fmt, ...) {
	va_list va;

	va_start(va, fmt);
	gb_printf_err("Internal Compiler Error: %s\n",
	              gb_bprintf_va(fmt, va));
	va_end(va);
	gb_exit(1);
}




