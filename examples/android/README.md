# Android

A NativeActivity app in Odin. It starts at `main` through `core:sys/android/native_app_glue`, fills its window with a colour that follows a touch, and reads `app/assets/hello.txt` through `core:os`.

## Requirements

- The Android NDK, as `ODIN_ANDROID_NDK`. Odin's bindings come from NDK r30.
- The Android SDK with build-tools and a platform, as `ODIN_ANDROID_SDK`. On Windows it defaults to `%LocalAppData%\Android\Sdk`.
- A JDK, through `JAVA_HOME` or `PATH`.
- A signing key. By default this is the debug keystore that Android Studio makes, `~/.android/debug.keystore`. Otherwise pass `-android-keystore`, `-android-keystore-alias`, and `-android-keystore-password`.
- For an `.aab`, bundletool's `.jar`, as `ODIN_ANDROID_BUNDLETOOL`.

## Layout

| Path                      | What                                                                       |
|---------------------------|----------------------------------------------------------------------------|
| `main.odin`               | The app.                                                                   |
| `app/AndroidManifest.xml` | Names the activity, `org.odin_lang.OdinActivity`, and the library to load. |
| `app/res/`                | Resources: here only the app's name.                                       |
| `app/assets/`             | Files the app reads under `/android_asset` with `core:os`.                 |
| `app/lib/<abi>/`          | `libexample.so` for each ABI, built below.                                 |

## Building

Build the library once per ABI, then bundle the `app` directory. A phone needs only `arm64-v8a`, and the emulator `x86_64`:

```sh
mkdir -p examples/android/app/lib/arm64-v8a
odin build examples/android -target:linux_arm64 -subtarget:android -minimum-os-version:29 -build-mode:shared -out:examples/android/app/lib/arm64-v8a/libexample.so
odin bundle android examples/android/app -minimum-os-version:29 -out:examples/android/example.apk
```

For all four ABIs:

```sh
for pair in arm64-v8a:linux_arm64 armeabi-v7a:linux_arm32 x86:linux_i386 x86_64:linux_amd64; do
	abi=${pair%%:*}
	target=${pair#*:}
	mkdir -p examples/android/app/lib/$abi
	odin build examples/android -target:$target -subtarget:android -minimum-os-version:29 -build-mode:shared -out:examples/android/app/lib/$abi/libexample.so
done
odin bundle android examples/android/app -minimum-os-version:29 -out:examples/android/example.apk
```

- Give every build and the bundle the same `-minimum-os-version`. It defaults to 34, and 29 is the lowest Odin supports.
- `odin build` does not create the output directory, hence the `mkdir`.
- `-out:examples/android/example.aab` makes an Android App Bundle for Google Play instead.

## Running

```sh
adb install examples/android/example.apk
adb shell am start -n org.odin_lang.example/org.odin_lang.OdinActivity
adb logcat -s OdinExample org.odin_lang.example
```

`core:log`'s console logger writes to logcat with its `ident` as the tag. stdout and stderr go to logcat too, tagged with the package name. Back ends `main`, and the process with it.
