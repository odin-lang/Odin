package sdl3

import "core:c"


SOFTWARE_RENDERER :: "software"

Vertex :: struct {
	position:  FPoint, /**< Vertex position, in SDL_Renderer coordinates  */
	color:     FColor, /**< Vertex color */
	tex_coord: FPoint, /**< Normalized texture coordinates, if needed */
}

TextureAccess :: enum c.int {
	STATIC,    /**< Changes rarely, not lockable */
	STREAMING, /**< Changes frequently, lockable */
	TARGET,    /**< Texture can be used as a render target */
}

RendererLogicalPresentation :: enum c.int {
	DISABLED,      /**< There is no logical size in effect */
	STRETCH,       /**< The rendered content is stretched to the output resolution */
	LETTERBOX,     /**< The rendered content is fit to the largest dimension and the other dimension is letterboxed with black bars */
	OVERSCAN,      /**< The rendered content is fit to the smallest dimension and the other dimension extends beyond the output bounds */
	INTEGER_SCALE, /**< The rendered content is scaled up by integer multiples to fit the output resolution */
}

Renderer :: struct {}

Texture :: struct {
	format:   PixelFormat,  /**< The format of the texture, read-only */
	w:        c.int,        /**< The width of the texture, read-only. */
	h:        c.int,        /**< The height of the texture, read-only. */

	refcount: c.int,        /**< Application reference count, used when freeing texture */
}

PROP_RENDERER_CREATE_NAME_STRING                                :: "SDL.renderer.create.name"
PROP_RENDERER_CREATE_WINDOW_POINTER                             :: "SDL.renderer.create.window"
PROP_RENDERER_CREATE_SURFACE_POINTER                            :: "SDL.renderer.create.surface"
PROP_RENDERER_CREATE_OUTPUT_COLORSPACE_NUMBER                   :: "SDL.renderer.create.output_colorspace"
PROP_RENDERER_CREATE_PRESENT_VSYNC_NUMBER                       :: "SDL.renderer.create.present_vsync"
PROP_RENDERER_CREATE_VULKAN_INSTANCE_POINTER                    :: "SDL.renderer.create.vulkan.instance"
PROP_RENDERER_CREATE_VULKAN_SURFACE_NUMBER                      :: "SDL.renderer.create.vulkan.surface"
PROP_RENDERER_CREATE_VULKAN_PHYSICAL_DEVICE_POINTER             :: "SDL.renderer.create.vulkan.physical_device"
PROP_RENDERER_CREATE_VULKAN_DEVICE_POINTER                      :: "SDL.renderer.create.vulkan.device"
PROP_RENDERER_CREATE_VULKAN_GRAPHICS_QUEUE_FAMILY_INDEX_NUMBER  :: "SDL.renderer.create.vulkan.graphics_queue_family_index"
PROP_RENDERER_CREATE_VULKAN_PRESENT_QUEUE_FAMILY_INDEX_NUMBER   :: "SDL.renderer.create.vulkan.present_queue_family_index"

