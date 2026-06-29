package sdl3_ttf

import "core:c"
import SDL "vendor:sdl3"

DrawCommand :: enum c.int {
	NOOP,
	FILL,
	COPY,
}

FillOperation :: struct {
	cmd:  DrawCommand,
	rect: SDL.Rect,
}

CopyOperation :: struct {
	cmd:         DrawCommand,
	text_offset: c.int,
	glyph_font:  ^Font,
	glyph_index: u32,
	src:         SDL.Rect,
	dst:         SDL.Rect,
	reserved:    rawptr,
}

DrawOperation :: struct #raw_union {
	cmd:  DrawCommand,
	fill: FillOperation,
	copy: CopyOperation,
}

TextLayout :: struct {}

TextData :: struct {
	font:                ^Font,
	color:               SDL.FColor,
	needs_layout_update: bool,
	layout:              ^TextLayout,
	x, y:                c.int,
	w, h:                c.int,
	num_ops:             c.int,
	ops:                 [^]DrawOperation `fmt:"v,num_ops"`,
	num_clusters:        c.int,
	clusters:            [^]SubString     `fmt:"v,num_clusters"`,
	props:               SDL.PropertiesID,
	needs_engine_update: bool,
	engine:              ^TextEngine,
	engine_text:         rawptr,
}

TextEngine :: struct {
	version:     u32,
	userdata:    rawptr,
	CreateText:  proc "c" (userdata: rawptr, text: ^Text) -> bool,
	DestroyText: proc "c" (userdata: rawptr, Textext: ^Text),
}

#assert(
	(size_of(TextEngine) == 16 && size_of(rawptr) == 4) ||
	(size_of(TextEngine) == 32 && size_of(rawptr) == 8),
)
