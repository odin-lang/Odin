"""
The reviewed table of NDK integer slots that take constants, beyond what the C headers' own types say.

generate.py turns named C enums (`media_status_t`) and typedef'd anonymous enums (`aaudio_format_t`) into Odin
enums by itself. This table adds the rest: new types for anonymous enums and #define families, the kinds of the
named enums that are not plain enums, bit_fields, and the slots each type takes.

Anonymous enums have no C name, so new types are named in the NDK's style from their constants' prefix:
`AKEYCODE_*` is `AKeyCode`, `AMOTION_EVENT_ACTION_*` is `AMotionEventAction`. Members drop the shared prefix
(`.BACK`), and a member that would start with a digit gets `_` (`._12KEY`), or `NUM` on a key code (`.NUM0`).
A bit_set's element enum takes the singular or `Flag`, as in darwin: `AKeyEventFlags` over `AKeyEventFlag`.
Its single bits become elements. A member of no bits or several bits keeps its C name as a typed constant
(`AMETA_NONE :: AMetaState{}`), and so does every named value of a bit_field.
The C constants that become members go; the rest stay.
"""

# New types for anonymous enums and #define families: name -> (kind, members)
#   members: "PREFIX_" for every constant starting with it, or a list of names and "PREFIX_*" patterns,
#            where "!NAME" or "!PREFIX_*" leaves some out. Constants left out stay constants.
NEW_TYPES = {
	# <android/input.h>, <android/keycodes.h>
	"AKeyCode":                    ("enum",    "AKEYCODE_"),
	"AMetaState":                  ("bit_set", "AMETA_"),
	"AInputEventType":             ("enum",    "AINPUT_EVENT_TYPE_"),
	"AKeyEventAction":             ("enum",    "AKEY_EVENT_ACTION_"),
	"AKeyEventFlags":              ("bit_set", "AKEY_EVENT_FLAG_"),
	"AMotionEventAction":          ("enum",    ["AMOTION_EVENT_ACTION_*", "!AMOTION_EVENT_ACTION_MASK",
	                                            "!AMOTION_EVENT_ACTION_POINTER_INDEX_MASK", "!AMOTION_EVENT_ACTION_POINTER_INDEX_SHIFT"]),
	"AMotionEventFlags":           ("bit_set", "AMOTION_EVENT_FLAG_"),
	"AMotionEventEdgeFlags":       ("bit_set", "AMOTION_EVENT_EDGE_FLAG_"),
	"AMotionEventAxis":            ("enum",    "AMOTION_EVENT_AXIS_"),
	"AMotionEventButtons":         ("bit_set", "AMOTION_EVENT_BUTTON_"),
	"AMotionEventToolType":        ("enum",    "AMOTION_EVENT_TOOL_TYPE_"),
	"AInputSources":               ("bit_set", "AINPUT_SOURCE_"),

	# <android/looper.h>, <android/native_activity.h>, <android/window.h>, <android/asset_manager.h>
	"ALooperEvents":               ("bit_set", "ALOOPER_EVENT_"),
	"ALooperPrepareOptions":       ("bit_set", "ALOOPER_PREPARE_"),
	"AWindowFlags":                ("bit_set", "AWINDOW_FLAG_"),
	"ANativeActivityShowSoftInputFlags": ("bit_set", "ANATIVEACTIVITY_SHOW_SOFT_INPUT_"),
	"ANativeActivityHideSoftInputFlags": ("bit_set", "ANATIVEACTIVITY_HIDE_SOFT_INPUT_"),
	"AAssetMode":                  ("enum",    "AASSET_MODE_"),

	# <android/configuration.h>: one anonymous enum of 91 constants, split by prefix
	"AConfigurationOrientation":   ("enum",    "ACONFIGURATION_ORIENTATION_"),
	"AConfigurationTouchscreen":   ("enum",    "ACONFIGURATION_TOUCHSCREEN_"),
	"AConfigurationKeyboard":      ("enum",    "ACONFIGURATION_KEYBOARD_"),
	"AConfigurationNavigation":    ("enum",    "ACONFIGURATION_NAVIGATION_"),
	"AConfigurationKeysHidden":    ("enum",    "ACONFIGURATION_KEYSHIDDEN_"),
	"AConfigurationNavHidden":     ("enum",    "ACONFIGURATION_NAVHIDDEN_"),
	"AConfigurationScreenSize":    ("enum",    "ACONFIGURATION_SCREENSIZE_"),
	"AConfigurationScreenLong":    ("enum",    "ACONFIGURATION_SCREENLONG_"),
	"AConfigurationScreenRound":   ("enum",    "ACONFIGURATION_SCREENROUND_"),
	"AConfigurationWideColorGamut": ("enum",   "ACONFIGURATION_WIDE_COLOR_GAMUT_"),
	"AConfigurationHdr":           ("enum",    "ACONFIGURATION_HDR_"),
	"AConfigurationUiModeType":    ("enum",    "ACONFIGURATION_UI_MODE_TYPE_"),
	"AConfigurationUiModeNight":   ("enum",    "ACONFIGURATION_UI_MODE_NIGHT_"),
	"AConfigurationLayoutDir":     ("enum",    "ACONFIGURATION_LAYOUTDIR_"),
	"AConfigurationGrammaticalGender": ("enum", "ACONFIGURATION_GRAMMATICAL_GENDER_"),
	"AConfigurationChanges":       ("bit_set", ["ACONFIGURATION_MCC", "ACONFIGURATION_MNC", "ACONFIGURATION_LOCALE",
		"ACONFIGURATION_TOUCHSCREEN", "ACONFIGURATION_KEYBOARD", "ACONFIGURATION_NAVIGATION", "ACONFIGURATION_ORIENTATION",
		"ACONFIGURATION_DENSITY", "ACONFIGURATION_SCREEN_SIZE", "ACONFIGURATION_VERSION", "ACONFIGURATION_SCREEN_LAYOUT",
		"ACONFIGURATION_UI_MODE", "ACONFIGURATION_SMALLEST_SCREEN_SIZE", "ACONFIGURATION_LAYOUTDIR",
		"ACONFIGURATION_SCREEN_ROUND", "ACONFIGURATION_COLOR_MODE", "ACONFIGURATION_GRAMMATICAL_GENDER"]),

	# <android/sensor.h>, <android/storage_manager.h>, <android/permission_manager.h>
	"ASensorType":                 ("enum",    "ASENSOR_TYPE_"),
	"ASensorStatus":               ("enum",    "ASENSOR_STATUS_"),
	"AReportingMode":              ("enum",    "AREPORTING_MODE_"),
	"ASensorDirectRate":           ("enum",    "ASENSOR_DIRECT_RATE_"),
	"ASensorDirectChannelType":    ("enum",    "ASENSOR_DIRECT_CHANNEL_TYPE_"),
	"ASensorAdditionalInfoType":   ("enum",    "ASENSOR_ADDITIONAL_INFO_"),
	"AObbState":                   ("enum",    "AOBB_STATE_"),
	"APermissionManagerStatus":    ("enum",    "PERMISSION_MANAGER_STATUS_"),
	"APermissionManagerPermission": ("enum",   "PERMISSION_MANAGER_PERMISSION_"),

	# <android/font.h>, <android/dlext.h>
	"AFamilyVariant":              ("enum",    "AFAMILY_VARIANT_"),
	"AndroidDlextFlags":           ("bit_set", "ANDROID_DLEXT_"),

	# vendor:android/jnigraphics
	"AndroidBitmapResult":         ("enum",    "ANDROID_BITMAP_RESULT_"),
	"AndroidBitmapAlpha":          ("enum",    ["ANDROID_BITMAP_FLAGS_ALPHA_*", "!ANDROID_BITMAP_FLAGS_ALPHA_MASK", "!ANDROID_BITMAP_FLAGS_ALPHA_SHIFT"]),
	"AImageDecoderResult":         ("enum",    ["ANDROID_IMAGE_DECODER_*", "!ANDROID_IMAGE_DECODER_DISPOSE_OP_*",
	                                            "!ANDROID_IMAGE_DECODER_BLEND_OP_*", "!ANDROID_IMAGE_DECODER_INFINITE"]),
	"AImageDecoderDisposeOp":      ("enum",    "ANDROID_IMAGE_DECODER_DISPOSE_OP_"),
	"AImageDecoderBlendOp":        ("enum",    "ANDROID_IMAGE_DECODER_BLEND_OP_"),

	# vendor:android/media, vendor:android/camera
	"AMediaCodecBufferFlags":      ("bit_set", "AMEDIACODEC_BUFFER_FLAG_"),
	"AMediaCodecConfigureFlags":   ("bit_set", "AMEDIACODEC_CONFIGURE_FLAG_"),
	"AMediaExtractorSampleFlags":  ("bit_set", "AMEDIAEXTRACTOR_SAMPLE_FLAG_"),
	"ACameraMetadataType":         ("enum",    "ACAMERA_TYPE_"),
	"ACameraCaptureFailureReason": ("enum",    "CAPTURE_FAILURE_REASON_"),
	"ACameraDeviceError":          ("enum",    ["ERROR_CAMERA_IN_USE", "ERROR_MAX_CAMERAS_IN_USE", "ERROR_CAMERA_DISABLED",
	                                            "ERROR_CAMERA_DEVICE", "ERROR_CAMERA_SERVICE"]),
	"AMidiOpcode":                 ("enum",    "AMIDI_OPCODE_"),
}

