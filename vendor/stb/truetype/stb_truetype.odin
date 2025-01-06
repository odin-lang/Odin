package stb_truetype

import c "core:c"
import stbrp "vendor:stb/rect_pack"

@(private)
LIB :: (
	     "../lib/stb_truetype.lib"      when ODIN_OS == .Windows
	else "../lib/stb_truetype.a"        when ODIN_OS == .Linux
	else "../lib/darwin/stb_truetype.a" when ODIN_OS == .Darwin
	else "../lib/stb_truetype_wasm.o"   when ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32
	else ""
)

when LIB != "" {
	when !#exists(LIB) {
		#panic("Could not find the compiled STB libraries, they can be compiled by running `make -C \"" + ODIN_ROOT + "vendor/stb/src\"`")
	}
}

when ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32 {
	foreign import stbtt "../lib/stb_truetype_wasm.o"
} else when LIB != "" {
	foreign import stbtt { LIB }
} else {
	foreign import stbtt "system:stb_truetype"
}

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
////
////   INTERFACE
////
////

#assert(size_of(c.int) == size_of(rune))
#assert(size_of(c.int) == size_of(b32))

//////////////////////////////////////////////////////////////////////////////
//
// TEXTURE BAKING API
//
// If you use this API, you only have to call two functions ever.
//

bakedchar :: struct {
	x0, y0, x1, y1: u16, // coordinates of bbox in bitmap
	xoff, yoff, xadvance: f32,
}

aligned_quad :: struct {
	x0, y0, s0, t0: f32, // top-left
	x1, y1, s1, t1: f32, // bottom-right
}



// bindings
@(default_calling_convention="c", link_prefix="stbtt_")
foreign stbtt {
	// if return is positive, the first unused row of the bitmap
	// if return is negative, returns the negative of the number of characters that fit
	// if return is 0, no characters fit and no rows were used
	// This uses a very crappy packing.
	BakeFontBitmap :: proc(data: [^]byte, offset: c.int,   // font location (use offset=0 for plain .ttf)
	                       pixel_height: f32,              // height of font in pixels
	                       pixels: [^]byte, pw, ph: c.int, // bitmap to be filled in
	                       first_char, num_chars: c.int,   // characters to bake
	                       chardata: [^]bakedchar,         // you allocate this, it's num_chars long
	) -> c.int ---
	
	// Call GetBakedQuad with char_index = 'character - first_char', and it
	// creates the quad you need to draw and advances the current position.
	//
	// The coordinate system used assumes y increases downwards.
	//
	// Characters will extend both above and below the current position;
	// see discussion of "BASELINE" above.
	//
	// It's inefficient; you might want to c&p it and optimize it.
	GetBakedQuad :: proc(chardata: ^bakedchar, pw, ph: c.int, // same data as above
	                     char_index: c.int,                   // character to display
	                     xpos, ypos: ^f32,                    // pointers to current position in screen pixel space
	                     q: ^aligned_quad,                    // output: quad to draw
	                     opengl_fillrule: b32,                // true if opengl fill rule; false if DX9 or earlier
	) ---
	
	// Query the font vertical metrics without having to create a font first.
	GetScaledFontVMetrics :: proc(fontdata: [^]byte, index: c.int, size: f32, ascent, descent, lineGap: ^f32) ---

}



//////////////////////////////////////////////////////////////////////////////
//
// NEW TEXTURE BAKING API
//
// This provides options for packing multiple fonts into one atlas, not
// perfectly but better than nothing.

packedchar :: struct {
	x0, y0, x1, y1:       u16,
	xoff, yoff, xadvance: f32,
	xoff2, yoff2:         f32,
}

pack_range :: struct {
	font_size:                        f32,
	first_unicode_codepoint_in_range: c.int,
	array_of_unicode_codepoints:      [^]rune,
	num_chars:                        c.int,
	chardata_for_range:               ^packedchar,
	_, _: u8, // used internally to store oversample info
}

pack_context :: struct {
	user_allocator_context, pack_info:       rawptr,
	width, height, stride_in_bytes, padding: c.int,
	skip_missing:                            b32,
	h_oversample, v_oversample:              u32,
	pixels:                                  [^]byte,
	nodes:                                   rawptr,
}

