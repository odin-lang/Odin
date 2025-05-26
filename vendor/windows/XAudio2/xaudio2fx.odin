#+build windows

package windows_xaudio2

import "core:math"

foreign import xa2 "system:xaudio2.lib"

/**************************************************************************
 *
 * Effect creation functions.
 *
 * On Xbox the application can link with the debug library to use the debug functionality.
 *
 **************************************************************************/

@(default_calling_convention="system")
foreign xa2 {
	CreateAudioVolumeMeter :: proc(ppApo: ^^IUnknown) -> HRESULT ---
	CreateAudioReverb      :: proc(ppApo: ^^IUnknown) -> HRESULT ---
}

/**************************************************************************
 *
 * Volume meter parameters.
 * The volume meter supports f32 audio formats and must be used in-place.
 *
 **************************************************************************/

// VOLUMEMETER_LEVELS: Receives results from GetEffectParameters().
// The user is responsible for allocating pPeakLevels, pRMSLevels, and initializing ChannelCount accordingly.
// The volume meter does not support SetEffectParameters().
VOLUMEMETER_LEVELS :: struct #packed {
	pPeakLevels:  [^]f32 `fmt:"v,ChannelCount"`,   // Peak levels table: receives maximum absolute level for each channel over a processing pass, may be nil if pRMSLevls != nil, otherwise must have at least ChannelCount elements.
	pRMSLevels:   [^]f32 `fmt:"v,ChannelCount"`,   // Root mean square levels table: receives RMS level for each channel over a processing pass, may be nil if pPeakLevels != nil, otherwise must have at least ChannelCount elements.
	ChannelCount: u32, 	                           // Number of channels being processed by the volume meter APO
}

/**************************************************************************
 *
 * Reverb parameters.
 * The reverb supports only f32 audio with the following channel configurations:
 *     Input: Mono   Output: Mono
 *     Input: Mono   Output: 5.1
 *     Input: Stereo Output: Stereo
 *     Input: Stereo Output: 5.1
 * The framerate must be within [20000, 48000] Hz.
 *
 * When using mono input, delay filters associated with the right channel are not executed.
 * In this case, parameters such as PositionRight and PositionMatrixRight have no effect.
 * This also means the reverb uses less CPU when hosted in a mono submix.
 *
 **************************************************************************/

REVERB_MIN_FRAMERATE :: 20000
REVERB_MAX_FRAMERATE :: 48000

// REVERB_PARAMETERS: Native parameter set for the reverb effect

REVERB_PARAMETERS :: struct #packed {
	// ratio of wet (processed) signal to dry (original) signal
	WetDryMix: f32,               // [0, 100] (percentage)
	// Delay times
	ReflectionsDelay: u32,        // [0, 300] in ms
	ReverbDelay:      byte,       // [0, 85] in ms
	RearDelay:        byte,       // 7.1: [0, 20] in ms, all other: [0, 5] in ms
	SideDelay:        byte,       // 7.1: [0, 5] in ms, all other: not used, but still validated
	// Indexed parameters
	PositionLeft:        byte,    // [0, 30] no units
	PositionRight:       byte,    // [0, 30] no units, ignored when configured to mono
	PositionMatrixLeft:  byte,    // [0, 30] no units
	PositionMatrixRight: byte,    // [0, 30] no units, ignored when configured to mono
	EarlyDiffusion:      byte,    // [0, 15] no units
	LateDiffusion:       byte,    // [0, 15] no units
	LowEQGain:           byte,    // [0, 12] no units
	LowEQCutoff:         byte,    // [0, 9] no units
	HighEQGain:          byte,    // [0, 8] no units
	HighEQCutoff:        byte,    // [0, 14] no units
	// Direct parameters
	RoomFilterFreq:  f32,         // [20, 20000] in Hz
	RoomFilterMain:  f32,         // [-100, 0] in dB
	RoomFilterHF:    f32,         // [-100, 0] in dB
	ReflectionsGain: f32,         // [-100, 20] in dB
	ReverbGain:      f32,         // [-100, 20] in dB
	DecayTime:       f32,         // [0.1, inf] in seconds
	Density:         f32,         // [0, 100] (percentage)
	RoomSize:        f32,         // [1, 100] in feet
	// component control
	DisableLateField: b32,        // true to disable late field reflections
}

