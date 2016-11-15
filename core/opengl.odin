#foreign_system_library "opengl32"

ZERO                 :: 0x0000
ONE                  :: 0x0001
TRIANGLES            :: 0x0004
BLEND                :: 0x0be2
SRC_ALPHA            :: 0x0302
ONE_MINUS_SRC_ALPHA  :: 0x0303
TEXTURE_2D           :: 0x0de1
RGBA8                :: 0x8058
UNSIGNED_BYTE        :: 0x1401
BGRA_EXT             :: 0x80e1
TEXTURE_MAX_LEVEL    :: 0x813d
RGBA                 :: 0x1908

NEAREST :: 0x2600
LINEAR  :: 0x2601

DEPTH_BUFFER_BIT   :: 0x00000100
STENCIL_BUFFER_BIT :: 0x00000400
COLOR_BUFFER_BIT   :: 0x00004000

TEXTURE_MAX_ANISOTROPY_EXT :: 0x84fe

TEXTURE_MAG_FILTER  :: 0x2800
TEXTURE_MIN_FILTER  :: 0x2801
TEXTURE_WRAP_S      :: 0x2802
TEXTURE_WRAP_T      :: 0x2803

Clear          :: proc(mask: u32)                                #foreign "glClear"
ClearColor     :: proc(r, g, b, a: f32)                          #foreign "glClearColor"
Begin          :: proc(mode: i32)                                #foreign "glBegin"
End            :: proc()                                         #foreign "glEnd"
Color3f        :: proc(r, g, b: f32)                             #foreign "glColor3f"
Color4f        :: proc(r, g, b, a: f32)                          #foreign "glColor4f"
Vertex2f       :: proc(x, y: f32)                                #foreign "glVertex2f"
Vertex3f       :: proc(x, y, z: f32)                             #foreign "glVertex3f"
TexCoord2f     :: proc(u, v: f32)                                #foreign "glTexCoord2f"
LoadIdentity   :: proc()                                         #foreign "glLoadIdentity"
Ortho          :: proc(left, right, bottom, top, near, far: f64) #foreign "glOrtho"
BlendFunc      :: proc(sfactor, dfactor: i32)                    #foreign "glBlendFunc"
Enable         :: proc(cap: i32)                                 #foreign "glEnable"
Disable        :: proc(cap: i32)                                 #foreign "glDisable"
GenTextures    :: proc(count: i32, result: ^u32)                 #foreign "glGenTextures"
TexParameteri  :: proc(target, pname, param: i32)                #foreign "glTexParameteri"
TexParameterf  :: proc(target: i32, pname: i32, param: f32)      #foreign "glTexParameterf"
BindTexture    :: proc(target: i32, texture: u32)                #foreign "glBindTexture"
TexImage2D     :: proc(target, level, internal_format, width, height, border, format, _type: i32, pixels: rawptr) #foreign "glTexImage2D"





