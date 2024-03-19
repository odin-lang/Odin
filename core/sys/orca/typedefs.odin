package orca

import "core:c"

vec2 :: [2]f32
vec3 :: [3]f32
vec4 :: [4]f32
vec2i :: [2]i32
// mat2x3 :: [6]f32
mat2x3 :: matrix[2, 3]f32
rect :: [4]f32

//------------------------------------------------------------------------------------------
// window
//------------------------------------------------------------------------------------------
@(default_calling_convention="c", link_prefix="oc_", link_suffix="_argptr_stub")
foreign {
	window_set_title :: proc(title: str8) ---
	window_set_size :: proc(size: vec2) ---
	request_quit :: proc() ---
}

clock_kind :: enum c.int {
	MONOTONIC,
	UPTIME,
	DATE,
}

@(default_calling_convention="c", link_prefix="oc_")
foreign {
	clock_time :: proc(clock: clock_kind) -> f64 ---
}
