package objc_Foundation

@(objc_class="NSPanel")
Panel :: struct {using _: Window}

NSOpenSavePanelDelegate :: struct {

}

@(objc_class="NSSavePanel")
SavePanel :: struct {using _: Panel}

ModalResponse :: enum Integer {
	ResponseCancel = 0,
	ResponseOK = 1,
	ResponseContinue = -1002,
	ResponseStop = -1000,
	ResponseAbort = -1001,
}

@(objc_type=SavePanel, objc_name="savePanel", objc_is_class_method=true)
SavePanel_openPanel :: proc() -> ^SavePanel {
	return msgSend(^SavePanel, SavePanel, "savePanel")
}

@(objc_type=SavePanel, objc_name="runModal")
SavePanel_runModal :: proc(self: ^SavePanel) -> ModalResponse {
	return msgSend(ModalResponse, self, "runModal")
}

@(objc_type=SavePanel, objc_name="URL")
SavePanel_URL :: proc(self: ^SavePanel) -> ^URL {
	return msgSend(^URL, self, "URL")
}

@(objc_class="NSOpenPanel")
OpenPanel :: struct {using _: SavePanel}

@(objc_type=OpenPanel, objc_name="openPanel", objc_is_class_method=true)
OpenPanel_openPanel :: proc() -> ^OpenPanel {
	return msgSend(^OpenPanel, OpenPanel, "openPanel")
}

@(objc_type=OpenPanel, objc_name="setCanChooseFiles")
OpenPanel_setCanChooseFiles :: proc(self: ^OpenPanel, ok: BOOL) {
	msgSend(nil, self, "setCanChooseFiles:", ok)
}

@(objc_type=OpenPanel, objc_name="canChooseFiles")
OpenPanel_canChooseFiles :: proc(self: ^OpenPanel) -> BOOL {
	return msgSend(BOOL, self, "canChooseFiles")
}

@(objc_type=OpenPanel, objc_name="setCanChooseDirectories")
OpenPanel_setCanChooseDirectories :: proc(self: ^OpenPanel, ok: BOOL) {
	msgSend(nil, self, "setCanChooseDirectories:", ok)
}

@(objc_type=OpenPanel, objc_name="canChooseDirectories")
OpenPanel_canChooseDirectories :: proc(self: ^OpenPanel) -> BOOL {
	return msgSend(BOOL, self, "canChooseDirectories")
}

@(objc_type=OpenPanel, objc_name="setResolvesAliases")
OpenPanel_setResolvesAliases :: proc(self: ^OpenPanel, ok: BOOL) {
	msgSend(nil, self, "setResolvesAliases:", ok)
}

@(objc_type=OpenPanel, objc_name="resolvesAliases")
OpenPanel_resolvesAliases :: proc(self: ^OpenPanel) -> BOOL {
	return msgSend(BOOL, self, "resolvesAliases")
}

@(objc_type=OpenPanel, objc_name="setAllowsMultipleSelection")
OpenPanel_setAllowsMultipleSelection :: proc(self: ^OpenPanel, ok: BOOL) {
	msgSend(nil, self, "setAllowsMultipleSelection:", ok)
}

@(objc_type=OpenPanel, objc_name="allowsMultipleSelection")
OpenPanel_allowsMultipleSelection :: proc(self: ^OpenPanel) -> BOOL {
	return msgSend(BOOL, self, "allowsMultipleSelection")
}

@(objc_type=OpenPanel, objc_name="setAccessoryViewDisclosed")
OpenPanel_setAccessoryViewDisclosed :: proc(self: ^OpenPanel, ok: BOOL) {
	msgSend(nil, self, "setAccessoryViewDisclosed:", ok)
}

@(objc_type=OpenPanel, objc_name="isAccessoryViewDisclosed")
OpenPanel_accessoryViewDisclosed :: proc(self: ^OpenPanel) -> BOOL {
	return msgSend(BOOL, self, "isAccessoryViewDisclosed")
}

@(objc_type=OpenPanel, objc_name="URLs")
OpenPanel_URLs :: proc(self: ^OpenPanel) -> ^Array {
	return msgSend(^Array, self, "URLs")
}

@(objc_type=OpenPanel, objc_name="setCanDownloadUbiquitousContents")
OpenPanel_setCanDownloadUbiquitousContents :: proc(self: ^OpenPanel, ok: BOOL) {
	msgSend(nil, self, "setCanDownloadUbiquitousContents:", ok)
}

@(objc_type=OpenPanel, objc_name="canDownloadUbiquitousContents")
OpenPanel_canDownloadUbiquitousContents :: proc(self: ^OpenPanel) -> BOOL {
	return msgSend(BOOL, self, "canDownloadUbiquitousContents")
}

@(objc_type=OpenPanel, objc_name="setCanResolveUbiquitousConflicts")
OpenPanel_setCanResolveUbiquitousConflicts :: proc(self: ^OpenPanel, ok: BOOL) {
	msgSend(nil, self, "setCanResolveUbiquitousConflicts:", ok)
}

@(objc_type=OpenPanel, objc_name="canResolveUbiquitousConflicts")
OpenPanel_canResolveUbiquitousConflicts :: proc(self: ^OpenPanel) -> BOOL {
	return msgSend(BOOL, self, "canResolveUbiquitousConflicts")
}
