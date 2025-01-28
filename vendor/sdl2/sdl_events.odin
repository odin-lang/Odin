package sdl2

import "core:c"

when ODIN_OS == .Windows {
	@(ignore_duplicates)
	foreign import lib "SDL2.lib"
} else {
	@(ignore_duplicates)
	foreign import lib "system:SDL2"
}

RELEASED :: 0
PRESSED  :: 1

EventType :: enum u32 {
	FIRSTEVENT     = 0,     /**< Unused (do not remove) */

	/* Application events */
	QUIT           = 0x100, /**< User-requested quit */

	/* These application events have special meaning on iOS, see README-ios.md for details */
	APP_TERMINATING,        /**< The application is being terminated by the OS
	                             Called on iOS in applicationWillTerminate()
	                             Called on Android in onDestroy()
	                        */
	APP_LOWMEMORY,          /**< The application is low on memory, free memory if possible.
	                             Called on iOS in applicationDidReceiveMemoryWarning()
	                             Called on Android in onLowMemory()
	                        */
	APP_WILLENTERBACKGROUND, /**< The application is about to enter the background
	                             Called on iOS in applicationWillResignActive()
	                             Called on Android in onPause()
	                        */
	APP_DIDENTERBACKGROUND, /**< The application did enter the background and may not get CPU for some time
	                             Called on iOS in applicationDidEnterBackground()
	                             Called on Android in onPause()
	                        */
	APP_WILLENTERFOREGROUND, /**< The application is about to enter the foreground
	                             Called on iOS in applicationWillEnterForeground()
	                             Called on Android in onResume()
	                        */
	APP_DIDENTERFOREGROUND, /**< The application is now interactive
	                             Called on iOS in applicationDidBecomeActive()
	                             Called on Android in onResume()
	                        */

	LOCALECHANGED,  /**< The user's locale preferences have changed. */

	/* Display events */
	DISPLAYEVENT   = 0x150,  /**< Display state change */

	/* Window events */
	WINDOWEVENT    = 0x200, /**< Window state change */
	SYSWMEVENT,             /**< System specific event */

	/* Keyboard events */
	KEYDOWN        = 0x300, /**< Key pressed */
	KEYUP,                  /**< Key released */
	TEXTEDITING,            /**< Keyboard text editing (composition) */
	TEXTINPUT,              /**< Keyboard text input */
	KEYMAPCHANGED,          /**< Keymap changed due to a system event such as an
	                             input language or keyboard layout change.
	                        */

	/* Mouse events */
	MOUSEMOTION    = 0x400, /**< Mouse moved */
	MOUSEBUTTONDOWN,        /**< Mouse button pressed */
	MOUSEBUTTONUP,          /**< Mouse button released */
	MOUSEWHEEL,             /**< Mouse wheel motion */

	/* Joystick events */
	JOYAXISMOTION  = 0x600, /**< Joystick axis motion */
	JOYBALLMOTION,          /**< Joystick trackball motion */
	JOYHATMOTION,           /**< Joystick hat position change */
	JOYBUTTONDOWN,          /**< Joystick button pressed */
	JOYBUTTONUP,            /**< Joystick button released */
	JOYDEVICEADDED,         /**< A new joystick has been inserted into the system */
	JOYDEVICEREMOVED,       /**< An opened joystick has been removed */

	/* Game controller events */
	CONTROLLERAXISMOTION  = 0x650, /**< Game controller axis motion */
	CONTROLLERBUTTONDOWN,          /**< Game controller button pressed */
	CONTROLLERBUTTONUP,            /**< Game controller button released */
	CONTROLLERDEVICEADDED,         /**< A new Game controller has been inserted into the system */
	CONTROLLERDEVICEREMOVED,       /**< An opened Game controller has been removed */
	CONTROLLERDEVICEREMAPPED,      /**< The controller mapping was updated */
	CONTROLLERTOUCHPADDOWN,        /**< Game controller touchpad was touched */
	CONTROLLERTOUCHPADMOTION,      /**< Game controller touchpad finger was moved */
	CONTROLLERTOUCHPADUP,          /**< Game controller touchpad finger was lifted */
	CONTROLLERSENSORUPDATE,        /**< Game controller sensor was updated */

	/* Touch events */
	FINGERDOWN      = 0x700,
	FINGERUP,
	FINGERMOTION,

	/* Gesture events */
	DOLLARGESTURE   = 0x800,
	DOLLARRECORD,
	MULTIGESTURE,

	/* Clipboard events */
	CLIPBOARDUPDATE = 0x900, /**< The clipboard changed */

	/* Drag and drop events */
	DROPFILE        = 0x1000, /**< The system requests a file open */
	DROPTEXT,                 /**< text/plain drag-and-drop event */
	DROPBEGIN,                /**< A new set of drops is beginning (NULL filename) */
	DROPCOMPLETE,             /**< Current set of drops is now complete (NULL filename) */

	/* Audio hotplug events */
	AUDIODEVICEADDED = 0x1100, /**< A new audio device is available */
	AUDIODEVICEREMOVED,        /**< An audio device has been removed. */

	/* Sensor events */
	SENSORUPDATE = 0x1200,     /**< A sensor was updated */

	/* Render events */
	RENDER_TARGETS_RESET = 0x2000, /**< The render targets have been reset and their contents need to be updated */
	RENDER_DEVICE_RESET, /**< The device has been reset and all textures need to be recreated */

	/** Events ::SDL_USEREVENT through ::SDL_LASTEVENT are for your use,
	*  and should be allocated with SDL_RegisterEvents()
	*/
	USEREVENT    = 0x8000,

	/**
	*  This last event is only for bounding internal arrays
	*/
	LASTEVENT    = 0xFFFF,
}

