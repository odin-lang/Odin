#+build windows

/* NOTES:
    1.  Definition of terms:
	    LFE: Low Frequency Effect -- always omnidirectional.
	    LPF: Low Pass Filter, divided into two classifications:
		 Direct -- Applied to the direct signal path,
			   used for obstruction/occlusion effects.
		 Reverb -- Applied to the reverb signal path,
			   used for occlusion effects only.

    2.  Volume level is expressed as a linear amplitude scaler:
	1.0 represents no attenuation applied to the original signal,
	0.5 denotes an attenuation of 6dB, and 0.0 results in silence.
	Amplification (volume > 1.0) is also allowed, and is not clamped.

	LPF values range from 1.0 representing all frequencies pass through,
	to 0.0 which results in silence as all frequencies are filtered out.

    3.  X3DAudio uses a left-handed Cartesian coordinate system with values
	on the x-axis increasing from left to right, on the y-axis from
	bottom to top, and on the z-axis from near to far.
	Azimuths are measured clockwise from a given reference direction.

	Distance measurement is with respect to user-defined world units.
	Applications may provide coordinates using any system of measure
	as all non-normalized calculations are scale invariant, with such
	operations natively occurring in user-defined world unit space.
	Metric constants are supplied only as a convenience.
	Distance is calculated using the Euclidean norm formula.

    4.  Only real values are permissible with functions using 32-bit
	float parameters -- NAN and infinite values are not accepted.
	All computation occurs in 32-bit precision mode.                    */


package windows_xaudio2

import "core:math"
import win "core:sys/windows"

foreign import xa2 "system:xaudio2.lib"

SPEAKER_FLAGS :: win.SPEAKER_FLAGS

//--------------<D-E-F-I-N-I-T-I-O-N-S>-------------------------------------//

// standard speaker geometry configurations, used with Initialize
SPEAKER_MONO             :: SPEAKER_FLAGS{.FRONT_CENTER}
SPEAKER_STEREO           :: SPEAKER_FLAGS{.FRONT_LEFT, .FRONT_RIGHT}
SPEAKER_2POINT1          :: SPEAKER_FLAGS{.FRONT_LEFT, .FRONT_RIGHT, .LOW_FREQUENCY}
SPEAKER_SURROUND         :: SPEAKER_FLAGS{.FRONT_LEFT, .FRONT_RIGHT, .FRONT_CENTER, .BACK_CENTER}
SPEAKER_QUAD             :: SPEAKER_FLAGS{.FRONT_LEFT, .FRONT_RIGHT, .BACK_LEFT, .BACK_RIGHT}
SPEAKER_4POINT1          :: SPEAKER_FLAGS{.FRONT_LEFT, .FRONT_RIGHT, .LOW_FREQUENCY, .BACK_LEFT, .BACK_RIGHT}
SPEAKER_5POINT1          :: SPEAKER_FLAGS{.FRONT_LEFT, .FRONT_RIGHT, .FRONT_CENTER, .LOW_FREQUENCY, .BACK_LEFT, .BACK_RIGHT}
SPEAKER_7POINT1          :: SPEAKER_FLAGS{.FRONT_LEFT, .FRONT_RIGHT, .FRONT_CENTER, .LOW_FREQUENCY, .BACK_LEFT, .BACK_RIGHT, .FRONT_LEFT_OF_CENTER, .FRONT_RIGHT_OF_CENTER}
SPEAKER_5POINT1_SURROUND :: SPEAKER_FLAGS{.FRONT_LEFT, .FRONT_RIGHT, .FRONT_CENTER, .LOW_FREQUENCY, .SIDE_LEFT, .SIDE_RIGHT}
SPEAKER_7POINT1_SURROUND :: SPEAKER_FLAGS{.FRONT_LEFT, .FRONT_RIGHT, .FRONT_CENTER, .LOW_FREQUENCY, .BACK_LEFT, .BACK_RIGHT, .SIDE_LEFT, .SIDE_RIGHT}

// size of instance handle in bytes
HANDLE_BYTESIZE :: 20

// speed of sound in meters per second for dry air at approximately 20C, used with Initialize
SPEED_OF_SOUND :: 343.5

