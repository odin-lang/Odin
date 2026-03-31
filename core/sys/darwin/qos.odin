package darwin

import "core:c"

qos_class_t :: enum c.uint {
	USER_INTERACTIVE = 0x21,
	USER_INITIATED   = 0x19,
	DEFAULT          = 0x15,
	UTILITY          = 0x11,
	BACKGROUND       = 0x09,
	UNSPECIFIED      = 0x00,
}
QOS_CLASS_USER_INTERACTIVE :: qos_class_t.USER_INTERACTIVE
QOS_CLASS_USER_INITIATED   :: qos_class_t.USER_INITIATED
QOS_CLASS_DEFAULT          :: qos_class_t.DEFAULT
QOS_CLASS_UTILITY          :: qos_class_t.UTILITY
QOS_CLASS_BACKGROUND       :: qos_class_t.BACKGROUND
QOS_CLASS_UNSPECIFIED      :: qos_class_t.UNSPECIFIED

QOS_MIN_RELATIVE_PRIORITY :: -15
