package sdl3

import "core:c"

EventType :: enum Uint32 {
	FIRST     = 0,     /**< Unused (do not remove) */

	/* Application events */
	QUIT           = 0x100, /**< User-requested quit */

	/* These application events have special meaning on iOS and Android, see README-ios.md and README-android.md for details */
	TERMINATING,      /**< The application is being terminated by the OS. This event must be handled in a callback set with SDL_AddEventWatch().
	                             Called on iOS in applicationWillTerminate()
	                             Called on Android in onDestroy()
	                        */
	LOW_MEMORY,       /**< The application is low on memory, free memory if possible. This event must be handled in a callback set with SDL_AddEventWatch().
	                             Called on iOS in applicationDidReceiveMemoryWarning()
	                             Called on Android in onTrimMemory()
	                        */
	WILL_ENTER_BACKGROUND, /**< The application is about to enter the background. This event must be handled in a callback set with SDL_AddEventWatch().
	                             Called on iOS in applicationWillResignActive()
	                             Called on Android in onPause()
	                        */
	DID_ENTER_BACKGROUND, /**< The application did enter the background and may not get CPU for some time. This event must be handled in a callback set with SDL_AddEventWatch().
	                             Called on iOS in applicationDidEnterBackground()
	                             Called on Android in onPause()
	                        */
	WILL_ENTER_FOREGROUND, /**< The application is about to enter the foreground. This event must be handled in a callback set with SDL_AddEventWatch().
	                             Called on iOS in applicationWillEnterForeground()
	                             Called on Android in onResume()
	                        */
	DID_ENTER_FOREGROUND, /**< The application is now interactive. This event must be handled in a callback set with SDL_AddEventWatch().
	                             Called on iOS in applicationDidBecomeActive()
	                             Called on Android in onResume()
	                        */

	LOCALE_CHANGED,  /**< The user's locale preferences have changed. */

	SYSTEM_THEME_CHANGED, /**< The system theme changed */

	/* Display events */
	/* 0x150 was SDL_DISPLAYEVENT, reserve the number for sdl2-compat */
	DISPLAY_ORIENTATION = 0x151,   /**< Display orientation has changed to data1 */
	DISPLAY_ADDED,                 /**< Display has been added to the system */
	DISPLAY_REMOVED,               /**< Display has been removed from the system */
	DISPLAY_MOVED,                 /**< Display has changed position */
	DISPLAY_DESKTOP_MODE_CHANGED,  /**< Display has changed desktop mode */
	DISPLAY_CURRENT_MODE_CHANGED,  /**< Display has changed current mode */
	DISPLAY_CONTENT_SCALE_CHANGED, /**< Display has changed content scale */
	DISPLAY_FIRST = DISPLAY_ORIENTATION,
	DISPLAY_LAST = DISPLAY_CONTENT_SCALE_CHANGED,

	/* Window events */
	/* 0x200 was SDL_WINDOWEVENT, reserve the number for sdl2-compat */
	/* 0x201 was SYSWM, reserve the number for sdl2-compat */
	WINDOW_SHOWN = 0x202,     /**< Window has been shown */
	WINDOW_HIDDEN,            /**< Window has been hidden */
	WINDOW_EXPOSED,           /**< Window has been exposed and should be redrawn, and can be redrawn directly from event watchers for this event */
	WINDOW_MOVED,             /**< Window has been moved to data1, data2 */
	WINDOW_RESIZED,           /**< Window has been resized to data1xdata2 */
	WINDOW_PIXEL_SIZE_CHANGED,/**< The pixel size of the window has changed to data1xdata2 */
	WINDOW_METAL_VIEW_RESIZED,/**< The pixel size of a Metal view associated with the window has changed */
	WINDOW_MINIMIZED,         /**< Window has been minimized */
	WINDOW_MAXIMIZED,         /**< Window has been maximized */
	WINDOW_RESTORED,          /**< Window has been restored to normal size and position */
	WINDOW_MOUSE_ENTER,       /**< Window has gained mouse focus */
	WINDOW_MOUSE_LEAVE,       /**< Window has lost mouse focus */
	WINDOW_FOCUS_GAINED,      /**< Window has gained keyboard focus */
	WINDOW_FOCUS_LOST,        /**< Window has lost keyboard focus */
	WINDOW_CLOSE_REQUESTED,   /**< The window manager requests that the window be closed */
	WINDOW_HIT_TEST,          /**< Window had a hit test that wasn't SDL_HITTEST_NORMAL */
	WINDOW_ICCPROF_CHANGED,   /**< The ICC profile of the window's display has changed */
	WINDOW_DISPLAY_CHANGED,   /**< Window has been moved to display data1 */
	WINDOW_DISPLAY_SCALE_CHANGED, /**< Window display scale has been changed */
	WINDOW_SAFE_AREA_CHANGED, /**< The window safe area has been changed */
	WINDOW_OCCLUDED,          /**< The window has been occluded */
	WINDOW_ENTER_FULLSCREEN,  /**< The window has entered fullscreen mode */
	WINDOW_LEAVE_FULLSCREEN,  /**< The window has left fullscreen mode */
	WINDOW_DESTROYED,         /**< The window with the associated ID is being or has been destroyed. If this message is being handled
	                                     in an event watcher, the window handle is still valid and can still be used to retrieve any properties
	                                     associated with the window. Otherwise, the handle has already been destroyed and all resources
	                                     associated with it are invalid */
	WINDOW_HDR_STATE_CHANGED, /**< Window HDR properties have changed */
	WINDOW_FIRST = WINDOW_SHOWN,
	WINDOW_LAST = WINDOW_HDR_STATE_CHANGED,

	/* Keyboard events */
	KEY_DOWN        = 0x300, /**< Key pressed */
	KEY_UP,                  /**< Key released */
	TEXT_EDITING,            /**< Keyboard text editing (composition) */
	TEXT_INPUT,              /**< Keyboard text input */
	KEYMAP_CHANGED,          /**< Keymap changed due to a system event such as an
	                                    input language or keyboard layout change. */
	KEYBOARD_ADDED,          /**< A new keyboard has been inserted into the system */
	KEYBOARD_REMOVED,        /**< A keyboard has been removed */
	TEXT_EDITING_CANDIDATES, /**< Keyboard text editing candidates */

	/* Mouse events */
	MOUSE_MOTION    = 0x400, /**< Mouse moved */
	MOUSE_BUTTON_DOWN,       /**< Mouse button pressed */
	MOUSE_BUTTON_UP,         /**< Mouse button released */
	MOUSE_WHEEL,             /**< Mouse wheel motion */
	MOUSE_ADDED,             /**< A new mouse has been inserted into the system */
	MOUSE_REMOVED,           /**< A mouse has been removed */

	/* Joystick events */
	JOYSTICK_AXIS_MOTION  = 0x600, /**< Joystick axis motion */
	JOYSTICK_BALL_MOTION,          /**< Joystick trackball motion */
	JOYSTICK_HAT_MOTION,           /**< Joystick hat position change */
	JOYSTICK_BUTTON_DOWN,          /**< Joystick button pressed */
	JOYSTICK_BUTTON_UP,            /**< Joystick button released */
	JOYSTICK_ADDED,                /**< A new joystick has been inserted into the system */
	JOYSTICK_REMOVED,              /**< An opened joystick has been removed */
	JOYSTICK_BATTERY_UPDATED,      /**< Joystick battery level change */
	JOYSTICK_UPDATE_COMPLETE,      /**< Joystick update is complete */

	/* Gamepad events */
	GAMEPAD_AXIS_MOTION  = 0x650, /**< Gamepad axis motion */
	GAMEPAD_BUTTON_DOWN,          /**< Gamepad button pressed */
	GAMEPAD_BUTTON_UP,            /**< Gamepad button released */
	GAMEPAD_ADDED,                /**< A new gamepad has been inserted into the system */
	GAMEPAD_REMOVED,              /**< A gamepad has been removed */
	GAMEPAD_REMAPPED,             /**< The gamepad mapping was updated */
	GAMEPAD_TOUCHPAD_DOWN,        /**< Gamepad touchpad was touched */
	GAMEPAD_TOUCHPAD_MOTION,      /**< Gamepad touchpad finger was moved */
	GAMEPAD_TOUCHPAD_UP,          /**< Gamepad touchpad finger was lifted */
	GAMEPAD_SENSOR_UPDATE,        /**< Gamepad sensor was updated */
	GAMEPAD_UPDATE_COMPLETE,      /**< Gamepad update is complete */
	GAMEPAD_STEAM_HANDLE_UPDATED,  /**< Gamepad Steam handle has changed */

	/* Touch events */
	FINGER_DOWN      = 0x700,
	FINGER_UP,
	FINGER_MOTION,
	FINGER_CANCELED,

	/* 0x800, 0x801, and 0x802 were the Gesture events from SDL2. Do not reuse these values! sdl2-compat needs them! */

	/* Clipboard events */
	CLIPBOARD_UPDATE = 0x900, /**< The clipboard or primary selection changed */

	/* Drag and drop events */
	DROP_FILE        = 0x1000, /**< The system requests a file open */
	DROP_TEXT,                 /**< text/plain drag-and-drop event */
	DROP_BEGIN,                /**< A new set of drops is beginning (NULL filename) */
	DROP_COMPLETE,             /**< Current set of drops is now complete (NULL filename) */
	DROP_POSITION,             /**< Position while moving over the window */

	/* Audio hotplug events */
	AUDIO_DEVICE_ADDED = 0x1100,  /**< A new audio device is available */
	AUDIO_DEVICE_REMOVED,         /**< An audio device has been removed. */
	AUDIO_DEVICE_FORMAT_CHANGED,  /**< An audio device's format has been changed by the system. */

	/* Sensor events */
	SENSOR_UPDATE = 0x1200,     /**< A sensor was updated */

	/* Pressure-sensitive pen events */
	PEN_PROXIMITY_IN = 0x1300,  /**< Pressure-sensitive pen has become available */
	PEN_PROXIMITY_OUT,          /**< Pressure-sensitive pen has become unavailable */
	PEN_DOWN,                   /**< Pressure-sensitive pen touched drawing surface */
	PEN_UP,                     /**< Pressure-sensitive pen stopped touching drawing surface */
	PEN_BUTTON_DOWN,            /**< Pressure-sensitive pen button pressed */
	PEN_BUTTON_UP,              /**< Pressure-sensitive pen button released */
	PEN_MOTION,                 /**< Pressure-sensitive pen is moving on the tablet */
	PEN_AXIS,                   /**< Pressure-sensitive pen angle/pressure/etc changed */

	/* Camera hotplug events */
	CAMERA_DEVICE_ADDED = 0x1400,  /**< A new camera device is available */
	CAMERA_DEVICE_REMOVED,         /**< A camera device has been removed. */
	CAMERA_DEVICE_APPROVED,        /**< A camera device has been approved for use by the user. */
	CAMERA_DEVICE_DENIED,          /**< A camera device has been denied for use by the user. */

	/* Render events */
	RENDER_TARGETS_RESET = 0x2000, /**< The render targets have been reset and their contents need to be updated */
	RENDER_DEVICE_RESET, /**< The device has been reset and all textures need to be recreated */
	RENDER_DEVICE_LOST, /**< The device has been lost and can't be recovered. */

	/* Reserved events for private platforms */
	PRIVATE0 = 0x4000,
	PRIVATE1,
	PRIVATE2,
	PRIVATE3,

	/* Internal events */
	POLL_SENTINEL = 0x7F00, /**< Signals the end of an event poll cycle */

	/** Events USER through LAST are for your use,
	*  and should be allocated with SDL_RegisterEvents()
	*/
	USER    = 0x8000,

	/**
	*  This last event is only for bounding internal arrays
	*/
	LAST    = 0xFFFF,
}

