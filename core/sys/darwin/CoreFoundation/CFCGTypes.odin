package CoreFoundation

import "core:c"
import "core:sys/darwin"

CGFloat :: distinct (f32 when size_of(uint) == 4 else f64)

CGPoint :: struct #align(8) {
	x: CGFloat,
	y: CGFloat,
}

CGRect :: struct #align(8) {
	using origin: CGPoint,
	using size:   CGSize,
}

CGSize :: struct #align(8) {
	width:  CGFloat,
	height: CGFloat,
}

Boolean   :: b8
boolean_t :: b32


// UInt8
UInt8 :: u8

// SInt8
SInt8 :: i8

// UInt16
UInt16 :: u16

// SInt16
SInt16 :: i16

// UInt32
UInt32 :: u32

// SInt32
SInt32 :: i32

// SInt64
SInt64 :: i64

// UInt64
UInt64 :: u64

// Ptr
Ptr :: cstring

// Handle
Handle :: ^Ptr

// Size
Size :: c.long

// OSErr
OSErr :: SInt16

// OSStatus
OSStatus :: SInt32

// LogicalAddress
LogicalAddress :: rawptr

// ConstLogicalAddress
ConstLogicalAddress :: rawptr

// PhysicalAddress
PhysicalAddress :: rawptr

// BytePtr
BytePtr :: [^]byte

// ByteCount
ByteCount :: c.ulong

// ByteOffset
ByteOffset :: c.ulong

// Duration
Duration :: SInt32

// AbsoluteTime
AbsoluteTime :: UnsignedWide

// OptionBits
OptionBits :: UInt32

// ItemCount
ItemCount :: c.ulong

// PBVersion
PBVersion :: UInt32

// ScriptCode
ScriptCode :: SInt16

// LangCode
LangCode :: SInt16

// RegionCode
RegionCode :: SInt16

// FourCharCode
FourCharCode :: UInt32

// OSType
OSType :: FourCharCode

// ResType
ResType :: FourCharCode

// OSTypePtr
OSTypePtr :: ^OSType

// ResTypePtr
ResTypePtr :: ^ResType

// SRefCon
SRefCon :: rawptr

// UTF32Char
UTF32Char :: UInt32

// UniChar
UniChar :: UInt16

// UTF16Char
UTF16Char :: UInt16

// UTF8Char
UTF8Char :: UInt8

// UniCharPtr
UniCharPtr :: ^UniChar

// UniCharCount
UniCharCount :: c.ulong

// UniCharCountPtr
UniCharCountPtr :: ^UniCharCount

// Str255
Str255 :: [256]u8

// Str63
Str63 :: [64]u8

// Str32
Str32 :: [33]u8

// Str31
Str31 :: [32]u8

// Str27
Str27 :: [28]u8

// Str15
Str15 :: [16]u8

// Str32Field
Str32Field :: [34]u8

// StrFileName
StrFileName :: Str63

// StringPtr
StringPtr :: cstring

// StringHandle
StringHandle :: ^StringPtr

// ConstStringPtr
ConstStringPtr :: cstring

// ConstStr255Param
ConstStr255Param :: cstring

// ConstStr63Param
ConstStr63Param :: cstring

// ConstStr32Param
ConstStr32Param :: cstring

// ConstStr31Param
ConstStr31Param :: cstring

// ConstStr27Param
ConstStr27Param :: cstring

// ConstStr15Param
ConstStr15Param :: cstring

// ConstStrFileNameParam
ConstStrFileNameParam :: ConstStr63Param

// SignedByte
SignedByte :: SInt8

// UnsignedWidePtr
UnsignedWidePtr :: ^UnsignedWide

// CFAllocatorTypeID
AllocatorTypeID :: c.ulonglong

// CFMutableStringRef
MutableStringRef :: StringRef

// CFPropertyListRef
PropertyListRef :: TypeRef

// CFComparatorFunction
ComparatorFunction :: proc "c" (val1: rawptr, val2: rawptr, _context: rawptr) -> ComparisonResult

// CFNullRef
NullRef :: ^__CFNull

// CFAllocatorRef
AllocatorRef :: ^__CFAllocator

// CFAllocatorRetainCallBack
AllocatorRetainCallBack :: proc "c" (info: rawptr) -> rawptr

// CFAllocatorReleaseCallBack
AllocatorReleaseCallBack :: proc "c" (info: rawptr)

// CFAllocatorCopyDescriptionCallBack
AllocatorCopyDescriptionCallBack :: proc "c" (info: rawptr) -> StringRef

// CFAllocatorAllocateCallBack
AllocatorAllocateCallBack :: proc "c" (allocSize: Index, hint: OptionFlags, info: rawptr) -> rawptr

// CFAllocatorReallocateCallBack
AllocatorReallocateCallBack :: proc "c" (ptr: rawptr, newsize: Index, hint: OptionFlags, info: rawptr) -> rawptr

// CFAllocatorDeallocateCallBack
AllocatorDeallocateCallBack :: proc "c" (ptr: rawptr, info: rawptr)

// CFAllocatorPreferredSizeCallBack
AllocatorPreferredSizeCallBack :: proc "c" (size: Index, hint: OptionFlags, info: rawptr) -> Index

// CFArrayRetainCallBack
ArrayRetainCallBack :: proc "c" (allocator: AllocatorRef, value: rawptr) -> rawptr

// CFArrayReleaseCallBack
ArrayReleaseCallBack :: proc "c" (allocator: AllocatorRef, value: rawptr)

// CFArrayCopyDescriptionCallBack
ArrayCopyDescriptionCallBack :: proc "c" (value: rawptr) -> StringRef

// CFArrayEqualCallBack
ArrayEqualCallBack :: proc "c" (value1: rawptr, value2: rawptr) -> Boolean

// CFArrayApplierFunction
ArrayApplierFunction :: proc "c" (value: rawptr, _context: rawptr)

// CFArrayRef
ArrayRef :: ^__CFArray

// CFMutableArrayRef
MutableArrayRef :: ^__CFArray

