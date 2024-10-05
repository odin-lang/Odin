package darwin

foreign import mach "system:System.framework"

import "core:c"

// NOTE(tetra): Unclear whether these should be aligned 16 or not.
// However all other sync primitives are aligned for robustness.
// I cannot currently align these though.
// See core/sys/unix/pthread_linux.odin/pthread_t.
task_t :: distinct u64
semaphore_t :: distinct u64

kern_return_t :: distinct u64
thread_act_t :: distinct u64

@(default_calling_convention="c")
foreign mach {
	mach_task_self :: proc() -> task_t ---

	semaphore_create :: proc(task: task_t, semaphore: ^semaphore_t, policy, value: c.int) -> kern_return_t ---
	semaphore_destroy :: proc(task: task_t, semaphore: semaphore_t) -> kern_return_t ---

	semaphore_signal :: proc(semaphore: semaphore_t) -> kern_return_t ---
	semaphore_signal_all :: proc(semaphore: semaphore_t) -> kern_return_t ---
	semaphore_signal_thread :: proc(semaphore: semaphore_t, thread: thread_act_t) -> kern_return_t ---
	
	semaphore_wait :: proc(semaphore: semaphore_t) -> kern_return_t ---
}

// NOTE(beau): types for stuff in the mach APIS, recreated from the typedefs as
// faithfully as possible
mach_port_t            :: c.uint
vm_map_t               :: mach_port_t
mem_entry_name_port_t  :: mach_port_t

vm_size_t              :: c.uintptr_t

vm_address_t           :: vm_offset_t
vm_offset_t            :: c.uintptr_t

boolean_t              :: c.int

