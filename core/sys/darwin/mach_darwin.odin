package darwin

foreign import mach "system:System.framework"

import "core:c"

// NOTE(tetra): Unclear whether these should be aligned 16 or not.
// However all other sync primitives are aligned for robustness.
// I cannot currently align these though.
// See core/sys/unix/pthread_linux.odin/pthread_t.
mach_port_t :: distinct i32
task_t :: mach_port_t

semaphore_t :: distinct u64

kern_return_t  :: distinct u64
thread_act_t   :: distinct u64
thread_state_t :: distinct ^u32
thread_list_t  :: [^]thread_act_t

MACH_PORT_NULL :: 0
MACH_PORT_DEAD :: ~mach_port_t(0)

MACH_MSG_PORT_DESCRIPTOR :: 0

MACH_SEND_MSG     :: 0x00000001
MACH_RCV_MSG      :: 0x00000002
MACH_SEND_TIMEOUT :: 0x00000010
MACH_RCV_TIMEOUT  :: 0x00000100

MACH_MSG_TYPE_COPY_SEND :: 19
MACH_MSG_TYPE_MAKE_SEND :: 20
MACH_MSGH_BITS_COMPLEX :: 0x80000000

MACH_PORT_RIGHT_SEND    :: 0
MACH_PORT_RIGHT_RECEIVE :: 1

VM_PROT_NONE    :: 0
VM_PROT_READ    :: 1
VM_PROT_WRITE   :: 2
VM_PROT_EXECUTE :: 4

VM_INHERIT_SHARE        :: 0
VM_INHERIT_COPY         :: 1
VM_INHERIT_NONE         :: 2
VM_INHERIT_DONATE_COPY  :: 3

TASK_BOOTSTRAP_PORT :: 4

BOOTSTRAP_NAME_IN_USE :: 1101

X86_THREAD_STATE32 :: 1
X86_THREAD_STATE64 :: 4
ARM_THREAD_STATE64 :: 6


mach_msg_option_t :: distinct i32
name_t :: distinct cstring

mach_msg_port_descriptor_t :: struct {
	name: mach_port_t,
	_: u32,
	using _: bit_field u32 {
		_: u32 | 16,
		disposition: u32 | 8,
		type: u32 | 8,
	},
}

mach_msg_header_t :: struct {
	msgh_bits: u32,
	msgh_size: u32,
	msgh_remote_port: mach_port_t,
	msgh_local_port: mach_port_t,
	msgh_voucher_port: u32,
	msgh_id: i32,
}

mach_msg_body_t :: struct {
	msgh_descriptor_count: u32,
}

mach_msg_trailer_t :: struct {
	msgh_trailer_type: u32,
	msgh_trailer_size: u32,
}

x86_thread_state32_t :: struct {
	eax: u32,
	ebx: u32,
	ecx: u32,
	edx: u32,
	edi: u32,
	esi: u32,
	ebp: u32,
	esp: u32,
	ss:  u32,
	eflags: u32,
	eip: u32,
	cs:  u32,
	ds:  u32,
	es:  u32,
	fs:  u32,
	gs:  u32,
}
X86_THREAD_STATE32_COUNT :: size_of(x86_thread_state32_t) / size_of(u32)

x86_thread_state64_t :: struct {
	rax: u64,
	rbx: u64,
	rcx: u64,
	rdx: u64,
	rdi: u64,
	rsi: u64,
	rbp: u64,
	rsp: u64,
	r8:  u64,
	r9:  u64,
	r10: u64,
	r11: u64,
	r12: u64,
	r13: u64,
	r14: u64,
	r15: u64,
	rip: u64,
	rflags: u64,
	cs:  u64,
	fs: u64,
	gs: u64,
}
X86_THREAD_STATE64_COUNT :: size_of(x86_thread_state64_t) / size_of(u32)

arm_thread_state64_t :: struct {
	x: [29]u64,
	fp: u64,
	lr: u64,
	sp: u64,
	pc: u64,
	cpsr: u32,
	pad:  u32,
}
ARM_THREAD_STATE64_COUNT :: size_of(arm_thread_state64_t) / size_of(u32)

@(default_calling_convention="c")
foreign mach {
	mach_task_self     :: proc() -> task_t ---
	mach_msg           :: proc(header: rawptr, option: mach_msg_option_t, send_size: u32, receive_limit: u32, receive_name: mach_port_t, timeout: u32, notify: mach_port_t) -> kern_return_t ---
	mach_msg_send      :: proc(header: rawptr) -> kern_return_t ---
	mach_vm_allocate   :: proc(target_task: task_t, adddress: u64, size: u64, flags: i32) -> kern_return_t ---
	mach_vm_deallocate :: proc(target_task: task_t, adddress: ^u64, size: u64) -> kern_return_t ---
	mach_vm_remap      :: proc(target_task: task_t, page: rawptr, size: u64, mask: u64, flags: i32, src_task: task_t, src_address: u64, copy: b32, cur_protection: ^i32, max_protection: ^i32, inheritance: i32) -> kern_return_t ---

	mach_port_allocate   :: proc(task: task_t, right: u32, name: rawptr) -> kern_return_t ---
	mach_port_deallocate :: proc(task: task_t, name: u32) -> kern_return_t ---
	mach_port_extract_right :: proc(task: task_t, name: u32, msgt_name: u32, poly: ^mach_port_t, poly_poly: ^mach_port_t) -> kern_return_t ---

	task_get_special_port :: proc(task: task_t, port: i32, special_port: ^mach_port_t) -> kern_return_t ---
	task_suspend   :: proc(task: task_t) -> kern_return_t ---
	task_resume    :: proc(task: task_t) -> kern_return_t ---
	task_threads   :: proc(task: task_t, thread_list: ^thread_list_t, list_count: ^u32) -> kern_return_t ---
	thread_get_state :: proc(thread: thread_act_t, flavor: i32, thread_state: thread_state_t, old_state_count: ^u32) -> kern_return_t ---

	bootstrap_register2 :: proc(bp: mach_port_t, service_name: name_t, sp: mach_port_t, flags: u64) -> kern_return_t ---
	bootstrap_look_up :: proc(bp: mach_port_t, service_name: name_t, sp: ^mach_port_t) -> kern_return_t ---

	semaphore_create :: proc(task: task_t, semaphore: ^semaphore_t, policy, value: c.int) -> kern_return_t ---
	semaphore_destroy :: proc(task: task_t, semaphore: semaphore_t) -> kern_return_t ---

	semaphore_signal :: proc(semaphore: semaphore_t) -> kern_return_t ---
	semaphore_signal_all :: proc(semaphore: semaphore_t) -> kern_return_t ---
	semaphore_signal_thread :: proc(semaphore: semaphore_t, thread: thread_act_t) -> kern_return_t ---
	
	semaphore_wait :: proc(semaphore: semaphore_t) -> kern_return_t ---
}
