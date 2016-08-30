#foreign_system_library "opengl32"

GL_ZERO                 :: 0x0000
GL_ONE                  :: 0x0001
GL_TRIANGLES            :: 0x0004
GL_BLEND                :: 0x0be2
GL_SRC_ALPHA            :: 0x0302
GL_ONE_MINUS_SRC_ALPHA  :: 0x0303
GL_TEXTURE_2D           :: 0x0de1
GL_RGBA8                :: 0x8058
GL_UNSIGNED_BYTE        :: 0x1401
GL_BGRA_EXT             :: 0x80e1
GL_TEXTURE_MAX_LEVEL    :: 0x813d
GL_RGBA                 :: 0x1908

GL_NEAREST :: 0x2600
GL_LINEAR  :: 0x2601

GL_DEPTH_BUFFER_BIT   :: 0x00000100
GL_STENCIL_BUFFER_BIT :: 0x00000400
GL_COLOR_BUFFER_BIT   :: 0x00004000

GL_TEXTURE_MAX_ANISOTROPY_EXT :: 0x84fe

GL_TEXTURE_MAG_FILTER  :: 0x2800
GL_TEXTURE_MIN_FILTER  :: 0x2801
GL_TEXTURE_WRAP_S      :: 0x2802
GL_TEXTURE_WRAP_T      :: 0x2803

glClear         :: proc(mask: u32) #foreign
glClearColor    :: proc(r, g, b, a: f32) #foreign
glBegin         :: proc(mode: i32) #foreign
glEnd           :: proc() #foreign
glColor3f       :: proc(r, g, b: f32) #foreign
glColor4f       :: proc(r, g, b, a: f32) #foreign
glVertex2f      :: proc(x, y: f32) #foreign
glVertex3f      :: proc(x, y, z: f32) #foreign
glTexCoord2f    :: proc(u, v: f32) #foreign
glLoadIdentity  :: proc() #foreign
glOrtho         :: proc(left, right, bottom, top, near, far: f64) #foreign
glBlendFunc     :: proc(sfactor, dfactor: i32) #foreign
glEnable        :: proc(cap: i32) #foreign
glDisable       :: proc(cap: i32) #foreign
glGenTextures   :: proc(count: i32, result: ^u32) #foreign
glTexParameteri :: proc(target, pname, param: i32) #foreign
glTexParameterf :: proc(target: i32, pname: i32, param: f32) #foreign
glBindTexture   :: proc(target: i32, texture: u32) #foreign
glTexImage2D    :: proc(target, level, internal_format, width, height, border, format, _type: i32, pixels: rawptr) #foreign

