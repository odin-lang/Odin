enum ErrorValueKind : u32 {
	ErrorValue_Error,
	ErrorValue_Warning,
};

struct ErrorValue {
	ErrorValueKind kind;
	TokenPos       pos;
	TokenPos       end;
	Array<u8>      msg;
	bool           seen_newline;
};

struct ErrorCollector {
	// TokenPos prev; // no point collecting because of the mulithreaded nature
	std::atomic<i64>  count;
	std::atomic<i64>  warning_count;
	std::atomic<bool> in_block;

	RecursiveMutex    mutex;
	BlockingMutex     path_mutex;

	Array<ErrorValue> error_values;
	ErrorValue        curr_error_value;
	std::atomic<bool> curr_error_value_set;
};

gb_global ErrorCollector global_error_collector;


gb_internal void push_error_value(TokenPos const &pos, ErrorValueKind kind = ErrorValue_Error) {
	GB_ASSERT_MSG(global_error_collector.curr_error_value_set.load() == false, "Possible race condition in error handling system, please report this with an issue");
	ErrorValue ev = {kind, pos};
	ev.msg.allocator = heap_allocator();

	global_error_collector.curr_error_value = ev;
	global_error_collector.curr_error_value_set.store(true);
}

gb_internal void pop_error_value(void) {
	mutex_lock(&global_error_collector.mutex);
	if (global_error_collector.curr_error_value_set.load()) {
		array_add(&global_error_collector.error_values, global_error_collector.curr_error_value);

		global_error_collector.curr_error_value = {};
		global_error_collector.curr_error_value_set.store(false);
	}
	mutex_unlock(&global_error_collector.mutex);
}


gb_internal void try_pop_error_value(void) {
	if (!global_error_collector.in_block.load()) {
		pop_error_value();
	}
}

gb_internal ErrorValue *get_error_value(void) {
	GB_ASSERT_MSG(global_error_collector.curr_error_value_set.load() == true, "Possible race condition in error handling system, please report this with an issue");
	return &global_error_collector.curr_error_value;
}



gb_internal bool any_errors(void) {
	return global_error_collector.count.load() != 0;
}
gb_internal bool any_warnings(void) {
	return global_error_collector.warning_count.load() != 0;
}


gb_internal void init_global_error_collector(void) {
	array_init(&global_error_collector.error_values, heap_allocator());
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
	mutex_lock(&global_error_collector.path_mutex);
	mutex_lock(&global_files_mutex);

	if (index >= global_file_path_strings.count) {
		array_resize(&global_file_path_strings, index+1);
	}
	String prev = global_file_path_strings[index];
	if (prev.len == 0) {
		global_file_path_strings[index] = path;
		ok = true;
	}

	mutex_unlock(&global_files_mutex);
	mutex_unlock(&global_error_collector.path_mutex);
	return ok;
}

gb_internal bool thread_safe_set_ast_file_from_id(i32 index, AstFile *file) {
	bool ok = false;
	GB_ASSERT(index >= 0);
	mutex_lock(&global_error_collector.path_mutex);
	mutex_lock(&global_files_mutex);

	if (index >= global_files.count) {
		array_resize(&global_files, index+1);
	}
	AstFile *prev = global_files[index];
	if (prev == nullptr) {
		global_files[index] = file;
		ok = true;
	}
	mutex_unlock(&global_files_mutex);
	mutex_unlock(&global_error_collector.path_mutex);
	return ok;
}

gb_internal String get_file_path_string(i32 index) {
	GB_ASSERT(index >= 0);
	mutex_lock(&global_error_collector.path_mutex);
	mutex_lock(&global_files_mutex);

	String path = {};
	if (index < global_file_path_strings.count) {
		path = global_file_path_strings[index];
	}

	mutex_unlock(&global_files_mutex);
	mutex_unlock(&global_error_collector.path_mutex);
	return path;
}

gb_internal AstFile *thread_safe_get_ast_file_from_id(i32 index) {
	GB_ASSERT(index >= 0);
	mutex_lock(&global_error_collector.path_mutex);
	mutex_lock(&global_files_mutex);

	AstFile *file = nullptr;
	if (index < global_files.count) {
		file = global_files[index];
	}

	mutex_unlock(&global_files_mutex);
	mutex_unlock(&global_error_collector.path_mutex);
	return file;
}



