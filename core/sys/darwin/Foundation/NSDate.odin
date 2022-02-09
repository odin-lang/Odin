package objc_Foundation

@(objc_class="NSDate")
Date :: struct {using _: Copying(Date)}

Date_dateWithTimeIntervalSinceNow :: proc(secs: TimeInterval) -> ^Date {
	return msgSend(^Date, Date, "dateWithTimeIntervalSinceNow:", secs)
}