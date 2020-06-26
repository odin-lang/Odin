package sys_windows

utf8_to_utf16 :: proc(s: string, allocator := context.temp_allocator) -> []u16 {
	if len(s) < 1 {
		return nil;
	}

	b := transmute([]byte)s;
	cstr := &b[0];
	n := MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, cstr, i32(len(s)), nil, 0);
	if n == 0 {
		return nil;
	}

	text := make([]u16, n+1, allocator);

	n1 := MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, cstr, i32(len(s)), wstring(&text[0]), i32(n));
	if n1 == 0 {
		delete(text, allocator);
		return nil;
	}

	text[n] = 0;
	for n >= 1 && text[n-1] == 0 {
		n -= 1;
	}
	return text[:n];
}
utf8_to_wstring :: proc(s: string, allocator := context.temp_allocator) -> wstring {
	if res := utf8_to_utf16(s, allocator); res != nil {
		return wstring(&res[0]);
	}
	return nil;
}

wstring_to_utf8 :: proc(s: wstring, N: int, allocator := context.temp_allocator) -> string {
	if N == 0 {
		return "";
	}

	n := WideCharToMultiByte(CP_UTF8, WC_ERR_INVALID_CHARS, s, i32(N), nil, 0, nil, nil);
	if n == 0 {
		return "";
	}

	// If N == -1 the call to WideCharToMultiByte assume the wide string is null terminated
	// and will scan it to find the first null terminated character. The resulting string will
	// also null terminated.
	// If N != -1 it assumes the wide string is not null terminated and the resulting string
	// will not be null terminated, we therefore have to force it to be null terminated manually.
	text := make([]byte, n+1 if N != -1 else n, allocator);

	if n1 := WideCharToMultiByte(CP_UTF8, WC_ERR_INVALID_CHARS, s, i32(N), &text[0], n, nil, nil); n1 == 0 {
		delete(text, allocator);
		return "";
	}

	for i in 0..<n {
		if text[i] == 0 {
			n = i;
			break;
		}
	}

	return string(text[:n]);
}

utf16_to_utf8 :: proc(s: []u16, allocator := context.temp_allocator) -> string {
	if len(s) == 0 do return "";
	return wstring_to_utf8(cast(wstring)&s[0], len(s), allocator);
}