POINT_SIZE :: #force_inline proc(x: $T) -> T { return -x } // @NOTE: this was a macro

// bindings
@(default_calling_convention="c", link_prefix="stbtt_")
foreign stbtt {
	// Initializes a packing context stored in the passed-in stbtt_pack_context.
	// Future calls using this context will pack characters into the bitmap passed
	// in here: a 1-channel bitmap that is width * height. stride_in_bytes is
	// the distance from one row to the next (or 0 to mean they are packed tightly
	// together). "padding" is the amount of padding to leave between each
	// character (normally you want '1' for bitmaps you'll use as textures with
	// bilinear filtering).
	//
	// Returns 0 on failure, 1 on success.
	PackBegin :: proc(spc: ^pack_context, pixels: [^]byte, width, height, stride_in_bytes, padding: c.int, alloc_context: rawptr) -> c.int ---
	
	// Cleans up the packing context and frees all memory.
	PackEnd :: proc(spc: ^pack_context) ---
	
	// Creates character bitmaps from the font_index'th font found in fontdata (use
	// font_index=0 if you don't know what that is). It creates num_chars_in_range
	// bitmaps for characters with unicode values starting at first_unicode_char_in_range
	// and increasing. Data for how to render them is stored in chardata_for_range;
	// pass these to stbtt_GetPackedQuad to get back renderable quads.
	//
	// font_size is the full height of the character from ascender to descender,
	// as computed by stbtt_ScaleForPixelHeight. To use a point size as computed
	// by stbtt_ScaleForMappingEmToPixels, wrap the point size in POINT_SIZE()
	// and pass that result as 'font_size':
	//       ...,            20 , ... // font max minus min y is 20 pixels tall
	//       ..., POINT_SIZE(20), ... // 'M' is 20 pixels tall
	PackFontRange :: proc(spc: ^pack_context, fontdata: [^]byte, font_index: c.int, font_size: f32, first_unicode_char_in_range, num_chars_in_range: c.int, chardata_for_range: ^packedchar) -> c.int ---
	
	// Creates character bitmaps from multiple ranges of characters stored in
	// ranges. This will usually create a better-packed bitmap than multiple
	// calls to stbtt_PackFontRange. Note that you can call this multiple
	// times within a single PackBegin/PackEnd.
	PackFontRanges :: proc(spc: ^pack_context, fontdata: [^]byte, font_index: c.int, ranges: [^]pack_range, num_ranges: c.int) -> c.int ---
	
	// Oversampling a font increases the quality by allowing higher-quality subpixel
	// positioning, and is especially valuable at smaller text sizes.
	//
	// This function sets the amount of oversampling for all following calls to
	// stbtt_PackFontRange(s) or stbtt_PackFontRangesGatherRects for a given
	// pack context. The default (no oversampling) is achieved by h_oversample=1
	// and v_oversample=1. The total number of pixels required is
	// h_oversample*v_oversample larger than the default; for example, 2x2
	// oversampling requires 4x the storage of 1x1. For best results, render
	// oversampled textures with bilinear filtering. Look at the readme in
	// stb/tests/oversample for information about oversampled fonts
	//
	// To use with PackFontRangesGather etc., you must set it before calls
	// call to PackFontRangesGatherRects.
	PackSetOversampling :: proc(spc: ^pack_context, h_oversample, v_oversample: c.uint) ---
	
	// If skip != false, this tells stb_truetype to skip any codepoints for which
	// there is no corresponding glyph. If skip=false, which is the default, then
	// codepoints without a glyph recived the font's "missing character" glyph,
	// typically an empty box by convention.
	PackSetSkipMissingCodepoints :: proc(spc: ^pack_context, skip: b32) ---
	
	GetPackedQuad :: proc(chardata: ^packedchar, pw, ph: c.int, // same data as above
	                      char_index: c.int,                    // character to display
	                      xpos, ypos: ^f32,                     // pointers to current position in screen pixel space
	                      q: ^aligned_quad,                     // output: quad to draw
	                      align_to_integer: b32,
	) ---
	
	// Calling these functions in sequence is roughly equivalent to calling
	// stbtt_PackFontRanges(). If you more control over the packing of multiple
	// fonts, or if you want to pack custom data into a font texture, take a look
	// at the source to of stbtt_PackFontRanges() and create a custom version
	// using these functions, e.g. call GatherRects multiple times,
	// building up a single array of rects, then call PackRects once,
	// then call RenderIntoRects repeatedly. This may result in a
	// better packing than calling PackFontRanges multiple times
	// (or it may not).
	PackFontRangesGatherRects     :: proc(spc: ^pack_context, info: ^fontinfo, ranges: ^pack_range, num_ranges: c.int, rects: [^]stbrp.Rect) -> c.int ---
	PackFontRangesPackRects       :: proc(spc: ^pack_context, rects: [^]stbrp.Rect, num_rects: c.int) --- 
	PackFontRangesRenderIntoRects :: proc(spc: ^pack_context, info: ^fontinfo, ranges: ^pack_range, num_ranges: c.int, rects: [^]stbrp.Rect) -> c.int --- 
}