// Maximum, minimum and default values for the parameters above
REVERB_MIN_WET_DRY_MIX        :: 0.0
REVERB_MIN_REFLECTIONS_DELAY  :: 0
REVERB_MIN_REVERB_DELAY       :: 0
REVERB_MIN_REAR_DELAY         :: 0
REVERB_MIN_7POINT1_SIDE_DELAY :: 0
REVERB_MIN_7POINT1_REAR_DELAY :: 0
REVERB_MIN_POSITION           :: 0
REVERB_MIN_DIFFUSION          :: 0
REVERB_MIN_LOW_EQ_GAIN        :: 0
REVERB_MIN_LOW_EQ_CUTOFF      :: 0
REVERB_MIN_HIGH_EQ_GAIN       :: 0
REVERB_MIN_HIGH_EQ_CUTOFF     :: 0
REVERB_MIN_ROOM_FILTER_FREQ   :: 20.0
REVERB_MIN_ROOM_FILTER_MAIN   :: -100.0
REVERB_MIN_ROOM_FILTER_HF     :: -100.0
REVERB_MIN_REFLECTIONS_GAIN   :: -100.0
REVERB_MIN_REVERB_GAIN        :: -100.0
REVERB_MIN_DECAY_TIME         :: 0.1
REVERB_MIN_DENSITY            :: 0.0
REVERB_MIN_ROOM_SIZE          :: 0.0

REVERB_MAX_WET_DRY_MIX        :: 100.0
REVERB_MAX_REFLECTIONS_DELAY  :: 300
REVERB_MAX_REVERB_DELAY       :: 85
REVERB_MAX_REAR_DELAY         :: 5
REVERB_MAX_7POINT1_SIDE_DELAY :: 5
REVERB_MAX_7POINT1_REAR_DELAY :: 20
REVERB_MAX_POSITION           :: 30
REVERB_MAX_DIFFUSION          :: 15
REVERB_MAX_LOW_EQ_GAIN        :: 12
REVERB_MAX_LOW_EQ_CUTOFF      :: 9
REVERB_MAX_HIGH_EQ_GAIN       :: 8
REVERB_MAX_HIGH_EQ_CUTOFF     :: 14
REVERB_MAX_ROOM_FILTER_FREQ   :: 20000.0
REVERB_MAX_ROOM_FILTER_MAIN   :: 0.0
REVERB_MAX_ROOM_FILTER_HF     :: 0.0
REVERB_MAX_REFLECTIONS_GAIN   :: 20.0
REVERB_MAX_REVERB_GAIN        :: 20.0
REVERB_MAX_DENSITY            :: 100.0
REVERB_MAX_ROOM_SIZE          :: 100.0

REVERB_DEFAULT_WET_DRY_MIX        :: 100.0
REVERB_DEFAULT_REFLECTIONS_DELAY  :: 5
REVERB_DEFAULT_REVERB_DELAY       :: 5
REVERB_DEFAULT_REAR_DELAY         :: 5
REVERB_DEFAULT_7POINT1_SIDE_DELAY :: 5
REVERB_DEFAULT_7POINT1_REAR_DELAY :: 20
REVERB_DEFAULT_POSITION           :: 6
REVERB_DEFAULT_POSITION_MATRIX    :: 27
REVERB_DEFAULT_EARLY_DIFFUSION    :: 8
REVERB_DEFAULT_LATE_DIFFUSION     :: 8
REVERB_DEFAULT_LOW_EQ_GAIN        :: 8
REVERB_DEFAULT_LOW_EQ_CUTOFF      :: 4
REVERB_DEFAULT_HIGH_EQ_GAIN       :: 8
REVERB_DEFAULT_HIGH_EQ_CUTOFF     :: 4
REVERB_DEFAULT_ROOM_FILTER_FREQ   :: 5000.0
REVERB_DEFAULT_ROOM_FILTER_MAIN   :: 0.0
REVERB_DEFAULT_ROOM_FILTER_HF     :: 0.0
REVERB_DEFAULT_REFLECTIONS_GAIN   :: 0.0
REVERB_DEFAULT_REVERB_GAIN        :: 0.0
REVERB_DEFAULT_DECAY_TIME         :: 1.0
REVERB_DEFAULT_DENSITY            :: 100.0
REVERB_DEFAULT_ROOM_SIZE          :: 100.0

