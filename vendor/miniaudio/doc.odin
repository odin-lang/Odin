package miniaudio

/*
Audio playback and capture library. Choice of public domain or MIT-0. See license statements at the end of this file.
miniaudio - v0.10.42 - 2021-08-22

David Reid - mackron@gmail.com

Website:       https://miniaud.io
Documentation: https://miniaud.io/docs
GitHub:        https://github.com/mackron/miniaudio
*/

/*
1. Introduction
===============
miniaudio is a single file library for audio playback and capture. To use it, do the following in one .c file:

    ```c
    #define MINIAUDIO_IMPLEMENTATION
    #include "miniaudio.h"
    ```

You can do `#include "miniaudio.h"` in other parts of the program just like any other header.

miniaudio uses the concept of a "device" as the abstraction for physical devices. The idea is that you choose a physical device to emit or capture audio from,
and then move data to/from the device when miniaudio tells you to. Data is delivered to and from devices asynchronously via a callback which you specify when
initializing the device.

When initializing the device you first need to configure it. The device configuration allows you to specify things like the format of the data delivered via
the callback, the size of the internal buffer and the ID of the device you want to emit or capture audio from.

Once you have the device configuration set up you can initialize the device. When initializing a device you need to allocate memory for the device object
beforehand. This gives the application complete control over how the memory is allocated. In the example below we initialize a playback device on the stack,
but you could allocate it on the heap if that suits your situation better.

    ```c
    void data_callback(ma_device* pDevice, void* pOutput, const void* pInput, ma_uint32 frameCount)
    {
        // In playback mode copy data to pOutput. In capture mode read data from pInput. In full-duplex mode, both
        // pOutput and pInput will be valid and you can move data from pInput into pOutput. Never process more than
        // frameCount frames.
    }

    int main()
    {
        ma_device_config config = ma_device_config_init(ma_device_type_playback);
        config.playback.format   = ma_format_f32;   // Set to ma_format_unknown to use the device's native format.
        config.playback.channels = 2;               // Set to 0 to use the device's native channel count.
        config.sampleRate        = 48000;           // Set to 0 to use the device's native sample rate.
        config.dataCallback      = data_callback;   // This function will be called when miniaudio needs more data.
        config.pUserData         = pMyCustomData;   // Can be accessed from the device object (device.pUserData).

        ma_device device;
        if (ma_device_init(NULL, &config, &device) != MA_SUCCESS) {
            return -1;  // Failed to initialize the device.
        }

        ma_device_start(&device);     // The device is sleeping by default so you'll need to start it manually.

        // Do something here. Probably your program's main loop.

        ma_device_uninit(&device);    // This will stop the device so no need to do that manually.
        return 0;
    }
    ```

In the example above, `data_callback()` is where audio data is written and read from the device. The idea is in playback mode you cause sound to be emitted
from the speakers by writing audio data to the output buffer (`pOutput` in the example). In capture mode you read data from the input buffer (`pInput`) to
extract sound captured by the microphone. The `frameCount` parameter tells you how many frames can be written to the output buffer and read from the input
buffer. A "frame" is one sample for each channel. For example, in a stereo stream (2 channels), one frame is 2 samples: one for the left, one for the right.
The channel count is defined by the device config. The size in bytes of an individual sample is defined by the sample format which is also specified in the
device config. Multi-channel audio data is always interleaved, which means the samples for each frame are stored next to each other in memory. For example, in
a stereo stream the first pair of samples will be the left and right samples for the first frame, the second pair of samples will be the left and right samples
for the second frame, etc.

The configuration of the device is defined by the `ma_device_config` structure. The config object is always initialized with `ma_device_config_init()`. It's
important to always initialize the config with this function as it initializes it with logical defaults and ensures your program doesn't break when new members
are added to the `ma_device_config` structure. The example above uses a fairly simple and standard device configuration. The call to `ma_device_config_init()`
takes a single parameter, which is whether or not the device is a playback, capture, duplex or loopback device (loopback devices are not supported on all
backends). The `config.playback.format` member sets the sample format which can be one of the following (all formats are native-endian):

    +---------------+----------------------------------------+---------------------------+
    | Symbol        | Description                            | Range                     |
    +---------------+----------------------------------------+---------------------------+
    | ma_format_f32 | 32-bit floating point                  | [-1, 1]                   |
    | ma_format_s16 | 16-bit signed integer                  | [-32768, 32767]           |
    | ma_format_s24 | 24-bit signed integer (tightly packed) | [-8388608, 8388607]       |
    | ma_format_s32 | 32-bit signed integer                  | [-2147483648, 2147483647] |
    | ma_format_u8  | 8-bit unsigned integer                 | [0, 255]                  |
    +---------------+----------------------------------------+---------------------------+

The `config.playback.channels` member sets the number of channels to use with the device. The channel count cannot exceed MA_MAX_CHANNELS. The
`config.sampleRate` member sets the sample rate (which must be the same for both playback and capture in full-duplex configurations). This is usually set to
44100 or 48000, but can be set to anything. It's recommended to keep this between 8000 and 384000, however.

Note that leaving the format, channel count and/or sample rate at their default values will result in the internal device's native configuration being used
which is useful if you want to avoid the overhead of miniaudio's automatic data conversion.

In addition to the sample format, channel count and sample rate, the data callback and user data pointer are also set via the config. The user data pointer is
not passed into the callback as a parameter, but is instead set to the `pUserData` member of `ma_device` which you can access directly since all miniaudio
structures are transparent.

Initializing the device is done with `ma_device_init()`. This will return a result code telling you what went wrong, if anything. On success it will return
`MA_SUCCESS`. After initialization is complete the device will be in a stopped state. To start it, use `ma_device_start()`. Uninitializing the device will stop
it, which is what the example above does, but you can also stop the device with `ma_device_stop()`. To resume the device simply call `ma_device_start()` again.
Note that it's important to never stop or start the device from inside the callback. This will result in a deadlock. Instead you set a variable or signal an
event indicating that the device needs to stop and handle it in a different thread. The following APIs must never be called inside the callback:

    ```c
    ma_device_init()
    ma_device_init_ex()
    ma_device_uninit()
    ma_device_start()
    ma_device_stop()
    ```

You must never try uninitializing and reinitializing a device inside the callback. You must also never try to stop and start it from inside the callback. There
are a few other things you shouldn't do in the callback depending on your requirements, however this isn't so much a thread-safety thing, but rather a
real-time processing thing which is beyond the scope of this introduction.

The example above demonstrates the initialization of a playback device, but it works exactly the same for capture. All you need to do is change the device type
from `ma_device_type_playback` to `ma_device_type_capture` when setting up the config, like so:

    ```c
    ma_device_config config = ma_device_config_init(ma_device_type_capture);
    config.capture.format   = MY_FORMAT;
    config.capture.channels = MY_CHANNEL_COUNT;
    ```

In the data callback you just read from the input buffer (`pInput` in the example above) and leave the output buffer alone (it will be set to NULL when the
device type is set to `ma_device_type_capture`).

These are the available device types and how you should handle the buffers in the callback:

    +-------------------------+--------------------------------------------------------+
    | Device Type             | Callback Behavior                                      |
    +-------------------------+--------------------------------------------------------+
    | ma_device_type_playback | Write to output buffer, leave input buffer untouched.  |
    | ma_device_type_capture  | Read from input buffer, leave output buffer untouched. |
    | ma_device_type_duplex   | Read from input buffer, write to output buffer.        |
    | ma_device_type_loopback | Read from input buffer, leave output buffer untouched. |
    +-------------------------+--------------------------------------------------------+

You will notice in the example above that the sample format and channel count is specified separately for playback and capture. This is to support different
data formats between the playback and capture devices in a full-duplex system. An example may be that you want to capture audio data as a monaural stream (one
channel), but output sound to a stereo speaker system. Note that if you use different formats between playback and capture in a full-duplex configuration you
will need to convert the data yourself. There are functions available to help you do this which will be explained later.

The example above did not specify a physical device to connect to which means it will use the operating system's default device. If you have multiple physical
devices connected and you want to use a specific one you will need to specify the device ID in the configuration, like so:

    ```c
    config.playback.pDeviceID = pMyPlaybackDeviceID;    // Only if requesting a playback or duplex device.
    config.capture.pDeviceID = pMyCaptureDeviceID;      // Only if requesting a capture, duplex or loopback device.
    ```

To retrieve the device ID you will need to perform device enumeration, however this requires the use of a new concept called the "context". Conceptually
speaking the context sits above the device. There is one context to many devices. The purpose of the context is to represent the backend at a more global level
and to perform operations outside the scope of an individual device. Mainly it is used for performing run-time linking against backend libraries, initializing
backends and enumerating devices. The example below shows how to enumerate devices.

    ```c
    ma_context context;
    if (ma_context_init(NULL, 0, NULL, &context) != MA_SUCCESS) {
        // Error.
    }

    ma_device_info* pPlaybackInfos;
    ma_uint32 playbackCount;
    ma_device_info* pCaptureInfos;
    ma_uint32 captureCount;
    if (ma_context_get_devices(&context, &pPlaybackInfos, &playbackCount, &pCaptureInfos, &captureCount) != MA_SUCCESS) {
        // Error.
    }

    // Loop over each device info and do something with it. Here we just print the name with their index. You may want
    // to give the user the opportunity to choose which device they'd prefer.
    for (ma_uint32 iDevice = 0; iDevice < playbackCount; iDevice += 1) {
        printf("%d - %s\n", iDevice, pPlaybackInfos[iDevice].name);
    }

    ma_device_config config = ma_device_config_init(ma_device_type_playback);
    config.playback.pDeviceID = &pPlaybackInfos[chosenPlaybackDeviceIndex].id;
    config.playback.format    = MY_FORMAT;
    config.playback.channels  = MY_CHANNEL_COUNT;
    config.sampleRate         = MY_SAMPLE_RATE;
    config.dataCallback       = data_callback;
    config.pUserData          = pMyCustomData;

    ma_device device;
    if (ma_device_init(&context, &config, &device) != MA_SUCCESS) {
        // Error
    }

    ...

    ma_device_uninit(&device);
    ma_context_uninit(&context);
    ```

The first thing we do in this example is initialize a `ma_context` object with `ma_context_init()`. The first parameter is a pointer to a list of `ma_backend`
values which are used to override the default backend priorities. When this is NULL, as in this example, miniaudio's default priorities are used. The second
parameter is the number of backends listed in the array pointed to by the first parameter. The third parameter is a pointer to a `ma_context_config` object
which can be NULL, in which case defaults are used. The context configuration is used for setting the logging callback, custom memory allocation callbacks,
user-defined data and some backend-specific configurations.

Once the context has been initialized you can enumerate devices. In the example above we use the simpler `ma_context_get_devices()`, however you can also use a
callback for handling devices by using `ma_context_enumerate_devices()`. When using `ma_context_get_devices()` you provide a pointer to a pointer that will,
upon output, be set to a pointer to a buffer containing a list of `ma_device_info` structures. You also provide a pointer to an unsigned integer that will
receive the number of items in the returned buffer. Do not free the returned buffers as their memory is managed internally by miniaudio.

The `ma_device_info` structure contains an `id` member which is the ID you pass to the device config. It also contains the name of the device which is useful
for presenting a list of devices to the user via the UI.

When creating your own context you will want to pass it to `ma_device_init()` when initializing the device. Passing in NULL, like we do in the first example,
will result in miniaudio creating the context for you, which you don't want to do since you've already created a context. Note that internally the context is
only tracked by it's pointer which means you must not change the location of the `ma_context` object. If this is an issue, consider using `malloc()` to
allocate memory for the context.



2. Building
===========
miniaudio should work cleanly out of the box without the need to download or install any dependencies. See below for platform-specific details.


2.1. Windows
------------
The Windows build should compile cleanly on all popular compilers without the need to configure any include paths nor link to any libraries.

2.2. macOS and iOS
------------------
The macOS build should compile cleanly without the need to download any dependencies nor link to any libraries or frameworks. The iOS build needs to be
compiled as Objective-C and will need to link the relevant frameworks but should compile cleanly out of the box with Xcode. Compiling through the command line
requires linking to `-lpthread` and `-lm`.

Due to the way miniaudio links to frameworks at runtime, your application may not pass Apple's notarization process. To fix this there are two options. The
first is to use the `MA_NO_RUNTIME_LINKING` option, like so:

    ```c
    #ifdef __APPLE__
        #define MA_NO_RUNTIME_LINKING
    #endif
    #define MINIAUDIO_IMPLEMENTATION
    #include "miniaudio.h"
    ```

This will require linking with `-framework CoreFoundation -framework CoreAudio -framework AudioUnit`. Alternatively, if you would rather keep using runtime
linking you can add the following to your entitlements.xcent file:

    ```
    <key>com.apple.security.cs.allow-dyld-environment-variables</key>
    <true/>
    <key>com.apple.security.cs.allow-unsigned-executable-memory</key>
    <true/>
    ```


2.3. Linux
----------
The Linux build only requires linking to `-ldl`, `-lpthread` and `-lm`. You do not need any development packages.

2.4. BSD
--------
The BSD build only requires linking to `-lpthread` and `-lm`. NetBSD uses audio(4), OpenBSD uses sndio and FreeBSD uses OSS.

2.5. Android
------------
AAudio is the highest priority backend on Android. This should work out of the box without needing any kind of compiler configuration. Support for AAudio
starts with Android 8 which means older versions will fall back to OpenSL|ES which requires API level 16+.

There have been reports that the OpenSL|ES backend fails to initialize on some Android based devices due to `dlopen()` failing to open "libOpenSLES.so". If
this happens on your platform you'll need to disable run-time linking with `MA_NO_RUNTIME_LINKING` and link with -lOpenSLES.

2.6. Emscripten
---------------
The Emscripten build emits Web Audio JavaScript directly and should compile cleanly out of the box. You cannot use -std=c* compiler flags, nor -ansi.


2.7. Build Options
------------------
`#define` these options before including miniaudio.h.

    +----------------------------------+--------------------------------------------------------------------+
    | Option                           | Description                                                        |
    +----------------------------------+--------------------------------------------------------------------+
    | MA_NO_WASAPI                     | Disables the WASAPI backend.                                       |
    +----------------------------------+--------------------------------------------------------------------+
    | MA_NO_DSOUND                     | Disables the DirectSound backend.                                  |
    +----------------------------------+--------------------------------------------------------------------+
    | MA_NO_WINMM                      | Disables the WinMM backend.                                        |
    +----------------------------------+--------------------------------------------------------------------+
    | MA_NO_ALSA                       | Disables the ALSA backend.                                         |
    +----------------------------------+--------------------------------------------------------------------+
    | MA_NO_PULSEAUDIO                 | Disables the PulseAudio backend.                                   |
    +----------------------------------+--------------------------------------------------------------------+
    | MA_NO_JACK                       | Disables the JACK backend.                                         |
    +----------------------------------+--------------------------------------------------------------------+
    | MA_NO_COREAUDIO                  | Disables the Core Audio backend.                                   |
    +----------------------------------+--------------------------------------------------------------------+
    | MA_NO_SNDIO                      | Disables the sndio backend.                                        |
    +----------------------------------+--------------------------------------------------------------------+
    | MA_NO_AUDIO4                     | Disables the audio(4) backend.                                     |
    +----------------------------------+--------------------------------------------------------------------+
    | MA_NO_OSS                        | Disables the OSS backend.                                          |
    +----------------------------------+--------------------------------------------------------------------+
    | MA_NO_AAUDIO                     | Disables the AAudio backend.                                       |
    +----------------------------------+--------------------------------------------------------------------+
    | MA_NO_OPENSL                     | Disables the OpenSL|ES backend.                                    |
    +----------------------------------+--------------------------------------------------------------------+
    | MA_NO_WEBAUDIO                   | Disables the Web Audio backend.                                    |
    +----------------------------------+--------------------------------------------------------------------+
    | MA_NO_NULL                       | Disables the null backend.                                         |
    +----------------------------------+--------------------------------------------------------------------+
    | MA_ENABLE_ONLY_SPECIFIC_BACKENDS | Disables all backends by default and requires `MA_ENABLE_*` to     |
    |                                  | enable specific backends.                                          |
    +----------------------------------+--------------------------------------------------------------------+
    | MA_ENABLE_WASAPI                 | Used in conjunction with MA_ENABLE_ONLY_SPECIFIC_BACKENDS to       |
    |                                  | enable the WASAPI backend.                                         |
    +----------------------------------+--------------------------------------------------------------------+
    | MA_ENABLE_DSOUND                 | Used in conjunction with MA_ENABLE_ONLY_SPECIFIC_BACKENDS to       |
    |                                  | enable the DirectSound backend.                                    |
    +----------------------------------+--------------------------------------------------------------------+
    | MA_ENABLE_WINMM                  | Used in conjunction with MA_ENABLE_ONLY_SPECIFIC_BACKENDS to       |
    |                                  | enable the WinMM backend.                                          |
    +----------------------------------+--------------------------------------------------------------------+
    | MA_ENABLE_ALSA                   | Used in conjunction with MA_ENABLE_ONLY_SPECIFIC_BACKENDS to       |
    |                                  | enable the ALSA backend.                                           |
    +----------------------------------+--------------------------------------------------------------------+
    | MA_ENABLE_PULSEAUDIO             | Used in conjunction with MA_ENABLE_ONLY_SPECIFIC_BACKENDS to       |
    |                                  | enable the PulseAudio backend.                                     |
    +----------------------------------+--------------------------------------------------------------------+
    | MA_ENABLE_JACK                   | Used in conjunction with MA_ENABLE_ONLY_SPECIFIC_BACKENDS to       |
    |                                  | enable the JACK backend.                                           |
    +----------------------------------+--------------------------------------------------------------------+
    | MA_ENABLE_COREAUDIO              | Used in conjunction with MA_ENABLE_ONLY_SPECIFIC_BACKENDS to       |
    |                                  | enable the Core Audio backend.                                     |
    +----------------------------------+--------------------------------------------------------------------+
    | MA_ENABLE_SNDIO                  | Used in conjunction with MA_ENABLE_ONLY_SPECIFIC_BACKENDS to       |
    |                                  | enable the sndio backend.                                          |
    +----------------------------------+--------------------------------------------------------------------+
    | MA_ENABLE_AUDIO4                 | Used in conjunction with MA_ENABLE_ONLY_SPECIFIC_BACKENDS to       |
    |                                  | enable the audio(4) backend.                                       |
    +----------------------------------+--------------------------------------------------------------------+
    | MA_ENABLE_OSS                    | Used in conjunction with MA_ENABLE_ONLY_SPECIFIC_BACKENDS to       |
    |                                  | enable the OSS backend.                                            |
    +----------------------------------+--------------------------------------------------------------------+
    | MA_ENABLE_AAUDIO                 | Used in conjunction with MA_ENABLE_ONLY_SPECIFIC_BACKENDS to       |
    |                                  | enable the AAudio backend.                                         |
    +----------------------------------+--------------------------------------------------------------------+
    | MA_ENABLE_OPENSL                 | Used in conjunction with MA_ENABLE_ONLY_SPECIFIC_BACKENDS to       |
    |                                  | enable the OpenSL|ES backend.                                      |
    +----------------------------------+--------------------------------------------------------------------+
    | MA_ENABLE_WEBAUDIO               | Used in conjunction with MA_ENABLE_ONLY_SPECIFIC_BACKENDS to       |
    |                                  | enable the Web Audio backend.                                      |
    +----------------------------------+--------------------------------------------------------------------+
    | MA_ENABLE_NULL                   | Used in conjunction with MA_ENABLE_ONLY_SPECIFIC_BACKENDS to       |
    |                                  | enable the null backend.                                           |
    +----------------------------------+--------------------------------------------------------------------+
    | MA_NO_DECODING                   | Disables decoding APIs.                                            |
    +----------------------------------+--------------------------------------------------------------------+
    | MA_NO_ENCODING                   | Disables encoding APIs.                                            |
    +----------------------------------+--------------------------------------------------------------------+
    | MA_NO_WAV                        | Disables the built-in WAV decoder and encoder.                     |
    +----------------------------------+--------------------------------------------------------------------+
    | MA_NO_FLAC                       | Disables the built-in FLAC decoder.                                |
    +----------------------------------+--------------------------------------------------------------------+
    | MA_NO_MP3                        | Disables the built-in MP3 decoder.                                 |
    +----------------------------------+--------------------------------------------------------------------+
    | MA_NO_DEVICE_IO                  | Disables playback and recording. This will disable ma_context and  |
    |                                  | ma_device APIs. This is useful if you only want to use miniaudio's |
    |                                  | data conversion and/or decoding APIs.                              |
    +----------------------------------+--------------------------------------------------------------------+
    | MA_NO_THREADING                  | Disables the ma_thread, ma_mutex, ma_semaphore and ma_event APIs.  |
    |                                  | This option is useful if you only need to use miniaudio for data   |
    |                                  | conversion, decoding and/or encoding. Some families of APIs        |
    |                                  | require threading which means the following options must also be   |
    |                                  | set:                                                               |
    |                                  |                                                                    |
    |                                  |     ```                                                            |
    |                                  |     MA_NO_DEVICE_IO                                                |
    |                                  |     ```                                                            |
    +----------------------------------+--------------------------------------------------------------------+
    | MA_NO_GENERATION                 | Disables generation APIs such a ma_waveform and ma_noise.          |
    +----------------------------------+--------------------------------------------------------------------+
    | MA_NO_SSE2                       | Disables SSE2 optimizations.                                       |
    +----------------------------------+--------------------------------------------------------------------+
    | MA_NO_AVX2                       | Disables AVX2 optimizations.                                       |
    +----------------------------------+--------------------------------------------------------------------+
    | MA_NO_AVX512                     | Disables AVX-512 optimizations.                                    |
    +----------------------------------+--------------------------------------------------------------------+
    | MA_NO_NEON                       | Disables NEON optimizations.                                       |
    +----------------------------------+--------------------------------------------------------------------+
    | MA_NO_RUNTIME_LINKING            | Disables runtime linking. This is useful for passing Apple's       |
    |                                  | notarization process. When enabling this, you may need to avoid    |
    |                                  | using `-std=c89` or `-std=c99` on Linux builds or else you may end |
    |                                  | up with compilation errors due to conflicts with `timespec` and    |
    |                                  | `timeval` data types.                                              |
    |                                  |                                                                    |
    |                                  | You may need to enable this if your target platform does not allow |
    |                                  | runtime linking via `dlopen()`.                                    |
    +----------------------------------+--------------------------------------------------------------------+
    | MA_DEBUG_OUTPUT                  | Enable processing of MA_LOG_LEVEL_DEBUG messages and `printf()`    |
    |                                  | output.                                                            |
    +----------------------------------+--------------------------------------------------------------------+
    | MA_COINIT_VALUE                  | Windows only. The value to pass to internal calls to               |
    |                                  | `CoInitializeEx()`. Defaults to `COINIT_MULTITHREADED`.            |
    +----------------------------------+--------------------------------------------------------------------+
    | MA_API                           | Controls how public APIs should be decorated. Default is `extern`. |
    +----------------------------------+--------------------------------------------------------------------+
    | MA_DLL                           | If set, configures MA_API to either import or export APIs          |
    |                                  | depending on whether or not the implementation is being defined.   |
    |                                  | If defining the implementation, MA_API will be configured to       |
    |                                  | export. Otherwise it will be configured to import. This has no     |
    |                                  | effect if MA_API is defined externally.                            |
    +----------------------------------+--------------------------------------------------------------------+


3. Definitions
==============
This section defines common terms used throughout miniaudio. Unfortunately there is often ambiguity in the use of terms throughout the audio space, so this
section is intended to clarify how miniaudio uses each term.

3.1. Sample
-----------
A sample is a single unit of audio data. If the sample format is f32, then one sample is one 32-bit floating point number.

3.2. Frame / PCM Frame
----------------------
A frame is a group of samples equal to the number of channels. For a stereo stream a frame is 2 samples, a mono frame is 1 sample, a 5.1 surround sound frame
is 6 samples, etc. The terms "frame" and "PCM frame" are the same thing in miniaudio. Note that this is different to a compressed frame. If ever miniaudio
needs to refer to a compressed frame, such as a FLAC frame, it will always clarify what it's referring to with something like "FLAC frame".

3.3. Channel
------------
A stream of monaural audio that is emitted from an individual speaker in a speaker system, or received from an individual microphone in a microphone system. A
stereo stream has two channels (a left channel, and a right channel), a 5.1 surround sound system has 6 channels, etc. Some audio systems refer to a channel as
a complex audio stream that's mixed with other channels to produce the final mix - this is completely different to miniaudio's use of the term "channel" and
should not be confused.

3.4. Sample Rate
----------------
The sample rate in miniaudio is always expressed in Hz, such as 44100, 48000, etc. It's the number of PCM frames that are processed per second.

3.5. Formats
------------
Throughout miniaudio you will see references to different sample formats:

    +---------------+----------------------------------------+---------------------------+
    | Symbol        | Description                            | Range                     |
    +---------------+----------------------------------------+---------------------------+
    | ma_format_f32 | 32-bit floating point                  | [-1, 1]                   |
    | ma_format_s16 | 16-bit signed integer                  | [-32768, 32767]           |
    | ma_format_s24 | 24-bit signed integer (tightly packed) | [-8388608, 8388607]       |
    | ma_format_s32 | 32-bit signed integer                  | [-2147483648, 2147483647] |
    | ma_format_u8  | 8-bit unsigned integer                 | [0, 255]                  |
    +---------------+----------------------------------------+---------------------------+

All formats are native-endian.



4. Decoding
===========
The `ma_decoder` API is used for reading audio files. Decoders are completely decoupled from devices and can be used independently. The following formats are
supported:

    +---------+------------------+----------+
    | Format  | Decoding Backend | Built-In |
    +---------+------------------+----------+
    | WAV     | dr_wav           | Yes      |
    | MP3     | dr_mp3           | Yes      |
    | FLAC    | dr_flac          | Yes      |
    | Vorbis  | stb_vorbis       | No       |
    +---------+------------------+----------+

Vorbis is supported via stb_vorbis which can be enabled by including the header section before the implementation of miniaudio, like the following:

    ```c
    #define STB_VORBIS_HEADER_ONLY
    #include "extras/stb_vorbis.c"    // Enables Vorbis decoding.

    #define MINIAUDIO_IMPLEMENTATION
    #include "miniaudio.h"

    // The stb_vorbis implementation must come after the implementation of miniaudio.
    #undef STB_VORBIS_HEADER_ONLY
    #include "extras/stb_vorbis.c"
    ```

A copy of stb_vorbis is included in the "extras" folder in the miniaudio repository (https://github.com/mackron/miniaudio).

Built-in decoders are amalgamated into the implementation section of miniaudio. You can disable the built-in decoders by specifying one or more of the
following options before the miniaudio implementation:

    ```c
    #define MA_NO_WAV
    #define MA_NO_MP3
    #define MA_NO_FLAC
    ```

Disabling built-in decoding libraries is useful if you use these libraries independantly of the `ma_decoder` API.

A decoder can be initialized from a file with `ma_decoder_init_file()`, a block of memory with `ma_decoder_init_memory()`, or from data delivered via callbacks
with `ma_decoder_init()`. Here is an example for loading a decoder from a file:

    ```c
    ma_decoder decoder;
    ma_result result = ma_decoder_init_file("MySong.mp3", NULL, &decoder);
    if (result != MA_SUCCESS) {
        return false;   // An error occurred.
    }

    ...

    ma_decoder_uninit(&decoder);
    ```

When initializing a decoder, you can optionally pass in a pointer to a `ma_decoder_config` object (the `NULL` argument in the example above) which allows you
to configure the output format, channel count, sample rate and channel map:

    ```c
    ma_decoder_config config = ma_decoder_config_init(ma_format_f32, 2, 48000);
    ```

When passing in `NULL` for decoder config in `ma_decoder_init*()`, the output format will be the same as that defined by the decoding backend.

Data is read from the decoder as PCM frames. This will return the number of PCM frames actually read. If the return value is less than the requested number of
PCM frames it means you've reached the end:

    ```c
    ma_uint64 framesRead = ma_decoder_read_pcm_frames(pDecoder, pFrames, framesToRead);
    if (framesRead < framesToRead) {
        // Reached the end.
    }
    ```

You can also seek to a specific frame like so:

    ```c
    ma_result result = ma_decoder_seek_to_pcm_frame(pDecoder, targetFrame);
    if (result != MA_SUCCESS) {
        return false;   // An error occurred.
    }
    ```

If you want to loop back to the start, you can simply seek back to the first PCM frame:

    ```c
    ma_decoder_seek_to_pcm_frame(pDecoder, 0);
    ```

When loading a decoder, miniaudio uses a trial and error technique to find the appropriate decoding backend. This can be unnecessarily inefficient if the type
is already known. In this case you can use `encodingFormat` variable in the device config to specify a specific encoding format you want to decode:

    ```c
    decoderConfig.encodingFormat = ma_encoding_format_wav;
    ```

See the `ma_encoding_format` enum for possible encoding formats.

The `ma_decoder_init_file()` API will try using the file extension to determine which decoding backend to prefer.



5. Encoding
===========
The `ma_encoding` API is used for writing audio files. The only supported output format is WAV which is achieved via dr_wav which is amalgamated into the
implementation section of miniaudio. This can be disabled by specifying the following option before the implementation of miniaudio:

    ```c
    #define MA_NO_WAV
    ```

An encoder can be initialized to write to a file with `ma_encoder_init_file()` or from data delivered via callbacks with `ma_encoder_init()`. Below is an
example for initializing an encoder to output to a file.

    ```c
    ma_encoder_config config = ma_encoder_config_init(ma_resource_format_wav, FORMAT, CHANNELS, SAMPLE_RATE);
    ma_encoder encoder;
    ma_result result = ma_encoder_init_file("my_file.wav", &config, &encoder);
    if (result != MA_SUCCESS) {
        // Error
    }

    ...

    ma_encoder_uninit(&encoder);
    ```

When initializing an encoder you must specify a config which is initialized with `ma_encoder_config_init()`. Here you must specify the file type, the output
sample format, output channel count and output sample rate. The following file types are supported:

    +------------------------+-------------+
    | Enum                   | Description |
    +------------------------+-------------+
    | ma_resource_format_wav | WAV         |
    +------------------------+-------------+

If the format, channel count or sample rate is not supported by the output file type an error will be returned. The encoder will not perform data conversion so
you will need to convert it before outputting any audio data. To output audio data, use `ma_encoder_write_pcm_frames()`, like in the example below:

    ```c
    framesWritten = ma_encoder_write_pcm_frames(&encoder, pPCMFramesToWrite, framesToWrite);
    ```

Encoders must be uninitialized with `ma_encoder_uninit()`.


6. Data Conversion
==================
A data conversion API is included with miniaudio which supports the majority of data conversion requirements. This supports conversion between sample formats,
channel counts (with channel mapping) and sample rates.


6.1. Sample Format Conversion
-----------------------------
Conversion between sample formats is achieved with the `ma_pcm_*_to_*()`, `ma_pcm_convert()` and `ma_convert_pcm_frames_format()` APIs. Use `ma_pcm_*_to_*()`
to convert between two specific formats. Use `ma_pcm_convert()` to convert based on a `ma_format` variable. Use `ma_convert_pcm_frames_format()` to convert
PCM frames where you want to specify the frame count and channel count as a variable instead of the total sample count.


6.1.1. Dithering
----------------
Dithering can be set using the ditherMode parameter.

The different dithering modes include the following, in order of efficiency:

    +-----------+--------------------------+
    | Type      | Enum Token               |
    +-----------+--------------------------+
    | None      | ma_dither_mode_none      |
    | Rectangle | ma_dither_mode_rectangle |
    | Triangle  | ma_dither_mode_triangle  |
    +-----------+--------------------------+

Note that even if the dither mode is set to something other than `ma_dither_mode_none`, it will be ignored for conversions where dithering is not needed.
Dithering is available for the following conversions:

    ```
    s16 -> u8
    s24 -> u8
    s32 -> u8
    f32 -> u8
    s24 -> s16
    s32 -> s16
    f32 -> s16
    ```

Note that it is not an error to pass something other than ma_dither_mode_none for conversions where dither is not used. It will just be ignored.



6.2. Channel Conversion
-----------------------
Channel conversion is used for channel rearrangement and conversion from one channel count to another. The `ma_channel_converter` API is used for channel
conversion. Below is an example of initializing a simple channel converter which converts from mono to stereo.

    ```c
    ma_channel_converter_config config = ma_channel_converter_config_init(
        ma_format,                      // Sample format
        1,                              // Input channels
        NULL,                           // Input channel map
        2,                              // Output channels
        NULL,                           // Output channel map
        ma_channel_mix_mode_default);   // The mixing algorithm to use when combining channels.

    result = ma_channel_converter_init(&config, &converter);
    if (result != MA_SUCCESS) {
        // Error.
    }
    ```

To perform the conversion simply call `ma_channel_converter_process_pcm_frames()` like so:

    ```c
    ma_result result = ma_channel_converter_process_pcm_frames(&converter, pFramesOut, pFramesIn, frameCount);
    if (result != MA_SUCCESS) {
        // Error.
    }
    ```

It is up to the caller to ensure the output buffer is large enough to accomodate the new PCM frames.

Input and output PCM frames are always interleaved. Deinterleaved layouts are not supported.


6.2.1. Channel Mapping
----------------------
In addition to converting from one channel count to another, like the example above, the channel converter can also be used to rearrange channels. When
initializing the channel converter, you can optionally pass in channel maps for both the input and output frames. If the channel counts are the same, and each
channel map contains the same channel positions with the exception that they're in a different order, a simple shuffling of the channels will be performed. If,
however, there is not a 1:1 mapping of channel positions, or the channel counts differ, the input channels will be mixed based on a mixing mode which is
specified when initializing the `ma_channel_converter_config` object.

When converting from mono to multi-channel, the mono channel is simply copied to each output channel. When going the other way around, the audio of each output
channel is simply averaged and copied to the mono channel.

In more complicated cases blending is used. The `ma_channel_mix_mode_simple` mode will drop excess channels and silence extra channels. For example, converting
from 4 to 2 channels, the 3rd and 4th channels will be dropped, whereas converting from 2 to 4 channels will put silence into the 3rd and 4th channels.

The `ma_channel_mix_mode_rectangle` mode uses spacial locality based on a rectangle to compute a simple distribution between input and output. Imagine sitting
in the middle of a room, with speakers on the walls representing channel positions. The MA_CHANNEL_FRONT_LEFT position can be thought of as being in the corner
of the front and left walls.

Finally, the `ma_channel_mix_mode_custom_weights` mode can be used to use custom user-defined weights. Custom weights can be passed in as the last parameter of
`ma_channel_converter_config_init()`.

Predefined channel maps can be retrieved with `ma_get_standard_channel_map()`. This takes a `ma_standard_channel_map` enum as it's first parameter, which can
be one of the following:

    +-----------------------------------+-----------------------------------------------------------+
    | Name                              | Description                                               |
    +-----------------------------------+-----------------------------------------------------------+
    | ma_standard_channel_map_default   | Default channel map used by miniaudio. See below.         |
    | ma_standard_channel_map_microsoft | Channel map used by Microsoft's bitfield channel maps.    |
    | ma_standard_channel_map_alsa      | Default ALSA channel map.                                 |
    | ma_standard_channel_map_rfc3551   | RFC 3551. Based on AIFF.                                  |
    | ma_standard_channel_map_flac      | FLAC channel map.                                         |
    | ma_standard_channel_map_vorbis    | Vorbis channel map.                                       |
    | ma_standard_channel_map_sound4    | FreeBSD's sound(4).                                       |
    | ma_standard_channel_map_sndio     | sndio channel map. http://www.sndio.org/tips.html.        |
    | ma_standard_channel_map_webaudio  | https://webaudio.github.io/web-audio-api/#ChannelOrdering |
    +-----------------------------------+-----------------------------------------------------------+

Below are the channel maps used by default in miniaudio (`ma_standard_channel_map_default`):

    +---------------+---------------------------------+
    | Channel Count | Mapping                         |
    +---------------+---------------------------------+
    | 1 (Mono)      | 0: MA_CHANNEL_MONO              |
    +---------------+---------------------------------+
    | 2 (Stereo)    | 0: MA_CHANNEL_FRONT_LEFT   <br> |
    |               | 1: MA_CHANNEL_FRONT_RIGHT       |
    +---------------+---------------------------------+
    | 3             | 0: MA_CHANNEL_FRONT_LEFT   <br> |
    |               | 1: MA_CHANNEL_FRONT_RIGHT  <br> |
    |               | 2: MA_CHANNEL_FRONT_CENTER      |
    +---------------+---------------------------------+
    | 4 (Surround)  | 0: MA_CHANNEL_FRONT_LEFT   <br> |
    |               | 1: MA_CHANNEL_FRONT_RIGHT  <br> |
    |               | 2: MA_CHANNEL_FRONT_CENTER <br> |
    |               | 3: MA_CHANNEL_BACK_CENTER       |
    +---------------+---------------------------------+
    | 5             | 0: MA_CHANNEL_FRONT_LEFT   <br> |
    |               | 1: MA_CHANNEL_FRONT_RIGHT  <br> |
    |               | 2: MA_CHANNEL_FRONT_CENTER <br> |
    |               | 3: MA_CHANNEL_BACK_LEFT    <br> |
    |               | 4: MA_CHANNEL_BACK_RIGHT        |
    +---------------+---------------------------------+
    | 6 (5.1)       | 0: MA_CHANNEL_FRONT_LEFT   <br> |
    |               | 1: MA_CHANNEL_FRONT_RIGHT  <br> |
    |               | 2: MA_CHANNEL_FRONT_CENTER <br> |
    |               | 3: MA_CHANNEL_LFE          <br> |
    |               | 4: MA_CHANNEL_SIDE_LEFT    <br> |
    |               | 5: MA_CHANNEL_SIDE_RIGHT        |
    +---------------+---------------------------------+
    | 7             | 0: MA_CHANNEL_FRONT_LEFT   <br> |
    |               | 1: MA_CHANNEL_FRONT_RIGHT  <br> |
    |               | 2: MA_CHANNEL_FRONT_CENTER <br> |
    |               | 3: MA_CHANNEL_LFE          <br> |
    |               | 4: MA_CHANNEL_BACK_CENTER  <br> |
    |               | 4: MA_CHANNEL_SIDE_LEFT    <br> |
    |               | 5: MA_CHANNEL_SIDE_RIGHT        |
    +---------------+---------------------------------+
    | 8 (7.1)       | 0: MA_CHANNEL_FRONT_LEFT   <br> |
    |               | 1: MA_CHANNEL_FRONT_RIGHT  <br> |
    |               | 2: MA_CHANNEL_FRONT_CENTER <br> |
    |               | 3: MA_CHANNEL_LFE          <br> |
    |               | 4: MA_CHANNEL_BACK_LEFT    <br> |
    |               | 5: MA_CHANNEL_BACK_RIGHT   <br> |
    |               | 6: MA_CHANNEL_SIDE_LEFT    <br> |
    |               | 7: MA_CHANNEL_SIDE_RIGHT        |
    +---------------+---------------------------------+
    | Other         | All channels set to 0. This     |
    |               | is equivalent to the same       |
    |               | mapping as the device.          |
    +---------------+---------------------------------+



6.3. Resampling
---------------
Resampling is achieved with the `ma_resampler` object. To create a resampler object, do something like the following:

    ```c
    ma_resampler_config config = ma_resampler_config_init(
        ma_format_s16,
        channels,
        sampleRateIn,
        sampleRateOut,
        ma_resample_algorithm_linear);

    ma_resampler resampler;
    ma_result result = ma_resampler_init(&config, &resampler);
    if (result != MA_SUCCESS) {
        // An error occurred...
    }
    ```

Do the following to uninitialize the resampler:

    ```c
    ma_resampler_uninit(&resampler);
    ```

The following example shows how data can be processed

    ```c
    ma_uint64 frameCountIn  = 1000;
    ma_uint64 frameCountOut = 2000;
    ma_result result = ma_resampler_process_pcm_frames(&resampler, pFramesIn, &frameCountIn, pFramesOut, &frameCountOut);
    if (result != MA_SUCCESS) {
        // An error occurred...
    }

    // At this point, frameCountIn contains the number of input frames that were consumed and frameCountOut contains the
    // number of output frames written.
    ```

To initialize the resampler you first need to set up a config (`ma_resampler_config`) with `ma_resampler_config_init()`. You need to specify the sample format
you want to use, the number of channels, the input and output sample rate, and the algorithm.

The sample format can be either `ma_format_s16` or `ma_format_f32`. If you need a different format you will need to perform pre- and post-conversions yourself
where necessary. Note that the format is the same for both input and output. The format cannot be changed after initialization.

The resampler supports multiple channels and is always interleaved (both input and output). The channel count cannot be changed after initialization.

The sample rates can be anything other than zero, and are always specified in hertz. They should be set to something like 44100, etc. The sample rate is the
only configuration property that can be changed after initialization.

The miniaudio resampler supports multiple algorithms:

    +-----------+------------------------------+
    | Algorithm | Enum Token                   |
    +-----------+------------------------------+
    | Linear    | ma_resample_algorithm_linear |
    | Speex     | ma_resample_algorithm_speex  |
    +-----------+------------------------------+

Because Speex is not public domain it is strictly opt-in and the code is stored in separate files. if you opt-in to the Speex backend you will need to consider
it's license, the text of which can be found in it's source files in "extras/speex_resampler". Details on how to opt-in to the Speex resampler is explained in
the Speex Resampler section below.

The algorithm cannot be changed after initialization.

Processing always happens on a per PCM frame basis and always assumes interleaved input and output. De-interleaved processing is not supported. To process
frames, use `ma_resampler_process_pcm_frames()`. On input, this function takes the number of output frames you can fit in the output buffer and the number of
input frames contained in the input buffer. On output these variables contain the number of output frames that were written to the output buffer and the
number of input frames that were consumed in the process. You can pass in NULL for the input buffer in which case it will be treated as an infinitely large
buffer of zeros. The output buffer can also be NULL, in which case the processing will be treated as seek.

The sample rate can be changed dynamically on the fly. You can change this with explicit sample rates with `ma_resampler_set_rate()` and also with a decimal
ratio with `ma_resampler_set_rate_ratio()`. The ratio is in/out.

Sometimes it's useful to know exactly how many input frames will be required to output a specific number of frames. You can calculate this with
`ma_resampler_get_required_input_frame_count()`. Likewise, it's sometimes useful to know exactly how many frames would be output given a certain number of
input frames. You can do this with `ma_resampler_get_expected_output_frame_count()`.

Due to the nature of how resampling works, the resampler introduces some latency. This can be retrieved in terms of both the input rate and the output rate
with `ma_resampler_get_input_latency()` and `ma_resampler_get_output_latency()`.


6.3.1. Resampling Algorithms
----------------------------
The choice of resampling algorithm depends on your situation and requirements. The linear resampler is the most efficient and has the least amount of latency,
but at the expense of poorer quality. The Speex resampler is higher quality, but slower with more latency. It also performs several heap allocations internally
for memory management.


6.3.1.1. Linear Resampling
--------------------------
The linear resampler is the fastest, but comes at the expense of poorer quality. There is, however, some control over the quality of the linear resampler which
may make it a suitable option depending on your requirements.

The linear resampler performs low-pass filtering before or after downsampling or upsampling, depending on the sample rates you're converting between. When
decreasing the sample rate, the low-pass filter will be applied before downsampling. When increasing the rate it will be performed after upsampling. By default
a fourth order low-pass filter will be applied. This can be configured via the `lpfOrder` configuration variable. Setting this to 0 will disable filtering.

The low-pass filter has a cutoff frequency which defaults to half the sample rate of the lowest of the input and output sample rates (Nyquist Frequency). This
can be controlled with the `lpfNyquistFactor` config variable. This defaults to 1, and should be in the range of 0..1, although a value of 0 does not make
sense and should be avoided. A value of 1 will use the Nyquist Frequency as the cutoff. A value of 0.5 will use half the Nyquist Frequency as the cutoff, etc.
Values less than 1 will result in more washed out sound due to more of the higher frequencies being removed. This config variable has no impact on performance
and is a purely perceptual configuration.

The API for the linear resampler is the same as the main resampler API, only it's called `ma_linear_resampler`.


6.3.1.2. Speex Resampling
-------------------------
The Speex resampler is made up of third party code which is released under the BSD license. Because it is licensed differently to miniaudio, which is public
domain, it is strictly opt-in and all of it's code is stored in separate files. If you opt-in to the Speex resampler you must consider the license text in it's
source files. To opt-in, you must first `#include` the following file before the implementation of miniaudio.h:

    ```c
    #include "extras/speex_resampler/ma_speex_resampler.h"
    ```

Both the header and implementation is contained within the same file. The implementation can be included in your program like so:

    ```c
    #define MINIAUDIO_SPEEX_RESAMPLER_IMPLEMENTATION
    #include "extras/speex_resampler/ma_speex_resampler.h"
    ```

Note that even if you opt-in to the Speex backend, miniaudio won't use it unless you explicitly ask for it in the respective config of the object you are
initializing. If you try to use the Speex resampler without opting in, initialization of the `ma_resampler` object will fail with `MA_NO_BACKEND`.

The only configuration option to consider with the Speex resampler is the `speex.quality` config variable. This is a value between 0 and 10, with 0 being
the fastest with the poorest quality and 10 being the slowest with the highest quality. The default value is 3.



6.4. General Data Conversion
----------------------------
The `ma_data_converter` API can be used to wrap sample format conversion, channel conversion and resampling into one operation. This is what miniaudio uses
internally to convert between the format requested when the device was initialized and the format of the backend's native device. The API for general data
conversion is very similar to the resampling API. Create a `ma_data_converter` object like this:

    ```c
    ma_data_converter_config config = ma_data_converter_config_init(
        inputFormat,
        outputFormat,
        inputChannels,
        outputChannels,
        inputSampleRate,
        outputSampleRate
    );

    ma_data_converter converter;
    ma_result result = ma_data_converter_init(&config, &converter);
    if (result != MA_SUCCESS) {
        // An error occurred...
    }
    ```

In the example above we use `ma_data_converter_config_init()` to initialize the config, however there's many more properties that can be configured, such as
channel maps and resampling quality. Something like the following may be more suitable depending on your requirements:

    ```c
    ma_data_converter_config config = ma_data_converter_config_init_default();
    config.formatIn = inputFormat;
    config.formatOut = outputFormat;
    config.channelsIn = inputChannels;
    config.channelsOut = outputChannels;
    config.sampleRateIn = inputSampleRate;
    config.sampleRateOut = outputSampleRate;
    ma_get_standard_channel_map(ma_standard_channel_map_flac, config.channelCountIn, config.channelMapIn);
    config.resampling.linear.lpfOrder = MA_MAX_FILTER_ORDER;
    ```

Do the following to uninitialize the data converter:

    ```c
    ma_data_converter_uninit(&converter);
    ```

The following example shows how data can be processed

    ```c
    ma_uint64 frameCountIn  = 1000;
    ma_uint64 frameCountOut = 2000;
    ma_result result = ma_data_converter_process_pcm_frames(&converter, pFramesIn, &frameCountIn, pFramesOut, &frameCountOut);
    if (result != MA_SUCCESS) {
        // An error occurred...
    }

    // At this point, frameCountIn contains the number of input frames that were consumed and frameCountOut contains the number
    // of output frames written.
    ```

The data converter supports multiple channels and is always interleaved (both input and output). The channel count cannot be changed after initialization.

Sample rates can be anything other than zero, and are always specified in hertz. They should be set to something like 44100, etc. The sample rate is the only
configuration property that can be changed after initialization, but only if the `resampling.allowDynamicSampleRate` member of `ma_data_converter_config` is
set to `MA_TRUE`. To change the sample rate, use `ma_data_converter_set_rate()` or `ma_data_converter_set_rate_ratio()`. The ratio must be in/out. The
resampling algorithm cannot be changed after initialization.

Processing always happens on a per PCM frame basis and always assumes interleaved input and output. De-interleaved processing is not supported. To process
frames, use `ma_data_converter_process_pcm_frames()`. On input, this function takes the number of output frames you can fit in the output buffer and the number
of input frames contained in the input buffer. On output these variables contain the number of output frames that were written to the output buffer and the
number of input frames that were consumed in the process. You can pass in NULL for the input buffer in which case it will be treated as an infinitely large
buffer of zeros. The output buffer can also be NULL, in which case the processing will be treated as seek.

Sometimes it's useful to know exactly how many input frames will be required to output a specific number of frames. You can calculate this with
`ma_data_converter_get_required_input_frame_count()`. Likewise, it's sometimes useful to know exactly how many frames would be output given a certain number of
input frames. You can do this with `ma_data_converter_get_expected_output_frame_count()`.

Due to the nature of how resampling works, the data converter introduces some latency if resampling is required. This can be retrieved in terms of both the
input rate and the output rate with `ma_data_converter_get_input_latency()` and `ma_data_converter_get_output_latency()`.



7. Filtering
============

7.1. Biquad Filtering
---------------------
Biquad filtering is achieved with the `ma_biquad` API. Example:

    ```c
    ma_biquad_config config = ma_biquad_config_init(ma_format_f32, channels, b0, b1, b2, a0, a1, a2);
    ma_result result = ma_biquad_init(&config, &biquad);
    if (result != MA_SUCCESS) {
        // Error.
    }

    ...

    ma_biquad_process_pcm_frames(&biquad, pFramesOut, pFramesIn, frameCount);
    ```

Biquad filtering is implemented using transposed direct form 2. The numerator coefficients are b0, b1 and b2, and the denominator coefficients are a0, a1 and
a2. The a0 coefficient is required and coefficients must not be pre-normalized.

Supported formats are `ma_format_s16` and `ma_format_f32`. If you need to use a different format you need to convert it yourself beforehand. When using
`ma_format_s16` the biquad filter will use fixed point arithmetic. When using `ma_format_f32`, floating point arithmetic will be used.

Input and output frames are always interleaved.

Filtering can be applied in-place by passing in the same pointer for both the input and output buffers, like so:

    ```c
    ma_biquad_process_pcm_frames(&biquad, pMyData, pMyData, frameCount);
    ```

If you need to change the values of the coefficients, but maintain the values in the registers you can do so with `ma_biquad_reinit()`. This is useful if you
need to change the properties of the filter while keeping the values of registers valid to avoid glitching. Do not use `ma_biquad_init()` for this as it will
do a full initialization which involves clearing the registers to 0. Note that changing the format or channel count after initialization is invalid and will
result in an error.


7.2. Low-Pass Filtering
-----------------------
Low-pass filtering is achieved with the following APIs:

    +---------+------------------------------------------+
    | API     | Description                              |
    +---------+------------------------------------------+
    | ma_lpf1 | First order low-pass filter              |
    | ma_lpf2 | Second order low-pass filter             |
    | ma_lpf  | High order low-pass filter (Butterworth) |
    +---------+------------------------------------------+

Low-pass filter example:

    ```c
    ma_lpf_config config = ma_lpf_config_init(ma_format_f32, channels, sampleRate, cutoffFrequency, order);
    ma_result result = ma_lpf_init(&config, &lpf);
    if (result != MA_SUCCESS) {
        // Error.
    }

    ...

    ma_lpf_process_pcm_frames(&lpf, pFramesOut, pFramesIn, frameCount);
    ```

Supported formats are `ma_format_s16` and` ma_format_f32`. If you need to use a different format you need to convert it yourself beforehand. Input and output
frames are always interleaved.

Filtering can be applied in-place by passing in the same pointer for both the input and output buffers, like so:

    ```c
    ma_lpf_process_pcm_frames(&lpf, pMyData, pMyData, frameCount);
    ```

The maximum filter order is limited to `MA_MAX_FILTER_ORDER` which is set to 8. If you need more, you can chain first and second order filters together.

    ```c
    for (iFilter = 0; iFilter < filterCount; iFilter += 1) {
        ma_lpf2_process_pcm_frames(&lpf2[iFilter], pMyData, pMyData, frameCount);
    }
    ```

If you need to change the configuration of the filter, but need to maintain the state of internal registers you can do so with `ma_lpf_reinit()`. This may be
useful if you need to change the sample rate and/or cutoff frequency dynamically while maintaing smooth transitions. Note that changing the format or channel
count after initialization is invalid and will result in an error.

The `ma_lpf` object supports a configurable order, but if you only need a first order filter you may want to consider using `ma_lpf1`. Likewise, if you only
need a second order filter you can use `ma_lpf2`. The advantage of this is that they're lighter weight and a bit more efficient.

If an even filter order is specified, a series of second order filters will be processed in a chain. If an odd filter order is specified, a first order filter
will be applied, followed by a series of second order filters in a chain.


7.3. High-Pass Filtering
------------------------
High-pass filtering is achieved with the following APIs:

    +---------+-------------------------------------------+
    | API     | Description                               |
    +---------+-------------------------------------------+
    | ma_hpf1 | First order high-pass filter              |
    | ma_hpf2 | Second order high-pass filter             |
    | ma_hpf  | High order high-pass filter (Butterworth) |
    +---------+-------------------------------------------+

High-pass filters work exactly the same as low-pass filters, only the APIs are called `ma_hpf1`, `ma_hpf2` and `ma_hpf`. See example code for low-pass filters
for example usage.


7.4. Band-Pass Filtering
------------------------
Band-pass filtering is achieved with the following APIs:

    +---------+-------------------------------+
    | API     | Description                   |
    +---------+-------------------------------+
    | ma_bpf2 | Second order band-pass filter |
    | ma_bpf  | High order band-pass filter   |
    +---------+-------------------------------+

Band-pass filters work exactly the same as low-pass filters, only the APIs are called `ma_bpf2` and `ma_hpf`. See example code for low-pass filters for example
usage. Note that the order for band-pass filters must be an even number which means there is no first order band-pass filter, unlike low-pass and high-pass
filters.


7.5. Notch Filtering
--------------------
Notch filtering is achieved with the following APIs:

    +-----------+------------------------------------------+
    | API       | Description                              |
    +-----------+------------------------------------------+
    | ma_notch2 | Second order notching filter             |
    +-----------+------------------------------------------+


7.6. Peaking EQ Filtering
-------------------------
Peaking filtering is achieved with the following APIs:

    +----------+------------------------------------------+
    | API      | Description                              |
    +----------+------------------------------------------+
    | ma_peak2 | Second order peaking filter              |
    +----------+------------------------------------------+


7.7. Low Shelf Filtering
------------------------
Low shelf filtering is achieved with the following APIs:

    +-------------+------------------------------------------+
    | API         | Description                              |
    +-------------+------------------------------------------+
    | ma_loshelf2 | Second order low shelf filter            |
    +-------------+------------------------------------------+

Where a high-pass filter is used to eliminate lower frequencies, a low shelf filter can be used to just turn them down rather than eliminate them entirely.


7.8. High Shelf Filtering
-------------------------
High shelf filtering is achieved with the following APIs:

    +-------------+------------------------------------------+
    | API         | Description                              |
    +-------------+------------------------------------------+
    | ma_hishelf2 | Second order high shelf filter           |
    +-------------+------------------------------------------+

The high shelf filter has the same API as the low shelf filter, only you would use `ma_hishelf` instead of `ma_loshelf`. Where a low shelf filter is used to
adjust the volume of low frequencies, the high shelf filter does the same thing for high frequencies.




8. Waveform and Noise Generation
================================

8.1. Waveforms
--------------
miniaudio supports generation of sine, square, triangle and sawtooth waveforms. This is achieved with the `ma_waveform` API. Example:

    ```c
    ma_waveform_config config = ma_waveform_config_init(
        FORMAT,
        CHANNELS,
        SAMPLE_RATE,
        ma_waveform_type_sine,
        amplitude,
        frequency);

    ma_waveform waveform;
    ma_result result = ma_waveform_init(&config, &waveform);
    if (result != MA_SUCCESS) {
        // Error.
    }

    ...

    ma_waveform_read_pcm_frames(&waveform, pOutput, frameCount);
    ```

The amplitude, frequency, type, and sample rate can be changed dynamically with `ma_waveform_set_amplitude()`, `ma_waveform_set_frequency()`,
`ma_waveform_set_type()`, and `ma_waveform_set_sample_rate()` respectively.

You can invert the waveform by setting the amplitude to a negative value. You can use this to control whether or not a sawtooth has a positive or negative
ramp, for example.

Below are the supported waveform types:

    +---------------------------+
    | Enum Name                 |
    +---------------------------+
    | ma_waveform_type_sine     |
    | ma_waveform_type_square   |
    | ma_waveform_type_triangle |
    | ma_waveform_type_sawtooth |
    +---------------------------+



8.2. Noise
----------
miniaudio supports generation of white, pink and Brownian noise via the `ma_noise` API. Example:

    ```c
    ma_noise_config config = ma_noise_config_init(
        FORMAT,
        CHANNELS,
        ma_noise_type_white,
        SEED,
        amplitude);

    ma_noise noise;
    ma_result result = ma_noise_init(&config, &noise);
    if (result != MA_SUCCESS) {
        // Error.
    }

    ...

    ma_noise_read_pcm_frames(&noise, pOutput, frameCount);
    ```

The noise API uses simple LCG random number generation. It supports a custom seed which is useful for things like automated testing requiring reproducibility.
Setting the seed to zero will default to `MA_DEFAULT_LCG_SEED`.

The amplitude, seed, and type can be changed dynamically with `ma_noise_set_amplitude()`, `ma_noise_set_seed()`, and `ma_noise_set_type()` respectively.

By default, the noise API will use different values for different channels. So, for example, the left side in a stereo stream will be different to the right
side. To instead have each channel use the same random value, set the `duplicateChannels` member of the noise config to true, like so:

    ```c
    config.duplicateChannels = MA_TRUE;
    ```

Below are the supported noise types.

    +------------------------+
    | Enum Name              |
    +------------------------+
    | ma_noise_type_white    |
    | ma_noise_type_pink     |
    | ma_noise_type_brownian |
    +------------------------+



9. Audio Buffers
================
miniaudio supports reading from a buffer of raw audio data via the `ma_audio_buffer` API. This can read from memory that's managed by the application, but
can also handle the memory management for you internally. Memory management is flexible and should support most use cases.

Audio buffers are initialised using the standard configuration system used everywhere in miniaudio:

    ```c
    ma_audio_buffer_config config = ma_audio_buffer_config_init(
        format,
        channels,
        sizeInFrames,
        pExistingData,
        &allocationCallbacks);

    ma_audio_buffer buffer;
    result = ma_audio_buffer_init(&config, &buffer);
    if (result != MA_SUCCESS) {
        // Error.
    }

    ...

    ma_audio_buffer_uninit(&buffer);
    ```

In the example above, the memory pointed to by `pExistingData` will *not* be copied and is how an application can do self-managed memory allocation. If you
would rather make a copy of the data, use `ma_audio_buffer_init_copy()`. To uninitialize the buffer, use `ma_audio_buffer_uninit()`.

Sometimes it can be convenient to allocate the memory for the `ma_audio_buffer` structure and the raw audio data in a contiguous block of memory. That is,
the raw audio data will be located immediately after the `ma_audio_buffer` structure. To do this, use `ma_audio_buffer_alloc_and_init()`:

    ```c
    ma_audio_buffer_config config = ma_audio_buffer_config_init(
        format,
        channels,
        sizeInFrames,
        pExistingData,
        &allocationCallbacks);

    ma_audio_buffer* pBuffer
    result = ma_audio_buffer_alloc_and_init(&config, &pBuffer);
    if (result != MA_SUCCESS) {
        // Error
    }

    ...

    ma_audio_buffer_uninit_and_free(&buffer);
    ```

If you initialize the buffer with `ma_audio_buffer_alloc_and_init()` you should uninitialize it with `ma_audio_buffer_uninit_and_free()`. In the example above,
the memory pointed to by `pExistingData` will be copied into the buffer, which is contrary to the behavior of `ma_audio_buffer_init()`.

An audio buffer has a playback cursor just like a decoder. As you read frames from the buffer, the cursor moves forward. The last parameter (`loop`) can be
used to determine if the buffer should loop. The return value is the number of frames actually read. If this is less than the number of frames requested it
means the end has been reached. This should never happen if the `loop` parameter is set to true. If you want to manually loop back to the start, you can do so
with with `ma_audio_buffer_seek_to_pcm_frame(pAudioBuffer, 0)`. Below is an example for reading data from an audio buffer.

    ```c
    ma_uint64 framesRead = ma_audio_buffer_read_pcm_frames(pAudioBuffer, pFramesOut, desiredFrameCount, isLooping);
    if (framesRead < desiredFrameCount) {
        // If not looping, this means the end has been reached. This should never happen in looping mode with valid input.
    }
    ```

Sometimes you may want to avoid the cost of data movement between the internal buffer and the output buffer. Instead you can use memory mapping to retrieve a
pointer to a segment of data:

    ```c
    void* pMappedFrames;
    ma_uint64 frameCount = frameCountToTryMapping;
    ma_result result = ma_audio_buffer_map(pAudioBuffer, &pMappedFrames, &frameCount);
    if (result == MA_SUCCESS) {
        // Map was successful. The value in frameCount will be how many frames were _actually_ mapped, which may be
        // less due to the end of the buffer being reached.
        ma_copy_pcm_frames(pFramesOut, pMappedFrames, frameCount, pAudioBuffer->format, pAudioBuffer->channels);

        // You must unmap the buffer.
        ma_audio_buffer_unmap(pAudioBuffer, frameCount);
    }
    ```

When you use memory mapping, the read cursor is increment by the frame count passed in to `ma_audio_buffer_unmap()`. If you decide not to process every frame
you can pass in a value smaller than the value returned by `ma_audio_buffer_map()`. The disadvantage to using memory mapping is that it does not handle looping
for you. You can determine if the buffer is at the end for the purpose of looping with `ma_audio_buffer_at_end()` or by inspecting the return value of
`ma_audio_buffer_unmap()` and checking if it equals `MA_AT_END`. You should not treat `MA_AT_END` as an error when returned by `ma_audio_buffer_unmap()`.



10. Ring Buffers
================
miniaudio supports lock free (single producer, single consumer) ring buffers which are exposed via the `ma_rb` and `ma_pcm_rb` APIs. The `ma_rb` API operates
on bytes, whereas the `ma_pcm_rb` operates on PCM frames. They are otherwise identical as `ma_pcm_rb` is just a wrapper around `ma_rb`.

Unlike most other APIs in miniaudio, ring buffers support both interleaved and deinterleaved streams. The caller can also allocate their own backing memory for
the ring buffer to use internally for added flexibility. Otherwise the ring buffer will manage it's internal memory for you.

The examples below use the PCM frame variant of the ring buffer since that's most likely the one you will want to use. To initialize a ring buffer, do
something like the following:

    ```c
    ma_pcm_rb rb;
    ma_result result = ma_pcm_rb_init(FORMAT, CHANNELS, BUFFER_SIZE_IN_FRAMES, NULL, NULL, &rb);
    if (result != MA_SUCCESS) {
        // Error
    }
    ```

The `ma_pcm_rb_init()` function takes the sample format and channel count as parameters because it's the PCM varient of the ring buffer API. For the regular
ring buffer that operates on bytes you would call `ma_rb_init()` which leaves these out and just takes the size of the buffer in bytes instead of frames. The
fourth parameter is an optional pre-allocated buffer and the fifth parameter is a pointer to a `ma_allocation_callbacks` structure for custom memory allocation
routines. Passing in `NULL` for this results in `MA_MALLOC()` and `MA_FREE()` being used.

Use `ma_pcm_rb_init_ex()` if you need a deinterleaved buffer. The data for each sub-buffer is offset from each other based on the stride. To manage your
sub-buffers you can use `ma_pcm_rb_get_subbuffer_stride()`, `ma_pcm_rb_get_subbuffer_offset()` and `ma_pcm_rb_get_subbuffer_ptr()`.

Use `ma_pcm_rb_acquire_read()` and `ma_pcm_rb_acquire_write()` to retrieve a pointer to a section of the ring buffer. You specify the number of frames you
need, and on output it will set to what was actually acquired. If the read or write pointer is positioned such that the number of frames requested will require
a loop, it will be clamped to the end of the buffer. Therefore, the number of frames you're given may be less than the number you requested.

After calling `ma_pcm_rb_acquire_read()` or `ma_pcm_rb_acquire_write()`, you do your work on the buffer and then "commit" it with `ma_pcm_rb_commit_read()` or
`ma_pcm_rb_commit_write()`. This is where the read/write pointers are updated. When you commit you need to pass in the buffer that was returned by the earlier
call to `ma_pcm_rb_acquire_read()` or `ma_pcm_rb_acquire_write()` and is only used for validation. The number of frames passed to `ma_pcm_rb_commit_read()` and
`ma_pcm_rb_commit_write()` is what's used to increment the pointers, and can be less that what was originally requested.

If you want to correct for drift between the write pointer and the read pointer you can use a combination of `ma_pcm_rb_pointer_distance()`,
`ma_pcm_rb_seek_read()` and `ma_pcm_rb_seek_write()`. Note that you can only move the pointers forward, and you should only move the read pointer forward via
the consumer thread, and the write pointer forward by the producer thread. If there is too much space between the pointers, move the read pointer forward. If
there is too little space between the pointers, move the write pointer forward.

You can use a ring buffer at the byte level instead of the PCM frame level by using the `ma_rb` API. This is exactly the same, only you will use the `ma_rb`
functions instead of `ma_pcm_rb` and instead of frame counts you will pass around byte counts.

The maximum size of the buffer in bytes is `0x7FFFFFFF-(MA_SIMD_ALIGNMENT-1)` due to the most significant bit being used to encode a loop flag and the internally
managed buffers always being aligned to MA_SIMD_ALIGNMENT.

Note that the ring buffer is only thread safe when used by a single consumer thread and single producer thread.



11. Backends
============
The following backends are supported by miniaudio.

    +-------------+-----------------------+--------------------------------------------------------+
    | Name        | Enum Name             | Supported Operating Systems                            |
    +-------------+-----------------------+--------------------------------------------------------+
    | WASAPI      | ma_backend_wasapi     | Windows Vista+                                         |
    | DirectSound | ma_backend_dsound     | Windows XP+                                            |
    | WinMM       | ma_backend_winmm      | Windows XP+ (may work on older versions, but untested) |
    | Core Audio  | ma_backend_coreaudio  | macOS, iOS                                             |
    | ALSA        | ma_backend_alsa       | Linux                                                  |
    | PulseAudio  | ma_backend_pulseaudio | Cross Platform (disabled on Windows, BSD and Android)  |
    | JACK        | ma_backend_jack       | Cross Platform (disabled on BSD and Android)           |
    | sndio       | ma_backend_sndio      | OpenBSD                                                |
    | audio(4)    | ma_backend_audio4     | NetBSD, OpenBSD                                        |
    | OSS         | ma_backend_oss        | FreeBSD                                                |
    | AAudio      | ma_backend_aaudio     | Android 8+                                             |
    | OpenSL ES   | ma_backend_opensl     | Android (API level 16+)                                |
    | Web Audio   | ma_backend_webaudio   | Web (via Emscripten)                                   |
    | Custom      | ma_backend_custom     | Cross Platform                                         |
    | Null        | ma_backend_null       | Cross Platform (not used on Web)                       |
    +-------------+-----------------------+--------------------------------------------------------+

Some backends have some nuance details you may want to be aware of.

11.1. WASAPI
------------
- Low-latency shared mode will be disabled when using an application-defined sample rate which is different to the device's native sample rate. To work around
  this, set `wasapi.noAutoConvertSRC` to true in the device config. This is due to IAudioClient3_InitializeSharedAudioStream() failing when the
  `AUDCLNT_STREAMFLAGS_AUTOCONVERTPCM` flag is specified. Setting wasapi.noAutoConvertSRC will result in miniaudio's internal resampler being used instead
  which will in turn enable the use of low-latency shared mode.

11.2. PulseAudio
----------------
- If you experience bad glitching/noise on Arch Linux, consider this fix from the Arch wiki:
  https://wiki.archlinux.org/index.php/PulseAudio/Troubleshooting#Glitches,_skips_or_crackling. Alternatively, consider using a different backend such as ALSA.

11.3. Android
-------------
- To capture audio on Android, remember to add the RECORD_AUDIO permission to your manifest: `<uses-permission android:name="android.permission.RECORD_AUDIO" />`
- With OpenSL|ES, only a single ma_context can be active at any given time. This is due to a limitation with OpenSL|ES.
- With AAudio, only default devices are enumerated. This is due to AAudio not having an enumeration API (devices are enumerated through Java). You can however
  perform your own device enumeration through Java and then set the ID in the ma_device_id structure (ma_device_id.aaudio) and pass it to ma_device_init().
- The backend API will perform resampling where possible. The reason for this as opposed to using miniaudio's built-in resampler is to take advantage of any
  potential device-specific optimizations the driver may implement.

11.4. UWP
---------
- UWP only supports default playback and capture devices.
- UWP requires the Microphone capability to be enabled in the application's manifest (Package.appxmanifest):

    ```
    <Package ...>
        ...
        <Capabilities>
            <DeviceCapability Name="microphone" />
        </Capabilities>
    </Package>
    ```

11.5. Web Audio / Emscripten
----------------------------
- You cannot use `-std=c*` compiler flags, nor `-ansi`. This only applies to the Emscripten build.
- The first time a context is initialized it will create a global object called "miniaudio" whose primary purpose is to act as a factory for device objects.
- Currently the Web Audio backend uses ScriptProcessorNode's, but this may need to change later as they've been deprecated.
- Google has implemented a policy in their browsers that prevent automatic media output without first receiving some kind of user input. The following web page
  has additional details: https://developers.google.com/web/updates/2017/09/autoplay-policy-changes. Starting the device may fail if you try to start playback
  without first handling some kind of user input.



12. Miscellaneous Notes
=======================
- Automatic stream routing is enabled on a per-backend basis. Support is explicitly enabled for WASAPI and Core Audio, however other backends such as
  PulseAudio may naturally support it, though not all have been tested.
- The contents of the output buffer passed into the data callback will always be pre-initialized to silence unless the `noPreZeroedOutputBuffer` config variable
  in `ma_device_config` is set to true, in which case it'll be undefined which will require you to write something to the entire buffer.
- By default miniaudio will automatically clip samples. This only applies when the playback sample format is configured as `ma_format_f32`. If you are doing
  clipping yourself, you can disable this overhead by setting `noClip` to true in the device config.
- The sndio backend is currently only enabled on OpenBSD builds.
- The audio(4) backend is supported on OpenBSD, but you may need to disable sndiod before you can use it.
- Note that GCC and Clang requires `-msse2`, `-mavx2`, etc. for SIMD optimizations.
- When compiling with VC6 and earlier, decoding is restricted to files less than 2GB in size. This is due to 64-bit file APIs not being available.
*/

