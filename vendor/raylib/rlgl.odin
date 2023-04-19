/**********************************************************************************************
*
*   rlgl v4.5 - A multi-OpenGL abstraction layer with an immediate-mode style API
*
*   An abstraction layer for multiple OpenGL versions (1.1, 2.1, 3.3 Core, 4.3 Core, ES 2.0)
*   that provides a pseudo-OpenGL 1.1 immediate-mode style API (rlVertex, rlTranslate, rlRotate...)
*
*   When choosing an OpenGL backend different than OpenGL 1.1, some internal buffer are
*   initialized on rlglInit() to accumulate vertex data.
*
*   When an internal state change is required all the stored vertex data is renderer in batch,
*   additionally, rlDrawRenderBatchActive() could be called to force flushing of the batch.
*
*   Some additional resources are also loaded for convenience, here the complete list:
*      - Default batch (RLGL.defaultBatch): RenderBatch system to accumulate vertex data
*      - Default texture (RLGL.defaultTextureId): 1x1 white pixel R8G8B8A8
*      - Default shader (RLGL.State.defaultShaderId, RLGL.State.defaultShaderLocs)
*
*   Internal buffer (and additional resources) must be manually unloaded calling rlglClose().
*
*
*   CONFIGURATION:
*
*   #define GRAPHICS_API_OPENGL_11
*   #define GRAPHICS_API_OPENGL_21
*   #define GRAPHICS_API_OPENGL_33
*   #define GRAPHICS_API_OPENGL_43
*   #define GRAPHICS_API_OPENGL_ES2
*       Use selected OpenGL graphics backend, should be supported by platform
*       Those preprocessor defines are only used on rlgl module, if OpenGL version is
*       required by any other module, use rlGetVersion() to check it
*
*   #define RLGL_IMPLEMENTATION
*       Generates the implementation of the library into the included file.
*       If not defined, the library is in header only mode and can be included in other headers
*       or source files without problems. But only ONE file should hold the implementation.
*
*   #define RLGL_RENDER_TEXTURES_HINT
*       Enable framebuffer objects (fbo) support (enabled by default)
*       Some GPUs could not support them despite the OpenGL version
*
*   #define RLGL_SHOW_GL_DETAILS_INFO
*       Show OpenGL extensions and capabilities detailed logs on init
*
*   #define RLGL_ENABLE_OPENGL_DEBUG_CONTEXT
*       Enable debug context (only available on OpenGL 4.3)
*
*   rlgl capabilities could be customized just defining some internal
*   values before library inclusion (default values listed):
*
*   #define RL_DEFAULT_BATCH_BUFFER_ELEMENTS   8192    // Default internal render batch elements limits
*   #define RL_DEFAULT_BATCH_BUFFERS              1    // Default number of batch buffers (multi-buffering)
*   #define RL_DEFAULT_BATCH_DRAWCALLS          256    // Default number of batch draw calls (by state changes: mode, texture)
*   #define RL_DEFAULT_BATCH_MAX_TEXTURE_UNITS    4    // Maximum number of textures units that can be activated on batch drawing (SetShaderValueTexture())
*
*   #define RL_MAX_MATRIX_STACK_SIZE             32    // Maximum size of internal Matrix stack
*   #define RL_MAX_SHADER_LOCATIONS              32    // Maximum number of shader locations supported
*   #define RL_CULL_DISTANCE_NEAR              0.01    // Default projection matrix near cull distance
*   #define RL_CULL_DISTANCE_FAR             1000.0    // Default projection matrix far cull distance
*
*   When loading a shader, the following vertex attribute and uniform
*   location names are tried to be set automatically:
*
*   #define RL_DEFAULT_SHADER_ATTRIB_NAME_POSITION     "vertexPosition"    // Bound by default to shader location: 0
*   #define RL_DEFAULT_SHADER_ATTRIB_NAME_TEXCOORD     "vertexTexCoord"    // Bound by default to shader location: 1
*   #define RL_DEFAULT_SHADER_ATTRIB_NAME_NORMAL       "vertexNormal"      // Bound by default to shader location: 2
*   #define RL_DEFAULT_SHADER_ATTRIB_NAME_COLOR        "vertexColor"       // Bound by default to shader location: 3
*   #define RL_DEFAULT_SHADER_ATTRIB_NAME_TANGENT      "vertexTangent"     // Bound by default to shader location: 4
*   #define RL_DEFAULT_SHADER_UNIFORM_NAME_MVP         "mvp"               // model-view-projection matrix
*   #define RL_DEFAULT_SHADER_UNIFORM_NAME_VIEW        "matView"           // view matrix
*   #define RL_DEFAULT_SHADER_UNIFORM_NAME_PROJECTION  "matProjection"     // projection matrix
*   #define RL_DEFAULT_SHADER_UNIFORM_NAME_MODEL       "matModel"          // model matrix
*   #define RL_DEFAULT_SHADER_UNIFORM_NAME_NORMAL      "matNormal"         // normal matrix (transpose(inverse(matModelView))
*   #define RL_DEFAULT_SHADER_UNIFORM_NAME_COLOR       "colDiffuse"        // color diffuse (base tint color, multiplied by texture color)
*   #define RL_DEFAULT_SHADER_SAMPLER2D_NAME_TEXTURE0  "texture0"          // texture0 (texture slot active 0)
*   #define RL_DEFAULT_SHADER_SAMPLER2D_NAME_TEXTURE1  "texture1"          // texture1 (texture slot active 1)
*   #define RL_DEFAULT_SHADER_SAMPLER2D_NAME_TEXTURE2  "texture2"          // texture2 (texture slot active 2)
*
*   DEPENDENCIES:
*
*      - OpenGL libraries (depending on platform and OpenGL version selected)
*      - GLAD OpenGL extensions loading library (only for OpenGL 3.3 Core, 4.3 Core)
*
*
*   LICENSE: zlib/libpng
*
*   Copyright (c) 2014-2023 Ramon Santamaria (@raysan5)
*
*   This software is provided "as-is", without any express or implied warranty. In no event
*   will the authors be held liable for any damages arising from the use of this software.
*
*   Permission is granted to anyone to use this software for any purpose, including commercial
*   applications, and to alter it and redistribute it freely, subject to the following restrictions:
*
*     1. The origin of this software must not be misrepresented; you must not claim that you
*     wrote the original software. If you use this software in a product, an acknowledgment
*     in the product documentation would be appreciated but is not required.
*
*     2. Altered source versions must be plainly marked as such, and must not be misrepresented
*     as being the original software.
*
*     3. This notice may not be removed or altered from any source distribution.
*
**********************************************************************************************/


