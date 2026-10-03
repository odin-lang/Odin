package objc_Foundation

AnimationGroupChanges :: distinct rawptr

@(objc_class="NSAnimationContext")
AnimationContext :: struct { using _: Object }

@(objc_type=AnimationContext, objc_name="currentContext", objc_is_class_method=true)
AnimationContext_currentContext :: proc "c" () -> ^AnimationContext {
	return msgSend(^AnimationContext, AnimationContext, "currentContext")
}

@(objc_type=AnimationContext, objc_name="runAnimationGroup", objc_is_class_method=true)
AnimationContext_runAnimationGroup :: #force_inline proc "c" (block: AnimationGroupChanges) {
	msgSend(nil, AnimationContext, "runAnimationGroup:", block)
}

@(objc_type=AnimationContext, objc_name="beginGrouping", objc_is_class_method=true)
AnimationContext_beginGrouping :: proc "c" () {
	msgSend(nil, AnimationContext, "beginGrouping")
}

@(objc_type=AnimationContext, objc_name="endGrouping", objc_is_class_method=true)
AnimationContext_endGrouping :: proc "c" () {
	msgSend(nil, AnimationContext, "endGrouping")
}

@(objc_type=AnimationContext, objc_name="setDuration")
AnimationContext_setDuration :: proc "c" (self: ^AnimationContext, duration: TimeInterval) {
	msgSend(nil, self, "setDuration:", duration)
}

@(objc_type=AnimationContext, objc_name="setAllowsImplicitAnimation")
AnimationContext_setAllowsImplicitAnimation :: proc "c" (self: ^AnimationContext, allowsImplicitAnimation: BOOL) {
	msgSend(nil, self, "setAllowsImplicitAnimation:", allowsImplicitAnimation)
}