// NOTE: defined in build_settings.cpp
gb_internal bool global_warnings_as_errors(void);
gb_internal bool global_ignore_warnings(void);
gb_internal bool show_error_line(void);
gb_internal bool terse_errors(void);
gb_internal bool json_errors(void);
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
gb_internal void print_all_errors(void);


#define ERROR_OUT_PROC(name) void name(char const *fmt, va_list va)
typedef ERROR_OUT_PROC(ErrorOutProc);

gb_internal ERROR_OUT_PROC(default_error_out_va) {
	char buf[4096] = {};
	isize len = gb_snprintf_va(buf, gb_size_of(buf), fmt, va);
	isize n = len-1;

	if (n > 0) {
		ErrorValue *ev = get_error_value();
		if (terse_errors()) {
			for (isize i = 0; i < n && !ev->seen_newline; i++) {
				u8 c = cast(u8)buf[i];
				if (c == '\n') {
					ev->seen_newline = true;
				}
				array_add(&ev->msg, c);
			}
		} else {
			array_add_elems(&ev->msg, (u8 *)buf, n);
		}
	}
}

gb_global ErrorOutProc *error_out_va = default_error_out_va;

gb_internal void begin_error_block(void) {
	mutex_lock(&global_error_collector.mutex);
	global_error_collector.in_block.store(true);
}

gb_internal void end_error_block(void) {
	pop_error_value();
	global_error_collector.in_block.store(false);
	mutex_unlock(&global_error_collector.mutex);
}

#define ERROR_BLOCK() begin_error_block(); defer (end_error_block())



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
	TerminalColour_Grey,
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
		case TerminalColour_Grey:   error_out("\x1b[%s;90m", ss); break;
		}
	}
}
gb_internal void terminal_reset_colours(void) {
	if (has_ansi_terminal_colours()) {
		error_out("\x1b[0m");
	}
}


