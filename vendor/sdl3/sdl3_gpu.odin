package sdl3

import "core:c"

GPUDevice           :: struct {}
GPUBuffer           :: struct {}
GPUTransferBuffer   :: struct {}
GPUTexture          :: struct {}
GPUSampler          :: struct {}
GPUShader           :: struct {}
GPUComputePipeline  :: struct {}
GPUGraphicsPipeline :: struct {}
GPUCommandBuffer    :: struct {}
GPURenderPass       :: struct {}
GPUComputePass      :: struct {}
GPUCopyPass         :: struct {}
GPUFence            :: struct {}


GPUPrimitiveType :: enum c.int {
	TRIANGLELIST,  /**< A series of separate triangles. */
	TRIANGLESTRIP, /**< A series of connected triangles. */
	LINELIST,      /**< A series of separate lines. */
	LINESTRIP,     /**< A series of connected lines. */
	POINTLIST,     /**< A series of separate points. */
}

GPULoadOp :: enum c.int {
	LOAD,      /**< The previous contents of the texture will be preserved. */
	CLEAR,     /**< The contents of the texture will be cleared to a color. */
	DONT_CARE, /**< The previous contents of the texture need not be preserved. The contents will be undefined. */
}

GPUStoreOp :: enum c.int {
	STORE,             /**< The contents generated during the render pass will be written to memory. */
	DONT_CARE,         /**< The contents generated during the render pass are not needed and may be discarded. The contents will be undefined. */
	RESOLVE,           /**< The multisample contents generated during the render pass will be resolved to a non-multisample texture. The contents in the multisample texture may then be discarded and will be undefined. */
	RESOLVE_AND_STORE, /**< The multisample contents generated during the render pass will be resolved to a non-multisample texture. The contents in the multisample texture will be written to memory. */
}

GPUIndexElementSize :: enum c.int {
	_16BIT, /**< The index elements are 16-bit. */
	_32BIT, /**< The index elements are 32-bit. */
}

GPUTextureFormat :: enum c.int {
	INVALID,

    /* Unsigned Normalized Float Color Formats */
	A8_UNORM,
	R8_UNORM,
	R8G8_UNORM,
	R8G8B8A8_UNORM,
	R16_UNORM,
	R16G16_UNORM,
	R16G16B16A16_UNORM,
	R10G10B10A2_UNORM,
	B5G6R5_UNORM,
	B5G5R5A1_UNORM,
	B4G4R4A4_UNORM,
	B8G8R8A8_UNORM,
    /* Compressed Unsigned Normalized Float Color Formats */
	BC1_RGBA_UNORM,
	BC2_RGBA_UNORM,
	BC3_RGBA_UNORM,
	BC4_R_UNORM,
	BC5_RG_UNORM,
	BC7_RGBA_UNORM,
    /* Compressed Signed Float Color Formats */
	BC6H_RGB_FLOAT,
    /* Compressed Unsigned Float Color Formats */
	BC6H_RGB_UFLOAT,
    /* Signed Normalized Float Color Formats  */
	R8_SNORM,
	R8G8_SNORM,
	R8G8B8A8_SNORM,
	R16_SNORM,
	R16G16_SNORM,
	R16G16B16A16_SNORM,
    /* Signed Float Color Formats */
	R16_FLOAT,
	R16G16_FLOAT,
	R16G16B16A16_FLOAT,
	R32_FLOAT,
	R32G32_FLOAT,
	R32G32B32A32_FLOAT,
    /* Unsigned Float Color Formats */
	R11G11B10_UFLOAT,
    /* Unsigned Integer Color Formats */
	R8_UINT,
	R8G8_UINT,
	R8G8B8A8_UINT,
	R16_UINT,
	R16G16_UINT,
	R16G16B16A16_UINT,
	R32_UINT,
	R32G32_UINT,
	R32G32B32A32_UINT,
    /* Signed Integer Color Formats */
	R8_INT,
	R8G8_INT,
	R8G8B8A8_INT,
	R16_INT,
	R16G16_INT,
	R16G16B16A16_INT,
	R32_INT,
	R32G32_INT,
	R32G32B32A32_INT,
    /* SRGB Unsigned Normalized Color Formats */
	R8G8B8A8_UNORM_SRGB,
	B8G8R8A8_UNORM_SRGB,
    /* Compressed SRGB Unsigned Normalized Color Formats */
	BC1_RGBA_UNORM_SRGB,
	BC2_RGBA_UNORM_SRGB,
	BC3_RGBA_UNORM_SRGB,
	BC7_RGBA_UNORM_SRGB,
    /* Depth Formats */
	D16_UNORM,
	D24_UNORM,
	D32_FLOAT,
	D24_UNORM_S8_UINT,
	D32_FLOAT_S8_UINT,
    /* Compressed ASTC Normalized Float Color Formats*/
	ASTC_4x4_UNORM,
	ASTC_5x4_UNORM,
	ASTC_5x5_UNORM,
	ASTC_6x5_UNORM,
	ASTC_6x6_UNORM,
	ASTC_8x5_UNORM,
	ASTC_8x6_UNORM,
	ASTC_8x8_UNORM,
	ASTC_10x5_UNORM,
	ASTC_10x6_UNORM,
	ASTC_10x8_UNORM,
	ASTC_10x10_UNORM,
	ASTC_12x10_UNORM,
	ASTC_12x12_UNORM,
    /* Compressed SRGB ASTC Normalized Float Color Formats*/
	ASTC_4x4_UNORM_SRGB,
	ASTC_5x4_UNORM_SRGB,
	ASTC_5x5_UNORM_SRGB,
	ASTC_6x5_UNORM_SRGB,
	ASTC_6x6_UNORM_SRGB,
	ASTC_8x5_UNORM_SRGB,
	ASTC_8x6_UNORM_SRGB,
	ASTC_8x8_UNORM_SRGB,
	ASTC_10x5_UNORM_SRGB,
	ASTC_10x6_UNORM_SRGB,
	ASTC_10x8_UNORM_SRGB,
	ASTC_10x10_UNORM_SRGB,
	ASTC_12x10_UNORM_SRGB,
	ASTC_12x12_UNORM_SRGB,
    /* Compressed ASTC Signed Float Color Formats*/
	ASTC_4x4_FLOAT,
	ASTC_5x4_FLOAT,
	ASTC_5x5_FLOAT,
	ASTC_6x5_FLOAT,
	ASTC_6x6_FLOAT,
	ASTC_8x5_FLOAT,
	ASTC_8x6_FLOAT,
	ASTC_8x8_FLOAT,
	ASTC_10x5_FLOAT,
	ASTC_10x6_FLOAT,
	ASTC_10x8_FLOAT,
	ASTC_10x10_FLOAT,
	ASTC_12x10_FLOAT,
	ASTC_12x12_FLOAT,
}

