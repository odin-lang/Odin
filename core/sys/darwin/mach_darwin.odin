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

mach_port_t :: distinct c.uint
vm_map_t :: distinct mach_port_t
mem_entry_name_port_t :: distinct mach_port_t

vm_size_t :: distinct c.uintptr_t

vm_address_t :: distinct vm_offset_t
vm_offset_t :: distinct c.uintptr_t

boolean_t :: distinct c.int

vm_prot_t :: distinct c.int

vm_inherit_t :: distinct c.uint

@(default_calling_convention="c")
foreign mach {
	mach_task_self :: proc() -> task_t ---

	semaphore_create :: proc(task: task_t, semaphore: ^semaphore_t, policy, value: c.int) -> kern_return_t ---
	semaphore_destroy :: proc(task: task_t, semaphore: semaphore_t) -> kern_return_t ---

	semaphore_signal :: proc(semaphore: semaphore_t) -> kern_return_t ---
	semaphore_signal_all :: proc(semaphore: semaphore_t) -> kern_return_t ---
	semaphore_signal_thread :: proc(semaphore: semaphore_t, thread: thread_act_t) -> kern_return_t ---
	
	semaphore_wait :: proc(semaphore: semaphore_t) -> kern_return_t ---

	vm_allocate :: proc (target_task : vm_map_t, address: ^vm_address_t, size: vm_size_t, flags: vm_flags_t,) -> kern_return_t ---

	vm_deallocate :: proc(target_task: vm_map_t, address: vm_address_t, size: vm_size_t) -> kern_return_t---

	vm_map :: proc (
		target_task    : vm_map_t,
		address        : ^vm_address_t,
		size           : vm_size_t,
		mask           : vm_address_t,
		flags          : vm_flags_t,
		object         : mem_entry_name_port_t,
		offset         : vm_offset_t,
		copy           : boolean_t,
		cur_protection : vm_prot_t,
		max_protection : vm_prot_t,
		inheritance    : vm_inherit_t
	) -> kern_return_t ---

	mach_make_memory_entry :: proc (
		target_task   : vm_map_t,
		size          : ^vm_size_t,
		offset        : vm_offset_t,
		permission    : vm_prot_t,
		object_handle : ^mem_entry_name_port_t,
		parent_entry  : mem_entry_name_port_t,
	) -> kern_return_t ---

	vm_page_size : vm_size_t
}

KERN_SUCCESS                  : kern_return_t : 0

KERN_INVALID_ADDRESS          : kern_return_t : 1
/* Specified address is not currently valid.
 */

KERN_PROTECTION_FAILURE       : kern_return_t : 2
/* Specified memory is valid, but does not permit the
 * required forms of access.
 */

KERN_NO_SPACE                 : kern_return_t : 3
/* The address range specified is already in use, or
 * no address range of the size specified could be
 * found.
 */

KERN_INVALID_ARGUMENT         : kern_return_t : 4
/* The function requested was not applicable to this
 * type of argument, or an argument is invalid
 */

KERN_FAILURE                  : kern_return_t : 5
/* The function could not be performed.  A catch-all.
 */

KERN_RESOURCE_SHORTAGE        : kern_return_t : 6
/* A system resource could not be allocated to fulfill
 * this request.  This failure may not be permanent.
 */

KERN_NOT_RECEIVER             : kern_return_t : 7
/* The task in question does not hold receive rights
 * for the port argument.
 */

KERN_NO_ACCESS                : kern_return_t : 8
/* Bogus access restriction.
 */

KERN_MEMORY_FAILURE           : kern_return_t : 9
/* During a page fault, the target address refers to a
 * memory object that has been destroyed.  This
 * failure is permanent.
 */

KERN_MEMORY_ERROR             : kern_return_t : 10
/* During a page fault, the memory object indicated
 * that the data could not be returned.  This failure
 * may be temporary; future attempts to access this
 * same data may succeed, as defined by the memory
 * object.
 */

KERN_ALREADY_IN_SET           : kern_return_t : 11
/* The receive right is already a member of the portset.
 */

KERN_NOT_IN_SET               : kern_return_t : 12
/* The receive right is not a member of a port set.
 */

KERN_NAME_EXISTS              : kern_return_t : 13
/* The name already denotes a right in the task.
 */

KERN_ABORTED                  : kern_return_t : 14
/* The operation was aborted.  Ipc code will
 * catch this and reflect it as a message error.
 */

KERN_INVALID_NAME             : kern_return_t : 15
/* The name doesn't denote a right in the task.
 */

KERN_INVALID_TASK             : kern_return_t : 16
/* Target task isn't an active task.
 */

