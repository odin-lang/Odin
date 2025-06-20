#+build windows
/*
	Bindings for Windows XAudio2:
	https://learn.microsoft.com/en-us/windows/win32/xaudio2/xaudio2-introduction

	Compiling for Windows 10 RS5 (1809) and later
*/

package windows_xaudio2

import win "core:sys/windows"
import "core:math"

foreign import xa2 "system:xaudio2.lib"

HRESULT         :: win.HRESULT
IUnknown        :: win.IUnknown
IUnknown_VTable :: win.IUnknown_VTable
WAVEFORMATEX    :: win.WAVEFORMATEX

/**************************************************************************
 *
 * XAudio2 constants, flags and error codes.
 *
 **************************************************************************/

// Numeric boundary values
MAX_BUFFER_BYTES     :: 0x80000000      // Maximum bytes allowed in a source buffer
MAX_QUEUED_BUFFERS   :: 64              // Maximum buffers allowed in a voice queue
MAX_BUFFERS_SYSTEM   :: 2               // Maximum buffers allowed for system threads (Xbox 360 only)
MAX_AUDIO_CHANNELS   :: 64              // Maximum channels in an audio stream
MIN_SAMPLE_RATE      :: 1000            // Minimum audio sample rate supported
MAX_SAMPLE_RATE      :: 200000          // Maximum audio sample rate supported
MAX_VOLUME_LEVEL     :: 16777216.0      // Maximum acceptable volume level (2^24)
MIN_FREQ_RATIO       :: (1.0 / 1024.0)  // Minimum SetFrequencyRatio argument
MAX_FREQ_RATIO       :: 1024.0          // Maximum MaxFrequencyRatio argument
DEFAULT_FREQ_RATIO   :: 2.0             // Default MaxFrequencyRatio argument
MAX_FILTER_ONEOVERQ  :: 1.5             // Maximum FILTER_PARAMETERS.OneOverQ
MAX_FILTER_FREQUENCY :: 1.0             // Maximum FILTER_PARAMETERS.Frequency
MAX_LOOP_COUNT       :: 254             // Maximum non-infinite BUFFER.LoopCount
MAX_INSTANCES        :: 8               // Maximum simultaneous XAudio2 objects on Xbox 360

// For XMA voices on Xbox 360 there is an additional restriction on the MaxFrequencyRatio argument and the voice's sample rate: the product of these numbers cannot exceed 600000 for one-channel voices or 300000 for voices with more than one channel.
MAX_RATIO_TIMES_RATE_XMA_MONO         :: 600000
MAX_RATIO_TIMES_RATE_XMA_MULTICHANNEL :: 300000

// Numeric values with special meanings
COMMIT_NOW         :: 0             // Used as an OperationSet argument
COMMIT_ALL         :: 0             // Used in IXAudio2.CommitChanges
INVALID_OPSET      :: 0xffffffff    // Not allowed for OperationSet arguments
NO_LOOP_REGION     :: 0             // Used in BUFFER.LoopCount
LOOP_INFINITE      :: 255           // Used in BUFFER.LoopCount
DEFAULT_CHANNELS   :: 0             // Used in CreateMasteringVoice
DEFAULT_SAMPLERATE :: 0             // Used in CreateMasteringVoice

// Flags
FLAGS :: distinct bit_set[FLAG; u32]
FLAG :: enum u32 {
	DEBUG_ENGINE            = 0,    // Used in Create
	VOICE_NOPITCH           = 1,    // Used in IXAudio2.CreateSourceVoice
	VOICE_NOSRC             = 2,    // Used in IXAudio2.CreateSourceVoice
	VOICE_USEFILTER         = 3,    // Used in IXAudio2.CreateSource/SubmixVoice
	PLAY_TAILS              = 5,    // Used in IXAudio2SourceVoice.Stop
	END_OF_STREAM           = 6,    // Used in BUFFER.Flags
	SEND_USEFILTER          = 7,    // Used in SEND_DESCRIPTOR.Flags
	VOICE_NOSAMPLESPLAYED   = 8,    // Used in IXAudio2SourceVoice.GetState
	STOP_ENGINE_WHEN_IDLE   = 13,   // Used in Create to force the engine to Stop when no source voices are Started, and Start when a voice is Started
	QUANTUM_1024            = 15,   // Used in Create to specify nondefault processing quantum of 21.33 ms (1024 samples at 48KHz)
	NO_VIRTUAL_AUDIO_CLIENT = 16,   // Used in CreateMasteringVoice to create a virtual audio client
}

// Default parameters for the built-in filter
DEFAULT_FILTER_TYPE      :: FILTER_TYPE.LowPassFilter
DEFAULT_FILTER_FREQUENCY :: MAX_FILTER_FREQUENCY
DEFAULT_FILTER_ONEOVERQ  :: 1.0

// Internal XAudio2 constants
// The audio frame quantum can be calculated by reducing the fraction:
//     SamplesPerAudioFrame / SamplesPerSecond
QUANTUM_NUMERATOR   :: 1                 // On Windows, XAudio2 processes audio
QUANTUM_DENOMINATOR :: 100               //  in 10ms chunks (= 1/100 seconds)
QUANTUM_MS          :: (1000.0 * QUANTUM_NUMERATOR / QUANTUM_DENOMINATOR)

// XAudio2 error codes
INVALID_CALL         :: HRESULT(-2003435519)    // 0x88960001 An API call or one of its arguments was illegal
XMA_DECODER_ERROR    :: HRESULT(-2003435518)    // 0x88960002 The XMA hardware suffered an unrecoverable error
XAPO_CREATION_FAILED :: HRESULT(-2003435517)    // 0x88960003 XAudio2 failed to initialize an XAPO effect
DEVICE_INVALIDATED   :: HRESULT(-2003435516)    // 0x88960004 An audio device became unusable (unplugged, etc)


/**************************************************************************
 *
 * XAudio2 structures and enumerations.
 *
 **************************************************************************/

