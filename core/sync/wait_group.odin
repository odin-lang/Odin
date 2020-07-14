package sync

import "intrinsics"

Wait_Group :: struct {
	counter: int,
	mutex:   Blocking_Mutex,
	cond:    Condition,
}

wait_group_init :: proc(wg: ^Wait_Group) {
	wg.counter = 0;
	blocking_mutex_init(&wg.mutex);
	condition_init(&wg.cond, &wg.mutex);
}


wait_group_destroy :: proc(wg: ^Wait_Group) {
	condition_destroy(&wg.cond);
	blocking_mutex_destroy(&wg.mutex);
}

wait_group_add :: proc(wg: ^Wait_Group, delta: int) {
	if delta == 0 {
		return;
	}

	blocking_mutex_lock(&wg.mutex);
	defer blocking_mutex_unlock(&wg.mutex);

	intrinsics.atomic_add(&wg.counter, delta);
	if wg.counter < 0 {
		panic("sync.Wait_Group negative counter");
	}
	if wg.counter == 0 {
		condition_broadcast(&wg.cond);
		if wg.counter != 0 {
			panic("sync.Wait_Group misuse: sync.wait_group_add called concurrently with sync.wait_group_wait");
		}
	}
}

wait_group_done :: proc(wg: ^Wait_Group) {
	wait_group_add(wg, -1);
}

wait_group_wait :: proc(wg: ^Wait_Group) {
	blocking_mutex_lock(&wg.mutex);
	defer blocking_mutex_unlock(&wg.mutex);

	if wg.counter != 0 {
		condition_wait_for(&wg.cond);
		if wg.counter != 0 {
			panic("sync.Wait_Group misuse: sync.wait_group_add called concurrently with sync.wait_group_wait");
		}
	}
}

