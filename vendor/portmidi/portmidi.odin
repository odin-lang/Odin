package portmidi

import "core:c"
import "core:strings"

PORTMIDI_SHARED :: #config(PORTMIDI_SHARED, false)

when ODIN_OS == .Windows {
	when PORTMIDI_SHARED {
		#panic("Shared linking not supported for portmidi on windows yet")
	} else {
		foreign import lib {
			"portmidi_s.lib",
			"system:Winmm.lib",
			"system:Advapi32.lib",
		}
	}
} else {
	foreign import lib "system:portmidi"
}

#assert(size_of(b32) == size_of(c.int))

DEFAULT_SYSEX_BUFFER_SIZE :: 1024

Error :: enum c.int {
	NoError = 0,
	NoData = 0, /**< A "no error" return that also indicates no data avail. */
	GotData = 1, /**< A "no error" return that also indicates data available */
	HostError = -10000,
	InvalidDeviceId, /** out of range or 
	                   * output device when input is requested or 
	                   * input device when output is requested or
	                   * device is already opened 
	                   */
	InsufficientMemory,
	BufferTooSmall,
	BufferOverflow,
	BadPtr, /* Stream parameter is nil or
	         * stream is not opened or
	         * stream is output when input is required or
	         * stream is input when output is required */
	BadData, /** illegal midi data, e.g. missing EOX */
	InternalError,
	BufferMaxSize, /** buffer is already as large as it can be */
}

/**  A single Stream is a descriptor for an open MIDI device.
*/
Stream :: distinct rawptr

@(default_calling_convention="c", link_prefix="Pm_")
foreign lib {
	/**
		Initialize() is the library initialisation function - call this before
		using the library.
	*/
	Initialize :: proc() -> Error ---
	
	/**
		Terminate() is the library termination function - call this after
		using the library.
	*/
	Terminate  :: proc() -> Error ---
	
	/**
		Test whether stream has a pending host error. Normally, the client finds
		out about errors through returned error codes, but some errors can occur
		asynchronously where the client does not
		explicitly call a function, and therefore cannot receive an error code.
		The client can test for a pending error using HasHostError(). If true,
		the error can be accessed and cleared by calling GetErrorText(). 
		Errors are also cleared by calling other functions that can return
		errors, e.g. OpenInput(), OpenOutput(), Read(), Write(). The
		client does not need to call HasHostError(). Any pending error will be
		reported the next time the client performs an explicit function call on 
		the stream, e.g. an input or output operation. Until the error is cleared,
		no new error codes will be obtained, even for a different stream.
	*/
	HasHostError :: proc(stream: Stream) -> b32 ---	
}

/**
	Translate portmidi error number into human readable message.
	These strings are constants (set at compile time) so client has
	no need to allocate storage
*/
GetErrorText :: proc (errnum: Error) -> string {
	@(default_calling_convention="c")
	foreign lib {
		Pm_GetErrorText :: proc(errnum: Error) -> cstring ---
	}
	return string(Pm_GetErrorText(errnum))
}

/**
	Translate portmidi host error into human readable message.
	These strings are computed at run time, so client has to allocate storage.
	After this routine executes, the host error is cleared.
*/
GetHostErrorText :: proc (buf: []byte) -> string {
	@(default_calling_convention="c")
	foreign lib {
		Pm_GetHostErrorText :: proc(msg: [^]u8, len: c.uint) ---
	}
	Pm_GetHostErrorText(raw_data(buf), u32(len(buf)))
	str := string(buf[:])
	return strings.truncate_to_byte(str, 0)
}


HDRLENGTH :: 50
HOST_ERROR_MSG_LEN :: 256 /* any host error msg will occupy less 
                              than this number of characters */

DeviceID :: distinct c.int
NoDevice :: DeviceID(-1)
DeviceInfo :: struct {
	structVersion: c.int,   /**< this internal structure version */ 
	interf:        cstring, /**< underlying MIDI API, e.g. MMSystem or DirectX */
	name:          cstring, /**< device name, e.g. USB MidiSport 1x1 */
	input:         b32,     /**< true iff input is available */
	output:        b32,     /**< true iff output is available */
	opened:        b32,     /**< used by generic PortMidi code to do error checking on arguments */
}