CommonEvent :: struct {
	type: EventType,
	timestamp: u32,   /**< In milliseconds, populated using SDL_GetTicks() */
}

DisplayEvent :: struct {
	type: EventType,           /**< ::SDL_DISPLAYEVENT */
	timestamp: u32,            /**< In milliseconds, populated using SDL_GetTicks() */
	display:   u32,            /**< The associated display index */
	event:     DisplayEventID, /**< ::SDL_DisplayEventID */
	_:  u8,
	_:  u8,
	_:  u8,
	data1:     i32,  /**< event dependent data */
}

WindowEvent :: struct {
	type: EventType,          /**< ::SDL_WINDOWEVENT */
	timestamp: u32,           /**< In milliseconds, populated using SDL_GetTicks() */
	windowID:  u32,           /**< The associated window */
	event:     WindowEventID, /**< ::SDL_WindowEventID */
	_:  u8,
	_:  u8,
	_:  u8,
	data1:     i32,  /**< event dependent data */
	data2:     i32,  /**< event dependent data */
}

KeyboardEvent :: struct {
	type: EventType,  /**< ::SDL_KEYDOWN or ::SDL_KEYUP */
	timestamp: u32,   /**< In milliseconds, populated using SDL_GetTicks() */
	windowID:  u32,   /**< The window with keyboard focus, if any */
	state:     u8,    /**< ::SDL_PRESSED or ::SDL_RELEASED */
	repeat:    u8,    /**< Non-zero if this is a key repeat */
	_: u8,
	_: u8,
	keysym: Keysym,   /**< The key that was pressed or released */
}

TEXTEDITINGEVENT_TEXT_SIZE :: 32
TextEditingEvent :: struct {
	type: EventType,                                /**< ::SDL_TEXTEDITING */
	timestamp: u32,                           /**< In milliseconds, populated using SDL_GetTicks() */
	windowID: u32,                            /**< The window with keyboard focus, if any */
	text: [TEXTEDITINGEVENT_TEXT_SIZE]u8,  /**< The editing text */
	start: i32,                               /**< The start cursor of selected editing text */
	length: i32,                              /**< The length of selected editing text */
}


