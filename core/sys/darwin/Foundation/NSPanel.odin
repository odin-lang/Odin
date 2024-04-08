package objc_Foundation

ModalResponse :: enum UInteger {
	Cancel = 0,
	OK = 1,
}

@(objc_class="NSPanel")
Panel :: struct{ using _: Window }