KERN_INVALID_RIGHT            : kern_return_t : 17
/* The name denotes a right, but not an appropriate right.
 */

KERN_INVALID_VALUE            : kern_return_t : 18
/* A blatant range error.
 */

KERN_UREFS_OVERFLOW           : kern_return_t : 19
/* Operation would overflow limit on user-references.
 */

KERN_INVALID_CAPABILITY       : kern_return_t : 20
/* The supplied (port) capability is improper.
 */

KERN_RIGHT_EXISTS             : kern_return_t : 21
/* The task already has send or receive rights
 * for the port under another name.
 */

KERN_INVALID_HOST             : kern_return_t : 22
/* Target host isn't actually a host.
 */

KERN_MEMORY_PRESENT           : kern_return_t : 23
/* An attempt was made to supply "precious" data
 * for memory that is already present in a
 * memory object.
 */

KERN_MEMORY_DATA_MOVED        : kern_return_t : 24
/* A page was requested of a memory manager via
 * memory_object_data_request for an object using
 * a MEMORY_OBJECT_COPY_CALL strategy, with the
 * VM_PROT_WANTS_COPY flag being used to specify
 * that the page desired is for a copy of the
 * object, and the memory manager has detected
 * the page was pushed into a copy of the object
 * while the kernel was walking the shadow chain
 * from the copy to the object. This error code
 * is delivered via memory_object_data_error
 * and is handled by the kernel (it forces the
 * kernel to restart the fault). It will not be
 * seen by users.
 */

KERN_MEMORY_RESTART_COPY      : kern_return_t : 25
/* A strategic copy was attempted of an object
 * upon which a quicker copy is now possible.
 * The caller should retry the copy using
 * vm_object_copy_quickly. This error code
 * is seen only by the kernel.
 */

KERN_INVALID_PROCESSOR_SET    : kern_return_t : 26
/* An argument applied to assert processor set privilege
 * was not a processor set control port.
 */

KERN_POLICY_LIMIT             : kern_return_t : 27
/* The specified scheduling attributes exceed the thread's
 * limits.
 */

KERN_INVALID_POLICY           : kern_return_t : 28
/* The specified scheduling policy is not currently
 * enabled for the processor set.
 */

KERN_INVALID_OBJECT           : kern_return_t : 29
/* The external memory manager failed to initialize the
 * memory object.
 */

KERN_ALREADY_WAITING          : kern_return_t : 30
/* A thread is attempting to wait for an event for which
 * there is already a waiting thread.
 */

KERN_DEFAULT_SET              : kern_return_t : 31
/* An attempt was made to destroy the default processor
 * set.
 */

KERN_EXCEPTION_PROTECTED      : kern_return_t : 32
/* An attempt was made to fetch an exception port that is
 * protected, or to abort a thread while processing a
 * protected exception.
 */

KERN_INVALID_LEDGER           : kern_return_t : 33
/* A ledger was required but not supplied.
 */

KERN_INVALID_MEMORY_CONTROL   : kern_return_t : 34
/* The port was not a memory cache control port.
 */

KERN_INVALID_SECURITY         : kern_return_t : 35
/* An argument supplied to assert security privilege
 * was not a host security port.
 */

KERN_NOT_DEPRESSED            : kern_return_t : 36
/* thread_depress_abort was called on a thread which
 * was not currently depressed.
 */

KERN_TERMINATED               : kern_return_t : 37
/* Object has been terminated and is no longer available
 */

KERN_LOCK_SET_DESTROYED       : kern_return_t : 38
/* Lock set has been destroyed and is no longer available.
 */

KERN_LOCK_UNSTABLE            : kern_return_t : 39
/* The thread holding the lock terminated before releasing
 * the lock
 */

KERN_LOCK_OWNED               : kern_return_t : 40
/* The lock is already owned by another thread
 */

KERN_LOCK_OWNED_SELF          : kern_return_t : 41
/* The lock is already owned by the calling thread
 */

KERN_SEMAPHORE_DESTROYED      : kern_return_t : 42
/* Semaphore has been destroyed and is no longer available.
 */

KERN_RPC_SERVER_TERMINATED    : kern_return_t : 43
/* Return from RPC indicating the target server was
 * terminated before it successfully replied
 */

KERN_RPC_TERMINATE_ORPHAN     : kern_return_t : 44
/* Terminate an orphaned activation.
 */

KERN_RPC_CONTINUE_ORPHAN      : kern_return_t : 45
/* Allow an orphaned activation to continue executing.
 */

KERN_NOT_SUPPORTED            : kern_return_t : 46
/* Empty thread activation (No thread linked to it)
 */

KERN_NODE_DOWN                : kern_return_t : 47
/* Remote node down or inaccessible.
 */

