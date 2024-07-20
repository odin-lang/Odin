#if defined(GB_SYSTEM_UNIX)
// Required for intrinsics on GCC
#include <xmmintrin.h>
#endif

#if defined(GB_COMPILER_MSVC)
#include <intrin.h>
#endif

#if defined(GB_SYSTEM_WINDOWS)

#define NOMINMAX            1
#include <windows.h>
#undef NOMINMAX
#endif

#include <string.h>

#define GB_WINDOWS_H_INCLUDED
#define GB_IMPLEMENTATION
#include "gb/gb.h"

#include <wchar.h>
#include <stdio.h>

#if defined(GB_COMPILER_MSVC)
#include <psapi.h>
#endif

#include <math.h>
#include <string.h>
#include <atomic> // Because I wanted the C++11 memory order semantics, of which gb.h does not offer (because it was a C89 library)

gb_internal gbAllocator heap_allocator(void);

#define for_array_off(index_, off_, array_) for (isize index_ = off_; index_ < (array_).count; index_++)
#define for_array(index_, array_) for_array_off(index_, 0, array_)

gb_internal i32 next_pow2(i32 n);
gb_internal i64 next_pow2(i64 n);
gb_internal isize next_pow2_isize(isize n);
gb_internal void debugf(char const *fmt, ...);

#if defined(GB_SYSTEM_WINDOWS) && defined(GB_ARCH_32_BIT)
#error Odin on Windows requires a 64-bit build-system. The 'Developer Command Prompt' for VS still defaults to 32-bit shell. The 64-bit shell can be found under the name 'x64 Native Tools Command Prompt' for VS. For more information, please see https://odin-lang.org/docs/install/#for-windows
#endif

template <typename T>
struct TypeIsPointer {
	enum {value = false};
};

template <typename T>
struct TypeIsPointer<T *> {
	enum {value = true};
};

template <typename T> struct TypeIsPtrSizedInteger { enum {value = false}; };
template <> struct TypeIsPtrSizedInteger<isize> { enum {value = true}; };
template <> struct TypeIsPtrSizedInteger<usize> { enum {value = true}; };


#include "unicode.cpp"
#include "array.cpp"
#include "threading.cpp"
#include "common_memory.cpp"
#include "queue.cpp"
#include "string.cpp"
#include "range_cache.cpp"

#if defined(GB_SYSTEM_WINDOWS)
	#pragma warning(push)
	#pragma warning(disable: 4505)
#endif

gb_internal gb_inline bool is_power_of_two(i64 x) {
	if (x <= 0) {
		return false;
	}
	return !(x & (x-1));
}

gb_internal int isize_cmp(isize x, isize y) {
	if (x < y) {
		return -1;
	} else if (x > y) {
		return +1;
	}
	return 0;
}
gb_internal int u64_cmp(u64 x, u64 y) {
	if (x < y) {
		return -1;
	} else if (x > y) {
		return +1;
	}
	return 0;
}
gb_internal int i64_cmp(i64 x, i64 y) {
	if (x < y) {
		return -1;
	} else if (x > y) {
		return +1;
	}
	return 0;
}
gb_internal int i32_cmp(i32 x, i32 y) {
	if (x < y) {
		return -1;
	} else if (x > y) {
		return +1;
	}
	return 0;
}

gb_internal u32 fnv32a(void const *data, isize len) {
	u8 const *bytes = cast(u8 const *)data;
	u32 h = 0x811c9dc5;
	
	for (; len >= 8; len -= 8, bytes += 8) {
		h = (h ^ bytes[0]) * 0x01000193;
		h = (h ^ bytes[1]) * 0x01000193;
		h = (h ^ bytes[2]) * 0x01000193;
		h = (h ^ bytes[3]) * 0x01000193;
		h = (h ^ bytes[4]) * 0x01000193;
		h = (h ^ bytes[5]) * 0x01000193;
		h = (h ^ bytes[6]) * 0x01000193;
		h = (h ^ bytes[7]) * 0x01000193;
	}

	while (len--) {
		h = (h ^ *bytes++) * 0x01000193;
	}
	return h;
}