CommonEvent :: struct {
	type:      EventType, /**< Event type, shared with all events, Uint32 to cover user events which are not in the SDL_EventType enumeration */
	_:         Uint32,
	timestamp: Uint64,  /**< In nanoseconds, populated using SDL_GetTicksNS() */
}

DisplayEvent :: struct {
	using commonEvent: CommonEvent, /**< SDL_DISPLAYEVENT_* */
	displayID: DisplayID,  /**< The associated display */
	data1:     Sint32,     /**< event dependent data */
	data2:     Sint32,     /**< event dependent data */
}

WindowEvent :: struct {
	using commonEvent: CommonEvent,  /**< SDL_EVENT_WINDOW_* */
	windowID:  WindowID,  /**< The associated window */
	data1:     Sint32,    /**< event dependent data */
	data2:     Sint32,    /**< event dependent data */
}

KeyboardDeviceEvent :: struct {
	using commonEvent: CommonEvent, /**< SDL_EVENT_KEYBOARD_ADDED or SDL_EVENT_KEYBOARD_REMOVED */
	which: KeyboardID,  /**< The keyboard instance id */
}

KeyboardEvent :: struct {
	using commonEvent: CommonEvent, /**< SDL_EVENT_KEY_DOWN or SDL_EVENT_KEY_UP */
	windowID:  WindowID,    /**< The window with keyboard focus, if any */
	which:     KeyboardID,  /**< The keyboard instance id, or 0 if unknown or virtual */
	scancode:  Scancode,    /**< SDL physical key code */
	key:       Keycode,     /**< SDL virtual key code */
	mod:       Keymod,      /**< current key modifiers */
	raw:       Uint16,      /**< The platform dependent scancode for this event */
	down:      bool,        /**< true if the key is pressed */
	repeat:    bool,        /**< true if this is a key repeat */
}

