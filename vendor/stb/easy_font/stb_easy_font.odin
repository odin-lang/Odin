/*
An Odin-native source port of [[ stb_easy_font.h ; https://github.com/nothings/stb/blob/master/stb_easy_font.h ]].

Example:
	quads: [999]easy_font.Quad = ---

	color := rl.GREEN
	c     := transmute(easy_font.Color)color
	num_quads := easy_font.print(10, 60, TEXT, c, quads[:])

	for q in quads[:num_quads] {
		tl    := q.tl.v
		br    := q.br.v
		color  = transmute(rl.Color)q.tl.c

		r := rl.Rectangle{x = tl.x, y = tl.y, width = br.x - tl.x, height = br.y - tl.y}

		// Yes, we could just use the `color` from above, but this shows how to get it back from the vertex.
		// And in practice this code will likely not live as close to the `easy_font` call.
		rl.DrawRectangleRec(r, color)
	}


Changelog:
	2022-04-03
		Bug fixes
		Add `print(x, y, text, color, quad_buffer)` version that takes `[]quad`.
			(Same internal memory layout as []u8 API, but more convenient for the caller.)
		Add optional `scale := f32(1.0)` param to `print` to embiggen the glyph quads.

	2021-09-14
		Original Odin version

Credits:
	Original port: gingerBill
	Bugfixes:      Florian Behr & Jeroen van Rijn
	Additions:     Jeroen van Rijn
*/
package stb_easy_font

import "core:math"
import "core:mem"

Color  :: [4]u8

Vertex :: struct {
	v: [3]f32,
	c: Color,
}
#assert(size_of(Vertex) == 16)

Quad :: struct #packed {
	tl: Vertex,
	tr: Vertex,
	br: Vertex,
	bl: Vertex,
}
#assert(size_of(Quad) == 64)

// Same memory layout, but takes a []quad instead of []byte
draw_segs_quad_buffer :: proc(x, y: f32, segs: []u8, vertical: bool, c: Color, buf: []Quad, start_offset: int, scale := f32(1.0)) -> (quads: int) {
	x, y := x, y
	quads = start_offset

	for seg in segs {
		stroke_length := f32(seg & 7) * scale
		x += f32((seg >> 3) & 1) * scale
		if stroke_length != 0 && quads + 1 <= len(buf) {
			y0 := y + (f32(seg >> 4) * scale)

			horz := scale if vertical else stroke_length
			vert := stroke_length if vertical else scale

			buf[quads].tl.c = c
			buf[quads].tl.v = { x,        y0,        0 }

			buf[quads].tr.c = c
			buf[quads].tr.v = { x + horz, y0,        0 }

			buf[quads].br.c = c
			buf[quads].br.v = { x + horz, y0 + vert, 0 }

			buf[quads].bl.c = c
			buf[quads].bl.v = { x,        y0 + vert, 0 }

			quads += 1
		}
	}
	return quads
}

// Compatible with original C API
draw_segs_vertex_buffer :: proc(x, y: f32, segs: []u8, vertical: bool, c: Color, vbuf: []byte, start_offset: int, scale := f32(1.0)) -> (offset: int) {
	buf := mem.slice_data_cast([]Quad, vbuf)
	offset = draw_segs_quad_buffer(x, y, segs, vertical, c, buf, start_offset / size_of(Quad), scale) * size_of(Quad)
	return offset
}

draw_segs :: proc{ draw_segs_quad_buffer, draw_segs_vertex_buffer }

@(private)
_spacing_val := f32(0)

font_spacing :: proc(spacing: f32) {
	_spacing_val = spacing
}