// calculation control flags, used with Calculate
CALCULATE_FLAGS :: distinct bit_set[CALCULATE_FLAG; u32]
CALCULATE_FLAG :: enum u32 {
	MATRIX        = 0, // enable matrix coefficient table calculation
	DELAY         = 1, // enable delay time array calculation (stereo final mix only)
	LPF_DIRECT    = 2, // enable LPF direct-path coefficient calculation
	LPF_REVERB    = 3, // enable LPF reverb-path coefficient calculation
	REVERB        = 4, // enable reverb send level calculation
	DOPPLER       = 5, // enable doppler shift factor calculation
	EMITTER_ANGLE = 6, // enable emitter-to-listener interior angle calculation

	ZEROCENTER      = 16, // do not position to front center speaker, signal positioned to remaining speakers instead, front center destination channel will be zero in returned matrix coefficient table, valid only for matrix calculations with final mix formats that have a front center channel
	REDIRECT_TO_LFE = 17, // apply equal mix of all source channels to LFE destination channel, valid only for matrix calculations with sources that have no LFE channel and final mix formats that have an LFE channel
}

//--------------<D-A-T-A---T-Y-P-E-S>---------------------------------------//
VECTOR :: distinct [3]f32 // float 3D vector

// instance handle of precalculated constants
HANDLE :: distinct [HANDLE_BYTESIZE]byte

// Distance curve point:
// Defines a DSP setting at a given normalized distance.
DISTANCE_CURVE_POINT :: struct #packed {
	Distance:   f32,   // normalized distance, must be within [0.0, 1.0]
	DSPSetting: f32,   // DSP setting
}

// Distance curve:
// A piecewise curve made up of linear segments used to define DSP behaviour with respect to normalized distance.
//
// Note that curve point distances are normalized within [0.0, 1.0].
// EMITTER.CurveDistanceScaler must be used to scale the normalized distances to user-defined world units.
// For distances beyond CurveDistanceScaler * 1.0, pPoints[PointCount-1].DSPSetting is used as the DSP setting.
//
// All distance curve spans must be such that:
//      pPoints[k-1].DSPSetting + ((pPoints[k].DSPSetting-pPoints[k-1].DSPSetting) / (pPoints[k].Distance-pPoints[k-1].Distance)) * (pPoints[k].Distance-pPoints[k-1].Distance) != NAN or infinite values
// For all points in the distance curve where 1 <= k < PointCount.
DISTANCE_CURVE :: struct #packed {
	pPoints:    [^]DISTANCE_CURVE_POINT `fmt:"v,PointCount"`,    // distance curve point array, must have at least PointCount elements with no duplicates and be sorted in ascending order with respect to Distance
	PointCount: u32,                                             // number of distance curve points, must be >= 2 as all distance curves must have at least two endpoints, defining DSP settings at 0.0 and 1.0 normalized distance
}
Default_LinearCurvePoints := [2]DISTANCE_CURVE_POINT{{0.0, 1.0}, {1.0, 0.0}}
Default_LinearCurve       := DISTANCE_CURVE{&Default_LinearCurvePoints[0], 2}

// Cone:
// Specifies directionality for a listener or single-channel emitter by modifying DSP behaviour with respect to its front orientation.
// This is modeled using two sound cones: an inner cone and an outer cone. On/within the inner cone, DSP settings are scaled by the inner values.
// On/beyond the outer cone, DSP settings are scaled by the outer values. If on both the cones, DSP settings are scaled by the inner values only.
// Between the two cones, the scaler is linearly interpolated between the inner and outer values.  Set both cone angles to 0 or TAU for omnidirectionality using only the outer or inner values respectively.
CONE :: struct #packed {
	InnerAngle:  f32,   // inner cone angle in radians, must be within [0.0, TAU]
	OuterAngle:  f32,   // outer cone angle in radians, must be within [InnerAngle, TAU]

	InnerVolume: f32,   // volume level scaler on/within inner cone, used only for matrix calculations, must be within [0.0, 2.0] when used
	OuterVolume: f32,   // volume level scaler on/beyond outer cone, used only for matrix calculations, must be within [0.0, 2.0] when used
	InnerLPF:    f32,   // LPF (both direct and reverb paths) coefficient subtrahend on/within inner cone, used only for LPF (both direct and reverb paths) calculations, must be within [0.0, 1.0] when used
	OuterLPF:    f32,   // LPF (both direct and reverb paths) coefficient subtrahend on/beyond outer cone, used only for LPF (both direct and reverb paths) calculations, must be within [0.0, 1.0] when used
	InnerReverb: f32,   // reverb send level scaler on/within inner cone, used only for reverb calculations, must be within [0.0, 2.0] when used
	OuterReverb: f32,   // reverb send level scaler on/beyond outer cone, used only for reverb calculations, must be within [0.0, 2.0] when used
}
Default_DirectionalCone := CONE{math.PI / 2, math.PI, 1.0, 0.708, 0.0, 0.25, 0.708, 1.0}

