//+build linux, freebsd, openbsd
package xlib

/* ----  X11/extensions/XKB.h ---------------------------------------------------------*/

XkbMinLegalKeyCode     :: 8
XkbMaxLegalKeyCode     :: 255
XkbMaxKeyCount         :: XkbMaxLegalKeyCode - XkbMinLegalKeyCode + 1
XkbPerKeyBitArraySize  :: (XkbMaxLegalKeyCode + 1) / 8
XkbKeyNameLength       :: 4
XkbNumVirtualMods      :: 16
XkbNumIndicators       :: 32
XkbNumKbdGroups        :: 4
XkbAnyActionDataSize   :: 7
XkbUseCoreKbd          :: 0x0100
XkbActionMessageLength :: 6

XkbInfoMask :: bit_set[XkbInfoMaskBits; int]
XkbInfoMaskBits :: enum u32 {
	KeyTypes           = 0,
	KeySyms            = 1,
	ModifierMap        = 2,
	ExplicitComponents = 3,
	KeyActions         = 4,
	KeyBehaviors       = 5,
	VirtualMods        = 6,
	VirtualModMap      = 7,
}

XkbAllClientInfoMask :: XkbInfoMask {
	.KeyTypes,
	.KeySyms,
	.ModifierMap,
}

XkbAllServerInfoMask :: XkbInfoMask {
	.ExplicitComponents,
	.KeyActions,
	.KeyBehaviors,
	.VirtualMods,
	.VirtualModMap,
}

XkbEventMask :: bit_set[XkbEventType; int]
XkbEventType :: enum i32 {
	NewKeyboardNotify     = 0,
	MapNotify             = 1,
	StateNotify           = 2,
	ControlsNotify        = 3,
	IndicatorStateNotify  = 4,
	IndicatorMapNotify    = 5,
	NamesNotify           = 6,
	CompatMapNotify       = 7,
	BellNotify            = 8,
	ActionMessage         = 9,
	AccessXNotify         = 10,
	ExtensionDeviceNotify = 11,
}

XkbAllEventsMask :: XkbEventMask {
	.NewKeyboardNotify,
	.MapNotify,
	.StateNotify,
	.ControlsNotify,
	.IndicatorStateNotify,
	.IndicatorMapNotify,
	.NamesNotify,
	.CompatMapNotify,
	.BellNotify,
	.ActionMessage,
	.AccessXNotify,
	.ExtensionDeviceNotify,
}

/* ----  X11/extensions/XI2.h ---------------------------------------------------------*/

XIAllDevices :: 0
XIAllMasterDevices :: 1


/* ----  X11/Xlib.h ---------------------------------------------------------*/

// Special values for many types. Most of these constants
// aren't attached to a specific type.

None            :: 0
ParentRelative  :: 1
CopyFromParent  :: 0
PointerWindow   :: 0
InputFocus      :: 1
PointerRoot     :: 1
AnyPropertyType :: 0
AnyKey          :: 0
AnyButton       :: 0
AllTemporary    :: 0
CurrentTime     :: 0
NoSymbol        :: 0

PropModeReplace :: 0
PropModePrepend :: 1
PropModeAppend  :: 2

XA_ATOM              :: Atom(4)
XA_WM_CLASS          :: Atom(67)
XA_WM_CLIENT_MACHINE :: Atom(36)
XA_WM_COMMAND        :: Atom(34)
XA_WM_HINTS          :: Atom(35)
XA_WM_ICON_NAME      :: Atom(37)
XA_WM_ICON_SIZE      :: Atom(38)
XA_WM_NAME           :: Atom(39)
XA_WM_NORMAL_HINTS   :: Atom(40)
XA_WM_SIZE_HINTS     :: Atom(41)
XA_WM_TRANSIENT_FOR  :: Atom(68)
XA_WM_ZOOM_HINTS     :: Atom(42)

// NOTE(flysand): Some implementations return Status as enum, other return it
// as an integer. I will make it a status.
Status :: enum i32 {
	Success             = 0,
	BadRequest          = 1,
	BadValue            = 2,
	BadWindow           = 3,
	BadPixmap           = 4,
	BadAtom             = 5,
	BadCursor           = 6,
	BadFont             = 7,
	BadMatch            = 8,
	BadDrawable         = 9,
	BadAccess           = 10,
	BadAlloc            = 11,
	BadColor            = 12,
	BadGC               = 13,
	BadIDChoice         = 14,
	BadName             = 15,
	BadLength           = 16,
	BadImplementation   = 17,
	FirstExtensionError = 128,
	LastExtensionError  = 255,
}