// CFBagRetainCallBack
BagRetainCallBack :: proc "c" (allocator: AllocatorRef, value: rawptr) -> rawptr

// CFBagReleaseCallBack
BagReleaseCallBack :: proc "c" (allocator: AllocatorRef, value: rawptr)

// CFBagCopyDescriptionCallBack
BagCopyDescriptionCallBack :: proc "c" (value: rawptr) -> StringRef

// CFBagEqualCallBack
BagEqualCallBack :: proc "c" (value1: rawptr, value2: rawptr) -> Boolean

// CFBagHashCallBack
BagHashCallBack :: proc "c" (value: rawptr) -> HashCode

// CFBagApplierFunction
BagApplierFunction :: proc "c" (value: rawptr, _context: rawptr)

// CFBagRef
BagRef :: ^__CFBag

// CFMutableBagRef
MutableBagRef :: ^__CFBag

// CFBinaryHeapApplierFunction
BinaryHeapApplierFunction :: proc "c" (val: rawptr, _context: rawptr)

// CFBinaryHeapRef
BinaryHeapRef :: ^__CFBinaryHeap

// CFBit
Bit :: UInt32

// CFBitVectorRef
BitVectorRef :: ^__CFBitVector

// CFMutableBitVectorRef
MutableBitVectorRef :: ^__CFBitVector

// CFByteOrder
ByteOrder :: Index

// CFDictionaryRetainCallBack
DictionaryRetainCallBack :: proc "c" (allocator: AllocatorRef, value: rawptr) -> rawptr

// CFDictionaryReleaseCallBack
DictionaryReleaseCallBack :: proc "c" (allocator: AllocatorRef, value: rawptr)

// CFDictionaryCopyDescriptionCallBack
DictionaryCopyDescriptionCallBack :: proc "c" (value: rawptr) -> StringRef

// CFDictionaryEqualCallBack
DictionaryEqualCallBack :: proc "c" (value1: rawptr, value2: rawptr) -> Boolean

// CFDictionaryHashCallBack
DictionaryHashCallBack :: proc "c" (value: rawptr) -> HashCode

// CFDictionaryApplierFunction
DictionaryApplierFunction :: proc "c" (key: rawptr, value: rawptr, _context: rawptr)

// CFDictionaryRef
DictionaryRef :: ^__CFDictionary

// CFMutableDictionaryRef
MutableDictionaryRef :: ^__CFDictionary

// CFNotificationName
NotificationName :: StringRef

// CFNotificationCenterRef
NotificationCenterRef :: ^__CFNotificationCenter

// CFNotificationCallback
NotificationCallback :: proc "c" (center: NotificationCenterRef, observer: rawptr, name: NotificationName, object: rawptr, userInfo: DictionaryRef)

// CFLocaleIdentifier
LocaleIdentifier :: StringRef

// CFLocaleKey
LocaleKey :: StringRef

// CFLocaleRef
LocaleRef :: ^__CFLocale

// CFCalendarIdentifier
CalendarIdentifier :: StringRef

// CFTimeInterval
TimeInterval :: f64

// CFAbsoluteTime
CFAbsoluteTime :: TimeInterval

// CFDateRef
DateRef :: ^__CFDate

// CFTimeZoneRef
TimeZoneRef :: ^__CFTimeZone

// CFDataRef
DataRef :: ^__CFData

// CFMutableDataRef
MutableDataRef :: ^__CFData

// CFCharacterSetRef
CharacterSetRef :: ^__CFCharacterSet

// CFMutableCharacterSetRef
MutableCharacterSetRef :: ^__CFCharacterSet

// CFErrorDomain
ErrorDomain :: StringRef

// CFErrorRef
ErrorRef :: ^__CFError

// CFCalendarRef
CalendarRef :: ^__CFCalendar

// CFDateFormatterKey
DateFormatterKey :: StringRef

// CFDateFormatterRef
DateFormatterRef :: ^__CFDateFormatter

// CFBooleanRef
BooleanRef :: ^__CFBoolean

// CFNumberRef
NumberRef :: ^__CFNumber

// CFNumberFormatterKey
NumberFormatterKey :: StringRef

// CFNumberFormatterRef
NumberFormatterRef :: ^__CFNumberFormatter

// CFURLRef
URLRef :: ^__CFURL

// CFURLBookmarkFileCreationOptions
URLBookmarkFileCreationOptions :: OptionFlags

// CFRunLoopMode
RunLoopMode :: StringRef

// CFRunLoopRef
RunLoopRef :: ^__CFRunLoop

// CFRunLoopSourceRef
RunLoopSourceRef :: ^__CFRunLoopSource

// CFRunLoopObserverRef
RunLoopObserverRef :: ^__CFRunLoopObserver

// CFRunLoopTimerRef
RunLoopTimerRef :: ^__CFRunLoopTimer

// CFRunLoopObserverCallBack
RunLoopObserverCallBack :: proc "c" (observer: RunLoopObserverRef, activity: RunLoopActivity, info: rawptr)

// CFRunLoopTimerCallBack
RunLoopTimerCallBack :: proc "c" (timer: RunLoopTimerRef, info: rawptr)

// CFSocketRef
SocketRef :: ^__CFSocket

// CFSocketCallBack
SocketCallBack :: proc "c" (s: SocketRef, type: SocketCallBackType, address: DataRef, data: rawptr, info: rawptr)

// CFSocketNativeHandle
SocketNativeHandle :: c.int

// os_function_t
os_function_t :: proc "c" (_: rawptr)

// os_block_t
os_block_t :: ^Objc_Block(proc "c" ())

// os_workgroup_t
os_workgroup_t :: ^os_workgroup_s

// os_workgroup_attr_s
os_workgroup_attr_s :: os_workgroup_attr_opaque_s

// os_workgroup_attr_t
os_workgroup_attr_t :: ^os_workgroup_attr_opaque_s

// os_workgroup_join_token_s
os_workgroup_join_token_s :: os_workgroup_join_token_opaque_s

