// Bindings for [[ SDL2 Mixer ; https://wiki.libsdl.org/SDL2/FrontPage ]].
package sdl2_mixer

import "core:c"
import SDL ".."

when ODIN_OS == .Windows {
	foreign import lib "SDL2_mixer.lib"
} else {
	foreign import lib "system:SDL2_mixer"
}

MAJOR_VERSION :: 2
MINOR_VERSION :: 0
PATCHLEVEL    :: 4

CHANNELS :: 8


bool :: SDL.bool


InitFlag :: enum c.int {
	FLAC   = 0,
	MOD    = 1,
	MP3    = 3,
	OGG    = 4,
	MID    = 5,
	OPUS   = 6,
}

InitFlags :: distinct bit_set[InitFlag; c.int]

INIT_FLAC :: InitFlags{.FLAC}
INIT_MOD  :: InitFlags{.MOD}
INIT_MP3  :: InitFlags{.MP3}
INIT_OGG  :: InitFlags{.OGG}
INIT_MID  :: InitFlags{.MID}
INIT_OPUS :: InitFlags{.OPUS}

DEFAULT_FREQUENCY :: 44100
DEFAULT_FORMAT :: SDL.AUDIO_S16SYS
DEFAULT_CHANNELS :: 2
MAX_VOLUME :: SDL.MIX_MAXVOLUME

Chunk :: struct {
	allocated: c.int,
	abuf:      [^]u8,
	alen:      u32,
	volume:    u8,  /* Per-sample volume, 0-128 */
}

Fading :: enum c.int {
	NO_FADING,
	FADING_OUT,
	FADING_IN,
}

NO_FADING  :: Fading.NO_FADING
FADING_OUT :: Fading.FADING_OUT
FADING_IN  :: Fading.FADING_IN

MusicType :: enum c.int {
	NONE,
	CMD,
	WAV,
	MOD,
	MID,
	OGG,
	MP3,
	MP3_MAD_UNUSED,
	FLAC,
	MODPLUG_UNUSED,
	OPUS,
}

MUS_NONE           :: MusicType.NONE
MUS_CMD            :: MusicType.CMD
MUS_WAV            :: MusicType.WAV
MUS_MOD            :: MusicType.MOD
MUS_MID            :: MusicType.MID
MUS_OGG            :: MusicType.OGG
MUS_MP3            :: MusicType.MP3
MUS_MP3_MAD_UNUSED :: MusicType.MP3_MAD_UNUSED
MUS_FLAC           :: MusicType.FLAC
MUS_MODPLUG_UNUSED :: MusicType.MODPLUG_UNUSED
MUS_OPUS           :: MusicType.OPUS

Music :: struct {}



/* We'll use SDL for reporting errors */
SetError   :: SDL.SetError
GetError   :: SDL.GetError
ClearError :: SDL.ClearError

LoadWAV :: #force_inline proc "c" (file: cstring) -> ^Chunk {
	return LoadWAV_RW(SDL.RWFromFile(file, "rb"), true)
}


MixFunc :: proc "c" (udata: rawptr, stream: [^]u8, len: c.int)

@(default_calling_convention="c", link_prefix="Mix_")
foreign lib {
	Linked_Version :: proc() -> ^SDL.version ---

	Init :: proc(flags: InitFlags) -> c.int ---
	Quit :: proc() ---

	OpenAudio            :: proc(frequency: c.int, format: u16, channels: c.int, chunksize: c.int) -> c.int ---
	OpenAudioDevice      :: proc(frequency: c.int, format: u16, channels: c.int, chunksize: c.int, device: cstring, allowed_changed: c.int) -> c.int ---
	AllocateChannels     :: proc(numchans: c.int) -> c.int ---
	QuerySpec            :: proc(frequency: ^c.int, format: ^u16, channels: ^c.int) -> c.int ---
	LoadWAV_RW           :: proc(src: ^SDL.RWops, freesrc: bool) -> ^Chunk ---
	LoadMUS              :: proc(file: cstring) -> ^Music ---
	LoadMUS_RW           :: proc(src: ^SDL.RWops, freesrc: bool) -> ^Music ---
	LoadMUSType_RW       :: proc(src: ^SDL.RWops, type: MusicType, freesrc: bool) -> ^Music ---
	QuickLoad_WAV        :: proc(mem: [^]u8) -> ^Chunk ---
	QuickLoad_RAW        :: proc(mem: [^]u8, len: u32) -> ^Chunk ---
	FreeChunk            :: proc(chunk: ^Chunk) ---
	FreeMusic            :: proc(music: ^Music) ---
	GetNumChunkDecoders  :: proc() -> c.int ---
	GetChunkDecoder      :: proc(index: c.int) -> cstring ---
	HasChunkDecoder      :: proc(name: cstring) -> bool ---
	GetNumMusicDecoders  :: proc() -> c.int ---
	GetMusicDecoder      :: proc(index: c.int) -> cstring ---
	HasMusicDecoder      :: proc(name: cstring) -> bool ---
	GetMusicType         :: proc(music: ^Music) -> MusicType ---
	GetMusicTitle        :: proc(music: ^Music) -> cstring ---
	GetMusicTitleTag     :: proc(music: ^Music) -> cstring ---
	GetMusicArtistTag    :: proc(music: ^Music) -> cstring ---
	GetMusicAlbumTag     :: proc(music: ^Music) -> cstring ---
	GetMusicCopyrightTag :: proc(music: ^Music) -> cstring ---

	SetPostMix           :: proc(mix_func: MixFunc, arg: rawptr) ---
	HookMusic            :: proc(mix_func: MixFunc, arg: rawptr) ---
	HookMusicFinished    :: proc(music_finished: proc "c" ()) ---
	GetMusicHookData     :: proc() -> rawptr ---

	ChannelFinished      :: proc(channel_finished: proc "c" (channel: c.int)) ---
}

