package raylib

import "core:c"

when ODIN_OS == "windows" {
	foreign import lib {
		"raylib.lib",
		"system:Winmm.lib",
		"system:Gdi32.lib",
		"system:User32.lib",
		"system:Shell32.lib",
	}
}
when ODIN_OS == "linux"  { foreign import lib "linux/libraylib.a" }
when ODIN_OS == "darwin" { foreign import lib "macos/libraylib.a" }

GRAPHICS_API_OPENGL_11  :: false
GRAPHICS_API_OPENGL_21  :: true
GRAPHICS_API_OPENGL_33  :: GRAPHICS_API_OPENGL_21
GRAPHICS_API_OPENGL_ES2 :: false
GRAPHICS_API_OPENGL_43  :: false

when !GRAPHICS_API_OPENGL_ES2 {
	// This is the maximum amount of elements (quads) per batch
	// NOTE: Be careful with text, every letter maps to a quad
	DEFAULT_BATCH_BUFFER_ELEMENTS :: 8192
} else {
	// We reduce memory sizes for embedded systems (RPI and HTML5)
	// NOTE: On HTML5 (emscripten) this is allocated on heap,
	// by default it's only 16MB!...just take care...
	DEFAULT_BATCH_BUFFER_ELEMENTS :: 2048
}

DEFAULT_BATCH_BUFFERS          :: 1                    // Default number of batch buffers (multi-buffering)
DEFAULT_BATCH_DRAWCALLS        :: 256                  // Default number of batch draw calls (by state changes: mode, texture)
MAX_BATCH_ACTIVE_TEXTURES      :: 4                    // Maximum number of additional textures that can be activated on batch drawing (SetShaderValueTexture())

// Internal Matrix stack
MAX_MATRIX_STACK_SIZE          :: 32                   // Maximum size of Matrix stack

// Shader limits
MAX_SHADER_LOCATIONS           :: 32                   // Maximum number of shader locations supported

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


//----------------------------------------------------------------------------------
// Types and Structures Definition
//----------------------------------------------------------------------------------
GlVersion :: enum c.int { OPENGL_11 = 1, OPENGL_21, OPENGL_33, OPENGL_ES_20 }

FramebufferAttachType :: enum c. int {
	COLOR_CHANNEL0 = 0,
	COLOR_CHANNEL1,
	COLOR_CHANNEL2,
	COLOR_CHANNEL3,
	COLOR_CHANNEL4,
	COLOR_CHANNEL5,
	COLOR_CHANNEL6,
	COLOR_CHANNEL7,
	DEPTH = 100,
	STENCIL = 200,
}

FramebufferAttachTextureType :: enum c.int {
	CUBEMAP_POSITIVE_X = 0,
	CUBEMAP_NEGATIVE_X,
	CUBEMAP_POSITIVE_Y,
	CUBEMAP_NEGATIVE_Y,
	CUBEMAP_POSITIVE_Z,
	CUBEMAP_NEGATIVE_Z,
	TEXTURE2D = 100,
	RENDERBUFFER = 200,
}

VertexBufferIndexType :: c.ushort when GRAPHICS_API_OPENGL_ES2 else c.uint

// Dynamic vertex buffers (position + texcoords + colors + indices arrays)
VertexBuffer :: struct {
	elementsCount: c.int,                    // Number of elements in the buffer (QUADS)

	vCounter:      c.int,                    // Vertex position counter to process (and draw) from full buffer
	tcCounter:     c.int,                    // Vertex texcoord counter to process (and draw) from full buffer
	cCounter:      c.int,                    // Vertex color counter to process (and draw) from full buffer

	vertices:      [^]f32,                   // Vertex position (XYZ - 3 components per vertex) (shader-location = 0)
	texcoords:     [^]f32,                   // Vertex texture coordinates (UV - 2 components per vertex) (shader-location = 1)
	colors:        [^]u8,                    // Vertex colors (RGBA - 4 components per vertex) (shader-location = 3)
	indices:       [^]VertexBufferIndexType, // Vertex indices (in case vertex data comes indexed) (6 indices per quad)
	vaoId:         u32,                      // OpenGL Vertex Array Object id
	vboId:         [4]u32,                   // OpenGL Vertex Buffer Objects id (4 types of vertex data)
} 

