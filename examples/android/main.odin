/*
A minimal Android app. It fills its window with a colour that follows a touch, and logs a line from its assets.

See README.md for building and running it.
*/
package main

import "core:fmt"
import "core:log"
import "core:os"
import "core:strings"
import "core:sys/android"
import glue "core:sys/android/native_app_glue"

State :: struct {
	color: u32, // `R8G8B8A8_UNORM`: red in the low byte, alpha in the high.
}

main :: proc() {
	context.logger = log.create_console_logger(ident="OdinExample")

	// `os.stdout` and os.stderr` go to logcat (by default), tagged with the package name.
	fmt.println("Hello from main, started with", os.args)

	if greeting, err := os.read_entire_file("/android_asset/hello.txt", context.allocator); err == nil {
		log.infof("assets/hello.txt says %q", strings.trim_space(string(greeting)))
		delete(greeting)
	} else {
		log.errorf("could not read assets/hello.txt: %v", err)
	}

	state := State{color = 0xff_80_40_20}

	app := glue.app()
	app.userData     = &state
	app.onAppCmd     = on_app_cmd
	app.onInputEvent = on_input_event

	// Back finishes the activity which sets `destroyRequested`.
	// Returning ends the process.
	for app.destroyRequested == 0 {
		source: ^glue.android_poll_source
		if android.ALooper_pollOnce(-1, nil, nil, (^rawptr)(&source)) >= 0 && source != nil {
			source.process(app, source)
		}
	}
	log.info("main returns")
}

on_app_cmd :: proc(app: ^glue.android_app, cmd: i32) {
	switch cmd {
	case glue.APP_CMD_INIT_WINDOW, glue.APP_CMD_WINDOW_RESIZED, glue.APP_CMD_WINDOW_REDRAW_NEEDED:
		draw(app)
	case glue.APP_CMD_DESTROY:
		log.info("the activity is going")
	}
}

on_input_event :: proc(app: ^glue.android_app, event: ^android.AInputEvent) -> i32 {
	// Back and the other keys keep their default behaviour.
	if android.AInputEvent_getType(event) != .MOTION || app.window == nil {
		return 0
	}

	#partial switch android.AMotionEvent_getAction(event).action {
	case .DOWN, .MOVE:
		width  := f32(android.ANativeWindow_getWidth(app.window))
		height := f32(android.ANativeWindow_getHeight(app.window))
		x := clamp(android.AMotionEvent_getX(event, 0) / width,  0, 1)
		y := clamp(android.AMotionEvent_getY(event, 0) / height, 0, 1)

		state := (^State)(app.userData)
		state.color = 0xff_80_00_00 | u32(y*255)<<8 | u32(x*255)
		draw(app)
	}
	return 1
}

draw :: proc(app: ^glue.android_app) {
	if app.window == nil {
		return
	}

	state := (^State)(app.userData)

	android.ANativeWindow_setBuffersGeometry(app.window, 0, 0, .R8G8B8A8_UNORM)
	buffer: android.ANativeWindow_Buffer
	if android.ANativeWindow_lock(app.window, &buffer, nil) != 0 {
		return
	}
	defer android.ANativeWindow_unlockAndPost(app.window)

	pixels := ([^]u32)(buffer.bits)
	for y in 0..<int(buffer.height) {
		row := pixels[y*int(buffer.stride):][:buffer.width]
		for &pixel in row {
			pixel = state.color
		}
	}
}
