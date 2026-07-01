#+private
package runtime

import "base:intrinsics"

VIRTUAL_MEMORY_SUPPORTED :: true

foreign import lib "system:System.framework"

foreign lib {
	vm_page_size: uintptr
	mach_task_self_: u32
	mach_vm_allocate :: proc(target: u32, address: ^u64, size: u64, flags: i32) -> i32 ---
	mach_vm_deallocate :: proc(target: u32, address: u64, size: u64) -> i32 ---
	mach_vm_protect :: proc(target_task: u32, address: u64, size: u64, set_maximum: b32, new_protection: i32) -> i32 ---
	mach_vm_map :: proc(
		target_task:    u32,
		address:        ^u64,
		size:           u64,
		mask:           u64,
		flags:          i32,
		object:         i32,
		offset:         uintptr,
		copy:           b32,
		cur_protection,
		max_protection: i32,
		inheritance:    u32,
	) -> i32 ---
	mach_vm_remap :: proc(
		target_task:    u32,
		target_address: ^u64,
		size:           u64,
		mask:           u64,
		flags:          i32,
		src_task:       u32,
		src_address:    u64,
		copy:           b32,
		cur_protection,
		max_protection: ^i32,
		inheritance:    u32,
	) -> i32 ---
}

// The following features are specific to Darwin only.
VM_FLAGS_ANYWHERE :: 0x0001

SUPERPAGE_SIZE_ANY :: 1
SUPERPAGE_SIZE_2MB :: 2

VM_FLAGS_SUPERPAGE_SHIFT    :: 16
VM_FLAGS_SUPERPAGE_SIZE_ANY :: SUPERPAGE_SIZE_ANY << VM_FLAGS_SUPERPAGE_SHIFT
VM_FLAGS_SUPERPAGE_SIZE_2MB :: SUPERPAGE_SIZE_2MB << VM_FLAGS_SUPERPAGE_SHIFT

MEMORY_OBJECT_NULL :: 0
VM_PROT_READ  :: 0x01
VM_PROT_WRITE :: 0x02
VM_INHERIT_COPY :: 1

_init_virtual_memory :: proc "contextless" () {
	page_size = _get_page_size()
	superpage_size = _get_superpage_size()
}

_get_page_size :: proc "contextless" () -> int {
	return int(vm_page_size)
}

_get_superpage_size :: proc "contextless" () -> int {
	when ODIN_ARCH == .amd64 {
		// NOTE(Feoramund): As far as we are aware, Darwin only supports
		// explicit superpage allocation on AMD64 with a 2MiB parameter.
		return 2 * Megabyte
	} else {
		return 0
	}
}

_allocate_virtual_memory :: proc "contextless" (size: int) -> rawptr {
	address: u64
	result := mach_vm_map(mach_task_self_, &address, u64(size), 0, VM_FLAGS_ANYWHERE, MEMORY_OBJECT_NULL, 0, false, VM_PROT_READ|VM_PROT_WRITE, VM_PROT_READ|VM_PROT_WRITE, VM_INHERIT_COPY)
	if result != 0 {
		return nil
	}
	return rawptr(uintptr(address))
}

_allocate_virtual_memory_superpage :: proc "contextless" () -> rawptr {
	address: u64
	flags: i32 = VM_FLAGS_ANYWHERE | VM_FLAGS_SUPERPAGE_SIZE_2MB
	assert_contextless(superpage_size & (superpage_size-1) == 0, "The superpage size is not a power of two.")
	alignment_mask: u64 = u64(superpage_size) - 1
	result := mach_vm_map(mach_task_self_, &address, 2 * Megabyte, alignment_mask, flags, MEMORY_OBJECT_NULL, 0, false, VM_PROT_READ|VM_PROT_WRITE, VM_PROT_READ|VM_PROT_WRITE, VM_INHERIT_COPY)
	if result != 0 {
		return nil
	}
	assert_contextless(address % u64(superpage_size) == 0)
	return rawptr(uintptr(address))
}

_allocate_virtual_memory_aligned :: proc "contextless" (size: int, alignment: int) -> rawptr {
	address: u64
	alignment_mask: u64 = u64(alignment) - 1
	result := mach_vm_map(mach_task_self_, &address, u64(size), alignment_mask, VM_FLAGS_ANYWHERE, MEMORY_OBJECT_NULL, 0, false, VM_PROT_READ|VM_PROT_WRITE, VM_PROT_READ|VM_PROT_WRITE, VM_INHERIT_COPY)
	if result != 0 {
		return nil
	}
	return rawptr(uintptr(address))
}

_free_virtual_memory :: proc "contextless" (ptr: rawptr, size: int) {
	mach_vm_deallocate(mach_task_self_, u64(uintptr(ptr)), u64(size))
}

_resize_virtual_memory :: proc "contextless" (ptr: rawptr, old_size: int, new_size: int, alignment: int) -> rawptr {
	result: rawptr = ---
	if alignment == 0 {
		result = _allocate_virtual_memory(new_size)
	} else {
		result = _allocate_virtual_memory_aligned(new_size, alignment)
	}
	intrinsics.mem_copy_non_overlapping(result, ptr, min(new_size, old_size))
	mach_vm_deallocate(mach_task_self_, u64(uintptr(ptr)), u64(old_size))
	return result
}
