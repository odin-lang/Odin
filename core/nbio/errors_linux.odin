#+private
package nbio

import "core:sys/linux"

PLATFORM_ERR_UNSUPPORTED       :: linux.Errno.ENOSYS
PLATFORM_ERR_ALLOCATION_FAILED :: linux.Errno.ENOMEM
PLATFORM_ERR_TIMEOUT           :: linux.Errno.ECANCELED
PLATFORM_ERR_INVALID_ARGUMENT  :: linux.Errno.EINVAL
PLATFORM_ERR_OVERFLOW          :: linux.Errno.E2BIG
PLATFORM_ERR_NOT_FOUND         :: linux.Errno.ENOENT
PLATFORM_ERR_EXISTS            :: linux.Errno.EEXIST
PLATFORM_ERR_PERMISSION_DENIED :: linux.Errno.EPERM
PLATFORM_ERR_EOF               :: -100 // There is no EOF errno, we use negative for our own error codes.

_Platform_Error :: linux.Errno