ByteOrder :: enum i32 {
	LSBFirst = 0,
	MSBFirst = 1,
}

Gravity :: enum i32 {
	ForgetGravity    =  0,
	UnmapGravity     =  0,
	NorthWestGravity =  1,
	NorthGravity     =  2,
	NorthEastGravity =  3,
	WestGravity      =  4,
	CenterGravity    =  5,
	EastGravity      =  6,
	SouthWestGravity =  7,
	SouthGravity     =  8,
	SouthEastGravity =  9,
	StaticGravity    = 10,
}

BackingStore :: enum i32 {
	NotUseful  = 0,
	WhenMapped = 1,
	Always     = 2,
}

MouseButton :: enum i32 {
	Button1 = 1,
	Button2 = 2,
	Button3 = 3,
	Button4 = 4,
	Button5 = 5,
}

EventMask :: bit_set[EventMaskBits; int]
EventMaskBits :: enum i32 {
	KeyPress             =  0,
	KeyRelease           =  1,
	ButtonPress          =  2,
	ButtonRelease        =  3,
	EnterWindow          =  4,
	LeaveWindow          =  5,
	PointerMotion        =  6,
	PointerMotionHint    =  7,
	Button1Motion        =  8,
	Button2Motion        =  9,
	Button3Motion        = 10,
	Button4Motion        = 11,
	Button5Motion        = 12,
	ButtonMotion         = 13,
	KeymapState          = 14,
	Exposure             = 15,
	VisibilityChange     = 16,
	StructureNotify      = 17,
	ResizeRedirect       = 18,
	SubstructureNotify   = 19,
	SubstructureRedirect = 20,
	FocusChange          = 21,
	PropertyChange       = 22,
	ColormapChange       = 23,
	OwnerGrabButton      = 24,
}

EventType :: enum i32 {
	KeyPress         = 2,
	KeyRelease       = 3,
	ButtonPress      = 4,
	ButtonRelease    = 5,
	MotionNotify     = 6,
	EnterNotify      = 7,
	LeaveNotify      = 8,
	FocusIn          = 9,
	FocusOut         = 10,
	KeymapNotify     = 11,
	Expose           = 12,
	GraphicsExpose   = 13,
	NoExpose         = 14,
	VisibilityNotify = 15,
	CreateNotify     = 16,
	DestroyNotify    = 17,
	UnmapNotify      = 18,
	MapNotify        = 19,
	MapRequest       = 20,
	ReparentNotify   = 21,
	ConfigureNotify  = 22,
	ConfigureRequest = 23,
	GravityNotify    = 24,
	ResizeRequest    = 25,
	CirculateNotify  = 26,
	CirculateRequest = 27,
	PropertyNotify   = 28,
	SelectionClear   = 29,
	SelectionRequest = 30,
	SelectionNotify  = 31,
	ColormapNotify   = 32,
	ClientMessage    = 33,
	MappingNotify    = 34,
	GenericEvent     = 35,
}

InputMask :: bit_set[InputMaskBits; i32]
InputMaskBits :: enum {
	ShiftMask   = 0,
	LockMask    = 1,
	ControlMask = 2,
	Mod1Mask    = 3,
	Mod2Mask    = 4,
	Mod3Mask    = 5,
	Mod4Mask    = 6,
	Mod5Mask    = 7,
	Button1Mask = 8,
	Button2Mask = 9,
	Button3Mask = 10,
	Button4Mask = 11,
	Button5Mask = 12,
	AnyModifier = 15,
}

NotifyMode :: enum i32 {
	NotifyNormal       = 0,
	NotifyGrab         = 1,
	NotifyUngrab       = 2,
	NotifyWhileGrabbed = 3,
}

NotifyDetail :: enum i32 {
	NotifyAncestor         = 0,
	NotifyVirtual          = 1,
	NotifyInferior         = 2,
	NotifyNonlinear        = 3,
	NotifyNonlinearVirtual = 4,
	NotifyPointer          = 5,
	NotifyPointerRoot      = 6,
	NotifyDetailNone       = 7,
}

MappingRequest :: enum i32 {
	MappingModifier = 0,
	MappingKeyboard = 1,
	MappingPointer  = 2,
}

VisibilityState :: enum i32 {
	VisibilityUnobscured        = 0,
	VisibilityPartiallyObscured = 1,
	VisibilityFullyObscured     = 2,
}

