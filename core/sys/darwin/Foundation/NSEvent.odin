package objc_Foundation

@(objc_class="NSEvent")
Event :: struct {using _: Object}



EventMask    :: distinct bit_set[EventType; UInteger]
EventMaskAny :: transmute(EventMask)(max(UInteger))

when size_of(UInteger) == 4 {
	// We don't support a 32-bit darwin system but this is mostly to shut up the type checker for the time being
	EventType :: enum UInteger {
		LeftMouseDown      = 1,
		LeftMouseUp        = 2,
		RightMouseDown     = 3,
		RightMouseUp       = 4,
		MouseMoved         = 5,
		LeftMouseDragged   = 6,
		RightMouseDragged  = 7,
		MouseEntered       = 8,
		MouseExited        = 9,
		KeyDown            = 10,
		KeyUp              = 11,
		FlagsChanged       = 12,
		AppKitDefined      = 13,
		SystemDefined      = 14,
		ApplicationDefined = 15,
		Periodic           = 16,
		CursorUpdate       = 17,
		Rotate             = 18,
		BeginGesture       = 19,
		EndGesture         = 20,
		ScrollWheel        = 22,
		TabletPoint        = 23,
		TabletProximity    = 24,
		OtherMouseDown     = 25,
		OtherMouseUp       = 26,
		OtherMouseDragged  = 27,
		Gesture            = 29,
		Magnify            = 30,
		Swipe              = 31,
	}
} else {
	EventType :: enum UInteger {
		LeftMouseDown      = 1,
		LeftMouseUp        = 2,
		RightMouseDown     = 3,
		RightMouseUp       = 4,
		MouseMoved         = 5,
		LeftMouseDragged   = 6,
		RightMouseDragged  = 7,
		MouseEntered       = 8,
		MouseExited        = 9,
		KeyDown            = 10,
		KeyUp              = 11,
		FlagsChanged       = 12,
		AppKitDefined      = 13,
		SystemDefined      = 14,
		ApplicationDefined = 15,
		Periodic           = 16,
		CursorUpdate       = 17,
		Rotate             = 18,
		BeginGesture       = 19,
		EndGesture         = 20,
		ScrollWheel        = 22,
		TabletPoint        = 23,
		TabletProximity    = 24,
		OtherMouseDown     = 25,
		OtherMouseUp       = 26,
		OtherMouseDragged  = 27,
		Gesture            = 29,
		Magnify            = 30,
		Swipe              = 31,
		SmartMagnify       = 32,
		QuickLook          = 33,
		Pressure           = 34,
		DirectTouch        = 37,
		ChangeMode         = 38,
	}
}

EventPhase :: distinct bit_set[EventPhaseFlag; UInteger]
EventPhaseFlag :: enum UInteger {
	Began      = 0,
	Stationary = 1,
	Changed    = 2,
	Ended      = 3,
	Cancelled  = 4,
	MayBegin   = 5,
}
EventPhaseNone       :: EventPhase{}
EventPhaseBegan      :: EventPhase{.Began}
EventPhaseStationary :: EventPhase{.Stationary}
EventPhaseChanged    :: EventPhase{.Changed}
EventPhaseEnded      :: EventPhase{.Ended}
EventPhaseCancelled  :: EventPhase{.Cancelled}
EventPhaseMayBegin   :: EventPhase{.MayBegin}

/* pointer types for NSTabletProximity events or mouse events with subtype NSTabletProximityEventSubtype*/
PointingDeviceType :: enum UInteger {
	Unknown = 0,
	Pen     = 1,
	Cursor  = 2,
	Eraser  = 3,
}

EventModifierFlag :: enum UInteger {
	CapsLock                      = 16,
	Shift                         = 17,
	Control                       = 18,
	Option                        = 19,
	Command                       = 20,
	NumericPad                    = 21,
	Help                          = 22,
	Function                      = 23,
}

