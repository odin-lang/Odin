#+build darwin
package objc_Foundation

os_workgroup_t  :: ^OS_os_workgroup
OS_os_workgroup :: struct{using _: OS_object}
os_workgroup_s  :: OS_os_workgroup

OS_object :: struct{using _: Object}

//TODO: Everything else in https://developer.apple.com/documentation/os?language=objc
