package objc_Foundation

@(objc_class="NSDate")
Date :: struct {using _: Copying(Date)}

@(objc_type=Date, objc_class_name="alloc")
Date_alloc :: proc() -> ^Date {
	return msgSend(^Date, Date, "alloc")
}

@(objc_type=Date, objc_name="init")
Date_init :: proc(self: ^Date) -> ^Date {
	return msgSend(^Date, self, "init")
}


@(objc_type=Date, objc_name="dateWithTimeIntervalSinceNow")
Date_dateWithTimeIntervalSinceNow :: proc(secs: TimeInterval) -> ^Date {
	return msgSend(^Date, Date, "dateWithTimeIntervalSinceNow:", secs)
}