// os_workgroup_join_token_t
os_workgroup_join_token_t :: ^os_workgroup_join_token_opaque_s

// os_workgroup_index
os_workgroup_index :: u32

// os_workgroup_working_arena_destructor_t
os_workgroup_working_arena_destructor_t :: proc "c" (_: rawptr)

// os_workgroup_mpt_attr_s
os_workgroup_mpt_attr_s :: os_workgroup_max_parallel_threads_attr_s

// os_workgroup_mpt_attr_t
os_workgroup_mpt_attr_t :: ^os_workgroup_max_parallel_threads_attr_s

// os_workgroup_parallel_t
os_workgroup_parallel_t :: os_workgroup_t

// dispatch_function_t
dispatch_function_t :: proc "c" (_: rawptr)

// dispatch_time_t
dispatch_time_t :: u64

// dispatch_block_t
dispatch_block_t :: ^Objc_Block(proc "c" ())

// dispatch_qos_class_t
dispatch_qos_class_t :: qos_class_t

// dispatch_queue_t
dispatch_queue_t :: ^dispatch_queue_s

// dispatch_queue_global_t
dispatch_queue_global_t :: dispatch_queue_t

// dispatch_queue_serial_executor_t
dispatch_queue_serial_executor_t :: dispatch_queue_t

// dispatch_queue_serial_t
dispatch_queue_serial_t :: dispatch_queue_t

// dispatch_queue_main_t
dispatch_queue_main_t :: dispatch_queue_serial_t

// dispatch_queue_concurrent_t
dispatch_queue_concurrent_t :: dispatch_queue_t

// dispatch_queue_priority_t
dispatch_queue_priority_t :: c.long

// dispatch_queue_attr_t
dispatch_queue_attr_t :: ^dispatch_queue_attr_s

// dispatch_source_t
dispatch_source_t :: ^dispatch_source_s

// dispatch_source_type_t
dispatch_source_type_t :: ^dispatch_source_type_s

// dispatch_source_mach_send_flags_t
dispatch_source_mach_send_flags_t :: c.ulong

// dispatch_source_mach_recv_flags_t
dispatch_source_mach_recv_flags_t :: c.ulong

// dispatch_source_memorypressure_flags_t
dispatch_source_memorypressure_flags_t :: c.ulong

// dispatch_source_proc_flags_t
dispatch_source_proc_flags_t :: c.ulong

// dispatch_source_vnode_flags_t
dispatch_source_vnode_flags_t :: c.ulong

// dispatch_source_timer_flags_t
dispatch_source_timer_flags_t :: c.ulong

// dispatch_group_t
dispatch_group_t :: ^dispatch_group_s

// dispatch_semaphore_t
dispatch_semaphore_t :: ^dispatch_semaphore_s

// dispatch_once_t
dispatch_once_t :: c.intptr_t

// dispatch_data_t
dispatch_data_t :: ^dispatch_data_s

// dispatch_data_applier_t
dispatch_data_applier_t :: ^Objc_Block(proc "c" (region: dispatch_data_t, offset: c.size_t, buffer: rawptr, size: c.size_t) -> bool)

// dispatch_fd_t
dispatch_fd_t :: c.int

// dispatch_io_t
dispatch_io_t :: ^dispatch_io_s

// dispatch_io_type_t
dispatch_io_type_t :: c.ulong

// dispatch_io_handler_t
dispatch_io_handler_t :: ^Objc_Block(proc "c" (done: bool, data: dispatch_data_t, error: c.int))

// dispatch_io_close_flags_t
dispatch_io_close_flags_t :: c.ulong

// dispatch_workloop_t
dispatch_workloop_t :: dispatch_queue_t

// CFStreamPropertyKey
StreamPropertyKey :: StringRef

// CFReadStreamRef
ReadStreamRef :: ^__CFReadStream

// CFWriteStreamRef
WriteStreamRef :: ^__CFWriteStream

// CFReadStreamClientCallBack
ReadStreamClientCallBack :: proc "c" (stream: ReadStreamRef, type: StreamEventType, clientCallBackInfo: rawptr)

// CFWriteStreamClientCallBack
WriteStreamClientCallBack :: proc "c" (stream: WriteStreamRef, type: StreamEventType, clientCallBackInfo: rawptr)

// CFSetRetainCallBack
SetRetainCallBack :: proc "c" (allocator: AllocatorRef, value: rawptr) -> rawptr

// CFSetReleaseCallBack
SetReleaseCallBack :: proc "c" (allocator: AllocatorRef, value: rawptr)

// CFSetCopyDescriptionCallBack
SetCopyDescriptionCallBack :: proc "c" (value: rawptr) -> StringRef

// CFSetEqualCallBack
SetEqualCallBack :: proc "c" (value1: rawptr, value2: rawptr) -> Boolean

// CFSetHashCallBack
SetHashCallBack :: proc "c" (value: rawptr) -> HashCode

// CFSetApplierFunction
SetApplierFunction :: proc "c" (value: rawptr, _context: rawptr)

// CFSetRef
SetRef :: ^__CFSet

// CFMutableSetRef
MutableSetRef :: ^__CFSet

// CFTreeRetainCallBack
TreeRetainCallBack :: proc "c" (info: rawptr) -> rawptr

// CFTreeReleaseCallBack
TreeReleaseCallBack :: proc "c" (info: rawptr)

// CFTreeCopyDescriptionCallBack
TreeCopyDescriptionCallBack :: proc "c" (info: rawptr) -> StringRef

// CFTreeApplierFunction
TreeApplierFunction :: proc "c" (value: rawptr, _context: rawptr)

// CFTreeRef
TreeRef :: ^__CFTree

// CFUUIDRef
UUIDRef :: ^__CFUUID

// CFBundleRef
BundleRef :: ^__CFBundle

// CFPlugInRef
PlugInRef :: ^__CFBundle

// CFBundleRefNum
BundleRefNum :: c.int

// CFMessagePortRef
MessagePortRef :: ^__CFMessagePort

// CFMessagePortCallBack
MessagePortCallBack :: proc "c" (local: MessagePortRef, msgid: SInt32, data: DataRef, info: rawptr) -> DataRef

