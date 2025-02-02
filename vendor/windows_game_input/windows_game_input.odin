#+build windows
/*
	Bindings for Windows Game Input GDK:
	https://learn.microsoft.com/en-us/gaming/gdk/_content/gc/input/overviews/input-overview

	Windows SDK 10.0.26100.0 is at least required to link with.
*/
package windows_game_input

foreign import wgi {
	"system:gameinput.lib",
}

import "core:c"
import "core:sys/windows"

// Enums
GameInputArcadeStickButtons_Flag :: enum c.int {
	Menu = 0,
	View = 1,
	Up = 2,
	Down = 3,
	Left = 4,
	Right = 5,
	Action1 = 6,
	Action2 = 7,
	Action3 = 8,
	Action4 = 9,
	Action5 = 10,
	Action6 = 11,
	Special1 = 12,
	Special2 = 13
}
GameInputArcadeStickButtons :: bit_set[GameInputArcadeStickButtons_Flag; c.int]

GameInputBatteryStatus :: enum c.int {
	Unknown = -1,
	NotPresent = 0,
	Discharging = 1,
	Idle = 2,
	Charging = 3
}

GameInputDeviceCapabilities_Flag :: enum c.int {
	Audio = 0,
	PluginModule = 1,
	PowerOff = 2,
	Synchronization = 3,
	Wireless = 4
}
GameInputDeviceCapabilities :: bit_set[GameInputDeviceCapabilities_Flag; c.int]

GameInputDeviceFamily :: enum c.int {
	Virtual = -1,
	Aggregate = 0,
	XboxOne = 1,
	Xbox360 = 2,
	Hid = 3,
	I8042 = 4
}

GameInputDeviceStatus_Flag :: enum c.int {
	Connected = 0,
	InputEnabled = 1,
	OutputEnabled = 2,
	RawIoEnabled = 3,
	AudioCapture = 4,
	AudioRender = 5,
	Synchronized = 6,
	Wireless = 7,
	UserIdle = 20,
}
GameInputDeviceStatus :: bit_set[GameInputDeviceStatus_Flag; c.int]

GameInputEnumerationKind :: enum c.int {
	NoEnumeration = 0,
	AsyncEnumeration = 1,
	BlockingEnumeration = 2
}

GameInputFeedbackAxes_Flag :: enum c.int {
	LinearX = 0,
	LinearY = 1,
	LinearZ = 2,
	AngularX = 3,
	AngularY = 4,
	AngularZ = 5,
	Normal = 6
}
GameInputFeedbackAxes :: bit_set[GameInputFeedbackAxes_Flag; c.int]

GameInputFeedbackEffectState :: enum c.int {
	Stopped = 0,
	Running = 1,
	Paused = 2
}

GameInputFlightStickButtons_Flag :: enum c.int {
	None = 0,
	Menu = 1,
	View = 2,
	FirePrimary = 3,
	FireSecondary = 4
}
GameInputFlightStickButtons :: bit_set[GameInputFlightStickButtons_Flag; c.int]

GameInputFocusPolicy_Flag :: enum c.int {
	DisableBackgroundInput = 0,
	ExclusiveForegroundInput = 1,
	DisableBackgroundGuideButton   = 2,
	ExclusiveForegroundGuideButton = 3,
	DisableBackgroundShareButton   = 4,
	ExclusiveForegroundShareButton = 5
}
GameInputFocusPolicy :: bit_set[GameInputFocusPolicy_Flag; c.int]

GameInputForceFeedbackEffectKind :: enum c.int {
	Constant = 0,
	Ramp = 1,
	SineWave = 2,
	SquareWave = 3,
	TriangleWave = 4,
	SawtoothUpWave = 5,
	SawtoothDownWave = 6,
	Spring = 7,
	Friction = 8,
	Damper = 9,
	Inertia = 10
}

GameInputGamepadButtons_Flag :: enum c.int {
	Menu = 0,
	View = 1,
	A = 2,
	B = 3,
	X = 4,
	Y = 5,
	DPadUp = 6,
	DPadDown = 7,
	DPadLeft = 8,
	DPadRight = 9,
	LeftShoulder = 10,
	RightShoulder = 11,
	LeftThumbstick = 12,
	RightThumbstick = 13
}
GameInputGamepadButtons :: bit_set[GameInputGamepadButtons_Flag; c.int]

GameInputKeyboardKind :: enum c.int {
	UnknownKeyboard = -1,
	AnsiKeyboard = 0,
	IsoKeyboard = 1,
	KsKeyboard = 2,
	AbntKeyboard = 3,
	JisKeyboard = 4
}

GameInputKind_Flag :: enum c.int {
	RawDeviceReport = 0,
	ControllerAxis	 = 1,
	ControllerButton = 2,
	ControllerSwitch = 3,
	Keyboard = 4,
	Mouse = 5,
	Touch = 8,
	Motion = 12,
	ArcadeStick = 16,
	FlightStick = 17,
	Gamepad = 18,
	RacingWheel = 19,
	UiNavigation = 20
}
GameInputKind :: bit_set[GameInputKind_Flag; c.int]
GameInputKind_Controller : GameInputKind : { .ControllerAxis, .ControllerButton, .ControllerSwitch }

