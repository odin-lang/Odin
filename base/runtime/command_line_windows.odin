package runtime

_windows_split_command_line :: proc "contextless" (cmd_line: [^]u16, argv: [^]cstring16, text: [^]u16) -> (argc, text_len: int) {
	put :: #force_inline proc "contextless" (text: [^]u16, text_len: ^int, c: u16) {
		if text != nil {
			text[text_len^] = c
		}
		text_len^ += 1
	}

	if cmd_line == nil {
		return
	}

	i := 0

	if argv != nil {
		argv[0] = cstring16(text)
	}
	argc = 1
	for in_quotes := false; cmd_line[i] != 0; i += 1 {
		c := cmd_line[i]
		if !in_quotes && (c == ' ' || c == '\t') {
			break
		}
		if c == '"' {
			in_quotes = !in_quotes
		} else {
			put(text, &text_len, c)
		}
	}
	put(text, &text_len, 0)

	in_quotes := false
	for {
		for cmd_line[i] == ' ' || cmd_line[i] == '\t' {
			i += 1
		}
		if cmd_line[i] == 0 {
			return
		}

		if argv != nil {
			argv[argc] = cstring16(text[text_len:])
		}
		argc += 1

		for {
			copy_char   := true
			backslashes := 0
			for cmd_line[i] == '\\' {
				backslashes += 1
				i += 1
			}
			if cmd_line[i] == '"' {
				if backslashes%2 == 0 {
					if in_quotes && cmd_line[i+1] == '"' {
						i += 1
					} else {
						copy_char = false
						in_quotes = !in_quotes
					}
				}
				backslashes /= 2
			}
			for _ in 0..<backslashes {
				put(text, &text_len, '\\')
			}

			c := cmd_line[i]
			if c == 0 || (!in_quotes && (c == ' ' || c == '\t')) {
				break
			}
			if copy_char {
				put(text, &text_len, c)
			}
			i += 1
		}
		put(text, &text_len, 0)
	}
}
