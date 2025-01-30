package sdl2

import "core:c"

when ODIN_OS == .Windows {
	@(ignore_duplicates)
	foreign import lib "SDL2.lib"
} else {
	@(ignore_duplicates)
	foreign import lib "system:SDL2"
}

/**
 *  \brief The blend mode used in SDL_RenderCopy() and drawing operations.
 */
BlendMode :: enum c.int {
	NONE = 0x00000000,     /**< no blending
	                        dstRGBA = srcRGBA */
	BLEND = 0x00000001,    /**< alpha blending
	                        dstRGB = (srcRGB * srcA) + (dstRGB * (1-srcA))
	                        dstA = srcA + (dstA * (1-srcA)) */
	ADD = 0x00000002,      /**< additive blending
	                        dstRGB = (srcRGB * srcA) + dstRGB
	                        dstA = dstA */
	MOD = 0x00000004,      /**< color modulate
	                        dstRGB = srcRGB * dstRGB
	                        dstA = dstA */
	MUL = 0x00000008,      /**< color multiply
	                        dstRGB = (srcRGB * dstRGB) + (dstRGB * (1-srcA))
	                        dstA = (srcA * dstA) + (dstA * (1-srcA)) */
	INVALID = 0x7FFFFFFF,

	/* Additional custom blend modes can be returned by ComposeCustomBlendMode() */
}

/**
 *  \brief The blend operation used when combining source and destination pixel components
 */
BlendOperation :: enum c.int {
	ADD              = 0x1,  /**< dst + src: supported by all renderers */
	SUBTRACT         = 0x2,  /**< dst - src : supported by D3D9, D3D11, OpenGL, OpenGLES */
	REV_SUBTRACT     = 0x3,  /**< src - dst : supported by D3D9, D3D11, OpenGL, OpenGLES */
	MINIMUM          = 0x4,  /**< min(dst, src) : supported by D3D11 */
	MAXIMUM          = 0x5,  /**< max(dst, src) : supported by D3D11 */
}

/**
 *  \brief The normalized factor used to multiply pixel components
 */
BlendFactor :: enum c.int  {
	ZERO                = 0x1,  /**< 0, 0, 0, 0 */
	ONE                 = 0x2,  /**< 1, 1, 1, 1 */
	SRC_COLOR           = 0x3,  /**< srcR, srcG, srcB, srcA */
	ONE_MINUS_SRC_COLOR = 0x4,  /**< 1-srcR, 1-srcG, 1-srcB, 1-srcA */
	SRC_ALPHA           = 0x5,  /**< srcA, srcA, srcA, srcA */
	ONE_MINUS_SRC_ALPHA = 0x6,  /**< 1-srcA, 1-srcA, 1-srcA, 1-srcA */
	DST_COLOR           = 0x7,  /**< dstR, dstG, dstB, dstA */
	ONE_MINUS_DST_COLOR = 0x8,  /**< 1-dstR, 1-dstG, 1-dstB, 1-dstA */
	DST_ALPHA           = 0x9,  /**< dstA, dstA, dstA, dstA */
	ONE_MINUS_DST_ALPHA = 0xA,  /**< 1-dstA, 1-dstA, 1-dstA, 1-dstA */
}


@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	ComposeCustomBlendMode :: proc(srcColorFactor, dstColorFactor: BlendFactor, colorOperation: BlendOperation,
	                               srcAlphaFactor, dstAlphaFactor: BlendFactor, alphaOperation: BlendOperation) -> BlendMode ---
}