GameInputLabel :: enum c.int {
	Unknown = -1,
	None = 0,
	XboxGuide = 1,
	XboxBack = 2,
	XboxStart = 3,
	XboxMenu = 4,
	XboxView = 5,
	XboxA = 7,
	XboxB = 8,
	XboxX = 9,
	XboxY = 10,
	XboxDPadUp = 11,
	XboxDPadDown = 12,
	XboxDPadLeft = 13,
	XboxDPadRight = 14,
	XboxLeftShoulder = 15,
	XboxLeftTrigger = 16,
	XboxLeftStickButton = 17,
	XboxRightShoulder = 18,
	XboxRightTrigger = 19,
	XboxRightStickButton = 20,
	XboxPaddle1 = 21,
	XboxPaddle2 = 22,
	XboxPaddle3 = 23,
	XboxPaddle4 = 24,
	LetterA = 25,
	LetterB = 26,
	LetterC = 27,
	LetterD = 28,
	LetterE = 29,
	LetterF = 30,
	LetterG = 31,
	LetterH = 32,
	LetterI = 33,
	LetterJ = 34,
	LetterK = 35,
	LetterL = 36,
	LetterM = 37,
	LetterN = 38,
	LetterO = 39,
	LetterP = 40,
	LetterQ = 41,
	LetterR = 42,
	LetterS = 43,
	LetterT = 44,
	LetterU = 45,
	LetterV = 46,
	LetterW = 47,
	LetterX = 48,
	LetterY = 49,
	LetterZ = 50,
	Number0 = 51,
	Number1 = 52,
	Number2 = 53,
	Number3 = 54,
	Number4 = 55,
	Number5 = 56,
	Number6 = 57,
	Number7 = 58,
	Number8 = 59,
	Number9 = 60,
	ArrowUp = 61,
	ArrowUpRight = 62,
	ArrowRight = 63,
	ArrowDownRight = 64,
	ArrowDown = 65,
	ArrowDownLLeft = 66,
	ArrowLeft = 67,
	ArrowUpLeft = 68,
	ArrowUpDown = 69,
	ArrowLeftRight = 70,
	ArrowUpDownLeftRight = 71,
	ArrowClockwise = 72,
	ArrowCounterClockwise = 73,
	ArrowReturn = 74,
	IconBranding = 75,
	IconHome = 76,
	IconMenu = 77,
	IconCross = 78,
	IconCircle = 79,
	IconSquare = 80,
	IconTriangle = 81,
	IconStar = 82,
	IconDPadUp = 83,
	IconDPadDown = 84,
	IconDPadLeft = 85,
	IconDPadRight = 86,
	IconDialClockwise = 87,
	IconDialCounterClockwise = 88,
	IconSliderLeftRight = 89,
	IconSliderUpDown = 90,
	IconWheelUpDown = 91,
	IconPlus = 92,
	IconMinus = 93,
	IconSuspension = 94,
	Home = 95,
	Guide = 96,
	Mode = 97,
	Select = 98,
	Menu = 99,
	View = 100,
	Back = 101,
	Start = 102,
	Options = 103,
	Share = 104,
	Up = 105,
	Down = 106,
	Left = 107,
	Right = 108,
	LB = 109,
	LT = 110,
	LSB = 111,
	L1 = 112,
	L2 = 113,
	L3 = 114,
	RB = 115,
	RT = 116,
	RSB = 117,
	R1 = 118,
	R2 = 119,
	R3 = 120,
	P1 = 121,
	P2 = 122,
	P3 = 123,
	P4 = 124
}

GameInputLocation :: enum c.int {
	Unknown = -1,
	Chassis = 0,
	Display = 1,
	Axis = 2,
	Button = 3,
	Switch = 4,
	Key = 5,
	TouchPad = 6
}

GameInputMotionAccuracy :: enum c.int {
	AccuracyUnknown = -1,
	Unavailable = 0,
	Unreliable = 1,
	Approximate = 2,
	Accurate = 3
}

GameInputMouseButtons_Flag :: enum c.int {
	LeftButton = 0,
	RightButton = 1,
	MiddleButton = 2,
	Button4 = 3,
	Button5 = 4,
	WheelTiltLeft = 5,
	WheelTiltRight = 6
}
GameInputMouseButtons :: bit_set[GameInputMouseButtons_Flag; c.int]

GameInputRacingWheelButtons_Flag :: enum c.int {
	Menu = 0,
	View = 1,
	PreviousGear = 2,
	NextGear = 3,
	DpadUp = 4,
	DpadDown = 5,
	DpadLeft = 6,
	DpadRight = 7
}
GameInputRacingWheelButtons :: bit_set[GameInputRacingWheelButtons_Flag; c.int]

GameInputRawDeviceItemCollectionKind :: enum c.int {
	UnknownItemCollection = -1,
	PhysicalItemCollection = 0,
	ApplicationItemCollection = 1,
	LogicalItemCollection = 2,
	ReportItemCollection = 3,
	NamedArrayItemCollection = 4,
	UsageSwitchItemCollection = 5,
	UsageModifierItemCollection = 6
}

GameInputRawDevicePhysicalUnitKind :: enum c.int {
	Unknown = -1,
	None = 0,
	Time = 1,
	Frequency = 2,
	Length = 3,
	Velocity = 4,
	Acceleration = 5,
	Mass = 6,
	Momentum = 7,
	Force = 8,
	Pressure = 9,
	Angle = 10,
	AngularVelocity = 11,
	AngularAcceleration = 12,
	AngularMass = 13,
	AngularMomentum = 14,
	AngularTorque = 15,
	ElectricCurrent = 16,
	ElectricCharge = 17,
	ElectricPotential = 18,
	Energy = 19,
	Power = 20,
	Temperature = 21,
	LuminousIntensity = 22,
	LuminousFlux = 23,
	Illuminance = 24
}

GameInputRawDeviceReportItemFlag :: enum c.int {
	ConstantItem = 0,
	ArrayItem = 1,
	RelativeItem = 2,
	WraparoundItem = 3,
	NonlinearItem = 4,
	StableItem = 5,
	NullableItem = 6,
	VolatileItem = 7,
	BufferedItem = 8
}
GameInputRawDeviceReportItemFlags :: bit_set[GameInputRawDeviceReportItemFlag; c.int]

GameInputRawDeviceReportKind :: enum c.int {
	InputReport = 0,
	OutputReport = 1,
	FeatureReport = 2
}

GameInputRumbleMotors_Flag :: enum c.int {
	LowFrequency = 0,
	HighFrequency = 1,
	LeftTrigger = 2,
	RightTrigger = 3
}
GameInputRumbleMotors :: bit_set[GameInputRumbleMotors_Flag; c.int]

