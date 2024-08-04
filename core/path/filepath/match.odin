package filepath

import "core:os"
import "core:slice"
import "core:strings"
import "core:unicode/utf8"

Match_Error :: enum {
	None,
	Syntax_Error,
}

// match states whether "name" matches the shell pattern
// Pattern syntax is:
//	pattern:
//		{term}
//	term:
//		'*'	        matches any sequence of non-/ characters
//		'?'             matches any single non-/ character
//		'[' ['^']  { character-range } ']'
//		                character classification (cannot be empty)
//		c               matches character c (c != '*', '?', '\\', '[')
//		'\\' c          matches character c
//
//	character-range
//		c               matches character c (c != '\\', '-', ']')
//		'\\' c          matches character c
//		lo '-' hi       matches character c for lo <= c <= hi
//
// match requires that the pattern matches the entirety of the name, not just a substring
// The only possible error returned is .Syntax_Error
//
// NOTE(bill): This is effectively the shell pattern matching system found
//
match :: proc(pattern, name: string) -> (matched: bool, err: Match_Error) {
	pattern, name := pattern, name
	pattern_loop: for len(pattern) > 0 {
		star: bool
		chunk: string
		star, chunk, pattern = scan_chunk(pattern)
		if star && chunk == "" {
			return !strings.contains(name, SEPARATOR_STRING), .None
		}

		t: string
		ok: bool
		t, ok, err = match_chunk(chunk, name)

		if ok && (len(t) == 0 || len(pattern) > 0) {
			name = t
			continue
		}
		if err != .None {
			return
		}
		if star {
			for i := 0; i < len(name) && name[i] != SEPARATOR; i += 1 {
				t, ok, err = match_chunk(chunk, name[i+1:])
				if ok {
					if len(pattern) == 0 && len(t) > 0 {
						continue
					}
					name = t
					continue pattern_loop
				}
				if err != .None {
					return
				}
			}
		}

		return false, .None
	}

	return len(name) == 0, .None
}


@(private="file")
scan_chunk :: proc(pattern: string) -> (star: bool, chunk, rest: string) {
	pattern := pattern
	for len(pattern) > 0 && pattern[0] == '*' {
		pattern = pattern[1:]
		star = true
	}

	in_range, i := false, 0

	scan_loop: for i = 0; i < len(pattern); i += 1 {
		switch pattern[i] {
		case '\\':
			when ODIN_OS != .Windows {
				if i+1 < len(pattern) {
					i += 1
				}
			}
		case '[':
			in_range = true
		case ']':
			in_range = false
		case '*':
			in_range or_break scan_loop

		}
	}
	return star, pattern[:i], pattern[i:]
}

@(private="file")
match_chunk :: proc(chunk, s: string) -> (rest: string, ok: bool, err: Match_Error) {
	chunk, s := chunk, s
	for len(chunk) > 0 {
		if len(s) == 0 {
			return
		}
		switch chunk[0] {
		case '[':
			r, w := utf8.decode_rune_in_string(s)
			s = s[w:]
			chunk = chunk[1:]
			is_negated := false
			if len(chunk) > 0 && chunk[0] == '^' {
				is_negated = true
				chunk = chunk[1:]
			}
			match := false
			range_count := 0
			for {
				if len(chunk) > 0 && chunk[0] == ']' && range_count > 0 {
					chunk = chunk[1:]
					break
				}
				lo, hi: rune
				if lo, chunk, err = get_escape(chunk); err != .None {
					return
				}
				hi = lo
				if chunk[0] == '-' {
					if hi, chunk, err = get_escape(chunk[1:]); err != .None {
						return
					}
				}

				if lo <= r && r <= hi {
					match = true
				}
				range_count += 1
			}
			if match == is_negated {
				return
			}

		case '?':
			if s[0] == SEPARATOR {
				return
			}
			_, w := utf8.decode_rune_in_string(s)
			s = s[w:]
			chunk = chunk[1:]

		case '\\':
			when ODIN_OS != .Windows {
				chunk = chunk[1:]
				if len(chunk) == 0 {
					err = .Syntax_Error
					return
				}
			}
			fallthrough
		case:
			if chunk[0] != s[0] {
				return
			}
			s = s[1:]
			chunk = chunk[1:]

		}
	}
	return s, true, .None
}

