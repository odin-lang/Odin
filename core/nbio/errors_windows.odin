#+private
package nbio

import win "core:sys/windows"

PLATFORM_ERR_UNSUPPORTED       :: win.System_Error.NOT_SUPPORTED

PLATFORM_ERR_ALLOCATION_FAILED :: win.System_Error.OUTOFMEMORY
PLATFORM_ERR_TIMEOUT           :: win.System_Error.WAIT_TIMEOUT
PLATFORM_ERR_INVALID_ARGUMENT  :: win.System_Error.BAD_ARGUMENTS
PLATFORM_ERR_OVERFLOW          :: win.System_Error.BUFFER_OVERFLOW
PLATFORM_ERR_NOT_FOUND         :: win.System_Error.FILE_NOT_FOUND
PLATFORM_ERR_EXISTS            :: win.System_Error.FILE_EXISTS
PLATFORM_ERR_PERMISSION_DENIED :: win.System_Error.ACCESS_DENIED
PLATFORM_ERR_EOF               :: win.System_Error.HANDLE_EOF

_Platform_Error :: win.System_Error