package raylib

import "core:c"

when ODIN_OS == .Windows {
	foreign import lib {
		"windows/raylib.lib",
		"system:Winmm.lib",
		"system:Gdi32.lib",
		"system:User32.lib",
		"system:Shell32.lib",
	}
} else when ODIN_OS == .Linux  {
	foreign import lib "linux/libraylib.a"
} else when ODIN_OS == .Darwin {
	when ODIN_ARCH == .arm64 {
		foreign import lib {
			"macos-arm64/libraylib.a",
			"system:Cocoa.framework",
			"system:OpenGL.framework",
			"system:IOKit.framework",
		}
	} else {
		foreign import lib {
			"macos/libraylib.a",
			"system:Cocoa.framework",
			"system:OpenGL.framework",
			"system:IOKit.framework",
		}
	}
} else {
	foreign import lib "system:raylib"
}

RL_GRAPHICS_API_OPENGL_11  :: false
RL_GRAPHICS_API_OPENGL_21  :: true
RL_GRAPHICS_API_OPENGL_33  :: RL_GRAPHICS_API_OPENGL_21 // default currently
RL_GRAPHICS_API_OPENGL_ES2 :: false
RL_GRAPHICS_API_OPENGL_43  :: false

when !RL_GRAPHICS_API_OPENGL_ES2 {
	// This is the maximum amount of elements (quads) per batch
	// NOTE: Be careful with text, every letter maps to a quad
	RL_DEFAULT_BATCH_BUFFER_ELEMENTS :: 8192
} else {
	// We reduce memory sizes for embedded systems (RPI and HTML5)
	// NOTE: On HTML5 (emscripten) this is allocated on heap,
	// by default it's only 16MB!...just take care...
	RL_DEFAULT_BATCH_BUFFER_ELEMENTS :: 2048
}

RL_DEFAULT_BATCH_BUFFERS            :: 1                    // Default number of batch buffers (multi-buffering)
RL_DEFAULT_BATCH_DRAWCALLS          :: 256                  // Default number of batch draw calls (by state changes: mode, texture)
RL_DEFAULT_BATCH_MAX_TEXTURE_UNITS  :: 4                    // Maximum number of additional textures that can be activated on batch drawing (SetShaderValueTexture())

// Internal Matrix stack
RL_MAX_MATRIX_STACK_SIZE          :: 32                   // Maximum size of Matrix stack

// Shader limits
RL_MAX_SHADER_LOCATIONS           :: 32                   // Maximum number of shader locations supported

// Projection matrix culling
RL_CULL_DISTANCE_NEAR          :: 0.01                 // Default near cull distance
RL_CULL_DISTANCE_FAR           :: 1000.0               // Default far cull distance

// Texture parameters (equivalent to OpenGL defines)
RL_TEXTURE_WRAP_S                       :: 0x2802      // GL_TEXTURE_WRAP_S
RL_TEXTURE_WRAP_T                       :: 0x2803      // GL_TEXTURE_WRAP_T
RL_TEXTURE_MAG_FILTER                   :: 0x2800      // GL_TEXTURE_MAG_FILTER
RL_TEXTURE_MIN_FILTER                   :: 0x2801      // GL_TEXTURE_MIN_FILTER

