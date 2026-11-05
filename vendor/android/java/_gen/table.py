"""
The reviewed table of the integer slots of vendor:android/java that take constants but carry no @IntDef.

generate.py types the slots @IntDef and @LongDef annotate (annotations.zip) by itself. This table adds new types for
constant families no annotation covers, bit_fields, and the slots each type takes.

Types are named `<Owner>_<Thing>`, after the class owning the constants. Members drop the shared prefix (`.BACK`),
and a member that would start with a digit gets `_` (`._90`), or `NUM` on a key code (`.NUM0`). A bit_set's element
enum takes the singular (`KeyEvent_Flags` -> `KeyEvent_Flag`) or `Flag` added (`KeyEvent_MetaState` ->
`KeyEvent_MetaStateFlag`), as in darwin. Its single bits become elements, and a member of no bits or several bits a
typed constant: `MenuItem_ShowAsAction_NEVER :: MenuItem_ShowAsAction{}`. The flat constants stay.
"""

# New types, for constant families no @IntDef covers.
#   name: (kind, class, members)
#   kind:    "enum" or "bit_set"
#   members: "PREFIX_" for every int constant starting with it, "*" for every int constant of the class,
#            or a list of names and glob patterns ("FLAG_*", "*_MASK"), where a leading "!" leaves those out.
# An @IntDef group of the same class whose members all belong to a new type merges into it.
NEW_TYPES = {
	# android.view: input
	"KeyEvent_KeyCode":                     ("enum",    "android/view/KeyEvent", "KEYCODE_"),
	"KeyEvent_Action":                      ("enum",    "android/view/KeyEvent", "ACTION_"),
	"KeyEvent_MetaState":                   ("bit_set", "android/view/KeyEvent", "META_"),
	"KeyEvent_Flags":                       ("bit_set", "android/view/KeyEvent", "FLAG_"),
	"MotionEvent_Action":                   ("enum",    "android/view/MotionEvent", [
		"ACTION_DOWN", "ACTION_UP", "ACTION_MOVE", "ACTION_CANCEL", "ACTION_OUTSIDE", "ACTION_POINTER_DOWN",
		"ACTION_POINTER_UP", "ACTION_HOVER_MOVE", "ACTION_SCROLL", "ACTION_HOVER_ENTER", "ACTION_HOVER_EXIT",
		"ACTION_BUTTON_PRESS", "ACTION_BUTTON_RELEASE",
	]),
	"MotionEvent_Buttons":                  ("bit_set", "android/view/MotionEvent", "BUTTON_"),
	"MotionEvent_EdgeFlags":                ("bit_set", "android/view/MotionEvent", "EDGE_"),
	"MotionEvent_Flags":                    ("bit_set", "android/view/MotionEvent", "FLAG_"),
	"InputDevice_Sources":                  ("bit_set", "android/view/InputDevice", "SOURCE_"),
	"InputDevice_KeyboardType":             ("enum",    "android/view/InputDevice", "KEYBOARD_TYPE_"),
	"KeyCharacterMap_KeyboardType":         ("enum",    "android/view/KeyCharacterMap", ["NUMERIC", "PREDICTIVE", "ALPHA", "FULL", "SPECIAL_FUNCTION"]),
	"KeyCharacterMap_ModifierBehavior":     ("enum",    "android/view/KeyCharacterMap", "MODIFIER_BEHAVIOR_"),
	"DragEvent_Action":                     ("enum",    "android/view/DragEvent", "ACTION_"),

	# android.view: windows and views
	"Window_Feature":                       ("enum",    "android/view/Window", "FEATURE_"),
	"WindowManager_LayoutParams_RotationAnimation": ("enum", "android/view/WindowManager$LayoutParams", "ROTATION_ANIMATION_"),
	"ActionMode_Type":                      ("enum",    "android/view/ActionMode", "TYPE_"),
	"Display_Flags":                        ("bit_set", "android/view/Display", "FLAG_"),
	"View_SystemUiFlags":                   ("bit_set", "android/view/View", "SYSTEM_UI_FLAG_"),
	"View_ImportantForAccessibility":       ("enum",    "android/view/View", "IMPORTANT_FOR_ACCESSIBILITY_"),
	"View_AccessibilityLiveRegion":         ("enum",    "android/view/View", "ACCESSIBILITY_LIVE_REGION_"),
	"View_OverScrollMode":                  ("enum",    "android/view/View", "OVER_SCROLL_"),
	"View_TextDirection":                   ("enum",    "android/view/View", "TEXT_DIRECTION_"),
	"View_DragFlags":                       ("bit_set", "android/view/View", "DRAG_FLAG_"),
	"View_ScreenState":                     ("enum",    "android/view/View", "SCREEN_STATE_"),
	"ViewGroup_LayoutMode":                 ("enum",    "android/view/ViewGroup", "LAYOUT_MODE_"),
	"HapticFeedbackConstants_Feedback":     ("enum",    "android/view/HapticFeedbackConstants", ["*", "!FLAG_*"]),
	"HapticFeedbackConstants_Flags":        ("bit_set", "android/view/HapticFeedbackConstants", "FLAG_"),
	"PointerIcon_Type":                     ("enum",    "android/view/PointerIcon", "TYPE_"),
	"SurfaceHolder_Type":                   ("enum",    "android/view/SurfaceHolder", "SURFACE_TYPE_"),
	"Menu_Flags":                           ("bit_set", "android/view/Menu", "FLAG_"),
	"MenuItem_ShowAsAction":                ("bit_set", "android/view/MenuItem", "SHOW_AS_ACTION_"),

	# android.view.inputmethod, android.text
	"InputConnection_GetExtractedTextFlags": ("bit_set", "android/view/inputmethod/InputConnection", ["GET_EXTRACTED_TEXT_MONITOR"]),
	"InputConnection_InputContentFlags":    ("bit_set", "android/view/inputmethod/InputConnection", "INPUT_CONTENT_"),
	"InputMethod_ShowFlags":                ("bit_set", "android/view/inputmethod/InputMethod", "SHOW_"),
	"CursorAnchorInfo_Flags":               ("bit_set", "android/view/inputmethod/CursorAnchorInfo", "FLAG_"),
	"ExtractedText_Flags":                  ("bit_set", "android/view/inputmethod/ExtractedText", "FLAG_"),
	"TextUtils_CapMode":                    ("bit_set", "android/text/TextUtils", "CAP_MODE_"),
	"Layout_Direction":                     ("enum",    "android/text/Layout", "DIR_"),
	"Html_FromHtmlFlags":                   ("bit_set", "android/text/Html", "FROM_HTML_"),
	"Html_ToHtmlOption":                    ("enum",    "android/text/Html", "TO_HTML_"),

	# android.widget
	"AbsListView_ChoiceMode":               ("enum",    "android/widget/AbsListView", "CHOICE_MODE_"),
	"AbsListView_TranscriptMode":           ("enum",    "android/widget/AbsListView", "TRANSCRIPT_MODE_"),
	"AbsListView_OnScrollListener_ScrollState": ("enum", "android/widget/AbsListView$OnScrollListener", "SCROLL_STATE_"),
	"PopupWindow_InputMethodMode":          ("enum",    "android/widget/PopupWindow", "INPUT_METHOD_"),
	"Spinner_Mode":                         ("enum",    "android/widget/Spinner", "MODE_"),
	"CursorAdapter_Flags":                  ("bit_set", "android/widget/CursorAdapter", "FLAG_"),
	"ExpandableListView_PackedPositionType": ("enum",   "android/widget/ExpandableListView", "PACKED_POSITION_TYPE_"),

	# android.app
	"DialogInterface_Button":               ("enum",    "android/content/DialogInterface", ["BUTTON_POSITIVE", "BUTTON_NEGATIVE", "BUTTON_NEUTRAL"]),
	"ActivityManager_LockTaskMode":         ("enum",    "android/app/ActivityManager", "LOCK_TASK_MODE_"),
	"ActivityManager_RecentFlags":          ("bit_set", "android/app/ActivityManager", "RECENT_"),
	"ActivityManager_RunningServiceInfo_Flags": ("bit_set", "android/app/ActivityManager$RunningServiceInfo", "FLAG_"),
	"ActivityManager_RunningAppProcessInfo_Reason": ("enum", "android/app/ActivityManager$RunningAppProcessInfo", "REASON_"),
	"AppOpsManager_Mode":                   ("enum",    "android/app/AppOpsManager", "MODE_"),
	"AppOpsManager_WatchFlags":             ("bit_set", "android/app/AppOpsManager", "WATCH_"),
	"ApplicationErrorReport_Type":          ("enum",    "android/app/ApplicationErrorReport", "TYPE_"),
	"DialogFragment_Style":                 ("enum",    "android/app/DialogFragment", "STYLE_"),
	"DownloadManager_Statuses":               ("bit_set", "android/app/DownloadManager", "STATUS_"),
	"DownloadManager_Request_Visibility":   ("enum",    "android/app/DownloadManager$Request", "VISIBILITY_"),
	"DownloadManager_Request_NetworkFlags": ("bit_set", "android/app/DownloadManager$Request", "NETWORK_"),
	"FragmentManager_PopFlags":             ("bit_set", "android/app/FragmentManager", "POP_"),
	"Notification_Defaults":                ("bit_set", "android/app/Notification", "DEFAULT_"),
	"Notification_BadgeIconType":           ("enum",    "android/app/Notification", "BADGE_ICON_"),
	"NotificationManager_Policy_PriorityCategories": ("bit_set", "android/app/NotificationManager$Policy", "PRIORITY_CATEGORY_"),
	"NotificationManager_Policy_SuppressedEffects":  ("bit_set", "android/app/NotificationManager$Policy", "SUPPRESSED_EFFECT_"),
	"ProgressDialog_Style":                 ("enum",    "android/app/ProgressDialog", "STYLE_"),
	"UiAutomation_Rotation":                ("enum",    "android/app/UiAutomation", "ROTATION_"),
	"UiModeManager_EnableCarModeFlags":     ("bit_set", "android/app/UiModeManager", "ENABLE_CAR_MODE_"),

	# android.content, android.content.pm, android.content.res
	"ContentResolver_SyncObserverType":     ("bit_set", "android/content/ContentResolver", "SYNC_OBSERVER_TYPE_"),
	"RestrictionEntry_Type":                ("enum",    "android/content/RestrictionEntry", "TYPE_"),
	"ActivityInfo_Flags":                   ("bit_set", "android/content/pm/ActivityInfo", "FLAG_"),
	"ActivityInfo_DocumentLaunchMode":      ("enum",    "android/content/pm/ActivityInfo", "DOCUMENT_LAUNCH_"),
	"ActivityInfo_PersistableMode":         ("enum",    "android/content/pm/ActivityInfo", "PERSIST_"),
	"ActivityInfo_UiOptions":               ("bit_set", "android/content/pm/ActivityInfo", "UIOPTION_"),
	"ApplicationInfo_Flags":                ("bit_set", "android/content/pm/ApplicationInfo", "FLAG_"),
	"ServiceInfo_Flags":                    ("bit_set", "android/content/pm/ServiceInfo", "FLAG_"),
	"ProviderInfo_Flags":                   ("bit_set", "android/content/pm/ProviderInfo", "FLAG_"),
	"FeatureInfo_Flags":                    ("bit_set", "android/content/pm/FeatureInfo", "FLAG_"),
	"ConfigurationInfo_InputFeatures":      ("bit_set", "android/content/pm/ConfigurationInfo", "INPUT_FEATURE_"),
	# The `int flags` overloads; the long-only flags need the newer `PackageInfoFlags`-style overloads.
	"PackageManager_InfoFlags":             ("bit_set", "android/content/pm/PackageManager", ["GET_*", "MATCH_*",
		"!GET_APP_LOCK_INFO", "!GET_ATTRIBUTIONS_LONG", "!MATCH_ARCHIVED_PACKAGES"]),
	"PackageManager_Verification":          ("enum",    "android/content/pm/PackageManager", "VERIFICATION_"),
	"PackageInstaller_SessionParams_Mode":  ("enum",    "android/content/pm/PackageInstaller$SessionParams", "MODE_"),
	"PackageInstaller_SessionInfo_SessionError": ("enum", "android/content/pm/PackageInstaller$SessionInfo", "SESSION_"),
	"Configuration_Keyboard":               ("enum",    "android/content/res/Configuration", "KEYBOARD_"),
	"Configuration_KeyboardHidden":         ("enum",    "android/content/res/Configuration", "KEYBOARDHIDDEN_"),
	"Configuration_HardKeyboardHidden":     ("enum",    "android/content/res/Configuration", "HARDKEYBOARDHIDDEN_"),
	"Configuration_Navigation":             ("enum",    "android/content/res/Configuration", "NAVIGATION_"),
	"Configuration_NavigationHidden":       ("enum",    "android/content/res/Configuration", "NAVIGATIONHIDDEN_"),
	"Configuration_Touchscreen":            ("enum",    "android/content/res/Configuration", "TOUCHSCREEN_"),
	"Configuration_UiModeType":             ("enum",    "android/content/res/Configuration", ["UI_MODE_TYPE_*", "!UI_MODE_TYPE_MASK"]),
	"AssetManager_Access":                  ("enum",    "android/content/res/AssetManager", "ACCESS_"),
	"ObbInfo_Flags":                        ("bit_set", "android/content/res/ObbInfo", "OBB_"),

	# android.graphics, android.hardware, android.net, android.os, android.util
	"PixelFormat_Format":                   ("enum",    "android/graphics/PixelFormat", "*"),
	"ImageFormat_Format":                   ("enum",    "android/graphics/ImageFormat", "*"),
	"Paint_Hinting":                        ("enum",    "android/graphics/Paint", "HINTING_"),
	"PathMeasure_MatrixFlags":              ("bit_set", "android/graphics/PathMeasure", ["POSITION_MATRIX_FLAG", "TANGENT_MATRIX_FLAG"]),
	"Sensor_Type":                          ("enum",    "android/hardware/Sensor", "TYPE_"),
	"Sensor_ReportingMode":                 ("enum",    "android/hardware/Sensor", "REPORTING_MODE_"),
	"SensorAdditionalInfo_Type":            ("enum",    "android/hardware/SensorAdditionalInfo", "TYPE_"),
	"SensorManager_Axis":                   ("enum",    "android/hardware/SensorManager", "AXIS_"),
	"Camera_CameraInfo_Facing":             ("enum",    "android/hardware/Camera$CameraInfo", "CAMERA_FACING_"),
	"ConnectivityManager_Type":             ("enum",    "android/net/ConnectivityManager", "TYPE_"),
	"LocalSocket_Type":                     ("enum",    "android/net/LocalSocket", "SOCKET_"),
	"BatteryManager_Property":              ("enum",    "android/os/BatteryManager", "BATTERY_PROPERTY_"),
	"Debug_TraceFlags":                     ("bit_set", "android/os/Debug", "TRACE_"),
	"Debug_ShowFlags":                      ("bit_set", "android/os/Debug", "SHOW_"),
	"IBinder_Flags":                        ("bit_set", "android/os/IBinder", "FLAG_"),
	"ParcelFileDescriptor_Mode":            ("bit_set", "android/os/ParcelFileDescriptor", "MODE_"),
	"FileObserver_Events":                  ("bit_set", "android/os/FileObserver", "*"),
	"PowerManager_ThermalStatus":           ("enum",    "android/os/PowerManager", "THERMAL_STATUS_"),
	"PowerManager_ReleaseFlags":            ("bit_set", "android/os/PowerManager", "RELEASE_FLAG_"),
	"android_util_Base64_Flags":            ("bit_set", "android/util/Base64", "*"),
	"TypedValue_Type":                      ("enum",    "android/util/TypedValue", "TYPE_"),
}