REVERB_DEFAULT_DISABLE_LATE_FIELD: b32 : false

// REVERB_I3DL2_PARAMETERS: Parameter set compliant with the I3DL2 standard

REVERB_I3DL2_PARAMETERS :: struct #packed {
	// ratio of wet (processed) signal to dry (original) signal
	WetDryMix: f32,            // [0, 100] (percentage)

	// Standard I3DL2 parameters
	Room:              i32,    // [-10000, 0] in mB (hundredths of decibels)
	RoomHF:            i32,    // [-10000, 0] in mB (hundredths of decibels)
	RoomRolloffFactor: f32,    // [0.0, 10.0]
	DecayTime:         f32,    // [0.1, 20.0] in seconds
	DecayHFRatio:      f32,    // [0.1, 2.0]
	Reflections:       i32,    // [-10000, 1000] in mB (hundredths of decibels)
	ReflectionsDelay:  f32,    // [0.0, 0.3] in seconds
	Reverb:            i32,    // [-10000, 2000] in mB (hundredths of decibels)
	ReverbDelay:       f32,    // [0.0, 0.1] in seconds
	Diffusion:         f32,    // [0.0, 100.0] (percentage)
	Density:           f32,    // [0.0, 100.0] (percentage)
	HFReference:       f32,    // [20.0, 20000.0] in Hz
}

/**************************************************************************
 *
 * Standard I3DL2 reverb presets (100% wet).
 *
 **************************************************************************/