GameInputSwitchKind :: enum c.int {
	UnknownSwitchKind = -1,
	GameInput2WaySwitch = 0,
	GameInput4WaySwitch = 1,
	GameInput8WaySwitch = 2
}

GameInputSwitchPosition :: enum c.int {
	Center = 0,
	Up = 1,
	UpRight = 2,
	Right = 3,
	DownRight = 4,
	Down = 5,
	DownLeft = 6,
	Left = 7,
	UpLeft = 8
}

GameInputSystemButtons_Flag :: enum c.int {
	Guide = 0,
	Share = 1 
}
GameInputSystemButtons :: bit_set[GameInputSystemButtons_Flag; c.int]

GameInputTouchShape :: enum c.int {
	Unknown = -1,
	Point = 0,
	Shape1DLinear = 1,
	Shape1DRadial = 2,
	Shape1DIrregular = 3,
	Shape2DRectangular = 4,
	Shape2DElliptical = 5,
	Shape2DIrregular = 6
}

GameInputUiNavigationButtons_Flag :: enum c.int {
	Menu = 0,
	View = 1,
	Accept = 2,
	Cancel = 3,
	Up = 4,
	Down = 5,
	Left = 6,
	Right = 7,
	Context1 = 8,
	Context2 = 9,
	Context3 = 10,
	Context4 = 11,
	PageUp = 12,
	PageDown = 13,
	PageLeft = 14,
	PageRight = 15,
	ScrollUp = 16,
	ScrollDown = 17,
	ScrollLeft = 18,
	ScrollRight = 19
}
GameInputUiNavigationButtons :: bit_set[GameInputUiNavigationButtons_Flag; c.int]

// Structs

APP_LOCAL_DEVICE_ID :: distinct [32]byte

GameInputArcadeStickInfo :: struct {
	menuButtonLabel: GameInputLabel,
	viewButtonLabel: GameInputLabel,
	stickUpLabel: GameInputLabel,
	stickDownLabel: GameInputLabel,
	stickLeftLabel: GameInputLabel,
	stickRightLabel: GameInputLabel,
	actionButton1Label: GameInputLabel,
	actionButton2Label: GameInputLabel,
	actionButton3Label: GameInputLabel,
	actionButton4Label: GameInputLabel,
	actionButton5Label: GameInputLabel,
	actionButton6Label: GameInputLabel,
	specialButton1Label: GameInputLabel,
	specialButton2Label: GameInputLabel,
}

GameInputArcadeStickState :: struct {
	buttons: GameInputArcadeStickButtons,
}

GameInputBatteryState :: struct {
	chargeRate: f32,
	maxChargeRate: f32,
	remainingCapacity: f32,
	fullChargeCapacity: f32,
	status: GameInputBatteryStatus,
}

GameInputControllerAxisInfo :: struct {
	mappedInputKinds: GameInputKind,
	label: GameInputLabel,
	isContinuous: bool,
	isNonlinear: bool,
	isQuantized: bool,
	hasRestValue: bool,
	restValue: f32,
	resolution: u64,
	legacyDInputIndex: u16,
	legacyHidIndex: u16,
	rawReportIndex: u32,
	inputReport: ^GameInputRawDeviceReportInfo,
	inputReportItem: ^GameInputRawDeviceReportItemInfo,
}

GameInputControllerButtonInfo :: struct {
	mappedInputKinds: GameInputKind,
	label: GameInputLabel,
	legacyDInputIndex: u16,
	legacyHidIndex: u16,
	rawReportIndex: u32,
	inputReport: ^GameInputRawDeviceReportInfo,
	inputReportItem: ^GameInputRawDeviceReportItemInfo,
}

GameInputControllerSwitchInfo :: struct {
	mappedInputKinds: GameInputKind,
	label: GameInputLabel,
	positionLabels: [9]GameInputLabel,
	kind: GameInputSwitchKind,
	legacyDInputIndex: u16,
	legacyHidIndex: u16,
	rawReportIndex: u32,
	inputReport: ^GameInputRawDeviceReportInfo,
	inputReportItem: ^GameInputRawDeviceReportItemInfo,
}

GameInputDeviceInfo :: struct {
	infoSize: u32,
	vendorId: u16,
	productId: u16,
	revisionNumber: u16,
	interfaceNumber: u8,
	collectionNumber: u8,
	usage: GameInputUsage,
	hardwareVersion: GameInputVersion,
	firmwareVersion: GameInputVersion,
	deviceId: APP_LOCAL_DEVICE_ID,
	deviceRootId: APP_LOCAL_DEVICE_ID,
	deviceFamily: GameInputDeviceFamily,
	capabilities: GameInputDeviceCapabilities,
	supportedInput: GameInputKind,
	supportedRumbleMotors: GameInputRumbleMotors,
	inputReportCount: u32,
	outputReportCount: u32,
	featureReportCount: u32,
	controllerAxisCount: u32,
	controllerButtonCount: u32,
	controllerSwitchCount: u32,
	touchPointCount: u32,
	touchSensorCount: u32,
	forceFeedbackMotorCount: u32,
	hapticFeedbackMotorCount: u32,
	deviceStringCount: u32,
	deviceDescriptorSize: u32,
	inputReportInfo: ^GameInputRawDeviceReportInfo,
	outputReportInfo: ^GameInputRawDeviceReportInfo,
	featureReportInfo: ^GameInputRawDeviceReportInfo,
	controllerAxisInfo: ^GameInputControllerAxisInfo,
	controllerButtonInfo: ^GameInputControllerButtonInfo,
	controllerSwitchInfo: ^GameInputControllerSwitchInfo,
	keyboardInfo: ^GameInputKeyboardInfo,
	mouseInfo: ^GameInputMouseInfo,
	touchSensorInfo: ^GameInputTouchSensorInfo,
	motionInfo: ^GameInputMotionInfo,
	arcadeStickInfo: ^GameInputArcadeStickInfo,
	flightStickInfo: ^GameInputFlightStickInfo,
	gamepadInfo: ^GameInputGamepadInfo,
	racingWheelInfo: ^GameInputRacingWheelInfo,
	uiNavigationInfo: ^GameInputUiNavigationInfo,
	forceFeedbackMotorInfo: ^GameInputForceFeedbackMotorInfo,
	hapticFeedbackMotorInfo: ^GameInputHapticFeedbackMotorInfo,
	displayName: ^GameInputString,
	deviceStrings: ^GameInputString,
	deviceDescriptorData: rawptr,
}