gb_internal u64 fnv64a(void const *data, isize len) {
	u8 const *bytes = cast(u8 const *)data;
	u64 h = 0xcbf29ce484222325ull;
	
	for (; len >= 8; len -= 8, bytes += 8) {
		h = (h ^ bytes[0]) * 0x100000001b3ull;
		h = (h ^ bytes[1]) * 0x100000001b3ull;
		h = (h ^ bytes[2]) * 0x100000001b3ull;
		h = (h ^ bytes[3]) * 0x100000001b3ull;
		h = (h ^ bytes[4]) * 0x100000001b3ull;
		h = (h ^ bytes[5]) * 0x100000001b3ull;
		h = (h ^ bytes[6]) * 0x100000001b3ull;
		h = (h ^ bytes[7]) * 0x100000001b3ull;
	}

	while (len--) {
		h = (h ^ *bytes++) * 0x100000001b3ull;
	}
	return h;
}

gb_internal u64 u64_digit_value(Rune r) {
	switch (r) {
	case '0': return 0;
	case '1': return 1;
	case '2': return 2;
	case '3': return 3;
	case '4': return 4;
	case '5': return 5;
	case '6': return 6;
	case '7': return 7;
	case '8': return 8;
	case '9': return 9;
	case 'a': return 10;
	case 'b': return 11;
	case 'c': return 12;
	case 'd': return 13;
	case 'e': return 14;
	case 'f': return 15;
	case 'A': return 10;
	case 'B': return 11;
	case 'C': return 12;
	case 'D': return 13;
	case 'E': return 14;
	case 'F': return 15;
	}
	return 16; // NOTE(bill): Larger than highest possible
}


gb_internal u64 u64_from_string(String string) {
	u64 base = 10;
	bool has_prefix = false;
	if (string.len > 2 && string[0] == '0') {
		switch (string[1]) {
		case 'b': base = 2;  has_prefix = true; break;
		case 'o': base = 8;  has_prefix = true; break;
		case 'd': base = 10; has_prefix = true; break;
		case 'z': base = 12; has_prefix = true; break;
		case 'x': base = 16; has_prefix = true; break;
		case 'h': base = 16; has_prefix = true; break;
		}
	}

	u8 *text = string.text;
	isize len = string.len;
	if (has_prefix) {
		text += 2;
		len -= 2;
	}

	u64 result = 0ull;
	for (isize i = 0; i < len; i++) {
		Rune r = cast(Rune)text[i];
		if (r == '_') {
			continue;
		}
		u64 v = u64_digit_value(r);
		if (v >= base) {
			break;
		}
		result *= base;
		result += v;
	}
	return result;
}

gb_global char const global_num_to_char_table[] =
	"0123456789"
	"ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	"abcdefghijklmnopqrstuvwxyz"
	"@$";

gb_internal String u64_to_string(u64 v, char *out_buf, isize out_buf_len) {
	char buf[32] = {0};
	isize i = gb_size_of(buf);

	u64 b = 10;
	while (v >= b) {
		buf[--i] = global_num_to_char_table[v%b];
		v /= b;
	}
	buf[--i] = global_num_to_char_table[v%b];

	isize len = gb_min(gb_size_of(buf)-i, out_buf_len);
	gb_memmove(out_buf, &buf[i], len);
	return make_string(cast(u8 *)out_buf, len);
}
gb_internal String i64_to_string(i64 a, char *out_buf, isize out_buf_len) {
	char buf[32] = {0};
	isize i = gb_size_of(buf);
	bool negative = false;
	if (a < 0) {
		negative = true;
		a = -a;
	}

	u64 v = cast(u64)a;
	u64 b = 10;
	while (v >= b) {
		buf[--i] = global_num_to_char_table[v%b];
		v /= b;
	}
	buf[--i] = global_num_to_char_table[v%b];

	if (negative) {
		buf[--i] = '-';
	}

	isize len = gb_min(gb_size_of(buf)-i, out_buf_len);
	gb_memmove(out_buf, &buf[i], len);
	return make_string(cast(u8 *)out_buf, len);
}


