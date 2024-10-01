#+build windows, linux, darwin
package nanovg

// TODO rename structs to old nanovg style!
// TODO rename enums to old nanovg style!

import "core:mem"
import "core:math"
import "core:fmt"
import "../fontstash"
import stbi "vendor:stb/image"

AlignVertical   :: fontstash.AlignVertical
AlignHorizontal :: fontstash.AlignHorizontal

INIT_FONTIMAGE_SIZE :: 512
MAX_FONTIMAGE_SIZE  :: 2048
MAX_FONTIMAGES      :: 4

MAX_STATES         :: 32
INIT_COMMANDS_SIZE :: 256
INIT_POINTS_SIZE   :: 128
INIT_PATH_SIZE     :: 16
INIT_VERTS_SIZE    :: 26
KAPPA              :: 0.5522847493

Color  :: [4]f32
Matrix :: [6]f32
Vertex :: [4]f32 // x,y,u,v

ImageFlag :: enum {
	GENERATE_MIPMAPS,
	REPEAT_X,
	REPEAT_Y,
	FLIP_Y,
	PREMULTIPLIED,
	NEAREST,
	NO_DELETE,
}
ImageFlags :: bit_set[ImageFlag]

Paint :: struct {
	xform:      Matrix,
	extent:     [2]f32,
	radius:     f32,
	feather:    f32,
	innerColor: Color,
	outerColor: Color,
	image:      int,
}

Winding :: enum {
	CCW = 1,
	CW,
}

Solidity :: enum {
	SOLID = 1, // CCW
	HOLE, // CW
}

LineCapType :: enum {
	BUTT,
	ROUND,
	SQUARE,
	BEVEL,
	MITER,
}

BlendFactor :: enum {
	ZERO,
	ONE,
	SRC_COLOR,
	ONE_MINUS_SRC_COLOR,
	DST_COLOR,
	ONE_MINUS_DST_COLOR,
	SRC_ALPHA,
	ONE_MINUS_SRC_ALPHA,
	DST_ALPHA,
	ONE_MINUS_DST_ALPHA,
	SRC_ALPHA_SATURATE,
}

CompositeOperation :: enum {
	SOURCE_OVER,
	SOURCE_IN,
	SOURCE_OUT,
	ATOP,
	DESTINATION_OVER,
	DESTINATION_IN,
	DESTINATION_OUT,
	DESTINATION_ATOP,
	LIGHTER,
	COPY,
	XOR,
}

CompositeOperationState :: struct {
	srcRGB: BlendFactor,
	dstRGB: BlendFactor,
	srcAlpha: BlendFactor,
	dstAlpha: BlendFactor,
}

// render data structures

Texture :: enum {
	Alpha,
	RGBA,
}

ScissorT :: struct {
	xform:  Matrix,
	extent: [2]f32,
}

Commands :: enum {
	MOVE_TO,
	LINE_TO,
	BEZIER_TO,
	CLOSE,
	WINDING,
}

PointFlag :: enum {
	CORNER,
	LEFT,
	BEVEL,
	INNER_BEVEL,
}
PointFlags :: bit_set[PointFlag]

Point :: struct {
	x, y:     f32,
	dx, dy:   f32,
	len:      f32,
	dmx, dmy: f32,
	flags:    PointFlags,
}

PathCache :: struct {
	points: [dynamic]Point,
	paths:  [dynamic]Path,
	verts:  [dynamic]Vertex,
	bounds: [4]f32,
}

Path :: struct {
	first:   int,
	count:   int,
	closed:  bool,
	nbevel:  int,
	fill:    []Vertex,
	stroke:  []Vertex,
	winding: Winding,
	convex:  bool,
}

State :: struct {
	compositeOperation: CompositeOperationState,
	shapeAntiAlias:     bool,
	fill:               Paint,
	stroke:             Paint,
	strokeWidth:        f32,
	miterLimit:         f32,
	lineJoin:           LineCapType,
	lineCap:            LineCapType,
	alpha:              f32,
	xform:              Matrix,
	scissor:            ScissorT,

	// font state
	fontSize:        f32,
	letterSpacing:   f32,
	lineHeight:      f32,
	fontBlur:        f32,
	alignHorizontal: AlignHorizontal,
	alignVertical:   AlignVertical,
	fontId:          int,
}

Context :: struct {
	params:        Params,
	commands:      [dynamic]f32,
	commandx,      commandy: f32,
	states:        [MAX_STATES]State,
	nstates:       int,
	cache:         PathCache,
	tessTol:       f32,
	distTol:       f32,
	fringeWidth:   f32,
	devicePxRatio: f32,

	// font
	fs:           fontstash.FontContext,
	fontImages:   [MAX_FONTIMAGES]int,
	fontImageIdx: int,

	// stats
	drawCallCount:  int,
	fillTriCount:   int,
	strokeTriCount: int,
	textTriCount:   int,

	// flush texture
	textureDirty: bool,
}

Params :: struct {
	userPtr:       rawptr,
	edgeAntiAlias: bool,
	
	// callbacks to fill out
	renderCreate: proc(uptr: rawptr) -> bool,
	renderDelete: proc(uptr: rawptr),

	// textures calls
	renderCreateTexture: proc(
		uptr:       rawptr,
		type:       Texture,
		w, h:       int,
		imageFlags: ImageFlags, 
		data:       []byte,
	) -> int,
	renderDeleteTexture: proc(uptr: rawptr, image: int) -> bool,
	renderUpdateTexture: proc(
		uptr:  rawptr,
		image: int,
		x, y:  int,
		w, h:  int,
		data:  []byte,
	) -> bool,
	renderGetTextureSize: proc(uptr: rawptr, image: int, w, h: ^int) -> bool,

	// rendering calls
	renderViewport: proc(uptr: rawptr, width, height, devicePixelRatio: f32),
	renderCancel: proc(uptr: rawptr),
	renderFlush: proc(uptr: rawptr),
	renderFill: proc(
		uptr:               rawptr,
		paint:              ^Paint,
		compositeOperation: CompositeOperationState, 
		scissor:            ^ScissorT,
		fringe:             f32,
		bounds:             [4]f32,
		paths:              []Path,
	),
	renderStroke: proc(
		uptr:               rawptr,
		paint:              ^Paint,
		compositeOperation: CompositeOperationState, 
		scissor:            ^ScissorT,
		fringe:             f32,
		strokeWidth:        f32,
		paths:              []Path,
	),	
	renderTriangles: proc(
		uptr:               rawptr,
		paint:              ^Paint,
		compositeOperation: CompositeOperationState, 
		scissor:            ^ScissorT,
		verts:              []Vertex,
		fringe:             f32,
	),
}

__allocPathCache :: proc(c: ^PathCache) {
	c.points = make([dynamic]Point, 0, INIT_POINTS_SIZE)
	c.paths  = make([dynamic]Path, 0, INIT_PATH_SIZE)
	c.verts  = make([dynamic]Vertex, 0, INIT_VERTS_SIZE)
}

__deletePathCache :: proc(c: PathCache) {
	delete(c.points)
	delete(c.paths)
	delete(c.verts)
}

__setDevicePxRatio :: proc(ctx: ^Context, ratio: f32) {
	ctx.tessTol       = 0.25 / ratio
	ctx.distTol       = 0.01 / ratio
	ctx.fringeWidth   = 1.0 / ratio
	ctx.devicePxRatio = ratio
}

__getState :: #force_inline proc(ctx: ^Context) -> ^State #no_bounds_check {
	return &ctx.states[ctx.nstates-1]
}

CreateInternal :: proc(params: Params) -> (ctx: ^Context) {
	ctx = new(Context)
	ctx.params = params
	ctx.commands = make([dynamic]f32, 0, INIT_COMMANDS_SIZE)
	__allocPathCache(&ctx.cache)

	Save(ctx)
	Reset(ctx)
	__setDevicePxRatio(ctx, 1)

	assert(ctx.params.renderCreate != nil)
	if !ctx.params.renderCreate(ctx.params.userPtr) {
		DeleteInternal(ctx)
		panic("Nanovg - CreateInternal failed")
	}

	w := INIT_FONTIMAGE_SIZE
	h := INIT_FONTIMAGE_SIZE
	fontstash.Init(&ctx.fs, w, h, .TOPLEFT)
	assert(ctx.params.renderCreateTexture != nil)
	ctx.fs.userData = ctx
	
	// handle to the image needs to be set to the new generated texture
	ctx.fs.callbackResize = proc(data: rawptr, w, h: int) {
		ctx := (^Context)(data)
		ctx.fontImages[0] = ctx.params.renderCreateTexture(ctx.params.userPtr, .Alpha, w, h, {}, ctx.fs.textureData)
	}
	
	// texture atlas
	ctx.fontImages[0] = ctx.params.renderCreateTexture(ctx.params.userPtr, .Alpha, w, h, {}, nil)
	ctx.fontImageIdx = 0

	return
}

DeleteInternal :: proc(ctx: ^Context) {
	__deletePathCache(ctx.cache)
	fontstash.Destroy(&ctx.fs)

	for image in ctx.fontImages {
		if image != 0 {
			DeleteImage(ctx, image)
		}
	}

	if ctx.params.renderDelete != nil {
		ctx.params.renderDelete(ctx.params.userPtr)
	}

	delete(ctx.commands)
	free(ctx)
}

/*
	Begin drawing a new frame
	Calls to nanovg drawing API should be wrapped in nvgBeginFrame() & nvgEndFrame()
	nvgBeginFrame() defines the size of the window to render to in relation currently
	set viewport (i.e. glViewport on GL backends). Device pixel ration allows to
	control the rendering on Hi-DPI devices.
	For example, GLFW returns two dimension for an opened window: window size and
	frame buffer size. In that case you would set windowWidth/Height to the window size
	devicePixelRatio to: frameBufferWidth / windowWidth.
*/
BeginFrame :: proc(
	ctx:              ^Context,
	windowWidth:      f32,
	windowHeight:     f32,
	devicePixelRatio: f32,
) {
	ctx.nstates = 0
	Save(ctx)
	Reset(ctx)
	__setDevicePxRatio(ctx, devicePixelRatio)

	assert(ctx.params.renderViewport != nil)
	ctx.params.renderViewport(ctx.params.userPtr, windowWidth, windowHeight, devicePixelRatio)

	ctx.drawCallCount = 0
	ctx.fillTriCount = 0
	ctx.strokeTriCount = 0
	ctx.textTriCount = 0
}

@(deferred_out=EndFrame)
FrameScoped :: proc(
	ctx:              ^Context,
	windowWidth:      f32,
	windowHeight:     f32,
	devicePixelRatio: f32,
) -> ^Context {
	BeginFrame(ctx, windowWidth, windowHeight, devicePixelRatio)
	return ctx
}

// Cancels drawing the current frame.
CancelFrame :: proc(ctx: ^Context) {
	assert(ctx.params.renderCancel != nil)
	ctx.params.renderCancel(ctx.params.userPtr)	
}

// Ends drawing flushing remaining render state.
EndFrame :: proc(ctx: ^Context) {
	// flush texture only once
	if ctx.textureDirty {
		__flushTextTexture(ctx)
		ctx.textureDirty = false
	}

	assert(ctx.params.renderFlush != nil)
	ctx.params.renderFlush(ctx.params.userPtr)

	// delete textures with invalid size
	if ctx.fontImageIdx != 0 {
		font_image := ctx.fontImages[ctx.fontImageIdx]
		ctx.fontImages[ctx.fontImageIdx] = 0

		if font_image == 0 {
			return
		}

		iw, ih := ImageSize(ctx, font_image)
		j: int
		for i in 0..<ctx.fontImageIdx {
			if ctx.fontImages[i] != 0 {
				image := ctx.fontImages[i]
				ctx.fontImages[i] = 0
				nw, nh := ImageSize(ctx, image)

				if nw < iw || nh < ih {
					DeleteImage(ctx, image)
				} else {
					ctx.fontImages[j] = image
					j += 1
				}
			}
		}

		// make current font image to first
		ctx.fontImages[j] = ctx.fontImages[0]
		ctx.fontImages[0] = font_image
		ctx.fontImageIdx = 0
	}
}

///////////////////////////////////////////////////////////
// COLORS
//
// Colors in NanoVG are stored as unsigned ints in ABGR format.
///////////////////////////////////////////////////////////

// Returns a color value from red, green, blue values. Alpha will be set to 255 (1.0f).
RGB :: proc(r, g, b: u8) -> Color {
	return RGBA(r, g, b, 255)
}

// Returns a color value from red, green, blue and alpha values.
RGBA :: proc(r, g, b, a: u8) -> (res: Color) {
	res.r = f32(r) / f32(255)
	res.g = f32(g) / f32(255)
	res.b = f32(b) / f32(255)
	res.a = f32(a) / f32(255)
	return
}

// Linearly interpolates from color c0 to c1, and returns resulting color value.
LerpRGBA :: proc(c0, c1: Color, u: f32) -> (cint: Color) {
	clamped := clamp(u, 0.0, 1.0)
	oneminu := 1.0 - clamped
	for _, i in cint {
		cint[i] = c0[i] * oneminu + c1[i] * clamped
	}

	return
}

// Returns color value specified by hue, saturation and lightness.
// HSL values are all in range [0..1], alpha will be set to 255.
HSL :: proc(h, s, l: f32) -> Color {
	return HSLA(h,s,l,255)
}

// Returns color value specified by hue, saturation and lightness and alpha.
// HSL values are all in range [0..1], alpha in range [0..255]
HSLA :: proc(hue, saturation, lightness: f32, a: u8) -> (col: Color) {
	hue_get :: proc(h, m1, m2: f32) -> f32 {
		h := h

		if h < 0 {
			h += 1
		}
		
		if h > 1 {
			h -= 1
		} 
		
		if h < 1.0 / 6.0 {
			return m1 + (m2 - m1) * h * 6.0
		} else if h < 3.0 / 6.0 {
			return m2
		} else if h < 4.0 / 6.0 {
			return m1 + (m2 - m1) * (2.0 / 3.0 - h) * 6.0
		}

		return m1
	}

	h := math.mod(hue, 1.0)
	if h < 0.0 {
		h += 1.0
	} 
	s := clamp(saturation, 0.0, 1.0)
	l := clamp(lightness, 0.0, 1.0)
	m2 := l <= 0.5 ? (l * (1 + s)) : (l + s - l * s)
	m1 := 2 * l - m2
	col.r = clamp(hue_get(h + 1.0/3.0, m1, m2), 0.0, 1.0)
	col.g = clamp(hue_get(h, m1, m2), 0.0, 1.0)
	col.b = clamp(hue_get(h - 1.0/3.0, m1, m2), 0.0, 1.0)
	col.a = f32(a) / 255.0
	return
}

