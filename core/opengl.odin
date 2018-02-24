when ODIN_OS == "windows" {
	foreign import lib "system:opengl32.lib"
	import win32 "core:sys/windows.odin"
	import "core:sys/wgl.odin"
} else when ODIN_OS == "linux" {
	foreign import lib "system:gl"
}

export "core:opengl_constants.odin"

(ODIN_OS != "osx");

@(default_calling_convention="c", link_prefix="gl")
foreign lib {
	Clear          :: proc(mask: u32) ---;
	ClearColor     :: proc(r, g, b, a: f32) ---;
	Begin          :: proc(mode: i32) ---;
	End            :: proc() ---;
	Finish         :: proc() ---;
	BlendFunc      :: proc(sfactor, dfactor: i32) ---;
	Enable         :: proc(cap: i32) ---;
	Disable        :: proc(cap: i32) ---;
	GenTextures    :: proc(count: i32, result: ^u32) ---;
	DeleteTextures :: proc(count: i32, result: ^u32) ---;
	TexParameteri  :: proc(target, pname, param: i32) ---;
	TexParameterf  :: proc(target: i32, pname: i32, param: f32) ---;
	BindTexture    :: proc(target: i32, texture: u32) ---;
	LoadIdentity   :: proc() ---;
	Viewport       :: proc(x, y, width, height: i32) ---;
	Ortho          :: proc(left, right, bottom, top, near, far: f64) ---;
	Color3f        :: proc(r, g, b: f32) ---;
	Vertex3f       :: proc(x, y, z: f32) ---;
	GetError       :: proc() -> i32 ---;
	GetString      :: proc(name: i32) -> ^u8 ---;
	GetIntegerv    :: proc(name: i32, v: ^i32) ---;
	TexCoord2f     :: proc(x, y: f32) ---;
	TexImage2D     :: proc(target, level, internal_format: i32,
	                       width, height, border: i32,
	                       format, type_: i32, pixels: rawptr) ---;
}


_string_data :: inline proc(s: string) -> ^u8 do return &s[0];

_libgl := win32.load_library_a(_string_data("opengl32.dll\x00"));

get_gl_proc_address :: proc(name: string) -> rawptr {
	if name[len(name)-1] == 0 {
		name = name[..len(name)-1];
	}
	// NOTE(bill): null terminated
	assert((&name[0] + len(name))^ == 0);
	res := wgl.get_gl_proc_address(&name[0]);
	if res == nil {
		res = win32.get_proc_address(_libgl, &name[0]);
	}
	return rawptr(res);
}

// Procedures
	GenBuffers:               proc "c" (count: i32, buffers: ^u32);
	GenVertexArrays:          proc "c" (count: i32, buffers: ^u32);
	GenSamplers:              proc "c" (count: i32, buffers: ^u32);
	DeleteBuffers:            proc "c" (count: i32, buffers: ^u32);
	BindBuffer:               proc "c" (target: i32, buffer: u32);
	BindVertexArray:          proc "c" (buffer: u32);
	DeleteVertexArrays:       proc "c" (count: i32, arrays: ^u32);
	BindSampler:              proc "c" (position: i32, sampler: u32);
	BufferData:               proc "c" (target: i32, size: int, data: rawptr, usage: i32);
	BufferSubData:            proc "c" (target: i32, offset, size: int, data: rawptr);

	DrawArrays:               proc "c" (mode, first: i32, count: u32);
	DrawElements:             proc "c" (mode: i32, count: u32, type_: i32, indices: rawptr);

	MapBuffer:                proc "c" (target, access: i32) -> rawptr;
	UnmapBuffer:              proc "c" (target: i32);

	VertexAttribPointer:      proc "c" (index: u32, size, type_: i32, normalized: i32, stride: u32, pointer: rawptr);
	EnableVertexAttribArray:  proc "c" (index: u32);

	CreateShader:             proc "c" (shader_type: i32) -> u32;
	ShaderSource:             proc "c" (shader: u32, count: u32, str: ^^u8, length: ^i32);
	CompileShader:            proc "c" (shader: u32);
	CreateProgram:            proc "c" () -> u32;
	AttachShader:             proc "c" (program, shader: u32);
	DetachShader:             proc "c" (program, shader: u32);
	DeleteShader:             proc "c" (shader:  u32);
	LinkProgram:              proc "c" (program: u32);
	UseProgram:               proc "c" (program: u32);
	DeleteProgram:            proc "c" (program: u32);


	GetShaderiv:              proc "c" (shader:  u32, pname: i32, params: ^i32);
	GetProgramiv:             proc "c" (program: u32, pname: i32, params: ^i32);
	GetShaderInfoLog:         proc "c" (shader:  u32, max_length: u32, length: ^u32, info_long: ^u8);
	GetProgramInfoLog:        proc "c" (program: u32, max_length: u32, length: ^u32, info_long: ^u8);

	ActiveTexture:            proc "c" (texture: i32);
	GenerateMipmap:           proc "c" (target:  i32);

	SamplerParameteri:        proc "c" (sampler: u32, pname: i32, param: i32);
	SamplerParameterf:        proc "c" (sampler: u32, pname: i32, param: f32);
	SamplerParameteriv:       proc "c" (sampler: u32, pname: i32, params: ^i32);
	SamplerParameterfv:       proc "c" (sampler: u32, pname: i32, params: ^f32);
	SamplerParameterIiv:      proc "c" (sampler: u32, pname: i32, params: ^i32);
	SamplerParameterIuiv:     proc "c" (sampler: u32, pname: i32, params: ^u32);


	Uniform1i:                proc "c" (loc: i32, v0: i32);
	Uniform2i:                proc "c" (loc: i32, v0, v1: i32);
	Uniform3i:                proc "c" (loc: i32, v0, v1, v2: i32);
	Uniform4i:                proc "c" (loc: i32, v0, v1, v2, v3: i32);
	Uniform1f:                proc "c" (loc: i32, v0: f32);
	Uniform2f:                proc "c" (loc: i32, v0, v1: f32);
	Uniform3f:                proc "c" (loc: i32, v0, v1, v2: f32);
	Uniform4f:                proc "c" (loc: i32, v0, v1, v2, v3: f32);
	UniformMatrix4fv:         proc "c" (loc: i32, count: u32, transpose: i32, value: ^f32);

	GetUniformLocation:       proc "c" (program: u32, name: ^u8) -> i32;