# bit_sets whose elements are not their single-bit constants: name -> {element: bit}.
# Every constant of such a type is a typed constant, single bits included.
ELEMENTS = {
	# Each AINPUT_SOURCE_* is a class bit plus a device bit, so the device bits are named after their sources.
	"AInputSources": {
		"CLASS_BUTTON": 0, "CLASS_POINTER": 1, "CLASS_NAVIGATION": 2, "CLASS_POSITION": 3, "CLASS_JOYSTICK": 4,
		"KEYBOARD": 8, "DPAD": 9, "GAMEPAD": 10, "TOUCHSCREEN": 12, "MOUSE": 13, "STYLUS": 14, "BLUETOOTH_STYLUS": 15,
		"TRACKBALL": 16, "MOUSE_RELATIVE": 17, "TOUCHPAD": 20, "TOUCH_NAVIGATION": 21, "ROTARY_ENCODER": 22,
		"JOYSTICK": 24, "HDMI": 25, "SENSOR": 26,
	},
}

# Types whose members that are only digits are keys labelled with that number: `.NUM0`, as in SDL.
NUMBER_KEYS = {"AKeyCode"}

# The prefix members drop, for named C enums where the shared one is wrong: name -> prefix.
# Members without it keep their C names.
PREFIXES = {
	"media_status_t": "AMEDIA_",          # shares none: AMEDIA_OK, AMEDIACODEC_ERROR_RECLAIMED
	"ResNsendFlags":  "ANDROID_RESOLV_",  # every member is a NO_
}

