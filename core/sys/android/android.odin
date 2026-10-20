/*
Raw bindings to the Android NDK's C APIs: `jni.h`, liblog, libandroid and libnativewindow, plus bionic's own extensions such as fdsan and `android_dlopen_ext`.

Names are exactly as in C. Most files are generated from the NDK headers by `_gen/generate.py`.

Odin requires API level 29 or higher (`-minimum-os-version:29`).
Procedures introduced later are marked `// API level N`.
Calling one while targeting a lower minimum API level is a link error.

For a NativeActivity app, see `core:sys/android/native_app_glue`.
*/
#+build linux
package android

import "base:intrinsics"

// C passes a `va_list` by value. On x86-64 it is an array, which decays to a pointer to its first element.
when ODIN_ARCH == .amd64 {
	va_list_arg :: ^intrinsics.c_va_list
} else {
	va_list_arg :: intrinsics.c_va_list
}