gb_internal isize show_error_on_line(TokenPos const &pos, TokenPos end) {
	get_error_value()->end = end;
	if (!show_error_line()) {
		return -1;
	}

	i32 error_start_index_bytes = 0;
	gbString the_line = get_file_line_as_string(pos, &error_start_index_bytes);
	defer (gb_string_free(the_line));

	if (the_line == nullptr || gb_string_length(the_line) == 0) {
		terminal_set_colours(TerminalStyle_Normal, TerminalColour_Grey);
		error_out("\t( empty line )\n");
		terminal_reset_colours();

		// Preserve the old return behaviour. Even if we can't guarantee the
		// exact visual space offset, there are two places that check this to
		// change what sort of suggestion they offer.
		if (the_line == nullptr) {
			return -1;
		} else {
			return cast(isize)error_start_index_bytes;
		}
	}

	// Specfically use basic ASCII arrows here, in case the terminal
	// doesn't support anything fancy. This is meant to be a good fallback.
	char const *mark_error_sign  = "><";
	char const *open_error_sign  = ">>";
	char const *close_error_sign = "<<";
	const TerminalColour marker_colour = TerminalColour_Yellow;

	// ANSI SGR:
	// 0      = Reset.
	// 58:5:2 = Underline colour, 8-bit, green. (non-standard)
	// 4:3    = Wiggly underline.               (non-standard)
	char const *wiggly_underline_sgr  = "";
	char const *disable_underline_sgr = "";
	if (has_ansi_terminal_colours()) {
		wiggly_underline_sgr  = "\x1b[0;58:5:2;4:3m";
		disable_underline_sgr = "\x1b[24m";
	}

	// These two will be used like an Odin slice later.
	char const *line_text = the_line;
	i32 line_length_bytes = cast(i32)gb_string_length(the_line);

	// NOTE(Feoramund): The numbers below are in Unicode codepoints
	// (or runes), not visual glyph width. Calculating the visual width of
	// a cluster of Unicode codepoints is vexing, and `utf8proc_charwidth`
	// is inadequate.
	//
	// We're counting codepoints here so we don't slice one down the
	// middle during truncation. It will still look strange if we slice
	// a cluster down the middle. (i.e. a letter and a combining diacritic)
	//
	// Luckily, if our assumption about 1 codepoint == 1 glyph is wrong,
	// we only suffer a shorter or longer line displayed in total, but all
	// of our highlighting and marking will be precise.
	// (Unless there's an invalid Unicode codepoint, in which case, no guarantees.)
	//
	// The line will be longer if a codepoint occupies more than one space
	// (CJK in most cases) and shorter if a codepoint is invisible or is
	// a type of joiner or combining codepoint.
	//
	// If we get a complete Unicode glyph counter, it would be as simple as
	// replacing `utf8_decode` below to make all of this work perfectly.

	enum {
		MAX_LINE_LENGTH  = 80,
		MAX_TAB_WIDTH    = 8,
		ELLIPSIS_PADDING = 8, // `...  ...`
		MAX_MARK_WIDTH   = 4, // `><` or `>>` and `<<`
		MIN_LEFT_VIEW    = 8,

		// A rough estimate of how many characters we'll insert, at most:
		MAX_INSERTED_WIDTH     = MAX_TAB_WIDTH + ELLIPSIS_PADDING + MAX_MARK_WIDTH,

		MAX_LINE_LENGTH_PADDED = MAX_LINE_LENGTH - MAX_INSERTED_WIDTH,
	};

	// For the purposes of truncating long lines, we calculate how many
	// runes the line is composed of, first. We'll take note of at which
	// rune index the error starts, too.
	i32 error_start_index_runes = 0;

	i32 line_length_runes = 0;
	for (i32 i = 0; i < line_length_bytes; /**/) {
		Rune rune;

		if (i == error_start_index_bytes) {
			error_start_index_runes = line_length_runes;
		}

		i32 bytes_read = cast(i32)utf8_decode(cast(const u8 *)line_text + i, line_length_bytes - i, &rune);
		if (rune == GB_RUNE_INVALID || bytes_read <= 0) {
			// Bail out; we won't even try to truncate the line later.
			line_length_runes = 0;
			break;
		}

		line_length_runes += 1;
		i += bytes_read;
	}

	if (error_start_index_runes == 0 && error_start_index_bytes != 0 && line_length_runes != 0) {
		// The error index in runes was not found, but we did find a valid Unicode string.
		//
		// This is an edge case where the error is sitting on a newline or the
		// end of the line, as that is the only location we could not have checked.
		error_start_index_runes = line_length_runes;
	}

	error_out("\t");

	bool show_right_ellipsis = false;

	if (line_length_runes > MAX_LINE_LENGTH_PADDED) {
		// Now that we know the line is over the length limit, we have to
		// compose a runic window in which to display the error.
		i32 window_width = MAX_LINE_LENGTH_PADDED;

		i32 extend_right = 0;
		i32 extend_left = 0;
		if (error_start_index_runes + window_width > line_length_runes - 1) {
			// Trade space from the right to the left.
			extend_right = line_length_runes - error_start_index_runes;
			extend_left = window_width - extend_right;
		} else if (MIN_LEFT_VIEW - error_start_index_runes > 0) {
			// Trade space from the left to the right.
			extend_left = error_start_index_runes;
			extend_right = window_width - extend_left;
		} else {
			// Square in the middle somewhere.
			extend_left = MIN_LEFT_VIEW;
			extend_right = window_width - extend_left;
		}

		i32 window_right_runes = gb_min(error_start_index_runes + extend_right, line_length_runes);
		i32 window_left_runes = gb_max(0, error_start_index_runes - extend_left);

		i32 window_right_bytes = 0;
		i32 window_left_bytes = 0;

		i32 i_runes = 0;
		for (i32 i = 0; i < line_length_bytes; /**/) {
			if (i_runes == window_left_runes ) { window_left_bytes  = i; }
			if (i_runes == window_right_runes) { window_right_bytes = i; }

			// No need for error-checking.
			//
			// We've already validated the string at this point, otherwise
			// `line_length_runes` would be 0, and we would not have
			// entered this block.
			i32 bytes_read = cast(i32)utf8_decode(cast(const u8 *)line_text + i, line_length_bytes - i, nullptr);

			i_runes += 1;
			i += bytes_read;
		}

		if (window_right_bytes == 0) {
			// The end of the window is the end of the line.
			window_right_bytes = line_length_bytes;
		}

		GB_ASSERT_MSG(window_right_runes >= window_left_runes, "Error line truncation window has wrong rune indices. (left, right: %i, %i)", window_left_runes, window_right_runes);
		GB_ASSERT_MSG(window_right_bytes >= window_left_bytes, "Error line truncation window has wrong byte indices. (left, right: %i, %i)", window_left_bytes, window_right_bytes);

		if (window_right_bytes != line_length_bytes) {
			show_right_ellipsis = true;
		}

		// The text will advance; all indices and lengths will become relative.
		// We must keep our other iterators in sync.
		// NOTE: Uncomment the rune versions if they ever get used beyond this point.

		// Close the window, going left.
		line_length_bytes = window_right_bytes;

		// Adjust the slice of text. In Odin, this would be:
		// `line_text = line_text[window_left_bytes:]`
		line_text += window_left_bytes;
		line_length_bytes -= window_left_bytes;
		// line_length_runes -= window_left_runes;
		GB_ASSERT_MSG(line_length_bytes >= 0, "Bounds-checking error: line_length_bytes");

		// Part of advancing `line_text`:
		error_start_index_bytes -= window_left_bytes;
		// error_start_index_runes -= window_left_runes;
		GB_ASSERT_MSG(error_start_index_bytes >= 0, "Bounds-checking error: error_start_index_bytes");

		if (window_left_bytes > 0) {
			error_out("... ");
		}
	}

	// Start printing code.

	terminal_set_colours(TerminalStyle_Normal, TerminalColour_White);
	error_out("%.*s", error_start_index_bytes, line_text);

	// Odin-like: `line_text = line_text[error_start_index_bytes:]`
	line_text += error_start_index_bytes;
	line_length_bytes -= error_start_index_bytes;
	GB_ASSERT_MSG(line_length_bytes >= 0, "Bounds-checking error: line_length_bytes");

	if (end.file_id == pos.file_id) {
		// The error has an endpoint.
		terminal_set_colours(TerminalStyle_Bold, marker_colour);
		error_out(open_error_sign);

		if (end.line > pos.line) {
			// Error goes to next line.
			error_out(wiggly_underline_sgr);
			error_out("%.*s", line_length_bytes, line_text);

			error_out(disable_underline_sgr);

			// Always show the ellipsis in this case
			show_right_ellipsis = true;

		} else if (end.line == pos.line && end.column > pos.column) {
			// Error terminates before line end.
			i32 error_length_bytes = gb_min(end.column - pos.column, line_length_bytes);

			error_out(wiggly_underline_sgr);
			error_out("%.*s", error_length_bytes, line_text);
			line_text += error_length_bytes;
			line_length_bytes -= error_length_bytes;
			GB_ASSERT_MSG(line_length_bytes >= 0, "Bounds-checking error: line_length_bytes");

			error_out(disable_underline_sgr);

			if (!show_right_ellipsis) {
				// The line hasn't been truncated; show the end marker.
				terminal_set_colours(TerminalStyle_Bold, marker_colour);
				error_out(close_error_sign);
			}

			terminal_set_colours(TerminalStyle_Normal, TerminalColour_White);
			error_out("%.*s", line_length_bytes, line_text);
		}

	} else {
		// The error is at one spot; no range known.
		terminal_set_colours(TerminalStyle_Bold, marker_colour);
		error_out(mark_error_sign);

		terminal_set_colours(TerminalStyle_Normal, TerminalColour_White);
		error_out("%.*s", line_length_bytes, line_text);
	}

	if (show_right_ellipsis) {
		error_out(" ...");
	}

	// NOTE(Feoramund): Specifically print a newline, then reset colours,
	// instead of the other way around. Otherwise the printing mechanism
	// will collapse the newline for reasons currently beyond my ken.
	error_out("\n");
	terminal_reset_colours();

	return error_start_index_bytes;
}