// Used in Create, specifies which CPU(s) to use.
PROCESSOR_FLAGS :: distinct bit_set[PROCESSOR_FLAG; u32]
PROCESSOR_FLAG :: enum u32 {
	Processor1  = 0,
	Processor2  = 1,
	Processor3  = 2,
	Processor4  = 3,
	Processor5  = 4,
	Processor6  = 5,
	Processor7  = 6,
	Processor8  = 7,
	Processor9  = 8,
	Processor10 = 9,
	Processor11 = 10,
	Processor12 = 11,
	Processor13 = 12,
	Processor14 = 13,
	Processor15 = 14,
	Processor16 = 15,
	Processor17 = 16,
	Processor18 = 17,
	Processor19 = 18,
	Processor20 = 19,
	Processor21 = 20,
	Processor22 = 21,
	Processor23 = 22,
	Processor24 = 23,
	Processor25 = 24,
	Processor26 = 25,
	Processor27 = 26,
	Processor28 = 27,
	Processor29 = 28,
	Processor30 = 29,
	Processor31 = 30,
	Processor32 = 31,
}
//ANY_PROCESSOR :: 0xffffffff
USE_DEFAULT_PROCESSOR :: PROCESSOR_FLAGS{}

// Returned by IXAudio2Voice.GetVoiceDetails
VOICE_DETAILS :: struct #packed {
	CreatingFlags:   FLAGS,
	ActiveFlags:     FLAGS,
	InputChannels:   u32,
	InputSampleRate: u32,
}

// Used in VOICE_SENDS below
SEND_DESCRIPTOR :: struct #packed {
	Flags:        FLAGS,              // Either 0 or SEND_USEFILTER.
	pOutputVoice: ^IXAudio2Voice,     // This send's destination voice.
}

// Used in the voice creation functions and in IXAudio2Voice.SetOutputVoices
VOICE_SENDS :: struct #packed {
	SendCount: u32,                                      // Number of sends from this voice.
	pSends:    [^]SEND_DESCRIPTOR `fmt:"v,SendCount"`,   // Array of SendCount send descriptors.
}

// Used in EFFECT_CHAIN below
EFFECT_DESCRIPTOR :: struct #packed {
	pEffect:        ^IUnknown,      // Pointer to the effect object's IUnknown interface.
	InitialState:   b32,            // TRUE if the effect should begin in the enabled state.
	OutputChannels: u32,            // How many output channels the effect should produce.
}

// Used in the voice creation functions and in IXAudio2Voice.SetEffectChain
EFFECT_CHAIN :: struct #packed {
	EffectCount:        u32,                                          // Number of effects in this voice's effect chain.
	pEffectDescriptors: [^]EFFECT_DESCRIPTOR `fmt:"v,EffectCount"`,   // Array of effect descriptors.
}

// Used in FILTER_PARAMETERS below
FILTER_TYPE :: enum i32 {
	LowPassFilter,                   // Attenuates frequencies above the cutoff frequency (state-variable filter).
	BandPassFilter,                  // Attenuates frequencies outside a given range      (state-variable filter).
	HighPassFilter,                  // Attenuates frequencies below the cutoff frequency (state-variable filter).
	NotchFilter,                     // Attenuates frequencies inside a given range       (state-variable filter).
	LowPassOnePoleFilter,            // Attenuates frequencies above the cutoff frequency (one-pole filter, FILTER_PARAMETERS.OneOverQ has no effect)
	HighPassOnePoleFilter,           // Attenuates frequencies below the cutoff frequency (one-pole filter, FILTER_PARAMETERS.OneOverQ has no effect)
}

// Used in IXAudio2Voice.Set/GetFilterParameters and Set/GetOutputFilterParameters
FILTER_PARAMETERS :: struct #packed {
	Type:      FILTER_TYPE,         // Filter type.
	Frequency: f32,                 // Filter coefficient. Must be >= 0 and <= MAX_FILTER_FREQUENCY. See CutoffFrequencyToRadians() for state-variable filter types and CutoffFrequencyToOnePoleCoefficient() for one-pole filter types.
	OneOverQ:  f32,                 // Reciprocal of the filter's quality factor Q; must be > 0 and <= MAX_FILTER_ONEOVERQ. Has no effect for one-pole filters.
}

// Used in IXAudio2SourceVoice.SubmitSourceBuffer
BUFFER :: struct #packed {
	Flags:      FLAGS,                                  // Either 0 or END_OF_STREAM.
	AudioBytes: u32,                                    // Size of the audio data buffer in bytes.
	pAudioData: [^]byte `fmt:"v,AudioBytes"`,           // Pointer to the audio data buffer.
	PlayBegin:  u32,                                    // First sample in this buffer to be played.
	PlayLength: u32,                                    // Length of the region to be played in samples, or 0 to play the whole buffer.
	LoopBegin:  u32,                                    // First sample of the region to be looped.
	LoopLength: u32,                                    // Length of the desired loop region in samples, or 0 to loop the entire buffer.
	LoopCount:  u32,                                    // Number of times to repeat the loop region, or LOOP_INFINITE to loop forever.
	pContext:   rawptr,                                 // Context value to be passed back in callbacks.
}

// Used in IXAudio2SourceVoice.SubmitSourceBuffer when submitting XWMA data.
// NOTE: If an XWMA sound is submitted in more than one buffer, each buffer's pDecodedPacketCumulativeBytes[PacketCount-1] value must be subtracted from all the entries in the next buffer's pDecodedPacketCumulativeBytes array.
// And whether a sound is submitted in more than one buffer or not, the final buffer of the sound should use the END_OF_STREAM flag, or else the client must call IXAudio2SourceVoice.Discontinuity after submitting it.
BUFFER_WMA :: struct #packed {
	pDecodedPacketCumulativeBytes: [^]u32 `fmt:"v,PacketCount"`,  // Decoded packet's cumulative size array. Each element is the number of bytes accumulated when the corresponding XWMA packet is decoded in order.  The array must have PacketCount elements.
	PacketCount:                   u32,                           // Number of XWMA packets submitted. Must be >= 1 and divide evenly into BUFFER.AudioBytes.
}