//////////////////////////////////////////////////////////////////////////////
//
// FONT LOADING
//
//

fontinfo :: struct {
	userdata:  rawptr,
	data:      [^]byte,
	fontstart: c.int,

	numGlyphs: c.int,

	loca, head, glyf, hhea, hmtx, kern, gpos, svg: c.int,
	index_map: c.int,
	indexToLocFormat: c.int,

	cff:         _buf,
	charstrings: _buf,
	gsubrs:      _buf,
	subrs:       _buf,
	fontdicts:   _buf,
	fdselect:    _buf,
}

@(default_calling_convention="c", link_prefix="stbtt_")
foreign stbtt {
	// Given an offset into the file that defines a font, this function builds
	// the necessary cached info for the rest of the system. You must allocate
	// the stbtt_fontinfo yourself, and stbtt_InitFont will fill it out. You don't
	// need to do anything special to free it, because the contents are pure
	// value data with no additional data structures. Returns 0 on failure.
	InitFont :: proc(info: ^fontinfo, data: [^]byte, offset: c.int) -> b32 ---
	
	// This function will determine the number of fonts in a font file.  TrueType
	// collection (.ttc) files may contain multiple fonts, while TrueType font
	// (.ttf) files only contain one font. The number of fonts can be used for
	// indexing with the previous function where the index is between zero and one
	// less than the total fonts. If an error occurs, -1 is returned.
	GetNumberOfFonts :: proc(data: [^]byte) -> c.int ---
	
	// Each .ttf/.ttc file may have more than one font. Each font has a sequential
	// index number starting from 0. Call this function to get the font offset for
	// a given index; it returns -1 if the index is out of range. A regular .ttf
	// file will only define one font and it always be at offset 0, so it will
	// return '0' for index 0, and -1 for all other indices.
	GetFontOffsetForIndex :: proc(data: [^]byte, index: c.int) -> c.int ---
}

//////////////////////////////////////////////////////////////////////////////
//
// CHARACTER TO GLYPH-INDEX CONVERSION

@(default_calling_convention="c", link_prefix="stbtt_")
foreign stbtt {
	// If you're going to perform multiple operations on the same character
	// and you want a speed-up, call this function with the character you're
	// going to process, then use glyph-based functions instead of the
	// codepoint-based functions.
	// Returns 0 if the character codepoint is not defined in the font.
	FindGlyphIndex :: proc(info: ^fontinfo, unicode_codepoint: rune) -> c.int ---
}

//////////////////////////////////////////////////////////////////////////////
//
// CHARACTER PROPERTIES
//