GPUTextureUsageFlags :: distinct bit_set[GPUTextureUsageFlag; Uint32]
GPUTextureUsageFlag :: enum Uint32 {
	SAMPLER                                 = 0, /**< Texture supports sampling. */
	COLOR_TARGET                            = 1, /**< Texture is a color render target. */
	DEPTH_STENCIL_TARGET                    = 2, /**< Texture is a depth stencil target. */
	GRAPHICS_STORAGE_READ                   = 3, /**< Texture supports storage reads in graphics stages. */
	COMPUTE_STORAGE_READ                    = 4, /**< Texture supports storage reads in the compute stage. */
	COMPUTE_STORAGE_WRITE                   = 5, /**< Texture supports storage writes in the compute stage. */
	COMPUTE_STORAGE_SIMULTANEOUS_READ_WRITE = 6, /**< Texture supports reads and writes in the same compute shader. This is NOT equivalent to READ | WRITE. */
}

GPUTextureType :: enum c.int {
	D2,         /**< The texture is a 2-dimensional image. */
	D2_ARRAY,   /**< The texture is a 2-dimensional array image. */
	D3,         /**< The texture is a 3-dimensional image. */
	CUBE,       /**< The texture is a cube image. */
	CUBE_ARRAY, /**< The texture is a cube array image. */
}

GPUSampleCount :: enum c.int {
	_1,  /**< No multisampling. */
	_2,  /**< MSAA 2x */
	_4,  /**< MSAA 4x */
	_8,  /**< MSAA 8x */
}

GPUCubeMapFace :: enum c.int {
	POSITIVEX,
	NEGATIVEX,
	POSITIVEY,
	NEGATIVEY,
	POSITIVEZ,
	NEGATIVEZ,
}


GPUBufferUsageFlags :: distinct bit_set[GPUBufferUsageFlag; Uint32]
GPUBufferUsageFlag :: enum Uint32 {
	VERTEX                = 0, /**< Buffer is a vertex buffer. */
	INDEX                 = 1, /**< Buffer is an index buffer. */
	INDIRECT              = 2, /**< Buffer is an indirect buffer. */
	GRAPHICS_STORAGE_READ = 3, /**< Buffer supports storage reads in graphics stages. */
	COMPUTE_STORAGE_READ  = 4, /**< Buffer supports storage reads in the compute stage. */
	COMPUTE_STORAGE_WRITE = 5, /**< Buffer supports storage writes in the compute stage. */
}

GPUTransferBufferUsage :: enum c.int {
	UPLOAD,
	DOWNLOAD,
}

GPUShaderStage :: enum c.int {
	VERTEX,
	FRAGMENT,
}

GPUShaderFormat :: distinct bit_set[GPUShaderFormatFlag; Uint32]
GPUShaderFormatFlag :: enum Uint32 {
	PRIVATE  = 0, /**< Shaders for NDA'd platforms. */
	SPIRV    = 1, /**< SPIR-V shaders for Vulkan. */
	DXBC     = 2, /**< DXBC SM5_1 shaders for D3D12. */
	DXIL     = 3, /**< DXIL SM6_0 shaders for D3D12. */
	MSL      = 4, /**< MSL shaders for Metal. */
	METALLIB = 5, /**< Precompiled metallib shaders for Metal. */
}
GPU_SHADERFORMAT_INVALID :: GPUShaderFormat{}

GPUVertexElementFormat :: enum c.int {
	INVALID,

	/* 32-bit Signed Integers */
	INT,
	INT2,
	INT3,
	INT4,

	/* 32-bit Unsigned Integers */
	UINT,
	UINT2,
	UINT3,
	UINT4,

	/* 32-bit Floats */
	FLOAT,
	FLOAT2,
	FLOAT3,
	FLOAT4,

	/* 8-bit Signed Integers */
	BYTE2,
	BYTE4,

	/* 8-bit Unsigned Integers */
	UBYTE2,
	UBYTE4,

	/* 8-bit Signed Normalized */
	BYTE2_NORM,
	BYTE4_NORM,

	/* 8-bit Unsigned Normalized */
	UBYTE2_NORM,
	UBYTE4_NORM,

	/* 16-bit Signed Integers */
	SHORT2,
	SHORT4,

	/* 16-bit Unsigned Integers */
	USHORT2,
	USHORT4,

	/* 16-bit Signed Normalized */
	SHORT2_NORM,
	SHORT4_NORM,

	/* 16-bit Unsigned Normalized */
	USHORT2_NORM,
	USHORT4_NORM,

	/* 16-bit Floats */
	HALF2,
	HALF4,
}

GPUVertexInputRate :: enum c.int {
	VERTEX,   /**< Attribute addressing is a function of the vertex index. */
	INSTANCE, /**< Attribute addressing is a function of the instance index. */
}


GPUFillMode :: enum c.int {
	FILL,  /**< Polygons will be rendered via rasterization. */
	LINE,  /**< Polygon edges will be drawn as line segments. */
}

GPUCullMode :: enum c.int {
	NONE,   /**< No triangles are culled. */
	FRONT,  /**< Front-facing triangles are culled. */
	BACK,   /**< Back-facing triangles are culled. */
}

GPUFrontFace :: enum c.int {
	COUNTER_CLOCKWISE,  /**< A triangle with counter-clockwise vertex winding will be considered front-facing. */
	CLOCKWISE,          /**< A triangle with clockwise vertex winding will be considered front-facing. */
}

GPUCompareOp :: enum c.int {
	INVALID,
	NEVER,             /**< The comparison always evaluates false. */
	LESS,              /**< The comparison evaluates reference < test. */
	EQUAL,             /**< The comparison evaluates reference == test. */
	LESS_OR_EQUAL,     /**< The comparison evaluates reference <= test. */
	GREATER,           /**< The comparison evaluates reference > test. */
	NOT_EQUAL,         /**< The comparison evaluates reference != test. */
	GREATER_OR_EQUAL,  /**< The comparison evalutes reference >= test. */
	ALWAYS,            /**< The comparison always evaluates true. */
}

GPUStencilOp :: enum c.int {
	INVALID,
	KEEP,                 /**< Keeps the current value. */
	ZERO,                 /**< Sets the value to 0. */
	REPLACE,              /**< Sets the value to reference. */
	INCREMENT_AND_CLAMP,  /**< Increments the current value and clamps to the maximum value. */
	DECREMENT_AND_CLAMP,  /**< Decrements the current value and clamps to 0. */
	INVERT,               /**< Bitwise-inverts the current value. */
	INCREMENT_AND_WRAP,   /**< Increments the current value and wraps back to 0. */
	DECREMENT_AND_WRAP,   /**< Decrements the current value and wraps to the maximum value. */
}

GPUBlendOp :: enum c.int {
	INVALID,
	ADD,               /**< (source * source_factor) + (destination * destination_factor) */
	SUBTRACT,          /**< (source * source_factor) - (destination * destination_factor) */
	REVERSE_SUBTRACT,  /**< (destination * destination_factor) - (source * source_factor) */
	MIN,               /**< min(source, destination) */
	MAX,               /**< max(source, destination) */
}