TextEditingEvent :: struct {
	using commonEvent: CommonEvent, /**< SDL_EVENT_TEXT_EDITING */
	windowID:  WindowID,  /**< The window with keyboard focus, if any */
	text:      cstring,   /**< The editing text */
	start:     Sint32,    /**< The start cursor of selected editing text, or -1 if not set */
	length:    Sint32,    /**< The length of selected editing text, or -1 if not set */
}

TextEditingCandidatesEvent :: struct {
	using commonEvent: CommonEvent, /**< SDL_EVENT_TEXT_EDITING_CANDIDATES */
	windowID:           WindowID,                            /**< The window with keyboard focus, if any */
	candidates:         [^]cstring `fmt:"v,num_candidates"`, /**< The list of candidates, or NULL if there are no candidates available */
	num_candidates:     Sint32,                              /**< The number of strings in `candidates` */
	selected_candidate: Sint32,                              /**< The index of the selected candidate, or -1 if no candidate is selected */
	horizontal:         bool,                                /**< true if the list is horizontal, false if it's vertical */
	_: Uint8,
	_: Uint8,
	_: Uint8,
}

TextInputEvent :: struct {
	using commonEvent: CommonEvent, /**< SDL_EVENT_TEXT_INPUT */
	windowID: WindowID,  /**< The window with keyboard focus, if any */
	text:     cstring,   /**< The input text, UTF-8 encoded */
}