@(default_calling_convention="c", link_prefix="stbtt_")
foreign stbtt {
	// computes a scale factor to produce a font whose "height" is 'pixels' tall.
	// Height is measured as the distance from the highest ascender to the lowest
	// descender; in other words, it's equivalent to calling stbtt_GetFontVMetrics
	// and computing:
	//       scale = pixels / (ascent - descent)
	// so if you prefer to measure height by the ascent only, use a similar calculation.
	ScaleForPixelHeight :: proc(info: ^fontinfo, pixels: f32) -> f32 ---
	
	// computes a scale factor to produce a font whose EM size is mapped to
	// 'pixels' tall. This is probably what traditional APIs compute, but
	// I'm not positive.
	ScaleForMappingEmToPixels :: proc(info: ^fontinfo, pixels: f32) -> f32 ---
	
	// ascent is the coordinate above the baseline the font extends; descent
	// is the coordinate below the baseline the font extends (i.e. it is typically negative)
	// lineGap is the spacing between one row's descent and the next row's ascent...
	// so you should advance the vertical position by "*ascent - *descent + *lineGap"
	//   these are expressed in unscaled coordinates, so you must multiply by
	//   the scale factor for a given size
	GetFontVMetrics :: proc(info: ^fontinfo, ascent, descent, lineGap: ^c.int) ---
	
	// analogous to GetFontVMetrics, but returns the "typographic" values from the OS/2
	// table (specific to MS/Windows TTF files).
	//
	// Returns 1 on success (table present), 0 on failure.
	GetFontVMetricsOS2 :: proc(info: ^fontinfo, typoAscent, typoDescent, typoLineGap: ^c.int) -> b32 ---
	
	// the bounding box around all possible characters
	GetFontBoundingBox :: proc(info: ^fontinfo, x0, y0, x1, y1: ^c.int) ---
	
	// leftSideBearing is the offset from the current horizontal position to the left edge of the character
	// advanceWidth is the offset from the current horizontal position to the next horizontal position
	//   these are expressed in unscaled coordinates
	GetCodepointHMetrics :: proc(info: ^fontinfo, codepoint: rune, advanceWidth, leftSideBearing: ^c.int) ---
	
	// an additional amount to add to the 'advance' value between ch1 and ch2
	GetCodepointKernAdvance :: proc(info: ^fontinfo, ch1, ch2: rune) -> (advance: c.int) ---
	
	// Gets the bounding box of the visible part of the glyph, in unscaled coordinates
	GetCodepointBox :: proc(info: ^fontinfo, codepoint: rune, x0, y0, x1, y1: ^c.int) -> c.int ---
	
	// as above, but takes one or more glyph indices for greater efficiency
	GetGlyphHMetrics    :: proc(info: ^fontinfo, glyph_index: c.int, advanceWidth, leftSideBearing: ^c.int) ---
	GetGlyphKernAdvance :: proc(info: ^fontinfo, glyph1, glyph2: c.int) -> c.int ---
	GetGlyphBox         :: proc(info: ^fontinfo, glyph_index: c.int, x0, y0, x1, y1: ^c.int) -> c.int ---
}

kerningentry :: struct {
	glyph1:  rune, // use FindGlyphIndex
	glyph2:  rune,
	advance: c.int,
}

@(default_calling_convention="c", link_prefix="stbtt_")
foreign stbtt {
	// Retrieves a complete list of all of the kerning pairs provided by the font
	// stbtt_GetKerningTable never writes more than table_length entries and returns how many entries it did write.
	// The table will be sorted by (a.glyph1 == b.glyph1)?(a.glyph2 < b.glyph2):(a.glyph1 < b.glyph1)
	GetKerningTableLength :: proc(info: ^fontinfo) -> c.int ---
	GetKerningTable       :: proc(info: ^fontinfo, table: [^]kerningentry, table_length: c.int) -> c.int ---
}


//////////////////////////////////////////////////////////////////////////////
//
// GLYPH SHAPES (you probably don't need these, but they have to go before
// the bitmaps for C declaration-order reasons)
//

vmove :: enum c.int {
	none,
	vmove=1,
	vline,
	vcurve,
	vcubic,
}

vertex_type :: distinct c.short // can't use stbtt_int16 because that's not visible in the header file
vertex :: struct {
	x, y, cx, cy, cx1, cy1: vertex_type,
	type, padding:          byte,
}

