#+build darwin:default
package test_internal

import "base:intrinsics"
import "core:testing"

foreign import objc_method_import_appkit "system:AppKit.framework"

@(objc_class="NSColor")
Objc_Link_Color :: struct {using _: intrinsics.objc_object}

foreign objc_method_import_appkit {
	@(objc_type=Objc_Link_Color, objc_selector="whiteColor", objc_is_class_method=true)
	Objc_Link_Color_whiteColor :: proc() -> ^Objc_Link_Color ---
}

// Calling an imported method must link its framework without @(require).
@(test)
objc_method_import_links :: proc(t: ^testing.T) {
	testing.expect(t, Objc_Link_Color.whiteColor() != nil)
}
