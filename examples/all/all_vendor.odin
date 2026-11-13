#+build !js
package all

// NOTE: Packages that link libraries which are only bundled as x64 builds for Windows are in `all_vendor_libs.odin`,
// or in `all_vendor_windows_x86.odin` for the Windows only ones.

@(require) import "vendor:cgltf"
@(require) import "vendor:OpenGL"
@(require) import "vendor:microui"
@(require) import "vendor:miniaudio"

@(require) import "vendor:vulkan"

@(require) import "vendor:nanovg"
@(require) import "vendor:nanovg/gl"
@(require) import "vendor:fontstash"

// NOTE: needed for doc generator
@(require) import "core:sys/darwin/CoreFoundation"
@(require) import "core:sys/darwin/CoreGraphics"
@(require) import "core:sys/darwin/CoreText"
@(require) import "core:sys/darwin/DiskArbitration"
@(require) import "core:sys/darwin/FSEvents"
@(require) import "core:sys/darwin/Foundation"
@(require) import "core:sys/darwin/IOKit"
@(require) import "core:sys/darwin/ObjectiveC"
@(require) import "core:sys/darwin/Security"
@(require) import "vendor:darwin/AppKit"
@(require) import "vendor:darwin/AudioToolbox"
@(require) import "vendor:darwin/AVFoundation"
@(require) import "vendor:darwin/CloudKit"
@(require) import "vendor:darwin/CoreHaptics"
@(require) import "vendor:darwin/CoreLocation"
@(require) import "vendor:darwin/CoreMedia"
@(require) import "vendor:darwin/CoreVideo"
@(require) import "vendor:darwin/EventKit"
@(require) import "vendor:darwin/GameController"
@(require) import "vendor:darwin/GameKit"
@(require) import "vendor:darwin/LocalAuthentication"
@(require) import "vendor:darwin/MapKit"
@(require) import "vendor:darwin/Metal"
@(require) import "vendor:darwin/MetalFX"
@(require) import "vendor:darwin/MetalKit"
@(require) import "vendor:darwin/ModelIO"
@(require) import "vendor:darwin/QuartzCore"
@(require) import "vendor:darwin/UIKit"

@(require) import "vendor:directx/dxc"
@(require) import "vendor:directx/d3d11"
@(require) import "vendor:directx/d3d12"
@(require) import "vendor:directx/d3d_compiler"
@(require) import "vendor:directx/dxgi"

@(require) import "vendor:stb/easy_font"
@(require) import stbi "vendor:stb/image"
@(require) import "vendor:stb/rect_pack"
@(require) import "vendor:stb/truetype"
@(require) import "vendor:stb/vorbis"


@(require) import "vendor:kb_text_shape"
