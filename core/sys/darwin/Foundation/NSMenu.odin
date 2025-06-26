package objc_Foundation

import "base:builtin"
import "base:intrinsics"
import "core:c"


MenuSelectionMode :: enum c.long {
	Automatic = 0,
	SelectOne = 1,
	SelectAny = 2,
}

MenuPresentationStyle :: enum c.long {
	Regular = 0,
	Palette = 1,
}

UserInterfaceLayoutDirection :: enum c.long {
	LeftToRight = 0,
	RightToLeft = 1,
}

MenuPropertyItem :: enum c.ulong {
	Title                    = 0,
	AttributedTitle          = 1,
	KeyEquivalent            = 2,
	Image                    = 3,
	Enabled                  = 4,
	AccessibilityDescription = 5,
}
MenuProperties :: distinct bit_set[MenuPropertyItem; c.ulong]


@(objc_class="NSMenu")
Menu :: struct {using _: Object}

@(objc_type=Menu, objc_name="init")
Menu_init :: proc "c" (self: ^Menu) -> ^Menu {
	return msgSend(^Menu, self, "init")
}


@(objc_type=Menu, objc_name="initWithTitle")
Menu_initWithTitle :: #force_inline proc "c" (self: ^Menu, title: ^String) -> ^Menu {
	return msgSend(^Menu, self, "initWithTitle:", title)
}
@(objc_type=Menu, objc_name="initWithCoder")
Menu_initWithCoder :: #force_inline proc "c" (self: ^Menu, coder: ^Coder) -> ^Menu {
	return msgSend(^Menu, self, "initWithCoder:", coder)
}
@(objc_type=Menu, objc_name="popUpContextMenu_withEvent_forView", objc_is_class_method=true)
Menu_popUpContextMenu_withEvent_forView :: #force_inline proc "c" (menu: ^Menu, event: ^Event, view: ^View) {
	msgSend(nil, Menu, "popUpContextMenu:withEvent:forView:", menu, event, view)
}
// @(objc_type=Menu, objc_name="popUpContextMenu_withEvent_forView_withFont", objc_is_class_method=true)
// Menu_popUpContextMenu_withEvent_forView_withFont :: #force_inline proc "c" (menu: ^Menu, event: ^Event, view: ^View, font: ^Font) {
// 	msgSend(nil, Menu, "popUpContextMenu:withEvent:forView:withFont:", menu, event, view, font)
// }
@(objc_type=Menu, objc_name="popUpMenuPositioningItem")
Menu_popUpMenuPositioningItem :: #force_inline proc "c" (self: ^Menu, item: ^MenuItem, location: Point, view: ^View) -> bool {
	return msgSend(bool, self, "popUpMenuPositioningItem:atLocation:inView:", item, location, view)
}
@(objc_type=Menu, objc_name="setMenuBarVisible", objc_is_class_method=true)
Menu_setMenuBarVisible :: #force_inline proc "c" (visible: bool) {
	msgSend(nil, Menu, "setMenuBarVisible:", visible)
}
@(objc_type=Menu, objc_name="menuBarVisible", objc_is_class_method=true)
Menu_menuBarVisible :: #force_inline proc "c" () -> bool {
	return msgSend(bool, Menu, "menuBarVisible")
}
@(objc_type=Menu, objc_name="insertItem")
Menu_insertItem :: #force_inline proc "c" (self: ^Menu, newItem: ^MenuItem, index: Integer) {
	msgSend(nil, self, "insertItem:atIndex:", newItem, index)
}
@(objc_type=Menu, objc_name="addItem")
Menu_addItem :: #force_inline proc "c" (self: ^Menu, newItem: ^MenuItem) {
	msgSend(nil, self, "addItem:", newItem)
}
@(objc_type=Menu, objc_name="insertItemWithTitle")
Menu_insertItemWithTitle :: #force_inline proc "c" (self: ^Menu, string: ^String, selector: SEL, charCode: ^String, index: Integer) -> ^MenuItem {
	return msgSend(^MenuItem, self, "insertItemWithTitle:action:keyEquivalent:atIndex:", string, selector, charCode, index)
}
@(objc_type=Menu, objc_name="addItemWithTitle")
Menu_addItemWithTitle :: #force_inline proc "c" (self: ^Menu, string: ^String, selector: SEL, charCode: ^String) -> ^MenuItem {
	return msgSend(^MenuItem, self, "addItemWithTitle:action:keyEquivalent:", string, selector, charCode)
}
@(objc_type=Menu, objc_name="removeItemAtIndex")
Menu_removeItemAtIndex :: #force_inline proc "c" (self: ^Menu, index: Integer) {
	msgSend(nil, self, "removeItemAtIndex:", index)
}
@(objc_type=Menu, objc_name="removeItem")
Menu_removeItem :: #force_inline proc "c" (self: ^Menu, item: ^MenuItem) {
	msgSend(nil, self, "removeItem:", item)
}
@(objc_type=Menu, objc_name="setSubmenu")
Menu_setSubmenu :: #force_inline proc "c" (self: ^Menu, menu: ^Menu, item: ^MenuItem) {
	msgSend(nil, self, "setSubmenu:forItem:", menu, item)
}
@(objc_type=Menu, objc_name="removeAllItems")
Menu_removeAllItems :: #force_inline proc "c" (self: ^Menu) {
	msgSend(nil, self, "removeAllItems")
}
@(objc_type=Menu, objc_name="itemAtIndex")
Menu_itemAtIndex :: #force_inline proc "c" (self: ^Menu, index: Integer) -> ^MenuItem {
	return msgSend(^MenuItem, self, "itemAtIndex:", index)
}
@(objc_type=Menu, objc_name="indexOfItem")
Menu_indexOfItem :: #force_inline proc "c" (self: ^Menu, item: ^MenuItem) -> Integer {
	return msgSend(Integer, self, "indexOfItem:", item)
}
@(objc_type=Menu, objc_name="indexOfItemWithTitle")
Menu_indexOfItemWithTitle :: #force_inline proc "c" (self: ^Menu, title: ^String) -> Integer {
	return msgSend(Integer, self, "indexOfItemWithTitle:", title)
}
@(objc_type=Menu, objc_name="indexOfItemWithTag")
Menu_indexOfItemWithTag :: #force_inline proc "c" (self: ^Menu, tag: Integer) -> Integer {
	return msgSend(Integer, self, "indexOfItemWithTag:", tag)
}
@(objc_type=Menu, objc_name="indexOfItemWithRepresentedObject")
Menu_indexOfItemWithRepresentedObject :: #force_inline proc "c" (self: ^Menu, object: id) -> Integer {
	return msgSend(Integer, self, "indexOfItemWithRepresentedObject:", object)
}
@(objc_type=Menu, objc_name="indexOfItemWithSubmenu")
Menu_indexOfItemWithSubmenu :: #force_inline proc "c" (self: ^Menu, submenu: ^Menu) -> Integer {
	return msgSend(Integer, self, "indexOfItemWithSubmenu:", submenu)
}
@(objc_type=Menu, objc_name="indexOfItemWithTarget")
Menu_indexOfItemWithTarget :: #force_inline proc "c" (self: ^Menu, target: id, actionSelector: SEL) -> Integer {
	return msgSend(Integer, self, "indexOfItemWithTarget:andAction:", target, actionSelector)
}
@(objc_type=Menu, objc_name="itemWithTitle")
Menu_itemWithTitle :: #force_inline proc "c" (self: ^Menu, title: ^String) -> ^MenuItem {
	return msgSend(^MenuItem, self, "itemWithTitle:", title)
}
@(objc_type=Menu, objc_name="itemWithTag")
Menu_itemWithTag :: #force_inline proc "c" (self: ^Menu, tag: Integer) -> ^MenuItem {
	return msgSend(^MenuItem, self, "itemWithTag:", tag)
}
@(objc_type=Menu, objc_name="update")
Menu_update :: #force_inline proc "c" (self: ^Menu) {
	msgSend(nil, self, "update")
}
@(objc_type=Menu, objc_name="performKeyEquivalent")
Menu_performKeyEquivalent :: #force_inline proc "c" (self: ^Menu, event: ^Event) -> bool {
	return msgSend(bool, self, "performKeyEquivalent:", event)
}
@(objc_type=Menu, objc_name="itemChanged")
Menu_itemChanged :: #force_inline proc "c" (self: ^Menu, item: ^MenuItem) {
	msgSend(nil, self, "itemChanged:", item)
}
@(objc_type=Menu, objc_name="performActionForItemAtIndex")
Menu_performActionForItemAtIndex :: #force_inline proc "c" (self: ^Menu, index: Integer) {
	msgSend(nil, self, "performActionForItemAtIndex:", index)
}
@(objc_type=Menu, objc_name="cancelTracking")
Menu_cancelTracking :: #force_inline proc "c" (self: ^Menu) {
	msgSend(nil, self, "cancelTracking")
}
@(objc_type=Menu, objc_name="cancelTrackingWithoutAnimation")
Menu_cancelTrackingWithoutAnimation :: #force_inline proc "c" (self: ^Menu) {
	msgSend(nil, self, "cancelTrackingWithoutAnimation")
}
@(objc_type=Menu, objc_name="title")
Menu_title :: #force_inline proc "c" (self: ^Menu) -> ^String {
	return msgSend(^String, self, "title")
}
@(objc_type=Menu, objc_name="setTitle")
Menu_setTitle :: #force_inline proc "c" (self: ^Menu, title: ^String) {
	msgSend(nil, self, "setTitle:", title)
}
@(objc_type=Menu, objc_name="supermenu")
Menu_supermenu :: #force_inline proc "c" (self: ^Menu) -> ^Menu {
	return msgSend(^Menu, self, "supermenu")
}
@(objc_type=Menu, objc_name="setSupermenu")
Menu_setSupermenu :: #force_inline proc "c" (self: ^Menu, supermenu: ^Menu) {
	msgSend(nil, self, "setSupermenu:", supermenu)
}
@(objc_type=Menu, objc_name="itemArray")
Menu_itemArray :: #force_inline proc "c" (self: ^Menu) -> ^Array {
	return msgSend(^Array, self, "itemArray")
}
@(objc_type=Menu, objc_name="setItemArray")
Menu_setItemArray :: #force_inline proc "c" (self: ^Menu, itemArray: ^Array) {
	msgSend(nil, self, "setItemArray:", itemArray)
}
@(objc_type=Menu, objc_name="numberOfItems")
Menu_numberOfItems :: #force_inline proc "c" (self: ^Menu) -> Integer {
	return msgSend(Integer, self, "numberOfItems")
}
@(objc_type=Menu, objc_name="autoenablesItems")
Menu_autoenablesItems :: #force_inline proc "c" (self: ^Menu) -> bool {
	return msgSend(bool, self, "autoenablesItems")
}
@(objc_type=Menu, objc_name="setAutoenablesItems")
Menu_setAutoenablesItems :: #force_inline proc "c" (self: ^Menu, autoenablesItems: bool) {
	msgSend(nil, self, "setAutoenablesItems:", autoenablesItems)
}
@(objc_type=Menu, objc_name="delegate")
Menu_delegate :: #force_inline proc "c" (self: ^Menu) -> ^MenuDelegate {
	return msgSend(^MenuDelegate, self, "delegate")
}
@(objc_type=Menu, objc_name="setDelegate")
Menu_setDelegate :: #force_inline proc "c" (self: ^Menu, delegate: ^MenuDelegate) {
	msgSend(nil, self, "setDelegate:", delegate)
}
@(objc_type=Menu, objc_name="menuBarHeight")
Menu_menuBarHeight :: #force_inline proc "c" (self: ^Menu) -> Float {
	return msgSend(Float, self, "menuBarHeight")
}
@(objc_type=Menu, objc_name="highlightedItem")
Menu_highlightedItem :: #force_inline proc "c" (self: ^Menu) -> ^MenuItem {
	return msgSend(^MenuItem, self, "highlightedItem")
}
@(objc_type=Menu, objc_name="minimumWidth")
Menu_minimumWidth :: #force_inline proc "c" (self: ^Menu) -> Float {
	return msgSend(Float, self, "minimumWidth")
}
@(objc_type=Menu, objc_name="setMinimumWidth")
Menu_setMinimumWidth :: #force_inline proc "c" (self: ^Menu, minimumWidth: Float) {
	msgSend(nil, self, "setMinimumWidth:", minimumWidth)
}
@(objc_type=Menu, objc_name="size")
Menu_size :: #force_inline proc "c" (self: ^Menu) -> Size {
	return msgSend(Size, self, "size")
}
// @(objc_type=Menu, objc_name="font")
// Menu_font :: #force_inline proc "c" (self: ^Menu) -> ^Font {
// 	return msgSend(^Font, self, "font")
// }
// @(objc_type=Menu, objc_name="setFont")
// Menu_setFont :: #force_inline proc "c" (self: ^Menu, font: ^Font) {
// 	msgSend(nil, self, "setFont:", font)
// }
@(objc_type=Menu, objc_name="allowsContextMenuPlugIns")
Menu_allowsContextMenuPlugIns :: #force_inline proc "c" (self: ^Menu) -> bool {
	return msgSend(bool, self, "allowsContextMenuPlugIns")
}
@(objc_type=Menu, objc_name="setAllowsContextMenuPlugIns")
Menu_setAllowsContextMenuPlugIns :: #force_inline proc "c" (self: ^Menu, allowsContextMenuPlugIns: bool) {
	msgSend(nil, self, "setAllowsContextMenuPlugIns:", allowsContextMenuPlugIns)
}
@(objc_type=Menu, objc_name="showsStateColumn")
Menu_showsStateColumn :: #force_inline proc "c" (self: ^Menu) -> bool {
	return msgSend(bool, self, "showsStateColumn")
}
@(objc_type=Menu, objc_name="setShowsStateColumn")
Menu_setShowsStateColumn :: #force_inline proc "c" (self: ^Menu, showsStateColumn: bool) {
	msgSend(nil, self, "setShowsStateColumn:", showsStateColumn)
}
@(objc_type=Menu, objc_name="userInterfaceLayoutDirection")
Menu_userInterfaceLayoutDirection :: #force_inline proc "c" (self: ^Menu) -> UserInterfaceLayoutDirection {
	return msgSend(UserInterfaceLayoutDirection, self, "userInterfaceLayoutDirection")
}
@(objc_type=Menu, objc_name="setUserInterfaceLayoutDirection")
Menu_setUserInterfaceLayoutDirection :: #force_inline proc "c" (self: ^Menu, userInterfaceLayoutDirection: UserInterfaceLayoutDirection) {
	msgSend(nil, self, "setUserInterfaceLayoutDirection:", userInterfaceLayoutDirection)
}
@(objc_type=Menu, objc_name="paletteMenuWithColors_titles_selectionHandler", objc_is_class_method=true)
Menu_paletteMenuWithColors_titles_selectionHandler :: #force_inline proc "c" (colors: ^Array, itemTitles: ^Array, onSelectionChange: proc "c" (_arg_0: ^Menu)) -> ^Menu {
	return msgSend(^Menu, Menu, "paletteMenuWithColors:titles:selectionHandler:", colors, itemTitles, onSelectionChange)
}
// @(objc_type=Menu, objc_name="paletteMenuWithColors_titles_templateImage_selectionHandler", objc_is_class_method=true)
// Menu_paletteMenuWithColors_titles_templateImage_selectionHandler :: #force_inline proc "c" (colors: ^Array, itemTitles: ^Array, image: ^Image, onSelectionChange: proc "c" (_arg_0: ^Menu)) -> ^Menu {
// 	return msgSend(^Menu, Menu, "paletteMenuWithColors:titles:templateImage:selectionHandler:", colors, itemTitles, image, onSelectionChange)
// }
@(objc_type=Menu, objc_name="presentationStyle")
Menu_presentationStyle :: #force_inline proc "c" (self: ^Menu) -> MenuPresentationStyle {
	return msgSend(MenuPresentationStyle, self, "presentationStyle")
}
@(objc_type=Menu, objc_name="setPresentationStyle")
Menu_setPresentationStyle :: #force_inline proc "c" (self: ^Menu, presentationStyle: MenuPresentationStyle) {
	msgSend(nil, self, "setPresentationStyle:", presentationStyle)
}
@(objc_type=Menu, objc_name="selectionMode")
Menu_selectionMode :: #force_inline proc "c" (self: ^Menu) -> MenuSelectionMode {
	return msgSend(MenuSelectionMode, self, "selectionMode")
}
@(objc_type=Menu, objc_name="setSelectionMode")
Menu_setSelectionMode :: #force_inline proc "c" (self: ^Menu, selectionMode: MenuSelectionMode) {
	msgSend(nil, self, "setSelectionMode:", selectionMode)
}
@(objc_type=Menu, objc_name="selectedItems")
Menu_selectedItems :: #force_inline proc "c" (self: ^Menu) -> ^Array {
	return msgSend(^Array, self, "selectedItems")
}
@(objc_type=Menu, objc_name="setSelectedItems")
Menu_setSelectedItems :: #force_inline proc "c" (self: ^Menu, selectedItems: ^Array) {
	msgSend(nil, self, "setSelectedItems:", selectedItems)
}
@(objc_type=Menu, objc_name="submenuAction")
Menu_submenuAction :: #force_inline proc "c" (self: ^Menu, sender: id) {
	msgSend(nil, self, "submenuAction:", sender)
}
@(objc_type=Menu, objc_name="propertiesToUpdate")
Menu_propertiesToUpdate :: #force_inline proc "c" (self: ^Menu) -> MenuProperties {
	return msgSend(MenuProperties, self, "propertiesToUpdate")
}
@(objc_type=Menu, objc_name="setMenuRepresentation")
Menu_setMenuRepresentation :: #force_inline proc "c" (self: ^Menu, menuRep: id) {
	msgSend(nil, self, "setMenuRepresentation:", menuRep)
}
@(objc_type=Menu, objc_name="menuRepresentation")
Menu_menuRepresentation :: #force_inline proc "c" (self: ^Menu) -> id {
	return msgSend(id, self, "menuRepresentation")
}
@(objc_type=Menu, objc_name="setContextMenuRepresentation")
Menu_setContextMenuRepresentation :: #force_inline proc "c" (self: ^Menu, menuRep: id) {
	msgSend(nil, self, "setContextMenuRepresentation:", menuRep)
}
@(objc_type=Menu, objc_name="contextMenuRepresentation")
Menu_contextMenuRepresentation :: #force_inline proc "c" (self: ^Menu) -> id {
	return msgSend(id, self, "contextMenuRepresentation")
}
@(objc_type=Menu, objc_name="setTearOffMenuRepresentation")
Menu_setTearOffMenuRepresentation :: #force_inline proc "c" (self: ^Menu, menuRep: id) {
	msgSend(nil, self, "setTearOffMenuRepresentation:", menuRep)
}
@(objc_type=Menu, objc_name="tearOffMenuRepresentation")
Menu_tearOffMenuRepresentation :: #force_inline proc "c" (self: ^Menu) -> id {
	return msgSend(id, self, "tearOffMenuRepresentation")
}
@(objc_type=Menu, objc_name="menuZone", objc_is_class_method=true)
Menu_menuZone :: #force_inline proc "c" () -> ^Zone {
	return msgSend(^Zone, Menu, "menuZone")
}
@(objc_type=Menu, objc_name="setMenuZone", objc_is_class_method=true)
Menu_setMenuZone :: #force_inline proc "c" (zone: ^Zone) {
	msgSend(nil, Menu, "setMenuZone:", zone)
}
@(objc_type=Menu, objc_name="attachedMenu")
Menu_attachedMenu :: #force_inline proc "c" (self: ^Menu) -> ^Menu {
	return msgSend(^Menu, self, "attachedMenu")
}
@(objc_type=Menu, objc_name="isAttached")
Menu_isAttached :: #force_inline proc "c" (self: ^Menu) -> bool {
	return msgSend(bool, self, "isAttached")
}
@(objc_type=Menu, objc_name="sizeToFit")
Menu_sizeToFit :: #force_inline proc "c" (self: ^Menu) {
	msgSend(nil, self, "sizeToFit")
}
@(objc_type=Menu, objc_name="locationForSubmenu")
Menu_locationForSubmenu :: #force_inline proc "c" (self: ^Menu, submenu: ^Menu) -> Point {
	return msgSend(Point, self, "locationForSubmenu:", submenu)
}
@(objc_type=Menu, objc_name="helpRequested")
Menu_helpRequested :: #force_inline proc "c" (self: ^Menu, eventPtr: ^Event) {
	msgSend(nil, self, "helpRequested:", eventPtr)
}
@(objc_type=Menu, objc_name="menuChangedMessagesEnabled")
Menu_menuChangedMessagesEnabled :: #force_inline proc "c" (self: ^Menu) -> bool {
	return msgSend(bool, self, "menuChangedMessagesEnabled")
}
@(objc_type=Menu, objc_name="setMenuChangedMessagesEnabled")
Menu_setMenuChangedMessagesEnabled :: #force_inline proc "c" (self: ^Menu, menuChangedMessagesEnabled: bool) {
	msgSend(nil, self, "setMenuChangedMessagesEnabled:", menuChangedMessagesEnabled)
}
@(objc_type=Menu, objc_name="isTornOff")
Menu_isTornOff :: #force_inline proc "c" (self: ^Menu) -> bool {
	return msgSend(bool, self, "isTornOff")
}
@(objc_type=Menu, objc_name="load", objc_is_class_method=true)
Menu_load :: #force_inline proc "c" () {
	msgSend(nil, Menu, "load")
}
@(objc_type=Menu, objc_name="initialize", objc_is_class_method=true)
Menu_initialize :: #force_inline proc "c" () {
	msgSend(nil, Menu, "initialize")
}
@(objc_type=Menu, objc_name="new", objc_is_class_method=true)
Menu_new :: #force_inline proc "c" () -> ^Menu {
	return msgSend(^Menu, Menu, "new")
}
@(objc_type=Menu, objc_name="allocWithZone", objc_is_class_method=true)
Menu_allocWithZone :: #force_inline proc "c" (zone: ^Zone) -> ^Menu {
	return msgSend(^Menu, Menu, "allocWithZone:", zone)
}
@(objc_type=Menu, objc_name="alloc", objc_is_class_method=true)
Menu_alloc :: #force_inline proc "c" () -> ^Menu {
	return msgSend(^Menu, Menu, "alloc")
}
@(objc_type=Menu, objc_name="copyWithZone", objc_is_class_method=true)
Menu_copyWithZone :: #force_inline proc "c" (zone: ^Zone) -> id {
	return msgSend(id, Menu, "copyWithZone:", zone)
}
@(objc_type=Menu, objc_name="mutableCopyWithZone", objc_is_class_method=true)
Menu_mutableCopyWithZone :: #force_inline proc "c" (zone: ^Zone) -> id {
	return msgSend(id, Menu, "mutableCopyWithZone:", zone)
}
@(objc_type=Menu, objc_name="instancesRespondToSelector", objc_is_class_method=true)
Menu_instancesRespondToSelector :: #force_inline proc "c" (aSelector: SEL) -> bool {
	return msgSend(bool, Menu, "instancesRespondToSelector:", aSelector)
}
@(objc_type=Menu, objc_name="conformsToProtocol", objc_is_class_method=true)
Menu_conformsToProtocol :: #force_inline proc "c" (protocol: ^Protocol) -> bool {
	return msgSend(bool, Menu, "conformsToProtocol:", protocol)
}
@(objc_type=Menu, objc_name="instanceMethodForSelector", objc_is_class_method=true)
Menu_instanceMethodForSelector :: #force_inline proc "c" (aSelector: SEL) -> IMP {
	return msgSend(IMP, Menu, "instanceMethodForSelector:", aSelector)
}
// @(objc_type=Menu, objc_name="instanceMethodSignatureForSelector", objc_is_class_method=true)
// Menu_instanceMethodSignatureForSelector :: #force_inline proc "c" (aSelector: SEL) -> ^MethodSignature {
// 	return msgSend(^MethodSignature, Menu, "instanceMethodSignatureForSelector:", aSelector)
// }
@(objc_type=Menu, objc_name="isSubclassOfClass", objc_is_class_method=true)
Menu_isSubclassOfClass :: #force_inline proc "c" (aClass: Class) -> bool {
	return msgSend(bool, Menu, "isSubclassOfClass:", aClass)
}
@(objc_type=Menu, objc_name="resolveClassMethod", objc_is_class_method=true)
Menu_resolveClassMethod :: #force_inline proc "c" (sel: SEL) -> bool {
	return msgSend(bool, Menu, "resolveClassMethod:", sel)
}
@(objc_type=Menu, objc_name="resolveInstanceMethod", objc_is_class_method=true)
Menu_resolveInstanceMethod :: #force_inline proc "c" (sel: SEL) -> bool {
	return msgSend(bool, Menu, "resolveInstanceMethod:", sel)
}
@(objc_type=Menu, objc_name="hash", objc_is_class_method=true)
Menu_hash :: #force_inline proc "c" () -> UInteger {
	return msgSend(UInteger, Menu, "hash")
}
@(objc_type=Menu, objc_name="superclass", objc_is_class_method=true)
Menu_superclass :: #force_inline proc "c" () -> Class {
	return msgSend(Class, Menu, "superclass")
}
@(objc_type=Menu, objc_name="class", objc_is_class_method=true)
Menu_class :: #force_inline proc "c" () -> Class {
	return msgSend(Class, Menu, "class")
}
@(objc_type=Menu, objc_name="description", objc_is_class_method=true)
Menu_description :: #force_inline proc "c" () -> ^String {
	return msgSend(^String, Menu, "description")
}
@(objc_type=Menu, objc_name="debugDescription", objc_is_class_method=true)
Menu_debugDescription :: #force_inline proc "c" () -> ^String {
	return msgSend(^String, Menu, "debugDescription")
}
@(objc_type=Menu, objc_name="version", objc_is_class_method=true)
Menu_version :: #force_inline proc "c" () -> Integer {
	return msgSend(Integer, Menu, "version")
}
@(objc_type=Menu, objc_name="setVersion", objc_is_class_method=true)
Menu_setVersion :: #force_inline proc "c" (aVersion: Integer) {
	msgSend(nil, Menu, "setVersion:", aVersion)
}
@(objc_type=Menu, objc_name="poseAsClass", objc_is_class_method=true)
Menu_poseAsClass :: #force_inline proc "c" (aClass: Class) {
	msgSend(nil, Menu, "poseAsClass:", aClass)
}
@(objc_type=Menu, objc_name="cancelPreviousPerformRequestsWithTarget_selector_object", objc_is_class_method=true)
Menu_cancelPreviousPerformRequestsWithTarget_selector_object :: #force_inline proc "c" (aTarget: id, aSelector: SEL, anArgument: id) {
	msgSend(nil, Menu, "cancelPreviousPerformRequestsWithTarget:selector:object:", aTarget, aSelector, anArgument)
}
@(objc_type=Menu, objc_name="cancelPreviousPerformRequestsWithTarget_", objc_is_class_method=true)
Menu_cancelPreviousPerformRequestsWithTarget_ :: #force_inline proc "c" (aTarget: id) {
	msgSend(nil, Menu, "cancelPreviousPerformRequestsWithTarget:", aTarget)
}
@(objc_type=Menu, objc_name="accessInstanceVariablesDirectly", objc_is_class_method=true)
Menu_accessInstanceVariablesDirectly :: #force_inline proc "c" () -> bool {
	return msgSend(bool, Menu, "accessInstanceVariablesDirectly")
}
@(objc_type=Menu, objc_name="useStoredAccessor", objc_is_class_method=true)
Menu_useStoredAccessor :: #force_inline proc "c" () -> bool {
	return msgSend(bool, Menu, "useStoredAccessor")
}
@(objc_type=Menu, objc_name="keyPathsForValuesAffectingValueForKey", objc_is_class_method=true)
Menu_keyPathsForValuesAffectingValueForKey :: #force_inline proc "c" (key: ^String) -> ^Set {
	return msgSend(^Set, Menu, "keyPathsForValuesAffectingValueForKey:", key)
}
@(objc_type=Menu, objc_name="automaticallyNotifiesObserversForKey", objc_is_class_method=true)
Menu_automaticallyNotifiesObserversForKey :: #force_inline proc "c" (key: ^String) -> bool {
	return msgSend(bool, Menu, "automaticallyNotifiesObserversForKey:", key)
}
@(objc_type=Menu, objc_name="setKeys", objc_is_class_method=true)
Menu_setKeys :: #force_inline proc "c" (keys: ^Array, dependentKey: ^String) {
	msgSend(nil, Menu, "setKeys:triggerChangeNotificationsForDependentKey:", keys, dependentKey)
}
@(objc_type=Menu, objc_name="classFallbacksForKeyedArchiver", objc_is_class_method=true)
Menu_classFallbacksForKeyedArchiver :: #force_inline proc "c" () -> ^Array {
	return msgSend(^Array, Menu, "classFallbacksForKeyedArchiver")
}
@(objc_type=Menu, objc_name="classForKeyedUnarchiver", objc_is_class_method=true)
Menu_classForKeyedUnarchiver :: #force_inline proc "c" () -> Class {
	return msgSend(Class, Menu, "classForKeyedUnarchiver")
}
@(objc_type=Menu, objc_name="exposeBinding", objc_is_class_method=true)
Menu_exposeBinding :: #force_inline proc "c" (binding: ^String) {
	msgSend(nil, Menu, "exposeBinding:", binding)
}
@(objc_type=Menu, objc_name="setDefaultPlaceholder", objc_is_class_method=true)
Menu_setDefaultPlaceholder :: #force_inline proc "c" (placeholder: id, marker: id, binding: ^String) {
	msgSend(nil, Menu, "setDefaultPlaceholder:forMarker:withBinding:", placeholder, marker, binding)
}
@(objc_type=Menu, objc_name="defaultPlaceholderForMarker", objc_is_class_method=true)
Menu_defaultPlaceholderForMarker :: #force_inline proc "c" (marker: id, binding: ^String) -> id {
	return msgSend(id, Menu, "defaultPlaceholderForMarker:withBinding:", marker, binding)
}
@(objc_type=Menu, objc_name="popUpContextMenu")
Menu_popUpContextMenu :: proc {
	Menu_popUpContextMenu_withEvent_forView,
	// Menu_popUpContextMenu_withEvent_forView_withFont,
}

