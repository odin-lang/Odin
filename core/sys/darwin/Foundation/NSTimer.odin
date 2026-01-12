package objc_Foundation

@(objc_class="NSTimer")
Timer :: struct { using _: Object }

@(objc_type=Timer, objc_name="scheduledTimerWithTimeIntervalRepeatsBlock", objc_is_class_method=true)
Timer_scheduledTimerWithTimeIntervalRepeatsBlock :: proc(interval: TimeInterval, repeats: BOOL, block: ^Block) -> ^Timer {
	return msgSend(^Timer, Timer, "scheduledTimerWithTimeInterval:repeats:block:")
}

@(objc_type=Timer, objc_name="scheduledTimerWithTimeIntervalTargetSelectorUserInfoRepeat", objc_is_class_method=true)
Timer_scheduledTimerWithTimeIntervalTargetSelectorUserInfoRepeat :: proc(interval: TimeInterval, aTarget: id, aSelector: SEL, userInfo: id, repeats: BOOL) -> ^Timer {
	return msgSend(^Timer, Timer, "scheduledTimerWithTimeInterval:target:selector:userInfo:repeats:", interval, aTarget, aSelector, userInfo, repeats)
}