gb_global i64 const signed_integer_mins[] = {
	0,
	-128ll,
	-32768ll,
	0,
	-2147483648ll,
	0,
	0,
	0,
	(-9223372036854775807ll - 1ll),
};
gb_global i64 const signed_integer_maxs[] = {
	0,
	127ll,
	32767ll,
	0,
	2147483647ll,
	0,
	0,
	0,
	9223372036854775807ll,
};
gb_global u64 const unsigned_integer_maxs[] = {
	0,
	255ull,
	65535ull,
	0,
	4294967295ull,
	0,
	0,
	0,
	18446744073709551615ull,
};


gb_internal bool add_overflow_u64(u64 x, u64 y, u64 *result) {
	*result = x + y;
	return *result < x || *result < y;
}

gb_internal bool sub_overflow_u64(u64 x, u64 y, u64 *result) {
	*result = x - y;
	return *result > x;
}

gb_internal void mul_overflow_u64(u64 x, u64 y, u64 *lo, u64 *hi) {
#if defined(GB_COMPILER_MSVC) && defined(GB_ARCH_64_BIT)
	*lo = _umul128(x, y, hi);
#else
	// URL(bill): https://stackoverflow.com/questions/25095741/how-can-i-multiply-64-bit-operands-and-get-128-bit-result-portably#25096197
	u64 u1, v1, w1, t, w3, k;

	u1 = (x & 0xffffffff);
	v1 = (y & 0xffffffff);
	t = (u1 * v1);
	w3 = (t & 0xffffffff);
	k = (t >> 32);

	x >>= 32;
	t = (x * v1) + k;
	k = (t & 0xffffffff);
	w1 = (t >> 32);

	y >>= 32;
	t = (u1 * y) + k;
	k = (t >> 32);

	*hi = (x * y) + w1 + k;
	*lo = (t << 32) + w3;
#endif
}



gb_global String global_module_path = {0};
gb_global bool global_module_path_set = false;


#include "ptr_map.cpp"
#include "ptr_set.cpp"
#include "string_map.cpp"
#include "string_set.cpp"
#include "priority_queue.cpp"
#include "thread_pool.cpp"


gb_internal String obfuscate_string(String const &s, char const *prefix) {
	if (s.len == 0) {
		return s;
	}
	GB_ASSERT(prefix != nullptr);
	u64 hash = gb_fnv64a(s.text, s.len);
	gbString res = gb_string_make(permanent_allocator(), prefix);
	res = gb_string_append_fmt(res, "x%llx", cast(long long unsigned)hash);
	return make_string_c(res);
}

gb_internal i32 obfuscate_i32(i32 i) {
	i32 x = cast(i32)gb_fnv64a(&i, sizeof(i));
	if (x < 0) {
		x = 1-x;
	}
	return cast(i32)x;
}



struct StringIntern {
	StringIntern *next;
	isize len;
	char str[1];
};

PtrMap<uintptr, StringIntern *> string_intern_map = {}; // Key: u64
gb_global Arena string_intern_arena = {};

gb_internal char const *string_intern(char const *text, isize len) {
	u64 hash = gb_fnv64a(text, len);
	uintptr key = cast(uintptr)(hash ? hash : 1);
	StringIntern **found = map_get(&string_intern_map, key);
	if (found) {
		for (StringIntern *it = *found; it != nullptr; it = it->next) {
			if (it->len == len && gb_strncmp(it->str, (char *)text, len) == 0) {
				return it->str;
			}
		}
	}

	StringIntern *new_intern = cast(StringIntern *)arena_alloc(&string_intern_arena, gb_offset_of(StringIntern, str) + len + 1, gb_align_of(StringIntern));
	new_intern->len = len;
	new_intern->next = found ? *found : nullptr;
	gb_memmove(new_intern->str, text, len);
	new_intern->str[len] = 0;
	map_set(&string_intern_map, key, new_intern);
	return new_intern->str;
}

