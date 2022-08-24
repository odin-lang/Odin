package objc_Foundation

import "core:intrinsics"

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

OperatingSystemVersion :: struct #packed {
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
