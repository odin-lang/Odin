package CoreGraphics

import "core:c"
import "core:sys/darwin"

import CF "core:sys/darwin/CoreFoundation"

Float :: CF.CGFloat

KeyCode :: c.uint16_t

Point :: CF.CGPoint

Rect :: CF.CGRect

Size :: CF.CGSize

// IOSurfaceRef
IOSurfaceRef :: distinct ^__IOSurface

// CGContextRef
ContextRef :: distinct ^Context

// CGColorRef
ColorRef :: distinct ^Color

// CGColorSpaceRef
ColorSpaceRef :: distinct ^ColorSpace

// CGDataProviderRef
DataProviderRef :: distinct ^DataProvider

// CGDataProviderGetBytesCallback
DataProviderGetBytesCallback :: proc "c" (info: rawptr, buffer: rawptr, count: c.size_t) -> c.size_t

// CGDataProviderSkipForwardCallback
DataProviderSkipForwardCallback :: proc "c" (info: rawptr, count: darwin.off_t) -> darwin.off_t

// CGDataProviderRewindCallback
DataProviderRewindCallback :: proc "c" (info: rawptr)

// CGDataProviderReleaseInfoCallback
DataProviderReleaseInfoCallback :: proc "c" (info: rawptr)

// CGDataProviderGetBytesAtPositionCallback
DataProviderGetBytesAtPositionCallback :: proc "c" (info: rawptr, buffer: rawptr, pos: darwin.off_t, cnt: c.size_t) -> c.size_t

// CGDataProviderReleaseDataCallback
DataProviderReleaseDataCallback :: proc "c" (info: rawptr, data: rawptr, size: c.size_t)

// ColorSyncProfileRef
ColorSyncProfileRef :: distinct ^ColorSyncProfile

// CGPatternRef
PatternRef :: distinct ^Pattern

// CGPatternDrawPatternCallback
PatternDrawPatternCallback :: proc "c" (info: rawptr, _context: ContextRef)

// CGPatternReleaseInfoCallback
PatternReleaseInfoCallback :: proc "c" (info: rawptr)

// CGFontRef
FontRef :: distinct ^Font

// CGFontIndex
FontIndex :: distinct c.ushort

// CGGlyph
Glyph :: distinct FontIndex

// CGGradientRef
GradientRef :: distinct ^Gradient

// CGImageRef
ImageRef :: distinct ^Image

// CGMutablePathRef
MutablePathRef :: distinct ^Path

// CGPathRef
PathRef :: distinct ^Path

// CGPathApplierFunction
PathApplierFunction :: proc "c" (info: rawptr, element: ^PathElement)

// CGPathApplyBlock
PathApplyBlock :: ^Objc_Block(proc "c" (element: ^PathElement))

// CGPDFDocumentRef
PDFDocumentRef :: distinct ^PDFDocument

// CGPDFPageRef
PDFPageRef :: distinct ^PDFPage

// CGPDFDictionaryRef
PDFDictionaryRef :: distinct ^PDFDictionary

// CGPDFArrayRef
PDFArrayRef :: distinct ^PDFArray

// CGPDFBoolean
PDFBoolean :: distinct c.uchar

// CGPDFInteger
PDFInteger :: distinct c.long

// CGPDFReal
PDFReal :: distinct Float

// CGPDFObjectRef
PDFObjectRef :: distinct ^PDFObject

// CGPDFStreamRef
PDFStreamRef :: distinct ^PDFStream

// CGPDFStringRef
PDFStringRef :: distinct ^PDFString

// CGPDFArrayApplierBlock
PDFArrayApplierBlock :: ^Objc_Block(proc "c" (index: c.size_t, value: PDFObjectRef, info: rawptr) -> bool)

// CGPDFDictionaryApplierFunction
PDFDictionaryApplierFunction :: proc "c" (key: cstring, value: PDFObjectRef, info: rawptr)

// CGPDFDictionaryApplierBlock
PDFDictionaryApplierBlock :: ^Objc_Block(proc "c" (key: cstring, value: PDFObjectRef, info: rawptr) -> bool)

// CGShadingRef
ShadingRef :: distinct ^Shading

// CGFunctionRef
FunctionRef :: distinct ^Function

// CGFunctionEvaluateCallback
FunctionEvaluateCallback :: proc "c" (info: rawptr, _in: ^Float, out: ^Float)

// CGFunctionReleaseInfoCallback
FunctionReleaseInfoCallback :: proc "c" (info: rawptr)

// CGRenderingBufferProviderRef
RenderingBufferProviderRef :: distinct ^RenderingBufferProvider

// CGBitmapContextReleaseDataCallback
BitmapContextReleaseDataCallback :: proc "c" (releaseInfo: rawptr, data: rawptr)

