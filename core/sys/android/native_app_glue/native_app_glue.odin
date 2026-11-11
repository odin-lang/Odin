/*
Runs an Odin program as an Android `NativeActivity`, starting at `main` as on other platforms.

Importing this package exports `ANativeActivity_onCreate`, the entry point `NativeActivity` calls.
It runs `main` on a thread of its own with an `ALooper`, once per process. `app` returns the app's state.
The activity's callbacks arrive on that looper as `APP_CMD_*` commands, and input events as `LOOPER_ID_INPUT`:

	package main

	import "core:sys/android"
	import glue "core:sys/android/native_app_glue"

	main :: proc() {
		app := glue.app()
		app.onAppCmd = proc(app: ^glue.android_app, cmd: i32) {
			switch cmd {
			case glue.APP_CMD_INIT_WINDOW: // `app.window` can be drawn to.
			case glue.APP_CMD_TERM_WINDOW: // `app.window` is about to go away.
			}
		}

		for app.destroyRequested == 0 {
			source: ^glue.android_poll_source
			if android.ALooper_pollOnce(-1, nil, nil, (^rawptr)(&source)) >= 0 && source != nil {
				source.process(app, source)
			}
		}
	}

When `main` returns, the activity is finished and the process exits, as returning from `main` does elsewhere.
Return once `destroyRequested` is set: the activity waits for it. The next launch starts a new process,
with the state saved during `APP_CMD_SAVE_STATE` in `savedState` if Android restores the activity.

An activity recreated for a configuration change the manifest does not declare (`android:configChanges`) goes to
the running `main`. `APP_CMD_ACTIVITY_CHANGED` arrives as the old activity goes, with `activity` nil, and again
when the new one comes. Apps usually declare every change they can handle, so this does not happen.

Before `main`, the process is set up as `core:os` expects of other platforms:
- stdout and stderr go to logcat, tagged with the package name, at `.INFO` and `.WARN`. They go to `/dev/null`
  when built with `-define:ODIN_ANDROID_STDIO_TO_LOGCAT=false`.
- The working directory is the app's files directory, its private storage.
- `HOME`, `XDG_CONFIG_HOME`, `XDG_DATA_HOME`, and `XDG_STATE_HOME` are set to the files directory, and `TMPDIR`
  and `XDG_CACHE_HOME` to the cache directory, when unset.
- `os.args` holds only the package name. An activity's arguments arrive through its `Intent` instead.
- The APK's assets can be read through `core:os` under `/android_asset`, and with `android.asset_*`.

Differences from the NDK's C `android_native_app_glue`:
- The program starts at `main`, not an exported `android_main`, and runs once per process.
- `onAppCmd`, `onInputEvent`, and `process` use the Odin calling convention.
*/
#+build linux
package native_app_glue

import "base:intrinsics"
import "base:runtime"
import "core:c"
import "core:c/libc"
import "core:strings"
import "core:sync"
import "core:sys/android"
import "core:sys/posix"
import "core:thread"

// Looper identifiers returned by `ALooper_pollOnce`.

LOOPER_ID_MAIN  :: 1 // Commands from the activity. The source is `cmdPollSource`.
LOOPER_ID_INPUT :: 2 // Events from the input queue. The source is `inputPollSource`.
LOOPER_ID_USER  :: 3 // The first identifier free for the app's own file descriptors.

// Commands passed to `onAppCmd`.

APP_CMD_INPUT_CHANGED        :: 0  // `inputQueue` changed.
APP_CMD_INIT_WINDOW          :: 1  // `window` is ready to use.
APP_CMD_TERM_WINDOW          :: 2  // `window` is about to go away. It is still valid during the command.
APP_CMD_WINDOW_RESIZED       :: 3
APP_CMD_WINDOW_REDRAW_NEEDED :: 4
APP_CMD_CONTENT_RECT_CHANGED :: 5  // See `contentRect`.
APP_CMD_GAINED_FOCUS         :: 6
APP_CMD_LOST_FOCUS           :: 7
APP_CMD_CONFIG_CHANGED       :: 8  // `config` has been updated.
APP_CMD_LOW_MEMORY           :: 9
APP_CMD_START                :: 10
APP_CMD_RESUME               :: 11
APP_CMD_SAVE_STATE           :: 12 // Store state with `set_saved_state` before returning.
APP_CMD_PAUSE                :: 13
APP_CMD_STOP                 :: 14
APP_CMD_DESTROY              :: 15 // `destroyRequested` is set. Return from `main`.
APP_CMD_ACTIVITY_CHANGED     :: 16 // `activity` is nil while a recreated activity goes, then the new one, with `config`.