MouseDeviceEvent :: struct {
	using commonEvent: CommonEvent, /**< SDL_EVENT_MOUSE_ADDED or SDL_EVENT_MOUSE_REMOVED */
	which: MouseID,  /**< The mouse instance id */
}

MouseMotionEvent :: struct {
	using commonEvent: CommonEvent, /**< SDL_EVENT_MOUSE_MOTION */
	windowID: WindowID,          /**< The window with mouse focus, if any */
	which:    MouseID,           /**< The mouse instance id in relative mode, SDL_TOUCH_MOUSEID for touch events, or 0 */
	state:    MouseButtonFlags,  /**< The current button state */
	x:        f32,               /**< X coordinate, relative to window */
	y:        f32,               /**< Y coordinate, relative to window */
	xrel:     f32,               /**< The relative motion in the X direction */
	yrel:     f32,               /**< The relative motion in the Y direction */
}

MouseButtonEvent :: struct {
	using commonEvent: CommonEvent, /**< SDL_EVENT_MOUSE_BUTTON_DOWN or SDL_EVENT_MOUSE_BUTTON_UP */
	windowID: WindowID,  /**< The window with mouse focus, if any */
	which:    MouseID,   /**< The mouse instance id in relative mode, SDL_TOUCH_MOUSEID for touch events, or 0 */
	button:   Uint8,     /**< The mouse button index */
	down:     bool,      /**< true if the button is pressed */
	clicks:   Uint8,     /**< 1 for single-click, 2 for double-click, etc. */
	_:        Uint8,
	x:        f32,       /**< X coordinate, relative to window */
	y:        f32,       /**< Y coordinate, relative to window */
}

MouseWheelEvent :: struct {
	using commonEvent: CommonEvent,  /**< SDL_EVENT_MOUSE_WHEEL */
	windowID:  WindowID,             /**< The window with mouse focus, if any */
	which:     MouseID,              /**< The mouse instance id in relative mode or 0 */
	x:         f32,                  /**< The amount scrolled horizontally, positive to the right and negative to the left */
	y:         f32,                  /**< The amount scrolled vertically, positive away from the user and negative toward the user */
	direction: MouseWheelDirection,  /**< Set to one of the SDL_MOUSEWHEEL_* defines. When FLIPPED the values in X and Y will be opposite. Multiply by -1 to change them back */
	mouse_x:   f32,                  /**< X coordinate, relative to window */
	mouse_y:   f32,                  /**< Y coordinate, relative to window */
}

