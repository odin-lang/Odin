package objc_Foundation

import "base:intrinsics"

import "core:c"

@(objc_class="NSProcessInfo")
ProcessInfo :: struct {using _: Object}

// Getting the Process Information Agent

@(objc_type=ProcessInfo, objc_name="processInfo", objc_is_class_method=true)
ProcessInfo_processInfo :: proc "c" () -> ^ProcessInfo {
	return msgSend(^ProcessInfo, ProcessInfo, "processInfo")
}

// Accessing Process Information

@(objc_type=ProcessInfo, objc_name="arguments")
ProcessInfo_arguments :: proc "c" (self: ^ProcessInfo) -> ^Array {
	return msgSend(^Array, self, "arguments")
}

@(objc_type=ProcessInfo, objc_name="environment")
ProcessInfo_environment :: proc "c" (self: ^ProcessInfo) -> ^Dictionary {
	return msgSend(^Dictionary, self, "environment")
}

@(objc_type=ProcessInfo, objc_name="globallyUniqueString")
ProcessInfo_globallyUniqueString :: proc "c" (self: ^ProcessInfo) -> ^String {
	return msgSend(^String, self, "globallyUniqueString")
}

@(objc_type=ProcessInfo, objc_name="isMacCatalystApp")
ProcessInfo_isMacCatalystApp :: proc "c" (self: ^ProcessInfo) -> bool {
	return msgSend(bool, self, "isMacCatalystApp")
}

@(objc_type=ProcessInfo, objc_name="isiOSAppOnMac")
ProcessInfo_isiOSAppOnMac :: proc "c" (self: ^ProcessInfo) -> bool {
	return msgSend(bool, self, "isiOSAppOnMac")
}

@(objc_type=ProcessInfo, objc_name="processIdentifier")
ProcessInfo_processIdentifier :: proc "c" (self: ^ProcessInfo) -> c.int {
	return msgSend(c.int, self, "processIdentifier")
}

@(objc_type=ProcessInfo, objc_name="processName")
ProcessInfo_processName :: proc "c" (self: ^ProcessInfo) -> ^String {
	return msgSend(^String, self, "processName")
}

// Accessing User Information 

@(objc_type=ProcessInfo, objc_name="userName")
ProcessInfo_userName :: proc "c" (self: ^ProcessInfo) -> ^String {
	return msgSend(^String, self, "userName")
}

@(objc_type=ProcessInfo, objc_name="fullUserName")
ProcessInfo_fullUserName :: proc "c" (self: ^ProcessInfo) -> ^String {
	return msgSend(^String, self, "fullUserName")
}

// Sudden Application Termination

@(objc_type=ProcessInfo, objc_name="disableSuddenTermination")
ProcessInfo_disableSuddenTermination :: proc "c" (self: ^ProcessInfo) {
	msgSend(nil, self, "disableSuddenTermination")
}

@(objc_type=ProcessInfo, objc_name="enableSuddenTermination")
ProcessInfo_enableSuddenTermination :: proc "c" (self: ^ProcessInfo) {
	msgSend(nil, self, "enableSuddenTermination")
}

// Controlling Automatic Termination

@(objc_type=ProcessInfo, objc_name="disableAutomaticTermination")
ProcessInfo_disableAutomaticTermination :: proc "c" (self: ^ProcessInfo, reason: ^String) {
	msgSend(nil, self, "disableAutomaticTermination:", reason)
}

@(objc_type=ProcessInfo, objc_name="enableAutomaticTermination")
ProcessInfo_enableAutomaticTermination :: proc "c" (self: ^ProcessInfo, reason: ^String) {
	msgSend(nil, self, "enableAutomaticTermination:", reason)
}

@(objc_type=ProcessInfo, objc_name="automaticTerminationSupportEnabled")
ProcessInfo_automaticTerminationSupportEnabled :: proc "c" (self: ^ProcessInfo) -> bool {
	return msgSend(bool, self, "automaticTerminationSupportEnabled")
}

@(objc_type=ProcessInfo, objc_name="setAutomaticTerminationSupportEnabled")
ProcessInfo_setAutomaticTerminationSupportEnabled :: proc "c" (self: ^ProcessInfo, automaticTerminationSupportEnabled: bool) {
	msgSend(nil, self, "setAutomaticTerminationSupportEnabled:", automaticTerminationSupportEnabled)
}

// Getting Host Information

@(objc_type=ProcessInfo, objc_name="hostName")
ProcessInfo_hostName :: proc "c" (self: ^ProcessInfo) -> ^String {
	return msgSend(^String, self, "hostName")
}

@(objc_type=ProcessInfo, objc_name="operatingSystemVersionString")
ProcessInfo_operatingSystemVersionString :: proc "c" (self: ^ProcessInfo) -> ^String {
	return msgSend(^String, self, "operatingSystemVersionString")
}

