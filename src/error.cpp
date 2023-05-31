struct ErrorCollector {
	TokenPos prev;
	std::atomic<i64>  count;
	std::atomic<i64>  warning_count;
	std::atomic<bool> in_block;
	BlockingMutex     mutex;
	BlockingMutex     error_out_mutex;
	BlockingMutex     string_mutex;
	RecursiveMutex    block_mutex;

	RecursiveMutex error_buffer_mutex;
	Array<u8>      error_buffer;
	Array<String>  errors;
};

gb_global ErrorCollector global_error_collector;


gb_internal bool any_errors(void) {
	return global_error_collector.count.load() != 0;
}

gb_internal void init_global_error_collector(void) {
	array_init(&global_error_collector.errors, heap_allocator());
	array_init(&global_error_collector.error_buffer, heap_allocator());
	array_init(&global_file_path_strings, heap_allocator(), 1, 4096);
	array_init(&global_files,             heap_allocator(), 1, 4096);
}

gb_internal isize MAX_ERROR_COLLECTOR_COUNT(void);


// temporary
// defined in build_settings.cpp
gb_internal char *token_pos_to_string(TokenPos const &pos);

gb_internal bool set_file_path_string(i32 index, String const &path) {
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

gb_internal bool thread_safe_set_ast_file_from_id(i32 index, AstFile *file) {
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

gb_internal String get_file_path_string(i32 index) {
	GB_ASSERT(index >= 0);
	mutex_lock(&global_error_collector.string_mutex);

	String path = {};
	if (index < global_file_path_strings.count) {
		path = global_file_path_strings[index];
	}

	mutex_unlock(&global_error_collector.string_mutex);
	return path;
}

gb_internal AstFile *thread_safe_get_ast_file_from_id(i32 index) {
	GB_ASSERT(index >= 0);
	mutex_lock(&global_error_collector.string_mutex);

	AstFile *file = nullptr;
	if (index < global_files.count) {
		file = global_files[index];
	}

	mutex_unlock(&global_error_collector.string_mutex);
	return file;
}



// NOTE: defined in build_settings.cpp
gb_internal bool global_warnings_as_errors(void);
gb_internal bool global_ignore_warnings(void);
gb_internal bool show_error_line(void);
gb_internal bool has_ansi_terminal_colours(void);
gb_internal gbString get_file_line_as_string(TokenPos const &pos, i32 *offset);

gb_internal void warning(Token const &token, char const *fmt, ...);
gb_internal void error(Token const &token, char const *fmt, ...);
gb_internal void error(TokenPos pos, char const *fmt, ...);
gb_internal void error_line(char const *fmt, ...);
gb_internal void syntax_error(Token const &token, char const *fmt, ...);
gb_internal void syntax_error(TokenPos pos, char const *fmt, ...);
gb_internal void syntax_warning(Token const &token, char const *fmt, ...);
gb_internal void compiler_error(char const *fmt, ...);

gb_internal void begin_error_block(void) {
	mutex_lock(&global_error_collector.block_mutex);
	global_error_collector.in_block.store(true);
}

gb_internal void end_error_block(void) {
	mutex_lock(&global_error_collector.error_buffer_mutex);
	isize n = global_error_collector.error_buffer.count;
	if (n > 0) {
		u8 *text = global_error_collector.error_buffer.data;

		bool add_extra_newline = false;

		if (show_error_line()) {
			if (n >= 2 && !(text[n-2] == '\n' && text[n-1] == '\n')) {
				add_extra_newline = true;
			}
		} else {
			isize newline_count = 0;
			for (isize i = 0; i < n; i++) {
				if (text[i] == '\n') {
					newline_count += 1;
				}
			}
			if (newline_count > 1) {
				add_extra_newline = true;
			}
		}

		if (add_extra_newline) {
			// add an extra new line as padding when the error line is being shown
			error_line("\n");
		}

		n = global_error_collector.error_buffer.count;
		text = gb_alloc_array(permanent_allocator(), u8, n+1);
		gb_memmove(text, global_error_collector.error_buffer.data, n);
		text[n] = 0;


		mutex_lock(&global_error_collector.error_out_mutex);
		String s = {text, n};
		array_add(&global_error_collector.errors, s);
		mutex_unlock(&global_error_collector.error_out_mutex);

		global_error_collector.error_buffer.count = 0;
	}
	mutex_unlock(&global_error_collector.error_buffer_mutex);
	global_error_collector.in_block.store(false);
	mutex_unlock(&global_error_collector.block_mutex);
}

#define ERROR_BLOCK() begin_error_block(); defer (end_error_block())


#define ERROR_OUT_PROC(name) void name(char const *fmt, va_list va)
typedef ERROR_OUT_PROC(ErrorOutProc);

gb_internal ERROR_OUT_PROC(default_error_out_va) {
	gbFile *f = gb_file_get_standard(gbFileStandard_Error);

	char buf[4096] = {};
	isize len = gb_snprintf_va(buf, gb_size_of(buf), fmt, va);
	isize n = len-1;
	if (global_error_collector.in_block) {
		mutex_lock(&global_error_collector.error_buffer_mutex);

		isize cap = global_error_collector.error_buffer.count + n;
		array_reserve(&global_error_collector.error_buffer, cap);
		u8 *data = global_error_collector.error_buffer.data + global_error_collector.error_buffer.count;
		gb_memmove(data, buf, n);
		global_error_collector.error_buffer.count += n;

		mutex_unlock(&global_error_collector.error_buffer_mutex);
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

gb_global ErrorOutProc *error_out_va = default_error_out_va;

gb_internal void error_out(char const *fmt, ...) {
	va_list va;
	va_start(va, fmt);
	error_out_va(fmt, va);
	va_end(va);
}

enum TerminalStyle {
	TerminalStyle_Normal,
	TerminalStyle_Bold,
	TerminalStyle_Underline,
};

enum TerminalColour {
	TerminalColour_White,
	TerminalColour_Red,
	TerminalColour_Yellow,
	TerminalColour_Green,
	TerminalColour_Cyan,
	TerminalColour_Blue,
	TerminalColour_Purple,
	TerminalColour_Black,
};

gb_internal void terminal_set_colours(TerminalStyle style, TerminalColour foreground) {
	if (has_ansi_terminal_colours()) {
		char const *ss = "0";
		switch (style) {
		case TerminalStyle_Normal:    ss = "0"; break;
		case TerminalStyle_Bold:      ss = "1"; break;
		case TerminalStyle_Underline: ss = "4"; break;
		}
		switch (foreground) {
		case TerminalColour_White:  error_out("\x1b[%s;37m", ss); break;
		case TerminalColour_Red:    error_out("\x1b[%s;31m", ss); break;
		case TerminalColour_Yellow: error_out("\x1b[%s;33m", ss); break;
		case TerminalColour_Green:  error_out("\x1b[%s;32m", ss); break;
		case TerminalColour_Cyan:   error_out("\x1b[%s;36m", ss); break;
		case TerminalColour_Blue:   error_out("\x1b[%s;34m", ss); break;
		case TerminalColour_Purple: error_out("\x1b[%s;35m", ss); break;
		case TerminalColour_Black:  error_out("\x1b[%s;30m", ss); break;
		}
	}
}
gb_internal void terminal_reset_colours(void) {
	if (has_ansi_terminal_colours()) {
		error_out("\x1b[0m");
	}
}


gb_internal bool show_error_on_line(TokenPos const &pos, TokenPos end) {
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
			MAX_LINE_LENGTH  = 80,
			MAX_TAB_WIDTH    = 8,
			ELLIPSIS_PADDING = 8, // `...  ...`
			MAX_LINE_LENGTH_PADDED = MAX_LINE_LENGTH-MAX_TAB_WIDTH-ELLIPSIS_PADDING,
		};

		error_out("\t");

		terminal_set_colours(TerminalStyle_Bold, TerminalColour_White);


		i32 error_length = gb_max(end.offset - pos.offset, 1);

		isize squiggle_extra = 0;

		if (line.len > MAX_LINE_LENGTH_PADDED) {
			i32 left = MAX_TAB_WIDTH;
			line.text += offset-left;
			line.len  -= offset-left;
			offset = left+MAX_TAB_WIDTH/2;
			if (line.len > MAX_LINE_LENGTH_PADDED) {
				line.len = MAX_LINE_LENGTH_PADDED;
				if (error_length > line.len-left) {
					error_length = cast(i32)line.len - left;
					squiggle_extra = 1;
				}
			}
			error_out("... %.*s ...", LIT(line));
		} else {
			error_out("%.*s", LIT(line));
		}
		error_out("\n\t");

		for (i32 i = 0; i < offset; i++) {
			error_out(" ");
		}

		terminal_set_colours(TerminalStyle_Bold, TerminalColour_Green);

		error_out("^");
		if (end.file_id == pos.file_id) {
			if (end.line > pos.line) {
				for (i32 i = offset; i < line.len; i++) {
					error_out("~");
				}
			} else if (end.line == pos.line && end.column > pos.column) {
				for (i32 i = 1; i < error_length-1+squiggle_extra; i++) {
					error_out("~");
				}
				if (error_length > 1 && squiggle_extra == 0) {
					error_out("^");
				}
			}
		}

		terminal_reset_colours();

		error_out("\n");
		return true;
	}
	return false;
}

gb_internal void error_out_pos(TokenPos pos) {
	terminal_set_colours(TerminalStyle_Bold, TerminalColour_White);
	error_out("%s ", token_pos_to_string(pos));
	terminal_reset_colours();
}

gb_internal void error_out_coloured(char const *str, TerminalStyle style, TerminalColour foreground) {
	terminal_set_colours(style, foreground);
	error_out(str);
	terminal_reset_colours();
}



gb_internal void error_va(TokenPos const &pos, TokenPos end, char const *fmt, va_list va) {
	global_error_collector.count.fetch_add(1);

	mutex_lock(&global_error_collector.mutex);
	// NOTE(bill): Duplicate error, skip it
	if (pos.line == 0) {
		error_out_coloured("Error: ", TerminalStyle_Normal, TerminalColour_Red);
		error_out_va(fmt, va);
		error_out("\n");
	} else if (global_error_collector.prev != pos) {
		global_error_collector.prev = pos;
		error_out_pos(pos);
		if (has_ansi_terminal_colours()) {
			error_out_coloured("Error: ", TerminalStyle_Normal, TerminalColour_Red);
		}
		error_out_va(fmt, va);
		error_out("\n");
		show_error_on_line(pos, end);
	}
	mutex_unlock(&global_error_collector.mutex);
	if (global_error_collector.count > MAX_ERROR_COLLECTOR_COUNT()) {
		gb_exit(1);
	}
}

gb_internal void warning_va(TokenPos const &pos, TokenPos end, char const *fmt, va_list va) {
	if (global_warnings_as_errors()) {
		error_va(pos, end, fmt, va);
		return;
	}
	global_error_collector.warning_count.fetch_add(1);
	mutex_lock(&global_error_collector.mutex);
	if (!global_ignore_warnings()) {
		// NOTE(bill): Duplicate error, skip it
		if (pos.line == 0) {
			error_out_coloured("Warning: ", TerminalStyle_Normal, TerminalColour_Yellow);
			error_out_va(fmt, va);
			error_out("\n");
		} else if (global_error_collector.prev != pos) {
			global_error_collector.prev = pos;
			error_out_pos(pos);
			error_out_coloured("Warning: ", TerminalStyle_Normal, TerminalColour_Yellow);
			error_out_va(fmt, va);
			error_out("\n");
			show_error_on_line(pos, end);
		}
	}
	mutex_unlock(&global_error_collector.mutex);
}


gb_internal void error_line_va(char const *fmt, va_list va) {
	error_out_va(fmt, va);
}

gb_internal void error_no_newline_va(TokenPos const &pos, char const *fmt, va_list va) {
	mutex_lock(&global_error_collector.mutex);
	global_error_collector.count++;
	// NOTE(bill): Duplicate error, skip it
	if (pos.line == 0) {
		error_out_coloured("Error: ", TerminalStyle_Normal, TerminalColour_Red);
		error_out_va(fmt, va);
	} else if (global_error_collector.prev != pos) {
		global_error_collector.prev = pos;
		error_out_pos(pos);
		if (has_ansi_terminal_colours()) {
			error_out_coloured("Error: ", TerminalStyle_Normal, TerminalColour_Red);
		}
		error_out_va(fmt, va);
	}
	mutex_unlock(&global_error_collector.mutex);
	if (global_error_collector.count > MAX_ERROR_COLLECTOR_COUNT()) {
		gb_exit(1);
	}
}


gb_internal void syntax_error_va(TokenPos const &pos, TokenPos end, char const *fmt, va_list va) {
	mutex_lock(&global_error_collector.mutex);
	global_error_collector.count++;
	// NOTE(bill): Duplicate error, skip it
	if (global_error_collector.prev != pos) {
		global_error_collector.prev = pos;
		error_out_pos(pos);
		error_out_coloured("Syntax Error: ", TerminalStyle_Normal, TerminalColour_Red);
		error_out_va(fmt, va);
		error_out("\n");
		// show_error_on_line(pos, end);
	} else if (pos.line == 0) {
		error_out_coloured("Syntax Error: ", TerminalStyle_Normal, TerminalColour_Red);
		error_out_va(fmt, va);
		error_out("\n");
	}

	mutex_unlock(&global_error_collector.mutex);
	if (global_error_collector.count > MAX_ERROR_COLLECTOR_COUNT()) {
		gb_exit(1);
	}
}

gb_internal void syntax_error_with_verbose_va(TokenPos const &pos, TokenPos end, char const *fmt, va_list va) {
	global_error_collector.count.fetch_add(1);

	mutex_lock(&global_error_collector.mutex);
	// NOTE(bill): Duplicate error, skip it
	if (pos.line == 0) {
		error_out_coloured("Syntax_Error: ", TerminalStyle_Normal, TerminalColour_Red);
		error_out_va(fmt, va);
		error_out("\n");
	} else if (global_error_collector.prev != pos) {
		global_error_collector.prev = pos;
		error_out_pos(pos);
		if (has_ansi_terminal_colours()) {
			error_out_coloured("Syntax_Error: ", TerminalStyle_Normal, TerminalColour_Red);
		}
		error_out_va(fmt, va);
		error_out("\n");
		show_error_on_line(pos, end);
	}
	mutex_unlock(&global_error_collector.mutex);
	if (global_error_collector.count > MAX_ERROR_COLLECTOR_COUNT()) {
		gb_exit(1);
	}
}


gb_internal void syntax_warning_va(TokenPos const &pos, TokenPos end, char const *fmt, va_list va) {
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
			error_out_pos(pos);
			error_out_coloured("Syntax Warning: ", TerminalStyle_Normal, TerminalColour_Yellow);
			error_out_va(fmt, va);
			error_out("\n");
			// show_error_on_line(pos, end);
		} else if (pos.line == 0) {
			error_out_coloured("Syntax Warning: ", TerminalStyle_Normal, TerminalColour_Yellow);
			error_out_va(fmt, va);
			error_out("\n");
		}
	}
	mutex_unlock(&global_error_collector.mutex);
}