GPUBlendFactor :: enum c.int {
	INVALID,
	ZERO,                      /**< 0 */
	ONE,                       /**< 1 */
	SRC_COLOR,                 /**< source color */
	ONE_MINUS_SRC_COLOR,       /**< 1 - source color */
	DST_COLOR,                 /**< destination color */
	ONE_MINUS_DST_COLOR,       /**< 1 - destination color */
	SRC_ALPHA,                 /**< source alpha */
	ONE_MINUS_SRC_ALPHA,       /**< 1 - source alpha */
	DST_ALPHA,                 /**< destination alpha */
	ONE_MINUS_DST_ALPHA,       /**< 1 - destination alpha */
	CONSTANT_COLOR,            /**< blend constant */
	ONE_MINUS_CONSTANT_COLOR,  /**< 1 - blend constant */
	SRC_ALPHA_SATURATE,        /**< min(source alpha, 1 - destination alpha) */
}


GPUColorComponentFlags :: distinct bit_set[GPUColorComponentFlag; Uint8]
GPUColorComponentFlag :: enum Uint8 {
	R = 0, /**< the red component */
	G = 1, /**< the green component */
	B = 2, /**< the blue component */
	A = 3, /**< the alpha component */
}

GPUFilter :: enum c.int {
	NEAREST,  /**< Point filtering. */
	LINEAR,   /**< Linear filtering. */
}

GPUSamplerMipmapMode :: enum c.int {
	NEAREST,  /**< Point filtering. */
	LINEAR,   /**< Linear filtering. */
}

GPUSamplerAddressMode :: enum c.int {
	REPEAT,           /**< Specifies that the coordinates will wrap around. */
	MIRRORED_REPEAT,  /**< Specifies that the coordinates will wrap around mirrored. */
	CLAMP_TO_EDGE,    /**< Specifies that the coordinates will clamp to the 0-1 range. */
}

GPUPresentMode :: enum c.int {
	VSYNC,
	IMMEDIATE,
	MAILBOX,
}

GPUSwapchainComposition :: enum c.int {
	SDR,
	SDR_LINEAR,
	HDR_EXTENDED_LINEAR,
	HDR10_ST2084,
}


GPUViewport :: struct {
	x: f32,          /**< The left offset of the viewport. */
	y: f32,          /**< The top offset of the viewport. */
	w: f32,          /**< The width of the viewport. */
	h: f32,          /**< The height of the viewport. */
	min_depth: f32,  /**< The minimum depth of the viewport. */
	max_depth: f32,  /**< The maximum depth of the viewport. */
}


GPUTextureTransferInfo :: struct {
	transfer_buffer: ^GPUTransferBuffer,  /**< The transfer buffer used in the transfer operation. */
	offset:          Uint32,              /**< The starting byte of the image data in the transfer buffer. */
	pixels_per_row:  Uint32,              /**< The number of pixels from one row to the next. */
	rows_per_layer:  Uint32,              /**< The number of rows from one layer/depth-slice to the next. */
}


GPUTransferBufferLocation :: struct {
	transfer_buffer: ^GPUTransferBuffer,  /**< The transfer buffer used in the transfer operation. */
	offset:          Uint32,              /**< The starting byte of the buffer data in the transfer buffer. */
}

GPUTextureLocation :: struct {
	texture:   ^GPUTexture,  /**< The texture used in the copy operation. */
	mip_level: Uint32,       /**< The mip level index of the location. */
	layer:     Uint32,       /**< The layer index of the location. */
	x:         Uint32,       /**< The left offset of the location. */
	y:         Uint32,       /**< The top offset of the location. */
	z:         Uint32,       /**< The front offset of the location. */
}

GPUTextureRegion :: struct {
	texture:   ^GPUTexture,  /**< The texture used in the copy operation. */
	mip_level: Uint32,       /**< The mip level index to transfer. */
	layer:     Uint32,       /**< The layer index to transfer. */
	x:         Uint32,       /**< The left offset of the region. */
	y:         Uint32,       /**< The top offset of the region. */
	z:         Uint32,       /**< The front offset of the region. */
	w:         Uint32,       /**< The width of the region. */
	h:         Uint32,       /**< The height of the region. */
	d:         Uint32,       /**< The depth of the region. */
}

GPUBlitRegion :: struct {
	texture:              ^GPUTexture,  /**< The texture. */
	mip_level:            Uint32,       /**< The mip level index of the region. */
	layer_or_depth_plane: Uint32,       /**< The layer index or depth plane of the region. This value is treated as a layer index on 2D array and cube textures, and as a depth plane on 3D textures. */
	x:                    Uint32,       /**< The left offset of the region. */
	y:                    Uint32,       /**< The top offset of the region.  */
	w:                    Uint32,       /**< The width of the region. */
	h:                    Uint32,       /**< The height of the region. */
}

GPUBufferLocation :: struct {
	buffer: ^GPUBuffer,  /**< The buffer. */
	offset: Uint32,      /**< The starting byte within the buffer. */
}


GPUBufferRegion :: struct {
	buffer: ^GPUBuffer,  /**< The buffer. */
	offset: Uint32,      /**< The starting byte within the buffer. */
	size:   Uint32,      /**< The size in bytes of the region. */
}


GPUIndirectDrawCommand :: struct {
	num_vertices:   Uint32,  /**< The number of vertices to draw. */
	num_instances:  Uint32,  /**< The number of instances to draw. */
	first_vertex:   Uint32,  /**< The index of the first vertex to draw. */
	first_instance: Uint32,  /**< The ID of the first instance to draw. */
}

GPUIndexedIndirectDrawCommand :: struct {
	num_indices:    Uint32,  /**< The number of indices to draw per instance. */
	num_instances:  Uint32,  /**< The number of instances to draw. */
	first_index:    Uint32,  /**< The base index within the index buffer. */
	vertex_offset:  Sint32,  /**< The value added to the vertex index before indexing into the vertex buffer. */
	first_instance: Uint32,  /**< The ID of the first instance to draw. */
}

GPUIndirectDispatchCommand :: struct {
	groupcount_x: Uint32,  /**< The number of local workgroups to dispatch in the X dimension. */
	groupcount_y: Uint32,  /**< The number of local workgroups to dispatch in the Y dimension. */
	groupcount_z: Uint32,  /**< The number of local workgroups to dispatch in the Z dimension. */
}


