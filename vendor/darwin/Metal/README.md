## About

**metal-odin** is a low overhead Odin interface for Metal that helps developers add Metal functionality to graphics applications that are written in Odin. **metal-odin** removes the need to create a shim and allows developers to call Metal functions directly from anywhere in their existing Odin code.

## Highlights

- Drop in Odin alternative interface to the Metal Objective-C headers.
- Direct mapping of all Metal Objective-C classes, constants, enums and bit_sets to Odin
- No measurable overhead compared to calling Metal Objective-C headers, due to inlining of Odin procedure calls.
- No usage of wrapper containers that require additional allocations.
- Identical header files and procedure/constant/enum availability for iOS, macOS and tvOS.
- Backwards compatibility: All `MTL.Device.supports...()` procedure check if their required selectors exist and automatically return `false` if not.
- String (`ErrorDomain`) constants are `@(linkage="weak")` and automatically set to `nil` if not available.

## Memory Allocation Policy

**metal-odin** follows the object allocation policies of Cocoa and Cocoa Touch. Understanding those rules is especially important when using `metal-odin`, as Odin values are not eligible for automatic reference counting (ARC).

**metal-odin** objects are reference counted. To help convey and manage object lifecycles, the following conventions are observed:

### AutoreleasePools and Objects

Several methods that create temporary objects in **metal-odin** add them to an `AutoreleasePool` to help manage their lifetimes. In these situations, after **metal-odin** creates the object, it adds it to an `AutoreleasePool`, which will release its objects when you release (or drain) it.

By adding temporary objects to an AutoreleasePool, you do not need to explicitly call `release()` to deallocate them. Instead, you can rely on the `AutoreleasePool` to implicitly manage those lifetimes.

If you create an object with a method that does not begin with `alloc`, or `copy`, the creating method adds the object to an autorelease pool.

The typical scope of an `AutoreleasePool` is one frame of rendering for the main thread of the program. When the thread returns control to the RunLoop (an object responsible for receiving input and events from the windowing system), the pool is *drained*, releasing its objects.

You can create and manage additional `AutoreleasePool`s at smaller scopes to reduce your program's working set, and you are required to do so for any additional threads your program creates.

If an object's lifecycle needs to be extended beyond the `AutoreleasePool`'s scope, you can claim ownership of it (avoiding its release beyond the pool's scope) by calling its `retain()` method before its pool is drained. In these cases, you will be responsible for making the appropriate `release()` call on the object after you no longer need it. 

You can find a more-detailed introduction to the memory management rules here: https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/MemoryMgmt/Articles/mmRules.html.

For more details about the application's RunLoop, please find its documentation here: https://developer.apple.com/documentation/foundation/nsrunloop

### Use and debug AutoreleasePools

When you create an autoreleased object and there is no enclosing `AutoreleasePool`, the object is leaked.

To prevent this, you normally create an `AutoreleasePool` in your program's `main` procedure, and in the entry procedure for every thread you create. You may also create additional `AutoreleasePool`s to avoid growing your program's high memory watermark when you create several autoreleased objects, such as when rendering.

Use the Environment Variable `OBJC_DEBUG_MISSING_POOLS=YES` to print a runtime warning when an autoreleased object is leaked because no enclosing `AutoreleasePool` is available for its thread.

You can also run `leaks --autoreleasePools` on a memgraph file or a process ID (macOS only) to view a listing of your program's `AutoreleasePool`s and all objects they contain.

### nil

Similar to Objective-C, it is legal to call any method, including `retain()` and `release()`, on `nil` "objects". While calling methods on `nil` still does incur in procedure call overhead, the effective result is equivalent of a NOP.

Conversely, do not assume that because calling a method on a pointer did not result in a crash, that the pointed-to object is valid.

## Adding `metal-odin` to a Project

Simply `import MTL "core:sys/darwin/Metal"`. To ensure that the selector and class symbols are linked.

```odin
import MTL "core:sys/darwin/Metal"
```

## Examples

#### Creating the device

###### Objective-C (with automatic reference counting)

```objc
id< MTLDevice > device = MTLCreateSystemDefaultDevice();

// ...
```

###### Objective-C

```objc
id< MTLDevice > device = MTLCreateSystemDefaultDevice();

// ...

[device release];
```

###### Odin

```odin
device := MTL.CreateSystemDefaultDevice()

// ...

device->release()
```

#### Metal function calls map directly to Odin

###### Objective-C (with automatic reference counting)

```objc
MTLSamplerDescriptor* samplerDescriptor = [[MTLSamplerDescriptor alloc] init];

[samplerDescriptor setSAddressMode: MTLSamplerAddressModeRepeat];
[samplerDescriptor setTAddressMode: MTLSamplerAddressModeRepeat];
[samplerDescriptor setRAddressMode: MTLSamplerAddressModeRepeat];
[samplerDescriptor setMagFilter: MTLSamplerMinMagFilterLinear];
[samplerDescriptor setMinFilter: MTLSamplerMinMagFilterLinear];
[samplerDescriptor setMipFilter: MTLSamplerMipFilterLinear];
[samplerDescriptor setSupportArgumentBuffers: YES];

id< MTLSamplerState > samplerState = [device newSamplerStateWithDescriptor:samplerDescriptor];
```

###### Objective-C

```objc
MTLSamplerDescriptor* samplerDescriptor = [[MTLSamplerDescriptor alloc] init];

[samplerDescriptor setSAddressMode: MTLSamplerAddressModeRepeat];
[samplerDescriptor setTAddressMode: MTLSamplerAddressModeRepeat];
[samplerDescriptor setRAddressMode: MTLSamplerAddressModeRepeat];
[samplerDescriptor setMagFilter: MTLSamplerMinMagFilterLinear];
[samplerDescriptor setMinFilter: MTLSamplerMinMagFilterLinear];
[samplerDescriptor setMipFilter: MTLSamplerMipFilterLinear];
[samplerDescriptor setSupportArgumentBuffers: YES];

id< MTLSamplerState > samplerState = [device newSamplerStateWithDescriptor:samplerDescriptor];

[samplerDescriptor release];

// ...

[samplerState release];
```

###### Odin

```odin
samplerDescriptor := MTL.SamplerDescriptor.alloc()->init()

samplerDescriptor->setSAddressMode(.Repeat)
samplerDescriptor->setTAddressMode(.Repeat)
samplerDescriptor->setRAddressMode(.Repeat)
samplerDescriptor->setMagFilter(.Linear)
samplerDescriptor->setMinFilter(.Linear)
samplerDescriptor->setMipFilter(.Linear)
samplerDescriptor->setSupportArgumentBuffers(true)

samplerState := device->newSamplerState(samplerDescriptor)

samplerDescriptor->release()

// ...

samplerState->release()
```
