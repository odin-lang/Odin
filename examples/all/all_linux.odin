#+build linux
package all

@(require) import "core:sys/android"
@(require) import "core:sys/android/native_app_glue"
@(require) import "core:sys/linux"
@(require) import "core:sys/linux/uring"
@(require) import "vendor:android/aaudio"
@(require) import "vendor:android/amidi"
@(require) import "vendor:android/binder"
@(require) import "vendor:android/camera"
@(require) import "vendor:android/icu"
@(require) import "vendor:android/jnigraphics"
@(require) import "vendor:android/media"
@(require) import "vendor:android/neuralnetworks"
@(require) import "vendor:android/openmaxal"
@(require) import "vendor:android/opensles"
@(require) import "vendor:android/sync"
@(require) import "vendor:x11/xlib"
