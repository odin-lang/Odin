package sdl3_mixer

import "core:c"

import SDL "vendor:sdl3"

when ODIN_OS == .Windows {
	foreign import lib "SDL3_mixer.lib"
} else {
	foreign import lib "system:SDL3_mixer"
}

Mixer :: struct {}
Audio :: struct {}
Track :: struct {}
Group :: struct {}

StereoGains :: struct {
	left, right: c.float,
}
Point3D :: struct {
	x, y, z: c.float,
}

TrackStoppedCallback :: #type proc(userdata: rawptr, track: ^Track)
TrackMixCallback :: #type proc(userdata: rawptr, track: ^Track, spec: ^SDL.AudioSpec, pcm: ^c.float, samples: c.int)
GroupMixCallback :: #type proc(userdata: rawptr, group: ^Group, spec: ^SDL.AudioSpec, pcm: ^c.float, samples: c.int)
PostMixCallback :: #type proc( userdata: rawptr, mixer: ^Mixer, spec: ^SDL.AudioSpec, pcm: ^c.float, samples: c.int)

AudioDecoder :: struct {}

MAJOR_VERSION :: 3
MINOR_VERSION :: 2
MICRO_VERSION :: 0

PROP_MIXER_DEVICE_NUMBER :: "SDL_mixer.mixer.device"

PROP_AUDIO_LOAD_IOSTREAM_POINTER           :: "SDL_mixer.audio.load.iostream"
PROP_AUDIO_LOAD_CLOSEIO_BOOLEAN            :: "SDL_mixer.audio.load.closeio"
PROP_AUDIO_LOAD_PREDECODE_BOOLEAN          :: "SDL_mixer.audio.load.predecode"
PROP_AUDIO_LOAD_PREFERRED_MIXER_POINTER    :: "SDL_mixer.audio.load.preferred_mixer"
PROP_AUDIO_LOAD_SKIP_METADATA_TAGS_BOOLEAN :: "SDL_mixer.audio.load.skip_metadata_tags"
PROP_AUDIO_DECODER_STRING                  :: "SDL_mixer.audio.decoder"

PROP_METADATA_TITLE_STRING              :: "SDL_mixer.metadata.title"
PROP_METADATA_ARTIST_STRING             :: "SDL_mixer.metadata.artist"
PROP_METADATA_ALBUM_STRING              :: "SDL_mixer.metadata.album"
PROP_METADATA_COPYRIGHT_STRING          :: "SDL_mixer.metadata.copyright"
PROP_METADATA_TRACK_NUMBER              :: "SDL_mixer.metadata.track"
PROP_METADATA_TOTAL_TRACKS_NUMBER       :: "SDL_mixer.metadata.total_tracks"
PROP_METADATA_YEAR_NUMBER               :: "SDL_mixer.metadata.year"
PROP_METADATA_DURATION_FRAMES_NUMBER    :: "SDL_mixer.metadata.duration_frames"
PROP_METADATA_DURATION_INFINITE_BOOLEAN :: "SDL_mixer.metadata.duration_infinite"

PROP_PLAY_LOOPS_NUMBER                       :: "SDL_mixer.play.loops"
PROP_PLAY_MAX_FRAME_NUMBER                   :: "SDL_mixer.play.max_frame"
PROP_PLAY_MAX_MILLISECONDS_NUMBER            :: "SDL_mixer.play.max_milliseconds"
PROP_PLAY_START_FRAME_NUMBER                 :: "SDL_mixer.play.start_frame"
PROP_PLAY_START_MILLISECOND_NUMBER           :: "SDL_mixer.play.start_millisecond"
PROP_PLAY_LOOP_START_FRAME_NUMBER            :: "SDL_mixer.play.loop_start_frame"
PROP_PLAY_LOOP_START_MILLISECOND_NUMBER      :: "SDL_mixer.play.loop_start_millisecond"
PROP_PLAY_FADE_IN_FRAMES_NUMBER              :: "SDL_mixer.play.fade_in_frames"
PROP_PLAY_FADE_IN_MILLISECONDS_NUMBER        :: "SDL_mixer.play.fade_in_milliseconds"
PROP_PLAY_FADE_IN_START_GAIN_FLOAT           :: "SDL_mixer.play.fade_in_start_gain"
PROP_PLAY_APPEND_SILENCE_FRAMES_NUMBER       :: "SDL_mixer.play.append_silence_frames"
PROP_PLAY_APPEND_SILENCE_MILLISECONDS_NUMBER :: "SDL_mixer.play.append_silence_milliseconds"
PROP_PLAY_HALT_WHEN_EXHAUSTED_BOOLEAN        :: "SDL_mixer.play.halt_when_exhausted"

DURATION_UNKNOWN  :: -1
DURATION_INFINITE :: -2

