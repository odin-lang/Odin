package CoreGraphics

import    "core:c"
import CF "core:sys/darwin/CoreFoundation"

@(require)
foreign import "system:CoreGraphics.framework"

@(link_prefix="CG", default_calling_convention="c")
foreign CoreGraphics {
	AssociateMouseAndMouseCursorPosition :: proc(connected: b32) -> Error ---
	DisplayIDToOpenGLDisplayMask         :: proc(display: DirectDisplayID) -> OpenGLDisplayMask ---
	DisplayMoveCursorToPoint             :: proc(display: DirectDisplayID, point: Point) -> Error ---
	EventSourceKeyState                  :: proc(stateID: EventSourceStateID, key: KeyCode) -> bool ---
	GetActiveDisplayList                 :: proc(maxDisplays: c.uint32_t, activeDisplays: [^]DirectDisplayID, displayCount: ^c.uint32_t) -> Error ---
	GetDisplaysWithOpenGLDisplayMask     :: proc(mask: OpenGLDisplayMask, maxDisplays: c.uint32_t, displays: [^]DirectDisplayID, matchingDisplayCount: ^c.uint32_t) -> Error ---
	GetDisplaysWithPoint                 :: proc(point: Point, maxDisplays: c.uint32_t, displays: [^]DirectDisplayID, matchingDisplayCount: ^c.uint32_t) -> Error ---
	GetDisplaysWithRect                  :: proc(rect: Rect, maxDisplays: c.uint32_t, displays: [^]DirectDisplayID, matchingDisplayCount: ^c.uint32_t) -> Error ---
	GetOnlineDisplayList                 :: proc(maxDisplays: c.uint32_t, onlineDisplays: [^]DirectDisplayID, displayCount: ^c.uint32_t) -> Error ---
	MainDisplayID                        :: proc() -> DirectDisplayID ---
	OpenGLDisplayMaskToDisplayID         :: proc(mask: OpenGLDisplayMask) -> DirectDisplayID ---
	WarpMouseCursorPosition              :: proc(newCursorPosition: Point) -> Error ---
}

DirectDisplayID :: c.uint32_t

Error :: enum c.int32_t {
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

EventSourceStateID :: enum c.int32_t {
	Private              = -1,
	CombinedSessionState = 0,
	HIDSystemState       = 1,
}

Float :: CF.CGFloat

KeyCode :: c.uint16_t

OpenGLDisplayMask :: c.uint32_t

Point :: CF.CGPoint

Rect :: CF.CGRect

Size :: CF.CGSize
