package webgl

foreign import "webgl2"

import "base:intrinsics"
import glm "core:math/linalg/glsl"

Query             :: distinct u32
Sampler           :: distinct u32
Sync              :: distinct u32
TransformFeedback :: distinct u32
VertexArrayObject :: distinct u32

IsWebGL2Supported :: proc "contextless" () -> bool {
	major, minor: i32
	GetWebGLVersion(&major, &minor)
	return major >= 2
}

@(default_calling_convention="contextless")
foreign webgl2 {
	/* Buffer objects */
	CopyBufferSubData :: proc(readTarget, writeTarget: Enum, readOffset, writeOffset: int, size: int) ---	
	GetBufferSubData  :: proc(target: Enum, srcByteOffset: int, dst_buffer: []byte, dstOffset: int = 0, length: int = 0) ---
	
	/* Framebuffer objects */
	BlitFramebuffer          :: proc(srcX0, srcY0, srcX1, srcY1, dstX0, dstY0, dstX1, dstY1: i32, mask: u32, filter: Enum) ---
	FramebufferTextureLayer  :: proc(target: Enum, attachment: Enum, texture: Texture, level: i32, layer: i32) ---
	InvalidateFramebuffer    :: proc(target: Enum, attachments: []Enum) ---
	InvalidateSubFramebuffer :: proc(target: Enum, attachments: []Enum, x, y, width, height: i32) ---
	ReadBuffer               :: proc(src: Enum) ---
	
	/* Renderbuffer objects */
	RenderbufferStorageMultisample :: proc(target: Enum, samples: i32, internalformat: Enum, width, height: i32) ---
	
	/* Texture objects */
	TexStorage3D            :: proc(target: Enum, levels: i32, internalformat: Enum, width, height, depth: i32) ---
	TexImage3D              :: proc(target: Enum, level: i32, internalformat: Enum, width, height, depth: i32, border: i32, format, type: Enum, size: int, data: rawptr) ---
	TexSubImage3D           :: proc(target: Enum, level: i32, xoffset, yoffset, width, height, depth: i32, format, type: Enum, size: int, data: rawptr) ---
	CompressedTexImage3D    :: proc(target: Enum, level: i32, internalformat: Enum, width, height, depth: i32, border: i32, imageSize: int, data: rawptr) ---
	CompressedTexSubImage3D :: proc(target: Enum, level: i32, xoffset, yoffset: i32, width, height, depth: i32, format: Enum, imageSize: int, data: rawptr) ---
	CopyTexSubImage3D       :: proc(target: Enum, level: i32, xoffset, yoffset, zoffset: i32, x, y, width, height: i32) ---
	
	/* Programs and shaders */
	GetFragDataLocation :: proc(program: Program, name: string) -> i32 ---
	
	/* Uniforms */
	Uniform1ui :: proc(location: i32, v0: u32) ---
	Uniform2ui :: proc(location: i32, v0: u32, v1: u32) ---
	Uniform3ui :: proc(location: i32, v0: u32, v1: u32, v2: u32) ---
	Uniform4ui :: proc(location: i32, v0: u32, v1: u32, v2: u32, v3: u32) ---

	/* Vertex attribs */
	VertexAttribI4i      :: proc(index: i32, x, y, z, w: i32) ---
	VertexAttribI4ui     :: proc(index: i32, x, y, z, w: u32) ---
	VertexAttribIPointer :: proc(index: i32, size: int, type: Enum, stride: int, offset: uintptr) ---
	
	/* Writing to the drawing buffer */
	VertexAttribDivisor   :: proc(index: u32, divisor: u32) ---
	DrawArraysInstanced   :: proc(mode: Enum, first, count: int, instanceCount: int) ---
	DrawElementsInstanced :: proc(mode: Enum, count: int, type: Enum, offset: int, instanceCount: int) ---
	DrawRangeElements     :: proc(mode: Enum, start, end, count: int, type: Enum, offset: int) ---
	
	/* Multiple Render Targets */
	DrawBuffers    :: proc(buffers: []Enum) ---
	ClearBufferfv  :: proc(buffer: Enum, drawbuffer: i32, values: []f32) ---
	ClearBufferiv  :: proc(buffer: Enum, drawbuffer: i32, values: []i32) ---
	ClearBufferuiv :: proc(buffer: Enum, drawbuffer: i32, values: []u32) ---
	ClearBufferfi  :: proc(buffer: Enum, drawbuffer: i32, depth: f32, stencil: i32) ---
	
	CreateQuery :: proc() -> Query ---
	DeleteQuery :: proc(query: Query) ---
	IsQuery     :: proc(query: Query) -> bool ---
	BeginQuery  :: proc(target: Enum, query: Query) ---
	EndQuery    :: proc(target: Enum) ---
	GetQuery    :: proc(target, pname: Enum) ---
	
	CreateSampler     :: proc() -> Sampler ---
	DeleteSampler     :: proc(sampler: Sampler) ---
	IsSampler         :: proc(sampler: Sampler) -> bool ---
	BindSampler       :: proc(unit: Enum, sampler: Sampler) ---
	SamplerParameteri :: proc(sampler: Sampler, pname: Enum, param: i32) ---
	SamplerParameterf :: proc(sampler: Sampler, pname: Enum, param: f32) ---
	
	FenceSync      :: proc(condition: Enum, flags: u32) -> Sync ---
	IsSync         :: proc(sync: Sync) -> bool ---
	DeleteSync     :: proc(sync: Sync) ---
	ClientWaitSync :: proc(sync: Sync, flags: u32, timeout: u64) ---
	WaitSync       :: proc(sync: Sync, flags: u32, timeout: i64) ---
	
	CreateTransformFeedback   :: proc() -> TransformFeedback ---
	DeleteTransformFeedback   :: proc(tf: TransformFeedback) ---
	IsTransformFeedback       :: proc(tf: TransformFeedback) -> bool ---
	BindTransformFeedback     :: proc(target: Enum, tf: TransformFeedback) ---
	BeginTransformFeedback    :: proc(primitiveMode: Enum) ---
	EndTransformFeedback      :: proc() ---
	TransformFeedbackVaryings :: proc(program: Program, varyings: []string, bufferMode: Enum) ---
	PauseTransformFeedback    :: proc() ---
	ResumeTransformFeedback   :: proc() ---
	
	BindBufferBase            :: proc(target: Enum, index: i32, buffer: Buffer) ---
	BindBufferRange           :: proc(target: Enum, index: i32, buffer: Buffer, offset: int, size: int) ---
	GetUniformBlockIndex      :: proc(program: Program, uniformBlockName: string) -> i32 ---
	UniformBlockBinding       :: proc(program: Program, uniformBlockIndex: i32, uniformBlockBinding: i32) ---
	
	CreateVertexArray :: proc() -> VertexArrayObject ---
	DeleteVertexArray :: proc(vertexArray: VertexArrayObject) ---
	IsVertexArray     :: proc(vertexArray: VertexArrayObject) -> bool ---
	BindVertexArray   :: proc(vertexArray: VertexArrayObject) ---	
}