PROP_RENDERER_NAME_STRING                               :: "SDL.renderer.name"
PROP_RENDERER_WINDOW_POINTER                            :: "SDL.renderer.window"
PROP_RENDERER_SURFACE_POINTER                           :: "SDL.renderer.surface"
PROP_RENDERER_VSYNC_NUMBER                              :: "SDL.renderer.vsync"
PROP_RENDERER_MAX_TEXTURE_SIZE_NUMBER                   :: "SDL.renderer.max_texture_size"
PROP_RENDERER_TEXTURE_FORMATS_POINTER                   :: "SDL.renderer.texture_formats"
PROP_RENDERER_OUTPUT_COLORSPACE_NUMBER                  :: "SDL.renderer.output_colorspace"
PROP_RENDERER_HDR_ENABLED_BOOLEAN                       :: "SDL.renderer.HDR_enabled"
PROP_RENDERER_SDR_WHITE_POINT_FLOAT                     :: "SDL.renderer.SDR_white_point"
PROP_RENDERER_HDR_HEADROOM_FLOAT                        :: "SDL.renderer.HDR_headroom"
PROP_RENDERER_D3D9_DEVICE_POINTER                       :: "SDL.renderer.d3d9.device"
PROP_RENDERER_D3D11_DEVICE_POINTER                      :: "SDL.renderer.d3d11.device"
PROP_RENDERER_D3D11_SWAPCHAIN_POINTER                   :: "SDL.renderer.d3d11.swap_chain"
PROP_RENDERER_D3D12_DEVICE_POINTER                      :: "SDL.renderer.d3d12.device"
PROP_RENDERER_D3D12_SWAPCHAIN_POINTER                   :: "SDL.renderer.d3d12.swap_chain"
PROP_RENDERER_D3D12_COMMAND_QUEUE_POINTER               :: "SDL.renderer.d3d12.command_queue"
PROP_RENDERER_VULKAN_INSTANCE_POINTER                   :: "SDL.renderer.vulkan.instance"
PROP_RENDERER_VULKAN_SURFACE_NUMBER                     :: "SDL.renderer.vulkan.surface"
PROP_RENDERER_VULKAN_PHYSICAL_DEVICE_POINTER            :: "SDL.renderer.vulkan.physical_device"
PROP_RENDERER_VULKAN_DEVICE_POINTER                     :: "SDL.renderer.vulkan.device"
PROP_RENDERER_VULKAN_GRAPHICS_QUEUE_FAMILY_INDEX_NUMBER :: "SDL.renderer.vulkan.graphics_queue_family_index"
PROP_RENDERER_VULKAN_PRESENT_QUEUE_FAMILY_INDEX_NUMBER  :: "SDL.renderer.vulkan.present_queue_family_index"
PROP_RENDERER_VULKAN_SWAPCHAIN_IMAGE_COUNT_NUMBER       :: "SDL.renderer.vulkan.swapchain_image_count"
PROP_RENDERER_GPU_DEVICE_POINTER                        :: "SDL.renderer.gpu.device"

PROP_TEXTURE_CREATE_COLORSPACE_NUMBER           :: "SDL.texture.create.colorspace"
PROP_TEXTURE_CREATE_FORMAT_NUMBER               :: "SDL.texture.create.format"
PROP_TEXTURE_CREATE_ACCESS_NUMBER               :: "SDL.texture.create.access"
PROP_TEXTURE_CREATE_WIDTH_NUMBER                :: "SDL.texture.create.width"
PROP_TEXTURE_CREATE_HEIGHT_NUMBER               :: "SDL.texture.create.height"
PROP_TEXTURE_CREATE_SDR_WHITE_POINT_FLOAT       :: "SDL.texture.create.SDR_white_point"
PROP_TEXTURE_CREATE_HDR_HEADROOM_FLOAT          :: "SDL.texture.create.HDR_headroom"
PROP_TEXTURE_CREATE_D3D11_TEXTURE_POINTER       :: "SDL.texture.create.d3d11.texture"
PROP_TEXTURE_CREATE_D3D11_TEXTURE_U_POINTER     :: "SDL.texture.create.d3d11.texture_u"
PROP_TEXTURE_CREATE_D3D11_TEXTURE_V_POINTER     :: "SDL.texture.create.d3d11.texture_v"
PROP_TEXTURE_CREATE_D3D12_TEXTURE_POINTER       :: "SDL.texture.create.d3d12.texture"
PROP_TEXTURE_CREATE_D3D12_TEXTURE_U_POINTER     :: "SDL.texture.create.d3d12.texture_u"
PROP_TEXTURE_CREATE_D3D12_TEXTURE_V_POINTER     :: "SDL.texture.create.d3d12.texture_v"
PROP_TEXTURE_CREATE_METAL_PIXELBUFFER_POINTER   :: "SDL.texture.create.metal.pixelbuffer"
PROP_TEXTURE_CREATE_OPENGL_TEXTURE_NUMBER       :: "SDL.texture.create.opengl.texture"
PROP_TEXTURE_CREATE_OPENGL_TEXTURE_UV_NUMBER    :: "SDL.texture.create.opengl.texture_uv"
PROP_TEXTURE_CREATE_OPENGL_TEXTURE_U_NUMBER     :: "SDL.texture.create.opengl.texture_u"
PROP_TEXTURE_CREATE_OPENGL_TEXTURE_V_NUMBER     :: "SDL.texture.create.opengl.texture_v"
PROP_TEXTURE_CREATE_OPENGLES2_TEXTURE_NUMBER    :: "SDL.texture.create.opengles2.texture"
PROP_TEXTURE_CREATE_OPENGLES2_TEXTURE_UV_NUMBER :: "SDL.texture.create.opengles2.texture_uv"
PROP_TEXTURE_CREATE_OPENGLES2_TEXTURE_U_NUMBER  :: "SDL.texture.create.opengles2.texture_u"
PROP_TEXTURE_CREATE_OPENGLES2_TEXTURE_V_NUMBER  :: "SDL.texture.create.opengles2.texture_v"
PROP_TEXTURE_CREATE_VULKAN_TEXTURE_NUMBER       :: "SDL.texture.create.vulkan.texture"