@(objc_type=Menu, objc_name="paletteMenuWithColors")
Menu_paletteMenuWithColors :: proc {
	Menu_paletteMenuWithColors_titles_selectionHandler,
	// Menu_paletteMenuWithColors_titles_templateImage_selectionHandler,
}

@(objc_type=Menu, objc_name="cancelPreviousPerformRequestsWithTarget")
Menu_cancelPreviousPerformRequestsWithTarget :: proc {
	Menu_cancelPreviousPerformRequestsWithTarget_selector_object,
	Menu_cancelPreviousPerformRequestsWithTarget_,
}







@(objc_class="NSMenuDelegate")
MenuDelegate :: struct {using _: Object, using _: ObjectProtocol}

@(objc_type=MenuDelegate, objc_name="menuNeedsUpdate")
MenuDelegate_menuNeedsUpdate :: #force_inline proc "c" (self: ^MenuDelegate, menu: ^Menu) {
	msgSend(nil, self, "menuNeedsUpdate:", menu)
}
@(objc_type=MenuDelegate, objc_name="numberOfItemsInMenu")
MenuDelegate_numberOfItemsInMenu :: #force_inline proc "c" (self: ^MenuDelegate, menu: ^Menu) -> Integer {
	return msgSend(Integer, self, "numberOfItemsInMenu:", menu)
}
@(objc_type=MenuDelegate, objc_name="menu_updateItem_atIndex_shouldCancel")
MenuDelegate_menu_updateItem_atIndex_shouldCancel :: #force_inline proc "c" (self: ^MenuDelegate, menu: ^Menu, item: ^MenuItem, index: Integer, shouldCancel: bool) -> bool {
	return msgSend(bool, self, "menu:updateItem:atIndex:shouldCancel:", menu, item, index, shouldCancel)
}
@(objc_type=MenuDelegate, objc_name="menuHasKeyEquivalent")
MenuDelegate_menuHasKeyEquivalent :: #force_inline proc "c" (self: ^MenuDelegate, menu: ^Menu, event: ^Event, target: ^id, action: ^SEL) -> bool {
	return msgSend(bool, self, "menuHasKeyEquivalent:forEvent:target:action:", menu, event, target, action)
}
@(objc_type=MenuDelegate, objc_name="menuWillOpen")
MenuDelegate_menuWillOpen :: #force_inline proc "c" (self: ^MenuDelegate, menu: ^Menu) {
	msgSend(nil, self, "menuWillOpen:", menu)
}
@(objc_type=MenuDelegate, objc_name="menuDidClose")
MenuDelegate_menuDidClose :: #force_inline proc "c" (self: ^MenuDelegate, menu: ^Menu) {
	msgSend(nil, self, "menuDidClose:", menu)
}
@(objc_type=MenuDelegate, objc_name="menu_willHighlightItem")
MenuDelegate_menu_willHighlightItem :: #force_inline proc "c" (self: ^MenuDelegate, menu: ^Menu, item: ^MenuItem) {
	msgSend(nil, self, "menu:willHighlightItem:", menu, item)
}
@(objc_type=MenuDelegate, objc_name="confinementRectForMenu")
MenuDelegate_confinementRectForMenu :: #force_inline proc "c" (self: ^MenuDelegate, menu: ^Menu, screen: ^Screen) -> Rect {
	return msgSend(Rect, self, "confinementRectForMenu:onScreen:", menu, screen)
}
@(objc_type=MenuDelegate, objc_name="menu")
MenuDelegate_menu :: proc {
	MenuDelegate_menu_updateItem_atIndex_shouldCancel,
	MenuDelegate_menu_willHighlightItem,
}
