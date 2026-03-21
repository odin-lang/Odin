/*
  SDL_mixer: An audio mixer library based on the SDL library
  Copyright (C) 1997-2026 Sam Lantinga <slouken@libsdl.org>

  This software is provided 'as-is', without any express or implied
  warranty.  In no event will the authors be held liable for any damages
  arising from the use of this software.

  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely, subject to the following restrictions:

  1. The origin of this software must not be misrepresented; you must not
     claim that you wrote the original software. If you use this software
     in a product, an acknowledgment in the product documentation would be
     appreciated but is not required.
  2. Altered source versions must be plainly marked as such, and must not be
     misrepresented as being the original software.
  3. This notice may not be removed or altered from any source distribution.
*/

/* WIKI CATEGORY: SDLMixer */

/**
 * # CategorySDLMixer
 *
 * SDL_mixer is a library to make complicated audio processing tasks easier.
 *
 * It offers audio file decoding, mixing multiple sounds together, basic 3D
 * positional audio, and various audio effects.
 *
 * It can mix sound to multiple audio devices in real time, or generate mixed
 * audio data to a memory buffer for any other use. It can do both at the same
 * time!
 *
 * To use the library, first call MIX_Init(). Then create a mixer with
 * MIX_CreateMixerDevice() (or MIX_CreateMixer() to render to memory).
 *
 * Once you have a mixer, you can load sound data with MIX_LoadAudio(),
 * MIX_LoadAudio_IO(), or MIX_LoadAudioWithProperties(). Data gets loaded once
 * and can be played over and over.
 *
 * When loading audio, SDL_mixer can parse out several metadata tag formats,
 * such as ID3 and APE tags, and exposes this information through the
 * MIX_GetAudioProperties() function.
 *
 * To play audio, you create a track with MIX_CreateTrack(). You need one
 * track for each sound that will be played simultaneously; think of tracks as
 * individual sliders on a mixer board. You might have loaded hundreds of
 * audio files, but you probably only have a handful of tracks that you assign
 * those loaded files to when they are ready to play, and reuse those tracks
 * with different audio later. Tracks take their input from a MIX_Audio
 * (static data to be played multiple times) or an SDL_AudioStream (streaming
 * PCM audio the app supplies, possibly as needed). A third option is to
 * supply an SDL_IOStream, to load and decode on the fly, which might be more
 * efficient for background music that is only used once, etc.
 *
 * Assign input to a MIX_Track with MIX_SetTrackAudio(),
 * MIX_SetTrackAudioStream(), or MIX_SetTrackIOStream().
 *
 * Once a track has an input, start it playing with MIX_PlayTrack(). There are
 * many options to this function to dictate mixing features: looping, fades,
 * etc.
 *
 * Tracks can be tagged with arbitrary strings, like "music" or "ingame" or
 * "ui". These tags can be used to start, stop, and pause a selection of
 * tracks at the same moment.
 *
 * All significant portions of the mixing pipeline have callbacks, so that an
 * app can hook in to the appropriate locations to examine or modify audio
 * data as it passes through the mixer: a "raw" callback for raw PCM data
 * decoded from an audio file without any modifications, a "cooked" callback
 * for that same data after all transformations (fade, positioning, etc) have
 * been processed, a "stopped" callback for when the track finishes mixing, a
 * "postmix" callback for the final mixed audio about to be sent to the audio
 * hardware to play. Additionally, you can use MIX_Group objects to mix a
 * subset of playing tracks and access the data before it is mixed in with
 * other tracks. All of this is optional, but allows for powerful access and
 * control of the mixing process.
 *
 * SDL_mixer can also be used for decoding audio files without actually
 * rendering a mix. This is done with MIX_AudioDecoder. Even though SDL_mixer
 * handles decoding transparently when used as the audio engine for an app,
 * and probably won't need this interface in that normal scenario, this can be
 * useful when using a different audio library to access many file formats.
 *
 * This library offers several features on top of mixing sounds together: a
 * track can have its own gain, to adjust its volume, in addition to a master
 * gain applied as well. One can set the "frequency ratio" of a track or the
 * final mixed output, to speed it up or slow it down, which also adjusts its
 * pitch. A channel map can also be applied per-track, to change what speaker
 * a given channel of audio is output to.
 *
 * Almost all timing in SDL_mixer is in _sample frames_. Stereo PCM audio data
 * in Sint16 format takes 4 bytes per sample frame (2 bytes per sample times 2
 * channels), for example. This allows everything in SDL_mixer to run at
 * sample-perfect accuracy, and it lets it run without concern for wall clock
 * time--you can produce audio faster than real-time, if desired. The problem,
 * though, is different pieces of audio at different _sample rates_ will
 * produce a different number of sample frames for the same length of time. To
 * deal with this, conversion routines are offered: MIX_TrackMSToFrames(),
 * MIX_TrackFramesToMS(), etc. Functions that operate on multiple tracks at
 * once will deal with time in milliseconds, so it can do these conversions
 * internally; be sure to read the documentation for these small quirks!
 *
 * SDL_mixer offers basic positional audio: a simple 3D positioning API
 * through MIX_SetTrack3DPosition() and MIX_SetTrackStereo(). The former will
 * do simple distance attenuation and spatialization--on a stereo setup, you
 * will hear sounds move from left to right--and on a surround-sound
 * configuration, individual tracks can move around the user. The latter,
 * MIX_SetTrackStereo(), will force a sound to the Front Left and Front Right
 * speakers and let the app pan it left and right as desired. Either effect
 * can be useful for different situations. SDL_mixer is not meant to be a full
 * 3D audio engine, but rather Good Enough for many purposes; if something
 * more powerful in terms of 3D audio is needed, consider a proper 3D library
 * like OpenAL.
 */

#ifndef SDL_MIXER_H_
#define SDL_MIXER_H_

#include <SDL3/SDL.h>
#include <SDL3/SDL_begin_code.h>

