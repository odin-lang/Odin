package sdl3

import vk "vendor:vulkan"

@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	Vulkan_LoadLibrary              :: proc(path: cstring) -> bool ---
	Vulkan_GetVkGetInstanceProcAddr :: proc() -> FunctionPointer ---
	Vulkan_UnloadLibrary            :: proc() ---
	Vulkan_GetInstanceExtensions    :: proc(count: ^Uint32) -> [^]cstring ---
	Vulkan_CreateSurface            :: proc(window: ^Window, instance: vk.Instance, allocator: Maybe(^vk.AllocationCallbacks), surface: ^vk.SurfaceKHR) -> bool ---
	Vulkan_DestroySurface           :: proc(instance: vk.Instance, surface: vk.SurfaceKHR, allocator: Maybe(^vk.AllocationCallbacks)) ---
	Vulkan_GetPresentationSupport   :: proc(instance: vk.Instance, physicalDevice: vk.PhysicalDevice, queueFamilyIndex: Uint32) -> bool ---

}