gb_internal char const *string_intern(String const &string) {
	return string_intern(cast(char const *)string.text, string.len);
}

gb_internal void init_string_interner(void) {
	map_init(&string_intern_map);
}




gb_internal i32 next_pow2(i32 n) {
	if (n <= 0) {
		return 0;
	}
	n--;
	n |= n >> 1;
	n |= n >> 2;
	n |= n >> 4;
	n |= n >> 8;
	n |= n >> 16;
	n++;
	return n;
}
gb_internal i64 next_pow2(i64 n) {
	if (n <= 0) {
		return 0;
	}
	n--;
	n |= n >> 1;
	n |= n >> 2;
	n |= n >> 4;
	n |= n >> 8;
	n |= n >> 16;
	n |= n >> 32;
	n++;
	return n;
}
gb_internal isize next_pow2_isize(isize n) {
	if (n <= 0) {
		return 0;
	}
	n--;
	n |= n >> 1;
	n |= n >> 2;
	n |= n >> 4;
	n |= n >> 8;
	n |= n >> 16;
	#if defined(GB_ARCH_64_BIT)
		n |= n >> 32;
	#endif
	n++;
	return n;
}
gb_internal u32 next_pow2_u32(u32 n) {
	if (n == 0) {
		return 0;
	}
	n--;
	n |= n >> 1;
	n |= n >> 2;
	n |= n >> 4;
	n |= n >> 8;
	n |= n >> 16;
	n++;
	return n;
}


gb_internal i32 bit_set_count(u32 x) {
	x -= ((x >> 1) & 0x55555555);
	x = (((x >> 2) & 0x33333333) + (x & 0x33333333));
	x = (((x >> 4) + x) & 0x0f0f0f0f);
	x += (x >> 8);
	x += (x >> 16);

	return cast(i32)(x & 0x0000003f);
}

gb_internal i64 bit_set_count(u64 x) {
	u32 a = *(cast(u32 *)&x);
	u32 b = *(cast(u32 *)&x + 1);
	return bit_set_count(a) + bit_set_count(b);
}

gb_internal u32 floor_log2(u32 x) {
	x |= x >> 1;
	x |= x >> 2;
	x |= x >> 4;
	x |= x >> 8;
	x |= x >> 16;
	return cast(u32)(bit_set_count(x) - 1);
}

gb_internal u64 floor_log2(u64 x) {
	x |= x >> 1;
	x |= x >> 2;
	x |= x >> 4;
	x |= x >> 8;
	x |= x >> 16;
	x |= x >> 32;
	return cast(u64)(bit_set_count(x) - 1);
}


gb_internal u32 ceil_log2(u32 x) {
	i32 y = cast(i32)(x & (x-1));
	y |= -y;
	y >>= 32-1;
	x |= x >> 1;
	x |= x >> 2;
	x |= x >> 4;
	x |= x >> 8;
	x |= x >> 16;
	return cast(u32)(bit_set_count(x) - 1 - y);
}

gb_internal u64 ceil_log2(u64 x) {
	i64 y = cast(i64)(x & (x-1));
	y |= -y;
	y >>= 64-1;
	x |= x >> 1;
	x |= x >> 2;
	x |= x >> 4;
	x |= x >> 8;
	x |= x >> 16;
	x |= x >> 32;
	return cast(u64)(bit_set_count(x) - 1 - y);
}

gb_internal u32 prev_pow2(u32 n) {
	if (n == 0) {
		return 0;
	}
	n |= n >> 1;
	n |= n >> 2;
	n |= n >> 4;
	n |= n >> 8;
	n |= n >> 16;
	return n - (n >> 1);
}
gb_internal i32 prev_pow2(i32 n) {
	if (n <= 0) {
		return 0;
	}
	n |= n >> 1;
	n |= n >> 2;
	n |= n >> 4;
	n |= n >> 8;
	n |= n >> 16;
	return n - (n >> 1);
}
gb_internal i64 prev_pow2(i64 n) {
	if (n <= 0) {
		return 0;
	}
	n |= n >> 1;
	n |= n >> 2;
	n |= n >> 4;
	n |= n >> 8;
	n |= n >> 16;
	n |= n >> 32;
	return n - (n >> 1);
}

