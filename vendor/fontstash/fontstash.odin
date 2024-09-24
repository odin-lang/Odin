#+vet !using-param
package fontstash

import "base:runtime"

import "core:log"
import "core:mem"
import "core:math"
import "core:strings"
import "core:slice"

import stbtt "vendor:stb/truetype"

// This is a port from Fontstash into odin - specialized for nanovg

// Notable features of Fontstash:
// Contains a *single* channel texture atlas for multiple fonts
// Manages a lookup table for frequent glyphs
// Allows blurred font glyphs
// Atlas can resize

// Changes from the original:
// stb truetype only 
// no scratch allocation -> parts use odins dynamic arrays
// leaves GPU vertex creation & texture management up to the user
// texture atlas expands by default

INVALID          :: -1
MAX_STATES       :: 20
HASH_LUT_SIZE    :: 256
INIT_GLYPHS      :: 256
INIT_ATLAS_NODES :: 256
MAX_FALLBACKS    :: 20
Glyph_Index      :: i32 // in case you want to change the handle for glyph indices

AlignHorizontal :: enum {
	LEFT,
	CENTER,
	RIGHT,
}

AlignVertical :: enum {
	TOP,
	MIDDLE,
	BOTTOM,
	BASELINE,
}

Font :: struct {
	name: string, // allocated

	info:           stbtt.fontinfo,
	loadedData:     []byte,
	freeLoadedData: bool, // in case you dont want loadedData to be removed

	ascender:   f32,
	descender:  f32,
	lineHeight: f32,

	glyphs: [dynamic]Glyph,
	lut:    [HASH_LUT_SIZE]int,

	fallbacks:  [MAX_FALLBACKS]int,
	nfallbacks: int,
}

Glyph :: struct {
	codepoint:      rune,
	index:          Glyph_Index,
	next:           int,
	isize:          i16,
	blurSize:       i16,
	x0, y0, x1, y1: i16,
	xoff, yoff:     i16,
	xadvance:       i16,
}

AtlasNode :: struct {
	x, y, width: i16,
}

Vertex :: struct #packed {
	x, y:  f32,
	u, v:  f32,
	color: [4]u8,
}

QuadLocation :: enum {
	TOPLEFT,
	BOTTOMLEFT,
}

FontContext :: struct {
	fonts: [dynamic]Font, // allocated using context.allocator

	// always assuming user wants to resize
	nodes: [dynamic]AtlasNode,

	// actual pixels
	textureData:   []byte, // allocated using context.allocator
	width, height: int,
	// 1 / texture_atlas_width, 1 / texture_atlas_height
	itw, ith: f32,

	// state 
	states:      []State,
	state_count: int, // used states

	location: QuadLocation,

	// dirty rectangle of the texture region that was updated
	dirtyRect: [4]f32,

	// callbacks with userData passed
	userData: rawptr, // by default set to the context

	// called when a texture is expanded and needs handling
	callbackResize: proc(data: rawptr, w, h: int), 
	// called in state_end to update the texture region that changed
	callbackUpdate: proc(data: rawptr, dirtyRect: [4]f32, textureData: rawptr), 
}

Init :: proc(ctx: ^FontContext, w, h: int, loc: QuadLocation) {
	ctx.userData = ctx
	ctx.location = loc
	ctx.fonts    = make([dynamic]Font, 0, 8)

	ctx.itw, ctx.ith = 1.0 / f32(w), 1.0 / f32(h)

	ctx.textureData = make([]byte, w * h)
	
	ctx.width  = w
	ctx.height = h
	ctx.nodes  = make([dynamic]AtlasNode, 0, INIT_ATLAS_NODES)
	__dirtyRectReset(ctx)

	ctx.states = make([]State, MAX_STATES)

	// NOTE NECESSARY
	append(&ctx.nodes, AtlasNode{
		width = i16(w),
	})

	__AtlasAddWhiteRect(ctx, 2, 2)

	PushState(ctx)
	ClearState(ctx)
}

Destroy :: proc(ctx: ^FontContext) {
	for font in ctx.fonts {
		if font.freeLoadedData {
			delete(font.loadedData)
		}

		delete(font.name)
		delete(font.glyphs)
	}

	delete(ctx.states)
	delete(ctx.textureData)
	delete(ctx.fonts)
	delete(ctx.nodes)
}

Reset :: proc(ctx: ^FontContext) {
	__atlasReset(ctx, ctx.width, ctx.height)
	__dirtyRectReset(ctx)
	slice.zero(ctx.textureData)

	for &font in ctx.fonts {
		__lutReset(&font)
	}

	__AtlasAddWhiteRect(ctx, 2, 2)
	PushState(ctx)
	ClearState(ctx)
}