I3DL2_PRESET_DEFAULT         := REVERB_I3DL2_PARAMETERS{100.0,-10000,    0,0.0, 1.00,0.50,-10000,0.020,-10000,0.040,100.0,100.0,5000.0}
I3DL2_PRESET_GENERIC         := REVERB_I3DL2_PARAMETERS{100.0, -1000, -100,0.0, 1.49,0.83, -2602,0.007,   200,0.011,100.0,100.0,5000.0}
I3DL2_PRESET_PADDEDCELL      := REVERB_I3DL2_PARAMETERS{100.0, -1000,-6000,0.0, 0.17,0.10, -1204,0.001,   207,0.002,100.0,100.0,5000.0}
I3DL2_PRESET_ROOM            := REVERB_I3DL2_PARAMETERS{100.0, -1000, -454,0.0, 0.40,0.83, -1646,0.002,    53,0.003,100.0,100.0,5000.0}
I3DL2_PRESET_BATHROOM        := REVERB_I3DL2_PARAMETERS{100.0, -1000,-1200,0.0, 1.49,0.54,  -370,0.007,  1030,0.011,100.0, 60.0,5000.0}
I3DL2_PRESET_LIVINGROOM      := REVERB_I3DL2_PARAMETERS{100.0, -1000,-6000,0.0, 0.50,0.10, -1376,0.003, -1104,0.004,100.0,100.0,5000.0}
I3DL2_PRESET_STONEROOM       := REVERB_I3DL2_PARAMETERS{100.0, -1000, -300,0.0, 2.31,0.64,  -711,0.012,    83,0.017,100.0,100.0,5000.0}
I3DL2_PRESET_AUDITORIUM      := REVERB_I3DL2_PARAMETERS{100.0, -1000, -476,0.0, 4.32,0.59,  -789,0.020,  -289,0.030,100.0,100.0,5000.0}
I3DL2_PRESET_CONCERTHALL     := REVERB_I3DL2_PARAMETERS{100.0, -1000, -500,0.0, 3.92,0.70, -1230,0.020,    -2,0.029,100.0,100.0,5000.0}
I3DL2_PRESET_CAVE            := REVERB_I3DL2_PARAMETERS{100.0, -1000,    0,0.0, 2.91,1.30,  -602,0.015,  -302,0.022,100.0,100.0,5000.0}
I3DL2_PRESET_ARENA           := REVERB_I3DL2_PARAMETERS{100.0, -1000, -698,0.0, 7.24,0.33, -1166,0.020,    16,0.030,100.0,100.0,5000.0}
I3DL2_PRESET_HANGAR          := REVERB_I3DL2_PARAMETERS{100.0, -1000,-1000,0.0,10.05,0.23,  -602,0.020,   198,0.030,100.0,100.0,5000.0}
I3DL2_PRESET_CARPETEDHALLWAY := REVERB_I3DL2_PARAMETERS{100.0, -1000,-4000,0.0, 0.30,0.10, -1831,0.002, -1630,0.030,100.0,100.0,5000.0}
I3DL2_PRESET_HALLWAY         := REVERB_I3DL2_PARAMETERS{100.0, -1000, -300,0.0, 1.49,0.59, -1219,0.007,   441,0.011,100.0,100.0,5000.0}
I3DL2_PRESET_STONECORRIDOR   := REVERB_I3DL2_PARAMETERS{100.0, -1000, -237,0.0, 2.70,0.79, -1214,0.013,   395,0.020,100.0,100.0,5000.0}
I3DL2_PRESET_ALLEY           := REVERB_I3DL2_PARAMETERS{100.0, -1000, -270,0.0, 1.49,0.86, -1204,0.007,    -4,0.011,100.0,100.0,5000.0}
I3DL2_PRESET_FOREST          := REVERB_I3DL2_PARAMETERS{100.0, -1000,-3300,0.0, 1.49,0.54, -2560,0.162,  -613,0.088, 79.0,100.0,5000.0}
I3DL2_PRESET_CITY            := REVERB_I3DL2_PARAMETERS{100.0, -1000, -800,0.0, 1.49,0.67, -2273,0.007, -2217,0.011, 50.0,100.0,5000.0}
I3DL2_PRESET_MOUNTAINS       := REVERB_I3DL2_PARAMETERS{100.0, -1000,-2500,0.0, 1.49,0.21, -2780,0.300, -2014,0.100, 27.0,100.0,5000.0}
I3DL2_PRESET_QUARRY          := REVERB_I3DL2_PARAMETERS{100.0, -1000,-1000,0.0, 1.49,0.83,-10000,0.061,   500,0.025,100.0,100.0,5000.0}
I3DL2_PRESET_PLAIN           := REVERB_I3DL2_PARAMETERS{100.0, -1000,-2000,0.0, 1.49,0.50, -2466,0.179, -2514,0.100, 21.0,100.0,5000.0}
I3DL2_PRESET_PARKINGLOT      := REVERB_I3DL2_PARAMETERS{100.0, -1000,    0,0.0, 1.65,1.50, -1363,0.008, -1153,0.012,100.0,100.0,5000.0}
I3DL2_PRESET_SEWERPIPE       := REVERB_I3DL2_PARAMETERS{100.0, -1000,-1000,0.0, 2.81,0.14,   429,0.014,   648,0.021, 80.0, 60.0,5000.0}
I3DL2_PRESET_UNDERWATER      := REVERB_I3DL2_PARAMETERS{100.0, -1000,-4000,0.0, 1.49,0.10,  -449,0.007,  1700,0.011,100.0,100.0,5000.0}
I3DL2_PRESET_SMALLROOM       := REVERB_I3DL2_PARAMETERS{100.0, -1000, -600,0.0, 1.10,0.83,  -400,0.005,   500,0.010,100.0,100.0,5000.0}
I3DL2_PRESET_MEDIUMROOM      := REVERB_I3DL2_PARAMETERS{100.0, -1000, -600,0.0, 1.30,0.83, -1000,0.010,  -200,0.020,100.0,100.0,5000.0}
I3DL2_PRESET_LARGEROOM       := REVERB_I3DL2_PARAMETERS{100.0, -1000, -600,0.0, 1.50,0.83, -1600,0.020, -1000,0.040,100.0,100.0,5000.0}
I3DL2_PRESET_MEDIUMHALL      := REVERB_I3DL2_PARAMETERS{100.0, -1000, -600,0.0, 1.80,0.70, -1300,0.015,  -800,0.030,100.0,100.0,5000.0}
I3DL2_PRESET_LARGEHALL       := REVERB_I3DL2_PARAMETERS{100.0, -1000, -600,0.0, 1.80,0.70, -2000,0.030, -1400,0.060,100.0,100.0,5000.0}
I3DL2_PRESET_PLATE           := REVERB_I3DL2_PARAMETERS{100.0, -1000, -200,0.0, 1.30,0.90,     0,0.002,     0,0.010,100.0, 75.0,5000.0}

