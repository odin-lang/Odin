#+build darwin, freebsd, netbsd, openbsd
#+private
package nbio

import "core:sys/posix"

PLATFORM_ERR_UNSUPPORTED       :: posix.Errno.ENOSYS
PLATFORM_ERR_ALLOCATION_FAILED :: posix.Errno.ENOMEM
PLATFORM_ERR_TIMEOUT           :: posix.Errno.ECANCELED
PLATFORM_ERR_INVALID_ARGUMENT  :: posix.Errno.EINVAL
PLATFORM_ERR_OVERFLOW          :: posix.Errno.E2BIG
PLATFORM_ERR_NOT_FOUND         :: posix.Errno.ENOENT
PLATFORM_ERR_EXISTS            :: posix.Errno.EEXIST
PLATFORM_ERR_PERMISSION_DENIED :: posix.Errno.EPERM
PLATFORM_ERR_EOF               :: -100 // There is no EOF errno, we use negative for our own error codes.

_Platform_Error :: posix.Errno
