#+build !windows
package miniaudio

import "core:sys/unix"
import "core:c"

thread :: unix.pthread_t
mutex :: unix.pthread_mutex_t
event :: struct {
	value: u32,
	lock: unix.pthread_mutex_t,
	cond: unix.pthread_cond_t,
}
semaphore :: struct {
	value: c.int,
	lock: unix.pthread_mutex_t,
	cond: unix.pthread_cond_t,
}
