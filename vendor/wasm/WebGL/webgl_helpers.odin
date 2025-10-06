package webgl

import "core:fmt"

CreateProgramFromStrings :: proc(vs_sources, fs_sources: []string) -> (program: Program, ok: bool) {
	ok = true
	log: [1024]byte

	vs := CreateShader(VERTEX_SHADER)
	fs := CreateShader(FRAGMENT_SHADER)
	defer DeleteShader(vs)
	defer DeleteShader(fs)
	ShaderSource(vs, vs_sources)
	ShaderSource(fs, fs_sources)
	CompileShader(vs)
	if GetShaderiv(vs, COMPILE_STATUS) == 0 {
		err := GetShaderInfoLog(vs, log[:])
		fmt.eprintln("Vertex shader did not compile successfully", err)
		ok = false
		return
	}

	CompileShader(fs)
	if GetShaderiv(fs, COMPILE_STATUS) == 0 {
		err := GetShaderInfoLog(fs, log[:])
		fmt.eprintln("Fragment shader did not compile successfully", err)
		ok = false
		return
	}

	program = CreateProgram()
	defer if !ok { DeleteProgram(program) }

	AttachShader(program, vs)
	AttachShader(program, fs)
	LinkProgram(program)
	DetachShader(program, vs)
	DetachShader(program, fs)

	if GetProgramParameter(program, LINK_STATUS) == 0 {
		err := GetProgramInfoLog(program, log[:])
		fmt.eprintln("Shader program did not link successfully", err)
		ok = false
		return
	}

	return

}
