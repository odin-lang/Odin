#+build !freestanding
package odin_libc

import "base:runtime"

import "core:c"
import "core:io"
import "core:os"
import "core:strconv"

import stb "vendor:stb/sprintf"

FILE :: uintptr

EOF :: -1

@(require, linkage="strong", link_name="fopen")
fopen :: proc "c" (path: cstring, mode: cstring) -> FILE {
	context = g_ctx
	unimplemented("vendor/libc: fopen")
}

@(require, linkage="strong", link_name="fseek")
fseek :: proc "c" (file: FILE, offset: c.long, whence: i32) -> i32 {
	context = g_ctx
	handle := os.Handle(file-1)
	_, err := os.seek(handle, i64(offset), int(whence))
	if err != nil {
		return -1
	}
	return 0
}

@(require, linkage="strong", link_name="ftell")
ftell :: proc "c" (file: FILE) -> c.long {
	context = g_ctx
	handle := os.Handle(file-1)
	off, err := os.seek(handle, 0, os.SEEK_CUR)
	if err != nil {
		return -1
	}
	return c.long(off)
}

@(require, linkage="strong", link_name="fclose")
fclose :: proc "c" (file: FILE) -> i32 {
	context = g_ctx
	handle := os.Handle(file-1)
	if os.close(handle) != nil {
		return -1
	}
	return 0
}

@(require, linkage="strong", link_name="fread")
fread :: proc "c" (buffer: [^]byte, size: uint, count: uint, file: FILE) -> uint {
	context = g_ctx
	handle := os.Handle(file-1)
	n, _   := os.read(handle, buffer[:min(size, count)])
	return uint(max(0, n))
}

@(require, linkage="strong", link_name="fwrite")
fwrite :: proc "c" (buffer: [^]byte, size: uint, count: uint, file: FILE) -> uint {
	context = g_ctx
	handle := os.Handle(file-1)
	n, _   := os.write(handle, buffer[:min(size, count)])
	return uint(max(0, n))
}

@(require, linkage="strong", link_name="putchar")
putchar :: proc "c" (char: c.int) -> c.int {
	context = g_ctx

	n, err := os.write_byte(os.stdout, byte(char))	
	if n == 0 || err != nil {
		return EOF
	}
	return char
}

@(require, linkage="strong", link_name="getchar")
getchar :: proc "c" () -> c.int {
	when #defined(os.stdin) {
		ret: [1]byte
		n, err := os.read(os.stdin, ret[:])
		if n == 0 || err != nil {
			return EOF
		}
		return c.int(ret[0])
	} else {
		return EOF
	}
}

@(require, linkage="strong", link_name="vsnprintf")
vsnprintf :: proc "c" (buf: [^]byte, count: uint, fmt: cstring, args: ^c.va_list) -> i32 {
	i32_count := i32(count)
	assert_contextless(i32_count >= 0)
	return stb.vsnprintf(buf, i32_count, fmt, args)
}

@(require, linkage="strong", link_name="vsprintf")
vsprintf :: proc "c" (buf: [^]byte, fmt: cstring, args: ^c.va_list) -> i32 {
	return stb.vsprintf(buf, fmt, args)
}

@(require, linkage="strong", link_name="vfprintf")
vfprintf :: proc "c" (file: FILE, fmt: cstring, args: ^c.va_list) -> i32 {
	context = g_ctx

	handle := os.Handle(file-1)

	MAX_STACK :: 4096

	buf: []byte
	stack_buf: [MAX_STACK]byte = ---
	{
		n := stb.vsnprintf(&stack_buf[0], MAX_STACK, fmt, args)
		if n <= 0 {
			return n
		}

		if n >= MAX_STACK {
			buf = make([]byte, n)
			n2 := stb.vsnprintf(raw_data(buf), i32(len(buf)), fmt, args)
			assert(n == n2)
		} else {
			buf = stack_buf[:n]
		}
	}
	defer if len(buf) > MAX_STACK {
		delete(buf)
	}

	_, err := io.write_full(os.stream_from_handle(handle), buf)
	if err != nil {
		return -1
	}

	return i32(len(buf))
}