// The data pointer `ALooper_pollOnce` returns for `LOOPER_ID_MAIN` and `LOOPER_ID_INPUT`.
android_poll_source :: struct {
	id:      i32,
	app:     ^android_app,
	process: proc(app: ^android_app, source: ^android_poll_source),
}

android_app :: struct {
	userData:     rawptr,
	onAppCmd:     proc(app: ^android_app, cmd: i32),
	onInputEvent: proc(app: ^android_app, event: ^android.AInputEvent) -> i32, // Return 1 if the event was handled.

	activity: ^android.ANativeActivity, // nil while a recreated activity is replaced (`APP_CMD_ACTIVITY_CHANGED`).
	config:   ^android.AConfiguration,

	// The state from the previous instance, if any. It must be allocated with `libc.malloc` (see `set_saved_state`).
	savedState:     rawptr,
	savedStateSize: c.size_t,

	looper:      ^android.ALooper,
	inputQueue:  ^android.AInputQueue,
	window:      ^android.ANativeWindow,
	contentRect: android.ARect,

	activityState:    i32, // `APP_CMD_START`, `APP_CMD_RESUME`, `APP_CMD_PAUSE` or `APP_CMD_STOP`.
	destroyRequested: i32,

	// Private to the glue.
	mutex:             sync.Mutex,
	cond:              sync.Cond,
	msgread:           posix.FD,
	msgwrite:          posix.FD,
	cmdPollSource:     android_poll_source,
	inputPollSource:   android_poll_source,
	running:           bool,
	stateSaved:        bool,
	destroyed:         bool,
	pendingInputQueue: ^android.AInputQueue,
	pendingWindow:     ^android.ANativeWindow,
	pendingActivity:   ^android.ANativeActivity,
}

/*
Whether stdout and stderr go to logcat, tagged with the package name (see `android.redirect_stdio_to_logcat`).
Build with `-define:ODIN_ANDROID_STDIO_TO_LOGCAT=false` to leave them at `/dev/null`.
*/
ODIN_ANDROID_STDIO_TO_LOGCAT :: #config(ODIN_ANDROID_STDIO_TO_LOGCAT, true)

// Runs as the library loads, before `main` and the `@(init)` procedures of the packages importing this one.
@(init, private)
init_stdio :: proc "contextless" () {
	when ODIN_ANDROID_STDIO_TO_LOGCAT {
		args := runtime.args__.([]cstring)
		tag  := string(args[0]) if len(args) > 0 else "Odin"
		android.redirect_stdio_to_logcat(tag)
	}
}

@(private)
the_app: ^android_app

// The app of the process, which `main` runs with. Activities come and go under it.
app :: proc "contextless" () -> ^android_app {
	return the_app
}

/*
Replace the saved state with a copy of `data`.

Call it while handling `APP_CMD_SAVE_STATE`. The copy is allocated with `libc.malloc` because the activity frees it.
*/
set_saved_state :: proc "contextless" (app: ^android_app, data: []byte) {
	sync.mutex_lock(&app.mutex)
	defer sync.mutex_unlock(&app.mutex)

	libc.free(app.savedState)
	app.savedState     = nil
	app.savedStateSize = 0
	if len(data) > 0 {
		app.savedState = libc.malloc(c.size_t(len(data)))
		if app.savedState != nil {
			libc.memcpy(app.savedState, raw_data(data), c.size_t(len(data)))
			app.savedStateSize = c.size_t(len(data))
		}
	}
}