__atlasInsertNode :: proc(ctx: ^FontContext, idx: int, x, y, w: int) {
	inject_at(&ctx.nodes, idx, AtlasNode{
		x     = i16(x),
		y     = i16(y),
		width = i16(w),
	})
}

__atlasRemoveNode :: proc(ctx: ^FontContext, idx: int) {
	if len(ctx.nodes) == 0 {
		return
	}

	ordered_remove(&ctx.nodes, idx)
}

__atlasExpand :: proc(ctx: ^FontContext, w, h: int) {
	if w > ctx.width {
		__atlasInsertNode(ctx, len(ctx.nodes), ctx.width, 0, w - ctx.width)
	}

	ctx.width, ctx.height = w, h
}

__atlasReset :: proc(ctx: ^FontContext, w, h: int) {
	ctx.width, ctx.height = w, h
	clear(&ctx.nodes)

	// init root node
	append(&ctx.nodes, AtlasNode{
		width = i16(w),
	})
}

__AtlasAddSkylineLevel :: proc(using ctx: ^FontContext, idx: int, x, y, w, h: int) {
	// insert new node
	__atlasInsertNode(ctx, idx, x, y + h, w)

	// Delete skyline segments that fall under the shadow of the new segment.
	for i := idx + 1; i < len(nodes); i += 1 {
		if nodes[i].x >= nodes[i-1].x + nodes[i-1].width {
			break
		}
		shrink := nodes[i-1].x + nodes[i-1].width - nodes[i].x
		nodes[i].x += i16(shrink)
		nodes[i].width -= i16(shrink)

		if nodes[i].width > 0 {
			break
		}
		__atlasRemoveNode(ctx, i)
		i -= 1
	}

	// Merge same height skyline segments that are next to each other.
	for i := 0; i < len(nodes) - 1; /**/ {
		if nodes[i].y == nodes[i+1].y {
			nodes[i].width += nodes[i+1].width
			__atlasRemoveNode(ctx, i+1)
		} else {
			i += 1
		}
	}
}

__AtlasRectFits :: proc(using ctx: ^FontContext, i, w, h: int) -> int {
	// Checks if there is enough space at the location of skyline span 'i',
	// and return the max height of all skyline spans under that at that location,
	// (think tetris block being dropped at that position). Or -1 if no space found.

	i := i
	x, y := int(nodes[i].x), int(nodes[i].y)

	if x + w > width {
		return -1
	}

	space_left := w
	for space_left > 0 {
		if i == len(nodes) {
			return -1
		}

		y = max(y, int(nodes[i].y))
		if y + h > height {
			return -1
		}

		space_left -= int(nodes[i].width)
		i += 1
	}

	return y
}

__AtlasAddRect :: proc(using ctx: ^FontContext, rw, rh: int) -> (rx, ry: int, ok: bool) {
	bestw, besth := width, height
	besti, bestx, besty := -1, -1, -1

	// Bottom left fit heuristic.
	for i in 0..<len(nodes) {
		y := __AtlasRectFits(ctx, i, rw, rh)
		
		if y != -1 {
			if y + rh < besth || (y + rh == besth && int(nodes[i].width) < bestw) {
				besti = i
				bestw = int(nodes[i].width)
				besth = y + rh
				bestx = int(nodes[i].x)
				besty = y
			}
		}
	}

	if besti == -1 {
		return
	}

	// Perform the actual packing.
	__AtlasAddSkylineLevel(ctx, besti, bestx, besty, rw, rh) 
	return bestx, besty, true
}

__AtlasAddWhiteRect :: proc(ctx: ^FontContext, w, h: int) -> bool {
	gx, gy := __AtlasAddRect(ctx, w, h) or_return

	// Rasterize
	dst := ctx.textureData[gx + gy * ctx.width:]
	for _ in 0..<h {
		for x in 0..<w {
			dst[x] = 0xff
		}

		dst = dst[ctx.width:]
	}

	ctx.dirtyRect[0] = f32(min(int(ctx.dirtyRect[0]), gx))
	ctx.dirtyRect[1] = f32(min(int(ctx.dirtyRect[1]), gy))
	ctx.dirtyRect[2] = f32(max(int(ctx.dirtyRect[2]), gx + w))
	ctx.dirtyRect[3] = f32(max(int(ctx.dirtyRect[3]), gy + h))

	return true
}