JoyAxisEvent :: struct {
	using commonEvent: CommonEvent, /**< SDL_EVENT_JOYSTICK_AXIS_MOTION */
	which: JoystickID,  /**< The joystick instance id */
	axis:  Uint8,       /**< The joystick axis index */
	_:     Uint8,
	_:     Uint8,
	_:     Uint8,
	value: Sint16,      /**< The axis value (range: -32768 to 32767) */
	_:     Uint16,
}

JoyBallEvent :: struct {
	using commonEvent: CommonEvent, /**< SDL_EVENT_JOYSTICK_BALL_MOTION */
	which: JoystickID,  /**< The joystick instance id */
	ball:  Uint8,       /**< The joystick trackball index */
	_:     Uint8,
	_:     Uint8,
	_:     Uint8,
	xrel:  Sint16,      /**< The relative motion in the X direction */
	yrel:  Sint16,      /**< The relative motion in the Y direction */
}

JoyHatEvent :: struct {
	using commonEvent: CommonEvent, /**< SDL_EVENT_JOYSTICK_HAT_MOTION */
	which: JoystickID, /**< The joystick instance id */
	hat:   Uint8,      /**< The joystick hat index */
	value: Uint8,      /**< The hat position value.
	                     *   \sa SDL_HAT_LEFTUP SDL_HAT_UP SDL_HAT_RIGHTUP
	                     *   \sa SDL_HAT_LEFT SDL_HAT_CENTERED SDL_HAT_RIGHT
	                     *   \sa SDL_HAT_LEFTDOWN SDL_HAT_DOWN SDL_HAT_RIGHTDOWN
	                     *
	                     *   Note that zero means the POV is centered.
	                     */
	_: Uint8,
	_: Uint8,
}

JoyButtonEvent :: struct {
	using commonEvent: CommonEvent, /**< SDL_EVENT_JOYSTICK_BUTTON_DOWN or SDL_EVENT_JOYSTICK_BUTTON_UP */
	which:  JoystickID,  /**< The joystick instance id */
	button: Uint8,       /**< The joystick button index */
	down:   bool,        /**< true if the button is pressed */
	_: Uint8,
	_: Uint8,
}

JoyDeviceEvent :: struct {
	using commonEvent: CommonEvent, /**< SDL_EVENT_JOYSTICK_ADDED or SDL_EVENT_JOYSTICK_REMOVED or SDL_EVENT_JOYSTICK_UPDATE_COMPLETE */
	which: JoystickID,  /**< The joystick instance id */
}

JoyBatteryEvent :: struct {
	using commonEvent: CommonEvent, /**< SDL_EVENT_JOYSTICK_BATTERY_UPDATED */
	which:   JoystickID,  /**< The joystick instance id */
	state:   PowerState,  /**< The joystick battery state */
	percent: c.int,       /**< The joystick battery percent charge remaining */
}

GamepadAxisEvent :: struct {
	using commonEvent: CommonEvent, /**< SDL_EVENT_GAMEPAD_AXIS_MOTION */
	which: JoystickID, /**< The joystick instance id */
	axis:  Uint8,      /**< The gamepad axis (SDL_GamepadAxis) */
	_:     Uint8,
	_:     Uint8,
	_:     Uint8,
	value: Sint16,     /**< The axis value (range: -32768 to 32767) */
	_:     Uint16,
}

GamepadButtonEvent :: struct {
	using commonEvent: CommonEvent, /**< SDL_EVENT_GAMEPAD_BUTTON_DOWN or SDL_EVENT_GAMEPAD_BUTTON_UP */
	which:  JoystickID,  /**< The joystick instance id */
	button: Uint8,       /**< The gamepad button (SDL_GamepadButton) */
	down:   bool,        /**< true if the button is pressed */
	_: Uint8,
	_: Uint8,
}

GamepadDeviceEvent :: struct {
	using commonEvent: CommonEvent, /**< SDL_EVENT_GAMEPAD_ADDED, SDL_EVENT_GAMEPAD_REMOVED, or SDL_EVENT_GAMEPAD_REMAPPED, SDL_EVENT_GAMEPAD_UPDATE_COMPLETE or SDL_EVENT_GAMEPAD_STEAM_HANDLE_UPDATED */
	which: JoystickID,              /**< The joystick instance id */
}

