package orca

import "core:c"
import ilist "core:container/intrusive/list"

@(default_calling_convention="c", link_prefix="oc_")
foreign {
	str8_push_buffer  :: proc(arena: ^arena, len: u64, buffer: rawptr) -> str8 ---
	str8_push_cstring :: proc(arena: ^arena, str: cstring) -> str8 ---
	str8_push_copy    :: proc(arena: ^arena, s: string) -> str8 ---
	str8_to_cstring   :: proc(arena: ^arena, s: str8) -> cstring ---
}


// string lists
//----------------------------------------------------------------------------------
str8_elt :: struct {
	listElt: list_elt,
	string:  str8,
}

str8_list :: struct {
	list: list,
	eltCount: u64,
	len:      u64,
}

@(default_calling_convention="c", link_prefix="oc_")
foreign {
	str8_list_push :: proc(arena: ^arena, list: ^str8_list, str: string) ---

	str8_list_collate :: proc(arena: ^arena, list: str8_list, prefix, separator, postfix: string) -> str8 ---
	str8_list_join    :: proc(arena: ^arena, list: str8_list) -> str8 ---
	str8_split        :: proc(arena: ^arena, str:  string, separators: str8_list) -> str8_list ---

	win32_utf8_to_wide                  :: proc(arena: ^arena, s: str8) -> str16 ---
	win32_wide_to_utf8                  :: proc(arena: ^arena, s: str16) -> str8 ---
	win32_path_normalize_slash_in_place :: proc(path: []byte) ---
}

