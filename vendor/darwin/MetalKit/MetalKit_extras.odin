#+build darwin
package darwin_MetalKit

// Hand-written helper for driving an `MTKView` with Odin procedures, without `@(objc_implement)`.

import "base:intrinsics"
import CG   "core:sys/darwin/CoreGraphics"
import ObjC "core:sys/darwin/ObjectiveC"

OdinViewDelegate :: struct {
	drawInMTKView:          proc "c" (self: ^OdinViewDelegate, view: ^View),
	drawableSizeWillChange: proc "c" (self: ^OdinViewDelegate, view: ^View, size: CG.Size),

	user_data: rawptr,
}

// Makes `delegate` drive the view through an `MTKViewDelegate` object which the view keeps alive.
// `delegate` itself is not copied, so it must stay valid while it is set.
@(objc_type=View, objc_name="setOdinDelegate")
View_setOdinDelegate :: proc "c" (self: ^View, delegate: ^OdinViewDelegate) {
	obj: ^ViewDelegate
	if delegate != nil {
		obj = (^ViewDelegate)(ObjC.class_createInstance(odin_view_delegate_class(), size_of(^OdinViewDelegate)))
		(^^OdinViewDelegate)(ObjC.object_getIndexedIvars(obj))^ = delegate
	}
	// `MTKView.delegate` is a weak reference, the association owns the object
	ObjC.objc_setAssociatedObject(self, &odin_view_delegate_key, obj, .Retain)
	if obj != nil {
		obj->release()
	}
	self->setDelegate(obj)
}

// Returns the delegate set with `setOdinDelegate`, or nil if the view's delegate is something else.
@(objc_type=View, objc_name="odinDelegate")
View_odinDelegate :: proc "c" (self: ^View) -> ^OdinViewDelegate {
	obj := (ObjC.id)(self->delegate())
	if obj == nil || ObjC.object_getClass(obj) != odin_view_delegate_class() {
		return nil
	}
	return (^^OdinViewDelegate)(ObjC.object_getIndexedIvars(obj))^
}

@(private="file")
odin_view_delegate_key: u8

@(private="file")
odin_view_delegate_class :: proc "c" () -> ObjC.Class {
	draw :: proc "c" (self: ObjC.id, cmd: ObjC.SEL, view: ^View) {
		del := (^^OdinViewDelegate)(ObjC.object_getIndexedIvars(self))^
		if del.drawInMTKView != nil {
			del->drawInMTKView(view)
		}
	}
	size_will_change :: proc "c" (self: ObjC.id, cmd: ObjC.SEL, view: ^View, size: CG.Size) {
		del := (^^OdinViewDelegate)(ObjC.object_getIndexedIvars(self))^
		if del.drawableSizeWillChange != nil {
			del->drawableSizeWillChange(view, size)
		}
	}

	cls := ObjC.objc_lookUpClass("OdinMTKViewDelegate")
	if cls == nil {
		cls = ObjC.objc_allocateClassPair(intrinsics.objc_find_class("NSObject"), "OdinMTKViewDelegate", 0)
		ObjC.class_addMethod(cls, intrinsics.objc_find_selector("drawInMTKView:"), auto_cast draw, "v@:@")
		ObjC.class_addMethod(cls, intrinsics.objc_find_selector("mtkView:drawableSizeWillChange:"), auto_cast size_will_change, "v@:@{CGSize=dd}")
		if protocol := ObjC.objc_getProtocol("MTKViewDelegate"); protocol != nil {
			ObjC.class_addProtocol(cls, protocol)
		}
		ObjC.objc_registerClassPair(cls)
	}
	return cls
}