GPUSamplerCreateInfo :: struct {
	min_filter:        GPUFilter,              /**< The minification filter to apply to lookups. */
	mag_filter:        GPUFilter,              /**< The magnification filter to apply to lookups. */
	mipmap_mode:       GPUSamplerMipmapMode,   /**< The mipmap filter to apply to lookups. */
	address_mode_u:    GPUSamplerAddressMode,  /**< The addressing mode for U coordinates outside [0, 1). */
	address_mode_v:    GPUSamplerAddressMode,  /**< The addressing mode for V coordinates outside [0, 1). */
	address_mode_w:    GPUSamplerAddressMode,  /**< The addressing mode for W coordinates outside [0, 1). */
	mip_lod_bias:      f32,                    /**< The bias to be added to mipmap LOD calculation. */
	max_anisotropy:    f32,                    /**< The anisotropy value clamp used by the sampler. If enable_anisotropy is false, this is ignored. */
	compare_op:        GPUCompareOp,           /**< The comparison operator to apply to fetched data before filtering. */
	min_lod:           f32,                    /**< Clamps the minimum of the computed LOD value. */
	max_lod:           f32,                    /**< Clamps the maximum of the computed LOD value. */
	enable_anisotropy: bool,                   /**< true to enable anisotropic filtering. */
	enable_compare:    bool,                   /**< true to enable comparison against a reference value during lookups. */
	_:                 Uint8,
	_:                 Uint8,

	props:             PropertiesID,           /**< A properties ID for extensions. Should be 0 if no extensions are needed. */
}

GPUVertexBufferDescription :: struct {
	slot:               Uint32,              /**< The binding slot of the vertex buffer. */
	pitch:              Uint32,              /**< The byte pitch between consecutive elements of the vertex buffer. */
	input_rate:         GPUVertexInputRate,  /**< Whether attribute addressing is a function of the vertex index or instance index. */
	instance_step_rate: Uint32,              /**< The number of instances to draw using the same per-instance data before advancing in the instance buffer by one element. Ignored unless input_rate is GPU_VERTEXINPUTRATE_INSTANCE */
}

GPUVertexAttribute :: struct {
	location:    Uint32,                  /**< The shader input location index. */
	buffer_slot: Uint32,                  /**< The binding slot of the associated vertex buffer. */
	format:      GPUVertexElementFormat,  /**< The size and type of the attribute data. */
	offset:      Uint32,                  /**< The byte offset of this attribute relative to the start of the vertex element. */
}

GPUVertexInputState :: struct {
	vertex_buffer_descriptions: [^]GPUVertexBufferDescription `fmt:"v,num_vertex_buffers"`,    /**< A pointer to an array of vertex buffer descriptions. */
	num_vertex_buffers:         Uint32,                                                        /**< The number of vertex buffer descriptions in the above array. */
	vertex_attributes:          [^]GPUVertexAttribute         `fmt:"v,num_vertex_attributes"`, /**< A pointer to an array of vertex attribute descriptions. */
	num_vertex_attributes:      Uint32,                                                        /**< The number of vertex attribute descriptions in the above array. */
}

GPUStencilOpState :: struct {
	fail_op:       GPUStencilOp, /**< The action performed on samples that fail the stencil test. */
	pass_op:       GPUStencilOp, /**< The action performed on samples that pass the depth and stencil tests. */
	depth_fail_op: GPUStencilOp, /**< The action performed on samples that pass the stencil test and fail the depth test. */
	compare_op:    GPUCompareOp, /**< The comparison operator used in the stencil test. */
}

GPUColorTargetBlendState :: struct {
	src_color_blendfactor:   GPUBlendFactor,          /**< The value to be multiplied by the source RGB value. */
	dst_color_blendfactor:   GPUBlendFactor,          /**< The value to be multiplied by the destination RGB value. */
	color_blend_op:          GPUBlendOp,              /**< The blend operation for the RGB components. */
	src_alpha_blendfactor:   GPUBlendFactor,          /**< The value to be multiplied by the source alpha. */
	dst_alpha_blendfactor:   GPUBlendFactor,          /**< The value to be multiplied by the destination alpha. */
	alpha_blend_op:          GPUBlendOp,              /**< The blend operation for the alpha component. */
	color_write_mask:        GPUColorComponentFlags,  /**< A bitmask specifying which of the RGBA components are enabled for writing. Writes to all channels if enable_color_write_mask is false. */
	enable_blend:            bool,                    /**< Whether blending is enabled for the color target. */
	enable_color_write_mask: bool,                    /**< Whether the color write mask is enabled. */
	_: Uint8,
	_: Uint8,
}

GPUShaderCreateInfo :: struct {
	code_size:            uint,             /**< The size in bytes of the code pointed to. */
	code:                 [^]Uint8,         /**< A pointer to shader code. */
	entrypoint:           cstring,          /**< A pointer to a null-terminated UTF-8 string specifying the entry point function name for the shader. */
	format:               GPUShaderFormat,  /**< The format of the shader code. */
	stage:                GPUShaderStage,   /**< The stage the shader program corresponds to. */
	num_samplers:         Uint32,           /**< The number of samplers defined in the shader. */
	num_storage_textures: Uint32,           /**< The number of storage textures defined in the shader. */
	num_storage_buffers:  Uint32,           /**< The number of storage buffers defined in the shader. */
	num_uniform_buffers:  Uint32,           /**< The number of uniform buffers defined in the shader. */

	props:                PropertiesID,     /**< A properties ID for extensions. Should be 0 if no extensions are needed. */
}

GPUTextureCreateInfo :: struct {
	type:                 GPUTextureType,        /**< The base dimensionality of the texture. */
	format:               GPUTextureFormat,      /**< The pixel format of the texture. */
	usage:                GPUTextureUsageFlags,  /**< How the texture is intended to be used by the client. */
	width:                Uint32,                /**< The width of the texture. */
	height:               Uint32,                /**< The height of the texture. */
	layer_count_or_depth: Uint32,                /**< The layer count or depth of the texture. This value is treated as a layer count on 2D array textures, and as a depth value on 3D textures. */
	num_levels:           Uint32,                /**< The number of mip levels in the texture. */
	sample_count:         GPUSampleCount,        /**< The number of samples per texel. Only applies if the texture is used as a render target. */

	props:                PropertiesID,          /**< A properties ID for extensions. Should be 0 if no extensions are needed. */
}

GPUBufferCreateInfo :: struct {
	usage: GPUBufferUsageFlags,  /**< How the buffer is intended to be used by the client. */
	size:  Uint32,               /**< The size in bytes of the buffer. */

	props: PropertiesID,         /**< A properties ID for extensions. Should be 0 if no extensions are needed. */
}

GPUTransferBufferCreateInfo :: struct {
	usage: GPUTransferBufferUsage,  /**< How the transfer buffer is intended to be used by the client. */
	size:  Uint32,                  /**< The size in bytes of the transfer buffer. */

	props: PropertiesID,            /**< A properties ID for extensions. Should be 0 if no extensions are needed. */
}

GPURasterizerState :: struct {
	fill_mode:                  GPUFillMode,   /**< Whether polygons will be filled in or drawn as lines. */
	cull_mode:                  GPUCullMode,   /**< The facing direction in which triangles will be culled. */
	front_face:                 GPUFrontFace,  /**< The vertex winding that will cause a triangle to be determined as front-facing. */
	depth_bias_constant_factor: f32,           /**< A scalar factor controlling the depth value added to each fragment. */
	depth_bias_clamp:           f32,           /**< The maximum depth bias of a fragment. */
	depth_bias_slope_factor:    f32,           /**< A scalar factor applied to a fragment's slope in depth calculations. */
	enable_depth_bias:          bool,          /**< true to bias fragment depth values. */
	enable_depth_clip:          bool,          /**< true to enable depth clip, false to enable depth clamp. */
	_: Uint8,
	_: Uint8,
}