// Read the next command from the activity. Returns -1 if none is waiting.
android_app_read_cmd :: proc "contextless" (app: ^android_app) -> i8 {
	cmd: i8
	if posix.read(app.msgread, (^byte)(&cmd), 1) != 1 {
		android.__android_log_write(.ERROR, "native_app_glue", "no data on the command pipe")
		return -1
	}
	if cmd == APP_CMD_SAVE_STATE {
		set_saved_state(app, nil)
	}
	return cmd
}

// The glue's own handling of `cmd`, before `onAppCmd`.
android_app_pre_exec_cmd :: proc "contextless" (app: ^android_app, cmd: i8) {
	switch cmd {
	case APP_CMD_INPUT_CHANGED:
		sync.mutex_lock(&app.mutex)
		if app.inputQueue != nil {
			android.AInputQueue_detachLooper(app.inputQueue)
		}
		app.inputQueue = app.pendingInputQueue
		if app.inputQueue != nil {
			android.AInputQueue_attachLooper(app.inputQueue, app.looper, LOOPER_ID_INPUT, nil, &app.inputPollSource)
		}
		sync.cond_broadcast(&app.cond)
		sync.mutex_unlock(&app.mutex)

	case APP_CMD_INIT_WINDOW:
		sync.mutex_lock(&app.mutex)
		app.window = app.pendingWindow
		sync.cond_broadcast(&app.cond)
		sync.mutex_unlock(&app.mutex)

	case APP_CMD_TERM_WINDOW:
		sync.cond_broadcast(&app.cond)

	case APP_CMD_START, APP_CMD_RESUME, APP_CMD_PAUSE, APP_CMD_STOP:
		sync.mutex_lock(&app.mutex)
		app.activityState = i32(cmd)
		sync.cond_broadcast(&app.cond)
		sync.mutex_unlock(&app.mutex)

	case APP_CMD_CONFIG_CHANGED:
		if app.activity != nil {
			android.AConfiguration_fromAssetManager(app.config, app.activity.assetManager)
		}

	case APP_CMD_DESTROY:
		app.destroyRequested = 1

	case APP_CMD_ACTIVITY_CHANGED:
		sync.mutex_lock(&app.mutex)
		app.activity = app.pendingActivity
		if app.activity != nil {
			android.AConfiguration_fromAssetManager(app.config, app.activity.assetManager)
		}
		sync.cond_broadcast(&app.cond)
		sync.mutex_unlock(&app.mutex)
	}
}

// The glue's own handling of `cmd`, after `onAppCmd`.
android_app_post_exec_cmd :: proc "contextless" (app: ^android_app, cmd: i8) {
	switch cmd {
	case APP_CMD_TERM_WINDOW:
		sync.mutex_lock(&app.mutex)
		app.window = nil
		sync.cond_broadcast(&app.cond)
		sync.mutex_unlock(&app.mutex)

	case APP_CMD_SAVE_STATE:
		sync.mutex_lock(&app.mutex)
		app.stateSaved = true
		sync.cond_broadcast(&app.cond)
		sync.mutex_unlock(&app.mutex)

	case APP_CMD_RESUME:
		set_saved_state(app, nil)
	}
}