// CFMessagePortInvalidationCallBack
MessagePortInvalidationCallBack :: proc "c" (ms: MessagePortRef, info: rawptr)

// CFPlugInDynamicRegisterFunction
PlugInDynamicRegisterFunction :: proc "c" (plugIn: PlugInRef)

// CFPlugInUnloadFunction
PlugInUnloadFunction :: proc "c" (plugIn: PlugInRef)

// CFPlugInFactoryFunction
PlugInFactoryFunction :: proc "c" (allocator: AllocatorRef, typeUUID: UUIDRef) -> rawptr

// CFPlugInInstanceRef
PlugInInstanceRef :: ^__CFPlugInInstance

// CFPlugInInstanceGetInterfaceFunction
PlugInInstanceGetInterfaceFunction :: proc "c" (instance: PlugInInstanceRef, interfaceName: StringRef, ftbl: ^rawptr) -> Boolean

// CFPlugInInstanceDeallocateInstanceDataFunction
PlugInInstanceDeallocateInstanceDataFunction :: proc "c" (instanceData: rawptr)

// CFMachPortRef
MachPortRef :: ^__CFMachPort

// CFMachPortCallBack
MachPortCallBack :: proc "c" (port: MachPortRef, msg: rawptr, size: Index, info: rawptr)

// CFMachPortInvalidationCallBack
MachPortInvalidationCallBack :: proc "c" (port: MachPortRef, info: rawptr)

// CFAttributedStringRef
AttributedStringRef :: ^__CFAttributedString

// CFMutableAttributedStringRef
MutableAttributedStringRef :: ^__CFAttributedString

// CFURLEnumeratorRef
URLEnumeratorRef :: ^__CFURLEnumerator

// CFFileSecurityRef
FileSecurityRef :: ^__CFFileSecurity

// CFStringTokenizerRef
StringTokenizerRef :: ^__CFStringTokenizer

// CFFileDescriptorNativeDescriptor
FileDescriptorNativeDescriptor :: c.int

// CFFileDescriptorRef
FileDescriptorRef :: ^__CFFileDescriptor

// CFFileDescriptorCallBack
FileDescriptorCallBack :: proc "c" (f: FileDescriptorRef, callBackTypes: OptionFlags, info: rawptr)

// CFUserNotificationRef
UserNotificationRef :: ^__CFUserNotification

// CFUserNotificationCallBack
UserNotificationCallBack :: proc "c" (userNotification: UserNotificationRef, responseFlags: OptionFlags)

// os_clockid_t
os_clockid_t :: enum c.uint {
	CLOCK_MACH_ABSOLUTE_TIME = 32,
}

// qos_class_t
qos_class_t :: enum c.uint {
	USER_INTERACTIVE = 33,
	USER_INITIATED   = 25,
	DEFAULT          = 21,
	UTILITY          = 17,
	BACKGROUND       = 9,
	UNSPECIFIED      = 0,
}

// dispatch_autorelease_frequency_t
dispatch_autorelease_frequency_t :: enum c.ulong {
	INHERIT   = 0,
	WORK_ITEM = 1,
	NEVER     = 2,
}

// dispatch_block_flags_t
dispatch_block_flags_t :: enum c.ulong {
	BARRIER           = 1,
	DETACHED          = 2,
	ASSIGN_CURRENT    = 4,
	NO_QOS_CLASS      = 8,
	INHERIT_QOS_CLASS = 16,
	ENFORCE_QOS_CLASS = 32,
}

// CFComparisonResult
ComparisonResult :: enum c.long {
	LessThan    = -1,
	EqualTo     = 0,
	GreaterThan = 1,
}

// __CFByteOrder
__CFByteOrder :: enum c.uint {
	Unknown      = 0,
	LittleEndian = 1,
	BigEndian    = 2,
}

// CFNotificationSuspensionBehavior
NotificationSuspensionBehavior :: enum c.long {
	Drop               = 1,
	Coalesce           = 2,
	Hold               = 3,
	DeliverImmediately = 4,
}

// CFLocaleLanguageDirection
LocaleLanguageDirection :: enum c.long {
	Unknown     = 0,
	LeftToRight = 1,
	RightToLeft = 2,
	TopToBottom = 3,
	BottomToTop = 4,
}

// CFGregorianUnitFlags
GregorianUnitFlag :: enum c.ulong {
	sYears   = 0,
	sMonths  = 1,
	sDays    = 2,
	sHours   = 3,
	sMinutes = 4,
	sSeconds = 5,
}
GregorianUnitFlags :: bit_set[GregorianUnitFlag; c.ulong]

// CFDataSearchFlags
DataSearchFlag :: enum c.ulong {
	Backwards = 0,
	Anchored  = 1,
}
DataSearchFlags :: bit_set[DataSearchFlag; c.ulong]

// CFCharacterSetPredefinedSet
CharacterSetPredefinedSet :: enum c.long {
	Control              = 1,
	Whitespace           = 2,
	WhitespaceAndNewline = 3,
	DecimalDigit         = 4,
	Letter               = 5,
	LowercaseLetter      = 6,
	UppercaseLetter      = 7,
	NonBase              = 8,
	Decomposable         = 9,
	AlphaNumeric         = 10,
	Punctuation          = 11,
	CapitalizedLetter    = 13,
	Symbol               = 14,
	Newline              = 15,
	Illegal              = 12,
}

// CFStringCompareFlags
StringCompareFlag :: enum c.ulong {
	CaseInsensitive      = 0,
	Backwards            = 2,
	Anchored             = 3,
	Nonliteral           = 4,
	Localized            = 5,
	Numerically          = 6,
	DiacriticInsensitive = 7,
	WidthInsensitive     = 8,
	ForcedOrdering       = 9,
}
StringCompareFlags :: bit_set[StringCompareFlag; c.ulong]

// CFStringNormalizationForm
StringNormalizationForm :: enum c.long {
	D  = 0,
	KD = 1,
	C  = 2,
	KC = 3,
}

