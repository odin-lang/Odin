#+build linux
package all

@(require) import "core:sys/android"
@(require) import "core:sys/android/native_app_glue"
@(require) import "core:sys/linux"
@(require) import "core:sys/linux/uring"
@(require) import "vendor:android/aaudio"
@(require) import "vendor:x11/xlib"
