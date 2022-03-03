package miniaudio

import "core:c"

when ODIN_OS == .Windows {
	foreign import lib "lib/miniaudio.lib"
} else when ODIN_OS == .Linux {
	foreign import lib "lib/miniaudio.a"
} else {
	foreign import lib "system:miniaudio"
}

handle :: distinct rawptr


/* SIMD alignment in bytes. Currently set to 64 bytes in preparation for future AVX-512 optimizations. */
SIMD_ALIGNMENT :: 64

LOG_LEVEL_DEBUG   :: 4
LOG_LEVEL_INFO    :: 3
LOG_LEVEL_WARNING :: 2
LOG_LEVEL_ERROR   :: 1


channel :: enum u8 {
	NONE                                = 0,
	MONO                                = 1,
	FRONT_LEFT                          = 2,
	FRONT_RIGHT                         = 3,
	FRONT_CENTER                        = 4,
	LFE                                 = 5,
	BACK_LEFT                           = 6,
	BACK_RIGHT                          = 7,
	FRONT_LEFT_CENTER                   = 8,
	FRONT_RIGHT_CENTER                  = 9,
	BACK_CENTER                         = 10,
	SIDE_LEFT                           = 11,
	SIDE_RIGHT                          = 12,
	TOP_CENTER                          = 13,
	TOP_FRONT_LEFT                      = 14,
	TOP_FRONT_CENTER                    = 15,
	TOP_FRONT_RIGHT                     = 16,
	TOP_BACK_LEFT                       = 17,
	TOP_BACK_CENTER                     = 18,
	TOP_BACK_RIGHT                      = 19,
	AUX_0                               = 20,
	AUX_1                               = 21,
	AUX_2                               = 22,
	AUX_3                               = 23,
	AUX_4                               = 24,
	AUX_5                               = 25,
	AUX_6                               = 26,
	AUX_7                               = 27,
	AUX_8                               = 28,
	AUX_9                               = 29,
	AUX_10                              = 30,
	AUX_11                              = 31,
	AUX_12                              = 32,
	AUX_13                              = 33,
	AUX_14                              = 34,
	AUX_15                              = 35,
	AUX_16                              = 36,
	AUX_17                              = 37,
	AUX_18                              = 38,
	AUX_19                              = 39,
	AUX_20                              = 40,
	AUX_21                              = 41,
	AUX_22                              = 42,
	AUX_23                              = 43,
	AUX_24                              = 44,
	AUX_25                              = 45,
	AUX_26                              = 46,
	AUX_27                              = 47,
	AUX_28                              = 48,
	AUX_29                              = 49,
	AUX_30                              = 50,
	AUX_31                              = 51,
	LEFT                                = FRONT_LEFT,
	RIGHT                               = FRONT_RIGHT,
	POSITION_COUNT                      = AUX_31 + 1,
}

result :: enum c.int {
	SUCCESS                                     =  0,
	ERROR                                       = -1,   /* A generic error. */
	INVALID_ARGS                                = -2,
	INVALID_OPERATION                           = -3,
	OUT_OF_MEMORY                               = -4,
	OUT_OF_RANGE                                = -5,
	ACCESS_DENIED                               = -6,
	DOES_NOT_EXIST                              = -7,
	ALREADY_EXISTS                              = -8,
	TOO_MANY_OPEN_FILES                         = -9,
	INVALID_FILE                                = -10,
	TOO_BIG                                     = -11,
	PATH_TOO_LONG                               = -12,
	NAME_TOO_LONG                               = -13,
	NOT_DIRECTORY                               = -14,
	IS_DIRECTORY                                = -15,
	DIRECTORY_NOT_EMPTY                         = -16,
	AT_END                                      = -17,
	NO_SPACE                                    = -18,
	BUSY                                        = -19,
	IO_ERROR                                    = -20,
	INTERRUPT                                   = -21,
	UNAVAILABLE                                 = -22,
	ALREADY_IN_USE                              = -23,
	BAD_ADDRESS                                 = -24,
	BAD_SEEK                                    = -25,
	BAD_PIPE                                    = -26,
	DEADLOCK                                    = -27,
	TOO_MANY_LINKS                              = -28,
	NOT_IMPLEMENTED                             = -29,
	NO_MESSAGE                                  = -30,
	BAD_MESSAGE                                 = -31,
	NO_DATA_AVAILABLE                           = -32,
	INVALID_DATA                                = -33,
	TIMEOUT                                     = -34,
	NO_NETWORK                                  = -35,
	NOT_UNIQUE                                  = -36,
	NOT_SOCKET                                  = -37,
	NO_ADDRESS                                  = -38,
	BAD_PROTOCOL                                = -39,
	PROTOCOL_UNAVAILABLE                        = -40,
	PROTOCOL_NOT_SUPPORTED                      = -41,
	PROTOCOL_FAMILY_NOT_SUPPORTED               = -42,
	ADDRESS_FAMILY_NOT_SUPPORTED                = -43,
	SOCKET_NOT_SUPPORTED                        = -44,
	CONNECTION_RESET                            = -45,
	ALREADY_CONNECTED                           = -46,
	NOT_CONNECTED                               = -47,
	CONNECTION_REFUSED                          = -48,
	NO_HOST                                     = -49,
	IN_PROGRESS                                 = -50,
	CANCELLED                                   = -51,
	MEMORY_ALREADY_MAPPED                       = -52,

	/* General miniaudio-specific errors. */
	FORMAT_NOT_SUPPORTED                        = -100,
	DEVICE_TYPE_NOT_SUPPORTED                   = -101,
	SHARE_MODE_NOT_SUPPORTED                    = -102,
	NO_BACKEND                                  = -103,
	NO_DEVICE                                   = -104,
	API_NOT_FOUND                               = -105,
	INVALID_DEVICE_CONFIG                       = -106,
	LOOP                                        = -107,

	/* State errors. */
	DEVICE_NOT_INITIALIZED                      = -200,
	DEVICE_ALREADY_INITIALIZED                  = -201,
	DEVICE_NOT_STARTED                          = -202,
	DEVICE_NOT_STOPPED                          = -203,

	/* Operation errors. */
	FAILED_TO_INIT_BACKEND                      = -300,
	FAILED_TO_OPEN_BACKEND_DEVICE               = -301,
	FAILED_TO_START_BACKEND_DEVICE              = -302,
	FAILED_TO_STOP_BACKEND_DEVICE               = -303,
} 