TEXTINPUTEVENT_TEXT_SIZE :: 32
TextInputEvent :: struct {
	type: EventType,                              /**< ::SDL_TEXTINPUT */
	timestamp: u32,                         /**< In milliseconds, populated using SDL_GetTicks() */
	windowID: u32,                          /**< The window with keyboard focus, if any */
	text: [TEXTINPUTEVENT_TEXT_SIZE]u8,  /**< The input text */
}

MouseMotionEvent :: struct {
	type: EventType, /**< ::SDL_MOUSEMOTION */
	timestamp: u32,  /**< In milliseconds, populated using SDL_GetTicks() */
	windowID:  u32,  /**< The window with mouse focus, if any */
	which:     u32,  /**< The mouse instance id, or SDL_TOUCH_MOUSEID */
	state:     u32,  /**< The current button state */
	x:         i32,  /**< X coordinate, relative to window */
	y:         i32,  /**< Y coordinate, relative to window */
	xrel:      i32,  /**< The relative motion in the X direction */
	yrel:      i32,  /**< The relative motion in the Y direction */
}

MouseButtonEvent :: struct {
	type: EventType,        /**< ::SDL_MOUSEBUTTONDOWN or ::SDL_MOUSEBUTTONUP */
	timestamp: u32,   /**< In milliseconds, populated using SDL_GetTicks() */
	windowID: u32,    /**< The window with mouse focus, if any */
	which: u32,       /**< The mouse instance id, or SDL_TOUCH_MOUSEID */
	button: u8,       /**< The mouse button index */
	state: u8,        /**< ::SDL_PRESSED or ::SDL_RELEASED */
	clicks: u8,       /**< 1 for single-click, 2 for double-click, etc. */
	_: u8,
	x: i32,           /**< X coordinate, relative to window */
	y: i32,           /**< Y coordinate, relative to window */
}

MouseWheelEvent :: struct {
	type: EventType,        /**< ::SDL_MOUSEWHEEL */
	timestamp: u32,   /**< In milliseconds, populated using SDL_GetTicks() */
	windowID: u32,    /**< The window with mouse focus, if any */
	which: u32,       /**< The mouse instance id, or SDL_TOUCH_MOUSEID */
	x: i32,           /**< The amount scrolled horizontally, positive to the right and negative to the left */
	y: i32,           /**< The amount scrolled vertically, positive away from the user and negative toward the user */
	direction: u32,   /**< Set to one of the SDL_MOUSEWHEEL_* defines. When FLIPPED the values in X and Y will be opposite. Multiply by -1 to change them back */
}

JoyAxisEvent :: struct {
	type: EventType,        /**< ::SDL_JOYAXISMOTION */
	timestamp: u32,   /**< In milliseconds, populated using SDL_GetTicks() */
	which: JoystickID, /**< The joystick instance id */
	axis: u8,         /**< The joystick axis index */
	_: u8,
	_: u8,
	_: u8,
	value: i16,       /**< The axis value (range: -32768 to 32767) */
	_: u16,
}

JoyBallEvent :: struct {
	type: EventType,        /**< ::SDL_JOYBALLMOTION */
	timestamp: u32,   /**< In milliseconds, populated using SDL_GetTicks() */
	which: JoystickID, /**< The joystick instance id */
	ball: u8,         /**< The joystick trackball index */
	_: u8,
	_: u8,
	_: u8,
	xrel: i16,        /**< The relative motion in the X direction */
	yrel: i16,        /**< The relative motion in the Y direction */
}

JoyHatEvent :: struct {
	type: EventType,        /**< ::SDL_JOYHATMOTION */
	timestamp: u32,   /**< In milliseconds, populated using SDL_GetTicks() */
	which: JoystickID, /**< The joystick instance id */
	hat: u8,          /**< The joystick hat index */
	value: u8,        /**< The hat position value.
	                 *   \sa ::SDL_HAT_LEFTUP ::SDL_HAT_UP ::SDL_HAT_RIGHTUP
	                 *   \sa ::SDL_HAT_LEFT ::SDL_HAT_CENTERED ::SDL_HAT_RIGHT
	                 *   \sa ::SDL_HAT_LEFTDOWN ::SDL_HAT_DOWN ::SDL_HAT_RIGHTDOWN
	                 *
	                 *   Note that zero means the POV is centered.
	                 */
	_: u8,
	_: u8,
}