gb_internal void error_out_empty(void) {
	error_out("");
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
	if (global_error_collector.count > MAX_ERROR_COLLECTOR_COUNT()) {
		print_all_errors();
		gb_exit(1);
	}

	push_error_value(pos, ErrorValue_Error);
	if (pos.line == 0) {
		error_out_empty();
		error_out_coloured("Error: ", TerminalStyle_Normal, TerminalColour_Red);
		error_out_va(fmt, va);
		error_out("\n");
	} else {
		// global_error_collector.prev = pos;
		if (json_errors()) {
			error_out_empty();
		} else {
			error_out_pos(pos);
			error_out_coloured("Error: ", TerminalStyle_Normal, TerminalColour_Red);
		}
		error_out_va(fmt, va);
		error_out("\n");
		show_error_on_line(pos, end);
	}
	try_pop_error_value();
	mutex_unlock(&global_error_collector.mutex);
}

gb_internal void warning_va(TokenPos const &pos, TokenPos end, char const *fmt, va_list va) {
	if (global_warnings_as_errors()) {
		error_va(pos, end, fmt, va);
		return;
	}
	if (global_ignore_warnings()) {
		return;
	}

	global_error_collector.warning_count.fetch_add(1);
	mutex_lock(&global_error_collector.mutex);

	push_error_value(pos, ErrorValue_Warning);

	if (pos.line == 0) {
		error_out_empty();
		error_out_coloured("Warning: ", TerminalStyle_Normal, TerminalColour_Yellow);
		error_out_va(fmt, va);
		error_out("\n");
	} else {
		// global_error_collector.prev = pos;
		if (json_errors()) {
			error_out_empty();
		} else {
			error_out_pos(pos);
			error_out_coloured("Warning: ", TerminalStyle_Normal, TerminalColour_Yellow);
		}
		error_out_va(fmt, va);
		error_out("\n");
		show_error_on_line(pos, end);
	}
	try_pop_error_value();
	mutex_unlock(&global_error_collector.mutex);
}


