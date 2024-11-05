#+build darwin, openbsd, freebsd, netbsd
package all

import posix  "core:sys/posix"
import kqueue "core:sys/kqueue"

_ :: posix
_ :: kqueue