RL_TEXTURE_FILTER_NEAREST               :: 0x2600      // GL_NEAREST
RL_TEXTURE_FILTER_LINEAR                :: 0x2601      // GL_LINEAR
RL_TEXTURE_FILTER_MIP_NEAREST           :: 0x2700      // GL_NEAREST_MIPMAP_NEAREST
RL_TEXTURE_FILTER_NEAREST_MIP_LINEAR    :: 0x2702      // GL_NEAREST_MIPMAP_LINEAR
RL_TEXTURE_FILTER_LINEAR_MIP_NEAREST    :: 0x2701      // GL_LINEAR_MIPMAP_NEAREST
RL_TEXTURE_FILTER_MIP_LINEAR            :: 0x2703      // GL_LINEAR_MIPMAP_LINEAR
RL_TEXTURE_FILTER_ANISOTROPIC           :: 0x3000      // Anisotropic filter (custom identifier)

RL_TEXTURE_WRAP_REPEAT                  :: 0x2901      // GL_REPEAT
RL_TEXTURE_WRAP_CLAMP                   :: 0x812F      // GL_CLAMP_TO_EDGE
RL_TEXTURE_WRAP_MIRROR_REPEAT           :: 0x8370      // GL_MIRRORED_REPEAT
RL_TEXTURE_WRAP_MIRROR_CLAMP            :: 0x8742      // GL_MIRROR_CLAMP_EXT

// Matrix modes (equivalent to OpenGL)
RL_MODELVIEW                            :: 0x1700      // GL_MODELVIEW
RL_PROJECTION                           :: 0x1701      // GL_PROJECTION
RL_TEXTURE                              :: 0x1702      // GL_TEXTURE

// Primitive assembly draw modes
RL_LINES                                :: 0x0001      // GL_LINES
RL_TRIANGLES                            :: 0x0004      // GL_TRIANGLES
RL_QUADS                                :: 0x0007      // GL_QUADS

// GL equivalent data types
RL_UNSIGNED_BYTE                        :: 0x1401      // GL_UNSIGNED_BYTE
RL_FLOAT                                :: 0x1406      // GL_FLOAT

// Buffer usage hint
RL_STREAM_DRAW                          :: 0x88E0      // GL_STREAM_DRAW
RL_STREAM_READ                          :: 0x88E1      // GL_STREAM_READ
RL_STREAM_COPY                          :: 0x88E2      // GL_STREAM_COPY
RL_STATIC_DRAW                          :: 0x88E4      // GL_STATIC_DRAW
RL_STATIC_READ                          :: 0x88E5      // GL_STATIC_READ
RL_STATIC_COPY                          :: 0x88E6      // GL_STATIC_COPY
RL_DYNAMIC_DRAW                         :: 0x88E8      // GL_DYNAMIC_DRAW
RL_DYNAMIC_READ                         :: 0x88E9      // GL_DYNAMIC_READ
RL_DYNAMIC_COPY                         :: 0x88EA      // GL_DYNAMIC_COPY

// GL Shader type
RL_FRAGMENT_SHADER                      :: 0x8B30      // GL_FRAGMENT_SHADER
RL_VERTEX_SHADER                        :: 0x8B31      // GL_VERTEX_SHADER
RL_COMPUTE_SHADER                       :: 0x91B9      // GL_COMPUTE_SHADER

// GL blending factors
RL_ZERO                                 :: 0           // GL_ZERO
RL_ONE                                  :: 1           // GL_ONE
RL_SRC_COLOR                            :: 0x0300      // GL_SRC_COLOR
RL_ONE_MINUS_SRC_COLOR                  :: 0x0301      // GL_ONE_MINUS_SRC_COLOR
RL_SRC_ALPHA                            :: 0x0302      // GL_SRC_ALPHA
RL_ONE_MINUS_SRC_ALPHA                  :: 0x0303      // GL_ONE_MINUS_SRC_ALPHA
RL_DST_ALPHA                            :: 0x0304      // GL_DST_ALPHA
RL_ONE_MINUS_DST_ALPHA                  :: 0x0305      // GL_ONE_MINUS_DST_ALPHA
RL_DST_COLOR                            :: 0x0306      // GL_DST_COLOR
RL_ONE_MINUS_DST_COLOR                  :: 0x0307      // GL_ONE_MINUS_DST_COLOR
RL_SRC_ALPHA_SATURATE                   :: 0x0308      // GL_SRC_ALPHA_SATURATE
RL_CONSTANT_COLOR                       :: 0x8001      // GL_CONSTANT_COLOR
RL_ONE_MINUS_CONSTANT_COLOR             :: 0x8002      // GL_ONE_MINUS_CONSTANT_COLOR
RL_CONSTANT_ALPHA                       :: 0x8003      // GL_CONSTANT_ALPHA
RL_ONE_MINUS_CONSTANT_ALPHA             :: 0x8004      // GL_ONE_MINUS_CONSTANT_ALPHA