ColormapState :: enum i32 {
	ColormapUninstalled = 0,
	ColormapInstalled   = 1,
}

PropertyState :: enum i32 {
	PropertyNewValue = 0,
	PropertyDelete   = 1,
}

CloseMode :: enum i32 {
	DestroyAll      = 0,
	RetainPermanent = 1,
	RetainTemporary = 2,
}

EventQueueMode :: enum i32 {
	QueuedAlready      = 0,
	QueuedAfterReading = 1,
	QueuedAfterFlush   = 2,
}

WindowAttributeMask :: bit_set[WindowAttributeMaskBits; int]
WindowAttributeMaskBits :: enum {
	CWBackPixmap       = 0,
	CWBackPixel        = 1,
	CWBorderPixmap     = 2,
	CWBorderPixel      = 3,
	CWBitGravity       = 4,
	CWWinGravity       = 5,
	CWBackingStore     = 6,
	CWBackingPlanes    = 7,
	CWBackingPixel     = 8,
	CWOverrideRedirect = 9,
	CWSaveUnder        = 10,
	CWEventMask        = 11,
	CWDontPropagate    = 12,
	CWColormap         = 13,
	CWCursor           = 14,
}

WindowClass :: enum i32 {
	CopyFromParent = 0,
	InputOutput    = 1,
	InputOnly      = 2,
}

WindowChangesMask :: bit_set[WindowChangesMaskBits; i32]
WindowChangesMaskBits :: enum {
	CWX           = 0,
	CWY           = 1,
	CWWidth       = 2,
	CWHeight      = 3,
	CWBorderWidth = 4,
	CWSibling     = 5,
	CWStackMode   = 6,
}

WindowStacking :: enum i32 {
	Above    = 0,
	Below    = 1,
	TopIf    = 2,
	BottomIf = 3,
	Opposite = 4,
}

CirculationDirection :: enum i32 {
	RaiseLowest  = 0,
	LowerHighest = 1,
}

CirculationRequest :: enum i32 {
	PlaceOnTop    = 0,
	PlaceOnBottom = 1,
}

WindowMapState :: enum i32 {
	IsUnmapped   = 0,
	IsUnviewable = 1,
	IsViewable   = 2,
}

KeyMask :: enum u32 {
	ShiftMask   = 0,
	LockMask    = 1,
	ControlMask = 2,
	Mod1Mask    = 3,
	Mod2Mask    = 4,
	Mod3Mask    = 5,
	Mod4Mask    = 6,
	Mod5Mask    = 7,
}

CursorShape :: enum u32 {
	XC_X_cursor            = 0,
	XC_arrow               = 2,
	XC_based_arrow_down    = 4,
	XC_based_arrow_up      = 6,
	XC_boat                = 8,
	XC_bogosity            = 10,
	XC_bottom_left_corner  = 12,
	XC_bottom_right_corner = 14,
	XC_bottom_side         = 16,
	XC_bottom_tee          = 18,
	XC_box_spiral          = 20,
	XC_center_ptr          = 22,
	XC_circle              = 24,
	XC_clock               = 26,
	XC_coffee_mug          = 28,
	XC_cross               = 30,
	XC_cross_reverse       = 32,
	XC_crosshair           = 34,
	XC_diamond_cross       = 36,
	XC_dot                 = 38,
	XC_dotbox              = 40,
	XC_double_arrow        = 42,
	XC_draft_large         = 44,
	XC_draft_small         = 46,
	XC_draped_box          = 48,
	XC_exchange            = 50,
	XC_fleur               = 52,
	XC_gobbler             = 54,
	XC_gumby               = 56,
	XC_hand1               = 58,
	XC_hand2               = 60,
	XC_heart               = 62,
	XC_icon                = 64,
	XC_iron_cross          = 66,
	XC_left_ptr            = 68,
	XC_left_side           = 70,
	XC_left_tee            = 72,
	XC_leftbutton          = 74,
	XC_ll_angle            = 76,
	XC_lr_angle            = 78,
	XC_man                 = 80,
	XC_middlebutton        = 82,
	XC_mouse               = 84,
	XC_pencil              = 86,
	XC_pirate              = 88,
	XC_plus                = 90,
	XC_question_arrow      = 92,
	XC_right_ptr           = 94,
	XC_right_side          = 96,
	XC_right_tee           = 98,
	XC_rightbutton         = 100,
	XC_rtl_logo            = 102,
	XC_sailboat            = 104,
	XC_sb_down_arrow       = 106,
	XC_sb_h_double_arrow   = 108,
	XC_sb_left_arrow       = 110,
	XC_sb_right_arrow      = 112,
	XC_sb_up_arrow         = 114,
	XC_sb_v_double_arrow   = 116,
	XC_shuttle             = 118,
	XC_sizing              = 120,
	XC_spider              = 122,
	XC_spraycan            = 124,
	XC_star                = 126,
	XC_target              = 128,
	XC_tcross              = 130,
	XC_top_left_arrow      = 132,
	XC_top_left_corner     = 134,
	XC_top_right_corner    = 136,
	XC_top_side            = 138,
	XC_top_tee             = 140,
	XC_trek                = 142,
	XC_ul_angle            = 144,
	XC_umbrella            = 146,
	XC_ur_angle            = 148,
	XC_watch               = 150,
	XC_xterm               = 152,
	XC_num_glyphs          = 154,
}

