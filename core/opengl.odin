#foreign_system_library lib "opengl32.lib" when ODIN_OS == "windows";
#import win32 "sys/windows.odin" when ODIN_OS == "windows";
#load "opengl_constants.odin";

Clear         :: proc(mask: u32)                                #foreign lib "glClear";
ClearColor    :: proc(r, g, b, a: f32)                          #foreign lib "glClearColor";
Begin         :: proc(mode: i32)                                #foreign lib "glBegin";
End           :: proc()                                         #foreign lib "glEnd";
Finish        :: proc()                                         #foreign lib "glFinish";
BlendFunc     :: proc(sfactor, dfactor: i32)                    #foreign lib "glBlendFunc";
Enable        :: proc(cap: i32)                                 #foreign lib "glEnable";
Disable       :: proc(cap: i32)                                 #foreign lib "glDisable";
GenTextures   :: proc(count: i32, result: ^u32)                 #foreign lib "glGenTextures";
DeleteTextures:: proc(count: i32, result: ^u32)                 #foreign lib "glDeleteTextures";
TexParameteri :: proc(target, pname, param: i32)                #foreign lib "glTexParameteri";
TexParameterf :: proc(target: i32, pname: i32, param: f32)      #foreign lib "glTexParameterf";
BindTexture   :: proc(target: i32, texture: u32)                #foreign lib "glBindTexture";
LoadIdentity  :: proc()                                         #foreign lib "glLoadIdentity";
Viewport      :: proc(x, y, width, height: i32)                 #foreign lib "glViewport";
Ortho         :: proc(left, right, bottom, top, near, far: f64) #foreign lib "glOrtho";
Color3f       :: proc(r, g, b: f32)                             #foreign lib "glColor3f";
Vertex3f      :: proc(x, y, z: f32)                             #foreign lib "glVertex3f";
TexImage2D    :: proc(target, level, internal_format,
                      width, height, border,
                      format, _type: i32, pixels: rawptr) #foreign lib "glTexImage2D";

GetError    :: proc() -> i32            #foreign lib "glGetError";
GetString   :: proc(name: i32) -> ^byte #foreign lib "glGetString";
GetIntegerv :: proc(name: i32, v: ^i32) #foreign lib "glGetIntegerv";


string_data :: proc(s: string) -> ^u8 #inline { return ^s[0]; }

_libgl := win32.LoadLibraryA(string_data("opengl32.dll\x00"));

GetProcAddress :: proc(name: string) -> proc() #cc_c {
	assert(name[name.count-1] == 0);
	res := win32.wglGetProcAddress(name.data);
	if res == nil {
		res = win32.GetProcAddress(_libgl, name.data);
	}
	return res;
}

GenBuffers:       proc(count: i32, buffers: ^u32) #cc_c;
GenVertexArrays:  proc(count: i32, buffers: ^u32) #cc_c;
GenSamplers:      proc(count: i32, buffers: ^u32) #cc_c;
BindBuffer:       proc(target: i32, buffer: u32) #cc_c;
BindVertexArray:  proc(buffer: u32) #cc_c;
BindSampler:      proc(position: i32, sampler: u32) #cc_c;
BufferData:       proc(target: i32, size: int, data: rawptr, usage: i32) #cc_c;
BufferSubData:    proc(target: i32, offset, size: int, data: rawptr) #cc_c;

DrawArrays:       proc(mode, first: i32, count: u32) #cc_c;
DrawElements:     proc(mode: i32, count: u32, type_: i32, indices: rawptr) #cc_c;

MapBuffer:        proc(target, access: i32) -> rawptr #cc_c;
UnmapBuffer:      proc(target: i32) #cc_c;

VertexAttribPointer:  proc(index: u32, size, type_: i32, normalized: i32, stride: u32, pointer: rawptr) #cc_c;
EnableVertexAttribArray:  proc(index: u32) #cc_c;

CreateShader:   proc(shader_type: i32) -> u32 #cc_c;
ShaderSource:   proc(shader: u32, count: u32, str: ^^byte, length: ^i32) #cc_c;
CompileShader:  proc(shader: u32) #cc_c;
CreateProgram:  proc() -> u32 #cc_c;
AttachShader:   proc(program, shader: u32) #cc_c;
DetachShader:   proc(program, shader: u32) #cc_c;
DeleteShader:   proc(shader:  u32) #cc_c;
LinkProgram:    proc(program: u32) #cc_c;
UseProgram:     proc(program: u32) #cc_c;
DeleteProgram:  proc(program: u32) #cc_c;


GetShaderiv:        proc(shader:  u32, pname: i32, params: ^i32) #cc_c;
GetProgramiv:       proc(program: u32, pname: i32, params: ^i32) #cc_c;
GetShaderInfoLog:   proc(shader:  u32, max_length: u32, length: ^u32, info_long: ^byte) #cc_c;
GetProgramInfoLog:  proc(program: u32, max_length: u32, length: ^u32, info_long: ^byte) #cc_c;