MIN_CHANNELS :: 1
MAX_CHANNELS :: 32

MAX_FILTER_ORDER :: 8



stream_format :: enum c.int {
	pcm = 0,
}

stream_layout :: enum c.int {
	interleaved = 0,
	deinterleaved,
}

dither_mode :: enum c.int {
    	none = 0,
    	rectangle,
    	triangle,
}

format :: enum c.int {
	/*
	I like to keep these explicitly defined because they're used as a key into a lookup table. When items are
	added to this, make sure there are no gaps and that they're added to the lookup table in ma_get_bytes_per_sample().
	*/
	unknown = 0,     /* Mainly used for indicating an error, but also used as the default for the output format for decoders. */
	u8      = 1,
	s16     = 2,     /* Seems to be the most widely supported format. */
	s24     = 3,     /* Tightly packed. 3 bytes per sample. */
	s32     = 4,
	f32     = 5,
}

standard_sample_rate :: enum u32 {
	/* Standard rates need to be in priority order. */
	rate_48000  = 48000,     /* Most common */
	rate_44100  = 44100,

	rate_32000  = 32000,     /* Lows */
	rate_24000  = 24000,
	rate_22050  = 22050,

	rate_88200  = 88200,     /* Highs */
	rate_96000  = 96000,
	rate_176400 = 176400,
	rate_192000 = 192000,

	rate_16000  = 16000,     /* Extreme lows */
	rate_11025  = 11250,
	rate_8000   = 8000,

	rate_352800 = 352800,    /* Extreme highs */
	rate_384000 = 384000,

	rate_min    = rate_8000,
	rate_max    = rate_384000,
	rate_count  = 14,        /* Need to maintain the count manually. Make sure this is updated if items are added to enum. */
}


channel_mix_mode :: enum c.int {
	rectangular = 0,   /* Simple averaging based on the plane(s) the channel is sitting on. */
	simple,            /* Drop excess channels; zeroed out extra channels. */
	custom_weights,    /* Use custom weights specified in ma_channel_router_config. */
	planar_blend = rectangular,
	default = rectangular,
}

standard_channel_map :: enum c.int {
	microsoft,
	alsa,
	rfc3551,   /* Based off AIFF. */
	flac,
	vorbis,
	sound4,    /* FreeBSD's sound(4). */
	sndio,     /* www.sndio.org/tips.html */
	webaudio = flac, /* https://webaudio.github.io/web-audio-api/#ChannelOrdering. Only 1, 2, 4 and 6 channels are defined, but can fill in the gaps with logical assumptions. */
	default = microsoft,
}

performance_profile :: enum c.int {
	low_latency = 0,
	conservative,
}


allocation_callbacks :: struct {
	pUserData: rawptr,
	onMalloc:  proc "c" (sz: c.size_t, pUserData: rawptr) -> rawptr,
	onRealloc: proc "c" (p: rawptr, sz: c.size_t, pUserData: rawptr) -> rawptr,
	onFree:    proc "c" (p: rawptr, pUserData: rawptr),
}

lcg :: struct {
	state: i32,
}

NO_THREADING :: false