@(default_calling_convention="c", link_prefix="stbtt_")
foreign stbtt {
	// returns true if nothing is drawn for this glyph
	IsGlyphEmpty :: proc(info: ^fontinfo, glyph_index: c.int) -> b32 ---

	// returns # of vertices and fills *vertices with the pointer to them
	//   these are expressed in "unscaled" coordinates
	//
	// The shape is a series of contours. Each one starts with
	// a STBTT_moveto, then consists of a series of mixed
	// STBTT_lineto and STBTT_curveto segments. A lineto
	// draws a line from previous endpoint to its x,y; a curveto
	// draws a quadratic bezier from previous endpoint to
	// its x,y, using cx,cy as the bezier control point.
	GetCodepointShape :: proc(info: ^fontinfo, unicode_codepoint: rune, vertices: ^[^]vertex) -> c.int ---
	GetGlyphShape     :: proc(info: ^fontinfo, glyph_index:      c.int, vertices: ^[^]vertex) -> c.int ---

	// frees the data allocated above
	FreeShape :: proc(info: ^fontinfo, vertices: [^]vertex) ---

	// fills svg with the character's SVG data.
	// returns data size or 0 if SVG not found.
	FindSVGDoc       :: proc(info: ^fontinfo, gl: b32) -> [^]byte ---
	GetCodepointSVG  :: proc(info: ^fontinfo, unicode_codepoint: rune, svg: ^cstring) -> c.int ---
	GetGlyphSVG      :: proc(info: ^fontinfo, gl: b32, svg: ^cstring) -> c.int ---
}


//////////////////////////////////////////////////////////////////////////////
//
// BITMAP RENDERING
//

_bitmap :: struct {
	w, h, stride: c.int,
	pixels: [^]byte,
}

