#+build !windows
package miniaudio

import "core:sys/posix"
import "core:c"

thread :: posix.pthread_t
mutex :: posix.pthread_mutex_t
event :: struct {
	value: u32,
	lock: posix.pthread_mutex_t,
	cond: posix.pthread_cond_t,
}
semaphore :: struct {
	value: c.int,
	lock: posix.pthread_mutex_t,
	cond: posix.pthread_cond_t,
}