// Same memory layout, but takes a []quad instead of []byte
print_quad_buffer :: proc(x, y: f32, text: string, color: Color, quad_buffer: []Quad, scale := f32(1.0)) -> (quads: int) {
	x, y, color := x, y, color
	text := text
	start_x := x

	if color == {} {
		color = {255, 255, 255, 255}
	}

	for len(text) != 0 && quads < len(quad_buffer) {
		c := text[0]
		if c == '\n' {
			y += 12
			x = start_x
		} else {
			advance := charinfo[c-32].advance
			y_ch := y+1 if advance & 16 != 0 else y
			h_seg := charinfo[c-32].h_seg
			v_seg := charinfo[c-32].v_seg
			num_h := charinfo[c-32 + 1].h_seg - h_seg
			num_v := charinfo[c-32 + 1].v_seg - v_seg

			quads = draw_segs(x, y_ch, hseg[h_seg:][:num_h], false, color, quad_buffer, quads, scale)
			quads = draw_segs(x, y_ch, vseg[v_seg:][:num_v], true,  color, quad_buffer, quads, scale)

			x += f32(advance & 15) * scale
			x += _spacing_val * scale
		}
		text = text[1:]
	}

	return
}

// Compatible with original C API
print_vertex_buffer :: proc(x, y: f32, text: string, color: Color, vertex_buffer: []byte, scale := f32(1.0)) -> int {
	buf := mem.slice_data_cast([]Quad, vertex_buffer)
	return print_quad_buffer(x, y, text, color, buf, scale)
}

print :: proc{ print_quad_buffer, print_vertex_buffer }

width :: proc(text: string) -> int {
	length := f32(0)
	max_length := f32(0)
	for i in 0..<len(text) {
		c := text[i]
		if c == '\n' {
			if length > max_length {
				max_length = length
			}
			length = 0
		} else {
			length += f32(charinfo[c-32].advance & 15)
			length += _spacing_val
		}
	}
	if length > max_length {
		max_length = length
	}
	return int(math.ceil(max_length))
}

height :: proc(text: string) -> int {
	y := f32(0)
	nonempty_line := false
	for i in 0..<len(text) {
		c := text[i]
		if c == '\n' {
			y += 12
			nonempty_line = false
		} else {
			nonempty_line = true
		}
	}
	return int(math.ceil(y + 12 if nonempty_line else 0))
}


info_struct :: struct{
	advance: u8,
	h_seg:   u8,
	v_seg:   u8,
}


@(private)
charinfo := [96]info_struct{
	{  6,  0,  0 },  {  3,  0,  0 },  {  5,  1,  1 },  {  7,  1,  4 },
	{  7,  3,  7 },  {  7,  6, 12 },  {  7,  8, 19 },  {  4, 16, 21 },
	{  4, 17, 22 },  {  4, 19, 23 },  { 23, 21, 24 },  { 23, 22, 31 },
	{ 20, 23, 34 },  { 22, 23, 36 },  { 19, 24, 36 },  { 21, 25, 36 },
	{  6, 25, 39 },  {  6, 27, 43 },  {  6, 28, 45 },  {  6, 30, 49 },
	{  6, 33, 53 },  {  6, 34, 57 },  {  6, 40, 58 },  {  6, 46, 59 },
	{  6, 47, 62 },  {  6, 55, 64 },  { 19, 57, 68 },  { 20, 59, 68 },
	{ 21, 61, 69 },  { 22, 66, 69 },  { 21, 68, 69 },  {  7, 73, 69 },
	{  9, 75, 74 },  {  6, 78, 81 },  {  6, 80, 85 },  {  6, 83, 90 },
	{  6, 85, 91 },  {  6, 87, 95 },  {  6, 90, 96 },  {  7, 92, 97 },
	{  6, 96,102 },  {  5, 97,106 },  {  6, 99,107 },  {  6,100,110 },
	{  6,100,115 },  {  7,101,116 },  {  6,101,121 },  {  6,101,125 },
	{  6,102,129 },  {  7,103,133 },  {  6,104,140 },  {  6,105,145 },
	{  7,107,149 },  {  6,108,151 },  {  7,109,155 },  {  7,109,160 },
	{  7,109,165 },  {  7,118,167 },  {  6,118,172 },  {  4,120,176 },
	{  6,122,177 },  {  4,122,181 },  { 23,124,182 },  { 22,129,182 },
	{  4,130,182 },  { 22,131,183 },  {  6,133,187 },  { 22,135,191 },
	{  6,137,192 },  { 22,139,196 },  {  6,144,197 },  { 22,147,198 },
	{  6,150,202 },  { 19,151,206 },  { 21,152,207 },  {  6,155,209 },
	{  3,160,210 },  { 23,160,211 },  { 22,164,216 },  { 22,165,220 },
	{ 22,167,224 },  { 22,169,228 },  { 21,171,232 },  { 21,173,233 },
	{  5,178,233 },  { 22,179,234 },  { 23,180,238 },  { 23,180,243 },
	{ 23,180,248 },  { 22,189,248 },  { 22,191,252 },  {  5,196,252 },
	{  3,203,252 },  {  5,203,253 },  { 22,210,253 },  {  0,214,253 },
}

