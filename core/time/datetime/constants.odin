package datetime

// Ordinal 1 = Midnight Monday, January 1, 1 A.D. (Gregorian)
//         |   Midnight Monday, January 3, 1 A.D. (Julian)
Ordinal :: int
EPOCH   :: Ordinal(1)

// Minimum and maximum dates and ordinals. Chosen for safe roundtripping.
when size_of(int) == 4 {
	MIN_DATE :: Date{year = -5_879_608, month =  1, day =  1}
	MAX_DATE :: Date{year =  5_879_608, month = 12, day = 31}

	MIN_ORD  :: Ordinal(-2_147_483_090)
	MAX_ORD  :: Ordinal( 2_147_482_725)
} else {
	MIN_DATE :: Date{year = -25_252_734_927_766_552, month =  1, day =  1}
	MAX_DATE :: Date{year =  25_252_734_927_766_552, month = 12, day = 31}

	MIN_ORD  :: Ordinal(-9_223_372_036_854_775_234)
	MAX_ORD  :: Ordinal( 9_223_372_036_854_774_869)
}

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
	year:   int,
	month:  int,
	day:    int,
}

Time :: struct {
	hour:   int,
	minute: int,
	second: int,
	nano:   int,
}

DateTime :: struct {
	using date: Date,
	using time: Time,
}

Delta :: struct {
	days:    int,
	seconds: int,
	nanos:   int,
}

Month :: enum int {
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

Weekday :: enum int {
	Sunday = 0,
	Monday,
	Tuesday,
	Wednesday,
	Thursday,
	Friday,
	Saturday,
}

@(private)
MONTH_DAYS :: [?]int{-1, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}