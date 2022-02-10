package objc_Metal

import NS "core:sys/darwin/Foundation"

PackedFloat3 :: distinct [3]f32
PackedFloat4x3 :: distinct [4]PackedFloat3

AxisAlignedBoundingBox :: struct{
	min, ax: PackedFloat3,
}