ActiveTexture:   proc(texture: i32) #cc_c;
GenerateMipmap:  proc(target:  i32) #cc_c;

SamplerParameteri:     proc(sampler: u32, pname: i32, param: i32) #cc_c;
SamplerParameterf:     proc(sampler: u32, pname: i32, param: f32) #cc_c;
SamplerParameteriv:    proc(sampler: u32, pname: i32, params: ^i32) #cc_c;
SamplerParameterfv:    proc(sampler: u32, pname: i32, params: ^f32) #cc_c;
SamplerParameterIiv:   proc(sampler: u32, pname: i32, params: ^i32) #cc_c;
SamplerParameterIuiv:  proc(sampler: u32, pname: i32, params: ^u32) #cc_c;


Uniform1i:         proc(loc: i32, v0: i32) #cc_c;
Uniform2i:         proc(loc: i32, v0, v1: i32) #cc_c;
Uniform3i:         proc(loc: i32, v0, v1, v2: i32) #cc_c;
Uniform4i:         proc(loc: i32, v0, v1, v2, v3: i32) #cc_c;
Uniform1f:         proc(loc: i32, v0: f32) #cc_c;
Uniform2f:         proc(loc: i32, v0, v1: f32) #cc_c;
Uniform3f:         proc(loc: i32, v0, v1, v2: f32) #cc_c;
Uniform4f:         proc(loc: i32, v0, v1, v2, v3: f32) #cc_c;
UniformMatrix4fv:  proc(loc: i32, count: u32, transpose: i32, value: ^f32) #cc_c;

GetUniformLocation:  proc(program: u32, name: ^byte) -> i32 #cc_c;

init :: proc() {
	set_proc_address :: proc(p: rawptr, name: string) #inline { (cast(^(proc() #cc_c))p)^ = GetProcAddress(name); }

	set_proc_address(^GenBuffers,      "glGenBuffers\x00");
	set_proc_address(^GenVertexArrays, "glGenVertexArrays\x00");
	set_proc_address(^GenSamplers,     "glGenSamplers\x00");
	set_proc_address(^BindBuffer,      "glBindBuffer\x00");
	set_proc_address(^BindSampler,     "glBindSampler\x00");
	set_proc_address(^BindVertexArray, "glBindVertexArray\x00");
	set_proc_address(^BufferData,      "glBufferData\x00");
	set_proc_address(^BufferSubData,   "glBufferSubData\x00");

	set_proc_address(^DrawArrays,      "glDrawArrays\x00");
	set_proc_address(^DrawElements,    "glDrawElements\x00");

	set_proc_address(^MapBuffer,   "glMapBuffer\x00");
	set_proc_address(^UnmapBuffer, "glUnmapBuffer\x00");

	set_proc_address(^VertexAttribPointer,     "glVertexAttribPointer\x00");
	set_proc_address(^EnableVertexAttribArray, "glEnableVertexAttribArray\x00");

	set_proc_address(^CreateShader,  "glCreateShader\x00");
	set_proc_address(^ShaderSource,  "glShaderSource\x00");
	set_proc_address(^CompileShader, "glCompileShader\x00");
	set_proc_address(^CreateProgram, "glCreateProgram\x00");
	set_proc_address(^AttachShader,  "glAttachShader\x00");
	set_proc_address(^DetachShader,  "glDetachShader\x00");
	set_proc_address(^DeleteShader,  "glDeleteShader\x00");
	set_proc_address(^LinkProgram,   "glLinkProgram\x00");
	set_proc_address(^UseProgram,    "glUseProgram\x00");
	set_proc_address(^DeleteProgram, "glDeleteProgram\x00");

	set_proc_address(^GetShaderiv,       "glGetShaderiv\x00");
	set_proc_address(^GetProgramiv,      "glGetProgramiv\x00");
	set_proc_address(^GetShaderInfoLog,  "glGetShaderInfoLog\x00");
	set_proc_address(^GetProgramInfoLog, "glGetProgramInfoLog\x00");

	set_proc_address(^ActiveTexture,  "glActiveTexture\x00");
	set_proc_address(^GenerateMipmap, "glGenerateMipmap\x00");

	set_proc_address(^Uniform1i,        "glUniform1i\x00");
	set_proc_address(^UniformMatrix4fv, "glUniformMatrix4fv\x00");

	set_proc_address(^GetUniformLocation, "glGetUniformLocation\x00");

	set_proc_address(^SamplerParameteri,    "glSamplerParameteri\x00");
	set_proc_address(^SamplerParameterf,    "glSamplerParameterf\x00");
	set_proc_address(^SamplerParameteriv,   "glSamplerParameteriv\x00");
	set_proc_address(^SamplerParameterfv,   "glSamplerParameterfv\x00");
	set_proc_address(^SamplerParameterIiv,  "glSamplerParameterIiv\x00");
	set_proc_address(^SamplerParameterIuiv, "glSamplerParameterIuiv\x00");
}

