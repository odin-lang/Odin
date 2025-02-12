#include <stddef.h>
#include <dirent.h>
#include <fcntl.h>
#include <glob.h>
#include <grp.h>
#include <locale.h>
#include <pthread.h>
#include <stdio.h>
#include <termios.h>
#include <netinet/in.h>
#include <netdb.h>
#include <poll.h>
#include <pwd.h>

#ifndef __HAIKU__
#include <sys/shm.h>
#endif

#include <sys/ipc.h>
#include <sys/msg.h>
#include <sys/un.h>
#include <stddef.h>
#include <sys/resource.h>
#include <sys/utsname.h>
#include <sys/times.h>
#include <signal.h>
#include <sys/select.h>
#include <sys/uio.h>
#include <sys/sem.h>
#include <sys/statvfs.h>
#include <sys/time.h>
#include <utime.h>

#ifndef __HAIKU__
#include <wordexp.h>
#endif

#include <sys/socket.h>

int main(int argc, char *argv[])
{
    printf("dirent %zu %zu\n", sizeof(struct dirent), _Alignof(struct dirent));
    printf("flock %zu %zu\n", sizeof(struct flock), _Alignof(struct flock));
    printf("glob_t %zu %zu\n", sizeof(glob_t), _Alignof(glob_t));
	printf("group %zu %zu\n", sizeof(struct group), _Alignof(struct group));
    printf("lconv %zu %zu\n", sizeof(struct lconv), _Alignof(struct lconv));

    printf("pthread_t %zu %zu\n", sizeof(pthread_t), _Alignof(pthread_t));
    printf("pthread_attr_t %zu %zu\n", sizeof(pthread_attr_t), _Alignof(pthread_attr_t));
    printf("pthread_key_t %zu %zu\n", sizeof(pthread_key_t), _Alignof(pthread_key_t));

#ifndef __linux__
    printf("sched_param %zu %zu\n", sizeof(struct sched_param), _Alignof(struct sched_param));
#endif

	printf("termios %zu %zu\n", sizeof(struct termios), _Alignof(struct termios));

	printf("in_addr %zu %zu\n", sizeof(struct in_addr), _Alignof(struct in_addr));
	printf("in6_addr %zu %zu\n", sizeof(struct in6_addr), _Alignof(struct in6_addr));
	printf("sockaddr_in %zu %zu\n", sizeof(struct sockaddr_in), _Alignof(struct sockaddr_in));
	printf("sockaddr_in6 %zu %zu\n", sizeof(struct sockaddr_in6), _Alignof(struct sockaddr_in6));
	printf("ipv6_mreq %zu %zu\n", sizeof(struct ipv6_mreq), _Alignof(struct ipv6_mreq));

	printf("sockaddr_storage %zu %zu\n", sizeof(struct sockaddr_storage), _Alignof(struct sockaddr_storage));
	printf("msghdr %zu %zu\n", sizeof(struct msghdr), _Alignof(struct msghdr));
	printf("cmsghdr %zu %zu\n", sizeof(struct cmsghdr), _Alignof(struct cmsghdr));
	printf("linger %zu %zu\n", sizeof(struct linger), _Alignof(struct linger));

	printf("hostent %zu %zu\n", sizeof(struct hostent), _Alignof(struct hostent));
	printf("netent %zu %zu\n", sizeof(struct netent), _Alignof(struct netent));
	printf("protoent %zu %zu\n", sizeof(struct protoent), _Alignof(struct protoent));
	printf("servent %zu %zu\n", sizeof(struct servent), _Alignof(struct servent));
	printf("addrinfo %zu %zu\n", sizeof(struct addrinfo), _Alignof(struct addrinfo));
	printf("ai_canonname %zu\n", offsetof(struct addrinfo, ai_canonname));

	printf("pollfd %zu %zu\n", sizeof(struct pollfd), _Alignof(struct pollfd));

	printf("passwd %zu %zu\n", sizeof(struct passwd), _Alignof(struct passwd));

#ifndef __HAIKU__
	printf("shmid_ds %zu %zu\n", sizeof(struct shmid_ds), _Alignof(struct shmid_ds));
#endif

	printf("ipc_perm %zu %zu\n", sizeof(struct ipc_perm), _Alignof(struct ipc_perm));
	printf("msqid_ds %zu %zu\n", sizeof(struct msqid_ds), _Alignof(struct msqid_ds));

	printf("rlimit %zu %zu\n", sizeof(struct rlimit), _Alignof(struct rlimit));
	printf("rusage %zu %zu\n", sizeof(struct rusage), _Alignof(struct rusage));

	printf("sockaddr_un %zu %zu\n", sizeof(struct sockaddr_un), _Alignof(struct sockaddr_un));

	printf("utsname %zu %zu\n", sizeof(struct utsname), _Alignof(struct utsname));

	printf("tms %zu %zu\n", sizeof(struct tms), _Alignof(struct tms));

	printf("sigaction %zu %zu\n", sizeof(struct sigaction), _Alignof(struct sigaction));
	printf("stack_t %zu %zu\n", sizeof(stack_t), _Alignof(stack_t));
	printf("siginfo_t %zu %zu\n", sizeof(siginfo_t), _Alignof(siginfo_t));

	printf("fd_set %zu %zu\n", sizeof(fd_set), _Alignof(fd_set));

	printf("iovec %zu %zu\n", sizeof(struct iovec), _Alignof(struct iovec));

	printf("semid_ds %zu %zu\n", sizeof(struct semid_ds), _Alignof(struct semid_ds));
	printf("sembuf %zu %zu\n", sizeof(struct sembuf), _Alignof(struct sembuf));

	printf("itimerval %zu %zu\n", sizeof(struct itimerval), _Alignof(struct itimerval));

	printf("utimbuf %zu %zu\n", sizeof(struct utimbuf), _Alignof(struct utimbuf));

#ifndef __HAIKU__
	printf("wordexp_t %zu %zu\n", sizeof(wordexp_t), _Alignof(wordexp_t));
#endif

	printf("time_t %zu %zu\n", sizeof(time_t), _Alignof(time_t));
	printf("timespec %zu %zu\n", sizeof(struct timespec), _Alignof(struct timespec));
	printf("clock_t %zu %zu\n", sizeof(clock_t), _Alignof(clock_t));

	printf("PTHREAD_CANCEL_ASYNCHRONOUS %d\n", PTHREAD_CANCEL_ASYNCHRONOUS);
	printf("PTHREAD_CANCEL_DEFERRED %d\n",     PTHREAD_CANCEL_DEFERRED);

	printf("PTHREAD_CANCEL_DISABLE %d\n",      PTHREAD_CANCEL_DISABLE);
	printf("PTHREAD_CANCEL_ENABLE %d\n",       PTHREAD_CANCEL_ENABLE);

	printf("PTHREAD_CANCELED %p\n",            PTHREAD_CANCELED);

	printf("PTHREAD_CREATE_JOINABLE %d\n",     PTHREAD_CREATE_JOINABLE);
	printf("PTHREAD_CREATE_DETACHED %d\n",     PTHREAD_CREATE_DETACHED);

	printf("PTHREAD_EXPLICIT_SCHED %d\n",      PTHREAD_EXPLICIT_SCHED);
	printf("PTHREAD_INHERIT_SCHED %d\n",       PTHREAD_INHERIT_SCHED);

	printf("PTHREAD_PRIO_INHERIT %d\n",        PTHREAD_PRIO_INHERIT);
	printf("PTHREAD_PRIO_NONE %d\n",           PTHREAD_PRIO_NONE);
	printf("PTHREAD_PRIO_PROTECT %d\n",        PTHREAD_PRIO_PROTECT);

	printf("PTHREAD_PROCESS_SHARED %d\n",      PTHREAD_PROCESS_SHARED);
	printf("PTHREAD_PROCESS_PRIVATE %d\n",     PTHREAD_PROCESS_PRIVATE);

	printf("PTHREAD_SCOPE_PROCESS %d\n",       PTHREAD_SCOPE_PROCESS);
	printf("PTHREAD_SCOPE_SYSTEM %d\n",        PTHREAD_SCOPE_SYSTEM);

	return 0;
}