@(default_calling_convention="c", link_prefix="stbtt_")
foreign stbtt {
	// frees the bitmap allocated below
	FreeBitmap :: proc(bitmap: [^]byte, userdata: rawptr) ---

	// allocates a large-enough single-channel 8bpp bitmap and renders the
	// specified character/glyph at the specified scale into it, with
	// antialiasing. 0 is no coverage (transparent), 255 is fully covered (opaque).
	// *width & *height are filled out with the width & height of the bitmap,
	// which is stored left-to-right, top-to-bottom.
	//
	// xoff/yoff are the offset it pixel space from the glyph origin to the top-left of the bitmap
	GetCodepointBitmap :: proc(info: ^fontinfo, scale_x, scale_y: f32, codepoint: rune, width, height, xoff, yoff: ^c.int) -> [^]byte ---

	// the same as stbtt_GetCodepoitnBitmap, but you can specify a subpixel
	// shift for the character
	GetCodepointBitmapSubpixel :: proc(info: ^fontinfo, scale_x, scale_y, shift_x, shift_y: f32, codepoint: rune, width, height, xoff, yoff: ^c.int) -> [^]byte ---

	// the same as stbtt_GetCodepointBitmap, but you pass in storage for the bitmap
	// in the form of 'output', with row spacing of 'out_stride' bytes. the bitmap
	// is clipped to out_w/out_h bytes. Call stbtt_GetCodepointBitmapBox to get the
	// width and height and positioning info for it first.
	MakeCodepointBitmap :: proc(info: ^fontinfo, output: [^]byte, out_w, out_h, out_stride: c.int, scale_x, scale_y: f32, codepoint: rune) ---

	// same as stbtt_MakeCodepointBitmap, but you can specify a subpixel
	// shift for the character
	MakeCodepointBitmapSubpixel :: proc(info: ^fontinfo, output: [^]byte, out_w, out_h, out_stride: c.int, scale_x, scale_y, shift_x, shift_y: f32, codepoint: rune) ---

	// same as stbtt_MakeCodepointBitmapSubpixel, but prefiltering
	// is performed (see stbtt_PackSetOversampling)
	MakeCodepointBitmapSubpixelPrefilter :: proc(info: ^fontinfo, output: [^]byte, out_w, out_h, out_stride: c.int, scale_x, scale_y, shift_x, shift_y: f32, oversample_x, oversample_y: b32, sub_x, sub_y: ^f32, codepoint: rune) ---

	// get the bbox of the bitmap centered around the glyph origin; so the
	// bitmap width is ix1-ix0, height is iy1-iy0, and location to place
	// the bitmap top left is (leftSideBearing*scale,iy0).
	// (Note that the bitmap uses y-increases-down, but the shape uses
	// y-increases-up, so CodepointBitmapBox and CodepointBox are inverted.)
	GetCodepointBitmapBox :: proc(font: ^fontinfo, codepoint: rune, scale_x, scale_y: f32, ix0, iy0, ix1, iy1: ^c.int) ---

	// same as stbtt_GetCodepointBitmapBox, but you can specify a subpixel
	// shift for the character
	GetCodepointBitmapBoxSubpixel :: proc(font: ^fontinfo, codepoint: rune, scale_x, scale_y, shift_x, shift_y: f32, ix0, iy0, ix1, iy1: ^c.int) ---

	// the following functions are equivalent to the above functions, but operate
	// on glyph indices instead of Unicode codepoints (for efficiency)
	GetGlyphBitmap                   :: proc(info: ^fontinfo, scale_x, scale_y: f32, glyph: c.int, width, height, xoff, yoff: ^c.int) -> [^]byte ---
	GetGlyphBitmapSubpixel           :: proc(info: ^fontinfo, scale_x, scale_y, shift_x, shift_y: f32, glyph: c.int, width, height, xoff, yoff: ^c.int) -> [^]byte ---
	MakeGlyphBitmap                  :: proc(info: ^fontinfo, output: [^]byte, out_w, out_h, out_stride: c.int, scale_x, scale_y: f32, glyph: c.int) ---
	MakeGlyphBitmapSubpixel          :: proc(info: ^fontinfo, output: [^]byte, out_w, out_h, out_stride: c.int, scale_x, scale_y, shift_x, shift_y: f32, glyph: c.int) ---
	MakeGlyphBitmapSubpixelPrefilter :: proc(info: ^fontinfo, output: [^]byte, out_w, out_h, out_stride: c.int, scale_x, scale_y, shift_x, shift_y: f32, oversample_x, oversample_y: c.int, sub_x, sub_y: ^f32, glyph: c.int) ---
	GetGlyphBitmapBox                :: proc(font: ^fontinfo, glyph: c.int, scale_x, scale_y: f32, ix0, iy0, ix1, iy1: ^c.int) ---
	GetGlyphBitmapBoxSubpixel        :: proc(font: ^fontinfo, glyph: c.int, scale_x, scale_y, shift_x, shift_y: f32, ix0, iy0, ix1, iy1: ^c.int) ---
	
	// rasterize a shape with quadratic beziers into a bitmap
	Rasterize :: proc(result: ^_bitmap,        // 1-channel bitmap to draw into
	                  flatness_in_pixels: f32, // allowable error of curve in pixels
	                  vertices: [^]vertex,     // array of vertices defining shape
	                  num_verts: c.int,        // number of vertices in above array
	                  scale_x, scale_y: f32,   // scale applied to input vertices
	                  shift_x, shift_y: f32,   // translation applied to input vertices
	                  x_off, y_off: c.int,     // another translation applied to input
	                  invert: b32,             // if non-zero, vertically flip shape
	                  userdata: rawptr,        // context for to STBTT_MALLOC
	) ---

}

//////////////////////////////////////////////////////////////////////////////
//
// Signed Distance Function (or Field) rendering
//

