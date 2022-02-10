package objc_Metal

import NS "core:sys/darwin/Foundation"
import "core:intrinsics"

alloc            :: NS.alloc
init             :: NS.init
retain           :: NS.retain
release          :: NS.release
autorelease      :: NS.autorelease
retainCount      :: NS.retainCount
copy             :: NS.copy
hash             :: NS.hash
isEqual          :: NS.isEqual
description      :: NS.description
debugDescription :: NS.debugDescription
bridgingCast     :: NS.bridgingCast

@(private)
msgSend :: intrinsics.objc_send

BOOL :: NS.BOOL