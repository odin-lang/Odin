#include <stddef.h>
#include <stdio.h>
#include <sys/event.h>

int main(int argc, char *argv[])
{
	printf("kevent %zu %zu\n",    sizeof(struct kevent), _Alignof(struct kevent));
	printf("kevent.ident %zu\n",  offsetof(struct kevent, ident));
	printf("kevent.filter %zu\n", offsetof(struct kevent, filter));
	printf("kevent.flags %zu\n",  offsetof(struct kevent, flags));
	printf("kevent.fflags %zu\n", offsetof(struct kevent, fflags));
	printf("kevent.data %zu\n",   offsetof(struct kevent, data));
	printf("kevent.udata %zu\n",  offsetof(struct kevent, udata));

	printf("EV_ADD %d\n",      EV_ADD);
	printf("EV_DELETE %d\n",   EV_DELETE);
	printf("EV_ENABLE %d\n",   EV_ENABLE);
	printf("EV_DISABLE %d\n",  EV_DISABLE);
	printf("EV_ONESHOT %d\n",  EV_ONESHOT);
	printf("EV_CLEAR %d\n",    EV_CLEAR);
	printf("EV_RECEIPT %d\n",  EV_RECEIPT);
	printf("EV_DISPATCH %d\n", EV_DISPATCH);
	printf("EV_ERROR %d\n",    EV_ERROR);
	printf("EV_EOF %d\n",      EV_EOF);

	printf("EVFILT_READ %d\n",   EVFILT_READ);
	printf("EVFILT_WRITE %d\n",  EVFILT_WRITE);
	printf("EVFILT_AIO %d\n",    EVFILT_AIO);
	printf("EVFILT_VNODE %d\n",  EVFILT_VNODE);
	printf("EVFILT_PROC %d\n",   EVFILT_PROC);
	printf("EVFILT_SIGNAL %d\n", EVFILT_SIGNAL);
	printf("EVFILT_TIMER %d\n",  EVFILT_TIMER);
	printf("EVFILT_USER %d\n",   EVFILT_USER);

	printf("NOTE_SECONDS %u\n",  NOTE_SECONDS);
	printf("NOTE_USECONDS %u\n", NOTE_USECONDS);
	printf("NOTE_NSECONDS %u\n", NOTE_NSECONDS);
#if defined(NOTE_ABSOLUTE)
	printf("NOTE_ABSOLUTE %u\n", NOTE_ABSOLUTE);
#else
	printf("NOTE_ABSOLUTE %u\n", NOTE_ABSTIME);
#endif

	printf("NOTE_LOWAT %u\n", NOTE_LOWAT);

	printf("NOTE_DELETE %u\n", NOTE_DELETE);
	printf("NOTE_WRITE %u\n",  NOTE_WRITE);
	printf("NOTE_EXTEND %u\n", NOTE_EXTEND);
	printf("NOTE_ATTRIB %u\n", NOTE_ATTRIB);
	printf("NOTE_LINK %u\n",   NOTE_LINK);
	printf("NOTE_RENAME %u\n", NOTE_RENAME);
	printf("NOTE_REVOKE %u\n", NOTE_REVOKE);

	printf("NOTE_EXIT %u\n", NOTE_EXIT);
	printf("NOTE_FORK %u\n", NOTE_FORK);
	printf("NOTE_EXEC %u\n", NOTE_EXEC);

	printf("NOTE_TRIGGER %u\n", NOTE_TRIGGER);
	printf("NOTE_FFAND %u\n",   NOTE_FFAND);
	printf("NOTE_FFOR %u\n",    NOTE_FFOR);
	printf("NOTE_FFCOPY %u\n",  NOTE_FFCOPY);
	return 0;
}
