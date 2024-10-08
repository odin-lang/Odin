package darwin

foreign import mach "system:System.framework"

import "core:c"

kern_return_t :: distinct c.int

mach_port_t :: distinct c.uint
vm_map_t :: mach_port_t
mem_entry_name_port_t :: mach_port_t
ipc_space_t :: mach_port_t
thread_t :: mach_port_t
task_t :: mach_port_t
semaphore_t :: mach_port_t

vm_size_t :: distinct c.uintptr_t

vm_address_t :: vm_offset_t
vm_offset_t :: distinct c.uintptr_t

boolean_t :: distinct c.int

vm_prot_t :: distinct c.int

vm_inherit_t :: distinct c.uint

mach_port_name_t :: distinct c.uint

@(default_calling_convention="c")
foreign mach {
	mach_task_self :: proc() -> mach_port_t ---

	semaphore_create :: proc(task: task_t, semaphore: ^semaphore_t, policy, value: c.int) -> Kern_Return ---
	semaphore_destroy :: proc(task: task_t, semaphore: semaphore_t) -> Kern_Return ---

	semaphore_signal :: proc(semaphore: semaphore_t) -> Kern_Return ---
	semaphore_signal_all :: proc(semaphore: semaphore_t) -> Kern_Return ---
	semaphore_signal_thread :: proc(semaphore: semaphore_t, thread: thread_t) -> Kern_Return ---
	
	semaphore_wait :: proc(semaphore: semaphore_t) -> Kern_Return ---

	vm_allocate :: proc (target_task : vm_map_t, address: ^vm_address_t, size: vm_size_t, flags: c.int,) -> Kern_Return ---

	vm_deallocate :: proc(target_task: vm_map_t, address: vm_address_t, size: vm_size_t) -> Kern_Return ---

	vm_map :: proc (
		target_task    : vm_map_t,
		address        : ^vm_address_t,
		size           : vm_size_t,
		mask           : vm_address_t,
		flags          : c.int,
		object         : mem_entry_name_port_t,
		offset         : vm_offset_t,
		copy           : boolean_t,
		cur_protection,
		max_protection : vm_prot_t,
		inheritance    : vm_inherit_t,
	) -> Kern_Return ---

	mach_make_memory_entry :: proc (
		target_task   : vm_map_t,
		size          : ^vm_size_t,
		offset        : vm_offset_t,
		permission    : vm_prot_t,
		object_handle : ^mem_entry_name_port_t,
		parent_entry  : mem_entry_name_port_t,
	) -> Kern_Return ---

	mach_port_deallocate :: proc (
		task: ipc_space_t,
		name: mach_port_name_t,
	) -> Kern_Return ---

	vm_page_size : vm_size_t
}