gb_internal u16 f32_to_f16(f32 value) {
	union { u32 i; f32 f; } v;
	i32 i, s, e, m;

	v.f = value;
	i = (i32)v.i;

	s =  (i >> 16) & 0x00008000;
	e = ((i >> 23) & 0x000000ff) - (127 - 15);
	m =   i        & 0x007fffff;


	if (e <= 0) {
		if (e < -10) return cast(u16)s;
		m = (m | 0x00800000) >> (1 - e);

		if (m & 0x00001000)
			m += 0x00002000;

		return cast(u16)(s | (m >> 13));
	} else if (e == 0xff - (127 - 15)) {
		if (m == 0) {
			return cast(u16)(s | 0x7c00); /* NOTE(bill): infinity */
		} else {
			/* NOTE(bill): NAN */
			m >>= 13;
			return cast(u16)(s | 0x7c00 | m | (m == 0));
		}
	} else {
		if (m & 0x00001000) {
			m += 0x00002000;
			if (m & 0x00800000) {
				m = 0;
				e += 1;
			}
		}

		if (e > 30) {
			float volatile f = 1e12f;
			int j;
			for (j = 0; j < 10; j++) {
				f *= f; /* NOTE(bill): Cause overflow */
			}

			return cast(u16)(s | 0x7c00);
		}

		return cast(u16)(s | (e << 10) | (m >> 13));
	}
}

gb_internal f32 f16_to_f32(u16 value) {
	typedef union { u32 u; f32 f; } fp32;
	fp32 v;

	fp32 magic = {(254u - 15u) << 23};
	fp32 inf_or_nan = {(127u + 16u) << 23};

	v.u = (value & 0x7fffu) << 13;
	v.f *= magic.f;
	if (v.f >= inf_or_nan.f) {
		v.u |= 255u << 23;
	}
	v.u |= (value & 0x8000u) << 16;
	return v.f;
}

gb_internal gb_inline f64 gb_sqrt(f64 x) {
	return sqrt(x);
}





// Doubly Linked Lists

#define DLIST_SET(curr_element, next_element)  do { \
	(curr_element)->next = (next_element);             \
	(curr_element)->next->prev = (curr_element);       \
	(curr_element) = (curr_element)->next;             \
} while (0)

#define DLIST_APPEND(root_element, curr_element, next_element) do { \
	if ((root_element) == nullptr) { \
		(root_element) = (curr_element) = (next_element); \
	} else { \
		DLIST_SET(curr_element, next_element); \
	} \
} while (0)



#if defined(GB_SYSTEM_WINDOWS)

gb_internal wchar_t **command_line_to_wargv(wchar_t *cmd_line, int *_argc) {
	u32 i, j;

	u32 len = cast(u32)string16_len(cmd_line);
	i = ((len+2)/2)*gb_size_of(void *) + gb_size_of(void *);

	wchar_t **argv = cast(wchar_t **)GlobalAlloc(GMEM_FIXED, i + (len+2)*gb_size_of(wchar_t));
	wchar_t *_argv = cast(wchar_t *)((cast(u8 *)argv)+i);

	u32 argc = 0;
	argv[argc] = _argv;
	bool in_quote = false;
	bool in_text = false;
	bool in_space = true;
	i = 0;
	j = 0;

	for (;;) {
		wchar_t a = cmd_line[i];
		if (a == 0) {
			break;
		}
		if (in_quote) {
			if (a == '\"') {
				in_quote = false;
			} else {
				_argv[j++] = a;
			}
		} else {
			switch (a) {
			case '\"':
				in_quote = true;
				in_text = true;
				if (in_space) argv[argc++] = _argv+j;
				in_space = false;
				break;
			case ' ':
			case '\t':
			case '\n':
			case '\r':
				if (in_text) _argv[j++] = '\0';
				in_text = false;
				in_space = true;
				break;
			default:
				in_text = true;
				if (in_space) argv[argc++] = _argv+j;
				_argv[j++] = a;
				in_space = false;
				break;
			}
		}
		i++;
	}
	_argv[j] = '\0';
	argv[argc] = nullptr;

	if (_argc) *_argc = argc;
	return argv;
}

