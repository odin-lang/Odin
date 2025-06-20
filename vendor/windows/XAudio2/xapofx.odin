#+build windows

package windows_xaudio2

import win "core:sys/windows"

foreign import xa2 "system:xaudio2.lib"

//--------------<D-E-F-I-N-I-T-I-O-N-S>-------------------------------------//

FXEQ_UUID_STRING :: "F5E01117-D6C4-485A-A3F5-695196F3DBFA"
FXEQ_UUID := &win.CLSID{0xF5E01117, 0xD6C4, 0x485A, {0xA3, 0xF5, 0x69, 0x51, 0x96, 0xF3, 0xDB, 0xFA}}

FXMasteringLimiter_UUID_STRING :: "C4137916-2BE1-46FD-8599-441536F49856"
FXMasteringLimiter_UUID := &win.CLSID{0xC4137916, 0x2BE1, 0x46FD, {0x85, 0x99, 0x44, 0x15, 0x36, 0xF4, 0x98, 0x56}}

FXReverb_UUID_STRING :: "7D9ACA56-CB68-4807-B632-B137352E8596"
FXReverb_UUID := &win.CLSID{0x7D9ACA56, 0xCB68, 0x4807, {0xB6, 0x32, 0xB1, 0x37, 0x35, 0x2E, 0x85, 0x96}}

FXEcho_UUID_STRING :: "5039D740-F736-449A-84D3-A56202557B87"
FXEcho_UUID := &win.CLSID{0x5039D740, 0xF736, 0x449A, {0x84, 0xD3, 0xA5, 0x62, 0x02, 0x55, 0x7B, 0x87}}

// EQ parameter bounds (inclusive), used with FXEQ:
FXEQ_MIN_FRAMERATE :: 22000
FXEQ_MAX_FRAMERATE :: 48000

FXEQ_MIN_FREQUENCY_CENTER       :: 20.0
FXEQ_MAX_FREQUENCY_CENTER       :: 20000.0
FXEQ_DEFAULT_FREQUENCY_CENTER_0 :: 100.0   // band 0
FXEQ_DEFAULT_FREQUENCY_CENTER_1 :: 800.0   // band 1
FXEQ_DEFAULT_FREQUENCY_CENTER_2 :: 2000.0  // band 2
FXEQ_DEFAULT_FREQUENCY_CENTER_3 :: 10000.0 // band 3

FXEQ_MIN_GAIN     :: 0.126 // -18dB
FXEQ_MAX_GAIN     :: 7.94  // +18dB
FXEQ_DEFAULT_GAIN :: 1.0   // 0dB change, all bands

FXEQ_MIN_BANDWIDTH     :: 0.1
FXEQ_MAX_BANDWIDTH     :: 2.0
FXEQ_DEFAULT_BANDWIDTH :: 1.0 // all bands


// Mastering limiter parameter bounds (inclusive), used with FXMasteringLimiter:
FXMASTERINGLIMITER_MIN_RELEASE     :: 1
FXMASTERINGLIMITER_MAX_RELEASE     :: 20
FXMASTERINGLIMITER_DEFAULT_RELEASE :: 6

FXMASTERINGLIMITER_MIN_LOUDNESS     :: 1
FXMASTERINGLIMITER_MAX_LOUDNESS     :: 1800
FXMASTERINGLIMITER_DEFAULT_LOUDNESS :: 1000


// Reverb parameter bounds (inclusive), used with FXReverb:
FXREVERB_MIN_DIFFUSION     :: 0.0
FXREVERB_MAX_DIFFUSION     :: 1.0
FXREVERB_DEFAULT_DIFFUSION :: 0.9

FXREVERB_MIN_ROOMSIZE     :: 0.0001
FXREVERB_MAX_ROOMSIZE     :: 1.0
FXREVERB_DEFAULT_ROOMSIZE :: 0.6

// Loudness defaults used with FXLoudness:
FXLOUDNESS_DEFAULT_MOMENTARY_MS :: 400
FXLOUDNESS_DEFAULT_SHORTTERM_MS :: 3000

// Echo initialization data/parameter bounds (inclusive), used with FXEcho:
FXECHO_MIN_WETDRYMIX     :: 0.0
FXECHO_MAX_WETDRYMIX     :: 1.0
FXECHO_DEFAULT_WETDRYMIX :: 0.5

FXECHO_MIN_FEEDBACK     :: 0.0
FXECHO_MAX_FEEDBACK     :: 1.0
FXECHO_DEFAULT_FEEDBACK :: 0.5

FXECHO_MIN_DELAY     :: 1.0
FXECHO_MAX_DELAY     :: 2000.0
FXECHO_DEFAULT_DELAY :: 500.0

//--------------<D-A-T-A---T-Y-P-E-S>---------------------------------------//

// EQ parameters (4 bands), used with IXAPOParameters.SetParameters:
// The EQ supports only f32 audio foramts.
// The framerate must be within [22000, 48000] Hz.
FXEQ_PARAMETERS :: struct #packed {
	FrequencyCenter0: f32,  // center frequency in Hz, band 0
	Gain0:            f32,  // boost/cut
	Bandwidth0:       f32,  // bandwidth, region of EQ is center frequency +/- bandwidth/2
	FrequencyCenter1: f32,  // band 1
	Gain1:            f32,
	Bandwidth1:       f32,
	FrequencyCenter2: f32,  // band 2
	Gain2:            f32,
	Bandwidth2:       f32,
	FrequencyCenter3: f32,  // band 3
	Gain3:            f32,
	Bandwidth3:       f32,
}

// Mastering limiter parameters, used with IXAPOParameters.SetParameters:
// The mastering limiter supports only f32 audio formats.
FXMASTERINGLIMITER_PARAMETERS :: struct #packed {
	Release:  u32,  // release time (tuning factor with no specific units)
	Loudness: u32,  // loudness target (threshold)
}

// Reverb parameters, used with IXAPOParameters.SetParameters:
// The reverb supports only f32 audio formats with the following channel configurations:
//     Input: Mono   Output: Mono
//     Input: Stereo Output: Stereo
FXREVERB_PARAMETERS :: struct #packed {
	Diffusion: f32,  // diffusion
	RoomSize:  f32,  // room size
}


// Echo initialization data, used with CreateFX:
// Use of this structure is optional, the default MaxDelay is FXECHO_DEFAULT_DELAY.
FXECHO_INITDATA :: struct #packed {
	MaxDelay: f32,  // maximum delay (all channels) in milliseconds, must be within [FXECHO_MIN_DELAY, FXECHO_MAX_DELAY]
}

// Echo parameters, used with IXAPOParameters.SetParameters:
// The echo supports only f32 audio formats.
FXECHO_PARAMETERS :: struct #packed {
	WetDryMix: f32,   // ratio of wet (processed) signal to dry (original) signal
	Feedback:  f32,   // amount of output fed back into input
	Delay:     f32,   // delay (all channels) in milliseconds, must be within [FXECHO_MIN_DELAY, FXECHO_PARAMETERS.MaxDelay]
}

//--------------<F-U-N-C-T-I-O-N-S>-----------------------------------------//

@(default_calling_convention="cdecl")
foreign xa2 {
	// creates instance of requested XAPO, use Release to free instance
    	//  pInitData        - [in] effect-specific initialization parameters, may be nil if InitDataByteSize == 0
    	//  InitDataByteSize - [in] size of pInitData in bytes, may be 0 if pInitData is nil
	CreateFX :: proc(clsid: win.REFCLSID, pEffect: ^^IUnknown, pInitDat: rawptr = nil, InitDataByteSize: u32 = 0) -> HRESULT ---
}
