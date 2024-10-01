#+build windows
package sys_windows

import "core:c"

foreign import "system:Opengl32.lib"

CONTEXT_MAJOR_VERSION_ARB             :: 0x2091
CONTEXT_MINOR_VERSION_ARB             :: 0x2092
CONTEXT_FLAGS_ARB                     :: 0x2094
CONTEXT_PROFILE_MASK_ARB              :: 0x9126
CONTEXT_FORWARD_COMPATIBLE_BIT_ARB    :: 0x0002
CONTEXT_CORE_PROFILE_BIT_ARB          :: 0x00000001
CONTEXT_COMPATIBILITY_PROFILE_BIT_ARB :: 0x00000002

HGLRC :: distinct HANDLE

LPLAYERPLANEDESCRIPTOR :: ^LAYERPLANEDESCRIPTOR
LAYERPLANEDESCRIPTOR  :: struct {
	nSize:           WORD,
	nVersion:        WORD,
	dwFlags:         DWORD,
	iPixelType:      BYTE,
	cColorBits:      BYTE,
	cRedBits:        BYTE,
	cRedShift:       BYTE,
	cGreenBits:      BYTE,
	cGreenShift:     BYTE,
	cBlueBits:       BYTE,
	cBlueShift:      BYTE,
	cAlphaBits:      BYTE,
	cAlphaShift:     BYTE,
	cAccumBits:      BYTE,
	cAccumRedBits:   BYTE,
	cAccumGreenBits: BYTE,
	cAccumBlueBits:  BYTE,
	cAccumAlphaBits: BYTE,
	cDepthBits:      BYTE,
	cStencilBits:    BYTE,
	cAuxBuffers:     BYTE,
	iLayerPlane:     BYTE,
	bReserved:       BYTE,
	crTransparent:   COLORREF,
}

POINTFLOAT :: struct {x, y: f32}

LPGLYPHMETRICSFLOAT :: ^GLYPHMETRICSFLOAT
GLYPHMETRICSFLOAT :: struct {
	gmfBlackBoxX:     f32,
	gmfBlackBoxY:     f32,
	gmfptGlyphOrigin: POINTFLOAT,
	gmfCellIncX:      f32,
	gmfCellIncY:      f32,
}

CreateContextAttribsARBType :: #type proc "c" (hdc: HDC, hShareContext: rawptr, attribList: [^]c.int) -> HGLRC
ChoosePixelFormatARBType    :: #type proc "c" (hdc: HDC, attribIList: [^]c.int, attribFList: [^]f32, maxFormats: DWORD, formats: [^]c.int, numFormats: [^]DWORD) -> BOOL
SwapIntervalEXTType         :: #type proc "c" (interval: c.int) -> bool
GetExtensionsStringARBType  :: #type proc "c" (HDC) -> cstring

// Procedures
	wglCreateContextAttribsARB: CreateContextAttribsARBType
	wglChoosePixelFormatARB:    ChoosePixelFormatARBType
	wglSwapIntervalEXT:         SwapIntervalEXTType
	wglGetExtensionsStringARB:  GetExtensionsStringARBType


@(default_calling_convention="system")
foreign Opengl32 {
	wglCreateContext          :: proc(hdc: HDC) -> HGLRC ---
	wglMakeCurrent            :: proc(hdc: HDC, HGLRC: HGLRC) -> BOOL ---
	wglGetProcAddress         :: proc(c_str: cstring) -> rawptr ---
	wglDeleteContext          :: proc(HGLRC: HGLRC) -> BOOL ---
	wglCopyContext            :: proc(src, dst: HGLRC, mask: UINT) -> BOOL ---
	wglCreateLayerContext     :: proc(hdc: HDC, layer_plane: c.int) -> HGLRC ---
	wglDescribeLayerPlane     :: proc(hdc: HDC, pixel_format, layer_plane: c.int, bytes: UINT, pd: LPLAYERPLANEDESCRIPTOR) -> BOOL ---
	wglGetCurrentContext      :: proc() -> HGLRC ---
	wglGetCurrentDC           :: proc() -> HDC ---
	wglGetLayerPaletteEntries :: proc(hdc: HDC, layer_plane, start, entries: c.int, cr: ^COLORREF) -> c.int ---
	wglRealizeLayerPalette    :: proc(hdc: HDC, layer_plane: c.int, realize: BOOL) -> BOOL ---
	wglSetLayerPaletteEntries :: proc(hdc: HDC, layer_plane, start, entries: c.int, cr: ^COLORREF) -> c.int ---
	wglShareLists             :: proc(HGLRC1, HGLRC2: HGLRC) -> BOOL ---
	wglSwapLayerBuffers       :: proc(hdc: HDC, planes: DWORD) -> BOOL ---
	wglUseFontBitmaps         :: proc(hdc: HDC, first, count, list_base: DWORD) -> BOOL ---
	wglUseFontOutlines        :: proc(hdc: HDC, first, count, list_base: DWORD, deviation, extrusion: f32, format: c.int, gmf: LPGLYPHMETRICSFLOAT) -> BOOL ---
}

// Used by vendor:OpenGL
// https://www.khronos.org/opengl/wiki/Load_OpenGL_Functions#Windows
gl_set_proc_address :: proc(p: rawptr, name: cstring) {
	func := wglGetProcAddress(name)
	switch uintptr(func) {
	case 0, 1, 2, 3, ~uintptr(0):
		module := LoadLibraryW(L("opengl32.dll"))
		func = GetProcAddress(module, name)
	}
	(^rawptr)(p)^ = func
}
