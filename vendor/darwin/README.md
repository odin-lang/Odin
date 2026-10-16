# Apple platform bindings

Bindings to Apple's Objective-C and C frameworks for macOS and iOS, generated from the SDK headers
(see [`_gen/README.md`](_gen/README.md) for how they are produced and regenerated).

Each framework is a single package for both platforms: declarations which only exist on one
platform are behind `#+build darwin:default` (macOS) or `#+build darwin:ios` (iOS and the
simulator), so a framework which does not exist on a platform, such as AppKit on iOS, is an empty
package there.

## Packages

| Collection        | Packages |
|-------------------|----------|
| `core:sys/darwin` | `ObjectiveC`, `CoreFoundation`, `CoreGraphics`, `CoreText`, `DiskArbitration`, `FSEvents`, `Foundation`, `IOKit`, `Security` |
| `vendor:darwin`   | `AppKit`, `AudioToolbox`, `AVFoundation`, `CloudKit`, `CoreHaptics`, `CoreLocation`, `CoreMedia`, `CoreVideo`, `EventKit`, `GameController`, `GameKit`, `LocalAuthentication`, `MapKit`, `Metal`, `MetalFX`, `MetalKit`, `ModelIO`, `QuartzCore`, `UIKit` |

The conventional import names follow the Apple prefixes:

```odin
import ObjC "core:sys/darwin/ObjectiveC"
import NS   "core:sys/darwin/Foundation"
import CF   "core:sys/darwin/CoreFoundation"
import CG   "core:sys/darwin/CoreGraphics"
import UI   "vendor:darwin/UIKit"
import CA   "vendor:darwin/QuartzCore"
import MTL  "vendor:darwin/Metal"
import MTK  "vendor:darwin/MetalKit"
```

Foundation and AppKit share the `NS` prefix, and AppKit re-exports all of Foundation, as
`#import <AppKit/AppKit.h>` does in Objective-C. Code using AppKit (macOS only) therefore imports it
as `NS` instead of Foundation, and gets both `NS.Window` and `NS.String`:

```odin
import NS "vendor:darwin/AppKit"
```

The re-exported declarations are aliases, so values pass freely between code which imports
Foundation and code which imports AppKit.

## Using the bindings

Objective-C methods are called with `->`, and class methods on the type itself. `alloc` and `init`
methods return the type they are called on.

```odin
desc := MTL.SamplerDescriptor.alloc()->init()
desc->setMinFilter(.Linear)
desc->setMagFilter(.Linear)
sampler := device->newSamplerStateWithDescriptor(desc)
desc->release()
```

- **Names** follow the selector. When several selectors share a name, each method is named after
  its whole selector (`newBufferWithLength_options`) and an overload group takes the shared name
  (`device->newBufferWithLength(length, options)`).
- **Errors.** Methods whose last parameter is an `NSError**` out-parameter return the error
  instead: `library, err := device->newLibraryWithSource(source, options)`, or
  `ok, err := bundle->loadAndReturnError()`. The original method is kept with an `_error` suffix,
  e.g. `device->newLibraryWithSource_options_error(source, options, &err)`.
- **Options** (`NS_OPTIONS`) are `bit_set`s, e.g. `desc->setUsage({.ShaderRead, .RenderTarget})`.
  Members which are 0 or a combination of flags are constants named `<type>_<member>`, e.g.
  `MTL.TextureUsage_Unknown` (`{}`) or `MTL.Stages_All`. So are the values of multi-bit fields within
  options, e.g. `UI.ViewAnimationOptions{.Repeat} | UI.ViewAnimationOptions_CurveEaseIn`; such a field
  is read back through its mask, as in `opts & NS.DataWritingOptions_FileProtectionMask`, and replaced
  with `opts &~ Mask | Value`.
- **Strings.** `NS.AT("literal")` makes a constant `NSString`, `NS.String.alloc()->initWithOdinString(str)`
  wraps an Odin string without copying it, and `ns_str->odinString()` returns a string which refers
  to the `NSString`'s storage.
- **Slices.** Metal methods which take a pointer and a count also accept slices, e.g.
  `encoder->setViewports(viewports[:])` or `encoder->setVertexBytes(mem.ptr_to_bytes(&uniforms), 1)`,
  and `buffer->contentsAsSlice([]Vertex)` views a buffer's contents.
- Odin-specific helpers live in the `*_extras.odin` files of each package.

```odin
window := NS.Window.alloc()->initWithContentRect(NS.Rect{{0, 0}, {640, 480}}, {.Titled, .Closable, .Resizable}, .Buffered, false)
window->setTitle(NS.AT("Hellope"))

layer := CA.MetalLayer.layer()
layer->setDevice(device)
layer->setPixelFormat(.BGRA8Unorm)
window->contentView()->setLayer(layer)
window->contentView()->setWantsLayer(true)
```

## Memory management

Objective-C objects are reference counted, and Odin code does not get automatic reference counting
(ARC), so the Cocoa rules apply:

- You own an object you get from a method whose name begins with `alloc`, `new`, `copy` or
  `mutableCopy`, and must `release()` it when you are done with it.
- Any other method returns an *autoreleased* object, which is released when the enclosing
  autorelease pool is drained. Call `retain()` on it to keep it for longer, and `release()` it later.
- Sending a message to `nil` is allowed and does nothing, returning a zero value. Do not take a
  call that did not crash as proof that an object is still valid.