GPUMultisampleState :: struct {
	sample_count: GPUSampleCount,  /**< The number of samples to be used in rasterization. */
	sample_mask:  Uint32,          /**< Determines which samples get updated in the render targets. Treated as 0xFFFFFFFF if enable_mask is false. */
	enable_mask:  bool,            /**< Enables sample masking. */
	_: Uint8,
	_: Uint8,
	_: Uint8,
}


GPUDepthStencilState :: struct {
	compare_op:          GPUCompareOp,       /**< The comparison operator used for depth testing. */
	back_stencil_state:  GPUStencilOpState,  /**< The stencil op state for back-facing triangles. */
	front_stencil_state: GPUStencilOpState,  /**< The stencil op state for front-facing triangles. */
	compare_mask:        Uint8,              /**< Selects the bits of the stencil values participating in the stencil test. */
	write_mask:          Uint8,              /**< Selects the bits of the stencil values updated by the stencil test. */
	enable_depth_test:   bool,               /**< true enables the depth test. */
	enable_depth_write:  bool,               /**< true enables depth writes. Depth writes are always disabled when enable_depth_test is false. */
	enable_stencil_test: bool,               /**< true enables the stencil test. */
	_: Uint8,
	_: Uint8,
	_: Uint8,
}

GPUColorTargetDescription :: struct {
	format:      GPUTextureFormat,          /**< The pixel format of the texture to be used as a color target. */
	blend_state: GPUColorTargetBlendState,  /**< The blend state to be used for the color target. */
}

GPUGraphicsPipelineTargetInfo :: struct {
	color_target_descriptions: [^]GPUColorTargetDescription `fmt:"v,num_color_targets"`,  /**< A pointer to an array of color target descriptions. */
	num_color_targets:         Uint32,                                                    /**< The number of color target descriptions in the above array. */
	depth_stencil_format:      GPUTextureFormat,                                          /**< The pixel format of the depth-stencil target. Ignored if has_depth_stencil_target is false. */
	has_depth_stencil_target:  bool,                                                      /**< true specifies that the pipeline uses a depth-stencil target. */
	_: Uint8,
	_: Uint8,
	_: Uint8,
}

GPUGraphicsPipelineCreateInfo :: struct {
	vertex_shader:       ^GPUShader,                     /**< The vertex shader used by the graphics pipeline. */
	fragment_shader:     ^GPUShader,                     /**< The fragment shader used by the graphics pipeline. */
	vertex_input_state:  GPUVertexInputState,            /**< The vertex layout of the graphics pipeline. */
	primitive_type:      GPUPrimitiveType,               /**< The primitive topology of the graphics pipeline. */
	rasterizer_state:    GPURasterizerState,             /**< The rasterizer state of the graphics pipeline. */
	multisample_state:   GPUMultisampleState,            /**< The multisample state of the graphics pipeline. */
	depth_stencil_state: GPUDepthStencilState,           /**< The depth-stencil state of the graphics pipeline. */
	target_info:         GPUGraphicsPipelineTargetInfo,  /**< Formats and blend modes for the render targets of the graphics pipeline. */

	props:               PropertiesID,                   /**< A properties ID for extensions. Should be 0 if no extensions are needed. */
}

GPUComputePipelineCreateInfo :: struct {
	code_size:                      uint,             /**< The size in bytes of the compute shader code pointed to. */
	code:                           [^]Uint8,         /**< A pointer to compute shader code. */
	entrypoint:                     cstring,          /**< A pointer to a null-terminated UTF-8 string specifying the entry point function name for the shader. */
	format:                         GPUShaderFormat,  /**< The format of the compute shader code. */
	num_samplers:                   Uint32,           /**< The number of samplers defined in the shader. */
	num_readonly_storage_textures:  Uint32,           /**< The number of readonly storage textures defined in the shader. */
	num_readonly_storage_buffers:   Uint32,           /**< The number of readonly storage buffers defined in the shader. */
	num_readwrite_storage_textures: Uint32,           /**< The number of read-write storage textures defined in the shader. */
	num_readwrite_storage_buffers:  Uint32,           /**< The number of read-write storage buffers defined in the shader. */
	num_uniform_buffers:            Uint32,           /**< The number of uniform buffers defined in the shader. */
	threadcount_x:                  Uint32,           /**< The number of threads in the X dimension. This should match the value in the shader. */
	threadcount_y:                  Uint32,           /**< The number of threads in the Y dimension. This should match the value in the shader. */
	threadcount_z:                  Uint32,           /**< The number of threads in the Z dimension. This should match the value in the shader. */

	props:                          PropertiesID,     /**< A properties ID for extensions. Should be 0 if no extensions are needed. */
}

GPUColorTargetInfo :: struct {
	texture:               ^GPUTexture,  /**< The texture that will be used as a color target by a render pass. */
	mip_level:             Uint32,       /**< The mip level to use as a color target. */
	layer_or_depth_plane:  Uint32,       /**< The layer index or depth plane to use as a color target. This value is treated as a layer index on 2D array and cube textures, and as a depth plane on 3D textures. */
	clear_color:           FColor,       /**< The color to clear the color target to at the start of the render pass. Ignored if GPU_LOADOP_CLEAR is not used. */
	load_op:               GPULoadOp,    /**< What is done with the contents of the color target at the beginning of the render pass. */
	store_op:              GPUStoreOp,   /**< What is done with the results of the render pass. */
	resolve_texture:       ^GPUTexture,  /**< The texture that will receive the results of a multisample resolve operation. Ignored if a RESOLVE* store_op is not used. */
	resolve_mip_level:     Uint32,       /**< The mip level of the resolve texture to use for the resolve operation. Ignored if a RESOLVE* store_op is not used. */
	resolve_layer:         Uint32,       /**< The layer index of the resolve texture to use for the resolve operation. Ignored if a RESOLVE* store_op is not used. */
	cycle:                 bool,         /**< true cycles the texture if the texture is bound and load_op is not LOAD */
	cycle_resolve_texture: bool,         /**< true cycles the resolve texture if the resolve texture is bound. Ignored if a RESOLVE* store_op is not used. */
	_: Uint8,
	_: Uint8,
}

GPUDepthStencilTargetInfo :: struct {
	texture:          ^GPUTexture,  /**< The texture that will be used as the depth stencil target by the render pass. */
	clear_depth:      f32,          /**< The value to clear the depth component to at the beginning of the render pass. Ignored if GPU_LOADOP_CLEAR is not used. */
	load_op:          GPULoadOp,    /**< What is done with the depth contents at the beginning of the render pass. */
	store_op:         GPUStoreOp,   /**< What is done with the depth results of the render pass. */
	stencil_load_op:  GPULoadOp,    /**< What is done with the stencil contents at the beginning of the render pass. */
	stencil_store_op: GPUStoreOp,   /**< What is done with the stencil results of the render pass. */
	cycle:            bool,         /**< true cycles the texture if the texture is bound and any load ops are not LOAD */
	clear_stencil:    Uint8,        /**< The value to clear the stencil component to at the beginning of the render pass. Ignored if GPU_LOADOP_CLEAR is not used. */
	_: Uint8,
	_: Uint8,
}


