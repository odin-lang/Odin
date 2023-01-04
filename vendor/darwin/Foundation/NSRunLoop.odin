package objc_Foundation

@(objc_class="NSRunLoop")
RunLoop :: struct {
	using _: Object,
}

RunLoopMode :: ^String
foreign {
	@(link_name = "NSDefaultRunLoopMode") DefaultRunLoopMode: RunLoopMode
	@(link_name = "NSEventTrackingRunLoopMode") EventTrackingRunLoopMode: RunLoopMode
}

@(objc_type=RunLoop, objc_name="currentRunLoop", objc_is_class_method=true)
RunLoop_currentRunLoop :: proc() -> ^RunLoop {
	return msgSend(^RunLoop, RunLoop, "currentRunLoop")
}

@(objc_type=RunLoop, objc_name="mainRunLoop", objc_is_class_method=true)
RunLoop_mainRunLoop :: proc() -> ^RunLoop {
	return msgSend(^RunLoop, RunLoop, "mainRunLoop")
}

@(objc_type=RunLoop, objc_name="runMode")
RunLoop_runMode :: proc(self: ^RunLoop, mode: RunLoopMode, limit_date: ^Date) -> BOOL {
	return msgSend(BOOL, self, "runMode:beforeDate:", mode, limit_date)
}
