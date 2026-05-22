#+build !js
#+build !wasi
#+build !orca
package vendor_gl

import "core:fmt"
import "core:os"
@(require) import "core:time"
_ :: fmt

load_compute_file :: proc(filename: string, binary_retrievable := false) -> (program_id: u32, ok: bool) {
    cs_data, cs_data_err := os.read_entire_file(filename, context.allocator)
    if cs_data_err != nil {
        return 0, false
    }
    defer delete(cs_data)

    // Create the shaders
    compute_shader_id := compile_shader_from_source(string(cs_data), Shader_Type(COMPUTE_SHADER)) or_return
    return create_and_link_program([]u32{compute_shader_id}, binary_retrievable)
}

load_shaders_file :: proc(vs_filename, fs_filename: string, binary_retrievable := false) -> (program_id: u32, ok: bool) {
	vs_data, vs_data_err := os.read_entire_file(vs_filename, context.allocator)
	if vs_data_err != nil {
		return 0, false
	}
	defer delete(vs_data)
	
	fs_data, fs_data_err := os.read_entire_file(fs_filename, context.allocator)
	if fs_data_err != nil {
		return 0, false
	}
	defer delete(fs_data)

	return load_shaders_source(string(vs_data), string(fs_data), binary_retrievable)
}

load_shaders :: proc {load_shaders_file}

when ODIN_OS == .Windows {
    update_shader_if_changed :: proc(
        vertex_name, fragment_name: string,
        program: u32,
        last_vertex_time, last_fragment_time: time.Time,
    ) -> (
        old_program: u32,
        current_vertex_time, current_fragment_time: time.Time,
        updated: bool,
    ) {
        current_vertex_time, _ = os.modification_time_by_path(vertex_name)
        current_fragment_time, _ = os.modification_time_by_path(fragment_name)
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
        last_compute_time: time.Time,
    ) -> (
        old_program: u32,
        current_compute_time: time.Time,
        updated: bool,
    ) {
        current_compute_time, _ = os.modification_time_by_path(compute_name)
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
