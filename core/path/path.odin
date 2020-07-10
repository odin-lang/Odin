package path

import "core:strings"
import "core:unicode/utf8"


// returns everything preceding the last path element
dir :: proc(path: string, new := false, allocator := context.allocator) -> string {
	if path == "" do return "";

	for i := len(path) - 1; i >= 0; i -= 1 {
		if path[i] == '/' || path[i] == '\\' {
			if path[:i] == "" {
				// path is root
				return new ? strings.clone(SEPARATOR_STRING, allocator) : SEPARATOR_STRING;
			} else {
				return new ? strings.clone(path[:i], allocator) : path[:i];
			}
		}
	}

	// path doesn't contain any folder structure
	return "";
}

// returns the final path element
base :: proc(path: string, new := false, allocator := context.allocator) -> string {
	if path == "" do return "";

	end := len(path) - 1;

	for i := end; i >= 0; i -= 1 {
		switch path[i] {
		case '/', '\\':
			if i != end {
				return new ? strings.clone(path[i+1:], allocator) : path[i+1:];
			} else {
				end = i; // we don't want trailing slashes
			}
		}
	}

	// path doesn't contain any folder structure, return entire path
	return new ? strings.clone(path, allocator) : path;
}

// returns the final path element, excluding the file extension if there is one
name :: proc(path: string, new := false, allocator := context.allocator) -> string {
	if path == "" do return "";

	dot := len(path);
	end := dot - 1;

	for i := end; i >= 0; i -= 1 {
		switch path[i] {
		case '.':       dot = (dot == end ? i : dot);
		case '/', '\\': return new ? strings.clone(path[i+1:dot], allocator) : path[i+1:dot];
		}
	}

	// path doesn't contain any folder structure or file extensions; assumed to be a valid file name
	return new ? strings.clone(path, allocator) : path;
}

// returns the file extension, if there is one
ext :: proc(path: string, new := false, allocator := context.allocator) -> string {
	if path == "" do return "";

	for i := len(path)-1; i >= 0; i -= 1 {
		switch path[i] {
		case '/', '\\': return "";
		case '.':       return new ? strings.clone(path[i+1:], allocator) : path[i+1:];
		}
	}

	// path does not include a file extension
	return "";
}


rel :: proc{rel_between, rel_current};

// returns the relative path from one path to another
rel_between :: proc(from, to: string, allocator := context.allocator) -> string {
	if from == "" || to == "" do return "";

	from, to := from, to;
	from = full(from, context.temp_allocator);
	to   = full(to,   context.temp_allocator);

	from_is_dir := is_dir(from);
	to_is_dir   := is_dir(to);

	index, slash := 0, 0;

	for {
		if index >= len(from) {
			if index >= len(to) || (from_is_dir && index < len(to) && (to[index] == '/' || to[index] == '\\')) {
				slash = index;
			}

			break;
		}
		else if index >= len(to) {
			if index >= len(from) || (to_is_dir && index < len(from) && (from[index] == '/' || from[index] == '\\')) {
				slash = index;
			}

			break;
		}

		lchar, skip := utf8.decode_rune_in_string(from[index:]);
		rchar, _    := utf8.decode_rune_in_string(to[index:]);

		if (lchar == '/' || lchar == '\\') && (rchar == '/' || lchar == '\\') {
			slash = index;
		}
		else if lchar != rchar {
			break;
		}

		index += skip;
	}

	if slash < 1 {
		// there is no common path, use the absolute `to` path
		return strings.clone(to, allocator);
	}

	from_slashes, to_slashes := 0, 0;

	if slash < len(from) {
		from = from[slash+1:];

		if from_is_dir {
			from_slashes += 1;
		}
	}
	else {
		from = "";
	}

	if slash < len(to) {
		to = to[slash+1:];

		if to_is_dir {
			to_slashes += 1;
		}
	}
	else {
		to = "";
	}

	for char in from {
		if char == '/' || char == '\\' {
			from_slashes += 1;
		}
	}

	for char in to {
		if char == '/' || char == '\\' {
			to_slashes += 1;
		}
	}

	if from_slashes == 0 {
		buffer := make([]byte, 2 + len(to), allocator);

		buffer[0] = '.';
		buffer[1] = SEPARATOR;
		copy(buffer[2:], to);

		return string(buffer);
	}
	else {
		buffer := make([]byte, from_slashes*3 + len(to), allocator);

		for i in 0..<from_slashes {
			buffer[i*3+0] = '.';
			buffer[i*3+1] = '.';
			buffer[i*3+2] = SEPARATOR;
		}

		copy(buffer[from_slashes*3:], to);

		return string(buffer);
	}

	return "";
}

// returns the relative path from the current directory to another path
rel_current :: proc(to: string, allocator := context.allocator) -> string {
	return rel_between(current(context.allocator), to, allocator);
}


// splits the path elements into slices of the original path string
split :: proc(s: string, allocator := context.allocator) -> []string {
	return strings.split_multi(s, []string{"\\", "/"}, true, allocator);
}
