package sdl2

import "core:c"

when ODIN_OS == "windows" do foreign import lib "SDL2.lib"
when ODIN_OS == "linux"   do foreign import lib "system:SDL2"
when ODIN_OS == "darwin"  do foreign import lib "system:SDL2"
when ODIN_OS == "freebsd" do foreign import lib "system:SDL2"

VkInstance   :: distinct u64;
VkSurfaceKHR :: distinct u64;

vulkanInstance :: VkInstance;
vulkanSurface  :: VkSurfaceKHR;

@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	Vulkan_LoadLibrary              :: proc(path: cstring) -> c.int ---
	Vulkan_GetVkGetInstanceProcAddr :: proc() -> rawptr ---
	Vulkan_UnloadLibrary            :: proc() ---
	Vulkan_GetInstanceExtensions    :: proc(window: ^Window, pCount: ^c.uint, pNames: ^cstring) -> bool ---
	Vulkan_CreateSurface            :: proc(window: ^Window, instance: VkInstance, surface: ^VkSurfaceKHR) -> bool ---
	Vulkan_GetDrawableSize          :: proc(window: ^Window, w, h: ^c.int) ---
}