GameInputFlightStickInfo :: struct {
	menuButtonLabel: GameInputLabel,
	viewButtonLabel: GameInputLabel,
	firePrimaryButtonLabel: GameInputLabel,
	fireSecondaryButtonLabel: GameInputLabel,
	hatSwitchKind: GameInputSwitchKind,
}

GameInputFlightStickState :: struct {
	buttons: GameInputFlightStickButtons,
	hatSwitch: GameInputSwitchPosition,
	roll: f32,
	pitch: f32,
	yaw: f32,
	throttle: f32,
}

GameInputForceFeedbackConditionParams :: struct {
	magnitude: GameInputForceFeedbackMagnitude,
	positiveCoefficient: f32,
	negativeCoefficient: f32,
	maxPositiveMagnitude: f32,
	maxNegativeMagnitude: f32,
	deadZone: f32,
	bias: f32,
}

GameInputForceFeedbackConstantParams :: struct {
	envelope: GameInputForceFeedbackEnvelope,
	magnitude: GameInputForceFeedbackMagnitude,
}

GameInputForceFeedbackEnvelope :: struct {
	attackDuration: u64,
	sustainDuration: u64,
	releaseDuration: u64,
	attackGain: f32,
	sustainGain: f32,
	releaseGain: f32,
	playCount: u32,
	repeatDelay: u64,
}

GameInputForceFeedbackMagnitude :: struct {
	linearX: f32,
	linearY: f32,
	linearZ: f32,
	angularX: f32,
	angularY: f32,
	angularZ: f32,
	normal: f32,
}

GameInputForceFeedbackMotorInfo :: struct {
	supportedAxes: GameInputFeedbackAxes,
	location: GameInputLocation,
	locationId: u32,
	maxSimultaneousEffects: u32,
	isConstantEffectSupported: bool,
	isRampEffectSupported: bool,
	isSineWaveEffectSupported: bool,
	isSquareWaveEffectSupported: bool,
	isTriangleWaveEffectSupported: bool,
	isSawtoothUpWaveEffectSupported: bool,
	isSawtoothDownWaveEffectSupported: bool,
	isSpringEffectSupported: bool,
	isFrictionEffectSupported: bool,
	isDamperEffectSupported: bool,
	isInertiaEffectSupported: bool,
}

GameInputForceFeedbackParams :: struct {
	kind: GameInputForceFeedbackEffectKind,
	using _: struct #raw_union {  
	constant: GameInputForceFeedbackConstantParams,
	ramp: GameInputForceFeedbackRampParams,
	sineWave: GameInputForceFeedbackPeriodicParams,
	squareWave: GameInputForceFeedbackPeriodicParams,
	triangleWave: GameInputForceFeedbackPeriodicParams,
	sawtoothUpWave: GameInputForceFeedbackPeriodicParams,
	sawtoothDownWave: GameInputForceFeedbackPeriodicParams,
	spring: GameInputForceFeedbackConditionParams,
	friction: GameInputForceFeedbackConditionParams,
	damper: GameInputForceFeedbackConditionParams,
	inertia: GameInputForceFeedbackConditionParams,
	}
}

GameInputForceFeedbackPeriodicParams :: struct {
	envelope: GameInputForceFeedbackEnvelope,
	magnitude: GameInputForceFeedbackMagnitude,
	frequency: f32,
	phase: f32,
	bias: f32,
}

GameInputForceFeedbackRampParams :: struct {
	envelope: GameInputForceFeedbackEnvelope,
	startMagnitude: GameInputForceFeedbackMagnitude,
	endMagnitude: GameInputForceFeedbackMagnitude,
}

GameInputGamepadInfo :: struct {
	menuButtonLabel: GameInputLabel,
	viewButtonLabel: GameInputLabel,
	aButtonLabel: GameInputLabel,
	bButtonLabel: GameInputLabel,
	xButtonLabel: GameInputLabel,
	yButtonLabel: GameInputLabel,
	dpadUpLabel: GameInputLabel,
	dpadDownLabel: GameInputLabel,
	dpadLeftLabel: GameInputLabel,
	dpadRightLabel: GameInputLabel,
	leftShoulderButtonLabel: GameInputLabel,
	rightShoulderButtonLabel: GameInputLabel,
	leftThumbstickButtonLabel: GameInputLabel,
	rightThumbstickButtonLabel: GameInputLabel,
}

GameInputGamepadState :: struct {
	buttons: GameInputGamepadButtons,
	leftTrigger: f32,
	rightTrigger: f32,
	leftThumbstickX: f32,
	leftThumbstickY: f32,
	rightThumbstickX: f32,
	rightThumbstickY: f32,
}

GameInputHapticFeedbackMotorInfo :: struct {
	mappedRumbleMotor: GameInputRumbleMotors,
	location: GameInputLocation,
	locationId: u32,
	waveformCount: u32,
	waveformInfo: [^]GameInputHapticWaveformInfo,
}

GameInputHapticFeedbackParams :: struct {
	waveformIndex: u32,
	duration: u64,
	intensity: f32,
	playCount: u32,
	repeatDelay: u64,
}

GameInputHapticWaveformInfo :: struct {
	usage: GameInputUsage,
	isDurationSupported: bool,
	isIntensitySupported: bool,
	isRepeatSupported: bool,
	isRepeatDelaySupported: bool,
	defaultDuration: u64,
}

GameInputKeyboardInfo :: struct {
	kind: GameInputKeyboardKind,
	layout: u32,
	keyCount: u32,
	functionKeyCount: u32,
	maxSimultaneousKeys: u32,
	platformType: u32,
	platformSubtype: u32,
	nativeLanguage: ^GameInputString,
}

