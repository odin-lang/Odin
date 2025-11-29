#+build windows
package vendor_curl

import win32 "core:sys/windows"

platform_sockaddr :: win32.sockaddr
platform_fd_set :: win32.fd_set