// CGColorConversionInfoRef
ColorConversionInfoRef :: distinct ^ColorConversionInfo

// CGDataConsumerRef
DataConsumerRef :: distinct ^DataConsumer

// CGDataConsumerPutBytesCallback
DataConsumerPutBytesCallback :: proc "c" (info: rawptr, buffer: rawptr, count: c.size_t) -> c.size_t

// CGDataConsumerReleaseInfoCallback
DataConsumerReleaseInfoCallback :: proc "c" (info: rawptr)

// CGErrorCallback
ErrorCallback :: proc "c" ()

// CGLayerRef
LayerRef :: distinct ^Layer

// CGPDFContentStreamRef
PDFContentStreamRef :: distinct ^PDFContentStream

// CGPDFTagProperty
PDFTagProperty :: distinct CF.StringRef

// CGPDFOperatorTableRef
PDFOperatorTableRef :: distinct ^PDFOperatorTable

// CGPDFScannerRef
PDFScannerRef :: distinct ^PDFScanner

// CGPDFOperatorCallback
PDFOperatorCallback :: proc "c" (scanner: PDFScannerRef, info: rawptr)

// CGWindowID
WindowID :: distinct u32

// CGWindowLevel
WindowLevel :: distinct i32

// CGDirectDisplayID
DirectDisplayID :: distinct u32

// CGOpenGLDisplayMask
OpenGLDisplayMask :: distinct u32

// CGRefreshRate
RefreshRate :: distinct f64

// CGDisplayModeRef
DisplayModeRef :: distinct ^DisplayMode

// CGGammaValue
GammaValue :: distinct f32

// CGDisplayCount
DisplayCount :: distinct u32

// CGDisplayErr
DisplayErr :: distinct Error

// CGDisplayConfigRef
DisplayConfigRef :: distinct ^_CGDisplayConfigRef

// CGDisplayReconfigurationCallBack
DisplayReconfigurationCallBack :: proc "c" (display: DirectDisplayID, flags: DisplayChangeSummaryFlags, userInfo: rawptr)

// CGDisplayFadeReservationToken
DisplayFadeReservationToken :: distinct u32

// CGDisplayBlendFraction
DisplayBlendFraction :: distinct f32

// CGDisplayFadeInterval
DisplayFadeInterval :: distinct f32

// CGDisplayReservationInterval
DisplayReservationInterval :: distinct f32

// CGDisplayStreamRef
DisplayStreamRef :: distinct ^DisplayStream

// CGDisplayStreamUpdateRef
DisplayStreamUpdateRef :: distinct ^DisplayStreamUpdate

// CGDisplayStreamFrameAvailableHandler
DisplayStreamFrameAvailableHandler :: ^Objc_Block(proc "c" (status: DisplayStreamFrameStatus, displayTime: c.uint64_t, frameSurface: IOSurfaceRef, updateRef: DisplayStreamUpdateRef))

// CGEventErr
EventErr :: distinct Error

// CGButtonCount
ButtonCount :: distinct u32

// CGWheelCount
WheelCount :: distinct u32

// CGCharCode
CharCode :: distinct c.uint16_t

// CGScreenRefreshCallback
ScreenRefreshCallback :: proc "c" (count: u32, rects: ^Rect, userInfo: rawptr)

// CGScreenUpdateMoveCallback
ScreenUpdateMoveCallback :: proc "c" (delta: ScreenUpdateMoveDelta, count: c.size_t, rects: ^Rect, userInfo: rawptr)

// CGRectCount
RectCount :: distinct u32

// CGEventRef
EventRef :: distinct ^__CGEvent

// CGEventTimestamp
EventTimestamp :: distinct c.uint64_t

// CGEventMask
EventMask :: distinct c.uint64_t

// CGEventTapProxy
EventTapProxy :: distinct ^__CGEventTapProxy

// CGEventTapCallBack
EventTapCallBack :: proc "c" (proxy: EventTapProxy, type: EventType, event: EventRef, userInfo: rawptr) -> EventRef

// CGEventTapInformation
EventTapInformation :: distinct __CGEventTapInformation

// CGEventSourceRef
EventSourceRef :: distinct ^__CGEventSource

// CGEventSourceKeyboardType
EventSourceKeyboardType :: distinct u32

// CGPSConverterRef
PSConverterRef :: distinct ^PSConverter

// CGPSConverterBeginDocumentCallback
PSConverterBeginDocumentCallback :: proc "c" (info: rawptr)

// CGPSConverterEndDocumentCallback
PSConverterEndDocumentCallback :: proc "c" (info: rawptr, success: bool)

// CGPSConverterBeginPageCallback
PSConverterBeginPageCallback :: proc "c" (info: rawptr, pageNumber: c.size_t, pageInfo: CF.DictionaryRef)

