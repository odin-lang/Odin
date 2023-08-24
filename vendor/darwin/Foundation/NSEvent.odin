package objc_Foundation

@(objc_class="NSEvent")
Event :: struct {using _: Object}



EventMask :: distinct bit_set[EventType; UInteger]
EventMaskAny :: ~EventMask{}

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

/* these messages are valid for all events */

@(objc_type=Event, objc_name="type")
Event_type :: proc "c" (self: ^Event) -> EventType {
	return msgSend(EventType, self, "type")
}
@(objc_type=Event, objc_name="modifierFlags")
Event_modifierFlags :: proc "c" (self: ^Event) -> UInteger {
	return msgSend(UInteger, self, "modifierFlags")
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
