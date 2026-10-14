package objc_Foundation

@(objc_class="NSLayoutConstraint")
LayoutConstraint :: struct {using _: Object}

@(objc_type=LayoutConstraint, objc_name="activateConstraints", objc_is_class_method=true)
LayoutConstraint_activateConstraints :: proc "c" (constraints: ^Array) {
	msgSend(nil, LayoutConstraint, "activateConstraints:", constraints)
}
