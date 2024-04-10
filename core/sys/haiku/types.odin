//+build haiku
package sys_haiku

import "core:c"

status_t       :: i32
bigtime_t      :: i64
nanotime_t     :: i64
type_code      :: u32
perform_code   :: u32

phys_addr_t    :: uintptr
phys_size_t    :: phys_addr_t
generic_addr_t :: uintptr
generic_size_t :: generic_addr_t

area_id        :: i32
port_id        :: i32
sem_id         :: i32
team_id        :: i32
thread_id      :: i32

blkcnt_t       :: i64
blksize_t      :: i32
fsblkcnt_t     :: i64
fsfilcnt_t     :: i64
off_t          :: i64
ino_t          :: i64
cnt_t          :: i32
dev_t          :: i32
pid_t          :: i32
id_t           :: i32

uid_t          :: u32
gid_t          :: u32
mode_t         :: u32
umode_t        :: u32
nlink_t        :: i32

caddr_t        :: ^c.char

addr_t         :: phys_addr_t
key_t          :: i32

clockid_t      :: i32

time_t         :: i64 when ODIN_ARCH == .amd64 || ODIN_ARCH == .arm64 else i32

sig_atomic_t   :: c.int
sigset_t       :: u64

image_id       :: i32

pthread_t      :: rawptr