KERN_NOT_WAITING              : kern_return_t : 48
/* A signalled thread was not actually waiting. */

KERN_OPERATION_TIMED_OUT      : kern_return_t : 49
/* Some thread-oriented operation (semaphore_wait) timed out
 */

KERN_CODESIGN_ERROR           : kern_return_t : 50
/* During a page fault, indicates that the page was rejected
 * as a result of a signature check.
 */

KERN_POLICY_STATIC            : kern_return_t : 51
/* The requested property cannot be changed at this time.
 */

KERN_INSUFFICIENT_BUFFER_SIZE : kern_return_t : 52
/* The provided buffer is of insufficient size for the requested data.
 */

KERN_DENIED                   : kern_return_t : 53
/* Denied by security policy
 */

KERN_MISSING_KC               : kern_return_t : 54
/* The KC on which the function is operating is missing
 */

KERN_INVALID_KC               : kern_return_t : 55
/* The KC on which the function is operating is invalid
 */

KERN_NOT_FOUND                : kern_return_t : 56
/* A search or query operation did not return a result
 */

KERN_RETURN_MAX               : kern_return_t : 0x100

/* Maximum return value allowable
 */
/*
 * VM allocation flags:
 *
 * VM_FLAGS_FIXED
 *      (really the absence of VM_FLAGS_ANYWHERE)
 *	Allocate new VM region at the specified virtual address, if possible.
 *
 * VM_FLAGS_ANYWHERE
 *	Allocate new VM region anywhere it would fit in the address space.
 *
 * VM_FLAGS_PURGABLE
 *	Create a purgable VM object for that new VM region.
 *
 * VM_FLAGS_4GB_CHUNK
 *	The new VM region will be chunked up into 4GB sized pieces.
 *
 * VM_FLAGS_NO_PMAP_CHECK
 *	(for DEBUG kernel config only, ignored for other configs)
 *	Do not check that there is no stale pmap mapping for the new VM region.
 *	This is useful for kernel memory allocations at bootstrap when building
 *	the initial kernel address space while some memory is already in use.
 *
 * VM_FLAGS_OVERWRITE
 *	The new VM region can replace existing VM regions if necessary
 *	(to be used in combination with VM_FLAGS_FIXED).
 *
 * VM_FLAGS_NO_CACHE
 *	Pages brought in to this VM region are placed on the speculative
 *	queue instead of the active queue.  In other words, they are not
 *	cached so that they will be stolen first if memory runs low.
 */

vm_flags_t :: distinct c.int // NOTE(beau): not in the apple sdk

VM_FLAGS_FIXED              : vm_flags_t : 0x00000000
VM_FLAGS_ANYWHERE           : vm_flags_t : 0x00000001
VM_FLAGS_PURGABLE           : vm_flags_t : 0x00000002
VM_FLAGS_4GB_CHUNK          : vm_flags_t : 0x00000004
VM_FLAGS_RANDOM_ADDR        : vm_flags_t : 0x00000008
VM_FLAGS_NO_CACHE           : vm_flags_t : 0x00000010
VM_FLAGS_RESILIENT_CODESIGN : vm_flags_t : 0x00000020
VM_FLAGS_RESILIENT_MEDIA    : vm_flags_t : 0x00000040
VM_FLAGS_PERMANENT          : vm_flags_t : 0x00000080
VM_FLAGS_TPRO               : vm_flags_t : 0x00001000
VM_FLAGS_OVERWRITE          : vm_flags_t : 0x00004000  /* delete any existing mappings first */

/*
 *	Protection values, defined as bits within the vm_prot_t type
 */

VM_PROT_NONE    : vm_prot_t : 0x00

VM_PROT_READ    : vm_prot_t : 0x01      /* read permission */
VM_PROT_WRITE   : vm_prot_t : 0x02      /* write permission */
VM_PROT_EXECUTE : vm_prot_t : 0x04      /* execute permission */

/*
 *	The default protection for newly-created virtual memory
 */

VM_PROT_DEFAULT :: VM_PROT_READ | VM_PROT_WRITE

/*
 *	The maximum privileges possible, for parameter checking.
 */

VM_PROT_ALL     :: VM_PROT_READ | VM_PROT_WRITE | VM_PROT_EXECUTE

/*
 *	Enumeration of valid values for vm_inherit_t.
 */

VM_INHERIT_SHARE       : vm_inherit_t : 0      /* share with child */
VM_INHERIT_COPY        : vm_inherit_t : 1      /* copy into child */
VM_INHERIT_NONE        : vm_inherit_t : 2      /* absent from child */
VM_INHERIT_DONATE_COPY : vm_inherit_t : 3      /* copy and delete */
