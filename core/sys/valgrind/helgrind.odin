#+build amd64
package sys_valgrind

import "base:intrinsics"

Helgrind_Client_Request :: enum uintptr {
	Clean_Memory = 'H'<<24 | 'G'<<16,
	Set_My_pthread_t = ('H'<<25 | 'G'<<16)+256,
	Pthread_Join_Post,
	Pthread_Mutex_Init_Post,
	Pthread_Mutex_Destroy_Pre,
	Pthread_Mutex_Unlock_Pre,
	Pthread_Mutex_Unlock_Post,
	Pthread_Mutex_Lock_Pre,
	Pthread_Mutex_Lock_Post,
	Pthread_Cond_Signal_Pre,
	Pthread_Cond_Broadcast_Pre,
	Pthread_Cond_Wait_Pre,
	Pthread_Cond_Wait_Post,
	Pthread_Cond_Destroy_Pre,
	Pthread_Rwlock_Init_Post,
	Pthread_Rwlock_Destroy_Pre,
	Pthread_Rwlock_Lock_Pre,
	Pthread_Rwlock_Lock_Post,
	Pthread_Rwlock_Unlock_Pre,
	Pthread_Rwlock_Unlock_Post,
	Posix_Sem_Init_Post,
	Posix_Sem_Destroy_Pre,
	Posix_Sem_Post_Pre,
	Posix_Sem_Wait_Post,
	Pthread_Barrier_Init_Pre,
	Pthread_Barrier_Wait_Pre,
	Pthread_Barrier_Destroy_Pre,
	Pthread_Spin_Init_Or_Unlock_Pre,
	Pthread_Spin_Init_Or_Unlock_Post,
	Pthread_Spin_Lock_Pre,
	Pthread_Spin_Lock_Post,
	Pthread_Spin_Destroy_Pre,
	Clientreq_Unimp,
	Userso_Send_Pre,
	Userso_Recv_Post,
	Userso_Forget_All,
	Reserved2,
	Reserved3,
	Reserved4,
	Arange_Make_Untracked,
	Arange_Make_Tracked,
	Pthread_Barrier_Resize_Pre,
	Clean_Memory_Heapblock,
	Pthread_Cond_Init_Post,
}

@(require_results)
helgrind_client_request_expr :: #force_inline proc "c" (default: uintptr, request: Helgrind_Client_Request, a0, a1, a2, a3, a4: uintptr) -> uintptr {
	return intrinsics.valgrind_client_request(default, uintptr(request), a0, a1, a2, a3, a4)
}
helgrind_client_request_stmt :: #force_inline proc "c" (request: Helgrind_Client_Request, a0, a1, a2, a3, a4: uintptr) {
	_ = intrinsics.valgrind_client_request(0, uintptr(request), a0, a1, a2, a3, a4)
}

helgrind_mutex_init_post :: proc "c" (mutex: rawptr, mb_rec: uint) {
	helgrind_client_request_stmt(.Pthread_Mutex_Init_Post, uintptr(mutex), uintptr(mb_rec), 0, 0, 0)
}
helgrind_mutex_destroy_pre :: proc "c" (mutex: rawptr) {
	helgrind_client_request_stmt(.Pthread_Mutex_Destroy_Pre, uintptr(mutex), 0, 0, 0, 0)
}
helgrind_mutex_lock_pre :: proc "c" (mutex: rawptr, is_try_lock: bool) {
	helgrind_client_request_stmt(.Pthread_Mutex_Lock_Pre, uintptr(mutex), uintptr(is_try_lock), 0, 0, 0)
}
helgrind_mutex_lock_post :: proc "c" (mutex: rawptr) {
	helgrind_client_request_stmt(.Pthread_Mutex_Lock_Post, uintptr(mutex), 0, 0, 0, 0)
}
helgrind_mutex_unlock_pre :: proc "c" (mutex: rawptr) {
	helgrind_client_request_stmt(.Pthread_Mutex_Unlock_Pre, uintptr(mutex), 0, 0, 0, 0)
}
helgrind_mutex_unlock_post :: proc "c" (mutex: rawptr) {
	helgrind_client_request_stmt(.Pthread_Mutex_Unlock_Post, uintptr(mutex), 0, 0, 0, 0)
}

helgrind_rwlock_init_post :: proc "c" (lock: rawptr) {
	helgrind_client_request_stmt(.Pthread_Rwlock_Init_Post, uintptr(lock), 0, 0, 0, 0)
}
helgrind_rwlock_destroy_pre :: proc "c" (lock: rawptr) {
	helgrind_client_request_stmt(.Pthread_Rwlock_Destroy_Pre, uintptr(lock), 0, 0, 0, 0)
}
helgrind_rwlock_lock_pre :: proc "c" (lock: rawptr, is_w: bool) {
	helgrind_client_request_stmt(.Pthread_Rwlock_Lock_Pre, uintptr(lock), uintptr(is_w), 0, 0, 0)
}
helgrind_rwlock_unlock_post :: proc "c" (lock: rawptr, is_w: bool) {
	helgrind_client_request_stmt(.Pthread_Rwlock_Unlock_Pre, uintptr(lock), uintptr(is_w), 0, 0, 0)
}


