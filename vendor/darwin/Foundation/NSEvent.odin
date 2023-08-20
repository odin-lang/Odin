package objc_Foundation

@(objc_class = "NSEvent")
Event :: struct {
	using _: Object,
}

@(objc_type = Event, objc_name = "type")
Event_type :: proc "c" (self: ^Event) -> EventType {
	return msgSend(EventType, self, "type")
}


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

EventTypeMask :: enum UInteger {
	Any                = UIntegerMax,
	LeftMouseDown      = 1 << u64(EventType.LeftMouseDown),
	LeftMouseDragged   = 1 << u64(EventType.LeftMouseDragged),
	RightMouseDown     = 1 << u64(EventType.RightMouseDown),
	RightMouseUp       = 1 << u64(EventType.RightMouseUp),
	MouseMoved         = 1 << u64(EventType.MouseMoved),
	RightMouseDragged  = 1 << u64(EventType.RightMouseDragged),
	MouseEntered       = 1 << u64(EventType.MouseEntered),
	MouseExited        = 1 << u64(EventType.MouseExited),
	KeyDown            = 1 << u64(EventType.KeyDown),
	KeyUp              = 1 << u64(EventType.KeyUp),
	FlagsChanged       = 1 << u64(EventType.FlagsChanged),
	AppKitDefined      = 1 << u64(EventType.AppKitDefined),
	SystemDefined      = 1 << u64(EventType.SystemDefined),
	ApplicationDefined = 1 << u64(EventType.ApplicationDefined),
	Periodic           = 1 << u64(EventType.Periodic),
	CursorUpdate       = 1 << u64(EventType.CursorUpdate),
	Rotate             = 1 << u64(EventType.Rotate),
	BeginGesture       = 1 << u64(EventType.BeginGesture),
	EndGesture         = 1 << u64(EventType.EndGesture),
	ScrollWheel        = 1 << u64(EventType.ScrollWheel),
	TabletPoint        = 1 << u64(EventType.TabletPoint),
	TabletProximity    = 1 << u64(EventType.TabletProximity),
	OtherMouseDown     = 1 << u64(EventType.OtherMouseDown),
	OtherMouseUp       = 1 << u64(EventType.OtherMouseUp),
	OtherMouseDragged  = 1 << u64(EventType.OtherMouseDragged),
	Gesture            = 1 << u64(EventType.Gesture),
	Magnify            = 1 << u64(EventType.Magnify),
	Swipe              = 1 << u64(EventType.Swipe),
	SmartMagnify       = 1 << u64(EventType.SmartMagnify),
	QuickLook          = 1 << u64(EventType.QuickLook),
	Pressure           = 1 << u64(EventType.Pressure),
	DirectTouch        = 1 << u64(EventType.DirectTouch),
	ChangeMode         = 1 << u64(EventType.ChangeMode),
}