// GL blending functions/equations
RL_FUNC_ADD                             :: 0x8006      // GL_FUNC_ADD
RL_MIN                                  :: 0x8007      // GL_MIN
RL_MAX                                  :: 0x8008      // GL_MAX
RL_FUNC_SUBTRACT                        :: 0x800A      // GL_FUNC_SUBTRACT
RL_FUNC_REVERSE_SUBTRACT                :: 0x800B      // GL_FUNC_REVERSE_SUBTRACT
RL_BLEND_EQUATION                       :: 0x8009      // GL_BLEND_EQUATION
RL_BLEND_EQUATION_RGB                   :: 0x8009      // GL_BLEND_EQUATION_RGB   // (Same as BLEND_EQUATION)
RL_BLEND_EQUATION_ALPHA                 :: 0x883D      // GL_BLEND_EQUATION_ALPHA
RL_BLEND_DST_RGB                        :: 0x80C8      // GL_BLEND_DST_RGB
RL_BLEND_SRC_RGB                        :: 0x80C9      // GL_BLEND_SRC_RGB
RL_BLEND_DST_ALPHA                      :: 0x80CA      // GL_BLEND_DST_ALPHA
RL_BLEND_SRC_ALPHA                      :: 0x80CB      // GL_BLEND_SRC_ALPHA
RL_BLEND_COLOR                          :: 0x8005      // GL_BLEND_COLOR


//----------------------------------------------------------------------------------
// Types and Structures Definition
//----------------------------------------------------------------------------------


VertexBufferIndexType :: c.ushort when RL_GRAPHICS_API_OPENGL_ES2 else c.uint

// Dynamic vertex buffers (position + texcoords + colors + indices arrays)
VertexBuffer :: struct {
	elementCount: c.int,                 // Number of elements in the buffer (QUADS)

	vertices:  [^]f32,                   // Vertex position (XYZ - 3 components per vertex) (shader-location = 0)
	texcoords: [^]f32,                   // Vertex texture coordinates (UV - 2 components per vertex) (shader-location = 1)
	colors:    [^]u8,                    // Vertex colors (RGBA - 4 components per vertex) (shader-location = 3)
	indices:   [^]VertexBufferIndexType, // Vertex indices (in case vertex data comes indexed) (6 indices per quad)
	vaoId:     c.uint,                   // OpenGL Vertex Array Object id
	vboId:     [4]c.uint,                // OpenGL Vertex Buffer Objects id (4 types of vertex data)
}

// Draw call type
// NOTE: Only texture changes register a new draw, other state-change-related elements are not
// used at this moment (vaoId, shaderId, matrices), raylib just forces a batch draw call if any
// of those state-change happens (this is done in core module)
DrawCall :: struct {
	mode:            c.int,        // Drawing mode: LINES, TRIANGLES, QUADS
	vertexCount:     c.int,        // Number of vertex of the draw
	vertexAlignment: c.int,        // Number of vertex required for index alignment (LINES, TRIANGLES)
	textureId:       c.uint,       // Texture id to be used on the draw -> Use to create new draw call if changes
}

// RenderBatch type
RenderBatch :: struct {
	bufferCount:   c.int,           // Number of vertex buffers (multi-buffering support)
	currentBuffer: c.int,           // Current buffer tracking in case of multi-buffering
	vertexBuffer:  [^]VertexBuffer, // Dynamic buffer(s) for vertex data

	draws:         [^]DrawCall,     // Draw calls array, depends on textureId
	drawCounter:   c.int,           // Draw calls counter
	currentDepth:  f32,             // Current depth value for next draw
}


// OpenGL version
GlVersion :: enum c.int {
	OPENGL_11 = 1,           // OpenGL 1.1
	OPENGL_21,               // OpenGL 2.1 (GLSL 120)
	OPENGL_33,               // OpenGL 3.3 (GLSL 330)
	OPENGL_43,               // OpenGL 4.3 (using GLSL 330)
	OPENGL_ES_20,            // OpenGL ES 2.0 (GLSL 100)
}


// Shader attribute data types
ShaderAttributeDataType :: enum c.int {
	FLOAT = 0,         // Shader attribute type: float
	VEC2,              // Shader attribute type: vec2 (2 float)
	VEC3,              // Shader attribute type: vec3 (3 float)
	VEC4,              // Shader attribute type: vec4 (4 float)
}

// Framebuffer attachment type
// NOTE: By default up to 8 color channels defined, but it can be more
FramebufferAttachType :: enum c.int {
	COLOR_CHANNEL0 = 0,   // Framebuffer attachment type: color 0
	COLOR_CHANNEL1,       // Framebuffer attachment type: color 1
	COLOR_CHANNEL2,       // Framebuffer attachment type: color 2
	COLOR_CHANNEL3,       // Framebuffer attachment type: color 3
	COLOR_CHANNEL4,       // Framebuffer attachment type: color 4
	COLOR_CHANNEL5,       // Framebuffer attachment type: color 5
	COLOR_CHANNEL6,       // Framebuffer attachment type: color 6
	COLOR_CHANNEL7,       // Framebuffer attachment type: color 7
	DEPTH = 100,          // Framebuffer attachment type: depth
	STENCIL = 200,        // Framebuffer attachment type: stencil
}

