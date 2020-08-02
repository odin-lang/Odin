// +build linux, darwin
package sync

import "core:time"

raw_channel_wait_queue_wait_on :: proc(state: ^uintptr, timeout: time.Duration) {
	// stub
}

raw_channel_wait_queue_signal :: proc(q: ^Raw_Channel_Wait_Queue) {
	// stub
}

raw_channel_wait_queue_broadcast :: proc(q: ^Raw_Channel_Wait_Queue) {
	// stub
}