EventModifierFlags :: distinct bit_set[EventModifierFlag; UInteger]
EventModifierFlagCapsLock         :: EventModifierFlags{.CapsLock}
EventModifierFlagShift            :: EventModifierFlags{.Shift}
EventModifierFlagControl          :: EventModifierFlags{.Control}
EventModifierFlagOption           :: EventModifierFlags{.Option}
EventModifierFlagCommand          :: EventModifierFlags{.Command}
EventModifierFlagNumericPad       :: EventModifierFlags{.NumericPad}
EventModifierFlagHelp             :: EventModifierFlags{.Help}
EventModifierFlagFunction         :: EventModifierFlags{.Function}
EventModifierFlagDeviceIndependentFlagsMask : UInteger : 0xffff0000

// Defined in Carbon.framework Events.h
kVK :: enum {
	ANSI_A                    = 0x00,
	ANSI_S                    = 0x01,
	ANSI_D                    = 0x02,
	ANSI_F                    = 0x03,
	ANSI_H                    = 0x04,
	ANSI_G                    = 0x05,
	ANSI_Z                    = 0x06,
	ANSI_X                    = 0x07,
	ANSI_C                    = 0x08,
	ANSI_V                    = 0x09,
	ANSI_B                    = 0x0B,
	ANSI_Q                    = 0x0C,
	ANSI_W                    = 0x0D,
	ANSI_E                    = 0x0E,
	ANSI_R                    = 0x0F,
	ANSI_Y                    = 0x10,
	ANSI_T                    = 0x11,
	ANSI_1                    = 0x12,
	ANSI_2                    = 0x13,
	ANSI_3                    = 0x14,
	ANSI_4                    = 0x15,
	ANSI_6                    = 0x16,
	ANSI_5                    = 0x17,
	ANSI_Equal                = 0x18,
	ANSI_9                    = 0x19,
	ANSI_7                    = 0x1A,
	ANSI_Minus                = 0x1B,
	ANSI_8                    = 0x1C,
	ANSI_0                    = 0x1D,
	ANSI_RightBracket         = 0x1E,
	ANSI_O                    = 0x1F,
	ANSI_U                    = 0x20,
	ANSI_LeftBracket          = 0x21,
	ANSI_I                    = 0x22,
	ANSI_P                    = 0x23,
	ANSI_L                    = 0x25,
	ANSI_J                    = 0x26,
	ANSI_Quote                = 0x27,
	ANSI_K                    = 0x28,
	ANSI_Semicolon            = 0x29,
	ANSI_Backslash            = 0x2A,
	ANSI_Comma                = 0x2B,
	ANSI_Slash                = 0x2C,
	ANSI_N                    = 0x2D,
	ANSI_M                    = 0x2E,
	ANSI_Period               = 0x2F,
	ANSI_Grave                = 0x32,
	ANSI_KeypadDecimal        = 0x41,
	ANSI_KeypadMultiply       = 0x43,
	ANSI_KeypadPlus           = 0x45,
	ANSI_KeypadClear          = 0x47,
	ANSI_KeypadDivide         = 0x4B,
	ANSI_KeypadEnter          = 0x4C,
	ANSI_KeypadMinus          = 0x4E,
	ANSI_KeypadEquals         = 0x51,
	ANSI_Keypad0              = 0x52,
	ANSI_Keypad1              = 0x53,
	ANSI_Keypad2              = 0x54,
	ANSI_Keypad3              = 0x55,
	ANSI_Keypad4              = 0x56,
	ANSI_Keypad5              = 0x57,
	ANSI_Keypad6              = 0x58,
	ANSI_Keypad7              = 0x59,
	ANSI_Keypad8              = 0x5B,
	ANSI_Keypad9              = 0x5C,
	Return                    = 0x24,
	Tab                       = 0x30,
	Space                     = 0x31,
	Delete                    = 0x33,
	Escape                    = 0x35,
	Command                   = 0x37,
	Shift                     = 0x38,
	CapsLock                  = 0x39,
	Option                    = 0x3A,
	Control                   = 0x3B,
	RightCommand              = 0x36,
	RightShift                = 0x3C,
	RightOption               = 0x3D,
	RightControl              = 0x3E,
	Function                  = 0x3F,
	F17                       = 0x40,
	VolumeUp                  = 0x48,
	VolumeDown                = 0x49,
	Mute                      = 0x4A,
	F18                       = 0x4F,
	F19                       = 0x50,
	F20                       = 0x5A,
	F5                        = 0x60,
	F6                        = 0x61,
	F7                        = 0x62,
	F3                        = 0x63,
	F8                        = 0x64,
	F9                        = 0x65,
	F11                       = 0x67,
	F13                       = 0x69,
	F16                       = 0x6A,
	F14                       = 0x6B,
	F10                       = 0x6D,
	F12                       = 0x6F,
	F15                       = 0x71,
	Help                      = 0x72,
	Home                      = 0x73,
	PageUp                    = 0x74,
	ForwardDelete             = 0x75,
	F4                        = 0x76,
	End                       = 0x77,
	F2                        = 0x78,
	PageDown                  = 0x79,
	F1                        = 0x7A,
	LeftArrow                 = 0x7B,
	RightArrow                = 0x7C,
	DownArrow                 = 0x7D,
	UpArrow                   = 0x7E,
	JIS_Yen                   = 0x5D,
	JIS_Underscore            = 0x5E,
	JIS_KeypadComma           = 0x5F,
	JIS_Eisu                  = 0x66,
	JIS_Kana                  = 0x68,
	ISO_Section               = 0x0A,
}