JoyButtonEvent :: struct {
	type: EventType,        /**< ::SDL_JOYBUTTONDOWN or ::SDL_JOYBUTTONUP */
	timestamp: u32,   /**< In milliseconds, populated using SDL_GetTicks() */
	which: JoystickID, /**< The joystick instance id */
	button: u8,       /**< The joystick button index */
	state: u8,        /**< ::SDL_PRESSED or ::SDL_RELEASED */
	_: u8,
	_: u8,
}

JoyDeviceEvent :: struct {
	type: EventType,        /**< ::SDL_JOYDEVICEADDED or ::SDL_JOYDEVICEREMOVED */
	timestamp: u32,   /**< In milliseconds, populated using SDL_GetTicks() */
	which: i32,       /**< The joystick device index for the ADDED event, instance id for the REMOVED event */
}


ControllerAxisEvent :: struct {
	type: EventType,        /**< ::SDL_CONTROLLERAXISMOTION */
	timestamp: u32,   /**< In milliseconds, populated using SDL_GetTicks() */
	which:     JoystickID, /**< The joystick instance id */
	axis:      u8,         /**< The controller axis (SDL_GameControllerAxis) */
	_:         u8,
	_:         u8,
	_:         u8,
	value:     i16,       /**< The axis value (range: -32768 to 32767) */
	_:  u16,
}


ControllerButtonEvent :: struct {
	type: EventType,        /**< ::SDL_CONTROLLERBUTTONDOWN or ::SDL_CONTROLLERBUTTONUP */
	timestamp: u32,   /**< In milliseconds, populated using SDL_GetTicks() */
	which: JoystickID, /**< The joystick instance id */
	button: u8,       /**< The controller button (SDL_GameControllerButton) */
	state: u8,        /**< ::SDL_PRESSED or ::SDL_RELEASED */
	_: u8,
	_: u8,
}


ControllerDeviceEvent :: struct {
	type: EventType,        /**< ::SDL_CONTROLLERDEVICEADDED, ::SDL_CONTROLLERDEVICEREMOVED, or ::SDL_CONTROLLERDEVICEREMAPPED */
	timestamp: u32,   /**< In milliseconds, populated using SDL_GetTicks() */
	which:     i32,       /**< The joystick device index for the ADDED event, instance id for the REMOVED or REMAPPED event */
}

ControllerTouchpadEvent :: struct {
	type: EventType,        /**< ::SDL_CONTROLLERTOUCHPADDOWN or ::SDL_CONTROLLERTOUCHPADMOTION or ::SDL_CONTROLLERTOUCHPADUP */
	timestamp: u32,   /**< In milliseconds, populated using SDL_GetTicks() */
	which:     JoystickID, /**< The joystick instance id */
	touchpad:  i32,    /**< The index of the touchpad */
	finger:    i32,      /**< The index of the finger on the touchpad */
	x:         f32,            /**< Normalized in the range 0...1 with 0 being on the left */
	y:         f32,            /**< Normalized in the range 0...1 with 0 being at the top */
	pressure:  f32,     /**< Normalized in the range 0...1 */
}

ControllerSensorEvent :: struct {
	type: EventType,        /**< ::SDL_CONTROLLERSENSORUPDATE */
	timestamp: u32,   /**< In milliseconds, populated using SDL_GetTicks() */
	which:     JoystickID, /**< The joystick instance id */
	sensor:    i32,      /**< The type of the sensor, one of the values of ::SDL_SensorType */
	data:      [3]f32,      /**< Up to 3 values from the sensor, as defined in SDL_sensor.h */
}

AudioDeviceEvent :: struct {
	type: EventType,        /**< ::SDL_AUDIODEVICEADDED, or ::SDL_AUDIODEVICEREMOVED */
	timestamp: u32,   /**< In milliseconds, populated using SDL_GetTicks() */
	which:     u32,       /**< The audio device index for the ADDED event (valid until next SDL_GetNumAudioDevices() call), SDL_AudioDeviceID for the REMOVED event */
	iscapture: u8,    /**< zero if an output device, non-zero if a capture device. */
	_:         u8,
	_:         u8,
	_:         u8,
}