// Returned by IXAudio2SourceVoice.GetState
VOICE_STATE :: struct #packed {
	pCurrentBufferContext: rawptr,      // The pContext value provided in the BUFFER that is currently being processed, or nil if there are no buffers in the queue.
	BuffersQueued:         u32,         // Number of buffers currently queued on the voice (including the one that is being processed).
	SamplesPlayed:         u64,         // Total number of samples produced by the voice since it began processing the current audio stream. If VOICE_NOSAMPLESPLAYED is specified in the call to IXAudio2SourceVoice.GetState, this member will not be calculated, saving CPU.
}

// Returned by IXAudio2.GetPerformanceData
PERFORMANCE_DATA :: struct #packed {
	// CPU usage information
	AudioCyclesSinceLastQuery: u64,     // CPU cycles spent on audio processing since the last call to StartEngine or GetPerformanceData.
	TotalCyclesSinceLastQuery: u64,     // Total CPU cycles elapsed since the last call (only counts the CPU XAudio2 is running on).
	MinimumCyclesPerQuantum:   u32,     // Fewest CPU cycles spent processing any one audio quantum since the last call.
	MaximumCyclesPerQuantum:   u32,     // Most CPU cycles spent processing any one audio quantum since the last call.

	// Memory usage information
	MemoryUsageInBytes: u32,            // Total heap space currently in use.

	// Audio latency and glitching information
	CurrentLatencyInSamples:    u32,    // Minimum delay from when a sample is read from a source buffer to when it reaches the speakers.
	GlitchesSinceEngineStarted: u32,    // Audio dropouts since the engine was started.

	// Data about XAudio2's current workload
	ActiveSourceVoiceCount: u32,        // Source voices currently playing.
	TotalSourceVoiceCount:  u32,        // Source voices currently existing.
	ActiveSubmixVoiceCount: u32,        // Submix voices currently playing/existing.

	ActiveResamplerCount: u32,          // Resample xAPOs currently active.
	ActiveMatrixMixCount: u32,          // MatrixMix xAPOs currently active.

	// Usage of the hardware XMA decoder (Xbox 360 only)
	ActiveXmaSourceVoices: u32,         // Number of source voices decoding XMA data.
	ActiveXmaStreams:      u32,         // A voice can use more than one XMA stream.
}

// Used in IXAudio2.SetDebugConfiguration
DEBUG_CONFIGURATION :: struct #packed {
	TraceMask:       DEBUG_CONFIG_FLAGS,      // Bitmap of enabled debug message types.
	BreakMask:       DEBUG_CONFIG_FLAGS,      // Message types that will break into the debugger.
	LogThreadID:     b32,			  // Whether to log the thread ID with each message.
	LogFileline:     b32,			  // Whether to log the source file and line number.
	LogFunctionName: b32,			  // Whether to log the function name.
	LogTiming:       b32,			  // Whether to log message timestamps.
}

// Values for the TraceMask and BreakMask bitmaps. Only ERRORS and WARNINGS are valid in BreakMask.
// WARNINGS implies ERRORS, DETAIL implies INFO, and FUNC_CALLS implies API_CALLS.
// By default, TraceMask is ERRORS and WARNINGS and all the other settings are zero.
DEBUG_CONFIG_FLAGS :: distinct bit_set[DEBUG_CONFIG_FLAG; u32]
DEBUG_CONFIG_FLAG :: enum u32 {
	ERRORS     = 0,   // For handled errors with serious effects.
	WARNINGS   = 1,   // For handled errors that may be recoverable.
	INFO       = 2,   // Informational chit-chat (e.g. state changes).
	DETAIL     = 3,   // More detailed chit-chat.
	API_CALLS  = 4,   // Public API function entries and exits.
	FUNC_CALLS = 5,   // Internal function entries and exits.
	TIMING     = 6,   // Delays detected and other timing data.
	LOCKS      = 7,   // Usage of critical sections and mutexes.
	MEMORY     = 8,   // Memory heap usage information.
	STREAMING  = 12,  // Audio streaming information.
}

/**************************************************************************
 *
 * IXAudio2: Top-level XAudio2 COM interface.
 *
 **************************************************************************/

