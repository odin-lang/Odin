package sync2


guard :: proc{
	mutex_guard,
	rw_mutex_guard,
	ticket_mutex_guard,
	benaphore_guard,
	recursive_benaphore_guard,
	atomic_mutex_guard,
	atomic_recursive_mutex_guard,
	atomic_rw_mutex_guard,
}

shared_guard :: proc{
	rw_mutex_shared_guard,
	atomic_rw_mutex_shared_guard,
}

lock :: proc{
	mutex_lock,
	rw_mutex_lock,
	ticket_mutex_lock,
	benaphore_lock,
	recursive_benaphore_lock,
	atomic_mutex_lock,
	atomic_recursive_mutex_lock,
	atomic_rw_mutex_lock,
}

unlock :: proc{
	mutex_unlock,
	rw_mutex_unlock,
	ticket_mutex_unlock,
	benaphore_unlock,
	recursive_benaphore_unlock,
	atomic_mutex_unlock,
	atomic_recursive_mutex_unlock,
	atomic_rw_mutex_unlock,
}

try_lock :: proc{
	mutex_try_lock,
	rw_mutex_try_lock,
	benaphore_try_lock,
	recursive_benaphore_try_lock,
	atomic_mutex_try_lock,
	atomic_recursive_mutex_try_lock,
	atomic_rw_mutex_try_lock,
}

shared_lock :: proc{
	rw_mutex_shared_lock,
	atomic_rw_mutex_shared_lock,
}

shared_unlock :: proc{
	rw_mutex_shared_unlock,
	atomic_rw_mutex_shared_unlock,
}

try_shared_lock :: proc{
	rw_mutex_try_shared_lock,
	atomic_rw_mutex_try_shared_lock,
}



wait :: proc{
	cond_wait,
	sema_wait,
	atomic_cond_wait,
	atomic_sema_wait,
	futex_wait,
}

wait_with_timeout :: proc{
	cond_wait_with_timeout,
	sema_wait_with_timeout,
	atomic_cond_wait_with_timeout,
	atomic_sema_wait_with_timeout,
	futex_wait_with_timeout,
}

post :: proc{
	sema_post,
	atomic_sema_post,
}

signal :: proc{
	cond_signal,
	atomic_cond_signal,
	futex_signal,
}

broadcast :: proc{
	cond_broadcast,
	atomic_cond_broadcast,
	futex_broadcast,
}