// CFTimeZoneNameStyle
TimeZoneNameStyle :: enum c.long {
	Standard            = 0,
	ShortStandard       = 1,
	DaylightSaving      = 2,
	ShortDaylightSaving = 3,
	Generic             = 4,
	ShortGeneric        = 5,
}

// CFCalendarUnit
CalendarUnit :: enum c.ulong {
	Era               = 2,
	Year              = 4,
	Month             = 8,
	Day               = 16,
	Hour              = 32,
	Minute            = 64,
	Second            = 128,
	Week              = 256,
	Weekday           = 512,
	WeekdayOrdinal    = 1024,
	Quarter           = 2048,
	WeekOfMonth       = 4096,
	WeekOfYear        = 8192,
	YearForWeekOfYear = 16384,
	DayOfYear         = 65536,
}

// CFDateFormatterStyle
DateFormatterStyle :: enum c.long {
	NoStyle     = 0,
	ShortStyle  = 1,
	MediumStyle = 2,
	LongStyle   = 3,
	FullStyle   = 4,
}

// CFISO8601DateFormatOptions
ISO8601DateFormatOptions :: enum c.ulong {
	Year                     = 1,
	Month                    = 2,
	WeekOfYear               = 4,
	Day                      = 16,
	Time                     = 32,
	TimeZone                 = 64,
	SpaceBetweenDateAndTime  = 128,
	DashSeparatorInDate      = 256,
	ColonSeparatorInTime     = 512,
	ColonSeparatorInTimeZone = 1024,
	FractionalSeconds        = 2048,
	FullDate                 = 275,
	FullTime                 = 1632,
	InternetDateTime         = 1907,
}

// CFNumberType
NumberType :: enum c.long {
	SInt8Type     = 1,
	SInt16Type    = 2,
	SInt32Type    = 3,
	SInt64Type    = 4,
	Float32Type   = 5,
	Float64Type   = 6,
	CharType      = 7,
	ShortType     = 8,
	IntType       = 9,
	LongType      = 10,
	LongLongType  = 11,
	FloatType     = 12,
	DoubleType    = 13,
	CFIndexType   = 14,
	NSIntegerType = 15,
	CGFloatType   = 16,
	MaxType       = 16,
}

// CFNumberFormatterStyle
NumberFormatterStyle :: enum c.long {
	NoStyle                 = 0,
	DecimalStyle            = 1,
	CurrencyStyle           = 2,
	PercentStyle            = 3,
	ScientificStyle         = 4,
	SpellOutStyle           = 5,
	OrdinalStyle            = 6,
	CurrencyISOCodeStyle    = 8,
	CurrencyPluralStyle     = 9,
	CurrencyAccountingStyle = 10,
}

// CFNumberFormatterOptionFlags
NumberFormatterOptionFlag :: enum c.ulong {
	ParseIntegersOnly = 0,
}
NumberFormatterOptionFlags :: bit_set[NumberFormatterOptionFlag; c.ulong]

// CFNumberFormatterRoundingMode
NumberFormatterRoundingMode :: enum c.long {
	RoundCeiling  = 0,
	RoundFloor    = 1,
	RoundDown     = 2,
	RoundUp       = 3,
	RoundHalfEven = 4,
	RoundHalfDown = 5,
	RoundHalfUp   = 6,
}

// CFNumberFormatterPadPosition
NumberFormatterPadPosition :: enum c.long {
	BeforePrefix = 0,
	AfterPrefix  = 1,
	BeforeSuffix = 2,
	AfterSuffix  = 3,
}

// CFURLPathStyle
URLPathStyle :: enum c.long {
	POSIXPathStyle   = 0,
	HFSPathStyle     = 1,
	WindowsPathStyle = 2,
}

// CFURLComponentType
URLComponentType :: enum c.long {
	Scheme            = 1,
	NetLocation       = 2,
	Path              = 3,
	ResourceSpecifier = 4,
	User              = 5,
	Password          = 6,
	UserInfo          = 7,
	Host              = 8,
	Port              = 9,
	ParameterString   = 10,
	Query             = 11,
	Fragment          = 12,
}

// CFURLBookmarkCreationOptions
URLBookmarkCreationOptions :: enum c.ulong {
	MinimalBookmarkMask              = 512,
	SuitableForBookmarkFile          = 1024,
	WithSecurityScope                = 2048,
	SecurityScopeAllowOnlyReadAccess = 4096,
	WithoutImplicitSecurityScope     = 536870912,
	PreferFileIDResolutionMask       = 256,
}

// CFURLBookmarkResolutionOptions
URLBookmarkResolutionOptions :: enum c.ulong {
	WithoutUIMask                 = 256,
	WithoutMountingMask           = 512,
	WithSecurityScope             = 1024,
	WithoutImplicitStartAccessing = 32768,
	kWithoutUIMask                = 256,
	kWithoutMountingMask          = 512,
}

// CFRunLoopRunResult
RunLoopRunResult :: enum c.int {
	Finished      = 1,
	Stopped       = 2,
	TimedOut      = 3,
	HandledSource = 4,
}

// CFRunLoopActivity
RunLoopActivity :: enum c.ulong {
	Entry         = 1,
	BeforeTimers  = 2,
	BeforeSources = 4,
	BeforeWaiting = 32,
	AfterWaiting  = 64,
	Exit          = 128,
	AllActivities = 268435455,
}

// CFSocketError
SocketError :: enum c.long {
	Success = 0,
	Error   = -1,
	Timeout = -2,
}

// CFSocketCallBackType
SocketCallBackType :: enum c.ulong {
	NoCallBack      = 0,
	ReadCallBack    = 1,
	AcceptCallBack  = 2,
	DataCallBack    = 3,
	ConnectCallBack = 4,
	WriteCallBack   = 8,
}

// CFStreamStatus
StreamStatus :: enum c.long {
	NotOpen = 0,
	Opening = 1,
	Open    = 2,
	Reading = 3,
	Writing = 4,
	AtEnd   = 5,
	Closed  = 6,
	Error   = 7,
}