gb_internal void error_line_va(char const *fmt, va_list va) {
	error_out_va(fmt, va);
}

gb_internal void error_no_newline_va(TokenPos const &pos, char const *fmt, va_list va) {
	global_error_collector.count.fetch_add(1);
	mutex_lock(&global_error_collector.mutex);
	if (global_error_collector.count.load() > MAX_ERROR_COLLECTOR_COUNT()) {
		print_all_errors();
		gb_exit(1);
	}

	push_error_value(pos, ErrorValue_Error);

	if (pos.line == 0) {
		error_out_empty();
		error_out_coloured("Error: ", TerminalStyle_Normal, TerminalColour_Red);
		error_out_va(fmt, va);
	} else {
		// global_error_collector.prev = pos;
		if (json_errors()) {
			error_out_empty();
		} else {
			error_out_pos(pos);
		}
		if (has_ansi_terminal_colours()) {
			error_out_coloured("Error: ", TerminalStyle_Normal, TerminalColour_Red);
		}
		error_out_va(fmt, va);
	}

	try_pop_error_value();
	mutex_unlock(&global_error_collector.mutex);
}


gb_internal void syntax_error_va(TokenPos const &pos, TokenPos end, char const *fmt, va_list va) {
	global_error_collector.count.fetch_add(1);
	mutex_lock(&global_error_collector.mutex);
	if (global_error_collector.count > MAX_ERROR_COLLECTOR_COUNT()) {
		print_all_errors();
		gb_exit(1);
	}

	push_error_value(pos, ErrorValue_Warning);

	if (pos.line == 0) {
		error_out_empty();
		error_out_coloured("Syntax Error: ", TerminalStyle_Normal, TerminalColour_Red);
		error_out_va(fmt, va);
		error_out("\n");
	} else {
		// global_error_collector.prev = pos;
		if (json_errors()) {
			error_out_empty();
		} else {
			error_out_pos(pos);
		}
		error_out_coloured("Syntax Error: ", TerminalStyle_Normal, TerminalColour_Red);
		error_out_va(fmt, va);
		error_out("\n");
		show_error_on_line(pos, end);
	}

	try_pop_error_value();
	mutex_unlock(&global_error_collector.mutex);
}

gb_internal void syntax_error_with_verbose_va(TokenPos const &pos, TokenPos end, char const *fmt, va_list va) {
	global_error_collector.count.fetch_add(1);
	mutex_lock(&global_error_collector.mutex);
	if (global_error_collector.count > MAX_ERROR_COLLECTOR_COUNT()) {
		print_all_errors();
		gb_exit(1);
	}

	push_error_value(pos, ErrorValue_Warning);

	if (pos.line == 0) {
		error_out_empty();
		error_out_coloured("Syntax Error: ", TerminalStyle_Normal, TerminalColour_Red);
		error_out_va(fmt, va);
		error_out("\n");
	} else {
		// global_error_collector.prev = pos;
		if (json_errors()) {
			error_out_empty();
		} else {
			error_out_pos(pos);
		}
		if (has_ansi_terminal_colours()) {
			error_out_coloured("Syntax Error: ", TerminalStyle_Normal, TerminalColour_Red);
		}
		error_out_va(fmt, va);
		error_out("\n");
		show_error_on_line(pos, end);
	}

	try_pop_error_value();
	mutex_unlock(&global_error_collector.mutex);
}