@(default_calling_convention="c", link_prefix="Pm_")
foreign lib {
	/**  Get devices count, ids range from 0 to CountDevices()-1. */
	CountDevices             :: proc() -> c.int ---

	GetDefaultInputDeviceID  :: proc() -> DeviceID ---
	GetDefaultOutputDeviceID :: proc() -> DeviceID ---
}


/**
	Timestamp is used to represent a millisecond clock with arbitrary
	start time. The type is used for all MIDI timestampes and clocks.
*/
Timestamp :: distinct i32
TimeProc :: proc "c" (time_info: rawptr) -> Timestamp

Before :: #force_inline proc "c" (t1, t2: Timestamp) -> b32 {
	return b32((t1-t2) < 0)
}

@(default_calling_convention="c", link_prefix="Pm_")
foreign lib {
	/**
		GetDeviceInfo() returns a pointer to a DeviceInfo structure
		referring to the device specified by id.
		If id is out of range the function returns nil.

		The returned structure is owned by the PortMidi implementation and must
		not be manipulated or freed. The pointer is guaranteed to be valid
		between calls to Initialize() and Terminate().
	*/
	GetDeviceInfo :: proc(id: DeviceID) -> ^DeviceInfo ---
	
	/**
		OpenInput() and OpenOutput() open devices.

		stream is the address of a Stream pointer which will receive
		a pointer to the newly opened stream.

		inputDevice is the id of the device used for input (see DeviceID above).

		inputDriverInfo is a pointer to an optional driver specific data structure
		containing additional information for device setup or handle processing.
		inputDriverInfo is never required for correct operation. If not used
		inputDriverInfo should be nil.

		outputDevice is the id of the device used for output (see DeviceID above.)

		outputDriverInfo is a pointer to an optional driver specific data structure
		containing additional information for device setup or handle processing.
		outputDriverInfo is never required for correct operation. If not used
		outputDriverInfo should be nil.

		For input, the buffersize specifies the number of input events to be 
		buffered waiting to be read using Read(). For output, buffersize 
		specifies the number of output events to be buffered waiting for output. 
		(In some cases -- see below -- PortMidi does not buffer output at all
		and merely passes data to a lower-level API, in which case buffersize
		is ignored.)

		latency is the delay in milliseconds applied to timestamps to determine 
		when the output should actually occur. (If latency is < 0, 0 is assumed.) 
		If latency is zero, timestamps are ignored and all output is delivered
		immediately. If latency is greater than zero, output is delayed until the
		message timestamp plus the latency. (NOTE: the time is measured relative 
		to the time source indicated by time_proc. Timestamps are absolute,
		not relative delays or offsets.) In some cases, PortMidi can obtain
		better timing than your application by passing timestamps along to the
		device driver or hardware. Latency may also help you to synchronize midi
		data to audio data by matching midi latency to the audio buffer latency.

		time_proc is a pointer to a procedure that returns time in milliseconds. It
		may be nil, in which case a default millisecond timebase (PortTime) is 
		used. If the application wants to use PortTime, it should start the timer
		(call Pt_Start) before calling OpenInput or OpenOutput. If the
		application tries to start the timer *after* OpenInput or OpenOutput,
		it may get a ptAlreadyStarted error from Pt_Start, and the application's
		preferred time resolution and callback function will be ignored.
		time_proc result values are appended to incoming MIDI data, and time_proc
		times are used to schedule outgoing MIDI data (when latency is non-zero).

		time_info is a pointer passed to time_proc.

		Example: If I provide a timestamp of 5000, latency is 1, and time_proc
		returns 4990, then the desired output time will be when time_proc returns
		timestamp+latency = 5001. This will be 5001-4990 = 11ms from now.

		return value:
		Upon success Open() returns NoError and places a pointer to a
		valid Stream in the stream argument.
		If a call to Open() fails a nonzero error code is returned (see
		PMError above) and the value of port is invalid.

		Any stream that is successfully opened should eventually be closed
		by calling Close().
	*/
	OpenInput :: proc(stream: ^Stream,
	                  inputDevice: DeviceID,
	                  inputDriverInfo: rawptr,
	                  bufferSize: i32,
	                  time_proc: TimeProc,
	                  time_info: rawptr) -> Error ---

	OpenOutput :: proc(stream: ^Stream,
	                   outputDevice: DeviceID,
	                   outputDriverInfo: rawptr,
	                   bufferSize: i32,
	                   time_proc: TimeProc,
	                   time_info: rawptr,
	                   latency: i32) -> Error ---
	
}