GPUBlitInfo :: struct {
	source:      GPUBlitRegion,  /**< The source region for the blit. */
	destination: GPUBlitRegion,  /**< The destination region for the blit. */
	load_op:     GPULoadOp,      /**< What is done with the contents of the destination before the blit. */
	clear_color: FColor,         /**< The color to clear the destination region to before the blit. Ignored if load_op is not GPU_LOADOP_CLEAR. */
	flip_mode:   FlipMode,       /**< The flip mode for the source region. */
	filter:      GPUFilter,      /**< The filter mode used when blitting. */
	cycle:       bool,           /**< true cycles the destination texture if it is already bound. */
	_: Uint8,
	_: Uint8,
	_: Uint8,
}

GPUBufferBinding :: struct {
	buffer: ^GPUBuffer,  /**< The buffer to bind. Must have been created with GPU_BUFFERUSAGE_VERTEX for BindGPUVertexBuffers, or GPU_BUFFERUSAGE_INDEX for BindGPUIndexBuffer. */
	offset: Uint32,      /**< The starting byte of the data to bind in the buffer. */
}

GPUTextureSamplerBinding :: struct {
	texture: ^GPUTexture,  /**< The texture to bind. Must have been created with GPU_TEXTUREUSAGE_SAMPLER. */
	sampler: ^GPUSampler,  /**< The sampler to bind. */
}

GPUStorageBufferReadWriteBinding :: struct {
	buffer: ^GPUBuffer,  /**< The buffer to bind. Must have been created with GPU_BUFFERUSAGE_COMPUTE_STORAGE_WRITE. */
	cycle:  bool,        /**< true cycles the buffer if it is already bound. */
	_: Uint8,
	_: Uint8,
	_: Uint8,
}

GPUStorageTextureReadWriteBinding :: struct {
	texture:   ^GPUTexture,  /**< The texture to bind. Must have been created with GPU_TEXTUREUSAGE_COMPUTE_STORAGE_WRITE or GPU_TEXTUREUSAGE_COMPUTE_STORAGE_SIMULTANEOUS_READ_WRITE. */
	mip_level: Uint32,       /**< The mip level index to bind. */
	layer:     Uint32,       /**< The layer index to bind. */
	cycle:     bool,         /**< true cycles the texture if it is already bound. */
	_: Uint8,
	_: Uint8,
	_: Uint8,
}


PROP_GPU_DEVICE_CREATE_DEBUGMODE_BOOLEAN          :: "SDL.gpu.device.create.debugmode"
PROP_GPU_DEVICE_CREATE_PREFERLOWPOWER_BOOLEAN     :: "SDL.gpu.device.create.preferlowpower"
PROP_GPU_DEVICE_CREATE_NAME_STRING                :: "SDL.gpu.device.create.name"
PROP_GPU_DEVICE_CREATE_SHADERS_PRIVATE_BOOLEAN    :: "SDL.gpu.device.create.shaders.private"
PROP_GPU_DEVICE_CREATE_SHADERS_SPIRV_BOOLEAN      :: "SDL.gpu.device.create.shaders.spirv"
PROP_GPU_DEVICE_CREATE_SHADERS_DXBC_BOOLEAN       :: "SDL.gpu.device.create.shaders.dxbc"
PROP_GPU_DEVICE_CREATE_SHADERS_DXIL_BOOLEAN       :: "SDL.gpu.device.create.shaders.dxil"
PROP_GPU_DEVICE_CREATE_SHADERS_MSL_BOOLEAN        :: "SDL.gpu.device.create.shaders.msl"
PROP_GPU_DEVICE_CREATE_SHADERS_METALLIB_BOOLEAN   :: "SDL.gpu.device.create.shaders.metallib"
PROP_GPU_DEVICE_CREATE_D3D12_SEMANTIC_NAME_STRING :: "SDL.gpu.device.create.d3d12.semantic"

PROP_GPU_COMPUTEPIPELINE_CREATE_NAME_STRING       :: "SDL.gpu.computepipeline.create.name"
PROP_GPU_GRAPHICSPIPELINE_CREATE_NAME_STRING      :: "SDL.gpu.graphicspipeline.create.name"
PROP_GPU_SAMPLER_CREATE_NAME_STRING               :: "SDL.gpu.sampler.create.name"
PROP_GPU_SHADER_CREATE_NAME_STRING                :: "SDL.gpu.shader.create.name"
PROP_GPU_TEXTURE_CREATE_D3D12_CLEAR_R_FLOAT       :: "SDL.gpu.texture.create.d3d12.clear.r"
PROP_GPU_TEXTURE_CREATE_D3D12_CLEAR_G_FLOAT       :: "SDL.gpu.texture.create.d3d12.clear.g"
PROP_GPU_TEXTURE_CREATE_D3D12_CLEAR_B_FLOAT       :: "SDL.gpu.texture.create.d3d12.clear.b"
PROP_GPU_TEXTURE_CREATE_D3D12_CLEAR_A_FLOAT       :: "SDL.gpu.texture.create.d3d12.clear.a"
PROP_GPU_TEXTURE_CREATE_D3D12_CLEAR_DEPTH_FLOAT   :: "SDL.gpu.texture.create.d3d12.clear.depth"
PROP_GPU_TEXTURE_CREATE_D3D12_CLEAR_STENCIL_UINT8 :: "SDL.gpu.texture.create.d3d12.clear.stencil"
PROP_GPU_TEXTURE_CREATE_NAME_STRING               :: "SDL.gpu.texture.create.name"
PROP_GPU_BUFFER_CREATE_NAME_STRING                :: "SDL.gpu.buffer.create.name"
PROP_GPU_TRANSFERBUFFER_CREATE_NAME_STRING        :: "SDL.gpu.transferbuffer.create.name"