IXAudio2_UUID_STRING :: "2B02E3CF-2E0B-4ec3-BE45-1B2A3FE7210D"
IXAudio2_UUID := &win.IID{0x2B02E3CF, 0x2E0B, 0x4ec3, {0xBE, 0x45, 0x1B, 0x2A, 0x3F, 0xE7, 0x21, 0x0D}}
IXAudio2 :: struct #raw_union {
	#subtype iunknown: IUnknown,
	using ixaudio2_vtable: ^IXAudio2_VTable,
}
IXAudio2_VTable :: struct {
	using iunknown_vtable: IUnknown_VTable,

	// NAME: IXAudio2.RegisterForCallbacks
	// DESCRIPTION: Adds a new client to receive XAudio2's engine callbacks.
	// ARGUMENTS:
	//  pCallback - Callback interface to be called during each processing pass.
	RegisterForCallbacks: proc "system" (this: ^IXAudio2, pCallback: ^IXAudio2EngineCallback) -> HRESULT,

	// NAME: IXAudio2.UnregisterForCallbacks
	// DESCRIPTION: Removes an existing receiver of XAudio2 engine callbacks.
	// ARGUMENTS:
	//  pCallback - Previously registered callback interface to be removed.
	UnregisterForCallbacks: proc "system" (this: ^IXAudio2, pCallback: ^IXAudio2EngineCallback),

	// NAME: IXAudio2.CreateSourceVoice
	// DESCRIPTION: Creates and configures a source voice.
	// ARGUMENTS:
	//  ppSourceVoice - Returns the new object's IXAudio2SourceVoice interface.
	//  pSourceFormat - Format of the audio that will be fed to the voice.
	//  Flags - VOICE flags specifying the source voice's behavior.
	//  MaxFrequencyRatio - Maximum SetFrequencyRatio argument to be allowed.
	//  pCallback - Optional pointer to a client-provided callback interface.
	//  pSendList - Optional list of voices this voice should send audio to.
	//  pEffectChain - Optional list of effects to apply to the audio data.
	CreateSourceVoice: proc "system" (this: ^IXAudio2, ppSourceVoice: ^^IXAudio2SourceVoice, pSourceFormat: ^WAVEFORMATEX, Flags: FLAGS = {}, MaxFrequencyRatio: f32 = DEFAULT_FREQ_RATIO, pCallback: ^IXAudio2VoiceCallback = nil, pSendList: [^]VOICE_SENDS = nil, pEffectChain: [^]EFFECT_CHAIN = nil) -> HRESULT,

	// NAME: IXAudio2.CreateSubmixVoice
	// DESCRIPTION: Creates and configures a submix voice.
	// ARGUMENTS:
	//  ppSubmixVoice - Returns the new object's IXAudio2SubmixVoice interface.
	//  InputChannels - Number of channels in this voice's input audio data.
	//  InputSampleRate - Sample rate of this voice's input audio data.
	//  Flags - VOICE flags specifying the submix voice's behavior.
	//  ProcessingStage - Arbitrary number that determines the processing order.
	//  pSendList - Optional list of voices this voice should send audio to.
	//  pEffectChain - Optional list of effects to apply to the audio data.
	CreateSubmixVoice: proc "system" (this: ^IXAudio2, ppSubmixVoice: ^^IXAudio2SubmixVoice, InputChannels: u32, InputSampleRate: u32, Flags: FLAGS = {}, ProcessingStage: u32 = 0, pSendList: [^]VOICE_SENDS = nil, pEffectChain: [^]EFFECT_CHAIN = nil) -> HRESULT,

	// NAME: IXAudio2.CreateMasteringVoice
	// DESCRIPTION: Creates and configures a mastering voice.
	// ARGUMENTS:
	//  ppMasteringVoice - Returns the new object's IXAudio2MasteringVoice interface.
	//  InputChannels - Number of channels in this voice's input audio data.
	//  InputSampleRate - Sample rate of this voice's input audio data.
	//  Flags - VOICE flags specifying the mastering voice's behavior.
	//  szDeviceId - Identifier of the device to receive the output audio.
	//  pEffectChain - Optional list of effects to apply to the audio data.
	//  StreamCategory - The audio stream category to use for this mastering voice
	CreateMasteringVoice: proc "system" (this: ^IXAudio2, ppMasteringVoice: ^^IXAudio2MasteringVoice, InputChannels: u32 = DEFAULT_CHANNELS, InputSampleRate: u32 = DEFAULT_SAMPLERATE, Flags: FLAGS = {}, szDeviceId: win.LPCWSTR = nil, pEffectChain: [^]EFFECT_CHAIN = nil, StreamCategory: AUDIO_STREAM_CATEGORY = .GameEffects) -> HRESULT,

	// NAME: IXAudio2.:StartEngine
	// DESCRIPTION: Creates and starts the audio processing thread.
	StartEngine: proc "system" (this: ^IXAudio2) -> HRESULT,

	// NAME: IXAudio2.StopEngine
	// DESCRIPTION: Stops and destroys the audio processing thread.
	StopEngine: proc "system" (this: ^IXAudio2),

	// NAME: IXAudio2.CommitChanges
	// DESCRIPTION: Atomically applies a set of operations previously tagged with a given identifier.
	// ARGUMENTS:
	//  OperationSet - Identifier of the set of operations to be applied.
	CommitChanges: proc "system" (this: ^IXAudio2, OperationSet: u32) -> HRESULT,

	// NAME: IXAudio2.GetPerformanceData
	// DESCRIPTION: Returns current resource usage details: memory, CPU, etc.
	// ARGUMENTS:
	//  pPerfData - Returns the performance data structure.
	GetPerformanceData: proc "system" (this: ^IXAudio2, pPerfData: ^PERFORMANCE_DATA),

	// NAME: IXAudio2.SetDebugConfiguration
	// DESCRIPTION: Configures XAudio2's debug output (in debug builds only).
	// ARGUMENTS:
	//  pDebugConfiguration - Structure describing the debug output behavior.
	//  pReserved - Optional parameter; must be nil.
	SetDebugConfiguration: proc "system" (this: ^IXAudio2, pDebugConfiguration: ^DEBUG_CONFIGURATION, pReserved: rawptr = nil),
}

// This interface extends IXAudio2 with additional functionality.
// Use IXAudio2.QueryInterface to obtain a pointer to this interface.
IXAudio2Extension_UUID_STRING :: "84ac29bb-d619-44d2-b197-e4acf7df3ed6"
IXAudio2Extension_UUID := &win.IID{0x84ac29bb, 0xd619, 0x44d2, {0xb1, 0x97, 0xe4, 0xac, 0xf7, 0xdf, 0x3e, 0xd6}}
IXAudio2Extension :: struct #raw_union {
	#subtype iunknown: IUnknown,
	using ixaudio2extension_vtable: ^IXAudio2Extension_VTable,
}
IXAudio2Extension_VTable :: struct {
	using iunknown_vtable: IUnknown_VTable,

	// NAME: IXAudio2Extension.GetProcessingQuantum
	// DESCRIPTION: Returns the processing quantum
	//              quantumMilliseconds = (1000.0f * quantumNumerator / quantumDenominator)
	// ARGUMENTS:
	//  quantumNumerator - Quantum numerator
	//  quantumDenominator - Quantum denominator
	GetProcessingQuantum: proc "system" (this: ^IXAudio2Extension, quantumNumerator: ^u32, quantumDenominator: ^u32),

	// NAME: IXAudio2Extension.GetProcessor
	// DESCRIPTION: Returns the number of the processor used by XAudio2
	// ARGUMENTS:
	//  processor - Non-zero Processor number
	GetProcessor: proc "system" (this: ^IXAudio2Extension, processor: ^PROCESSOR_FLAGS),
}

/**************************************************************************
 *
 * IXAudio2Voice: Base voice management interface.
 *
 **************************************************************************/