// hex to 0xAARRGGBB color
ColorHex :: proc(color: u32) -> (res: Color) {
	color := color
	res.b = f32(0x000000FF & color) / 255; color >>= 8
	res.g = f32(0x000000FF & color) / 255; color >>= 8
	res.r = f32(0x000000FF & color) / 255; color >>= 8
	res.a = f32(0x000000FF & color) / 255
	return
}

///////////////////////////////////////////////////////////
// TRANSFORMS
//
// The following functions can be used to make calculations on 2x3 transformation matrices.
// A 2x3 matrix is represented as float[6].
///////////////////////////////////////////////////////////

// Sets the transform to identity matrix.
TransformIdentity :: proc(t: ^Matrix) {
	t[0] = 1
	t[1] = 0
	t[2] = 0
	t[3] = 1
	t[4] = 0
	t[5] = 0
}

// Sets the transform to translation matrix matrix.
TransformTranslate :: proc(t: ^Matrix, tx, ty: f32) {
	t[0] = 1
	t[1] = 0
	t[2] = 0
	t[3] = 1
	t[4] = tx
	t[5] = ty
}

// Sets the transform to scale matrix.
TransformScale :: proc(t: ^Matrix, sx, sy: f32) {
	t[0] = sx
	t[1] = 0
	t[2] = 0
	t[3] = sy
	t[4] = 0
	t[5] = 0
}

// Sets the transform to rotate matrix. Angle is specified in radians.
TransformRotate :: proc(t: ^Matrix, a: f32) {
	cs := math.cos(a)
	sn := math.sin(a)
	t[0] = cs
	t[1] = sn
	t[2] = -sn
	t[3] = cs
	t[4] = 0
	t[5] = 0
}

// Sets the transform to skew-x matrix. Angle is specified in radians.
TransformSkewX :: proc(t: ^Matrix, a: f32) {
	t[0] = 1
	t[1] = 0
	t[2] = math.tan(a)
	t[3] = 1
	t[4] = 0
	t[5] = 0
}

// Sets the transform to skew-y matrix. Angle is specified in radians.
TransformSkewY :: proc(t: ^Matrix, a: f32) {
	t[0] = 1
	t[1] = math.tan(a)
	t[2] = 0
	t[3] = 1
	t[4] = 0
	t[5] = 0
}

// Sets the transform to the result of multiplication of two transforms, of A = A*B.
TransformMultiply :: proc(t: ^Matrix, s: Matrix) {
	t0 := t[0] * s[0] + t[1] * s[2]
	t2 := t[2] * s[0] + t[3] * s[2]
	t4 := t[4] * s[0] + t[5] * s[2] + s[4]
	t[1] = t[0] * s[1] + t[1] * s[3]
	t[3] = t[2] * s[1] + t[3] * s[3]
	t[5] = t[4] * s[1] + t[5] * s[3] + s[5]
	t[0] = t0
	t[2] = t2
	t[4] = t4
}

// Sets the transform to the result of multiplication of two transforms, of A = B*A.
TransformPremultiply :: proc(t: ^Matrix, s: Matrix) {
	temp := s
	TransformMultiply(&temp, t^)
	t^ = temp
}

// Sets the destination to inverse of specified transform.
// Returns true if the inverse could be calculated, else false.
TransformInverse :: proc(inv: ^Matrix, t: Matrix) -> bool {
	// TODO could be bad math? due to types
	det := f64(t[0]) * f64(t[3]) - f64(t[2]) * f64(t[1])
	
	if det > -1e-6 && det < 1e-6 {
		TransformIdentity(inv)
		return false
	}
	
	invdet := 1.0 / det
	inv[0] = f32(f64(t[3]) * invdet)
	inv[2] = f32(f64(-t[2]) * invdet)
	inv[4] = f32((f64(t[2]) * f64(t[5]) - f64(t[3]) * f64(t[4])) * invdet)
	inv[1] = f32(f64(-t[1]) * invdet)
	inv[3] = f32(f64(t[0]) * invdet)
	inv[5] = f32((f64(t[1]) * f64(t[4]) - f64(t[0]) * f64(t[5])) * invdet)
	return true
}

// Transform a point by given transform.
TransformPoint :: proc(
	dx: ^f32, 
	dy: ^f32, 
	t:  Matrix,
	sx: f32, 
	sy: f32,
) {
	dx^ = sx * t[0] + sy * t[2] + t[4]
	dy^ = sx * t[1] + sy * t[3] + t[5]
}

DegToRad :: proc(deg: f32) -> f32 {
	return deg / 180.0 * math.PI
}

RadToDeg :: proc(rad: f32) -> f32 {
	return rad / math.PI * 180.0
}

///////////////////////////////////////////////////////////
// STATE MANAGEMENT
//
// NanoVG contains state which represents how paths will be rendered.
// The state contains transform, fill and stroke styles, text and font styles,
// and scissor clipping.
///////////////////////////////////////////////////////////

// Pushes and saves the current render state into a state stack.
// A matching nvgRestore() must be used to restore the state.
Save :: proc(ctx: ^Context) {
	if ctx.nstates >= MAX_STATES {
		return
	}

	// copy prior
	if ctx.nstates > 0 {
		ctx.states[ctx.nstates] = ctx.states[ctx.nstates-1]
	}

	ctx.nstates += 1
}

// Pops and restores current render state.
Restore :: proc(ctx: ^Context) {
	if ctx.nstates <= 1 {
		return
	}

	ctx.nstates -= 1
}

// NOTE useful helper
@(deferred_in=Restore)
SaveScoped :: #force_inline proc(ctx: ^Context) {
	Save(ctx)
}

__setPaintColor :: proc(p: ^Paint, color: Color) {
	p^ = {}
	TransformIdentity(&p.xform)
	p.radius     = 0
	p.feather    = 1
	p.innerColor = color
	p.outerColor = color
}

// Resets current render state to default values. Does not affect the render state stack.
Reset :: proc(ctx: ^Context) {
	state := __getState(ctx)
	state^ = {}

	__setPaintColor(&state.fill, RGBA(255, 255, 255, 255))
	__setPaintColor(&state.stroke, RGBA(0, 0, 0, 255))

	state.compositeOperation = __compositeOperationState(.SOURCE_OVER)
	state.shapeAntiAlias     = true
	state.strokeWidth        = 1
	state.miterLimit         = 10
	state.lineCap            = .BUTT
	state.lineJoin           = .MITER
	state.alpha              = 1
	TransformIdentity(&state.xform)

	state.scissor.extent[0] = -1
	state.scissor.extent[1] = -1

	// font settings
	state.fontSize        = 16
	state.letterSpacing   = 0
	state.lineHeight      = 1
	state.fontBlur        = 0
	state.alignHorizontal = .LEFT
	state.alignVertical   = .BASELINE
	state.fontId          = 0
}

///////////////////////////////////////////////////////////
// STATE SETTING
///////////////////////////////////////////////////////////

// Sets whether to draw antialias for nvgStroke() and nvgFill(). It's enabled by default.
ShapeAntiAlias :: proc(ctx: ^Context, enabled: bool) {
	state := __getState(ctx)
	state.shapeAntiAlias = enabled
}

// Sets the stroke width of the stroke style.
StrokeWidth :: proc(ctx: ^Context, width: f32) {
	state := __getState(ctx)
	state.strokeWidth = width		
}

// Sets the miter limit of the stroke style.
// Miter limit controls when a sharp corner is beveled.
MiterLimit :: proc(ctx: ^Context, limit: f32) {
	state := __getState(ctx)
	state.miterLimit = limit
}

// Sets how the end of the line (cap) is drawn,
// Can be one of: NVG_BUTT (default), NVG_ROUND, NVG_SQUARE.
LineCap :: proc(ctx: ^Context, cap: LineCapType) {
	state := __getState(ctx)
	state.lineCap = cap
}

// Sets how sharp path corners are drawn.
// Can be one of NVG_MITER (default), NVG_ROUND, NVG_BEVEL.
LineJoin :: proc(ctx: ^Context, join: LineCapType) {
	state := __getState(ctx)
	state.lineJoin = join
}

// Sets the transparency applied to all rendered shapes.
// Already transparent paths will get proportionally more transparent as well.
GlobalAlpha :: proc(ctx: ^Context, alpha: f32) {
	state := __getState(ctx)
	state.alpha = alpha
}

// Sets current stroke style to a solid color.
StrokeColor :: proc(ctx: ^Context, color: Color) {
	state := __getState(ctx)
	__setPaintColor(&state.stroke, color)	
}

// Sets current stroke style to a paint, which can be a one of the gradients or a pattern.
StrokePaint :: proc(ctx: ^Context, paint: Paint) {
	state := __getState(ctx)
	state.stroke = paint
	TransformMultiply(&state.stroke.xform, state.xform)
}

// Sets current fill style to a solid color.
FillColor :: proc(ctx: ^Context, color: Color) {
	state := __getState(ctx)
	__setPaintColor(&state.fill, color)	
}

// Sets current fill style to a paint, which can be a one of the gradients or a pattern.
FillPaint :: proc(ctx: ^Context, paint: Paint) {
	state := __getState(ctx)
	state.fill = paint
	TransformMultiply(&state.fill.xform, state.xform)
}

///////////////////////////////////////////////////////////
// STATE TRANSFORMS
//
// The paths, gradients, patterns and scissor region are transformed by an transformation
// matrix at the time when they are passed to the API.
// The current transformation matrix is a affine matrix:
//   [sx kx tx]
//   [ky sy ty]
//   [ 0  0  1]
// Where: sx,sy define scaling, kx,ky skewing, and tx,ty translation.
// The last row is assumed to be 0,0,1 and is not stored.
//
// Apart from nvgResetTransform(), each transformation function first creates
// specific transformation matrix and pre-multiplies the current transformation by it.
//
// Current coordinate system (transformation) can be saved and restored using nvgSave() and nvgRestore().
///////////////////////////////////////////////////////////

Transform :: proc(ctx: ^Context, a, b, c, d, e, f: f32) {
	state := __getState(ctx)
	TransformPremultiply(&state.xform, {a, b, c, d, e, f})
}

// Resets current transform to a identity matrix.
ResetTransform :: proc(ctx: ^Context) {
	state := __getState(ctx)
	TransformIdentity(&state.xform)
}

// Translates current coordinate system.
Translate :: proc(ctx: ^Context, x, y: f32) {
	state := __getState(ctx)
	temp: Matrix
	TransformTranslate(&temp, x, y)
	TransformPremultiply(&state.xform, temp)
}

// Rotates current coordinate system. Angle is specified in radians.
Rotate :: proc(ctx: ^Context, angle: f32) {
	state := __getState(ctx)
	temp: Matrix
	TransformRotate(&temp, angle)
	TransformPremultiply(&state.xform, temp)
}

// Skews the current coordinate system along X axis. Angle is specified in radians.
SkewX :: proc(ctx: ^Context, angle: f32) {
	state := __getState(ctx)
	temp: Matrix
	TransformSkewX(&temp, angle)
	TransformPremultiply(&state.xform, temp)
}

// Skews the current coordinate system along Y axis. Angle is specified in radians.
SkewY :: proc(ctx: ^Context, angle: f32) {
	state := __getState(ctx)
	temp: Matrix
	TransformSkewY(&temp, angle)
	TransformPremultiply(&state.xform, temp)
}

// Scales the current coordinate system.
Scale :: proc(ctx: ^Context, x, y: f32) {
	state := __getState(ctx)
	temp: Matrix
	TransformScale(&temp, x, y)
	TransformPremultiply(&state.xform, temp)
}

/*
	Stores the top part (a-f) of the current transformation matrix in to the specified buffer.
	  [a c e]
	  [b d f]
	  [0 0 1]
	There should be space for 6 floats in the return buffer for the values a-f.
*/
CurrentTransform :: proc(ctx: ^Context, xform: ^Matrix) {
	if xform == nil {
		return
	}
	state := __getState(ctx)
	xform^ = state.xform
}

///////////////////////////////////////////////////////////
// IMAGE HANDLING
//
// NanoVG allows you to load jpg, png, psd, tga, pic and gif files to be used for rendering.
// In addition you can upload your own image. The image loading is provided by stb_image.
// The parameter imageFlags is a combination of flags defined in NVGimageFlags.
///////////////////////////////////////////////////////////

// Creates image by loading it from the disk from specified file name.
// Returns handle to the image.
CreateImagePath :: proc(ctx: ^Context, filename: cstring, imageFlags: ImageFlags) -> int {
	stbi.set_unpremultiply_on_load(1)
	stbi.convert_iphone_png_to_rgb(1)
	w, h, n: i32
	img := stbi.load(filename, &w, &h, &n, 4)
	
	if img == nil {
		return 0
	}

	data  := img[:int(w) * int(h) * int(n)]
	image := CreateImageRGBA(ctx, int(w), int(h), imageFlags, data)
	stbi.image_free(img)
	return image
}

// Creates image by loading it from the specified chunk of memory.
// Returns handle to the image.
CreateImageMem :: proc(ctx: ^Context, data: []byte, imageFlags: ImageFlags) -> int {
	stbi.set_unpremultiply_on_load(1)
	stbi.convert_iphone_png_to_rgb(1)
	w, h, n: i32
	img := stbi.load_from_memory(raw_data(data), i32(len(data)), &w, &h, &n, 4)
	
	if img == nil {
		return 0
	}

	pixel_data := img[:int(w) * int(h) * int(n)]
	image := CreateImageRGBA(ctx, int(w), int(h), imageFlags, pixel_data)
	stbi.image_free(img)
	return image
}