# Named C enums whose values C passes only through narrower integers: name -> Odin backing.
# Their C types are in no signature or record, so their size does not matter.
BACKINGS = {
	"ANativeWindow_FrameRateCompatibility":  "i8",  # ANativeWindow_setFrameRate(int8_t compatibility)
	"ANativeWindow_ChangeFrameRateStrategy": "i8",
	"FeatureLevelCode":                      "i64", # ANeuralNetworksDevice_getFeatureLevel(int64_t* featureLevel)
}

# Named C enums, and typedef'd anonymous ones, that are not plain enums: name -> (kind, element enum name)
NAMED_KINDS = {
	"aaudio_channel_mask_t": ("bit_set", "aaudio_channel_t"),  # AAUDIO_CHANNEL_STEREO and the like become constants
	"ResNsendFlags":         ("bit_set", "ResNsendFlag"),
}

# Integer typedefs right after an anonymous enum that are not that enum's type. They stay integers.
RAW_PAIRS = {
	"aaudio_session_id_t",  # a session ID, or AAUDIO_SESSION_ID_NONE/ALLOCATE
	"transaction_code_t",   # the enum before it is binder_flags_t's FLAG_ONEWAY
}

LOG_FUNCTIONS = ("__android_log_write", "__android_log_print", "__android_log_vprint", "__android_log_buf_write",
	"__android_log_buf_print", "__android_log_is_loggable", "__android_log_is_loggable_len", "__android_log_assert",
	"__android_log_set_minimum_priority")
SET_ENTRY = tuple(f"ACaptureRequest_setEntry{p}_{t}" for p in ("", "_physicalCamera") for t in ("u8", "i32", "float", "i64", "double", "rational"))
IMAGE_DECODER_RESULTS = ("AImageDecoder_createFromAAsset", "AImageDecoder_createFromFd", "AImageDecoder_createFromBuffer",
	"AImageDecoder_setAndroidBitmapFormat", "AImageDecoder_setUnpremultipliedRequired", "AImageDecoder_setDataSpace",
	"AImageDecoder_setTargetSize", "AImageDecoder_computeSampledSize", "AImageDecoder_setCrop", "AImageDecoder_decodeImage",
	"AImageDecoder_advanceFrame", "AImageDecoder_rewind", "AImageDecoder_getFrameInfo")

