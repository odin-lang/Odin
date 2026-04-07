#+build darwin
package CoreGraphics

import    "base:intrinsics"
import    "core:c"
import    "core:sys/darwin"
import CF "core:sys/darwin/CoreFoundation"

@(require)
foreign import lib "system:CoreGraphics.framework"

FontIndexMax          :: 65534
FontIndexInvalid      :: 65535
GlyphMax              :: 65534
BitmapByteOrder16Host :: 4096
BitmapByteOrder32Host :: 8192

MTLDevice :: intrinsics.objc_object

@(link_prefix="CG")
foreign lib {
	PointZero:               Point
	SizeZero:                Size
	RectZero:                Rect
	RectNull:                Rect
	RectInfinite:            Rect
	AffineTransformIdentity: AffineTransform
}

@(link_prefix="kCG")
foreign lib {
	ColorSpaceGenericGray:                    CF.StringRef
	ColorSpaceGenericRGB:                     CF.StringRef
	ColorSpaceGenericCMYK:                    CF.StringRef
	ColorSpaceDisplayP3:                      CF.StringRef
	ColorSpaceGenericRGBLinear:               CF.StringRef
	ColorSpaceAdobeRGB1998:                   CF.StringRef
	ColorSpaceSRGB:                           CF.StringRef
	ColorSpaceGenericGrayGamma2_2:            CF.StringRef
	ColorSpaceGenericXYZ:                     CF.StringRef
	ColorSpaceGenericLab:                     CF.StringRef
	ColorSpaceACESCGLinear:                   CF.StringRef
	ColorSpaceITUR_709:                       CF.StringRef
	ColorSpaceITUR_709_PQ:                    CF.StringRef
	ColorSpaceITUR_709_HLG:                   CF.StringRef
	ColorSpaceITUR_2020:                      CF.StringRef
	ColorSpaceITUR_2020_sRGBGamma:            CF.StringRef
	ColorSpaceROMMRGB:                        CF.StringRef
	ColorSpaceDCIP3:                          CF.StringRef
	ColorSpaceLinearITUR_2020:                CF.StringRef
	ColorSpaceExtendedITUR_2020:              CF.StringRef
	ColorSpaceExtendedLinearITUR_2020:        CF.StringRef
	ColorSpaceLinearDisplayP3:                CF.StringRef
	ColorSpaceExtendedDisplayP3:              CF.StringRef
	ColorSpaceExtendedLinearDisplayP3:        CF.StringRef
	ColorSpaceITUR_2100_PQ:                   CF.StringRef
	ColorSpaceITUR_2100_HLG:                  CF.StringRef
	ColorSpaceDisplayP3_PQ:                   CF.StringRef
	ColorSpaceDisplayP3_HLG:                  CF.StringRef
	ColorSpaceITUR_2020_PQ:                   CF.StringRef
	ColorSpaceITUR_2020_HLG:                  CF.StringRef
	ColorSpaceDisplayP3_PQ_EOTF:              CF.StringRef
	ColorSpaceITUR_2020_PQ_EOTF:              CF.StringRef
	ColorSpaceExtendedSRGB:                   CF.StringRef
	ColorSpaceLinearSRGB:                     CF.StringRef
	ColorSpaceExtendedLinearSRGB:             CF.StringRef
	ColorSpaceExtendedGray:                   CF.StringRef
	ColorSpaceLinearGray:                     CF.StringRef
	ColorSpaceExtendedLinearGray:             CF.StringRef
	ColorSpaceCoreMedia709:                   CF.StringRef
	ColorSpaceExtendedRange:                  CF.StringRef
	ColorWhite:                               CF.StringRef
	ColorBlack:                               CF.StringRef
	ColorClear:                               CF.StringRef
	FontVariationAxisName:                    CF.StringRef
	FontVariationAxisMinValue:                CF.StringRef
	FontVariationAxisMaxValue:                CF.StringRef
	FontVariationAxisDefaultValue:            CF.StringRef
	PDFOutlineTitle:                          CF.StringRef
	PDFOutlineChildren:                       CF.StringRef
	PDFOutlineDestination:                    CF.StringRef
	PDFOutlineDestinationRect:                CF.StringRef
	EXRToneMappingGammaDefog:                 CF.StringRef
	EXRToneMappingGammaExposure:              CF.StringRef
	EXRToneMappingGammaKneeLow:               CF.StringRef
	EXRToneMappingGammaKneeHigh:              CF.StringRef
	Use100nitsHLGOOTF:                        CF.StringRef
	UseBT1886ForCoreVideoGamma:               CF.StringRef
	SkipBoostToHDR:                           CF.StringRef
	UseLegacyHDREcosystem:                    CF.StringRef
	PreferredDynamicRange:                    CF.StringRef
	DynamicRangeHigh:                         CF.StringRef
	DynamicRangeConstrained:                  CF.StringRef
	DynamicRangeStandard:                     CF.StringRef
	ContentAverageLightLevel:                 CF.StringRef
	ContentAverageLightLevelNits:             CF.StringRef
	AdaptiveMaximumBitDepth:                  CF.StringRef
	ColorConversionBlackPointCompensation:    CF.StringRef
	ColorConversionTRCSize:                   CF.StringRef
	PDFContextMediaBox:                       CF.StringRef
	PDFContextCropBox:                        CF.StringRef
	PDFContextBleedBox:                       CF.StringRef
	PDFContextTrimBox:                        CF.StringRef
	PDFContextArtBox:                         CF.StringRef
	PDFContextTitle:                          CF.StringRef
	PDFContextAuthor:                         CF.StringRef
	PDFContextSubject:                        CF.StringRef
	PDFContextKeywords:                       CF.StringRef
	PDFContextCreator:                        CF.StringRef
	PDFContextOwnerPassword:                  CF.StringRef
	PDFContextUserPassword:                   CF.StringRef
	PDFContextEncryptionKeyLength:            CF.StringRef
	PDFContextAllowsPrinting:                 CF.StringRef
	PDFContextAllowsCopying:                  CF.StringRef
	PDFContextOutputIntent:                   CF.StringRef
	PDFXOutputIntentSubtype:                  CF.StringRef
	PDFXOutputConditionIdentifier:            CF.StringRef
	PDFXOutputCondition:                      CF.StringRef
	PDFXRegistryName:                         CF.StringRef
	PDFXInfo:                                 CF.StringRef
	PDFXDestinationOutputProfile:             CF.StringRef
	PDFContextOutputIntents:                  CF.StringRef
	PDFContextAccessPermissions:              CF.StringRef
	PDFContextCreateLinearizedPDF:            CF.StringRef
	PDFContextCreatePDFA:                     CF.StringRef
	WindowNumber:                             CF.StringRef
	WindowStoreType:                          CF.StringRef
	WindowLayer:                              CF.StringRef
	WindowBounds:                             CF.StringRef
	WindowSharingState:                       CF.StringRef
	WindowAlpha:                              CF.StringRef
	WindowOwnerPID:                           CF.StringRef
	WindowMemoryUsage:                        CF.StringRef
	WindowWorkspace:                          CF.StringRef
	WindowOwnerName:                          CF.StringRef
	WindowName:                               CF.StringRef
	WindowIsOnscreen:                         CF.StringRef
	WindowBackingLocationVideoMemory:         CF.StringRef
	DisplayShowDuplicateLowResolutionModes:   CF.StringRef
	DisplayStreamSourceRect:                  CF.StringRef
	DisplayStreamDestinationRect:             CF.StringRef
	DisplayStreamPreserveAspectRatio:         CF.StringRef
	DisplayStreamColorSpace:                  CF.StringRef
	DisplayStreamMinimumFrameTime:            CF.StringRef
	DisplayStreamShowCursor:                  CF.StringRef
	DisplayStreamQueueDepth:                  CF.StringRef
	DisplayStreamYCbCrMatrix:                 CF.StringRef
	DisplayStreamYCbCrMatrix_ITU_R_709_2:     CF.StringRef
	DisplayStreamYCbCrMatrix_ITU_R_601_4:     CF.StringRef
	DisplayStreamYCbCrMatrix_SMPTE_240M_1995: CF.StringRef

	DefaultHDRImageContentHeadroom: c.float

	PDFTagPropertyActualText:      PDFTagProperty
	PDFTagPropertyAlternativeText: PDFTagProperty
	PDFTagPropertyTitleText:       PDFTagProperty
	PDFTagPropertyLanguageText:    PDFTagProperty
}

when ODIN_PLATFORM_SUBTARGET == .Default {
	@(link_prefix="CG", default_calling_convention="c")
	foreign lib {
		DisplayCreateUUIDFromDisplayID :: proc(displayID: DirectDisplayID) -> CF.UUIDRef ---
		DisplayGetDisplayIDFromUUID    :: proc(uuid: CF.UUIDRef) -> DirectDisplayID ---
	}
}


