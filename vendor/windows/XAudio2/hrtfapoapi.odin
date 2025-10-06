#+build windows

package windows_xaudio2

import win "core:sys/windows"

foreign import hrtf "system:hrtfapo.lib"

HRTF_MAX_GAIN_LIMIT              :: 12.0
HRTF_MIN_GAIN_LIMIT              :: -96.0
HRTF_MIN_UNITY_GAIN_DISTANCE     :: 0.05
HRTF_DEFAULT_UNITY_GAIN_DISTANCE :: 1.0
HRTF_DEFAULT_CUTOFF_DISTANCE     :: 3.402823466e+38

//! Represents a position in 3D space, using a right-handed coordinate system.
HrtfPosition :: struct {
	x: f32,
	y: f32,
	z: f32,
}

//! Indicates the orientation of an HRTF directivity object. This is a row-major 3x3 rotation matrix.
HrtfOrientation :: struct {
	element: [9]f32,
}

//! Indicates one of several stock directivity patterns.
HrtfDirectivityType :: enum i32 {
	//! The sound emission is in all directions.
	OmniDirectional = 0,
	//! The sound emission is a cardiod shape.
	Cardioid,
	//! The sound emission is a cone.
	Cone,
}

//! Indicates one of several stock environment types.
HrtfEnvironment :: enum i32 {
	//! A small room.
	Small = 0,
	//! A medium-sized room.
	Medium,
	//! A large enclosed space.
	Large,
	//! An outdoor space.
	Outdoors,
}

//! Base directivity pattern descriptor. Describes the type of directivity applied to a sound.
//! The scaling parameter is used to interpolate between directivity behavior and omnidirectional, it determines how much attenuation is applied to the source outside of the directivity pattern and controls how directional the source is.
HrtfDirectivity :: struct {
	//! Indicates the type of directivity.
	type: HrtfDirectivityType,
	//! A normalized value between zero and one. Specifies the amount of linear interpolation between omnidirectional sound and the full directivity pattern, where 0 is fully omnidirectional and 1 is fully directional.
	scaling: f32,
}

//! Describes a cardioid directivity pattern.
HrtfDirectivityCardioid :: struct {
	//! Descriptor for the cardioid pattern. The type parameter must be set to HrtfDirectivityType.Cardioid.
	directivity: HrtfDirectivity,
	//! Order controls the shape of the cardioid. The higher order the shape, the narrower it is. Must be greater than 0 and less than or equal to 32.
	order: f32,
}

//! Describes a cone directivity.
//! Attenuation is 0 inside the inner cone.
//! Attenuation is linearly interpolated between the inner cone, which is defined by innerAngle, and the outer cone, which is defined by outerAngle.
HrtfDirectivityCone :: struct {
	//! Descriptor for the cone pattern. The type parameter must be set to HrtfDirectivityType.Cone.
	directivity: HrtfDirectivity,
	//! Angle, in radians, that defines the inner cone. Must be between 0 and TAU.
	innerAngle: f32,
	//! Angle, in radians, that defines the outer cone. Must be between 0 and TAU.
	outerAngle: f32,
}

//! Indicates a distance-based decay type applied to a sound.
HrtfDistanceDecayType :: enum i32 {
	//! Simulates natural decay with distance, as constrained by minimum and maximum gain distance limits. Drops to silence at rolloff distance.
	NaturalDecay = 0,
	//! Used to set up a custom gain curve, within the maximum and minimum gain limit.
	CustomDecay,
}

//! Describes a distance-based decay behavior.
HrtfDistanceDecay :: struct {
	//! The type of decay behavior, natural or custom.
	type: HrtfDistanceDecayType,
	//! The maximum gain limit applied at any distance. Applies to both natural and custom decay. This value is specified in dB, with a range from -96 to 12 inclusive. The default value is 12 dB.
	maxGain: f32,
	//! The minimum gain limit applied at any distance. Applies to both natural and custom decay. This value is specified in dB, with a range from -96 to 12 inclusive. The default value is -96 dB.
	minGain: f32,
	//! The distance at which the gain is 0dB. Applies to natural decay only. This value is specified in meters, with a range from 0.05 to infinity (max(f32)). The default value is 1 meter.
	unityGainDistance: f32,
	//! The distance at which output is silent. Applies to natural decay only. This value is specified in meters, with a range from zero (non-inclusive) to infinity (max(f32)). The default value is infinity.
	cutoffDistance: f32,
}

//! Specifies parameters used to initialize HRTF.
//! Instances of the XAPO interface are created by using the CreateHrtfApo() API:
//!   ```CreateHrtfApo :: proc(pInit: HrtfApoInit, ppXapo: ^^IXAPO) -> HRESULT```
HrtfApoInit :: struct {
	//! The decay type. If you pass in nil, the default value will be used. The default is natural decay.
	distanceDecay: ^HrtfDistanceDecay,
	//! The directivity type. If you pass in nil, the default value will be used. The default directivity is omni-directional.
	directivity: ^HrtfDirectivity,
}

//! Creates an instance of the XAPO object.
//! Format requirements:
//! * Input: mono, 48 kHz, 32-bit float PCM.
//! * Output: stereo, 48 kHz, 32-bit float PCM.
//! Audio is processed in blocks of 1024 samples.
//! Returns:
//!     S_OK for success, any other value indicates failure.
//!     Returns E_NOTIMPL on unsupported platforms.
@(default_calling_convention="system")
foreign hrtf {
	CreateHrtfApo :: proc(
		//! Pointer to an HrtfApoInit struct. Specifies parameters for XAPO interface initialization.
		#by_ptr init: HrtfApoInit,
		//! Returns the new instance of the XAPO interface.
		xApo: ^^IXAPO,
	) -> HRESULT ---
}

//! The interface used to set parameters that control how HRTF is applied to a sound.
IXAPOHrtfParameters_UUID_STRING :: "15B3CD66-E9DE-4464-B6E6-2BC3CF63D455"
IXAPOHrtfParameters_UUID := &win.IID{0x15B3CD66, 0xE9DE, 0x4464, {0xB6, 0xE6, 0x2B, 0xC3, 0xCF, 0x63, 0xD4, 0x55}}
IXAPOHrtfParameters :: struct #raw_union {
	#subtype iunknown: IUnknown,
	using ixapohrtfparameters_vtable: ^IXAPOHrtfParameters_VTable,
}
IXAPOHrtfParameters_VTable :: struct {
	using iunknown_vtable: IUnknown_VTable,

	// HRTF params
	//! The position of the sound relative to the listener.
	SetSourcePosition: proc "system" (this: ^IXAPOHrtfParameters, position: ^HrtfPosition) -> HRESULT,
	//! The rotation matrix for the source orientation, with respect to the listener's frame of reference (the listener's coordinate system).
	SetSourceOrientation: proc "system" (this: ^IXAPOHrtfParameters, orientation: ^HrtfOrientation) -> HRESULT,
	//! The custom direct path gain value for the current source position. Valid only for sounds played with the HrtfDistanceDecayType. Custom decay type.
	SetSourceGain: proc "system" (this: ^IXAPOHrtfParameters, gain: f32) -> HRESULT,

	// Distance cue params
	//! Selects the acoustic environment to simulate.
	SetEnvironment: proc "system" (this: ^IXAPOHrtfParameters, environment: HrtfEnvironment) -> HRESULT,
}