// CGPSConverterEndPageCallback
PSConverterEndPageCallback :: proc "c" (info: rawptr, pageNumber: c.size_t, pageInfo: CF.DictionaryRef)

// CGPSConverterProgressCallback
PSConverterProgressCallback :: proc "c" (info: rawptr)

// CGPSConverterMessageCallback
PSConverterMessageCallback :: proc "c" (info: rawptr, message: CF.StringRef)

// CGPSConverterReleaseInfoCallback
PSConverterReleaseInfoCallback :: proc "c" (info: rawptr)

// CGRectEdge
RectEdge :: enum c.uint {
	MinXEdge = 0,
	MinYEdge = 1,
	MaxXEdge = 2,
	MaxYEdge = 3,
}

// CGColorRenderingIntent
ColorRenderingIntent :: enum c.int {
	Default              = 0,
	AbsoluteColorimetric = 1,
	RelativeColorimetric = 2,
	Perceptual           = 3,
	Saturation           = 4,
}

// CGColorSpaceModel
ColorSpaceModel :: enum c.int {
	Unknown    = -1,
	Monochrome = 0,
	RGB        = 1,
	CMYK       = 2,
	Lab        = 3,
	DeviceN    = 4,
	Indexed    = 5,
	Pattern    = 6,
	XYZ        = 7,
}

// CGPatternTiling
PatternTiling :: enum c.int {
	NoDistortion                     = 0,
	ConstantSpacingMinimalDistortion = 1,
	ConstantSpacing                  = 2,
}

// CGFontPostScriptFormat
FontPostScriptFormat :: enum c.int {
	Type1  = 1,
	Type3  = 3,
	Type42 = 42,
}

// CGGlyphDeprecatedEnum
GlyphDeprecatedEnum :: enum c.int {
	Min = 0,
	Max = 1,
}

// CGGradientDrawingOptions
GradientDrawingOptions :: enum c.uint {
	DrawsBeforeStartLocation = 1,
	DrawsAfterEndLocation    = 2,
}

// CGImageAlphaInfo
ImageAlphaInfo :: enum c.uint {
	None               = 0,
	PremultipliedLast  = 1,
	PremultipliedFirst = 2,
	Last               = 3,
	First              = 4,
	NoneSkipLast       = 5,
	NoneSkipFirst      = 6,
	Only               = 7,
}

// CGImageComponentInfo
ImageComponentInfo :: enum c.uint {
	Integer = 0,
	Float   = 256,
}

// CGImageByteOrderInfo
ImageByteOrderInfo :: enum c.uint {
	Mask      = 28672,
	Default   = 0,
	_16Little = 4096,
	_32Little = 8192,
	_16Big    = 12288,
	_32Big    = 16384,
	_16Host   = 4096,
	_32Host   = 8192,
}

// CGImagePixelFormatInfo
ImagePixelFormatInfo :: enum c.uint {
	Mask      = 983040,
	Packed    = 0,
	RGB555    = 65536,
	RGB565    = 131072,
	RGB101010 = 196608,
	RGBCIF10  = 262144,
}

// CGBitmapInfo
BitmapInfo :: enum c.uint {
	AlphaInfoMask       = 31,
	ComponentInfoMask   = 3840,
	ByteOrderInfoMask   = 28672,
	PixelFormatInfoMask = 983040,
	FloatInfoMask       = 3840,
	ByteOrderMask       = 28672,
	FloatComponents     = 256,
	ByteOrderDefault    = 0,
	ByteOrder16Little   = 4096,
	ByteOrder32Little   = 8192,
	ByteOrder16Big      = 12288,
	ByteOrder32Big      = 16384,
}

// CGLineJoin
LineJoin :: enum c.int {
	Miter = 0,
	Round = 1,
	Bevel = 2,
}

// CGLineCap
LineCap :: enum c.int {
	Butt   = 0,
	Round  = 1,
	Square = 2,
}

// CGPathElementType
PathElementType :: enum c.int {
	MoveToPoint         = 0,
	AddLineToPoint      = 1,
	AddQuadCurveToPoint = 2,
	AddCurveToPoint     = 3,
	CloseSubpath        = 4,
}

// CGPDFObjectType
PDFObjectType :: enum c.int {
	Null       = 1,
	Boolean    = 2,
	Integer    = 3,
	Real       = 4,
	Name       = 5,
	String     = 6,
	Array      = 7,
	Dictionary = 8,
	Stream     = 9,
}

// CGPDFDataFormat
PDFDataFormat :: enum c.int {
	Raw         = 0,
	JPEGEncoded = 1,
	JPEG2000    = 2,
}

// CGPDFBox
PDFBox :: enum c.int {
	MediaBox = 0,
	CropBox  = 1,
	BleedBox = 2,
	TrimBox  = 3,
	ArtBox   = 4,
}