CreateImage :: proc{CreateImagePath, CreateImageMem}

// Creates image from specified image data.
// Returns handle to the image.
CreateImageRGBA :: proc(ctx: ^Context, w, h: int, imageFlags: ImageFlags, data: []byte) -> int {
	assert(ctx.params.renderCreateTexture != nil)
	return ctx.params.renderCreateTexture(
		ctx.params.userPtr,
		.RGBA,
		w, h,
		imageFlags,
		data,
	)
}

// Updates image data specified by image handle.
UpdateImage :: proc(ctx: ^Context, image: int, data: []byte) {
	assert(ctx.params.renderGetTextureSize != nil)
	assert(ctx.params.renderUpdateTexture != nil)
	
	w, h: int
	found := ctx.params.renderGetTextureSize(ctx.params.userPtr, image, &w, &h)
	if found {
		ctx.params.renderUpdateTexture(ctx.params.userPtr, image, 0, 0, w, h, data)
	}
}

// Returns the dimensions of a created image.
ImageSize :: proc(ctx: ^Context, image: int) -> (w, h: int) {
	assert(ctx.params.renderGetTextureSize != nil)
	ctx.params.renderGetTextureSize(ctx.params.userPtr, image, &w, &h)
	return
}

// Deletes created image.
DeleteImage :: proc(ctx: ^Context, image: int) {
	assert(ctx.params.renderDeleteTexture != nil)
	ctx.params.renderDeleteTexture(ctx.params.userPtr, image)
}

///////////////////////////////////////////////////////////
// PAINT gradients / image
//
// NanoVG supports four types of paints: linear gradient, box gradient, radial gradient and image pattern.
// These can be used as paints for strokes and fills.
///////////////////////////////////////////////////////////

/*
	Creates and returns a linear gradient. Parameters (sx,sy)-(ex,ey) specify the start and end coordinates
	of the linear gradient, icol specifies the start color and ocol the end color.
	The gradient is transformed by the current transform when it is passed to nvgFillPaint() or nvgStrokePaint().
*/
LinearGradient :: proc(
	sx, sy: f32,
	ex, ey: f32,
	icol:   Color,
	ocol:   Color,
) -> (p: Paint) {
	LARGE :: f32(1e5)

	// Calculate transform aligned to the line
	dx := ex - sx
	dy := ey - sy
	d := math.sqrt(dx*dx + dy*dy)
	if d > 0.0001 {
		dx /= d
		dy /= d
	} else {
		dx = 0
		dy = 1
	}

	p.xform[0] = dy
	p.xform[1] = -dx
	p.xform[2] = dx
	p.xform[3] = dy
	p.xform[4] = sx - dx*LARGE
	p.xform[5] = sy - dy*LARGE

	p.extent[0] = LARGE
	p.extent[1] = LARGE + d*0.5

	p.feather = max(1.0, d)

	p.innerColor = icol
	p.outerColor = ocol

	return
}

/*
	Creates and returns a box gradient. Box gradient is a feathered rounded rectangle, it is useful for rendering
	drop shadows or highlights for boxes. Parameters (x,y) define the top-left corner of the rectangle,
	(w,h) define the size of the rectangle, r defines the corner radius, and f feather. Feather defines how blurry
	the border of the rectangle is. Parameter icol specifies the inner color and ocol the outer color of the gradient.
	The gradient is transformed by the current transform when it is passed to nvgFillPaint() or nvgStrokePaint().
*/
RadialGradient :: proc(
	cx, cy: f32,
	inr:    f32,
	outr:   f32,
	icol:   Color,
	ocol:   Color,
) -> (p: Paint) {
	r := (inr+outr)*0.5
	f := (outr-inr)

	TransformIdentity(&p.xform)
	p.xform[4] = cx
	p.xform[5] = cy

	p.extent[0] = r
	p.extent[1] = r

	p.radius = r
	p.feather = max(1.0, f)

	p.innerColor = icol
	p.outerColor = ocol

	return 
}

/*
	Creates and returns a radial gradient. Parameters (cx,cy) specify the center, inr and outr specify
	the inner and outer radius of the gradient, icol specifies the start color and ocol the end color.
	The gradient is transformed by the current transform when it is passed to nvgFillPaint() or nvgStrokePaint().
*/
BoxGradient :: proc(
	x, y: f32,
	w, h: f32,
	r:    f32,
	f:    f32,
	icol: Color,
	ocol: Color,
) -> (p: Paint) {
	TransformIdentity(&p.xform)
	p.xform[4] = x+w*0.5
	p.xform[5] = y+h*0.5

	p.extent[0] = w*0.5
	p.extent[1] = h*0.5

	p.radius = r
	p.feather = max(1.0, f)

	p.innerColor = icol
	p.outerColor = ocol

	return 
}

/*
	Creates and returns an image pattern. Parameters (ox,oy) specify the left-top location of the image pattern,
	(ex,ey) the size of one image, angle rotation around the top-left corner, image is handle to the image to render.
	The gradient is transformed by the current transform when it is passed to nvgFillPaint() or nvgStrokePaint().
*/
ImagePattern :: proc(
	cx, cy: f32,
	w, h:   f32,
	angle:  f32,
	image:  int,
	alpha:  f32,
) -> (p: Paint) {
	TransformRotate(&p.xform, angle)
	p.xform[4] = cx
	p.xform[5] = cy

	p.extent[0] = w
	p.extent[1] = h

	p.image = image
	p.innerColor = {1, 1, 1, alpha}
	p.outerColor = p.innerColor

	return
}

///////////////////////////////////////////////////////////
// SCISSOR
//
// Scissoring allows you to clip the rendering into a rectangle. This is useful for various
// user interface cases like rendering a text edit or a timeline.
///////////////////////////////////////////////////////////

// Sets the current scissor rectangle.
// The scissor rectangle is transformed by the current transform.
Scissor :: proc(
	ctx:           ^Context,
	x, y:          f32,
	width, height: f32,
) {
	state := __getState(ctx)
	w := max(width, 0)
	h := max(height, 0)
	
	TransformIdentity(&state.scissor.xform)
	state.scissor.xform[4] = x + w * 0.5
	state.scissor.xform[5] = y + h * 0.5
	TransformMultiply(&state.scissor.xform, state.xform)

	state.scissor.extent[0] = w * 0.5
	state.scissor.extent[1] = h * 0.5
}

/*
	Intersects current scissor rectangle with the specified rectangle.
	The scissor rectangle is transformed by the current transform.
	Note: in case the rotation of previous scissor rect differs from
	the current one, the intersection will be done between the specified
	rectangle and the previous scissor rectangle transformed in the current
	transform space. The resulting shape is always rectangle.
*/
IntersectScissor :: proc(
	ctx:        ^Context,
	x, y, w, h: f32,
) {
	isect_rects :: proc(
		dst:            ^[4]f32,
		ax, ay, aw, ah: f32,
		bx, by, bw, bh: f32,
	) {
		minx := max(ax, bx)
		miny := max(ay, by)
		maxx := min(ax + aw, bx + bw)
		maxy := min(ay + ah, by + bh)
		dst[0] = minx
		dst[1] = miny
		dst[2] = max(0.0, maxx - minx)
		dst[3] = max(0.0, maxy - miny)
	}

	state := __getState(ctx)

	// If no previous scissor has been set, set the scissor as current scissor.
	if state.scissor.extent[0] < 0 {
		Scissor(ctx, x, y, w, h)
		return
	}

	pxform := state.scissor.xform
	ex := state.scissor.extent[0]
	ey := state.scissor.extent[1]

	invxorm: Matrix
	TransformInverse(&invxorm, state.xform)
	TransformMultiply(&pxform, invxorm)
	tex := ex * abs(pxform[0]) + ey * abs(pxform[2])
	tey := ex * abs(pxform[1]) + ey * abs(pxform[3])
	
	rect: [4]f32
	isect_rects(&rect, pxform[4] - tex, pxform[5] - tey, tex * 2, tey * 2, x,y,w,h)
	Scissor(ctx, rect.x, rect.y, rect.z, rect.w)
}

// Reset and disables scissoring.
ResetScissor :: proc(ctx: ^Context) {
	state := __getState(ctx)
	state.scissor.xform = 0
	state.scissor.extent[0] = -1
	state.scissor.extent[1] = -1
}

///////////////////////////////////////////////////////////
// Global composite operation
//
// The composite operations in NanoVG are modeled after HTML Canvas API, and
// the blend func is based on OpenGL (see corresponding manuals for more info).
// The colors in the blending state have premultiplied alpha.
///////////////////////////////////////////////////////////

// state table instead of if else chains
OP_STATE_TABLE := [CompositeOperation][2]BlendFactor {
	.SOURCE_OVER = {.ONE,                  .ONE_MINUS_SRC_ALPHA},
	.SOURCE_IN   = {.DST_ALPHA,           .ZERO},
	.SOURCE_OUT  = {.ONE_MINUS_DST_ALPHA, .ZERO},
	.ATOP        = {.DST_ALPHA,           .ONE_MINUS_SRC_ALPHA},

	.DESTINATION_OVER = {.ONE_MINUS_DST_ALPHA, .ONE},
	.DESTINATION_IN   = {.ZERO,                .SRC_ALPHA},
	.DESTINATION_OUT  = {.ZERO,                .ONE_MINUS_SRC_ALPHA},
	.DESTINATION_ATOP = {.ONE_MINUS_DST_ALPHA, .SRC_ALPHA},

	.LIGHTER = {.ONE,                 .ONE},
	.COPY    = {.ONE,                 .ZERO},
	.XOR     = {.ONE_MINUS_DST_ALPHA, .ONE_MINUS_SRC_ALPHA},
}

__compositeOperationState :: proc(op: CompositeOperation) -> (res: CompositeOperationState) {
	factors := OP_STATE_TABLE[op]
	res.srcRGB   = factors.x
	res.dstRGB   = factors.y
	res.srcAlpha = factors.x
	res.dstAlpha = factors.y
	return
}

// Sets the composite operation. The op parameter should be one of NVGcompositeOperation.
GlobalCompositeOperation :: proc(ctx: ^Context, op: CompositeOperation) {
	state := __getState(ctx)
	state.compositeOperation = __compositeOperationState(op)
}

// Sets the composite operation with custom pixel arithmetic. The parameters should be one of NVGblendFactor.
GlobalCompositeBlendFunc :: proc(ctx: ^Context, sfactor, dfactor: BlendFactor) {
	GlobalCompositeBlendFuncSeparate(ctx, sfactor, dfactor, sfactor, dfactor)
}

// Sets the composite operation with custom pixel arithmetic for RGB and alpha components separately. The parameters should be one of NVGblendFactor.
GlobalCompositeBlendFuncSeparate :: proc(
	ctx:      ^Context,
	srcRGB:   BlendFactor,
	dstRGB:   BlendFactor,
	srcAlpha: BlendFactor,
	dstAlpha: BlendFactor,
) {
	state := __getState(ctx)
	state.compositeOperation = CompositeOperationState{
		srcRGB,
		dstRGB,
		srcAlpha,
		dstAlpha,
	}
}

///////////////////////////////////////////////////////////
// Points / Path handling
///////////////////////////////////////////////////////////

__cross :: proc(dx0, dy0, dx1, dy1: f32) -> f32 {
	return dx1*dy0 - dx0*dy1
}

__ptEquals :: proc(x1, y1, x2, y2, tol: f32) -> bool {
	dx := x2 - x1
	dy := y2 - y1
	return dx * dx + dy * dy < tol * tol
}

__distPtSeg :: proc(x, y, px, py, qx, qy: f32) -> f32 {
	pqx := qx - px
	pqy := qy - py
	dx := x - px
	dy := y - py
	d := pqx * pqx + pqy * pqy
	t := pqx * dx + pqy * dy
	
	if d > 0 {
		t /= d
	}
	t = clamp(t, 0, 1)

	dx = px + t * pqx - x
	dy = py + t * pqy - y
	return dx * dx + dy * dy
}

__appendCommands :: proc(ctx: ^Context, values: ..f32) {
	state := __getState(ctx)

	if Commands(values[0]) != .CLOSE && Commands(values[0]) != .WINDING {
		ctx.commandx = values[len(values)-2]
		ctx.commandy = values[len(values)-1]
	}
	for i := 0; i < len(values); /**/ {
		cmd := Commands(values[i])

		switch cmd {
		case .MOVE_TO, .LINE_TO:
			TransformPoint(&values[i+1], &values[i+2], state.xform, values[i+1], values[i+2])
			i += 3
		case .BEZIER_TO:
			TransformPoint(&values[i+1], &values[i+2], state.xform, values[i+1], values[i+2])
			TransformPoint(&values[i+3], &values[i+4], state.xform, values[i+3], values[i+4])
			TransformPoint(&values[i+5], &values[i+6], state.xform, values[i+5], values[i+6])
			i += 7
		case .CLOSE:
			i += 1
		case .WINDING:
			i += 2
		case:
			i += 1
		}
	}

	// append values
	append(&ctx.commands, ..values)
}

__clearPathCache :: proc(ctx: ^Context) {
	clear(&ctx.cache.points)
	clear(&ctx.cache.paths)
}

__lastPath :: proc(ctx: ^Context) -> ^Path {
	if len(ctx.cache.paths) > 0 {
		return &ctx.cache.paths[len(ctx.cache.paths)-1]
	}

	return nil
}

__addPath :: proc(ctx: ^Context) {
	append(&ctx.cache.paths, Path{
		first   = len(ctx.cache.points),
		winding = .CCW,
	})
}

__lastPoint :: proc(ctx: ^Context) -> ^Point {
	if len(ctx.cache.paths) > 0 {
		return &ctx.cache.points[len(ctx.cache.points)-1]
	}

	return nil
}

__addPoint :: proc(ctx: ^Context, x, y: f32, flags: PointFlags) {
	path := __lastPath(ctx)

	if path == nil {
		return
	}

	if path.count > 0 && len(ctx.cache.points) > 0 {
		pt := __lastPoint(ctx)

		if __ptEquals(pt.x, pt.y, x, y, ctx.distTol) {
			pt.flags |= flags
			return
		}
	}

	append(&ctx.cache.points, Point{
		x = x,
		y = y,
		flags = flags,
	})
	path.count += 1
}

