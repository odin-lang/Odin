package objc_Foundation

@(objc_class="NSOpenPanel")
OpenPanel :: struct{ using _: SavePanel }

@(objc_type=OpenPanel, objc_name="openPanel", objc_is_class_method=true)
OpenPanel_openPanel :: proc "c" () -> ^OpenPanel {
	return msgSend(^OpenPanel, OpenPanel, "openPanel")
}

@(objc_type=OpenPanel, objc_name="URLs")
OpenPanel_URLs :: proc "c" (self: ^OpenPanel) -> ^Array {
	return msgSend(^Array, self, "URLs")
}

@(objc_type=OpenPanel, objc_name="setCanChooseFiles")
OpenPanel_setCanChooseFiles :: proc "c" (self: ^OpenPanel, setting: BOOL) {
	msgSend(nil, self, "setCanChooseFiles:", setting)
}
@(objc_type=OpenPanel, objc_name="setCanChooseDirectories")
OpenPanel_setCanChooseDirectories :: proc "c" (self: ^OpenPanel, setting: BOOL) {
	msgSend(nil, self, "setCanChooseDirectories:", setting)
}
@(objc_type=OpenPanel, objc_name="setResolvesAliases")
OpenPanel_setResolvesAliases :: proc "c" (self: ^OpenPanel, setting: BOOL) {
	msgSend(nil, self, "setResolvesAliases:", setting)
}
@(objc_type=OpenPanel, objc_name="setAllowsMultipleSelection")
OpenPanel_setAllowsMultipleSelection :: proc "c" (self: ^OpenPanel, setting: BOOL) {
	msgSend(nil, self, "setAllowsMultipleSelection:", setting)
}
@(objc_type=OpenPanel, objc_name="setAllowedFileTypes")
OpenPanel_setAllowedFileTypes :: proc "c" (self: ^OpenPanel, types: ^Array) {
	msgSend(nil, self, "setAllowedFileTypes:", types)
}