Kern_Return :: enum kern_return_t {
	Success,

	Invalid_Address,
	/* Specified address is not currently valid.
	 */

	Protection_Failure,
	/* Specified memory is valid, but does not permit the
	 * required forms of access.
	 */

	No_Space,
	/* The address range specified is already in use, or
	 * no address range of the size specified could be
	 * found.
	 */

	Invalid_Argument,
	/* The function requested was not applicable to this
	 * type of argument, or an argument is invalid
	 */

	Failure,
	/* The function could not be performed.  A catch-all.
	 */

	Resource_Shortage,
	/* A system resource could not be allocated to fulfill
	 * this request.  This failure may not be permanent.
	 */

	Not_Receiver,
	/* The task in question does not hold receive rights
	 * for the port argument.
	 */

	No_Access,
	/* Bogus access restriction.
	 */

	Memory_Failure,
	/* During a page fault, the target address refers to a
	 * memory object that has been destroyed.  This
	 * failure is permanent.
	 */

	Memory_Error,
	/* During a page fault, the memory object indicated
	 * that the data could not be returned.  This failure
	 * may be temporary; future attempts to access this
	 * same data may succeed, as defined by the memory
	 * object.
	 */

	Already_In_Set,
	/* The receive right is already a member of the portset.
	 */

	Not_In_Set,
	/* The receive right is not a member of a port set.
	 */

	Name_Exists,
	/* The name already denotes a right in the task.
	 */

	Aborted,
	/* The operation was aborted.  Ipc code will
	 * catch this and reflect it as a message error.
	 */

	Invalid_Name,
	/* The name doesn't denote a right in the task.
	 */

	Invalid_Task,
	/* Target task isn't an active task.
	 */

	Invalid_Right,
	/* The name denotes a right, but not an appropriate right.
	 */

	Invalid_Value,
	/* A blatant range error.
	 */

	URefs_Overflow,
	/* Operation would overflow limit on user-references.
	 */

	Invalid_Capability,
	/* The supplied (port) capability is improper.
	 */

	Right_Exists,
	/* The task already has send or receive rights
	 * for the port under another name.
	 */

	Invalid_Host,
	/* Target host isn't actually a host.
	 */

	Memory_Present,
	/* An attempt was made to supply "precious" data
	 * for memory that is already present in a
	 * memory object.
	 */

	Memory_Data_Moved,
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

	Memory_Restart_Copy,
	/* A strategic copy was attempted of an object
	 * upon which a quicker copy is now possible.
	 * The caller should retry the copy using
	 * vm_object_copy_quickly. This error code
	 * is seen only by the kernel.
	 */

	Invalid_Processor_Set,
	/* An argument applied to assert processor set privilege
	 * was not a processor set control port.
	 */

	Policy_Limit,
	/* The specified scheduling attributes exceed the thread's
	 * limits.
	 */

	Invalid_Policy,
	/* The specified scheduling policy is not currently
	 * enabled for the processor set.
	 */

	Invalid_Object,
	/* The external memory manager failed to initialize the
	 * memory object.
	 */

	Already_Waiting,
	/* A thread is attempting to wait for an event for which
	 * there is already a waiting thread.
	 */

	Default_Set,
	/* An attempt was made to destroy the default processor
	 * set.
	 */

	Exception_Protected,
	/* An attempt was made to fetch an exception port that is
	 * protected, or to abort a thread while processing a
	 * protected exception.
	 */

	Invalid_Ledger,
	/* A ledger was required but not supplied.
	 */

	Invalid_Memory_Control,
	/* The port was not a memory cache control port.
	 */

	Invalid_Security,
	/* An argument supplied to assert security privilege
	 * was not a host security port.
	 */

	Not_Depressed,
	/* thread_depress_abort was called on a thread which
	 * was not currently depressed.
	 */

	Terminated,
	/* Object has been terminated and is no longer available
	 */

	Lock_Set_Destroyed,
	/* Lock set has been destroyed and is no longer available.
	 */

	Lock_Unstable,
	/* The thread holding the lock terminated before releasing
	 * the lock
	 */

	Lock_Owned,
	/* The lock is already owned by another thread
	 */

	Lock_Owned_Self,
	/* The lock is already owned by the calling thread
	 */

	Semaphore_Destroyed,
	/* Semaphore has been destroyed and is no longer available.
	 */

	Rpc_Server_Terminated,
	/* Return from RPC indicating the target server was
	 * terminated before it successfully replied
	 */

	RPC_Terminate_Orphan,
	/* Terminate an orphaned activation.
	 */

	RPC_Continue_Orphan,
	/* Allow an orphaned activation to continue executing.
	 */

	Not_Supported,
	/* Empty thread activation (No thread linked to it)
	 */

	Node_Down,
	/* Remote node down or inaccessible.
	 */

	Not_Waiting,
	/* A signalled thread was not actually waiting. */

	Operation_Timed_Out,
	/* Some thread-oriented operation (semaphore_wait) timed out
	 */

	Codesign_Error,
	/* During a page fault, indicates that the page was rejected
	 * as a result of a signature check.
	 */

	Policy_Static,
	/* The requested property cannot be changed at this time.
	 */

	Insufficient_Buffer_Size,
	/* The provided buffer is of insufficient size for the requested data.
	 */

	Denied,
	/* Denied by security policy
	 */

	Missing_KC,
	/* The KC on which the function is operating is missing
	 */

	Invalid_KC,
	/* The KC on which the function is operating is invalid
	 */

	Not_Found,
	/* A search or query operation did not return a result
	 */

	Return_Max               = 0x100,
}

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

VM_FLAGS_FIXED              :: 0x00000000
VM_FLAGS_ANYWHERE           :: 0x00000001
VM_FLAGS_PURGABLE           :: 0x00000002
VM_FLAGS_4GB_CHUNK          :: 0x00000004
VM_FLAGS_RANDOM_ADDR        :: 0x00000008
VM_FLAGS_NO_CACHE           :: 0x00000010
VM_FLAGS_RESILIENT_CODESIGN :: 0x00000020
VM_FLAGS_RESILIENT_MEDIA    :: 0x00000040
VM_FLAGS_PERMANENT          :: 0x00000080
VM_FLAGS_TPRO               :: 0x00001000
VM_FLAGS_OVERWRITE          :: 0x00004000  /* delete any existing mappings first */

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