// Listener:
// Defines a point of 3D audio reception.
// The cone is directed by the listener's front orientation.
LISTENER :: struct #packed {
	OrientFront: VECTOR,   // orientation of front direction, used only for matrix and delay calculations or listeners with cones for matrix, LPF (both direct and reverb paths), and reverb calculations, must be normalized when used
	OrientTop:   VECTOR,   // orientation of top direction, used only for matrix and delay calculations, must be orthonormal with OrientFront when used

	Position: VECTOR,      // position in user-defined world units, does not affect Velocity
	Velocity: VECTOR,      // velocity vector in user-defined world units/second, used only for doppler calculations, does not affect Position

	pCone: ^CONE,          // sound cone, used only for matrix, LPF (both direct and reverb paths), and reverb calculations, nil specifies omnidirectionality
}

// Emitter:
// Defines a 3D audio source, divided into two classifications:
// Single-point -- For use with single-channel sounds.
//                 Positioned at the emitter base, i.e. the channel radius and azimuth are ignored if the number of channels == 1.
//                 May be omnidirectional or directional using a cone.
//                 The cone originates from the emitter base position, and is directed by the emitter's front orientation.
// Multi-point  -- For use with multi-channel sounds.
//                 Each non-LFE channel is positioned using an azimuth along the channel radius with respect to the front orientation vector in the plane orthogonal to the top orientation vector.
//                 An azimuth of TAU specifies a channel is an LFE. Such channels are positioned at the emitter base and are calculated with respect to pLFECurve only, never pVolumeCurve.
//                 Multi-point emitters are always omnidirectional, i.e. the cone is ignored if the number of channels > 1.
// Note that many properties are shared among all channel points, locking certain behaviour with respect to the emitter base position.
// For example, doppler shift is always calculated with respect to the emitter base position and so is constant for all its channel points.
// Distance curve calculations are also with respect to the emitter base position, with the curves being calculated independently of each other.
// For instance, volume and LFE calculations do not affect one another.
EMITTER :: struct #packed {
	pCone: ^CONE,   // sound cone, used only with single-channel emitters for matrix, LPF (both direct and reverb paths), and reverb calculations, nil specifies omnidirectionality

	OrientFront: VECTOR,   // orientation of front direction, used only for emitter angle calculations or with multi-channel emitters for matrix calculations or single-channel emitters with cones for matrix, LPF (both direct and reverb paths), and reverb calculations, must be normalized when used
	OrientTop:   VECTOR,   // orientation of top direction, used only with multi-channel emitters for matrix calculations, must be orthonormal with OrientFront when used

	Position: VECTOR,   // position in user-defined world units, does not affect Velocity
	Velocity: VECTOR,   // velocity vector in user-defined world units/second, used only for doppler calculations, does not affect Position

	InnerRadius:      f32,    // inner radius, must be within [0.0, max(f32)]
	InnerRadiusAngle: f32,    // inner radius angle, must be within [0.0, PI/4.0)

	ChannelCount:     u32,                              // number of sound channels, must be > 0
	ChannelRadius:    f32,                              // channel radius, used only with multi-channel emitters for matrix calculations, must be >= 0.0 when used
	pChannelAzimuths: [^]f32 `fmt:"v,ChannelCount"`,    // channel azimuth array, used only with multi-channel emitters for matrix calculations, contains positions of each channel expressed in radians along the channel radius with respect to the front orientation vector in the plane orthogonal to the top orientation vector, or TAU to specify an LFE channel, must have at least ChannelCount elements, all within [0.0, TAU] when used

	pVolumeCurve:    ^DISTANCE_CURVE,    // volume level distance curve, used only for matrix calculations, nil specifies a default curve that conforms to the inverse square law, calculated in user-defined world units with distances <= CurveDistanceScaler clamped to no attenuation
	pLFECurve:       ^DISTANCE_CURVE,    // LFE level distance curve, used only for matrix calculations, nil specifies a default curve that conforms to the inverse square law, calculated in user-defined world units with distances <= CurveDistanceScaler clamped to no attenuation
	pLPFDirectCurve: ^DISTANCE_CURVE,    // LPF direct-path coefficient distance curve, used only for LPF direct-path calculations, nil specifies the default curve: [0.0,1.0], [1.0,0.75]
	pLPFReverbCurve: ^DISTANCE_CURVE,    // LPF reverb-path coefficient distance curve, used only for LPF reverb-path calculations, nil specifies the default curve: [0.0,0.75], [1.0,0.75]
	pReverbCurve:    ^DISTANCE_CURVE,    // reverb send level distance curve, used only for reverb calculations, nil specifies the default curve: [0.0,1.0], [1.0,0.0]

	CurveDistanceScaler: f32,   // curve distance scaler, used to scale normalized distance curves to user-defined world units and/or exaggerate their effect, used only for matrix, LPF (both direct and reverb paths), and reverb calculations, must be within [min(f32), max(f32)] when used
	DopplerScaler:       f32,   // doppler shift scaler, used to exaggerate doppler shift effect, used only for doppler calculations, must be within [0.0, max(f32)] when used
}