GamepadTouchpadEvent :: struct {
	using commonEvent: CommonEvent, /**< SDL_EVENT_GAMEPAD_TOUCHPAD_DOWN or SDL_EVENT_GAMEPAD_TOUCHPAD_MOTION or SDL_EVENT_GAMEPAD_TOUCHPAD_UP */
	which:    JoystickID,  /**< The joystick instance id */
	touchpad: Sint32,      /**< The index of the touchpad */
	finger:   Sint32,      /**< The index of the finger on the touchpad */
	x:        f32,         /**< Normalized in the range 0...1 with 0 being on the left */
	y:        f32,         /**< Normalized in the range 0...1 with 0 being at the top */
	pressure: f32,         /**< Normalized in the range 0...1 */
}

GamepadSensorEvent :: struct {
	using commonEvent: CommonEvent, /**< SDL_EVENT_GAMEPAD_SENSOR_UPDATE */
	which:            JoystickID,  /**< The joystick instance id */
	sensor:           Sint32,      /**< The type of the sensor, one of the values of SDL_SensorType */
	data:             [3]f32,      /**< Up to 3 values from the sensor, as defined in SDL_sensor.h */
	sensor_timestamp: Uint64,      /**< The timestamp of the sensor reading in nanoseconds, not necessarily synchronized with the system clock */
}

AudioDeviceEvent :: struct {
	using commonEvent: CommonEvent, /**< SDL_EVENT_AUDIO_DEVICE_ADDED, or SDL_EVENT_AUDIO_DEVICE_REMOVED, or SDL_EVENT_AUDIO_DEVICE_FORMAT_CHANGED */
	which:     AudioDeviceID,  /**< SDL_AudioDeviceID for the device being added or removed or changing */
	recording: bool,           /**< false if a playback device, true if a recording device. */
	_: Uint8,
	_: Uint8,
	_: Uint8,
}

CameraDeviceEvent :: struct {
	using commonEvent: CommonEvent, /**< SDL_EVENT_CAMERA_DEVICE_ADDED, SDL_EVENT_CAMERA_DEVICE_REMOVED, SDL_EVENT_CAMERA_DEVICE_APPROVED, SDL_EVENT_CAMERA_DEVICE_DENIED */
	which: CameraID,  /**< SDL_CameraID for the device being added or removed or changing */
}

RenderEvent :: struct {
	using commonEvent: CommonEvent, /**< SDL_EVENT_RENDER_TARGETS_RESET, SDL_EVENT_RENDER_DEVICE_RESET, SDL_EVENT_RENDER_DEVICE_LOST */
	windowID: WindowID,  /**< The window containing the renderer in question. */
}

TouchFingerEvent :: struct {
	using commonEvent: CommonEvent, /**< SDL_EVENT_FINGER_DOWN, SDL_EVENT_FINGER_UP, SDL_EVENT_FINGER_MOTION, or SDL_EVENT_FINGER_CANCELED */
	touchID:  TouchID,   /**< The touch device id */
	fingerID: FingerID,
	x:        f32,       /**< Normalized in the range 0...1 */
	y:        f32,       /**< Normalized in the range 0...1 */
	dx:       f32,       /**< Normalized in the range -1...1 */
	dy:       f32,       /**< Normalized in the range -1...1 */
	pressure: f32,       /**< Normalized in the range 0...1 */
	windowID: WindowID,  /**< The window underneath the finger, if any */
}

PenProximityEvent :: struct {
	using commonEvent: CommonEvent, /**< SDL_EVENT_PEN_PROXIMITY_IN or SDL_EVENT_PEN_PROXIMITY_OUT */
	windowID: WindowID,  /**< The window with pen focus, if any */
	which:    PenID,     /**< The pen instance id */
}


PenMotionEvent :: struct {
	using commonEvent: CommonEvent, /**< SDL_EVENT_PEN_MOTION */
	windowID:  WindowID,       /**< The window with pen focus, if any */
	which:     PenID,          /**< The pen instance id */
	pen_state: PenInputFlags,  /**< Complete pen input state at time of event */
	x:         f32,            /**< X coordinate, relative to window */
	y:         f32,            /**< Y coordinate, relative to window */
}

PenTouchEvent :: struct {
	using commonEvent: CommonEvent,     /**< SDL_EVENT_PEN_DOWN or SDL_EVENT_PEN_UP */
	windowID:  WindowID,       /**< The window with pen focus, if any */
	which:     PenID,          /**< The pen instance id */
	pen_state: PenInputFlags,  /**< Complete pen input state at time of event */
	x:         f32,            /**< X coordinate, relative to window */
	y:         f32,            /**< Y coordinate, relative to window */
	eraser:    bool,           /**< true if eraser end is used (not all pens support this). */
	down:      bool,           /**< true if the pen is touching or false if the pen is lifted off */
}