PROP_TEXTURE_COLORSPACE_NUMBER                  :: "SDL.texture.colorspace"
PROP_TEXTURE_FORMAT_NUMBER                      :: "SDL.texture.format"
PROP_TEXTURE_ACCESS_NUMBER                      :: "SDL.texture.access"
PROP_TEXTURE_WIDTH_NUMBER                       :: "SDL.texture.width"
PROP_TEXTURE_HEIGHT_NUMBER                      :: "SDL.texture.height"
PROP_TEXTURE_SDR_WHITE_POINT_FLOAT              :: "SDL.texture.SDR_white_point"
PROP_TEXTURE_HDR_HEADROOM_FLOAT                 :: "SDL.texture.HDR_headroom"
PROP_TEXTURE_D3D11_TEXTURE_POINTER              :: "SDL.texture.d3d11.texture"
PROP_TEXTURE_D3D11_TEXTURE_U_POINTER            :: "SDL.texture.d3d11.texture_u"
PROP_TEXTURE_D3D11_TEXTURE_V_POINTER            :: "SDL.texture.d3d11.texture_v"
PROP_TEXTURE_D3D12_TEXTURE_POINTER              :: "SDL.texture.d3d12.texture"
PROP_TEXTURE_D3D12_TEXTURE_U_POINTER            :: "SDL.texture.d3d12.texture_u"
PROP_TEXTURE_D3D12_TEXTURE_V_POINTER            :: "SDL.texture.d3d12.texture_v"
PROP_TEXTURE_OPENGL_TEXTURE_NUMBER              :: "SDL.texture.opengl.texture"
PROP_TEXTURE_OPENGL_TEXTURE_UV_NUMBER           :: "SDL.texture.opengl.texture_uv"
PROP_TEXTURE_OPENGL_TEXTURE_U_NUMBER            :: "SDL.texture.opengl.texture_u"
PROP_TEXTURE_OPENGL_TEXTURE_V_NUMBER            :: "SDL.texture.opengl.texture_v"
PROP_TEXTURE_OPENGL_TEXTURE_TARGET_NUMBER       :: "SDL.texture.opengl.target"
PROP_TEXTURE_OPENGL_TEX_W_FLOAT                 :: "SDL.texture.opengl.tex_w"
PROP_TEXTURE_OPENGL_TEX_H_FLOAT                 :: "SDL.texture.opengl.tex_h"
PROP_TEXTURE_OPENGLES2_TEXTURE_NUMBER           :: "SDL.texture.opengles2.texture"
PROP_TEXTURE_OPENGLES2_TEXTURE_UV_NUMBER        :: "SDL.texture.opengles2.texture_uv"
PROP_TEXTURE_OPENGLES2_TEXTURE_U_NUMBER         :: "SDL.texture.opengles2.texture_u"
PROP_TEXTURE_OPENGLES2_TEXTURE_V_NUMBER         :: "SDL.texture.opengles2.texture_v"
PROP_TEXTURE_OPENGLES2_TEXTURE_TARGET_NUMBER    :: "SDL.texture.opengles2.target"
PROP_TEXTURE_VULKAN_TEXTURE_NUMBER              :: "SDL.texture.vulkan.texture"