@(default_calling_convention="c", link_prefix="SDL_", require_results)
foreign lib {
	GPUSupportsShaderFormats              :: proc(format_flags: GPUShaderFormat, name: cstring) -> bool ---
	GPUSupportsProperties                 :: proc(props: PropertiesID) -> bool ---
	CreateGPUDevice                       :: proc(format_flags: GPUShaderFormat, debug_mode: bool, name: cstring) -> ^GPUDevice ---
	CreateGPUDeviceWithProperties         :: proc(props: PropertiesID) -> ^GPUDevice ---
	DestroyGPUDevice                      :: proc(device: ^GPUDevice) ---
	GetNumGPUDrivers                      :: proc() -> c.int ---
	GetGPUDriver                          :: proc(index: c.int) -> cstring ---
	GetGPUDeviceDriver                    :: proc(device: ^GPUDevice) -> cstring ---
	GetGPUShaderFormats                   :: proc(device: ^GPUDevice) -> GPUShaderFormat ---
	CreateGPUComputePipeline              :: proc(device: ^GPUDevice, #by_ptr createinfo: GPUComputePipelineCreateInfo) -> ^GPUComputePipeline ---
	CreateGPUGraphicsPipeline             :: proc(device: ^GPUDevice, #by_ptr createinfo: GPUGraphicsPipelineCreateInfo) -> ^GPUGraphicsPipeline ---
	CreateGPUSampler                      :: proc(device: ^GPUDevice, #by_ptr createinfo: GPUSamplerCreateInfo) -> ^GPUSampler ---
	CreateGPUShader                       :: proc(device: ^GPUDevice, #by_ptr createinfo: GPUShaderCreateInfo) -> ^GPUShader ---
	CreateGPUTexture                      :: proc(device: ^GPUDevice, #by_ptr createinfo: GPUTextureCreateInfo) -> ^GPUTexture ---
	CreateGPUBuffer                       :: proc(device: ^GPUDevice, #by_ptr createinfo: GPUBufferCreateInfo) -> ^GPUBuffer ---
	CreateGPUTransferBuffer               :: proc(device: ^GPUDevice, #by_ptr createinfo: GPUTransferBufferCreateInfo) -> ^GPUTransferBuffer ---
	SetGPUBufferName                      :: proc(device: ^GPUDevice, buffer: ^GPUBuffer, text: cstring) ---
	SetGPUTextureName                     :: proc(device: ^GPUDevice, texture: ^GPUTexture, text: cstring) ---
	InsertGPUDebugLabel                   :: proc(command_buffer: ^GPUCommandBuffer, text: cstring) ---
	PushGPUDebugGroup                     :: proc(command_buffer: ^GPUCommandBuffer, name: cstring) ---
	PopGPUDebugGroup                      :: proc(command_buffer: ^GPUCommandBuffer) ---
	ReleaseGPUTexture                     :: proc(device: ^GPUDevice, texture: ^GPUTexture) ---
	ReleaseGPUSampler                     :: proc(device: ^GPUDevice, sampler: ^GPUSampler) ---
	ReleaseGPUBuffer                      :: proc(device: ^GPUDevice, buffer: ^GPUBuffer) ---
	ReleaseGPUTransferBuffer              :: proc(device: ^GPUDevice, transfer_buffer: ^GPUTransferBuffer) ---
	ReleaseGPUComputePipeline             :: proc(device: ^GPUDevice, compute_pipeline: ^GPUComputePipeline) ---
	ReleaseGPUShader                      :: proc(device: ^GPUDevice, shader: ^GPUShader) ---
	ReleaseGPUGraphicsPipeline            :: proc(device: ^GPUDevice, graphics_pipeline: ^GPUGraphicsPipeline) ---
	AcquireGPUCommandBuffer               :: proc(device: ^GPUDevice) -> ^GPUCommandBuffer ---
	PushGPUVertexUniformData              :: proc(command_buffer: ^GPUCommandBuffer, slot_index: Uint32, data: rawptr, length: Uint32) ---
	PushGPUFragmentUniformData            :: proc(command_buffer: ^GPUCommandBuffer, slot_index: Uint32, data: rawptr, length: Uint32) ---
	PushGPUComputeUniformData             :: proc(command_buffer: ^GPUCommandBuffer, slot_index: Uint32, data: rawptr, length: Uint32) ---
	BeginGPURenderPass                    :: proc(command_buffer: ^GPUCommandBuffer, color_target_infos: [^]GPUColorTargetInfo, num_color_targets: Uint32, depth_stencil_target_info: Maybe(^GPUDepthStencilTargetInfo)) -> ^GPURenderPass ---
	BindGPUGraphicsPipeline               :: proc(render_pass: ^GPURenderPass, graphics_pipeline: ^GPUGraphicsPipeline) ---
	SetGPUViewport                        :: proc(render_pass: ^GPURenderPass, #by_ptr viewport: GPUViewport) ---
	SetGPUScissor                         :: proc(render_pass: ^GPURenderPass, #by_ptr scissor: Rect) ---
	SetGPUBlendConstants                  :: proc(render_pass: ^GPURenderPass, blend_constants: FColor) ---
	SetGPUStencilReference                :: proc(render_pass: ^GPURenderPass, reference: Uint8) ---
	BindGPUVertexBuffers                  :: proc(render_pass: ^GPURenderPass, first_slot: Uint32, bindings: [^]GPUBufferBinding, num_bindings: Uint32) ---
	BindGPUIndexBuffer                    :: proc(render_pass: ^GPURenderPass, #by_ptr binding: GPUBufferBinding, index_element_size: GPUIndexElementSize) ---
	BindGPUVertexSamplers                 :: proc(render_pass: ^GPURenderPass, first_slot: Uint32, texture_sampler_bindings: [^]GPUTextureSamplerBinding, num_bindings: Uint32) ---
	BindGPUVertexStorageTextures          :: proc(render_pass: ^GPURenderPass, first_slot: Uint32, storage_textures: [^]^GPUTexture, num_bindings: Uint32) ---
	BindGPUVertexStorageBuffers           :: proc(render_pass: ^GPURenderPass, first_slot: Uint32, storage_buffers: [^]^GPUBuffer, num_bindings: Uint32) ---
	BindGPUFragmentSamplers               :: proc(render_pass: ^GPURenderPass, first_slot: Uint32, texture_sampler_bindings: [^]GPUTextureSamplerBinding, num_bindings: Uint32) ---
	BindGPUFragmentStorageTextures        :: proc(render_pass: ^GPURenderPass, first_slot: Uint32, storage_textures: [^]^GPUTexture, num_bindings: Uint32) ---
	BindGPUFragmentStorageBuffers         :: proc(render_pass: ^GPURenderPass, first_slot: Uint32, storage_buffers: [^]^GPUBuffer, num_bindings: Uint32) ---
	DrawGPUIndexedPrimitives              :: proc(render_pass: ^GPURenderPass, num_indices: Uint32,  num_instances: Uint32, first_index:  Uint32, vertex_offset: Sint32, first_instance: Uint32) ---
	DrawGPUPrimitives                     :: proc(render_pass: ^GPURenderPass, num_vertices: Uint32, num_instances: Uint32, first_vertex: Uint32, first_instance: Uint32) ---
	DrawGPUPrimitivesIndirect             :: proc(render_pass: ^GPURenderPass, buffer: ^GPUBuffer, offset: Uint32, draw_count: Uint32) ---
	DrawGPUIndexedPrimitivesIndirect      :: proc(render_pass: ^GPURenderPass, buffer: ^GPUBuffer, offset: Uint32, draw_count: Uint32) ---
	EndGPURenderPass                      :: proc(render_pass: ^GPURenderPass) ---
	BeginGPUComputePass                   :: proc(command_buffer: ^GPUCommandBuffer, storage_texture_bindings: [^]GPUStorageTextureReadWriteBinding, num_storage_texture_bindings: Uint32, storage_buffer_bindings: [^]GPUStorageBufferReadWriteBinding, num_storage_buffer_bindings: Uint32) -> ^GPUComputePass ---
	BindGPUComputePipeline                :: proc(compute_pass: ^GPUComputePass, compute_pipeline: ^GPUComputePipeline) ---
	BindGPUComputeSamplers                :: proc(compute_pass: ^GPUComputePass, first_slot: Uint32, texture_sampler_bindings: [^]GPUTextureSamplerBinding, num_bindings: Uint32) ---
	BindGPUComputeStorageTextures         :: proc(compute_pass: ^GPUComputePass, first_slot: Uint32, storage_textures: [^]^GPUTexture, num_bindings: Uint32) ---
	BindGPUComputeStorageBuffers          :: proc(compute_pass: ^GPUComputePass, first_slot: Uint32, storage_buffers: [^]^GPUBuffer, num_bindings: Uint32) ---
	DispatchGPUCompute                    :: proc(compute_pass: ^GPUComputePass, groupcount_x, groupcount_y, groupcount_z: Uint32) ---
	DispatchGPUComputeIndirect            :: proc(compute_pass: ^GPUComputePass, buffer: ^GPUBuffer, offset: Uint32) ---
	EndGPUComputePass                     :: proc(compute_pass: ^GPUComputePass) ---
	MapGPUTransferBuffer                  :: proc(device: ^GPUDevice, transfer_buffer: ^GPUTransferBuffer, cycle: bool) -> rawptr ---
	UnmapGPUTransferBuffer                :: proc(device: ^GPUDevice, transfer_buffer: ^GPUTransferBuffer) ---
	BeginGPUCopyPass                      :: proc(command_buffer: ^GPUCommandBuffer) -> ^GPUCopyPass ---
	UploadToGPUTexture                    :: proc(copy_pass: ^GPUCopyPass, #by_ptr source: GPUTextureTransferInfo,    #by_ptr destination: GPUTextureRegion, cycle: bool) ---
	UploadToGPUBuffer                     :: proc(copy_pass: ^GPUCopyPass, #by_ptr source: GPUTransferBufferLocation, #by_ptr destination: GPUBufferRegion, cycle: bool) ---
	CopyGPUTextureToTexture               :: proc(copy_pass: ^GPUCopyPass, #by_ptr source: GPUTextureLocation,        #by_ptr destination: GPUTextureLocation, w, h, d: Uint32, cycle: bool) ---
	CopyGPUBufferToBuffer                 :: proc(copy_pass: ^GPUCopyPass, #by_ptr source: GPUBufferLocation,         #by_ptr destination: GPUBufferLocation, size: Uint32, cycle: bool) ---
	DownloadFromGPUTexture                :: proc(copy_pass: ^GPUCopyPass, #by_ptr source: GPUTextureRegion,          #by_ptr destination: GPUTextureTransferInfo) ---
	DownloadFromGPUBuffer                 :: proc(copy_pass: ^GPUCopyPass, #by_ptr source: GPUBufferRegion,           #by_ptr destination: GPUTransferBufferLocation) ---
	EndGPUCopyPass                        :: proc(copy_pass: ^GPUCopyPass) ---
	GenerateMipmapsForGPUTexture          :: proc(command_buffer: ^GPUCommandBuffer, texture: ^GPUTexture) ---
	BlitGPUTexture                        :: proc(command_buffer: ^GPUCommandBuffer, #by_ptr info: GPUBlitInfo) ---
	WindowSupportsGPUSwapchainComposition :: proc(device: ^GPUDevice, window: ^Window, swapchain_composition: GPUSwapchainComposition) -> bool ---
	WindowSupportsGPUPresentMode          :: proc(device: ^GPUDevice, window: ^Window, present_mode: GPUPresentMode) -> bool ---
	ClaimWindowForGPUDevice               :: proc(device: ^GPUDevice, window: ^Window) -> bool ---
	ReleaseWindowFromGPUDevice            :: proc(device: ^GPUDevice, window: ^Window) ---
	SetGPUSwapchainParameters             :: proc(device: ^GPUDevice, window: ^Window, swapchain_composition: GPUSwapchainComposition, present_mode: GPUPresentMode) -> bool ---
	SetGPUAllowedFramesInFlight           :: proc(device: ^GPUDevice, allowed_frames_in_flight: Uint32) -> bool ---
	GetGPUSwapchainTextureFormat          :: proc(device: ^GPUDevice, window: ^Window) -> GPUTextureFormat ---
	AcquireGPUSwapchainTexture            :: proc(command_buffer: ^GPUCommandBuffer, window: ^Window, swapchain_texture: ^^GPUTexture, swapchain_texture_width, swapchain_texture_height: ^Uint32) -> bool ---
	WaitForGPUSwapchain                   :: proc(device: ^GPUDevice, window: ^Window) -> bool ---
	WaitAndAcquireGPUSwapchainTexture     :: proc(command_buffer: ^GPUCommandBuffer, window: ^Window, swapchain_texture: ^^GPUTexture, swapchain_texture_width, swapchain_texture_height: ^Uint32) -> bool ---
	SubmitGPUCommandBuffer                :: proc(command_buffer: ^GPUCommandBuffer) -> bool ---
	SubmitGPUCommandBufferAndAcquireFence :: proc(command_buffer: ^GPUCommandBuffer) -> ^GPUFence ---
	CancelGPUCommandBuffer                :: proc(command_buffer: ^GPUCommandBuffer) -> bool ---
	WaitForGPUIdle                        :: proc(device: ^GPUDevice) -> bool ---
	WaitForGPUFences                      :: proc(device: ^GPUDevice, wait_all: bool, fences: [^]^GPUFence, num_fences: Uint32) -> bool ---
	QueryGPUFence                         :: proc(device: ^GPUDevice, fence: ^GPUFence) -> bool ---
	ReleaseGPUFence                       :: proc(device: ^GPUDevice, fence: ^GPUFence) ---
	GPUTextureFormatTexelBlockSize        :: proc(format: GPUTextureFormat) -> Uint32 ---
	GPUTextureSupportsFormat              :: proc(device: ^GPUDevice, format: GPUTextureFormat, type: GPUTextureType, usage: GPUTextureUsageFlags) -> bool ---
	GPUTextureSupportsSampleCount         :: proc(device: ^GPUDevice, format: GPUTextureFormat, sample_count: GPUSampleCount) -> bool ---
	CalculateGPUTextureFormatSize         :: proc(format: GPUTextureFormat, width, height: Uint32, depth_or_layer_count: Uint32) -> Uint32 ---
}




// GDK
@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	GDKSuspendGPU :: proc(device: ^GPUDevice) ---
	GDKResumeGPU  :: proc(device: ^GPUDevice) ---
}