# bit_sets whose elements are not their single-bit constants: name -> {element: bit}.
# Every constant of such a type is a typed constant, single bits included.
ELEMENTS = {
	# Each SOURCE_* is a class bit plus a device bit, so the device bits are named after their sources.
	"InputDevice_Sources": {
		"CLASS_BUTTON": 0, "CLASS_POINTER": 1, "CLASS_TRACKBALL": 2, "CLASS_POSITION": 3, "CLASS_JOYSTICK": 4,
		"KEYBOARD": 8, "DPAD": 9, "GAMEPAD": 10, "TOUCHSCREEN": 12, "MOUSE": 13, "STYLUS": 14, "BLUETOOTH_STYLUS": 15,
		"TRACKBALL": 16, "MOUSE_RELATIVE": 17, "TOUCHPAD": 20, "TOUCH_NAVIGATION": 21, "ROTARY_ENCODER": 22,
		"JOYSTICK": 24, "HDMI": 25, "SENSOR": 26,
	},
}

# Types whose members that are only digits are keys labelled with that number: `.NUM0`, as in SDL.
NUMBER_KEYS = {"KeyEvent_KeyCode"}

# Names for @IntDef groups, where the derived one is wrong, named by one member: "@<class>.<CONSTANT>" -> name.
# (Everywhere in this table, a constant in both an @IntDef and a @LongDef group names the @IntDef one.)
# A group is named `<Owner>_<Thing>` after the class owning most of its constants. Thing is the constants' shared
# prefix (`NAVIGATION_MODE_` -> `NavigationMode`), with `Flags` for a bit_set (`BIND_` -> `BindFlags`), or else the
# slot's name (`setVisibility` -> `Visibility`). A @LongDef group named like an @IntDef group gets `64`.
INTDEF_NAMES = {
	"@android/app/PendingIntent.FLAG_IMMUTABLE":                  "PendingIntent_Flags",         # with Intent.FILL_IN_*
	"@android/content/pm/PackageManager.GET_ATTRIBUTIONS_LONG":   "PackageManager_InfoFlags64",  # PackageInfoFlags.of
}