gb_internal void syntax_warning_va(TokenPos const &pos, TokenPos end, char const *fmt, va_list va) {
	if (global_warnings_as_errors()) {
		syntax_error_va(pos, end, fmt, va);
		return;
	}
	if (global_ignore_warnings()) {
		return;
	}
	mutex_lock(&global_error_collector.mutex);
	global_error_collector.warning_count++;


	push_error_value(pos, ErrorValue_Warning);

	if (pos.line == 0) {
		error_out_empty();
		error_out_coloured("Syntax Warning: ", TerminalStyle_Normal, TerminalColour_Yellow);
		error_out_va(fmt, va);
		error_out("\n");
	} else {
		// global_error_collector.prev = pos;
		if (json_errors()) {
			error_out_empty();
		} else {
			error_out_pos(pos);
		}
		error_out_coloured("Syntax Warning: ", TerminalStyle_Normal, TerminalColour_Yellow);
		error_out_va(fmt, va);
		error_out("\n");
		// show_error_on_line(pos, end);
	}

	try_pop_error_value();
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
	if (any_errors() || any_warnings()) {
		print_all_errors();
	}

	va_list va;

	va_start(va, fmt);
	gb_printf_err("Internal Compiler Error: %s\n",
	              gb_bprintf_va(fmt, va));
	va_end(va);
	GB_DEBUG_TRAP();
	gb_exit(1);
}


gb_internal void exit_with_errors(void) {
	if (any_errors() || any_warnings()) {
		print_all_errors();
	}
	gb_exit(1);
}



gb_internal int error_value_cmp(void const *a, void const *b) {
	ErrorValue *x = cast(ErrorValue *)a;
	ErrorValue *y = cast(ErrorValue *)b;
	return token_pos_cmp(x->pos, y->pos);
}

gb_internal bool errors_already_printed = false;