@(default_calling_convention="c", link_prefix="Pm_")
foreign lib {
	/**
		SetFilter() sets filters on an open input stream to drop selected
		input types. By default, only active sensing messages are filtered.
		To prohibit, say, active sensing and sysex messages, call
		SetFilter(stream, FILT_ACTIVE | FILT_SYSEX);

		Filtering is useful when midi routing or midi thru functionality is being
		provided by the user application.
		For example, you may want to exclude timing messages (clock, MTC, start/stop/continue),
		while allowing note-related messages to pass.
		Or you may be using a sequencer or drum-machine for MIDI clock information but want to
		exclude any notes it may play.
	 */
	SetFilter :: proc(stream: Stream, filters: i32) -> Error ---
}
 	
 	
/* Filter bit-mask definitions */
/** filter active sensing messages (0xFE): */
FILT_ACTIVE             :: 1 << 0x0E
/** filter system exclusive messages (0xF0): */
FILT_SYSEX              :: 1 << 0x00
/** filter MIDI clock message (0xF8) */
FILT_CLOCK              :: 1 << 0x08
/** filter play messages (start 0xFA, stop 0xFC, continue 0xFB) */
FILT_PLAY               :: (1 << 0x0A) | (1 << 0x0C) | (1 << 0x0B)
/** filter tick messages (0xF9) */
FILT_TICK               :: 1 << 0x09
/** filter undefined FD messages */
FILT_FD                 :: 1 << 0x0D
/** filter undefined real-time messages */
FILT_UNDEFINED          :: FILT_FD
/** filter reset messages (0xFF) */
FILT_RESET              :: 1 << 0x0F
/** filter all real-time messages */
FILT_REALTIME           :: FILT_ACTIVE | FILT_SYSEX | FILT_CLOCK | FILT_PLAY | FILT_UNDEFINED | FILT_RESET | FILT_TICK
/** filter note-on and note-off (0x90-0x9F and 0x80-0x8F */
FILT_NOTE               :: (1 << 0x19) | (1 << 0x18)
/** filter channel aftertouch (most midi controllers use this) (0xD0-0xDF)*/
FILT_CHANNEL_AFTERTOUCH :: 1 << 0x1D
/** per-note aftertouch (0xA0-0xAF) */
FILT_POLY_AFTERTOUCH    :: 1 << 0x1A
/** filter both channel and poly aftertouch */
FILT_AFTERTOUCH         :: FILT_CHANNEL_AFTERTOUCH | FILT_POLY_AFTERTOUCH
/** Program changes (0xC0-0xCF) */
FILT_PROGRAM            :: 1 << 0x1C
/** Control Changes (CC's) (0xB0-0xBF)*/
FILT_CONTROL            :: 1 << 0x1B
/** Pitch Bender (0xE0-0xEF*/
FILT_PITCHBEND          :: 1 << 0x1E
/** MIDI Time Code (0xF1)*/
FILT_MTC                :: 1 << 0x01
/** Song Position (0xF2) */
FILT_SONG_POSITION      :: 1 << 0x02
/** Song Select (0xF3)*/
FILT_SONG_SELECT        :: 1 << 0x03
/** Tuning request (0xF6)*/
FILT_TUNE               :: 1 << 0x06
/** All System Common messages (mtc, song position, song select, tune request) */
FILT_SYSTEMCOMMON       :: FILT_MTC | FILT_SONG_POSITION | FILT_SONG_SELECT | FILT_TUNE

Channel :: #force_inline proc "c" (channel: c.int) -> c.int {
	return 1<<c.uint(channel)
}

