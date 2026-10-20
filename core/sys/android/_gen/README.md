# core:sys/android generator

Most of `core:sys/android` is generated from the Android NDK's C headers by `generate.py`:

```
python core/sys/android/_gen/generate.py --ndk <path/to/ndk> --verify
```

`--ndk` defaults to the `ODIN_ANDROID_NDK` environment variable. Only Python 3 and the NDK are needed.
The NDK's own clang reads the headers (`-Xclang -ast-dump=json`), so there is no libclang or pip dependency.

Last generated from NDK r30 (30.0.16248370).

## What it does

- Every header in `HEADERS` becomes one Odin file. Small related headers share one.
- Names stay exactly as in C (`ALooper_pollOnce`, `AKEYCODE_BACK`, `JNIEnv`).
- clang evaluates every enum constant and object-like macro. The source spelling is kept when it is a plain literal.
- The NDK's stub libraries decide each function's `foreign import` and the API level it appeared in.
  - Functions newer than Odin's minimum API level (29) get an `// API level N` comment.
- Records only forward-declared in a bound header (`struct timespec`) map to `core:sys/posix` through `EXTERNAL_RECORDS`.
- Parameter names of function-pointer types come from the header source, when every parameter has one.
- Every generated file starts with a marker line. Only marked files are overwritten or deleted.

Not generated:

| What                         | Why                                                               |
|------------------------------|-------------------------------------------------------------------|
| `JNI_OnLoad`, `JNI_OnUnload` | Callbacks the app exports, not functions it calls.                |
| `inline` functions           | No library exports them. They are hand-written in `inlines.odin`. |
| `android.odin`               | The package documentation and `va_list_arg`.                      |
| `native_app_glue`            | Hand-written Odin, not a binding.                                 |

A header whose functions live outside the libraries in `LIBRARIES` is an error. Those belong in `vendor:android/<library>`.

## Verification

`--verify` checks the generated package against clang on all four Android ABIs (arm64, x86_64, armv7, x86):

- the size and alignment of every type, the offset of every field, and the value of every constant;
- that every procedure and variable links against the newest stub libraries.

Run it after every regeneration.