// push a font to the font stack
// optionally init with ascii characters at a wanted size
AddFontMem :: proc(
	ctx:            ^FontContext,
	name:           string,
	data:           []u8,
	freeLoadedData: bool,
) -> int {
	append(&ctx.fonts, Font{})
	res := &ctx.fonts[len(ctx.fonts) - 1]
	res.loadedData     = data
	res.freeLoadedData = freeLoadedData
	res.name           = strings.clone(name)

	stbtt.InitFont(&res.info, &res.loadedData[0], 0)
	ascent, descent, line_gap: i32

	stbtt.GetFontVMetrics(&res.info, &ascent, &descent, &line_gap)
	fh := f32(ascent - descent)
	res.ascender   = f32(ascent) / fh
	res.descender  = f32(descent) / fh
	res.lineHeight = (fh + f32(line_gap)) / fh
	res.glyphs     = make([dynamic]Glyph, 0, INIT_GLYPHS)

	__lutReset(res)
	return len(ctx.fonts) - 1
}

AddFont :: proc { AddFontPath, AddFontMem }

AddFallbackFont :: proc(ctx: ^FontContext, base, fallback: int) -> bool {
	base_font := __getFont(ctx, base)
	
	if base_font.nfallbacks < MAX_FALLBACKS {
		base_font.fallbacks[base_font.nfallbacks] = fallback
		base_font.nfallbacks += 1
		return true
	}

	return false
}

ResetFallbackFont :: proc(ctx: ^FontContext, base: int) {
	base_font := __getFont(ctx, base)
	base_font.nfallbacks = 0
	clear(&base_font.glyphs)
	__lutReset(base_font)
}

// find font by name
GetFontByName :: proc(ctx: ^FontContext, name: string) -> int {
	for font, i in ctx.fonts {
		if font.name == name {
			return i
		}
	}

	return INVALID
}

__lutReset :: proc(font: ^Font) {
	// set lookup table
	slice.fill(font.lut[:], -1)
}

__hashint :: proc(a: u32) -> u32 {
	a := a
	a += ~(a << 15)
	a ~=  (a >> 10)
	a +=  (a << 3)
	a ~=  (a >> 6)
	a +=  (a << 11)
	a ~=  (a >> 16)
	return a
}

__renderGlyphBitmap :: proc(
	font:       ^Font,
	output:     []u8,
	outWidth:   i32,
	outHeight:  i32,
	outStride:  i32,
	scaleX:     f32,
	scaleY:     f32,
	glyphIndex: Glyph_Index,
) {
	stbtt.MakeGlyphBitmap(&font.info, raw_data(output), outWidth, outHeight, outStride, scaleX, scaleY, glyphIndex)
}

__buildGlyphBitmap :: proc(
	font:       ^Font,
	glyphIndex: Glyph_Index,
	pixelSize:  f32,
	scale:      f32,
) -> (advance, lsb, x0, y0, x1, y1: i32) {
	stbtt.GetGlyphHMetrics(&font.info, glyphIndex, &advance, &lsb)
	stbtt.GetGlyphBitmapBox(&font.info, glyphIndex, scale, scale, &x0, &y0, &x1, &y1)
	return
}

