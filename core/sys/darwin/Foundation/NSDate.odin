package objc_Foundation

@(objc_class="NSDate")
Date :: struct {using _: Copying(Date)}

@(objc_type=Date, objc_name="alloc", objc_is_class_method=true)
Date_alloc :: proc "c" () -> ^Date {
	return msgSend(^Date, Date, "alloc")
}

@(objc_type=Date, objc_name="init")
Date_init :: proc "c" (self: ^Date) -> ^Date {
	return msgSend(^Date, self, "init")
}

@(objc_type=Date, objc_name="dateWithTimeIntervalSinceNow")
Date_dateWithTimeIntervalSinceNow :: proc "c" (secs: TimeInterval) -> ^Date {
	return msgSend(^Date, Date, "dateWithTimeIntervalSinceNow:", secs)
}

@(objc_type=Date, objc_name="distantFuture", objc_is_class_method=true)
Date_distantFuture :: proc "c" () -> ^Date {
	return msgSend(^Date, Date, "distantFuture")
}

@(objc_type=Date, objc_name="distantPast", objc_is_class_method=true)
Date_distantPast :: proc "c" () -> ^Date {
	return msgSend(^Date, Date, "distantPast")
}