@(objc_type=ProcessInfo, objc_name="operatingSystemVersion")
ProcessInfo_operatingSystemVersion :: proc "c" (self: ^ProcessInfo) -> OperatingSystemVersion {
	return msgSend(OperatingSystemVersion, self, "operatingSystemVersion")
}

@(objc_type=ProcessInfo, objc_name="isOperatingSystemAtLeastVersion")
ProcessInfo_isOperatingSystemAtLeastVersion :: proc "c" (self: ^ProcessInfo, version: OperatingSystemVersion) -> bool {
	return msgSend(bool, self, "isOperatingSystemAtLeastVersion:", version)
}

// Getting Computer Information

@(objc_type=ProcessInfo, objc_name="processorCount")
ProcessInfo_processorCount :: proc "c" (self: ^ProcessInfo) -> UInteger {
	return msgSend(UInteger, self, "processorCount")
}

@(objc_type=ProcessInfo, objc_name="activeProcessorCount")
ProcessInfo_activeProcessorCount :: proc "c" (self: ^ProcessInfo) -> UInteger {
	return msgSend(UInteger, self, "activeProcessorCount")
}

@(objc_type=ProcessInfo, objc_name="physicalMemory")
ProcessInfo_physicalMemory :: proc "c" (self: ^ProcessInfo) -> c.ulonglong {
	return msgSend(c.ulonglong, self, "physicalMemory")
}

@(objc_type=ProcessInfo, objc_name="systemUptime")
ProcessInfo_systemUptime :: proc "c" (self: ^ProcessInfo) -> TimeInterval {
	return msgSend(TimeInterval, self, "systemUptime")
}

// Managing Activities

@(private)
log2 :: intrinsics.constant_log2

ActivityOptionsBits :: enum u64 {
	IdleDisplaySleepDisabled             = log2(1099511627776),  // Require the screen to stay powered on.
	IdleSystemSleepDisabled              = log2(1048576),        // Prevent idle sleep.
	SuddenTerminationDisabled            = log2(16384),          // Prevent sudden termination.
	AutomaticTerminationDisabled         = log2(32768),          // Prevent automatic termination.
	AnimationTrackingEnabled             = log2(35184372088832), // Track activity with an animation signpost interval.
	TrackingEnabled                      = log2(70368744177664), // Track activity with a signpost interval.
	UserInitiated                        = log2(16777215),       // Performing a user-requested action.
	UserInitiatedAllowingIdleSystemSleep = log2(15728639),       // Performing a user-requested action, but the system can sleep on idle.
	Background                           = log2(255),            // Initiated some kind of work, but not as the direct result of a user request.
	LatencyCritical                      = log2(1095216660480),  // Requires the highest amount of timer and I/O precision available.
	UserInteractive                      = log2(1095233437695),  // Responding to user interaction.
}
ActivityOptions :: bit_set[ActivityOptionsBits; u64]

@(objc_type=ProcessInfo, objc_name="beginActivityWithOptions")
ProcessInfo_beginActivityWithOptions :: proc "c" (self: ^ProcessInfo, options: ActivityOptions, reason: ^String) -> ^ObjectProtocol {
	return msgSend(^ObjectProtocol, self, "beginActivityWithOptions:reason:", options, reason)
}

@(objc_type=ProcessInfo, objc_name="endActivity")
ProcessInfo_endActivity :: proc "c" (self: ^ProcessInfo, activity: ^ObjectProtocol) {
	msgSend(nil, self, "endActivity:", activity)
}

@(objc_type=ProcessInfo, objc_name="performActivityWithOptions")
ProcessInfo_performActivityWithOptions :: proc "c" (self: ^ProcessInfo, options: ActivityOptions, reason: ^String, block: proc "c" ()) {
	msgSend(nil, self, "performActivityWithOptions:reason:usingBlock:", options, reason, block)
}

@(objc_type=ProcessInfo, objc_name="performExpiringActivityWithReason")
ProcessInfo_performExpiringActivityWithReason :: proc "c" (self: ^ProcessInfo, reason: ^String, block: proc "c" (expired: bool)) {
	msgSend(nil, self, "performExpiringActivityWithReason:usingBlock:", reason, block)
}

// Getting the Thermal State

ProcessInfoThermalState :: enum c.long {
	Nominal,
	Fair,
	Serious,
	Critical,
}

@(objc_type=ProcessInfo, objc_name="thermalState")
ProcessInfo_thermalState :: proc "c" (self: ^ProcessInfo) -> ProcessInfoThermalState {
	return msgSend(ProcessInfoThermalState, self, "thermalState")
}

// Determining Whether Low Power Mode is Enabled

@(objc_type=ProcessInfo, objc_name="isLowPowerModeEnabled")
ProcessInfo_isLowPowerModeEnabled :: proc "c" (self: ^ProcessInfo) -> bool {
	return msgSend(bool, self, "isLowPowerModeEnabled")
}