ColorFormat :: enum u32 {
	XcmsUndefinedFormat = 0x00000000,
	XcmsCIEXYZFormat    = 0x00000001,
	XcmsCIEuvYFormat    = 0x00000002,
	XcmsCIExyYFormat    = 0x00000003,
	XcmsCIELabFormat    = 0x00000004,
	XcmsCIELuvFormat    = 0x00000005,
	XcmsTekHVCFormat    = 0x00000006,
	XcmsRGBFormat       = 0x80000000,
	XcmsRGBiFormat      = 0x80000001,
}

ColormapAlloc :: enum i32 {
	AllocNone = 0,
	AllocAll  = 1,
}

ColorFlags :: bit_set[ColorFlagsBits; i32]
ColorFlagsBits :: enum {
	DoRed   = 0,
	DoGreen = 1,
	DoBlue  = 2,
}

GCAttributeMask :: bit_set[GCAttributeMaskBits; uint]
GCAttributeMaskBits :: enum {
	GCFunction         = 0,
	GCPlaneMask        = 1,
	GCForeground       = 2,
	GCBackground       = 3,
	GCLineWidth        = 4,
	GCLineStyle        = 5,
	GCCapStyle         = 6,
	GCJoinStyle        = 7,
	GCFillStyle        = 8,
	GCFillRule         = 9,
	GCTile             = 10,
	GCStipple          = 11,
	GCTileStipXOrigin  = 12,
	GCTileStipYOrigin  = 13,
	GCFont             = 14,
	GCSubwindowMode    = 15,
	GCGraphicsExposures= 16,
	GCClipXOrigin      = 17,
	GCClipYOrigin      = 18,
	GCClipMask         = 19,
	GCDashOffset       = 20,
	GCDashList         = 21,
	GCArcMode          = 22,
}

GCFunction :: enum i32 {
	GXclear        = 0x0, // 0
	GXand          = 0x1, // src & dst
	GXandReverse   = 0x2, // src & ~dst
	GXcopy         = 0x3, // src
	GXandInverted  = 0x4, // ~src & dst
	GXnoop         = 0x5, // dst
	GXxor          = 0x6, // src ~ dst
	GXor           = 0x7, // src | dst
	GXnor          = 0x8, // ~src & ~dst
	GXequiv        = 0x9, // ~src ~ dst
	GXinvert       = 0xa, // ~dst
	GXorReverse    = 0xb, // src | ~dst
	GXcopyInverted = 0xc, // ~src
	GXorInverted   = 0xd, // ~src | dst
	GXnand         = 0xe, // ~src | ~dst
	GXset          = 0xf, // 1
}

LineStyle :: enum i32 {
	LineSolid      = 0,
	LineOnOffDash  = 1,
	LineDoubleDash = 2,
}

CapStyle :: enum i32 {
	CapNotLast    = 0,
	CapButt       = 1,
	CapRound      = 2,
	CapProjecting = 3,
}

JoinStyle :: enum i32 {
	JoinMiter = 0,
	JoinRound = 1,
	JoinBevel = 2,
}

FillStyle :: enum i32 {
	FillSolid          = 0,
	FillTiled          = 1,
	FillStippled       = 2,
	FillOpaqueStippled = 3,
}

FillRule :: enum i32 {
	EvenOddRule = 0,
	WindingRule = 1,
}

ArcMode :: enum i32 {
	ArcChord    = 0,
	ArcPieSlice = 1,
}

SubwindowMode :: enum i32 {
	ClipByChildren   = 0,
	IncludeInferiors = 1,
}