// Framebuffer texture attachment type
FramebufferAttachTextureType :: enum c.int {
	CUBEMAP_POSITIVE_X = 0, // Framebuffer texture attachment type: cubemap, +X side
	CUBEMAP_NEGATIVE_X,     // Framebuffer texture attachment type: cubemap, -X side
	CUBEMAP_POSITIVE_Y,     // Framebuffer texture attachment type: cubemap, +Y side
	CUBEMAP_NEGATIVE_Y,     // Framebuffer texture attachment type: cubemap, -Y side
	CUBEMAP_POSITIVE_Z,     // Framebuffer texture attachment type: cubemap, +Z side
	CUBEMAP_NEGATIVE_Z,     // Framebuffer texture attachment type: cubemap, -Z side
	TEXTURE2D = 100,        // Framebuffer texture attachment type: texture2d
	RENDERBUFFER = 200,     // Framebuffer texture attachment type: renderbuffer
}

CullMode :: enum c.int {
	FRONT = 0,
	BACK,
}

@(default_calling_convention="c")
foreign lib {
	//------------------------------------------------------------------------------------
	// Functions Declaration - Matrix operations
	//------------------------------------------------------------------------------------
	rlMatrixMode   :: proc(mode: c.int) ---                 // Choose the current matrix to be transformed
	rlPushMatrix   :: proc() ---                            // Push the current matrix to stack
	rlPopMatrix    :: proc() ---                            // Pop lattest inserted matrix from stack
	rlLoadIdentity :: proc() ---                            // Reset current matrix to identity matrix
	rlTranslatef   :: proc(x, y, z: f32) ---                // Multiply the current matrix by a translation matrix
	rlRotatef      :: proc(angleDeg: f32, x, y, z: f32) --- // Multiply the current matrix by a rotation matrix
	rlScalef       :: proc(x, y, z: f32) ---                // Multiply the current matrix by a scaling matrix
	rlMultMatrixf  :: proc(matf: [^]f32) ---                // Multiply the current matrix by another matrix
	rlFrustum      :: proc(left, right, bottom, top, znear, zfar: f64) ---
	rlOrtho        :: proc(left, right, bottom, top, znear, zfar: f64) ---
	rlViewport     :: proc(x, y, width, height: c.int) ---  // Set the viewport area

	//------------------------------------------------------------------------------------
	// Functions Declaration - Vertex level operations
	//------------------------------------------------------------------------------------
	rlBegin        :: proc(mode: c.int)     --- // Initialize drawing mode (how to organize vertex)
	rlEnd          :: proc()                --- // Finish vertex providing
	rlVertex2i     :: proc(x, y: c.int)     --- // Define one vertex (position) - 2 int
	rlVertex2f     :: proc(x, y: f32)       --- // Define one vertex (position) - 2 f32
	rlVertex3f     :: proc(x, y, z: f32)    --- // Define one vertex (position) - 3 f32
	rlTexCoord2f   :: proc(x, y: f32)       --- // Define one vertex (texture coordinate) - 2 f32
	rlNormal3f     :: proc(x, y, z: f32)    --- // Define one vertex (normal) - 3 f32
	rlColor4ub     :: proc(r, g, b, a: u8)  --- // Define one vertex (color) - 4 byte
	rlColor3f      :: proc(x, y, z: f32)    --- // Define one vertex (color) - 3 f32
	rlColor4f      :: proc(x, y, z, w: f32) --- // Define one vertex (color) - 4 f32

	//------------------------------------------------------------------------------------
	// Functions Declaration - OpenGL style functions (common to 1.1, 3.3+, ES2)
	// NOTE: This functions are used to completely abstract raylib code from OpenGL layer,
	// some of them are direct wrappers over OpenGL calls, some others are custom
	//------------------------------------------------------------------------------------

	// Vertex buffers state
	rlEnableVertexArray          :: proc(vaoId: c.uint) -> bool --- // Enable vertex array (VAO, if supported)
	rlDisableVertexArray         :: proc() ---                      // Disable vertex array (VAO, if supported)
	rlEnableVertexBuffer         :: proc(id: c.uint) ---            // Enable vertex buffer (VBO)
	rlDisableVertexBuffer        :: proc() ---                      // Disable vertex buffer (VBO)
	rlEnableVertexBufferElement  :: proc(id: c.uint) ---            // Enable vertex buffer element (VBO element)
	rlDisableVertexBufferElement :: proc() ---                      // Disable vertex buffer element (VBO element)
	rlEnableVertexAttribute      :: proc(index: c.uint) ---         // Enable vertex attribute index
	rlDisableVertexAttribute     :: proc(index: c.uint) ---         // Disable vertex attribute index
	when RL_GRAPHICS_API_OPENGL_11 {
		rlEnableStatePointer :: proc(vertexAttribType: c.int, buffer: rawptr) ---
		rlDisableStatePointer :: proc(vertexAttribType: c.int) ---
	}

	// Textures state
	rlActiveTextureSlot     :: proc(slot: c.int) ---                            // Select and active a texture slot
	rlEnableTexture         :: proc(id: c.uint) ---                             // Enable texture
	rlDisableTexture        :: proc() ---                                       // Disable texture
	rlEnableTextureCubemap  :: proc(id: c.uint) ---                             // Enable texture cubemap
	rlDisableTextureCubemap :: proc() ---                                       // Disable texture cubemap
	rlTextureParameters     :: proc(id: c.uint, param: c.int, value: c.int) --- // Set texture parameters (filter, wrap)
	rlCubemapParameters     :: proc(id: i32, param: c.int, value: c.int) ---    // Set cubemap parameters (filter, wrap)

	// Shader state
	rlEnableShader  :: proc(id: c.uint) ---                                       // Enable shader program
	rlDisableShader :: proc() ---                                                 // Disable shader program

	// Framebuffer state
	rlEnableFramebuffer  :: proc(id: c.uint) ---                                  // Enable render texture (fbo)
	rlDisableFramebuffer :: proc() ---                                            // Disable render texture (fbo), return to default framebuffer
	rlActiveDrawBuffers  :: proc(count: c.int) ---                                // Activate multiple draw color buffers

	// General render state
	rlDisableColorBlend      :: proc() ---                           // Disable color blending
	rlEnableDepthTest        :: proc() ---                           // Enable depth test
	rlDisableDepthTest       :: proc() ---                           // Disable depth test
	rlEnableDepthMask        :: proc() ---                           // Enable depth write
	rlDisableDepthMask       :: proc() ---                           // Disable depth write
	rlEnableBackfaceCulling  :: proc() ---                           // Enable backface culling
	rlDisableBackfaceCulling :: proc() ---                           // Disable backface culling
	rlSetCullFace            :: proc(mode: CullMode) ---             // Set face culling mode
	rlEnableScissorTest      :: proc() ---                           // Enable scissor test
	rlDisableScissorTest     :: proc() ---                           // Disable scissor test
	rlScissor                :: proc(x, y, width, height: c.int) --- // Scissor test
	rlEnableWireMode         :: proc() ---                           // Enable wire mode
	rlDisableWireMode        :: proc() ---                           // Disable wire mode
	rlSetLineWidth           :: proc(width: f32) ---                 // Set the line drawing width
	rlGetLineWidth           :: proc() -> f32 ---                    // Get the line drawing width
	rlEnableSmoothLines      :: proc() ---                           // Enable line aliasing
	rlDisableSmoothLines     :: proc() ---                           // Disable line aliasing
	rlEnableStereoRender     :: proc() ---                           // Enable stereo rendering
	rlDisableStereoRender    :: proc() ---                           // Disable stereo rendering
	rlIsStereoRenderEnabled  :: proc() -> bool ---                   // Check if stereo render is enabled


	rlClearColor              :: proc(r, g, b, a: u8) ---                                                        // Clear color buffer with color
	rlClearScreenBuffers      :: proc() ---                                                                      // Clear used screen buffers (color and depth)
	rlCheckErrors             :: proc() ---                                                                      // Check and log OpenGL error codes
	rlSetBlendMode            :: proc(mode: c.int) ---                                                           // Set blending mode
	rlSetBlendFactors         :: proc(glSrcFactor, glDstFactor, glEquation: c.int) ---                           // Set blending mode factor and equation (using OpenGL factors)
	rlSetBlendFactorsSeparate :: proc(glSrcRGB, glDstRGB, glSrcAlpha, glDstAlpha, glEqRGB, glEqAlpha: c.int) --- // Set blending mode factors and equations separately (using OpenGL factors)

	//------------------------------------------------------------------------------------
	// Functions Declaration - rlgl functionality
	//------------------------------------------------------------------------------------
	// rlgl initialization functions
	rlglInit               :: proc(width, height: c.int) --- // Initialize rlgl (buffers, shaders, textures, states)
	rlglClose              :: proc() ---                     // De-initialize rlgl (buffers, shaders, textures)
	rlLoadExtensions       :: proc(loader: rawptr) ---       // Load OpenGL extensions (loader function required)
	rlGetVersion           :: proc() -> GlVersion ---        // Get current OpenGL version
	rlSetFramebufferWidth  :: proc(width: c.int) ---         // Set current framebuffer width
	rlGetFramebufferWidth  :: proc() -> c.int ---            // Get default framebuffer width
	rlSetFramebufferHeight :: proc(height: c.int) ---        // Set current framebuffer height
	rlGetFramebufferHeight :: proc() -> c.int ---            // Get default framebuffer height


	rlGetTextureIdDefault  :: proc() -> c.uint ---   // Get default texture id
	rlGetShaderIdDefault   :: proc() -> c.uint ---   // Get default shader id
	rlGetShaderLocsDefault :: proc() -> [^]c.int --- // Get default shader locations

	// Render batch management
	// NOTE: rlgl provides a default render batch to behave like OpenGL 1.1 immediate mode
	// but this render batch API is exposed in case of custom batches are required
	rlLoadRenderBatch       :: proc(numBuffers, bufferElements: c.int) -> RenderBatch --- // Load a render batch system
	rlUnloadRenderBatch     :: proc(batch: RenderBatch) ---                               // Unload render batch system
	rlDrawRenderBatch       :: proc(batch: ^RenderBatch) ---                              // Draw render batch data (Update->Draw->Reset)
	rlSetRenderBatchActive  :: proc(batch: ^RenderBatch) ---                              // Set the active render batch for rlgl (NULL for default internal)
	rlDrawRenderBatchActive :: proc() ---                                                 // Update and draw internal render batch
	rlCheckRenderBatchLimit :: proc(vCount: c.int) -> c.int ---                           // Check internal buffer overflow for a given number of vertex

	rlSetTexture :: proc(id: c.uint) --- // Set current texture for render batch and check buffers limits

	//------------------------------------------------------------------------------------------------------------------------

	// Vertex buffers management
	rlLoadVertexArray                  :: proc() -> c.uint ---                                                      // Load vertex array (vao) if supported
	rlLoadVertexBuffer                 :: proc(buffer: rawptr, size: c.int, is_dynamic: bool) -> c.uint ---         // Load a vertex buffer attribute
	rlLoadVertexBufferElement          :: proc(buffer: rawptr, size: c.int, is_dynamic: bool) -> c.uint ---         // Load a new attributes element buffer
	rlUpdateVertexBuffer               :: proc(bufferId: c.uint, data: rawptr, dataSize: c.int, offset: c.int) ---  // Update GPU buffer with new data
	rlUpdateVertexBufferElements       :: proc(id: c.uint, data: rawptr, dataSize: c.int, offset: c.int) ---        // Update vertex buffer elements with new data
	rlUnloadVertexArray                :: proc(vaoId: c.uint) ---
	rlUnloadVertexBuffer               :: proc(vboId: c.uint) ---
	rlSetVertexAttribute               :: proc(index: c.uint, compSize: c.int, type: c.int, normalized: bool, stride: c.int, pointer: rawptr) ---
	rlSetVertexAttributeDivisor        :: proc(index: c.uint, divisor: c.int) ---
	rlSetVertexAttributeDefault        :: proc(locIndex: c.int, value: rawptr, attribType: c.int, count: c.int) --- // Set vertex attribute default value
	rlDrawVertexArray                  :: proc(offset: c.int, count: c.int) ---
	rlDrawVertexArrayElements          :: proc(offset: c.int, count: c.int, buffer: rawptr) ---
	rlDrawVertexArrayInstanced         :: proc(offset: c.int, count: c.int, instances: c.int) ---
	rlDrawVertexArrayElementsInstanced :: proc(offset: c.int, count: c.int, buffer: rawptr, instances: c.int) ---

	// Textures management
	rlLoadTexture         :: proc(data: rawptr, width, height: c.int, format: c.int, mipmapCount: c.int) -> c.uint ---        // Load texture in GPU
	rlLoadTextureDepth    :: proc(width, height: c.int, useRenderBuffer: bool) -> c.uint ---                                  // Load depth texture/renderbuffer (to be attached to fbo)
	rlLoadTextureCubemap  :: proc(data: rawptr, size: c.int, format: c.int) -> c.uint ---                                     // Load texture cubemap
	rlUpdateTexture       :: proc(id: c.uint, offsetX, offsetY: c.int, width, height: c.int, format: c.int, data: rawptr) --- // Update GPU texture with new data
	rlGetGlTextureFormats :: proc(format: c.int, glInternalFormat, glFormat, glType: ^c.uint) ---                             // Get OpenGL internal formats
	rlGetPixelFormatName  :: proc(format: c.uint) -> cstring ---                                                              // Get name string for pixel format
	rlUnloadTexture       :: proc(id: c.uint) ---                                                                             // Unload texture from GPU memory
	rlGenTextureMipmaps   :: proc(id: c.uint, width, height: c.int, format: c.int, mipmaps: ^c.int) ---                       // Generate mipmap data for selected texture
	rlReadTexturePixels   :: proc(id: c.uint, width, height: c.int, format: c.int) -> rawptr ---                              // Read texture pixel data
	rlReadScreenPixels    :: proc(width, height: c.int) -> [^]byte ---                                                        // Read screen pixel data (color buffer)

	// Framebuffer management (fbo)
	rlLoadFramebuffer     :: proc(width, height: c.int) -> c.uint ---                                           // Load an empty framebuffer
	rlFramebufferAttach   :: proc(fboId, texId: c.uint, attachType: c.int, texType: c.int, mipLevel: c.int) --- // Attach texture/renderbuffer to a framebuffer
	rlFramebufferComplete :: proc(id: c.uint) -> bool ---                                                       // Verify framebuffer is complete
	rlUnloadFramebuffer   :: proc(id: c.uint) ---                                                               // Delete framebuffer from GPU

	// Shaders management
	rlLoadShaderCode      :: proc(vsCode, fsCode: cstring) -> c.uint ---                                // Load shader from code strings
	rlCompileShader       :: proc(shaderCode: cstring, type: c.int) -> c.uint ---                       // Compile custom shader and return shader id (type: RL_VERTEX_SHADER, RL_FRAGMENT_SHADER, RL_COMPUTE_SHADER)
	rlLoadShaderProgram   :: proc(vShaderId, fShaderId: c.uint) -> c.uint ---                           // Load custom shader program
	rlUnloadShaderProgram :: proc(id: c.uint) ---                                                       // Unload shader program
	rlGetLocationUniform  :: proc(shaderId: c.uint, uniformName: cstring) -> c.int ---                  // Get shader location uniform
	rlGetLocationAttrib   :: proc(shaderId: c.uint, attribName: cstring) -> c.int ---                   // Get shader location attribute
	rlSetUniform          :: proc(locIndex: c.int, value: rawptr, uniformType: c.int, count: c.int) --- // Set shader value uniform
	rlSetUniformMatrix    :: proc(locIndex: c.int, mat: Matrix) ---                                     // Set shader value matrix
	rlSetUniformSampler   :: proc(locIndex: c.int, textureId: c.uint) ---                               // Set shader value sampler
	rlSetShader           :: proc(id: c.uint, locs: [^]c.int) ---                                       // Set shader currently active (id and locations)

	// Compute shader management
	rlLoadComputeShaderProgram :: proc(shaderId: c.uint) -> c.uint ---     // Load compute shader program
	rlComputeShaderDispatch    :: proc(groupX, groupY, groupZ: c.uint) --- // Dispatch compute shader (equivalent to *draw* for graphics pipeline)

	// Shader buffer storage object management (ssbo)
	rlLoadShaderBuffer    :: proc(size: c.uint, data: rawptr, usageHint: c.int) -> c.uint ---              // Load shader storage buffer object (SSBO)
	rlUnloadShaderBuffer  :: proc(ssboId: c.uint) ---                                                      // Unload shader storage buffer object (SSBO)
	rlUpdateShaderBuffer  :: proc(id: c.uint, data: rawptr, dataSize: c.uint, offset: c.uint) ---          // Update SSBO buffer data
	rlBindShaderBuffer    :: proc(id: c.uint, index: c.uint) ---                                           // Bind SSBO buffer
	rlReadShaderBuffer    :: proc(id: c.uint, dest: rawptr, count: c.uint, offset: c.uint) ---             // Read SSBO buffer data (GPU->CPU)
	rlCopyShaderBuffer    :: proc(destId, srcId: c.uint, destOffset, srcOffset: c.uint, count: c.uint) --- // Copy SSBO data between buffers
	rlGetShaderBufferSize :: proc(id: c.uint) -> c.uint ---                                                // Get SSBO buffer size

	// Buffer management
	rlBindImageTexture :: proc(id: c.uint, index: c.uint, format: c.int, readonly: bool) ---  // Bind image texture

	// Matrix state management
	rlGetMatrixModelview        :: proc() -> Matrix ---           // Get internal modelview matrix
	rlGetMatrixProjection       :: proc() -> Matrix ---           // Get internal projection matrix
	rlGetMatrixTransform        :: proc() -> Matrix ---           // Get internal accumulated transform matrix
	rlGetMatrixProjectionStereo :: proc(eye: c.int) -> Matrix --- // Get internal projection matrix for stereo render (selected eye)
	rlGetMatrixViewOffsetStereo :: proc(eye: c.int) -> Matrix --- // Get internal view offset matrix for stereo render (selected eye)
	rlSetMatrixProjection       :: proc(proj: Matrix) ---         // Set a custom projection matrix (replaces internal projection matrix)
	rlSetMatrixModelview        :: proc(view: Matrix) ---         // Set a custom modelview matrix (replaces internal modelview matrix)
	rlSetMatrixProjectionStereo :: proc(right, left: Matrix) ---  // Set eyes projection matrices for stereo rendering
	rlSetMatrixViewOffsetStereo :: proc(right, left: Matrix) ---  // Set eyes view offsets matrices for stereo rendering

	// Quick and dirty cube/quad buffers load->draw->unload
	rlLoadDrawCube :: proc() --- // Load and draw a cube
	rlLoadDrawQuad :: proc() --- // Load and draw a quad
}
