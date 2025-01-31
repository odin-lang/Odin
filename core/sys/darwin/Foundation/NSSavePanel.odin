package objc_Foundation

@(objc_class="NSSavePanel")
SavePanel :: struct{ using _: Panel }

@(objc_type=SavePanel, objc_name="runModal")
SavePanel_runModal :: proc "c" (self: ^SavePanel) -> ModalResponse {
	return msgSend(ModalResponse, self, "runModal")
}

@(objc_type=SavePanel, objc_name="savePanel", objc_is_class_method=true)
SavePanel_savePanel :: proc "c" () -> ^SavePanel {
	return msgSend(^SavePanel, SavePanel, "savePanel")
}

@(objc_type=SavePanel, objc_name="URL")
SavePanel_URL :: proc "c" (self: ^SavePanel) -> ^Array {
	return msgSend(^Array, self, "URL")
}