@(private="file")
get_escape :: proc(chunk: string) -> (r: rune, next_chunk: string, err: Match_Error) {
	if len(chunk) == 0 || chunk[0] == '-' || chunk[0] == ']' {
		err = .Syntax_Error
		return
	}
	chunk := chunk
	if chunk[0] == '\\' && ODIN_OS != .Windows {
		chunk = chunk[1:]
		if len(chunk) == 0 {
			err = .Syntax_Error
			return
		}
	}

	w: int
	r, w = utf8.decode_rune_in_string(chunk)
	if r == utf8.RUNE_ERROR && w == 1 {
		err = .Syntax_Error
	}

	next_chunk = chunk[w:]
	if len(next_chunk) == 0 {
		err = .Syntax_Error
	}

	return
}



// glob returns the names of all files matching pattern or nil if there are no matching files
// The syntax of patterns is the same as "match".
// The pattern may describe hierarchical names such as /usr/*/bin (assuming '/' is a separator)
//
// glob ignores file system errors
//
glob :: proc(pattern: string, allocator := context.allocator) -> (matches: []string, err: Match_Error) {
	context.allocator = allocator

	if !has_meta(pattern) {
		// TODO(bill): os.lstat on here to check for error
		m := make([]string, 1)
		m[0] = pattern
		return m[:], .None
	}

	dir, file := split(pattern)
	volume_len := 0
	when ODIN_OS == .Windows {
		temp_buf: [8]byte
		volume_len, dir = clean_glob_path_windows(dir, temp_buf[:])

	} else {
		dir = clean_glob_path(dir)
	}

	if !has_meta(dir[volume_len:]) {
		m, e := _glob(dir, file, nil)
		return m[:], e
	}

	m: []string
	m, err = glob(dir)
	if err != .None {
		return
	}
	dmatches := make([dynamic]string, 0, 0)
	for d in m {
		dmatches, err = _glob(d, file, &dmatches)
		if err != .None {
			break
		}
	}
	if len(dmatches) > 0 {
		matches = dmatches[:]
	}
	return
}

// Internal implementation of `glob`, not meant to be used by the user. Prefer `glob`.
_glob :: proc(dir, pattern: string, matches: ^[dynamic]string, allocator := context.allocator) -> (m: [dynamic]string, e: Match_Error) {
	context.allocator = allocator

	if matches != nil {
		m = matches^
	} else {
		m = make([dynamic]string, 0, 0)
	}


	d, derr := os.open(dir, os.O_RDONLY)
	if derr != nil {
		return
	}
	defer os.close(d)

	{
		file_info, ferr := os.fstat(d)
		defer os.file_info_delete(file_info)

		if ferr != nil {
			return
		}
		if !file_info.is_dir {
			return
		}
	}


	fis, _ := os.read_dir(d, -1)
	slice.sort_by(fis, proc(a, b: os.File_Info) -> bool {
		return a.name < b.name
	})
	defer {
		for fi in fis {
			os.file_info_delete(fi)
		}
		delete(fis)
	}

	for fi in fis {
		n := fi.name
		matched := match(pattern, n) or_return
		if matched {
			append(&m, join({dir, n}))
		}
	}
	return
}

@(private)
has_meta :: proc(path: string) -> bool {
	when ODIN_OS == .Windows {
		CHARS :: `*?[`
	} else {
		CHARS :: `*?[\`
	}
	return strings.contains_any(path, CHARS)
}

@(private)
clean_glob_path :: proc(path: string) -> string {
	switch path {
	case "":
		return "."
	case SEPARATOR_STRING:
		return path
	}
	return path[:len(path)-1]
}


@(private)
clean_glob_path_windows :: proc(path: string, temp_buf: []byte) -> (prefix_len: int, cleaned: string) {
	vol_len := volume_name_len(path)
	switch {
	case path == "":
		return 0, "."
	case vol_len+1 == len(path) && is_separator(path[len(path)-1]): // /, \, C:\, C:/
		return vol_len+1, path
	case vol_len == len(path) && len(path) == 2: // C:
		copy(temp_buf[:], path)
		temp_buf[2] = '.'
		return vol_len, string(temp_buf[:3])
	}

	if vol_len >= len(path) {
		vol_len = len(path) -1
	}
	return vol_len, path[:len(path)-1]
}
