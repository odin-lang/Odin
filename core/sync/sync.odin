package sync

foreign {
	@(link_name="llvm.x86.sse2.pause")
	yield_processor :: proc() ---
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
	for ticket != m.serving {
		yield_processor();
	}
}

ticket_mutex_unlock :: inline proc(m: ^Ticket_Mutex) {
	atomic_add(&m.serving, 1, .Relaxed);
}
