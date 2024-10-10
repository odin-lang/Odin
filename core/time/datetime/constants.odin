package datetime

/*
Type representing a mononotic day number corresponding to a date.

	Ordinal 1 = Midnight Monday, January 1, 1 A.D. (Gregorian)
	        |   Midnight Monday, January 3, 1 A.D. (Julian)
*/
Ordinal :: i64

/*
*/
EPOCH   :: Ordinal(1)

/*
Minimum valid value for date.

The value is chosen such that a conversion `date -> ordinal -> date` is always
safe.
*/
MIN_DATE :: Date{year = -25_252_734_927_766_552, month =  1, day =  1}

/*
Maximum valid value for date

The value is chosen such that a conversion `date -> ordinal -> date` is always
safe.
*/
MAX_DATE :: Date{year =  25_252_734_927_766_552, month = 12, day = 31}

/*
Minimum value for an ordinal
*/
MIN_ORD  :: Ordinal(-9_223_372_036_854_775_234)

/*
Maximum value for an ordinal
*/
MAX_ORD  :: Ordinal( 9_223_372_036_854_774_869)

/*
Possible errors returned by datetime functions.
*/
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

/*
A type representing a date.

The minimum and maximum values for a year can be found in `MIN_DATE` and
`MAX_DATE` constants. The `month` field can range from 1 to 12, and the day
ranges from 1 to however many days there are in the specified month.
*/
Date :: struct {
	year:   i64,
	month:  i8,
	day:    i8,
}

/*
A type representing a time within a single day within a nanosecond precision.
*/
Time :: struct {
	hour:   i8,
	minute: i8,
	second: i8,
	nano:   i32,
}

TZ_Record :: struct {
	time:       i64,
	utc_offset: i64,
	shortname:  string,
	dst:        bool,
}

TZ_Date_Kind :: enum {
	No_Leap,
	Leap,
	Month_Week_Day,
}

TZ_Transition_Date :: struct {
	type: TZ_Date_Kind,

	month:  u8,
	week:   u8,
	day:    u16,

	time:   i64,
}

TZ_RRule :: struct {
	has_dst:    bool,

	std_name:   string,
	std_offset: i64,
	std_date:   TZ_Transition_Date,

	dst_name:   string,
	dst_offset: i64,
	dst_date:   TZ_Transition_Date,
}

TZ_Region :: struct {
	name:       string,
	records:    []TZ_Record,
	shortnames: []string,
	rrule:      TZ_RRule,
}

/*
A type representing datetime.
*/
DateTime :: struct {
	using date: Date,
	using time: Time,
	tz:   ^TZ_Region,
}

/*
A type representing a difference between two instances of datetime.

**Note**: All fields are i64 because we can also use it to add a number of
seconds or nanos to a moment, that are then normalized within their respective
ranges.
*/
Delta :: struct {
	days:    i64, 
	seconds: i64, 
	nanos:   i64,
}

/*
Type representing one of the months.
*/
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

/*
Type representing one of the weekdays.
*/
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