__closePath :: proc(ctx: ^Context) {
	path := __lastPath(ctx)
	if path == nil {
		return
	}
	path.closed = true
}

__pathWinding :: proc(ctx: ^Context, winding: Winding) {
	path := __lastPath(ctx)
	if path == nil {
		return
	}
	path.winding = winding
}

__getAverageScale :: proc(t: []f32) -> f32 {
	assert(len(t) > 4)
	sx := math.sqrt(f64(t[0]) * f64(t[0]) + f64(t[2]) * f64(t[2]))
	sy := math.sqrt(f64(t[1]) * f64(t[1]) + f64(t[3]) * f64(t[3]))
	return f32((sx + sy) * 0.5)
	// sx := math.sqrt(t[0] * t[0] + t[2] * t[2])
	// sy := math.sqrt(t[1] * t[1] + t[3] * t[3])
	// return (sx + sy) * 0.5
}

__triarea2 :: proc(ax, ay, bx, by, cx, cy: f32) -> f32 {
	abx := bx - ax
	aby := by - ay
	acx := cx - ax
	acy := cy - ay
	return acx * aby - abx * acy
}

__polyArea :: proc(points: []Point) -> f32 {
	area := f32(0)
	
	for i := 2; i < len(points); i += 1 {
		a := &points[0]
		b := &points[i-1]
		c := &points[i]
		area += __triarea2(a.x, a.y, b.x, b.y, c.x, c.y)
	}
	
	return area * 0.5
}

__polyReverse :: proc(points: []Point) {
	tmp: Point
	i := 0 
	j := len(points) - 1
	
	for i < j {
		tmp = points[i]
		points[i] = points[j]
		points[j] = tmp
		i += 1
		j -= 1
	}
}

__normalize :: proc(x, y: ^f32) -> f32 {
	d := math.sqrt(x^ * x^ + y^ * y^)
	if d > 1e-6 {
		id := 1.0 / d
		x^ *= id
		y^ *= id
	}
	return d
}

__tesselateBezier :: proc(
	ctx:    ^Context,
	x1, y1: f32,
	x2, y2: f32,
	x3, y3: f32,
	x4, y4: f32,
	level:  int,
	flags:  PointFlags,
) {
	if level > 10 {
		return
	}

	x12  := (x1  + x2)  * 0.5
	y12  := (y1  + y2)  * 0.5
	x23  := (x2  + x3)  * 0.5
	y23  := (y2  + y3)  * 0.5
	x34  := (x3  + x4)  * 0.5
	y34  := (y3  + y4)  * 0.5
	x123 := (x12 + x23) * 0.5
	y123 := (y12 + y23) * 0.5

	dx := x4 - x1
	dy := y4 - y1
	d2 := abs(((x2 - x4) * dy - (y2 - y4) * dx))
	d3 := abs(((x3 - x4) * dy - (y3 - y4) * dx))

	if (d2 + d3)*(d2 + d3) < ctx.tessTol * (dx*dx + dy*dy) {
		__addPoint(ctx, x4, y4, flags)
		return
	}

	x234  := (x23  + x34)  * 0.5
	y234  := (y23  + y34)  * 0.5
	x1234 := (x123 + x234) * 0.5
	y1234 := (y123 + y234) * 0.5

	__tesselateBezier(ctx, x1,y1, x12,y12, x123,y123, x1234,y1234, level+1, {})
	__tesselateBezier(ctx, x1234,y1234, x234,y234, x34,y34, x4,y4, level+1, flags)
}

__flattenPaths :: proc(ctx: ^Context) {
	cache := &ctx.cache

	if len(cache.paths) > 0 {
		return
	}

	// flatten
	i := 0
	for i < len(ctx.commands) {
		cmd := Commands(ctx.commands[i])
		
		switch cmd {
		case .MOVE_TO:
			__addPath(ctx)
			p := ctx.commands[i + 1:]
			__addPoint(ctx, p[0], p[1], {.CORNER})
			i += 3

		case .LINE_TO:
			p := ctx.commands[i + 1:]
			__addPoint(ctx, p[0], p[1], {.CORNER})
			i += 3

		case .BEZIER_TO:
			if last := __lastPoint(ctx); last != nil {
				cp1 := ctx.commands[i + 1:]
				cp2 := ctx.commands[i + 3:]
				p := ctx.commands[i + 5:]
				__tesselateBezier(ctx, last.x,last.y, cp1[0],cp1[1], cp2[0],cp2[1], p[0],p[1], 0, {.CORNER})
			}

			i += 7

		case .CLOSE:
			__closePath(ctx)
			i += 1

		case .WINDING:
			__pathWinding(ctx, Winding(ctx.commands[i + 1]))
			i += 2

		case: i += 1
		}
	}

	cache.bounds[0] = 1e6
	cache.bounds[1] = 1e6
	cache.bounds[2] = -1e6
	cache.bounds[3] = -1e6

	// Calculate the direction and length of line segments.
	for &path in cache.paths {
		pts := cache.points[path.first:]

		// If the first and last points are the same, remove the last, mark as closed path.
		p0 := &pts[path.count-1]
		p1 := &pts[0]
		if __ptEquals(p0.x,p0.y, p1.x,p1.y, ctx.distTol) {
			path.count -= 1
			p0 = &pts[path.count-1]
			path.closed = true
		}

		// enforce winding
		if path.count > 2 {
			area := __polyArea(pts[:path.count])
			
			if path.winding == .CCW && area < 0 {
				__polyReverse(pts[:path.count])
			}
			
			if path.winding == .CW && area > 0 {
				__polyReverse(pts[:path.count])
			}
		}

		for _ in 0..<path.count {
			// Calculate segment direction and length
			p0.dx = p1.x - p0.x
			p0.dy = p1.y - p0.y
			p0.len = __normalize(&p0.dx, &p0.dy)
			
			// Update bounds
			cache.bounds[0] = min(cache.bounds[0], p0.x)
			cache.bounds[1] = min(cache.bounds[1], p0.y)
			cache.bounds[2] = max(cache.bounds[2], p0.x)
			cache.bounds[3] = max(cache.bounds[3], p0.y)
			
			// Advance
			p0 = p1
			p1 = mem.ptr_offset(p1, 1)
		}
	}
}

__curveDivs :: proc(r, arc, tol: f32) -> f32 {
	da := math.acos(r / (r + tol)) * 2
	return max(2, math.ceil(arc / da))
}

__chooseBevel :: proc(
	bevel: bool,
	p0: ^Point,
	p1: ^Point,
	w: f32,
	x0, y0, x1, y1: ^f32,
) {
	if bevel {
		x0^ = p1.x + p0.dy * w
		y0^ = p1.y - p0.dx * w
		x1^ = p1.x + p1.dy * w
		y1^ = p1.y - p1.dx * w
	} else {
		x0^ = p1.x + p1.dmx * w
		y0^ = p1.y + p1.dmy * w
		x1^ = p1.x + p1.dmx * w
		y1^ = p1.y + p1.dmy * w
	}
}

///////////////////////////////////////////////////////////
// Vertice Setting
///////////////////////////////////////////////////////////

// set vertex & increase slice position (decreases length)
__vset :: proc(dst: ^[]Vertex, x, y, u, v: f32, loc := #caller_location) {
	dst[0] = {x, y, u, v}
	dst^ = dst[1:]
}

__roundJoin :: proc(
	dst:    ^[]Vertex,
	p0, p1: ^Point,
	lw, rw: f32,
	lu,ru:  f32,
	ncap:   int,
) {
	dlx0, dly0 := p0.dy, -p0.dx
	dlx1, dly1 := p1.dy, -p1.dx

	if .LEFT in p1.flags {
		lx0,ly0,lx1,ly1: f32
		__chooseBevel(.INNER_BEVEL in p1.flags, p0, p1, lw, &lx0,&ly0, &lx1,&ly1)
		a0 := math.atan2(-dly0, -dlx0)
		a1 := math.atan2(-dly1, -dlx1)
		
		if a1 > a0 {
			a1 -= math.PI * 2
		} 

		__vset(dst, lx0, ly0, lu, 1)
		__vset(dst, p1.x - dlx0 * rw, p1.y - dly0 * rw, ru, 1)

		temp := int(math.ceil((a0 - a1) / math.PI * f32(ncap)))
		n := clamp(temp, 2, ncap)

		for i := 0; i < n; i += 1 {
			u := f32(i) / f32(n - 1)
			a := a0 + u * (a1 - a0)
			rx := p1.x + math.cos(a) * rw
			ry := p1.y + math.sin(a) * rw
			__vset(dst, p1.x, p1.y, 0.5, 1)
			__vset(dst, rx, ry, ru, 1)
		}

		__vset(dst, lx1, ly1, lu, 1)
		__vset(dst, p1.x - dlx1*rw, p1.y - dly1*rw, ru, 1)
	} else {
		rx0,ry0,rx1,ry1: f32
		__chooseBevel(.INNER_BEVEL in p1.flags, p0, p1, -rw, &rx0, &ry0, &rx1, &ry1)
		a0 := math.atan2(dly0, dlx0)
		a1 := math.atan2(dly1, dlx1)
		if a1 < a0 {
			a1 += math.PI * 2
		}

		__vset(dst, p1.x + dlx0*rw, p1.y + dly0*rw, lu, 1)
		__vset(dst, rx0, ry0, ru, 1)

		temp := int(math.ceil((a1 - a0) / math.PI * f32(ncap)))
		n := clamp(temp, 2, ncap)

		for i := 0; i < n; i += 1 {
			u := f32(i) / f32(n - 1)
			a := a0 + u*(a1-a0)
			lx := p1.x + math.cos(a) * lw
			ly := p1.y + math.sin(a) * lw
			__vset(dst, lx, ly, lu, 1)
			__vset(dst, p1.x, p1.y, 0.5, 1)
		}

		__vset(dst, p1.x + dlx1*rw, p1.y + dly1*rw, lu, 1)
		__vset(dst, rx1, ry1, ru, 1)
	}
}

__bevelJoin :: proc(
	dst:    ^[]Vertex,
	p0, p1: ^Point,
	lw, rw: f32,
	lu, ru: f32,
) {
	dlx0,dly0  := p0.dy, -p0.dx
	dlx1, dly1 := p1.dy, -p1.dx

	rx0, ry0, rx1, ry1: f32
	lx0, ly0, lx1, ly1: f32

	if .LEFT in p1.flags {
		__chooseBevel(.INNER_BEVEL in p1.flags, p0, p1, lw, &lx0,&ly0, &lx1,&ly1)

		__vset(dst, lx0, ly0, lu, 1)
		__vset(dst, p1.x - dlx0*rw, p1.y - dly0*rw, ru, 1)

		if .BEVEL in p1.flags {
			__vset(dst, lx0, ly0, lu, 1)
			__vset(dst, p1.x - dlx0*rw, p1.y - dly0*rw, ru, 1)

			__vset(dst, lx1, ly1, lu, 1)
			__vset(dst, p1.x - dlx1*rw, p1.y - dly1*rw, ru, 1)
		} else {
			rx0 = p1.x - p1.dmx * rw
			ry0 = p1.y - p1.dmy * rw

			__vset(dst, p1.x, p1.y, 0.5, 1)
			__vset(dst, p1.x - dlx0*rw, p1.y - dly0*rw, ru, 1)

			__vset(dst, rx0, ry0, ru, 1)
			__vset(dst, rx0, ry0, ru, 1)

			__vset(dst, p1.x, p1.y, 0.5, 1)
			__vset(dst, p1.x - dlx1*rw, p1.y - dly1*rw, ru, 1)
		}

		__vset(dst, lx1, ly1, lu, 1)
		__vset(dst, p1.x - dlx1*rw, p1.y - dly1*rw, ru, 1)
	} else {
		__chooseBevel(.INNER_BEVEL in p1.flags, p0, p1, -rw, &rx0,&ry0, &rx1,&ry1)

		__vset(dst, p1.x + dlx0*lw, p1.y + dly0*lw, lu, 1)
		__vset(dst, rx0, ry0, ru, 1)

		if .BEVEL in p1.flags {
			__vset(dst, p1.x + dlx0*lw, p1.y + dly0*lw, lu, 1)
			__vset(dst, rx0, ry0, ru, 1)

			__vset(dst, p1.x + dlx1*lw, p1.y + dly1*lw, lu, 1)
			__vset(dst, rx1, ry1, ru, 1)
		} else {
			lx0 = p1.x + p1.dmx * lw
			ly0 = p1.y + p1.dmy * lw

			__vset(dst, p1.x + dlx0*lw, p1.y + dly0*lw, lu, 1)
			__vset(dst, p1.x, p1.y, 0.5, 1)

			__vset(dst, lx0, ly0, lu, 1)
			__vset(dst, lx0, ly0, lu, 1)

			__vset(dst, p1.x + dlx1*lw, p1.y + dly1*lw, lu, 1)
			__vset(dst, p1.x, p1.y, 0.5, 1)
		}

		__vset(dst, p1.x + dlx1*lw, p1.y + dly1*lw, lu, 1)
		__vset(dst, rx1, ry1, ru, 1)
	}
}

__buttCapStart :: proc(
	dst:    ^[]Vertex,
	p:      ^Point,
	dx, dy: f32,
	w:      f32,
	d:      f32,
	aa:     f32,
	u0:     f32,
	u1:     f32,
) {
	px := p.x - dx * d
	py := p.y - dy * d
	dlx := dy
	dly := -dx
	__vset(dst, px + dlx*w - dx*aa, py + dly*w - dy*aa, u0,0)
	__vset(dst, px - dlx*w - dx*aa, py - dly*w - dy*aa, u1,0)
	__vset(dst, px + dlx*w, py + dly*w, u0,1)
	__vset(dst, px - dlx*w, py - dly*w, u1,1)
}