@(default_calling_convention="c", link_prefix="Pm_")
foreign lib {
	/**
		SetChannelMask() filters incoming messages based on channel.
		The mask is a 16-bit bitfield corresponding to appropriate channels.
		The _Channel macro can assist in calling this function.
		i.e. to set receive only input on channel 1, call with
		SetChannelMask(Channel(1));
		Multiple channels should be OR'd together, like
		SetChannelMask(Channel(10) | Channel(11))

		Note that channels are numbered 0 to 15 (not 1 to 16). Most 
		synthesizer and interfaces number channels starting at 1, but
		PortMidi numbers channels starting at 0.

		All channels are allowed by default
	*/
	SetChannelMask :: proc(stream: Stream, mask: c.int) -> Error ---
	
	/**
		Abort() terminates outgoing messages immediately
		The caller should immediately close the output port;
		this call may result in transmission of a partial midi message.
		There is no abort for Midi input because the user can simply
		ignore messages in the buffer and close an input device at
		any time.
	 */
	Abort :: proc(stream: Stream) -> Error ---
	
	/**
		Close() closes a midi stream, flushing any pending buffers.
		(PortMidi attempts to close open streams when the application 
		exits -- this is particularly difficult under Windows.)
	*/
	Close :: proc(stream: Stream) -> Error ---
	
	/**
		Synchronize() instructs PortMidi to (re)synchronize to the
		time_proc passed when the stream was opened. Typically, this
		is used when the stream must be opened before the time_proc
		reference is actually advancing. In this case, message timing
		may be erratic, but since timestamps of zero mean 
		"send immediately," initialization messages with zero timestamps
		can be written without a functioning time reference and without
		problems. Before the first MIDI message with a non-zero
		timestamp is written to the stream, the time reference must
		begin to advance (for example, if the time_proc computes time
		based on audio samples, time might begin to advance when an 
		audio stream becomes active). After time_proc return values
		become valid, and BEFORE writing the first non-zero timestamped 
		MIDI message, call Synchronize() so that PortMidi can observe
		the difference between the current time_proc value and its
		MIDI stream time. 
		
		In the more normal case where time_proc 
		values advance continuously, there is no need to call 
		Synchronize. PortMidi will always synchronize at the 
		first output message and periodically thereafter.
	*/
	Synchronize :: proc(stream: Stream) -> Error ---
}

/**
	MessageMake() encodes a short Midi message into a 32-bit word. If data1
	and/or data2 are not present, use zero.

	MessageStatus(), MessageData1(), and
	MessageData2() extract fields from a 32-bit midi message.
*/
MessageMake :: #force_inline proc "c" (status: c.int, data1, data2: c.int) -> Message {
	return Message(((data2 << 16) & 0xFF0000) | ((data1 << 8) & 0xFF00) | (status & 0xFF))
}
MessageStatus :: #force_inline proc "c" (msg: Message) -> c.int {
	return c.int(msg & 0xFF)
}
MessageData1  :: #force_inline proc "c" (msg: Message) -> c.int {
	return c.int((msg >> 8) & 0xFF)
}
MessageData2  :: #force_inline proc "c" (msg: Message) -> c.int {
	return c.int((msg >> 16) & 0xFF)
}

MessageCompose :: MessageMake
MessageDecompose :: #force_inline proc "c" (msg: Message) -> (status, data1, data2: c.int) {
	status = c.int(msg & 0xFF)
	data1  = c.int((msg >> 8) & 0xFF)
	data2  = c.int((msg >> 16) & 0xFF)
	return
}