IXAudio2Voice :: struct {
	using ixaudio2voice_vtable: ^IXAudio2Voice_VTable,
}
IXAudio2Voice_VTable :: struct {
	// NAME: IXAudio2Voice.GetVoiceDetails
	// DESCRIPTION: Returns the basic characteristics of this voice.
	// ARGUMENTS:
	//  pVoiceDetails - Returns the voice's details.
	GetVoiceDetails: proc "system" (this: ^IXAudio2Voice, pVoiceDetails: ^VOICE_DETAILS),

	// NAME: IXAudio2Voice.SetOutputVoices
	// DESCRIPTION: Replaces the set of submix/mastering voices that receive this voice's output.
	// ARGUMENTS:
	//  pSendList - Optional list of voices this voice should send audio to.
	SetOutputVoices: proc "system" (this: ^IXAudio2Voice, pSendList: [^]VOICE_SENDS) -> HRESULT,

	// NAME: IXAudio2Voice.SetEffectChain
	// DESCRIPTION: Replaces this voice's current effect chain with a new one.
	// ARGUMENTS:
	//  pEffectChain - Structure describing the new effect chain to be used.
	SetEffectChain: proc "system" (this: ^IXAudio2Voice, pEffectChain: ^EFFECT_CHAIN) -> HRESULT,

	// NAME: IXAudio2Voice.EnableEffect
	// DESCRIPTION: Enables an effect in this voice's effect chain.
	// ARGUMENTS:
	//  EffectIndex - Index of an effect within this voice's effect chain.
	//  OperationSet - Used to identify this call as part of a deferred batch.
	EnableEffect: proc "system" (this: ^IXAudio2Voice, EffectIndex: u32, OperationSet: u32 = COMMIT_NOW) -> HRESULT,

	// NAME: IXAudio2Voice.DisableEffect
	// DESCRIPTION: Disables an effect in this voice's effect chain.
	// ARGUMENTS:
	//  EffectIndex - Index of an effect within this voice's effect chain.
	//  OperationSet - Used to identify this call as part of a deferred batch.
	DisableEffect: proc "system" (this: ^IXAudio2Voice, EffectIndex: u32, OperationSet: u32 = COMMIT_NOW) -> HRESULT,

	// NAME: IXAudio2Voice.GetEffectState
	// DESCRIPTION: Returns the running state of an effect.
	// ARGUMENTS:
	//  EffectIndex - Index of an effect within this voice's effect chain.
	//  pEnabled - Returns the enabled/disabled state of the given effect.
	GetEffectState: proc "system" (this: ^IXAudio2Voice, EffectIndex: u32, pEnabled: ^b32),

	// NAME: IXAudio2Voice.SetEffectParameters
	// DESCRIPTION: Sets effect-specific parameters.
	// REMARKS: Unlike IXAPOParameters.SetParameters, this method may be called from any thread. XAudio2 implements appropriate synchronization to copy the parameters to the realtime audio processing thread.
	// ARGUMENTS:
	//  EffectIndex - Index of an effect within this voice's effect chain.
	//  pParameters - Pointer to an effect-specific parameters block.
	//  ParametersByteSize - Size of the pParameters array  in bytes.
	//  OperationSet - Used to identify this call as part of a deferred batch.
	SetEffectParameters: proc "system" (this: ^IXAudio2Voice, EffectIndex: u32, pParameters: rawptr, ParametersByteSize: u32, OperationSet: u32 = COMMIT_NOW) -> HRESULT,

	// NAME: IXAudio2Voice.GetEffectParameters
	// DESCRIPTION: Obtains the current effect-specific parameters.
	// ARGUMENTS:
	//  EffectIndex - Index of an effect within this voice's effect chain.
	//  pParameters - Returns the current values of the effect-specific parameters.
	//  ParametersByteSize - Size of the pParameters array in bytes.
	GetEffectParameters: proc "system" (this: ^IXAudio2Voice, EffectIndex: u32, pParameters: rawptr, ParametersByteSize: u32) -> HRESULT,

	// NAME: IXAudio2Voice.SetFilterParameters
	// DESCRIPTION: Sets this voice's filter parameters.
	// ARGUMENTS:
	//  pParameters - Pointer to the filter's parameter structure.
	//  OperationSet - Used to identify this call as part of a deferred batch.
	SetFilterParameters: proc "system" (this: ^IXAudio2Voice, pParameters: ^FILTER_PARAMETERS, OperationSet: u32 = COMMIT_NOW) -> HRESULT,

	// NAME: IXAudio2Voice.GetFilterParameters
	// DESCRIPTION: Returns this voice's current filter parameters.
	// ARGUMENTS:
	//  pParameters - Returns the filter parameters.
	GetFilterParameters: proc "system" (this: ^IXAudio2Voice, pParameters: ^FILTER_PARAMETERS),

	// NAME: IXAudio2Voice.SetOutputFilterParameters
	// DESCRIPTION: Sets the filter parameters on one of this voice's sends.
	// ARGUMENTS:
	//  pDestinationVoice - Destination voice of the send whose filter parameters will be set.
	//  pParameters - Pointer to the filter's parameter structure.
	//  OperationSet - Used to identify this call as part of a deferred batch.
	SetOutputFilterParameters: proc "system" (this: ^IXAudio2Voice, pDestinationVoice: ^IXAudio2Voice, pParameters: ^FILTER_PARAMETERS, OperationSet: u32 = COMMIT_NOW) -> HRESULT,

	// NAME: IXAudio2Voice.GetOutputFilterParameters
	// DESCRIPTION: Returns the filter parameters from one of this voice's sends.
	// ARGUMENTS:
	//  pDestinationVoice - Destination voice of the send whose filter parameters will be read.
	//  pParameters - Returns the filter parameters.
	GetOutputFilterParameters: proc "system" (this: ^IXAudio2Voice, pDestinationVoice: ^IXAudio2Voice, pParameters: ^FILTER_PARAMETERS),

	// NAME: IXAudio2Voice.SetVolume
	// DESCRIPTION: Sets this voice's overall volume level.
	// ARGUMENTS:
	//  Volume - New overall volume level to be used, as an amplitude factor.
	//  OperationSet - Used to identify this call as part of a deferred batch.
	SetVolume: proc "system" (this: ^IXAudio2Voice, Volume: f32, OperationSet: u32 = COMMIT_NOW) -> HRESULT,

	// NAME: IXAudio2Voice.GetVolume
	// DESCRIPTION: Obtains this voice's current overall volume level.
	// ARGUMENTS:
	//  pVolume: Returns the voice's current overall volume level.
	GetVolume: proc "system" (this: ^IXAudio2Voice, pVolume: ^f32),

	// NAME: IXAudio2Voice.SetChannelVolumes
	// DESCRIPTION: Sets this voice's per-channel volume levels.
	// ARGUMENTS:
	//  Channels - Used to confirm the voice's channel count.
	//  pVolumes - Array of per-channel volume levels to be used.
	//  OperationSet - Used to identify this call as part of a deferred batch.
	SetChannelVolumes: proc "system" (this: ^IXAudio2Voice, Channels: u32, pVolumes: [^]f32, OperationSet: u32 = COMMIT_NOW) -> HRESULT,

	// NAME: IXAudio2Voice.GetChannelVolumes
	// DESCRIPTION: Returns this voice's current per-channel volume levels.
	// ARGUMENTS:
	//  Channels - Used to confirm the voice's channel count.
	//  pVolumes - Returns an array of the current per-channel volume levels.
	GetChannelVolumes: proc "system" (this: ^IXAudio2Voice, Channels: u32, pVolumes: [^]f32),

	// NAME: IXAudio2Voice.SetOutputMatrix
	// DESCRIPTION: Sets the volume levels used to mix from each channel of this voice's output audio to each channel of a given destination voice's input audio.
	// ARGUMENTS:
	//  pDestinationVoice - The destination voice whose mix matrix to change.
	//  SourceChannels - Used to confirm this voice's output channel count (the number of channels produced by the last effect in the chain).
	//  DestinationChannels - Confirms the destination voice's input channels.
	//  pLevelMatrix - Array of [SourceChannels * DestinationChannels] send levels. The level used to send from source channel S to destination channel D should be in pLevelMatrix[S + SourceChannels * D].
	//  OperationSet - Used to identify this call as part of a deferred batch.
	SetOutputMatrix: proc "system" (this: ^IXAudio2Voice, pDestinationVoice: ^IXAudio2Voice, SourceChannels: u32, DestinationChannels: u32, pLevelMatrix: [^]f32, OperationSet: u32 = COMMIT_NOW) -> HRESULT,

	// NAME: IXAudio2Voice.GetOutputMatrix
	// DESCRIPTION: Obtains the volume levels used to send each channel of this voice's output audio to each channel of a given destination voice's input audio.
	// ARGUMENTS:
	//  pDestinationVoice - The destination voice whose mix matrix to obtain.
	//  SourceChannels - Used to confirm this voice's output channel count (the number of channels produced by the last effect in the chain).
	//  DestinationChannels - Confirms the destination voice's input channels.
	//  pLevelMatrix - Array of send levels, as above.
	GetOutputMatrix: proc "system" (this: ^IXAudio2Voice, pDestinationVoice: ^IXAudio2Voice, SourceChannels: u32, DestinationChannels: u32, pLevelMatrix: [^]f32),

	// NAME: IXAudio2Voice.DestroyVoice
	// DESCRIPTION: Destroys this voice, stopping it if necessary and removing it from the XAudio2 graph.
	DestroyVoice: proc "system" (this: ^IXAudio2Voice),
}