__buttCapEnd :: proc(
	dst:    ^[]Vertex,
	p:      ^Point,
	dx, dy: f32,
	w:      f32,
	d:      f32,
	aa:     f32,
	u0:     f32,
	u1:     f32,
) {
	px := p.x + dx * d
	py := p.y + dy * d
	dlx := dy
	dly := -dx
	__vset(dst, px + dlx*w, py + dly*w, u0,1)
	__vset(dst, px - dlx*w, py - dly*w, u1,1)
	__vset(dst, px + dlx*w + dx*aa, py + dly*w + dy*aa, u0,0)
	__vset(dst, px - dlx*w + dx*aa, py - dly*w + dy*aa, u1,0)
}

__roundCapStart :: proc(
	dst:    ^[]Vertex,
	p:      ^Point,
	dx, dy: f32,
	w:      f32,
	ncap:   int,
	u0:     f32,
	u1:     f32,
) {
	px := p.x
	py := p.y
	dlx := dy
	dly := -dx

	for i in 0..<ncap {
		a := f32(i) / f32(ncap-1) * math.PI
		ax := math.cos(a) * w
		ay := math.sin(a) * w
		__vset(dst, px - dlx*ax - dx*ay, py - dly*ax - dy*ay, u0,1)
		__vset(dst, px, py, 0.5, 1)
	}

	__vset(dst, px + dlx*w, py + dly*w, u0,1)
	__vset(dst, px - dlx*w, py - dly*w, u1,1)
}

__roundCapEnd :: proc(
	dst:    ^[]Vertex,
	p:      ^Point,
	dx, dy: f32,
	w:      f32,
	ncap:   int,
	u0:     f32,
	u1:     f32,
) {
	px := p.x
	py := p.y
	dlx := dy
	dly := -dx

	__vset(dst, px + dlx*w, py + dly*w, u0,1)
	__vset(dst, px - dlx*w, py - dly*w, u1,1)
	for i in 0..<ncap {
		a := f32(i) / f32(ncap - 1) * math.PI
		ax := math.cos(a) * w
		ay := math.sin(a) * w
		__vset(dst, px, py, 0.5, 1)
		__vset(dst, px - dlx*ax + dx*ay, py - dly*ax + dy*ay, u0,1)
	}
}

__calculateJoins :: proc(
	ctx:        ^Context,
	w:          f32,
	lineJoin:   LineCapType,
	miterLimit: f32,
) {
	cache := &ctx.cache
	iw := f32(0)

	if w > 0 {
		iw = 1.0 / w
	} 

	// Calculate which joins needs extra vertices to append, and gather vertex count.
	for &path in cache.paths {
		pts := cache.points[path.first:]
		p0  := &pts[path.count-1]
		p1  := &pts[0]
		nleft := 0
		path.nbevel = 0

		for _ in 0..<path.count {
			dlx0, dly0, dlx1, dly1, dmr2, __cross, limit: f32
			dlx0 = p0.dy
			dly0 = -p0.dx
			dlx1 = p1.dy
			dly1 = -p1.dx
			// Calculate extrusions
			p1.dmx = (dlx0 + dlx1) * 0.5
			p1.dmy = (dly0 + dly1) * 0.5
			dmr2 = p1.dmx*p1.dmx + p1.dmy*p1.dmy
			if dmr2 > 0.000001 {
				scale := 1.0 / dmr2
				if scale > 600.0 {
					scale = 600.0
				}
				p1.dmx *= scale
				p1.dmy *= scale
			}

			// Clear flags, but keep the corner.
			p1.flags = {.CORNER} if .CORNER in p1.flags else nil

			// Keep track of left turns.
			__cross = p1.dx * p0.dy - p0.dx * p1.dy
			if __cross > 0.0 {
				nleft += 1
				p1.flags += {.LEFT}
			}

			// Calculate if we should use bevel or miter for inner join.
			limit = max(1.01, min(p0.len, p1.len) * iw)
			if (dmr2 * limit * limit) < 1.0 {
				p1.flags += {.INNER_BEVEL}
			}

			// Check to see if the corner needs to be beveled.
			if .CORNER in p1.flags {
				if (dmr2 * miterLimit*miterLimit) < 1.0 || lineJoin == .BEVEL || lineJoin == .ROUND {
					p1.flags += {.BEVEL}
				}
			}

			if (.BEVEL in p1.flags) || (.INNER_BEVEL in p1.flags) {
				path.nbevel += 1
			}

			p0 = p1
			p1 = mem.ptr_offset(p1, 1)
		}

		path.convex = nleft == path.count
	}
}

// TODO could be done better? or not need dynamic
__allocTempVerts :: proc(ctx: ^Context, nverts: int) -> []Vertex {
	resize(&ctx.cache.verts, nverts)
	return ctx.cache.verts[:]
}

__expandStroke :: proc(
	ctx:        ^Context,
	w:          f32,
	fringe:     f32,
	lineCap:    LineCapType,
	lineJoin:   LineCapType,
	miterLimit: f32,	
) -> bool {
	cache := &ctx.cache
	aa := fringe
	u0 := f32(0.0)
	u1 := f32(1.0)
	ncap := __curveDivs(w, math.PI, ctx.tessTol)	// Calculate divisions per half circle.

	w := w
	w += aa * 0.5

	// Disable the gradient used for antialiasing when antialiasing is not used.
	if aa == 0.0 {
		u0 = 0.5
		u1 = 0.5
	}

	__calculateJoins(ctx, w, lineJoin, miterLimit)

	// Calculate max vertex usage.
	cverts := 0
	for path in cache.paths {
		loop := path.closed
	
		// TODO check if f32 calculation necessary?	
		if lineJoin == .ROUND {
			cverts += (path.count + path.nbevel * int(ncap + 2) + 1) * 2 // plus one for loop
		} else {
			cverts += (path.count + path.nbevel*5 + 1) * 2 // plus one for loop
		}

		if !loop {
			// space for caps
			if lineCap == .ROUND {
				cverts += int(ncap*2 + 2)*2
			} else {
				cverts += (3 + 3)*2
			}
		}
	}

	verts := __allocTempVerts(ctx, cverts)
	dst_index: int

	for &path in cache.paths {
		pts := cache.points[path.first:]
		p0, p1: ^Point
		start, end: int
		dx, dy: f32

		// nil the fil
		path.fill = nil

		// Calculate fringe or stroke
		loop := path.closed
		dst := verts[dst_index:]
		dst_start_length := len(dst)

		if loop {
			// Looping
			p0 = &pts[path.count-1]
			p1 = &pts[0]
			start = 0
			end = path.count
		} else {
			// Add cap
			p0 = &pts[0]
			p1 = &pts[1]
			start = 1
			end = path.count - 1
		}

		if !loop {
			// Add cap
			dx = p1.x - p0.x
			dy = p1.y - p0.y
			__normalize(&dx, &dy)

			if lineCap == .BUTT {
				__buttCapStart(&dst, p0, dx, dy, w, -aa*0.5, aa, u0, u1)
			}	else if lineCap == .BUTT || lineCap == .SQUARE {
				__buttCapStart(&dst, p0, dx, dy, w, w-aa, aa, u0, u1)
			}	else if lineCap == .ROUND {
				__roundCapStart(&dst, p0, dx, dy, w, int(ncap), u0, u1)
			}
		}

		for _ in start..<end {
			// TODO check this
			// if ((p1.flags & (NVG_PT_BEVEL | NVG_PR_INNERBEVEL)) != 0) {
			if (.BEVEL in p1.flags) || (.INNER_BEVEL in p1.flags) {
				if lineJoin == .ROUND {
					__roundJoin(&dst, p0, p1, w, w, u0, u1, int(ncap))
				} else {
					__bevelJoin(&dst, p0, p1, w, w, u0, u1)
				}
			} else {
				__vset(&dst, p1.x + (p1.dmx * w), p1.y + (p1.dmy * w), u0, 1)
				__vset(&dst, p1.x - (p1.dmx * w), p1.y - (p1.dmy * w), u1, 1)
			}

			p0 = p1 
			p1 = mem.ptr_offset(p1, 1)
		}

		if loop {
			// NOTE use old vertices to loopback!
			// Loop it
			__vset(&dst, verts[dst_index + 0].x, verts[dst_index + 0].y, u0, 1)
			__vset(&dst, verts[dst_index + 1].x, verts[dst_index + 1].y, u1, 1)
		} else {
			// Add cap
			dx = p1.x - p0.x
			dy = p1.y - p0.y
			__normalize(&dx, &dy)

			if lineCap == .BUTT {
				__buttCapEnd(&dst, p1, dx, dy, w, -aa*0.5, aa, u0, u1)
			}	else if lineCap == .BUTT || lineCap == .SQUARE {
				__buttCapEnd(&dst, p1, dx, dy, w, w-aa, aa, u0, u1)
			}	else if lineCap == .ROUND {
				__roundCapEnd(&dst, p1, dx, dy, w, int(ncap), u0, u1)
			}
		}

		// count of vertices pushed
		dst_diff := dst_start_length - len(dst) 
		// set stroke to the new region
		path.stroke = verts[dst_index:dst_index + dst_diff]
		// move index for next iteration
		dst_index += dst_diff
	}

	return true
}

__expandFill :: proc(
	ctx:        ^Context,
	w:          f32,
	lineJoin:   LineCapType,
	miterLimit: f32,
) -> bool {
	cache := &ctx.cache
	aa := ctx.fringeWidth
	fringe := w > 0.0
	__calculateJoins(ctx, w, lineJoin, miterLimit)

	// Calculate max vertex usage.
	cverts := 0
	for path in cache.paths {
		cverts += path.count + path.nbevel + 1

		if fringe {
			cverts += (path.count + path.nbevel*5 + 1) * 2 // plus one for loop
		}
	}

	convex := len(cache.paths) == 1 && cache.paths[0].convex
	verts := __allocTempVerts(ctx, cverts)
	dst_index: int

	for &path in cache.paths {
		pts := cache.points[path.first:]
		p0, p1: ^Point
		rw, lw, woff: f32
		ru, lu: f32

		// Calculate shape vertices.
		woff = 0.5*aa
		dst := verts[dst_index:]
		dst_start_length := len(dst)

		if fringe {
			// Looping
			p0 = &pts[path.count-1]
			p1 = &pts[0]

			for _ in 0..<path.count {
				if .BEVEL in p1.flags {
					dlx0 := p0.dy
					dly0 := -p0.dx
					dlx1 := p1.dy
					dly1 := -p1.dx
					
					if .LEFT in p1.flags {
						lx := p1.x + p1.dmx * woff
						ly := p1.y + p1.dmy * woff
						__vset(&dst, lx, ly, 0.5, 1)
					} else {
						lx0 := p1.x + dlx0 * woff
						ly0 := p1.y + dly0 * woff
						lx1 := p1.x + dlx1 * woff
						ly1 := p1.y + dly1 * woff
						__vset(&dst, lx0, ly0, 0.5, 1)
						__vset(&dst, lx1, ly1, 0.5, 1)
					}
				} else {
					__vset(&dst, p1.x + (p1.dmx * woff), p1.y + (p1.dmy * woff), 0.5, 1)
				}

				p0 = p1
				p1 = mem.ptr_offset(p1, 1)
			}
		} else {
			for v in pts[:path.count] {
				__vset(&dst, v.x, v.y, 0.5, 1)
			}
		}

		dst_diff := dst_start_length - len(dst) 
		path.fill = verts[dst_index:dst_index + dst_diff]

		// advance
		dst_start_length = len(dst)
		dst_index += dst_diff

		// Calculate fringe
		if fringe {
			lw = w + woff
			rw = w - woff
			lu = 0
			ru = 1

			// Create only half a fringe for convex shapes so that
			// the shape can be rendered without stenciling.
			if convex {
				lw = woff	// This should generate the same vertex as fill inset above.
				lu = 0.5	// Set outline fade at middle.
			}

			// Looping
			p0 = &pts[path.count-1]
			p1 = &pts[0]

			for _ in 0..<path.count {
				if (.BEVEL in p1.flags) || (.INNER_BEVEL in p1.flags) {
					__bevelJoin(&dst, p0, p1, lw, rw, lu, ru)
				} else {
					__vset(&dst, p1.x + (p1.dmx * lw), p1.y + (p1.dmy * lw), lu, 1)
					__vset(&dst, p1.x - (p1.dmx * rw), p1.y - (p1.dmy * rw), ru, 1)
				}

				p0 = p1
				p1 = mem.ptr_offset(p1, 1)
			}

			// Loop it
			__vset(&dst, verts[dst_index + 0].x, verts[dst_index + 0].y, lu, 1)
			__vset(&dst, verts[dst_index + 1].x, verts[dst_index + 1].y, ru, 1)

			dst_diff = dst_start_length - len(dst) 
			path.stroke = verts[dst_index:dst_index + dst_diff]

			// advance
			dst_index += dst_diff
		} else {
			path.stroke = nil
		}
	}

	return true
}

///////////////////////////////////////////////////////////
// Paths
//
// Drawing a new shape starts with nvgBeginPath(), it clears all the currently defined paths.
// Then you define one or more paths and sub-paths which describe the shape. The are functions
// to draw common shapes like rectangles and circles, and lower level step-by-step functions,
// which allow to define a path curve by curve.
//
// NanoVG uses even-odd fill rule to draw the shapes. Solid shapes should have counter clockwise
// winding and holes should have counter clockwise order. To specify winding of a path you can
// call nvgPathWinding(). This is useful especially for the common shapes, which are drawn CCW.
//
// Finally you can fill the path using current fill style by calling nvgFill(), and stroke it
// with current stroke style by calling nvgStroke().
//
// The curve segments and sub-paths are transformed by the current transform.
///////////////////////////////////////////////////////////

// NOTE: helper to go from Command to f32
__cmdf :: #force_inline proc(cmd: Commands) -> f32 {
	return f32(cmd)
}

// Clears the current path and sub-paths.
BeginPath :: proc(ctx: ^Context) {
	clear(&ctx.commands)
	__clearPathCache(ctx)
}

@(deferred_in=Fill)
FillScoped :: proc(ctx: ^Context) {
	BeginPath(ctx)
}