GameInputKeyState :: struct {
	scanCode: u32,
	codePoint: u32,
	virtualKey: u8,
	isDeadKey: bool,
}

GameInputMotionInfo :: struct {
	maxAcceleration: f32,
	maxAngularVelocity: f32,
	maxMagneticFieldStrength: f32,
}

GameInputMotionState :: struct {
	accelerationX: f32,
	accelerationY: f32,
	accelerationZ: f32,
	angularVelocityX: f32,
	angularVelocityY: f32,
	angularVelocityZ: f32,
	magneticFieldX: f32,
	magneticFieldY: f32,
	magneticFieldZ: f32,
	orientationW: f32,
	orientationX: f32,
	orientationY: f32,
	orientationZ: f32,
	accelerometerAccuracy: GameInputMotionAccuracy,
	gyroscopeAccuracy: GameInputMotionAccuracy,
	magnetometerAccuracy: GameInputMotionAccuracy,
	orientationAccuracy: GameInputMotionAccuracy,
}

GameInputMouseInfo :: struct {
	supportedButtons: GameInputMouseButtons,
	sampleRate: u32,
	sensorDpi: u32,
	hasWheelX: bool,
	hasWheelY: bool,
}

GameInputMouseState :: struct {
	buttons: GameInputMouseButtons,
	positionX: i64,
	positionY: i64,
	wheelX: i64,
	wheelY: i64,
}

GameInputRacingWheelInfo :: struct {
	menuButtonLabel: GameInputLabel,
	viewButtonLabel: GameInputLabel,
	previousGearButtonLabel: GameInputLabel,
	nextGearButtonLabel: GameInputLabel,
	dpadUpLabel: GameInputLabel,
	dpadDownLabel: GameInputLabel,
	dpadLeftLabel: GameInputLabel,
	dpadRightLabel: GameInputLabel,
	hasClutch: bool,
	hasHandbrake: bool,
	hasPatternShifter: bool,
	minPatternShifterGear: i32,
	maxPatternShifterGear: i32,
	maxWheelAngle: f32,
}

GameInputRacingWheelState :: struct {
	buttons: GameInputRacingWheelButtons,
	patternShifterGear: i32,
	wheel: f32,
	throttle: f32,
	brake: f32,
	clutch: f32,
	handbrake: f32,
}

GameInputRawDeviceItemCollectionInfo :: struct {
	kind: GameInputRawDeviceItemCollectionKind,
	childCount: u32,
	siblingCount: u32,
	usageCount: u32,
	usages: [^]GameInputUsage,
	parent: ^GameInputRawDeviceItemCollectionInfo,
	firstSibling: ^GameInputRawDeviceItemCollectionInfo,
	previousSibling: ^GameInputRawDeviceItemCollectionInfo,
	nextSibling: ^GameInputRawDeviceItemCollectionInfo,
	lastSibling: ^GameInputRawDeviceItemCollectionInfo,
	firstChild: ^GameInputRawDeviceItemCollectionInfo,
	lastChild: ^GameInputRawDeviceItemCollectionInfo,
}

GameInputRawDeviceReportInfo :: struct {
	kind: GameInputRawDeviceReportKind,
	id: u32,
	size: u32,
	itemCount: u32,
	items: [^]GameInputRawDeviceReportItemInfo,
}

GameInputRawDeviceReportItemInfo :: struct {
	bitOffset: u32,
	bitSize: u32,
	logicalMin: i64,
	logicalMax: i64,
	physicalMin: f64,
	physicalMax: f64,
	physicalUnits: GameInputRawDevicePhysicalUnitKind,
	rawPhysicalUnits: u32,
	rawPhysicalUnitsExponent: i32,
	flags: GameInputRawDeviceReportItemFlags,
	usageCount: u32,
	usages: [^]GameInputUsage,
	collection: ^GameInputRawDeviceItemCollectionInfo,
	itemString: ^GameInputString,
}

GameInputRumbleParams :: struct {
	lowFrequency: f32,
	highFrequency: f32,
	leftTrigger: f32,
	rightTrigger: f32,
}

GameInputString :: struct {
	sizeInBytes: u32,
	codePointCount: u32,
	data: [^]byte,
}

GameInputTouchSensorInfo :: struct {
	mappedInputKinds: GameInputKind,
	label: GameInputLabel,
	location: GameInputLocation,
	locationId: u32,
	resolutionX: u64,
	resolutionY: u64,
	shape: GameInputTouchShape,
	aspectRatio: f32,
	orientation: f32,
	physicalWidth: f32,
	physicalHeight: f32,
	maxPressure: f32,
	maxProximity: f32,
	maxTouchPoints: u32,
}

GameInputTouchState :: struct {
	touchId: u64,
	sensorIndex: u32,
	positionX: f32,
	positionY: f32,
	pressure: f32,
	proximity: f32,
	contactRectTop: f32,
	contactRectLeft: f32,
	contactRectRight: f32,
	contactRectBottom: f32,
}

GameInputUiNavigationInfo :: struct {
	menuButtonLabel: GameInputLabel,
	viewButtonLabel: GameInputLabel,
	acceptButtonLabel: GameInputLabel,
	cancelButtonLabel: GameInputLabel,
	upButtonLabel: GameInputLabel,
	downButtonLabel: GameInputLabel,
	leftButtonLabel: GameInputLabel,
	rightButtonLabel: GameInputLabel,
	contextButton1Label: GameInputLabel,
	contextButton2Label: GameInputLabel,
	contextButton3Label: GameInputLabel,
	contextButton4Label: GameInputLabel,
	pageUpButtonLabel: GameInputLabel,
	pageDownButtonLabel: GameInputLabel,
	pageLeftButtonLabel: GameInputLabel,
	pageRightButtonLabel: GameInputLabel,
	scrollUpButtonLabel: GameInputLabel,
	scrollDownButtonLabel: GameInputLabel,
	scrollLeftButtonLabel: GameInputLabel,
	scrollRightButtonLabel: GameInputLabel,
	guideButtonLabel: GameInputLabel,
}

