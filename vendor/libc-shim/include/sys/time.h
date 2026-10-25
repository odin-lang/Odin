#ifdef __cplusplus
extern "C" {
#endif

#pragma once

struct timeval {
	long tv_sec;
	long tv_usec;
};

// Declared only, NOT implemented: a call fails at link time. Some libraries (miniaudio)
// reference it from code that is compiled but never used on wasm.
int select(int, void *, void *, void *, struct timeval *);

#ifdef __cplusplus
}
#endif