// get glyph and push to atlas if not exists
__getGlyph :: proc(
	ctx:       ^FontContext,
	font:      ^Font,
	codepoint: rune,
	isize:     i16,
	blur:      i16 = 0,
) -> (res: ^Glyph, ok: bool) #no_bounds_check {
	if isize < 2 {
		return
	}

	// find code point and size
	h := __hashint(u32(codepoint)) & (HASH_LUT_SIZE - 1)
	for i := font.lut[h]; i != -1; /**/ {
		glyph := &font.glyphs[i]
		
		if glyph.codepoint == codepoint &&
		   glyph.isize     == isize &&
		   glyph.blurSize  == blur {
			res = glyph
			ok = true
			return
		}

		i = glyph.next
	}

	// could not find glyph, create it.
	render_font := font // font used to render
	glyph_index := __getGlyph_index(font, codepoint)
	if glyph_index == 0 {
		// lookout for possible fallbacks
		for i in 0..<font.nfallbacks {
			fallback_font := __getFont(ctx, font.fallbacks[i])
			fallback_index := __getGlyph_index(fallback_font, codepoint)

			if fallback_index != 0 {
				glyph_index = fallback_index
				render_font = fallback_font
				break
			}
		}
	}

	pixel_size := f32(isize) / 10
	blurSize   := min(blur, 20)
	padding    := i16(blurSize + 2) // 2 minimum padding
	scale      := __getPixelHeightScale(render_font, pixel_size)
	advance, _, x0, y0, x1, y1 := __buildGlyphBitmap(render_font, glyph_index, pixel_size, scale)
	gw := (x1 - x0) + i32(padding) * 2
	gh := (y1 - y0) + i32(padding) * 2 

	// Find free spot for the rect in the atlas
	gx, gy, rect_ok := __AtlasAddRect(ctx, int(gw), int(gh))
	if !rect_ok {
		// try again with expanded
		ExpandAtlas(ctx, ctx.width * 2, ctx.height * 2)
		gx, gy = __AtlasAddRect(ctx, int(gw), int(gh)) or_return
	}
	
	// Init glyph.
	append(&font.glyphs, Glyph{
		codepoint = codepoint,
		isize     = isize,
		blurSize  = blurSize,
		index     = glyph_index,
		x0        = i16(gx),
		y0        = i16(gy),
		x1        = i16(i32(gx) + gw),
		y1        = i16(i32(gy) + gh),
		xadvance  = i16(scale * f32(advance) * 10),
		xoff      = i16(x0 - i32(padding)),
		yoff      = i16(y0 - i32(padding)),

		// insert char to hash lookup.
		next = font.lut[h],
	})
	font.lut[h] = len(font.glyphs) - 1
	res = &font.glyphs[len(font.glyphs) - 1]

	// rasterize
	dst := ctx.textureData[int(res.x0 + padding) + int(res.y0 + padding) * ctx.width:]
	__renderGlyphBitmap(
		render_font,
		dst,
		gw - i32(padding) * 2, 
		gh - i32(padding) * 2, 
		i32(ctx.width), 
		scale,
		scale,
		glyph_index,
	)

	// make sure there is one pixel empty border.
	dst = ctx.textureData[int(res.x0) + int(res.y0) * ctx.width:]
	// y direction
	for y in 0..<int(gh) {
		dst[y * ctx.width] = 0
		dst[int(gw - 1) + y * ctx.width] = 0
	}
	// x direction
	for x in 0..<int(gw) {
		dst[x] = 0
		dst[x + int(gh - 1) * ctx.width] = 0
	}

	if blurSize > 0 {
		__blur(dst, int(gw), int(gh), ctx.width, blurSize)
	}

	ctx.dirtyRect[0] = f32(min(int(ctx.dirtyRect[0]), int(res.x0)))
	ctx.dirtyRect[1] = f32(min(int(ctx.dirtyRect[1]), int(res.y0)))
	ctx.dirtyRect[2] = f32(max(int(ctx.dirtyRect[2]), int(res.x1)))
	ctx.dirtyRect[3] = f32(max(int(ctx.dirtyRect[3]), int(res.y1)))

	ok = true
	return
}

/////////////////////////////////
// blur
/////////////////////////////////

// Based on Exponential blur, Jani Huhtanen, 2006

BLUR_APREC :: 16
BLUR_ZPREC :: 7

__blurCols :: proc(dst: []u8, w, h, dstStride, alpha: int) {
	dst := dst

	for _ in 0..<h {
		z := 0 // force zero border

		for x in 1..<w {
			z += (alpha * ((int(dst[x]) << BLUR_ZPREC) - z)) >> BLUR_APREC
			dst[x] = u8(z >> BLUR_ZPREC)
		}

		dst[w - 1] = 0 // force zero border
		z = 0

		for x := w - 2; x >= 0; x -= 1 {
			z += (alpha * ((int(dst[x]) << BLUR_ZPREC) - z)) >> BLUR_APREC
			dst[x] = u8(z >> BLUR_ZPREC)
		}

		dst[0] = 0 // force zero border
		dst = dst[dstStride:] // advance slice
	}
}

__blurRows :: proc(dst: []u8, w, h, dstStride, alpha: int) {
	dst := dst

	for _ in 0..<w {
		z := 0 // force zero border
		for y := dstStride; y < h * dstStride; y += dstStride {
			z += (alpha * ((int(dst[y]) << BLUR_ZPREC) - z)) >> BLUR_APREC
			dst[y] = u8(z >> BLUR_ZPREC)
		}

		dst[(h - 1) * dstStride] = 0 // force zero border
		z = 0

		for y := (h - 2) * dstStride; y >= 0; y -= dstStride {
			z += (alpha * ((int(dst[y]) << BLUR_ZPREC) - z)) >> BLUR_APREC
			dst[y] = u8(z >> BLUR_ZPREC)
		}

		dst[0] = 0 // force zero border
		dst = dst[1:] // advance
	}
}

