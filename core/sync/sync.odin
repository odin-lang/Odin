package sync

import "core:intrinsics"

cpu_relax :: inline proc() {
	intrinsics.cpu_relax();
}

Ticket_Mutex :: struct {
	ticket:  u64,
	serving: u64,
}

ticket_mutex_init :: proc(m: ^Ticket_Mutex) {
	atomic_store(&m.ticket,  0, .Relaxed);
	atomic_store(&m.serving, 0, .Relaxed);
}

ticket_mutex_lock :: inline proc(m: ^Ticket_Mutex) {
	ticket := atomic_add(&m.ticket, 1, .Relaxed);
	for ticket != atomic_load(&m.serving, .Acquire) {
		intrinsics.cpu_relax();
	}
}

ticket_mutex_unlock :: inline proc(m: ^Ticket_Mutex) {
	atomic_add(&m.serving, 1, .Relaxed);
}
