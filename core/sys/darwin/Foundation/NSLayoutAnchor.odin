package objc_Foundation

@(objc_class="NSLayoutAnchor")
LayoutAnchor :: struct {using _: Object}

@(objc_type=LayoutAnchor, objc_name="constraintEqualToAnchorConstant")
LayoutAnchor_constraintEqualToAnchorConstant :: proc "c" (self: ^LayoutAnchor, anchor: ^LayoutAnchor, constant: Float) -> ^LayoutConstraint {
	return msgSend(^LayoutConstraint, self, "constraintEqualToAnchor:constant:", anchor, constant)
}