// CFStreamEventType
StreamEventType :: enum c.ulong {
	None              = 0,
	OpenCompleted     = 1,
	HasBytesAvailable = 2,
	CanAcceptBytes    = 4,
	ErrorOccurred     = 8,
	EndEncountered    = 16,
}

// CFStreamErrorDomain
StreamErrorDomain :: enum c.long {
	Custom      = -1,
	POSIX       = 1,
	MacOSStatus = 2,
}

// CFPropertyListMutabilityOptions
PropertyListMutabilityOptions :: enum c.ulong {
	Immutable                  = 0,
	MutableContainers          = 1,
	MutableContainersAndLeaves = 2,
}

// CFPropertyListFormat
PropertyListFormat :: enum c.long {
	OpenStepFormat    = 1,
	XMLFormat_v1_0    = 100,
	BinaryFormat_v1_0 = 200,
}


// CFURLError
URLError :: enum c.long {
	UnknownError                 = -10,
	UnknownSchemeError           = -11,
	ResourceNotFoundError        = -12,
	ResourceAccessViolationError = -13,
	RemoteHostUnavailableError   = -14,
	ImproperArgumentsError       = -15,
	UnknownPropertyKeyError      = -16,
	PropertyKeyUnavailableError  = -17,
	TimeoutError                 = -18,
}

// CFURLEnumeratorOptions
URLEnumeratorOptions :: enum c.ulong {
	DefaultBehavior             = 0,
	DescendRecursively          = 1,
	SkipInvisibles              = 2,
	GenerateFileReferenceURLs   = 4,
	SkipPackageContents         = 8,
	IncludeDirectoriesPreOrder  = 16,
	IncludeDirectoriesPostOrder = 32,
	GenerateRelativePathURLs    = 64,
}

// CFURLEnumeratorResult
URLEnumeratorResult :: enum c.long {
	Success                   = 1,
	End                       = 2,
	Error                     = 3,
	DirectoryPostOrderSuccess = 4,
}

// CFFileSecurityClearOptions
FileSecurityClearOptions :: enum c.ulong {
	Owner             = 1,
	Group             = 2,
	Mode              = 4,
	OwnerUUID         = 8,
	GroupUUID         = 16,
	AccessControlList = 32,
}

// CFStringTokenizerTokenType
StringTokenizerTokenType :: enum c.ulong {
	None                    = 0,
	Normal                  = 1,
	HasSubTokensMask        = 2,
	HasDerivedSubTokensMask = 4,
	HasHasNumbersMask       = 8,
	HasNonLettersMask       = 16,
	IsCJWordMask            = 32,
}

// UnsignedWide
UnsignedWide :: struct #align (2) {
	lo: UInt32,
	hi: UInt32,
}
#assert(size_of(UnsignedWide) == 8)

// __CFNull
__CFNull :: struct {}

// __CFAllocator
__CFAllocator :: struct {}

// CFAllocatorContext
AllocatorContext :: struct #align (8) {
	version:         Index,
	info:            rawptr,
	retain:          AllocatorRetainCallBack,
	release:         AllocatorReleaseCallBack,
	copyDescription: AllocatorCopyDescriptionCallBack,
	allocate:        AllocatorAllocateCallBack,
	reallocate:      AllocatorReallocateCallBack,
	deallocate:      AllocatorDeallocateCallBack,
	preferredSize:   AllocatorPreferredSizeCallBack,
}
#assert(size_of(AllocatorContext) == 72)

// CFArrayCallBacks
ArrayCallBacks :: struct #align (8) {
	version:         Index,
	retain:          ArrayRetainCallBack,
	release:         ArrayReleaseCallBack,
	copyDescription: ArrayCopyDescriptionCallBack,
	equal:           ArrayEqualCallBack,
}
#assert(size_of(ArrayCallBacks) == 40)

// __CFArray
__CFArray :: struct {}

// CFBagCallBacks
BagCallBacks :: struct #align (8) {
	version:         Index,
	retain:          BagRetainCallBack,
	release:         BagReleaseCallBack,
	copyDescription: BagCopyDescriptionCallBack,
	equal:           BagEqualCallBack,
	hash:            BagHashCallBack,
}
#assert(size_of(BagCallBacks) == 48)

// __CFBag
__CFBag :: struct {}

// CFBinaryHeapCompareContext
BinaryHeapCompareContext :: struct #align (8) {
	version:         Index,
	info:            rawptr,
	retain:          proc "c" (info: rawptr) -> rawptr,
	release:         proc "c" (info: rawptr),
	copyDescription: proc "c" (info: rawptr) -> StringRef,
}
#assert(size_of(BinaryHeapCompareContext) == 40)

// CFBinaryHeapCallBacks
BinaryHeapCallBacks :: struct #align (8) {
	version:         Index,
	retain:          proc "c" (allocator: AllocatorRef, ptr: rawptr) -> rawptr,
	release:         proc "c" (allocator: AllocatorRef, ptr: rawptr),
	copyDescription: proc "c" (ptr: rawptr) -> StringRef,
	compare:         proc "c" (ptr1: rawptr, ptr2: rawptr, _context: rawptr) -> ComparisonResult,
}
#assert(size_of(BinaryHeapCallBacks) == 40)

// __CFBinaryHeap
__CFBinaryHeap :: struct {}

// __CFBitVector
__CFBitVector :: struct {}

// CFSwappedFloat32
SwappedFloat32 :: struct #align (4) {
	v: u32,
}
#assert(size_of(SwappedFloat32) == 4)

// CFSwappedFloat64
SwappedFloat64 :: struct #align (8) {
	v: u64,
}
#assert(size_of(SwappedFloat64) == 8)

// CFDictionaryKeyCallBacks
DictionaryKeyCallBacks :: struct #align (8) {
	version:         Index,
	retain:          DictionaryRetainCallBack,
	release:         DictionaryReleaseCallBack,
	copyDescription: DictionaryCopyDescriptionCallBack,
	equal:           DictionaryEqualCallBack,
	hash:            DictionaryHashCallBack,
}
#assert(size_of(DictionaryKeyCallBacks) == 48)

