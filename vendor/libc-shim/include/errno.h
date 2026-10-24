#ifdef __cplusplus
extern "C" {
#endif

#pragma once

int *__errno_location(void);
#define errno (*__errno_location())

#define EPERM   1
#define ENOENT  2
#define EIO     5
#define EBADF   9
#define ENOMEM  12
#define EACCES  13
#define EEXIST  17
#define EINVAL  22
#define ENOSPC  28
#define ERANGE  34
#define ENOSYS  38
#define EILSEQ  84

#ifdef __cplusplus
}
#endif
