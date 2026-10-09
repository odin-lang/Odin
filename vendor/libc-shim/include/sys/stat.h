#ifdef __cplusplus
extern "C" {
#endif

#pragma once

struct stat {
	long long st_size;
	unsigned int st_mode;
};

// Not supported: always fails with EBADF (see stdio.odin).
int fstat(int, struct stat *);

#ifdef __cplusplus
}
#endif