# @IntDef groups to leave raw, named by one member.
RAW_GROUPS = {
	"@android/graphics/Canvas.ALL_SAVE_FLAG": "only `ALL_SAVE_FLAG` is public, and it is several bits",
}

# bit_fields, for values that pack small numbers into groups of bits.
#   name: {
#     "backing":   the Odin backing type; the field enums take the unsigned integer of the same width, since a
#                  field of a signed enum is sign-extended (2 does not fit a 2-bit field of an `enum i32`)
#     "enums":     {enum name: {member: value}}, values in the field's own units (after the shift);
#                  an enum may instead be a NEW_TYPES name, whose values are already field units
#     "fields":    [(name, type, bits)], lowest bits first; type is an enum, "bool", an integer type, or "_" for padding
#     "constants": (class, spec), with spec as in NEW_TYPES: the named values that become typed constants
#                  (`Gravity_Field_CENTER :: Gravity_Field{horizontal = .CENTER, vertical = .CENTER}`).
#                  Each must decode exactly. A mask's fields hold all ones, which no member need name
#                  (`EditorInfo_ImeOptions_MASK_ACTION :: EditorInfo_ImeOptions{action = EditorInfo_ImeAction(0xff)}`).
#                  Shifts are bit numbers, not values: they are left out, and stay flat constants.
#     "strip":     the prefix the constants' names lose, when the shared one is wrong (optional)
#   }
# An @IntDef group whose members all belong to a bit_field's constants takes the bit_field instead.
# Its slots are in SLOTS like any other type's, and so are slots taking one of its field enums.
BIT_FIELDS = {
	"Gravity_Field": {
		"backing": "i32",
		"enums": {
			"Gravity_Horizontal": {"NONE": 0, "CENTER": 1, "LEFT": 3, "RIGHT": 5, "FILL": 7},
			"Gravity_Vertical":   {"NONE": 0, "CENTER": 1, "TOP": 3, "BOTTOM": 5, "FILL": 7},
		},
		"fields": [
			("horizontal", "Gravity_Horizontal", 3), ("clip_horizontal", "bool", 1),
			("vertical", "Gravity_Vertical", 3), ("clip_vertical", "bool", 1),
			("_", "_", 15), ("relative", "bool", 1), ("display_clip_horizontal", "bool", 1),
			("_", "_", 3), ("display_clip_vertical", "bool", 1), ("_", "_", 3),
		],
		# AXIS_* are the bits of one axis before its shift, not values.
		"constants": ("android/view/Gravity", ["*", "!*_SHIFT", "!AXIS_*"]),
	},
	"WindowManager_LayoutParams_SoftInputMode": {
		"backing": "i32",
		"enums": {
			"WindowManager_LayoutParams_SoftInputState":  {"UNSPECIFIED": 0, "UNCHANGED": 1, "HIDDEN": 2, "ALWAYS_HIDDEN": 3, "VISIBLE": 4, "ALWAYS_VISIBLE": 5},
			"WindowManager_LayoutParams_SoftInputAdjust": {"UNSPECIFIED": 0, "RESIZE": 1, "PAN": 2, "NOTHING": 3},
		},
		"fields": [
			("state", "WindowManager_LayoutParams_SoftInputState", 4), ("adjust", "WindowManager_LayoutParams_SoftInputAdjust", 4),
			("is_forward_navigation", "bool", 1), ("mode_changed", "bool", 1), ("_", "_", 22),
		],
		"constants": ("android/view/WindowManager$LayoutParams", "SOFT_INPUT_"),
	},
	"EditorInfo_ImeOptions": {
		"backing": "i32",
		"enums": {
			"EditorInfo_ImeAction": {"UNSPECIFIED": 0, "NONE": 1, "GO": 2, "SEARCH": 3, "SEND": 4, "NEXT": 5, "DONE": 6, "PREVIOUS": 7},
		},
		"fields": [
			("action", "EditorInfo_ImeAction", 8), ("_", "_", 16),
			("no_personalized_learning", "bool", 1), ("no_fullscreen", "bool", 1), ("navigate_previous", "bool", 1),
			("navigate_next", "bool", 1), ("no_extract_ui", "bool", 1), ("no_accessory_action", "bool", 1),
			("no_enter_action", "bool", 1), ("force_ascii", "bool", 1),
		],
		"constants": ("android/view/inputmethod/EditorInfo", "IME_"),
	},
	"Configuration_UiMode": {
		"backing": "i32",
		"enums": {
			"Configuration_UiModeNight": {"UNDEFINED": 0, "NO": 1, "YES": 2},
		},
		"fields": [("type", "Configuration_UiModeType", 4), ("night", "Configuration_UiModeNight", 2), ("_", "_", 26)],
		"constants": ("android/content/res/Configuration", "UI_MODE_"),
	},
	"Configuration_ScreenLayout": {
		"backing": "i32",
		"enums": {
			"Configuration_ScreenLayoutSize":  {"UNDEFINED": 0, "SMALL": 1, "NORMAL": 2, "LARGE": 3, "XLARGE": 4},
			"Configuration_ScreenLayoutLong":  {"UNDEFINED": 0, "NO": 1, "YES": 2},
			"Configuration_ScreenLayoutDir":   {"UNDEFINED": 0, "LTR": 1, "RTL": 2},
			"Configuration_ScreenLayoutRound": {"UNDEFINED": 0, "NO": 1, "YES": 2},
		},
		"fields": [
			("size", "Configuration_ScreenLayoutSize", 4), ("long", "Configuration_ScreenLayoutLong", 2),
			("layout_dir", "Configuration_ScreenLayoutDir", 2), ("round", "Configuration_ScreenLayoutRound", 2), ("_", "_", 22),
		],
		"constants": ("android/content/res/Configuration", ["SCREENLAYOUT_*", "!SCREENLAYOUT_*_SHIFT"]),
	},
	"Configuration_ColorMode": {
		"backing": "i32",
		"enums": {
			"Configuration_ColorModeWideColorGamut": {"UNDEFINED": 0, "NO": 1, "YES": 2},
			"Configuration_ColorModeHdr":            {"UNDEFINED": 0, "NO": 1, "YES": 2},
		},
		"fields": [
			("wide_color_gamut", "Configuration_ColorModeWideColorGamut", 2), ("hdr", "Configuration_ColorModeHdr", 2), ("_", "_", 28),
		],
		"constants": ("android/content/res/Configuration", ["COLOR_MODE_*", "!COLOR_MODE_*_SHIFT"]),
	},
	"DataSpace_Field": {
		"backing": "i32",
		"enums": {
			"DataSpace_Standard": {"UNSPECIFIED": 0, "BT709": 1, "BT601_625": 2, "BT601_625_UNADJUSTED": 3, "BT601_525": 4,
				"BT601_525_UNADJUSTED": 5, "BT2020": 6, "BT2020_CONSTANT_LUMINANCE": 7, "BT470M": 8, "FILM": 9, "DCI_P3": 10, "ADOBE_RGB": 11},
			"DataSpace_Transfer": {"UNSPECIFIED": 0, "LINEAR": 1, "SRGB": 2, "SMPTE_170M": 3, "GAMMA2_2": 4, "GAMMA2_6": 5,
				"GAMMA2_8": 6, "ST2084": 7, "HLG": 8},
			"DataSpace_Range":    {"UNSPECIFIED": 0, "FULL": 1, "LIMITED": 2, "EXTENDED": 3},
		},
		"fields": [
			# `other` holds the data spaces outside the scheme (DEPTH, HEIF, JPEG_R), with the fields above it 0.
			("other", "u16", 16), ("standard", "DataSpace_Standard", 6), ("transfer", "DataSpace_Transfer", 5),
			("range", "DataSpace_Range", 3), ("_", "_", 2),
		],
		"constants": ("android/hardware/DataSpace", "*"),
		"strip":     "DATASPACE_",
	},
	"Spanned_SpanFlags": {
		"backing": "i32",
		"enums": {
			"Spanned_SpanPoint": {"NONE": 0, "MARK": 1, "POINT": 2, "PARAGRAPH": 3},
		},
		"fields": [
			("end", "Spanned_SpanPoint", 2), ("_", "_", 2), ("start", "Spanned_SpanPoint", 2), ("_", "_", 2),
			("composing", "bool", 1), ("intermediate", "bool", 1), ("_", "_", 6), ("priority", "u8", 8), ("user", "u8", 8),
		],
		"constants": ("android/text/Spanned", ["SPAN_*", "!SPAN_*_SHIFT"]),
	},
	"PowerManager_WakeLockLevelAndFlags": {
		"backing": "i32",
		"enums": {
			"PowerManager_WakeLockLevel": {"PARTIAL": 0x1, "SCREEN_DIM": 0x6, "SCREEN_BRIGHT": 0xa, "FULL": 0x1a, "PROXIMITY_SCREEN_OFF": 0x20},
		},
		"fields": [
			("level", "PowerManager_WakeLockLevel", 16), ("_", "_", 12),
			("acquire_causes_wakeup", "bool", 1), ("on_after_release", "bool", 1), ("_", "_", 2),
		],
		"constants": ("android/os/PowerManager", ["*_WAKE_LOCK", "ACQUIRE_CAUSES_WAKEUP", "ON_AFTER_RELEASE"]),
	},
	# The same bits as the NDK's AHardwareBuffer_UsageFlags, which Java names fewer of.
	"HardwareBuffer_Usage": {
		"backing": "i64",
		"enums": {
			"HardwareBuffer_CpuUsage": {"NEVER": 0, "RARELY": 2, "OFTEN": 3},
		},
		"fields": [
			("cpu_read", "HardwareBuffer_CpuUsage", 4), ("cpu_write", "HardwareBuffer_CpuUsage", 4),
			("gpu_sampled_image", "bool", 1), ("gpu_color_output", "bool", 1), ("_", "_", 1), ("composer_overlay", "bool", 1),
			("_", "_", 2), ("protected_content", "bool", 1), ("_", "_", 1), ("video_encode", "bool", 1), ("_", "_", 6),
			("sensor_direct_data", "bool", 1), ("gpu_data_buffer", "bool", 1), ("gpu_cube_map", "bool", 1),
			("gpu_mipmap_complete", "bool", 1), ("_", "_", 5), ("front_buffer", "bool", 1), ("_", "_", 31),
		],
		"constants": ("android/hardware/HardwareBuffer", "USAGE_"),
	},
	"MotionEvent_PackedAction": {
		"backing": "i32",
		"enums": {},
		"fields": [("action", "MotionEvent_Action", 8), ("pointer_index", "u8", 8), ("_", "_", 16)],
		# The deprecated ACTION_POINTER_2_DOWN and the like are packed actions, and ACTION_POINTER_ID_MASK is
		# ACTION_POINTER_INDEX_MASK's old name.
		"constants": ("android/view/MotionEvent", ["ACTION_POINTER_1_*", "ACTION_POINTER_2_*", "ACTION_POINTER_3_*",
			"ACTION_MASK", "ACTION_POINTER_INDEX_MASK", "ACTION_POINTER_ID_MASK"]),
		"strip":     "ACTION_",
	},
	"PermissionInfo_ProtectionLevel": {
		"backing": "i32",
		"enums": {
			"PermissionInfo_Protection": {"NORMAL": 0, "DANGEROUS": 1, "SIGNATURE": 2, "SIGNATURE_OR_SYSTEM": 3, "INTERNAL": 4},
		},
		"fields": [
			("base", "PermissionInfo_Protection", 4), ("privileged", "bool", 1), ("development", "bool", 1), ("appop", "bool", 1),
			("pre23", "bool", 1), ("installer", "bool", 1), ("verifier", "bool", 1), ("preinstalled", "bool", 1),
			("setup", "bool", 1), ("instant", "bool", 1), ("runtime_only", "bool", 1), ("_", "_", 18),
		],
		# PROTECTION_MASK_FLAGS also covers the two bits above the flags, which are padding here.
		"constants": ("android/content/pm/PermissionInfo", ["PROTECTION_*", "!PROTECTION_MASK_FLAGS"]),
	},
}