/* these messages are valid for all events */

@(objc_type=Event, objc_name="type")
Event_type :: proc "c" (self: ^Event) -> EventType {
	return msgSend(EventType, self, "type")
}
@(objc_type=Event, objc_name="modifierFlags")
Event_modifierFlags :: proc "c" (self: ^Event) -> EventModifierFlags {
	return msgSend(EventModifierFlags, self, "modifierFlags")
}
@(objc_type=Event, objc_name="timestamp")
Event_timestamp :: proc "c" (self: ^Event) -> TimeInterval {
	return msgSend(TimeInterval, self, "timestamp")
}
@(objc_type=Event, objc_name="window")
Event_window :: proc "c" (self: ^Event) -> ^Window {
	return msgSend(^Window, self, "window")
}
@(objc_type=Event, objc_name="windowNumber")
Event_windowNumber :: proc "c" (self: ^Event) -> UInteger {
	return msgSend(UInteger, self, "windowNumber")
}

/* these messages are valid for all mouse down/up/drag events */

@(objc_type=Event, objc_name="clickCount")
Event_clickCount :: proc "c" (self: ^Event) -> Integer {
	return msgSend(Integer, self, "clickCount")
}

// for NSOtherMouse events, but will return valid constants for NSLeftMouse and NSRightMouse
@(objc_type=Event, objc_name="buttonNumber")
Event_buttonNumber :: proc "c" (self: ^Event) -> Integer {
	return msgSend(Integer, self, "buttonNumber")
}

/* these messages are valid for all mouse down/up/drag and enter/exit events */
@(objc_type=Event, objc_name="eventNumber")
Event_eventNumber :: proc "c" (self: ^Event) -> Integer {
	return msgSend(Integer, self, "eventNumber")
}

/* -pressure is valid for all mouse down/up/drag events, and is also valid for NSTabletPoint events on 10.4 or later */
@(objc_type=Event, objc_name="pressure")
Event_pressure :: proc "c" (self: ^Event) -> f32 {
	return msgSend(f32, self, "pressure")
}

/* -locationInWindow is valid for all mouse-related events */
@(objc_type=Event, objc_name="locationInWindow")
Event_locationInWindow :: proc "c" (self: ^Event) -> Point {
	return msgSend(Point, self, "locationInWindow")
}