/*
Derived from musl libc - MIT licensed - Copyright © 2005-2020 Rich Felker, et al.
*/
@(require, linkage="strong", link_name="__sscanf")
_sscanf :: proc "c" (str, fmt: [^]byte, orig_ptrs: [^]rawptr) -> i32 {
	Size :: enum u8 {
		None,
		hh,
		h,
		l,
		L,
		ll,
	}

	store_int :: proc(dest: rawptr, size: Size, i: u64) {
		if dest == nil { return }
		#partial switch size {
		case .hh:
			(^c.char)(dest)^ = c.char(i)
		case .h:
			(^c.short)(dest)^ = c.short(i)
		case .None:
			(^c.int)(dest)^ = c.int(i)
		case .l:
			(^c.long)(dest)^ = c.long(i)
		case .ll:
			(^c.longlong)(dest)^ = c.longlong(i)
		}
	}

	context = g_ctx

	str := str
	ptrs := orig_ptrs

	// TODO: implement wide char variants

	pos: u64
	dest: rawptr
	ch, t: byte
	// wcs: [^]c.wchar_t
	s: [^]byte
	k, i, width: int
	alloc: bool
	scanset: [257]byte
	invert: u8
	matches: i32
	size: Size
	input_fail, match_fail, fmt_fail, alloc_fail: bool

	main_loop: for p := fmt; p[0] != 0; p = p[1:] {
		alloc = false

		if isspace(i32(p[0])) {
			for isspace(i32(p[0])) {
				p = p[1:]
			}
			for isspace(i32(str[0])) {
				str = str[1:]
				pos += 1
			}
		}

		if p[0] != '%' || p[1] == '%' {
			if p[0] == '%' {
				p = p[1:]
			}
			ch = str[0]
			if ch != p[0] {
				if ch == 0 {
					input_fail = true
					break
				}
				match_fail = true
				break
			}
			pos += 1
			continue
		}

		p = p[1:]
		if p[0] == '*' {
			dest = nil
			p = p[1:]
		} else if isdigit(i32(p[0])) && p[1] == '$' {
			dest = orig_ptrs[p[0] - '0']
			p = p[2:]
		} else {
			dest = ptrs[0]
			ptrs = ptrs[1:]
		}

		for width = 0; isdigit(i32(p[0])); p = p[1:] {
			width = 10 * width + int(p[0] - '0')
		}

		if p[0] == 'm' {
			// wcs = nil
			s = nil
			alloc = dest != nil
			p = p[1:]
		} else {
			alloc = false
		}

		size = .None
		p = p[1:]
		switch p[-1] {
		case 'h':
			size = .h
			if p[0] == 'h' {
				p = p[1:]
				size = .hh
			}
		case 'l':
			size = .l
			if p[0] == 'l' {
				p = p[1:]
				size = .ll
			}
		case 'j':
			size = .ll
		case 'z', 't':
			size = .l
		case 'L':
			size = .L
		case 'd', 'i', 'o', 'u', 'x',
		     'a', 'e', 'f', 'g',
		     'A', 'E', 'F', 'G', 'X',
			 's', 'c', '[',
		     'S', 'C', 'p', 'n':
			p = p[-1:]
		case:
			fmt_fail = true
			break main_loop
		}

		t = p[0]

		switch t {
		case 'C':
			t = 'c'
			size = .l
		case 'S':
			t = 's'
			size = .l
		}

		switch t {
		case 'c':
			if width < 1 {
				width = 1
			}
		case '[':
		case 'n':
			store_int(dest, size, pos)
			continue
		case:
			for isspace(i32(str[0])) {
				str = str[1:]
				pos += 1
			}
		}

		if str[0] == 0 {
			input_fail = true
			break
		}

		if width == 0 {
			width = max(int)
		}

		switch t {
		case 's', 'c', '[':
			if t == 'c' || t == 's' {
				runtime.memset(&scanset, -1, size_of(scanset))
				scanset[0] = 0
				if t == 's' {
					scanset['\t'] = 0
					scanset['\n'] = 0
					scanset['\v'] = 0
					scanset['\f'] = 0
					scanset['\r'] = 0
					scanset[' ']  = 0
				}
			} else {
				p = p[1:]
				invert = 0
				if p[0] == '^' {
					p = p[1:]
					invert = 1
				}

				runtime.memset(&scanset, i32(invert), size_of(scanset))
				scanset[0] = 0
				if p[0] == '-' {
					p = p[1:]
					scanset['-'] = 1 - invert
				} else if p[0] == ']' {
					p = p[1:]
					scanset[']'] = 1 - invert
				}

				for ; p[0] != ']'; p = p[1:] {
					if p[0] == 0 {
						fmt_fail = true
						break main_loop
					}
					if p[0] == '-' && p[1] != ']' {
						c := p
						p = p[1:]
						for ch = c[0]; c[0] < p[0]; c, ch = c[1:], c[0] {
							scanset[ch] = 1 - invert
						}
						scanset[p[0]] = 1 - invert
					}
				}
			}

			// wcs = nil
			s = nil
			i = 0
			k = t == 'c' ? width + 1 : 31
			if size == .l {
				unimplemented("vendor/libc: sscanf wide character support")
			} else if alloc {
				s = make([^]byte, k)
				if s == nil {
					alloc_fail = true
					break main_loop
				}

				for ch = str[0]; scanset[ch] != 0 && i < width; {
					s[i] = ch
					i += 1
					if i == k {
						old_size := k
						k += k + 1
						tmp, _ := runtime.non_zero_mem_resize(s, old_size, k)
						if tmp == nil {
							alloc_fail = true
							break main_loop
						}
						s = raw_data(tmp)
					}

					str = str[1:]
					ch = str[0]
				}
			} else {
				s = cast([^]byte)dest
				if s != nil {
					for ch = str[0]; scanset[ch] != 0 && i < width; {
						s[i] = ch
						i += 1

						str = str[1:]
						ch = str[0]
					}
				} else {
					for ; scanset[str[0]] != 0 && i < width; str = str[1:] {}
				}
			}

			if i == 0 {
				match_fail = true
				break main_loop
			}

			str = str[-1:]

			if t == 'c' && i != width {
				match_fail = true
				break main_loop
			}

			if alloc {
				(^rawptr)(dest)^ = s
			}

			if t != 'c' {
				if s != nil {s[i] = 0}
			}
		case:
			base := -1
			switch t {
			case 'p', 'X', 'x':
				base = 16
				if i + 2 < width && str[0] == '0' && str[1] == 'x' {
					str = str[2:]
				}
			case 'o':
				base = 8
				if i + 1 < width && str[0] == '0' {
					str = str[1:]
				}
			case 'd', 'u':
				base = 10
			case 'i':
				base = 0
			}

			odin_str := string(cstring(str))
			odin_str  = odin_str[:min(len(odin_str), width-i)]
			cnt: int
			if base >= 0 {
				x: i64
				if base == 0 {
					x, _ = strconv.parse_i64_maybe_prefixed(odin_str, &cnt)
				} else {
					x, _ = strconv.parse_i64_of_base(odin_str, base, &cnt)
				}

				if cnt == 0 {
					match_fail = true
					break main_loop
				}

				if t == 'p' && dest != nil {
					(^rawptr)(dest)^ = rawptr(uintptr(x))
				} else {
					store_int(dest, size, u64(x))
				}
			} else {
				// should be a guarantee bcs of validation above.
				// switch t {
				// case 'a', 'A',
				//      'e', 'E',
				//      'f', 'F',
				//      'g', 'G':
				// }
				x, _ := strconv.parse_f64(odin_str, &cnt)

				if cnt == 0 {
					match_fail = true
					break main_loop
				}

				if dest != nil {
					#partial switch size {
					case .None:
						(^c.float)(dest)^ = c.float(x)
					case .l:
						(^c.double)(dest)^ = c.double(x)
					case .L:
						(^c.double)(dest)^ = c.double(x) // longdouble
					}
				}
			}

			pos += u64(cnt)
			str = str[cnt:]
		}

		if dest != nil {
			matches += 1
		}
	}

	if fmt_fail || alloc_fail || input_fail {
		if matches == 0 {
			matches = -1
		}
	}

	if match_fail {
		if alloc {
			free(s)
			// free(wcs)
		}
	}

	return matches
}
