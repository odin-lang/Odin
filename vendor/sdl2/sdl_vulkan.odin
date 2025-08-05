package sdl2

import "core:c"
import vk "vendor:vulkan"

when ODIN_OS == .Windows {
	@(ignore_duplicates)
	foreign import lib "SDL2.lib"
} else {
	@(ignore_duplicates)
	foreign import lib "system:SDL2"
}

VkInstance   :: vk.Instance
VkSurfaceKHR :: vk.SurfaceKHR

vulkanInstance :: VkInstance
vulkanSurface  :: VkSurfaceKHR

@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	Vulkan_LoadLibrary              :: proc(path: cstring) -> c.int ---
	Vulkan_GetVkGetInstanceProcAddr :: proc() -> rawptr ---
	Vulkan_UnloadLibrary            :: proc() ---
	Vulkan_GetInstanceExtensions    :: proc(window: ^Window, pCount: ^c.uint, pNames: [^]cstring) -> bool ---
	Vulkan_CreateSurface            :: proc(window: ^Window, instance: VkInstance, surface: ^VkSurfaceKHR) -> bool ---
	Vulkan_GetDrawableSize          :: proc(window: ^Window, w, h: ^c.int) ---
}
