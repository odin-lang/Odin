// OpenGL function pointer loader implemented in Odin. Supports the `core` profile up to version 4.6.
package vendor_gl

// Helper for loading shaders into a program

import "core:os"
import "core:fmt"
import "core:strings"
import "base:runtime"
_ :: fmt
_ :: runtime

Shader_Type :: enum i32 {
	NONE = 0x0000,
	FRAGMENT_SHADER        = 0x8B30,
	VERTEX_SHADER          = 0x8B31,
	GEOMETRY_SHADER        = 0x8DD9,
	COMPUTE_SHADER         = 0x91B9,
	TESS_EVALUATION_SHADER = 0x8E87,
	TESS_CONTROL_SHADER    = 0x8E88,
	SHADER_LINK            = -1, // @Note: Not an OpenGL constant, but used for error checking.
}


@(private, thread_local)
last_compile_error_message: []byte
@(private, thread_local)
last_link_error_message: []byte

@(private, thread_local)
last_compile_error_type: Shader_Type
@(private, thread_local)
last_link_error_type: Shader_Type

get_last_error_messages :: proc() -> (compile_message: string, compile_type: Shader_Type, link_message: string, link_type: Shader_Type) {
	compile_message = string(last_compile_error_message[:max(0, len(last_compile_error_message)-1)])
	compile_type = last_compile_error_type
	link_message = string(last_link_error_message[:max(0, len(last_link_error_message)-1)])
	link_type = last_link_error_type
	return
}

get_last_error_message :: proc() -> (compile_message: string, compile_type: Shader_Type) {
	compile_message = string(last_compile_error_message[:max(0, len(last_compile_error_message)-1)])
	compile_type = last_compile_error_type
	return
}

// Shader checking and linking checking are identical
// except for calling differently named GL functions
// it's a bit ugly looking, but meh
when GL_DEBUG {
	@private
	check_error :: proc(
		id: u32, type: Shader_Type, status: u32,
		iv_func: proc "c" (u32, u32, [^]i32, runtime.Source_Code_Location),
		log_func: proc "c" (u32, i32, ^i32, [^]u8, runtime.Source_Code_Location), 
		loc := #caller_location,
	) -> (success: bool) {
		result, info_log_length: i32
		iv_func(id, status, &result, loc)
		iv_func(id, INFO_LOG_LENGTH, &info_log_length, loc)

		if result == 0 {
			if log_func == GetShaderInfoLog {
				delete(last_compile_error_message)
				last_compile_error_message = make([]byte, info_log_length)
				last_compile_error_type = type

				log_func(id, i32(info_log_length), nil, raw_data(last_compile_error_message), loc)
				//fmt.printf_err("Error in %v:\n%s", type, string(last_compile_error_message[0:len(last_compile_error_message)-1]));
			} else {

				delete(last_link_error_message)
				last_link_error_message = make([]byte, info_log_length)
				last_compile_error_type = type

				log_func(id, i32(info_log_length), nil, raw_data(last_link_error_message), loc)
				//fmt.printf_err("Error in %v:\n%s", type, string(last_link_error_message[0:len(last_link_error_message)-1]));
			}

			return false
		}

		return true
	}
} else {
	@private
	check_error :: proc(
		id: u32, type: Shader_Type, status: u32,
		iv_func: proc "c" (u32, u32, [^]i32),
		log_func: proc "c" (u32, i32, ^i32, [^]u8),
	) -> (success: bool) {
		result, info_log_length: i32
		iv_func(id, status, &result)
		iv_func(id, INFO_LOG_LENGTH, &info_log_length)

		if result == 0 {
			if log_func == GetShaderInfoLog {
				delete(last_compile_error_message)
				last_compile_error_message = make([]u8, info_log_length)
				last_link_error_type = type

				log_func(id, i32(info_log_length), nil, raw_data(last_compile_error_message))
				fmt.eprintf("Error in %v:\n%s", type, string(last_compile_error_message[0:len(last_compile_error_message)-1]))
			} else {
				delete(last_link_error_message)
				last_link_error_message = make([]u8, info_log_length)
				last_link_error_type = type

				log_func(id, i32(info_log_length), nil, raw_data(last_link_error_message))
				fmt.eprintf("Error in %v:\n%s", type, string(last_link_error_message[0:len(last_link_error_message)-1]))

			}

			return false
		}

		return true
	}
}