// DSP settings:
// Receives results from a call to Calculate to be sent to the low-level audio rendering API for 3D signal processing.
// The user is responsible for allocating the matrix coefficient table, delay time array, and initializing the channel counts when used.
DSP_SETTINGS :: struct #packed {
	pMatrixCoefficients: [^]f32,  // [inout] matrix coefficient table, receives an array representing the volume level used to send from source channel S to destination channel D, stored as pMatrixCoefficients[SrcChannelCount * D + S], must have at least SrcChannelCount*DstChannelCount elements
	pDelayTimes:         [^]f32,  // [inout] delay time array, receives delays for each destination channel in milliseconds, must have at least DstChannelCount elements (stereo final mix only)
	SrcChannelCount:     u32,     // [in] number of source channels, must equal number of channels in respective emitter
	DstChannelCount:     u32,     // [in] number of destination channels, must equal number of channels of the final mix

	LPFDirectCoefficient:   f32,  // [out] LPF direct-path coefficient
	LPFReverbCoefficient:   f32,  // [out] LPF reverb-path coefficient
	ReverbLevel:            f32,  // [out] reverb send level
	DopplerFactor:          f32,  // [out] doppler shift factor, scales resampler ratio for doppler shift effect, where the effective frequency = DopplerFactor * original frequency
	EmitterToListenerAngle: f32,  // [out] emitter-to-listener interior angle, expressed in radians with respect to the emitter's front orientation

	EmitterToListenerDistance: f32,  // [out] distance in user-defined world units from the emitter base to listener position, always calculated
	EmitterVelocityComponent:  f32,  // [out] component of emitter velocity vector projected onto emitter->listener vector in user-defined world units/second, calculated only for doppler
	ListenerVelocityComponent: f32,  // [out] component of listener velocity vector projected onto emitter->listener vector in user-defined world units/second, calculated only for doppler
}

//--------------<F-U-N-C-T-I-O-N-S>-----------------------------------------//
@(default_calling_convention="cdecl", link_prefix="X3DAudio")
foreign xa2 {
	// initializes instance handle
	Initialize :: proc(SpeakerChannelMask: SPEAKER_FLAGS, SpeedOfSound: f32, Instance: HANDLE) -> HRESULT ---

	// calculates DSP settings with respect to 3D parameters
	Calculate :: proc(Instance: HANDLE, #by_ptr pListener: LISTENER, #by_ptr pEmitter: EMITTER, Flags: CALCULATE_FLAGS, pDSPSettings: ^DSP_SETTINGS) ---
}