@(deferred_in=Stroke)
StrokeScoped :: proc(ctx: ^Context) {
	BeginPath(ctx)
}

@(deferred_in=Stroke)
FillStrokeScoped :: proc(ctx: ^Context) {
	BeginPath(ctx)		
}

// Starts new sub-path with specified point as first point.
MoveTo :: proc(ctx: ^Context, x, y: f32) {
	__appendCommands(ctx, __cmdf(.MOVE_TO), x, y)
}

// Adds line segment from the last point in the path to the specified point.
LineTo :: proc(ctx: ^Context, x, y: f32) {
	__appendCommands(ctx, __cmdf(.LINE_TO), x, y)
}

// Adds cubic bezier segment from last point in the path via two control points to the specified point.
BezierTo :: proc(
	ctx: ^Context, 
	c1x, c1y: f32,
	c2x, c2y: f32,
	x, y: f32,
) {
	__appendCommands(ctx, __cmdf(.BEZIER_TO), c1x, c1y, c2x, c2y, x, y)
}

// Adds quadratic bezier segment from last point in the path via a control point to the specified point.
QuadTo :: proc(ctx: ^Context, cx, cy, x, y: f32) {
	x0 := ctx.commandx
	y0 := ctx.commandy
	__appendCommands(ctx,
		__cmdf(.BEZIER_TO),
		x0 + 2 / 3 * (cx - x0),
		y0 + 2 / 3 * (cy - y0),
		x  + 2 / 3 * (cx - x),
		y  + 2 / 3 * (cy - y),
		x,
		y,
	)
}

// Adds an arc segment at the corner defined by the last path point, and two specified points.
ArcTo :: proc(
	ctx: ^Context,
	x1, y1: f32,
	x2, y2: f32,
	radius: f32,
) {
	if len(ctx.commands) == 0 {
		return
	}

	x0 := ctx.commandx
	y0 := ctx.commandy
	// Handle degenerate cases.
	if __ptEquals(x0,y0, x1,y1, ctx.distTol) ||
		__ptEquals(x1,y1, x2,y2, ctx.distTol) ||
		__distPtSeg(x1,y1, x0,y0, x2,y2) < ctx.distTol*ctx.distTol ||
		radius < ctx.distTol {
		LineTo(ctx, x1, y1)
		return
	}

	// Calculate tangential circle to lines (x0,y0)-(x1,y1) and (x1,y1)-(x2,y2).
	dx0 := x0-x1
	dy0 := y0-y1
	dx1 := x2-x1
	dy1 := y2-y1
	__normalize(&dx0,&dy0)
	__normalize(&dx1,&dy1)
	a := math.acos(dx0*dx1 + dy0*dy1)
	d := radius / math.tan(a / 2.0)

	if d > 10000 {
		LineTo(ctx, x1, y1)
		return
	}

	a0, a1, cx, cy: f32
	direction: Winding

	if __cross(dx0,dy0, dx1,dy1) > 0.0 {
		cx = x1 + dx0*d + dy0*radius
		cy = y1 + dy0*d + -dx0*radius
		a0 = math.atan2(dx0, -dy0)
		a1 = math.atan2(-dx1, dy1)
		direction = .CW
	} else {
		cx = x1 + dx0*d + -dy0*radius
		cy = y1 + dy0*d + dx0*radius
		a0 = math.atan2(-dx0, dy0)
		a1 = math.atan2(dx1, -dy1)
		direction = .CCW
	}

	Arc(ctx, cx, cy, radius, a0, a1, direction)
}

// Creates new circle arc shaped sub-path. The arc center is at cx,cy, the arc radius is r,
// and the arc is drawn from angle a0 to a1, and swept in direction dir (NVG_CCW, or NVG_CW).
// Angles are specified in radians.
Arc :: proc(ctx: ^Context, cx, cy, r, a0, a1: f32, dir: Winding) {
	move: Commands = .LINE_TO if len(ctx.commands) > 0 else .MOVE_TO

	// Clamp angles
	da := a1 - a0
	if dir == .CW {
		if abs(da) >= math.PI*2 {
			da = math.PI*2
		} else {
			for da < 0.0 {
				da += math.PI*2
			}
		}
	} else {
		if abs(da) >= math.PI*2 {
			da = -math.PI*2
		} else {
			for da > 0.0 {
				da -= math.PI*2
			} 
		}
	}

	// Split arc into max 90 degree segments.
	ndivs := max(1, min((int)(abs(da) / (math.PI*0.5) + 0.5), 5))
	hda := (da / f32(ndivs)) / 2.0
	kappa := abs(4.0 / 3.0 * (1.0 - math.cos(hda)) / math.sin(hda))

	if dir == .CCW {
		kappa = -kappa
	}

	values: [3 + 5 * 7 + 100]f32
	nvals := 0

	px, py, ptanx, ptany: f32
	for i in 0..=ndivs {
		a := a0 + da * f32(i) / f32(ndivs)
		dx := math.cos(a)
		dy := math.sin(a)
		x := cx + dx*r
		y := cy + dy*r
		tanx := -dy*r*kappa
		tany := dx*r*kappa

		if i == 0 {
			values[nvals] = __cmdf(move); nvals += 1
			values[nvals] = x; nvals += 1
			values[nvals] = y; nvals += 1
		} else {
			values[nvals] = __cmdf(.BEZIER_TO); nvals += 1
			values[nvals] = px + ptanx; nvals += 1
			values[nvals] = py + ptany; nvals += 1
			values[nvals] = x-tanx; nvals += 1
			values[nvals] = y-tany; nvals += 1
			values[nvals] = x; nvals += 1
			values[nvals] = y; nvals += 1
		}
		px = x
		py = y
		ptanx = tanx
		ptany = tany
	}

	// stored internally
	__appendCommands(ctx, ..values[:nvals])
}

// Closes current sub-path with a line segment.
ClosePath :: proc(ctx: ^Context) {
	__appendCommands(ctx, __cmdf(.CLOSE))
}

// Sets the current sub-path winding, see NVGwinding and NVGsolidity.
PathWinding :: proc(ctx: ^Context, direction: Winding) {
	__appendCommands(ctx, __cmdf(.WINDING), f32(direction))
}

// same as path_winding but with different enum
PathSolidity :: proc(ctx: ^Context, solidity: Solidity) {
	__appendCommands(ctx, __cmdf(.WINDING), f32(solidity))
}

// Creates new rectangle shaped sub-path.
Rect :: proc(ctx: ^Context, x, y, w, h: f32) {
	__appendCommands(ctx,
		__cmdf(.MOVE_TO), x, y,
		__cmdf(.LINE_TO), x, y + h,
		__cmdf(.LINE_TO), x + w, y + h,
		__cmdf(.LINE_TO), x + w, y,
		__cmdf(.CLOSE),
	)
}

// Creates new rounded rectangle shaped sub-path.
RoundedRect :: proc(ctx: ^Context, x, y, w, h, radius: f32) {
	RoundedRectVarying(ctx, x, y, w, h, radius, radius, radius, radius)
}

// Creates new rounded rectangle shaped sub-path with varying radii for each corner.
RoundedRectVarying :: proc(
	ctx: ^Context,
	x, y: f32,
	w, h: f32,
	radius_top_left: f32,
	radius_top_right: f32,
	radius_bottom_right: f32,
	radius_bottom_left: f32,
) {
	if radius_top_left < 0.1 && radius_top_right < 0.1 && radius_bottom_right < 0.1 && radius_bottom_left < 0.1 {
		Rect(ctx, x, y, w, h)
	} else {
		halfw := abs(w) * 0.5
		halfh := abs(h) * 0.5
		rxBL  := min(radius_bottom_left, halfw) * math.sign(w)
		ryBL  := min(radius_bottom_left, halfh) * math.sign(h)
		rxBR  := min(radius_bottom_right, halfw) * math.sign(w)
		ryBR  := min(radius_bottom_right, halfh) * math.sign(h)
		rxTR  := min(radius_top_right, halfw) * math.sign(w)
		ryTR  := min(radius_top_right, halfh) * math.sign(h)
		rxTL  := min(radius_top_left, halfw) * math.sign(w)
		ryTL  := min(radius_top_left, halfh) * math.sign(h)
		__appendCommands(ctx,
			__cmdf(.MOVE_TO), x, y + ryTL,
			__cmdf(.LINE_TO), x, y + h - ryBL,
			__cmdf(.BEZIER_TO), x, y + h - ryBL*(1 - KAPPA), x + rxBL*(1 - KAPPA), y + h, x + rxBL, y + h,
			__cmdf(.LINE_TO), x + w - rxBR, y + h,
			__cmdf(.BEZIER_TO), x + w - rxBR*(1 - KAPPA), y + h, x + w, y + h - ryBR*(1 - KAPPA), x + w, y + h - ryBR,
			__cmdf(.LINE_TO), x + w, y + ryTR,
			__cmdf(.BEZIER_TO), x + w, y + ryTR*(1 - KAPPA), x + w - rxTR*(1 - KAPPA), y, x + w - rxTR, y,
			__cmdf(.LINE_TO), x + rxTL, y,
			__cmdf(.BEZIER_TO), x + rxTL*(1 - KAPPA), y, x, y + ryTL*(1 - KAPPA), x, y + ryTL,
			__cmdf(.CLOSE),
		)
	}
}

// Creates new ellipse shaped sub-path.
Ellipse :: proc(ctx: ^Context, cx, cy, rx, ry: f32) {
	__appendCommands(ctx,
		__cmdf(.MOVE_TO), cx-rx, cy,
		__cmdf(.BEZIER_TO), cx-rx, cy+ry*KAPPA, cx-rx*KAPPA, cy+ry, cx, cy+ry,
		__cmdf(.BEZIER_TO), cx+rx*KAPPA, cy+ry, cx+rx, cy+ry*KAPPA, cx+rx, cy,
		__cmdf(.BEZIER_TO), cx+rx, cy-ry*KAPPA, cx+rx*KAPPA, cy-ry, cx, cy-ry,
		__cmdf(.BEZIER_TO), cx-rx*KAPPA, cy-ry, cx-rx, cy-ry*KAPPA, cx-rx, cy,
		__cmdf(.CLOSE),
	)
}

// Creates new circle shaped sub-path.
Circle :: #force_inline proc(ctx: ^Context, cx, cy: f32, radius: f32) {
	Ellipse(ctx, cx, cy, radius, radius)
}

// Fills the current path with current fill style.
Fill :: proc(ctx: ^Context) {
	state := __getState(ctx)
	fill_paint := state.fill

	__flattenPaths(ctx)

	if ctx.params.edgeAntiAlias && state.shapeAntiAlias {
		__expandFill(ctx, ctx.fringeWidth, .MITER, 2.4)
	} else {
		__expandFill(ctx, 0, .MITER, 2.4)
	}

	// apply global alpha
	fill_paint.innerColor.a *= state.alpha
	fill_paint.outerColor.a *= state.alpha

	assert(ctx.params.renderFill != nil)
	ctx.params.renderFill(
		ctx.params.userPtr,
		&fill_paint,
		state.compositeOperation,
		&state.scissor,
		ctx.fringeWidth,
		ctx.cache.bounds,
		ctx.cache.paths[:],
	)

	for path in ctx.cache.paths {
		ctx.fillTriCount += len(path.fill) - 2
		ctx.fillTriCount += len(path.stroke) - 2
		ctx.drawCallCount += 2
	}
}

// Fills the current path with current stroke style.
Stroke :: proc(ctx: ^Context) {
	state := __getState(ctx)
	scale := __getAverageScale(state.xform[:])
	strokeWidth := clamp(state.strokeWidth * scale, 0, 200)
	stroke_paint := state.stroke

	if strokeWidth < ctx.fringeWidth {
		// If the stroke width is less than pixel size, use alpha to emulate coverage.
		// Since coverage is area, scale by alpha*alpha.
		alpha := clamp(strokeWidth / ctx.fringeWidth, 0, 1)
		stroke_paint.innerColor.a *= alpha * alpha
		stroke_paint.outerColor.a *= alpha * alpha
		strokeWidth = ctx.fringeWidth
	}

	// apply global alpha
	stroke_paint.innerColor.a *= state.alpha
	stroke_paint.outerColor.a *= state.alpha

	__flattenPaths(ctx)

	if ctx.params.edgeAntiAlias && state.shapeAntiAlias {
		__expandStroke(ctx, strokeWidth * 0.5, ctx.fringeWidth, state.lineCap, state.lineJoin, state.miterLimit)
	} else {
		__expandStroke(ctx, strokeWidth * 0.5, 0, state.lineCap, state.lineJoin, state.miterLimit)
	}	

	assert(ctx.params.renderStroke != nil)
	ctx.params.renderStroke(
		ctx.params.userPtr,
		&stroke_paint,
		state.compositeOperation,
		&state.scissor,
		ctx.fringeWidth,
		strokeWidth,
		ctx.cache.paths[:],
	)

	for path in ctx.cache.paths {
		ctx.strokeTriCount += len(path.stroke) - 2
		ctx.drawCallCount += 1
	}	
}

DebugDumpPathCache :: proc(ctx: ^Context) {
	fmt.printf("~~~~~~~~~~~~~Dumping %d cached paths\n", len(ctx.cache.paths))
	
	for path, i in ctx.cache.paths {
		fmt.printf(" - Path %d\n", i)
		
		if len(path.fill) != 0 {
			fmt.printf("   - fill: %d\n", len(path.fill))
			
			for v in path.fill {
				fmt.printf("%f\t%f\n", v.x, v.y)
			}
		}

		if len(path.stroke) != 0 {
			fmt.printf("   - stroke: %d\n", len(path.stroke))
			
			for v in path.stroke {
				fmt.printf("%f\t%f\n", v.x, v.y)
			}
		}
	}
}