// Draw call type
// NOTE: Only texture changes register a new draw, other state-change-related elements are not
// used at this moment (vaoId, shaderId, matrices), raylib just forces a batch draw call if any
// of those state-change happens (this is done in core module)
DrawCall :: struct {
	mode:            c.int,       // Drawing mode: LINES, TRIANGLES, QUADS
	vertexCount:     c.int,       // Number of vertex of the draw
	vertexAlignment: c.int,       // Number of vertex required for index alignment (LINES, TRIANGLES)
	//vaoId: u32,                 // Vertex array id to be used on the draw -> Using RLGL.currentBatch->vertexBuffer.vaoId
	//shaderId: u32,              // Shader id to be used on the draw -> Using RLGL.currentShader.id
	textureId: u32,               // Texture id to be used on the draw -> Use to create new draw call if changes

	//projection: Matrix,         // Projection matrix for this draw -> Using RLGL.projection by default
	//modelview:  Matrix,         // Modelview matrix for this draw -> Using RLGL.modelview by default
} 

// RenderBatch type
RenderBatch :: struct {
	buffersCount:  c.int,           // Number of vertex buffers (multi-buffering support)
	currentBuffer: c.int,           // Current buffer tracking in case of multi-buffering
	vertexBuffer:  [^]VertexBuffer, // Dynamic buffer(s) for vertex data

	draws:        [^]DrawCall,      // Draw calls array, depends on textureId
	drawsCounter: c.int,            // Draw calls counter
	currentDepth: f32,              // Current depth value for next draw
}

