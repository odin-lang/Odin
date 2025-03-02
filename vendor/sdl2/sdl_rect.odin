package sdl2

import "core:c"

when ODIN_OS == .Windows {
	@(ignore_duplicates)
	foreign import lib "SDL2.lib"
} else {
	@(ignore_duplicates)
	foreign import lib "system:SDL2"
}

Point :: struct {
	x: c.int,
	y: c.int,
}

FPoint :: struct {
	x: f32,
	y: f32,
}


Rect :: struct {
	x, y: c.int,
	w, h: c.int,
}

FRect :: struct {
	x, y: f32,
	w, h: f32,
}

PointInRect :: proc(p: ^Point, r: ^Rect) -> bool {
	return bool((p.x >= r.x) && (p.x < (r.x + r.w)) && (p.y >= r.y) && (p.y < (r.y + r.h)))
}

RectEmpty :: proc(r: ^Rect) -> bool {
	return bool(r == nil|| r.w <= 0 || r.h <= 0)
}

RectEquals :: proc(a, b: ^Rect) -> bool {
	return a != nil && b != nil && a^ == b^
}

@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	HasIntersection      :: proc(A, B: ^Rect) -> bool ---
	IntersectRect        :: proc(A, B: ^Rect, result: ^Rect) -> bool ---
	UnionRect            :: proc(A, B: ^Rect, result: ^Rect) ---
	EnclosePoints        :: proc(points: [^]Point, count: c.int, clip: ^Rect, result: ^Rect) -> bool ---
	IntersectRectAndLine :: proc(rect: ^Rect, X1, Y1, X2, Y2: ^c.int) -> bool ---
}