// CFDictionaryValueCallBacks
DictionaryValueCallBacks :: struct #align (8) {
	version:         Index,
	retain:          DictionaryRetainCallBack,
	release:         DictionaryReleaseCallBack,
	copyDescription: DictionaryCopyDescriptionCallBack,
	equal:           DictionaryEqualCallBack,
}
#assert(size_of(DictionaryValueCallBacks) == 40)

// __CFDictionary
__CFDictionary :: struct {}

// __CFNotificationCenter
__CFNotificationCenter :: struct {}

// __CFLocale
__CFLocale :: struct {}

// __CFDate
__CFDate :: struct {}

// __CFTimeZone
__CFTimeZone :: struct {}

// CFGregorianDate
GregorianDate :: struct #align (8) {
	year:   SInt32,
	month:  SInt8,
	day:    SInt8,
	hour:   SInt8,
	minute: SInt8,
	second: f64,
}
#assert(size_of(GregorianDate) == 16)

// CFGregorianUnits
GregorianUnits :: struct #align (8) {
	years:   SInt32,
	months:  SInt32,
	days:    SInt32,
	hours:   SInt32,
	minutes: SInt32,
	seconds: f64,
}
#assert(size_of(GregorianUnits) == 32)

// __CFData
__CFData :: struct {}

// __CFCharacterSet
__CFCharacterSet :: struct {}

// __CFError
__CFError :: struct {}

// CFStringInlineBuffer
StringInlineBuffer :: struct #align (8) {
	buffer:              [64]UniChar,
	theString:           StringRef,
	directUniCharBuffer: ^UniChar,
	directCStringBuffer: cstring,
	rangeToBuffer:       Range,
	bufferedRangeStart:  Index,
	bufferedRangeEnd:    Index,
}
#assert(size_of(StringInlineBuffer) == 184)

// __CFCalendar
__CFCalendar :: struct {}

// __CFDateFormatter
__CFDateFormatter :: struct {}

// __CFBoolean
__CFBoolean :: struct {}

// __CFNumber
__CFNumber :: struct {}

// __CFNumberFormatter
__CFNumberFormatter :: struct {}

// __CFURL
__CFURL :: struct {}

// __CFRunLoop
__CFRunLoop :: struct {}

// __CFRunLoopSource
__CFRunLoopSource :: struct {}

// __CFRunLoopObserver
__CFRunLoopObserver :: struct {}

// __CFRunLoopTimer
__CFRunLoopTimer :: struct {}

// CFRunLoopSourceContext
RunLoopSourceContext :: struct #align (8) {
	version:         Index,
	info:            rawptr,
	retain:          proc "c" (info: rawptr) -> rawptr,
	release:         proc "c" (info: rawptr),
	copyDescription: proc "c" (info: rawptr) -> StringRef,
	equal:           proc "c" (info1: rawptr, info2: rawptr) -> Boolean,
	hash:            proc "c" (info: rawptr) -> HashCode,
	schedule:        proc "c" (info: rawptr, rl: RunLoopRef, mode: RunLoopMode),
	cancel:          proc "c" (info: rawptr, rl: RunLoopRef, mode: RunLoopMode),
	perform:         proc "c" (info: rawptr),
}
#assert(size_of(RunLoopSourceContext) == 80)

// CFRunLoopSourceContext1
RunLoopSourceContext1 :: struct #align (8) {
	version:         Index,
	info:            rawptr,
	retain:          proc "c" (info: rawptr) -> rawptr,
	release:         proc "c" (info: rawptr),
	copyDescription: proc "c" (info: rawptr) -> StringRef,
	equal:           proc "c" (info1: rawptr, info2: rawptr) -> Boolean,
	hash:            proc "c" (info: rawptr) -> HashCode,
	getPort:         proc "c" (info: rawptr) -> darwin.mach_port_t,
	perform:         proc "c" (msg: rawptr, size: Index, allocator: AllocatorRef, info: rawptr) -> rawptr,
}
#assert(size_of(RunLoopSourceContext1) == 72)

// CFRunLoopObserverContext
RunLoopObserverContext :: struct #align (8) {
	version:         Index,
	info:            rawptr,
	retain:          proc "c" (info: rawptr) -> rawptr,
	release:         proc "c" (info: rawptr),
	copyDescription: proc "c" (info: rawptr) -> StringRef,
}
#assert(size_of(RunLoopObserverContext) == 40)

// CFRunLoopTimerContext
RunLoopTimerContext :: struct #align (8) {
	version:         Index,
	info:            rawptr,
	retain:          proc "c" (info: rawptr) -> rawptr,
	release:         proc "c" (info: rawptr),
	copyDescription: proc "c" (info: rawptr) -> StringRef,
}
#assert(size_of(RunLoopTimerContext) == 40)

// __CFSocket
__CFSocket :: struct {}

// CFSocketSignature
SocketSignature :: struct #align (8) {
	protocolFamily: SInt32,
	socketType:     SInt32,
	protocol:       SInt32,
	address:        DataRef,
}
#assert(size_of(SocketSignature) == 24)

// CFSocketContext
SocketContext :: struct #align (8) {
	version:         Index,
	info:            rawptr,
	retain:          proc "c" (info: rawptr) -> rawptr,
	release:         proc "c" (info: rawptr),
	copyDescription: proc "c" (info: rawptr) -> StringRef,
}
#assert(size_of(SocketContext) == 40)

// os_workgroup_attr_opaque_s
os_workgroup_attr_opaque_s :: struct #align (4) {
	sig:    u32,
	opaque: [60]u8,
}
#assert(size_of(os_workgroup_attr_opaque_s) == 64)

// os_workgroup_interval_data_opaque_s
os_workgroup_interval_data_opaque_s :: struct #align (4) {
	sig:    u32,
	opaque: [56]u8,
}
#assert(size_of(os_workgroup_interval_data_opaque_s) == 60)

