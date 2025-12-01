package vendor_curl

import c "core:c/libc"

easytype :: enum c.int {
	OT_LONG,     /* long (a range of values) */
	OT_VALUES,   /*      (a defined set or bitmask) */
	OT_OFF_T,    /* curl_off_t (a range of values) */
	OT_OBJECT,   /* pointer (void *) */
	OT_STRING,   /*         (char * to null-terminated buffer) */
	OT_SLIST,    /*         (struct curl_slist *) */
	OT_CBPTR,    /*         (void * passed as-is to a callback) */
	OT_BLOB,     /* blob (struct curl_blob *) */
	OT_FUNCTION, /* function pointer */
}


easyoptionflags :: distinct bit_set[easyoptionflag; c.uint]
easyoptionflag :: enum c.uint {
	/* "alias" means it is provided for old programs to remain functional, we prefer another name */
	ALIAS = 0,
}

/*
		The CURLOPTTYPE_* id ranges can still be used to figure out what type/size
		to use for curl_easy_setopt() for the given id
	*/
easyoption :: struct {
	name:  cstring,
	id:    option,
	type:  easytype,
	flags: easyoptionflags,
}


@(default_calling_convention="c", link_prefix="curl_")
foreign lib {
	easy_option_by_name :: proc(name: cstring) -> ^easyoption ---
	easy_option_by_id   :: proc(id: option) -> ^easyoption ---
	easy_option_next    :: proc(prev: ^easyoption) -> ^easyoption ---
}