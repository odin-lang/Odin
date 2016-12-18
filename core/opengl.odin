#foreign_system_library "opengl32" when ODIN_OS == "windows";
#import win32 "sys/windows.odin" when ODIN_OS == "windows";
#include "opengl_constants.odin";

proc Clear         (mask: u32)                                #foreign "glClear"
proc ClearColor    (r, g, b, a: f32)                          #foreign "glClearColor"
proc Begin         (mode: i32)                                #foreign "glBegin"
proc End           ()                                         #foreign "glEnd"
proc Finish        ()                                         #foreign "glFinish"
proc BlendFunc     (sfactor, dfactor: i32)                    #foreign "glBlendFunc"
proc Enable        (cap: i32)                                 #foreign "glEnable"
proc Disable       (cap: i32)                                 #foreign "glDisable"
proc GenTextures   (count: i32, result: ^u32)                 #foreign "glGenTextures"
proc DeleteTextures(count: i32, result: ^u32)                 #foreign "glDeleteTextures"
proc TexParameteri (target, pname, param: i32)                #foreign "glTexParameteri"
proc TexParameterf (target: i32, pname: i32, param: f32)      #foreign "glTexParameterf"
proc BindTexture   (target: i32, texture: u32)                #foreign "glBindTexture"
proc LoadIdentity  ()                                         #foreign "glLoadIdentity"
proc Viewport      (x, y, width, height: i32)                 #foreign "glViewport"
proc Ortho         (left, right, bottom, top, near, far: f64) #foreign "glOrtho"
proc Color3f       (r, g, b: f32)                             #foreign "glColor3f"
proc Vertex3f      (x, y, z: f32)                             #foreign "glVertex3f"
proc TexImage2D    (target, level, internal_format,
                    width, height, border,
                    format, _type: i32, pixels: rawptr) #foreign "glTexImage2D"

proc GetError   () -> i32            #foreign "glGetError"
proc GetString  (name: i32) -> ^byte #foreign "glGetString"
proc GetIntegerv(name: i32, v: ^i32) #foreign "glGetIntegerv"



_libgl := win32.LoadLibraryA(("opengl32.dll\x00" as string).data);

proc GetProcAddress(name: string) -> proc() {
	assert(name[name.count-1] == 0);
	res := win32.wglGetProcAddress(name.data);
	if res == nil {
		res = win32.GetProcAddress(_libgl, name.data);
	}
	return res;
}


GenBuffers:      proc(count: i32, buffers: ^u32);
GenVertexArrays: proc(count: i32, buffers: ^u32);
GenSamplers:     proc(count: i32, buffers: ^u32);
BindBuffer:      proc(target: i32, buffer: u32);
BindVertexArray: proc(buffer: u32);
BindSampler:     proc(position: i32, sampler: u32);
BufferData:      proc(target: i32, size: int, data: rawptr, usage: i32);
BufferSubData:   proc(target: i32, offset, size: int, data: rawptr);

DrawArrays:      proc(mode, first: i32, count: u32);
DrawElements:    proc(mode: i32, count: u32, type_: i32, indices: rawptr);

MapBuffer:       proc(target, access: i32) -> rawptr;
UnmapBuffer:     proc(target: i32);

VertexAttribPointer: proc(index: u32, size, type_: i32, normalized: i32, stride: u32, pointer: rawptr);
EnableVertexAttribArray: proc(index: u32);

CreateShader:  proc(shader_type: i32) -> u32;
ShaderSource:  proc(shader: u32, count: u32, string: ^^byte, length: ^i32);
CompileShader: proc(shader: u32);
CreateProgram: proc() -> u32;
AttachShader:  proc(program, shader: u32);
DetachShader:  proc(program, shader: u32);
DeleteShader:  proc(shader: u32);
LinkProgram:   proc(program: u32);
UseProgram:    proc(program: u32);
DeleteProgram: proc(program: u32);


GetShaderiv:       proc(shader:  u32, pname: i32, params: ^i32);
GetProgramiv:      proc(program: u32, pname: i32, params: ^i32);
GetShaderInfoLog:  proc(shader:  u32, max_length: u32, length: ^u32, info_long: ^byte);
GetProgramInfoLog: proc(program: u32, max_length: u32, length: ^u32, info_long: ^byte);

ActiveTexture:  proc(texture: i32);
GenerateMipmap: proc(target: i32);

SamplerParameteri:    proc(sampler: u32, pname: i32, param: i32);
SamplerParameterf:    proc(sampler: u32, pname: i32, param: f32);
SamplerParameteriv:   proc(sampler: u32, pname: i32, params: ^i32);
SamplerParameterfv:   proc(sampler: u32, pname: i32, params: ^f32);
SamplerParameterIiv:  proc(sampler: u32, pname: i32, params: ^i32);
SamplerParameterIuiv: proc(sampler: u32, pname: i32, params: ^u32);


Uniform1i:        proc(loc: i32, v0: i32);
Uniform2i:        proc(loc: i32, v0, v1: i32);
Uniform3i:        proc(loc: i32, v0, v1, v2: i32);
Uniform4i:        proc(loc: i32, v0, v1, v2, v3: i32);
Uniform1f:        proc(loc: i32, v0: f32);
Uniform2f:        proc(loc: i32, v0, v1: f32);
Uniform3f:        proc(loc: i32, v0, v1, v2: f32);
Uniform4f:        proc(loc: i32, v0, v1, v2, v3: f32);
UniformMatrix4fv: proc(loc: i32, count: u32, transpose: i32, value: ^f32);

GetUniformLocation: proc(program: u32, name: ^byte) -> i32;

proc init() {
	proc set_proc_address(p: rawptr, name: string) #inline { (p as ^proc())^ = GetProcAddress(name); }

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