// CGPDFAccessPermissions
PDFAccessPermissions :: enum c.uint {
	AllowsLowQualityPrinting   = 1,
	AllowsHighQualityPrinting  = 2,
	AllowsDocumentChanges      = 4,
	AllowsDocumentAssembly     = 8,
	AllowsContentCopying       = 16,
	AllowsContentAccessibility = 32,
	AllowsCommenting           = 64,
	AllowsFormFieldEntry       = 128,
}

// CGToneMapping
ToneMapping :: enum c.uint {
	Default                  = 0,
	ImageSpecificLumaScaling = 1,
	ReferenceWhiteBased      = 2,
	ITURecommended           = 3,
	EXRGamma                 = 4,
	None                     = 5,
}

// CGPathDrawingMode
PathDrawingMode :: enum c.int {
	Fill         = 0,
	EOFill       = 1,
	Stroke       = 2,
	FillStroke   = 3,
	EOFillStroke = 4,
}

// CGTextDrawingMode
TextDrawingMode :: enum c.int {
	Fill           = 0,
	Stroke         = 1,
	FillStroke     = 2,
	Invisible      = 3,
	FillClip       = 4,
	StrokeClip     = 5,
	FillStrokeClip = 6,
	Clip           = 7,
}

// CGTextEncoding
TextEncoding :: enum c.int {
	FontSpecific = 0,
	MacRoman     = 1,
}

// CGInterpolationQuality
InterpolationQuality :: enum c.int {
	Default = 0,
	None    = 1,
	Low     = 2,
	Medium  = 4,
	High    = 3,
}

// CGBlendMode
BlendMode :: enum c.int {
	Normal          = 0,
	Multiply        = 1,
	Screen          = 2,
	Overlay         = 3,
	Darken          = 4,
	Lighten         = 5,
	ColorDodge      = 6,
	ColorBurn       = 7,
	SoftLight       = 8,
	HardLight       = 9,
	Difference      = 10,
	Exclusion       = 11,
	Hue             = 12,
	Saturation      = 13,
	Color           = 14,
	Luminosity      = 15,
	Clear           = 16,
	Copy            = 17,
	SourceIn        = 18,
	SourceOut       = 19,
	SourceAtop      = 20,
	DestinationOver = 21,
	DestinationIn   = 22,
	DestinationOut  = 23,
	DestinationAtop = 24,
	XOR             = 25,
	PlusDarker      = 26,
	PlusLighter     = 27,
}

// CGColorModel
ColorModel :: enum c.uint {
	NoColorant = 0,
	Gray       = 1,
	RGB        = 2,
	CMYK       = 4,
	Lab        = 8,
	DeviceN    = 16,
}

// CGComponent
Component :: enum c.uint {
	Unknown      = 0,
	Integer8Bit  = 1,
	Integer10Bit = 6,
	Integer16Bit = 2,
	Integer32Bit = 3,
	Float16Bit   = 5,
	Float32Bit   = 4,
}

// CGBitmapLayout
BitmapLayout :: enum c.uint {
	AlphaOnly = 0,
	Gray      = 1,
	GrayAlpha = 2,
	RGBA      = 3,
	ARGB      = 4,
	RGBX      = 5,
	XRGB      = 6,
	BGRA      = 7,
	BGRX      = 8,
	ABGR      = 9,
	XBGR      = 10,
	CMYK      = 11,
}

// CGColorConversionInfoTransformType
ColorConversionInfoTransformType :: enum c.uint {
	FromSpace  = 0,
	ToSpace    = 1,
	ApplySpace = 2,
}

// CGError
Error :: enum c.int {
	Success           = 0,
	Failure           = 1000,
	IllegalArgument   = 1001,
	InvalidConnection = 1002,
	InvalidContext    = 1003,
	CannotComplete    = 1004,
	NotImplemented    = 1006,
	RangeCheck        = 1007,
	TypeCheck         = 1008,
	InvalidOperation  = 1010,
	NoneAvailable     = 1011,
}

// CGPDFTagType
PDFTagType :: enum c.int {
	Document           = 100,
	Part               = 101,
	Art                = 102,
	Section            = 103,
	Div                = 104,
	BlockQuote         = 105,
	Caption            = 106,
	TOC                = 107,
	TOCI               = 108,
	Index              = 109,
	NonStructure       = 110,
	Private            = 111,
	Paragraph          = 200,
	Header             = 201,
	Header1            = 202,
	Header2            = 203,
	Header3            = 204,
	Header4            = 205,
	Header5            = 206,
	Header6            = 207,
	List               = 300,
	ListItem           = 301,
	Label              = 302,
	ListBody           = 303,
	Table              = 400,
	TableRow           = 401,
	TableHeaderCell    = 402,
	TableDataCell      = 403,
	TableHeader        = 404,
	TableBody          = 405,
	TableFooter        = 406,
	Span               = 500,
	Quote              = 501,
	Note               = 502,
	Reference          = 503,
	Bibliography       = 504,
	Code               = 505,
	Link               = 506,
	Annotation         = 507,
	Ruby               = 600,
	RubyBaseText       = 601,
	RubyAnnotationText = 602,
	RubyPunctuation    = 603,
	Warichu            = 604,
	WarichuText        = 605,
	WarichuPunctiation = 606,
	Figure             = 700,
	Formula            = 701,
	Form               = 702,
	Object             = 800,
}

