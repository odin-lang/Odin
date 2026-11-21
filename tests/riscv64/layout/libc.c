#define _GNU_SOURCE
#include <stdio.h>
#include <stddef.h>
#include <dirent.h>
#include <sys/socket.h>

#define S(n, t)    printf("%s %d %d\n", n, (int)sizeof(t), (int)_Alignof(t))
#define Z(n, t)    printf("%s %d\n", n, (int)sizeof(t))
#define F(n, t, f) printf("%s %d\n", n, (int)offsetof(t, f))

void libc_layouts(void)
{
	F("dirent64.d_off", struct dirent64, d_off);
	F("dirent64.d_reclen", struct dirent64, d_reclen);
	F("dirent64.d_type", struct dirent64, d_type);
	F("dirent64.d_name", struct dirent64, d_name);

	Z("sockaddr", struct sockaddr);
	F("sockaddr.sa_data", struct sockaddr, sa_data);
	S("linger", struct linger);
	F("linger.l_linger", struct linger, l_linger);
	S("msghdr", struct msghdr);
	F("msghdr.msg_namelen", struct msghdr, msg_namelen);
	F("msghdr.msg_iov", struct msghdr, msg_iov);
	F("msghdr.msg_iovlen", struct msghdr, msg_iovlen);
	F("msghdr.msg_control", struct msghdr, msg_control);
	F("msghdr.msg_controllen", struct msghdr, msg_controllen);
	F("msghdr.msg_flags", struct msghdr, msg_flags);
	S("mmsghdr", struct mmsghdr);
	F("mmsghdr.msg_len", struct mmsghdr, msg_len);
}