RENDERER_VSYNC_DISABLED :: 0
RENDERER_VSYNC_ADAPTIVE :: -1

DEBUG_TEXT_FONT_CHARACTER_SIZE :: 8

@(default_calling_convention="c", link_prefix="SDL_", require_results)
foreign lib {
	GetNumRenderDrivers              :: proc() -> c.int ---
	GetRenderDriver                  :: proc(index: c.int) -> cstring ---
	CreateRenderer                   :: proc(window: ^Window, name: cstring) -> ^Renderer ---
	CreateRendererWithProperties     :: proc(props: PropertiesID) -> ^Renderer ---
	CreateSoftwareRenderer           :: proc(surface: ^Surface) -> ^Renderer ---
	GetRenderer                      :: proc(window: ^Window) -> ^Renderer ---
	GetRenderWindow                  :: proc(renderer: ^Renderer) -> ^Window ---
	GetRendererName                  :: proc(renderer: ^Renderer) -> cstring ---
	GetRendererProperties            :: proc(renderer: ^Renderer) -> PropertiesID ---
	CreateTexture                    :: proc(renderer: ^Renderer, format: PixelFormat, access: TextureAccess, w, h: c.int) -> ^Texture ---
	CreateTextureFromSurface         :: proc(renderer: ^Renderer, surface: ^Surface) -> ^Texture ---
	CreateTextureWithProperties      :: proc(renderer: ^Renderer, props: PropertiesID) -> ^Texture ---
	GetTextureProperties             :: proc(texture: ^Texture) -> PropertiesID ---
	GetRendererFromTexture           :: proc(texture: ^Texture) -> ^Renderer ---
	GetRenderTarget                  :: proc(renderer: ^Renderer) -> Maybe(^Texture) ---
	RenderViewportSet                :: proc(renderer: ^Renderer) -> bool ---
	RenderClipEnabled                :: proc(renderer: ^Renderer) -> bool ---
	RenderReadPixels                 :: proc(renderer: ^Renderer, rect: Maybe(^Rect)) -> ^Surface ---
	GetRenderMetalLayer              :: proc(renderer: ^Renderer) -> rawptr ---
	GetRenderMetalCommandEncoder     :: proc(renderer: ^Renderer) -> rawptr ---
}