///////////////////////////////////////////////////////////
// NanoVG allows you to load .ttf files and use the font to render text.
//
// The appearance of the text can be defined by setting the current text style
// and by specifying the fill color. Common text and font settings such as
// font size, letter spacing and text align are supported. Font blur allows you
// to create simple text effects such as drop shadows.
//
// At render time the font face can be set based on the font handles or name.
//
// Font measure functions return values in local space, the calculations are
// carried in the same resolution as the final rendering. This is done because
// the text glyph positions are snapped to the nearest pixels sharp rendering.
//
// The local space means that values are not rotated or scale as per the current
// transformation. For example if you set font size to 12, which would mean that
// line height is 16, then regardless of the current scaling and rotation, the
// returned line height is always 16. Some measures may vary because of the scaling
// since aforementioned pixel snapping.
//
// While this may sound a little odd, the setup allows you to always render the
// same way regardless of scaling. I.e. following works regardless of scaling:
//
//		const char* txt = "Text me up.";
//		nvgTextBounds(vg, x,y, txt, nil, bounds);
//		nvgBeginPath(vg);
//		nvgRoundedRect(vg, bounds[0],bounds[1], bounds[2]-bounds[0], bounds[3]-bounds[1]);
//		nvgFill(vg);
//
// Note: currently only solid color fill is supported for text.
///////////////////////////////////////////////////////////

// Creates font by loading it from the disk from specified file name.
// Returns handle to the font.
CreateFont :: proc(ctx: ^Context, name, filename: string) -> int {
	return fontstash.AddFontPath(&ctx.fs, name, filename)
}

// Creates font by loading it from the specified memory chunk.
// Returns handle to the font.
CreateFontMem :: proc(ctx: ^Context, name: string, slice: []byte, free_loaded_data: bool) -> int {
	return fontstash.AddFontMem(&ctx.fs, name, slice, free_loaded_data)
}

// Finds a loaded font of specified name, and returns handle to it, or -1 if the font is not found.
FindFont :: proc(ctx: ^Context, name: string) -> int {
	if name == "" {
		return -1
	}

	return fontstash.GetFontByName(&ctx.fs, name)
}

// Adds a fallback font by handle.
AddFallbackFontId :: proc(ctx: ^Context, base_font, fallback_font: int) -> bool {
	if base_font == -1 || fallback_font == -1 {
		return false
	}

	return fontstash.AddFallbackFont(&ctx.fs, base_font, fallback_font)
}

// Adds a fallback font by name.
AddFallbackFont :: proc(ctx: ^Context, base_font: string, fallback_font: string) -> bool {
	return AddFallbackFontId(
		ctx,
		FindFont(ctx, base_font),
		FindFont(ctx, fallback_font),
	)
}

// Resets fallback fonts by handle.
ResetFallbackFontsId :: proc(ctx: ^Context, base_font: int) {
	fontstash.ResetFallbackFont(&ctx.fs, base_font)
}

// Resets fallback fonts by name.
ResetFallbackFonts :: proc(ctx: ^Context, base_font: string) {
	fontstash.ResetFallbackFont(&ctx.fs, FindFont(ctx, base_font))
}

// Sets the font size of current text style.
FontSize :: proc(ctx: ^Context, size: f32) {
	state := __getState(ctx)
	state.fontSize = size
}

// Sets the blur of current text style.
FontBlur :: proc(ctx: ^Context, blur: f32) {
	state := __getState(ctx)
	state.fontBlur = blur
}

// Sets the letter spacing of current text style.
TextLetterSpacing :: proc(ctx: ^Context, spacing: f32) {
	state := __getState(ctx)
	state.letterSpacing = spacing
}

// Sets the proportional line height of current text style. The line height is specified as multiple of font size.
TextLineHeight :: proc(ctx: ^Context, lineHeight: f32) {
	state := __getState(ctx)
	state.lineHeight = lineHeight
}

// Sets the horizontal text align of current text style
TextAlignHorizontal :: proc(ctx: ^Context, align: AlignHorizontal) {
	state := __getState(ctx)
	state.alignHorizontal = align
}

// Sets the vertical text align of current text style
TextAlignVertical :: proc(ctx: ^Context, align: AlignVertical) {
	state := __getState(ctx)
	state.alignVertical = align
}

// Sets the text align of current text style, see NVGalign for options.
TextAlign :: proc(ctx: ^Context, ah: AlignHorizontal, av: AlignVertical) {
	state := __getState(ctx)
	state.alignHorizontal = ah
	state.alignVertical = av
}

// Sets the font face based on specified name of current text style.
FontFaceId :: proc(ctx: ^Context, font: int) {
	state := __getState(ctx)
	state.fontId = font
}

// Sets the font face based on specified name of current text style.
FontFace :: proc(ctx: ^Context, font: string) {
	state := __getState(ctx)
	state.fontId = fontstash.GetFontByName(&ctx.fs, font)
}

__quantize :: proc(a, d: f32) -> f32 {
	return f32(int(a / d + 0.5)) * d
}

__getFontScale :: proc(state: ^State) -> f32 {
	return min(__quantize(__getAverageScale(state.xform[:]), 0.01), 4.0)
}

__flushTextTexture :: proc(ctx: ^Context) {
	dirty: [4]f32
	assert(ctx.params.renderUpdateTexture != nil)

	if fontstash.ValidateTexture(&ctx.fs, &dirty) {
		font_image := ctx.fontImages[ctx.fontImageIdx]
		
		// Update texture
		if font_image != 0 {
			data := ctx.fs.textureData
			x := dirty[0]
			y := dirty[1]
			w := dirty[2] - dirty[0]
			h := dirty[3] - dirty[1]
			ctx.params.renderUpdateTexture(ctx.params.userPtr, font_image, int(x), int(y), int(w), int(h), data)
		}
	}
}

__allocTextAtlas :: proc(ctx: ^Context) -> bool {
	__flushTextTexture(ctx)
	
	if ctx.fontImageIdx >= MAX_FONTIMAGES - 1 {
		return false
	}
	
	// if next fontImage already have a texture
	iw, ih: int
	if ctx.fontImages[ctx.fontImageIdx+1] != 0 {
		iw, ih = ImageSize(ctx, ctx.fontImages[ctx.fontImageIdx+1])
	} else { // calculate the new font image size and create it.
		iw, ih = ImageSize(ctx, ctx.fontImages[ctx.fontImageIdx])
		
		if iw > ih {
			ih *= 2
		}	else {
			iw *= 2
		}

		if iw > MAX_FONTIMAGE_SIZE || ih > MAX_FONTIMAGE_SIZE {
			iw = MAX_FONTIMAGE_SIZE
			ih = MAX_FONTIMAGE_SIZE
		}

		ctx.fontImages[ctx.fontImageIdx + 1] = ctx.params.renderCreateTexture(ctx.params.userPtr, .Alpha, iw, ih, {}, nil)
	}

	ctx.fontImageIdx += 1
	fontstash.ResetAtlas(&ctx.fs, iw, ih)

	return true
}

__renderText :: proc(ctx: ^Context, verts: []Vertex) {
	// disallow 0
	if len(verts) == 0 {
		return
	}

	state := __getState(ctx)
	paint := state.fill

	// Render triangles.
	paint.image = ctx.fontImages[ctx.fontImageIdx]

	// Apply global alpha
	paint.innerColor.a *= state.alpha
	paint.outerColor.a *= state.alpha

	ctx.params.renderTriangles(ctx.params.userPtr, &paint, state.compositeOperation, &state.scissor, verts, ctx.fringeWidth)
	
	ctx.drawCallCount += 1
	ctx.textTriCount += len(verts) / 3
}

__isTransformFlipped :: proc(xform: []f32) -> bool {
	det := xform[0] * xform[3] - xform[2] * xform[1]
	return det < 0
}

// draw a single codepoint, useful for icons
TextIcon :: proc(ctx: ^Context, xpos, ypos: f32, codepoint: rune) -> f32 {
	state := __getState(ctx)
	scale := __getFontScale(state) * ctx.devicePxRatio
	invscale := f32(1.0) / scale
	is_flipped := __isTransformFlipped(state.xform[:])

	if state.fontId == -1 {
		return xpos
	}

	fs := &ctx.fs
	fontstash.SetSize(fs, state.fontSize * scale)
	fontstash.SetSpacing(fs, state.letterSpacing * scale)
	fontstash.SetBlur(fs, state.fontBlur * scale)
	fontstash.SetAlignHorizontal(fs, state.alignHorizontal)
	fontstash.SetAlignVertical(fs, state.alignVertical)
	fontstash.SetFont(fs, state.fontId)

	// fontstash internals
	fstate := fontstash.__getState(fs)
	font := fontstash.__getFont(fs, state.fontId)
	isize := i16(fstate.size * 10)
	iblur := i16(fstate.blur)
	glyph, _ := fontstash.__getGlyph(fs, font, codepoint, isize, iblur)
	fscale := fontstash.__getPixelHeightScale(font, f32(isize) / 10)
	
	// transform x / y
	x := xpos * scale
	y := ypos * scale
	switch fstate.ah {
	case .LEFT: {}
	
	case .CENTER: 
		width := fontstash.CodepointWidth(font, codepoint, fscale)
		x = math.round(x - width * 0.5)

	case .RIGHT: 
		width := fontstash.CodepointWidth(font, codepoint, fscale)
		x -= width
	}

	// align vertically
	y = math.round(y + fontstash.__getVerticalAlign(fs, font, fstate.av, isize))
	nextx := f32(x)
	nexty := f32(y)

	if glyph != nil {
		q: fontstash.Quad
		fontstash.__getQuad(fs, font, -1, glyph, fscale, fstate.spacing, &nextx, &nexty, &q)

		if is_flipped {
			q.y0, q.y1 = q.y1, q.y0
			q.t0, q.t1 = q.t1, q.t0
		}

		// single glyph only
		verts := __allocTempVerts(ctx, 6)
		c: [4 * 2]f32
	
		// Transform corners.
		TransformPoint(&c[0], &c[1], state.xform, q.x0 * invscale, q.y0 * invscale)
		TransformPoint(&c[2], &c[3], state.xform, q.x1 * invscale, q.y0 * invscale)
		TransformPoint(&c[4], &c[5], state.xform, q.x1 * invscale, q.y1 * invscale)
		TransformPoint(&c[6], &c[7], state.xform, q.x0 * invscale, q.y1 * invscale)
		
		// Create triangles
		verts[0] = {c[0], c[1], q.s0, q.t0}
		verts[1] = {c[4], c[5], q.s1, q.t1}
		verts[2] = {c[2], c[3], q.s1, q.t0}
		verts[3] = {c[0], c[1], q.s0, q.t0}
		verts[4] = {c[6], c[7], q.s0, q.t1}
		verts[5] = {c[4], c[5], q.s1, q.t1}

		ctx.textureDirty = true
		__renderText(ctx, verts[:])
	}

	return nextx / scale
}

// Draws text string at specified location. If end is specified only the sub-string up to the end is drawn.
Text :: proc(ctx: ^Context, x, y: f32, text: string) -> f32 {
	state := __getState(ctx)
	scale := __getFontScale(state) * ctx.devicePxRatio
	invscale := f32(1.0) / scale
	is_flipped := __isTransformFlipped(state.xform[:])

	if state.fontId == -1 {
		return x
	}

	fs := &ctx.fs
	fontstash.SetSize(fs, state.fontSize * scale)
	fontstash.SetSpacing(fs, state.letterSpacing * scale)
	fontstash.SetBlur(fs, state.fontBlur * scale)
	fontstash.SetAlignHorizontal(fs, state.alignHorizontal)
	fontstash.SetAlignVertical(fs, state.alignVertical)
	fontstash.SetFont(fs, state.fontId)

	cverts := max(2, len(text)) * 6 // conservative estimate.
	verts := __allocTempVerts(ctx, cverts)
	nverts: int

	iter := fontstash.TextIterInit(fs, x * scale, y * scale, text)
	prev_iter := iter
	q: fontstash.Quad
	for fontstash.TextIterNext(&ctx.fs, &iter, &q) {
		c: [4 * 2]f32
		
		if iter.previousGlyphIndex == -1 { // can not retrieve glyph?
			if nverts != 0 {
				__renderText(ctx, verts[:])
				nverts = 0
			}

			if !__allocTextAtlas(ctx) {
				break // no memory :(
			}

			iter = prev_iter
			fontstash.TextIterNext(fs, &iter, &q) // try again
			
			if iter.previousGlyphIndex == -1 {
				// still can not find glyph?
				break
			} 
		}
		
		prev_iter = iter
		if is_flipped {
			q.y0, q.y1 = q.y1, q.y0
			q.t0, q.t1 = q.t1, q.t0
		}

		// Transform corners.
		TransformPoint(&c[0], &c[1], state.xform, q.x0 * invscale, q.y0 * invscale)
		TransformPoint(&c[2], &c[3], state.xform, q.x1 * invscale, q.y0 * invscale)
		TransformPoint(&c[4], &c[5], state.xform, q.x1 * invscale, q.y1 * invscale)
		TransformPoint(&c[6], &c[7], state.xform, q.x0 * invscale, q.y1 * invscale)
		
		// Create triangles
		if nverts + 6 <= cverts {
			verts[nverts+0] = {c[0], c[1], q.s0, q.t0}
			verts[nverts+1] = {c[4], c[5], q.s1, q.t1}
			verts[nverts+2] = {c[2], c[3], q.s1, q.t0}
			verts[nverts+3] = {c[0], c[1], q.s0, q.t0}
			verts[nverts+4] = {c[6], c[7], q.s0, q.t1}
			verts[nverts+5] = {c[4], c[5], q.s1, q.t1}
			nverts += 6
		}
	}

	ctx.textureDirty = true
	__renderText(ctx, verts[:nverts])

	return iter.nextx / scale
}

// Returns the vertical metrics based on the current text style.
// Measured values are returned in local coordinate space.
TextMetrics :: proc(ctx: ^Context) -> (ascender, descender, lineHeight: f32) {
	state := __getState(ctx)
	scale := __getFontScale(state) * ctx.devicePxRatio
	invscale := f32(1.0) / scale

	if state.fontId == -1 {
		return
	}

	fs := &ctx.fs
	fontstash.SetSize(fs, state.fontSize*scale)
	fontstash.SetSpacing(fs, state.letterSpacing*scale)
	fontstash.SetBlur(fs, state.fontBlur*scale)
	fontstash.SetAlignHorizontal(fs, state.alignHorizontal)
	fontstash.SetAlignVertical(fs, state.alignVertical)
	fontstash.SetFont(fs, state.fontId)

	ascender, descender, lineHeight = fontstash.VerticalMetrics(fs)
	ascender *= invscale
	descender *= invscale
	lineHeight *= invscale
	return
}

