#+build !windows
package vendor_curl

import "core:sys/posix"

platform_sockaddr :: posix.sockaddr
platform_fd_set   :: posix.fd_set