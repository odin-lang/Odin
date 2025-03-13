package webgl

foreign import "webgl"

import glm "core:math/linalg/glsl"

Enum :: distinct u32

Buffer       :: distinct u32
Framebuffer  :: distinct u32
Program      :: distinct u32
Renderbuffer :: distinct u32
Shader       :: distinct u32
Texture      :: distinct u32

ContextAttribute :: enum u32 {
	disableAlpha                 = 0,
	disableAntialias             = 1,
	disableDepth                 = 2,
	failIfMajorPerformanceCaveat = 3,
	disablePremultipliedAlpha    = 4,
	preserveDrawingBuffer        = 5,
	stencil                      = 6,
	desynchronized               = 7,
}
ContextAttributes :: distinct bit_set[ContextAttribute; u32]

DEFAULT_CONTEXT_ATTRIBUTES :: ContextAttributes{}

@(default_calling_convention="contextless")
foreign webgl {
	// CreateCurrentContextById must be called before `GetCurrentContextAttributes` if the user wants to
	// set specific attributes, otherwise the default attributes will be set for the WebGL context
	CreateCurrentContextById :: proc(name: string, attributes: ContextAttributes) -> bool ---
	// Acquire the WebGL context from a canvas element by id
	SetCurrentContextById :: proc(name: string) -> bool ---
	GetCurrentContextAttributes :: proc() -> ContextAttributes ---

	DrawingBufferWidth  :: proc() -> i32 ---
	DrawingBufferHeight :: proc() -> i32 ---
	
	GetWebGLVersion :: proc(major, minor: ^i32) ---
	GetESVersion :: proc(major, minor: ^i32) ---
	
	GetError :: proc() -> Enum ---
	
	IsExtensionSupported :: proc(name: string) -> bool ---

	ActiveTexture         :: proc(x: Enum) ---
	AttachShader          :: proc(program: Program, shader: Shader) ---
	BindAttribLocation    :: proc(program: Program, index: i32, name: string) ---
	BindBuffer            :: proc(target: Enum, buffer: Buffer) ---
	BindFramebuffer       :: proc(target: Enum, framebuffer: Framebuffer) ---
	BindTexture           :: proc(target: Enum, texture: Texture) ---
	BlendColor            :: proc(red, green, blue, alpha: f32) ---
	BlendEquation         :: proc(mode: Enum) ---
	BlendEquationSeparate :: proc(modeRGB: Enum, modeAlpha: Enum) ---
	BlendFunc             :: proc(sfactor, dfactor: Enum) ---
	BlendFuncSeparate     :: proc(srcRGB, dstRGB, srcAlpha, dstAlpha: Enum) ---
	
	BufferData    :: proc(target: Enum, size: int, data: rawptr, usage: Enum) ---
	BufferSubData :: proc(target: Enum, offset: uintptr, size: int, data: rawptr) ---

	Clear         :: proc(bits: Enum) ---
	ClearColor    :: proc(r, g, b, a: f32) ---
	ClearDepth    :: proc(x: Enum) ---
	ClearStencil  :: proc(x: Enum) ---
	ColorMask     :: proc(r, g, b, a: bool) ---
	CompileShader :: proc(shader: Shader) ---
	
	CompressedTexImage2D    :: proc(target: Enum, level: i32, internalformat: Enum, width, height: i32, border: i32, imageSize: int, data: rawptr) ---
	CompressedTexSubImage2D :: proc(target: Enum, level: i32, xoffset, yoffset, width, height: i32, format: Enum, imageSize: int, data: rawptr) ---
	CopyTexImage2D          :: proc(target: Enum, level: i32, internalformat: Enum, x, y, width, height: i32, border: i32) ---
	CopyTexSubImage2D       :: proc(target: Enum, level: i32, xoffset, yoffset, x, y: i32, width, height: i32) ---
	

	CreateBuffer       :: proc() -> Buffer ---
	CreateFramebuffer  :: proc() -> Framebuffer ---
	CreateProgram      :: proc() -> Program ---
	CreateRenderbuffer :: proc() -> Renderbuffer ---
	CreateShader       :: proc(shaderType: Enum) -> Shader ---
	CreateTexture      :: proc() -> Texture ---
	
	CullFace :: proc(mode: Enum) ---
	
	DeleteBuffer       :: proc(buffer: Buffer) ---
	DeleteFramebuffer  :: proc(framebuffer: Framebuffer) ---
	DeleteProgram      :: proc(program: Program) ---
	DeleteRenderbuffer :: proc(renderbuffer: Renderbuffer) ---
	DeleteShader       :: proc(shader: Shader) ---
	DeleteTexture      :: proc(texture: Texture) ---
	
	DepthFunc                :: proc(func: Enum) ---
	DepthMask                :: proc(flag: bool) ---
	DepthRange               :: proc(zNear, zFar: f32) ---
	DetachShader             :: proc(program: Program, shader: Shader) ---
	Disable                  :: proc(cap: Enum) ---
	DisableVertexAttribArray :: proc(index: i32) ---
	DrawArrays               :: proc(mode: Enum, first, count: int) ---
	DrawElements             :: proc(mode: Enum, count: int, type: Enum, indices: rawptr) ---
	
	Enable                  :: proc(cap: Enum) ---
	EnableVertexAttribArray :: proc(index: i32) ---
	Finish                  :: proc() ---
	Flush                   :: proc() ---
	FramebufferRenderbuffer :: proc(target, attachment, renderbufertarget: Enum, renderbuffer: Renderbuffer) ---
	FramebufferTexture2D    :: proc(target, attachment, textarget: Enum, texture: Texture, level: i32) ---
	FrontFace               :: proc(mode: Enum) ---
	
	GenerateMipmap :: proc(target: Enum) ---
	
	GetAttribLocation     :: proc(program: Program, name: string) -> i32 ---
	GetUniformLocation    :: proc(program: Program, name: string) -> i32 ---
	GetVertexAttribOffset :: proc(index: i32, pname: Enum) -> uintptr ---
	GetProgramParameter   :: proc(program: Program, pname: Enum) -> i32 ---
	GetParameter          :: proc(pname: Enum) -> i32 ---
	GetParameter4i        :: proc(pname: Enum, v0, v1, v2, v4: ^i32) ---

	Hint :: proc(target: Enum, mode: Enum) ---
	
	IsBuffer       :: proc(buffer: Buffer) -> bool ---
	IsEnabled      :: proc(cap: Enum) -> bool ---
	IsFramebuffer  :: proc(framebuffer: Framebuffer) -> bool ---
	IsProgram      :: proc(program: Program) -> bool ---
	IsRenderbuffer :: proc(renderbuffer: Renderbuffer) -> bool ---
	IsShader       :: proc(shader: Shader) -> bool ---
	IsTexture      :: proc(texture: Texture) -> bool ---
	
	LineWidth     :: proc(width: f32) ---
	LinkProgram   :: proc(program: Program) ---
	PixelStorei   :: proc(pname: Enum, param: i32) ---
	PolygonOffset :: proc(factor: f32, units: f32) ---
	
	ReadnPixels         :: proc(x, y, width, height: i32, format: Enum, type: Enum, bufSize: int, data: rawptr) ---
	RenderbufferStorage :: proc(target: Enum, internalformat: Enum, width, height: i32) ---
	SampleCoverage      :: proc(value: f32, invert: bool) ---
	Scissor             :: proc(x, y, width, height: i32) ---
	ShaderSource        :: proc(shader: Shader, strings: []string) ---
	
	StencilFunc         :: proc(func: Enum, ref: i32, mask: u32) ---
	StencilFuncSeparate :: proc(face, func: Enum, ref: i32, mask: u32) ---
	StencilMask         :: proc(mask: u32) ---
	StencilMaskSeparate :: proc(face: Enum, mask: u32) ---
	StencilOp           :: proc(fail, zfail, zpass: Enum) ---
	StencilOpSeparate   :: proc(face, fail, zfail, zpass: Enum)	 ---
	
	TexImage2D    :: proc(target: Enum, level: i32, internalformat: Enum, width, height: i32, border: i32, format, type: Enum, size: int, data: rawptr) ---
	TexSubImage2D :: proc(target: Enum, level: i32, xoffset, yoffset, width, height: i32, format, type: Enum, size: int, data: rawptr) ---
	
	TexParameterf :: proc(target, pname: Enum, param: f32) ---
	TexParameteri :: proc(target, pname: Enum, param: i32) ---
	
	Uniform1f :: proc(location: i32, v0: f32) ---
	Uniform2f :: proc(location: i32, v0, v1: f32) ---
	Uniform3f :: proc(location: i32, v0, v1, v2: f32) ---
	Uniform4f :: proc(location: i32, v0, v1, v2, v3: f32) ---
	
	Uniform1i :: proc(location: i32, v0: i32) ---
	Uniform2i :: proc(location: i32, v0, v1: i32) ---
	Uniform3i :: proc(location: i32, v0, v1, v2: i32) ---
	Uniform4i :: proc(location: i32, v0, v1, v2, v3: i32) ---
	
	UseProgram      :: proc(program: Program) ---
	ValidateProgram :: proc(program: Program) ---
		
	VertexAttrib1f      :: proc(index: i32, x: f32) ---
	VertexAttrib2f      :: proc(index: i32, x, y: f32) ---
	VertexAttrib3f      :: proc(index: i32, x, y, z: f32) ---
	VertexAttrib4f      :: proc(index: i32, x, y, z, w: f32) ---
	VertexAttribPointer :: proc(index: i32, size: int, type: Enum, normalized: bool, stride: int, ptr: uintptr) ---
	
	Viewport :: proc(x, y, w, h: i32) ---
}

