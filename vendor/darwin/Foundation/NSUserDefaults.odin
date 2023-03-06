package objc_Foundation

@(objc_class="NSUserDefaults")
UserDefaults :: struct { using _: Object }

@(objc_type=UserDefaults, objc_name="standardUserDefaults", objc_is_class_method=true)
UserDefaults_standardUserDefaults :: proc() -> ^UserDefaults {
	return msgSend(^UserDefaults, UserDefaults, "standardUserDefaults")
}

@(objc_type=UserDefaults, objc_name="setBoolForKey")
UserDefaults_setBoolForKey :: proc(self: ^UserDefaults, value: BOOL, name: ^String) {
	msgSend(nil, self, "setBool:forKey:", value, name)
}
