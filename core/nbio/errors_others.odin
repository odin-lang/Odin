#+build !darwin
#+build !freebsd
#+build !openbsd
#+build !netbsd
#+build !linux
#+build !windows
#+private
package nbio

PLATFORM_ERR_UNSUPPORTED       :: 1
PLATFORM_ERR_ALLOCATION_FAILED :: 2
PLATFORM_ERR_TIMEOUT           :: 3
PLATFORM_ERR_INVALID_ARGUMENT  :: 4
PLATFORM_ERR_OVERFLOW          :: 5
PLATFORM_ERR_NOT_FOUND         :: 6
PLATFORM_ERR_EXISTS            :: 7
PLATFORM_ERR_PERMISSION_DENIED :: 8
PLATFORM_ERR_EOF               :: 9

_Platform_Error :: enum i32 {}