GameInputUiNavigationState :: struct {
	buttons: GameInputUiNavigationButtons,
}

GameInputUsage :: struct {
	page: u16,
	id: u16,
}

GameInputVersion :: struct {
	major: u16,
	minor: u16,
	build: u16,
	revision: u16,
}

// COM Interfaces

IUnknown	:: windows.IUnknown
IUnknown_VTable :: windows.IUnknown_VTable
IID		:: windows.GUID

IGameInput_UUID_STRING :: "11BE2A7E-4254-445A-9C09-FFC40F006918"
IGameInput_UUID := &IID{0x11BE2A7E, 0x4254, 0x445A, {0x9C, 0x09, 0xFF, 0xC4, 0x0F, 0x00, 0x69, 0x18}}
IGameInput :: struct #raw_union {
	#subtype iunknown: IUnknown,
	using igameinput_vtable: ^IGameInput_VTable,
}
IGameInput_VTable :: struct {
	using iunknown_vtable: IUnknown_VTable,
	GetCurrentTimestamp: proc "system" (this: ^IGameInput) -> u64,
	GetCurrentReading: proc "system" (this: ^IGameInput, inputKind: GameInputKind, device: ^IGameInputDevice, reading: ^^IGameInputReading) -> HRESULT,
	GetNextReading: proc "system" (this: ^IGameInput, referenceReading: ^IGameInputReading, inputKind: GameInputKind, device: ^IGameInputDevice, reading: ^^IGameInputReading) -> HRESULT,
	GetPreviousReading: proc "system" (this: ^IGameInput, referenceReading: ^IGameInputReading, inputKind: GameInputKind, device: ^IGameInputDevice, reading: ^^IGameInputReading) -> HRESULT,
	GetTemporalReading: proc "system" (this: ^IGameInput, timestamp: u64, device: ^IGameInputDevice, reading: ^^IGameInputReading) -> HRESULT,
	RegisterReadingCallback: proc "system" (this: ^IGameInput, device: ^IGameInputDevice, inputKind: GameInputKind, analogThreshold: f32, ctx: rawptr, callbackFunc: GameInputReadingCallback, callbackToken: ^GameInputCallbackToken) -> HRESULT,
	RegisterDeviceCallback: proc "system" (this: ^IGameInput, device: ^IGameInputDevice, inputKind: GameInputKind, statusFilter: GameInputDeviceStatus, enumerationKind: GameInputEnumerationKind, ctx: rawptr, callbackFunc: GameInputDeviceCallback, callbackToken: ^GameInputCallbackToken) -> HRESULT,
	RegisterSystemButtonCallback: proc "system" (this: ^IGameInput, device: ^IGameInputDevice, buttonFilter: GameInputSystemButtons, ctx: rawptr, callbackFunc: GameInputSystemButtonCallback, callbackToken: ^GameInputCallbackToken) -> HRESULT,
	RegisterKeyboardLayoutCallback: proc "system" (this: ^IGameInput, device: ^IGameInputDevice, ctx: rawptr, callbackFunc: GameInputKeyboardLayoutCallback, callbackToken: ^GameInputCallbackToken) -> HRESULT,
	StopCallback: proc "system" (this: ^IGameInput, callbackToken: GameInputCallbackToken),
	UnregisterCallback: proc "system" (this: ^IGameInput, callbackToken: GameInputCallbackToken, timeoutInMicroseconds: u64) -> bool,
	CreateDispatcher: proc "system" (this: ^IGameInput, dispatcher: ^^IGameInputDispatcher) -> HRESULT,
	CreateAggregateDevice: proc "system" (this: ^IGameInput, kind: GameInputKind, device: ^^IGameInputDevice) -> HRESULT,
	FindDeviceFromId: proc "system" (this: ^IGameInput, value: ^APP_LOCAL_DEVICE_ID, device: ^^IGameInputDevice) -> HRESULT,
	FindDeviceFromObject: proc "system" (this: ^IGameInput, value: ^IUnknown, device: ^^IGameInputDevice) -> HRESULT,
	FindDeviceFromPlatformHandle: proc "system" (this: ^IGameInput, value: HANDLE, device: ^^IGameInputDevice) -> HRESULT,
	FindDeviceFromPlatformString: proc "system" (this: ^IGameInput, value: windows.LPCWSTR, device: ^^IGameInputDevice) -> HRESULT,
	EnableOemDeviceSupport: proc "system" (this: ^IGameInput, vendorId: u16, productId: u16, interfaceNumber: u8, collectionNumber: u8) -> HRESULT,
	SetFocusPolicy: proc "system" (this: ^IGameInput, policy: GameInputFocusPolicy),
}