// CGWindowSharingType
WindowSharingType :: enum c.uint {
	None      = 0,
	ReadOnly  = 1,
	ReadWrite = 2,
}

// CGWindowBackingType
WindowBackingType :: enum c.uint {
	StoreRetained    = 0,
	StoreNonretained = 1,
	StoreBuffered    = 2,
}

// CGWindowListOption
WindowListOption :: enum c.uint {
	All                    = 0,
	OnScreenOnly           = 1,
	OnScreenAboveWindow    = 2,
	OnScreenBelowWindow    = 4,
	IncludingWindow        = 8,
	ExcludeDesktopElements = 16,
}

// CGWindowImageOption
WindowImageOption :: enum c.uint {
	Default             = 0,
	BoundsIgnoreFraming = 1,
	ShouldBeOpaque      = 2,
	OnlyShadows         = 4,
	BestResolution      = 8,
	NominalResolution   = 16,
}

// CGWindowLevelKey
WindowLevelKey :: enum c.int {
	BaseWindowLevelKey              = 0,
	MinimumWindowLevelKey           = 1,
	DesktopWindowLevelKey           = 2,
	BackstopMenuLevelKey            = 3,
	NormalWindowLevelKey            = 4,
	FloatingWindowLevelKey          = 5,
	TornOffMenuWindowLevelKey       = 6,
	DockWindowLevelKey              = 7,
	MainMenuWindowLevelKey          = 8,
	StatusWindowLevelKey            = 9,
	ModalPanelWindowLevelKey        = 10,
	PopUpMenuWindowLevelKey         = 11,
	DraggingWindowLevelKey          = 12,
	ScreenSaverWindowLevelKey       = 13,
	MaximumWindowLevelKey           = 14,
	OverlayWindowLevelKey           = 15,
	HelpWindowLevelKey              = 16,
	UtilityWindowLevelKey           = 17,
	DesktopIconWindowLevelKey       = 18,
	CursorWindowLevelKey            = 19,
	AssistiveTechHighWindowLevelKey = 20,
	NumberOfWindowLevelKeys         = 21,
}

// CGCaptureOptions
CaptureOptions :: enum c.uint {
	NoOptions = 0,
	NoFill    = 1,
}

// CGConfigureOption
ConfigureOption :: enum c.uint {
	ForAppOnly  = 0,
	ForSession  = 1,
	Permanently = 2,
}

// CGDisplayChangeSummaryFlags
DisplayChangeSummaryFlag :: enum c.uint {
	BeginConfigurationFlag  = 0,
	MovedFlag               = 1,
	SetMainFlag             = 2,
	SetModeFlag             = 3,
	AddFlag                 = 4,
	RemoveFlag              = 5,
	EnabledFlag             = 8,
	DisabledFlag            = 9,
	MirrorFlag              = 10,
	UnMirrorFlag            = 11,
	DesktopShapeChangedFlag = 12,
}
DisplayChangeSummaryFlags :: bit_set[DisplayChangeSummaryFlag; c.uint]

// CGDisplayStreamUpdateRectType
DisplayStreamUpdateRectType :: enum c.int {
	RefreshedRects    = 0,
	MovedRects        = 1,
	DirtyRects        = 2,
	ReducedDirtyRects = 3,
}

// CGDisplayStreamFrameStatus
DisplayStreamFrameStatus :: enum c.int {
	FrameComplete = 0,
	FrameIdle     = 1,
	FrameBlank    = 2,
	Stopped       = 3,
}

// CGScreenUpdateOperation
ScreenUpdateOperation :: enum c.uint {
	Refresh                    = 0,
	Move                       = 1,
	ReducedDirtyRectangleCount = 2147483648,
}

// CGEventFilterMask
EventFilterMaskFlag :: enum c.uint {
	PermitLocalMouseEvents    = 0,
	PermitLocalKeyboardEvents = 1,
	PermitSystemDefinedEvents = 2,
}
EventFilterMask :: bit_set[EventFilterMaskFlag; c.uint]

// CGEventSuppressionState
EventSuppressionState :: enum c.uint {
	SuppressionInterval            = 0,
	RemoteMouseDrag                = 1,
	NumberOfEventSuppressionStates = 2,
}