@(objc_type=Event, objc_name="deltaX")
Event_deltaX :: proc "c" (self: ^Event) -> Float {
	return msgSend(Float, self, "deltaX")
}
@(objc_type=Event, objc_name="deltaY")
Event_deltaY :: proc "c" (self: ^Event) -> Float {
	return msgSend(Float, self, "deltaY")
}
@(objc_type=Event, objc_name="deltaZ")
Event_deltaZ :: proc "c" (self: ^Event) -> Float {
	return msgSend(Float, self, "deltaZ")
}
@(objc_type=Event, objc_name="delta")
Event_delta :: proc "c" (self: ^Event) -> (x, y, z: Float) {
	x = self->deltaX()
	y = self->deltaY()
	z = self->deltaZ()
	return
}

@(objc_type=Event, objc_name="hasPreciseScrollingDeltas")
Event_hasPreciseScrollingDeltas :: proc "c" (self: ^Event) -> BOOL {
	return msgSend(BOOL, self, "hasPreciseScrollingDeltas")
}


@(objc_type=Event, objc_name="scrollingDeltaX")
Event_scrollingDeltaX :: proc "c" (self: ^Event) -> Float {
	return msgSend(Float, self, "scrollingDeltaX")
}
@(objc_type=Event, objc_name="scrollingDeltaY")
Event_scrollingDeltaY :: proc "c" (self: ^Event) -> Float {
	return msgSend(Float, self, "scrollingDeltaY")
}
@(objc_type=Event, objc_name="scrollingDelta")
Event_scrollingDelta :: proc "c" (self: ^Event) -> (x, y: Float) {
	x = self->scrollingDeltaX()
	y = self->scrollingDeltaY()
	return
}



@(objc_type=Event, objc_name="momentumPhase")
Event_momentumPhase :: proc "c" (self: ^Event) -> EventPhase {
	return msgSend(EventPhase, self, "momentumPhase")
}
@(objc_type=Event, objc_name="phase")
Event_phase :: proc "c" (self: ^Event) -> EventPhase {
	return msgSend(EventPhase, self, "phase")
}


@(objc_type=Event, objc_name="isDirectionInvertedFromDevice")
Event_isDirectionInvertedFromDevice :: proc "c" (self: ^Event) -> BOOL {
	return msgSend(BOOL, self, "isDirectionInvertedFromDevice")
}

@(objc_type=Event, objc_name="characters")
Event_characters :: proc "c" (self: ^Event) -> ^String {
	return msgSend(^String, self, "characters")
}
@(objc_type=Event, objc_name="charactersIgnoringModifiers")
Event_charactersIgnoringModifiers :: proc "c" (self: ^Event) -> ^String {
	return msgSend(^String, self, "charactersIgnoringModifiers")
}
@(objc_type=Event, objc_name="isARepeat")
Event_isARepeat :: proc "c" (self: ^Event) -> BOOL {
	return msgSend(BOOL, self, "isARepeat")
}

@(objc_type=Event, objc_name="keyCode")
Event_keyCode :: proc "c" (self: ^Event) -> u16 {
	return msgSend(u16, self, "keyCode")
}

@(objc_type=Event, objc_name="subtype")
Event_subtype :: proc "c" (self: ^Event) -> i16 {
	return msgSend(i16, self, "subtype")
}

@(objc_type=Event, objc_name="data1")
Event_data1 :: proc "c" (self: ^Event) -> Integer {
	return msgSend(Integer, self, "data1")
}
@(objc_type=Event, objc_name="data2")
Event_data2 :: proc "c" (self: ^Event) -> Integer {
	return msgSend(Integer, self, "data2")
}


