# odin-gl: opengl loader in Odin

Includes procedures to load OpenGL function pointers. Currently only supports the `core` profile, up to version 4.6. Based on the output from the [glad](https://github.com/Dav1dde/glad) webservice using 4.6 `core`.

#### Note: You will be required to pass your own GetProcAddress equivalent (wglGetProcAddress, glXGetProcAddress, glfwGetProcAddress, etc.), for example:

```go
gl.load_up_to(4, 5, proc(p: rawptr, name: cstring) do (cast(^rawptr)p)^ = glfw.GetProcAddress(name); );
```
`vendor:glfw` also provides a useful helper you can pass straight to `gl.load_up_to`:
```go
gl.load_up_to(4, 5, glfw.gl_set_proc_address);
```

## Extra utility procedures (Outdated. See the end of `gl.odin`)

Some useful helper procedures can be found in `helpers.odin`, for tasks such as:

 - loading vertex, fragment and compute shaders (from source or files) using `load_shaders_file`, `load_shaders_source`, `load_compute_file` and `load_compute_source`
 - grabbing uniform and attribute locations using `get_uniform_location` and `get_attribute_location`
 - getting all active uniforms from a program using `get_uniforms_from_program`
 - hot reloading of shaders (windows only right now) using `update_shader_if_changed` and `update_shader_if_changed_compute`

## Debug mode

Each `gl` call will be appended by a debug helper calling `glGetError()` if compiled with `-debug`. This can be useful to detect incorrect usage. Sample output (also outputting the NO_ERRORS case for the sake of showcasing): 

```
glGetError() returned NO_ERROR
   call: glTexImage2D(GL_TEXTURE_2D=3553, 0, 34836, 1150, 1024, 0, GL_RGBA=6408, GL_FLOAT=5126, 0x0)
   in:   C:/<snip>/texture.odin(156:23)
glGetError() returned NO_ERROR
   call: glEnable(GL_DEBUG_OUTPUT=37600)
   in:   C:/<snip>/main.odin(185:6)
glGetError() returned NO_ERROR
   call: glGetError() -> 0 
   in:   C:/<snip>/main.odin(193:5)
glGetError() returned INVALID_ENUM
   call: glEnable(INVALID_ENUM=123123123)
   in:   C:/<snip>/main.odin(194:5)
glGetError() returned INVALID_VALUE
   call: glPointSize(-1.000)
   in:   C:/<snip>/main.odin(195:5)
glGetError() returned NO_ERROR
   call: glDisable(GL_SCISSOR_TEST=3089)
   in:   C:/<snip>/main.odin(270:6)
glGetError() returned NO_ERROR
   call: glViewport(0, 0, 1150, 1024)
   in:   C:/<snip>/main.odin(271:6)
glGetError() returned NO_ERROR
   call: glClearColor(0.800, 0.800, 0.800, 1.000)
   in:   C:/<snip>/main.odin(272:6)
```