@(default_calling_convention="c", link_prefix="stbtt_")
foreign stbtt {
	// frees the SDF bitmap allocated below
	FreeSDF :: proc(bitmap: [^]byte, userdata: rawptr) ---
	
	// These functions compute a discretized SDF field for a single character, suitable for storing
	// in a single-channel texture, sampling with bilinear filtering, and testing against
	// larger than some threshold to produce scalable fonts.
	//        info              --  the font
	//        scale             --  controls the size of the resulting SDF bitmap, same as it would be creating a regular bitmap
	//        glyph/codepoint   --  the character to generate the SDF for
	//        padding           --  extra "pixels" around the character which are filled with the distance to the character (not 0),
	//                                 which allows effects like bit outlines
	//        onedge_value      --  value 0-255 to test the SDF against to reconstruct the character (i.e. the isocontour of the character)
	//        pixel_dist_scale  --  what value the SDF should increase by when moving one SDF "pixel" away from the edge (on the 0..255 scale)
	//                                 if positive, > onedge_value is inside; if negative, < onedge_value is inside
	//        width,height      --  output height & width of the SDF bitmap (including padding)
	//        xoff,yoff         --  output origin of the character
	//        return value      --  a 2D array of bytes 0..255, width*height in size
	//
	// pixel_dist_scale & onedge_value are a scale & bias that allows you to make
	// optimal use of the limited 0..255 for your application, trading off precision
	// and special effects. SDF values outside the range 0..255 are clamped to 0..255.
	//
	// Example:
	//      scale = stbtt_ScaleForPixelHeight(22)
	//      padding = 5
	//      onedge_value = 180
	//      pixel_dist_scale = 180/5.0 = 36.0
	//
	//      This will create an SDF bitmap in which the character is about 22 pixels
	//      high but the whole bitmap is about 22+5+5=32 pixels high. To produce a filled
	//      shape, sample the SDF at each pixel and fill the pixel if the SDF value
	//      is greater than or equal to 180/255. (You'll actually want to antialias,
	//      which is beyond the scope of this example.) Additionally, you can compute
	//      offset outlines (e.g. to stroke the character border inside & outside,
	//      or only outside). For example, to fill outside the character up to 3 SDF
	//      pixels, you would compare against (180-36.0*3)/255 = 72/255. The above
	//      choice of variables maps a range from 5 pixels outside the shape to
	//      2 pixels inside the shape to 0..255; this is intended primarily for apply
	//      outside effects only (the interior range is needed to allow proper
	//      antialiasing of the font at *smaller* sizes)
	//
	// The function computes the SDF analytically at each SDF pixel, not by e.g.
	// building a higher-res bitmap and approximating it. In theory the quality
	// should be as high as possible for an SDF of this size & representation, but
	// unclear if this is true in practice (perhaps building a higher-res bitmap
	// and computing from that can allow drop-out prevention).
	//
	// The algorithm has not been optimized at all, so expect it to be slow
	// if computing lots of characters or very large sizes.

	GetGlyphSDF     :: proc(info: ^fontinfo, scale: f32, glyph, padding: c.int, onedge_value: u8, pixel_dist_scale: f32, width, height, xoff, yoff: ^c.int) -> [^]byte ---
	GetCodepointSDF :: proc(info: ^fontinfo, scale: f32, codepoint, padding: c.int, onedge_value: u8, pixel_dist_scale: f32, width, height, xoff, yoff: ^c.int) -> [^]byte ---
}



//////////////////////////////////////////////////////////////////////////////
//
// Finding the right font...
//
// You should really just solve this offline, keep your own tables
// of what font is what, and don't try to get it out of the .ttf file.
// That's because getting it out of the .ttf file is really hard, because
// the names in the file can appear in many possible encodings, in many
// possible languages, and e.g. if you need a case-insensitive comparison,
// the details of that depend on the encoding & language in a complex way
// (actually underspecified in truetype, but also gigantic).
//
// But you can use the provided functions in two possible ways:
//     stbtt_FindMatchingFont() will use *case-sensitive* comparisons on
//             unicode-encoded names to try to find the font you want;
//             you can run this before calling stbtt_InitFont()
//
//     stbtt_GetFontNameString() lets you get any of the various strings
//             from the file yourself and do your own comparisons on them.
//             You have to have called stbtt_InitFont() first.

MACSTYLE_DONTCARE     :: 0
MACSTYLE_BOLD         :: 1
MACSTYLE_ITALIC       :: 2
MACSTYLE_UNDERSCORE   :: 4
MACSTYLE_NONE         :: 8   // <= not same as 0, this makes us check the bitfield is 0

