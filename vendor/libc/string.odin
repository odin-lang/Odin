package odin_libc

import "base:intrinsics"

import "core:c"
import "core:strings"
import "core:mem"

// NOTE: already defined by Odin.
// void *memcpy(void *, const void *, size_t);
// void *memset(void *, int, size_t);

@(require, linkage="strong", link_name="memcmp")
memcmp :: proc "c" (lhs: [^]byte, rhs: [^]byte, count: uint) -> i32 {
	icount := int(count)
	assert_contextless(icount >= 0)
	return i32(mem.compare(lhs[:icount], rhs[:icount]))
}

@(require, linkage="strong", link_name="strlen")
strlen :: proc "c" (str: cstring) -> c.ulong {
	return c.ulong(len(str))
}

@(require, linkage="strong", link_name="strchr")
strchr :: proc "c" (str: cstring, ch: i32) -> cstring {
	bch  := u8(ch)
	sstr := string(str)
	if bch == 0 {
		return cstring(raw_data(sstr)[len(sstr):])
	}

	idx := strings.index_byte(sstr, bch)
	if idx < 0 {
		return nil
	}

	return cstring(raw_data(sstr)[idx:])
}

@(require, linkage="strong", link_name="strrchr")
strrchr :: proc "c" (str: cstring, ch: i32) -> cstring {
	bch  := u8(ch)
	sstr := string(str)
	if bch == 0 {
		return cstring(raw_data(sstr)[len(sstr):])
	}

	idx := strings.last_index_byte(sstr, bch)
	if idx < 0 {
		return nil
	}

	return cstring(raw_data(sstr)[idx:])
}

@(require, linkage="strong", link_name="strncpy")
strncpy :: proc "c" (dst: [^]byte, src: cstring, count: uint) -> cstring {
	icount := int(count)
	assert_contextless(icount >= 0)
	cnt := min(len(src), icount)
	intrinsics.mem_copy_non_overlapping(dst, rawptr(src), cnt)
	intrinsics.mem_zero(dst, icount-cnt)
	return cstring(dst)
}

@(require, linkage="strong", link_name="strcpy")
strcpy :: proc "c" (dst: [^]byte, src: cstring) -> cstring {
	intrinsics.mem_copy_non_overlapping(dst, rawptr(src), len(src)+1)
	return cstring(dst)
}

@(require, linkage="strong", link_name="strcspn")
strcspn :: proc "c" (dst: cstring, src: cstring) -> uint {
	context = g_ctx
	sdst := string(dst)
	idx := strings.index_any(sdst, string(src))
	if idx == -1 {
		return len(sdst)
	}
	return uint(idx)
}

@(require, linkage="strong", link_name="strncmp")
strncmp :: proc "c" (lhs: cstring, rhs: cstring, count: uint) -> i32 {
	icount := int(count)
	assert_contextless(icount >= 0)
	lhss := strings.string_from_null_terminated_ptr(([^]byte)(lhs), icount)
	rhss := strings.string_from_null_terminated_ptr(([^]byte)(rhs), icount)
	return i32(strings.compare(lhss, rhss))
}

@(require, linkage="strong", link_name="strcmp")
strcmp :: proc "c" (lhs: cstring, rhs: cstring) -> i32 {
	return i32(strings.compare(string(lhs), string(rhs)))
}

@(require, linkage="strong", link_name="strstr")
strstr :: proc "c" (str: cstring, substr: cstring) -> cstring {
	if substr == "" {
		return str
	}

	idx := strings.index(string(str), string(substr))
	if idx < 0 {
		return nil
	}

	return cstring(([^]byte)(str)[idx:])
}