TouchFingerEvent :: struct {
	type: EventType,    /**< ::SDL_FINGERMOTION or ::SDL_FINGERDOWN or ::SDL_FINGERUP */
	timestamp: u32,     /**< In milliseconds, populated using SDL_GetTicks() */
	touchId:   TouchID, /**< The touch device id */
	fingerId:  FingerID,
	x:         f32,     /**< Normalized in the range 0...1 */
	y:         f32,     /**< Normalized in the range 0...1 */
	dx:        f32,     /**< Normalized in the range -1...1 */
	dy:        f32,     /**< Normalized in the range -1...1 */
	pressure:  f32,     /**< Normalized in the range 0...1 */
	windowID:  u32,     /**< The window underneath the finger, if any */
}


MultiGestureEvent :: struct {
	type: EventType,     /**< ::SDL_MULTIGESTURE */
	timestamp:  u32,     /**< In milliseconds, populated using SDL_GetTicks() */
	touchId:    TouchID, /**< The touch device id */
	dTheta:     f32,
	dDist:      f32,
	x:          f32,
	y:          f32,
	numFingers: u16,
	padding:    u16,
}


/**
 * \brief Dollar Gesture Event (event.dgesture.*)
 */
DollarGestureEvent :: struct {
	type: EventType,       /**< ::SDL_DOLLARGESTURE or ::SDL_DOLLARRECORD */
	timestamp:  u32,       /**< In milliseconds, populated using SDL_GetTicks() */
	touchId:    TouchID,   /**< The touch device id */
	gestureId:  GestureID,
	numFingers: u32,
	error:      f32,
	x:          f32,       /**< Normalized center of gesture */
	y:          f32,       /**< Normalized center of gesture */
}


DropEvent :: struct {
	type: EventType,        /**< ::SDL_DROPBEGIN or ::SDL_DROPFILE or ::SDL_DROPTEXT or ::SDL_DROPCOMPLETE */
	timestamp: u32,   /**< In milliseconds, populated using SDL_GetTicks() */
	file:      cstring,         /**< The file name, which should be freed with SDL_free(), is NULL on begin/complete */
	windowID:  u32,    /**< The window that was dropped on, if any */
}


SensorEvent :: struct {
	type: EventType,        /**< ::SDL_SENSORUPDATE */
	timestamp: u32,   /**< In milliseconds, populated using SDL_GetTicks() */
	which:     i32,       /**< The instance ID of the sensor */
	data:      [6]f32,      /**< Up to 6 values from the sensor - additional values can be queried using SDL_SensorGetData() */
}

QuitEvent :: struct {
	type: EventType,        /**< ::SDL_QUIT */
	timestamp: u32,   /**< In milliseconds, populated using SDL_GetTicks() */
}

OSEvent :: struct {
	type: EventType,        /**< ::SDL_QUIT */
	timestamp: u32,   /**< In milliseconds, populated using SDL_GetTicks() */
}

UserEvent :: struct {
	type: EventType,   /**< ::SDL_USEREVENT through ::SDL_LASTEVENT-1 */
	timestamp: u32,    /**< In milliseconds, populated using SDL_GetTicks() */
	windowID:  u32,    /**< The associated window if any */
	code:      i32,    /**< User defined event code */
	data1:     rawptr, /**< User defined data pointer */
	data2:     rawptr, /**< User defined data pointer */
}


SysWMEvent :: struct {
	type: EventType,     /**< ::SDL_SYSWMEVENT */
	timestamp: u32,      /**< In milliseconds, populated using SDL_GetTicks() */
	msg:      ^SysWMmsg, /**< driver dependent data, defined in SDL_syswm.h */
}

