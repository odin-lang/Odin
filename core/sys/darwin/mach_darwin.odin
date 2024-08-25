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

kern_return_t :: distinct u64
thread_act_t :: distinct u64

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

TASK_BOOTSTRAP_PORT :: 4

mach_msg_option_t :: distinct i32
name_t :: distinct cstring

mach_msg_port_descriptor_t :: struct {
	name: mach_port_t,
	_: u32,
	extra: bit_field u32 {
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

@(default_calling_convention="c")
foreign mach {
	mach_task_self :: proc() -> task_t ---
	mach_msg :: proc(header: rawptr, option: mach_msg_option_t, send_size: u32, receive_limit: u32, receive_name: mach_port_t, timeout: u32, notify: mach_port_t) -> kern_return_t ---
	mach_msg_send :: proc(header: rawptr) -> kern_return_t ---

	mach_port_allocate   :: proc(task: task_t, right: u32, name: rawptr) -> kern_return_t ---
	mach_port_deallocate :: proc(task: task_t, name: u32) -> kern_return_t ---
	mach_port_extract_right :: proc(task: task_t, name: u32, msgt_name: u32, poly: ^mach_port_t, poly_poly: ^mach_port_t) -> kern_return_t ---

	task_get_special_port :: proc(task: task_t, port: i32, special_port: ^mach_port_t) -> kern_return_t ---
	bootstrap_register2 :: proc(bp: mach_port_t, service_name: name_t, sp: mach_port_t, flags: u64) -> kern_return_t ---
	bootstrap_look_up :: proc(bp: mach_port_t, service_name: name_t, sp: ^mach_port_t) -> kern_return_t ---

	semaphore_create :: proc(task: task_t, semaphore: ^semaphore_t, policy, value: c.int) -> kern_return_t ---
	semaphore_destroy :: proc(task: task_t, semaphore: semaphore_t) -> kern_return_t ---

	semaphore_signal :: proc(semaphore: semaphore_t) -> kern_return_t ---
	semaphore_signal_all :: proc(semaphore: semaphore_t) -> kern_return_t ---
	semaphore_signal_thread :: proc(semaphore: semaphore_t, thread: thread_act_t) -> kern_return_t ---
	
	semaphore_wait :: proc(semaphore: semaphore_t) -> kern_return_t ---
}