@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	CreateWindowAndRenderer          :: proc(title: cstring, width, height: c.int, window_flags: WindowFlags, window: ^^Window, renderer: ^^Renderer) -> bool ---
	GetRenderOutputSize              :: proc(renderer: ^Renderer, w, h: ^c.int) -> bool ---
	GetCurrentRenderOutputSize       :: proc(renderer: ^Renderer, w, h: ^c.int) -> bool ---
	GetTextureSize                   :: proc(texture: ^Texture, w, h: ^f32) -> bool ---
	SetTextureColorMod               :: proc(texture: ^Texture, r, g, b: Uint8) -> bool ---
	SetTextureColorModFloat          :: proc(texture: ^Texture, r, g, b: f32) -> bool ---
	GetTextureColorMod               :: proc(texture: ^Texture, r, g, b: ^Uint8) -> bool ---
	GetTextureColorModFloat          :: proc(texture: ^Texture, r, g, b: ^f32) -> bool ---
	SetTextureAlphaMod               :: proc(texture: ^Texture, alpha: Uint8) -> bool ---
	SetTextureAlphaModFloat          :: proc(texture: ^Texture, alpha: f32) -> bool ---
	GetTextureAlphaMod               :: proc(texture: ^Texture, alpha: ^Uint8) -> bool ---
	GetTextureAlphaModFloat          :: proc(texture: ^Texture, alpha: ^f32) -> bool ---
	SetTextureBlendMode              :: proc(texture: ^Texture, blendMode: BlendMode) -> bool ---
	GetTextureBlendMode              :: proc(texture: ^Texture, blendMode: ^BlendMode) -> bool ---
	SetTextureScaleMode              :: proc(texture: ^Texture, scaleMode: ScaleMode) -> bool ---
	GetTextureScaleMode              :: proc(texture: ^Texture, scaleMode: ^ScaleMode) -> bool ---
	UpdateTexture                    :: proc(texture: ^Texture, rect: Maybe(^Rect), pixels: rawptr, pitch: c.int) -> bool ---
	UpdateYUVTexture                 :: proc(texture: ^Texture, rect: Maybe(^Rect), Yplane: [^]Uint8, Ypitch: c.int, Uplane: [^]Uint8, Upitch: c.int, Vplane: [^]Uint8, Vpitch: c.int) -> bool ---
	UpdateNVTexture                  :: proc(texture: ^Texture, rect: Maybe(^Rect), Yplane: [^]Uint8, Ypitch: c.int, UVplane: [^]Uint8, UVpitch: c.int) -> bool ---
	LockTexture                      :: proc(texture: ^Texture, rect: Maybe(^Rect), pixels: ^rawptr, pitch: ^c.int) -> bool ---
	LockTextureToSurface             :: proc(texture: ^Texture, rect: Maybe(^Rect), surface: ^^Surface) -> bool ---
	UnlockTexture                    :: proc(texture: ^Texture) ---
	SetRenderTarget                  :: proc(renderer: ^Renderer, texture: Maybe(^Texture)) -> bool ---
	SetRenderLogicalPresentation     :: proc(renderer: ^Renderer, w, h: c.int, mode: RendererLogicalPresentation) -> bool ---
	GetRenderLogicalPresentation     :: proc(renderer: ^Renderer, w, h: ^c.int, mode: ^RendererLogicalPresentation) -> bool ---
	GetRenderLogicalPresentationRect :: proc(renderer: ^Renderer, rect: ^FRect) -> bool ---
	RenderCoordinatesFromWindow      :: proc(renderer: ^Renderer, window_x, window_y: f32, x, y: ^f32) -> bool ---
	RenderCoordinatesToWindow        :: proc(renderer: ^Renderer, x, y: f32, window_x, window_y: ^f32) -> bool ---
	ConvertEventToRenderCoordinates  :: proc(renderer: ^Renderer, event: ^Event) -> bool ---
	SetRenderViewport                :: proc(renderer: ^Renderer, #by_ptr rect: Rect) -> bool ---
	GetRenderViewport                :: proc(renderer: ^Renderer, rect: ^Rect) -> bool ---
	GetRenderSafeArea                :: proc(renderer: ^Renderer, rect: ^Rect) -> bool ---
	SetRenderClipRect                :: proc(renderer: ^Renderer, #by_ptr rect: Rect) -> bool ---
	GetRenderClipRect                :: proc(renderer: ^Renderer, rect: ^Rect) -> bool ---
	SetRenderScale                   :: proc(renderer: ^Renderer, scaleX, scaleY: f32) -> bool ---
	GetRenderScale                   :: proc(renderer: ^Renderer, scaleX, scaleY: ^f32) -> bool ---
	SetRenderDrawColor               :: proc(renderer: ^Renderer, r, g, b, a: Uint8) -> bool ---
	SetRenderDrawColorFloat          :: proc(renderer: ^Renderer, r, g, b, a: f32) -> bool ---
	GetRenderDrawColor               :: proc(renderer: ^Renderer, r, g, b, a: ^Uint8) -> bool ---
	GetRenderDrawColorFloat          :: proc(renderer: ^Renderer, r, g, b, a: ^f32) -> bool ---
	SetRenderColorScale              :: proc(renderer: ^Renderer, scale: f32) -> bool ---
	GetRenderColorScale              :: proc(renderer: ^Renderer, scale: ^f32) -> bool ---
	SetRenderDrawBlendMode           :: proc(renderer: ^Renderer, blendMode: BlendMode) -> bool ---
	GetRenderDrawBlendMode           :: proc(renderer: ^Renderer, blendMode: ^BlendMode) -> bool ---
	RenderClear                      :: proc(renderer: ^Renderer) -> bool ---
	RenderPoint                      :: proc(renderer: ^Renderer, x, y: f32) -> bool ---
	RenderPoints                     :: proc(renderer: ^Renderer, points: [^]FPoint, count: c.int) -> bool ---
	RenderLine                       :: proc(renderer: ^Renderer, x1, y1, x2, y2: f32) -> bool ---
	RenderLines                      :: proc(renderer: ^Renderer, points: [^]FPoint, count: c.int) -> bool ---
	RenderRect                       :: proc(renderer: ^Renderer, #by_ptr rect: FRect) -> bool ---
	RenderRects                      :: proc(renderer: ^Renderer, rects: [^]FRect, count: c.int) -> bool ---
	RenderFillRect                   :: proc(renderer: ^Renderer, #by_ptr rect: FRect) -> bool ---
	RenderFillRects                  :: proc(renderer: ^Renderer, rects: [^]FRect, count: c.int) -> bool ---
	RenderTexture                    :: proc(renderer: ^Renderer, texture: ^Texture, srcrect, dstrect: Maybe(^FRect)) -> bool ---
	RenderTextureRotated             :: proc(renderer: ^Renderer, texture: ^Texture, srcrect, dstrect: Maybe(^FRect), angle: f64, #by_ptr center: FPoint, flip: FlipMode) -> bool ---
	RenderTextureAffine              :: proc(renderer: ^Renderer, texture: ^Texture, srcrect: Maybe(^FRect), origin, right, down: Maybe(^FPoint)) -> bool ---
	RenderTextureTiled               :: proc(renderer: ^Renderer, texture: ^Texture, srcrect: Maybe(^FRect), scale: f32, dstrect: Maybe(^FRect)) -> bool ---
	RenderTexture9Grid               :: proc(renderer: ^Renderer, texture: ^Texture, srcrect: Maybe(^FRect), left_width, right_width, top_height, bottom_height: f32, scale: f32, dstrect: Maybe(^FRect)) -> bool ---
	RenderGeometry                   :: proc(renderer: ^Renderer, texture: ^Texture, vertices: [^]Vertex, num_vertices: c.int, indices: [^]c.int, num_indices: c.int) -> bool ---
	RenderGeometryRaw                :: proc(renderer: ^Renderer, texture: ^Texture, xy: [^]f32, xy_stride: c.int, color: [^]FColor, color_stride: c.int, uv: [^]f32, uv_stride: c.int, num_vertices: c.int, indices: rawptr, num_indices: c.int, size_indices: c.int) -> bool ---
	RenderPresent                    :: proc(renderer: ^Renderer) -> bool ---
	DestroyTexture                   :: proc(texture: ^Texture) ---
	DestroyRenderer                  :: proc(renderer: ^Renderer) ---
	FlushRenderer                    :: proc(renderer: ^Renderer) -> bool ---
	AddVulkanRenderSemaphores        :: proc(renderer: ^Renderer, wait_stage_mask: Uint32, wait_semaphore, signal_semaphore: Sint64) -> bool ---
	SetRenderVSync                   :: proc(renderer: ^Renderer, vsync: c.int) -> bool ---
	GetRenderVSync                   :: proc(renderer: ^Renderer, vsync: ^c.int) -> bool ---
	RenderDebugText                  :: proc(renderer: ^Renderer, x, y: f32, str: cstring) -> bool ---
	RenderDebugTextFormat            :: proc(renderer: ^Renderer, x, y: f32, fmt: cstring, #c_vararg args: ..any) -> bool ---
}