// CGMouseButton
MouseButton :: enum c.uint {
	Left   = 0,
	Right  = 1,
	Center = 2,
}

// CGScrollEventUnit
ScrollEventUnit :: enum c.uint {
	Pixel = 0,
	Line  = 1,
}

// CGMomentumScrollPhase
MomentumScrollPhase :: enum c.uint {
	None     = 0,
	Begin    = 1,
	Continue = 2,
	End      = 3,
}

// CGScrollPhase
ScrollPhase :: enum c.uint {
	Began     = 1,
	Changed   = 2,
	Ended     = 4,
	Cancelled = 8,
	MayBegin  = 128,
}

// CGGesturePhase
GesturePhase :: enum c.uint {
	None      = 0,
	Began     = 1,
	Changed   = 2,
	Ended     = 4,
	Cancelled = 8,
	MayBegin  = 128,
}

// CGEventFlags
EventFlag :: enum c.ulonglong {
	FlagMaskAlphaShift   = 16,
	FlagMaskShift        = 17,
	FlagMaskControl      = 18,
	FlagMaskAlternate    = 19,
	FlagMaskCommand      = 20,
	FlagMaskHelp         = 22,
	FlagMaskSecondaryFn  = 23,
	FlagMaskNumericPad   = 21,
	FlagMaskNonCoalesced = 8,
}
EventFlags :: bit_set[EventFlag; c.ulonglong]

// CGEventType
EventType :: enum c.uint {
	Null                   = 0,
	LeftMouseDown          = 1,
	LeftMouseUp            = 2,
	RightMouseDown         = 3,
	RightMouseUp           = 4,
	MouseMoved             = 5,
	LeftMouseDragged       = 6,
	RightMouseDragged      = 7,
	KeyDown                = 10,
	KeyUp                  = 11,
	FlagsChanged           = 12,
	ScrollWheel            = 22,
	TabletPointer          = 23,
	TabletProximity        = 24,
	OtherMouseDown         = 25,
	OtherMouseUp           = 26,
	OtherMouseDragged      = 27,
	TapDisabledByTimeout   = 4294967294,
	TapDisabledByUserInput = 4294967295,
}

// CGEventField
EventField :: enum c.uint {
	MouseEventNumber                 = 0,
	MouseEventClickState             = 1,
	MouseEventPressure               = 2,
	MouseEventButtonNumber           = 3,
	MouseEventDeltaX                 = 4,
	MouseEventDeltaY                 = 5,
	MouseEventInstantMouser          = 6,
	MouseEventSubtype                = 7,
	KeyboardEventAutorepeat          = 8,
	KeyboardEventKeycode             = 9,
	KeyboardEventKeyboardType        = 10,
	ScrollWheelEventDeltaAxis1       = 11,
	ScrollWheelEventDeltaAxis2       = 12,
	ScrollWheelEventDeltaAxis3       = 13,
	ScrollWheelEventFixedPtDeltaAxis1 = 93,
	ScrollWheelEventFixedPtDeltaAxis2 = 94,
	ScrollWheelEventFixedPtDeltaAxis3 = 95,
	ScrollWheelEventPointDeltaAxis1  = 96,
	ScrollWheelEventPointDeltaAxis2  = 97,
	ScrollWheelEventPointDeltaAxis3  = 98,
	ScrollWheelEventScrollPhase      = 99,
	ScrollWheelEventScrollCount      = 100,
	ScrollWheelEventMomentumPhase    = 123,
	ScrollWheelEventInstantMouser    = 14,
	TabletEventPointX                = 15,
	TabletEventPointY                = 16,
	TabletEventPointZ                = 17,
	TabletEventPointButtons          = 18,
	TabletEventPointPressure         = 19,
	TabletEventTiltX                 = 20,
	TabletEventTiltY                 = 21,
	TabletEventRotation              = 22,
	TabletEventTangentialPressure    = 23,
	TabletEventDeviceID              = 24,
	TabletEventVendor1               = 25,
	TabletEventVendor2               = 26,
	TabletEventVendor3               = 27,
	TabletProximityEventVendorID     = 28,
	TabletProximityEventTabletID     = 29,
	TabletProximityEventPointerID    = 30,
	TabletProximityEventDeviceID     = 31,
	TabletProximityEventSystemTabletID = 32,
	TabletProximityEventVendorPointerType = 33,
	TabletProximityEventVendorPointerSerialNumber = 34,
	TabletProximityEventVendorUniqueID = 35,
	TabletProximityEventCapabilityMask = 36,
	TabletProximityEventPointerType  = 37,
	TabletProximityEventEnterProximity = 38,
	TargetProcessSerialNumber        = 39,
	TargetUnixProcessID              = 40,
	SourceUnixProcessID              = 41,
	SourceUserData                   = 42,
	SourceUserID                     = 43,
	SourceGroupID                    = 44,
	SourceStateID                    = 45,
	ScrollWheelEventIsContinuous     = 88,
	MouseEventWindowUnderMousePointer = 91,
	MouseEventWindowUnderMousePointerThatCanHandleThisEvent = 92,
	UnacceleratedPointerMovementX    = 170,
	UnacceleratedPointerMovementY    = 171,
	ScrollWheelEventMomentumOptionPhase = 173,
	ScrollWheelEventAcceleratedDeltaAxis1 = 176,
	ScrollWheelEventAcceleratedDeltaAxis2 = 175,
	ScrollWheelEventRawDeltaAxis1    = 178,
	ScrollWheelEventRawDeltaAxis2    = 177,
}