__blur :: proc(dst: []u8, w, h, dstStride: int, blurSize: i16) {
	assert(blurSize > 0)

	// Calculate the alpha such that 90% of the kernel is within the radius. (Kernel extends to infinity)
	sigma := f32(blurSize) * 0.57735 // 1 / sqrt(3)
	alpha := int((1 << BLUR_APREC) * (1 - math.exp(-2.3 / (sigma + 1))))
	__blurRows(dst, w, h, dstStride, alpha)
	__blurCols(dst, w, h, dstStride, alpha)
	__blurRows(dst, w, h, dstStride, alpha)
	__blurCols(dst, w, h, dstStride, alpha)
}

/////////////////////////////////
// Texture expansion
/////////////////////////////////

ExpandAtlas :: proc(ctx: ^FontContext, width, height: int, allocator := context.allocator) -> bool {
	w := max(ctx.width, width)
	h := max(ctx.height, height)

	if w == ctx.width && h == ctx.height {
		return true
	}

	if ctx.callbackResize != nil {
		ctx.callbackResize(ctx.userData, w, h)
	}

	data := make([]byte, w * h, allocator)

	for i in 0..<ctx.height {
		dst := &data[i * w]
		src := &ctx.textureData[i * ctx.width]
		mem.copy(dst, src, ctx.width)

		if w > ctx.width {
			mem.set(&data[i * w + ctx.width], 0, w - ctx.width)
		}
	}

	if h > ctx.height {
		mem.set(&data[ctx.height * w], 0, (h - ctx.height) * w)
	}

	delete(ctx.textureData)
	ctx.textureData = data

	// increase atlas size
	__atlasExpand(ctx, w, h)

	// add existing data as dirty
	maxy := i16(0)
	for node in ctx.nodes {
		maxy = max(maxy, node.y)
	}
	ctx.dirtyRect[0] = 0
	ctx.dirtyRect[1] = 0
	ctx.dirtyRect[2] = f32(ctx.width)
	ctx.dirtyRect[3] = f32(maxy)

	ctx.width = w
	ctx.height = h
	ctx.itw = 1.0 / f32(w)
	ctx.ith = 1.0 / f32(h)

	return true
}

ResetAtlas :: proc(ctx: ^FontContext, width, height: int, allocator := context.allocator) -> bool {
	if width == ctx.width && height == ctx.height {
		// just clear
		slice.zero(ctx.textureData)
	} else {
		// realloc
		delete(ctx.textureData, allocator)
		ctx.textureData = make([]byte, width * height, allocator)
	}

	ctx.dirtyRect[0] = f32(width)
	ctx.dirtyRect[1] = f32(height)
	ctx.dirtyRect[2] = 0
	ctx.dirtyRect[3] = 0

	// reset fonts
	for &font in ctx.fonts {
		clear(&font.glyphs)
		__lutReset(&font)
	}

	ctx.width = width
	ctx.height = height
	ctx.itw = 1.0 / f32(width)
	ctx.ith = 1.0 / f32(height)

	_ = __AtlasAddWhiteRect(ctx, 2, 2)
	return true
}

__getGlyph_index :: proc(font: ^Font, codepoint: rune) -> Glyph_Index {
	return stbtt.FindGlyphIndex(&font.info, codepoint)
}

__getPixelHeightScale :: proc(font: ^Font, pixel_height: f32) -> f32 {
	return stbtt.ScaleForPixelHeight(&font.info, pixel_height)
}

__getGlyphKernAdvance :: proc(font: ^Font, glyph1, glyph2: Glyph_Index) -> i32 {
	return stbtt.GetGlyphKernAdvance(&font.info, glyph1, glyph2)
}

// get a font with bounds checking
__getFont :: proc(ctx: ^FontContext, index: int, loc := #caller_location) -> ^Font #no_bounds_check {
	runtime.bounds_check_error_loc(loc, index, len(ctx.fonts))
	return &ctx.fonts[index]
}

// only useful for single glyphs where you quickly want the width
CodepointWidth :: proc(
	font: ^Font,
	codepoint: rune,
	scale: f32,
) -> f32 {
	glyph_index := __getGlyph_index(font, codepoint)
	xadvance, lsb: i32
	stbtt.GetGlyphHMetrics(&font.info, glyph_index, &xadvance, &lsb)
	return f32(xadvance) * scale
}

// get top and bottom line boundary
LineBounds :: proc(ctx: ^FontContext, y: f32) -> (miny, maxy: f32) {
	state := __getState(ctx)
	font  := __getFont(ctx, state.font)
	isize := i16(state.size * 10.0)
	y := y
	y += __getVerticalAlign(ctx, font, state.av, isize)

	if ctx.location == .TOPLEFT {
		miny =    y - font.ascender   * f32(isize) / 10
		maxy = miny + font.lineHeight * f32(isize / 10)
	} else if ctx.location == .BOTTOMLEFT {
		miny =    y + font.ascender   * f32(isize) / 10
		maxy = miny - font.lineHeight * f32(isize / 10)
	}

	return
}

