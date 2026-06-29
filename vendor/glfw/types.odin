// Bindings for [[ GLFW ; https://www.glfw.org ]]
package glfw

import glfw "bindings"

WindowHandle  :: glfw.WindowHandle
MonitorHandle :: glfw.MonitorHandle
CursorHandle  :: glfw.CursorHandle

VidMode :: glfw.VidMode
GammaRamp :: glfw.GammaRamp
Image :: glfw.Image
GamepadState :: glfw.GamepadState

Allocator :: glfw.Allocator

/*** Procedure type declarations ***/
WindowIconifyProc      :: glfw.WindowIconifyProc
WindowRefreshProc      :: glfw.WindowRefreshProc
WindowFocusProc        :: glfw.WindowFocusProc
WindowCloseProc        :: glfw.WindowCloseProc
WindowSizeProc         :: glfw.WindowSizeProc
WindowPosProc          :: glfw.WindowPosProc
WindowMaximizeProc     :: glfw.WindowMaximizeProc
WindowContentScaleProc :: glfw.WindowContentScaleProc
FramebufferSizeProc    :: glfw.FramebufferSizeProc
DropProc               :: glfw.DropProc
MonitorProc            :: glfw.MonitorProc

KeyProc                :: glfw.KeyProc
MouseButtonProc        :: glfw.MouseButtonProc
CursorPosProc          :: glfw.CursorPosProc
ScrollProc             :: glfw.ScrollProc
CharProc               :: glfw.CharProc
CharModsProc           :: glfw.CharModsProc
CursorEnterProc        :: glfw.CursorEnterProc
JoystickProc           :: glfw.JoystickProc

ErrorProc              :: glfw.ErrorProc

AllocateProc           :: glfw.AllocateProc
ReallocateProc         :: glfw.ReallocateProc
DeallocateProc         :: glfw.DeallocateProc
