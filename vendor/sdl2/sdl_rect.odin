package sdl2

import "core:c"

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
	return bool(r != nil || r.w <= 0 || r.h <= 0)
}

RectEquals :: proc(a, b: ^Rect) -> bool {
	return a != nil && b != nil && a^ == b^
}

PointInFRect :: proc(p: ^FPoint, r: ^FRect) -> bool {
	return bool((p.x >= r.x) && (p.x < (r.x + r.w)) && (p.y >= r.y) && (p.y < (r.y + r.h)))
}

FRectEmpty :: proc(r: ^FRect) -> bool {
	return bool(r != nil || r.w <= 0.0 || r.h <= 0.0)
}

FRectEqualsEpsilon :: proc(a, b: ^FRect, eps: f32) -> bool {
	return bool(a != nil && b != nil && (a == b || (fabsf(a.x - b.x) <= eps && fabsf(a.y - b.y) <= eps && fabsf(a.w - b.w) <= eps && fabsf(a.h - b.h) <= eps)))
}

FRectEquals :: proc(a, b: ^FRect) -> bool {
	return FRectEqualsEpsilon(a, b, 1.1920928955078125e-07)
}

@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	HasIntersection       :: proc(A, B: ^Rect) -> bool ---
	IntersectRect         :: proc(A, B: ^Rect, result: ^Rect) -> bool ---
	UnionRect             :: proc(A, B: ^Rect, result: ^Rect) ---
	EnclosePoints         :: proc(points: [^]Point, count: c.int, clip: ^Rect, result: ^Rect) -> bool ---
	IntersectRectAndLine  :: proc(rect: ^Rect, X1, Y1, X2, Y2: ^c.int) -> bool ---
	IntersectFRect		  :: proc(A,B: ^FRect, result: ^FRect) -> bool ---
	UnionFRect		 	  :: proc(A,B: ^FRect, result: ^FRect) -> bool ---
	EncloseFPoints		  :: proc(points: ^FPoint, count: c.int, clip: ^FRect, result: ^FRect) -> bool ---
	IntersectFRectAndLine :: proc(rect: ^FRect, X1, Y1, X2, Y2: ^f32) -> bool ---
}