// CGEventMouseSubtype
EventMouseSubtype :: enum c.uint {
	Default         = 0,
	TabletPoint     = 1,
	TabletProximity = 2,
}

// CGEventTapLocation
EventTapLocation :: enum c.uint {
	HIDEventTap              = 0,
	SessionEventTap          = 1,
	AnnotatedSessionEventTap = 2,
}

// CGEventTapPlacement
EventTapPlacement :: enum c.uint {
	HeadInsertEventTap = 0,
	TailAppendEventTap = 1,
}

// CGEventTapOptions
EventTapOptions :: enum c.uint {
	OptionDefault    = 0,
	OptionListenOnly = 1,
}

// CGEventSourceStateID
EventSourceStateID :: enum c.int {
	Private              = -1,
	CombinedSessionState = 0,
	HIDSystemState       = 1,
}

// CGVector
Vector :: struct #align (8) {
	dx: Float,
	dy: Float,
}
#assert(size_of(Vector) == 16)

// CGAffineTransform
AffineTransform :: struct #align (8) {
	a:  Float,
	b:  Float,
	c:  Float,
	d:  Float,
	tx: Float,
	ty: Float,
}
#assert(size_of(AffineTransform) == 48)

// CGAffineTransformComponents
AffineTransformComponents :: struct #align (8) {
	scale:           Size,
	horizontalShear: Float,
	rotation:        Float,
	translation:     Vector,
}
#assert(size_of(AffineTransformComponents) == 48)

// __IOSurface
__IOSurface :: struct {}

// CGContext
Context :: struct {}

// CGColor
Color :: struct {}

// CGColorSpace
ColorSpace :: struct {}

// CGDataProvider
DataProvider :: struct {}

// CGDataProviderSequentialCallbacks
DataProviderSequentialCallbacks :: struct #align (8) {
	version:     c.uint,
	getBytes:    DataProviderGetBytesCallback,
	skipForward: DataProviderSkipForwardCallback,
	rewind:      DataProviderRewindCallback,
	releaseInfo: DataProviderReleaseInfoCallback,
}
#assert(size_of(DataProviderSequentialCallbacks) == 40)

// CGDataProviderDirectCallbacks
DataProviderDirectCallbacks :: struct #align (8) {
	version:            c.uint,
	getBytePointer:     proc "c" (info: rawptr) -> rawptr,
	releaseBytePointer: proc "c" (info: rawptr, pointer: rawptr),
	getBytesAtPosition: DataProviderGetBytesAtPositionCallback,
	releaseInfo:        DataProviderReleaseInfoCallback,
}
#assert(size_of(DataProviderDirectCallbacks) == 40)

// ColorSyncProfile
ColorSyncProfile :: struct {}

// CGPattern
Pattern :: struct {}

// CGPatternCallbacks
PatternCallbacks :: struct #align (8) {
	version:     c.uint,
	drawPattern: PatternDrawPatternCallback,
	releaseInfo: PatternReleaseInfoCallback,
}
#assert(size_of(PatternCallbacks) == 24)

// CGFont
Font :: struct {}

// CGGradient
Gradient :: struct {}

// CGImage
Image :: struct {}

// CGPath
Path :: struct {}

// CGPathElement
PathElement :: struct #align (8) {
	type:   PathElementType,
	points: ^Point,
}
#assert(size_of(PathElement) == 16)

// CGPDFDocument
PDFDocument :: struct {}

// CGPDFPage
PDFPage :: struct {}

// CGPDFDictionary
PDFDictionary :: struct {}

// CGPDFArray
PDFArray :: struct {}

// CGPDFObject
PDFObject :: struct {}

// CGPDFStream
PDFStream :: struct {}

// CGPDFString
PDFString :: struct {}

// CGShading
Shading :: struct {}

// CGFunction
Function :: struct {}