IGameInputReading_UUID_STRING :: "2156947A-E1FA-4DE0-A30B-D812931DBD8D"
IGameInputReading_UUID := &IID{0x2156947A, 0xE1FA, 0x4DE0, {0xA3, 0x0B, 0xD8, 0x12, 0x93, 0x1D, 0x0BD, 0x8D}}
IGameInputReading :: struct #raw_union {
	#subtype iunknown: IUnknown,
	using igameinputreading_vtable: ^IGameInputReading_VTable,
}
IGameInputReading_VTable :: struct {
	using iunknown_vtable: IUnknown_VTable,
	GetInputKind: proc "system" (this: ^IGameInputReading) -> GameInputKind,
	GetSequenceNumber: proc "system" (this: ^IGameInputReading) -> u64,
	GetTimestamp: proc "system" (this: ^IGameInputReading) -> u64,
	GetDevice: proc "system" (this: ^IGameInputReading, device: ^^IGameInputDevice),
	GetRawReport: proc "system" (this: ^IGameInputReading, report: ^^IGameInputRawDeviceReport) -> bool,
	GetControllerAxisCount: proc "system" (this: ^IGameInputReading) -> u32,
	GetControllerAxisState: proc "system" (this: ^IGameInputReading, stateArrayCount: u32, stateArray: [^]f32) -> u32,
	GetControllerButtonCount: proc "system" (this: ^IGameInputReading) -> u32,
	GetControllerButtonState: proc "system" (this: ^IGameInputReading, stateArrayCount: u32, stateArray: [^]bool) -> u32,
	GetControllerSwitchCount: proc "system" (this: ^IGameInputReading) -> u32,
	GetControllerSwitchState: proc "system" (this: ^IGameInputReading, stateArrayCount: u32, stateArray: [^]GameInputSwitchPosition) -> u32,
	GetKeyCount: proc "system" (this: ^IGameInputReading) -> u32,
	GetKeyState: proc "system" (this: ^IGameInputReading, stateArrayCount: u32, stateArray: [^]GameInputKeyState) -> u32,
	GetMouseState: proc "system" (this: ^IGameInputReading, state: ^GameInputMouseState) -> bool,
	GetTouchCount: proc "system" (this: ^IGameInputReading) -> u32,
	GetTouchState: proc "system" (this: ^IGameInputReading, stateArrayCount: u32, stateArray: [^]GameInputTouchState) -> u32,
	GetMotionState: proc "system" (this: ^IGameInputReading, state: ^GameInputMotionState) -> bool,
	GetArcadeStickState: proc "system" (this: ^IGameInputReading, state: ^GameInputArcadeStickState) -> bool,
	GetFlightStickState: proc "system" (this: ^IGameInputReading, state: ^GameInputFlightStickState) -> bool,
	GetGamepadState: proc "system" (this: ^IGameInputReading, state: ^GameInputGamepadState) -> bool,
	GetRacingWheelState: proc "system" (this: ^IGameInputReading, state: ^GameInputRacingWheelState) -> bool,
	GetUiNavigationState: proc "system" (this: ^IGameInputReading, state: ^GameInputUiNavigationState) -> bool,
}

IGameInputDevice_UUID_STRING :: "31DD86FB-4C1B-408A-868F-439B3CD47125"
IGameInputDevice_UUID := &IID{0x31DD86FB, 0x4C1B, 0x408A, {0x86, 0x8F, 0x43, 0x9B, 0x3C, 0xD4, 0x71, 0x25}}
IGameInputDevice :: struct #raw_union {
	#subtype iunknown: IUnknown,
	using igameinputdevice_vtable: ^IGameInputDevice_Vtable,
}
IGameInputDevice_Vtable :: struct {
	using iunknown_vtable: IUnknown_VTable,
	GetDeviceInfo: proc "system" (this: ^IGameInputDevice) -> ^GameInputDeviceInfo,
	GetDeviceStatus: proc "system" (this: ^IGameInputDevice) -> GameInputDeviceStatus,
	GetBatteryState: proc "system" (this: ^IGameInputDevice, state: ^GameInputBatteryState),
	CreateForceFeedbackEffect: proc "system" (this: ^IGameInputDevice, motorIndex: u32, params: ^GameInputForceFeedbackParams, effect: ^^IGameInputForceFeedbackEffect) -> HRESULT,
	IsForceFeedbackMotorPoweredOn: proc "system" (this: ^IGameInputDevice, motorIndex: u32) -> bool,
	SetForceFeedbackMotorGain: proc "system" (this: ^IGameInputDevice, motorIndex: u32, masterGain: f32),
	SetHapticMotorState: proc "system" (this: ^IGameInputDevice, motorIndex: u32, params: ^GameInputHapticFeedbackParams) -> HRESULT,
	SetRumbleState: proc "system" (this: ^IGameInputDevice, params: ^GameInputRumbleParams),
	SetInputSynchronizationState: proc "system" (this: ^IGameInputDevice, enabled: bool),
	SendInputSynchronizationHint: proc "system" (this: ^IGameInputDevice),
	PowerOff: proc "system" (this: ^IGameInputDevice),
	CreateRawDeviceReport: proc "system" (this: ^IGameInputDevice, reportId: u32, reportKind: GameInputRawDeviceReportKind, report: ^^IGameInputRawDeviceReport) -> HRESULT,
	GetRawDeviceFeature: proc "system" (this: ^IGameInputDevice, reportId: u32, report: ^^IGameInputRawDeviceReport) -> HRESULT,
	SetRawDeviceFeature: proc "system" (this: ^IGameInputDevice, report: ^IGameInputRawDeviceReport) -> HRESULT,
	SendRawDeviceOutput: proc "system" (this: ^IGameInputDevice, report: ^IGameInputRawDeviceReport) -> HRESULT,
	SendRawDeviceOutputWithResponse: proc "system" (this: ^IGameInputDevice, requestReport: ^IGameInputRawDeviceReport, responseReport: ^^IGameInputRawDeviceReport) -> HRESULT,
	ExecuteRawDeviceIoControl: proc "system" (this: ^IGameInputDevice, controlCode: u32, inputBufferSize: c.size_t, inputBuffer: rawptr, outputBufferSize: c.size_t, outputBuffer: rawptr, outputSize: ^c.size_t) -> HRESULT,
	AcquireExclusiveRawDeviceAccess: proc "system" (this: ^IGameInputDevice, timeoutInMicroseconds: u64) -> bool,
	ReleaseExclusiveRawDeviceAccess: proc "system" (this: ^IGameInputDevice),
}

IGameInputDispatcher_UUID_STRING :: "415EED2E-98CB-42C2-8F28-B94601074E31"
IGameInputDispatcher_UUID := &IID{0x415EED2E, 0x98CB, 0x42C2, {0x8F, 0x28, 0xB9, 0x46, 0x01, 0x07, 0x4E, 0x31}}
IGameInputDispatcher :: struct #raw_union {
	#subtype iunknown: IUnknown,
	using igameinputdispatcher_vtable: ^IGameInputDispatcher_Vtable,
}
IGameInputDispatcher_Vtable :: struct {
	using iunknown_vtable: IUnknown_VTable,
	Dispatch: proc "system" (this: ^IGameInputDispatcher, quotaInMicroseconds: u64) -> bool,
	OpenWaitHandle: proc "system" (this: ^IGameInputDispatcher, waitHandle: ^HANDLE) -> HRESULT,
}