// Compiling shaders are identical for any shader (vertex, geometry, fragment, tesselation, (maybe compute too))
compile_shader_from_source :: proc(shader_data: string, shader_type: Shader_Type) -> (shader_id: u32, ok: bool) {
	shader_id = CreateShader(cast(u32)shader_type)
	length := i32(len(shader_data))
	shader_data_copy := cstring(raw_data(shader_data))
	ShaderSource(shader_id, 1, &shader_data_copy, &length)
	CompileShader(shader_id)

	check_error(shader_id, shader_type, COMPILE_STATUS, GetShaderiv, GetShaderInfoLog) or_return
	ok = true
	return
}

// only used once, but I'd just make a subprocedure(?) for consistency
create_and_link_program :: proc(shader_ids: []u32, binary_retrievable := false) -> (program_id: u32, ok: bool) {
	program_id = CreateProgram()
	for id in shader_ids {
		AttachShader(program_id, id)
	}
	if binary_retrievable {
		ProgramParameteri(program_id, PROGRAM_BINARY_RETRIEVABLE_HINT, 1/*true*/)
	}
	LinkProgram(program_id)

	check_error(program_id, Shader_Type.SHADER_LINK, LINK_STATUS, GetProgramiv, GetProgramInfoLog) or_return
	ok = true
	return
}

load_compute_file :: proc(filename: string, binary_retrievable := false) -> (program_id: u32, ok: bool) {
	cs_data := os.read_entire_file(filename) or_return
	defer delete(cs_data)

	// Create the shaders
	compute_shader_id := compile_shader_from_source(string(cs_data), Shader_Type(COMPUTE_SHADER)) or_return
	return create_and_link_program([]u32{compute_shader_id}, binary_retrievable)
}

load_compute_source :: proc(cs_data: string, binary_retrievable := false) -> (program_id: u32, ok: bool) {
	// Create the shaders
	compute_shader_id := compile_shader_from_source(cs_data, Shader_Type(COMPUTE_SHADER)) or_return
	return create_and_link_program([]u32{compute_shader_id}, binary_retrievable)
}

load_shaders_file :: proc(vs_filename, fs_filename: string, binary_retrievable := false) -> (program_id: u32, ok: bool) {
	vs_data := os.read_entire_file(vs_filename) or_return
	defer delete(vs_data)
	
	fs_data := os.read_entire_file(fs_filename) or_return
	defer delete(fs_data)

	return load_shaders_source(string(vs_data), string(fs_data), binary_retrievable)
}

load_shaders_source :: proc(vs_source, fs_source: string, binary_retrievable := false) -> (program_id: u32, ok: bool) {
	// actual function from here
	vertex_shader_id := compile_shader_from_source(vs_source, Shader_Type.VERTEX_SHADER) or_return
	defer DeleteShader(vertex_shader_id)

	fragment_shader_id := compile_shader_from_source(fs_source, Shader_Type.FRAGMENT_SHADER) or_return
	defer DeleteShader(fragment_shader_id)

	return create_and_link_program([]u32{vertex_shader_id, fragment_shader_id}, binary_retrievable)
}

load_shaders :: proc{load_shaders_file}


when ODIN_OS == .Windows {
	update_shader_if_changed :: proc(
		vertex_name, fragment_name: string, 
		program: u32, 
		last_vertex_time, last_fragment_time: os.File_Time,
	) -> (
		old_program: u32, 
		current_vertex_time, current_fragment_time: os.File_Time, 
		updated: bool,
	) {
		current_vertex_time, _ = os.last_write_time_by_name(vertex_name)
		current_fragment_time, _ = os.last_write_time_by_name(fragment_name)
		old_program = program

		if current_vertex_time != last_vertex_time || current_fragment_time != last_fragment_time {
			new_program, success := load_shaders(vertex_name, fragment_name)
			if success {
				DeleteProgram(old_program)
				old_program = new_program
				fmt.println("Updated shaders")
				updated = true
			} else {
				fmt.println("Failed to update shaders")
			}
		}

		return old_program, current_vertex_time, current_fragment_time, updated
	}

	update_shader_if_changed_compute :: proc(
		compute_name: string, 
		program: u32, 
		last_compute_time: os.File_Time,
	) -> (
		old_program: u32, 
		current_compute_time: os.File_Time, 
		updated: bool,
	) {
		current_compute_time, _ = os.last_write_time_by_name(compute_name)
		old_program = program

		if current_compute_time != last_compute_time {
			new_program, success := load_compute_file(compute_name)
			if success {
				DeleteProgram(old_program)
				old_program = new_program
				fmt.println("Updated shaders")
				updated = true
			} else {
				fmt.println("Failed to update shaders")
			}
		}

		return old_program, current_compute_time, updated
	}
}