PenButtonEvent :: struct {
	using commonEvent: CommonEvent, /**< SDL_EVENT_PEN_BUTTON_DOWN or SDL_EVENT_PEN_BUTTON_UP */
	windowID:  WindowID,       /**< The window with mouse focus, if any */
	which:     PenID,          /**< The pen instance id */
	pen_state: PenInputFlags,  /**< Complete pen input state at time of event */
	x:         f32,            /**< X coordinate, relative to window */
	y:         f32,            /**< Y coordinate, relative to window */
	button:    Uint8,          /**< The pen button index (first button is 1). */
	down:      bool,           /**< true if the button is pressed */
}

PenAxisEvent :: struct {
	using commonEvent: CommonEvent, /**< SDL_EVENT_PEN_AXIS */
	windowID:  WindowID,       /**< The window with pen focus, if any */
	which:     PenID,          /**< The pen instance id */
	pen_state: PenInputFlags,  /**< Complete pen input state at time of event */
	x:         f32,            /**< X coordinate, relative to window */
	y:         f32,            /**< Y coordinate, relative to window */
	axis:      PenAxis,        /**< Axis that has changed */
	value:     f32,            /**< New value of axis */
}

DropEvent :: struct {
	using commonEvent: CommonEvent, /**< SDL_EVENT_DROP_BEGIN or SDL_EVENT_DROP_FILE or SDL_EVENT_DROP_TEXT or SDL_EVENT_DROP_COMPLETE or SDL_EVENT_DROP_POSITION */
	windowID: WindowID,  /**< The window that was dropped on, if any */
	x:        f32,       /**< X coordinate, relative to window (not on begin) */
	y:        f32,       /**< Y coordinate, relative to window (not on begin) */
	source:   cstring,   /**< The source app that sent this drop event, or NULL if that isn't available */
	data:     cstring,   /**< The text for SDL_EVENT_DROP_TEXT and the file name for SDL_EVENT_DROP_FILE, NULL for other events */
}

ClipboardEvent :: struct {
	using commonEvent: CommonEvent, /**< SDL_EVENT_CLIPBOARD_UPDATE */
	owner:          bool,                                /**< are we owning the clipboard (internal update) */
	num_mime_types: Sint32,                              /**< number of mime types */
	mime_types:     [^]cstring `fmt:"v,num_mime_types"`, /**< current mime types */
}

SensorEvent :: struct {
	using commonEvent: CommonEvent, /**< SDL_EVENT_SENSOR_UPDATE */
	which:            SensorID, /**< The instance ID of the sensor */
	data: [6]f32,               /**< Up to 6 values from the sensor - additional values can be queried using SDL_GetSensorData() */
	sensor_timestamp: Uint64,   /**< The timestamp of the sensor reading in nanoseconds, not necessarily synchronized with the system clock */
}

QuitEvent :: struct {
	using commonEvent: CommonEvent, /**< SDL_EVENT_QUIT */
}

UserEvent :: struct {
	using commonEvent: CommonEvent, /**< SDL_EVENT_USER through SDL_EVENT_LAST-1, Uint32 because these are not in the SDL_EventType enumeration */
	windowID: WindowID,  /**< The associated window if any */
	code:     Sint32,    /**< User defined event code */
	data1:    rawptr,    /**< User defined data pointer */
	data2:    rawptr,    /**< User defined data pointer */
}




