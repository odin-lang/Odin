#+build darwin
package test_internal

import "base:intrinsics"
import "core:testing"
import NS "core:sys/darwin/Foundation"

// Sending a message makes the Objective-C setup look up the receiver's class and the
// selector, so the compiler needs objc_lookUpClass and sel_registerName even when nothing
// else refers to them.
@(test)
objc_send_registers_names :: proc(t: ^testing.T) {
	s := NS.String.alloc()->initWithOdinString("hello")
	defer s->release()
	testing.expect_value(t, s->odinString(), "hello")
	testing.expect_value(t, intrinsics.objc_send(NS.UInteger, s, "length"), 5)
}
