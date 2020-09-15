package runtime

import "core:sys/es"

@(link_name="memset")
memset :: proc "c" (ptr: rawptr, val: i32, len: int) -> rawptr {
	return es.CRTmemset(ptr, val, len);
}

@(link_name="memmove")
memmove :: proc "c" (dst, src: rawptr, len: int) -> rawptr {
	return es.CRTmemmove(dst, src, len);
}

@(link_name="memcpy")
memcpy :: proc "c" (dst, src: rawptr, len: int) -> rawptr {
	return es.CRTmemcpy(dst, src, len);
}