@(export)
ANativeActivity_onCreate :: proc "c" (activity: ^android.ANativeActivity, savedState: rawptr, savedStateSize: c.size_t) {
	context = runtime.default_context()
	defer free_all(context.temp_allocator)

	write_cmd :: proc "contextless" (app: ^android_app, cmd: i8) {
		cmd := cmd
		if posix.write(app.msgwrite, (^byte)(&cmd), 1) != 1 {
			android.__android_log_write(.ERROR, "native_app_glue", "could not write to the command pipe")
		}
	}

	// Send `cmd` and wait until the app thread has acted on it.
	set_activity_state :: proc "contextless" (app: ^android_app, cmd: i8) {
		sync.mutex_lock(&app.mutex)
		write_cmd(app, cmd)
		for app.activityState != i32(cmd) {
			sync.cond_wait(&app.cond, &app.mutex)
		}
		sync.mutex_unlock(&app.mutex)
	}

	set_window :: proc "contextless" (app: ^android_app, window: ^android.ANativeWindow) {
		sync.mutex_lock(&app.mutex)
		if app.pendingWindow != nil {
			write_cmd(app, APP_CMD_TERM_WINDOW)
		}
		app.pendingWindow = window
		if window != nil {
			write_cmd(app, APP_CMD_INIT_WINDOW)
		}
		for app.window != app.pendingWindow {
			sync.cond_wait(&app.cond, &app.mutex)
		}
		sync.mutex_unlock(&app.mutex)
	}

	set_input :: proc "contextless" (app: ^android_app, queue: ^android.AInputQueue) {
		sync.mutex_lock(&app.mutex)
		app.pendingInputQueue = queue
		write_cmd(app, APP_CMD_INPUT_CHANGED)
		for app.inputQueue != app.pendingInputQueue {
			sync.cond_wait(&app.cond, &app.mutex)
		}
		sync.mutex_unlock(&app.mutex)
	}

	set_activity :: proc "contextless" (app: ^android_app, activity: ^android.ANativeActivity) {
		sync.mutex_lock(&app.mutex)
		app.pendingActivity = activity
		write_cmd(app, APP_CMD_ACTIVITY_CHANGED)
		for app.activity != app.pendingActivity {
			sync.cond_wait(&app.cond, &app.mutex)
		}
		sync.mutex_unlock(&app.mutex)
	}

	// Whether the activity is destroyed only to be recreated, for a configuration change.
	is_changing_configurations :: proc "contextless" (activity: ^android.ANativeActivity) -> bool {
		env := activity.env
		class := env->GetObjectClass(activity.clazz)
		defer env->DeleteLocalRef(class)
		method := env->GetMethodID(class, "isChangingConfigurations", "()Z")
		if method == nil {
			env->ExceptionClear()
			return false
		}
		return env->CallBooleanMethodA(activity.clazz, method, nil) != 0
	}

	// Keep the application's `AssetManager`, which outlives any activity.
	set_asset_manager :: proc "contextless" (activity: ^android.ANativeActivity) -> bool {
		call :: proc "contextless" (env: ^android.JNIEnv, object: android.jobject, name, signature: cstring) -> android.jobject {
			class := env->GetObjectClass(object)
			defer env->DeleteLocalRef(class)
			method := env->GetMethodID(class, name, signature)
			if method == nil {
				env->ExceptionClear()
				return nil
			}
			result := env->CallObjectMethodA(object, method, nil)
			if env->ExceptionCheck() != android.JNI_FALSE {
				env->ExceptionClear()
				return nil
			}
			return result
		}

		env := activity.env
		app_context := call(env, activity.clazz, "getApplicationContext", "()Landroid/content/Context;")
		if app_context == nil {
			return false
		}
		defer env->DeleteLocalRef(app_context)
		assets := call(env, app_context, "getAssets", "()Landroid/content/res/AssetManager;")
		if assets == nil {
			return false
		}
		defer env->DeleteLocalRef(assets)
		return android.asset_set_manager(env, assets)
	}

	to_app :: proc "contextless" (activity: ^android.ANativeActivity) -> ^android_app {
		return (^android_app)(activity.instance)
	}

	// The thread `main` runs on.
	app_thread :: proc(app: ^android_app) {
		process_cmd :: proc(app: ^android_app, source: ^android_poll_source) {
			cmd := android_app_read_cmd(app)
			android_app_pre_exec_cmd(app, cmd)
			if app.onAppCmd != nil {
				app.onAppCmd(app, i32(cmd))
			}
			android_app_post_exec_cmd(app, cmd)
		}

		process_input :: proc(app: ^android_app, source: ^android_poll_source) {

			event: ^android.AInputEvent
			for android.AInputQueue_getEvent(app.inputQueue, &event) >= 0 {
				if android.AInputQueue_preDispatchEvent(app.inputQueue, event) != 0 {
					continue
				}
				handled: i32
				if app.onInputEvent != nil {
					handled = app.onInputEvent(app, event)
				}
				android.AInputQueue_finishEvent(app.inputQueue, event, c.int(handled))
			}
		}

		app.config = android.AConfiguration_new()
		android.AConfiguration_fromAssetManager(app.config, app.activity.assetManager)

		app.cmdPollSource   = {LOOPER_ID_MAIN,  app, process_cmd}
		app.inputPollSource = {LOOPER_ID_INPUT, app, process_input}

		app.looper = android.ALooper_prepare({.ALLOW_NON_CALLBACKS})
		android.ALooper_addFd(app.looper, c.int(app.msgread), LOOPER_ID_MAIN, {.INPUT}, nil, &app.cmdPollSource)

		sync.mutex_lock(&app.mutex)
		app.running = true
		sync.cond_broadcast(&app.cond)
		sync.mutex_unlock(&app.mutex)

		intrinsics.__entry_point()

		// `main` returned. Finish the activity, and answer the commands it sends until it is destroyed.
		app.onAppCmd     = nil
		app.onInputEvent = nil
		finished: ^android.ANativeActivity
		for app.destroyRequested == 0 {
			if app.activity != nil && app.activity != finished {
				android.ANativeActivity_finish(app.activity)
				finished = app.activity
			}
			source: ^android_poll_source
			if android.ALooper_pollOnce(-1, nil, nil, (^rawptr)(&source)) >= 0 && source != nil {
				source.process(app, source)
			}
		}

		set_saved_state(app, nil)

		sync.mutex_lock(&app.mutex)
		if app.inputQueue != nil {
			android.AInputQueue_detachLooper(app.inputQueue)
		}
		android.AConfiguration_delete(app.config)
		app.destroyed = true
		sync.cond_broadcast(&app.cond)
		sync.mutex_unlock(&app.mutex)
		// The activity's thread ends the process from here on.
	}

	callbacks := activity.callbacks

	callbacks.onStart = proc "c" (activity: ^android.ANativeActivity) {
		set_activity_state(to_app(activity), APP_CMD_START)
	}
	callbacks.onResume = proc "c" (activity: ^android.ANativeActivity) {
		set_activity_state(to_app(activity), APP_CMD_RESUME)
	}
	callbacks.onPause = proc "c" (activity: ^android.ANativeActivity) {
		set_activity_state(to_app(activity), APP_CMD_PAUSE)
	}
	callbacks.onStop = proc "c" (activity: ^android.ANativeActivity) {
		set_activity_state(to_app(activity), APP_CMD_STOP)
	}
	callbacks.onSaveInstanceState = proc "c" (activity: ^android.ANativeActivity, outSize: ^c.size_t) -> rawptr {
		app := to_app(activity)

		sync.mutex_lock(&app.mutex)
		defer sync.mutex_unlock(&app.mutex)

		app.stateSaved = false
		write_cmd(app, APP_CMD_SAVE_STATE)
		for !app.stateSaved {
			sync.cond_wait(&app.cond, &app.mutex)
		}

		// The activity takes ownership and frees it.
		state := app.savedState
		outSize^ = app.savedStateSize
		app.savedState     = nil
		app.savedStateSize = 0
		return state
	}
	callbacks.onDestroy = proc "c" (activity: ^android.ANativeActivity) {
		app := to_app(activity)

		// The running `main` gets the activity that replaces this one.
		if is_changing_configurations(activity) {
			set_activity(app, nil)
			return
		}

		sync.mutex_lock(&app.mutex)
		write_cmd(app, APP_CMD_DESTROY)
		for !app.destroyed {
			sync.cond_wait(&app.cond, &app.mutex)
		}
		sync.mutex_unlock(&app.mutex)

		// `main` has returned, so the process ends, as it does on other platforms.
		// NOTE(bill): `exit` would also run C++ static destructors that Android's own threads (HWUI's) still use,
		// and they abort on the destroyed mutexes. So the `@(fini)` procedures run here, then the process `_exit`s.
		runtime._cleanup_runtime_contextless()
		libc.fflush(nil)
		posix._exit(0)
	}
	callbacks.onConfigurationChanged = proc "c" (activity: ^android.ANativeActivity) {
		write_cmd(to_app(activity), APP_CMD_CONFIG_CHANGED)
	}
	callbacks.onContentRectChanged = proc "c" (activity: ^android.ANativeActivity, rect: ^android.ARect) {
		app := to_app(activity)
		sync.mutex_lock(&app.mutex)
		app.contentRect = rect^
		sync.mutex_unlock(&app.mutex)
		write_cmd(app, APP_CMD_CONTENT_RECT_CHANGED)
	}
	callbacks.onLowMemory = proc "c" (activity: ^android.ANativeActivity) {
		write_cmd(to_app(activity), APP_CMD_LOW_MEMORY)
	}
	callbacks.onWindowFocusChanged = proc "c" (activity: ^android.ANativeActivity, hasFocus: c.int) {
		write_cmd(to_app(activity), APP_CMD_GAINED_FOCUS if hasFocus != 0 else APP_CMD_LOST_FOCUS)
	}
	callbacks.onNativeWindowCreated = proc "c" (activity: ^android.ANativeActivity, window: ^android.ANativeWindow) {
		set_window(to_app(activity), window)
	}
	callbacks.onNativeWindowDestroyed = proc "c" (activity: ^android.ANativeActivity, window: ^android.ANativeWindow) {
		set_window(to_app(activity), nil)
	}
	callbacks.onNativeWindowRedrawNeeded = proc "c" (activity: ^android.ANativeActivity, window: ^android.ANativeWindow) {
		write_cmd(to_app(activity), APP_CMD_WINDOW_REDRAW_NEEDED)
	}
	callbacks.onNativeWindowResized = proc "c" (activity: ^android.ANativeActivity, window: ^android.ANativeWindow) {
		write_cmd(to_app(activity), APP_CMD_WINDOW_RESIZED)
	}
	callbacks.onInputQueueCreated = proc "c" (activity: ^android.ANativeActivity, queue: ^android.AInputQueue) {
		set_input(to_app(activity), queue)
	}
	callbacks.onInputQueueDestroyed = proc "c" (activity: ^android.ANativeActivity, queue: ^android.AInputQueue) {
		set_input(to_app(activity), nil)
	}

	// An activity recreated for a configuration change goes to the running `main`.
	if the_app != nil {
		activity.instance = the_app
		set_activity(the_app, activity)
		return
	}

	// `core:os` finds the user directories through `HOME`, `TMPDIR`, and the XDG variables. The files directory is
	// the one place an app can write, so relative paths resolve there. The cache directory sits next to it.
	if files := activity.internalDataPath; files != nil {
		posix.setenv("HOME",            files, false)
		posix.setenv("XDG_CONFIG_HOME", files, false)
		posix.setenv("XDG_DATA_HOME",   files, false)
		posix.setenv("XDG_STATE_HOME",  files, false)
		posix.chdir(files)

		if i := strings.last_index_byte(string(files), '/'); i > 0 {
			cache := strings.concatenate({string(files)[:i], "/cache"}, context.temp_allocator)
			ccache := strings.clone_to_cstring(cache, context.temp_allocator)
			posix.setenv("TMPDIR",         ccache, false)
			posix.setenv("XDG_CACHE_HOME", ccache, false)
		}
	}

	// For `android.jni_env` and the `vendor:android/java` wrappers.
	android.jni_set_vm(activity.vm)

	// For `android.asset_*` and `core:os`'s `/android_asset` paths.
	if !set_asset_manager(activity) {
		android.__android_log_write(.ERROR, "native_app_glue", "could not get the application's AssetManager")
	}

	app := new(android_app, runtime.heap_allocator())
	app.activity = activity

	if savedState != nil {
		set_saved_state(app, ([^]byte)(savedState)[:savedStateSize])
	}

	fds: [2]posix.FD
	if posix.pipe(&fds) != .OK {
		android.__android_log_write(.ERROR, "native_app_glue", "could not create the command pipe")
		free(app, runtime.heap_allocator())
		return
	}
	app.msgread  = fds[0]
	app.msgwrite = fds[1]

	activity.instance = app
	the_app = app

	thread.create_and_start_with_poly_data(app, app_thread, self_cleanup=true)

	// Wait for the thread's looper before any command is sent.
	sync.mutex_lock(&app.mutex)
	for !app.running {
		sync.cond_wait(&app.cond, &app.mutex)
	}
	sync.mutex_unlock(&app.mutex)
}
