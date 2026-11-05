package main

import "base:intrinsics"

shared_value: u32 = 41
initialized_value: u32 = 73

@(export, link_name = "fixture_shared_value_ptr")
shared_value_ptr :: proc "contextless" () -> ^u32 {
	return &shared_value
}

@(export, link_name = "fixture_initialized_value_ptr")
initialized_value_ptr :: proc "contextless" () -> ^u32 {
	return &initialized_value
}

@(export, link_name = "fixture_increment")
fixture_increment :: proc "contextless" () -> u32 {
	return intrinsics.atomic_add_explicit(&shared_value, 1, .Seq_Cst) + 1
}

@(export, link_name = "fixture_dispatch")
fixture_dispatch :: proc "contextless" (callback_pointer, context_pointer: rawptr) {
	callback := transmute(proc "c" (_: rawptr))callback_pointer
	callback(context_pointer)
}

fixture_callback :: proc "c" (context_pointer: rawptr) {
	value := (^u32)(context_pointer)
	_ = intrinsics.atomic_add_explicit(value, 1, .Seq_Cst)
}

@(export, link_name = "fixture_callback_pointer")
fixture_callback_pointer :: proc "contextless" () -> rawptr {
	return rawptr(fixture_callback)
}

main :: proc() {}
