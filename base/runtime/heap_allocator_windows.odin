package runtime

foreign import kernel32 "system:Kernel32.lib"

@(private="file")
@(default_calling_convention="system")
foreign kernel32 {
        // NOTE(bill): The types are not using the standard names (e.g. DWORD and LPVOID) to just minimizing the dependency

        // default_allocator
        GetProcessHeap :: proc() -> rawptr ---
        HeapAlloc      :: proc(hHeap: rawptr, dwFlags: u32, dwBytes: uint) -> rawptr ---
        HeapReAlloc    :: proc(hHeap: rawptr, dwFlags: u32, lpMem: rawptr, dwBytes: uint) -> rawptr ---
        HeapFree       :: proc(hHeap: rawptr, dwFlags: u32, lpMem: rawptr) -> b32 ---
}

heap_alloc :: proc "contextless" (size: int, zero_memory := true) -> rawptr {
        HEAP_ZERO_MEMORY :: 0x00000008
        return HeapAlloc(GetProcessHeap(), HEAP_ZERO_MEMORY if zero_memory else 0, uint(size))
}
heap_resize :: proc "contextless" (ptr: rawptr, new_size: int) -> rawptr {
        if new_size == 0 {
                heap_free(ptr)
                return nil
        }
        if ptr == nil {
                return heap_alloc(new_size)
        }

        HEAP_ZERO_MEMORY :: 0x00000008
        return HeapReAlloc(GetProcessHeap(), HEAP_ZERO_MEMORY, ptr, uint(new_size))
}
heap_free :: proc "contextless" (ptr: rawptr) {
        if ptr == nil {
                return
        }
        HeapFree(GetProcessHeap(), 0, ptr)
}
