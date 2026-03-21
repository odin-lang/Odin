package main

import "core:fmt"
import "core:sys/kqueue"

main :: proc() {
	fmt.println("kevent",        size_of(kqueue.KEvent), align_of(kqueue.KEvent))
	fmt.println("kevent.ident",  offset_of(kqueue.KEvent, ident))
	fmt.println("kevent.filter", offset_of(kqueue.KEvent, filter))
	fmt.println("kevent.flags",  offset_of(kqueue.KEvent, flags))
	fmt.println("kevent.fflags", offset_of(kqueue.KEvent, fflags))
	fmt.println("kevent.data",   offset_of(kqueue.KEvent, data))
	fmt.println("kevent.udata",  offset_of(kqueue.KEvent, udata))

	fmt.println("EV_ADD",      transmute(kqueue._Flags_Backing)kqueue.Flags{.Add})
	fmt.println("EV_DELETE",   transmute(kqueue._Flags_Backing)kqueue.Flags{.Delete})
	fmt.println("EV_ENABLE",   transmute(kqueue._Flags_Backing)kqueue.Flags{.Enable})
	fmt.println("EV_DISABLE",  transmute(kqueue._Flags_Backing)kqueue.Flags{.Disable})
	fmt.println("EV_ONESHOT",  transmute(kqueue._Flags_Backing)kqueue.Flags{.One_Shot})
	fmt.println("EV_CLEAR",    transmute(kqueue._Flags_Backing)kqueue.Flags{.Clear})
	fmt.println("EV_RECEIPT",  transmute(kqueue._Flags_Backing)kqueue.Flags{.Receipt})
	fmt.println("EV_DISPATCH", transmute(kqueue._Flags_Backing)kqueue.Flags{.Dispatch})
	fmt.println("EV_ERROR",    transmute(kqueue._Flags_Backing)kqueue.Flags{.Error})
	fmt.println("EV_EOF",      transmute(kqueue._Flags_Backing)kqueue.Flags{.EOF})

	fmt.println("EVFILT_READ",   int(kqueue.Filter.Read))
	fmt.println("EVFILT_WRITE",  int(kqueue.Filter.Write))
	fmt.println("EVFILT_AIO",    int(kqueue.Filter.AIO))
	fmt.println("EVFILT_VNODE",  int(kqueue.Filter.VNode))
	fmt.println("EVFILT_PROC",   int(kqueue.Filter.Proc))
	fmt.println("EVFILT_SIGNAL", int(kqueue.Filter.Signal))
	fmt.println("EVFILT_TIMER",  int(kqueue.Filter.Timer))
	fmt.println("EVFILT_USER",   int(kqueue.Filter.User))

	fmt.println("NOTE_SECONDS",  transmute(u32)kqueue.Timer_Flags{.Seconds})
	fmt.println("NOTE_USECONDS", transmute(u32)kqueue.Timer_Flags{.USeconds})
	fmt.println("NOTE_NSECONDS", transmute(u32)kqueue.TIMER_FLAGS_NSECONDS)
	fmt.println("NOTE_ABSOLUTE", transmute(u32)kqueue.Timer_Flags{.Absolute})

	fmt.println("NOTE_LOWAT", transmute(u32)kqueue.RW_Flags{.Low_Water_Mark})

	fmt.println("NOTE_DELETE", transmute(u32)kqueue.VNode_Flags{.Delete})
	fmt.println("NOTE_WRITE",  transmute(u32)kqueue.VNode_Flags{.Write})
	fmt.println("NOTE_EXTEND", transmute(u32)kqueue.VNode_Flags{.Extend})
	fmt.println("NOTE_ATTRIB", transmute(u32)kqueue.VNode_Flags{.Attrib})
	fmt.println("NOTE_LINK",   transmute(u32)kqueue.VNode_Flags{.Link})
	fmt.println("NOTE_RENAME", transmute(u32)kqueue.VNode_Flags{.Rename})
	fmt.println("NOTE_REVOKE", transmute(u32)kqueue.VNode_Flags{.Revoke})

	fmt.println("NOTE_EXIT",   transmute(u32)kqueue.Proc_Flags{.Exit})
	fmt.println("NOTE_FORK",   transmute(u32)kqueue.Proc_Flags{.Fork})
	fmt.println("NOTE_EXEC",   transmute(u32)kqueue.Proc_Flags{.Exec})

	fmt.println("NOTE_TRIGGER", transmute(u32)kqueue.User_Flags{.Trigger})
	fmt.println("NOTE_FFAND",   transmute(u32)kqueue.User_Flags{.FFAnd})
	fmt.println("NOTE_FFOR",    transmute(u32)kqueue.User_Flags{.FFOr})
	fmt.println("NOTE_FFCOPY",  transmute(u32)kqueue.USER_FLAGS_COPY)
}
