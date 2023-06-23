package objc_Foundation

@(objc_class="NSSavePanel")
SavePanel :: struct{ using _: Panel }

@(objc_type=SavePanel, objc_name="runModal")
SavePanel_runModal :: proc "c" (self: ^SavePanel) -> ModalResponse {
	return msgSend(ModalResponse, self, "runModal")
}