KEY_EVENT = "android/view/KeyEvent"
MOTION_EVENT = "android/view/MotionEvent"
INPUT_CLASSES = (
	"android/view/InputDevice", "android/view/InputDevice$MotionRange", "android/view/InputDevice$ViewBehavior",
	"android/view/InputEvent", KEY_EVENT, MOTION_EVENT, "android/view/VerifiedInputEvent", "android/view/MotionPredictor",
	"android/view/ScrollFeedbackProvider", "android/view/ViewConfiguration",
)
AXIS_CLASSES = INPUT_CLASSES + ("android/view/MotionEvent$PointerCoords",)
INPUT_CONNECTIONS = (
	"android/view/inputmethod/InputConnection", "android/view/inputmethod/BaseInputConnection",
	"android/view/inputmethod/InputConnectionWrapper",
)
LAYOUT_PARAMS = "android/view/WindowManager$LayoutParams"

# Slots: (classes, member, slot, type)
#   classes: a binary class name, a tuple of them, or "*" for every bound class
#   member:  a method or field name, "<init>" for constructors, a tuple, or "*"
#   slot:    a parameter name, "result", or "field" (a tuple matches any)
#   type:    a NEW_TYPES name, or "@<class>.<CONSTANT>" for the @IntDef group holding that constant
SLOTS = [
	# Key events
	("*", "*", ("keyCode", "keycode"), "KeyEvent_KeyCode"),
	(KEY_EVENT, "<init>", "code", "KeyEvent_KeyCode"),
	((KEY_EVENT, "android/view/VerifiedKeyEvent", "android/view/KeyboardShortcutInfo"), ("getKeyCode", "getKeycode", "keyCodeFromString"), "result", "KeyEvent_KeyCode"),
	("android/view/InputDevice", "getKeyCodeForKeyLocation", ("locationKeyCode", "result"), "KeyEvent_KeyCode"),
	(KEY_EVENT, ("<init>", "changeAction"), "action", "KeyEvent_Action"),
	(KEY_EVENT, "getAction", "result", "KeyEvent_Action"),
	("*", "*", "metaState", "KeyEvent_MetaState"),
	(KEY_EVENT, "metaStateHasModifiers", "modifiers", "KeyEvent_MetaState"),
	(KEY_EVENT, ("getMetaState", "getModifiers", "normalizeMetaState", "getModifierMetaStateMask"), "result", "KeyEvent_MetaState"),
	(KEY_EVENT, "hasModifiers", "modifiers", "KeyEvent_MetaState"),
	(("android/view/VerifiedKeyEvent", "android/view/VerifiedMotionEvent", MOTION_EVENT), "getMetaState", "result", "KeyEvent_MetaState"),
	("android/view/KeyboardShortcutInfo", "<init>", "modifiers", "KeyEvent_MetaState"),
	("android/view/KeyboardShortcutInfo", "getModifiers", "result", "KeyEvent_MetaState"),
	("android/view/MenuItem", ("setAlphabeticShortcut", "setNumericShortcut", "setShortcut"), ("alphaModifiers", "numericModifiers"), "KeyEvent_MetaState"),
	("android/view/MenuItem", ("getAlphabeticModifiers", "getNumericModifiers"), "result", "KeyEvent_MetaState"),
	(INPUT_CONNECTIONS, "clearMetaKeyStates", "states", "KeyEvent_MetaState"),
	(KEY_EVENT, ("<init>", "changeFlags"), "flags", "KeyEvent_Flags"),
	(KEY_EVENT, "changeTimeRepeat", "newFlags", "KeyEvent_Flags"),
	(KEY_EVENT, "getFlags", "result", "KeyEvent_Flags"),
	("android/view/VerifiedKeyEvent", "getFlag", "flag", "KeyEvent_Flags"),
	("android/view/KeyCharacterMap", "getKeyboardType", "result", "KeyCharacterMap_KeyboardType"),
	("android/view/KeyCharacterMap", "getModifierBehavior", "result", "KeyCharacterMap_ModifierBehavior"),

	# Motion events
	(MOTION_EVENT, "getActionMasked", "result", "MotionEvent_Action"),
	(AXIS_CLASSES, "*", "axis", "@android/view/MotionEvent.AXIS_X"),
	(MOTION_EVENT, ("axisToString",), "axis", "@android/view/MotionEvent.AXIS_X"),
	((MOTION_EVENT, "android/view/InputDevice$MotionRange"), ("axisFromString", "getAxis"), "result", "@android/view/MotionEvent.AXIS_X"),
	((MOTION_EVENT, "android/view/VerifiedMotionEvent"), ("getButtonState", "getActionButton"), "result", "MotionEvent_Buttons"),
	(MOTION_EVENT, ("isButtonPressed", "obtain"), ("button", "buttonState"), "MotionEvent_Buttons"),
	(MOTION_EVENT, "getEdgeFlags", "result", "MotionEvent_EdgeFlags"),
	(MOTION_EVENT, "obtain", "edgeFlags", "MotionEvent_EdgeFlags"),
	(MOTION_EVENT, "setEdgeFlags", "flags", "MotionEvent_EdgeFlags"),
	(MOTION_EVENT, "obtain", "flags", "MotionEvent_Flags"),
	(MOTION_EVENT, "getFlags", "result", "MotionEvent_Flags"),
	("android/view/VerifiedMotionEvent", "getFlag", "flag", "MotionEvent_Flags"),

	# Input sources and devices
	(INPUT_CLASSES, "*", "source", "InputDevice_Sources"),
	(INPUT_CLASSES, ("getSource", "getSources"), "result", "InputDevice_Sources"),
	("android/view/InputDevice", "getKeyboardType", "result", "InputDevice_KeyboardType"),
	("android/view/DragEvent", "getAction", "result", "DragEvent_Action"),

	# Windows
	("android/view/Window", ("addFlags", "clearFlags", "setFlags"), ("flags", "mask"), "@android/view/WindowManager$LayoutParams.FLAG_KEEP_SCREEN_ON"),
	(LAYOUT_PARAMS, ("<init>", "mayUseInputMethod"), ("_flags", "flags"), "@android/view/WindowManager$LayoutParams.FLAG_KEEP_SCREEN_ON"),
	(LAYOUT_PARAMS, "<init>", "_type", "@android/view/WindowManager$LayoutParams.TYPE_APPLICATION"),
	("android/view/Window", "setType", "type", "@android/view/WindowManager$LayoutParams.TYPE_APPLICATION"),
	(("android/widget/PopupWindow", "android/widget/ListPopupWindow"), ("setWindowLayoutType", "getWindowLayoutType"), ("layoutType", "result"), "@android/view/WindowManager$LayoutParams.TYPE_APPLICATION"),
	(LAYOUT_PARAMS, "<init>", "_format", "PixelFormat_Format"),
	(LAYOUT_PARAMS, "format", "field", "PixelFormat_Format"),
	(("android/view/Window", "android/view/SurfaceHolder"), "setFormat", "format", "PixelFormat_Format"),
	("android/view/Display", "getPixelFormat", "result", "PixelFormat_Format"),
	(LAYOUT_PARAMS, "rotationAnimation", "field", "WindowManager_LayoutParams_RotationAnimation"),
	("*", "*", ("featureId", "feature"), "Window_Feature"),
	("android/view/Window", "setUiOptions", "uiOptions", "ActivityInfo_UiOptions"),
	(("android/content/pm/ActivityInfo", "android/content/pm/ApplicationInfo"), "uiOptions", "field", "ActivityInfo_UiOptions"),
	("android/view/SurfaceHolder", "setType", "type", "SurfaceHolder_Type"),
	("android/view/Display", "getFlags", "result", "Display_Flags"),

	# Views
	(("android/app/Activity", "android/app/Dialog", "android/view/View", "android/view/ViewGroup", "android/view/ViewParent", "android/view/Window$Callback"),
		("startActionMode", "onWindowStartingActionMode", "startActionModeForChild"), "type", "ActionMode_Type"),
	("android/view/ActionMode", ("getType", "setType"), ("result", "type"), "ActionMode_Type"),
	(("android/view/View", "android/view/ViewGroup", "android/view/View$OnSystemUiVisibilityChangeListener"),
		("setSystemUiVisibility", "dispatchSystemUiVisibilityChanged", "onWindowSystemUiVisibilityChanged",
		 "dispatchWindowSystemUiVisiblityChanged", "onSystemUiVisibilityChange"), ("visibility", "visible"), "View_SystemUiFlags"),
	("android/view/View", ("getSystemUiVisibility", "getWindowSystemUiVisibility"), "result", "View_SystemUiFlags"),
	("android/view/View", ("setImportantForAccessibility", "getImportantForAccessibility"), ("mode", "result"), "View_ImportantForAccessibility"),
	("android/view/View", ("setAccessibilityLiveRegion", "getAccessibilityLiveRegion"), ("mode", "result"), "View_AccessibilityLiveRegion"),
	("android/view/View", ("setOverScrollMode", "getOverScrollMode"), ("overScrollMode", "result"), "View_OverScrollMode"),
	(("android/view/View", "android/view/ViewParent"), ("setTextDirection", "getTextDirection"), ("textDirection", "result"), "View_TextDirection"),
	("android/view/ViewParent", "getTextAlignment", "result", "@android/view/View.TEXT_ALIGNMENT_CENTER"),
	("android/view/View", ("startDrag", "startDragAndDrop"), "flags", "View_DragFlags"),
	(("android/view/View", "android/widget/TextView"), "onScreenStateChanged", "screenState", "View_ScreenState"),
	("android/view/ViewGroup", ("setLayoutMode", "getLayoutMode"), ("layoutMode", "result"), "ViewGroup_LayoutMode"),
	("android/view/View", "performHapticFeedback", "feedbackConstant", "HapticFeedbackConstants_Feedback"),
	("android/view/View", "performHapticFeedback", "flags", "HapticFeedbackConstants_Flags"),
	("android/view/View", "onProvideAutofillVirtualStructure", "flags", "@android/view/View.AUTOFILL_FLAG_INCLUDE_NOT_IMPORTANT_VIEWS"),
	("android/view/ViewStructure", "setVisibility", "visibility", "@android/view/View.VISIBLE"),
	(("android/view/View", "android/view/ViewGroup", "android/view/ViewParent", "android/view/FocusFinder",
	  "android/widget/SearchView", "android/widget/ScrollView", "android/widget/HorizontalScrollView"),
		("requestFocus", "focusSearch", "findNextFocus", "findNextFocusFromRect", "findNearestTouchable",
		 "addKeyboardNavigationClusters", "keyboardNavigationClusterSearch", "arrowScroll", "fullScroll", "pageScroll"),
		"direction", "@android/view/View.FOCUS_DOWN"),
	(("android/view/ViewGroup$MarginLayoutParams", "android/view/ViewGroup$LayoutParams", "android/widget/RelativeLayout$LayoutParams",
	  "android/view/Gravity"), ("setLayoutDirection", "resolveLayoutDirection", "getAbsoluteGravity", "apply", "applyDisplay"),
		"layoutDirection", "@android/view/View.LAYOUT_DIRECTION_LTR"),
	(("android/view/ViewGroup$MarginLayoutParams", "android/view/ViewParent", "android/content/res/Configuration", "android/text/TextUtils"),
		("getLayoutDirection", "getLayoutDirectionFromLocale"), "result", "@android/view/View.LAYOUT_DIRECTION_LTR"),
	("android/view/SoundEffectConstants", "getContantForFocusDirection", "result", "@android/view/SoundEffectConstants.NAVIGATION_DOWN"),
	("android/view/PointerIcon", "getSystemIcon", "type", "PointerIcon_Type"),

	# Menus
	(("android/view/Menu", "android/view/Window", "android/app/Instrumentation"),
		("performIdentifierAction", "performShortcut", "addIntentOptions", "performContextMenuIdentifierAction",
		 "performPanelIdentifierAction", "performPanelShortcut", "invokeMenuActionSync", "invokeContextMenuAction"),
		("flags", "flag"), "Menu_Flags"),
	("android/view/MenuItem", ("setShowAsAction", "setShowAsActionFlags"), "actionEnum", "MenuItem_ShowAsAction"),

	# Text input
	(INPUT_CONNECTIONS, ("getTextBeforeCursor", "getTextAfterCursor", "getSelectedText"), "flags", "@android/view/inputmethod/InputConnection.GET_TEXT_WITH_STYLES"),
	("android/view/inputmethod/ExtractedTextRequest", "flags", "field", "@android/view/inputmethod/InputConnection.GET_TEXT_WITH_STYLES"),
	(INPUT_CONNECTIONS, "getExtractedText", "flags", "InputConnection_GetExtractedTextFlags"),
	(INPUT_CONNECTIONS, "requestCursorUpdates", "cursorUpdateMode", "@android/view/inputmethod/InputConnection.CURSOR_UPDATE_IMMEDIATE"),
	(INPUT_CONNECTIONS, "commitContent", "flags", "InputConnection_InputContentFlags"),
	(INPUT_CONNECTIONS + ("android/text/TextUtils",), ("getCursorCapsMode", "getCapsMode"), ("reqModes", "result"), "TextUtils_CapMode"),
	("android/view/inputmethod/EditorInfo", "initialCapsMode", "field", "TextUtils_CapMode"),
	("android/view/inputmethod/TextSnapshot", ("<init>", "getCursorCapsMode"), ("cursorCapsMode", "result"), "TextUtils_CapMode"),
	("android/view/inputmethod/InputMethod", "showSoftInput", "flags", "InputMethod_ShowFlags"),
	("android/view/inputmethod/CursorAnchorInfo", ("getCharacterBoundsFlags", "getInsertionMarkerFlags"), "result", "CursorAnchorInfo_Flags"),
	("android/view/inputmethod/CursorAnchorInfo$Builder", ("addCharacterBounds", "setInsertionMarkerLocation"), "flags", "CursorAnchorInfo_Flags"),
	("android/view/inputmethod/ExtractedText", "flags", "field", "ExtractedText_Flags"),
	("*", "getParagraphDirection", "result", "Layout_Direction"),
	("android/text/Html", "fromHtml", "flags", "Html_FromHtmlFlags"),
	("android/text/Html", "toHtml", "option", "Html_ToHtmlOption"),
	(("android/widget/TextView", "android/widget/RemoteViews", "android/util/TypedValue"),
		("setTextSize", "getTextSizeUnit", "setTextViewTextSize", "setAutoSizeTextTypeUniformWithConfiguration",
		 "setAutoSizeTextTypeUniformWithPresetSizes", "getComplexUnit"), ("unit", "units", "result"), "@android/util/TypedValue.COMPLEX_UNIT_PX"),
	(("android/widget/TextView", "android/graphics/Paint", "android/text/TextPaint"), ("setPaintFlags", "getPaintFlags", "<init>"), ("flags", "result"), "@android/graphics/Paint.ANTI_ALIAS_FLAG"),
	("android/graphics/Paint", "setHinting", "mode", "Paint_Hinting"),
	("android/widget/Switch", "setSwitchTypeface", "style", "@android/graphics/Typeface.BOLD"),

	# Widgets
	("android/widget/AbsListView", ("setChoiceMode", "getChoiceMode"), ("choiceMode", "result"), "AbsListView_ChoiceMode"),
	("android/widget/AbsListView", ("setTranscriptMode", "getTranscriptMode"), ("mode", "result"), "AbsListView_TranscriptMode"),
	("android/widget/AbsListView$OnScrollListener", "onScrollStateChanged", "scrollState", "AbsListView_OnScrollListener_ScrollState"),
	("android/widget/ListPopupWindow", ("setInputMethodMode", "getInputMethodMode"), ("mode", "result"), "@android/widget/ListPopupWindow.INPUT_METHOD_NEEDED"),
	("android/widget/PopupWindow", ("setInputMethodMode", "getInputMethodMode"), ("mode", "result"), "PopupWindow_InputMethodMode"),
	("android/widget/Spinner", "<init>", "mode", "Spinner_Mode"),
	(("android/widget/CursorAdapter", "android/widget/SimpleCursorAdapter", "android/widget/ResourceCursorAdapter"), "<init>", "flags", "CursorAdapter_Flags"),
	("android/widget/ExpandableListView", "getPackedPositionType", "result", "ExpandableListView_PackedPositionType"),
	("android/app/AlertDialog", ("getButton", "setButton"), "whichButton", "DialogInterface_Button"),

	# Activities, fragments, and the app framework
	("android/app/Activity", "getChangingConfigurations", "result", "@android/content/pm/ActivityInfo.CONFIG_ORIENTATION"),
	("android/content/pm/ActivityInfo", "configChanges", "field", "@android/content/pm/ActivityInfo.CONFIG_ORIENTATION"),
	(("android/content/Context", "android/content/ContextWrapper", "android/app/Activity", "android/app/Fragment", "android/app/FragmentHostCallback"),
		("startIntentSender", "startIntentSenderForResult", "startIntentSenderFromChild", "onStartIntentSenderFromFragment"),
		("flagsMask", "flagsValues", "extraFlags"), "@android/content/Intent.FLAG_ACTIVITY_NEW_TASK"),
	(("android/content/Context", "android/content/ContextWrapper"), ("bindService", "bindIsolatedService", "bindServiceAsUser"), "flags", "@android/content/Context.BIND_AUTO_CREATE"),
	("android/app/ActionBar", "getDisplayOptions", "result", "@android/app/ActionBar.DISPLAY_HOME_AS_UP"),
	("android/app/ActivityManager", "getLockTaskModeState", "result", "ActivityManager_LockTaskMode"),
	("android/app/ActivityManager", "getRecentTasks", "flags", "ActivityManager_RecentFlags"),
	("android/app/ActivityManager$RunningServiceInfo", "flags", "field", "ActivityManager_RunningServiceInfo_Flags"),
	("android/app/ActivityManager$RunningAppProcessInfo", "importanceReasonCode", "field", "ActivityManager_RunningAppProcessInfo_Reason"),
	("android/app/ActivityManager$RunningAppProcessInfo", "lastTrimLevel", "field", "@android/content/ComponentCallbacks2.TRIM_MEMORY_COMPLETE"),
	("android/app/FragmentController", "dispatchTrimMemory", "level", "@android/content/ComponentCallbacks2.TRIM_MEMORY_COMPLETE"),
	("android/app/AppOpsManager", ("checkOp", "checkOpNoThrow", "noteOp", "noteOpNoThrow", "noteProxyOp", "noteProxyOpNoThrow",
		"startOp", "startOpNoThrow", "startProxyOp", "startProxyOpNoThrow", "unsafeCheckOp", "unsafeCheckOpNoThrow",
		"unsafeCheckOpRaw", "unsafeCheckOpRawNoThrow"), "result", "AppOpsManager_Mode"),
	("android/app/AppOpsManager", "startWatchingMode", "flags", "AppOpsManager_WatchFlags"),
	("android/app/ApplicationErrorReport", "type", "field", "ApplicationErrorReport_Type"),
	("android/app/ApplicationErrorReport", "getErrorReportReceiver", "appFlags", "ApplicationInfo_Flags"),
	("android/app/AutomaticZenRule", ("<init>", "getInterruptionFilter"), ("interruptionFilter", "result"), "@android/app/NotificationManager.INTERRUPTION_FILTER_ALL"),
	("android/app/DialogFragment", "setStyle", "style", "DialogFragment_Style"),
	("android/app/DownloadManager$Request", "setNotificationVisibility", "visibility", "DownloadManager_Request_Visibility"),
	("android/app/DownloadManager$Request", "setAllowedNetworkTypes", "flags", "DownloadManager_Request_NetworkFlags"),
	("android/app/DownloadManager$Query", "setFilterByStatus", "flags", "DownloadManager_Statuses"),
	(("android/app/FragmentManager", "android/app/FragmentBreadCrumbs$OnBreadCrumbClickListener"), ("popBackStack", "popBackStackImmediate", "onBreadCrumbClick"), "flags", "FragmentManager_PopFlags"),
	("android/app/Notification", "flags", "field", "@android/app/Notification.FLAG_AUTO_CANCEL"),
	("android/app/Notification", "defaults", "field", "Notification_Defaults"),
	("android/app/Notification$Builder", "setDefaults", "defaults", "Notification_Defaults"),
	("android/app/Notification", "getBadgeIconType", "result", "Notification_BadgeIconType"),
	("android/app/Notification$Builder", "setBadgeIconType", "icon", "Notification_BadgeIconType"),
	("android/app/NotificationChannel", ("getLockscreenVisibility", "setLockscreenVisibility"), ("result", "lockscreenVisibility"), "@android/app/Notification.VISIBILITY_PUBLIC"),
	("android/app/NotificationManager$Policy", ("priorityCategories", "<init>", "priorityCategoriesToString"), ("field", "priorityCategories"), "NotificationManager_Policy_PriorityCategories"),
	("android/app/NotificationManager$Policy", ("suppressedVisualEffects", "<init>", "suppressedEffectsToString"), ("field", "suppressedVisualEffects", "effects"), "NotificationManager_Policy_SuppressedEffects"),
	("android/app/NotificationManager$Policy", ("<init>", "prioritySendersToString"), ("priorityCallSenders", "priorityMessageSenders", "prioritySenders"), "@android/app/NotificationManager$Policy.PRIORITY_SENDERS_ANY"),
	("android/app/ProgressDialog", "setProgressStyle", "style", "ProgressDialog_Style"),
	("android/app/UiAutomation", "setRotation", "rotation", "UiAutomation_Rotation"),
	("android/app/UiModeManager", "enableCarMode", "flags", "UiModeManager_EnableCarModeFlags"),
	("android/app/UiModeManager", "getCurrentModeType", "result", "Configuration_UiModeType"),
	(("android/app/WallpaperManager", "android/app/WallpaperManager$OnColorsChangedListener"), ("getWallpaperColors", "onColorsChanged"), "which", "@android/app/WallpaperManager.FLAG_SYSTEM"),

	# Content, packages, and resources
	("android/content/SyncStatusObserver", "onStatusChanged", "which", "ContentResolver_SyncObserverType"),
	("android/content/RestrictionEntry", ("<init>", "getType", "setType"), ("type", "result"), "RestrictionEntry_Type"),
	(("android/content/IntentFilter", "android/os/PatternMatcher", "android/content/pm/PathPermission"),
		("addDataPath", "addDataSchemeSpecificPart", "<init>", "getType"), ("type", "result"), "@android/os/PatternMatcher.PATTERN_LITERAL"),
	("android/content/pm/ActivityInfo", "flags", "field", "ActivityInfo_Flags"),
	("android/content/pm/ActivityInfo", "documentLaunchMode", "field", "ActivityInfo_DocumentLaunchMode"),
	("android/content/pm/ActivityInfo", "persistableMode", "field", "ActivityInfo_PersistableMode"),
	("android/content/pm/ApplicationInfo", "flags", "field", "ApplicationInfo_Flags"),
	("android/content/pm/ServiceInfo", "flags", "field", "ServiceInfo_Flags"),
	("android/content/pm/ProviderInfo", "flags", "field", "ProviderInfo_Flags"),
	("android/content/pm/FeatureInfo", "flags", "field", "FeatureInfo_Flags"),
	("android/content/pm/ConfigurationInfo", "reqInputFeatures", "field", "ConfigurationInfo_InputFeatures"),
	("android/content/pm/ConfigurationInfo", "reqKeyboardType", "field", "Configuration_Keyboard"),
	("android/content/pm/ConfigurationInfo", "reqNavigation", "field", "Configuration_Navigation"),
	("android/content/pm/ConfigurationInfo", "reqTouchScreen", "field", "Configuration_Touchscreen"),
	("android/content/pm/PackageManager", ("getActivityInfo", "getApplicationInfo", "getInstalledApplications", "getInstalledPackages",
		"getPackageArchiveInfo", "getPackageGids", "getPackageInfo", "getPackageUid", "getPackagesHoldingPermissions",
		"getPreferredPackages", "getProviderInfo", "getReceiverInfo", "getServiceInfo", "getSharedLibraries",
		"queryBroadcastReceivers", "queryContentProviders", "queryIntentActivities", "queryIntentActivityOptions",
		"queryIntentContentProviders", "queryIntentServices", "resolveActivity", "resolveContentProvider", "resolveService"),
		"flags", "PackageManager_InfoFlags"),
	# Their @LongDefs, ComponentInfoFlags' and ApplicationInfoFlags', have bits an int cannot hold, so they do not type them.
	(("android/content/Intent", "android/content/pm/LauncherApps"), ("resolveActivityInfo", "getApplicationInfo"), "flags", "PackageManager_InfoFlags"),
	("android/content/pm/PackageManager", "verifyPendingInstall", "verificationCode", "PackageManager_Verification"),
	("android/content/pm/PackageInstaller$SessionParams", "<init>", "mode", "PackageInstaller_SessionParams_Mode"),
	("android/content/pm/PackageInstaller$SessionInfo", "getMode", "result", "PackageInstaller_SessionParams_Mode"),
	("android/content/pm/PackageInstaller$SessionInfo", "getStagedSessionErrorCode", "result", "PackageInstaller_SessionInfo_SessionError"),
	("android/content/res/Configuration", "keyboard", "field", "Configuration_Keyboard"),
	("android/content/res/Configuration", "keyboardHidden", "field", "Configuration_KeyboardHidden"),
	("android/content/res/Configuration", "hardKeyboardHidden", "field", "Configuration_HardKeyboardHidden"),
	("android/content/res/Configuration", "navigation", "field", "Configuration_Navigation"),
	("android/content/res/Configuration", "navigationHidden", "field", "Configuration_NavigationHidden"),
	("android/content/res/Configuration", "touchscreen", "field", "Configuration_Touchscreen"),
	("android/content/res/AssetManager", "open", "accessMode", "AssetManager_Access"),
	("android/content/res/ObbInfo", "flags", "field", "ObbInfo_Flags"),
	(("android/content/res/TypedArray", "android/util/TypedValue"), ("getType", "type", "coerceToString"), ("result", "field", "type"), "TypedValue_Type"),
	(("android/content/res/Resources$Theme", "android/util/LogPrinter"), ("dump", "<init>"), "priority", "@android/util/Log.DEBUG"),

	# Graphics, hardware, network, and OS
	(("android/hardware/Camera$Parameters", "android/graphics/YuvImage", "android/graphics/ImageFormat"),
		("setPictureFormat", "setPreviewFormat", "<init>", "getBitsPerPixel"), ("pixel_format", "format"), "ImageFormat_Format"),
	(("android/hardware/Camera$Parameters", "android/graphics/YuvImage"), ("getPictureFormat", "getPreviewFormat", "getYuvFormat"), "result", "ImageFormat_Format"),
	("android/hardware/Camera$CameraInfo", "facing", "field", "Camera_CameraInfo_Facing"),
	("android/hardware/HardwareBuffer", "getUsage", "result", "HardwareBuffer_Usage"),
	("android/graphics/PathMeasure", "getMatrix", "flags", "PathMeasure_MatrixFlags"),
	("android/hardware/Sensor", "getType", "result", "Sensor_Type"),
	("android/hardware/SensorManager", ("getDefaultSensor", "getSensorList", "getDynamicSensorList"), "type", "Sensor_Type"),
	("android/hardware/Sensor", "getReportingMode", "result", "Sensor_ReportingMode"),
	("android/hardware/SensorAdditionalInfo", "type", "field", "SensorAdditionalInfo_Type"),
	("android/hardware/SensorManager", "remapCoordinateSystem", ("X", "Y"), "SensorManager_Axis"),
	("android/net/ConnectivityManager", ("getNetworkInfo", "isNetworkTypeValid"), "networkType", "ConnectivityManager_Type"),
	("android/net/NetworkInfo", ("<init>", "getType"), ("type", "result"), "ConnectivityManager_Type"),
	("android/net/LocalSocket", "<init>", "sockType", "LocalSocket_Type"),
	("android/os/Debug", "startMethodTracing", "flags", "Debug_TraceFlags"),
	("android/os/Debug", "printLoadedClasses", "flags", "Debug_ShowFlags"),
	(("android/os/IBinder", "android/os/Binder"), "transact", "flags", "IBinder_Flags"),
	("android/os/Parcel", "*", ("parcelableFlags", "flags"), "@android/os/Parcelable.PARCELABLE_WRITE_RETURN_VALUE"),
	("android/os/ParcelFileDescriptor", ("open", "parseMode"), ("mode", "result"), "ParcelFileDescriptor_Mode"),
	(("android/os/PowerManager", "android/os/PowerManager$OnThermalStatusChangedListener"), ("getCurrentThermalStatus", "onThermalStatusChanged"), ("result", "status"), "PowerManager_ThermalStatus"),
	("android/os/PowerManager$WakeLock", "release", "flags", "PowerManager_ReleaseFlags"),
	("android/os/FileObserver", "onEvent", "event", "FileObserver_Events"),
	("android/os/BatteryManager", ("getIntProperty", "getLongProperty"), "id", "BatteryManager_Property"),
	("android/os/ProfilingResult", "getTriggerType", "result", "@android/os/ProfilingTrigger.TRIGGER_TYPE_ANR"),
	("android/net/TetheringInterface", "getType", "result", "@android/net/TetheringManager.TETHERING_WIFI"),
	(("android/util/Base64", "android/util/Base64InputStream", "android/util/Base64OutputStream"), "*", "flags", "android_util_Base64_Flags"),

	# bit_fields
	("*", "*", ("gravity", "horizontalGravity", "verticalGravity", "foregroundGravity", "contentIconGravity"), "Gravity_Field"),
	("*", "gravity", "field", "Gravity_Field"),
	("*", ("getGravity", "getForegroundGravity", "getContentIconGravity", "getAbsoluteGravity"), "result", "Gravity_Field"),
	(("android/view/Window", "android/widget/ListPopupWindow", "android/widget/PopupWindow"), ("setSoftInputMode", "getSoftInputMode"),
		("mode", "result"), "WindowManager_LayoutParams_SoftInputMode"),
	("android/view/inputmethod/EditorInfo", "imeOptions", "field", "EditorInfo_ImeOptions"),
	(("android/widget/TextView", "android/widget/SearchView", "android/app/SearchableInfo"), ("setImeOptions", "getImeOptions"),
		("imeOptions", "result"), "EditorInfo_ImeOptions"),
	("android/content/res/Configuration", "uiMode", "field", "Configuration_UiMode"),
	("android/content/res/Configuration", "screenLayout", "field", "Configuration_ScreenLayout"),
	("android/content/res/Configuration", "colorMode", "field", "Configuration_ColorMode"),
	(("android/text/Spannable", "android/text/SpannableString", "android/text/SpannableStringBuilder", "android/text/PrecomputedText",
	  "android/text/Spanned", "android/text/SpannedString"), ("setSpan", "getSpanFlags", "append"), ("flags", "result"), "Spanned_SpanFlags"),
	("android/os/PowerManager", "newWakeLock", "levelAndFlags", "PowerManager_WakeLockLevelAndFlags"),
	("android/os/PowerManager", "isWakeLockLevelSupported", "level", "PowerManager_WakeLockLevel"),
	(MOTION_EVENT, "getAction", "result", "MotionEvent_PackedAction"),
	(MOTION_EVENT, ("setAction", "obtain", "actionToString"), "action", "MotionEvent_PackedAction"),
	("android/content/pm/PermissionInfo", "protectionLevel", "field", "PermissionInfo_ProtectionLevel"),
	("android/content/pm/PermissionInfo", "getProtection", "result", "PermissionInfo_Protection"),
]