@(default_calling_convention="c", link_prefix="stbtt_")
foreign stbtt {	
	// returns the offset (not index) of the font that matches, or -1 if none
	//   if you use STBTT_MACSTYLE_DONTCARE, use a font name like "Arial Bold".
	//   if you use any other flag, use a font name like "Arial"; this checks
	//     the 'macStyle' header field; i don't know if fonts set this consistently
	FindMatchingFont :: proc(fontdata: [^]byte, name: cstring, flags: c.int) -> c.int ---
	
	// returns 1/0 whether the first string interpreted as utf8 is identical to
	// the second string interpreted as big-endian utf16... useful for strings from next func
	CompareUTF8toUTF16_bigendian :: proc(s1: cstring, len1: c.int, s2: cstring, len2: c.int) -> c.int ---

	// returns the string (which may be big-endian double byte, e.g. for unicode)
	// and puts the length in bytes in *length.
	//
	// some of the values for the IDs are below; for more see the truetype spec:
	//     http://developer.apple.com/textfonts/TTRefMan/RM06/Chap6name.html
	//     http://www.microsoft.com/typography/otspec/name.htm
	GetFontNameString :: proc(font: ^fontinfo, length: ^c.int, platformID: PLATFORM_ID, encodingID, languageID, nameID: c.int) -> cstring ---
}


PLATFORM_ID :: enum c.int { // platformID
	PLATFORM_ID_UNICODE   = 0,
	PLATFORM_ID_MAC       = 1,
	PLATFORM_ID_ISO       = 2,
	PLATFORM_ID_MICROSOFT = 3,
}

// encodingID for PLATFORM_ID_UNICODE
UNICODE_EID_UNICODE_1_0      :: 0
UNICODE_EID_UNICODE_1_1      :: 1
UNICODE_EID_ISO_10646        :: 2
UNICODE_EID_UNICODE_2_0_BMP  :: 3
UNICODE_EID_UNICODE_2_0_FULL :: 4

// encodingID for PLATFORM_ID_MICROSOFT
MS_EID_SYMBOL       :: 0
MS_EID_UNICODE_BMP  :: 1
MS_EID_SHIFTJIS     :: 2
MS_EID_UNICODE_FULL :: 10


// encodingID for PLATFORM_ID_MAC; same as Script Manager codes
MAC_EID_ROMAN,        MAC_EID_ARABIC  :: 0, 4
MAC_EID_JAPANESE,     MAC_EID_HEBREW  :: 1, 5
MAC_EID_CHINESE_TRAD, MAC_EID_GREEK   :: 2, 6
MAC_EID_KOREAN,       MAC_EID_RUSSIAN :: 3, 7

// languageID for PLATFORM_ID_MICROSOFT; same as LCID...
// problematic because there are e.g. 16 english LCIDs and 16 arabic LCIDs
MS_LANG_ENGLISH,  MS_LANG_ITALIAN  :: 0x0409, 0x0410
MS_LANG_CHINESE,  MS_LANG_JAPANESE :: 0x0804, 0x0411
MS_LANG_DUTCH,    MS_LANG_KOREAN   :: 0x0413, 0x0412
MS_LANG_FRENCH,   MS_LANG_RUSSIAN  :: 0x040c, 0x0419
MS_LANG_GERMAN,   MS_LANG_SPANISH  :: 0x0407, 0x0409
MS_LANG_HEBREW,   MS_LANG_SWEDISH  :: 0x040d, 0x041D


// languageID for PLATFORM_ID_MAC
MAC_LANG_ENGLISH, MAC_LANG_JAPANESE           :: 0,  11
MAC_LANG_ARABIC,  MAC_LANG_KOREAN             :: 12, 23
MAC_LANG_DUTCH,   MAC_LANG_RUSSIAN            :: 4,  32
MAC_LANG_FRENCH,  MAC_LANG_SPANISH            :: 1,  6
MAC_LANG_GERMAN,  MAC_LANG_SWEDISH            :: 2,  5
MAC_LANG_HEBREW,  MAC_LANG_CHINESE_SIMPLIFIED :: 10, 33
MAC_LANG_ITALIAN, MAC_LANG_CHINESE_TRAD       :: 3,  19

// private structure
_buf :: struct {
	data:   [^]byte,
	cursor: c.int,
	size:   c.int,
}