/**************************************************************************
 *
 * IXAudio2SourceVoice: Source voice management interface.
 *
 **************************************************************************/

IXAudio2SourceVoice :: struct #raw_union {
	#subtype ixaudio2voice: IXAudio2Voice,
	using ixaudio2sourcevoice_vtable: ^IXAudio2SourceVoice_VTable,
}
IXAudio2SourceVoice_VTable :: struct {
	using ixaudio2voice_vtable: IXAudio2Voice_VTable,

	// NAME: IXAudio2SourceVoice.Start
	// DESCRIPTION: Makes this voice start consuming and processing audio.
	// ARGUMENTS:
	//  Flags - Flags controlling how the voice should be started.
	//  OperationSet - Used to identify this call as part of a deferred batch.
	Start: proc "system" (this: ^IXAudio2SourceVoice, Flags: FLAGS = {}, OperationSet: u32 = COMMIT_NOW) -> HRESULT,

	// NAME: IXAudio2SourceVoice.Stop
	// DESCRIPTION: Makes this voice stop consuming audio.
	// ARGUMENTS:
	//  Flags - Flags controlling how the voice should be stopped.
	//  OperationSet - Used to identify this call as part of a deferred batch.
	Stop: proc "system" (this: ^IXAudio2SourceVoice, Flags: FLAGS = {}, OperationSet: u32 = COMMIT_NOW) -> HRESULT,

	// NAME: IXAudio2SourceVoice.SubmitSourceBuffer
	// DESCRIPTION: Adds a new audio buffer to this voice's input queue.
	// ARGUMENTS:
	//  pBuffer - Pointer to the buffer structure to be queued.
	//  pBufferWMA - Additional structure used only when submitting XWMA data.
	SubmitSourceBuffer: proc "system" (this: ^IXAudio2SourceVoice, pBuffer: ^BUFFER, pBufferWMA: ^BUFFER_WMA = nil) -> HRESULT,

	// NAME: IXAudio2SourceVoice.FlushSourceBuffers
	// DESCRIPTION: Removes all pending audio buffers from this voice's queue.
	FlushSourceBuffers: proc "system" (this: ^IXAudio2SourceVoice) -> HRESULT,

	// NAME: IXAudio2SourceVoice.Discontinuity
	// DESCRIPTION: Notifies the voice of an intentional break in the stream of audio buffers (e.g. the end of a sound), to prevent XAudio2 from interpreting an empty buffer queue as a glitch.
	Discontinuity: proc "system" (this: ^IXAudio2SourceVoice) -> HRESULT,

	// NAME: IXAudio2SourceVoice.ExitLoop
	// DESCRIPTION: Breaks out of the current loop when its end is reached.
	// ARGUMENTS:
	//  OperationSet - Used to identify this call as part of a deferred batch.
	ExitLoop: proc "system" (this: ^IXAudio2SourceVoice, OperationSet: u32 = COMMIT_NOW) -> HRESULT,

	// NAME: IXAudio2SourceVoice.GetState
	// DESCRIPTION: Returns the number of buffers currently queued on this voice, the pContext value associated with the currently processing buffer (if any), and other voice state information.
	// ARGUMENTS:
	//  pVoiceState - Returns the state information.
	//  Flags - Flags controlling what voice state is returned.
	GetState: proc "system" (this: ^IXAudio2SourceVoice, pVoiceState: ^VOICE_STATE, Flags: FLAGS = {}),

	// NAME: IXAudio2SourceVoice.SetFrequencyRatio
	// DESCRIPTION: Sets this voice's frequency adjustment, i.e. its pitch.
	// ARGUMENTS:
	//  Ratio - Frequency change, expressed as source frequency / target frequency.
	//  OperationSet - Used to identify this call as part of a deferred batch.
	SetFrequencyRatio: proc "system" (this: ^IXAudio2SourceVoice, Ratio: f32, OperationSet: u32 = COMMIT_NOW) -> HRESULT,

	// NAME: IXAudio2SourceVoice.GetFrequencyRatio
	// DESCRIPTION: Returns this voice's current frequency adjustment ratio.
	// ARGUMENTS:
	//  pRatio - Returns the frequency adjustment.
	GetFrequencyRatio: proc "system" (this: ^IXAudio2SourceVoice, pRatio: ^f32),

	// NAME: IXAudio2SourceVoice.SetSourceSampleRate
	// DESCRIPTION: Reconfigures this voice to treat its source data as being at a different sample rate than the original one specified in CreateSourceVoice's pSourceFormat argument.
	// ARGUMENTS:
	//  UINT32 - The intended sample rate of further submitted source data.
	SetSourceSampleRate: proc "system" (this: ^IXAudio2SourceVoice, NewSourceSampleRate: u32) -> HRESULT,
}