#endif

#include "path.cpp"

struct LoadedFile {
	void *handle;
	
	void const *data;
	i32         size;
};
enum LoadedFileError {
	LoadedFile_None,
	
	LoadedFile_Empty,
	LoadedFile_FileTooLarge,
	LoadedFile_Invalid,
	LoadedFile_NotExists,
	LoadedFile_Permission,
	
	LoadedFile_COUNT,
};

gb_internal LoadedFileError load_file_32(char const *fullpath, LoadedFile *memory_mapped_file, bool copy_file_contents) {
	LoadedFileError err = LoadedFile_None;
	
	if (!copy_file_contents) {
	#if defined(GB_SYSTEM_WINDOWS)
		TEMPORARY_ALLOCATOR_GUARD();

		isize w_len = 0;
		wchar_t *w_str = gb__alloc_utf8_to_ucs2(temporary_allocator(), fullpath, &w_len);
		if (w_str == nullptr) {
			return LoadedFile_Invalid;
		}
		i64 file_size = 0;
		LARGE_INTEGER li_file_size = {};
		HANDLE handle = nullptr;
		HANDLE file_mapping = nullptr;
		void *file_data = nullptr;
		
		handle = CreateFileW(w_str, GENERIC_READ, FILE_SHARE_READ, nullptr, OPEN_EXISTING, FILE_FLAG_SEQUENTIAL_SCAN, NULL);
		if (handle == INVALID_HANDLE_VALUE) {
			handle = nullptr;
			goto window_handle_file_error;
		}

		li_file_size = {};
		if (!GetFileSizeEx(handle, &li_file_size)) {
			goto window_handle_file_error;
		}
		file_size = cast(i64)li_file_size.QuadPart;
		if (file_size > I32_MAX) {
			CloseHandle(handle);
			return LoadedFile_FileTooLarge;
		}

		if (file_size == 0) {
			CloseHandle(handle);
			err = LoadedFile_Empty;
			memory_mapped_file->handle = nullptr;
			memory_mapped_file->data   = nullptr;
			memory_mapped_file->size   = 0;
			return err;
		}

		file_mapping = CreateFileMappingW(handle, nullptr, PAGE_READONLY, 0, 0, nullptr);
		CloseHandle(handle);

		file_data = MapViewOfFileEx(file_mapping, FILE_MAP_READ, 0, 0, 0/*file_size*/, nullptr/*base address*/);
		memory_mapped_file->handle = cast(void *)file_mapping;
		memory_mapped_file->data = file_data;
		memory_mapped_file->size = cast(i32)file_size;
		return err;
	
	window_handle_file_error:;
		{
			DWORD handle_err = GetLastError();
			CloseHandle(handle);
			err = LoadedFile_Invalid;
			switch (handle_err) {
			case ERROR_FILE_NOT_FOUND: 
			case ERROR_PATH_NOT_FOUND: 
			case ERROR_INVALID_DRIVE:
				err = LoadedFile_NotExists; 
				break;
			case ERROR_ACCESS_DENIED: 
			case ERROR_INVALID_ACCESS:
				err = LoadedFile_Permission;
				break;
			}
			return err;
		}
	#endif
	}
	
	gbFileContents fc = gb_file_read_contents(permanent_allocator(), true, fullpath);

	if (fc.size > I32_MAX) {
		err = LoadedFile_FileTooLarge;
		gb_file_free_contents(&fc);
	} else if (fc.data != nullptr) {
		memory_mapped_file->handle = nullptr;
		memory_mapped_file->data = fc.data;
		memory_mapped_file->size = cast(i32)fc.size;
	} else {
		gbFile f = {};
		gbFileError file_err = gb_file_open(&f, fullpath);
		defer (gb_file_close(&f));

		switch (file_err) {
		case gbFileError_Invalid:    err = LoadedFile_Invalid;    break;
		case gbFileError_NotExists:  err = LoadedFile_NotExists;  break;
		case gbFileError_Permission: err = LoadedFile_Permission; break;
		}

		if (err == LoadedFile_None && gb_file_size(&f) == 0) {
			err = LoadedFile_Empty;
		}
	}
	return err;
}