An autoreleased object which is created while there is no autorelease pool is leaked. Create a pool
in `main`, in the entry procedure of every thread you create, and around work which creates many
temporary objects, such as each rendered frame:

```odin
for running {
	NS.scoped_autoreleasepool() // drained at the end of the scope
	render_frame()
}
```

The environment variable `OBJC_DEBUG_MISSING_POOLS=YES` reports objects leaked without a pool, and
`leaks --autoreleasePools` lists the pools of a process and their objects (macOS only).
See Apple's [memory management rules](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/MemoryMgmt/Articles/mmRules.html).

## Implementing Objective-C classes

Classes, delegates and protocols can be implemented in Odin with the `@(objc_implement)` attribute
on the type and its methods; call the superclass with `intrinsics.objc_super(self)->init()`.
For common cases there are helpers which do not need it:

- `NS.application_delegate_register_and_alloc` and `NS.window_delegate_register_and_alloc` (AppKit) create
  an application or window delegate from a struct of Odin procedures.
- `view->setOdinDelegate(&delegate)` drives an `MTK.View` with an `MTK.OdinViewDelegate`.
- `ObjC.register_subclass` registers a subclass whose methods are added by an Odin procedure.

## Migrating from the previous bindings

These packages replace the hand-written `core:sys/darwin/Foundation`, `CoreFoundation`,
`CoreGraphics` and `Security`, and `vendor:darwin/Metal`, `MetalKit` and `QuartzCore`, under the
same import paths. The main differences:

- **AppKit** classes (`Window`, `View`, `Application`, `Event`, `Menu`, `Screen`, `Color`, `Cursor`,
  `OpenPanel`, …) moved from `core:sys/darwin/Foundation` to `vendor:darwin/AppKit`. Code using
  them keeps writing `NS.Window` by importing AppKit as `NS` instead of Foundation:
  `import NS "vendor:darwin/AppKit"`.
- **Objective-C runtime** procedures (`objc_lookUpClass`, `class_addMethod`, `class_getName`,
  `sel_registerName`, …) and `register_subclass` and its helpers moved to `core:sys/darwin/ObjectiveC`.
- **Method names** follow the selectors, so some hand-picked names changed:

  | Previously | Now |
  |---|---|
  | `device->newSamplerState(desc)` | `device->newSamplerStateWithDescriptor(desc)` |
  | `device->newTexture(desc)` | `device->newTextureWithDescriptor(desc)` |
  | `device->newDepthStencilState(desc)` | `device->newDepthStencilStateWithDescriptor(desc)` |
  | `function->newArgumentEncoder(index)` | `function->newArgumentEncoderWithBufferIndex(index)` |
  | `encoder->setArgumentBufferWithOffset(buffer, offset)` | `encoder->setArgumentBuffer(buffer, offset)` |
  | `encoder->drawIndexedPrimitivesWithInstanceCount(…)` | `encoder->drawIndexedPrimitives(…)` |
  | `CA.MetalLayer_layer()` | `CA.MetalLayer.layer()` |
- **Errors** are returned as `(res, err)` by every method with an `NSError**` out-parameter.
- **Options.** Every `NS_OPTIONS` type is a `bit_set`, named after the C type, over an element enum
  named in the singular or with `Flag`: e.g. Metal's `PipelineOptions :: bit_set[PipelineOption]`
  where the old bindings had `PipelineOption :: bit_set[PipelineOptionFlag]`. Constants such as
  `NS.WindowStyleMaskTitled` or `MTL.ResourceStorageModeShared` are gone; write `{.Titled}` or `{}`.
  Enum members follow the SDK names, e.g. `.CaseInsensitiveSearch`, and enums use the C integer
  types (`c.ulong`) rather than `NS.UInteger`.
- **Strings.** `NS.StringEncoding` is a plain integer type with constants such as
  `NS.UTF8StringEncoding`, rather than an enum with `.UTF8`.
- **Numbers.** `NS.Number.number(x)` and the typed helpers (`numberWithI32`, `i8Value`, …) remain;
  those for `int` and `uint` are now `numberWithOdinInt`, `initWithOdinInt`, `odinIntValue` and
  `odinUintValue`, as `numberWithInt` and `intValue` now mean the C `int` versions.
  `uintegerValue` is `unsignedIntegerValue`, and `Integermin` is `IntegerMin`.
- **Metal.** `buffer->contents()` returns a `rawptr`, which `contentsPointer()` used to; use `contentsAsSlice`
  or `contentsAsType` for typed access. `device->newBuffer(length, options)` is `newBufferWithLength`.
  `CA.MetalLayer` now takes `MTL.Device` and `MTL.PixelFormat` directly.
- **MetalKit.** `view->setDelegate` takes an `MTKViewDelegate` object; the struct of Odin procedures
  is now `MTK.OdinViewDelegate`, set with `view->setOdinDelegate`.
- **Delegate templates** return the `NS.ApplicationDelegate` and `NS.WindowDelegate` protocol types,
  which `setDelegate` takes directly.
- **Subclassing.** `super_msg_send` does not exist; use `intrinsics.objc_super(self)->method()`,
  which resolves the superclass statically.
- **Platforms.** AppKit only exists on macOS, so `glfw.GetCocoaWindow` and the darwin parts of
  `vendor:wgpu/glfwglue` and `vendor:wgpu/sdl2glue` are macOS only.