# Candidates that stay raw, by reason. For the record: nothing reads this.
RAW = {
	"Fields whose meaning depends on another field": [
		"input type (TextView/SearchView/SearchableInfo/EditorInfo/ViewStructure): the variation and flag bits mean different "
		"things for each class, so only the class could be an enum",
	],
	"A size and state bits packed together, which was not among the bit_field cases you approved": [
		"View measured states (getMeasuredState, resolveSizeAndState, combineMeasuredStates)",
	],
	"The app's own values": [
		"request and result codes, Handler/Message `what`, Binder.transact `code`, UriMatcher codes, Adapter view types",
		"IME action IDs (onEditorAction, performEditorAction, setImeActionLabel), which may be custom",
		"ApplicationExitInfo.getStatus (an exit status or signal number)",
	],
	"Always 0, or reserved": [
		"InputMethod.hideSoftInput(flags), Binder/IBinder linkToDeath and unlinkToDeath(flags), onProvideContentCaptureStructure(flags)",
	],
	"Numbers that have a few named values": [
		"HandlerThread(name, priority): a nice value; Process.THREAD_PRIORITY_* name some of them",
		"IntentFilter priority, Bitmap/Canvas/Resources density, OrientationEventListener.onOrientationChanged (degrees or ORIENTATION_UNKNOWN)",
		"SensorManager.registerListener sampling periods (microseconds or SENSOR_DELAY_*)",
		"Window.getDefaultFeatures (a mask of 1 << feature)",
	],
	"Constants in packages that are not bound": [
		"setVolumeControlStream/getVolumeControlStream, Notification.audioStreamType, Builder.setSound(streamType): android.media.AudioManager",
		"View.sendAccessibilityEvent, performAccessibilityAction, notifySubtreeAccessibilityStateChanged: android.view.accessibility",
		"UiAutomation.performGlobalAction: android.accessibilityservice",
		"NetworkInfo.getSubtype: android.telephony; LinkAddress.getFlags: android.system.OsConstants",
		"MediaRouteButton route types: android.media.MediaRouter",
	],
	"Deprecated, or too rarely used to be worth a type": [
		"DialerFilter modes, UrlQuerySanitizer flags, WindowManager.LayoutParams.memoryType",
	],
}