Event :: struct #raw_union {
	type:      EventType,               /**< Event type, shared with all events */
	common:    CommonEvent,             /**< Common event data */
	display:   DisplayEvent,            /**< Display event data */
	window:    WindowEvent,             /**< Window event data */
	key:       KeyboardEvent,           /**< Keyboard event data */
	edit:      TextEditingEvent,        /**< Text editing event data */
	text:      TextInputEvent,          /**< Text input event data */
	motion:    MouseMotionEvent,        /**< Mouse motion event data */
	button:    MouseButtonEvent,        /**< Mouse button event data */
	wheel:     MouseWheelEvent,         /**< Mouse wheel event data */
	jaxis:     JoyAxisEvent,            /**< Joystick axis event data */
	jball:     JoyBallEvent,            /**< Joystick ball event data */
	jhat:      JoyHatEvent,             /**< Joystick hat event data */
	jbutton:   JoyButtonEvent,          /**< Joystick button event data */
	jdevice:   JoyDeviceEvent,          /**< Joystick device change event data */
	caxis:     ControllerAxisEvent,     /**< Game Controller axis event data */
	cbutton:   ControllerButtonEvent,   /**< Game Controller button event data */
	cdevice:   ControllerDeviceEvent,   /**< Game Controller device event data */
	ctouchpad: ControllerTouchpadEvent, /**< Game Controller touchpad event data */
	csensor:   ControllerSensorEvent,   /**< Game Controller sensor event data */
	adevice:   AudioDeviceEvent,        /**< Audio device event data */
	sensor:    SensorEvent,             /**< Sensor event data */
	quit:      QuitEvent,               /**< Quit request event data */
	user:      UserEvent,               /**< Custom event data */
	syswm:     SysWMEvent,              /**< System dependent window event data */
	tfinger:   TouchFingerEvent,        /**< Touch finger event data */
	mgesture:  MultiGestureEvent,       /**< Gesture event data */
	dgesture:  DollarGestureEvent,      /**< Gesture event data */
	drop:      DropEvent,               /**< Drag and drop event data */

	padding: [56 when size_of(rawptr) <= 8 else 64 when size_of(rawptr) == 16 else 3 * size_of(rawptr)]u8,
}



/* Make sure we haven't broken binary compatibility */
#assert(size_of(Event) == size_of(Event{}.padding))



eventaction :: enum c.int {
	ADDEVENT,
	PEEKEVENT,
	GETEVENT,
}

EventFilter :: proc "c" (userdata: rawptr, event: ^Event) -> c.int

QUERY   :: -1
IGNORE  ::  0
DISABLE ::  0
ENABLE  ::  1


GetEventState :: #force_inline proc "c" (type: EventType) -> b8 { return EventState(type, QUERY) }


@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	PumpEvents       :: proc() ---
	PeepEvents       :: proc(events: [^]Event, numevents: c.int, action: eventaction, minType, maxType: EventType) -> c.int ---
	HasEvent         :: proc(type: EventType) -> bool ---
	HasEvents        :: proc(minType, maxType: EventType) -> bool ---
	FlushEvent       :: proc(type: EventType) ---
	FlushEvents      :: proc(minType, maxType: EventType) ---
	PollEvent        :: proc(event: ^Event) -> bool ---                 // original return value is c.int
	WaitEvent        :: proc(event: ^Event) -> bool ---                 // original return value is c.int
	WaitEventTimeout :: proc(event: ^Event, timeout: c.int) -> bool --- // original return value is c.int
	PushEvent        :: proc(event: ^Event) -> bool ---                 // original return value is c.int
	SetEventFilter   :: proc(filter: EventFilter, userdata: rawptr) ---
	GetEventFilter   :: proc(filter: ^EventFilter, userdata: ^rawptr) -> bool ---
	AddEventWatch    :: proc(filter: EventFilter, userdata: rawptr) ---
	DelEventWatch    :: proc(filter: EventFilter, userdata: rawptr) ---
	FilterEvents     :: proc(filter: EventFilter, userdata: rawptr) ---
	EventState       :: proc(type: EventType, state: c.int) -> b8 --- // original return value is u8
	RegisterEvents   :: proc(numevents: c.int) -> u32 ---
}