// reset dirty rect
__dirtyRectReset :: proc(using ctx: ^FontContext) {
	dirtyRect[0] = f32(width)
	dirtyRect[1] = f32(height)
	dirtyRect[2] = 0
	dirtyRect[3] = 0
}

// true when the dirty rectangle is valid and needs a texture update on the gpu
ValidateTexture :: proc(using ctx: ^FontContext, dirty: ^[4]f32) -> bool {
	if dirtyRect[0] < dirtyRect[2] && dirtyRect[1] < dirtyRect[3] {
		dirty[0] = dirtyRect[0]
		dirty[1] = dirtyRect[1]
		dirty[2] = dirtyRect[2]
		dirty[3] = dirtyRect[3]
		__dirtyRectReset(ctx)
		return true
	}

	return false
}

// get alignment based on font
__getVerticalAlign :: proc(
	ctx:       ^FontContext,
	font:      ^Font,
	av:        AlignVertical,
	pixelSize: i16,
) -> (res: f32) {
	switch ctx.location {
	case .TOPLEFT:
		switch av {
		case .TOP: res = font.ascender * f32(pixelSize) / 10
		case .MIDDLE: res = (font.ascender + font.descender) / 2 * f32(pixelSize) / 10
		case .BASELINE: res = 0
		case .BOTTOM: res = font.descender * f32(pixelSize) / 10
		}

	case .BOTTOMLEFT: 
		switch av {
		case .TOP: res = -font.ascender * f32(pixelSize) / 10
		case .MIDDLE: res = -(font.ascender + font.descender) / 2 * f32(pixelSize) / 10
		case .BASELINE: res = 0
		case .BOTTOM: res = -font.descender * f32(pixelSize) / 10
		}
	}

	return
}

@(private)
UTF8_ACCEPT :: 0

@(private)
UTF8_REJECT :: 1

@(private)
utf8d := [400]u8{
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, // 00..1f
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, // 20..3f
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, // 40..5f
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, // 60..7f
	1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9, // 80..9f
	7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7, // a0..bf
	8,8,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2, // c0..df
	0xa,0x3,0x3,0x3,0x3,0x3,0x3,0x3,0x3,0x3,0x3,0x3,0x3,0x4,0x3,0x3, // e0..ef
	0xb,0x6,0x6,0x6,0x5,0x8,0x8,0x8,0x8,0x8,0x8,0x8,0x8,0x8,0x8,0x8, // f0..ff
	0x0,0x1,0x2,0x3,0x5,0x8,0x7,0x1,0x1,0x1,0x4,0x6,0x1,0x1,0x1,0x1, // s0..s0
	1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,0,1,0,1,1,1,1,1,1, // s1..s2
	1,2,1,1,1,1,1,2,1,2,1,1,1,1,1,1,1,1,1,1,1,1,1,2,1,1,1,1,1,1,1,1, // s3..s4
	1,2,1,1,1,1,1,1,1,2,1,1,1,1,1,1,1,1,1,1,1,1,1,3,1,3,1,1,1,1,1,1, // s5..s6
	1,3,1,1,1,1,1,3,1,3,1,1,1,1,1,1,1,3,1,1,1,1,1,1,1,1,1,1,1,1,1,1, // s7..s8
}

// decode codepoints from a state
@(private)
__decutf8 :: #force_inline proc(state: ^rune, codep: ^rune, b: byte) -> bool {
	b := rune(b)
	type := utf8d[b]
	codep^ = (state^ != UTF8_ACCEPT) ? ((b & 0x3f) | (codep^ << 6)) : ((0xff >> type) & (b))
	state^ = rune(utf8d[256 + state^ * 16 + rune(type)])
	return state^ == UTF8_ACCEPT
}

// state used to share font options
State :: struct {
	font:    int,
	size:    f32,
	color:   [4]u8,
	spacing: f32,
	blur:    f32,

	ah: AlignHorizontal,
	av: AlignVertical,
}

// quad that should be used to draw from the texture atlas
Quad :: struct {
	x0, y0, s0, t0: f32,
	x1, y1, s1, t1: f32,
}

// text iteration with custom settings
TextIter :: struct {
	x, y, nextx, nexty, scale, spacing: f32,
	isize, iblur:                       i16,

	font:               ^Font,
	previousGlyphIndex: Glyph_Index,

	// unicode iteration
	utf8state:      rune, // utf8
	codepoint:      rune,
	text:           string,
	codepointCount: int,

	// byte indices
	str:  int,
	next: int,
	end:  int,
}