// Shader attribute data types
ShaderAttributeDataType :: enum c.int {
	FLOAT = 0,
	VEC2,
	VEC3,
	VEC4,
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
	rlEnableVertexArray          :: proc(vaoId: u32) -> bool --- // Enable vertex array (VAO, if supported)
	rlDisableVertexArray         :: proc() ---                   // Disable vertex array (VAO, if supported)
	rlEnableVertexBuffer         :: proc(id: u32) ---            // Enable vertex buffer (VBO)
	rlDisableVertexBuffer        :: proc() ---                   // Disable vertex buffer (VBO)
	rlEnableVertexBufferElement  :: proc(id: u32) ---            // Enable vertex buffer element (VBO element)
	rlDisableVertexBufferElement :: proc() ---                   // Disable vertex buffer element (VBO element)
	rlEnableVertexAttribute      :: proc(index: u32) ---         // Enable vertex attribute index
	rlDisableVertexAttribute     :: proc(index: u32) ---         // Disable vertex attribute index
	when GRAPHICS_API_OPENGL_11 {
		rlEnableStatePointer :: proc(vertexAttribType: c.int, buffer: rawptr) ---
		rlDisableStatePointer :: proc(vertexAttribType: c.int) ---
	}

	// Textures state
	rlActiveTextureSlot     :: proc(slot: c.int) ---                         // Select and active a texture slot
	rlEnableTexture         :: proc(id: u32) ---                             // Enable texture
	rlDisableTexture        :: proc() ---                                    // Disable texture
	rlEnableTextureCubemap  :: proc(id: u32) ---                             // Enable texture cubemap
	rlDisableTextureCubemap :: proc() ---                                    // Disable texture cubemap
	rlTextureParameters     :: proc(id: u32, param: c.int, value: c.int) --- // Set texture parameters (filter, wrap)

	// Shader state
	rlEnableShader  :: proc(id: u32) ---                                          // Enable shader program
	rlDisableShader :: proc() ---                                                 // Disable shader program

	// Framebuffer state
	rlEnableFramebuffer  :: proc(id: u32) ---                                     // Enable render texture (fbo)
	rlDisableFramebuffer :: proc() ---                                            // Disable render texture (fbo), return to default framebuffer
	rlActiveDrawBuffers  :: proc(count: c.int) ---                                // Activate multiple draw color buffers

	// General render state
	rlEnableColorBlend       :: proc() ---                           // Enable color blending
	rlDisableColorBlend      :: proc() ---                           // Disable color blending
	rlEnableDepthTest        :: proc() ---                           // Enable depth test
	rlDisableDepthTest       :: proc() ---                           // Disable depth test
	rlEnableDepthMask        :: proc() ---                           // Enable depth write
	rlDisableDepthMask       :: proc() ---                           // Disable depth write
	rlEnableBackfaceCulling  :: proc() ---                           // Enable backface culling
	rlDisableBackfaceCulling :: proc() ---                           // Disable backface culling
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

	rlClearColor         :: proc(r, g, b, a: u8) ---                              // Clear color buffer with color
	rlClearScreenBuffers :: proc() ---                                            // Clear used screen buffers (color and depth)
	rlCheckErrors        :: proc() ---                                            // Check and log OpenGL error codes
	rlSetBlendMode       :: proc(mode: c.int) ---                                 // Set blending mode
	rlSetBlendFactors    :: proc(glSrcFactor, glDstFactor, glEquation: c.int) --- // Set blending mode factor and equation (using OpenGL factors)

	//------------------------------------------------------------------------------------
	// Functions Declaration - rlgl functionality
	//------------------------------------------------------------------------------------
	// rlgl initialization functions
	rlglInit               :: proc(width, height: c.int) ---                               // Initialize rlgl (buffers, shaders, textures, states)
	rlglClose              :: proc() ---                                                   // De-inititialize rlgl (buffers, shaders, textures)
	rlLoadExtensions       :: proc(loader: rawptr) ---                                     // Load OpenGL extensions (loader function pointer required)
	rlGetVersion           :: proc() -> GlVersion ---                                      // Returns current OpenGL version
	rlGetFramebufferWidth  :: proc() -> c.int ---                                          // Get default framebuffer width
	rlGetFramebufferHeight :: proc() -> c.int ---                                          // Get default framebuffer height

	rlGetTextureIdDefault  :: proc() -> u32 ---                                            // Get default texture id
	rlGetShaderIdDefault   :: proc() -> u32 ---                                            // Get default shader id
	rlGetShaderLocsDefault :: proc() -> [^]i32 ---                                         // Get default shader locations

	// Render batch management
	// NOTE: rlgl provides a default render batch to behave like OpenGL 1.1 immediate mode
	// but this render batch API is exposed in case of custom batches are required
	rlLoadRenderBatch       :: proc(numBuffers, bufferElements: c.int) -> RenderBatch ---  // Load a render batch system
	rlUnloadRenderBatch     :: proc(batch: RenderBatch) ---                                // Unload render batch system
	rlDrawRenderBatch       :: proc(batch: ^RenderBatch) ---                               // Draw render batch data (Update->Draw->Reset)
	rlSetRenderBatchActive  :: proc(batch: ^RenderBatch) ---                               // Set the active render batch for rlgl (NULL for default internal)
	rlDrawRenderBatchActive :: proc() ---                                                  // Update and draw internal render batch
	rlCheckRenderBatchLimit :: proc(vCount: c.int) -> bool ---                             // Check internal buffer overflow for a given number of vertex
	rlSetTexture            :: proc(id: u32) ---                                           // Set current texture for render batch and check buffers limits

	//------------------------------------------------------------------------------------------------------------------------

	// Vertex buffers management
	rlLoadVertexArray                  :: proc() -> u32 ---                                                                 // Load vertex array (vao) if supported
	rlLoadVertexBuffer                 :: proc(buffer: rawptr, size: c.int, is_dynamic: bool) -> u32 ---                    // Load a vertex buffer attribute
	rlLoadVertexBufferElement          :: proc(buffer: rawptr, size: c.int, is_dynamic: bool) -> u32 ---                    // Load a new attributes element buffer
	rlUpdateVertexBuffer               :: proc(bufferId: c.int, data: rawptr, dataSize: c.int, offset: c.int) -> u32 ---    // Update GPU buffer with new data
	rlUnloadVertexArray                :: proc(vaoId: u32) ---
	rlUnloadVertexBuffer               :: proc(vboId: u32) ---
	rlSetVertexAttribute               :: proc(index: u32, compSize: c.int, type: c.int, normalized: bool, stride: c.int, pointer: uintptr) ---
	rlSetVertexAttributeDivisor        :: proc(index: u32, divisor: c.int) ---
	rlSetVertexAttributeDefault        :: proc(locIndex: c.int, value: rawptr, attribType: c.int, count: c.int) ---         // Set vertex attribute default value
	rlDrawVertexArray                  :: proc(offset: c.int, count: c.int) ---
	rlDrawVertexArrayElements          :: proc(offset: c.int, count: c.int, buffer: rawptr) ---
	rlDrawVertexArrayInstanced         :: proc(offset: c.int, count: c.int, instances: c.int) ---
	rlDrawVertexArrayElementsInstanced :: proc(offset: c.int, count: c.int, buffer: rawptr, instances: c.int) ---

	// Textures management
	rlLoadTexture          :: proc(data: rawptr, width, height: c.int, format: c.int, mipmapCount: c.int) -> u32 ---  // Load texture in GPU
	rlLoadTextureDepth     :: proc(width, height: c.int, useRenderBuffer: bool) -> u32 ---                            // Load depth texture/renderbuffer (to be attached to fbo)
	rlLoadTextureCubemap   :: proc(data: rawptr, size: c.int, format: c.int) -> u32 ---                               // Load texture cubemap
	rlUpdateTexture        :: proc(id: u32, offsetX, offsetY, width, height: c.int, format: c.int, data: rawptr) ---  // Update GPU texture with new data
	rlGetGlTextureFormats  :: proc(format: c.int, glInternalFormat: ^u32, glFormat: ^u32, glType: ^u32) ---           // Get OpenGL internal formats
	rlGetPixelFormatName   :: proc(format: PixelFormat) -> cstring ---                                                // Get name string for pixel format
	rlUnloadTexture        :: proc(id: u32) ---                                                                       // Unload texture from GPU memory
	rlGenerateMipmaps      :: proc(texture: ^Texture2D) ---                                                           // Generate mipmap data for selected texture
	rlReadTexturePixels    :: proc(texture: Texture2D) -> rawptr ---                                                  // Read texture pixel data
	rlReadScreenPixels     :: proc(width, height: c.int) -> [^]u8 ---                                                 // Read screen pixel data (color buffer)

	// Framebuffer management (fbo)
	rlLoadFramebuffer     :: proc(width, height: c.int) -> u32 ---                                                // Load an empty framebuffer
	rlFramebufferAttach   :: proc(fboId: u32, texId: u32, attachType: c.int, texType: c.int, mipLevel: c.int) --- // Attach texture/renderbuffer to a framebuffer
	rlFramebufferComplete :: proc(id: u32) -> bool ---                                                            // Verify framebuffer is complete
	rlUnloadFramebuffer   :: proc(id: u32) ---                                                                    // Delete framebuffer from GPU

	// Shaders management
	rlLoadShaderCode      :: proc(vsCode, fsCode: cstring) -> u32 ---                                   // Load shader from code strings
	rlCompileShader       :: proc(shaderCode: cstring, type: c.int) -> u32 ---                          // Compile custom shader and return shader id (type: GL_VERTEX_SHADER, GL_FRAGMENT_SHADER)
	rlLoadShaderProgram   :: proc(vShaderId, fShaderId: u32) -> u32 ---                                 // Load custom shader program
	rlUnloadShaderProgram :: proc(id: u32) ---                                                          // Unload shader program
	rlGetLocationUniform  :: proc(shaderId: u32, uniformName: cstring) -> c.int ---                     // Get shader location uniform
	rlGetLocationAttrib   :: proc(shaderId: u32, attribName: cstring) -> c.int ---                      // Get shader location attribute
	rlSetUniform          :: proc(locIndex: c.int, value: rawptr, uniformType: c.int, count: c.int) --- // Set shader value uniform
	rlSetUniformMatrix    :: proc(locIndex: c.int, mat: Matrix) ---                                     // Set shader value matrix
	rlSetUniformSampler   :: proc(locIndex: c.int, textureId: u32) ---                                  // Set shader value sampler
	rlSetShader           :: proc(shader: Shader) ---                                                   // Set shader currently active

	// Compute shader management
	rlLoadComputeShaderProgram :: proc(shaderId: u32) -> u32 ---        // Load compute shader program
	rlComputeShaderDispatch    :: proc(groupX, groupY, groupZ: u32) --- // Dispatch compute shader (equivalent to *draw* for graphics pilepine)

	
	// Shader buffer storage object management (ssbo)
	rlLoadShaderBuffer           :: proc(size: u64, data: rawptr, usageHint: c.int) -> u32 ---  // Load shader storage buffer object (SSBO)
	rlUnloadShaderBuffer         :: proc(ssboId: u32) ---                                       // Unload shader storage buffer object (SSBO)
	rlUpdateShaderBufferElements :: proc(id: u32, data: rawptr, dataSize: u64, offset: u64) --- // Update SSBO buffer data
	rlGetShaderBufferSize        :: proc(id: u32) -> u64 ---                                    // Get SSBO buffer size
	rlReadShaderBufferElements   :: proc(id: u32, dest: rawptr, count: u64, offset: u64) ---    // Bind SSBO buffer
	rlBindShaderBuffer           :: proc(id: u32, index: u32) ---                               // Copy SSBO buffer data

	// Buffer management
	rlCopyBuffersElements  :: proc(destId, srcId: u32, destOffset, srcOffset: u64, count: u64) --- // Copy SSBO buffer data
	rlBindImageTexture     :: proc(id: u32, index: u32, format: u32, readonly: b32) ---            // Bind image texture


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