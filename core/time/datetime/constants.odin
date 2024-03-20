package datetime

// Ordinal 1 = Midnight Monday, January 1, 1 A.D. (Gregorian)
//         |   Midnight Monday, January 3, 1 A.D. (Julian)
Ordinal :: i64
EPOCH   :: Ordinal(1)

// Minimum and maximum dates and ordinals. Chosen for safe roundtripping.
MIN_DATE :: Date{year = -25_252_734_927_766_552, month =  1, day =  1}
MAX_DATE :: Date{year =  25_252_734_927_766_552, month = 12, day = 31}
MIN_ORD  :: Ordinal(-9_223_372_036_854_775_234)
MAX_ORD  :: Ordinal( 9_223_372_036_854_774_869)

Error :: enum {
	None,
	Invalid_Year,
	Invalid_Month,
	Invalid_Day,
	Invalid_Hour,
	Invalid_Minute,
	Invalid_Second,
	Invalid_Nano,
	Invalid_Ordinal,
	Invalid_Delta,
}

Date :: struct {
	year:   i64,
	month:  i8,
	day:    i8,
}

Time :: struct {
	hour:   i8,
	minute: i8,
	second: i8,
	nano:   i32,
}

DateTime :: struct {
	using date: Date,
	using time: Time,
}

Delta :: struct {
	days:    i64, // These are all i64 because we can also use it to add a number of seconds or nanos to a moment,
	seconds: i64, // that are then normalized within their respective ranges.
	nanos:   i64,
}

Month :: enum i8 {
	January = 1,
	February,
	March,
	April,
	May,
	June,
	July,
	August,
	September,
	October,
	November,
	December,
}

Weekday :: enum i8 {
	Sunday = 0,
	Monday,
	Tuesday,
	Wednesday,
	Thursday,
	Friday,
	Saturday,
}

@(private)
MONTH_DAYS :: [?]i8{-1, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}