def config(name, type_):
	"""An AConfiguration getter's result and its setter's value."""
	return ((f"AConfiguration_get{name}", f"AConfiguration_set{name}"), ("result", "*"), type_)

# Slots: (owners, slots, type)
#   owners: a function or callback typedef, "Struct.field", a tuple of them, or a list of patterns ("ANeuralNetworks*", "!name")
#   slots:  a parameter name, "result", "field", "*" for every integer parameter, or a tuple
#   type:   a NEW_TYPES name, or a named C type (`android_LogPriority`, `AHardwareBuffer_Format`)
SLOTS = [
	# Input events
	("AInputEvent_getType", "result", "AInputEventType"),
	("AInputEvent_getSource", "result", "AInputSources"),
	("AKeyEvent_getAction", "result", "AKeyEventAction"),
	("AKeyEvent_getFlags", "result", "AKeyEventFlags"),
	("AKeyEvent_getKeyCode", "result", "AKeyCode"),
	(("AKeyEvent_getMetaState", "AMotionEvent_getMetaState"), "result", "AMetaState"),
	("AMotionEvent_getFlags", "result", "AMotionEventFlags"),
	("AMotionEvent_getEdgeFlags", "result", "AMotionEventEdgeFlags"),
	("AMotionEvent_getAction", "result", "AMotionEventPackedAction"),
	(("AMotionEvent_getButtonState", "AMotionEvent_getActionButton"), "result", "AMotionEventButtons"),
	("AMotionEvent_getToolType", "result", "AMotionEventToolType"),
	(("AMotionEvent_getAxisValue", "AMotionEvent_getHistoricalAxisValue"), "axis", "AMotionEventAxis"),
	("AMotionEvent_getClassification", "result", "AMotionClassification"),

	# Looper, activity, window, assets
	(("ALooper_addFd", "ALooper_callbackFunc"), "events", "ALooperEvents"),
	("ALooper_prepare", "opts", "ALooperPrepareOptions"),
	("ANativeActivity_setWindowFlags", ("addFlags", "removeFlags"), "AWindowFlags"),
	("ANativeActivity_showSoftInput", "flags", "ANativeActivityShowSoftInputFlags"),
	("ANativeActivity_hideSoftInput", "flags", "ANativeActivityHideSoftInputFlags"),
	("AAssetManager_open", "mode", "AAssetMode"),

	# Configuration
	config("Orientation", "AConfigurationOrientation"),
	config("Touchscreen", "AConfigurationTouchscreen"),
	config("Keyboard", "AConfigurationKeyboard"),
	config("Navigation", "AConfigurationNavigation"),
	config("KeysHidden", "AConfigurationKeysHidden"),
	config("NavHidden", "AConfigurationNavHidden"),
	config("ScreenSize", "AConfigurationScreenSize"),
	config("ScreenLong", "AConfigurationScreenLong"),
	config("ScreenRound", "AConfigurationScreenRound"),
	config("UiModeType", "AConfigurationUiModeType"),
	config("UiModeNight", "AConfigurationUiModeNight"),
	config("LayoutDirection", "AConfigurationLayoutDir"),
	config("GrammaticalGender", "AConfigurationGrammaticalGender"),
	("AConfiguration_diff", "result", "AConfigurationChanges"),

	# Sensors, storage, permissions
	(("ASensorManager_getDefaultSensor", "ASensorManager_getDefaultSensorEx"), "type", "ASensorType"),
	("ASensor_getType", "result", "ASensorType"),
	("ASensorEvent.type", "field", "ASensorType"),
	("ASensor_getReportingMode", "result", "AReportingMode"),
	("ASensorManager_configureDirectReport", "rate", "ASensorDirectRate"),
	("ASensor_getHighestDirectReportRateLevel", "result", "ASensorDirectRate"),
	("ASensor_isDirectChannelTypeSupported", "channelType", "ASensorDirectChannelType"),
	("AAdditionalInfoEvent.type", "field", "ASensorAdditionalInfoType"),
	("ASensorVector.status", "field", "ASensorStatus"),
	("AStorageManager_obbCallbackFunc", "state", "AObbState"),
	("APermissionManager_checkPermission", "result", "APermissionManagerStatus"),

	# Logging
	(LOG_FUNCTIONS, ("prio", "priority", "default_prio"), "android_LogPriority"),
	(("__android_log_set_minimum_priority", "__android_log_get_minimum_priority"), "result", "android_LogPriority"),
	("__android_log_message.priority", "field", "android_LogPriority"),
	(("__android_log_buf_write", "__android_log_buf_print"), "log_id", "log_id_t"),
	("__android_log_message.buffer_id", "field", "log_id_t"),

	# Windows, buffers, surfaces
	("ANativeWindow_setBuffersGeometry", "format", "AHardwareBuffer_Format"),
	("ANativeWindow_getFormat", "result", "AHardwareBuffer_Format"),
	(("ANativeWindow_Buffer.format", "AHardwareBuffer_Desc.format"), "field", "AHardwareBuffer_Format"),
	("AHardwareBuffer_Desc.usage", "field", "AHardwareBuffer_UsageFlags"),
	(("AHardwareBuffer_lock", "AHardwareBuffer_lockPlanes", "AHardwareBuffer_lockAndGetInfo"), "usage", "AHardwareBuffer_UsageFlags"),
	(("ANativeWindow_setBuffersTransform", "ASurfaceTransaction_setGeometry", "ASurfaceTransaction_setBufferTransform"), "transform", "ANativeWindowTransform"),
	(("ANativeWindow_setBuffersDataSpace", "ASurfaceTransaction_setBufferDataSpace", "AImageDecoder_setDataSpace", "AndroidBitmap_compress",
	  "AImageReader_newWithDataSpace"), ("dataSpace", "dataspace", "data_space"), "ADataSpace"),
	(("ANativeWindow_getBuffersDataSpace", "ANativeWindow_getBuffersDefaultDataSpace", "AndroidBitmap_getDataSpace",
	  "AImageDecoderHeaderInfo_getDataSpace"), "result", "ADataSpace"),
	(("ANativeWindow_setFrameRate", "ANativeWindow_setFrameRateWithChangeStrategy", "ASurfaceTransaction_setFrameRate",
	  "ASurfaceTransaction_setFrameRateWithChangeStrategy"), "compatibility", "ANativeWindow_FrameRateCompatibility"),
	(("ANativeWindow_setFrameRateWithChangeStrategy", "ASurfaceTransaction_setFrameRateWithChangeStrategy"), "changeFrameRateStrategy", "ANativeWindow_ChangeFrameRateStrategy"),

	# Images and bitmaps
	(("AImageReader_new", "AImageReader_newWithUsage"), "format", "AIMAGE_FORMATS"),
	(("AImageReader_newWithUsage", "AImageReader_newWithDataSpace"), "usage", "AHardwareBuffer_UsageFlags"),
	(("AImageReader_newWithDataSpace", "AImageReader_setDefaultAHardwareBufferFormat"), ("hardwareBufferFormat", "format"), "AHardwareBuffer_Format"),
	(("AndroidBitmap_getInfo", "AndroidBitmap_lockPixels", "AndroidBitmap_unlockPixels", "AndroidBitmap_getHardwareBuffer",
	  "AndroidBitmap_compress"), "result", "AndroidBitmapResult"),
	("AndroidBitmapInfo.format", "field", "AndroidBitmapFormat"),
	("AndroidBitmapInfo.flags", "field", "AndroidBitmapFlags"),
	("AndroidBitmap_compress", "format", "AndroidBitmapCompressFormat"),
	("AImageDecoderHeaderInfo_getAlphaFlags", "result", "AndroidBitmapAlpha"),
	("AImageDecoder_setAndroidBitmapFormat", "format", "AndroidBitmapFormat"),
	("AImageDecoderHeaderInfo_getAndroidBitmapFormat", "result", "AndroidBitmapFormat"),
	(IMAGE_DECODER_RESULTS, "result", "AImageDecoderResult"),
	("AImageDecoderFrameInfo_getDisposeOp", "result", "AImageDecoderDisposeOp"),
	("AImageDecoderFrameInfo_getBlendOp", "result", "AImageDecoderBlendOp"),

	# Media and camera
	(("AMediaCodec_queueInputBuffer", "AMediaCodec_queueSecureInputBuffer"), "flags", "AMediaCodecBufferFlags"),
	("AMediaCodecBufferInfo.flags", "field", "AMediaCodecBufferFlags"),
	("AMediaCodec_configure", "flags", "AMediaCodecConfigureFlags"),
	("AMediaExtractor_getSampleFlags", "result", "AMediaExtractorSampleFlags"),
	(SET_ENTRY + ("ACaptureRequest_getConstEntry", "ACaptureRequest_getConstEntry_physicalCamera", "ACameraMetadata_getConstEntry"), "tag", "acamera_metadata_tag_t"),
	(("ACameraMetadata_entry.tag", "ACameraMetadata_const_entry.tag"), "field", "acamera_metadata_tag_t"),
	(("ACameraMetadata_entry.type", "ACameraMetadata_const_entry.type"), "field", "ACameraMetadataType"),
	("ACameraCaptureFailure.reason", "field", "ACameraCaptureFailureReason"),
	("ACameraDevice_ErrorStateCallback", "error", "ACameraDeviceError"),

	# Fonts, dlext, NPU, networking
	("AFontMatcher_setFamilyVariant", "familyVariant", "AFamilyVariant"),
	("android_dlextinfo.flags", "field", "AndroidDlextFlags"),
	(("ANpuManager_AllocRequest_setBufferPriority", "ANpuBuffer_setPriority"), ("bufferPriority", "newBufferPriority"), "ANpuBuffer_Priority"),
	(("android_res_nsend", "android_res_nquery"), "flags", "ResNsendFlags"),

	# Neural networks: every `int` result is a `ResultCode`
	(["ANeuralNetworks*", "!ANeuralNetworks_getRuntimeFeatureLevel", "!ANeuralNetworks_getDefaultLoopTimeout",
	  "!ANeuralNetworks_getMaximumLoopTimeout"], "result", "ResultCode"),
	("ANeuralNetworksModel_addOperation", "type", "OperationCode"),
	("ANeuralNetworksOperandType.type", "field", "OperandCode"),
	("ANeuralNetworksCompilation_setPreference", "preference", "PreferenceCode"),
	("ANeuralNetworksCompilation_setPriority", "priority", "PriorityCode"),
	("ANeuralNetworksExecution_getDuration", "durationCode", "DurationCode"),
]