init :: proc() {
	set_proc_address :: proc(p: rawptr, name: string) {
		x := cast(^rawptr)p;
		x^ = get_gl_proc_address(name);
	}

	set_proc_address(&GenBuffers,              "glGenBuffers\x00");
	set_proc_address(&GenVertexArrays,         "glGenVertexArrays\x00");
	set_proc_address(&GenSamplers,             "glGenSamplers\x00");
	set_proc_address(&DeleteBuffers,           "glDeleteBuffers\x00");
	set_proc_address(&BindBuffer,              "glBindBuffer\x00");
	set_proc_address(&BindSampler,             "glBindSampler\x00");
	set_proc_address(&BindVertexArray,         "glBindVertexArray\x00");
	set_proc_address(&DeleteVertexArrays,      "glDeleteVertexArrays\x00");
	set_proc_address(&BufferData,              "glBufferData\x00");
	set_proc_address(&BufferSubData,           "glBufferSubData\x00");

	set_proc_address(&DrawArrays,              "glDrawArrays\x00");
	set_proc_address(&DrawElements,            "glDrawElements\x00");

	set_proc_address(&MapBuffer,               "glMapBuffer\x00");
	set_proc_address(&UnmapBuffer,             "glUnmapBuffer\x00");

	set_proc_address(&VertexAttribPointer,     "glVertexAttribPointer\x00");
	set_proc_address(&EnableVertexAttribArray, "glEnableVertexAttribArray\x00");

	set_proc_address(&CreateShader,            "glCreateShader\x00");
	set_proc_address(&ShaderSource,            "glShaderSource\x00");
	set_proc_address(&CompileShader,           "glCompileShader\x00");
	set_proc_address(&CreateProgram,           "glCreateProgram\x00");
	set_proc_address(&AttachShader,            "glAttachShader\x00");
	set_proc_address(&DetachShader,            "glDetachShader\x00");
	set_proc_address(&DeleteShader,            "glDeleteShader\x00");
	set_proc_address(&LinkProgram,             "glLinkProgram\x00");
	set_proc_address(&UseProgram,              "glUseProgram\x00");
	set_proc_address(&DeleteProgram,           "glDeleteProgram\x00");

	set_proc_address(&GetShaderiv,             "glGetShaderiv\x00");
	set_proc_address(&GetProgramiv,            "glGetProgramiv\x00");
	set_proc_address(&GetShaderInfoLog,        "glGetShaderInfoLog\x00");
	set_proc_address(&GetProgramInfoLog,       "glGetProgramInfoLog\x00");

	set_proc_address(&ActiveTexture,           "glActiveTexture\x00");
	set_proc_address(&GenerateMipmap,          "glGenerateMipmap\x00");

	set_proc_address(&Uniform1i,               "glUniform1i\x00");
	set_proc_address(&UniformMatrix4fv,        "glUniformMatrix4fv\x00");

	set_proc_address(&GetUniformLocation,      "glGetUniformLocation\x00");

	set_proc_address(&SamplerParameteri,       "glSamplerParameteri\x00");
	set_proc_address(&SamplerParameterf,       "glSamplerParameterf\x00");
	set_proc_address(&SamplerParameteriv,      "glSamplerParameteriv\x00");
	set_proc_address(&SamplerParameterfv,      "glSamplerParameterfv\x00");
	set_proc_address(&SamplerParameterIiv,     "glSamplerParameterIiv\x00");
	set_proc_address(&SamplerParameterIuiv,    "glSamplerParameterIuiv\x00");
}