/**************************************************************************
 *
 * IXAudio2SubmixVoice: Submixing voice management interface.
 *
 **************************************************************************/

IXAudio2SubmixVoice :: struct #raw_union {
	#subtype ixaudio2voice: IXAudio2Voice,
	using ixaudio2submixvoice_vtable: ^IXAudio2SubmixVoice_VTable,
}
IXAudio2SubmixVoice_VTable :: struct {
	using ixaudio2voice_vtable: IXAudio2Voice_VTable,
	// There are currently no methods specific to submix voices.
}

 /**************************************************************************
  *
  * IXAudio2MasteringVoice: Mastering voice management interface.
  *
  **************************************************************************/

IXAudio2MasteringVoice :: struct #raw_union {
	#subtype ixaudio2voice: IXAudio2Voice,
	using ixaudio2masteringvoice_vtable: ^IXAudio2MasteringVoice_VTable,
}
IXAudio2MasteringVoice_VTable :: struct {
	using ixaudio2voice_vtable: IXAudio2Voice_VTable,

	// NAME: IXAudio2MasteringVoice.GetChannelMask
	// DESCRIPTION: Returns the channel mask for this voice
	// ARGUMENTS:
	//  pChannelMask - returns the channel mask for this voice.  This corresponds to the dwChannelMask member of WAVEFORMATEXTENSIBLE.
	GetChannelMask: proc "system" (this: ^IXAudio2MasteringVoice, pChannelmask: ^win.DWORD) -> HRESULT,
}

/**************************************************************************
 *
 * IXAudio2EngineCallback: Client notification interface for engine events.
 *
 * REMARKS: Contains methods to notify the client when certain events happen in the XAudio2 engine. This interface should be implemented by the client.
 *          XAudio2 will call these methods via the interface pointer provided by the client when it calls IXAudio2.RegisterForCallbacks.
 *
 **************************************************************************/

IXAudio2EngineCallback :: struct {
	using ixaudio2enginecallback_vtable: ^IXAudio2EngineCallback_VTable,
}
IXAudio2EngineCallback_VTable :: struct {
	// Called by XAudio2 just before an audio processing pass begins.
	OnProcessingPassStart: proc "system" (this: ^IXAudio2EngineCallback),

	// Called just after an audio processing pass ends.
	OnProcessingPassEnd: proc "system" (this: ^IXAudio2EngineCallback),

	// Called in the event of a critical system error which requires XAudio2 to be closed down and restarted. The error code is given in Error.
	OnCriticalError: proc "system" (this: ^IXAudio2EngineCallback, Error: HRESULT),
}

 /**************************************************************************
  *
  * IXAudio2VoiceCallback: Client notification interface for voice events.
  *
  * REMARKS: Contains methods to notify the client when certain events happen in an XAudio2 voice. This interface should be implemented by the client.
  *          XAudio2 will call these methods via an interface pointer provided by the client in the IXAudio2.CreateSourceVoice call.
  *
  **************************************************************************/

IXAudio2VoiceCallback :: struct {
	using ixaudio2voicecallback_vtable: ^IXAudio2VoiceCallback_VTable,
}
IXAudio2VoiceCallback_VTable :: struct {
	// Called just before this voice's processing pass begins.
	OnVoiceProcessingPassStart: proc "system" (this: ^IXAudio2VoiceCallback, BytesRequired: u32),

	// Called just after this voice's processing pass ends.
	OnVoiceProcessingPassEnd: proc "system" (this: ^IXAudio2VoiceCallback),

	// Called when this voice has just finished playing a buffer stream (as marked with the END_OF_STREAM flag on the last buffer).
	OnStreamEnd: proc "system" (this: ^IXAudio2VoiceCallback),

	// Called when this voice is about to start processing a new buffer.
	OnBufferStart: proc "system" (this: ^IXAudio2VoiceCallback, pBufferContext: rawptr),

	// Called when this voice has just finished processing a buffer.
	// The buffer can now be reused or destroyed.
	OnBufferEnd: proc "system" (this: ^IXAudio2VoiceCallback, pBufferContext: rawptr),

	// Called when this voice has just reached the end position of a loop.
	OnLoopEnd: proc "system" (this: ^IXAudio2VoiceCallback, pBufferContext: rawptr),

	// Called in the event of a critical error during voice processing, such as a failing xAPO or an error from the hardware XMA decoder.
	// The voice may have to be destroyed and re-created to recover from the error.
	// The callback arguments report which buffer was being processed when the error occurred, and its HRESULT code.
	OnVoiceError: proc "system" (this: ^IXAudio2VoiceCallback, pBufferContext: rawptr, Error: HRESULT),
}