// push a state, copies the current one over to the next one
PushState :: proc(using ctx: ^FontContext, loc := #caller_location) #no_bounds_check {
	runtime.bounds_check_error_loc(loc, state_count, MAX_STATES)

	if state_count > 0 {
		states[state_count] = states[state_count - 1]
	}

	state_count += 1
}

// pop a state 
PopState :: proc(using ctx: ^FontContext) {
	if state_count <= 1 {
		log.error("FONTSTASH: state underflow! to many pops were called")
	} else {
		state_count -= 1
	}
}

// clear current state
ClearState :: proc(ctx: ^FontContext) {
	state := __getState(ctx)
	state.size    = 12
	state.color   = 255
	state.blur    = 0
	state.spacing = 0
	state.font    = 0
	state.ah      = .LEFT
	state.av      = .BASELINE
}

__getState :: #force_inline proc(ctx: ^FontContext) -> ^State #no_bounds_check {
	return &ctx.states[ctx.state_count - 1]
}

SetSize :: proc(ctx: ^FontContext, size: f32) {
	__getState(ctx).size = size
}

SetColor :: proc(ctx: ^FontContext, color: [4]u8) {
	__getState(ctx).color = color
}

SetSpacing :: proc(ctx: ^FontContext, spacing: f32) {
	__getState(ctx).spacing = spacing
}

SetBlur :: proc(ctx: ^FontContext, blur: f32) {
	__getState(ctx).blur = blur
}

SetFont :: proc(ctx: ^FontContext, font: int) {
	__getState(ctx).font = font
}

SetAH :: SetAlignHorizontal
SetAV :: SetAlignVertical

SetAlignHorizontal :: proc(ctx: ^FontContext, ah: AlignHorizontal) {
	__getState(ctx).ah = ah
}

SetAlignVertical :: proc(ctx: ^FontContext, av: AlignVertical) {
	__getState(ctx).av = av
}

__getQuad :: proc(
	ctx:  ^FontContext,
	font: ^Font,
	
	previousGlyphIndex: i32,
	glyph:              ^Glyph,

	scale:   f32,
	spacing: f32,
	
	x, y: ^f32,
	quad: ^Quad,
) {
	if previousGlyphIndex != -1 {
		adv := f32(__getGlyphKernAdvance(font, previousGlyphIndex, glyph.index)) * scale
		x^ += f32(int(adv + spacing + 0.5))
	}

	// fill props right
	rx, ry, x0, y0, x1, y1, xoff, yoff: f32
	xoff = f32(glyph.xoff + 1)
	yoff = f32(glyph.yoff + 1)
	x0 = f32(glyph.x0 + 1)
	y0 = f32(glyph.y0 + 1)
	x1 = f32(glyph.x1 - 1)
	y1 = f32(glyph.y1 - 1)

	switch ctx.location {
	case .TOPLEFT:
		rx = math.floor(x^ + xoff)
		ry = math.floor(y^ + yoff)
		
		quad.x0 = rx
		quad.y0 = ry
		quad.x1 = rx + x1 - x0
		quad.y1 = ry + y1 - y0

		quad.s0 = x0 * ctx.itw
		quad.t0 = y0 * ctx.ith
		quad.s1 = x1 * ctx.itw
		quad.t1 = y1 * ctx.ith

	case .BOTTOMLEFT:
		rx = math.floor(x^ + xoff)
		ry = math.floor(y^ - yoff)

		quad.x0 = rx
		quad.y0 = ry
		quad.x1 = rx + x1 - x0
		quad.y1 = ry - y1 + y0

		quad.s0 = x0 * ctx.itw
		quad.t0 = y0 * ctx.ith
		quad.s1 = x1 * ctx.itw
		quad.t1 = y1 * ctx.ith
	}

	x^ += f32(int(f32(glyph.xadvance) / 10 + 0.5))
}

// init text iter struct with settings
TextIterInit :: proc(
	ctx:  ^FontContext,
	x:    f32,
	y:    f32,
	text: string,
) -> (res: TextIter) {

	x, y := x, y

	state := __getState(ctx)
	res.font  = __getFont(ctx, state.font)
	res.isize = i16(f32(state.size) * 10)
	res.iblur = i16(state.blur)
	res.scale = __getPixelHeightScale(res.font, f32(res.isize) / 10)

	// align horizontally
	switch state.ah {
	case .LEFT:
		/**/
	case .CENTER:
		width := TextBounds(ctx, text, x, y, nil)
		x = math.round(x - width * 0.5)
	case .RIGHT: 
		width := TextBounds(ctx, text, x, y, nil)
		x -= width
	}

	// align vertically
	y = math.round(y + __getVerticalAlign(ctx, res.font, state.av, res.isize))

	// set positions
	res.x, res.nextx = x, x
	res.y, res.nexty = y, y
	res.previousGlyphIndex = -1
	res.spacing = state.spacing
	res.text    = text

	res.str  = 0
	res.next = 0
	res.end  = len(text)

	return
}