IGameInputForceFeedbackEffect_UUID_STRING :: "51BDA05E-F742-45D9-B085-9444AE48381D"
IGameInputForceFeedbackEffect_UUID := &IID{0x51BDA05E, 0xF742, 0x45D9, {0xB0, 0x85, 0x94, 0x44, 0xAE, 0x48, 0x38, 0x1D}}
IGameInputForceFeedbackEffect :: struct #raw_union {
	#subtype iunknown: IUnknown,
	using igameinputforcefeedbackeffect_vtable: ^IGameInputForceFeedbackEffect_Vtable,
}
IGameInputForceFeedbackEffect_Vtable :: struct {
	using iunknown_vtable: IUnknown_VTable,
	GetDevice: proc "system" (this: ^IGameInputForceFeedbackEffect, device: ^^IGameInputDevice),
	GetMotorIndex: proc "system" (this: ^IGameInputForceFeedbackEffect) -> u32,
	GetGain: proc "system" (this: ^IGameInputForceFeedbackEffect) -> f32,
	SetGain: proc "system" (this: ^IGameInputForceFeedbackEffect, gain: f32),
	GetParams: proc "system" (this: ^IGameInputForceFeedbackEffect, params: ^GameInputForceFeedbackParams),
	SetParams: proc "system" (this: ^IGameInputForceFeedbackEffect, params: ^GameInputForceFeedbackParams) -> bool,
	GetState: proc "system" (this: ^IGameInputForceFeedbackEffect) -> GameInputFeedbackEffectState,
	SetState: proc "system" (this: ^IGameInputForceFeedbackEffect, state: GameInputFeedbackEffectState),
}

IGameInputRawDeviceReport_UUID_STRING :: "61F08CF1-1FFC-40CA-A2B8-E1AB8BC5B6DC"
IGameInputRawDeviceReport_UUID := &IID{0x61F08CF1, 0x1FFC, 0x40CA, {0xA2, 0xB8, 0xE1, 0xAB, 0x8B, 0xC5, 0xB6, 0xDC}}
IGameInputRawDeviceReport :: struct #raw_union {
	#subtype iunknown: IUnknown,
	using igameinputrawdevicereport_vtable: ^IGameInputRawDeviceReport_Vtable,
}
IGameInputRawDeviceReport_Vtable :: struct {
	using iunknown_vtable: IUnknown_VTable,
	GetDevice: proc "system" (this: ^IGameInputRawDeviceReport, device: ^^IGameInputDevice),
	GetReportInfo: proc "system" (this: ^IGameInputRawDeviceReport) -> ^GameInputRawDeviceReportInfo,
	GetRawDataSize: proc "system" (this: ^IGameInputRawDeviceReport) -> c.size_t,
	GetRawData: proc "system" (this: ^IGameInputRawDeviceReport, bufferSize: c.size_t, buffer: rawptr) -> c.size_t,
	SetRawData: proc "system" (this: ^IGameInputRawDeviceReport, bufferSize: c.size_t, buffer: rawptr) -> bool,
	GetItemValue: proc "system" (this: ^IGameInputRawDeviceReport, itemIndex: u32, value: ^u64) -> bool,
	SetItemValue: proc "system" (this: ^IGameInputRawDeviceReport, itemIndex: u32, value: u64) -> bool,
	ResetItemValue: proc "system" (this: ^IGameInputRawDeviceReport, itemIndex: u32) -> bool,
	ResetAllItems: proc "system" (this: ^IGameInputRawDeviceReport) -> bool,
}

// Functions
HRESULT :: windows.HRESULT
HANDLE :: windows.HANDLE

DEVICE_DISCONNECTED : HRESULT : -0x7C75FFFF
DEVICE_NOT_FOUND : HRESULT : -0x7C75FFFE
READING_NOT_FOUND : HRESULT : -0x7C75FFFD
REFERENCE_READING_TOO_OLD : HRESULT : -0x7C75FFFC
TIMESTAMP_OUT_OF_RANGE : HRESULT : -0x7C75FFFB
INSUFFICIENT_FORCE_FEEDBACK_RESOURCES : HRESULT : -0x7C75FFFA

GameInputCallbackToken :: distinct u64

GAMEINPUT_CURRENT_CALLBACK_TOKEN_VALUE : GameInputCallbackToken : 0xFFFFFFFFFFFFFFFF
GAMEINPUT_INVALID_CALLBACK_TOKEN_VALUE : GameInputCallbackToken : 0x0000000000000000

@(default_calling_convention="system")
foreign wgi {
	GameInputCreate :: proc(gameInput: ^^IGameInput) -> HRESULT ---
}

GameInputDeviceCallback :: #type proc "system" (callbackToken: GameInputCallbackToken, ctx: rawptr, device: ^IGameInputDevice, timestamp: u64, currentState: GameInputDeviceStatus, previousState: GameInputDeviceStatus)
GameInputGuideButtonCallback :: #type proc "system" (callbackToken: GameInputCallbackToken, ctx: rawptr, device: ^IGameInputDevice, timestamp: u64, isPressed: bool)
GameInputSystemButtonCallback :: #type proc "system" (callbackToken: GameInputCallbackToken, ctx: rawptr, device: ^IGameInputDevice, timestamp: u64, currentState: GameInputDeviceStatus, previousState: GameInputDeviceStatus)
GameInputReadingCallback :: #type proc "system" (callbackToken: GameInputCallbackToken, ctx: rawptr, reading: ^IGameInputReading, hasOverrunOccured: bool)
GameInputKeyboardLayoutCallback :: #type proc "system" (callbackToken: GameInputCallbackToken, ctx: rawptr, device: ^IGameInputDevice, timestamp: u64, currentState: GameInputDeviceStatus, previousState: GameInputDeviceStatus)