Event :: struct #raw_union {
	type:            EventType,                  /**< Event type, shared with all events, Uint32 to cover user events which are not in the SDL_EventType enumeration */
	common:          CommonEvent,                /**< Common event data */
	display:         DisplayEvent,               /**< Display event data */
	window:          WindowEvent,                /**< Window event data */
	kdevice:         KeyboardDeviceEvent,        /**< Keyboard device change event data */
	key:             KeyboardEvent,              /**< Keyboard event data */
	edit:            TextEditingEvent,           /**< Text editing event data */
	edit_candidates: TextEditingCandidatesEvent, /**< Text editing candidates event data */
	text:            TextInputEvent,             /**< Text input event data */
	mdevice:         MouseDeviceEvent,           /**< Mouse device change event data */
	motion:          MouseMotionEvent,           /**< Mouse motion event data */
	button:          MouseButtonEvent,           /**< Mouse button event data */
	wheel:           MouseWheelEvent,            /**< Mouse wheel event data */
	jdevice:         JoyDeviceEvent,             /**< Joystick device change event data */
	jaxis:           JoyAxisEvent,               /**< Joystick axis event data */
	jball:           JoyBallEvent,               /**< Joystick ball event data */
	jhat:            JoyHatEvent,                /**< Joystick hat event data */
	jbutton:         JoyButtonEvent,             /**< Joystick button event data */
	jbattery:        JoyBatteryEvent,            /**< Joystick battery event data */
	gdevice:         GamepadDeviceEvent,         /**< Gamepad device event data */
	gaxis:           GamepadAxisEvent,           /**< Gamepad axis event data */
	gbutton:         GamepadButtonEvent,         /**< Gamepad button event data */
	gtouchpad:       GamepadTouchpadEvent,       /**< Gamepad touchpad event data */
	gsensor:         GamepadSensorEvent,         /**< Gamepad sensor event data */
	adevice:         AudioDeviceEvent,           /**< Audio device event data */
	cdevice:         CameraDeviceEvent,          /**< Camera device event data */
	sensor:          SensorEvent,                /**< Sensor event data */
	quit:            QuitEvent,                  /**< Quit request event data */
	user:            UserEvent,                  /**< Custom event data */
	tfinger:         TouchFingerEvent,           /**< Touch finger event data */
	pproximity:      PenProximityEvent,          /**< Pen proximity event data */
	ptouch:          PenTouchEvent,              /**< Pen tip touching event data */
	pmotion:         PenMotionEvent,             /**< Pen motion event data */
	pbutton:         PenButtonEvent,             /**< Pen button event data */
	paxis:           PenAxisEvent,               /**< Pen axis event data */
	render:          RenderEvent,                /**< Render event data */
	drop:            DropEvent,                  /**< Drag and drop event data */
	clipboard:       ClipboardEvent,             /**< Clipboard event data */

	/* This is necessary for ABI compatibility between Visual C++ and GCC.
	   Visual C++ will respect the push pack pragma and use 52 bytes (size of
	   SDL_TextEditingEvent, the largest structure for 32-bit and 64-bit
	   architectures) for this union, and GCC will use the alignment of the
	   largest datatype within the union, which is 8 bytes on 64-bit
	   architectures.

	   So... we'll add _to force the size to be the same for both.

	   On architectures where pointers are 16 bytes, this needs rounding up to
	   the next multiple of 16, 64, and on architectures where pointers are
	   even larger the size of SDL_UserEvent will dominate as being 3 pointers.
	*/
	padding: [128]Uint8,
}


#assert(size_of(Event) == size_of(Event{}.padding))

EventAction :: enum c.int {
	ADDEVENT,  /**< Add events to the back of the queue. */
	PEEKEVENT, /**< Check but don't remove events from the queue front. */
	GETEVENT,  /**< Retrieve/remove events from the front of the queue. */
}

EventFilter :: proc "c" (userdata: rawptr, event: ^Event) -> bool


@(default_calling_convention="c", link_prefix="SDL_", require_results)
foreign lib {
	PumpEvents         :: proc() ---
	PeepEvents         :: proc(events: [^]Event, numevents: c.int, action: EventAction, minType, maxType: EventType) -> int ---
	HasEvent           :: proc(type: EventType) -> bool ---
	HasEvents          :: proc(minType, maxType: EventType) -> bool ---
	FlushEvent         :: proc(type: EventType) ---
	FlushEvents        :: proc(minType, maxType: EventType) ---
	PollEvent          :: proc(event: ^Event) -> bool ---
	WaitEvent          :: proc(event: ^Event) -> bool ---
	WaitEventTimeout   :: proc(event: ^Event, timeoutMS: Sint32) -> bool ---
	PushEvent          :: proc(event: ^Event) -> bool ---
	SetEventFilter     :: proc(filter: EventFilter, userdata: rawptr) ---
	GetEventFilter     :: proc(filter: ^EventFilter, userdata: ^rawptr) -> bool ---
	AddEventWatch      :: proc(filter: EventFilter, userdata: rawptr) -> bool ---
	RemoveEventWatch   :: proc(filter: EventFilter, userdata: rawptr) ---
	FilterEvents       :: proc(filter: EventFilter, userdata: rawptr) ---
	SetEventEnabled    :: proc(type: EventType, enabled: bool) ---
	EventEnabled       :: proc(type: EventType) -> bool ---
	RegisterEvents     :: proc(numevents: c.int) -> Uint32 ---
	GetWindowFromEvent :: proc(#by_ptr event: Event) -> ^Window ---
}