Uniform1fv :: proc "contextless" (location: i32, v: f32)       { Uniform1f(location, v) }
Uniform2fv :: proc "contextless" (location: i32, v: glm.vec2)  { Uniform2f(location, v.x, v.y) }
Uniform3fv :: proc "contextless" (location: i32, v: glm.vec3)  { Uniform3f(location, v.x, v.y, v.z) }
Uniform4fv :: proc "contextless" (location: i32, v: glm.vec4)  { Uniform4f(location, v.x, v.y, v.z, v.w) }
Uniform1iv :: proc "contextless" (location: i32, v: i32)       { Uniform1i(location, v) }
Uniform2iv :: proc "contextless" (location: i32, v: glm.ivec2) { Uniform2i(location, v.x, v.y) }
Uniform3iv :: proc "contextless" (location: i32, v: glm.ivec3) { Uniform3i(location, v.x, v.y, v.z) }
Uniform4iv :: proc "contextless" (location: i32, v: glm.ivec4) { Uniform4i(location, v.x, v.y, v.z, v.w) }

VertexAttrib1fv :: proc "contextless" (index: i32, v: f32)     { VertexAttrib1f(index, v) }
VertexAttrib2fv :: proc "contextless" (index: i32, v: glm.vec2){ VertexAttrib2f(index, v.x, v.y) }
VertexAttrib3fv :: proc "contextless" (index: i32, v: glm.vec3){ VertexAttrib3f(index, v.x, v.y, v.z) }
VertexAttrib4fv :: proc "contextless" (index: i32, v: glm.vec4){ VertexAttrib4f(index, v.x, v.y, v.z, v.w) }

