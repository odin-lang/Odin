package objc_Foundation

import "base:builtin"
import "base:intrinsics"

KeyEquivalentModifierFlag :: enum UInteger {
	CapsLock   = 16, // Set if Caps Lock key is pressed.
	Shift      = 17, // Set if Shift key is pressed.
	Control    = 18, // Set if Control key is pressed.
	Option     = 19, // Set if Option or Alternate key is pressed.
	Command    = 20, // Set if Command key is pressed.
	NumericPad = 21, // Set if any key in the numeric keypad is pressed.
	Help       = 22, // Set if the Help key is pressed.
	Function   = 23, // Set if any function key is pressed.
}
KeyEquivalentModifierMask :: distinct bit_set[KeyEquivalentModifierFlag; UInteger]

// Used to retrieve only the device-independent modifier flags, allowing applications to mask off the device-dependent modifier flags, including event coalescing information.
KeyEventModifierFlagDeviceIndependentFlagsMask := transmute(KeyEquivalentModifierMask)_KeyEventModifierFlagDeviceIndependentFlagsMask
@(private) _KeyEventModifierFlagDeviceIndependentFlagsMask := UInteger(0xffff0000)


MenuItemCallback :: proc "c" (unused: rawptr, name: SEL, sender: ^Object)


@(objc_class="NSMenuItem")
MenuItem :: struct {using _: Object}

@(objc_type=MenuItem, objc_name="alloc", objc_is_class_method=true)
MenuItem_alloc :: proc "c" () -> ^MenuItem {
	return msgSend(^MenuItem, MenuItem, "alloc")
}

@(objc_type=MenuItem, objc_name="registerActionCallback", objc_is_class_method=true)
MenuItem_registerActionCallback :: proc "c" (name: cstring, callback: MenuItemCallback) -> SEL {
	s := string(name)
	n := len(s)
	sel: SEL
	if n > 0 && s[n-1] != ':' {
		col_name := intrinsics.alloca(n+2, 1)
		builtin.copy(col_name[:n], s)
		col_name[n] = ':'
		col_name[n+1] = 0
		sel = sel_registerName(cstring(col_name))
	} else {
		sel = sel_registerName(name)
	}
	if callback != nil {
		class_addMethod(intrinsics.objc_find_class("NSObject"), sel, auto_cast callback, "v@:@")
	}
	return sel
}

@(objc_type=MenuItem, objc_name="separatorItem", objc_is_class_method=true)
MenuItem_separatorItem :: proc "c" () -> ^MenuItem {
	return msgSend(^MenuItem, MenuItem, "separatorItem")
}

@(objc_type=MenuItem, objc_name="init")
MenuItem_init :: proc "c" (self: ^MenuItem) -> ^MenuItem {
	return msgSend(^MenuItem, self, "init")
}

@(objc_type=MenuItem, objc_name="initWithTitle")
MenuItem_initWithTitle :: proc "c" (self: ^MenuItem, title: ^String, action: SEL, keyEquivalent: ^String) -> ^MenuItem {
	return msgSend(^MenuItem, self, "initWithTitle:action:keyEquivalent:", title, action, keyEquivalent)
}

@(objc_type=MenuItem, objc_name="setKeyEquivalentModifierMask")
MenuItem_setKeyEquivalentModifierMask :: proc "c" (self: ^MenuItem, modifierMask: KeyEquivalentModifierMask) {
	msgSend(nil, self, "setKeyEquivalentModifierMask:", modifierMask)
}

@(objc_type=MenuItem, objc_name="keyEquivalentModifierMask")
MenuItem_keyEquivalentModifierMask :: proc "c" (self: ^MenuItem) -> KeyEquivalentModifierMask {
	return msgSend(KeyEquivalentModifierMask, self, "keyEquivalentModifierMask")
}

@(objc_type=MenuItem, objc_name="setSubmenu")
MenuItem_setSubmenu :: proc "c" (self: ^MenuItem, submenu: ^Menu) {
	msgSend(nil, self, "setSubmenu:", submenu)
}

@(objc_type=MenuItem, objc_name="title")
MenuItem_title :: proc "c" (self: ^MenuItem) -> ^String {
	return msgSend(^String, self, "title")
}

@(objc_type=MenuItem, objc_name="setTitle")
MenuItem_setTitle :: proc "c" (self: ^MenuItem, title: ^String) -> ^String {
	return msgSend(^String, self, "title:", title)
}



@(objc_class="NSMenu")
Menu :: struct {using _: Object}

@(objc_type=Menu, objc_name="alloc", objc_is_class_method=true)
Menu_alloc :: proc "c" () -> ^Menu {
	return msgSend(^Menu, Menu, "alloc")
}

@(objc_type=Menu, objc_name="init")
Menu_init :: proc "c" (self: ^Menu) -> ^Menu {
	return msgSend(^Menu, self, "init")
}

@(objc_type=Menu, objc_name="initWithTitle")
Menu_initWithTitle :: proc "c" (self: ^Menu, title: ^String) -> ^Menu {
	return msgSend(^Menu, self, "initWithTitle:", title)
}


@(objc_type=Menu, objc_name="addItem")
Menu_addItem :: proc "c" (self: ^Menu, item: ^MenuItem) {
	msgSend(nil, self, "addItem:", item)
}

@(objc_type=Menu, objc_name="addItemWithTitle")
Menu_addItemWithTitle :: proc "c" (self: ^Menu, title: ^String, selector: SEL, keyEquivalent: ^String) -> ^MenuItem {
	return msgSend(^MenuItem, self, "addItemWithTitle:action:keyEquivalent:", title, selector, keyEquivalent)
}

@(objc_type=Menu, objc_name="itemArray")
Menu_itemArray :: proc "c" (self: ^Menu) -> ^Array {
	return msgSend(^Array, self, "itemArray")
}