gb_internal void print_all_errors(void) {
	if (errors_already_printed) {
		if (global_error_collector.warning_count.load() == global_error_collector.error_values.count) {
			for (ErrorValue &ev : global_error_collector.error_values) {
				array_free(&ev.msg);
			}
			array_clear(&global_error_collector.error_values);
			errors_already_printed = false;
		}
		return;
	}

	auto const &escape_char = [](gbString res, u8 c) -> gbString {
		switch (c) {
		case '\n': res = gb_string_append_length(res, "\\n",  2); break;
		case '"':  res = gb_string_append_length(res, "\\\"", 2); break;
		case '\\': res = gb_string_append_length(res, "\\\\", 2); break;
		case '\b': res = gb_string_append_length(res, "\\b",  2); break;
		case '\f': res = gb_string_append_length(res, "\\f",  2); break;
		case '\r': res = gb_string_append_length(res, "\\r",  2); break;
		case '\t': res = gb_string_append_length(res, "\\t",  2); break;
		default:
			if ('\x00' <= c && c <= '\x1f') {
				res = gb_string_append_fmt(res, "\\u%04x", c);
			} else {
				res = gb_string_append_length(res, &c, 1);
			}
			break;
		}
		return res;
	};

	GB_ASSERT(any_errors() || any_warnings());

	array_sort(global_error_collector.error_values, error_value_cmp);


	{ // NOTE(bill): merge neighbouring errors
		isize default_lines_to_skip = 1;
		if (show_error_line()) {
			// NOTE(bill): this will always be 2 extra lines
			default_lines_to_skip += 2;
		}

		ErrorValue *prev_ev = nullptr;
		for (isize i = 0; i < global_error_collector.error_values.count; /**/) {
			ErrorValue &ev = global_error_collector.error_values[i];

			if (prev_ev && prev_ev->pos == ev.pos) {
				String_Iterator it = {{ev.msg.data, ev.msg.count}, 0};

				for (isize lines_to_skip = default_lines_to_skip; lines_to_skip > 0; lines_to_skip -= 1) {
					String line = string_split_iterator(&it, '\n');
					if (line.len == 0) {
						break;
					}
				}

				// Merge additional text (suggestions for example) into the previous error.
				String current = {prev_ev->msg.data, prev_ev->msg.count};
				String addition = {it.str.text+it.pos, it.str.len-it.pos};
				if (addition.len > 0 && !string_contains_string(current, addition)) {
					array_add_elems(&prev_ev->msg, addition.text, addition.len);
				}

				array_free(&ev.msg);
				array_ordered_remove(&global_error_collector.error_values, i);
			} else {
				prev_ev = &ev;
				i += 1;
			}
		}
	}

	gbString res = gb_string_make(heap_allocator(), "");
	defer (gb_string_free(res));

	if (json_errors()) {
		res = gb_string_append_fmt(res, "{\n");
		res = gb_string_append_fmt(res, "\t\"error_count\": %td,\n", global_error_collector.error_values.count);
		res = gb_string_append_fmt(res, "\t\"errors\": [\n");

		for_array(i, global_error_collector.error_values) {
			ErrorValue ev = global_error_collector.error_values[i];

			res = gb_string_append_fmt(res, "\t\t{\n");

			res = gb_string_append_fmt(res, "\t\t\t\"type\": \"");
			if (ev.kind == ErrorValue_Warning) {
				res = gb_string_append_fmt(res, "warning");
			} else {
				res = gb_string_append_fmt(res, "error");
			}
			res = gb_string_append_fmt(res, "\",\n");

			if (ev.pos.file_id) {
				res = gb_string_append_fmt(res, "\t\t\t\"pos\": {\n");
				res = gb_string_append_fmt(res, "\t\t\t\t\"file\": \"");
				String file = get_file_path_string(ev.pos.file_id);
				for (isize k = 0; k < file.len; k++) {
					res = escape_char(res, file.text[k]);
				}
				res = gb_string_append_fmt(res, "\",\n");
				res = gb_string_append_fmt(res, "\t\t\t\t\"offset\": %d,\n", ev.pos.offset);
				res = gb_string_append_fmt(res, "\t\t\t\t\"line\": %d,\n", ev.pos.line);
				res = gb_string_append_fmt(res, "\t\t\t\t\"column\": %d,\n", ev.pos.column);
				i32 end_column = gb_max(ev.end.column, ev.pos.column);
				res = gb_string_append_fmt(res, "\t\t\t\t\"end_column\": %d\n", end_column);
				res = gb_string_append_fmt(res, "\t\t\t},\n");
			} else {
				res = gb_string_append_fmt(res, "\t\t\t\"pos\": null,\n");
			}

			res = gb_string_append_fmt(res, "\t\t\t\"msgs\": [\n");

			auto lines = split_lines_from_array(ev.msg, heap_allocator());
			defer (array_free(&lines));

			if (lines.count > 0) {
				res = gb_string_append_fmt(res, "\t\t\t\t\"");

				for (isize j = 0; j < lines.count; j++) {
					String line = lines[j];
					for (isize k = 0; k < line.len; k++) {
						u8 c = line.text[k];
						res = escape_char(res, c);
					}
					if (j+1 < lines.count) {
						res = gb_string_append_fmt(res, "\",\n");
						res = gb_string_append_fmt(res, "\t\t\t\t\"");
					}
				}
				res = gb_string_append_fmt(res, "\"\n");
			}
			res = gb_string_append_fmt(res, "\t\t\t]\n");
			res = gb_string_append_fmt(res, "\t\t}");
			if (i+1 != global_error_collector.error_values.count) {
				res = gb_string_append_fmt(res, ",");
			}
			res = gb_string_append_fmt(res, "\n");
		}

		res = gb_string_append_fmt(res, "\t]\n");
		res = gb_string_append_fmt(res, "}\n");
	} else {
		for_array(i, global_error_collector.error_values) {
			ErrorValue ev = global_error_collector.error_values[i];

			String_Iterator it = {{ev.msg.data, ev.msg.count}, 0};

			for (isize line_idx = 0; /**/; line_idx++) {
				String line = string_split_iterator(&it, '\n');
				if (line.len == 0) {
					break;
				}
				line = string_trim_trailing_whitespace(line);
				res = gb_string_append_length(res, line.text, line.len);
				res = gb_string_append_length(res, " \n", 2);
				if (line_idx == 0 && terse_errors()) {
					break;
				}
			}
		}
	}
	gbFile *f = gb_file_get_standard(gbFileStandard_Error);
	gb_file_write(f, res, gb_string_length(res));

	errors_already_printed = true;
}