/**************************************************************************
 *
 * XAudio2Create: Top-level function that creates an XAudio2 instance.
 *
 * ARGUMENTS:
 *
 *  Flags - Flags specifying the XAudio2 object's behavior.
 *
 *  Processor - A PROCESSOR_FLAGS value that specifies the hardware threads (Xbox) or processors (Windows) that XAudio2 will use.
 *          Note that XAudio2 supports concurrent processing on multiple threads, using any combination of PROCESSOR_FLAGS flags.
 *          The values are platform-specific; platform-independent code can use USE_DEFAULT_PROCESSOR to use the default on each platform.
 *
 **************************************************************************/

@(default_calling_convention="system", link_prefix="XAudio2")
foreign xa2 {
	Create :: proc(ppXaudio2: ^^IXAudio2, Flags: FLAGS = {}, Processor: PROCESSOR_FLAGS = {.Processor1}) -> HRESULT ---
}

/**************************************************************************
 *
 * Utility functions used to convert from pitch in semitones and volume in decibels to the frequency and amplitude ratio units used by XAudio2.
 *
 **************************************************************************/

// Calculate the argument to SetVolume from a decibel value
DecibelsToAmplitudeRatio :: #force_inline proc "contextless" (Decibels: f32) -> f32 {
	return math.pow_f32(10.0, Decibels / 20.0)
}

// Recover a volume in decibels from an amplitude factor
AmplitudeRatioToDecibels :: #force_inline proc "contextless" (Volume: f32) -> f32 {
	if Volume == 0 {
		return min(f32)
	}
	return 20.0 * math.log10_f32(Volume)
}

// Calculate the argument to SetFrequencyRatio from a semitone value
SemitonesToFrequencyRatio :: #force_inline proc "contextless" (Semitones: f32) -> f32 {
	// FrequencyRatio = 2 ^ Octaves
	//                = 2 ^ (Semitones / 12)
	return math.pow_f32(2.0, Semitones / 12.0)
}

// Recover a pitch in semitones from a frequency ratio
FrequencyRatioToSemitones :: #force_inline proc "contextless" (FrequencyRatio: f32) -> f32 {
	// Semitones = 12 * log2(FrequencyRatio)
	//           = 12 * log2(10) * log10(FrequencyRatio)
	return 12.0 * math.log2_f32(FrequencyRatio)
}

// Convert from filter cutoff frequencies expressed in Hertz to the radian frequency values used in FILTER_PARAMETERS.Frequency, state-variable filter types only.
// Use CutoffFrequencyToOnePoleCoefficient() for one-pole filter types.
// Note that the highest CutoffFrequency supported is SampleRate/6.
// Higher values of CutoffFrequency will return MAX_FILTER_FREQUENCY.
CutoffFrequencyToRadians :: #force_inline proc "contextless" (CutoffFrequency: f32, SampleRate: u32) -> f32 {
	if u32(CutoffFrequency * 6.0) >= SampleRate {
		return MAX_FILTER_FREQUENCY
	}
	return 2.0 * math.sin_f32(math.PI * CutoffFrequency / f32(SampleRate))
}

// Convert from radian frequencies back to absolute frequencies in Hertz
RadiansToCutoffFrequency :: #force_inline proc "contextless" (Radians: f32, SampleRate: f32) -> f32 {
	return SampleRate * math.asin_f32(Radians / 2.0) / math.PI
}

// Convert from filter cutoff frequencies expressed in Hertz to the filter coefficients used with FILTER_PARAMETERS.Frequency,
// LowPassOnePoleFilter and HighPassOnePoleFilter filter types only.
// Use CutoffFrequencyToRadians() for state-variable filter types.
CutoffFrequencyToOnePoleCoefficient :: #force_inline proc "contextless" (CutoffFrequency: f32, SampleRate: u32) -> f32 {
	if u32(CutoffFrequency) >= SampleRate {
		return MAX_FILTER_FREQUENCY
	}
	return 1.0 - math.pow_f32(1.0 - 2.0 * CutoffFrequency / f32(SampleRate), 2.0)
}

//-------------------------------------------------------------------------
// Description: Audio stream categories
//
// Other                   - All other streams (default)
// ForegroundOnlyMedia     - (deprecated for Win10) Music, Streaming audio
// BackgroundCapableMedia  - (deprecated for Win10) Video with audio
// Communications          - VOIP, chat, phone call
// Alerts                  - Alarm, Ring tones
// SoundEffects            - Sound effects, clicks, dings
// GameEffects             - Game sound effects
// GameMedia               - Background audio for games
// GameChat                - In game player chat
// Speech                  - Speech recognition
// Media                   - Music, Streaming audio
// Movie                   - Video with audio
// FarFieldSpeech          - Capture of far field speech
// UniformSpeech           - Uniform, device agnostic speech processing
// VoiceTyping             - Dictation, typing by voice
//
AUDIO_STREAM_CATEGORY :: enum i32 {
	Other          = 0,
	//ForegroundOnlyMedia = 1,
	//BackgroundCapableMedia = 2,
	Communications = 3,
	Alerts         = 4,
	SoundEffects   = 5,
	GameEffects    = 6,
	GameMedia      = 7,
	GameChat       = 8,
	Speech         = 9,
	Movie          = 10,
	Media          = 11,
	FarFieldSpeech = 12,
	UniformSpeech  = 13,
	VoiceTyping    = 14,
}