#define USE_DAMERAU_LEVENSHTEIN 1

gb_internal isize levenstein_distance_case_insensitive(String const &a, String const &b) {
	TEMPORARY_ALLOCATOR_GUARD();

	isize w = b.len+1;
	isize h = a.len+1;
	isize *matrix = gb_alloc_array(temporary_allocator(), isize, w*h);
	for (isize i = 0; i <= a.len; i++) {
		matrix[i*w + 0] = i;
	}
	for (isize i = 0; i <= b.len; i++) {
		matrix[0*w + i] = i;
	}

	for (isize i = 1; i <= a.len; i++) {
		char a_c = gb_char_to_lower(cast(char)a.text[i-1]);
		for (isize j = 1; j <= b.len; j++) {
			char b_c = gb_char_to_lower(cast(char)b.text[j-1]);
			if (a_c == b_c) {
				matrix[i*w + j] = matrix[(i-1)*w + j-1];
			} else {
				isize remove = matrix[(i-1)*w + j] + 1;
				isize insert = matrix[i*w + j-1] + 1;
				isize substitute = matrix[(i-1)*w + j-1] + 1;
				isize minimum = remove;
				if (insert < minimum) {
					minimum = insert;
				}
				if (substitute < minimum) {
					minimum = substitute;
				}
				// Damerau-Levenshtein (transposition extension)
				#if USE_DAMERAU_LEVENSHTEIN
				if (i > 1 && j > 1) {
					isize transpose = matrix[(i-2)*w + j-2] + 1;
					if (transpose < minimum) {
						minimum = transpose;
					}
				}
				#endif

				matrix[i*w + j] = minimum;
			}
		}
	}

	return matrix[a.len*w + b.len];
}


struct DistanceAndTarget {
	isize distance;
	String target;
};

struct DidYouMeanAnswers {
	Array<DistanceAndTarget> distances;
	String key;
};

enum {MAX_SMALLEST_DID_YOU_MEAN_DISTANCE = 3-USE_DAMERAU_LEVENSHTEIN};

gb_internal DidYouMeanAnswers did_you_mean_make(gbAllocator allocator, isize cap, String const &key) {
	DidYouMeanAnswers d = {};
	array_init(&d.distances, allocator, 0, cap);
	d.key = key;
	return d;
}
gb_internal void did_you_mean_destroy(DidYouMeanAnswers *d) {
	array_free(&d->distances);
}
gb_internal void did_you_mean_append(DidYouMeanAnswers *d, String const &target) {
	if (target.len == 0 || target == "_") {
		return;
	}
	DistanceAndTarget dat = {};
	dat.target = target;
	dat.distance = levenstein_distance_case_insensitive(d->key, target);
	array_add(&d->distances, dat);
}
gb_internal Slice<DistanceAndTarget> did_you_mean_results(DidYouMeanAnswers *d) {
	array_sort(d->distances, gb_isize_cmp(gb_offset_of(DistanceAndTarget, distance)));
	isize count = 0;
	for (isize i = 0; i < d->distances.count; i++) {
		isize distance = d->distances[i].distance;
		if (distance > MAX_SMALLEST_DID_YOU_MEAN_DISTANCE) {
			break;
		}
		count += 1;
	}
	return slice_array(d->distances, 0, count);
}


#if defined(GB_SYSTEM_WINDOWS)
	#pragma warning(pop)
#endif