Message :: distinct i32
/**
	All midi data comes in the form of Event structures. A sysex
	message is encoded as a sequence of Event structures, with each
	structure carrying 4 bytes of the message, i.e. only the first
	Event carries the status byte.

	Note that MIDI allows nested messages: the so-called "real-time" MIDI 
	messages can be inserted into the MIDI byte stream at any location, 
	including within a sysex message. MIDI real-time messages are one-byte
	messages used mainly for timing (see the MIDI spec). PortMidi retains 
	the order of non-real-time MIDI messages on both input and output, but 
	it does not specify exactly how real-time messages are processed. This
	is particulary problematic for MIDI input, because the input parser 
	must either prepare to buffer an unlimited number of sysex message 
	bytes or to buffer an unlimited number of real-time messages that 
	arrive embedded in a long sysex message. To simplify things, the input
	parser is allowed to pass real-time MIDI messages embedded within a 
	sysex message, and it is up to the client to detect, process, and 
	remove these messages as they arrive.

	When receiving sysex messages, the sysex message is terminated
	by either an EOX status byte (anywhere in the 4 byte messages) or
	by a non-real-time status byte in the low order byte of the message.
	If you get a non-real-time status byte but there was no EOX byte, it 
	means the sysex message was somehow truncated. This is not
	considered an error; e.g., a missing EOX can result from the user
	disconnecting a MIDI cable during sysex transmission.

	A real-time message can occur within a sysex message. A real-time 
	message will always occupy a full Event with the status byte in 
	the low-order byte of the Event message field. (This implies that
	the byte-order of sysex bytes and real-time message bytes may not
	be preserved -- for example, if a real-time message arrives after
	3 bytes of a sysex message, the real-time message will be delivered
	first. The first word of the sysex message will be delivered only
	after the 4th byte arrives, filling the 4-byte Event message field.

	The timestamp field is observed when the output port is opened with
	a non-zero latency. A timestamp of zero means "use the current time",
	which in turn means to deliver the message with a delay of
	latency (the latency parameter used when opening the output port.)
	Do not expect PortMidi to sort data according to timestamps -- 
	messages should be sent in the correct order, and timestamps MUST 
	be non-decreasing. See also "Example" for OpenOutput() above.

	A sysex message will generally fill many Event structures. On 
	output to a Stream with non-zero latency, the first timestamp
	on sysex message data will determine the time to begin sending the 
	message. PortMidi implementations may ignore timestamps for the 
	remainder of the sysex message. 

	On input, the timestamp ideally denotes the arrival time of the 
	status byte of the message. The first timestamp on sysex message 
	data will be valid. Subsequent timestamps may denote 
	when message bytes were actually received, or they may be simply 
	copies of the first timestamp.

	Timestamps for nested messages: If a real-time message arrives in 
	the middle of some other message, it is enqueued immediately with 
	the timestamp corresponding to its arrival time. The interrupted 
	non-real-time message or 4-byte packet of sysex data will be enqueued 
	later. The timestamp of interrupted data will be equal to that of
	the interrupting real-time message to insure that timestamps are
	non-decreasing.
 */
Event :: struct {
	message:   Message,
	timestamp: Timestamp,
}


@(default_calling_convention="c", link_prefix="Pm_")
foreign lib {
	/**
		Read() retrieves midi data into a buffer, and returns the number
		of events read. Result is a non-negative number unless an error occurs, 
		in which case a Error value will be returned.

		Buffer Overflow

		The problem: if an input overflow occurs, data will be lost, ultimately 
		because there is no flow control all the way back to the data source. 
		When data is lost, the receiver should be notified and some sort of 
		graceful recovery should take place, e.g. you shouldn't resume receiving 
		in the middle of a long sysex message.

		With a lock-free fifo, which is pretty much what we're stuck with to 
		enable portability to the Mac, it's tricky for the producer and consumer 
		to synchronously reset the buffer and resume normal operation.

		Solution: the buffer managed by PortMidi will be flushed when an overflow
		occurs. The consumer (Read()) gets an error message (.BufferOverflow)
		and ordinary processing resumes as soon as a new message arrives. The
		remainder of a partial sysex message is not considered to be a "new
		message" and will be flushed as well.

	*/
	Read :: proc(stream: Stream, buffer: [^]Event, length: i32) -> c.int ---
	
	/**
		Poll() tests whether input is available.
	*/
	Poll       :: proc(stream: Stream) -> Error ---
	
	/** 
		Write() writes midi data from a buffer. This may contain:
			- short messages 
		or 
			- sysex messages that are converted into a sequence of Event
			  structures, e.g. sending data from a file or forwarding them
			  from midi input.

		Use WriteSysEx() to write a sysex message stored as a contiguous 
		array of bytes.

		Sysex data may contain embedded real-time messages.
	*/
	Write :: proc(stream: Stream, buffer: [^]Event, length: i32) -> Error ---
	
	/**
		WriteShort() writes a timestamped non-system-exclusive midi message.
		Messages are delivered in order as received, and timestamps must be 
		non-decreasing. (But timestamps are ignored if the stream was opened
		with latency = 0.)
	*/
	WriteShort :: proc(stream: Stream, whence: Timestamp, msg: Message) -> Error ---
	
	/**
		WriteSysEx() writes a timestamped system-exclusive midi message.
	*/
	WriteSysEx :: proc(stream: Stream, whence: Timestamp, msg: cstring) -> Error ---
}
