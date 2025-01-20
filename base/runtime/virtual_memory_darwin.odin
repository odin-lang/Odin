#+private
package runtime

import "base:intrinsics"

VIRTUAL_MEMORY_SUPPORTED :: true

foreign import lib "system:System.framework"

foreign lib {
	mach_task_self :: proc() -> u32 ---
	mach_vm_deallocate :: proc(target: u32, address: u64, size: u64) -> i32 ---
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
VM_INHERIT_SHARE :: 0

_allocate_virtual_memory :: proc "contextless" (size: int) -> rawptr {
	address: u64
	result := mach_vm_map(mach_task_self(), &address, u64(size), 0, VM_FLAGS_ANYWHERE, MEMORY_OBJECT_NULL, 0, false, VM_PROT_READ|VM_PROT_WRITE, VM_PROT_READ|VM_PROT_WRITE, VM_INHERIT_SHARE)
	if result != 0 {
		return nil
	}
	return rawptr(uintptr(address))
}

_allocate_virtual_memory_superpage :: proc "contextless" () -> rawptr {
	address: u64
	flags: i32 = VM_FLAGS_ANYWHERE
	when SUPERPAGE_SIZE == 2 * Megabyte {
		flags |= VM_FLAGS_SUPERPAGE_SIZE_2MB
	} else {
		flags |= VM_FLAGS_SUPERPAGE_SIZE_ANY
	}
	alignment_mask: u64 = SUPERPAGE_SIZE - 1 // Assumes a power of two size, ensured by an assertion in `virtual_memory.odin`.
	result := mach_vm_map(mach_task_self(), &address, SUPERPAGE_SIZE, alignment_mask, flags, MEMORY_OBJECT_NULL, 0, false, VM_PROT_READ|VM_PROT_WRITE, VM_PROT_READ|VM_PROT_WRITE, VM_INHERIT_SHARE)
	if result != 0 {
		return nil
	}
	assert_contextless(address % SUPERPAGE_SIZE == 0)
	return rawptr(uintptr(address))
}

_allocate_virtual_memory_aligned :: proc "contextless" (size: int, alignment: int) -> rawptr {
	address: u64
	alignment_mask: u64 = u64(alignment) - 1
	result := mach_vm_map(mach_task_self(), &address, u64(size), alignment_mask, VM_FLAGS_ANYWHERE, MEMORY_OBJECT_NULL, 0, false, VM_PROT_READ|VM_PROT_WRITE, VM_PROT_READ|VM_PROT_WRITE, VM_INHERIT_SHARE)
	if result != 0 {
		return nil
	}
	return rawptr(uintptr(address))
}

_free_virtual_memory :: proc "contextless" (ptr: rawptr, size: int) {
	mach_vm_deallocate(mach_task_self(), u64(uintptr(ptr)), u64(size))
}

_resize_virtual_memory :: proc "contextless" (ptr: rawptr, old_size: int, new_size: int, alignment: int) -> rawptr {
	// NOTE(Feoramund): mach_vm_remap does not permit resizing, as far as I understand it.
	result: rawptr = ---
	if alignment == 0 {
		result = _allocate_virtual_memory(new_size)
	} else {
		result = _allocate_virtual_memory_aligned(new_size, alignment)
	}
	intrinsics.mem_copy_non_overlapping(result, ptr, min(new_size, old_size))
	mach_vm_deallocate(mach_task_self(), u64(uintptr(ptr)), u64(old_size))
	return result
}
