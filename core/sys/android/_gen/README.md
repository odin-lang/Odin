# Android NDK generator

Most of `core:sys/android` and the `vendor:android/*` packages are generated from the Android NDK's C headers by `generate.py`:

```
python core/sys/android/_gen/generate.py --ndk <path/to/ndk> --verify
```

`--ndk` defaults to the `ODIN_ANDROID_NDK` environment variable. Only Python 3 and the NDK are needed.
The NDK's own clang reads the headers (`-Xclang -ast-dump=json`), so there is no libclang or pip dependency.

Last generated from NDK r30 (30.0.16248370).

## What it does

- Every header in a target's list becomes one Odin file. Small related headers share one.
  - A header with nothing to bind (only function-like macros) produces no file.
- Names stay exactly as in C (`ALooper_pollOnce`, `ANativeWindow`, `JNIEnv`), apart from the members of enums below.
  - A record that shares its name with a procedure gets `_t`, as in `core:sys/posix` (`sync_file_info_t`).
- clang evaluates every enum constant and object-like macro. The source spelling is kept when it is a plain literal.
- The NDK's stub libraries decide each function's `foreign import` and the API level it appeared in.
  - Functions newer than Odin's minimum API level (29) get an `// API level N` comment.
- Types from `core` or a target in `uses` refer to that package (`android.ANativeWindow`, `android_media.media_status_t`).
- Records only forward-declared in a bound header (`struct timespec`) map to `core:sys/posix` through `EXTERNAL_RECORDS`.
- Parameter names of function-pointer types come from the header source, when every parameter has one.
- A pointer to a table of function pointers becomes a struct with a `using` field, so `->` calls through it.
  - `JNIEnv :: struct { using functions: ^JNINativeInterface }`, so `env->FindClass(name)` works on a `^JNIEnv`. `JavaVM` is the same.
  - OpenSL ES and OpenMAX AL interfaces, e.g. `SLObjectItf :: ^struct { using itf: ^SLObjectItf_ }`, so `object->Realize(SL_BOOLEAN_FALSE)` works.
- Every generated file starts with a marker line. Only marked files are overwritten or deleted.

## Enums, bit_sets, and bit_fields

C enums become Odin types, and so do the anonymous constants `table.py`, the reviewed table, groups:

- A named C enum (`media_status_t`), or an anonymous enum right before an integer typedef (`aaudio_format_t`), is an `enum` of that name.
- `table.py` adds new types for anonymous enums and `#define` families (`AKeyCode`, `AInputSources`), bit_sets and bit_fields (`ADataSpace`, `AHardwareBuffer_UsageFlags`), and the slots each type takes: `AKeyEvent_getKeyCode` returns an `AKeyCode`.
- Members drop their shared prefix (`.OK`, `.PCM_I16`). A member that would start with a digit gets `_` (`._12KEY`), or `NUM` on a key code (`.NUM0`).
- A bit_set's single bits are its element enum's members (`ALooperEvents` over `ALooperEvent`). A member of no bits or several bits keeps its C name as a typed constant (`AMETA_NONE :: AMetaState{}`), and so does every named value of a bit_field.
- The C constants that become members go. The rest stay.
- A slot takes a type of exactly its width. A rule that does not fit its slot, or matches nothing, is an error.

Not generated:

| What                         | Why                                                                                   |
|------------------------------|---------------------------------------------------------------------------------------|
| `JNI_OnLoad`, `JNI_OnUnload` | Callbacks the app exports, not functions it calls.                                    |
| `inline` functions           | No library exports them. They are hand-written in the package's `inlines.odin`.       |
| `android.odin`               | The package documentation and `va_list_arg`.                                          |
| `native_app_glue`            | Hand-written Odin, not a binding.                                                     |
| `jni_env.odin`               | The implicit `JNIEnv` (`jni_set_vm`, `jni_env`) is hand-written.                      |
| EGL, GLES, Vulkan, zlib      | `vendor:egl`, `vendor:OpenGL` (`load_gles_up_to`), `vendor:vulkan` and `vendor:zlib`. |
| GLES 1.x (libGLESv1_CM)      | Fixed-function OpenGL ES. Not bound.                                                  |
| The Java APIs                | `vendor:android/java`, generated from the SDK's `android.jar` by its own `_gen`.      |

## Targets

| Target           | Package                         | Libraries                                                         | Notes                                                          |
|------------------|---------------------------------|-------------------------------------------------------------------|----------------------------------------------------------------|
| `core`           | `core:sys/android`              | libandroid, libnativewindow, liblog, libnativehelper, libc, libdl |                                                                |
| `aaudio`         | `vendor:android/aaudio`         | libaaudio                                                         |                                                                |
| `camera`         | `vendor:android/camera`         | libcamera2ndk                                                     |                                                                |
| `media`          | `vendor:android/media`          | libmediandk                                                       |                                                                |
| `amidi`          | `vendor:android/amidi`          | libamidi                                                          | Uses `media`.                                                  |
| `jnigraphics`    | `vendor:android/jnigraphics`    | libjnigraphics                                                    | `bitmap.h`, `imagedecoder.h`.                                  |
| `binder`         | `vendor:android/binder`         | libbinder_ndk, libandroid, libnativewindow                        | With the binder-based parts of libandroid and libnativewindow. |
| `sync`           | `vendor:android/sync`           | libsync                                                           |                                                                |
| `neuralnetworks` | `vendor:android/neuralnetworks` | libneuralnetworks                                                 | Deprecated in API level 35.                                    |
| `icu`            | `vendor:android/icu`            | libicu                                                            | API level 31.                                                  |
| `opensles`       | `vendor:android/opensles`       | libOpenSLES                                                       | Deprecated. Use AAudio.                                        |
| `openmaxal`      | `vendor:android/openmaxal`      | libOpenMAXAL                                                      | Deprecated.                                                    |

A vendor package is called `android_<target>`, but an import is named after its path: `import "vendor:android/camera"` gives `camera`.

`--target <name>` generates one of them. The models of `core` and the target's `uses` are always built, since their types are referred to.

A header whose functions live outside its target's libraries is an error. Such a header belongs to another target.

## Verification

`--verify` checks every generated package against clang on all four Android ABIs (arm64, x86_64, armv7, x86):

- the size and alignment of every type, the offset of every field, and the value of every constant, enum member, bit_set element, and typed constant;
- that every procedure and variable links against the newest stub libraries.

Run it after every regeneration.
