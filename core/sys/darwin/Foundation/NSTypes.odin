package objc_Foundation

import "base:intrinsics"

@(private) msgSend :: intrinsics.objc_send

id      :: ^intrinsics.objc_object
SEL     :: ^intrinsics.objc_selector
Class   :: ^intrinsics.objc_class

TimeInterval :: distinct f64
Integer      :: distinct int
UInteger     :: distinct uint

IntegerMax  :: max(Integer)
Integermin  :: min(Integer)
UIntegerMax :: max(UInteger)

BOOL :: bool // TODO(bill): should this be `distinct`?
YES  :: true
NO   :: false

OperatingSystemVersion :: struct #align(8) {
	majorVersion: Integer,
	minorVersion: Integer,
	patchVersion: Integer,
}

ComparisonResult :: enum Integer {
	OrderedAscending  = -1,
	OrderedSame       =  0,
	OrderedDescending =  1,
}

NotFound :: IntegerMax

Float :: distinct (f32 when size_of(uint) == 4 else f64)

Point :: struct {
	x: Float,
	y: Float,
}

Size :: struct {
	width:  Float,
	height: Float,
}

when size_of(UInteger) == 8 {
	_UINTEGER_ENCODING :: "Q"
} else {
	_UINTEGER_ENCODING :: "I"
}

when size_of(Float) == 8 {
	_POINT_ENCODING :: "{CGPoint=dd}"
	_SIZE_ENCODING :: "{CGSize=dd}"
} else {
	_POINT_ENCODING :: "{NSPoint=ff}"
	_SIZE_ENCODING :: "{NSSize=ff}"
}