GetActiveUniformBlockName :: proc(program: Program, uniformBlockIndex: i32, buf: []byte) -> string {
	foreign webgl2 {
		_GetActiveUniformBlockName :: proc "contextless" (program: Program, uniformBlockIndex: i32, buf: []byte, length: ^int) ---
	}
	n: int
	_GetActiveUniformBlockName(program, uniformBlockIndex, buf, &n)
	return string(buf[:n])	
}


Uniform1uiv :: proc "contextless" (location: i32, v: u32) {
	Uniform1ui(location, v)
}
Uniform2uiv :: proc "contextless" (location: i32, v: glm.uvec2) {
	Uniform2ui(location, v.x, v.y)
}
Uniform3uiv :: proc "contextless" (location: i32, v: glm.uvec3) {
	Uniform3ui(location, v.x, v.y, v.z)
}
Uniform4uiv :: proc "contextless" (location: i32, v: glm.uvec4) {
	Uniform4ui(location, v.x, v.y, v.z, v.w)
}

UniformMatrix3x2fv :: proc "contextless" (location: i32, m: glm.mat3x2) {
	foreign webgl2 {
		_UniformMatrix3x2fv :: proc "contextless" (location: i32, addr: [^]f32) ---
	}
	array := intrinsics.matrix_flatten(m)
	_UniformMatrix3x2fv(location, &array[0])
}
UniformMatrix4x2fv :: proc "contextless" (location: i32, m: glm.mat4x2) {
	foreign webgl2 {
		_UniformMatrix4x2fv :: proc "contextless" (location: i32, addr: [^]f32) ---
	}
	array := intrinsics.matrix_flatten(m)
	_UniformMatrix4x2fv(location, &array[0])
}
UniformMatrix2x3fv :: proc "contextless" (location: i32, m: glm.mat2x3) {
	foreign webgl2 {
		_UniformMatrix2x3fv :: proc "contextless" (location: i32, addr: [^]f32) ---
	}
	array := intrinsics.matrix_flatten(m)
	_UniformMatrix2x3fv(location, &array[0])
}
UniformMatrix4x3fv :: proc "contextless" (location: i32, m: glm.mat4x3) {
	foreign webgl2 {
		_UniformMatrix4x3fv :: proc "contextless" (location: i32, addr: [^]f32) ---
	}
	array := intrinsics.matrix_flatten(m)
	_UniformMatrix4x3fv(location, &array[0])
}
UniformMatrix2x4fv :: proc "contextless" (location: i32, m: glm.mat2x4) {
	foreign webgl2 {
		_UniformMatrix2x4fv :: proc "contextless" (location: i32, addr: [^]f32) ---
	}
	array := intrinsics.matrix_flatten(m)
	_UniformMatrix2x4fv(location, &array[0])
}
UniformMatrix3x4fv :: proc "contextless" (location: i32, m: glm.mat3x4) {
	foreign webgl2 {
		_UniformMatrix3x4fv :: proc "contextless" (location: i32, addr: [^]f32) ---
	}
	array := intrinsics.matrix_flatten(m)
	_UniformMatrix3x4fv(location, &array[0])
}

VertexAttribI4iv :: proc "contextless" (index: i32, v: glm.ivec4) {
	VertexAttribI4i(index, v.x, v.y, v.z, v.w)
}
VertexAttribI4uiv :: proc "contextless" (index: i32, v: glm.uvec4) {
	VertexAttribI4ui(index, v.x, v.y, v.z, v.w)
}
