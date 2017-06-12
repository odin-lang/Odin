#foreign_system_library lib "opengl32.lib" when ODIN_OS == "windows";
#foreign_system_library lib "gl" when ODIN_OS == "linux";
#import win32 "sys/windows.odin" when ODIN_OS == "windows";
#import "sys/wgl.odin" when ODIN_OS == "windows";
#load "opengl_constants.odin";

proc Clear         (mask: u32)                                #foreign lib "glClear";
proc ClearColor    (r, g, b, a: f32)                          #foreign lib "glClearColor";
proc Begin         (mode: i32)                                #foreign lib "glBegin";
proc End           ()                                         #foreign lib "glEnd";
proc Finish        ()                                         #foreign lib "glFinish";
proc BlendFunc     (sfactor, dfactor: i32)                    #foreign lib "glBlendFunc";
proc Enable        (cap: i32)                                 #foreign lib "glEnable";
proc Disable       (cap: i32)                                 #foreign lib "glDisable";
proc GenTextures   (count: i32, result: ^u32)                 #foreign lib "glGenTextures";
proc DeleteTextures(count: i32, result: ^u32)                 #foreign lib "glDeleteTextures";
proc TexParameteri (target, pname, param: i32)                #foreign lib "glTexParameteri";
proc TexParameterf (target: i32, pname: i32, param: f32)      #foreign lib "glTexParameterf";
proc BindTexture   (target: i32, texture: u32)                #foreign lib "glBindTexture";
proc LoadIdentity  ()                                         #foreign lib "glLoadIdentity";
proc Viewport      (x, y, width, height: i32)                 #foreign lib "glViewport";
proc Ortho         (left, right, bottom, top, near, far: f64) #foreign lib "glOrtho";
proc Color3f       (r, g, b: f32)                             #foreign lib "glColor3f";
proc Vertex3f      (x, y, z: f32)                             #foreign lib "glVertex3f";
proc GetError      () -> i32                                  #foreign lib "glGetError";
proc GetString     (name: i32) -> ^u8                         #foreign lib "glGetString";
proc GetIntegerv   (name: i32, v: ^i32)                       #foreign lib "glGetIntegerv";
proc TexCoord2f    (x, y: f32)                                #foreign lib "glTexCoord2f";
proc TexImage2D    (target, level, internal_format,
                    width, height, border,
                    format, type_: i32, pixels: rawptr)       #foreign lib "glTexImage2D";


proc _string_data(s: string) -> ^u8 #inline { return &s[0]; }

var _libgl = win32.load_library_a(_string_data("opengl32.dll\x00"));

proc get_proc_address(name: string) -> proc() #cc_c {
	if name[len(name)-1] == 0 {
		name = name[0..<len(name)-1];
	}
	// NOTE(bill): null terminated
	assert((&name[0] + len(name))^ == 0);
	var res = wgl.get_proc_address(&name[0]);
	if res == nil {
		res = win32.get_proc_address(_libgl, &name[0]);
	}
	return res;
}

var GenBuffers:               proc(count: i32, buffers: ^u32) #cc_c;
var GenVertexArrays:          proc(count: i32, buffers: ^u32) #cc_c;
var GenSamplers:              proc(count: i32, buffers: ^u32) #cc_c;
var DeleteBuffers:            proc(count: i32, buffers: ^u32) #cc_c;
var BindBuffer:               proc(target: i32, buffer: u32) #cc_c;
var BindVertexArray:          proc(buffer: u32) #cc_c;
var DeleteVertexArrays:       proc(count: i32, arrays: ^u32) #cc_c;
var BindSampler:              proc(position: i32, sampler: u32) #cc_c;
var BufferData:               proc(target: i32, size: int, data: rawptr, usage: i32) #cc_c;
var BufferSubData:            proc(target: i32, offset, size: int, data: rawptr) #cc_c;

var DrawArrays:               proc(mode, first: i32, count: u32) #cc_c;
var DrawElements:             proc(mode: i32, count: u32, type_: i32, indices: rawptr) #cc_c;

var MapBuffer:                proc(target, access: i32) -> rawptr #cc_c;
var UnmapBuffer:              proc(target: i32) #cc_c;

var VertexAttribPointer:      proc(index: u32, size, type_: i32, normalized: i32, stride: u32, pointer: rawptr) #cc_c;
var EnableVertexAttribArray:  proc(index: u32) #cc_c;

var CreateShader:             proc(shader_type: i32) -> u32 #cc_c;
var ShaderSource:             proc(shader: u32, count: u32, str: ^^u8, length: ^i32) #cc_c;
var CompileShader:            proc(shader: u32) #cc_c;
var CreateProgram:            proc() -> u32 #cc_c;
var AttachShader:             proc(program, shader: u32) #cc_c;
var DetachShader:             proc(program, shader: u32) #cc_c;
var DeleteShader:             proc(shader:  u32) #cc_c;
var LinkProgram:              proc(program: u32) #cc_c;
var UseProgram:               proc(program: u32) #cc_c;
var DeleteProgram:            proc(program: u32) #cc_c;


var GetShaderiv:              proc(shader:  u32, pname: i32, params: ^i32) #cc_c;
var GetProgramiv:             proc(program: u32, pname: i32, params: ^i32) #cc_c;
var GetShaderInfoLog:         proc(shader:  u32, max_length: u32, length: ^u32, info_long: ^u8) #cc_c;
var GetProgramInfoLog:        proc(program: u32, max_length: u32, length: ^u32, info_long: ^u8) #cc_c;

var ActiveTexture:            proc(texture: i32) #cc_c;
var GenerateMipmap:           proc(target:  i32) #cc_c;

var SamplerParameteri:        proc(sampler: u32, pname: i32, param: i32) #cc_c;
var SamplerParameterf:        proc(sampler: u32, pname: i32, param: f32) #cc_c;
var SamplerParameteriv:       proc(sampler: u32, pname: i32, params: ^i32) #cc_c;
var SamplerParameterfv:       proc(sampler: u32, pname: i32, params: ^f32) #cc_c;
var SamplerParameterIiv:      proc(sampler: u32, pname: i32, params: ^i32) #cc_c;
var SamplerParameterIuiv:     proc(sampler: u32, pname: i32, params: ^u32) #cc_c;


var Uniform1i:                proc(loc: i32, v0: i32) #cc_c;
var Uniform2i:                proc(loc: i32, v0, v1: i32) #cc_c;
var Uniform3i:                proc(loc: i32, v0, v1, v2: i32) #cc_c;
var Uniform4i:                proc(loc: i32, v0, v1, v2, v3: i32) #cc_c;
var Uniform1f:                proc(loc: i32, v0: f32) #cc_c;
var Uniform2f:                proc(loc: i32, v0, v1: f32) #cc_c;
var Uniform3f:                proc(loc: i32, v0, v1, v2: f32) #cc_c;
var Uniform4f:                proc(loc: i32, v0, v1, v2, v3: f32) #cc_c;
var UniformMatrix4fv:         proc(loc: i32, count: u32, transpose: i32, value: ^f32) #cc_c;

var GetUniformLocation:       proc(program: u32, name: ^u8) -> i32 #cc_c;

proc init() {
	proc set_proc_address(p: rawptr, name: string) #inline {
		var x = ^(proc() #cc_c)(p);
		x^ = get_proc_address(name);
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