@(default_calling_convention = "c", link_prefix = "MIX_", require_results)
foreign lib {
	Version                    :: proc() -> c.int ---
	Init                       :: proc() -> c.bool ---
	Quit                       :: proc() ---
	GetNumAudioDecoders        :: proc() -> c.int ---
	GetAudioDecoder            :: proc(index: c.int) -> cstring ---
	CreateMixerDevice          :: proc(devid: SDL.AudioDeviceID, spec: ^SDL.AudioSpec) -> ^Mixer ---
	CreateMixer                :: proc(spec: ^SDL.AudioSpec) -> ^Mixer ---
	DestroyMixer               :: proc(mixer: ^Mixer) ---
	GetMixerProperties         :: proc(mixer: ^Mixer) -> SDL.PropertiesID ---
	GetMixerFormat             :: proc(mixer: ^Mixer, spec: ^SDL.AudioSpec) -> c.bool ---
	LockMixer                  :: proc(mixer: ^Mixer) ---
	UnlockMixer                :: proc(mixer: ^Mixer) ---
	LoadAudio_IO               :: proc(mixer: ^Mixer, io: ^SDL.IOStream, predecode, closeio: c.bool) -> ^Audio ---
	LoadAudio                  :: proc(mixer: ^Mixer, path: cstring, predecode: c.bool) -> ^Audio ---
	LoadAudioNoCopy            :: proc(mixer: ^Mixer, data: rawptr, datalen: c.size_t, free_when_done: c.bool) -> ^Audio ---
	LoadAudioWithProperties    :: proc(props: SDL.PropertiesID) -> ^Audio ---
	LoadRawAudio_IO            :: proc(mixer: ^Mixer, io: ^SDL.IOStream, #by_ptr spec: SDL.AudioSpec, closeio: c.bool) -> ^Audio ---
	LoadRawAudio               :: proc(mixer: ^Mixer, data: rawptr, datalen: c.size_t, #by_ptr spec: SDL.AudioSpec) -> ^Audio ---
	LoadRawAudioNoCopy         :: proc(mixer: ^Mixer, data: rawptr, datalen: c.size_t, #by_ptr spec: SDL.AudioSpec, free_when_done: c.bool) -> ^Audio ---
	CreateSineWaveAudio        :: proc(mixer: ^Mixer, hz: c.int, amplitude: c.float, ms: SDL.Sint64) -> ^Audio ---
	GetAudioProperties         :: proc(audio: ^Audio) -> SDL.PropertiesID ---
	GetAudioDuration           :: proc(audio: ^Audio) -> SDL.Sint64 ---
	GetAudioFormat             :: proc(audio: ^Audio, spec: ^SDL.AudioSpec) -> c.bool ---
	DestroyAudio               :: proc(audio: ^Audio) ---
	CreateTrack                :: proc(mixer: ^Mixer) -> ^Track ---
	DestroyTrack               :: proc(track: ^Track) ---
	GetTrackProperties         :: proc(track: ^Track) -> SDL.PropertiesID ---
	GetTrackMixer              :: proc(track: ^Track) -> ^Mixer ---
	SetTrackAudio              :: proc(track: ^Track, audio: ^Audio) -> c.bool ---
	SetTrackAudioStream        :: proc(track: ^Track, stream: ^SDL.AudioStream) -> c.bool ---
	SetTrackIOStream           :: proc(track: ^Track, io: ^SDL.IOStream, closeio: c.bool) -> c.bool ---
	SetTrackRawIOStream        :: proc(track: ^Track, io: ^SDL.IOStream, #by_ptr spec: SDL.AudioSpec, closeio: c.bool) -> c.bool ---
	TagTrack                   :: proc(track: ^Track, tag: cstring) -> c.bool ---
	UntagTrack                 :: proc(track: ^Track, tag: cstring) ---
	GetTrackTags               :: proc(track: ^Track, count: ^c.int) -> [^]cstring ---
	GetTaggedTracks            :: proc(mixer: ^Mixer, tag: cstring, count: ^c.int) -> [^]^Track ---
	SetTrackPlaybackPosition   :: proc(track: ^Track, frames: SDL.Sint64) -> c.bool ---
	GetTrackPlaybackPosition   :: proc(track: ^Track) -> SDL.Sint64 ---
	GetTrackFadeFrames         :: proc(track: ^Track) -> SDL.Sint64 ---
	GetTrackLoops              :: proc(track: ^Track) -> c.int ---
	SetTrackLoops              :: proc(track: ^Track, num_loops: c.int) -> c.bool ---
	GetTrackAudio              :: proc(track: ^Track) -> ^Audio ---
	GetTrackAudioStream        :: proc(track: ^Track) -> ^SDL.AudioStream ---
	GetTrackRemaining          :: proc(track: ^Track) -> SDL.Sint64 ---
	TrackMSToFrames            :: proc(track: ^Track, ms: SDL.Sint64) -> SDL.Sint64 ---
	TrackFramesToMS            :: proc(track: ^Track, frames: SDL.Sint64) -> SDL.Sint64 ---
	AudioMSToFrames            :: proc(audio: ^Audio, ms: SDL.Sint64) -> SDL.Sint64 ---
	AudioFramesToMS            :: proc(audio: ^Audio, frames: SDL.Sint64) -> SDL.Sint64 ---
	MSToFrames                 :: proc(sample_rate: c.int, ms: SDL.Sint64) -> SDL.Sint64 ---
	FramesToMS                 :: proc(sample_rate: c.int, frames: SDL.Sint64) -> SDL.Sint64 ---
	PlayTrack                  :: proc(track: ^Track, options: SDL.PropertiesID) -> c.bool ---
	PlayTag                    :: proc(mixer: ^Mixer, tag: cstring, options: SDL.PropertiesID) -> c.bool ---
	PlayAudio                  :: proc(mixer: ^Mixer, audio: ^Audio) -> c.bool ---
	StopTrack                  :: proc(track: ^Track, fade_out_frames: SDL.Sint64) -> c.bool ---
	StopAllTracks              :: proc(mixer: ^Mixer, fade_out_ms: SDL.Sint64) -> c.bool ---
	StopTag                    :: proc(mixer: ^Mixer, tag: cstring, fade_out_ms: SDL.Sint64) -> c.bool ---
	PauseTrack                 :: proc(track: ^Track) -> c.bool ---
	PauseAllTracks             :: proc(mixer: ^Mixer) -> c.bool ---
	PauseTag                   :: proc(mixer: ^Mixer, tag: cstring) -> c.bool ---
	ResumeTrack                :: proc(track: ^Track) -> c.bool ---
	ResumeAllTracks            :: proc(mixer: ^Mixer) -> c.bool ---
	ResumeTag                  :: proc(mixer: ^Mixer, tag: cstring) -> c.bool ---
	TrackPlaying               :: proc(track: ^Track) -> c.bool ---
	TrackPaused                :: proc(track: ^Track) -> c.bool ---
	SetMixerGain               :: proc(mixer: ^Mixer, gain: c.float) -> c.bool ---
	GetMixerGain               :: proc(mixer: ^Mixer) -> c.float ---
	SetTrackGain               :: proc(track: ^Track, gain: c.float) -> c.bool ---
	GetTrackGain               :: proc(track: ^Track) -> c.float ---
	SetTagGain                 :: proc(mixer: ^Mixer, tag: cstring, gain: c.float) -> c.bool ---
	SetMixerFrequencyRatio     :: proc(mixer: ^Mixer, ratio: c.float) -> c.bool ---
	GetMixerFrequencyRatio     :: proc(mixer: ^Mixer) -> c.float ---
	SetTrackFrequencyRatio     :: proc(track: ^Track, ratio: c.float) -> c.bool ---
	GetTrackFrequencyRatio     :: proc(track: ^Track) -> c.float ---
	SetTrackOutputChannelMap   :: proc(track: ^Track, chmap: [^]c.int, count: c.int) -> c.bool ---
	SetTrackStereo             :: proc(track: ^Track, gains: ^StereoGains) -> c.bool ---
	SetTrack3DPosition         :: proc(track: ^Track, position: ^Point3D) -> c.bool ---
	GetTrack3DPosition         :: proc(track: ^Track, position: ^Point3D) -> c.bool ---
	CreateGroup                :: proc(mixer: ^Mixer) -> ^Group ---
	DestroyGroup               :: proc(group: ^Group) ---
	GetGroupProperties         :: proc(group: ^Group) -> SDL.PropertiesID ---
	GetGroupMixer              :: proc(group: ^Group) -> ^Mixer ---
	SetTrackGroup              :: proc(track: ^Track, group: ^Group) -> c.bool ---
	SetTrackStoppedCallback    :: proc(track: ^Track, cb: TrackStoppedCallback, userdata: rawptr) -> c.bool ---
	SetTrackRawCallback        :: proc(track: ^Track, cb: TrackMixCallback, userdata: rawptr) -> c.bool ---
	SetTrackCookedCallback     :: proc(track: ^Track, cb: TrackMixCallback, userdata: rawptr) -> c.bool ---
	SetGroupPostMixCallback    :: proc(group: ^Group, cb: GroupMixCallback, userdata: rawptr) -> c.bool ---
	SetPostMixCallback         :: proc(mixer: ^Mixer, cb: PostMixCallback, userdata: rawptr) -> c.bool ---
	Generate                   :: proc(mixer: ^Mixer, buffer: rawptr, buflen: c.int) -> c.int ---
	CreateAudioDecoder         :: proc(path: cstring, props: SDL.PropertiesID) -> ^AudioDecoder ---
	CreateAudioDecoder_IO      :: proc(io: ^SDL.IOStream, closeio: c.bool, props: SDL.PropertiesID) -> ^AudioDecoder ---
	DestroyAudioDecoder        :: proc(audiodecoder: ^AudioDecoder) ---
	GetAudioDecoderProperties  :: proc(audiodecoder: ^AudioDecoder) -> SDL.PropertiesID ---
	GetAudioDecoderFormat      :: proc(audiodecoder: ^AudioDecoder, spec: ^SDL.AudioSpec) -> c.bool ---
	DecodeAudio                :: proc(audiodecoder: ^AudioDecoder, buffer: rawptr, buflen: c.int, #by_ptr spec: SDL.AudioSpec) -> c.int ---
}