# bit_fields, for values that pack small numbers into groups of bits:
#   name: {
#     "backing":   the Odin backing type; field enums take the unsigned integer of the same width, since a field
#                  of a signed enum is sign-extended (2 does not fit a 2-bit field of an `enum i32`)
#     "enums":     {enum name: {member: value}} in the field's own units, or {enum name: (members, shift)}: the
#                  constants `members` names, shifted down, with their shared prefix dropped
#     "fields":    [(name, type, bits)], lowest bits first; type is one of "enums", a NEW_TYPES enum, "bool",
#                  an integer type, or "_" for padding
#     "constants": a members spec: the named values that keep their C names as typed constants
#                  (`ADATASPACE_SRGB :: ADataSpace{standard = .BT709, transfer = .SRGB, range = .FULL}`).
#                  Each must decode exactly. A mask's fields hold all ones, which no member need name
#                  (`ADATASPACE_STANDARD_MASK :: ADataSpace{standard = ADataSpaceStandard(0x3f)}`).
#                  Shifts are bit numbers, not values: they are left out, and stay constants.
#     "drop":      constants that go entirely (optional)
#   }
# A named C enum that becomes a bit_field keeps its C name, and the slots C already gives it.
BIT_FIELDS = {
	"ADataSpace": {
		"backing": "i32",
		"enums": {
			"ADataSpaceStandard": (["ADATASPACE_STANDARD_*", "!ADATASPACE_STANDARD_MASK"], 16),
			"ADataSpaceTransfer": (["ADATASPACE_TRANSFER_*", "!ADATASPACE_TRANSFER_MASK"], 22),
			"ADataSpaceRange":    (["ADATASPACE_RANGE_*", "!ADATASPACE_RANGE_MASK"], 27),
		},
		"fields": [
			# `other` holds the data spaces outside the scheme (DEPTH, DYNAMIC_DEPTH), with the fields above it 0.
			("other", "u16", 16), ("standard", "ADataSpaceStandard", 6), ("transfer", "ADataSpaceTransfer", 5),
			("range", "ADataSpaceRange", 3), ("_", "_", 2),
		],
		"constants": "ADATASPACE_",
		# The header's legacy names for the same values, which ADATASPACE_SKIP_LEGACY_DEFINES drops in C.
		"drop":      ["STANDARD_*", "TRANSFER_*", "RANGE_*"],
	},
	"AHardwareBuffer_UsageFlags": {
		"backing": "u64",
		"enums": {
			"AHardwareBuffer_CpuUsage": {"NEVER": 0, "RARELY": 2, "OFTEN": 3},
		},
		"fields": [
			("cpu_read", "AHardwareBuffer_CpuUsage", 4), ("cpu_write", "AHardwareBuffer_CpuUsage", 4),
			("gpu_sampled_image", "bool", 1), ("gpu_framebuffer", "bool", 1), ("_", "_", 1), ("composer_overlay", "bool", 1),
			("_", "_", 2), ("protected_content", "bool", 1), ("_", "_", 1), ("video_encode", "bool", 1), ("_", "_", 6),
			("sensor_direct_data", "bool", 1), ("gpu_data_buffer", "bool", 1), ("gpu_cube_map", "bool", 1),
			("gpu_mipmap_complete", "bool", 1), ("_", "_", 1), ("vendor_0_3", "u8", 4), ("front_buffer", "bool", 1),
			("_", "_", 15), ("vendor_4_19", "u16", 16),
		],
		"constants": "AHARDWAREBUFFER_USAGE_",
	},
	"AMotionEventPackedAction": {
		"backing": "i32",
		"enums": {},
		"fields": [("action", "AMotionEventAction", 8), ("pointer_index", "u8", 8), ("_", "_", 16)],
		"constants": ["AMOTION_EVENT_ACTION_MASK", "AMOTION_EVENT_ACTION_POINTER_INDEX_MASK"],
	},
	"AndroidBitmapFlags": {
		"backing": "u32",
		"enums": {},
		"fields": [("alpha", "AndroidBitmapAlpha", 2), ("_", "_", 29), ("is_hardware", "bool", 1)],
		"constants": ["ANDROID_BITMAP_FLAGS_ALPHA_MASK", "ANDROID_BITMAP_FLAGS_IS_HARDWARE"],
	},
}