CHANNEL_POST :: -2

EffectFunc_t :: proc "c" (chan: c.int, stream: rawptr, len: c.int, udata: rawptr)
EffectDone_t :: proc "c" (chan: c.int, udata: rawptr)

EFFECTSMAXSPEED :: "MIX_EFFECTSMAXSPEED"

PlayChannel :: #force_inline proc "c" (channel: c.int, chunk: ^Chunk, loops: c.int) -> c.int {
	return PlayChannelTimed(channel, chunk, loops, -1)
}
FadeInChannel :: #force_inline proc "c" (channel: c.int, chunk: ^Chunk, loops: c.int, ms: c.int) -> c.int {
	return FadeInChannelTimed(channel, chunk, loops, ms, -1)
}


@(default_calling_convention="c", link_prefix="Mix_")
foreign lib {
	RegisterEffect        :: proc(chan: c.int, f: EffectFunc_t, d: EffectDone_t, arg: rawptr) -> c.int ---
	UnregisterEffect      :: proc(channel: c.int, f: EffectFunc_t) -> c.int ---
	UnregisterAllEffects  :: proc(channel: c.int) -> c.int ---

	SetPanning            :: proc(channel: c.int, left, right: u8) -> c.int ---
	SetPosition           :: proc(channel: c.int, angle: i16, distance: u8) -> c.int ---
	SetDistance           :: proc(channel: c.int, distance: u8) -> c.int ---
	SetReverseStereo      :: proc(channel: c.int, flip: bool) -> c.int ---
	ReserveChannels       :: proc(num: c.int) -> c.int ---
	GroupChannel          :: proc(which: c.int, tag: c.int) -> c.int ---
	GroupChannels         :: proc(from, to: c.int, tag: c.int) -> c.int ---
	GroupAvailable        :: proc(tag: c.int) -> c.int ---
	GroupCount            :: proc(tag: c.int) -> c.int ---
	GroupOldest           :: proc(tag: c.int) -> c.int ---
	GroupNewer            :: proc(tag: c.int) -> c.int ---
	PlayChannelTimed      :: proc(channel: c.int, chunk: ^Chunk, loops: c.int, ticks: c.int) -> c.int ---
	PlayMusic             :: proc(music: ^Music, loops: c.int) -> c.int ---
	FadeInMusic           :: proc(music: ^Music, loops: c.int, ms: c.int) -> c.int ---
	FadeInMusicPos        :: proc(music: ^Music, loops: c.int, ms: c.int, position: f64) -> c.int ---
	FadeInChannelTimed    :: proc(channel: c.int, chunk: ^Chunk, loops: c.int, ms: c.int, ticks: c.int) -> c.int ---
	Volume                :: proc(channel: c.int, volume: c.int) -> c.int ---
	VolumeChunk           :: proc(chunk: ^Chunk, volume: c.int) -> c.int ---
	VolumeMusic           :: proc(volume: c.int) -> c.int ---
	GetMusicVolume        :: proc(music: ^Music) -> c.int ---
	HaltChannel           :: proc(channel: c.int) -> c.int ---
	HaltGroup             :: proc(tag: c.int) -> c.int ---
	HaltMusic             :: proc() -> c.int ---
	ExpireChannel         :: proc(channel: c.int, ticks: c.int) -> c.int ---
	FadeOutChannel        :: proc(which: c.int, ms: c.int) -> c.int ---
	FadeOutGroup          :: proc(tag: c.int, ms: c.int) -> c.int ---
	FadeOutMusic          :: proc(ms: c.int) -> c.int ---
	FadingMusic           :: proc() -> Fading ---
	FadingChannel         :: proc(which: c.int) -> Fading ---
	Pause                 :: proc(channel: c.int) ---
	Resume                :: proc(channel: c.int) ---
	Paused                :: proc(channel: c.int) -> c.int ---
	PauseMusic            :: proc() ---
	ResumeMusic           :: proc() ---
	RewindMusic           :: proc() ---
	PausedMusic           :: proc() -> c.int ---
	ModMusicJumpToOrder   :: proc(order: c.int) -> c.int ---
	SetMusicPosition      :: proc(position: f64) -> c.int ---
	GetMusicPosition      :: proc(music: ^Music) -> f64 ---
	MusicDuration         :: proc(music: ^Music) -> f64 ---
	GetMusicLoopStartTime :: proc(music: ^Music) -> f64 ---
	GetMusicLoopEndTime   :: proc(music: ^Music) -> f64 ---
	GetMusicLoopLengthTime:: proc(music: ^Music) -> f64 ---
	Playing               :: proc(channel: c.int) -> c.int ---
	PlayingMusic          :: proc() -> c.int ---
	SetMusicCMD           :: proc(command: cstring) -> c.int ---
	SetSynchroValue       :: proc(value: c.int) -> c.int ---
	GetSynchroValue       :: proc() -> c.int ---
	SetSoundFonts         :: proc(paths: cstring) -> c.int ---
	GetSoundFonts         :: proc() -> cstring ---
	EachSoundFont         :: proc(function : proc "c" (cstring, rawptr) -> c.int, data: rawptr) -> c.int ---
	SetTimidityCfg        :: proc(path: cstring) -> c.int ---
	GetTimidityCfg        :: proc() -> cstring ---
	GetChunk              :: proc(channel: c.int) -> ^Chunk ---
	CloseAudio            :: proc() ---
}

