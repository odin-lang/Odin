package unix

import "core:c"

timespec :: struct {
	secs:  i64,
	nsecs: c.long,
}