# Out-parameters (pointers) the survey did not cover: the pointee takes the type. Checked by hand.
POINTER_SLOTS = [
	("APermissionManager_checkPermission", "outResult", "APermissionManagerPermission"),
	("AImage_getFormat", "format", "AIMAGE_FORMATS"),
	("AMidiOutputPort_receive", "opcodePtr", "AMidiOpcode"),
	("ANeuralNetworksDevice_getType", "type", "DeviceTypeCode"),
	("ANeuralNetworksDevice_getFeatureLevel", "featureLevel", "FeatureLevelCode"),
]

# Candidates that stay raw, by reason. For the record: nothing reads this.
RAW = {
	"The app's own identifiers, or a negative status": [
		"ALooper_pollOnce/pollAll results and ALooper_addFd(ident): an ident the app chose, or ALOOPER_POLL_*",
		"ALooper_callbackFunc result (1 to keep watching, 0 to stop)", "ASensorManager_createEventQueue(ident)",
		"AMediaCodec_dequeueInputBuffer/dequeueOutputBuffer: a buffer index, or AMEDIACODEC_INFO_*",
		"AMidiDevice_getType: AMIDI_DEVICE_TYPE_*, or a media_status_t error",
		"APersistableBundle_get*: a size, or APERSISTABLEBUNDLE_KEY_NOT_FOUND/ALLOCATOR_FAILED",
	],
	"Numbers with a few named values": [
		"AConfiguration density, SDK version, screen dp sizes, MCC/MNC (ACONFIGURATION_DENSITY_*, *_DP_ANY, MNC_ZERO)",
		"AFont_getWeight and AFontMatcher_setStyle(weight): 1 to 1000 (AFONT_WEIGHT_*)",
		"AImageDecoder_getRepeatCount (or ANDROID_IMAGE_DECODER_INFINITE)", "JNI versions", "aaudio_session_id_t, binder transaction_code_t",
	],
	"libc's constants": ["AAsset_seek/seek64(whence): SEEK_SET, SEEK_CUR, SEEK_END"],
	"Out of scope": [
		"OpenSL ES and OpenMAX AL: deprecated, and every value is an SLuint32/XAuint32",
		"ICU option masks (U_COMPARE_*, U_FOLD_*): int32_t options, left as in ICU's C API",
		"sync_fence_info.status (1 signaled, 0 active, negative error)",
	],
}