// os_workgroup_join_token_opaque_s
os_workgroup_join_token_opaque_s :: struct #align (4) {
	sig:    u32,
	opaque: [36]u8,
}
#assert(size_of(os_workgroup_join_token_opaque_s) == 40)

// os_workgroup_s
os_workgroup_s :: struct {}

// os_workgroup_max_parallel_threads_attr_s
os_workgroup_max_parallel_threads_attr_s :: struct {}

// dispatch_object_t::_os_object_s
_os_object_s :: struct {}

// dispatch_object_t::dispatch_object_s
dispatch_object_s :: struct {}

// dispatch_object_t::dispatch_queue_s
dispatch_queue_s :: struct {}

// dispatch_object_t::dispatch_queue_attr_s
dispatch_queue_attr_s :: struct {}

// dispatch_object_t::dispatch_group_s
dispatch_group_s :: struct {}

// dispatch_object_t::dispatch_source_s
dispatch_source_s :: struct {}

// dispatch_object_t::dispatch_channel_s
dispatch_channel_s :: struct {}

// dispatch_object_t::dispatch_mach_s
dispatch_mach_s :: struct {}

// dispatch_object_t::dispatch_mach_msg_s
dispatch_mach_msg_s :: struct {}

// dispatch_object_t::dispatch_semaphore_s
dispatch_semaphore_s :: struct {}

// dispatch_object_t::dispatch_data_s
dispatch_data_s :: struct {}

// dispatch_object_t::dispatch_io_s
dispatch_io_s :: struct {}

// dispatch_source_type_s
dispatch_source_type_s :: struct {}

// CFStreamError
StreamError :: struct #align (8) {
	domain: Index,
	error:  SInt32,
}
#assert(size_of(StreamError) == 16)

// CFStreamClientContext
StreamClientContext :: struct #align (8) {
	version:         Index,
	info:            rawptr,
	retain:          proc "c" (info: rawptr) -> rawptr,
	release:         proc "c" (info: rawptr),
	copyDescription: proc "c" (info: rawptr) -> StringRef,
}
#assert(size_of(StreamClientContext) == 40)

// __CFReadStream
__CFReadStream :: struct {}

// __CFWriteStream
__CFWriteStream :: struct {}

// CFSetCallBacks
SetCallBacks :: struct #align (8) {
	version:         Index,
	retain:          SetRetainCallBack,
	release:         SetReleaseCallBack,
	copyDescription: SetCopyDescriptionCallBack,
	equal:           SetEqualCallBack,
	hash:            SetHashCallBack,
}
#assert(size_of(SetCallBacks) == 48)

// __CFSet
__CFSet :: struct {}

// CFTreeContext
TreeContext :: struct #align (8) {
	version:         Index,
	info:            rawptr,
	retain:          TreeRetainCallBack,
	release:         TreeReleaseCallBack,
	copyDescription: TreeCopyDescriptionCallBack,
}
#assert(size_of(TreeContext) == 40)

// __CFTree
__CFTree :: struct {}

// __CFUUID
__CFUUID :: struct {}

// CFUUIDBytes
UUIDBytes :: struct #align (1) {
	byte0:  UInt8,
	byte1:  UInt8,
	byte2:  UInt8,
	byte3:  UInt8,
	byte4:  UInt8,
	byte5:  UInt8,
	byte6:  UInt8,
	byte7:  UInt8,
	byte8:  UInt8,
	byte9:  UInt8,
	byte10: UInt8,
	byte11: UInt8,
	byte12: UInt8,
	byte13: UInt8,
	byte14: UInt8,
	byte15: UInt8,
}
#assert(size_of(UUIDBytes) == 16)

// __CFBundle
__CFBundle :: struct {}

// __CFMessagePort
__CFMessagePort :: struct {}

// CFMessagePortContext
MessagePortContext :: struct #align (8) {
	version:         Index,
	info:            rawptr,
	retain:          proc "c" (info: rawptr) -> rawptr,
	release:         proc "c" (info: rawptr),
	copyDescription: proc "c" (info: rawptr) -> StringRef,
}
#assert(size_of(MessagePortContext) == 40)

// __CFPlugInInstance
__CFPlugInInstance :: struct {}

// __CFMachPort
__CFMachPort :: struct {}

// CFMachPortContext
MachPortContext :: struct #align (8) {
	version:         Index,
	info:            rawptr,
	retain:          proc "c" (info: rawptr) -> rawptr,
	release:         proc "c" (info: rawptr),
	copyDescription: proc "c" (info: rawptr) -> StringRef,
}
#assert(size_of(MachPortContext) == 40)

// __CFAttributedString
__CFAttributedString :: struct {}

// __CFURLEnumerator
__CFURLEnumerator :: struct {}

// __CFFileSecurity
__CFFileSecurity :: struct {}

// __CFStringTokenizer
__CFStringTokenizer :: struct {}

// __CFFileDescriptor
__CFFileDescriptor :: struct {}

// CFFileDescriptorContext
FileDescriptorContext :: struct #align (8) {
	version:         Index,
	info:            rawptr,
	retain:          proc "c" (info: rawptr) -> rawptr,
	release:         proc "c" (info: rawptr),
	copyDescription: proc "c" (info: rawptr) -> StringRef,
}
#assert(size_of(FileDescriptorContext) == 40)

// __CFUserNotification
__CFUserNotification :: struct {}

// dispatch_object_t
dispatch_object_t :: struct #raw_union #align (8) {
	_os_obj:   ^_os_object_s,
	_do:       ^dispatch_object_s,
	_dq:       ^dispatch_queue_s,
	_dqa:      ^dispatch_queue_attr_s,
	_dg:       ^dispatch_group_s,
	_ds:       ^dispatch_source_s,
	_dch:      ^dispatch_channel_s,
	_dm:       ^dispatch_mach_s,
	_dmsg:     ^dispatch_mach_msg_s,
	_dsema:    ^dispatch_semaphore_s,
	_ddata:    ^dispatch_data_s,
	_dchannel: ^dispatch_io_s,
}
#assert(size_of(dispatch_object_t) == 8)