gb_internal void warning(Token const &token, char const *fmt, ...) {
	va_list va;
	va_start(va, fmt);
	warning_va(token.pos, {}, fmt, va);
	va_end(va);
}

gb_internal void error(Token const &token, char const *fmt, ...) {
	va_list va;
	va_start(va, fmt);
	error_va(token.pos, {}, fmt, va);
	va_end(va);
}

gb_internal void error(TokenPos pos, char const *fmt, ...) {
	va_list va;
	va_start(va, fmt);
	Token token = {};
	token.pos = pos;
	error_va(pos, {}, fmt, va);
	va_end(va);
}

gb_internal void error_line(char const *fmt, ...) {
	va_list va;
	va_start(va, fmt);
	error_line_va(fmt, va);
	va_end(va);
}


gb_internal void syntax_error(Token const &token, char const *fmt, ...) {
	va_list va;
	va_start(va, fmt);
	syntax_error_va(token.pos, {}, fmt, va);
	va_end(va);
}

gb_internal void syntax_error(TokenPos pos, char const *fmt, ...) {
	va_list va;
	va_start(va, fmt);
	syntax_error_va(pos, {}, fmt, va);
	va_end(va);
}

gb_internal void syntax_warning(Token const &token, char const *fmt, ...) {
	va_list va;
	va_start(va, fmt);
	syntax_warning_va(token.pos, {}, fmt, va);
	va_end(va);
}

gb_internal void syntax_error_with_verbose(TokenPos pos, TokenPos end, char const *fmt, ...) {
	va_list va;
	va_start(va, fmt);
	syntax_error_with_verbose_va(pos, end, fmt, va);
	va_end(va);
}



gb_internal void compiler_error(char const *fmt, ...) {
	va_list va;

	va_start(va, fmt);
	gb_printf_err("Internal Compiler Error: %s\n",
	              gb_bprintf_va(fmt, va));
	va_end(va);
	GB_DEBUG_TRAP();
	gb_exit(1);
}