when !NO_THREADING {
/* Thread priorities should be ordered such that the default priority of the worker thread is 0. */
thread_priority :: enum c.int {
	idle     = -5,
	lowest   = -4,
	low      = -3,
	normal   = -2,
	high     = -1,
	highest  =  0,
	realtime =  1,
	default  =  0,
}

/* Spinlocks are 32-bit for compatibility reasons. */
spinlock :: distinct u32

when ODIN_OS == .Windows {
	thread    :: distinct rawptr
	mutex     :: distinct rawptr
	event     :: distinct rawptr
	semaphore :: distinct rawptr
} else {
	import "core:sys/unix"
	
	thread :: unix.pthread_t
	mutex :: unix.pthread_mutex_t
	event :: struct {
		value: u32,
		lock: unix.pthread_mutex_t,
		cond: unix.pthread_cond_t,
	}
	semaphore :: struct {
		value: c.int,
		lock: unix.pthread_mutex_t,
		cond: unix.pthread_cond_t,
	}
}

	
@(default_calling_convention="c", link_prefix="ma_")
foreign lib {
	/*
	Locks a spinlock.
	*/
	spinlock_lock :: proc(/*volatile*/ pSpinlock: ^spinlock) -> result ---

	/*
	Locks a spinlock, but does not yield() when looping.
	*/
	spinlock_lock_noyield :: proc(/*volatile*/ pSpinlock: ^spinlock) -> result ---

	/*
	Unlocks a spinlock.
	*/
	spinlock_unlock :: proc(/*volatile*/ pSpinlock: ^spinlock) -> result ---


	/*
	Creates a mutex.

	A mutex must be created from a valid context. A mutex is initially unlocked.
	*/
	mutex_init :: proc(pMutex: ^mutex) -> result ---

	/*
	Deletes a mutex.
	*/
	mutex_uninit :: proc(pMutex: ^mutex) ---

	/*
	Locks a mutex with an infinite timeout.
	*/
	mutex_lock :: proc(pMutex: ^mutex) ---

	/*
	Unlocks a mutex.
	*/
	mutex_unlock :: proc(pMutex: ^mutex) ---


	/*
	Initializes an auto-reset event.
	*/
	event_init :: proc(pEvent: ^event) -> result ---

	/*
	Uninitializes an auto-reset event.
	*/
	event_uninit :: proc(pEvent: ^event) ---

	/*
	Waits for the specified auto-reset event to become signalled.
	*/
	event_wait :: proc(pEvent: ^event) -> result ---

	/*
	Signals the specified auto-reset event.
	*/
	event_signal :: proc(pEvent: ^event) -> result ---
}

}  /* NO_THREADING */


@(default_calling_convention="c", link_prefix="ma_")
foreign lib {
	version :: proc(pMajor, pMinor, pRevision: ^u32) ---
	version_string :: proc() -> cstring ---
}



/************************************************************************************************************************************************************

Miscellaneous Helpers

************************************************************************************************************************************************************/

@(default_calling_convention="c", link_prefix="ma_")
foreign lib {
	/*
	Retrieves a human readable description of the given result code.
	*/
	result_description :: proc(result: result) -> cstring ---

	/*
	malloc(). Calls MA_MALLOC().
	*/
	malloc :: proc(sz: c.size_t, pAllocationCallbacks: ^allocation_callbacks) -> rawptr ---

	/*
	realloc(). Calls MA_REALLOC().
	*/
	realloc :: proc(p: rawptr, sz: c.size_t, pAllocationCallbacks: ^allocation_callbacks) -> rawptr ---

	/*
	free(). Calls MA_FREE().
	*/
	free :: proc(p: rawptr, pAllocationCallbacks: ^allocation_callbacks) ---

	/*
	Performs an aligned malloc, with the assumption that the alignment is a power of 2.
	*/
	aligned_malloc :: proc(sz, alignment: c.size_t, pAllocationCallbacks: ^allocation_callbacks) -> rawptr ---

	/*
	Free's an aligned malloc'd buffer.
	*/
	aligned_free :: proc(p: rawptr, pAllocationCallbacks: ^allocation_callbacks) ---

	/*
	Retrieves a friendly name for a format.
	*/
	get_format_name :: proc(format: format) -> cstring ---

	/*
	Blends two frames in floating point format.
	*/
	blend_f32 :: proc(pOut, pInA, pInB: ^f32, factor: f32, channels: u32) ---

	/*
	Retrieves the size of a sample in bytes for the given format.

	This API is efficient and is implemented using a lookup table.

	Thread Safety: SAFE
	  This API is pure.
	*/
	get_bytes_per_sample :: proc(format: format) -> u32 ---

	/*
	Converts a log level to a string.
	*/
	log_level_to_string :: proc(logLevel: u32) -> cstring ---
}

get_bytes_per_frame :: #force_inline proc "c" (format: format, channels: u32) -> u32 { return get_bytes_per_sample(format) * channels }
