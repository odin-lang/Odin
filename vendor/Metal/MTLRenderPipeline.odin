package objc_Metal

import NS "core:sys/darwin/Foundation"

BlendFactor :: enum NS.UInteger {
	Zero                     = 0,
	One                      = 1,
	SourceColor              = 2,
	OneMinusSourceColor      = 3,
	SourceAlpha              = 4,
	OneMinusSourceAlpha      = 5,
	DestinationColor         = 6,
	OneMinusDestinationColor = 7,
	DestinationAlpha         = 8,
	OneMinusDestinationAlpha = 9,
	SourceAlphaSaturated     = 10,
	BlendColor               = 11,
	OneMinusBlendColor       = 12,
	BlendAlpha               = 13,
	OneMinusBlendAlpha       = 14,
	Source1Color             = 15,
	OneMinusSource1Color     = 16,
	Source1Alpha             = 17,
	OneMinusSource1Alpha     = 18,
}

BlendOperation :: enum NS.UInteger {
	Add             = 0,
	Subtract        = 1,
	ReverseSubtract = 2,
	Min             = 3,
	Max             = 4,
}

ColorWriteMaskOption :: enum NS.UInteger {
	Alpha = 0,
	Blue  = 1,
	Green = 2,
	Red   = 3,
}
ColorWriteMask :: distinct bit_set[ColorWriteMaskOption; NS.UInteger]
ColorWriteMaskNone :: ColorWriteMask{}
ColorWriteMaskAll :: ColorWriteMask{.Alpha, .Blue, .Green, .Red}

PrimitiveTopologyClass :: enum NS.UInteger {
	ClassUnspecified = 0,
	ClassPoint       = 1,
	ClassLine        = 2,
	ClassTriangle    = 3,
}

TessellationPartitionMode :: enum NS.UInteger {
	ModePow2 =           0,
	ModeInteger =        1,
	ModeFractionalOdd =  2,
	ModeFractionalEven = 3,
}

TessellationFactorStepFunction :: enum NS.UInteger {
	Constant               = 0,
	PerPatch               = 1,
	PerInstance            = 2,
	PerPatchAndPerInstance = 3,
}

TessellationFactorFormat :: enum NS.UInteger {
	Half = 0,
}

TessellationControlPointIndexType :: enum NS.UInteger {
	None   = 0,
	UInt16 = 1,
	UInt32 = 2,
}
