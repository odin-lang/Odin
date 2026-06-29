package objc_Foundation

foreign import "system:Foundation.framework"

RunLoopMode :: ^String

@(link_prefix="NS")
foreign Foundation {
	RunLoopCommonModes:       RunLoopMode
	DefaultRunLoopMode:       RunLoopMode
	EventTrackingRunLoopMode: RunLoopMode
	ModalPanelRunLoopMode:    RunLoopMode
}

@(objc_class="NSRunLoop")
RunLoop :: struct { using _: Object }

@(objc_type=RunLoop, objc_name="mainRunLoop", objc_is_class_method=true)
RunLoop_mainRunLoop :: proc() -> ^RunLoop {
	return msgSend(^RunLoop, RunLoop, "mainRunLoop")
}

@(objc_type=RunLoop, objc_name="addTimerForMode")
RunLoop_addTimerForMode :: proc(self: ^RunLoop, timer: ^Timer, forMode: RunLoopMode) {
	msgSend(nil, self, "addTimer:forMode:", timer, forMode)
}