CoordMode :: enum i32 {
	CoordModeOrigin   = 0,
	CoordModePrevious = 1,
}

Shape :: enum i32 {
	Complex   = 0,
	Nonconvex = 1,
	Convex    = 2,
}

FontDirection :: enum i32 {
	FontLeftToRight = 0,
	FontRightToLeft = 1,
}

ImageFormat :: enum i32 {
	XYBitmap = 0,
	XYPixmap = 1,
	ZPixmap  = 2,
}

SaveSetChangeMode :: enum i32 {
	SetModeInsert = 0,
	SetModeDelete = 1,
}


ScreenSaverBlanking :: enum i32 {
	DontPreferBlanking = 0,
	PreferBlanking     = 1,
	DefaultBlanking    = 2,
}

ScreenSavingExposures :: enum i32 {
	DontAllowExposures = 0,
	AllowExposures     = 1,
	DefaultExposures   = 2,
}

ScreenSaverForceMode :: enum i32 {
	ScreenSaverReset  = 0,
	ScreenSaverActive = 1,
}

AccessControlMode :: enum i32 {
	DisableAccess = 0,
	EnableAccess  = 1,
}

GrabMode :: enum i32 {
	GrabModeSync  = 0,
	GrabModeAsync = 1,
}

AllowEventsMode :: enum i32 {
	AsyncPointer   = 0,
	SyncPointer    = 1,
	ReplayPointer  = 2,
	AsyncKeyboard  = 3,
	SyncKeyboard   = 4,
	ReplayKeyboard = 5,
	AsyncBoth      = 6,
	SyncBoth       = 7,
}

FocusRevert :: enum i32 {
	RevertToNone        = 0,
	RevertToPointerRoot = 1,
	RevertToParent      = 2,
}

KeyboardControlMask :: bit_set[KeyboardControlMaskBits; int]
KeyboardControlMaskBits :: enum {
	KBKeyClickPercent = 0,
	KBBellPercent     = 1,
	KBBellPitch       = 2,
	KBBellDuration    = 3,
	KBLed             = 4,
	KBLedMode         = 5,
	KBKey             = 6,
	KBAutoRepeatMode  = 7,
}

KeyboardAutoRepeatMode :: enum i32 {
	AutoRepeatModeOff     = 0,
	AutoRepeatModeOn      = 1,
	AutoRepeatModeDefault = 2,
}

KeyboardLedMode :: enum i32 {
	LedModeOff = 0,
	LedModeOn  = 1,
}

WMHints :: bit_set[WMHintsBits; uint]
WMHintsBits :: enum {
	InputHint        = 0,
	StateHint        = 1,
	IconPixmapHint   = 2,
	IconWindowHint   = 3,
	IconPositionHint = 4,
	IconMaskHint     = 5,
	WindowGroupHint  = 6,
	XUrgencyHint     = 8,
}

WMHintState :: enum i32 {
	WithdrawnState = 0,
	NormalState    = 1,
	IconicState    = 3,
}

AllHints :: WMHints{
	.InputHint,
	.StateHint,
	.IconPixmapHint,
	.IconWindowHint,
	.IconPositionHint,
	.IconMaskHint,
	.WindowGroupHint,
}

SizeHints :: bit_set[SizeHintsBits; uint]
SizeHintsBits :: enum {
	USPosition  = 0,
	USSize      = 1,
	PPosition   = 2,
	PSize       = 3,
	PMinSize    = 4,
	PMaxSize    = 5,
	PResizeInc  = 6,
	PAspect     = 7,
	PBaseSize   = 8,
	PWinGravity = 9,
}

VisualInfoMask :: bit_set[VisualInfoMaskBits; int]
VisualInfoMaskBits :: enum {
	VisualIDMask           = 0,
	VisualScreenMask       = 1,
	VisualDepthMask        = 2,
	VisualClassMask        = 3,
	VisualRedMaskMask      = 4,
	VisualGreenMaskMask    = 5,
	VisualBlueMaskMask     = 6,
	VisualColormapSizeMask = 7,
	VisualBitsPerRGBMask   = 8,
}

VisualNoMask  :: VisualInfoMask {}
VisualAllMask :: VisualInfoMask {
	.VisualIDMask,
	.VisualScreenMask,
	.VisualDepthMask,
	.VisualClassMask,
	.VisualRedMaskMask,
	.VisualGreenMaskMask,
	.VisualBlueMaskMask,
	.VisualColormapSizeMask,
	.VisualBitsPerRGBMask,
}