// Measures the specified text string. Parameter bounds should be a pointer to float[4],
// if the bounding box of the text should be returned. The bounds value are [xmin,ymin, xmax,ymax]
// Returns the horizontal advance of the measured text (i.e. where the next character should drawn).
// Measured values are returned in local coordinate space.
TextBounds :: proc(
	ctx:    ^Context,
	x, y:   f32,
	input:  string,
	bounds: ^[4]f32 = nil,
) -> (advance: f32) {
	state    := __getState(ctx)
	scale    := __getFontScale(state) * ctx.devicePxRatio
	invscale := f32(1.0) / scale

	if state.fontId == -1 {
		return 0
	}

	fs := &ctx.fs
	fontstash.SetSize(fs, state.fontSize*scale)
	fontstash.SetSpacing(fs, state.letterSpacing*scale)
	fontstash.SetBlur(fs, state.fontBlur*scale)
	fontstash.SetAlignHorizontal(fs, state.alignHorizontal)
	fontstash.SetAlignVertical(fs, state.alignVertical)
	fontstash.SetFont(fs, state.fontId)

	width := fontstash.TextBounds(fs, input, x * scale, y * scale, bounds)

	if bounds != nil {
		// Use line bounds for height.
		one, two := fontstash.LineBounds(fs, y * scale)

		bounds[1] = one
		bounds[3] = two
		bounds[0] *= invscale
		bounds[1] *= invscale
		bounds[2] *= invscale
		bounds[3] *= invscale
	}

	return width * invscale
}

// text row with relative byte offsets into a string
Text_Row :: struct {
	start:      int,
	end:        int,
	next:       int,
	width:      f32,
	minx, maxx: f32,
}

Codepoint_Type :: enum {
	Space,
	Newline,
	Char,
	CJK,
}

// Draws multi-line text string at specified location wrapped at the specified width. If end is specified only the sub-string up to the end is drawn.
// White space is stripped at the beginning of the rows, the text is split at word boundaries or when new-line characters are encountered.
// Words longer than the max width are slit at nearest character (i.e. no hyphenation).
TextBox :: proc(
	ctx:             ^Context,
	x, y:            f32,
	break_row_width: f32,
	input:           string,
) {
	state := __getState(ctx)
	rows: [2]Text_Row

	if state.fontId == -1 {
		return
	} 

	_, _, lineHeight := TextMetrics(ctx)
	old_align := state.alignHorizontal
	defer state.alignHorizontal = old_align
	state.alignHorizontal = .LEFT
	rows_mod := rows[:]

	y := y
	input := input
	for nrows, input_last in TextBreakLines(ctx, &input, break_row_width, &rows_mod) {
		for row in rows[:nrows] {
			Text(ctx, x, y, input_last[row.start:row.end])		
			y += lineHeight * state.lineHeight
		}
	}
}

// NOTE text break lines works relative to the string in byte indexes now, instead of on pointers
// Breaks the specified text into lines
// White space is stripped at the beginning of the rows, the text is split at word boundaries or when new-line characters are encountered.
// Words longer than the max width are slit at nearest character (i.e. no hyphenation).
TextBreakLines :: proc(
	ctx:             ^Context,
	text:            ^string,
	break_row_width: f32,
	rows:            ^[]Text_Row,
) -> (nrows: int, last: string, ok: bool) {
	state := __getState(ctx)
	scale := __getFontScale(state) * ctx.devicePxRatio
	invscale := 1.0 / scale

	row_start_x, row_width, row_min_x, row_max_x: f32
	max_rows := len(rows)

	row_start: int = -1
	row_end: int = -1
	word_start: int = -1
	break_end: int = -1
	word_start_x, word_min_x: f32

	break_width, break_max_x: f32
	type  := Codepoint_Type.Space
	ptype := Codepoint_Type.Space
	pcodepoint: rune

	if max_rows == 0 || state.fontId == -1 || len(text) == 0 {
		return
	}

	fs := &ctx.fs
	fontstash.SetSize(fs, state.fontSize * scale)
	fontstash.SetSpacing(fs, state.letterSpacing * scale)
	fontstash.SetBlur(fs, state.fontBlur * scale)
	fontstash.SetAlignHorizontal(fs, state.alignHorizontal)
	fontstash.SetAlignVertical(fs, state.alignVertical)
	fontstash.SetFont(fs, state.fontId)

	break_x   := break_row_width * scale
	iter      := fontstash.TextIterInit(fs, 0, 0, text^)
	prev_iter := iter

	q: fontstash.Quad
	stopped_early: bool

	for fontstash.TextIterNext(fs, &iter, &q) {
		if iter.previousGlyphIndex < 0 && __allocTextAtlas(ctx) { // can not retrieve glyph?
			iter = prev_iter
			fontstash.TextIterNext(fs, &iter, &q) // try again
		}
		prev_iter = iter

		switch iter.codepoint {
		case '\t', '\v', '\f', ' ', 0x00a0:
			// NBSP
			type = .Space

		case '\n':
			type = .Space if pcodepoint == 13 else .Newline
		
		case '\r':
			type = .Space if pcodepoint == 10 else .Newline

		case 0x0085: 
			// NEL
			type = .Newline

		case: 
			switch iter.codepoint {
			case 0x4E00..=0x9FFF,
			     0x3000..=0x30FF,
			     0xFF00..=0xFFEF,
			     0x1100..=0x11FF,
			     0x3130..=0x318F,
			     0xAC00..=0xD7AF:
				type = .CJK
			case:
				type = .Char
			}
		}

		if type == .Newline {
			// Always handle new lines.
			rows[nrows].start = row_start if row_start != -1 else iter.str
			rows[nrows].end   = row_end   if row_end   != -1 else iter.str
			rows[nrows].width = row_width * invscale
			rows[nrows].minx  = row_min_x * invscale
			rows[nrows].maxx  = row_max_x * invscale
			rows[nrows].next  = iter.next
			nrows += 1
			
			if nrows >= max_rows {
				stopped_early = true
				break
			}

			// Set nil break point
			break_end = row_start
			break_width = 0.0
			break_max_x = 0.0
			// Indicate to skip the white space at the beginning of the row.
			row_start = -1
			row_end = -1
			row_width = 0
			row_min_x = 0
			row_max_x = 0
		} else {
			if row_start == -1 {
				// Skip white space until the beginning of the line
				if type == .Char || type == .CJK {
					// The current char is the row so far
					row_start_x = iter.x
					row_start = iter.str
					row_end = iter.next
					row_width = iter.nextx - row_start_x
					row_min_x = q.x0 - row_start_x
					row_max_x = q.x1 - row_start_x
					word_start = iter.str
					word_start_x = iter.x
					word_min_x = q.x0 - row_start_x
					// Set nil break point
					break_end = row_start
					break_width = 0.0
					break_max_x = 0.0
				}
			} else {
				next_width := iter.nextx - row_start_x

				// track last non-white space character
				if type == .Char || type == .CJK {
					row_end = iter.next
					row_width = iter.nextx - row_start_x
					row_max_x = q.x1 - row_start_x
				}
				// track last end of a word
				if ((ptype == .Char || ptype == .CJK) && type == .Space) || type == .CJK {
					break_end = iter.str
					break_width = row_width
					break_max_x = row_max_x
				}
				// track last beginning of a word
				if ((ptype == .Space && (type == .Char || type == .CJK)) || type == .CJK) {
					word_start = iter.str
					word_start_x = iter.x
					word_min_x = q.x0
				}

				// Break to new line when a character is beyond break width.
				if (type == .Char || type == .CJK) && next_width > break_x {
					// The run length is too long, need to break to new line.
					if break_end == row_start {
						// The current word is longer than the row length, just break it from here.
						rows[nrows].start = row_start
						rows[nrows].end = iter.str
						rows[nrows].width = row_width * invscale
						rows[nrows].minx = row_min_x * invscale
						rows[nrows].maxx = row_max_x * invscale
						rows[nrows].next = iter.str
						nrows += 1

						if nrows >= max_rows {
							stopped_early = true
							break
						}

						row_start_x = iter.x
						row_start = iter.str
						row_end = iter.next
						row_width = iter.nextx - row_start_x
						row_min_x = q.x0 - row_start_x
						row_max_x = q.x1 - row_start_x
						word_start = iter.str
						word_start_x = iter.x
						word_min_x = q.x0 - row_start_x
					} else {
						// Break the line from the end of the last word, and start new line from the beginning of the new.
						rows[nrows].start = row_start
						rows[nrows].end = break_end
						rows[nrows].width = break_width * invscale
						rows[nrows].minx = row_min_x * invscale
						rows[nrows].maxx = break_max_x * invscale
						rows[nrows].next = word_start
						nrows += 1
						if nrows >= max_rows {
							stopped_early = true
							break
						}
						// Update row
						row_start_x = word_start_x
						row_start = word_start
						row_end = iter.next
						row_width = iter.nextx - row_start_x
						row_min_x = word_min_x - row_start_x
						row_max_x = q.x1 - row_start_x
					}
					// Set nil break point
					break_end = row_start
					break_width = 0.0
					break_max_x = 0.0
				}
			}
		}

		pcodepoint = iter.codepoint
		ptype = type
	}

	// Break the line from the end of the last word, and start new line from the beginning of the new.
	if !stopped_early && row_start != -1 {
		rows[nrows].start = row_start
		rows[nrows].end = row_end
		rows[nrows].width = row_width * invscale
		rows[nrows].minx = row_min_x * invscale
		rows[nrows].maxx = row_max_x * invscale
		rows[nrows].next = iter.end
		nrows += 1
	}

	// NOTE a bit hacky, row.start / row.end need to work with last string range
	last = text^
	// advance early
	next := rows[nrows-1].next
	text^ = text[next:]
	// terminate the for loop on non ok
	ok = nrows != 0

	return 
}

// Measures the specified multi-text string. Parameter bounds should be a pointer to float[4],
// if the bounding box of the text should be returned. The bounds value are [xmin,ymin, xmax,ymax]
// Measured values are returned in local coordinate space.
TextBoxBounds :: proc(
	ctx:           ^Context,
	x, y:          f32,
	breakRowWidth: f32, 
	input:         string,
	bounds:        ^[4]f32,
) {
	state := __getState(ctx)
	rows: [2]Text_Row
	scale := __getFontScale(state) * ctx.devicePxRatio
	invscale := f32(1.0) / scale

	if state.fontId == -1 {
		if bounds != nil {
			bounds^ = {}
		}

		return
	}

	// alignment
	halign := state.alignHorizontal
	old_align := state.alignHorizontal
	defer state.alignHorizontal = old_align
	state.alignHorizontal = .LEFT

	_, _, lineh := TextMetrics(ctx)
	minx, maxx := x, x
	miny, maxy := y, y

	fs := &ctx.fs
	fontstash.SetSize(fs, state.fontSize * scale)
	fontstash.SetSpacing(fs, state.letterSpacing * scale)
	fontstash.SetBlur(fs, state.fontBlur * scale)
	fontstash.SetAlignHorizontal(fs, state.alignHorizontal)
	fontstash.SetAlignVertical(fs, state.alignVertical)
	fontstash.SetFont(fs, state.fontId)
	rminy, rmaxy := fontstash.LineBounds(fs, 0)
	rminy *= invscale
	rmaxy *= invscale

	input := input
	rows_mod := rows[:]
	y := y

	for nrows in TextBreakLines(ctx, &input, breakRowWidth, &rows_mod) {
		for row in rows[:nrows] {
			rminx, rmaxx, dx: f32
			
			// Horizontal bounds
			switch halign {
			case .LEFT:   dx = 0
			case .CENTER: dx = breakRowWidth*0.5 - row.width*0.5
			case .RIGHT:  dx = breakRowWidth     - row.width
			}

			rminx = x + row.minx + dx
			rmaxx = x + row.maxx + dx
			minx = min(minx, rminx)
			maxx = max(maxx, rmaxx)
			// Vertical bounds.
			miny = min(miny, y + rminy)
			maxy = max(maxy, y + rmaxy)

			y += lineh * state.lineHeight
		}
	}

	if bounds != nil {
		bounds^ = {minx, miny, maxx, maxy}
	}
}

Glyph_Position :: struct {
	str:        int,
	x:          f32,
	minx, maxx: f32,
}

// Calculates the glyph x positions of the specified text.
// Measured values are returned in local coordinate space.
TextGlyphPositions :: proc(
	ctx:       ^Context,
	x, y:      f32,
	text:      string,
	positions: ^[]Glyph_Position,
) -> int {
	state := __getState(ctx)
	scale := __getFontScale(state) * ctx.devicePxRatio

	if state.fontId == -1 || len(text) == 0 {
		return 0
	}

	fs := &ctx.fs
	fontstash.SetSize(fs, state.fontSize*scale)
	fontstash.SetSpacing(fs, state.letterSpacing*scale)
	fontstash.SetBlur(fs, state.fontBlur*scale)
	fontstash.SetAlignHorizontal(fs, state.alignHorizontal)
	fontstash.SetAlignVertical(fs, state.alignVertical)
	fontstash.SetFont(fs, state.fontId)

	iter := fontstash.TextIterInit(fs, 0, 0, text)
	prev_iter := iter
	q: fontstash.Quad
	npos: int
	for fontstash.TextIterNext(fs, &iter, &q) {
		if iter.previousGlyphIndex < 0 && __allocTextAtlas(ctx) { // can not retrieve glyph?
			iter = prev_iter
			fontstash.TextIterNext(fs, &iter, &q) // try again
		}

		prev_iter = iter
		positions[npos].str = iter.str
		positions[npos].x = iter.x + x
		positions[npos].minx = min(iter.x, q.x0) + x
		positions[npos].maxx = max(iter.nextx, q.x1) + x
		npos += 1
		
		if npos >= len(positions) {
			break
		}
	}

	return npos
}