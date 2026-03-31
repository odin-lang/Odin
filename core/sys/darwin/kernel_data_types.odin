package darwin

import "core:c"

timespec :: struct{
	tv_sec:  __darwin_time_t,
	tv_nsec: c.long,
}

//TODO: Everything else in https://developer.apple.com/documentation/kernel/kernel_data_types