@(objc_type=Event, objc_name="absoluteX")
Event_absoluteX :: proc "c" (self: ^Event) -> Integer {
	return msgSend(Integer, self, "absoluteX")
}
@(objc_type=Event, objc_name="absoluteY")
Event_absoluteY :: proc "c" (self: ^Event) -> Integer {
	return msgSend(Integer, self, "absoluteY")
}
@(objc_type=Event, objc_name="absoluteZ")
Event_absoluteZ :: proc "c" (self: ^Event) -> Integer {
	return msgSend(Integer, self, "absoluteZ")
}

@(objc_type=Event, objc_name="absolute")
Event_absolute :: proc "c" (self: ^Event) -> (x, y, z: Integer) {
	x = self->absoluteX()
	y = self->absoluteY()
	z = self->absoluteZ()
	return
}


@(objc_type=Event, objc_name="buttonMask")
Event_buttonMask :: proc "c" (self: ^Event) -> UInteger {
	return msgSend(UInteger, self, "buttonMask")
}

@(objc_type=Event, objc_name="tilt")
tilt :: proc "c" (self: ^Event) -> Point {
	return msgSend(Point, self, "tilt")
}

@(objc_type=Event, objc_name="tangentialPressure")
Event_tangentialPressure :: proc "c" (self: ^Event) -> f32 {
	return msgSend(f32, self, "tangentialPressure")
}

@(objc_type=Event, objc_name="vendorDefined")
Event_vendorDefined :: proc "c" (self: ^Event) -> id {
	return msgSend(id, self, "vendorDefined")
}


@(objc_type=Event, objc_name="vendorID")
Event_vendorID :: proc "c" (self: ^Event) -> UInteger {
	return msgSend(UInteger, self, "vendorID")
}
@(objc_type=Event, objc_name="tabletID")
Event_tabletID :: proc "c" (self: ^Event) -> UInteger {
	return msgSend(UInteger, self, "tabletID")
}
@(objc_type=Event, objc_name="pointingDeviceID")
Event_pointingDeviceID :: proc "c" (self: ^Event) -> UInteger {
	return msgSend(UInteger, self, "pointingDeviceID")
}
@(objc_type=Event, objc_name="systemTabletID")
Event_systemTabletID :: proc "c" (self: ^Event) -> UInteger {
	return msgSend(UInteger, self, "systemTabletID")
}
@(objc_type=Event, objc_name="vendorPointingDeviceType")
Event_vendorPointingDeviceType :: proc "c" (self: ^Event) -> UInteger {
	return msgSend(UInteger, self, "vendorPointingDeviceType")
}
@(objc_type=Event, objc_name="pointingDeviceSerialNumber")
Event_pointingDeviceSerialNumber :: proc "c" (self: ^Event) -> UInteger {
	return msgSend(UInteger, self, "pointingDeviceSerialNumber")
}
@(objc_type=Event, objc_name="uniqueID")
Event_uniqueID :: proc "c" (self: ^Event) -> u64 {
	return msgSend(u64, self, "uniqueID")
}
@(objc_type=Event, objc_name="capabilityMask")
Event_capabilityMask :: proc "c" (self: ^Event) -> UInteger {
	return msgSend(UInteger, self, "capabilityMask")
}
@(objc_type=Event, objc_name="pointingDeviceType")
Event_pointingDeviceType :: proc "c" (self: ^Event) -> PointingDeviceType {
	return msgSend(PointingDeviceType, self, "pointingDeviceType")
}
@(objc_type=Event, objc_name="isEnteringProximity")
Event_isEnteringProximity :: proc "c" (self: ^Event) -> BOOL {
	return msgSend(BOOL, self, "isEnteringProximity")
}


@(objc_type=Event, objc_name="isSwipeTrackingFromScrollEventsEnabled")
Event_isSwipeTrackingFromScrollEventsEnabled :: proc "c" (self: ^Event) -> BOOL {
	return msgSend(BOOL, self, "isSwipeTrackingFromScrollEventsEnabled")
}