// ReverbConvertI3DL2ToNative: Utility function to map from I3DL2 to native parameters

ReverbConvertI3DL2ToNative :: proc "contextless" (pI3DL2: ^REVERB_I3DL2_PARAMETERS, pNative: ^REVERB_PARAMETERS, sevenDotOneReverb: b32 = true) {
	reflectionsDelay: f32
	reverbDelay:      f32

	// RoomRolloffFactor is ignored

	// These parameters have no equivalent in I3DL2
	if sevenDotOneReverb {
		pNative.RearDelay = REVERB_DEFAULT_7POINT1_REAR_DELAY // 20
	} else {
		pNative.RearDelay = REVERB_DEFAULT_REAR_DELAY // 5
	}
	pNative.SideDelay           = REVERB_DEFAULT_7POINT1_SIDE_DELAY // 5
	pNative.PositionLeft        = REVERB_DEFAULT_POSITION // 6
	pNative.PositionRight       = REVERB_DEFAULT_POSITION // 6
	pNative.PositionMatrixLeft  = REVERB_DEFAULT_POSITION_MATRIX // 27
	pNative.PositionMatrixRight = REVERB_DEFAULT_POSITION_MATRIX // 27
	pNative.RoomSize            = REVERB_DEFAULT_ROOM_SIZE // 100
	pNative.LowEQCutoff         = 4
	pNative.HighEQCutoff        = 6

	// The rest of the I3DL2 parameters map to the native property set
	pNative.RoomFilterMain = f32(pI3DL2.Room) / 100.0
	pNative.RoomFilterHF   = f32(pI3DL2.RoomHF) / 100.0

	if pI3DL2.DecayHFRatio >= 1.0 {
		index := i32(-4.0 * math.log10_f32(pI3DL2.DecayHFRatio))
		if index < -8 {index = -8}
		pNative.LowEQGain  = byte((index < 0) ? index + 8 : 8)
		pNative.HighEQGain = 8
		pNative.DecayTime  = pI3DL2.DecayTime * pI3DL2.DecayHFRatio
	} else {
		index := i32(4.0 * math.log10_f32(pI3DL2.DecayHFRatio))
		if index < -8 {index = -8}
		pNative.LowEQGain  = 8
		pNative.HighEQGain = byte((index < 0) ? index + 8 : 8)
		pNative.DecayTime  = pI3DL2.DecayTime
	}

	reflectionsDelay = pI3DL2.ReflectionsDelay * 1000.0
	if reflectionsDelay >= REVERB_MAX_REFLECTIONS_DELAY { // 300
		reflectionsDelay = f32(REVERB_MAX_REFLECTIONS_DELAY - 1)
	} else if reflectionsDelay <= 1 {
		reflectionsDelay = 1
	}
	pNative.ReflectionsDelay = u32(reflectionsDelay)

	reverbDelay = pI3DL2.ReverbDelay * 1000.0
	if reverbDelay >= REVERB_MAX_REVERB_DELAY { // 85
		reverbDelay = f32(REVERB_MAX_REVERB_DELAY - 1)
	}
	pNative.ReverbDelay = byte(reverbDelay)

	pNative.ReflectionsGain = f32(pI3DL2.Reflections) / 100.0
	pNative.ReverbGain      = f32(pI3DL2.Reverb) / 100.0
	pNative.EarlyDiffusion  = byte(15.0 * pI3DL2.Diffusion / 100.0)
	pNative.LateDiffusion   = pNative.EarlyDiffusion
	pNative.Density         = pI3DL2.Density
	pNative.RoomFilterFreq  = pI3DL2.HFReference

	pNative.WetDryMix        = pI3DL2.WetDryMix
	pNative.DisableLateField = false
}