/* Set up for C function definitions, even when using C++ */
#ifdef __cplusplus
extern "C" {
#endif


/**
 * An opaque object that represents a mixer.
 *
 * The MIX_Mixer is the toplevel object for this library. To use SDL_mixer,
 * you must have at least one, but are allowed to have several. Each mixer is
 * responsible for generating a single output stream of mixed audio, usually
 * to an audio device for realtime playback.
 *
 * Mixers are either created to feed an audio device (through
 * MIX_CreateMixerDevice()), or to generate audio to a buffer in memory, where
 * it can be used for anything (through MIX_CreateMixer()).
 *
 * \since This datatype is available since SDL_mixer 3.0.0.
 */
typedef struct MIX_Mixer MIX_Mixer;

/**
 * An opaque object that represents audio data.
 *
 * Generally you load audio data (in whatever file format) into SDL_mixer with
 * MIX_LoadAudio() or one of its several variants, producing a MIX_Audio
 * object.
 *
 * A MIX_Audio represents static audio data; it could be background music, or
 * maybe a laser gun sound effect. It is loaded into RAM and can be played
 * multiple times, possibly on different tracks at the same time.
 *
 * Unlike most other objects, MIX_Audio objects can be shared between mixers.
 *
 * \since This datatype is available since SDL_mixer 3.0.0.
 */
typedef struct MIX_Audio MIX_Audio;

/**
 * An opaque object that represents a source of sound output to be mixed.
 *
 * A MIX_Mixer has an arbitrary number of tracks, and each track manages its
 * own unique audio to be mixed together.
 *
 * Tracks also have other properties: gain, loop points, fading, 3D position,
 * and other attributes that alter the produced sound; many can be altered
 * during playback.
 *
 * \since This datatype is available since SDL_mixer 3.0.0.
 */
typedef struct MIX_Track MIX_Track;

/**
 * An opaque object that represents a grouping of tracks.
 *
 * SDL_mixer offers callbacks at various stages of the mixing pipeline to
 * allow apps to view and manipulate data as it is transformed. Sometimes it
 * is useful to hook in at a point where several tracks--but not all tracks--
 * have been mixed. For example, when a game is in some options menu, perhaps
 * adjusting game audio but not UI sounds could be useful.
 *
 * SDL_mixer allows you to assign several tracks to a group, and receive a
 * callback when that group has finished mixing, with a buffer of just that
 * group's mixed audio, before it mixes into the final output.
 *
 * \since This datatype is available since SDL_mixer 3.0.0.
 */
typedef struct MIX_Group MIX_Group;

/**
 * The current major version of SDL_mixer headers.
 *
 * If this were SDL_mixer version 3.2.1, this value would be 3.
 *
 * \since This macro is available since SDL_mixer 3.0.0.
 */
#define SDL_MIXER_MAJOR_VERSION   3

/**
 * The current minor version of the SDL_mixer headers.
 *
 * If this were SDL_mixer version 3.2.1, this value would be 2.
 *
 * \since This macro is available since SDL_mixer 3.0.0.
 */
#define SDL_MIXER_MINOR_VERSION   2

/**
 * The current micro (or patchlevel) version of the SDL_mixer headers.
 *
 * If this were SDL_mixer version 3.2.1, this value would be 1.
 *
 * \since This macro is available since SDL_mixer 3.0.0.
 */
#define SDL_MIXER_MICRO_VERSION   0

/**
 * This is the current version number macro of the SDL_mixer headers.
 *
 * \since This macro is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_Version
 */
#define SDL_MIXER_VERSION SDL_VERSIONNUM(SDL_MIXER_MAJOR_VERSION, SDL_MIXER_MINOR_VERSION, SDL_MIXER_MICRO_VERSION)

/**
 * This macro will evaluate to true if compiled with SDL_mixer at least X.Y.Z.
 *
 * \since This macro is available since SDL_mixer 3.0.0.
 */
#define SDL_MIXER_VERSION_ATLEAST(X, Y, Z) \
    ((SDL_MIXER_MAJOR_VERSION >= X) && \
     (SDL_MIXER_MAJOR_VERSION > X || SDL_MIXER_MINOR_VERSION >= Y) && \
     (SDL_MIXER_MAJOR_VERSION > X || SDL_MIXER_MINOR_VERSION > Y || SDL_MIXER_MICRO_VERSION >= Z))

/**
 * Get the version of SDL_mixer that is linked against your program.
 *
 * If you are linking to SDL_mixer dynamically, then it is possible that the
 * current version will be different than the version you compiled against.
 * This function returns the current version, while SDL_MIXER_VERSION is the
 * version you compiled with.
 *
 * This function may be called safely at any time, even before MIX_Init().
 *
 * \returns the version of the linked library.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa SDL_MIXER_VERSION
 */
extern SDL_DECLSPEC int SDLCALL MIX_Version(void);

/**
 * Initialize the SDL_mixer library.
 *
 * This must be successfully called once before (almost) any other SDL_mixer
 * function can be used.
 *
 * It is safe to call this multiple times; the library will only initialize
 * once, and won't deinitialize until MIX_Quit() has been called a matching
 * number of times. Extra attempts to init report success.
 *
 * \returns true on success, false on error; call SDL_GetError() for details.
 *
 * \threadsafety This function is not thread safe.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_Quit
 */
extern SDL_DECLSPEC bool SDLCALL MIX_Init(void);

/**
 * Deinitialize the SDL_mixer library.
 *
 * This must be called when done with the library, probably at the end of your
 * program.
 *
 * It is safe to call this multiple times; the library will only deinitialize
 * once, when this function is called the same number of times as MIX_Init was
 * successfully called.
 *
 * Once you have successfully deinitialized the library, it is safe to call
 * MIX_Init to reinitialize it for further use.
 *
 * On successful deinitialization, SDL_mixer will destroy almost all created
 * objects, including objects of type:
 *
 * - MIX_Mixer
 * - MIX_Track
 * - MIX_Audio
 * - MIX_Group
 * - MIX_AudioDecoder
 *
 * ...which is to say: it's possible a single call to this function will clean
 * up anything it allocated, stop all audio output, close audio devices, etc.
 * Don't attempt to destroy objects after this call. The app is still
 * encouraged to manage their resources carefully and clean up first, treating
 * this function as a safety net against memory leaks.
 *
 * \threadsafety This function is not thread safe.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_Init
 */
extern SDL_DECLSPEC void SDLCALL MIX_Quit(void);

/**
 * Report the number of audio decoders available for use.
 *
 * An audio decoder is what turns specific audio file formats into usable PCM
 * data. For example, there might be an MP3 decoder, or a WAV decoder, etc.
 * SDL_mixer probably has several decoders built in.
 *
 * The return value can be used to call MIX_GetAudioDecoder() in a loop.
 *
 * The number of decoders available is decided during MIX_Init() and does not
 * change until the library is deinitialized.
 *
 * \returns the number of decoders available.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_GetAudioDecoder
 */
extern SDL_DECLSPEC int SDLCALL MIX_GetNumAudioDecoders(void);

/**
 * Report the name of a specific audio decoders.
 *
 * An audio decoder is what turns specific audio file formats into usable PCM
 * data. For example, there might be an MP3 decoder, or a WAV decoder, etc.
 * SDL_mixer probably has several decoders built in.
 *
 * The names are capital English letters and numbers, low-ASCII. They don't
 * necessarily map to a specific file format; Some decoders, like "XMP"
 * operate on multiple file types, and more than one decoder might handle the
 * same file type, like "DRMP3" vs "MPG123". Note that in that last example,
 * neither decoder is called "MP3".
 *
 * The index of a specific decoder is decided during MIX_Init() and does not
 * change until the library is deinitialized. Valid indices are between zero
 * and the return value of MIX_GetNumAudioDecoders().
 *
 * The returned pointer is const memory owned by SDL_mixer; do not free it.
 *
 * \param index the index of the decoder to query.
 * \returns a UTF-8 (really, ASCII) string of the decoder's name, or NULL if
 *          `index` is invalid.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_GetNumAudioDecoders
 */
extern SDL_DECLSPEC const char * SDLCALL MIX_GetAudioDecoder(int index);

/**
 * Create a mixer that plays sound directly to an audio device.
 *
 * This is usually the function you want, vs MIX_CreateMixer().
 *
 * You can choose a specific device ID to open, following SDL's usual rules,
 * but often the correct choice is to specify
 * SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK and let SDL figure out what device to use
 * (and seamlessly transition you to new hardware if the default changes).
 *
 * Only playback devices make sense here. Attempting to open a recording
 * device will fail.
 *
 * This will call SDL_Init(SDL_INIT_AUDIO) internally; it's safe to call
 * SDL_Init() before this call, too, if you intend to enumerate audio devices
 * to choose one to open here.
 *
 * An audio format can be requested, and the system will try to set the
 * hardware to those specifications, or as close as possible, but this is just
 * a hint. SDL_mixer will handle all data conversion behind the scenes in any
 * case, and specifying a NULL spec is a reasonable choice. The best reason to
 * specify a format is because you know all your data is in that format and it
 * might save some unnecessary CPU time on conversion.
 *
 * The actual device format chosen is available through MIX_GetMixerFormat().
 *
 * Once a mixer is created, next steps are usually to load audio (through
 * MIX_LoadAudio() and friends), create a track (MIX_CreateTrack()), and play
 * that audio through that track.
 *
 * When done with the mixer, it can be destroyed with MIX_DestroyMixer().
 *
 * \param devid the device to open for playback, or
 *              SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK for the default.
 * \param spec the audio format to request from the device. May be NULL.
 * \returns a mixer that can be used to play audio, or NULL on failure; call
 *          SDL_GetError() for more information.
 *
 * \threadsafety This function should only be called on the main thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_CreateMixer
 * \sa MIX_DestroyMixer
 */
extern SDL_DECLSPEC MIX_Mixer * SDLCALL MIX_CreateMixerDevice(SDL_AudioDeviceID devid, const SDL_AudioSpec *spec);

/**
 * Create a mixer that generates audio to a memory buffer.
 *
 * Usually you want MIX_CreateMixerDevice() instead of this function. The
 * mixer created here can be used with MIX_Generate() to produce more data on
 * demand, as fast as desired.
 *
 * An audio format must be specified. This is the format it will output in.
 * This cannot be NULL.
 *
 * Once a mixer is created, next steps are usually to load audio (through
 * MIX_LoadAudio() and friends), create a track (MIX_CreateTrack()), and play
 * that audio through that track.
 *
 * When done with the mixer, it can be destroyed with MIX_DestroyMixer().
 *
 * \param spec the audio format that mixer will generate.
 * \returns a mixer that can be used to generate audio, or NULL on failure;
 *          call SDL_GetError() for more information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_CreateMixerDevice
 * \sa MIX_DestroyMixer
 */
extern SDL_DECLSPEC MIX_Mixer * SDLCALL MIX_CreateMixer(const SDL_AudioSpec *spec);

/**
 * Free a mixer.
 *
 * If this mixer was created with MIX_CreateMixerDevice(), this function will
 * also close the audio device and call SDL_QuitSubSystem(SDL_INIT_AUDIO).
 *
 * Any MIX_Group or MIX_Track created for this mixer will also be destroyed.
 * Do not access them again or attempt to destroy them after the device is
 * destroyed. MIX_Audio objects will not be destroyed, since they can be
 * shared between mixers (but those will all be destroyed during MIX_Quit()).
 *
 * \param mixer the mixer to destroy.
 *
 * \threadsafety If this is used with a MIX_Mixer from MIX_CreateMixerDevice,
 *               then this function should only be called on the main thread.
 *               If this is used with a MIX_Mixer from MIX_CreateMixer, then
 *               it is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_CreateMixerDevice
 * \sa MIX_CreateMixer
 */
extern SDL_DECLSPEC void SDLCALL MIX_DestroyMixer(MIX_Mixer *mixer);


/**
 * Get the properties associated with a mixer.
 *
 * The following read-only properties are provided by SDL_mixer:
 *
 * - `MIX_PROP_MIXER_DEVICE_NUMBER`: the SDL_AudioDeviceID that this mixer has
 *   opened for playback. This will be zero (no device) if the mixer was
 *   created with Mix_CreateMixer() instead of Mix_CreateMixerDevice().
 *
 * \param mixer the mixer to query.
 * \returns a valid property ID on success or 0 on failure; call
 *          SDL_GetError() for more information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 */
extern SDL_DECLSPEC SDL_PropertiesID SDLCALL MIX_GetMixerProperties(MIX_Mixer *mixer);

#define MIX_PROP_MIXER_DEVICE_NUMBER "SDL_mixer.mixer.device"


/**
 * Get the audio format a mixer is generating.
 *
 * Generally you don't need this information, as SDL_mixer will convert data
 * as necessary between inputs you provide and its output format, but it might
 * be useful if trying to match your inputs to reduce conversion and
 * resampling costs.
 *
 * For mixers created with MIX_CreateMixerDevice(), this is the format of the
 * audio device (and may change later if the device itself changes; SDL_mixer
 * will seamlessly handle this change internally, though).
 *
 * For mixers created with MIX_CreateMixer(), this is the format that
 * MIX_Generate() will produce, as requested at create time, and does not
 * change.
 *
 * Note that internally, SDL_mixer will work in SDL_AUDIO_F32 format before
 * outputting the format specified here, so it would be more efficient to
 * match input data to that, not the final output format.
 *
 * \param mixer the mixer to query.
 * \param spec where to store the mixer audio format.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 */
extern SDL_DECLSPEC bool SDLCALL MIX_GetMixerFormat(MIX_Mixer *mixer, SDL_AudioSpec *spec);

/**
 * Lock a mixer by obtaining its internal mutex.
 *
 * While locked, the mixer will not be able to mix more audio or change its
 * internal state in another thread. Those other threads will block until the
 * mixer is unlocked again.
 *
 * Under the hood, this function calls SDL_LockMutex(), so all the same rules
 * apply: the lock can be recursive, it must be unlocked the same number of
 * times from the same thread that locked it, etc.
 *
 * Just about every SDL_mixer API _also_ locks the mixer while doing its work,
 * as does the SDL audio device thread while actual mixing is in progress, so
 * basic use of this library never requires the app to explicitly lock the
 * device to be thread safe. There are two scenarios where this can be useful,
 * however:
 *
 * - The app has a provided a callback that the mixing thread might call, and
 *   there is some app state that needs to be protected against race
 *   conditions as changes are made and mixing progresses simultaneously. Any
 *   lock can be used for this, but this is a conveniently-available lock.
 * - The app wants to make multiple, atomic changes to the mix. For example,
 *   to start several tracks at the exact same moment, one would lock the
 *   mixer, call MIX_PlayTrack multiple times, and then unlock again; all the
 *   tracks will start mixing on the same sample frame.
 *
 * Each call to this function must be paired with a call to MIX_UnlockMixer
 * from the same thread. It is safe to lock a mixer multiple times; it remains
 * locked until the final matching unlock call.
 *
 * Do not lock the mixer for significant amounts of time, or it can cause
 * audio dropouts. Just do simply things quickly and unlock again.
 *
 * Locking a NULL mixer is a safe no-op.
 *
 * \param mixer the mixer to lock. May be NULL.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_UnlockMixer
 */
extern SDL_DECLSPEC void SDLCALL MIX_LockMixer(MIX_Mixer *mixer);

/**
 * Unlock a mixer previously locked by a call to MIX_LockMixer().
 *
 * While locked, the mixer will not be able to mix more audio or change its
 * internal state another thread. Those other threads will block until the
 * mixer is unlocked again.
 *
 * Under the hood, this function calls SDL_LockMutex(), so all the same rules
 * apply: the lock can be recursive, it must be unlocked the same number of
 * times from the same thread that locked it, etc.
 *
 * Unlocking a NULL mixer is a safe no-op.
 *
 * \param mixer the mixer to unlock. May be NULL.
 *
 * \threadsafety This call must be paired with a previous MIX_LockMixer call
 *               on the same thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_LockMixer
 */
extern SDL_DECLSPEC void SDLCALL MIX_UnlockMixer(MIX_Mixer *mixer);

/**
 * Load audio for playback from an SDL_IOStream.
 *
 * In normal usage, apps should load audio once, maybe at startup, then play
 * it multiple times.
 *
 * When loading audio, it will be cached fully in RAM in its original data
 * format. Each time it plays, the data will be decoded. For example, an MP3
 * will be stored in memory in MP3 format and be decompressed on the fly
 * during playback. This is a tradeoff between i/o overhead and memory usage.
 *
 * If `predecode` is true, the data will be decompressed during load and
 * stored as raw PCM data. This might dramatically increase loading time and
 * memory usage, but there will be no need to decompress data during playback.
 *
 * (One could also use MIX_SetTrackIOStream() to bypass loading the data into
 * RAM upfront at all, but this offers still different tradeoffs. The correct
 * approach depends on the app's needs and employing different approaches in
 * different situations can make sense.)
 *
 * MIX_Audio objects can be shared between mixers. This function takes a
 * MIX_Mixer, to imply this is the most likely place it will be used and
 * loading should try to match its audio format, but the resulting audio can
 * be used elsewhere. If `mixer` is NULL, SDL_mixer will set reasonable
 * defaults.
 *
 * Once a MIX_Audio is created, it can be assigned to a MIX_Track with
 * MIX_SetTrackAudio(), or played without any management with MIX_PlayAudio().
 *
 * When done with a MIX_Audio, it can be freed with MIX_DestroyAudio().
 *
 * This function loads data from an SDL_IOStream. There is also a version that
 * loads from a path on the filesystem (MIX_LoadAudio()), and one that accepts
 * properties for ultimate control (MIX_LoadAudioWithProperties()).
 *
 * The SDL_IOStream provided must be able to seek, or loading will fail. If
 * the stream can't seek (data is coming from an HTTP connection, etc),
 * consider caching the data to memory or disk first and creating a new stream
 * to read from there.
 *
 * \param mixer a mixer this audio is intended to be used with. May be NULL.
 * \param io the SDL_IOStream to load data from.
 * \param predecode if true, data will be fully uncompressed before returning.
 * \param closeio true if SDL_mixer should close `io` before returning
 *                (success or failure).
 * \returns an audio object that can be used to make sound on a mixer, or NULL
 *          on failure; call SDL_GetError() for more information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_DestroyAudio
 * \sa MIX_SetTrackAudio
 * \sa MIX_LoadAudio
 * \sa MIX_LoadAudioWithProperties
 */
extern SDL_DECLSPEC MIX_Audio * SDLCALL MIX_LoadAudio_IO(MIX_Mixer *mixer, SDL_IOStream *io, bool predecode, bool closeio);

/**
 * Load audio for playback from a file.
 *
 * This is equivalent to calling:
 *
 * ```c
 * MIX_LoadAudio_IO(mixer, SDL_IOFromFile(path, "rb"), predecode, true);
 * ```
 *
 * This function loads data from a path on the filesystem. There is also a
 * version that loads from an SDL_IOStream (MIX_LoadAudio_IO()), and one that
 * accepts properties for ultimate control (MIX_LoadAudioWithProperties()).
 *
 * \param mixer a mixer this audio is intended to be used with. May be NULL.
 * \param path the path on the filesystem to load data from.
 * \param predecode if true, data will be fully uncompressed before returning.
 * \returns an audio object that can be used to make sound on a mixer, or NULL
 *          on failure; call SDL_GetError() for more information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_DestroyAudio
 * \sa MIX_SetTrackAudio
 * \sa MIX_LoadAudio_IO
 * \sa MIX_LoadAudioWithProperties
 */
extern SDL_DECLSPEC MIX_Audio * SDLCALL MIX_LoadAudio(MIX_Mixer *mixer, const char *path, bool predecode);

/**
 * Load audio for playback from a memory buffer without making a copy.
 *
 * When loading audio through most other LoadAudio functions, the data will be
 * cached fully in RAM in its original data format, for decoding on-demand.
 * This function does most of the same work as those functions, but instead
 * uses a buffer of memory provided by the app that it does not make a copy
 * of.
 *
 * This buffer must live for the entire time the returned MIX_Audio lives, as
 * the mixer will access the buffer whenever it needs to mix more data.
 *
 * This function is meant to maximize efficiency: if the data is already in
 * memory and can remain there, don't copy it. This data can be in any
 * supported audio file format (WAV, MP3, etc); it will be decoded on the fly
 * while mixing. Unlike MIX_LoadAudio(), there is no `predecode` option
 * offered here, as this is meant to optimize for data that's already in
 * memory and intends to exist there for significant time; since predecoding
 * would only need the file format data once, upfront, one could simply wrap
 * it in SDL_CreateIOFromConstMem() and pass that to MIX_LoadAudio_IO().
 *
 * MIX_Audio objects can be shared between multiple mixers. The `mixer`
 * parameter just suggests the most likely mixer to use this audio, in case
 * some optimization might be applied, but this is not required, and a NULL
 * mixer may be specified.
 *
 * If `free_when_done` is true, SDL_mixer will call `SDL_free(data)` when the
 * returned MIX_Audio is eventually destroyed. This can be useful when the
 * data is not static, but rather loaded elsewhere for this specific MIX_Audio
 * and simply wants to avoid the extra copy.
 *
 * As audio format information is obtained from the file format metadata, this
 * isn't useful for raw PCM data; in that case, use MIX_LoadRawAudioNoCopy()
 * instead, which offers an SDL_AudioSpec.
 *
 * Once a MIX_Audio is created, it can be assigned to a MIX_Track with
 * MIX_SetTrackAudio(), or played without any management with MIX_PlayAudio().
 *
 * When done with a MIX_Audio, it can be freed with MIX_DestroyAudio().
 *
 * \param mixer a mixer this audio is intended to be used with. May be NULL.
 * \param data the buffer where the audio data lives.
 * \param datalen the size, in bytes, of the buffer.
 * \param free_when_done if true, `data` will be given to SDL_free() when the
 *                       MIX_Audio is destroyed.
 * \returns an audio object that can be used to make sound on a mixer, or NULL
 *          on failure; call SDL_GetError() for more information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_DestroyAudio
 * \sa MIX_SetTrackAudio
 * \sa MIX_LoadRawAudioNoCopy
 * \sa MIX_LoadAudio_IO
 */
extern SDL_DECLSPEC MIX_Audio * SDLCALL MIX_LoadAudioNoCopy(MIX_Mixer *mixer, const void *data, size_t datalen, bool free_when_done);

/**
 * Load audio for playback through a collection of properties.
 *
 * Please see MIX_LoadAudio_IO() for a description of what the various
 * LoadAudio functions do. This function uses properties to dictate how it
 * operates, and exposes functionality the other functions don't provide.
 *
 * SDL_PropertiesID are discussed in
 * [SDL's documentation](https://wiki.libsdl.org/SDL3/CategoryProperties)
 * .
 *
 * These are the supported properties:
 *
 * - `MIX_PROP_AUDIO_LOAD_IOSTREAM_POINTER`: a pointer to an SDL_IOStream to
 *   be used to load audio data. Required. This stream must be able to seek!
 * - `MIX_PROP_AUDIO_LOAD_CLOSEIO_BOOLEAN`: true if SDL_mixer should close the
 *   SDL_IOStream before returning (success or failure).
 * - `MIX_PROP_AUDIO_LOAD_PREDECODE_BOOLEAN`: true if SDL_mixer should fully
 *   decode and decompress the data before returning. Otherwise it will be
 *   stored in its original state and decompressed on demand.
 * - `MIX_PROP_AUDIO_LOAD_PREFERRED_MIXER_POINTER`: a pointer to a MIX_Mixer,
 *   in case steps can be made to match its format when decoding. Optional.
 * - `MIX_PROP_AUDIO_LOAD_SKIP_METADATA_TAGS_BOOLEAN`: true to skip parsing
 *   metadata tags, like ID3 and APE tags. This can be used to speed up
 *   loading _if the data definitely doesn't have these tags_. Some decoders
 *   will fail if these tags are present when this property is true.
 * - `MIX_PROP_AUDIO_DECODER_STRING`: the name of the decoder to use for this
 *   data. Optional. If not specified, SDL_mixer will examine the data and
 *   choose the best decoder. These names are the same returned from
 *   MIX_GetAudioDecoder().
 *
 * Specific decoders might accept additional custom properties, such as where
 * to find soundfonts for MIDI playback, etc.
 *
 * \param props a set of properties on how to load audio.
 * \returns an audio object that can be used to make sound on a mixer, or NULL
 *          on failure; call SDL_GetError() for more information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_DestroyAudio
 * \sa MIX_SetTrackAudio
 * \sa MIX_LoadAudio
 * \sa MIX_LoadAudio_IO
 */
extern SDL_DECLSPEC MIX_Audio * SDLCALL MIX_LoadAudioWithProperties(SDL_PropertiesID props);

#define MIX_PROP_AUDIO_LOAD_IOSTREAM_POINTER "SDL_mixer.audio.load.iostream"
#define MIX_PROP_AUDIO_LOAD_CLOSEIO_BOOLEAN "SDL_mixer.audio.load.closeio"
#define MIX_PROP_AUDIO_LOAD_PREDECODE_BOOLEAN "SDL_mixer.audio.load.predecode"
#define MIX_PROP_AUDIO_LOAD_PREFERRED_MIXER_POINTER "SDL_mixer.audio.load.preferred_mixer"
#define MIX_PROP_AUDIO_LOAD_SKIP_METADATA_TAGS_BOOLEAN "SDL_mixer.audio.load.skip_metadata_tags"
#define MIX_PROP_AUDIO_DECODER_STRING "SDL_mixer.audio.decoder"

/**
 * Load raw PCM data from an SDL_IOStream.
 *
 * There are other options for _streaming_ raw PCM: an SDL_AudioStream can be
 * connected to a track, as can an SDL_IOStream, and will read from those
 * sources on-demand when it is time to mix the audio. This function is useful
 * for loading static audio data that is meant to be played multiple times.
 *
 * This function will load the raw data in its entirety and cache it in RAM.
 *
 * MIX_Audio objects can be shared between multiple mixers. The `mixer`
 * parameter just suggests the most likely mixer to use this audio, in case
 * some optimization might be applied, but this is not required, and a NULL
 * mixer may be specified.
 *
 * \param mixer a mixer this audio is intended to be used with. May be NULL.
 * \param io the SDL_IOStream to load data from.
 * \param spec what format the raw data is in.
 * \param closeio true if SDL_mixer should close `io` before returning
 *                (success or failure).
 * \returns an audio object that can be used to make sound on a mixer, or NULL
 *          on failure; call SDL_GetError() for more information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_DestroyAudio
 * \sa MIX_SetTrackAudio
 * \sa MIX_LoadRawAudio
 * \sa MIX_LoadRawAudioNoCopy
 * \sa MIX_LoadAudio_IO
 */
extern SDL_DECLSPEC MIX_Audio * SDLCALL MIX_LoadRawAudio_IO(MIX_Mixer *mixer, SDL_IOStream *io, const SDL_AudioSpec *spec, bool closeio);

/**
 * Load raw PCM data from a memory buffer.
 *
 * There are other options for _streaming_ raw PCM: an SDL_AudioStream can be
 * connected to a track, as can an SDL_IOStream, and will read from those
 * sources on-demand when it is time to mix the audio. This function is useful
 * for loading static audio data that is meant to be played multiple times.
 *
 * This function will load the raw data in its entirety and cache it in RAM,
 * allocating a copy. If the original data will outlive the created MIX_Audio,
 * you can use MIX_LoadRawAudioNoCopy() to avoid extra allocations and copies.
 *
 * MIX_Audio objects can be shared between multiple mixers. The `mixer`
 * parameter just suggests the most likely mixer to use this audio, in case
 * some optimization might be applied, but this is not required, and a NULL
 * mixer may be specified.
 *
 * \param mixer a mixer this audio is intended to be used with. May be NULL.
 * \param data the raw PCM data to load.
 * \param datalen the size, in bytes, of the raw PCM data.
 * \param spec what format the raw data is in.
 * \returns an audio object that can be used to make sound on a mixer, or NULL
 *          on failure; call SDL_GetError() for more information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_DestroyAudio
 * \sa MIX_SetTrackAudio
 * \sa MIX_LoadRawAudio_IO
 * \sa MIX_LoadRawAudioNoCopy
 * \sa MIX_LoadAudio_IO
 */
extern SDL_DECLSPEC MIX_Audio * SDLCALL MIX_LoadRawAudio(MIX_Mixer *mixer, const void *data, size_t datalen, const SDL_AudioSpec *spec);

/**
 * Load raw PCM data from a memory buffer without making a copy.
 *
 * This buffer must live for the entire time the returned MIX_Audio lives, as
 * the mixer will access the buffer whenever it needs to mix more data.
 *
 * This function is meant to maximize efficiency: if the data is already in
 * memory and can remain there, don't copy it. But it can also lead to some
 * interesting tricks, like changing the buffer's contents to alter multiple
 * playing tracks at once. (But, of course, be careful when being too clever.)
 *
 * MIX_Audio objects can be shared between multiple mixers. The `mixer`
 * parameter just suggests the most likely mixer to use this audio, in case
 * some optimization might be applied, but this is not required, and a NULL
 * mixer may be specified.
 *
 * If `free_when_done` is true, SDL_mixer will call `SDL_free(data)` when the
 * returned MIX_Audio is eventually destroyed. This can be useful when the
 * data is not static, but rather composed dynamically for this specific
 * MIX_Audio and simply wants to avoid the extra copy.
 *
 * \param mixer a mixer this audio is intended to be used with. May be NULL.
 * \param data the buffer where the raw PCM data lives.
 * \param datalen the size, in bytes, of the buffer.
 * \param spec what format the raw data is in.
 * \param free_when_done if true, `data` will be given to SDL_free() when the
 *                       MIX_Audio is destroyed.
 * \returns an audio object that can be used to make sound on a mixer, or NULL
 *          on failure; call SDL_GetError() for more information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_DestroyAudio
 * \sa MIX_SetTrackAudio
 * \sa MIX_LoadRawAudio
 * \sa MIX_LoadRawAudio_IO
 * \sa MIX_LoadAudio_IO
 */
extern SDL_DECLSPEC MIX_Audio * SDLCALL MIX_LoadRawAudioNoCopy(MIX_Mixer *mixer, const void *data, size_t datalen, const SDL_AudioSpec *spec, bool free_when_done);

/**
 * Create a MIX_Audio that generates a sinewave.
 *
 * This is useful just to have _something_ to play, perhaps for testing or
 * debugging purposes.
 *
 * You specify its frequency in Hz (determines the pitch of the sinewave's
 * audio) and amplitude (determines the volume of the sinewave: 1.0f is very
 * loud, 0.0f is silent).
 *
 * A number of milliseconds of audio to generate can be specified. Specifying
 * a value less than zero will generate infinite audio (when assigned to a
 * MIX_Track, the sinewave will play forever).
 *
 * MIX_Audio objects can be shared between multiple mixers. The `mixer`
 * parameter just suggests the most likely mixer to use this audio, in case
 * some optimization might be applied, but this is not required, and a NULL
 * mixer may be specified.
 *
 * \param mixer a mixer this audio is intended to be used with. May be NULL.
 * \param hz the sinewave's frequency in Hz.
 * \param amplitude the sinewave's amplitude from 0.0f to 1.0f.
 * \param ms the maximum number of milliseconds of audio to generate, or less
 *           than zero to generate infinite audio.
 * \returns an audio object that can be used to make sound on a mixer, or NULL
 *          on failure; call SDL_GetError() for more information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_DestroyAudio
 * \sa MIX_SetTrackAudio
 * \sa MIX_LoadAudio_IO
 */
extern SDL_DECLSPEC MIX_Audio * SDLCALL MIX_CreateSineWaveAudio(MIX_Mixer *mixer, int hz, float amplitude, Sint64 ms);


/**
 * Get the properties associated with a MIX_Audio.
 *
 * SDL_mixer offers some properties of its own, but this can also be a
 * convenient place to store app-specific data.
 *
 * A SDL_PropertiesID is created the first time this function is called for a
 * given MIX_Audio, if necessary.
 *
 * The following read-only properties are provided by SDL_mixer:
 *
 * - `MIX_PROP_METADATA_TITLE_STRING`: the audio's title ("Smells Like Teen
 *   Spirit").
 * - `MIX_PROP_METADATA_ARTIST_STRING`: the audio's artist name ("Nirvana").
 * - `MIX_PROP_METADATA_ALBUM_STRING`: the audio's album name ("Nevermind").
 * - `MIX_PROP_METADATA_COPYRIGHT_STRING`: the audio's copyright info
 *   ("Copyright (c) 1991")
 * - `MIX_PROP_METADATA_TRACK_NUMBER`: the audio's track number on the album
 *   (1)
 * - `MIX_PROP_METADATA_TOTAL_TRACKS_NUMBER`: the total tracks on the album
 *   (13)
 * - `MIX_PROP_METADATA_YEAR_NUMBER`: the year the audio was released (1991)
 * - `MIX_PROP_METADATA_DURATION_FRAMES_NUMBER`: The sample frames worth of
 *   PCM data that comprise this audio. It might be off by a little if the
 *   decoder only knows the duration as a unit of time.
 * - `MIX_PROP_METADATA_DURATION_INFINITE_BOOLEAN`: if true, audio never runs
 *   out of sound to generate. This isn't necessarily always known to
 *   SDL_mixer, though.
 *
 * Other properties, documented with MIX_LoadAudioWithProperties(), may also
 * be present.
 *
 * Note that the metadata properties are whatever SDL_mixer finds in things
 * like ID3 tags, and they often have very little standardized formatting, may
 * be missing, and can be completely wrong if the original data is
 * untrustworthy (like an MP3 from a P2P file sharing service).
 *
 * \param audio the audio to query.
 * \returns a valid property ID on success or 0 on failure; call
 *          SDL_GetError() for more information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 */
extern SDL_DECLSPEC SDL_PropertiesID SDLCALL MIX_GetAudioProperties(MIX_Audio *audio);

#define MIX_PROP_METADATA_TITLE_STRING "SDL_mixer.metadata.title"
#define MIX_PROP_METADATA_ARTIST_STRING "SDL_mixer.metadata.artist"
#define MIX_PROP_METADATA_ALBUM_STRING "SDL_mixer.metadata.album"
#define MIX_PROP_METADATA_COPYRIGHT_STRING "SDL_mixer.metadata.copyright"
#define MIX_PROP_METADATA_TRACK_NUMBER "SDL_mixer.metadata.track"
#define MIX_PROP_METADATA_TOTAL_TRACKS_NUMBER "SDL_mixer.metadata.total_tracks"
#define MIX_PROP_METADATA_YEAR_NUMBER "SDL_mixer.metadata.year"
#define MIX_PROP_METADATA_DURATION_FRAMES_NUMBER "SDL_mixer.metadata.duration_frames"
#define MIX_PROP_METADATA_DURATION_INFINITE_BOOLEAN "SDL_mixer.metadata.duration_infinite"


/**
 * Get the length of a MIX_Audio's playback in sample frames.
 *
 * This information is also available via the
 * MIX_PROP_METADATA_DURATION_FRAMES_NUMBER property, but it's common enough
 * to provide a simple accessor function.
 *
 * This reports the length of the data in _sample frames_, so sample-perfect
 * mixing can be possible. Sample frames are only meaningful as a measure of
 * time if the sample rate (frequency) is also known. To convert from sample
 * frames to milliseconds, use MIX_AudioFramesToMS().
 *
 * Not all audio file formats can report the complete length of the data they
 * will produce through decoding: some can't calculate it, some might produce
 * infinite audio.
 *
 * Also, some file formats can only report duration as a unit of time, which
 * means SDL_mixer might have to estimate sample frames from that information.
 * With less precision, the reported duration might be off by a few sample
 * frames in either direction.
 *
 * This will return a value >= 0 if a duration is known. It might also return
 * MIX_DURATION_UNKNOWN or MIX_DURATION_INFINITE.
 *
 * \param audio the audio to query.
 * \returns the length of the audio in sample frames, or MIX_DURATION_UNKNOWN
 *          or MIX_DURATION_INFINITE.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 */
extern SDL_DECLSPEC Sint64 SDLCALL MIX_GetAudioDuration(MIX_Audio *audio);

#define MIX_DURATION_UNKNOWN -1
#define MIX_DURATION_INFINITE -2


/**
 * Query the initial audio format of a MIX_Audio.
 *
 * Note that some audio files can change format in the middle; some explicitly
 * support this, but a more common example is two MP3 files concatenated
 * together. In many cases, SDL_mixer will correctly handle these sort of
 * files, but this function will only report the initial format a file uses.
 *
 * \param audio the audio to query.
 * \param spec on success, audio format details will be stored here.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 */
extern SDL_DECLSPEC bool SDLCALL MIX_GetAudioFormat(MIX_Audio *audio, SDL_AudioSpec *spec);

/**
 * Destroy the specified audio.
 *
 * MIX_Audio is reference-counted internally, so this function only unrefs it.
 * If doing so causes the reference count to drop to zero, the MIX_Audio will
 * be deallocated. This allows the system to safely operate if the audio is
 * still assigned to a MIX_Track at the time of destruction. The actual
 * destroying will happen when the track stops using it.
 *
 * But from the caller's perspective, once this function is called, it should
 * assume the `audio` pointer has become invalid.
 *
 * Destroying a NULL MIX_Audio is a legal no-op.
 *
 * \param audio the audio to destroy.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 */
extern SDL_DECLSPEC void SDLCALL MIX_DestroyAudio(MIX_Audio *audio);

/**
 * Create a new track on a mixer.
 *
 * A track provides a single source of audio. All currently-playing tracks
 * will be processed and mixed together to form the final output from the
 * mixer.
 *
 * There are no limits to the number of tracks one may create, beyond running
 * out of memory, but in normal practice there are a small number of tracks
 * that are reused between all loaded audio as appropriate.
 *
 * Tracks are unique to a specific MIX_Mixer and can't be transferred between
 * them.
 *
 * \param mixer the mixer on which to create this track.
 * \returns a new MIX_Track on success, NULL on error; call SDL_GetError() for
 *          more informations.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_DestroyTrack
 */
extern SDL_DECLSPEC MIX_Track * SDLCALL MIX_CreateTrack(MIX_Mixer *mixer);

/**
 * Destroy the specified track.
 *
 * If the track is currently playing, it will be stopped immediately, without
 * any fadeout. If there is a callback set through
 * MIX_SetTrackStoppedCallback(), it will _not_ be called.
 *
 * If the mixer is currently mixing in another thread, this will block until
 * it finishes.
 *
 * Destroying a NULL MIX_Track is a legal no-op.
 *
 * \param track the track to destroy.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 */
extern SDL_DECLSPEC void SDLCALL MIX_DestroyTrack(MIX_Track *track);

/**
 * Get the properties associated with a track.
 *
 * Currently SDL_mixer assigns no properties of its own to a track, but this
 * can be a convenient place to store app-specific data.
 *
 * A SDL_PropertiesID is created the first time this function is called for a
 * given track.
 *
 * \param track the track to query.
 * \returns a valid property ID on success or 0 on failure; call
 *          SDL_GetError() for more information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 */
extern SDL_DECLSPEC SDL_PropertiesID SDLCALL MIX_GetTrackProperties(MIX_Track *track);

/**
 * Get the MIX_Mixer that owns a MIX_Track.
 *
 * This is the mixer pointer that was passed to MIX_CreateTrack().
 *
 * \param track the track to query.
 * \returns the mixer associated with the track, or NULL on error; call
 *          SDL_GetError() for more information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 */
extern SDL_DECLSPEC MIX_Mixer * SDLCALL MIX_GetTrackMixer(MIX_Track *track);

/**
 * Set a MIX_Track's input to a MIX_Audio.
 *
 * A MIX_Audio is audio data stored in RAM (possibly still in a compressed
 * form). One MIX_Audio can be assigned to multiple tracks at once.
 *
 * Once a track has a valid input, it can start mixing sound by calling
 * MIX_PlayTrack(), or possibly MIX_PlayTag().
 *
 * Calling this function with a NULL audio input is legal, and removes any
 * input from the track. If the track was currently playing, the next time the
 * mixer runs, it'll notice this and mark the track as stopped, calling any
 * assigned MIX_TrackStoppedCallback.
 *
 * It is legal to change the input of a track while it's playing, however some
 * states, like loop points, may cease to make sense with the new audio. In
 * such a case, one can call MIX_PlayTrack again to adjust parameters.
 *
 * The track will hold a reference to the provided MIX_Audio, so it is safe to
 * call MIX_DestroyAudio() on it while the track is still using it. The track
 * will drop its reference (and possibly free the resources) once it is no
 * longer using the MIX_Audio.
 *
 * \param track the track on which to set a new audio input.
 * \param audio the new audio input to set. May be NULL.
 * \returns true on success, false on error; call SDL_GetError() for details.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 */
extern SDL_DECLSPEC bool SDLCALL MIX_SetTrackAudio(MIX_Track *track, MIX_Audio *audio);

/**
 * Set a MIX_Track's input to an SDL_AudioStream.
 *
 * Using an audio stream allows the application to generate any type of audio,
 * in any format, possibly procedurally or on-demand, and mix in with all
 * other tracks.
 *
 * When a track uses an audio stream, it will call SDL_GetAudioStreamData as
 * it needs more audio to mix. The app can either buffer data to the stream
 * ahead of time, or set a callback on the stream to provide data as needed.
 * Please refer to SDL's documentation for details.
 *
 * A given audio stream may only be assigned to a single track at a time;
 * duplicate assignments won't return an error, but assigning a stream to
 * multiple tracks will cause each track to read from the stream arbitrarily,
 * causing confusion and incorrect mixing.
 *
 * Once a track has a valid input, it can start mixing sound by calling
 * MIX_PlayTrack(), or possibly MIX_PlayTag().
 *
 * Calling this function with a NULL audio stream is legal, and removes any
 * input from the track. If the track was currently playing, the next time the
 * mixer runs, it'll notice this and mark the track as stopped, calling any
 * assigned MIX_TrackStoppedCallback.
 *
 * It is legal to change the input of a track while it's playing, however some
 * states, like loop points, may cease to make sense with the new audio. In
 * such a case, one can call MIX_PlayTrack again to adjust parameters.
 *
 * The provided audio stream must remain valid until the track no longer needs
 * it (either by changing the track's input or destroying the track).
 *
 * \param track the track on which to set a new audio input.
 * \param stream the audio stream to use as the track's input.
 * \returns true on success, false on error; call SDL_GetError() for details.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 */
extern SDL_DECLSPEC bool SDLCALL MIX_SetTrackAudioStream(MIX_Track *track, SDL_AudioStream *stream);

/**
 * Set a MIX_Track's input to an SDL_IOStream.
 *
 * This is not the recommended way to set a track's input, but this can be
 * useful for a very specific scenario: a large file, to be played once, that
 * must be read from disk in small chunks as needed. In most cases, however,
 * it is preferable to create a MIX_Audio ahead of time and use
 * MIX_SetTrackAudio() instead.
 *
 * The stream supplied here should provide an audio file in a supported
 * format. SDL_mixer will parse it during this call to make sure it's valid,
 * and then will read file data from the stream as it needs to decode more
 * during mixing.
 *
 * The stream must be able to seek through the complete set of data, or this
 * function will fail.
 *
 * A given IOStream may only be assigned to a single track at a time;
 * duplicate assignments won't return an error, but assigning a stream to
 * multiple tracks will cause each track to read from the stream arbitrarily,
 * causing confusion, incorrect mixing, or failure to decode.
 *
 * Once a track has a valid input, it can start mixing sound by calling
 * MIX_PlayTrack(), or possibly MIX_PlayTag().
 *
 * Calling this function with a NULL stream is legal, and removes any input
 * from the track. If the track was currently playing, the next time the mixer
 * runs, it'll notice this and mark the track as stopped, calling any assigned
 * MIX_TrackStoppedCallback.
 *
 * It is legal to change the input of a track while it's playing, however some
 * states, like loop points, may cease to make sense with the new audio. In
 * such a case, one can call MIX_PlayTrack again to adjust parameters.
 *
 * The provided stream must remain valid until the track no longer needs it
 * (either by changing the track's input or destroying the track).
 *
 * \param track the track on which to set a new audio input.
 * \param io the new i/o stream to use as the track's input.
 * \param closeio if true, close the stream when done with it.
 * \returns true on success, false on error; call SDL_GetError() for details.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_SetTrackRawIOStream
 */
extern SDL_DECLSPEC bool SDLCALL MIX_SetTrackIOStream(MIX_Track *track, SDL_IOStream *io, bool closeio);

/**
 * Set a MIX_Track's input to an SDL_IOStream providing raw PCM data.
 *
 * This is not the recommended way to set a track's input, but this can be
 * useful for a very specific scenario: a large file, to be played once, that
 * must be read from disk in small chunks as needed. In most cases, however,
 * it is preferable to create a MIX_Audio ahead of time and use
 * MIX_SetTrackAudio() instead.
 *
 * Also, an MIX_SetTrackAudioStream() can _also_ provide raw PCM audio to a
 * track, via an SDL_AudioStream, which might be preferable unless the data is
 * already coming directly from an SDL_IOStream.
 *
 * The stream supplied here should provide an audio in raw PCM format.
 *
 * A given IOStream may only be assigned to a single track at a time;
 * duplicate assignments won't return an error, but assigning a stream to
 * multiple tracks will cause each track to read from the stream arbitrarily,
 * causing confusion and incorrect mixing.
 *
 * Once a track has a valid input, it can start mixing sound by calling
 * MIX_PlayTrack(), or possibly MIX_PlayTag().
 *
 * Calling this function with a NULL stream is legal, and removes any input
 * from the track. If the track was currently playing, the next time the mixer
 * runs, it'll notice this and mark the track as stopped, calling any assigned
 * MIX_TrackStoppedCallback.
 *
 * It is legal to change the input of a track while it's playing, however some
 * states, like loop points, may cease to make sense with the new audio. In
 * such a case, one can call MIX_PlayTrack again to adjust parameters.
 *
 * The provided stream must remain valid until the track no longer needs it
 * (either by changing the track's input or destroying the track).
 *
 * \param track the track on which to set a new audio input.
 * \param io the new i/o stream to use as the track's input.
 * \param spec the format of the PCM data that the SDL_IOStream will provide.
 * \param closeio if true, close the stream when done with it.
 * \returns true on success, false on error; call SDL_GetError() for details.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_SetTrackAudioStream
 * \sa MIX_SetTrackIOStream
 */
extern SDL_DECLSPEC bool SDLCALL MIX_SetTrackRawIOStream(MIX_Track *track, SDL_IOStream *io, const SDL_AudioSpec *spec, bool closeio);


/**
 * Assign an arbitrary tag to a track.
 *
 * A tag can be any valid C string in UTF-8 encoding. It can be useful to
 * group tracks in various ways. For example, everything in-game might be
 * marked as "game", so when the user brings up the settings menu, the app can
 * pause all tracks involved in gameplay at once, but keep background music
 * and menu sound effects running.
 *
 * A track can have as many tags as desired, until the machine runs out of
 * memory.
 *
 * It's legal to add the same tag to a track more than once; the extra
 * attempts will report success but not change anything.
 *
 * Tags can later be removed with MIX_UntagTrack().
 *
 * \param track the track to add a tag to.
 * \param tag the tag to add.
 * \returns true on success, false on error; call SDL_GetError() for details.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_UntagTrack
 */
extern SDL_DECLSPEC bool SDLCALL MIX_TagTrack(MIX_Track *track, const char *tag);

/**
 * Remove an arbitrary tag from a track.
 *
 * A tag can be any valid C string in UTF-8 encoding. It can be useful to
 * group tracks in various ways. For example, everything in-game might be
 * marked as "game", so when the user brings up the settings menu, the app can
 * pause all tracks involved in gameplay at once, but keep background music
 * and menu sound effects running.
 *
 * It's legal to remove a tag that the track doesn't have; this function
 * doesn't report errors, so this simply does nothing.
 *
 * Specifying a NULL tag will remove all tags on a track.
 *
 * \param track the track from which to remove a tag.
 * \param tag the tag to remove, or NULL to remove all current tags.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_TagTrack
 */
extern SDL_DECLSPEC void SDLCALL MIX_UntagTrack(MIX_Track *track, const char *tag);

/**
 * Get the tags currently associated with a track.
 *
 * Tags are not provided in any guaranteed order.
 *
 * \param track the track to query.
 * \param count a pointer filled in with the number of tags returned, can be
 *              NULL.
 * \returns an array of the tags, NULL-terminated, or NULL on failure; call
 *          SDL_GetError() for more information. This is a single allocation
 *          that should be freed with SDL_free() when it is no longer needed.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 */
extern SDL_DECLSPEC char ** SDLCALL MIX_GetTrackTags(MIX_Track *track, int *count);

/**
 * Get all tracks with a specific tag.
 *
 * Tracks are not provided in any guaranteed order.
 *
 * \param mixer the mixer to query.
 * \param tag the tag to search.
 * \param count a pointer filled in with the number of tracks returned, can be
 *              NULL.
 * \returns an array of the tracks, NULL-terminated, or NULL on failure; call
 *          SDL_GetError() for more information. The returned pointer should
 *          be freed with SDL_free() when it is no longer needed.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 */
extern SDL_DECLSPEC MIX_Track ** SDLCALL MIX_GetTaggedTracks(MIX_Mixer *mixer, const char *tag, int *count);

/**
 * Seek a playing track to a new position in its input.
 *
 * (Not to be confused with MIX_SetTrack3DPosition(), which is positioning of
 * the track in 3D space, not the playback position of its audio data.)
 *
 * On a playing track, the next time the mixer runs, it will start mixing from
 * the new position.
 *
 * Position is defined in _sample frames_ of decoded audio, not units of time,
 * so that sample-perfect mixing can be achieved. To instead operate in units
 * of time, use MIX_TrackMSToFrames() to get the approximate sample frames for
 * a given tick.
 *
 * This function requires an input that can seek (so it can not be used if the
 * input was set with MIX_SetTrackAudioStream()), and a audio file format that
 * allows seeking. SDL_mixer's decoders for some file formats do not offer
 * seeking, or can only seek to times, not exact sample frames, in which case
 * the final position may be off by some amount of sample frames. Please check
 * your audio data and file bug reports if appropriate.
 *
 * It's legal to call this function on a track that is stopped, but a future
 * call to MIX_PlayTrack() will reset the start position anyhow. Paused tracks
 * will resume at the new input position.
 *
 * \param track the track to change.
 * \param frames the sample frame position to seek to.
 * \returns true on success, false on error; call SDL_GetError() for details.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_GetTrackPlaybackPosition
 */
extern SDL_DECLSPEC bool SDLCALL MIX_SetTrackPlaybackPosition(MIX_Track *track, Sint64 frames);

/**
 * Get the current input position of a playing track.
 *
 * (Not to be confused with MIX_GetTrack3DPosition(), which is positioning of
 * the track in 3D space, not the playback position of its audio data.)
 *
 * Position is defined in _sample frames_ of decoded audio, not units of time,
 * so that sample-perfect mixing can be achieved. To instead operate in units
 * of time, use MIX_TrackFramesToMS() to convert the return value to
 * milliseconds.
 *
 * Stopped and paused tracks will report the position when they halted.
 * Playing tracks will report the current position, which will change over
 * time.
 *
 * \param track the track to change.
 * \returns the track's current sample frame position, or -1 on error; call
 *          SDL_GetError() for details.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_SetTrackPlaybackPosition
 */
extern SDL_DECLSPEC Sint64 SDLCALL MIX_GetTrackPlaybackPosition(MIX_Track *track);

/**
 * Query whether a given track is fading.
 *
 * This specifically checks if the track is _not stopped_ (paused or playing),
 * and it is fading in or out, and returns the number of frames remaining in
 * the fade.
 *
 * If fading out, the returned value will be negative. When fading in, the
 * returned value will be positive. If not fading, this function returns zero.
 *
 * On various errors (MIX_Init() was not called, the track is NULL), this
 * returns 0, but there is no mechanism to distinguish errors from tracks that
 * aren't fading.
 *
 * \param track the track to query.
 * \returns less than 0 if the track is fading out, greater than 0 if fading
 *          in, zero otherwise.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 */
extern SDL_DECLSPEC Sint64 SDLCALL MIX_GetTrackFadeFrames(MIX_Track *track);

/**
 * Query how many loops remain for a given track.
 *
 * This returns the number of loops still pending; if a track will eventually
 * complete and loop to play again one more time, this will return 1. If a
 * track _was_ looping but is on its final iteration of the loop (will stop
 * when this iteration completes), this will return zero.
 *
 * A track that is looping infinitely will return -1. This value does not
 * report an error in this case.
 *
 * A track that is stopped (not playing and not paused) will have zero loops
 * remaining.
 *
 * On various errors (MIX_Init() was not called, the track is NULL), this
 * returns zero, but there is no mechanism to distinguish errors from
 * non-looping tracks.
 *
 * \param track the track to query.
 * \returns the number of pending loops, zero if not looping, and -1 if
 *          looping infinitely.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 */
extern SDL_DECLSPEC int SDLCALL MIX_GetTrackLoops(MIX_Track *track);

/**
 * Change the number of times a currently-playing track will loop.
 *
 * This replaces any previously-set remaining loops. A value of 1 will loop to
 * the start of playback one time. Zero will not loop at all. A value of -1
 * requests infinite loops. If the input is not seekable and `num_loops` isn't
 * zero, this function will report success but the track will stop at the
 * point it should loop.
 *
 * The new loop count replaces any previous state, even if the track has
 * already looped.
 *
 * This has no effect on a track that is stopped, or rather, starting a
 * stopped track later will set a new loop count, replacing this value.
 * Stopped tracks can specify a loop count while starting via
 * MIX_PROP_PLAY_LOOPS_NUMBER. This function is intended to alter that count
 * in the middle of playback.
 *
 * \param track the track to configure.
 * \param num_loops new number of times to loop. Zero to disable looping, -1
 *                  to loop infinitely.
 * \returns true on success, false on error; call SDL_GetError() for details.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_GetTrackLoops
 */
extern SDL_DECLSPEC bool SDLCALL MIX_SetTrackLoops(MIX_Track *track, int num_loops);

/**
 * Query the MIX_Audio assigned to a track.
 *
 * This returns the MIX_Audio object currently assigned to `track` through a
 * call to MIX_SetTrackAudio(). If there is none assigned, or the track has an
 * input that isn't a MIX_Audio (such as an SDL_AudioStream or SDL_IOStream),
 * this will return NULL.
 *
 * On various errors (MIX_Init() was not called, the track is NULL), this
 * returns NULL, but there is no mechanism to distinguish errors from tracks
 * without a valid input.
 *
 * \param track the track to query.
 * \returns a MIX_Audio if available, NULL if not.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_GetTrackAudioStream
 */
extern SDL_DECLSPEC MIX_Audio * SDLCALL MIX_GetTrackAudio(MIX_Track *track);

/**
 * Query the SDL_AudioStream assigned to a track.
 *
 * This returns the SDL_AudioStream object currently assigned to `track`
 * through a call to MIX_SetTrackAudioStream(). If there is none assigned, or
 * the track has an input that isn't an SDL_AudioStream (such as a MIX_Audio
 * or SDL_IOStream), this will return NULL.
 *
 * On various errors (MIX_Init() was not called, the track is NULL), this
 * returns NULL, but there is no mechanism to distinguish errors from tracks
 * without a valid input.
 *
 * \param track the track to query.
 * \returns an SDL_AudioStream if available, NULL if not.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_GetTrackAudio
 */
extern SDL_DECLSPEC SDL_AudioStream * SDLCALL MIX_GetTrackAudioStream(MIX_Track *track);

/**
 * Return the number of sample frames remaining to be mixed in a track.
 *
 * If the track is playing or paused, and its total duration is known, this
 * will report how much audio is left to mix. If the track is playing, future
 * calls to this function will report different values.
 *
 * Remaining audio is defined in _sample frames_ of decoded audio, not units
 * of time, so that sample-perfect mixing can be achieved. To instead operate
 * in units of time, use MIX_TrackFramesToMS() to convert the return value to
 * milliseconds.
 *
 * This function does not take into account fade-outs or looping, just the
 * current mixing position vs the duration of the track.
 *
 * If the duration of the track isn't known, or `track` is NULL, this function
 * returns -1. A stopped track reports 0.
 *
 * \param track the track to query.
 * \returns the total sample frames still to be mixed, or -1 if unknown.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 */
extern SDL_DECLSPEC Sint64 SDLCALL MIX_GetTrackRemaining(MIX_Track *track);

/**
 * Convert milliseconds to sample frames for a track's current format.
 *
 * This calculates time based on the track's current input format, which can
 * change when its input does, and also if that input changes formats
 * mid-stream (for example, if decoding a file that is two MP3s concatenated
 * together).
 *
 * On various errors (MIX_Init() was not called, the track is NULL), this
 * returns -1. If the track has no input, this returns -1. If `ms` is < 0,
 * this returns -1.
 *
 * \param track the track to query.
 * \param ms the milliseconds to convert to track-specific sample frames.
 * \returns Converted number of sample frames, or -1 for errors/no input; call
 *          SDL_GetError() for details.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_TrackFramesToMS
 */
extern SDL_DECLSPEC Sint64 SDLCALL MIX_TrackMSToFrames(MIX_Track *track, Sint64 ms);

/**
 * Convert sample frames for a track's current format to milliseconds.
 *
 * This calculates time based on the track's current input format, which can
 * change when its input does, and also if that input changes formats
 * mid-stream (for example, if decoding a file that is two MP3s concatenated
 * together).
 *
 * Sample frames are more precise than milliseconds, so out of necessity, this
 * function will approximate by rounding down to the closest full millisecond.
 *
 * On various errors (MIX_Init() was not called, the track is NULL), this
 * returns -1. If the track has no input, this returns -1. If `frames` is < 0,
 * this returns -1.
 *
 * \param track the track to query.
 * \param frames the track-specific sample frames to convert to milliseconds.
 * \returns Converted number of milliseconds, or -1 for errors/no input; call
 *          SDL_GetError() for details.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_TrackMSToFrames
 */
extern SDL_DECLSPEC Sint64 SDLCALL MIX_TrackFramesToMS(MIX_Track *track, Sint64 frames);

/**
 * Convert milliseconds to sample frames for a MIX_Audio's format.
 *
 * This calculates time based on the audio's initial format, even if the
 * format would change mid-stream.
 *
 * If `ms` is < 0, this returns -1.
 *
 * \param audio the audio to query.
 * \param ms the milliseconds to convert to audio-specific sample frames.
 * \returns Converted number of sample frames, or -1 for errors/no input; call
 *          SDL_GetError() for details.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_AudioFramesToMS
 */
extern SDL_DECLSPEC Sint64 SDLCALL MIX_AudioMSToFrames(MIX_Audio *audio, Sint64 ms);

/**
 * Convert sample frames for a MIX_Audio's format to milliseconds.
 *
 * This calculates time based on the audio's initial format, even if the
 * format would change mid-stream.
 *
 * Sample frames are more precise than milliseconds, so out of necessity, this
 * function will approximate by rounding down to the closest full millisecond.
 *
 * If `frames` is < 0, this returns -1.
 *
 * \param audio the audio to query.
 * \param frames the audio-specific sample frames to convert to milliseconds.
 * \returns Converted number of milliseconds, or -1 for errors/no input; call
 *          SDL_GetError() for details.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_AudioMSToFrames
 */
extern SDL_DECLSPEC Sint64 SDLCALL MIX_AudioFramesToMS(MIX_Audio *audio, Sint64 frames);

/**
 * Convert milliseconds to sample frames at a specific sample rate.
 *
 * If `sample_rate` is <= 0, this returns -1. If `ms` is < 0, this returns -1.
 *
 * \param sample_rate the sample rate to use for conversion.
 * \param ms the milliseconds to convert to rate-specific sample frames.
 * \returns Converted number of sample frames, or -1 for errors; call
 *          SDL_GetError() for details.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_FramesToMS
 */
extern SDL_DECLSPEC Sint64 SDLCALL MIX_MSToFrames(int sample_rate, Sint64 ms);

/**
 * Convert sample frames, at a specific sample rate, to milliseconds.
 *
 * Sample frames are more precise than milliseconds, so out of necessity, this
 * function will approximate by rounding down to the closest full millisecond.
 *
 * If `sample_rate` is <= 0, this returns -1. If `frames` is < 0, this returns
 * -1.
 *
 * \param sample_rate the sample rate to use for conversion.
 * \param frames the rate-specific sample frames to convert to milliseconds.
 * \returns Converted number of milliseconds, or -1 for errors; call
 *          SDL_GetError() for details.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_MSToFrames
 */
extern SDL_DECLSPEC Sint64 SDLCALL MIX_FramesToMS(int sample_rate, Sint64 frames);


/* operations that deal with actual mixing/playback... */

/**
 * Start (or restart) mixing a track for playback.
 *
 * The track will use whatever input was last assigned to it when playing; an
 * input must be assigned to this track or this function will fail. Inputs are
 * assigned with calls to MIX_SetTrackAudio(), MIX_SetTrackAudioStream(), or
 * MIX_SetTrackIOStream().
 *
 * If the track is already playing, or paused, this will restart the track
 * with the newly-specified parameters.
 *
 * As there are several parameters, and more may be added in the future, they
 * are specified with an SDL_PropertiesID. The parameters have reasonable
 * defaults, and specifying a 0 for `options` will choose defaults for
 * everything.
 *
 * SDL_PropertiesID are discussed in
 * [SDL's documentation](https://wiki.libsdl.org/SDL3/CategoryProperties)
 * .
 *
 * These are the supported properties:
 *
 * - `MIX_PROP_PLAY_LOOPS_NUMBER`: The number of times to loop the track when
 *   it reaches the end. A value of 1 will loop to the start one time. Zero
 *   will not loop at all. A value of -1 requests infinite loops. If the input
 *   is not seekable and this value isn't zero, this function will report
 *   success but the track will stop at the point it should loop. Default 0.
 * - `MIX_PROP_PLAY_MAX_FRAME_NUMBER`: Mix at most to this sample frame
 *   position in the track. This will be treated as if the input reach EOF at
 *   this point in the audio file. If -1, mix all available audio without a
 *   limit. Default -1.
 * - `MIX_PROP_PLAY_MAX_MILLISECONDS_NUMBER`: The same as using the
 *   MIX_PROP_PLAY_MAX_FRAME_NUMBER property, but the value is specified in
 *   milliseconds instead of sample frames. If both properties are specified,
 *   the sample frames value is favored. Default -1.
 * - `MIX_PROP_PLAY_START_FRAME_NUMBER`: Start mixing from this sample frame
 *   position in the track's input. A value <= 0 will begin from the start of
 *   the track's input. If the input is not seekable and this value is > 0,
 *   this function will report failure. Default 0.
 * - `MIX_PROP_PLAY_START_MILLISECOND_NUMBER`: The same as using the
 *   MIX_PROP_PLAY_START_FRAME_NUMBER property, but the value is specified in
 *   milliseconds instead of sample frames. If both properties are specified,
 *   the sample frames value is favored. Default 0.
 * - `MIX_PROP_PLAY_LOOP_START_FRAME_NUMBER`: If the track is looping, this is
 *   the sample frame position that the track will loop back to; this lets one
 *   play an intro at the start of a track on the first iteration, but have a
 *   loop point somewhere in the middle thereafter. A value <= 0 will begin
 *   the loop from the start of the track's input. Default 0.
 * - `MIX_PROP_PLAY_LOOP_START_MILLISECOND_NUMBER`: The same as using the
 *   MIX_PROP_PLAY_LOOP_START_FRAME_NUMBER property, but the value is
 *   specified in milliseconds instead of sample frames. If both properties
 *   are specified, the sample frames value is favored. Default 0.
 * - `MIX_PROP_PLAY_FADE_IN_FRAMES_NUMBER`: The number of sample frames over
 *   which to fade in the newly-started track. The track will begin mixing
 *   silence and reach full volume smoothly over this many sample frames. If
 *   the track loops before the fade-in is complete, it will continue to fade
 *   correctly from the loop point. A value <= 0 will disable fade-in, so the
 *   track starts mixing at full volume. Default 0.
 * - `MIX_PROP_PLAY_FADE_IN_MILLISECONDS_NUMBER`: The same as using the
 *   MIX_PROP_PLAY_FADE_IN_FRAMES_NUMBER property, but the value is specified
 *   in milliseconds instead of sample frames. If both properties are
 *   specified, the sample frames value is favored. Default 0.
 * - `MIX_PROP_PLAY_FADE_IN_START_GAIN_FLOAT`: If fading in, start fading from
 *   this volume level. 0.0f is silence and 1.0f is full volume, every in
 *   between is a linear change in gain. The specified value will be clamped
 *   between 0.0f and 1.0f. Default 0.0f.
 * - `MIX_PROP_PLAY_APPEND_SILENCE_FRAMES_NUMBER`: At the end of mixing this
 *   track, after all loops are complete, append this many sample frames of
 *   silence as if it were part of the audio file. This allows for apps to
 *   implement effects in callbacks, like reverb, that need to generate
 *   samples past the end of the stream's audio, or perhaps introduce a delay
 *   before starting a new sound on the track without having to manage it
 *   directly. A value <= 0 generates no silence before stopping the track.
 *   Default 0.
 * - `MIX_PROP_PLAY_APPEND_SILENCE_MILLISECONDS_NUMBER`: The same as using the
 *   MIX_PROP_PLAY_APPEND_SILENCE_FRAMES_NUMBER property, but the value is
 *   specified in milliseconds instead of sample frames. If both properties
 *   are specified, the sample frames value is favored. Default 0.
 * - `MIX_PROP_PLAY_HALT_WHEN_EXHAUSTED_BOOLEAN`: If true, when input is
 *   completely consumed for the track, the mixer will mark the track as
 *   stopped (and call any appropriate MIX_TrackStoppedCallback, etc); to play
 *   more, the track will need to be restarted. If false, the track will just
 *   not contribute to the mix, but it will not be marked as stopped. There
 *   may be clever logic tricks this exposes generally, but this property is
 *   specifically useful when the track's input is an SDL_AudioStream assigned
 *   via MIX_SetTrackAudioStream(). Setting this property to true can be
 *   useful when pushing a complete piece of audio to the stream that has a
 *   definite ending, as the track will operate like any other audio was
 *   applied. Setting to false means as new data is added to the stream, the
 *   mixer will start using it as soon as possible, which is useful when audio
 *   should play immediately as it drips in: new VoIP packets, etc. Note that
 *   in this situation, if the audio runs out when needed, there _will_ be
 *   gaps in the mixed output, so try to buffer enough data to avoid this when
 *   possible. Note that a track is not consider exhausted until all its loops
 *   and appended silence have been mixed (and also, that loops don't mean
 *   anything when the input is an AudioStream). Default true.
 *
 * If this function fails, mixing of this track will not start (or restart, if
 * it was already started).
 *
 * \param track the track to start (or restart) mixing.
 * \param options a set of properties that control playback. May be zero.
 * \returns true on success, false on error; call SDL_GetError() for details.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_PlayTag
 * \sa MIX_PlayAudio
 * \sa MIX_StopTrack
 * \sa MIX_PauseTrack
 * \sa MIX_TrackPlaying
 */
extern SDL_DECLSPEC bool SDLCALL MIX_PlayTrack(MIX_Track *track, SDL_PropertiesID options);

#define MIX_PROP_PLAY_LOOPS_NUMBER "SDL_mixer.play.loops"
#define MIX_PROP_PLAY_MAX_FRAME_NUMBER "SDL_mixer.play.max_frame"
#define MIX_PROP_PLAY_MAX_MILLISECONDS_NUMBER "SDL_mixer.play.max_milliseconds"
#define MIX_PROP_PLAY_START_FRAME_NUMBER "SDL_mixer.play.start_frame"
#define MIX_PROP_PLAY_START_MILLISECOND_NUMBER "SDL_mixer.play.start_millisecond"
#define MIX_PROP_PLAY_LOOP_START_FRAME_NUMBER "SDL_mixer.play.loop_start_frame"
#define MIX_PROP_PLAY_LOOP_START_MILLISECOND_NUMBER "SDL_mixer.play.loop_start_millisecond"
#define MIX_PROP_PLAY_FADE_IN_FRAMES_NUMBER "SDL_mixer.play.fade_in_frames"
#define MIX_PROP_PLAY_FADE_IN_MILLISECONDS_NUMBER "SDL_mixer.play.fade_in_milliseconds"
#define MIX_PROP_PLAY_FADE_IN_START_GAIN_FLOAT "SDL_mixer.play.fade_in_start_gain"
#define MIX_PROP_PLAY_APPEND_SILENCE_FRAMES_NUMBER "SDL_mixer.play.append_silence_frames"
#define MIX_PROP_PLAY_APPEND_SILENCE_MILLISECONDS_NUMBER "SDL_mixer.play.append_silence_milliseconds"
#define MIX_PROP_PLAY_HALT_WHEN_EXHAUSTED_BOOLEAN "SDL_mixer.play.halt_when_exhausted"

/**
 * Start (or restart) mixing all tracks with a specific tag for playback.
 *
 * This function follows all the same rules as MIX_PlayTrack(); please refer
 * to its documentation for the details. Unlike that function, MIX_PlayTag()
 * operates on multiple tracks at once that have the specified tag applied,
 * via MIX_TagTrack().
 *
 * If all of your tagged tracks have different sample rates, it would make
 * sense to use the `*_MILLISECONDS_NUMBER` properties in your `options`,
 * instead of `*_FRAMES_NUMBER`, and let SDL_mixer figure out how to apply it
 * to each track.
 *
 * This function returns true if all tagged tracks are started (or restarted).
 * If any track fails, this function returns false, but all tracks that could
 * start will still be started even when this function reports failure.
 *
 * From the point of view of the mixing process, all tracks that successfully
 * (re)start will do so at the exact same moment.
 *
 * \param mixer the mixer on which to look for tagged tracks.
 * \param tag the tag to use when searching for tracks.
 * \param options the set of options that will be applied to each track.
 * \returns true on success, false on error; call SDL_GetError() for details.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_PlayTrack
 * \sa MIX_TagTrack
 * \sa MIX_StopTrack
 * \sa MIX_PauseTrack
 * \sa MIX_TrackPlaying
 */
extern SDL_DECLSPEC bool SDLCALL MIX_PlayTag(MIX_Mixer *mixer, const char *tag, SDL_PropertiesID options);

/**
 * Play a MIX_Audio from start to finish without any management.
 *
 * This is what we term a "fire-and-forget" sound. Internally, SDL_mixer will
 * manage a temporary track to mix the specified MIX_Audio, cleaning it up
 * when complete. No options can be provided for how to do the mixing, like
 * MIX_PlayTrack() offers, and since the track is not available to the caller,
 * no adjustments can be made to mixing over time.
 *
 * This is not the function to build an entire game of any complexity around,
 * but it can be convenient to play simple, one-off sounds that can't be
 * stopped early. An example would be a voice saying "GAME OVER" during an
 * unpausable endgame sequence.
 *
 * There are no limits to the number of fire-and-forget sounds that can mix at
 * once (short of running out of memory), and SDL_mixer keeps an internal pool
 * of temporary tracks it creates as needed and reuses when available.
 *
 * \param mixer the mixer on which to play this audio.
 * \param audio the audio input to play.
 * \returns true if the track has begun mixing, false on error; call
 *          SDL_GetError() for details.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_PlayTrack
 * \sa MIX_LoadAudio
 */
extern SDL_DECLSPEC bool SDLCALL MIX_PlayAudio(MIX_Mixer *mixer, MIX_Audio *audio);

/**
 * Halt a currently-playing track, possibly fading out over time.
 *
 * If `fade_out_frames` is > 0, the track does not stop mixing immediately,
 * but rather fades to silence over that many sample frames before stopping.
 * Sample frames are specific to the input assigned to the track, to allow for
 * sample-perfect mixing. MIX_TrackMSToFrames() can be used to convert
 * milliseconds to an appropriate value here.
 *
 * If the track ends normally while the fade-out is still in progress, the
 * audio stops there; the fade is not adjusted to be shorter if it will last
 * longer than the audio remaining.
 *
 * Once a track has completed any fadeout and come to a stop, it will call its
 * MIX_TrackStoppedCallback, if any. It is legal to assign the track a new
 * input and/or restart it during this callback.
 *
 * It is legal to halt a track that's already stopped. It does nothing, and
 * returns true.
 *
 * \param track the track to halt.
 * \param fade_out_frames the number of sample frames to spend fading out to
 *                        silence before halting. 0 to stop immediately.
 * \returns true if the track has stopped, false on error; call SDL_GetError()
 *          for details.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_PlayTrack
 */
extern SDL_DECLSPEC bool SDLCALL MIX_StopTrack(MIX_Track *track, Sint64 fade_out_frames);

/**
 * Halt all currently-playing tracks, possibly fading out over time.
 *
 * If `fade_out_ms` is > 0, the tracks do not stop mixing immediately, but
 * rather fades to silence over that many milliseconds before stopping. Note
 * that this is different than MIX_StopTrack(), which wants sample frames;
 * this function takes milliseconds because different tracks might have
 * different sample rates.
 *
 * If a track ends normally while the fade-out is still in progress, the audio
 * stops there; the fade is not adjusted to be shorter if it will last longer
 * than the audio remaining.
 *
 * Once a track has completed any fadeout and come to a stop, it will call its
 * MIX_TrackStoppedCallback, if any. It is legal to assign the track a new
 * input and/or restart it during this callback. This function does not
 * prevent new play requests from being made.
 *
 * \param mixer the mixer on which to stop all tracks.
 * \param fade_out_ms the number of milliseconds to spend fading out to
 *                    silence before halting. 0 to stop immediately.
 * \returns true on success, false on error; call SDL_GetError() for details.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_StopTrack
 */
extern SDL_DECLSPEC bool SDLCALL MIX_StopAllTracks(MIX_Mixer *mixer, Sint64 fade_out_ms);

/**
 * Halt all tracks with a specific tag, possibly fading out over time.
 *
 * If `fade_out_ms` is > 0, the tracks do not stop mixing immediately, but
 * rather fades to silence over that many milliseconds before stopping. Note
 * that this is different than MIX_StopTrack(), which wants sample frames;
 * this function takes milliseconds because different tracks might have
 * different sample rates.
 *
 * If a track ends normally while the fade-out is still in progress, the audio
 * stops there; the fade is not adjusted to be shorter if it will last longer
 * than the audio remaining.
 *
 * Once a track has completed any fadeout and come to a stop, it will call its
 * MIX_TrackStoppedCallback, if any. It is legal to assign the track a new
 * input and/or restart it during this callback. This function does not
 * prevent new play requests from being made.
 *
 * \param mixer the mixer on which to stop tracks.
 * \param tag the tag to use when searching for tracks.
 * \param fade_out_ms the number of milliseconds to spend fading out to
 *                    silence before halting. 0 to stop immediately.
 * \returns true on success, false on error; call SDL_GetError() for details.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_StopTrack
 * \sa MIX_TagTrack
 */
extern SDL_DECLSPEC bool SDLCALL MIX_StopTag(MIX_Mixer *mixer, const char *tag, Sint64 fade_out_ms);

/**
 * Pause a currently-playing track.
 *
 * A paused track is not considered "stopped," so its MIX_TrackStoppedCallback
 * will not fire if paused, but it won't change state by default, generate
 * audio, or generally make progress, until it is resumed.
 *
 * It is legal to pause a track that's in any state (playing, already paused,
 * or stopped). Unless the track is currently playing, pausing does nothing,
 * and returns true. A false return is only used to signal errors here (such
 * as MIX_Init not being called or `track` being NULL).
 *
 * \param track the track to pause.
 * \returns true if the track has paused, false on error; call SDL_GetError()
 *          for details.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_ResumeTrack
 */
extern SDL_DECLSPEC bool SDLCALL MIX_PauseTrack(MIX_Track *track);

/**
 * Pause all currently-playing tracks.
 *
 * A paused track is not considered "stopped," so its MIX_TrackStoppedCallback
 * will not fire if paused, but it won't change state by default, generate
 * audio, or generally make progress, until it is resumed.
 *
 * This function makes all tracks on the specified mixer that are currently
 * playing move to a paused state. They can later be resumed.
 *
 * \param mixer the mixer on which to pause all tracks.
 * \returns true on success, false on error; call SDL_GetError() for details.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_ResumeTrack
 * \sa MIX_ResumeAllTracks
 */
extern SDL_DECLSPEC bool SDLCALL MIX_PauseAllTracks(MIX_Mixer *mixer);

/**
 * Pause all tracks with a specific tag.
 *
 * A paused track is not considered "stopped," so its MIX_TrackStoppedCallback
 * will not fire if paused, but it won't change state by default, generate
 * audio, or generally make progress, until it is resumed.
 *
 * This function makes all currently-playing tracks on the specified mixer,
 * with a specific tag, move to a paused state. They can later be resumed.
 *
 * Tracks that match the specified tag that aren't currently playing are
 * ignored.
 *
 * \param mixer the mixer on which to pause tracks.
 * \param tag the tag to use when searching for tracks.
 * \returns true on success, false on error; call SDL_GetError() for details.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_PauseTrack
 * \sa MIX_ResumeTrack
 * \sa MIX_ResumeTag
 * \sa MIX_TagTrack
 */
extern SDL_DECLSPEC bool SDLCALL MIX_PauseTag(MIX_Mixer *mixer, const char *tag);

/**
 * Resume a currently-paused track.
 *
 * A paused track is not considered "stopped," so its MIX_TrackStoppedCallback
 * will not fire if paused, but it won't change state by default, generate
 * audio, or generally make progress, until it is resumed.
 *
 * It is legal to resume a track that's in any state (playing, paused, or
 * stopped). Unless the track is currently paused, resuming does nothing, and
 * returns true. A false return is only used to signal errors here (such as
 * MIX_Init not being called or `track` being NULL).
 *
 * \param track the track to resume.
 * \returns true if the track has resumed, false on error; call SDL_GetError()
 *          for details.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_PauseTrack
 */
extern SDL_DECLSPEC bool SDLCALL MIX_ResumeTrack(MIX_Track *track);

/**
 * Resume all currently-paused tracks.
 *
 * A paused track is not considered "stopped," so its MIX_TrackStoppedCallback
 * will not fire if paused, but it won't change state by default, generate
 * audio, or generally make progress, until it is resumed.
 *
 * This function makes all tracks on the specified mixer that are currently
 * paused move to a playing state.
 *
 * \param mixer the mixer on which to resume all tracks.
 * \returns true on success, false on error; call SDL_GetError() for details.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_PauseTrack
 * \sa MIX_PauseAllTracks
 */
extern SDL_DECLSPEC bool SDLCALL MIX_ResumeAllTracks(MIX_Mixer *mixer);

/**
 * Resume all tracks with a specific tag.
 *
 * A paused track is not considered "stopped," so its MIX_TrackStoppedCallback
 * will not fire if paused, but it won't change state by default, generate
 * audio, or generally make progress, until it is resumed.
 *
 * This function makes all currently-paused tracks on the specified mixer,
 * with a specific tag, move to a playing state.
 *
 * Tracks that match the specified tag that aren't currently paused are
 * ignored.
 *
 * \param mixer the mixer on which to resume tracks.
 * \param tag the tag to use when searching for tracks.
 * \returns true on success, false on error; call SDL_GetError() for details.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_ResumeTrack
 * \sa MIX_PauseTrack
 * \sa MIX_PauseTag
 * \sa MIX_TagTrack
 */
extern SDL_DECLSPEC bool SDLCALL MIX_ResumeTag(MIX_Mixer *mixer, const char *tag);

/**
 * Query if a track is currently playing.
 *
 * If this returns true, the track is currently contributing to the mixer's
 * output (it's "playing"). It is not stopped nor paused.
 *
 * On various errors (MIX_Init() was not called, the track is NULL), this
 * returns false, but there is no mechanism to distinguish errors from
 * non-playing tracks.
 *
 * \param track the track to query.
 * \returns true if playing, false otherwise.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_PlayTrack
 * \sa MIX_PauseTrack
 * \sa MIX_ResumeTrack
 * \sa MIX_StopTrack
 * \sa MIX_TrackPaused
 */
extern SDL_DECLSPEC bool SDLCALL MIX_TrackPlaying(MIX_Track *track);

/**
 * Query if a track is currently paused.
 *
 * If this returns true, the track is not currently contributing to the
 * mixer's output but will when resumed (it's "paused"). It is not playing nor
 * stopped.
 *
 * On various errors (MIX_Init() was not called, the track is NULL), this
 * returns false, but there is no mechanism to distinguish errors from
 * non-playing tracks.
 *
 * \param track the track to query.
 * \returns true if paused, false otherwise.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_PlayTrack
 * \sa MIX_PauseTrack
 * \sa MIX_ResumeTrack
 * \sa MIX_StopTrack
 * \sa MIX_TrackPlaying
 */
extern SDL_DECLSPEC bool SDLCALL MIX_TrackPaused(MIX_Track *track);


/* volume control... */

/**
 * Set a mixer's master gain control.
 *
 * Each mixer has a master gain, to adjust the volume of the entire mix. Each
 * sample passing through the pipeline is modulated by this gain value. A gain
 * of zero will generate silence, 1.0f will not change the mixed volume, and
 * larger than 1.0f will increase the volume. Negative values are illegal.
 * There is no maximum gain specified, but this can quickly get extremely
 * loud, so please be careful with this setting.
 *
 * A mixer's master gain defaults to 1.0f.
 *
 * This value can be changed at any time to adjust the future mix.
 *
 * \param mixer the mixer to adjust.
 * \param gain the new gain value.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_GetMixerGain
 * \sa MIX_SetTrackGain
 */
extern SDL_DECLSPEC bool SDLCALL MIX_SetMixerGain(MIX_Mixer *mixer, float gain);

/**
 * Get a mixer's master gain control.
 *
 * This returns the last value set through MIX_SetMixerGain(), or 1.0f if no
 * value has ever been explicitly set.
 *
 * \param mixer the mixer to query.
 * \returns the mixer's current master gain.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_SetMixerGain
 * \sa MIX_GetTrackGain
 */
extern SDL_DECLSPEC float SDLCALL MIX_GetMixerGain(MIX_Mixer *mixer);

/**
 * Set a track's gain control.
 *
 * Each track has its own gain, to adjust its overall volume. Each sample from
 * this track is modulated by this gain value. A gain of zero will generate
 * silence, 1.0f will not change the mixed volume, and larger than 1.0f will
 * increase the volume. Negative values are illegal. There is no maximum gain
 * specified, but this can quickly get extremely loud, so please be careful
 * with this setting.
 *
 * A track's gain defaults to 1.0f.
 *
 * This value can be changed at any time to adjust the future mix.
 *
 * \param track the track to adjust.
 * \param gain the new gain value.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_GetTrackGain
 * \sa MIX_SetMixerGain
 */
extern SDL_DECLSPEC bool SDLCALL MIX_SetTrackGain(MIX_Track *track, float gain);

/**
 * Get a track's gain control.
 *
 * This returns the last value set through MIX_SetTrackGain(), or 1.0f if no
 * value has ever been explicitly set.
 *
 * \param track the track to query.
 * \returns the track's current gain.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_SetTrackGain
 * \sa MIX_GetMixerGain
 */
extern SDL_DECLSPEC float SDLCALL MIX_GetTrackGain(MIX_Track *track);

/**
 * Set the gain control of all tracks with a specific tag.
 *
 * Each track has its own gain, to adjust its overall volume. Each sample from
 * this track is modulated by this gain value. A gain of zero will generate
 * silence, 1.0f will not change the mixed volume, and larger than 1.0f will
 * increase the volume. Negative values are illegal. There is no maximum gain
 * specified, but this can quickly get extremely loud, so please be careful
 * with this setting.
 *
 * A track's gain defaults to 1.0f.
 *
 * This will change the gain control on tracks on the specified mixer that
 * have the specified tag.
 *
 * From the point of view of the mixing process, all tracks that successfully
 * change gain values will do so at the exact same moment.
 *
 * This value can be changed at any time to adjust the future mix.
 *
 * \param mixer the mixer on which to look for tagged tracks.
 * \param tag the tag to use when searching for tracks.
 * \param gain the new gain value.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_GetTrackGain
 * \sa MIX_SetTrackGain
 * \sa MIX_SetMixerGain
 * \sa MIX_TagTrack
 */
extern SDL_DECLSPEC bool SDLCALL MIX_SetTagGain(MIX_Mixer *mixer, const char *tag, float gain);


/* frequency ratio ... */

/**
 * Set a mixer's master frequency ratio.
 *
 * Each mixer has a master frequency ratio, that affects the entire mix. This
 * can cause the final output to change speed and pitch. A value greater than
 * 1.0f will play the audio faster, and at a higher pitch. A value less than
 * 1.0f will play the audio slower, and at a lower pitch. 1.0f is normal
 * speed.
 *
 * Each track _also_ has a frequency ratio; it will be applied when mixing
 * that track's audio regardless of the master setting. The master setting
 * affects the final output after all mixing has been completed.
 *
 * A mixer's master frequency ratio defaults to 1.0f.
 *
 * This value can be changed at any time to adjust the future mix.
 *
 * \param mixer the mixer to adjust.
 * \param ratio the frequency ratio. Must be between 0.01f and 100.0f.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_GetMixerFrequencyRatio
 * \sa MIX_SetTrackFrequencyRatio
 */
extern SDL_DECLSPEC bool SDLCALL MIX_SetMixerFrequencyRatio(MIX_Mixer *mixer, float ratio);

/**
 * Get a mixer's master frequency ratio.
 *
 * This returns the last value set through MIX_SetMixerFrequencyRatio(), or
 * 1.0f if no value has ever been explicitly set.
 *
 * \param mixer the mixer to query.
 * \returns the mixer's current master frequency ratio.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_SetMixerFrequencyRatio
 * \sa MIX_GetTrackFrequencyRatio
 */
extern SDL_DECLSPEC float SDLCALL MIX_GetMixerFrequencyRatio(MIX_Mixer *mixer);


/**
 * Change the frequency ratio of a track.
 *
 * The frequency ratio is used to adjust the rate at which audio data is
 * consumed. Changing this effectively modifies the speed and pitch of the
 * track's audio. A value greater than 1.0f will play the audio faster, and at
 * a higher pitch. A value less than 1.0f will play the audio slower, and at a
 * lower pitch. 1.0f is normal speed.
 *
 * The default value is 1.0f.
 *
 * This value can be changed at any time to adjust the future mix.
 *
 * \param track the track on which to change the frequency ratio.
 * \param ratio the frequency ratio. Must be between 0.01f and 100.0f.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_GetTrackFrequencyRatio
 */
extern SDL_DECLSPEC bool SDLCALL MIX_SetTrackFrequencyRatio(MIX_Track *track, float ratio);

/**
 * Query the frequency ratio of a track.
 *
 * The frequency ratio is used to adjust the rate at which audio data is
 * consumed. Changing this effectively modifies the speed and pitch of the
 * track's audio. A value greater than 1.0f will play the audio faster, and at
 * a higher pitch. A value less than 1.0f will play the audio slower, and at a
 * lower pitch. 1.0f is normal speed.
 *
 * The default value is 1.0f.
 *
 * On various errors (MIX_Init() was not called, the track is NULL), this
 * returns 0.0f. Since this is not a valid value to set, this can be seen as
 * an error state.
 *
 * \param track the track on which to query the frequency ratio.
 * \returns the current frequency ratio, or 0.0f on failure; call
 *          SDL_GetError() for more information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_GetTrackFrequencyRatio
 */
extern SDL_DECLSPEC float SDLCALL MIX_GetTrackFrequencyRatio(MIX_Track *track);


/* channel maps... */

/**
 * Set the current output channel map of a track.
 *
 * Channel maps are optional; most things do not need them, instead passing
 * data in the order that SDL expects.
 *
 * The output channel map reorders track data after transformations and before
 * it is mixed into a mixer group. This can be useful for reversing stereo
 * channels, for example.
 *
 * Each item in the array represents an input channel, and its value is the
 * channel that it should be remapped to. To reverse a stereo signal's left
 * and right values, you'd have an array of `{ 1, 0 }`. It is legal to remap
 * multiple channels to the same thing, so `{ 1, 1 }` would duplicate the
 * right channel to both channels of a stereo signal. An element in the
 * channel map set to -1 instead of a valid channel will mute that channel,
 * setting it to a silence value.
 *
 * You cannot change the number of channels through a channel map, just
 * reorder/mute them.
 *
 * Tracks default to no remapping applied. Passing a NULL channel map is
 * legal, and turns off remapping.
 *
 * SDL_mixer will copy the channel map; the caller does not have to save this
 * array after this call.
 *
 * \param track the track to change.
 * \param chmap the new channel map, NULL to reset to default.
 * \param count The number of channels in the map.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 */
extern SDL_DECLSPEC bool SDLCALL MIX_SetTrackOutputChannelMap(MIX_Track *track, const int *chmap, int count);


/* positional audio... */

/**
 * A set of per-channel gains for tracks using MIX_SetTrackStereo().
 *
 * When forcing a track to stereo, the app can specify a per-channel gain, to
 * further adjust the left or right outputs.
 *
 * When mixing audio that has been forced to stereo, each channel is modulated
 * by these values. A value of 1.0f produces no change, 0.0f produces silence.
 *
 * A simple panning effect would be to set `left` to the desired value and
 * `right` to `1.0f - left`.
 *
 * \since This struct is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_SetTrackStereo
 */
typedef struct MIX_StereoGains
{
    float left;   /**< left channel gain */
    float right;  /**< right channel gain */
} MIX_StereoGains;

/**
 * Force a track to stereo output, with optionally left/right panning.
 *
 * This will cause the output of the track to convert to stereo, and then mix
 * it only onto the Front Left and Front Right speakers, regardless of the
 * speaker configuration. The left and right channels are modulated by
 * `gains`, which can be used to produce panning effects. This function may be
 * called to adjust the gains at any time.
 *
 * If `gains` is not NULL, this track will be switched into forced-stereo
 * mode. If `gains` is NULL, this will disable spatialization (both the
 * forced-stereo mode of this function and full 3D spatialization of
 * MIX_SetTrack3DPosition()).
 *
 * Negative gains are clamped to zero; there is no clamp for maximum, so one
 * could set the value > 1.0f to make a channel louder.
 *
 * The track's 3D position, reported by MIX_GetTrack3DPosition(), will be
 * reset to (0, 0, 0).
 *
 * \param track the track to adjust.
 * \param gains the per-channel gains, or NULL to disable spatialization.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_SetTrack3DPosition
 */
extern SDL_DECLSPEC bool SDLCALL MIX_SetTrackStereo(MIX_Track *track, const MIX_StereoGains *gains);


/**
 * 3D coordinates for MIX_SetTrack3DPosition.
 *
 * The coordinates use a "right-handed" coordinate system, like OpenGL and
 * OpenAL.
 *
 * \since This struct is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_SetTrack3DPosition
 */
typedef struct MIX_Point3D
{
    float x;  /**< X coordinate (negative left, positive right). */
    float y;  /**< Y coordinate (negative down, positive up). */
    float z;  /**< Z coordinate (negative forward, positive back). */
} MIX_Point3D;

/**
 * Set a track's position in 3D space.
 *
 * (Please note that SDL_mixer is not intended to be a extremely powerful 3D
 * API. It lacks 3D features that other APIs like OpenAL offer: there's no
 * doppler effect, distance models, rolloff, etc. This is meant to be Good
 * Enough for games that can use some positional sounds and can even take
 * advantage of surround-sound configurations.)
 *
 * If `position` is not NULL, this track will be switched into 3D positional
 * mode. If `position` is NULL, this will disable positional mixing (both the
 * full 3D spatialization of this function and forced-stereo mode of
 * MIX_SetTrackStereo()).
 *
 * In 3D positional mode, SDL_mixer will mix this track as if it were
 * positioned in 3D space, including distance attenuation (quieter as it gets
 * further from the listener) and spatialization (positioned on the correct
 * speakers to suggest direction, either with stereo outputs or full surround
 * sound).
 *
 * For a mono speaker output, spatialization is effectively disabled but
 * distance attenuation will still work, which is all you can really do with a
 * single speaker.
 *
 * The coordinate system operates like OpenGL or OpenAL: a "right-handed"
 * coordinate system. See MIX_Point3D for the details.
 *
 * The listener is always at coordinate (0,0,0) and can't be changed.
 *
 * The track's input will be converted to mono (1 channel) so it can be
 * rendered across the correct speakers.
 *
 * \param track the track for which to set 3D position.
 * \param position the new 3D position for the track. May be NULL.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_GetTrack3DPosition
 * \sa MIX_SetTrackStereo
 */
extern SDL_DECLSPEC bool SDLCALL MIX_SetTrack3DPosition(MIX_Track *track, const MIX_Point3D *position);

/**
 * Get a track's current position in 3D space.
 *
 * If 3D positioning isn't enabled for this track, through a call to
 * MIX_SetTrack3DPosition(), this will return (0,0,0).
 *
 * \param track the track to query.
 * \param position on successful return, will contain the track's position.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_SetTrack3DPosition
 */
extern SDL_DECLSPEC bool SDLCALL MIX_GetTrack3DPosition(MIX_Track *track, MIX_Point3D *position);


/* Mix groups... */

/**
 * Create a mixing group.
 *
 * Tracks are assigned to a mixing group (or if unassigned, they live in a
 * mixer's internal default group). All tracks in a group are mixed together
 * and the app can access this mixed data before it is mixed with all other
 * groups to produce the final output.
 *
 * This can be a useful feature, but is completely optional; apps can ignore
 * mixing groups entirely and still have a full experience with SDL_mixer.
 *
 * After creating a group, assign tracks to it with MIX_SetTrackGroup(). Use
 * MIX_SetGroupPostMixCallback() to access the group's mixed data.
 *
 * A mixing group can be destroyed with MIX_DestroyGroup() when no longer
 * needed. Destroying the mixer will also destroy all its still-existing
 * mixing groups.
 *
 * \param mixer the mixer on which to create a mixing group.
 * \returns a newly-created mixing group, or NULL on error; call
 *          SDL_GetError() for more information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_DestroyGroup
 * \sa MIX_SetTrackGroup
 * \sa MIX_SetGroupPostMixCallback
 */
extern SDL_DECLSPEC MIX_Group * SDLCALL MIX_CreateGroup(MIX_Mixer *mixer);

/**
 * Destroy a mixing group.
 *
 * Any tracks currently assigned to this group will be reassigned to the
 * mixer's internal default group.
 *
 * \param group the mixing group to destroy.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_CreateGroup
 */
extern SDL_DECLSPEC void SDLCALL MIX_DestroyGroup(MIX_Group *group);

/**
 * Get the properties associated with a group.
 *
 * Currently SDL_mixer assigns no properties of its own to a group, but this
 * can be a convenient place to store app-specific data.
 *
 * A SDL_PropertiesID is created the first time this function is called for a
 * given group.
 *
 * \param group the group to query.
 * \returns a valid property ID on success or 0 on failure; call
 *          SDL_GetError() for more information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 */
extern SDL_DECLSPEC SDL_PropertiesID SDLCALL MIX_GetGroupProperties(MIX_Group *group);

/**
 * Get the MIX_Mixer that owns a MIX_Group.
 *
 * This is the mixer pointer that was passed to MIX_CreateGroup().
 *
 * \param group the group to query.
 * \returns the mixer associated with the group, or NULL on error; call
 *          SDL_GetError() for more information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 */
extern SDL_DECLSPEC MIX_Mixer * SDLCALL MIX_GetGroupMixer(MIX_Group *group);

/**
 * Assign a track to a mixing group.
 *
 * All tracks in a group are mixed together, and that output is made available
 * to the app before it is mixed into the final output.
 *
 * Tracks can only be in one group at a time, and the track and group must
 * have been created on the same MIX_Mixer.
 *
 * Setting a track to a NULL group will remove it from any app-created groups,
 * and reassign it to the mixer's internal default group.
 *
 * \param track the track to set mixing group assignment.
 * \param group the new mixing group to assign to. May be NULL.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_CreateGroup
 * \sa MIX_SetGroupPostMixCallback
 */
extern SDL_DECLSPEC bool SDLCALL MIX_SetTrackGroup(MIX_Track *track, MIX_Group *group);



/* Hooks... */

/**
 * A callback that fires when a MIX_Track is stopped.
 *
 * This callback is fired when a track completes playback, either because it
 * ran out of data to mix (and all loops were completed as well), or it was
 * explicitly stopped by the app. Pausing a track will not fire this callback.
 *
 * It is legal to adjust the track, including changing its input and
 * restarting it. If this is done because it ran out of data in the middle of
 * mixing, the mixer will start mixing the new track state in its current run
 * without any gap in the audio.
 *
 * This callback will not fire when a playing track is destroyed.
 *
 * \param userdata an opaque pointer provided by the app for its personal use.
 * \param track the track that has stopped.
 *
 * \since This datatype is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_SetTrackStoppedCallback
 */
typedef void (SDLCALL *MIX_TrackStoppedCallback)(void *userdata, MIX_Track *track);

/**
 * Set a callback that fires when a MIX_Track is stopped.
 *
 * When a track completes playback, either because it ran out of data to mix
 * (and all loops were completed as well), or it was explicitly stopped by the
 * app, it will fire the callback specified here.
 *
 * Each track has its own unique callback.
 *
 * Passing a NULL callback here is legal; it disables this track's callback.
 *
 * Pausing a track will not fire the callback, nor will the callback fire on a
 * playing track that is being destroyed.
 *
 * It is legal to adjust the track, including changing its input and
 * restarting it. If this is done because it ran out of data in the middle of
 * mixing, the mixer will start mixing the new track state in its current run
 * without any gap in the audio.
 *
 * \param track the track to assign this callback to.
 * \param cb the function to call when the track stops. May be NULL.
 * \param userdata an opaque pointer provided to the callback for its own
 *                 personal use.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_TrackStoppedCallback
 */
extern SDL_DECLSPEC bool SDLCALL MIX_SetTrackStoppedCallback(MIX_Track *track, MIX_TrackStoppedCallback cb, void *userdata);

/**
 * A callback that fires when a MIX_Track is mixing at various stages.
 *
 * This callback is fired for different parts of the mixing pipeline, and
 * gives the app visbility into the audio data that is being generated at
 * various stages.
 *
 * The audio data passed through here is _not_ const data; the app is
 * permitted to change it in any way it likes, and those changes will
 * propagate through the mixing pipeline.
 *
 * An audiospec is provided. Different tracks might be in different formats,
 * and an app needs to be able to handle that, but SDL_mixer always does its
 * mixing work in 32-bit float samples, even if the inputs or final output are
 * not floating point. As such, `spec->format` will always be `SDL_AUDIO_F32`
 * and `pcm` hardcoded to be a float pointer.
 *
 * `samples` is the number of float values pointed to by `pcm`: samples, not
 * sample frames! There are no promises how many samples will be provided
 * per-callback, and this number can vary wildly from call to call, depending
 * on many factors.
 *
 * Making changes to the track during this callback is undefined behavior.
 * Change the data in `pcm` but not the track itself.
 *
 * \param userdata an opaque pointer provided by the app for its personal use.
 * \param track the track that is being mixed.
 * \param spec the format of the data in `pcm`.
 * \param pcm the raw PCM data in float32 format.
 * \param samples the number of float values pointed to by `pcm`.
 *
 * \since This datatype is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_SetTrackRawCallback
 * \sa MIX_SetTrackCookedCallback
 */
typedef void (SDLCALL *MIX_TrackMixCallback)(void *userdata, MIX_Track *track, const SDL_AudioSpec *spec, float *pcm, int samples);

/**
 * Set a callback that fires when a MIX_Track has initial decoded audio.
 *
 * As a track needs to mix more data, it pulls from its input (a MIX_Audio, an
 * SDL_AudioStream, etc). This input might be a compressed file format, like
 * MP3, so a little more data is uncompressed from it.
 *
 * Once the track has PCM data to start operating on, it can fire a callback
 * before _any_ changes to the raw PCM input have happened. This lets an app
 * view the data before it has gone through transformations such as gain, 3D
 * positioning, fading, etc. It can also change the data in any way it pleases
 * during this callback, and the mixer will continue as if this data came
 * directly from the input.
 *
 * Each track has its own unique raw callback.
 *
 * Passing a NULL callback here is legal; it disables this track's callback.
 *
 * \param track the track to assign this callback to.
 * \param cb the function to call when the track mixes. May be NULL.
 * \param userdata an opaque pointer provided to the callback for its own
 *                 personal use.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_TrackMixCallback
 * \sa MIX_SetTrackCookedCallback
 */
extern SDL_DECLSPEC bool SDLCALL MIX_SetTrackRawCallback(MIX_Track *track, MIX_TrackMixCallback cb, void *userdata);

/**
 * Set a callback that fires when the mixer has transformed a track's audio.
 *
 * As a track needs to mix more data, it pulls from its input (a MIX_Audio, an
 * SDL_AudioStream, etc). This input might be a compressed file format, like
 * MP3, so a little more data is uncompressed from it.
 *
 * Once the track has PCM data to start operating on, and its raw callback has
 * completed, it will begin to transform the audio: gain, fading, frequency
 * ratio, 3D positioning, etc.
 *
 * A callback can be fired after all these transformations, but before the
 * transformed data is mixed into other tracks. This lets an app view the data
 * at the last moment that it is still a part of this track. It can also
 * change the data in any way it pleases during this callback, and the mixer
 * will continue as if this data came directly from the input.
 *
 * Each track has its own unique cooked callback.
 *
 * Passing a NULL callback here is legal; it disables this track's callback.
 *
 * \param track the track to assign this callback to.
 * \param cb the function to call when the track mixes. May be NULL.
 * \param userdata an opaque pointer provided to the callback for its own
 *                 personal use.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_TrackMixCallback
 * \sa MIX_SetTrackRawCallback
 */
extern SDL_DECLSPEC bool SDLCALL MIX_SetTrackCookedCallback(MIX_Track *track, MIX_TrackMixCallback cb, void *userdata);

/**
 * A callback that fires when a MIX_Group has completed mixing.
 *
 * This callback is fired when a mixing group has finished mixing: all tracks
 * in the group have mixed into a single buffer and are prepared to be mixed
 * into all other groups for the final mix output.
 *
 * The audio data passed through here is _not_ const data; the app is
 * permitted to change it in any way it likes, and those changes will
 * propagate through the mixing pipeline.
 *
 * An audiospec is provided. Different groups might be in different formats,
 * and an app needs to be able to handle that, but SDL_mixer always does its
 * mixing work in 32-bit float samples, even if the inputs or final output are
 * not floating point. As such, `spec->format` will always be `SDL_AUDIO_F32`
 * and `pcm` hardcoded to be a float pointer.
 *
 * `samples` is the number of float values pointed to by `pcm`: samples, not
 * sample frames! There are no promises how many samples will be provided
 * per-callback, and this number can vary wildly from call to call, depending
 * on many factors.
 *
 * \param userdata an opaque pointer provided by the app for its personal use.
 * \param group the group that is being mixed.
 * \param spec the format of the data in `pcm`.
 * \param pcm the raw PCM data in float32 format.
 * \param samples the number of float values pointed to by `pcm`.
 *
 * \since This datatype is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_SetGroupPostMixCallback
 */
typedef void (SDLCALL *MIX_GroupMixCallback)(void *userdata, MIX_Group *group, const SDL_AudioSpec *spec, float *pcm, int samples);

/**
 * Set a callback that fires when a mixer group has completed mixing.
 *
 * After all playing tracks in a mixer group have pulled in more data from
 * their inputs, transformed it, and mixed together into a single buffer, a
 * callback can be fired. This lets an app view the data at the last moment
 * that it is still a part of this group. It can also change the data in any
 * way it pleases during this callback, and the mixer will continue as if this
 * data came directly from the group's mix buffer.
 *
 * Each group has its own unique callback. Tracks that aren't in an explicit
 * MIX_Group are mixed in an internal grouping that is not available to the
 * app.
 *
 * Passing a NULL callback here is legal; it disables this group's callback.
 *
 * \param group the mixing group to assign this callback to.
 * \param cb the function to call when the group mixes. May be NULL.
 * \param userdata an opaque pointer provided to the callback for its own
 *                 personal use.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_GroupMixCallback
 */
extern SDL_DECLSPEC bool SDLCALL MIX_SetGroupPostMixCallback(MIX_Group *group, MIX_GroupMixCallback cb, void *userdata);

/**
 * A callback that fires when all mixing has completed.
 *
 * This callback is fired when the mixer has completed all its work. If this
 * mixer was created with MIX_CreateMixerDevice(), the data provided by this
 * callback is what is being sent to the audio hardware, minus last
 * conversions for format requirements. If this mixer was created with
 * MIX_CreateMixer(), this is what is being output from MIX_Generate(), after
 * final conversions.
 *
 * The audio data passed through here is _not_ const data; the app is
 * permitted to change it in any way it likes, and those changes will replace
 * the final mixer pipeline output.
 *
 * An audiospec is provided. SDL_mixer always does its mixing work in 32-bit
 * float samples, even if the inputs or final output are not floating point.
 * As such, `spec->format` will always be `SDL_AUDIO_F32` and `pcm` hardcoded
 * to be a float pointer.
 *
 * `samples` is the number of float values pointed to by `pcm`: samples, not
 * sample frames! There are no promises how many samples will be provided
 * per-callback, and this number can vary wildly from call to call, depending
 * on many factors.
 *
 * \param userdata an opaque pointer provided by the app for its personal use.
 * \param mixer the mixer that is generating audio.
 * \param spec the format of the data in `pcm`.
 * \param pcm the raw PCM data in float32 format.
 * \param samples the number of float values pointed to by `pcm`.
 *
 * \since This datatype is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_SetPostMixCallback
 */
typedef void (SDLCALL *MIX_PostMixCallback)(void *userdata, MIX_Mixer *mixer, const SDL_AudioSpec *spec, float *pcm, int samples);

/**
 * Set a callback that fires when all mixing has completed.
 *
 * After all mixer groups have processed, their buffers are mixed together
 * into a single buffer for the final output, at which point a callback can be
 * fired. This lets an app view the data at the last moment before mixing
 * completes. It can also change the data in any way it pleases during this
 * callback, and the mixer will continue as if this data is the final output.
 *
 * Each mixer has its own unique callback.
 *
 * Passing a NULL callback here is legal; it disables this mixer's callback.
 *
 * \param mixer the mixer to assign this callback to.
 * \param cb the function to call when the mixer mixes. May be NULL.
 * \param userdata an opaque pointer provided to the callback for its own
 *                 personal use.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_PostMixCallback
 */
extern SDL_DECLSPEC bool SDLCALL MIX_SetPostMixCallback(MIX_Mixer *mixer, MIX_PostMixCallback cb, void *userdata);


/* Audio generation without an audio device... */

/**
 * Generate mixer output when not driving an audio device.
 *
 * SDL_mixer allows the creation of MIX_Mixer objects that are not connected
 * to an audio device, by calling MIX_CreateMixer() instead of
 * MIX_CreateMixerDevice(). Such mixers will not generate output until
 * explicitly requested through this function.
 *
 * The caller may request as much audio as desired, so long as `buflen` is a
 * multiple of the sample frame size specified when creating the mixer (for
 * example, if requesting stereo Sint16 audio, buflen must be a multiple of 4:
 * 2 bytes-per-channel times 2 channels).
 *
 * The mixer will mix as quickly as possible; since it works in sample frames
 * instead of time, it can potentially generate enormous amounts of audio in a
 * small amount of time.
 *
 * On success, this always fills `buffer` with `buflen` bytes of audio; if all
 * playing tracks finish mixing, it will fill the remaining buffer with
 * silence.
 *
 * Each call to this function will pick up where it left off, playing tracks
 * will continue to mix from the point the previous call completed, etc. The
 * mixer state can be changed between each call in any way desired: tracks can
 * be added, played, stopped, changed, removed, etc. Effectively this function
 * does the same thing SDL_mixer does internally when the audio device needs
 * more audio to play.
 *
 * This function can not be used with mixers from MIX_CreateMixerDevice();
 * those generate audio as needed internally.
 *
 * This function returns the number of _bytes_ of real audio mixed, which
 * might be less than `buflen`. While all `buflen` bytes of `buffer` will be
 * initialized, if available tracks to mix run out, the end of the buffer will
 * be initialized with silence; this silence will not be counted in the return
 * value, so the caller has the option to identify how much of the buffer has
 * legimitate contents vs appended silence. As such, any value >= 0 signifies
 * success. A return value of -1 means failure (out of memory, invalid
 * parameters, etc).
 *
 * \param mixer the mixer for which to generate more audio.
 * \param buffer a pointer to a buffer to store audio in.
 * \param buflen the number of bytes to store in buffer.
 * \returns The number of bytes of mixed audio, discounting appended silence,
 *          on success, or -1 on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_CreateMixer
 */
extern SDL_DECLSPEC int SDLCALL MIX_Generate(MIX_Mixer *mixer, void *buffer, int buflen);


/* Decode audio files directly without a mixer ... */

/**
 * An opaque object that represents an audio decoder.
 *
 * Most apps won't need this, as SDL_mixer's usual interfaces will decode
 * audio as needed. However, if one wants to decode an audio file into a
 * memory buffer without playing it, this interface offers that.
 *
 * These objects are created with MIX_CreateAudioDecoder() or
 * MIX_CreateAudioDecoder_IO(), and then can use MIX_DecodeAudio() to retrieve
 * the raw PCM data.
 *
 * \since This struct is available since SDL_mixer 3.0.0.
 */
typedef struct MIX_AudioDecoder MIX_AudioDecoder;

/**
 * Create a MIX_AudioDecoder from a path on the filesystem.
 *
 * Most apps won't need this, as SDL_mixer's usual interfaces will decode
 * audio as needed. However, if one wants to decode an audio file into a
 * memory buffer without playing it, this interface offers that.
 *
 * This function allows properties to be specified. This is intended to supply
 * file-specific settings, such as where to find SoundFonts for a MIDI file,
 * etc. In most cases, the caller should pass a zero to specify no extra
 * properties.
 *
 * SDL_PropertiesID are discussed in
 * [SDL's documentation](https://wiki.libsdl.org/SDL3/CategoryProperties)
 * .
 *
 * When done with the audio decoder, it can be destroyed with
 * MIX_DestroyAudioDecoder().
 *
 * This function requires SDL_mixer to have been initialized with a successful
 * call to MIX_Init(), but does not need an actual MIX_Mixer to have been
 * created.
 *
 * \param path the path on the filesystem from which to load data.
 * \param props decoder-specific properties. May be zero.
 * \returns an audio decoder, ready to decode.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_CreateAudioDecoder_IO
 * \sa MIX_DecodeAudio
 * \sa MIX_DestroyAudioDecoder
 */
extern SDL_DECLSPEC MIX_AudioDecoder * SDLCALL MIX_CreateAudioDecoder(const char *path, SDL_PropertiesID props);

/**
 * Create a MIX_AudioDecoder from an SDL_IOStream.
 *
 * Most apps won't need this, as SDL_mixer's usual interfaces will decode
 * audio as needed. However, if one wants to decode an audio file into a
 * memory buffer without playing it, this interface offers that.
 *
 * This function allows properties to be specified. This is intended to supply
 * file-specific settings, such as where to find SoundFonts for a MIDI file,
 * etc. In most cases, the caller should pass a zero to specify no extra
 * properties.
 *
 * If `closeio` is true, then `io` will be closed when this decoder is done
 * with it. If this function fails and `closeio` is true, then `io` will be
 * closed before this function returns.
 *
 * When done with the audio decoder, it can be destroyed with
 * MIX_DestroyAudioDecoder().
 *
 * This function requires SDL_mixer to have been initialized with a successful
 * call to MIX_Init(), but does not need an actual MIX_Mixer to have been
 * created.
 *
 * \param io the i/o stream from which to load data.
 * \param closeio if true, close the i/o stream when done with it.
 * \param props decoder-specific properties. May be zero.
 * \returns an audio decoder, ready to decode.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_CreateAudioDecoder_IO
 * \sa MIX_DecodeAudio
 * \sa MIX_DestroyAudioDecoder
 */
extern SDL_DECLSPEC MIX_AudioDecoder * SDLCALL MIX_CreateAudioDecoder_IO(SDL_IOStream *io, bool closeio, SDL_PropertiesID props);

/**
 * Destroy the specified audio decoder.
 *
 * Destroying a NULL MIX_AudioDecoder is a legal no-op.
 *
 * \param audiodecoder the audio to destroy.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 */
extern SDL_DECLSPEC void SDLCALL MIX_DestroyAudioDecoder(MIX_AudioDecoder *audiodecoder);

/**
 * Get the properties associated with a MIX_AudioDecoder.
 *
 * SDL_mixer offers some properties of its own, but this can also be a
 * convenient place to store app-specific data.
 *
 * A SDL_PropertiesID is created the first time this function is called for a
 * given MIX_AudioDecoder, if necessary.
 *
 * The file-specific metadata exposed through this function is identical to
 * those available through MIX_GetAudioProperties(). Please refer to that
 * function's documentation for details.
 *
 * \param audiodecoder the audio decoder to query.
 * \returns a valid property ID on success or 0 on failure; call
 *          SDL_GetError() for more information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 *
 * \sa MIX_GetAudioProperties
 */
extern SDL_DECLSPEC SDL_PropertiesID SDLCALL MIX_GetAudioDecoderProperties(MIX_AudioDecoder *audiodecoder);

/**
 * Query the initial audio format of a MIX_AudioDecoder.
 *
 * Note that some audio files can change format in the middle; some explicitly
 * support this, but a more common example is two MP3 files concatenated
 * together. In many cases, SDL_mixer will correctly handle these sort of
 * files, but this function will only report the initial format a file uses.
 *
 * \param audiodecoder the audio decoder to query.
 * \param spec on success, audio format details will be stored here.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 */
extern SDL_DECLSPEC bool SDLCALL MIX_GetAudioDecoderFormat(MIX_AudioDecoder *audiodecoder, SDL_AudioSpec *spec);

/**
 * Decode more audio from a MIX_AudioDecoder.
 *
 * Data is decoded on demand in whatever format is requested. The format is
 * permitted to change between calls.
 *
 * This function will return the number of bytes decoded, which may be less
 * than requested if there was an error or end-of-file. A return value of zero
 * means the entire file was decoded, -1 means an unrecoverable error
 * happened.
 *
 * \param audiodecoder the decoder from which to retrieve more data.
 * \param buffer the memory buffer to store decoded audio.
 * \param buflen the maximum number of bytes to store to `buffer`.
 * \param spec the format that audio data will be stored to `buffer`.
 * \returns number of bytes decoded, or -1 on error; call SDL_GetError() for
 *          more information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_mixer 3.0.0.
 */
extern SDL_DECLSPEC int SDLCALL MIX_DecodeAudio(MIX_AudioDecoder *audiodecoder, void *buffer, int buflen, const SDL_AudioSpec *spec);

/* Ends C function definitions when using C++ */
#ifdef __cplusplus
}
#endif
#include <SDL3/SDL_close_code.h>

#endif /* SDL_MIXER_H_ */