UniformMatrix2fv :: proc "contextless" (location: i32, m: glm.mat2) {
	foreign webgl {
		@(link_name="UniformMatrix2fv")
		_UniformMatrix2fv :: proc "contextless" (location: i32, value: [^]f32) ---
	}
	value := transmute([2*2]f32)m
	_UniformMatrix2fv(location, &value[0])
}
UniformMatrix3fv :: proc "contextless" (location: i32, m: glm.mat3) {
	foreign webgl {
		@(link_name="UniformMatrix3fv")
		_UniformMatrix3fv :: proc "contextless" (location: i32, value: [^]f32) ---
	}
	value := transmute([3*3]f32)m
	_UniformMatrix3fv(location, &value[0])
}
UniformMatrix4fv :: proc "contextless" (location: i32, m: glm.mat4) {
	foreign webgl {
		@(link_name="UniformMatrix4fv")
		_UniformMatrix4fv :: proc "contextless" (location: i32, value: [^]f32) ---
	}
	value := transmute([4*4]f32)m
	_UniformMatrix4fv(location, &value[0])
}

GetShaderiv :: proc "contextless" (shader: Shader, pname: Enum) -> (p: i32) {
	foreign webgl {
		@(link_name="GetShaderiv")
		_GetShaderiv :: proc "contextless" (shader: Shader, pname: Enum, p: ^i32) ---
	}
	_GetShaderiv(shader, pname, &p)
	return
}


