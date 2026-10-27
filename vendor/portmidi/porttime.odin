package portmidi

import "core:c"

when ODIN_OS == .Windows {
	foreign import lib "portmidi_s.lib"
} else when ODIN_OS == .Darwin && !PORTMIDI_SHARED {
	foreign import lib "darwin/portmidi_s.a"
} else {
	foreign import lib "system:portmidi"
}

/*
	PortTime is a small millisecond timer that PortMidi uses as its default time source, for the timestamps of MIDI
	messages. It is part of the same library, and its timestamps are the `Timestamp` of PortMidi.
*/

TimerError :: enum c.int {
	NoError = 0,
	HostError = -10000,
	AlreadyStarted, /**< cannot start timer because it is already started */
	AlreadyStopped, /**< cannot stop timer because it is already stopped */
	InsufficientMemory, /**< memory could not be allocated */
}

/**
	A function that TimerStart() calls from the timer thread every `resolution` milliseconds with the current time.
*/
TimerCallback :: proc "c" (timestamp: Timestamp, userData: rawptr)

@(default_calling_convention="c")
foreign lib {
	/**
		Start a timer thread that calls `callback` every `resolution` milliseconds, with `userData` as its second
		argument. The callback may be nil to only start the clock. If you want to use the timer as the time source
		of PortMidi, start it before opening any stream. Returns .AlreadyStarted if it is running.
	*/
	@(link_name="Pt_Start")
	TimerStart :: proc(resolution: c.int, callback: TimerCallback, userData: rawptr) -> TimerError ---

	/**
		Stop the timer, returns .AlreadyStopped if it was not running.
	*/
	@(link_name="Pt_Stop")
	TimerStop :: proc() -> TimerError ---

	/**
		Returns whether the timer is running.
	*/
	@(link_name="Pt_Started")
	TimerStarted :: proc() -> b32 ---

	/**
		Returns the time in milliseconds since the timer was started.
	*/
	@(link_name="Pt_Time")
	TimerTime :: proc() -> Timestamp ---

	/**
		Sleep for `duration` milliseconds.
	*/
	@(link_name="Pt_Sleep")
	TimerSleep :: proc(duration: i32) ---
}