@(private)
hseg := [214]u8{
	97,37,69,84,28,51,2,18,10,49,98,41,65,25,81,105,33,9,97,1,97,37,37,36,
	81,10,98,107,3,100,3,99,58,51,4,99,58,8,73,81,10,50,98,8,73,81,4,10,50,
	98,8,25,33,65,81,10,50,17,65,97,25,33,25,49,9,65,20,68,1,65,25,49,41,
	11,105,13,101,76,10,50,10,50,98,11,99,10,98,11,50,99,11,50,11,99,8,57,
	58,3,99,99,107,10,10,11,10,99,11,5,100,41,65,57,41,65,9,17,81,97,3,107,
	9,97,1,97,33,25,9,25,41,100,41,26,82,42,98,27,83,42,98,26,51,82,8,41,
	35,8,10,26,82,114,42,1,114,8,9,73,57,81,41,97,18,8,8,25,26,26,82,26,82,
	26,82,41,25,33,82,26,49,73,35,90,17,81,41,65,57,41,65,25,81,90,114,20,
	84,73,57,41,49,25,33,65,81,9,97,1,97,25,33,65,81,57,33,25,41,25,
}

@(private)
vseg := [253]u8{
	4,2,8,10,15,8,15,33,8,15,8,73,82,73,57,41,82,10,82,18,66,10,21,29,1,65,
	27,8,27,9,65,8,10,50,97,74,66,42,10,21,57,41,29,25,14,81,73,57,26,8,8,
	26,66,3,8,8,15,19,21,90,58,26,18,66,18,105,89,28,74,17,8,73,57,26,21,
	8,42,41,42,8,28,22,8,8,30,7,8,8,26,66,21,7,8,8,29,7,7,21,8,8,8,59,7,8,
	8,15,29,8,8,14,7,57,43,10,82,7,7,25,42,25,15,7,25,41,15,21,105,105,29,
	7,57,57,26,21,105,73,97,89,28,97,7,57,58,26,82,18,57,57,74,8,30,6,8,8,
	14,3,58,90,58,11,7,74,43,74,15,2,82,2,42,75,42,10,67,57,41,10,7,2,42,
	74,106,15,2,35,8,8,29,7,8,8,59,35,51,8,8,15,35,30,35,8,8,30,7,8,8,60,
	36,8,45,7,7,36,8,43,8,44,21,8,8,44,35,8,8,43,23,8,8,43,35,8,8,31,21,15,
	20,8,8,28,18,58,89,58,26,21,89,73,89,29,20,8,8,30,7,
}


/*
------------------------------------------------------------------------------
This software is available under 2 licenses -- choose whichever you prefer.
------------------------------------------------------------------------------
ALTERNATIVE A - MIT License
Copyright (c) 2017 Sean Barrett
Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
------------------------------------------------------------------------------
ALTERNATIVE B - Public Domain (www.unlicense.org)
This is free and unencumbered software released into the public domain.
Anyone is free to copy, modify, publish, use, compile, sell, or distribute this
software, either in source code form or as a compiled binary, for any purpose,
commercial or non-commercial, and by any means.
In jurisdictions that recognize copyright laws, the author or authors of this
software dedicate any and all copyright interest in the software to the public
domain. We make this dedication for the benefit of the public at large and to
the detriment of our heirs and successors. We intend this dedication to be an
overt act of relinquishment in perpetuity of all present and future rights to
this software under copyright law.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
------------------------------------------------------------------------------
*/