@(link_prefix="CG", default_calling_convention="c")
foreign lib {
	RectGetMinX :: proc(rect: Rect) -> Float ---
	RectGetMidX :: proc(rect: Rect) -> Float ---
	RectGetMaxX :: proc(rect: Rect) -> Float ---
	RectGetMinY :: proc(rect: Rect) -> Float ---
	RectGetMidY :: proc(rect: Rect) -> Float ---
	RectGetMaxY :: proc(rect: Rect) -> Float ---
	RectGetWidth :: proc(rect: Rect) -> Float ---
	RectGetHeight :: proc(rect: Rect) -> Float ---
	PointEqualToPoint :: proc(point1: Point, point2: Point) -> bool ---
	SizeEqualToSize :: proc(size1: Size, size2: Size) -> bool ---
	RectEqualToRect :: proc(rect1: Rect, rect2: Rect) -> bool ---
	RectStandardize :: proc(rect: Rect) -> Rect ---
	RectIsEmpty :: proc(rect: Rect) -> bool ---
	RectIsNull :: proc(rect: Rect) -> bool ---
	RectIsInfinite :: proc(rect: Rect) -> bool ---
	RectInset :: proc(rect: Rect, dx: Float, dy: Float) -> Rect ---
	RectIntegral :: proc(rect: Rect) -> Rect ---
	RectUnion :: proc(r1: Rect, r2: Rect) -> Rect ---
	RectIntersection :: proc(r1: Rect, r2: Rect) -> Rect ---
	RectOffset :: proc(rect: Rect, dx: Float, dy: Float) -> Rect ---
	RectDivide :: proc(rect: Rect, slice: ^Rect, remainder: ^Rect, amount: Float, edge: RectEdge) ---
	RectContainsPoint :: proc(rect: Rect, point: Point) -> bool ---
	RectContainsRect :: proc(rect1: Rect, rect2: Rect) -> bool ---
	RectIntersectsRect :: proc(rect1: Rect, rect2: Rect) -> bool ---
	PointCreateDictionaryRepresentation :: proc(point: Point) -> CF.DictionaryRef ---
	PointMakeWithDictionaryRepresentation :: proc(dict: CF.DictionaryRef, point: ^Point) -> bool ---
	SizeCreateDictionaryRepresentation :: proc(size: Size) -> CF.DictionaryRef ---
	SizeMakeWithDictionaryRepresentation :: proc(dict: CF.DictionaryRef, size: ^Size) -> bool ---
	RectCreateDictionaryRepresentation :: proc(_0: Rect) -> CF.DictionaryRef ---
	RectMakeWithDictionaryRepresentation :: proc(dict: CF.DictionaryRef, rect: ^Rect) -> bool ---
	AffineTransformMake :: proc(a: Float, b: Float, c: Float, d: Float, tx: Float, ty: Float) -> AffineTransform ---
	AffineTransformMakeTranslation :: proc(tx: Float, ty: Float) -> AffineTransform ---
	AffineTransformMakeScale :: proc(sx: Float, sy: Float) -> AffineTransform ---
	AffineTransformMakeRotation :: proc(angle: Float) -> AffineTransform ---
	AffineTransformIsIdentity :: proc(t: AffineTransform) -> bool ---
	AffineTransformTranslate :: proc(t: AffineTransform, tx: Float, ty: Float) -> AffineTransform ---
	AffineTransformScale :: proc(t: AffineTransform, sx: Float, sy: Float) -> AffineTransform ---
	AffineTransformRotate :: proc(t: AffineTransform, angle: Float) -> AffineTransform ---
	AffineTransformInvert :: proc(t: AffineTransform) -> AffineTransform ---
	AffineTransformConcat :: proc(t1: AffineTransform, t2: AffineTransform) -> AffineTransform ---
	AffineTransformEqualToTransform :: proc(t1: AffineTransform, t2: AffineTransform) -> bool ---
	PointApplyAffineTransform :: proc(point: Point, t: AffineTransform) -> Point ---
	SizeApplyAffineTransform :: proc(size: Size, t: AffineTransform) -> Size ---
	RectApplyAffineTransform :: proc(rect: Rect, t: AffineTransform) -> Rect ---
	AffineTransformDecompose :: proc(transform: AffineTransform) -> AffineTransformComponents ---
	AffineTransformMakeWithComponents :: proc(components: AffineTransformComponents) -> AffineTransform ---
	DataProviderGetTypeID :: proc() -> CF.TypeID ---
	DataProviderCreateSequential :: proc(info: rawptr, callbacks: ^DataProviderSequentialCallbacks) -> DataProviderRef ---
	DataProviderCreateDirect :: proc(info: rawptr, size: darwin.off_t, callbacks: ^DataProviderDirectCallbacks) -> DataProviderRef ---
	DataProviderCreateWithData :: proc(info: rawptr, data: rawptr, size: c.size_t, releaseData: DataProviderReleaseDataCallback) -> DataProviderRef ---
	DataProviderCreateWithCFData :: proc(data: CF.DataRef) -> DataProviderRef ---
	DataProviderCreateWithURL :: proc(url: CF.URLRef) -> DataProviderRef ---
	DataProviderCreateWithFilename :: proc(filename: cstring) -> DataProviderRef ---
	DataProviderRetain :: proc(provider: DataProviderRef) -> DataProviderRef ---
	DataProviderRelease :: proc(provider: DataProviderRef) ---
	DataProviderCopyData :: proc(provider: DataProviderRef) -> CF.DataRef ---
	DataProviderGetInfo :: proc(provider: DataProviderRef) -> rawptr ---
	ColorSpaceCreateDeviceGray :: proc() -> ColorSpaceRef ---
	ColorSpaceCreateDeviceRGB :: proc() -> ColorSpaceRef ---
	ColorSpaceCreateDeviceCMYK :: proc() -> ColorSpaceRef ---
	ColorSpaceCreateCalibratedGray :: proc(whitePoint: ^Float, blackPoint: ^Float, gamma: Float) -> ColorSpaceRef ---
	ColorSpaceCreateCalibratedRGB :: proc(whitePoint: ^Float, blackPoint: ^Float, gamma: ^Float, _matrix: [^]Float) -> ColorSpaceRef ---
	ColorSpaceCreateLab :: proc(whitePoint: ^Float, blackPoint: ^Float, range: ^Float) -> ColorSpaceRef ---
	ColorSpaceCreateWithICCData :: proc(data: CF.TypeRef) -> ColorSpaceRef ---
	ColorSpaceCreateICCBased :: proc(nComponents: c.size_t, range: ^Float, profile: DataProviderRef, alternate: ColorSpaceRef) -> ColorSpaceRef ---
	ColorSpaceCreateIndexed :: proc(baseSpace: ColorSpaceRef, lastIndex: c.size_t, colorTable: [^]u8) -> ColorSpaceRef ---
	ColorSpaceCreatePattern :: proc(baseSpace: ColorSpaceRef) -> ColorSpaceRef ---
	ColorSpaceCreateWithColorSyncProfile :: proc(_0: ColorSyncProfileRef, options: CF.DictionaryRef) -> ColorSpaceRef ---
	ColorSpaceCreateWithName :: proc(name: CF.StringRef) -> ColorSpaceRef ---
	ColorSpaceRetain :: proc(space: ColorSpaceRef) -> ColorSpaceRef ---
	ColorSpaceRelease :: proc(space: ColorSpaceRef) ---
	ColorSpaceGetName :: proc(space: ColorSpaceRef) -> CF.StringRef ---
	ColorSpaceCopyName :: proc(space: ColorSpaceRef) -> CF.StringRef ---
	ColorSpaceGetTypeID :: proc() -> CF.TypeID ---
	ColorSpaceGetNumberOfComponents :: proc(space: ColorSpaceRef) -> c.size_t ---
	ColorSpaceGetModel :: proc(space: ColorSpaceRef) -> ColorSpaceModel ---
	ColorSpaceGetBaseColorSpace :: proc(space: ColorSpaceRef) -> ColorSpaceRef ---
	ColorSpaceCopyBaseColorSpace :: proc(space: ColorSpaceRef) -> ColorSpaceRef ---
	ColorSpaceGetColorTableCount :: proc(space: ColorSpaceRef) -> c.size_t ---
	ColorSpaceGetColorTable :: proc(space: ColorSpaceRef, table: [^]u8) ---
	ColorSpaceCopyICCData :: proc(space: ColorSpaceRef) -> CF.DataRef ---
	ColorSpaceIsWideGamutRGB :: proc(_0: ColorSpaceRef) -> bool ---
	ColorSpaceIsHDR :: proc(_0: ColorSpaceRef) -> bool ---
	ColorSpaceUsesITUR_2100TF :: proc(_0: ColorSpaceRef) -> bool ---
	ColorSpaceIsPQBased :: proc(s: ColorSpaceRef) -> bool ---
	ColorSpaceIsHLGBased :: proc(s: ColorSpaceRef) -> bool ---
	ColorSpaceSupportsOutput :: proc(space: ColorSpaceRef) -> bool ---
	ColorSpaceCopyPropertyList :: proc(space: ColorSpaceRef) -> CF.PropertyListRef ---
	ColorSpaceCreateWithPropertyList :: proc(plist: CF.PropertyListRef) -> ColorSpaceRef ---
	ColorSpaceUsesExtendedRange :: proc(space: ColorSpaceRef) -> bool ---
	ColorSpaceCreateLinearized :: proc(space: ColorSpaceRef) -> ColorSpaceRef ---
	ColorSpaceCreateExtended :: proc(space: ColorSpaceRef) -> ColorSpaceRef ---
	ColorSpaceCreateExtendedLinearized :: proc(space: ColorSpaceRef) -> ColorSpaceRef ---
	ColorSpaceCreateCopyWithStandardRange :: proc(space: ColorSpaceRef) -> ColorSpaceRef ---
	ColorSpaceCreateWithICCProfile :: proc(data: CF.DataRef) -> ColorSpaceRef ---
	ColorSpaceCopyICCProfile :: proc(space: ColorSpaceRef) -> CF.DataRef ---
	ColorSpaceCreateWithPlatformColorSpace :: proc(ref: rawptr) -> ColorSpaceRef ---
	PatternGetTypeID :: proc() -> CF.TypeID ---
	PatternCreate :: proc(info: rawptr, bounds: Rect, _matrix: AffineTransform, xStep: Float, yStep: Float, tiling: PatternTiling, isColored: bool, callbacks: ^PatternCallbacks) -> PatternRef ---
	PatternRetain :: proc(pattern: PatternRef) -> PatternRef ---
	PatternRelease :: proc(pattern: PatternRef) ---
	ColorCreate :: proc(space: ColorSpaceRef, components: [^]Float) -> ColorRef ---
	ColorCreateGenericGray :: proc(gray: Float, alpha: Float) -> ColorRef ---
	ColorCreateGenericRGB :: proc(red: Float, green: Float, blue: Float, alpha: Float) -> ColorRef ---
	ColorCreateGenericCMYK :: proc(cyan: Float, magenta: Float, yellow: Float, black: Float, alpha: Float) -> ColorRef ---
	ColorCreateGenericGrayGamma2_2 :: proc(gray: Float, alpha: Float) -> ColorRef ---
	ColorCreateSRGB :: proc(red: Float, green: Float, blue: Float, alpha: Float) -> ColorRef ---
	ColorCreateWithContentHeadroom :: proc(headroom: f32, space: ColorSpaceRef, red: Float, green: Float, blue: Float, alpha: Float) -> ColorRef ---
	ColorGetContentHeadroom :: proc(color: ColorRef) -> f32 ---
	ColorGetConstantColor :: proc(colorName: CF.StringRef) -> ColorRef ---
	ColorCreateWithPattern :: proc(space: ColorSpaceRef, pattern: PatternRef, components: [^]Float) -> ColorRef ---
	ColorCreateCopy :: proc(color: ColorRef) -> ColorRef ---
	ColorCreateCopyWithAlpha :: proc(color: ColorRef, alpha: Float) -> ColorRef ---
	ColorCreateCopyByMatchingToColorSpace :: proc(_0: ColorSpaceRef, intent: ColorRenderingIntent, color: ColorRef, options: CF.DictionaryRef) -> ColorRef ---
	ColorRetain :: proc(color: ColorRef) -> ColorRef ---
	ColorRelease :: proc(color: ColorRef) ---
	ColorEqualToColor :: proc(color1: ColorRef, color2: ColorRef) -> bool ---
	ColorGetNumberOfComponents :: proc(color: ColorRef) -> c.size_t ---
	ColorGetComponents :: proc(color: ColorRef) -> ^Float ---
	ColorGetAlpha :: proc(color: ColorRef) -> Float ---
	ColorGetColorSpace :: proc(color: ColorRef) -> ColorSpaceRef ---
	ColorGetPattern :: proc(color: ColorRef) -> PatternRef ---
	ColorGetTypeID :: proc() -> CF.TypeID ---
	FontGetTypeID :: proc() -> CF.TypeID ---
	FontCreateWithPlatformFont :: proc(platformFontReference: rawptr) -> FontRef ---
	FontCreateWithDataProvider :: proc(provider: DataProviderRef) -> FontRef ---
	FontCreateWithFontName :: proc(name: CF.StringRef) -> FontRef ---
	FontCreateCopyWithVariations :: proc(font: FontRef, variations: CF.DictionaryRef) -> FontRef ---
	FontRetain :: proc(font: FontRef) -> FontRef ---
	FontRelease :: proc(font: FontRef) ---
	FontGetNumberOfGlyphs :: proc(font: FontRef) -> c.size_t ---
	FontGetUnitsPerEm :: proc(font: FontRef) -> c.int ---
	FontCopyPostScriptName :: proc(font: FontRef) -> CF.StringRef ---
	FontCopyFullName :: proc(font: FontRef) -> CF.StringRef ---
	FontGetAscent :: proc(font: FontRef) -> c.int ---
	FontGetDescent :: proc(font: FontRef) -> c.int ---
	FontGetLeading :: proc(font: FontRef) -> c.int ---
	FontGetCapHeight :: proc(font: FontRef) -> c.int ---
	FontGetXHeight :: proc(font: FontRef) -> c.int ---
	FontGetFontBBox :: proc(font: FontRef) -> Rect ---
	FontGetItalicAngle :: proc(font: FontRef) -> Float ---
	FontGetStemV :: proc(font: FontRef) -> Float ---
	FontCopyVariationAxes :: proc(font: FontRef) -> CF.ArrayRef ---
	FontCopyVariations :: proc(font: FontRef) -> CF.DictionaryRef ---
	FontGetGlyphAdvances :: proc(font: FontRef, glyphs: [^]Glyph, count: c.size_t, advances: [^]c.int) -> bool ---
	FontGetGlyphBBoxes :: proc(font: FontRef, glyphs: [^]Glyph, count: c.size_t, bboxes: [^]Rect) -> bool ---
	FontGetGlyphWithGlyphName :: proc(font: FontRef, name: CF.StringRef) -> Glyph ---
	FontCopyGlyphNameForGlyph :: proc(font: FontRef, glyph: Glyph) -> CF.StringRef ---
	FontCanCreatePostScriptSubset :: proc(font: FontRef, format: FontPostScriptFormat) -> bool ---
	FontCreatePostScriptSubset :: proc(font: FontRef, subsetName: CF.StringRef, format: FontPostScriptFormat, glyphs: [^]Glyph, count: c.size_t, encoding: ^Glyph) -> CF.DataRef ---
	FontCreatePostScriptEncoding :: proc(font: FontRef, encoding: ^Glyph) -> CF.DataRef ---
	FontCopyTableTags :: proc(font: FontRef) -> CF.ArrayRef ---
	FontCopyTableForTag :: proc(font: FontRef, tag: u32) -> CF.DataRef ---
	GradientGetTypeID :: proc() -> CF.TypeID ---
	GradientCreateWithColorComponents :: proc(space: ColorSpaceRef, components: [^]Float, locations: [^]Float, count: c.size_t) -> GradientRef ---
	GradientCreateWithContentHeadroom :: proc(headroom: f32, space: ColorSpaceRef, components: [^]Float, locations: [^]Float, count: c.size_t) -> GradientRef ---
	GradientCreateWithColors :: proc(space: ColorSpaceRef, colors: CF.ArrayRef, locations: [^]Float) -> GradientRef ---
	GradientRetain :: proc(gradient: GradientRef) -> GradientRef ---
	GradientRelease :: proc(gradient: GradientRef) ---
	GradientGetContentHeadroom :: proc(gradient: GradientRef) -> f32 ---
	ImageGetTypeID :: proc() -> CF.TypeID ---
	ImageCreate :: proc(width: c.size_t, height: c.size_t, bitsPerComponent: c.size_t, bitsPerPixel: c.size_t, bytesPerRow: c.size_t, space: ColorSpaceRef, bitmapInfo: BitmapInfo, provider: DataProviderRef, decode: ^Float, shouldInterpolate: bool, intent: ColorRenderingIntent) -> ImageRef ---
	ImageMaskCreate :: proc(width: c.size_t, height: c.size_t, bitsPerComponent: c.size_t, bitsPerPixel: c.size_t, bytesPerRow: c.size_t, provider: DataProviderRef, decode: ^Float, shouldInterpolate: bool) -> ImageRef ---
	ImageCreateCopy :: proc(image: ImageRef) -> ImageRef ---
	ImageCreateWithJPEGDataProvider :: proc(source: DataProviderRef, decode: ^Float, shouldInterpolate: bool, intent: ColorRenderingIntent) -> ImageRef ---
	ImageCreateWithPNGDataProvider :: proc(source: DataProviderRef, decode: ^Float, shouldInterpolate: bool, intent: ColorRenderingIntent) -> ImageRef ---
	ImageCreateWithImageInRect :: proc(image: ImageRef, rect: Rect) -> ImageRef ---
	ImageCreateWithMask :: proc(image: ImageRef, mask: ImageRef) -> ImageRef ---
	ImageCreateWithMaskingColors :: proc(image: ImageRef, components: [^]Float) -> ImageRef ---
	ImageCreateCopyWithColorSpace :: proc(image: ImageRef, space: ColorSpaceRef) -> ImageRef ---
	ImageCreateWithContentHeadroom :: proc(headroom: f32, width: c.size_t, height: c.size_t, bitsPerComponent: c.size_t, bitsPerPixel: c.size_t, bytesPerRow: c.size_t, space: ColorSpaceRef, bitmapInfo: BitmapInfo, provider: DataProviderRef, decode: ^Float, shouldInterpolate: bool, intent: ColorRenderingIntent) -> ImageRef ---
	ImageCreateCopyWithContentHeadroom :: proc(headroom: f32, image: ImageRef) -> ImageRef ---
	ImageGetContentHeadroom :: proc(image: ImageRef) -> f32 ---
	ImageCalculateContentHeadroom :: proc(image: ImageRef) -> f32 ---
	ImageGetContentAverageLightLevel :: proc(image: ImageRef) -> f32 ---
	ImageCalculateContentAverageLightLevel :: proc(image: ImageRef) -> f32 ---
	ImageCreateCopyWithContentAverageLightLevel :: proc(image: ImageRef, avll: f32) -> ImageRef ---
	ImageCreateCopyWithCalculatedHDRStats :: proc(image: ImageRef) -> ImageRef ---
	ImageRetain :: proc(image: ImageRef) -> ImageRef ---
	ImageRelease :: proc(image: ImageRef) ---
	ImageIsMask :: proc(image: ImageRef) -> bool ---
	ImageGetWidth :: proc(image: ImageRef) -> c.size_t ---
	ImageGetHeight :: proc(image: ImageRef) -> c.size_t ---
	ImageGetBitsPerComponent :: proc(image: ImageRef) -> c.size_t ---
	ImageGetBitsPerPixel :: proc(image: ImageRef) -> c.size_t ---
	ImageGetBytesPerRow :: proc(image: ImageRef) -> c.size_t ---
	ImageGetColorSpace :: proc(image: ImageRef) -> ColorSpaceRef ---
	ImageGetAlphaInfo :: proc(image: ImageRef) -> ImageAlphaInfo ---
	ImageGetDataProvider :: proc(image: ImageRef) -> DataProviderRef ---
	ImageGetDecode :: proc(image: ImageRef) -> ^Float ---
	ImageGetShouldInterpolate :: proc(image: ImageRef) -> bool ---
	ImageGetRenderingIntent :: proc(image: ImageRef) -> ColorRenderingIntent ---
	ImageGetBitmapInfo :: proc(image: ImageRef) -> BitmapInfo ---
	ImageGetByteOrderInfo :: proc(image: ImageRef) -> ImageByteOrderInfo ---
	ImageGetPixelFormatInfo :: proc(image: ImageRef) -> ImagePixelFormatInfo ---
	ImageShouldToneMap :: proc(image: ImageRef) -> bool ---
	ImageContainsImageSpecificToneMappingMetadata :: proc(image: ImageRef) -> bool ---
	ImageGetUTType :: proc(image: ImageRef) -> CF.StringRef ---
	PathGetTypeID :: proc() -> CF.TypeID ---
	PathCreateMutable :: proc() -> MutablePathRef ---
	PathCreateCopy :: proc(path: PathRef) -> PathRef ---
	PathCreateCopyByTransformingPath :: proc(path: PathRef, transform: ^AffineTransform) -> PathRef ---
	PathCreateMutableCopy :: proc(path: PathRef) -> MutablePathRef ---
	PathCreateMutableCopyByTransformingPath :: proc(path: PathRef, transform: ^AffineTransform) -> MutablePathRef ---
	PathCreateWithRect :: proc(rect: Rect, transform: ^AffineTransform) -> PathRef ---
	PathCreateWithEllipseInRect :: proc(rect: Rect, transform: ^AffineTransform) -> PathRef ---
	PathCreateWithRoundedRect :: proc(rect: Rect, cornerWidth: Float, cornerHeight: Float, transform: ^AffineTransform) -> PathRef ---
	PathAddRoundedRect :: proc(path: MutablePathRef, transform: ^AffineTransform, rect: Rect, cornerWidth: Float, cornerHeight: Float) ---
	PathCreateCopyByDashingPath :: proc(path: PathRef, transform: ^AffineTransform, phase: Float, lengths: [^]Float, count: c.size_t) -> PathRef ---
	PathCreateCopyByStrokingPath :: proc(path: PathRef, transform: ^AffineTransform, lineWidth: Float, lineCap: LineCap, lineJoin: LineJoin, miterLimit: Float) -> PathRef ---
	PathRetain :: proc(path: PathRef) -> PathRef ---
	PathRelease :: proc(path: PathRef) ---
	PathEqualToPath :: proc(path1: PathRef, path2: PathRef) -> bool ---
	PathMoveToPoint :: proc(path: MutablePathRef, m: ^AffineTransform, x: Float, y: Float) ---
	PathAddLineToPoint :: proc(path: MutablePathRef, m: ^AffineTransform, x: Float, y: Float) ---
	PathAddQuadCurveToPoint :: proc(path: MutablePathRef, m: ^AffineTransform, cpx: Float, cpy: Float, x: Float, y: Float) ---
	PathAddCurveToPoint :: proc(path: MutablePathRef, m: ^AffineTransform, cp1x: Float, cp1y: Float, cp2x: Float, cp2y: Float, x: Float, y: Float) ---
	PathCloseSubpath :: proc(path: MutablePathRef) ---
	PathAddRect :: proc(path: MutablePathRef, m: ^AffineTransform, rect: Rect) ---
	PathAddRects :: proc(path: MutablePathRef, m: ^AffineTransform, rects: [^]Rect, count: c.size_t) ---
	PathAddLines :: proc(path: MutablePathRef, m: ^AffineTransform, points: [^]Point, count: c.size_t) ---
	PathAddEllipseInRect :: proc(path: MutablePathRef, m: ^AffineTransform, rect: Rect) ---
	PathAddRelativeArc :: proc(path: MutablePathRef, _matrix: ^AffineTransform, x: Float, y: Float, radius: Float, startAngle: Float, delta: Float) ---
	PathAddArc :: proc(path: MutablePathRef, m: ^AffineTransform, x: Float, y: Float, radius: Float, startAngle: Float, endAngle: Float, clockwise: bool) ---
	PathAddArcToPoint :: proc(path: MutablePathRef, m: ^AffineTransform, x1: Float, y1: Float, x2: Float, y2: Float, radius: Float) ---
	PathAddPath :: proc(path1: MutablePathRef, m: ^AffineTransform, path2: PathRef) ---
	PathIsEmpty :: proc(path: PathRef) -> bool ---
	PathIsRect :: proc(path: PathRef, rect: ^Rect) -> bool ---
	PathGetCurrentPoint :: proc(path: PathRef) -> Point ---
	PathGetBoundingBox :: proc(path: PathRef) -> Rect ---
	PathGetPathBoundingBox :: proc(path: PathRef) -> Rect ---
	PathContainsPoint :: proc(path: PathRef, m: ^AffineTransform, point: Point, eoFill: bool) -> bool ---
	PathApply :: proc(path: PathRef, info: rawptr, function: PathApplierFunction) ---
	PathApplyWithBlock :: proc(path: PathRef, block: PathApplyBlock) ---
	PathCreateCopyByNormalizing :: proc(path: PathRef, evenOddFillRule: bool) -> PathRef ---
	PathCreateCopyByUnioningPath :: proc(path: PathRef, maskPath: PathRef, evenOddFillRule: bool) -> PathRef ---
	PathCreateCopyByIntersectingPath :: proc(path: PathRef, maskPath: PathRef, evenOddFillRule: bool) -> PathRef ---
	PathCreateCopyBySubtractingPath :: proc(path: PathRef, maskPath: PathRef, evenOddFillRule: bool) -> PathRef ---
	PathCreateCopyBySymmetricDifferenceOfPath :: proc(path: PathRef, maskPath: PathRef, evenOddFillRule: bool) -> PathRef ---
	PathCreateCopyOfLineBySubtractingPath :: proc(path: PathRef, maskPath: PathRef, evenOddFillRule: bool) -> PathRef ---
	PathCreateCopyOfLineByIntersectingPath :: proc(path: PathRef, maskPath: PathRef, evenOddFillRule: bool) -> PathRef ---
	PathCreateSeparateComponents :: proc(path: PathRef, evenOddFillRule: bool) -> CF.ArrayRef ---
	PathCreateCopyByFlattening :: proc(path: PathRef, flatteningThreshold: Float) -> PathRef ---
	PathIntersectsPath :: proc(path1: PathRef, path2: PathRef, evenOddFillRule: bool) -> bool ---
	PDFObjectGetType :: proc(object: PDFObjectRef) -> PDFObjectType ---
	PDFObjectGetValue :: proc(object: PDFObjectRef, type: PDFObjectType, value: rawptr) -> bool ---
	PDFStreamGetDictionary :: proc(stream: PDFStreamRef) -> PDFDictionaryRef ---
	PDFStreamCopyData :: proc(stream: PDFStreamRef, format: ^PDFDataFormat) -> CF.DataRef ---
	PDFStringGetLength :: proc(string: PDFStringRef) -> c.size_t ---
	PDFStringGetBytePtr :: proc(string: PDFStringRef) -> [^]byte ---
	PDFStringCopyTextString :: proc(string: PDFStringRef) -> CF.StringRef ---
	PDFStringCopyDate :: proc(string: PDFStringRef) -> CF.DateRef ---
	PDFArrayGetCount :: proc(array: PDFArrayRef) -> c.size_t ---
	PDFArrayGetObject :: proc(array: PDFArrayRef, index: c.size_t, value: ^PDFObjectRef) -> bool ---
	PDFArrayGetNull :: proc(array: PDFArrayRef, index: c.size_t) -> bool ---
	PDFArrayGetBoolean :: proc(array: PDFArrayRef, index: c.size_t, value: ^PDFBoolean) -> bool ---
	PDFArrayGetInteger :: proc(array: PDFArrayRef, index: c.size_t, value: ^PDFInteger) -> bool ---
	PDFArrayGetNumber :: proc(array: PDFArrayRef, index: c.size_t, value: ^PDFReal) -> bool ---
	PDFArrayGetName :: proc(array: PDFArrayRef, index: c.size_t, value: ^cstring) -> bool ---
	PDFArrayGetString :: proc(array: PDFArrayRef, index: c.size_t, value: ^PDFStringRef) -> bool ---
	PDFArrayGetArray :: proc(array: PDFArrayRef, index: c.size_t, value: ^PDFArrayRef) -> bool ---
	PDFArrayGetDictionary :: proc(array: PDFArrayRef, index: c.size_t, value: ^PDFDictionaryRef) -> bool ---
	PDFArrayGetStream :: proc(array: PDFArrayRef, index: c.size_t, value: ^PDFStreamRef) -> bool ---
	PDFArrayApplyBlock :: proc(array: PDFArrayRef, block: PDFArrayApplierBlock, info: rawptr) ---
	PDFDictionaryGetCount :: proc(dict: PDFDictionaryRef) -> c.size_t ---
	PDFDictionaryGetObject :: proc(dict: PDFDictionaryRef, key: cstring, value: ^PDFObjectRef) -> bool ---
	PDFDictionaryGetBoolean :: proc(dict: PDFDictionaryRef, key: cstring, value: ^PDFBoolean) -> bool ---
	PDFDictionaryGetInteger :: proc(dict: PDFDictionaryRef, key: cstring, value: ^PDFInteger) -> bool ---
	PDFDictionaryGetNumber :: proc(dict: PDFDictionaryRef, key: cstring, value: ^PDFReal) -> bool ---
	PDFDictionaryGetName :: proc(dict: PDFDictionaryRef, key: cstring, value: ^cstring) -> bool ---
	PDFDictionaryGetString :: proc(dict: PDFDictionaryRef, key: cstring, value: ^PDFStringRef) -> bool ---
	PDFDictionaryGetArray :: proc(dict: PDFDictionaryRef, key: cstring, value: ^PDFArrayRef) -> bool ---
	PDFDictionaryGetDictionary :: proc(dict: PDFDictionaryRef, key: cstring, value: ^PDFDictionaryRef) -> bool ---
	PDFDictionaryGetStream :: proc(dict: PDFDictionaryRef, key: cstring, value: ^PDFStreamRef) -> bool ---
	PDFDictionaryApplyFunction :: proc(dict: PDFDictionaryRef, function: PDFDictionaryApplierFunction, info: rawptr) ---
	PDFDictionaryApplyBlock :: proc(dict: PDFDictionaryRef, block: PDFDictionaryApplierBlock, info: rawptr) ---
	PDFPageRetain :: proc(page: PDFPageRef) -> PDFPageRef ---
	PDFPageRelease :: proc(page: PDFPageRef) ---
	PDFPageGetDocument :: proc(page: PDFPageRef) -> PDFDocumentRef ---
	PDFPageGetPageNumber :: proc(page: PDFPageRef) -> c.size_t ---
	PDFPageGetBoxRect :: proc(page: PDFPageRef, box: PDFBox) -> Rect ---
	PDFPageGetRotationAngle :: proc(page: PDFPageRef) -> c.int ---
	PDFPageGetDrawingTransform :: proc(page: PDFPageRef, box: PDFBox, rect: Rect, rotate: c.int, preserveAspectRatio: bool) -> AffineTransform ---
	PDFPageGetDictionary :: proc(page: PDFPageRef) -> PDFDictionaryRef ---
	PDFPageGetTypeID :: proc() -> CF.TypeID ---
	PDFDocumentCreateWithProvider :: proc(provider: DataProviderRef) -> PDFDocumentRef ---
	PDFDocumentCreateWithURL :: proc(url: CF.URLRef) -> PDFDocumentRef ---
	PDFDocumentRetain :: proc(document: PDFDocumentRef) -> PDFDocumentRef ---
	PDFDocumentRelease :: proc(document: PDFDocumentRef) ---
	PDFDocumentGetVersion :: proc(document: PDFDocumentRef, majorVersion: ^c.int, minorVersion: ^c.int) ---
	PDFDocumentIsEncrypted :: proc(document: PDFDocumentRef) -> bool ---
	PDFDocumentUnlockWithPassword :: proc(document: PDFDocumentRef, password: cstring) -> bool ---
	PDFDocumentIsUnlocked :: proc(document: PDFDocumentRef) -> bool ---
	PDFDocumentAllowsPrinting :: proc(document: PDFDocumentRef) -> bool ---
	PDFDocumentAllowsCopying :: proc(document: PDFDocumentRef) -> bool ---
	PDFDocumentGetNumberOfPages :: proc(document: PDFDocumentRef) -> c.size_t ---
	PDFDocumentGetPage :: proc(document: PDFDocumentRef, pageNumber: c.size_t) -> PDFPageRef ---
	PDFDocumentGetCatalog :: proc(document: PDFDocumentRef) -> PDFDictionaryRef ---
	PDFDocumentGetInfo :: proc(document: PDFDocumentRef) -> PDFDictionaryRef ---
	PDFDocumentGetID :: proc(document: PDFDocumentRef) -> PDFArrayRef ---
	PDFDocumentGetTypeID :: proc() -> CF.TypeID ---
	PDFDocumentGetOutline :: proc(document: PDFDocumentRef) -> CF.DictionaryRef ---
	PDFDocumentGetAccessPermissions :: proc(document: PDFDocumentRef) -> PDFAccessPermissions ---
	PDFDocumentGetMediaBox :: proc(document: PDFDocumentRef, page: c.int) -> Rect ---
	PDFDocumentGetCropBox :: proc(document: PDFDocumentRef, page: c.int) -> Rect ---
	PDFDocumentGetBleedBox :: proc(document: PDFDocumentRef, page: c.int) -> Rect ---
	PDFDocumentGetTrimBox :: proc(document: PDFDocumentRef, page: c.int) -> Rect ---
	PDFDocumentGetArtBox :: proc(document: PDFDocumentRef, page: c.int) -> Rect ---
	PDFDocumentGetRotationAngle :: proc(document: PDFDocumentRef, page: c.int) -> c.int ---
	FunctionGetTypeID :: proc() -> CF.TypeID ---
	FunctionCreate :: proc(info: rawptr, domainDimension: c.size_t, domain: ^Float, rangeDimension: c.size_t, range: ^Float, callbacks: ^FunctionCallbacks) -> FunctionRef ---
	FunctionRetain :: proc(function: FunctionRef) -> FunctionRef ---
	FunctionRelease :: proc(function: FunctionRef) ---
	ShadingGetTypeID :: proc() -> CF.TypeID ---
	ShadingCreateAxial :: proc(space: ColorSpaceRef, start: Point, end: Point, function: FunctionRef, extendStart: bool, extendEnd: bool) -> ShadingRef ---
	ShadingCreateAxialWithContentHeadroom :: proc(headroom: f32, space: ColorSpaceRef, start: Point, end: Point, function: FunctionRef, extendStart: bool, extendEnd: bool) -> ShadingRef ---
	ShadingCreateRadial :: proc(space: ColorSpaceRef, start: Point, startRadius: Float, end: Point, endRadius: Float, function: FunctionRef, extendStart: bool, extendEnd: bool) -> ShadingRef ---
	ShadingCreateRadialWithContentHeadroom :: proc(headroom: f32, space: ColorSpaceRef, start: Point, startRadius: Float, end: Point, endRadius: Float, function: FunctionRef, extendStart: bool, extendEnd: bool) -> ShadingRef ---
	ShadingRetain :: proc(shading: ShadingRef) -> ShadingRef ---
	ShadingRelease :: proc(shading: ShadingRef) ---
	ShadingGetContentHeadroom :: proc(shading: ShadingRef) -> f32 ---
	EXRToneMappingGammaGetDefaultOptions :: proc() -> CF.DictionaryRef ---
	ContextGetTypeID :: proc() -> CF.TypeID ---
	ContextSaveGState :: proc(ctx: ContextRef) ---
	ContextRestoreGState :: proc(ctx: ContextRef) ---
	ContextScaleCTM :: proc(ctx: ContextRef, sx: Float, sy: Float) ---
	ContextTranslateCTM :: proc(ctx: ContextRef, tx: Float, ty: Float) ---
	ContextRotateCTM :: proc(ctx: ContextRef, angle: Float) ---
	ContextConcatCTM :: proc(ctx: ContextRef, transform: AffineTransform) ---
	ContextGetCTM :: proc(ctx: ContextRef) -> AffineTransform ---
	ContextSetLineWidth :: proc(ctx: ContextRef, width: Float) ---
	ContextSetLineCap :: proc(ctx: ContextRef, cap: LineCap) ---
	ContextSetLineJoin :: proc(ctx: ContextRef, join: LineJoin) ---
	ContextSetMiterLimit :: proc(ctx: ContextRef, limit: Float) ---
	ContextSetLineDash :: proc(ctx: ContextRef, phase: Float, lengths: [^]Float, count: c.size_t) ---
	ContextSetFlatness :: proc(ctx: ContextRef, flatness: Float) ---
	ContextSetAlpha :: proc(ctx: ContextRef, alpha: Float) ---
	ContextSetBlendMode :: proc(ctx: ContextRef, mode: BlendMode) ---
	ContextBeginPath :: proc(ctx: ContextRef) ---
	ContextMoveToPoint :: proc(ctx: ContextRef, x: Float, y: Float) ---
	ContextAddLineToPoint :: proc(ctx: ContextRef, x: Float, y: Float) ---
	ContextAddCurveToPoint :: proc(ctx: ContextRef, cp1x: Float, cp1y: Float, cp2x: Float, cp2y: Float, x: Float, y: Float) ---
	ContextAddQuadCurveToPoint :: proc(ctx: ContextRef, cpx: Float, cpy: Float, x: Float, y: Float) ---
	ContextClosePath :: proc(ctx: ContextRef) ---
	ContextAddRect :: proc(ctx: ContextRef, rect: Rect) ---
	ContextAddRects :: proc(ctx: ContextRef, rects: [^]Rect, count: c.size_t) ---
	ContextAddLines :: proc(ctx: ContextRef, points: [^]Point, count: c.size_t) ---
	ContextAddEllipseInRect :: proc(ctx: ContextRef, rect: Rect) ---
	ContextAddArc :: proc(ctx: ContextRef, x: Float, y: Float, radius: Float, startAngle: Float, endAngle: Float, clockwise: c.int) ---
	ContextAddArcToPoint :: proc(ctx: ContextRef, x1: Float, y1: Float, x2: Float, y2: Float, radius: Float) ---
	ContextAddPath :: proc(ctx: ContextRef, path: PathRef) ---
	ContextReplacePathWithStrokedPath :: proc(ctx: ContextRef) ---
	ContextIsPathEmpty :: proc(ctx: ContextRef) -> bool ---
	ContextGetPathCurrentPoint :: proc(ctx: ContextRef) -> Point ---
	ContextGetPathBoundingBox :: proc(ctx: ContextRef) -> Rect ---
	ContextCopyPath :: proc(ctx: ContextRef) -> PathRef ---
	ContextPathContainsPoint :: proc(ctx: ContextRef, point: Point, mode: PathDrawingMode) -> bool ---
	ContextDrawPath :: proc(ctx: ContextRef, mode: PathDrawingMode) ---
	ContextFillPath :: proc(ctx: ContextRef) ---
	ContextEOFillPath :: proc(ctx: ContextRef) ---
	ContextStrokePath :: proc(ctx: ContextRef) ---
	ContextFillRect :: proc(ctx: ContextRef, rect: Rect) ---
	ContextFillRects :: proc(ctx: ContextRef, rects: [^]Rect, count: c.size_t) ---
	ContextStrokeRect :: proc(ctx: ContextRef, rect: Rect) ---
	ContextStrokeRectWithWidth :: proc(ctx: ContextRef, rect: Rect, width: Float) ---
	ContextClearRect :: proc(ctx: ContextRef, rect: Rect) ---
	ContextFillEllipseInRect :: proc(ctx: ContextRef, rect: Rect) ---
	ContextStrokeEllipseInRect :: proc(ctx: ContextRef, rect: Rect) ---
	ContextStrokeLineSegments :: proc(ctx: ContextRef, points: [^]Point, count: c.size_t) ---
	ContextClip :: proc(ctx: ContextRef) ---
	ContextEOClip :: proc(ctx: ContextRef) ---
	ContextResetClip :: proc(ctx: ContextRef) ---
	ContextClipToMask :: proc(ctx: ContextRef, rect: Rect, mask: ImageRef) ---
	ContextGetClipBoundingBox :: proc(ctx: ContextRef) -> Rect ---
	ContextClipToRect :: proc(ctx: ContextRef, rect: Rect) ---
	ContextClipToRects :: proc(ctx: ContextRef, rects: [^]Rect, count: c.size_t) ---
	ContextSetFillColorWithColor :: proc(ctx: ContextRef, color: ColorRef) ---
	ContextSetStrokeColorWithColor :: proc(ctx: ContextRef, color: ColorRef) ---
	ContextSetFillColorSpace :: proc(ctx: ContextRef, space: ColorSpaceRef) ---
	ContextSetStrokeColorSpace :: proc(ctx: ContextRef, space: ColorSpaceRef) ---
	ContextSetFillColor :: proc(ctx: ContextRef, components: [^]Float) ---
	ContextSetStrokeColor :: proc(ctx: ContextRef, components: [^]Float) ---
	ContextSetFillPattern :: proc(ctx: ContextRef, pattern: PatternRef, components: [^]Float) ---
	ContextSetStrokePattern :: proc(ctx: ContextRef, pattern: PatternRef, components: [^]Float) ---
	ContextSetPatternPhase :: proc(ctx: ContextRef, phase: Size) ---
	ContextSetGrayFillColor :: proc(ctx: ContextRef, gray: Float, alpha: Float) ---
	ContextSetGrayStrokeColor :: proc(ctx: ContextRef, gray: Float, alpha: Float) ---
	ContextSetRGBFillColor :: proc(ctx: ContextRef, red: Float, green: Float, blue: Float, alpha: Float) ---
	ContextSetRGBStrokeColor :: proc(ctx: ContextRef, red: Float, green: Float, blue: Float, alpha: Float) ---
	ContextSetCMYKFillColor :: proc(ctx: ContextRef, cyan: Float, magenta: Float, yellow: Float, black: Float, alpha: Float) ---
	ContextSetCMYKStrokeColor :: proc(ctx: ContextRef, cyan: Float, magenta: Float, yellow: Float, black: Float, alpha: Float) ---
	ContextSetRenderingIntent :: proc(ctx: ContextRef, intent: ColorRenderingIntent) ---
	ContextSetEDRTargetHeadroom :: proc(ctx: ContextRef, headroom: f32) -> bool ---
	ContextGetEDRTargetHeadroom :: proc(ctx: ContextRef) -> f32 ---
	ContextDrawImage :: proc(ctx: ContextRef, rect: Rect, image: ImageRef) ---
	ContextDrawTiledImage :: proc(ctx: ContextRef, rect: Rect, image: ImageRef) ---
	ContextDrawImageApplyingToneMapping :: proc(ctx: ContextRef, r: Rect, image: ImageRef, method: ToneMapping, options: CF.DictionaryRef) -> bool ---
	ContextGetContentToneMappingInfo :: proc(ctx: ContextRef) -> ContentToneMappingInfo ---
	ContextSetContentToneMappingInfo :: proc(ctx: ContextRef, info: ContentToneMappingInfo) ---
	ContextGetInterpolationQuality :: proc(ctx: ContextRef) -> InterpolationQuality ---
	ContextSetInterpolationQuality :: proc(ctx: ContextRef, quality: InterpolationQuality) ---
	ContextSetShadowWithColor :: proc(ctx: ContextRef, offset: Size, blur: Float, color: ColorRef) ---
	ContextSetShadow :: proc(ctx: ContextRef, offset: Size, blur: Float) ---
	ContextDrawLinearGradient :: proc(ctx: ContextRef, gradient: GradientRef, startPoint: Point, endPoint: Point, options: GradientDrawingOptions) ---
	ContextDrawRadialGradient :: proc(ctx: ContextRef, gradient: GradientRef, startCenter: Point, startRadius: Float, endCenter: Point, endRadius: Float, options: GradientDrawingOptions) ---
	ContextDrawConicGradient :: proc(ctx: ContextRef, gradient: GradientRef, center: Point, angle: Float) ---
	ContextDrawShading :: proc(ctx: ContextRef, shading: ShadingRef) ---
	ContextSetCharacterSpacing :: proc(ctx: ContextRef, spacing: Float) ---
	ContextSetTextPosition :: proc(ctx: ContextRef, x: Float, y: Float) ---
	ContextGetTextPosition :: proc(ctx: ContextRef) -> Point ---
	ContextSetTextMatrix :: proc(ctx: ContextRef, t: AffineTransform) ---
	ContextGetTextMatrix :: proc(ctx: ContextRef) -> AffineTransform ---
	ContextSetTextDrawingMode :: proc(ctx: ContextRef, mode: TextDrawingMode) ---
	ContextSetFont :: proc(ctx: ContextRef, font: FontRef) ---
	ContextSetFontSize :: proc(ctx: ContextRef, size: Float) ---
	ContextShowGlyphsAtPositions :: proc(ctx: ContextRef, glyphs: [^]Glyph, Lpositions: [^]Point, count: c.size_t) ---
	ContextDrawPDFPage :: proc(ctx: ContextRef, page: PDFPageRef) ---
	ContextBeginPage :: proc(ctx: ContextRef, mediaBox: ^Rect) ---
	ContextEndPage :: proc(ctx: ContextRef) ---
	ContextRetain :: proc(ctx: ContextRef) -> ContextRef ---
	ContextRelease :: proc(ctx: ContextRef) ---
	ContextFlush :: proc(ctx: ContextRef) ---
	ContextSynchronize :: proc(ctx: ContextRef) ---
	ContextSynchronizeAttributes :: proc(ctx: ContextRef) ---
	ContextSetShouldAntialias :: proc(ctx: ContextRef, shouldAntialias: bool) ---
	ContextSetAllowsAntialiasing :: proc(ctx: ContextRef, allowsAntialiasing: bool) ---
	ContextSetShouldSmoothFonts :: proc(ctx: ContextRef, shouldSmoothFonts: bool) ---
	ContextSetAllowsFontSmoothing :: proc(ctx: ContextRef, allowsFontSmoothing: bool) ---
	ContextSetShouldSubpixelPositionFonts :: proc(ctx: ContextRef, shouldSubpixelPositionFonts: bool) ---
	ContextSetAllowsFontSubpixelPositioning :: proc(ctx: ContextRef, allowsFontSubpixelPositioning: bool) ---
	ContextSetShouldSubpixelQuantizeFonts :: proc(ctx: ContextRef, shouldSubpixelQuantizeFonts: bool) ---
	ContextSetAllowsFontSubpixelQuantization :: proc(ctx: ContextRef, allowsFontSubpixelQuantization: bool) ---
	ContextBeginTransparencyLayer :: proc(ctx: ContextRef, auxiliaryInfo: CF.DictionaryRef) ---
	ContextBeginTransparencyLayerWithRect :: proc(ctx: ContextRef, rect: Rect, auxInfo: CF.DictionaryRef) ---
	ContextEndTransparencyLayer :: proc(ctx: ContextRef) ---
	ContextGetUserSpaceToDeviceSpaceTransform :: proc(ctx: ContextRef) -> AffineTransform ---
	ContextConvertPointToDeviceSpace :: proc(ctx: ContextRef, point: Point) -> Point ---
	ContextConvertPointToUserSpace :: proc(ctx: ContextRef, point: Point) -> Point ---
	ContextConvertSizeToDeviceSpace :: proc(ctx: ContextRef, size: Size) -> Size ---
	ContextConvertSizeToUserSpace :: proc(ctx: ContextRef, size: Size) -> Size ---
	ContextConvertRectToDeviceSpace :: proc(ctx: ContextRef, rect: Rect) -> Rect ---
	ContextConvertRectToUserSpace :: proc(ctx: ContextRef, rect: Rect) -> Rect ---
	ContextSelectFont :: proc(ctx: ContextRef, name: cstring, size: Float, textEncoding: TextEncoding) ---
	ContextShowText :: proc(ctx: ContextRef, string: cstring, length: c.size_t) ---
	ContextShowTextAtPoint :: proc(ctx: ContextRef, x: Float, y: Float, string: cstring, length: c.size_t) ---
	ContextShowGlyphs :: proc(ctx: ContextRef, g: ^Glyph, count: c.size_t) ---
	ContextShowGlyphsAtPoint :: proc(ctx: ContextRef, x: Float, y: Float, glyphs: [^]Glyph, count: c.size_t) ---
	ContextShowGlyphsWithAdvances :: proc(ctx: ContextRef, glyphs: [^]Glyph, advances: [^]Size, count: c.size_t) ---
	ContextDrawPDFDocument :: proc(ctx: ContextRef, rect: Rect, document: PDFDocumentRef, page: c.int) ---
	RenderingBufferProviderCreate :: proc(info: rawptr, size: c.size_t, lockPointer: ^Objc_Block(proc "c" (info: rawptr) -> rawptr), unlockPointer: ^Objc_Block(proc "c" (info: rawptr, pointer: rawptr)), releaseInfo: ^Objc_Block(proc "c" (info: rawptr))) -> RenderingBufferProviderRef ---
	RenderingBufferProviderCreateWithCFData :: proc(data: CF.MutableDataRef) -> RenderingBufferProviderRef ---
	RenderingBufferProviderGetSize :: proc(provider: RenderingBufferProviderRef) -> c.size_t ---
	RenderingBufferLockBytePtr :: proc(provider: RenderingBufferProviderRef) -> rawptr ---
	RenderingBufferUnlockBytePtr :: proc(provider: RenderingBufferProviderRef) ---
	RenderingBufferProviderGetTypeID :: proc() -> CF.TypeID ---
	BitmapContextCreateWithData :: proc(data: rawptr, width: c.size_t, height: c.size_t, bitsPerComponent: c.size_t, bytesPerRow: c.size_t, space: ColorSpaceRef, bitmapInfo: BitmapInfo, releaseCallback: BitmapContextReleaseDataCallback, releaseInfo: rawptr) -> ContextRef ---
	BitmapContextCreate :: proc(data: rawptr, width: c.size_t, height: c.size_t, bitsPerComponent: c.size_t, bytesPerRow: c.size_t, space: ColorSpaceRef, bitmapInfo: BitmapInfo) -> ContextRef ---
	BitmapContextCreateAdaptive :: proc(width: c.size_t, height: c.size_t, auxiliaryInfo: CF.DictionaryRef, onResolve: ^Objc_Block(proc "c" (_: ^ContentInfo, _1: ^BitmapParameters) -> bool), onAllocate: ^Objc_Block(proc "c" (_: ^ContentInfo, _1: ^BitmapParameters) -> RenderingBufferProviderRef), onFree: ^Objc_Block(proc "c" (_: RenderingBufferProviderRef, _1: ^ContentInfo, _2: ^BitmapParameters)), onError: ^Objc_Block(proc "c" (_: CF.ErrorRef, _1: ^ContentInfo, _2: ^BitmapParameters))) -> ContextRef ---
	BitmapContextGetData :: proc(_context: ContextRef) -> rawptr ---
	BitmapContextGetWidth :: proc(_context: ContextRef) -> c.size_t ---
	BitmapContextGetHeight :: proc(_context: ContextRef) -> c.size_t ---
	BitmapContextGetBitsPerComponent :: proc(_context: ContextRef) -> c.size_t ---
	BitmapContextGetBitsPerPixel :: proc(_context: ContextRef) -> c.size_t ---
	BitmapContextGetBytesPerRow :: proc(_context: ContextRef) -> c.size_t ---
	BitmapContextGetColorSpace :: proc(_context: ContextRef) -> ColorSpaceRef ---
	BitmapContextGetAlphaInfo :: proc(_context: ContextRef) -> ImageAlphaInfo ---
	BitmapContextGetBitmapInfo :: proc(_context: ContextRef) -> BitmapInfo ---
	BitmapContextCreateImage :: proc(_context: ContextRef) -> ImageRef ---
	ColorConversionInfoGetTypeID :: proc() -> CF.TypeID ---
	ColorConversionInfoCreate :: proc(src: ColorSpaceRef, dst: ColorSpaceRef) -> ColorConversionInfoRef ---
	ColorConversionInfoCreateWithOptions :: proc(src: ColorSpaceRef, dst: ColorSpaceRef, options: CF.DictionaryRef) -> ColorConversionInfoRef ---
	ColorConversionInfoCreateFromList :: proc(options: CF.DictionaryRef, _0: ColorSpaceRef, _1: ColorConversionInfoTransformType, _2: ColorRenderingIntent, #c_vararg args: ..any) -> ColorConversionInfoRef ---
	ColorConversionInfoCreateFromListWithArguments :: proc(options: CF.DictionaryRef, _0: ColorSpaceRef, _1: ColorConversionInfoTransformType, _2: ColorRenderingIntent, _3: ^c.va_list) -> ColorConversionInfoRef ---
	ColorConversionInfoCreateForToneMapping :: proc(from: ColorSpaceRef, source_headroom: f32, to: ColorSpaceRef, target_headroom: f32, method: ToneMapping, options: CF.DictionaryRef, error: ^CF.ErrorRef) -> ColorConversionInfoRef ---
	ColorConversionInfoConvertData :: proc(info: ColorConversionInfoRef, width: c.size_t, height: c.size_t, dst_data: rawptr, dst_format: ColorBufferFormat, src_data: rawptr, src_format: ColorBufferFormat, options: CF.DictionaryRef) -> bool ---
	ConvertColorDataWithFormat :: proc(width: c.size_t, height: c.size_t, dst_data: rawptr, dst_format: ColorDataFormat, src_data: rawptr, src_format: ColorDataFormat, options: CF.DictionaryRef) -> bool ---
	DataConsumerGetTypeID :: proc() -> CF.TypeID ---
	DataConsumerCreate :: proc(info: rawptr, cbks: ^DataConsumerCallbacks) -> DataConsumerRef ---
	DataConsumerCreateWithURL :: proc(url: CF.URLRef) -> DataConsumerRef ---
	DataConsumerCreateWithCFData :: proc(data: CF.MutableDataRef) -> DataConsumerRef ---
	DataConsumerRetain :: proc(consumer: DataConsumerRef) -> DataConsumerRef ---
	DataConsumerRelease :: proc(consumer: DataConsumerRef) ---
	ErrorSetCallback :: proc(callback: ErrorCallback) ---
	LayerCreateWithContext :: proc(_context: ContextRef, size: Size, auxiliaryInfo: CF.DictionaryRef) -> LayerRef ---
	LayerRetain :: proc(layer: LayerRef) -> LayerRef ---
	LayerRelease :: proc(layer: LayerRef) ---
	LayerGetSize :: proc(layer: LayerRef) -> Size ---
	LayerGetContext :: proc(layer: LayerRef) -> ContextRef ---
	ContextDrawLayerInRect :: proc(_context: ContextRef, rect: Rect, layer: LayerRef) ---
	ContextDrawLayerAtPoint :: proc(_context: ContextRef, point: Point, layer: LayerRef) ---
	LayerGetTypeID :: proc() -> CF.TypeID ---
	PDFContentStreamCreateWithPage :: proc(page: PDFPageRef) -> PDFContentStreamRef ---
	PDFContentStreamCreateWithStream :: proc(stream: PDFStreamRef, streamResources: PDFDictionaryRef, parent: PDFContentStreamRef) -> PDFContentStreamRef ---
	PDFContentStreamRetain :: proc(cs: PDFContentStreamRef) -> PDFContentStreamRef ---
	PDFContentStreamRelease :: proc(cs: PDFContentStreamRef) ---
	PDFContentStreamGetStreams :: proc(cs: PDFContentStreamRef) -> CF.ArrayRef ---
	PDFContentStreamGetResource :: proc(cs: PDFContentStreamRef, category: cstring, name: cstring) -> PDFObjectRef ---
	PDFContextCreate :: proc(consumer: DataConsumerRef, mediaBox: ^Rect, auxiliaryInfo: CF.DictionaryRef) -> ContextRef ---
	PDFContextCreateWithURL :: proc(url: CF.URLRef, mediaBox: ^Rect, auxiliaryInfo: CF.DictionaryRef) -> ContextRef ---
	PDFContextClose :: proc(_context: ContextRef) ---
	PDFContextBeginPage :: proc(_context: ContextRef, pageInfo: CF.DictionaryRef) ---
	PDFContextEndPage :: proc(_context: ContextRef) ---
	PDFContextAddDocumentMetadata :: proc(_context: ContextRef, metadata: CF.DataRef) ---
	PDFContextSetParentTree :: proc(_context: ContextRef, parentTreeDictionary: PDFDictionaryRef) ---
	PDFContextSetIDTree :: proc(_context: ContextRef, IDTreeDictionary: PDFDictionaryRef) ---
	PDFContextSetPageTagStructureTree :: proc(_context: ContextRef, pageTagStructureTreeDictionary: CF.DictionaryRef) ---
	PDFContextSetURLForRect :: proc(_context: ContextRef, url: CF.URLRef, rect: Rect) ---
	PDFContextAddDestinationAtPoint :: proc(_context: ContextRef, name: CF.StringRef, point: Point) ---
	PDFContextSetDestinationForRect :: proc(_context: ContextRef, name: CF.StringRef, rect: Rect) ---
	PDFContextSetOutline :: proc(_context: ContextRef, outline: CF.DictionaryRef) ---
	PDFTagTypeGetName :: proc(tagType: PDFTagType) -> cstring ---
	PDFContextBeginTag :: proc(_context: ContextRef, tagType: PDFTagType, tagProperties: CF.DictionaryRef) ---
	PDFContextEndTag :: proc(_context: ContextRef) ---
	PDFScannerCreate :: proc(cs: PDFContentStreamRef, table: PDFOperatorTableRef, info: rawptr) -> PDFScannerRef ---
	PDFScannerRetain :: proc(scanner: PDFScannerRef) -> PDFScannerRef ---
	PDFScannerRelease :: proc(scanner: PDFScannerRef) ---
	PDFScannerScan :: proc(scanner: PDFScannerRef) -> bool ---
	PDFScannerGetContentStream :: proc(scanner: PDFScannerRef) -> PDFContentStreamRef ---
	PDFScannerPopObject :: proc(scanner: PDFScannerRef, value: ^PDFObjectRef) -> bool ---
	PDFScannerPopBoolean :: proc(scanner: PDFScannerRef, value: ^PDFBoolean) -> bool ---
	PDFScannerPopInteger :: proc(scanner: PDFScannerRef, value: ^PDFInteger) -> bool ---
	PDFScannerPopNumber :: proc(scanner: PDFScannerRef, value: ^PDFReal) -> bool ---
	PDFScannerPopName :: proc(scanner: PDFScannerRef, value: ^cstring) -> bool ---
	PDFScannerPopString :: proc(scanner: PDFScannerRef, value: ^PDFStringRef) -> bool ---
	PDFScannerPopArray :: proc(scanner: PDFScannerRef, value: ^PDFArrayRef) -> bool ---
	PDFScannerPopDictionary :: proc(scanner: PDFScannerRef, value: ^PDFDictionaryRef) -> bool ---
	PDFScannerPopStream :: proc(scanner: PDFScannerRef, value: ^PDFStreamRef) -> bool ---
	PDFScannerStop :: proc(s: PDFScannerRef) ---
	PDFOperatorTableCreate :: proc() -> PDFOperatorTableRef ---
	PDFOperatorTableRetain :: proc(table: PDFOperatorTableRef) -> PDFOperatorTableRef ---
	PDFOperatorTableRelease :: proc(table: PDFOperatorTableRef) ---
	PDFOperatorTableSetCallback :: proc(table: PDFOperatorTableRef, name: cstring, callback: PDFOperatorCallback) ---
	WindowListCopyWindowInfo :: proc(option: WindowListOption, relativeToWindow: WindowID) -> CF.ArrayRef ---
	WindowListCreate :: proc(option: WindowListOption, relativeToWindow: WindowID) -> CF.ArrayRef ---
	WindowListCreateDescriptionFromArray :: proc(windowArray: CF.ArrayRef) -> CF.ArrayRef ---
	WindowListCreateImage :: proc(screenBounds: Rect, listOption: WindowListOption, windowID: WindowID, imageOption: WindowImageOption) -> ImageRef ---
	WindowListCreateImageFromArray :: proc(screenBounds: Rect, windowArray: CF.ArrayRef, imageOption: WindowImageOption) -> ImageRef ---
	PreflightScreenCaptureAccess :: proc() -> bool ---
	RequestScreenCaptureAccess :: proc() -> bool ---
	WindowLevelForKey :: proc(key: WindowLevelKey) -> WindowLevel ---
	MainDisplayID :: proc() -> DirectDisplayID ---
	GetDisplaysWithPoint :: proc(point: Point, maxDisplays: u32, displays: [^]DirectDisplayID, matchingDisplayCount: ^u32) -> Error ---
	GetDisplaysWithRect :: proc(rect: Rect, maxDisplays: u32, displays: [^]DirectDisplayID, matchingDisplayCount: ^u32) -> Error ---
	GetDisplaysWithOpenGLDisplayMask :: proc(mask: OpenGLDisplayMask, maxDisplays: u32, displays: [^]DirectDisplayID, matchingDisplayCount: ^u32) -> Error ---
	GetActiveDisplayList :: proc(maxDisplays: u32, activeDisplays: [^]DirectDisplayID, displayCount: ^u32) -> Error ---
	GetOnlineDisplayList :: proc(maxDisplays: u32, onlineDisplays: [^]DirectDisplayID, displayCount: ^u32) -> Error ---
	DisplayIDToOpenGLDisplayMask :: proc(display: DirectDisplayID) -> OpenGLDisplayMask ---
	OpenGLDisplayMaskToDisplayID :: proc(mask: OpenGLDisplayMask) -> DirectDisplayID ---
	DisplayBounds :: proc(display: DirectDisplayID) -> Rect ---
	DisplayPixelsWide :: proc(display: DirectDisplayID) -> c.size_t ---
	DisplayPixelsHigh :: proc(display: DirectDisplayID) -> c.size_t ---
	DisplayCopyAllDisplayModes :: proc(display: DirectDisplayID, options: CF.DictionaryRef) -> CF.ArrayRef ---
	DisplayCopyDisplayMode :: proc(display: DirectDisplayID) -> DisplayModeRef ---
	DisplaySetDisplayMode :: proc(display: DirectDisplayID, mode: DisplayModeRef, options: CF.DictionaryRef) -> Error ---
	DisplayModeGetWidth :: proc(mode: DisplayModeRef) -> c.size_t ---
	DisplayModeGetHeight :: proc(mode: DisplayModeRef) -> c.size_t ---
	DisplayModeCopyPixelEncoding :: proc(mode: DisplayModeRef) -> CF.StringRef ---
	DisplayModeGetRefreshRate :: proc(mode: DisplayModeRef) -> f64 ---
	DisplayModeGetIOFlags :: proc(mode: DisplayModeRef) -> u32 ---
	DisplayModeGetIODisplayModeID :: proc(mode: DisplayModeRef) -> i32 ---
	DisplayModeIsUsableForDesktopGUI :: proc(mode: DisplayModeRef) -> bool ---
	DisplayModeGetTypeID :: proc() -> CF.TypeID ---
	DisplayModeRetain :: proc(mode: DisplayModeRef) -> DisplayModeRef ---
	DisplayModeRelease :: proc(mode: DisplayModeRef) ---
	DisplayModeGetPixelWidth :: proc(mode: DisplayModeRef) -> c.size_t ---
	DisplayModeGetPixelHeight :: proc(mode: DisplayModeRef) -> c.size_t ---
	SetDisplayTransferByFormula :: proc(display: DirectDisplayID, redMin: GammaValue, redMax: GammaValue, redGamma: GammaValue, greenMin: GammaValue, greenMax: GammaValue, greenGamma: GammaValue, blueMin: GammaValue, blueMax: GammaValue, blueGamma: GammaValue) -> Error ---
	GetDisplayTransferByFormula :: proc(display: DirectDisplayID, redMin: ^GammaValue, redMax: ^GammaValue, redGamma: ^GammaValue, greenMin: ^GammaValue, greenMax: ^GammaValue, greenGamma: ^GammaValue, blueMin: ^GammaValue, blueMax: ^GammaValue, blueGamma: ^GammaValue) -> Error ---
	DisplayGammaTableCapacity :: proc(display: DirectDisplayID) -> u32 ---
	SetDisplayTransferByTable :: proc(display: DirectDisplayID, tableSize: u32, redTable: ^GammaValue, greenTable: ^GammaValue, blueTable: ^GammaValue) -> Error ---
	GetDisplayTransferByTable :: proc(display: DirectDisplayID, capacity: u32, redTable: ^GammaValue, greenTable: ^GammaValue, blueTable: ^GammaValue, sampleCount: ^u32) -> Error ---
	SetDisplayTransferByByteTable :: proc(display: DirectDisplayID, tableSize: u32, redTable, greenTable, blueTable: [^]u8) -> Error ---
	DisplayRestoreColorSyncSettings :: proc() ---
	DisplayIsCaptured :: proc(display: DirectDisplayID) -> darwin.boolean_t ---
	DisplayCapture :: proc(display: DirectDisplayID) -> Error ---
	DisplayCaptureWithOptions :: proc(display: DirectDisplayID, options: CaptureOptions) -> Error ---
	DisplayRelease :: proc(display: DirectDisplayID) -> Error ---
	CaptureAllDisplays :: proc() -> Error ---
	CaptureAllDisplaysWithOptions :: proc(options: CaptureOptions) -> Error ---
	ReleaseAllDisplays :: proc() -> Error ---
	ShieldingWindowID :: proc(display: DirectDisplayID) -> WindowID ---
	ShieldingWindowLevel :: proc() -> WindowLevel ---
	DisplayCreateImage :: proc(displayID: DirectDisplayID) -> ImageRef ---
	DisplayCreateImageForRect :: proc(display: DirectDisplayID, rect: Rect) -> ImageRef ---
	DisplayHideCursor :: proc(display: DirectDisplayID) -> Error ---
	DisplayShowCursor :: proc(display: DirectDisplayID) -> Error ---
	DisplayMoveCursorToPoint :: proc(display: DirectDisplayID, point: Point) -> Error ---
	GetLastMouseDelta :: proc(deltaX: ^i32, deltaY: ^i32) ---
	DisplayGetDrawingContext :: proc(display: DirectDisplayID) -> ContextRef ---
	DisplayAvailableModes :: proc(dsp: DirectDisplayID) -> CF.ArrayRef ---
	DisplayBestModeForParameters :: proc(display: DirectDisplayID, bitsPerPixel: c.size_t, width: c.size_t, height: c.size_t, exactMatch: ^darwin.boolean_t) -> CF.DictionaryRef ---
	DisplayBestModeForParametersAndRefreshRate :: proc(display: DirectDisplayID, bitsPerPixel: c.size_t, width: c.size_t, height: c.size_t, refreshRate: RefreshRate, exactMatch: ^darwin.boolean_t) -> CF.DictionaryRef ---
	DisplayCurrentMode :: proc(display: DirectDisplayID) -> CF.DictionaryRef ---
	DisplaySwitchToMode :: proc(display: DirectDisplayID, mode: CF.DictionaryRef) -> Error ---
	BeginDisplayConfiguration :: proc(config: ^DisplayConfigRef) -> Error ---
	ConfigureDisplayOrigin :: proc(config: DisplayConfigRef, display: DirectDisplayID, x: i32, y: i32) -> Error ---
	ConfigureDisplayWithDisplayMode :: proc(config: DisplayConfigRef, display: DirectDisplayID, mode: DisplayModeRef, options: CF.DictionaryRef) -> Error ---
	ConfigureDisplayStereoOperation :: proc(config: DisplayConfigRef, display: DirectDisplayID, stereo: darwin.boolean_t, forceBlueLine: darwin.boolean_t) -> Error ---
	ConfigureDisplayMirrorOfDisplay :: proc(config: DisplayConfigRef, display: DirectDisplayID, master: DirectDisplayID) -> Error ---
	CancelDisplayConfiguration :: proc(config: DisplayConfigRef) -> Error ---
	CompleteDisplayConfiguration :: proc(config: DisplayConfigRef, option: ConfigureOption) -> Error ---
	RestorePermanentDisplayConfiguration :: proc() ---
	DisplayRegisterReconfigurationCallback :: proc(callback: DisplayReconfigurationCallBack, userInfo: rawptr) -> Error ---
	DisplayRemoveReconfigurationCallback :: proc(callback: DisplayReconfigurationCallBack, userInfo: rawptr) -> Error ---
	DisplaySetStereoOperation :: proc(display: DirectDisplayID, stereo: darwin.boolean_t, forceBlueLine: darwin.boolean_t, option: ConfigureOption) -> Error ---
	DisplayIsActive :: proc(display: DirectDisplayID) -> darwin.boolean_t ---
	DisplayIsAsleep :: proc(display: DirectDisplayID) -> darwin.boolean_t ---
	DisplayIsOnline :: proc(display: DirectDisplayID) -> darwin.boolean_t ---
	DisplayIsMain :: proc(display: DirectDisplayID) -> darwin.boolean_t ---
	DisplayIsBuiltin :: proc(display: DirectDisplayID) -> darwin.boolean_t ---
	DisplayIsInMirrorSet :: proc(display: DirectDisplayID) -> darwin.boolean_t ---
	DisplayIsAlwaysInMirrorSet :: proc(display: DirectDisplayID) -> darwin.boolean_t ---
	DisplayIsInHWMirrorSet :: proc(display: DirectDisplayID) -> darwin.boolean_t ---
	DisplayMirrorsDisplay :: proc(display: DirectDisplayID) -> DirectDisplayID ---
	DisplayUsesOpenGLAcceleration :: proc(display: DirectDisplayID) -> darwin.boolean_t ---
	DisplayIsStereo :: proc(display: DirectDisplayID) -> darwin.boolean_t ---
	DisplayPrimaryDisplay :: proc(display: DirectDisplayID) -> DirectDisplayID ---
	DisplayUnitNumber :: proc(display: DirectDisplayID) -> u32 ---
	DisplayVendorNumber :: proc(display: DirectDisplayID) -> u32 ---
	DisplayModelNumber :: proc(display: DirectDisplayID) -> u32 ---
	DisplaySerialNumber :: proc(display: DirectDisplayID) -> u32 ---
	DisplayIOServicePort :: proc(display: DirectDisplayID) -> darwin.mach_port_t ---
	DisplayScreenSize :: proc(display: DirectDisplayID) -> Size ---
	DisplayRotation :: proc(display: DirectDisplayID) -> f64 ---
	DisplayCopyColorSpace :: proc(display: DirectDisplayID) -> ColorSpaceRef ---
	ConfigureDisplayMode :: proc(config: DisplayConfigRef, display: DirectDisplayID, mode: CF.DictionaryRef) -> Error ---
	ConfigureDisplayFadeEffect :: proc(config: DisplayConfigRef, fadeOutSeconds: DisplayFadeInterval, fadeInSeconds: DisplayFadeInterval, fadeRed: f32, fadeGreen: f32, fadeBlue: f32) -> Error ---
	AcquireDisplayFadeReservation :: proc(seconds: DisplayReservationInterval, token: ^DisplayFadeReservationToken) -> Error ---
	ReleaseDisplayFadeReservation :: proc(token: DisplayFadeReservationToken) -> Error ---
	DisplayFade :: proc(token: DisplayFadeReservationToken, duration: DisplayFadeInterval, startBlend: DisplayBlendFraction, endBlend: DisplayBlendFraction, redBlend: f32, greenBlend: f32, blueBlend: f32, synchronous: darwin.boolean_t) -> Error ---
	DisplayFadeOperationInProgress :: proc() -> darwin.boolean_t ---
	DisplayStreamUpdateGetTypeID :: proc() -> CF.TypeID ---
	DisplayStreamUpdateGetRects :: proc(updateRef: DisplayStreamUpdateRef, rectType: DisplayStreamUpdateRectType, rectCount: ^c.size_t) -> ^Rect ---
	DisplayStreamUpdateCreateMergedUpdate :: proc(firstUpdate: DisplayStreamUpdateRef, secondUpdate: DisplayStreamUpdateRef) -> DisplayStreamUpdateRef ---
	DisplayStreamUpdateGetMovedRectsDelta :: proc(updateRef: DisplayStreamUpdateRef, dx: ^Float, dy: ^Float) ---
	DisplayStreamUpdateGetDropCount :: proc(updateRef: DisplayStreamUpdateRef) -> c.size_t ---
	DisplayStreamGetTypeID :: proc() -> CF.TypeID ---
	DisplayStreamCreate :: proc(display: DirectDisplayID, outputWidth: c.size_t, outputHeight: c.size_t, pixelFormat: i32, properties: CF.DictionaryRef, handler: DisplayStreamFrameAvailableHandler) -> DisplayStreamRef ---
	DisplayStreamCreateWithDispatchQueue :: proc(display: DirectDisplayID, outputWidth: c.size_t, outputHeight: c.size_t, pixelFormat: i32, properties: CF.DictionaryRef, queue: CF.dispatch_queue_t, handler: DisplayStreamFrameAvailableHandler) -> DisplayStreamRef ---
	DisplayStreamStart :: proc(displayStream: DisplayStreamRef) -> Error ---
	DisplayStreamStop :: proc(displayStream: DisplayStreamRef) -> Error ---
	DisplayStreamGetRunLoopSource :: proc(displayStream: DisplayStreamRef) -> CF.RunLoopSourceRef ---
	RegisterScreenRefreshCallback :: proc(callback: ScreenRefreshCallback, userInfo: rawptr) -> Error ---
	UnregisterScreenRefreshCallback :: proc(callback: ScreenRefreshCallback, userInfo: rawptr) ---
	WaitForScreenRefreshRects :: proc(rects: ^[^]Rect, count: ^u32) -> Error ---
	ScreenRegisterMoveCallback :: proc(callback: ScreenUpdateMoveCallback, userInfo: rawptr) -> Error ---
	ScreenUnregisterMoveCallback :: proc(callback: ScreenUpdateMoveCallback, userInfo: rawptr) ---
	WaitForScreenUpdateRects :: proc(requestedOperations: ScreenUpdateOperation, currentOperation: ^ScreenUpdateOperation, rects: ^[^]Rect, rectCount: ^c.size_t, delta: ^ScreenUpdateMoveDelta) -> Error ---
	ReleaseScreenRefreshRects :: proc(rects: ^Rect) ---
	CursorIsVisible :: proc() -> darwin.boolean_t ---
	CursorIsDrawnInFramebuffer :: proc() -> darwin.boolean_t ---
	WarpMouseCursorPosition :: proc(newCursorPosition: Point) -> Error ---
	AssociateMouseAndMouseCursorPosition :: proc(connected: darwin.boolean_t) -> Error ---
	WindowServerCreateServerPort :: proc() -> CF.MachPortRef ---
	EnableEventStateCombining :: proc(combineState: darwin.boolean_t) -> Error ---
	InhibitLocalEvents :: proc(inhibit: darwin.boolean_t) -> Error ---
	PostMouseEvent :: proc(mouseCursorPosition: Point, updateMouseCursorPosition: darwin.boolean_t, buttonCount: ButtonCount, mouseButtonDown: darwin.boolean_t, #c_vararg args: ..any) -> Error ---
	PostScrollWheelEvent :: proc(wheelCount: WheelCount, wheel1: i32, #c_vararg args: ..any) -> Error ---
	PostKeyboardEvent :: proc(keyChar: CharCode, virtualKey: KeyCode, keyDown: darwin.boolean_t) -> Error ---
	SetLocalEventsFilterDuringSuppressionState :: proc(filter: EventFilterMask, state: EventSuppressionState) -> Error ---
	SetLocalEventsSuppressionInterval :: proc(seconds: CF.TimeInterval) -> Error ---
	WindowServerCFMachPort :: proc() -> CF.MachPortRef ---
	EventGetTypeID :: proc() -> CF.TypeID ---
	EventCreate :: proc(source: EventSourceRef) -> EventRef ---
	EventCreateData :: proc(allocator: CF.AllocatorRef, event: EventRef) -> CF.DataRef ---
	EventCreateFromData :: proc(allocator: CF.AllocatorRef, data: CF.DataRef) -> EventRef ---
	EventCreateMouseEvent :: proc(source: EventSourceRef, mouseType: EventType, mouseCursorPosition: Point, mouseButton: MouseButton) -> EventRef ---
	EventCreateKeyboardEvent :: proc(source: EventSourceRef, virtualKey: KeyCode, keyDown: bool) -> EventRef ---
	EventCreateScrollWheelEvent :: proc(source: EventSourceRef, units: ScrollEventUnit, wheelCount: u32, wheel1: i32, #c_vararg args: ..any) -> EventRef ---
	EventCreateScrollWheelEvent2 :: proc(source: EventSourceRef, units: ScrollEventUnit, wheelCount: u32, wheel1: i32, wheel2: i32, wheel3: i32) -> EventRef ---
	EventCreateCopy :: proc(event: EventRef) -> EventRef ---
	EventCreateSourceFromEvent :: proc(event: EventRef) -> EventSourceRef ---
	EventSetSource :: proc(event: EventRef, source: EventSourceRef) ---
	EventGetType :: proc(event: EventRef) -> EventType ---
	EventSetType :: proc(event: EventRef, type: EventType) ---
	EventGetTimestamp :: proc(event: EventRef) -> EventTimestamp ---
	EventSetTimestamp :: proc(event: EventRef, timestamp: EventTimestamp) ---
	EventGetLocation :: proc(event: EventRef) -> Point ---
	EventGetUnflippedLocation :: proc(event: EventRef) -> Point ---
	EventSetLocation :: proc(event: EventRef, location: Point) ---
	EventGetFlags :: proc(event: EventRef) -> EventFlags ---
	EventSetFlags :: proc(event: EventRef, flags: EventFlags) ---
	EventKeyboardGetUnicodeString :: proc(event: EventRef, maxStringLength: CF.UniCharCount, actualStringLength: ^CF.UniCharCount, unicodeString: ^CF.UniChar) ---
	EventKeyboardSetUnicodeString :: proc(event: EventRef, stringLength: CF.UniCharCount, unicodeString: ^CF.UniChar) ---
	EventGetIntegerValueField :: proc(event: EventRef, field: EventField) -> i64 ---
	EventSetIntegerValueField :: proc(event: EventRef, field: EventField, value: i64) ---
	EventGetDoubleValueField :: proc(event: EventRef, field: EventField) -> f64 ---
	EventSetDoubleValueField :: proc(event: EventRef, field: EventField, value: f64) ---
	EventTapCreate :: proc(tap: EventTapLocation, place: EventTapPlacement, options: EventTapOptions, eventsOfInterest: EventMask, callback: EventTapCallBack, userInfo: rawptr) -> CF.MachPortRef ---
	EventTapCreateForPSN :: proc(processSerialNumber: rawptr, place: EventTapPlacement, options: EventTapOptions, eventsOfInterest: EventMask, callback: EventTapCallBack, userInfo: rawptr) -> CF.MachPortRef ---
	EventTapCreateForPid :: proc(pid: darwin.pid_t, place: EventTapPlacement, options: EventTapOptions, eventsOfInterest: EventMask, callback: EventTapCallBack, userInfo: rawptr) -> CF.MachPortRef ---
	EventTapEnable :: proc(tap: CF.MachPortRef, enable: bool) ---
	EventTapIsEnabled :: proc(tap: CF.MachPortRef) -> bool ---
	EventTapPostEvent :: proc(proxy: EventTapProxy, event: EventRef) ---
	EventPost :: proc(tap: EventTapLocation, event: EventRef) ---
	EventPostToPSN :: proc(processSerialNumber: rawptr, event: EventRef) ---
	EventPostToPid :: proc(pid: darwin.pid_t, event: EventRef) ---
	GetEventTapList :: proc(maxNumberOfTaps: u32, tapList: ^EventTapInformation, eventTapCount: ^u32) -> Error ---
	PreflightListenEventAccess :: proc() -> bool ---
	RequestListenEventAccess :: proc() -> bool ---
	PreflightPostEventAccess :: proc() -> bool ---
	RequestPostEventAccess :: proc() -> bool ---
	EventSourceGetTypeID :: proc() -> CF.TypeID ---
	EventSourceCreate :: proc(stateID: EventSourceStateID) -> EventSourceRef ---
	EventSourceGetKeyboardType :: proc(source: EventSourceRef) -> EventSourceKeyboardType ---
	EventSourceSetKeyboardType :: proc(source: EventSourceRef, keyboardType: EventSourceKeyboardType) ---
	EventSourceGetPixelsPerLine :: proc(source: EventSourceRef) -> f64 ---
	EventSourceSetPixelsPerLine :: proc(source: EventSourceRef, pixelsPerLine: f64) ---
	EventSourceGetSourceStateID :: proc(source: EventSourceRef) -> EventSourceStateID ---
	EventSourceButtonState :: proc(stateID: EventSourceStateID, button: MouseButton) -> bool ---
	EventSourceKeyState :: proc(stateID: EventSourceStateID, key: KeyCode) -> bool ---
	EventSourceFlagsState :: proc(stateID: EventSourceStateID) -> EventFlags ---
	EventSourceSecondsSinceLastEventType :: proc(stateID: EventSourceStateID, eventType: EventType) -> CF.TimeInterval ---
	EventSourceCounterForEventType :: proc(stateID: EventSourceStateID, eventType: EventType) -> u32 ---
	EventSourceSetUserData :: proc(source: EventSourceRef, userData: i64) ---
	EventSourceGetUserData :: proc(source: EventSourceRef) -> i64 ---
	EventSourceSetLocalEventsFilterDuringSuppressionState :: proc(source: EventSourceRef, filter: EventFilterMask, state: EventSuppressionState) ---
	EventSourceGetLocalEventsFilterDuringSuppressionState :: proc(source: EventSourceRef, state: EventSuppressionState) -> EventFilterMask ---
	EventSourceSetLocalEventsSuppressionInterval :: proc(source: EventSourceRef, seconds: CF.TimeInterval) ---
	EventSourceGetLocalEventsSuppressionInterval :: proc(source: EventSourceRef) -> CF.TimeInterval ---
	PSConverterCreate :: proc(info: rawptr, callbacks: ^PSConverterCallbacks, options: CF.DictionaryRef) -> PSConverterRef ---
	PSConverterConvert :: proc(converter: PSConverterRef, provider: DataProviderRef, consumer: DataConsumerRef, options: CF.DictionaryRef) -> bool ---
	PSConverterAbort :: proc(converter: PSConverterRef) -> bool ---
	PSConverterIsConverting :: proc(converter: PSConverterRef) -> bool ---
	PSConverterGetTypeID :: proc() -> CF.TypeID ---
	SessionCopyCurrentDictionary :: proc() -> CF.DictionaryRef ---
	DirectDisplayCopyCurrentMetalDevice :: proc(display: DirectDisplayID) -> ^MTLDevice ---
}