// step through each codepoint
TextIterNext :: proc(
	ctx:  ^FontContext,
	iter: ^TextIter, 
	quad: ^Quad,
) -> (ok: bool) {
	str := iter.next
	iter.str = iter.next

	for str < iter.end {
		defer str += 1

		if __decutf8(&iter.utf8state, &iter.codepoint, iter.text[str]) {
			iter.x = iter.nextx
			iter.y = iter.nexty
			iter.codepointCount += 1
			if glyph, glyph_ok := __getGlyph(ctx, iter.font, iter.codepoint, iter.isize, iter.iblur); glyph_ok {
				__getQuad(ctx, iter.font, iter.previousGlyphIndex, glyph, iter.scale, iter.spacing, &iter.nextx, &iter.nexty, quad)
				iter.previousGlyphIndex = glyph.index
			} else {
				iter.previousGlyphIndex = -1
			}
			ok = true
			break
		}
	}

	iter.next = str
	return
}

// width of a text line, optionally the full rect
TextBounds :: proc(
	ctx:    ^FontContext,
	text:   string,
	x:      f32 = 0,
	y:      f32 = 0,
	bounds: ^[4]f32 = nil,
) -> f32 {
	state := __getState(ctx)
	isize := i16(state.size * 10)
	iblur := i16(state.blur)
	font  := __getFont(ctx, state.font)

	// bunch of state
	x, y := x, y
	minx, maxx := x, x
	miny, maxy := y, y
	start_x := x

	// iterate	
	scale := __getPixelHeightScale(font, f32(isize) / 10)
	previousGlyphIndex: Glyph_Index = -1
	quad: Quad
	utf8state: rune
	codepoint: rune
	for byte_offset in 0..<len(text) {
		if __decutf8(&utf8state, &codepoint, text[byte_offset]) {
			if glyph, ok := __getGlyph(ctx, font, codepoint, isize, iblur); ok {
				__getQuad(ctx, font, previousGlyphIndex, glyph, scale, state.spacing, &x, &y, &quad)

				if quad.x0 < minx {
					minx = quad.x0
				}
				if quad.x1 > maxx {
					maxx = quad.x1
				}

				if ctx.location == .TOPLEFT {
					if quad.y0 < miny {
						miny = quad.y0
					}
					if quad.y1 > maxy {
						maxy = quad.y1
					}
				} else if ctx.location == .BOTTOMLEFT {
					if quad.y1 < miny {
						miny = quad.y1
					}
					if quad.y0 > maxy {
						maxy = quad.y0
					}
				}

				previousGlyphIndex = glyph.index
			} else {
				previousGlyphIndex = -1
			}

		}
	}

	// horizontal alignment
	advance := x - start_x
	switch state.ah {
	case .LEFT:
		/**/
	case .CENTER: 
		minx -= advance * 0.5
		maxx -= advance * 0.5
	case .RIGHT:
		minx -= advance
		maxx -= advance
	}

	if bounds != nil {
		bounds^ = { minx, miny, maxx, maxy }
	}

	return advance
}

VerticalMetrics :: proc(
	ctx: ^FontContext,
) -> (ascender, descender, lineHeight: f32) {
	state := __getState(ctx)
	isize := i16(state.size * 10.0)
	font  := __getFont(ctx, state.font)
	ascender   = font.ascender * f32(isize / 10)
	descender  = font.descender * f32(isize / 10)
	lineHeight = font.lineHeight * f32(isize / 10)
	return
}

// reset to single state
BeginState :: proc(ctx: ^FontContext) {
	ctx.state_count = 0
	PushState(ctx)
	ClearState(ctx)
}

// checks for texture updates after potential __getGlyph calls
EndState :: proc(using ctx: ^FontContext) {
	// check for texture update
	if dirtyRect[0] < dirtyRect[2] && dirtyRect[1] < dirtyRect[3] {
		if callbackUpdate != nil {
			callbackUpdate(userData, dirtyRect, raw_data(textureData))
		}
		__dirtyRectReset(ctx)
	}
}