Uniform_Type :: enum i32 {
	FLOAT      = 0x1406,
	FLOAT_VEC2 = 0x8B50,
	FLOAT_VEC3 = 0x8B51,
	FLOAT_VEC4 = 0x8B52,

	DOUBLE      = 0x140A,
	DOUBLE_VEC2 = 0x8FFC,
	DOUBLE_VEC3 = 0x8FFD,
	DOUBLE_VEC4 = 0x8FFE,

	INT      = 0x1404,
	INT_VEC2 = 0x8B53,
	INT_VEC3 = 0x8B54,
	INT_VEC4 = 0x8B55,

	UNSIGNED_INT      = 0x1405,
	UNSIGNED_INT_VEC2 = 0x8DC6,
	UNSIGNED_INT_VEC3 = 0x8DC7,
	UNSIGNED_INT_VEC4 = 0x8DC8,

	BOOL      = 0x8B56,
	BOOL_VEC2 = 0x8B57,
	BOOL_VEC3 = 0x8B58,
	BOOL_VEC4 = 0x8B59,

	FLOAT_MAT2   = 0x8B5A,
	FLOAT_MAT3   = 0x8B5B,
	FLOAT_MAT4   = 0x8B5C,
	FLOAT_MAT2x3 = 0x8B65,
	FLOAT_MAT2x4 = 0x8B66,
	FLOAT_MAT3x2 = 0x8B67,
	FLOAT_MAT3x4 = 0x8B68,
	FLOAT_MAT4x2 = 0x8B69,
	FLOAT_MAT4x3 = 0x8B6A,

	DOUBLE_MAT2   = 0x8F46,
	DOUBLE_MAT3   = 0x8F47,
	DOUBLE_MAT4   = 0x8F48,
	DOUBLE_MAT2x3 = 0x8F49,
	DOUBLE_MAT2x4 = 0x8F4A,
	DOUBLE_MAT3x2 = 0x8F4B,
	DOUBLE_MAT3x4 = 0x8F4C,
	DOUBLE_MAT4x2 = 0x8F4D,
	DOUBLE_MAT4x3 = 0x8F4E,

	SAMPLER_1D                   = 0x8B5D,
	SAMPLER_2D                   = 0x8B5E,
	SAMPLER_3D                   = 0x8B5F,
	SAMPLER_CUBE                 = 0x8B60,
	SAMPLER_1D_SHADOW            = 0x8B61,
	SAMPLER_2D_SHADOW            = 0x8B62,
	SAMPLER_1D_ARRAY             = 0x8DC0,
	SAMPLER_2D_ARRAY             = 0x8DC1,
	SAMPLER_1D_ARRAY_SHADOW      = 0x8DC3,
	SAMPLER_2D_ARRAY_SHADOW      = 0x8DC4,
	SAMPLER_2D_MULTISAMPLE       = 0x9108,
	SAMPLER_2D_MULTISAMPLE_ARRAY = 0x910B,
	SAMPLER_CUBE_SHADOW          = 0x8DC5,
	SAMPLER_BUFFER               = 0x8DC2,
	SAMPLER_2D_RECT              = 0x8B63,
	SAMPLER_2D_RECT_SHADOW       = 0x8B64,

	INT_SAMPLER_1D                   = 0x8DC9,
	INT_SAMPLER_2D                   = 0x8DCA,
	INT_SAMPLER_3D                   = 0x8DCB,
	INT_SAMPLER_CUBE                 = 0x8DCC,
	INT_SAMPLER_1D_ARRAY             = 0x8DCE,
	INT_SAMPLER_2D_ARRAY             = 0x8DCF,
	INT_SAMPLER_2D_MULTISAMPLE       = 0x9109,
	INT_SAMPLER_2D_MULTISAMPLE_ARRAY = 0x910C,
	INT_SAMPLER_BUFFER               = 0x8DD0,
	INT_SAMPLER_2D_RECT              = 0x8DCD,

	UNSIGNED_INT_SAMPLER_1D                   = 0x8DD1,
	UNSIGNED_INT_SAMPLER_2D                   = 0x8DD2,
	UNSIGNED_INT_SAMPLER_3D                   = 0x8DD3,
	UNSIGNED_INT_SAMPLER_CUBE                 = 0x8DD4,
	UNSIGNED_INT_SAMPLER_1D_ARRAY             = 0x8DD6,
	UNSIGNED_INT_SAMPLER_2D_ARRAY             = 0x8DD7,
	UNSIGNED_INT_SAMPLER_2D_MULTISAMPLE       = 0x910A,
	UNSIGNED_INT_SAMPLER_2D_MULTISAMPLE_ARRAY = 0x910D,
	UNSIGNED_INT_SAMPLER_BUFFER               = 0x8DD8,
	UNSIGNED_INT_SAMPLER_2D_RECT              = 0x8DD5,

	IMAGE_1D                   = 0x904C,
	IMAGE_2D                   = 0x904D,
	IMAGE_3D                   = 0x904E,
	IMAGE_2D_RECT              = 0x904F,
	IMAGE_CUBE                 = 0x9050,
	IMAGE_BUFFER               = 0x9051,
	IMAGE_1D_ARRAY             = 0x9052,
	IMAGE_2D_ARRAY             = 0x9053,
	IMAGE_CUBE_MAP_ARRAY       = 0x9054,
	IMAGE_2D_MULTISAMPLE       = 0x9055,
	IMAGE_2D_MULTISAMPLE_ARRAY = 0x9056,

	INT_IMAGE_1D                   = 0x9057,
	INT_IMAGE_2D                   = 0x9058,
	INT_IMAGE_3D                   = 0x9059,
	INT_IMAGE_2D_RECT              = 0x905A,
	INT_IMAGE_CUBE                 = 0x905B,
	INT_IMAGE_BUFFER               = 0x905C,
	INT_IMAGE_1D_ARRAY             = 0x905D,
	INT_IMAGE_2D_ARRAY             = 0x905E,
	INT_IMAGE_CUBE_MAP_ARRAY       = 0x905F,
	INT_IMAGE_2D_MULTISAMPLE       = 0x9060,
	INT_IMAGE_2D_MULTISAMPLE_ARRAY = 0x9061,

	UNSIGNED_INT_IMAGE_1D                   = 0x9062,
	UNSIGNED_INT_IMAGE_2D                   = 0x9063,
	UNSIGNED_INT_IMAGE_3D                   = 0x9064,
	UNSIGNED_INT_IMAGE_2D_RECT              = 0x9065,
	UNSIGNED_INT_IMAGE_CUBE                 = 0x9066,
	UNSIGNED_INT_IMAGE_BUFFER               = 0x9067,
	UNSIGNED_INT_IMAGE_1D_ARRAY             = 0x9068,
	UNSIGNED_INT_IMAGE_2D_ARRAY             = 0x9069,
	UNSIGNED_INT_IMAGE_CUBE_MAP_ARRAY       = 0x906A,
	UNSIGNED_INT_IMAGE_2D_MULTISAMPLE       = 0x906B,
	UNSIGNED_INT_IMAGE_2D_MULTISAMPLE_ARRAY = 0x906C,

	UNSIGNED_INT_ATOMIC_COUNTER = 0x92DB,
}

Uniform_Info :: struct {
	location: i32,
	size:     i32,
	kind:     Uniform_Type,
	name:     string, // NOTE: This will need to be freed
}

Uniforms :: map[string]Uniform_Info

destroy_uniforms :: proc(u: Uniforms) {
	for _, v in u {
		delete(v.name)
	}
	delete(u)
}

get_uniforms_from_program :: proc(program: u32) -> (uniforms: Uniforms) {
	uniform_count: i32
	GetProgramiv(program, ACTIVE_UNIFORMS, &uniform_count)

	if uniform_count > 0 {
		reserve(&uniforms, int(uniform_count))
	}

	for i in 0..<uniform_count {
		uniform_info: Uniform_Info

		length: i32
		cname: [256]u8
		GetActiveUniform(program, u32(i), 256, &length, &uniform_info.size, cast(^u32)&uniform_info.kind, &cname[0])

		uniform_info.location = GetUniformLocation(program, cstring(&cname[0]))
		uniform_info.name = strings.clone(string(cname[:length])) // @NOTE: These need to be freed
		uniforms[uniform_info.name] = uniform_info
	}

	return uniforms
}