helgrind_sem_init_post :: proc "c" (sem: rawptr, value: uint) {
	helgrind_client_request_stmt(.Posix_Sem_Init_Post, uintptr(sem), uintptr(value), 0, 0, 0)
}
helgrind_sem_wait_post :: proc "c" (sem: rawptr) {
	helgrind_client_request_stmt(.Posix_Sem_Wait_Post, uintptr(sem), 0, 0, 0, 0)
}
helgrind_sem_post_pre :: proc "c" (sem: rawptr) {
	helgrind_client_request_stmt(.Posix_Sem_Post_Pre, uintptr(sem), 0, 0, 0, 0)
}
helgrind_sem_destroy_pre :: proc "c" (sem: rawptr) {
	helgrind_client_request_stmt(.Posix_Sem_Destroy_Pre, uintptr(sem), 0, 0, 0, 0)
}


helgrind_barrier_init_pre :: proc "c" (bar: rawptr, count: uint, resizable: bool) {
	helgrind_client_request_stmt(.Pthread_Barrier_Init_Pre, uintptr(bar), uintptr(count), uintptr(resizable), 0, 0)
}
helgrind_barrier_wait_pre :: proc "c" (bar: rawptr) {
	helgrind_client_request_stmt(.Pthread_Barrier_Wait_Pre, uintptr(bar), 0, 0, 0, 0)
}
helgrind_barrier_resize_pre :: proc "c" (bar: rawptr, new_count: uint) {
	helgrind_client_request_stmt(.Pthread_Barrier_Resize_Pre, uintptr(bar), uintptr(new_count), 0, 0, 0)
}
helgrind_barrier_destroy_pre :: proc "c" (bar: rawptr) {
	helgrind_client_request_stmt(.Pthread_Barrier_Destroy_Pre, uintptr(bar), 0, 0, 0, 0)
}



helgrind_clean_memory :: proc "c" (qzz_start: rawptr, qzz_len: uint) {
	helgrind_client_request_stmt(.Clean_Memory, uintptr(qzz_start), uintptr(qzz_len), 0, 0, 0)
}
helgrind_clean_memory_slice :: proc "c" (qzz: []byte) {
	helgrind_client_request_stmt(.Clean_Memory, uintptr(raw_data(qzz)), uintptr(len(qzz)), 0, 0, 0)
}
helgrind_clean_memory_heap_block :: proc "c" (qzz_blockstart: rawptr) -> int {
	return int(helgrind_client_request_expr(~uintptr(1), .Clean_Memory_Heapblock, uintptr(qzz_blockstart), 0, 0, 0, 0))
}


helgrind_disable_checking :: proc "c" (qzz_start: rawptr, qzz_len: uint) {
	helgrind_client_request_stmt(.Arange_Make_Untracked, uintptr(qzz_start), uintptr(qzz_len), 0, 0, 0)
}
helgrind_enable_checking :: proc "c" (qzz_start: rawptr, qzz_len: uint) {
	helgrind_client_request_stmt(.Arange_Make_Tracked, uintptr(qzz_start), uintptr(qzz_len), 0, 0, 0)
}


helgrind_cond_init_post :: proc "c" (cond: rawptr) {
	helgrind_client_request_stmt(.Pthread_Cond_Init_Post, uintptr(cond), 0, 0, 0, 0)
}
helgrind_cond_destroy_pre :: proc "c" (cond: rawptr) {
	helgrind_client_request_stmt(.Pthread_Cond_Destroy_Pre, uintptr(cond), 0, 0, 0, 0)
}
helgrind_cond_signal_pre :: proc "c" (cond: rawptr) {
	helgrind_client_request_stmt(.Pthread_Cond_Signal_Pre, uintptr(cond), 0, 0, 0, 0)
}
helgrind_cond_broadcast_pre :: proc "c" (cond: rawptr) {
	helgrind_client_request_stmt(.Pthread_Cond_Broadcast_Pre, uintptr(cond), 0, 0, 0, 0)
}
helgrind_cond_wait_pre :: proc "c" (cond: rawptr, lock: rawptr) -> bool {
	return 0 != helgrind_client_request_expr(0, .Pthread_Cond_Wait_Pre, uintptr(cond), uintptr(lock), 0, 0, 0)
}
helgrind_cond_wait_post :: proc "c" (cond: rawptr, lock: rawptr) -> bool {
	return 0 != helgrind_client_request_expr(0, .Pthread_Cond_Wait_Post, uintptr(cond), uintptr(lock), 0, 0, 0)
}


helgrind_client_request_unimp :: #force_inline proc "c" (msg: cstring) {
	helgrind_client_request_stmt(.Clientreq_Unimp, uintptr(rawptr(msg)), 0, 0, 0, 0)
}


helgrind_annotate_condvar_lock_wait :: #force_inline proc "c" (cv: rawptr, lock: rawptr) {
	helgrind_client_request_unimp("ANNOTATE_CONDVAR_LOCK_WAIT")
}
helgrind_annotate_condvar_wait :: proc "c" (cv: rawptr) {
	helgrind_client_request_unimp("ANNOTATE_CONDVAR_WAIT")
}
helgrind_annotate_condvar_signal :: proc "c" (cv: rawptr) {
	helgrind_client_request_unimp("ANNOTATE_CONDVAR_SIGNAL")
}
helgrind_annotate_condvar_signal_all :: proc "c" (cv: rawptr) {
	helgrind_client_request_unimp("ANNOTATE_CONDVAR_SIGNAL_ALL")
}