// CGFunctionCallbacks
FunctionCallbacks :: struct #align (8) {
	version:     c.uint,
	evaluate:    FunctionEvaluateCallback,
	releaseInfo: FunctionReleaseInfoCallback,
}
#assert(size_of(FunctionCallbacks) == 24)

// CGContentToneMappingInfo
ContentToneMappingInfo :: struct #align (8) {
	method:  ToneMapping,
	options: CF.DictionaryRef,
}
#assert(size_of(ContentToneMappingInfo) == 16)

// CGRenderingBufferProvider
RenderingBufferProvider :: struct {}

// CGContentInfo
ContentInfo :: struct #align (4) {
	deepestImageComponent:  Component,
	contentColorModels:     ColorModel,
	hasWideGamut:           bool,
	hasTransparency:        bool,
	largestContentHeadroom: f32,
}
#assert(size_of(ContentInfo) == 16)

// CGBitmapParameters
BitmapParameters :: struct #align (8) {
	width:                 c.size_t,
	height:                c.size_t,
	bytesPerPixel:         c.size_t,
	alignedBytesPerRow:    c.size_t,
	component:             Component,
	layout:                BitmapLayout,
	format:                ImagePixelFormatInfo,
	colorSpace:            ColorSpaceRef,
	hasPremultipliedAlpha: bool,
	byteOrder:             CF.ByteOrder,
	edrTargetHeadroom:     f32,
}
#assert(size_of(BitmapParameters) == 80)

// CGColorConversionInfo
ColorConversionInfo :: struct {}

// CGColorBufferFormat
ColorBufferFormat :: struct #align (8) {
	version:          u32,
	bitmapInfo:       BitmapInfo,
	bitsPerComponent: c.size_t,
	bitsPerPixel:     c.size_t,
	bytesPerRow:      c.size_t,
}
#assert(size_of(ColorBufferFormat) == 32)

// CGColorDataFormat
ColorDataFormat :: struct #align (8) {
	version:            u32,
	colorspace_info:    CF.TypeRef,
	bitmap_info:        BitmapInfo,
	bits_per_component: c.size_t,
	bytes_per_row:      c.size_t,
	intent:             ColorRenderingIntent,
	decode:             ^Float,
}
#assert(size_of(ColorDataFormat) == 56)

// CGDataConsumer
DataConsumer :: struct {}

// CGDataConsumerCallbacks
DataConsumerCallbacks :: struct #align (8) {
	putBytes:        DataConsumerPutBytesCallback,
	releaseConsumer: DataConsumerReleaseInfoCallback,
}
#assert(size_of(DataConsumerCallbacks) == 16)

// CGLayer
Layer :: struct {}

// CGPDFContentStream
PDFContentStream :: struct {}

// CGPDFOperatorTable
PDFOperatorTable :: struct {}

// CGPDFScanner
PDFScanner :: struct {}

// CGDisplayMode
DisplayMode :: struct {}

// CGDeviceColor
DeviceColor :: struct #align (4) {
	red:   f32,
	green: f32,
	blue:  f32,
}
#assert(size_of(DeviceColor) == 12)

// _CGDisplayConfigRef
_CGDisplayConfigRef :: struct {}

// CGDisplayStream
DisplayStream :: struct {}

// CGDisplayStreamUpdate
DisplayStreamUpdate :: struct {}

// CGScreenUpdateMoveDelta
ScreenUpdateMoveDelta :: struct #align (4) {
	dX: i32,
	dY: i32,
}
#assert(size_of(ScreenUpdateMoveDelta) == 8)

// __CGEvent
__CGEvent :: struct {}

// __CGEventTapProxy
__CGEventTapProxy :: struct {}

// __CGEventTapInformation
__CGEventTapInformation :: struct #align (8) {
	eventTapID:         u32,
	tapPoint:           EventTapLocation,
	options:            EventTapOptions,
	eventsOfInterest:   EventMask,
	tappingProcess:     darwin.pid_t,
	processBeingTapped: darwin.pid_t,
	enabled:            bool,
	minUsecLatency:     f32,
	avgUsecLatency:     f32,
	maxUsecLatency:     f32,
}
#assert(size_of(__CGEventTapInformation) == 48)

// __CGEventSource
__CGEventSource :: struct {}

// CGPSConverter
PSConverter :: struct {}

// CGPSConverterCallbacks
PSConverterCallbacks :: struct #align (8) {
	version:       c.uint,
	beginDocument: PSConverterBeginDocumentCallback,
	endDocument:   PSConverterEndDocumentCallback,
	beginPage:     PSConverterBeginPageCallback,
	endPage:       PSConverterEndPageCallback,
	noteProgress:  PSConverterProgressCallback,
	noteMessage:   PSConverterMessageCallback,
	releaseInfo:   PSConverterReleaseInfoCallback,
}
#assert(size_of(PSConverterCallbacks) == 64)