GetProgramInfoLog :: proc "contextless" (program: Program, buf: []byte) -> string {
	foreign webgl {
		@(link_name="GetProgramInfoLog")
		_GetProgramInfoLog :: proc "contextless" (program: Program, buf: []byte, length: ^int) ---
	}
	
	length: int
	_GetProgramInfoLog(program, buf, &length)
	return string(buf[:length])
}

GetShaderInfoLog :: proc "contextless" (shader: Shader, buf: []byte) -> string {
	foreign webgl {
		@(link_name="GetShaderInfoLog")
		_GetShaderInfoLog :: proc "contextless" (shader: Shader, buf: []byte, length: ^int) ---
	}
	
	length: int
	_GetShaderInfoLog(shader, buf, &length)
	return string(buf[:length])
}



BufferDataSlice :: proc "contextless" (target: Enum, slice: $S/[]$E, usage: Enum) {
	BufferData(target, len(slice)*size_of(E), raw_data(slice), usage)
}
BufferSubDataSlice :: proc "contextless" (target: Enum, offset: uintptr, slice: $S/[]$E) {
	BufferSubData(target, offset, len(slice)*size_of(E), raw_data(slice))
}

CompressedTexImage2DSlice :: proc "contextless" (target: Enum, level: i32, internalformat: Enum, width, height: i32, border: i32, slice: $S/[]$E) {
	CompressedTexImage2DSlice(target, level, internalformat, width, height, border, len(slice)*size_of(E), raw_data(slice))
}
CompressedTexSubImage2DSlice :: proc "contextless" (target: Enum, level: i32, xoffset, yoffset, width, height: i32, format: Enum, slice: $S/[]$E) {
	CompressedTexSubImage2DSlice(target, level, level, xoffset, yoffset, width, height, format, len(slice)*size_of(E), raw_data(slice))
}

ReadPixelsSlice :: proc "contextless" (x, y, width, height: i32, format: Enum, type: Enum, slice: $S/[]$E) {
	ReadnPixels(x, y, width, height, format, type, len(slice)*size_of(E), raw_data(slice))
}

TexImage2DSlice :: proc "contextless" (target: Enum, level: i32, internalformat: Enum, width, height: i32, border: i32, format, type: Enum, slice: $S/[]$E) {
	TexImage2D(target, level, internalformat, width, height, border, format, type, len(slice)*size_of(E), raw_data(slice))
}
TexSubImage2DSlice :: proc "contextless" (target: Enum, level: i32, xoffset, yoffset, width, height: i32, format, type: Enum, slice: $S/[]$E) {
	TexSubImage2D(target, level, xoffset, yoffset, width, height, format, type, len(slice)*size_of(E), raw_data(slice))
}
